-----------------------------------------------------------
-- Pivot Query State Management
-- Pure query mutation and inspection functions.
-- No UI dependencies — only references types.lua and extractors.lua.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local pivot = BattleScrolls.journal.pivot

local query = {}
pivot.query = query

---Strip metrics incompatible with Boss dimension in Group domain
---@param q PivotQuery
local function filterBossMetrics(q)
    if q.domain ~= pivot.Domain.GROUP then return end
    local hasBoss = q.rowDimension == pivot.Dimension.BOSS or q.columnMode == pivot.Dimension.BOSS
    if not hasBoss then return end
    local bossMetrics = pivot.extractors.GROUP_BOSS_METRICS
    local filtered = {}
    for _, m in ipairs(q.metrics) do
        if bossMetrics[m] then filtered[#filtered + 1] = m end
    end
    -- Ensure at least one metric remains
    if #filtered == 0 then
        filtered = { pivot.Metric.GROUP_DPS }
    end
    q.metrics = filtered
end

---Apply a field option selection to the query
---@param q PivotQuery
---@param fieldName string
---@param selectedKey any
function query.applyFieldSelection(q, fieldName, selectedKey)
    if fieldName == "instanceScope" then
        q.scope.instanceMode = selectedKey
    elseif fieldName == "timeFilter" then
        if selectedKey == "all" then
            q.scope.timeMode = pivot.TimeMode.ALL
            q.scope.timeFrom = nil
            q.scope.timeTo = nil
        elseif type(selectedKey) == "number" then
            q.scope.timeMode = pivot.TimeMode.CUSTOM
            if selectedKey == 0 then
                -- "Today": compute midnight
                local now = GetTimeStamp()
                local today = os.date("*t", now)
                today.hour, today.min, today.sec = 0, 0, 0
                q.scope.timeFrom = os.time(today)
            else
                q.scope.timeFrom = GetTimeStamp() - selectedKey * 86400
            end
            q.scope.timeTo = nil
        end
    elseif fieldName == "encounterFilter" then
        q.scope.encounterCategory = selectedKey
    elseif fieldName == "targets" then
        if selectedKey == pivot.TargetMode.ALL then
            q.targetMode = nil
        else
            q.targetMode = selectedKey
        end
    elseif fieldName == "domain" then
        q.domain = selectedKey
        q.targetMode = nil  -- reset target filter when domain changes
        -- Reset rows/columns/values to domain defaults (pick first two metrics)
        local metrics = pivot.DomainMetrics[selectedKey]
        q.rowDimension = pivot.Dimension.ENCOUNTER
        q.columnMode = pivot.ColumnMode.METRICS
        q.aggregation = nil  -- reset so updateAggregation picks new metric's default
        if metrics and #metrics >= 2 then
            q.metrics = { metrics[1], metrics[2] }
        elseif metrics and #metrics >= 1 then
            q.metrics = { metrics[1] }
        else
            q.metrics = {}
        end
    elseif fieldName == "rows" then
        q.rowDimension = selectedKey
        filterBossMetrics(q)
    elseif fieldName == "columns" then
        q.columnMode = selectedKey
        -- If switching from metrics to a dimension, keep only first metric
        if selectedKey ~= pivot.ColumnMode.METRICS and #q.metrics > 1 then
            q.metrics = { q.metrics[1] }
        end
        filterBossMetrics(q)
    elseif fieldName == "values" then
        local oldFirst = q.metrics[1]
        -- For multi-select (metrics mode), toggle the metric in the list (max 10)
        if q.columnMode == pivot.ColumnMode.METRICS then
            local found = false
            for i, m in ipairs(q.metrics) do
                if m == selectedKey then
                    -- Don't remove if it's the only metric
                    if #q.metrics > 1 then
                        table.remove(q.metrics, i)
                    end
                    found = true
                    break
                end
            end
            if not found and #q.metrics < 10 then
                table.insert(q.metrics, selectedKey)
            end
        else
            q.metrics = { selectedKey }
        end
        -- Reset aggregation when the primary metric changes (different default)
        if q.metrics[1] ~= oldFirst then
            q.aggregation = nil
        end
    elseif fieldName == "aggregation" then
        q.aggregation = selectedKey
    end
end

---Get the current value of a field from the query
---@param q PivotQuery
---@param fieldName string
---@return any
function query.getCurrentFieldValue(q, fieldName)
    if fieldName == "instanceScope" then return q.scope.instanceMode
    elseif fieldName == "timeFilter" then
        if q.scope.timeMode == pivot.TimeMode.ALL then return "all" end
        if q.scope.timeFrom then
            local daysAgo = math.floor((GetTimeStamp() - q.scope.timeFrom) / 86400)
            return daysAgo
        end
        return "all"
    elseif fieldName == "encounterFilter" then return q.scope.encounterCategory
    elseif fieldName == "targets" then return q.targetMode or pivot.TargetMode.ALL
    elseif fieldName == "domain" then return q.domain
    elseif fieldName == "rows" then return q.rowDimension
    elseif fieldName == "columns" then return q.columnMode
    elseif fieldName == "values" then return q.metrics[1]
    elseif fieldName == "aggregation" then return q.aggregation
    end
    return nil
end

---Update the query's aggregation field based on current state
---@param q PivotQuery
---@param scopedEncounterCount number
function query.updateAggregation(q, scopedEncounterCount)
    local rowIsEncounter = q.rowDimension == pivot.Dimension.ENCOUNTER
    local colIsEncounter = q.columnMode == pivot.Dimension.ENCOUNTER

    -- Aggregation needed when neither dimension provides per-encounter granularity.
    -- Instance is NOT per-encounter (it groups multiple encounters), so it needs aggregation.
    local needsAgg = scopedEncounterCount > 1 and not rowIsEncounter and not colIsEncounter

    -- Effects and Group domains always need aggregation: cells aggregate across
    -- multiple sources (group members, bosses, abilities, duplicate entries)
    if not needsAgg then
        local d = q.domain
        if d == pivot.Domain.EFFECTS_SELF or d == pivot.Domain.EFFECTS_BOSS
            or d == pivot.Domain.EFFECTS_GROUP or d == pivot.Domain.GROUP then
            needsAgg = true
        end
    end

    if needsAgg then
        if not q.aggregation then
            -- Set default based on first metric
            q.aggregation = pivot.extractors.getDefaultAggregation(q.metrics[1])
        end
    else
        q.aggregation = nil
    end
end
