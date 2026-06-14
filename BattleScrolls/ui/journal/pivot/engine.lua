-----------------------------------------------------------
-- Pivot Engine
-- Async decode-extract-discard pipeline for pivot queries
--
-- Resolves scope, extracts data per encounter, aggregates
-- results, and returns a PivotResult for rendering.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local pivot = BattleScrolls.journal.pivot
local extractors = pivot.extractors
local binaryStorage = BattleScrolls.binaryStorage
local storage = BattleScrolls.storage
local Effect = BattleScrolls.Effect

local engine = {}
pivot.engine = engine

---Check if domain is one of the three effects sub-domains
---@param domain string
---@return boolean
local function isEffectsDomain(domain)
    return domain == pivot.Domain.EFFECTS_SELF
        or domain == pivot.Domain.EFFECTS_BOSS
        or domain == pivot.Domain.EFFECTS_GROUP
end

---Build a lookup table mapping each EffectStats reference to its unit's alive time.
---This preserves referential identity (no wrapping) so cross-dimension paths still work.
---@param decoded DecodedEncounter
---@param domain string
---@param durationS number
---@return table<EffectStats, number>|nil -- stats ref → aliveTimeS, nil if not needed
local function buildAliveTimeLookup(decoded, domain, durationS)
    if domain == pivot.Domain.EFFECTS_SELF then return nil end -- player alive time is already correct
    local unitAliveTimeMs = decoded.unitAliveTimeMs
    local playerAliveTimeS = decoded.playerAliveTimeMs and (decoded.playerAliveTimeMs / 1000) or durationS
    local lookup = {}

    if domain == pivot.Domain.EFFECTS_GROUP then
        for displayName, memberEffects in pairs(decoded.effectsOnGroup or {}) do
            local aliveS = unitAliveTimeMs and unitAliveTimeMs[displayName]
                and (unitAliveTimeMs[displayName] / 1000) or durationS
            for _, stats in pairs(memberEffects) do
                lookup[stats] = aliveS
            end
        end
        -- Player buffs included in group effects use player alive time
        for _, stats in pairs(decoded.effectsOnPlayer or {}) do
            if stats.effectType == BUFF_EFFECT_TYPE_BUFF then
                lookup[stats] = playerAliveTimeS
            end
        end
    elseif domain == pivot.Domain.EFFECTS_BOSS then
        for unitTag, bossEffects in pairs(decoded.effectsOnBosses or {}) do
            local aliveS = unitAliveTimeMs and unitAliveTimeMs[unitTag]
                and (unitAliveTimeMs[unitTag] / 1000) or durationS
            for _, stats in pairs(bossEffects) do
                lookup[stats] = aliveS
            end
        end
    end

    return next(lookup) and lookup or nil
end

---Filter damageByUnitId to only include boss targets
---@param damageByUnitId table
---@param bossTagSeqByUnitId table
---@return table
local function filterToBossTargets(damageByUnitId, bossTagSeqByUnitId)
    local filtered = {}
    for sourceId, byTarget in pairs(damageByUnitId) do
        for targetId, damageData in pairs(byTarget) do
            if bossTagSeqByUnitId[targetId] then
                if not filtered[sourceId] then filtered[sourceId] = {} end
                filtered[sourceId][targetId] = damageData
            end
        end
    end
    return filtered
end

--- Maximum number of value columns (row label column is separate)
local MAX_VALUE_COLUMNS = 10
--- Maximum number of result rows to prevent memory exhaustion on large queries
local MAX_RESULT_ROWS = 500

-------------------------
-- Scope Resolution
-------------------------

---Build encounter label from compact metadata
---@param encounter CompactEncounter
---@param index number
---@return string
local function encounterLabel(encounter, index)
    local name = encounter.displayName
    if not name or name == "" then
        name = string.format("#%d", index)
    end
    if encounter.timestampS then
        return os.date("%m/%d %H:%M", encounter.timestampS) .. " — " .. name
    end
    return name
end

---Build instance label from storage
---@param instance InstanceStorage
---@return string
local function instanceLabel(instance)
    local zone = instance.zone or GetString(BATTLESCROLLS_UNKNOWN)
    if instance.timestampS then
        return os.date("%m/%d %H:%M", instance.timestampS) .. " — " .. zone
    end
    return zone
end

---Check if an encounter passes the time filter
---@param encounter CompactEncounter
---@param scope PivotScope
---@return boolean
local function passesTimeFilter(encounter, scope)
    if scope.timeMode == pivot.TimeMode.ALL then return true end
    -- CUSTOM: check timeFrom/timeTo range
    local ts = encounter.timestampS
    local from = scope.timeFrom or 0
    local to = scope.timeTo or GetTimeStamp()
    return ts >= from and ts <= to
end

---Check if an encounter passes the category filter
---@param encounter CompactEncounter
---@param scope PivotScope
---@return boolean
local function passesCategoryFilter(encounter, scope)
    local cat = scope.encounterCategory
    if cat == pivot.EncounterCategory.ALL then return true end
    if cat == pivot.EncounterCategory.SPECIFIC then return true end  -- handled by encounterIds check

    local hasBosses = encounter.bossesUnits and #encounter.bossesUnits > 0
    if cat == pivot.EncounterCategory.BOSS then return hasBosses end
    if cat == pivot.EncounterCategory.BOSS_NAMES then return hasBosses end
    if cat == pivot.EncounterCategory.TRASH then return not hasBosses and not encounter.isPlayerFight and not encounter.isDummyFight end
    if cat == pivot.EncounterCategory.PLAYER then return encounter.isPlayerFight == true end
    if cat == pivot.EncounterCategory.DUMMY then return encounter.isDummyFight == true end
    return true
