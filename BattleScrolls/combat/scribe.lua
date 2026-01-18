-----------------------------------------------------------
-- Scribe
-- Encounter finalization and import for Battle Scrolls
--
-- Handles the transition from live combat state to stored
-- encounter data. Key responsibilities:
--   - Capture state snapshots at combat end
--   - Compute display names from damage data
--   - Encode encounters to binary format
--   - Push encounters to storage
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

-- =============================================================================
-- DISPLAY NAME COMPUTATION (for encounter list UI)
-- =============================================================================

---@class EnemyDamageInfo
---@field name string Enemy name
---@field damage number Total damage to this enemy type
---@field count number Number of unique enemy units with this name

---Gets the top enemies for an encounter by damage taken (used for display name)
---@param encounter Encounter The encounter with damage data
---@param unitNames table<number, string> Unit ID to name lookup
---@param maxCount number Maximum number of enemies to return
---@return string|nil result Formatted string like "Enemy1, Enemy2 (x2), Enemy3", or nil if no data
local function getTopEnemies(encounter, unitNames, maxCount)
    if not encounter.damageByUnitId then
        return nil
    end

    local computeTotal = BattleScrolls.arithmancer.ComputeDamageTotal
    -- Group damage by enemy name (formatted), iterating nested structure
    ---@type table<string, number>
    local damageByName = {}
    ---@type table<string, number>
    local countByName = {}
    ---@type table<number, boolean>
    local uniqueTargetIds = {}
    for _, byTarget in pairs(encounter.damageByUnitId) do
        for targetUnitId, dmg in pairs(byTarget) do
            local rawName = unitNames and unitNames[targetUnitId] or "Unknown"
            damageByName[rawName] = (damageByName[rawName] or 0) + computeTotal(dmg)
            if not uniqueTargetIds[targetUnitId] then
                uniqueTargetIds[targetUnitId] = true
                countByName[rawName] = (countByName[rawName] or 0) + 1
            end
        end
    end

    -- Convert to sortable array
    ---@type EnemyDamageInfo[]
    local enemies = {}
    for name, dmg in pairs(damageByName) do
        table.insert(enemies, { name = name, damage = dmg, count = countByName[name] })
    end

    -- Sort by damage descending
    table.sort(enemies, function(a, b)
        return a.damage > b.damage
    end)

    -- Take top N, but only include if damage is at least half of top-1
    -- Also limit total string length to ~50 characters
    local MAX_LENGTH = 50
    local result = {}
    local charCount = 0
    local topDamage = enemies[1] and enemies[1].damage or 0
    for i = 1, math.min(maxCount, #enemies) do
        local enemy = enemies[i]
        -- Only include if at least half of top damage (top-1 always included)
        if i == 1 or enemy.damage >= topDamage / 2 then
            -- Estimate length this enemy would add
            local nameLen = utf8.len(enemy.name) or #enemy.name
            local addLen = nameLen
            if enemy.count > 1 then
                addLen = addLen + 5 -- " (xN)"
            end
            if #result > 0 then
                addLen = addLen + 2 -- ", " separator
            end

            -- Stop if adding this would exceed limit (always include at least one)
            if charCount + addLen > MAX_LENGTH and #result > 0 then
                break
            end

            charCount = charCount + addLen
            if enemy.count > 1 then
                table.insert(result, zo_strformat(BATTLESCROLLS_ENCOUNTER_MULTIPLE_ENEMIES, enemy.name, enemy.count))
            else
                table.insert(result, zo_strformat(SI_UNIT_NAME, enemy.name))
            end
        end
    end

    return #result > 0 and ZO_GenerateCommaSeparatedListWithAnd(result) or nil
end

---Computes display name for an encounter (used for encounter list UI)
---@param encounter Encounter The encounter data
---@param unitNames table<number, string> Unit ID to name lookup
---@return string displayName The display name for the encounter
local function computeEncounterDisplayName(encounter, unitNames)
    -- Boss fights: just show boss name(s)
    if encounter.bossesUnits and #encounter.bossesUnits > 0 then
        local namesCount = {}
        for _, bossId in ipairs(encounter.bossesUnits) do
            local bossName = unitNames[bossId] or zo_strformat(BATTLESCROLLS_UNKNOWN)
            namesCount[bossName] = (namesCount[bossName] or 0) + 1
        end
        local names = {}
        for name, count in pairs(namesCount) do
            if count > 1 then
                table.insert(names, zo_strformat(BATTLESCROLLS_ENCOUNTER_MULTIPLE_ENEMIES, name, count))
            else
                table.insert(names, zo_strformat(SI_UNIT_NAME, name))
            end
        end

        return ZO_GenerateCommaSeparatedListWithAnd(names)
    end

    -- Non-boss fights: "Fight at {location} with {enemies}"
    local enemies = getTopEnemies(encounter, unitNames, 3)
    BattleScrolls.gc:RequestGC()
    local location = encounter.location

    if location and enemies then
        return zo_strformat(BATTLESCROLLS_ENCOUNTER_FIGHT_IN_WITH, location, enemies)
    elseif enemies then
        return zo_strformat(BATTLESCROLLS_ENCOUNTER_FIGHT_WITH, enemies)
    elseif location then
        return zo_strformat(BATTLESCROLLS_ENCOUNTER_FIGHT_IN, location)
    else
        return zo_strformat(BATTLESCROLLS_ENCOUNTER_COMBAT)
    end
end

---@class Scribe
---@field pushedToStorage boolean Whether the data has been pushed to storage
---@field instance InstanceStorage The current instance data (always compressed format)
---@field decodedAbilityInfo table<number, AbilityInfo> Decoded cache for active instance

---@type Scribe
local scribe = {
    pushedToStorage = false,
    instance = {
        zone = "",
        isOverland = true,
        timestampS = 0,
        encounters = {},
    },
    -- Decoded cache for active instance (kept in sync with instance._instanceData)
    decodedAbilityInfo = {},
}
BattleScrolls.scribe = scribe

function scribe:Initialize()
    -- Run initialization in async context so decode completes before OnPlayerActivated
    LibEffect.Async(function()
        -- Load instance from history or create new
        local history = BattleScrolls.storage.savedVariables.history
        if history and #history > 0 and history[#history].left == false then
            local lastInstance = history[#history]
            self.instance = lastInstance
            self.pushedToStorage = true
            -- Decode abilityInfo into cache (yields internally)
            local result = BattleScrolls.storage.DecodeInstanceFieldsAsync(lastInstance):Await()
            self.decodedAbilityInfo = result[1]
        else
            self:ResetForNewInstance()
        end

        -- Check zone after decode is complete
        self:OnPlayerActivated()

        -- Register events (can run even while async init is in progress)
        EVENT_MANAGER:RegisterForEvent("BattleScrolls_Scribe", EVENT_GROUPING_TOOLS_LFG_JOINED, function()
            self:ResetForNewInstance()
        end)

        EVENT_MANAGER:RegisterForEvent("BattleScrolls_Scribe", EVENT_PLAYER_ACTIVATED, function()
            self:OnPlayerActivated()
        end)

        EVENT_MANAGER:RegisterForEvent("BattleScrolls_Scribe", EVENT_PLAYER_COMBAT_STATE,
                function(_, inCombat)
                    if not inCombat then
                        self:WaitAndMaybeReset()
                    else
                        self.location = BattleScrolls.utils.MaybeLocationName()
                    end
                end)

        EVENT_MANAGER:RegisterForEvent("BattleScrolls_Scribe", EVENT_PLAYER_ALIVE, function()
            self:WaitAndMaybeReset()
        end)

        EVENT_MANAGER:RegisterForEvent("BattleScrolls_Scribe", EVENT_BOSSES_CHANGED, function()
            self:WaitAndMaybeReset()
        end)

        local mageArrivalAbilityId = 50184
        EVENT_MANAGER:RegisterForEvent("BattleScrolls_Scribe_Mage_Arrival", EVENT_EFFECT_CHANGED,
                function(_eventCode, _changeType, _effectSlot, _effectName, _unitTag, _beginTime, _endTime, _stackCount, _iconName, _buffType, _effectType, _abilityType, _statusEffectType, _unitName, _unitId, eventAbilityId, _sourceType)
                    -- Extra safety check for abilityId (also filtered at ESO level)
                    if eventAbilityId ~= mageArrivalAbilityId then
                        return
                    end
                    self:FinalizeEncounter()
                    BattleScrolls.state:ChangePlayerCombatState(true)
                end)
        EVENT_MANAGER:AddFilterForEvent("BattleScrolls_Scribe_Mage_Arrival", EVENT_EFFECT_CHANGED,
                REGISTER_FILTER_ABILITY_ID, mageArrivalAbilityId)

    end):Run()
end

---Unregisters all event handlers for cleanup/hot reload
function scribe:Cleanup()
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Scribe", EVENT_GROUPING_TOOLS_LFG_JOINED)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Scribe", EVENT_PLAYER_ACTIVATED)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Scribe", EVENT_PLAYER_COMBAT_STATE)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Scribe", EVENT_PLAYER_ALIVE)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Scribe", EVENT_BOSSES_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Scribe_Mage_Arrival", EVENT_EFFECT_CHANGED)
end

