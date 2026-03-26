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

-- =============================================================================
-- ENCOUNTER SHARE MATCHING
-- =============================================================================

local MATCH_WINDOW_TOLERANCE_S = 5
local RECENT_INSTANCE_CUTOFF_S = 3600

---@class PendingEncounterEntry
---@field startS number Fight start timestamp (real time seconds)
---@field endS number Fight end timestamp (real time seconds)
---@field sharedData SharedDataEntry[]|nil Shared data matched while encoding

---@type PendingEncounterEntry[]
local pendingEncounters = {}

---@class DiscardedEncounterSink
---@field startS number Fight start timestamp (real time seconds)
---@field endS number Fight end timestamp (real time seconds)

--- Lightweight time ranges for encounters discarded by recording filters.
--- Participates in matchShare overlap so shared data from group members
--- is absorbed here instead of incorrectly matching a nearby recorded encounter.
---@type DiscardedEncounterSink[]
local discardedSinks = {}

---Compute time overlap between two time ranges
---@param startA number Start of range A (seconds)
---@param endA number End of range A (seconds)
---@param startB number Start of range B (seconds)
---@param endB number End of range B (seconds)
---@return number overlap Overlap in seconds (negative if no overlap)
local function computeOverlap(startA, endA, startB, endB)
    local overlapStart = math.max(startA, startB)
    local overlapEnd = math.min(endA, endB)
    return overlapEnd - overlapStart
end

---Attempt to match shared data to an existing encounter
---Uses time overlap across all candidates (live combat, stored history, pending encoding)
---@param unitTag string Sender's unit tag
---@param sharedData SharedEncounterData Reconstructed encounter data
local function matchShare(unitTag, sharedData)
    local displayName = BattleScrolls.utils.GetUndecoratedDisplayName(unitTag)
    if not displayName or displayName == "" then
        return
    end

    local sharedStart = sharedData.timestampS - MATCH_WINDOW_TOLERANCE_S
    local sharedEnd = sharedData.timestampS + sharedData.durationMs / 1000 + MATCH_WINDOW_TOLERANCE_S

    local bestOverlap = 0
    ---@type "live"|"stored"|"pending"|"discarded"|nil
    local bestType = nil
    ---@type CompactEncounter|PendingEncounterEntry|nil
    local bestTarget = nil

    -- Check live combat
    local state = BattleScrolls.state
    if state.inCombat and state.initialized then
        local localStart = state.fightStartRealTimeS - MATCH_WINDOW_TOLERANCE_S
        local localEnd = GetTimeStamp() + MATCH_WINDOW_TOLERANCE_S
        local overlap = computeOverlap(sharedStart, sharedEnd, localStart, localEnd)
        if overlap > bestOverlap then
            bestOverlap = overlap
            bestType = "live"
            bestTarget = nil
        end
    end

    -- Check stored history
    local history = BattleScrolls.storage.savedVariables.history
    if history then
        local now = GetTimeStamp()
        local cutoff = now - RECENT_INSTANCE_CUTOFF_S
        local scannedPastCutoff = false

        for i = #history, 1, -1 do
            local instance = history[i]

            -- Stop after scanning one instance beyond the cutoff
            if instance.timestampS < cutoff then
                if scannedPastCutoff then
                    break
                end
                scannedPastCutoff = true
            end

            for _, enc in ipairs(instance.encounters) do
                local localStart = enc.timestampS - MATCH_WINDOW_TOLERANCE_S
                local localEnd = enc.timestampS + enc.durationMs / 1000 + MATCH_WINDOW_TOLERANCE_S
                local overlap = computeOverlap(sharedStart, sharedEnd, localStart, localEnd)
                if overlap > bestOverlap then
                    bestOverlap = overlap
                    bestType = "stored"
                    bestTarget = enc
                end
            end
        end
    end

    -- Check pending encounters (currently being encoded)
    for _, pending in ipairs(pendingEncounters) do
        local localStart = pending.startS - MATCH_WINDOW_TOLERANCE_S
        local localEnd = pending.endS + MATCH_WINDOW_TOLERANCE_S
        local overlap = computeOverlap(sharedStart, sharedEnd, localStart, localEnd)
        if overlap > bestOverlap then
            bestOverlap = overlap
            bestType = "pending"
            bestTarget = pending
        end
    end

    -- Check discarded encounter sinks (absorb shared data for encounters we chose not to record)
    local sinkCutoff = GetTimeStamp() - RECENT_INSTANCE_CUTOFF_S
    for i = #discardedSinks, 1, -1 do
        local sink = discardedSinks[i]
        if sink.endS < sinkCutoff then
            table.remove(discardedSinks, i)
        else
            local localStart = sink.startS - MATCH_WINDOW_TOLERANCE_S
            local localEnd = sink.endS + MATCH_WINDOW_TOLERANCE_S
            local overlap = computeOverlap(sharedStart, sharedEnd, localStart, localEnd)
            if overlap > bestOverlap then
                bestOverlap = overlap
                bestType = "discarded"
                bestTarget = nil
            end
        end
    end

    ---@type SharedDataEntry
    local entry = {
        displayName = displayName,
        data = sharedData,
        role = BattleScrolls.utils.getUnitRole(unitTag),
    }

    -- Apply match
    local matched = false
    if bestType == "live" then
        state.pendingSharedData = state.pendingSharedData or {}
        table.insert(state.pendingSharedData, entry)
        matched = true
        -- BattleScrolls.log.Debug(function()
        --     return string.format("EncounterShare: matched %s to live combat", displayName)
        -- end)
    elseif bestType == "discarded" then
        -- Intentionally dropped: this shared data belongs to an encounter we chose not to record
        -- BattleScrolls.log.Debug(function()
        --     return string.format("EncounterShare: absorbed %s into discarded sink", displayName)
        -- end)
    elseif bestTarget then
        bestTarget.sharedData = bestTarget.sharedData or {}
        table.insert(bestTarget.sharedData, entry)
        matched = true
        -- BattleScrolls.log.Debug(function()
        --     return string.format("EncounterShare: matched %s to %s encounter (ts=%d)",
        --         displayName, bestType, bestTarget.timestampS or bestTarget.startS)
        -- end)
    end

    -- Request full setup only if the share was matched to a real encounter
    if matched and sharedData.setupHash then
        local setupShareModule = BattleScrolls.setupShare
        if setupShareModule then
            setupShareModule:onEncounterHashReceived(displayName, sharedData.setupHash)
        end
    end