end

---Check if an encounter passes the boss name filter.
---Applied when encounter category is ALL, BOSS, or BOSS_NAMES.
---@param encounter CompactEncounter
---@param scope PivotScope
---@return boolean
local function passesBossFilter(encounter, scope)
    if not scope.encounterBosses then return true end
    local cat = scope.encounterCategory
    if cat ~= pivot.EncounterCategory.ALL and cat ~= pivot.EncounterCategory.BOSS and cat ~= pivot.EncounterCategory.BOSS_NAMES then
        return true
    end
    if not encounter.bossSeqNames then return false end

    for _, bossName in pairs(encounter.bossSeqNames) do
        if scope.encounterBosses[bossName] then
            return true  -- OR: any matching boss is enough
        end
    end
    return false
end

---Check if an instance passes the instance scope filter
---@param instance InstanceStorage
---@param scope PivotScope
---@return boolean
local function passesInstanceFilter(instance, scope)
    local mode = scope.instanceMode
    if mode == pivot.InstanceMode.EVERYTHING then return true end
    if mode == pivot.InstanceMode.INSTANCED then return not instance.isOverland and not instance.isHouse and not instance.isPvP end
    if mode == pivot.InstanceMode.OVERLAND then return instance.isOverland == true and not instance.isHouse and not instance.isPvP end
    if mode == pivot.InstanceMode.HOUSES then return instance.isHouse == true end
    if mode == pivot.InstanceMode.PVP then return instance.isPvP == true end
    if mode == pivot.InstanceMode.ZONES then
        return scope.instanceZones and scope.instanceZones[instance.zone] or false
    end
    if mode == pivot.InstanceMode.SPECIFIC then
        -- instanceIds checked by caller
        return true
    end
    return true
end

---Resolve scope to a flat list of encounters with parent info
---@param scope PivotScope
---@return ScopedEncounter[]
function engine.resolveScope(scope)
    local history = storage.savedVariables.history
    local result = {}

    for i, instance in ipairs(history) do
        -- Instance filter
        local passesInstance
        if scope.instanceMode == pivot.InstanceMode.SPECIFIC then
            passesInstance = scope.instanceIds and scope.instanceIds[instance.index]
        else
            passesInstance = passesInstanceFilter(instance, scope)
        end

        if passesInstance then
            -- Encounter filter within instance
            for j, encounter in ipairs(instance.encounters) do
                -- Specific encounters: check encounter ID directly
                local passesEncounter
                if scope.encounterCategory == pivot.EncounterCategory.SPECIFIC then
                    passesEncounter = scope.encounterIds and scope.encounterIds[encounter.timestampS]
                else
                    passesEncounter = passesCategoryFilter(encounter, scope)
                        and passesBossFilter(encounter, scope)
                end

                if passesEncounter and passesTimeFilter(encounter, scope) then
                    table.insert(result, {
                        instance = instance,
                        instanceIndex = i,
                        encounter = encounter,
                        encounterIndex = j,
                    })
                end
            end
        end
    end

    return result
end

-------------------------
-- Data Extraction
-------------------------

---Merge breakdowns into a single aggregate
---@param breakdowns any[]
---@param metricExtractor MetricExtractor
---@param durationS number
---@param aliveTimeS number|nil
---@param aggregation string|nil
---@param aliveTimeLookup table|nil -- per-stats alive time override (effects domains)
---@return number
local function computeMetricFromBreakdowns(breakdowns, metricExtractor, durationS, aliveTimeS, aggregation, aliveTimeLookup)
    if not breakdowns or #breakdowns == 0 then return 0 end
    if metricExtractor.aggregate then
        return metricExtractor.aggregate(breakdowns, durationS, aliveTimeS, aggregation, aliveTimeLookup)
    end
    -- Fallback for metrics without aggregate (e.g., overview metrics that bypass this path)
    local bdAliveTimeS = aliveTimeLookup and aliveTimeLookup[breakdowns[1]] or aliveTimeS
    return metricExtractor.extract(breakdowns[1], durationS, bdAliveTimeS)
end

---Extract data from a single decoded encounter for decode domains
---@param query PivotQuery
---@param decoded DecodedEncounter
---@param abilityInfo table<number, AbilityInfo>
---@param unitNames table<number, string>|nil
---@param durationS number
---@param metricIds string[]
---@return table<string, table<string, number>> -- rowKey -> metricId -> value
local function extractFromDecoded(query, decoded, abilityInfo, unitNames, durationS, metricIds)
    local dimExtractor = extractors.dimensions[query.rowDimension]
    if not dimExtractor then return {} end

    -- Pass alive time for uptime accuracy (extractors decide which to use)
    local aliveTimeS = decoded.playerAliveTimeMs and (decoded.playerAliveTimeMs / 1000) or nil
    -- Per-unit alive time lookup for effects domains (group/boss)
    local aliveTimeLookup = isEffectsDomain(query.domain)
        and buildAliveTimeLookup(decoded, query.domain, durationS) or nil

    local grouped = dimExtractor.extract(decoded, abilityInfo, query.domain, unitNames)
    local rows = {}

    for key, breakdowns in pairs(grouped) do
        rows[key] = {}
        for _, metricId in ipairs(metricIds) do
            local metricExt = extractors.metrics[metricId]
            if metricExt then
                rows[key][metricId] = computeMetricFromBreakdowns(breakdowns, metricExt, durationS, aliveTimeS, query.aggregation, aliveTimeLookup)
            end
        end
    end

    return rows