---Resets the scribe for a new instance
function scribe:ResetForNewInstance()
    self.left = true
    self.pushedToStorage = false
    -- Reset decoded cache
    self.decodedAbilityInfo = {}
    -- Determine zone type
    local isInstanced = CanExitInstanceImmediately()
    local isHouse = GetCurrentZoneHouseId() ~= 0
    local isPvP = IsPlayerInAvAWorld() or IsActiveWorldBattleground()

    -- Create new instance (no raw abilityInfo/unitNames - always use compressed format)
    ---@type InstanceStorage
    self.instance = {
        zone = BattleScrolls.utils.FormattedZoneName(),
        isOverland = not isInstanced,
        isHouse = isHouse,
        isPvP = isPvP,
        left = false,
        timestampS = GetTimeStamp(),
        encounters = {},
        -- _instanceData and _instanceBits will be set after first encounter
    }
    self.location = BattleScrolls.utils.MaybeLocationName()
    -- GC after replacing instance (old instance/caches discarded, nothing important happening)
    BattleScrolls.gc:RequestGC(2)
end

function scribe:OnPlayerActivated()
    if self.instance.zone ~= BattleScrolls.utils.FormattedZoneName() then
        if BattleScrolls.state:ShouldReset() then
            self:FinalizeEncounter()
        end
        self:ResetForNewInstance()
    end