end

---Remove a pending encounter entry from the list
---@param entry PendingEncounterEntry
local function removePendingEncounter(entry)
    for i = #pendingEncounters, 1, -1 do
        if pendingEncounters[i] == entry then
            table.remove(pendingEncounters, i)
            return
        end
    end
end

---Record a discarded encounter's time range so matchShare can absorb shared data for it
---@param entry PendingEncounterEntry
local function addDiscardedSink(entry)
    table.insert(discardedSinks, {
        startS = entry.startS,
        endS = entry.endS,
    })
end

function scribe:Initialize()
    -- Register callback for incoming encounter share data
    BattleScrolls.encounterShare:RegisterCallback("scribe", matchShare)

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
    self.instance.left = true
    self.pushedToStorage = false
    -- Reset decoded cache
    self.decodedAbilityInfo = {}
    -- Determine zone type
    local isInstanced = CanExitInstanceImmediately()
    local isHouse = GetCurrentZoneHouseId() ~= 0
    local isPvP = IsPlayerInAvAWorld() or IsActiveWorldBattleground()
    local isAdventureZone = IsInAdventureZone and IsInAdventureZone() or false

    -- Create new instance (no raw abilityInfo/unitNames - always use compressed format)
    ---@type InstanceStorage
    self.instance = {
        zone = BattleScrolls.utils.FormattedZoneName(),
        isOverland = not isInstanced,
        isHouse = isHouse,
        isPvP = isPvP,
        isAdventureZone = isAdventureZone,
        left = false,
        timestampS = GetTimeStamp(),
        encounters = {},
        -- _instanceData will be set after first encounter
    }
    self.location = BattleScrolls.utils.MaybeLocationName()
    -- GC after replacing instance (old instance/caches discarded, nothing important happening)
    BattleScrolls.gc:RequestGC(2)
end