end

---Extract cross-dimension data: rows grouped by one dimension, columns by another.
---Both extractors must return original breakdown references (not synthetic aggregates)
---so that object identity can be used to cross-reference them.
---@param query PivotQuery
---@param decoded DecodedEncounter
---@param abilityInfo table<number, AbilityInfo>
---@param unitNames table<number, string>|nil
---@param durationS number
---@param metricId string Single metric (cross-dimension uses one metric)
---@return table<string, table<string, number>> -- rowKey → colKey → value
local function extractCrossDimension(query, decoded, abilityInfo, unitNames, durationS, metricId)
    local rowDimExtractor = extractors.dimensions[query.rowDimension]
    local colDimExtractor = extractors.dimensions[query.columnMode]
    if not rowDimExtractor or not colDimExtractor then return {} end

    local aliveTimeS = decoded.playerAliveTimeMs and (decoded.playerAliveTimeMs / 1000) or nil
    local aliveTimeLookup = isEffectsDomain(query.domain)
        and buildAliveTimeLookup(decoded, query.domain, durationS) or nil

    -- Run column extractor → colKey → breakdowns[]
    local colGroups = colDimExtractor.extract(decoded, abilityInfo, query.domain, unitNames)

    -- Build reverse map: breakdown table reference → colKey
    local breakdownToCol = {}
    for colKey, breakdowns in pairs(colGroups) do
        for _, bd in ipairs(breakdowns) do
            breakdownToCol[bd] = colKey
        end
    end

    -- Run row extractor → rowKey → breakdowns[]
    local rowGroups = rowDimExtractor.extract(decoded, abilityInfo, query.domain, unitNames)

    -- Cross-tabulate: group breakdowns by (rowKey, colKey), then compute metric
    local metricExt = extractors.metrics[metricId]
    if not metricExt then return {} end

    local result = {}
    for rowKey, breakdowns in pairs(rowGroups) do
        local colBuckets = {}
        for _, bd in ipairs(breakdowns) do
            local colKey = breakdownToCol[bd]
            if colKey then
                if not colBuckets[colKey] then colBuckets[colKey] = {} end
                table.insert(colBuckets[colKey], bd)
            end
        end
        result[rowKey] = {}
        for colKey, colBreakdowns in pairs(colBuckets) do
            result[rowKey][colKey] = computeMetricFromBreakdowns(colBreakdowns, metricExt, durationS, aliveTimeS, query.aggregation, aliveTimeLookup)
        end
    end

    return result
end

---Extract overview-level metrics from a decoded encounter using ArithmancerInstance
---@param decoded DecodedEncounter
---@param abilityInfo table<number, AbilityInfo>
---@param metricIds string[]
---@return table<string, number> -- metricId -> value
local function extractOverview(decoded, abilityInfo, metricIds)
    local Arithmancer = BattleScrolls.arithmancer
    local calc = Arithmancer:Make(decoded, abilityInfo)
    local bossCalc ---@type ArithmancerInstance|nil

    local values = {}
    for _, metricId in ipairs(metricIds) do
        if metricId == pivot.Metric.DPS then
            values[metricId] = calc:personalDPS()
        elseif metricId == pivot.Metric.TOTAL_DAMAGE then
            values[metricId] = calc:personalTotalDamage()
        elseif metricId == pivot.Metric.CRIT_PERCENT then
            values[metricId] = calc:getDamageQuality().critRate
        elseif metricId == pivot.Metric.RAW_HPS_OUT then
            values[metricId] = calc:getHealingOutSummary().rawHps
        elseif metricId == pivot.Metric.EFFECTIVE_HPS_OUT then
            values[metricId] = calc:getHealingOutSummary().effectiveHps
        elseif metricId == pivot.Metric.RAW_HPS_IN then
            values[metricId] = calc:getHealingInSummary().rawHps
        elseif metricId == pivot.Metric.EFFECTIVE_HPS_IN then
            values[metricId] = calc:getHealingInSummary().effectiveHps
        elseif metricId == pivot.Metric.BOSS_DPS or metricId == pivot.Metric.BOSS_DAMAGE then
            if bossCalc == nil then
                bossCalc = Arithmancer:ForBosses(decoded, abilityInfo) or false
            end
            if bossCalc then
                if metricId == pivot.Metric.BOSS_DPS then
                    values[metricId] = bossCalc:personalDPS()
                else
                    values[metricId] = bossCalc:personalTotalDamage()
                end
            else
                values[metricId] = 0
            end
        elseif metricId == pivot.Metric.DTPS then
            values[metricId] = calc:getDamageTakenSummary().dtps
        elseif metricId == pivot.Metric.DAMAGE_TAKEN then
            values[metricId] = calc:damageTakenTotal()
        elseif metricId == pivot.Metric.DURATION then
            values[metricId] = calc:getDurationS()
        elseif metricId == pivot.Metric.DEATH_COUNT then
            values[metricId] = decoded.deaths and decoded.deaths.deathCount or 0
        elseif metricId == pivot.Metric.AVG_WEAVE_TIME then
            local weaving = decoded.weaving
            if weaving then
                local totalSum, totalCount = 0, 0
                for _, entry in ipairs(weaving.byAbility) do
                    totalSum = totalSum + entry.afterSum
                    totalCount = totalCount + entry.afterCount
                end
                values[metricId] = totalCount > 0 and (totalSum / totalCount) or 0
            else
                values[metricId] = 0
            end
        elseif metricId == pivot.Metric.LIGHT_ATTACKS_PER_SEC then
            local weaving = decoded.weaving
            local durationS = calc:getDurationS()
            if weaving and durationS > 0 then
                values[metricId] = weaving.lightAttackHits / durationS
            else
                values[metricId] = 0
            end
        elseif metricId == pivot.Metric.WEAVING_ERRORS then
            values[metricId] = decoded.weaving and decoded.weaving.totalWeavingErrors or 0
        elseif metricId == pivot.Metric.TIME_LOST then
            local weaving = decoded.weaving
            if weaving then
                local totalSum = 0
                for _, entry in ipairs(weaving.byAbility) do
                    totalSum = totalSum + entry.afterSum
                end
                values[metricId] = totalSum / 1000
            else
                values[metricId] = 0
            end
        elseif metricId == pivot.Metric.DOUBLE_LA_ERRORS then
            values[metricId] = decoded.weaving and decoded.weaving.doubleLaErrors or 0
        end
    end
    return values