end

function scribe:FinalizeEncounter()
    self:ImportEncounterFromStateAsync()
    BattleScrolls.state:Reset()
end

function scribe:WaitAndMaybeReset()
    zo_callLater(function()
        if BattleScrolls.state:ShouldReset() then
            self:FinalizeEncounter()
        end
    end, 150)
end

---Import encounter from state asynchronously
---Captures references to state data immediately so state can be reset after this call
function scribe:ImportEncounterFromStateAsync()
    local state = BattleScrolls.state

    if not state.initialized then
        return
    end

    -- Check recording settings (sync, quick checks before async work)
    local settings = BattleScrolls.storage.savedVariables.settings
    local defaults = BattleScrolls.storage.defaults.settings

    -- Global recording toggle
    if settings and settings.recordingEnabled == false then return end

    -- Zone filter: set of zone types
    local recordInZones = settings and settings.recordInZones or defaults.recordInZones
    -- Determine current zone type (priority: house > pvp > instanced/overland)
    local currentZoneType
    if self.instance.isHouse then
        currentZoneType = "house"
    elseif self.instance.isPvP then
        currentZoneType = "pvp"
    elseif self.instance.isOverland then
        currentZoneType = "overland"
    else
        currentZoneType = "instanced"
    end
    if not recordInZones[currentZoneType] then return end

    -- Fight filter: set of fight types
    local recordInFights = settings and settings.recordInFights or defaults.recordInFights
    -- Determine current fight type (priority: dummy > player > boss > trash)
    local currentFightType
    if state.isDummyFight then
        currentFightType = "dummy"
    elseif state.isPlayerFight then
        currentFightType = "player"
    elseif state.isBossFight then
        currentFightType = "boss"
    else
        currentFightType = "trash"
    end
    if not recordInFights[currentFightType] then return end

    -- Capture references to state data (state:Reset() creates new tables, doesn't modify old ones)
    local capturedLocation = self.location
    ---@type BattleScrollsState|nil
    local capturedState = BattleScrolls.state:Snapshot()
    local capturedPushedToStorage = self.pushedToStorage

    ---@class RawToDisplayEntry
    ---@field displayName string The display name for this unit
    ---@field isRaw boolean Whether the original name was raw (unformatted)

    -- Build rawToDisplay lookup (sync, small data from current group)
    ---@type table<string, RawToDisplayEntry>|nil
    local rawToDisplay = {}
    ---@type string[]
    local unitTags = { "player" }
    for i = 1, MAX_GROUP_SIZE_THRESHOLD do
        table.insert(unitTags, ZO_Group_GetUnitTagForGroupIndex(i))
    end
    for _, unitTag in ipairs(unitTags) do
        local rawName = GetRawUnitName(unitTag)
        local displayName = BattleScrolls.utils.GetUndecoratedDisplayName(unitTag)
        if rawName and rawName ~= "" and displayName and displayName ~= "" then
            local formattedName = zo_strformat(SI_UNIT_NAME, rawName)
            local isRaw = rawName ~= formattedName
            rawToDisplay[rawName] = { displayName = displayName, isRaw = isRaw }
            rawToDisplay[formattedName] = { displayName = displayName, isRaw = isRaw }
        end
    end

    local instance = self.instance
    local decodedAbilityInfo = self.decodedAbilityInfo

    return LibEffect.Async(function()
        -- Finalize any active effects on the state snapshot
        -- (effects are now processed synchronously, no queue to drain)
        BattleScrolls.effects.finalize(capturedState)
        LibEffect.YieldWithGC():Await()

        -- Merge abilityInfo into decoded cache (trivial table assignments, no yield needed)
        for abilityId, info in pairs(capturedState.abilityInfo) do
            decodedAbilityInfo[abilityId] = info
        end

        -- Replace raw names with display names in captured state
        for unitId, name in pairs(capturedState.unitIdToName) do
            local formattedName = zo_strformat(SI_UNIT_NAME, name)
            local entry = rawToDisplay[name] or rawToDisplay[formattedName]
            if entry then
                capturedState.unitIdToName[unitId] = entry.displayName
            end
        end
        rawToDisplay = nil  -- Allow GC
        LibEffect.YieldWithGC():Await()


        -- Build alive times from captured state
        local durationMs = capturedState.lastDamageDoneMs - capturedState.fightStartTimeMs
        local playerAliveTimeMs = BattleScrolls.effects.getPlayerAliveTime(capturedState, durationMs)
        local unitAliveTimeMs = BattleScrolls.effects.getUnitAliveTimes(capturedState)

        -- Build encounter object
        ---@type Encounter
        local encounter = {
            location = capturedLocation,
            timestampS = capturedState.fightStartRealTimeS,
            durationMs = durationMs,
            bossesUnits = {},
            damageByUnitId = capturedState.damageByUnitId,
            damageByUnitIdGroup = capturedState.damageByUnitIdGroup,
            damageTakenByUnitId = capturedState.damageTakenByUnitId,
            healingStats = capturedState.healingStats,
            procs = {},
            effectsOnPlayer = capturedState.effectsOnPlayer,
            effectsOnBosses = capturedState.effectsOnBosses,
            effectsOnGroup = capturedState.effectsOnGroup,
            bossNames = next(capturedState.bossNames) and capturedState.bossNames or nil,
            isPlayerFight = capturedState.isPlayerFight or nil, -- nil if false to save storage
            isDummyFight = capturedState.isDummyFight or nil,   -- nil if false to save storage
            playerAliveTimeMs = playerAliveTimeMs ~= durationMs and playerAliveTimeMs or nil,
            unitAliveTimeMs = next(unitAliveTimeMs) and unitAliveTimeMs or nil,
        }

        -- Build boss list
        if capturedState.isBossFight then
            for unitId in pairs(capturedState.bossesByUnitId) do
                table.insert(encounter.bossesUnits, unitId)
            end
        end
        LibEffect.YieldWithGC():Await()

        -- Process procs (yields per ability)
        for abilityId, events in pairs(capturedState.procs) do
            if #events > 0 then
                -- Group by enemy
                local countsByEnemy = {}
                for _, event in ipairs(events) do
                    countsByEnemy[event.targetUnitId] = (countsByEnemy[event.targetUnitId] or 0) + 1
                end

                local procsByEnemy = {}
                for unitId, count in pairs(countsByEnemy) do
                    table.insert(procsByEnemy, { unitId = unitId, procCount = count })
                end

                -- Calculate intervals
                local meanIntervalMs, medianIntervalMs = 0, 0
                if #events > 1 then
                    local intervals = {}
                    for i = 2, #events do
                        table.insert(intervals, events[i].timestampMs - events[i - 1].timestampMs)
                    end
                    meanIntervalMs = math.ceil((events[#events].timestampMs - events[1].timestampMs) / #intervals - 0.5)
                    medianIntervalMs = math.ceil(BattleScrolls.utils.median(intervals) - 0.5)
                end

                table.insert(encounter.procs, {
                    abilityId = abilityId,
                    totalProcs = #events,
                    procsByEnemy = procsByEnemy,
                    meanIntervalMs = meanIntervalMs,
                    medianIntervalMs = medianIntervalMs,
                })
            end
            LibEffect.YieldWithGC():Await()
        end

        -- Collect unitNames used in this encounter from captured state (v7+: stored per-encounter)
        -- Must happen before capturedState is cleared for GC
        encounter.unitNames = capturedState.unitIdToName

        -- Compute display name using only this encounter's unit names
        encounter.displayName = computeEncounterDisplayName(encounter, encounter.unitNames)

        capturedState = nil  -- Allow GC
        LibEffect.YieldWithGC():Await()

        -- Encode encounter to compact format and add to instance
        local compactEncounter = BattleScrolls.storage.EncodeEncounterAsync(encounter):Await()
        LibEffect.YieldWithGC():Await()

        -- Re-encode instance fields (abilityInfo only, unitNames now per-encounter)
        -- This ensures SavedVariables always has consistent compressed data
        local encodedFields = BattleScrolls.binaryStorage.EncodeInstanceFieldsAsync(
            decodedAbilityInfo):Await()
        -- No yield between setting fields and inserting encounter to make
        -- sure it's atomic
        instance._instanceData = encodedFields._instanceData
        instance._instanceBits = encodedFields._instanceBits
        table.insert(instance.encounters, compactEncounter)
        -- Invalidate cached size since instance data changed
        instance._estimatedSize = nil
        LibEffect.YieldWithGC():Await()

        -- Push instance to storage on first encounter
        if not capturedPushedToStorage then
            BattleScrolls.storage:PushInstance(instance)
            if instance == self.instance then
                self.pushedToStorage = true
            end
        end

        -- GC after encoding (generates significant garbage, nothing important happening now)
        BattleScrolls.gc:RequestGC(2)
        BattleScrolls.storage:CleanupIfNecessaryAsync()
    end):Run()
end