---Called by storage when an instance is removed from history
---Resets scribe if the removed instance is the active one to prevent orphaned encounters
---@param instance Instance The instance that was removed
function scribe:OnInstanceRemoved(instance)
    if self.instance == instance then
        self:ResetForNewInstance()
    end
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

    -- Capture references to state data (state:Reset() creates new tables, doesn't modify old ones)
    local capturedLocation = self.location
    ---@type BattleScrollsState|nil
    local capturedState = BattleScrolls.state:Snapshot()
    local capturedPushedToStorage = self.pushedToStorage

    ---@class RawToDisplayEntry
    ---@field displayName string The display name for this unit
    ---@field isRaw boolean Whether the original name was raw (unformatted)

    -- Build rawToDisplay lookup (sync, small data from current group)
    ---@type table<string, RawToDisplayEntry>
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

    -- Register pending encounter so matchShare can find it during the encoding window
    local durationMs = capturedState.lastDamageDoneMs - capturedState.fightStartTimeMs
    ---@type PendingEncounterEntry
    local pendingEntry = {
        startS = capturedState.fightStartRealTimeS,
        endS = capturedState.fightStartRealTimeS + durationMs / 1000,
    }
    table.insert(pendingEncounters, pendingEntry)

    return LibEffect.Async(function()
        -- Finalize active effects on the state snapshot (moderate: up to ~600 effects)
        -- Pass lastDamageDoneMs so effect uptimes are consistent with fight duration
        BattleScrolls.effects.finalize(capturedState, capturedState.lastDamageDoneMs)
        LibEffect.YieldWithGC():Await()

        local playerAliveTimeMs = math.min(
            BattleScrolls.effects.getPlayerAliveTime(capturedState, durationMs), durationMs)
        local unitAliveTimeMs = BattleScrolls.effects.getUnitAliveTimes(capturedState)

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
            isPlayerFight = capturedState.isPlayerFight or nil,
            isDummyFight = capturedState.isDummyFight or nil,
            playerAliveTimeMs = playerAliveTimeMs ~= durationMs and playerAliveTimeMs or nil,
            unitAliveTimeMs = next(unitAliveTimeMs) and unitAliveTimeMs or nil,
        }

        -- Capture death recaps
        local deathCount = capturedState.playerDeathCount or 0
        if deathCount > 0 then
            local recaps = {}
            for _, snap in ipairs(capturedState.deathRecaps or {}) do
                recaps[#recaps + 1] = { timeOffsetMs = snap.timeMs, attacks = snap.attacks }
            end
            encounter.deaths = { deathCount = deathCount, recaps = recaps }
        end

        encounter.setup = capturedState.playerSetup
        if encounter.setup and capturedState.effectsOnPlayer then
            BattleScrolls.setupCapture.finalizeEffectData(encounter.setup, capturedState.effectsOnPlayer)
        end

        local bossTagSeqByUnitId = nil
        if capturedState.isBossFight then
            bossTagSeqByUnitId = {}
            for unitId, boss in pairs(capturedState.bossesByUnitId) do
                if not capturedState.bossUnitIdRedirects[unitId] then
                    table.insert(encounter.bossesUnits, unitId)
                    bossTagSeqByUnitId[unitId] = boss.unitTag .. ":" .. boss.tagSeq
                end
            end
            encounter.bossTagSeqByUnitId = bossTagSeqByUnitId
        end

        -- Compute setup hash for sharing (before send, after setup finalization)
        local setupHash = nil
        if encounter.setup then
            local setupShareModule = BattleScrolls.setupShare
            if setupShareModule then
                local compact = setupShareModule.convertToCompact(encounter.setup)
                setupHash = setupShareModule.computeHash(compact)
                setupShareModule:cacheLocalSetup(setupHash, compact)
                local localName = BattleScrolls.utils.GetUndecoratedDisplayName()
                setupShareModule:storeSetup(localName, setupHash, compact)
            end
        end

        -- Send encounter data to group members (always, regardless of recording settings)
        local arithmancer = BattleScrolls.arithmancer:Make(encounter, capturedState.abilityInfo)
        local sharedData = arithmancer:buildSharedEncounterData()
        BattleScrolls.encounterShare:send(sharedData, encounter.timestampS, setupHash)

        -- Check recording settings (sharing already happened above)
        local settings = BattleScrolls.storage.savedVariables.settings
        local defaults = BattleScrolls.storage.defaults.settings

        if settings and settings.recordingEnabled == false then
            addDiscardedSink(pendingEntry)
            return
        end

        local recordInAdventureZone = settings and settings.recordInAdventureZone or defaults.recordInAdventureZone
        local recordInZones = settings and settings.recordInZones or defaults.recordInZones
        local currentZoneType
        if instance.isHouse then
            currentZoneType = "house"
        elseif instance.isPvP then
            currentZoneType = "pvp"
        elseif instance.isOverland then
            currentZoneType = "overland"
        else
            currentZoneType = "instanced"
        end
        if instance.isAdventureZone and recordInAdventureZone then
            -- Adventure zone override: skip zone type check
        elseif not recordInZones[currentZoneType] then
            addDiscardedSink(pendingEntry)
            return
        end

        local recordInFights = settings and settings.recordInFights or defaults.recordInFights
        local currentFightType
        if capturedState.isDummyFight then
            currentFightType = "dummy"
        elseif capturedState.isPlayerFight then
            currentFightType = "player"
        elseif capturedState.isBossFight then
            currentFightType = "boss"
        else
            currentFightType = "trash"
        end
        if not recordInFights[currentFightType] then
            addDiscardedSink(pendingEntry)
            return
        end

        -- Recording-only: merge abilityInfo, replace raw names with display names
        for abilityId, info in pairs(capturedState.abilityInfo) do
            decodedAbilityInfo[abilityId] = info
        end

        for unitId, name in pairs(capturedState.unitIdToName) do
            local formattedName = zo_strformat(SI_UNIT_NAME, name)
            local entry = rawToDisplay[name] or rawToDisplay[formattedName]
            if entry then
                capturedState.unitIdToName[unitId] = entry.displayName
            end
        end

        for abilityId, events in pairs(capturedState.procs) do
            if #events > 0 then
                local countsByEnemy = {}
                for _, event in ipairs(events) do
                    countsByEnemy[event.targetUnitId] = (countsByEnemy[event.targetUnitId] or 0) + 1
                end

                local procsByEnemy = {}
                for unitId, count in pairs(countsByEnemy) do
                    table.insert(procsByEnemy, { unitId = unitId, procCount = count })
                end

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
        end

        encounter.unitNames = capturedState.unitIdToName
        encounter.displayName = computeEncounterDisplayName(encounter, encounter.unitNames)

        -- Build bossSeqNames mapping for cross-client boss identification (reuses bossTagSeqByUnitId built earlier)
        if bossTagSeqByUnitId then
            local bossSeqNames = {}
            for unitId, key in pairs(bossTagSeqByUnitId) do
                local name = encounter.unitNames[unitId]
                if name then bossSeqNames[key] = name end
            end
            if next(bossSeqNames) then
                encounter.bossSeqNames = bossSeqNames
            end
        end

        -- Extract shared data received during live combat before releasing snapshot
        local capturedPendingSharedData = capturedState.pendingSharedData
        capturedState = nil
        LibEffect.YieldWithGC():Await()

        -- Encode encounter to binary (yields internally based on data volume)
        local compactEncounter = BattleScrolls.storage.EncodeEncounterAsync(encounter):Await()

        -- Re-encode instance fields (yields internally based on data volume)
        local encodedFields = BattleScrolls.binaryStorage.encodeInstanceFieldsAsync(
            decodedAbilityInfo):Await()
        -- Atomic: set fields and insert encounter together
        instance._instanceData = encodedFields._instanceData
        table.insert(instance.encounters, compactEncounter)
        instance._estimatedSize = nil

        LibEffect.YieldWithGC():Await()

        -- Transfer shared data from live combat and pending queue to the compact encounter
        local allShared = capturedPendingSharedData
        if pendingEntry.sharedData then
            allShared = allShared or {}
            for _, shared in ipairs(pendingEntry.sharedData) do
                table.insert(allShared, shared)
            end
        end
        if allShared then
            compactEncounter.sharedData = allShared
        end

        -- Remove pending entry now that the encounter is stored and shared data transferred
        removePendingEncounter(pendingEntry)

        if not capturedPushedToStorage then
            BattleScrolls.storage:PushInstance(instance)
            if instance == self.instance then
                self.pushedToStorage = true
            end
        end

        BattleScrolls.gc:RequestGC(2)
        BattleScrolls.storage:CleanupIfNecessaryAsync()
    end):Ensure(function()
        -- Safety net: remove pending entry if async chain errors or is cancelled
        removePendingEncounter(pendingEntry)
    end):Run()
end