end

-------------------------
-- Query Execution
-------------------------

---Determine the effective metric IDs for a query
---@param query PivotQuery
---@return string[]
local function resolveMetricIds(query)
    if query.columnMode == pivot.ColumnMode.METRICS then
        return query.metrics
    else
        -- Single metric when columns is a dimension
        return { query.metrics[1] }
    end
end

---Determine column keys for the result
---@param query PivotQuery
---@param scopedEncounters ScopedEncounter[]
---@return string[], table<string, string> -- columnKeys, columnLabels
local function resolveColumns(query, scopedEncounters)
    if query.columnMode == pivot.ColumnMode.METRICS then
        local keys = {}
        local labels = {}
        for i, metricId in ipairs(query.metrics) do
            if i > MAX_VALUE_COLUMNS then break end
            table.insert(keys, metricId)
            labels[metricId] = extractors.getMetricLabel(metricId)
        end
        return keys, labels
    end

    -- Columns is a dimension: build column keys from scoped data
    if query.columnMode == pivot.Dimension.ENCOUNTER then
        local keys = {}
        local labels = {}
        for _, se in ipairs(scopedEncounters) do
            if #keys >= MAX_VALUE_COLUMNS then break end
            local key = string.format("enc_%d_%d", se.instanceIndex, se.encounterIndex)
            table.insert(keys, key)
            labels[key] = encounterLabel(se.encounter, se.encounterIndex)
        end
        return keys, labels
    end

    if query.columnMode == pivot.Dimension.INSTANCE then
        -- Deduplicate instances
        local seen = {}
        local keys = {}
        local labels = {}
        for _, se in ipairs(scopedEncounters) do
            if #keys >= MAX_VALUE_COLUMNS then break end
            if not seen[se.instanceIndex] then
                seen[se.instanceIndex] = true
                local key = string.format("inst_%d", se.instanceIndex)
                table.insert(keys, key)
                labels[key] = instanceLabel(se.instance)
            end
        end
        return keys, labels
    end

    -- Other dimensions as columns: keys discovered during extraction
    return {}, {}
end

---Check if aggregation is needed
---@param query PivotQuery
---@param scopedEncounters ScopedEncounter[]
---@return boolean
local function needsAggregation(query, scopedEncounters)
    if #scopedEncounters <= 1 then return false end
    if query.rowDimension == pivot.Dimension.ENCOUNTER then return false end
    if query.columnMode == pivot.Dimension.ENCOUNTER then return false end
    return true
end

-------------------------
-- Shared Accumulator
-------------------------

---Construct a row key, label, and storage indices for encounter/instance row dimensions
---@param se ScopedEncounter
---@param rowDimension string
---@return string key, string label, { instanceIndex: number, encounterIndex: number|nil } indices
local function makeRowKey(se, rowDimension)
    if rowDimension == pivot.Dimension.ENCOUNTER then
        local key = string.format("enc_%d_%d", se.instanceIndex, se.encounterIndex)
        return key, encounterLabel(se.encounter, se.encounterIndex),
            { instanceIndex = se.instanceIndex, encounterIndex = se.encounterIndex }
    else -- INSTANCE
        local key = string.format("inst_%d", se.instanceIndex)
        return key, instanceLabel(se.instance),
            { instanceIndex = se.instanceIndex }
    end
end

---@class PivotAccumulator
---@field data table<string, table<string, number>>
---@field counts table<string, table<string, number>>
---@field rowLabels table<string, string>
---@field rowIndices table<string, { instanceIndex: number, encounterIndex: number|nil }>
---@field rowCount number
---@field knownCols table<string, boolean>
---@field knownColCount number
---@field aggFunc string
---@field rowsCapped boolean
---@field columnsCapped boolean

---Create a new accumulator for incremental aggregation
---@param aggFunc string
---@param columnKeys string[]
---@return PivotAccumulator
local function createAccumulator(aggFunc, columnKeys)
    local knownCols = {}
    local knownColCount = 0
    for _, k in ipairs(columnKeys) do
        knownCols[k] = true
        knownColCount = knownColCount + 1
    end
    return {
        data = {},
        counts = {},
        rowLabels = {},
        rowIndices = {},
        rowCount = 0,
        knownCols = knownCols,
        knownColCount = knownColCount,
        aggFunc = aggFunc,
        rowsCapped = false,
        columnsCapped = false,
    }
end

---Accumulate a single value into an accumulator cell
---@param acc PivotAccumulator
---@param rowKey string
---@param colKey string
---@param value number
local function accumulate(acc, rowKey, colKey, value)
    if not acc.knownCols[colKey] then
        if acc.knownColCount >= MAX_VALUE_COLUMNS then
            acc.columnsCapped = true
            return
        end
        acc.knownCols[colKey] = true
        acc.knownColCount = acc.knownColCount + 1
    end
    if not acc.data[rowKey] then
        if acc.rowCount >= MAX_RESULT_ROWS then
            acc.rowsCapped = true
            return
        end
        acc.data[rowKey] = {}
        acc.counts[rowKey] = {}
        acc.rowCount = acc.rowCount + 1
    end
    if acc.aggFunc == pivot.Aggregation.MAX then
        local cur = acc.data[rowKey][colKey]
        if cur == nil or value > cur then
            acc.data[rowKey][colKey] = value
        end
    elseif acc.aggFunc == pivot.Aggregation.MIN then
        local cur = acc.data[rowKey][colKey]
        if cur == nil or value < cur then
            acc.data[rowKey][colKey] = value
        end
    else -- SUM or AVG: both accumulate sum; AVG divides at the end
        acc.data[rowKey][colKey] = (acc.data[rowKey][colKey] or 0) + value
        if acc.aggFunc == pivot.Aggregation.AVG then
            acc.counts[rowKey][colKey] = (acc.counts[rowKey][colKey] or 0) + 1
        end
    end
end

---Finalize accumulator and build PivotResult
---@param acc PivotAccumulator
---@param columnKeys string[]
---@param columnLabels table<string, string>
---@param rowDimension string
---@param encounterCount number
---@param query PivotQuery
---@return PivotResult
local function buildResult(acc, columnKeys, columnLabels, rowDimension, encounterCount, query)
    -- Finalize AVG: divide sums by counts
    if acc.aggFunc == pivot.Aggregation.AVG then
        for rowKey, cols in pairs(acc.data) do
            for colKey, sum in pairs(cols) do
                local count = acc.counts[rowKey][colKey] or 1
                acc.data[rowKey][colKey] = count > 0 and (sum / count) or 0
            end
        end
    end

    -- Discover dynamic column keys (for cross-dimension columns)
    if #columnKeys == 0 then
        for k in pairs(acc.knownCols) do
            table.insert(columnKeys, k)
        end
        table.sort(columnKeys)
        columnLabels = {}
        for _, k in ipairs(columnKeys) do columnLabels[k] = k end
    end

    -- Build result rows
    local rows = {}
    for rowKey, columns in pairs(acc.data) do
        local displayKey = acc.rowLabels[rowKey] or rowKey
        local indices = acc.rowIndices[rowKey]
        ---@type PivotResultRow
        local row = {
            key = displayKey,
            sortKey = displayKey:lower(),
            values = columns,
            instanceIndex = indices and indices.instanceIndex or nil,
            encounterIndex = indices and indices.encounterIndex or nil,
        }
        table.insert(rows, row)
    end

    -- Sort by first column value descending
    local firstCol = columnKeys[1]
    if firstCol then
        table.sort(rows, function(a, b)
            local va = a.values[firstCol] or 0
            local vb = b.values[firstCol] or 0
            if va ~= vb then return va > vb end
            return a.key < b.key
        end)
    end

    return {
        rows = rows,
        columns = columnKeys,
        columnLabels = columnLabels,
        rowDimensionLabel = extractors.getDimensionLabel(rowDimension),
        encounterCount = encounterCount,
        query = query,
        rowsCapped = acc.rowsCapped or nil,
        columnsCapped = acc.columnsCapped or nil,
    }
end

---Run a group domain query (no decode needed)
---@param query PivotQuery
---@param scopedEncounters ScopedEncounter[]
---@param onProgress fun(current: number, total: number)|nil
---@return PivotResult
function engine.runGroupQuery(query, scopedEncounters, onProgress)
    local metricIds = resolveMetricIds(query)
    local columnKeys, columnLabels = resolveColumns(query, scopedEncounters)
    local aggFunc = query.aggregation or (needsAggregation(query, scopedEncounters) and pivot.Aggregation.AVG or pivot.Aggregation.SUM)

    local groupDimExtractor = extractors.groupDimensions[query.rowDimension]
    local groupColDimExtractor = extractors.groupDimensions[query.columnMode]
    local isCrossDim = query.columnMode ~= pivot.ColumnMode.METRICS
        and query.columnMode ~= pivot.Dimension.ENCOUNTER
        and query.columnMode ~= pivot.Dimension.INSTANCE

    -- Track whether Boss dimension is active (rows or columns) for per-boss extraction
    local rowIsBoss = query.rowDimension == pivot.Dimension.BOSS
    local colIsBoss = query.columnMode == pivot.Dimension.BOSS

    local acc = createAccumulator(aggFunc, columnKeys)

    for idx, se in ipairs(scopedEncounters) do
        local sharedData = se.encounter.sharedData
        if sharedData then
            -- Track encounter-level metrics to avoid duplication across members
            local encounterMetricAdded = {}
            for _, entry in ipairs(sharedData) do
                -- Determine row key(s) (use unique keys for encounter/instance)
                local rowKeys
                if query.rowDimension == pivot.Dimension.ENCOUNTER
                    or query.rowDimension == pivot.Dimension.INSTANCE then
                    local key, label, indices = makeRowKey(se, query.rowDimension)
                    rowKeys = { key }
                    acc.rowLabels[key] = label
                    acc.rowIndices[key] = indices
                elseif groupDimExtractor then
                    local result = groupDimExtractor.extract(entry, se.encounter, se.instance)
                    if not result then
                        -- nil means skip this entry (e.g., non-boss encounter for Boss dimension)
                    elseif type(result) == "table" then
                        rowKeys = result
                    else
                        rowKeys = { result }
                    end
                else
                    rowKeys = { entry.displayName }
                end

                if rowKeys then
                    for _, rowKey in ipairs(rowKeys) do
                        -- Resolve which boss name applies to this row (if Boss is a dimension)
                        local bossName = rowIsBoss and rowKey or nil

                        -- Helper: extract a single metric value from a group entry
                        local function extractGroupMetric(mId, overrideBossName)
                            local metricExt = extractors.groupMetrics[mId] or extractors.metrics[mId]
                            if not metricExt or not metricExt.extract then return 0 end
                            if extractors.groupMetrics[mId] then
                                local bn = overrideBossName or bossName
                                if bn and metricExt.bossExtract then
                                    return metricExt.bossExtract(entry, se.encounter, bn)
                                end
                                return metricExt.extract(entry, se.encounter)
                            else
                                -- Encounter-level metric (Duration etc.), add only once per encounter
                                local dedupKey = mId .. ":" .. rowKey
                                if encounterMetricAdded[dedupKey] then return nil end
                                encounterMetricAdded[dedupKey] = true
                                return metricExt.extract({}, se.encounter.durationMs / 1000)
                            end
                        end

                        -- Determine column key and extract metric
                        if query.columnMode == pivot.ColumnMode.METRICS then
                            for _, metricId in ipairs(metricIds) do
                                local value = extractGroupMetric(metricId)
                                if value then accumulate(acc, rowKey, metricId, value) end
                            end
                        elseif query.columnMode == pivot.Dimension.ENCOUNTER then
                            local value = extractGroupMetric(metricIds[1])
                            if value then accumulate(acc, rowKey, string.format("enc_%d_%d", se.instanceIndex, se.encounterIndex), value) end
                        elseif query.columnMode == pivot.Dimension.INSTANCE then
                            local value = extractGroupMetric(metricIds[1])
                            if value then accumulate(acc, rowKey, string.format("inst_%d", se.instanceIndex), value) end
                        elseif isCrossDim and groupColDimExtractor then
                            local colResult = groupColDimExtractor.extract(entry, se.encounter, se.instance)
                            if colResult then
                                local colKeys = type(colResult) == "table" and colResult or { colResult }
                                for _, colKey in ipairs(colKeys) do
                                    local value = extractGroupMetric(metricIds[1], colIsBoss and colKey or nil)
                                    if value then accumulate(acc, rowKey, colKey, value) end
                                end
                            end
                        end
                    end
                end
            end
        end

        if onProgress then onProgress(idx, #scopedEncounters) end
    end

    return buildResult(acc, columnKeys, columnLabels, query.rowDimension, #scopedEncounters, query)
end

---Run a decode domain query (damage/healing/effects/overview) asynchronously
---@param query PivotQuery
---@param scopedEncounters ScopedEncounter[]
---@param onProgress fun(current: number, total: number)|nil
---@return Effect
function engine.runDecodeQueryAsync(query, scopedEncounters, onProgress)
    return Effect.Async(function()
        local metricIds = resolveMetricIds(query)
        local columnKeys, columnLabels = resolveColumns(query, scopedEncounters)
        local doAgg = needsAggregation(query, scopedEncounters)
        -- When no aggregation needed, use SUM (identity for single values)
        local aggFunc = doAgg and (query.aggregation or pivot.Aggregation.AVG) or pivot.Aggregation.SUM
        local isOverview = query.domain == pivot.Domain.OVERVIEW

        local acc = createAccumulator(aggFunc, columnKeys)

        -- Cache decoded instance fields per instance index to avoid re-decoding
        local instanceFieldsCache = {}

        for idx, se in ipairs(scopedEncounters) do
            -- Decode instance fields if needed (abilityInfo may be compressed)
            if not instanceFieldsCache[se.instanceIndex] then
                if not se.instance.abilityInfo and se.instance._instanceData then
                    local fields = binaryStorage.decodeInstanceFieldsAsync(se.instance):Await()
                    instanceFieldsCache[se.instanceIndex] = fields and fields[1] or {}
                else
                    instanceFieldsCache[se.instanceIndex] = se.instance.abilityInfo or {}
                end
            end

            -- Decode encounter
            local decoded = binaryStorage.decodeEncounterAsync(se.encounter):Await()
            if decoded then
                -- Boss-only target filter: replace damageByUnitId with filtered copy
                if query.targetMode == pivot.TargetMode.BOSSES
                    and decoded.damageByUnitId and decoded.bossTagSeqByUnitId then
                    decoded.damageByUnitId = filterToBossTargets(
                        decoded.damageByUnitId, decoded.bossTagSeqByUnitId)
                end

                local durationS = decoded.durationMs / 1000

                -- Resolve abilityInfo from instance (cached)
                local abilityInfo = instanceFieldsCache[se.instanceIndex]
                local unitNames = decoded.unitNames or se.instance.unitNames

                if isOverview then
                    -- Overview: one row per encounter or instance (unique keys)
                    local rowKey, label, indices = makeRowKey(se, query.rowDimension)
                    acc.rowLabels[rowKey] = label
                    acc.rowIndices[rowKey] = indices

                    local overviewValues = extractOverview(decoded, abilityInfo, metricIds)

                    if query.columnMode == pivot.ColumnMode.METRICS then
                        for _, metricId in ipairs(metricIds) do
                            accumulate(acc, rowKey, metricId, overviewValues[metricId] or 0)
                        end
                    elseif query.columnMode == pivot.Dimension.ENCOUNTER then
                        local colKey = string.format("enc_%d_%d", se.instanceIndex, se.encounterIndex)
                        accumulate(acc, rowKey, colKey, overviewValues[metricIds[1]] or 0)
                    end
                else
                    -- Decode domain: extract rows
                    if query.rowDimension == pivot.Dimension.ENCOUNTER
                        or query.rowDimension == pivot.Dimension.INSTANCE then
                        -- Row is encounter/instance level: aggregate all data into one row
                        -- Use unique keys to prevent same-name encounters from merging
                        local rowKey, label, indices = makeRowKey(se, query.rowDimension)
                        acc.rowLabels[rowKey] = label
                        acc.rowIndices[rowKey] = indices

                        -- Compute each metric at encounter level by aggregating all breakdowns
                        -- Collect all breakdowns for the domain into a flat list
                        local allBreakdowns = {}
                        if query.domain == pivot.Domain.DAMAGE then
                            for _, byTarget in pairs(decoded.damageByUnitId or {}) do
                                for _, byAbility in pairs(byTarget) do
                                    for _, bd in pairs(byAbility) do
                                        table.insert(allBreakdowns, bd)
                                    end
                                end
                            end
                        elseif query.domain == pivot.Domain.DAMAGE_IN then
                            for _, byTarget in pairs(decoded.damageTakenByUnitId or {}) do
                                for _, byAbility in pairs(byTarget) do
                                    for _, bd in pairs(byAbility) do
                                        table.insert(allBreakdowns, bd)
                                    end
                                end
                            end
                        elseif query.domain == pivot.Domain.HEALING_OUT
                            or query.domain == pivot.Domain.HEALING_IN then
                            local hs = decoded.healingStats
                            if hs then
                                local mainTable = query.domain == pivot.Domain.HEALING_OUT
                                    and hs.healingOutToGroup or hs.healingInFromGroup
                                for _, healData in pairs(mainTable or {}) do
                                    if healData.total then
                                        table.insert(allBreakdowns, healData.total)
                                    end
                                end
                                if hs.selfHealing and hs.selfHealing.total then
                                    table.insert(allBreakdowns, hs.selfHealing.total)
                                end
                            end
                        end

                        local aliveTimeS = decoded.playerAliveTimeMs
                            and (decoded.playerAliveTimeMs / 1000) or nil
                        local aliveTimeLookup = isEffectsDomain(query.domain)
                            and buildAliveTimeLookup(decoded, query.domain, durationS) or nil

                        local isCrossDimCol = query.columnMode ~= pivot.ColumnMode.METRICS
                            and query.columnMode ~= pivot.Dimension.ENCOUNTER
                            and query.columnMode ~= pivot.Dimension.INSTANCE

                        if isCrossDimCol then
                            -- Cross-dimension columns on encounter-level rows:
                            -- run column extractor, compute metric per column bucket
                            local colDimExt = extractors.dimensions[query.columnMode]
                            if colDimExt then
                                local colGroups = colDimExt.extract(decoded, abilityInfo, query.domain, unitNames)
                                local metricId = metricIds[1]
                                local metricExt = extractors.metrics[metricId]
                                if metricExt then
                                    for colKey, breakdowns in pairs(colGroups) do
                                        local value = computeMetricFromBreakdowns(
                                            breakdowns, metricExt, durationS, aliveTimeS, query.aggregation, aliveTimeLookup)
                                        accumulate(acc, rowKey, colKey, value)
                                    end
                                end
                            end
                        else
                            for _, metricId in ipairs(metricIds) do
                                local metricExt = extractors.metrics[metricId]
                                if metricExt then
                                    local value = 0
                                    if isEffectsDomain(query.domain) then
                                        -- Avg across all effects in the sub-domain
                                        local sum, count = 0, 0
                                        if query.domain == pivot.Domain.EFFECTS_SELF then
                                            for _, stats in pairs(decoded.effectsOnPlayer or {}) do
                                                sum = sum + metricExt.extract(stats, durationS, aliveTimeS)
                                                count = count + 1
                                            end
                                        elseif query.domain == pivot.Domain.EFFECTS_BOSS then
                                            for _, byAbility in pairs(decoded.effectsOnBosses or {}) do
                                                for _, stats in pairs(byAbility) do
                                                    local statsAliveS = aliveTimeLookup and aliveTimeLookup[stats] or aliveTimeS
                                                    sum = sum + metricExt.extract(stats, durationS, statsAliveS)
                                                    count = count + 1
                                                end
                                            end
                                        elseif query.domain == pivot.Domain.EFFECTS_GROUP then
                                            for _, byAbility in pairs(decoded.effectsOnGroup or {}) do
                                                for _, stats in pairs(byAbility) do
                                                    local statsAliveS = aliveTimeLookup and aliveTimeLookup[stats] or aliveTimeS
                                                    sum = sum + metricExt.extract(stats, durationS, statsAliveS)
                                                    count = count + 1
                                                end
                                            end
                                            -- Also include player buffs from effectsOnPlayer
                                            for _, stats in pairs(decoded.effectsOnPlayer or {}) do
                                                if stats.effectType == BUFF_EFFECT_TYPE_BUFF then
                                                    sum = sum + metricExt.extract(stats, durationS, aliveTimeS)
                                                    count = count + 1
                                                end
                                            end
                                        end
                                        value = count > 0 and (sum / count) or 0
                                    else
                                        -- Compute from real breakdowns (preserves ticks, crits, etc.)
                                        value = computeMetricFromBreakdowns(
                                            allBreakdowns, metricExt, durationS, aliveTimeS, query.aggregation)
                                    end

                                    if query.columnMode == pivot.ColumnMode.METRICS then
                                        accumulate(acc, rowKey, metricId, value)
                                    elseif query.columnMode == pivot.Dimension.ENCOUNTER then
                                        accumulate(acc, rowKey, string.format("enc_%d_%d", se.instanceIndex, se.encounterIndex), value)
                                    elseif query.columnMode == pivot.Dimension.INSTANCE then
                                        accumulate(acc, rowKey, string.format("inst_%d", se.instanceIndex), value)
                                    end
                                end
                            end
                        end
                    else
                        -- Normal extraction: rows grouped by dimension within encounter
                        if query.columnMode == pivot.ColumnMode.METRICS
                            or query.columnMode == pivot.Dimension.ENCOUNTER
                            or query.columnMode == pivot.Dimension.INSTANCE then
                            local extracted = extractFromDecoded(query, decoded, abilityInfo, unitNames, durationS, metricIds)

                            for rowKey, metricValues in pairs(extracted) do
                                if query.columnMode == pivot.ColumnMode.METRICS then
                                    for _, mId in ipairs(metricIds) do
                                        accumulate(acc, rowKey, mId, metricValues[mId] or 0)
                                    end
                                elseif query.columnMode == pivot.Dimension.ENCOUNTER then
                                    accumulate(acc, rowKey, string.format("enc_%d_%d", se.instanceIndex, se.encounterIndex), metricValues[metricIds[1]] or 0)
                                else -- INSTANCE
                                    accumulate(acc, rowKey, string.format("inst_%d", se.instanceIndex), metricValues[metricIds[1]] or 0)
                                end
                            end
                        else
                            -- Cross-dimension: both rows and columns are data dimensions
                            local crossData = extractCrossDimension(
                                query, decoded, abilityInfo, unitNames, durationS, metricIds[1])

                            for rowKey, cols in pairs(crossData) do
                                for colKey, value in pairs(cols) do
                                    accumulate(acc, rowKey, colKey, value)
                                end
                            end
                        end
                    end
                end
            end
            -- Release decode before the next iteration (suspended Async keeps locals reachable).
            decoded = nil

            if onProgress then onProgress(idx, #scopedEncounters) end
        end

        return buildResult(acc, columnKeys, columnLabels, query.rowDimension, #scopedEncounters, query)
    end)
end

---Run a pivot query, dispatching to the appropriate pipeline
---@param query PivotQuery
---@param onProgress fun(current: number, total: number)|nil
---@return Effect -- resolves to PivotResult
function engine.runQueryAsync(query, onProgress)
    return Effect.Async(function()
        local scopedEncounters = engine.resolveScope(query.scope)

        if #scopedEncounters == 0 then
            return {
                rows = {},
                columns = {},
                columnLabels = {},
                rowDimensionLabel = extractors.getDimensionLabel(query.rowDimension),
                encounterCount = 0,
                query = query,
            }
        end

        if query.domain == pivot.Domain.GROUP then
            return engine.runGroupQuery(query, scopedEncounters, onProgress)
        else
            return engine.runDecodeQueryAsync(query, scopedEncounters, onProgress):Await()
        end
    end)
end
