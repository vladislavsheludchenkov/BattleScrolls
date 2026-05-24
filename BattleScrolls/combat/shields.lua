if not SemisPlaygroundCheckAccess() then
    return
end

-- Damage shield tracking for healing attribution.
-- Shield applications are raw healing, shield absorbs are effective healing,
-- and the remaining unapplied value stays as overheal.

BattleScrolls = BattleScrolls or {}

---@class PendingShieldDelta
---@field delta number
---@field arrivedAtMs number

---@class PendingShieldEffect
---@field abilityId number
---@field targetName string
---@field targetUnitId number
---@field targetType number
---@field sourceType number
---@field arrivedAtMs number

---@class PendingShieldCombatGain
---@field abilityId number
---@field sourceName string
---@field sourceUnitId number
---@field sourceType number
---@field targetName string
---@field targetUnitId number
---@field targetType number
---@field arrivedAtMs number

---@class PendingShieldAttributeBlock
---@field targetName string
---@field targetUnitId number
---@field arrivedAtMs number

---@class ActiveShieldInstance
---@field sourceUnitId number
---@field targetUnitId number
---@field sourceType number
---@field targetType number
---@field appliedAtMs number
---@field remaining number
---@field creditable boolean

---@class BattleScrollsShields : StateObserver
local shields = {}
BattleScrolls.shields = shields

local PENDING_EVENT_WINDOW_MS = 250
local PATTERN_GROUP = "^group"
local INFERRED_PLAYER_UNIT_ID = BattleScrolls.constants.INFERRED_PLAYER_UNIT_ID
local INFERRED_COMPANION_UNIT_ID = BattleScrolls.constants.INFERRED_COMPANION_UNIT_ID

local FALLBACK_SELF_SHIELD_ABILITY_IDS = {
    [201265] = true, -- Pragmatic Fatecarver
}

local INFERRED_SOURCE_UNIT_ID_BY_TYPE = {
    [COMBAT_UNIT_TYPE_PLAYER] = INFERRED_PLAYER_UNIT_ID,
    [COMBAT_UNIT_TYPE_PLAYER_COMPANION] = INFERRED_COMPANION_UNIT_ID,
}

---@type table<string, number>
local shieldTotalsByTag = {}

---@type table<string, PendingShieldDelta[]>
local pendingDeltaByName = {}

---@type PendingShieldEffect[]
local pendingShieldEffects = {}

---@type PendingShieldCombatGain[]
local pendingCombatGains = {}

---@type PendingShieldAttributeBlock[]
local pendingAttributeBlocks = {}

---@type table<number, boolean>
local damageShieldAbilityById = {
    [201265] = true,
}

---@type table<number, table<number, ActiveShieldInstance[]>>
local activeShields = {}

---@type string[]
local visualEventNames = {}

---@type string[]
local combatEventNames = {}

---@type table<number, boolean>
local personalTypesSet = BattleScrolls.constants.personalTypesSet

local function clearTracking()
    shieldTotalsByTag = {}
    pendingDeltaByName = {}
    pendingShieldEffects = {}
    pendingCombatGains = {}
    pendingAttributeBlocks = {}
    activeShields = {}
end

---@param abilityId number
---@param abilityType number
local function rememberAbilityType(abilityId, abilityType)
    if abilityId and abilityId > 0 then
        if abilityType == ABILITY_TYPE_DAMAGESHIELD then
            damageShieldAbilityById[abilityId] = true
        elseif damageShieldAbilityById[abilityId] == nil then
            damageShieldAbilityById[abilityId] = false
        end
    end
end

---@param abilityId number
---@return boolean
local function isFallbackSelfShieldAbility(abilityId)
    return FALLBACK_SELF_SHIELD_ABILITY_IDS[abilityId] == true
end

---@param sourceType number
---@return boolean
local function isInferableSourceType(sourceType)
    return INFERRED_SOURCE_UNIT_ID_BY_TYPE[sourceType] ~= nil
end

---@param sourceType number
---@return string
local function getInferredSourceName(sourceType)
    if sourceType == COMBAT_UNIT_TYPE_PLAYER then
        return GetRawUnitName("player") or ""
    end
    if sourceType == COMBAT_UNIT_TYPE_PLAYER_COMPANION then
        return GetRawUnitName("companion") or ""
    end
    return ""
end

---@param toQueue ActiveShieldInstance[]
---@param fromQueue ActiveShieldInstance[]
local function mergeActiveShieldQueue(toQueue, fromQueue)
    for _, instance in ipairs(fromQueue) do
        toQueue[#toQueue + 1] = instance
    end
    table.sort(toQueue, function(a, b)
        return a.appliedAtMs < b.appliedAtMs
    end)
end

---@param fromUnitId number
---@param toUnitId number
local function retconActiveShieldUnitId(fromUnitId, toUnitId)
    if fromUnitId == toUnitId then return end

    local fromByAbility = activeShields[fromUnitId]
    if fromByAbility then
        local toByAbility = activeShields[toUnitId]
        if not toByAbility then
            activeShields[toUnitId] = fromByAbility
        else
            for abilityId, fromQueue in pairs(fromByAbility) do
                local toQueue = toByAbility[abilityId]
                if toQueue then
                    mergeActiveShieldQueue(toQueue, fromQueue)
                else
                    toByAbility[abilityId] = fromQueue
                end
            end
        end
        activeShields[fromUnitId] = nil
    end

    for _, byAbility in pairs(activeShields) do
        for _, queue in pairs(byAbility) do
            for _, instance in ipairs(queue) do
                if instance.sourceUnitId == fromUnitId then
                    instance.sourceUnitId = toUnitId
                end
                if instance.targetUnitId == fromUnitId then
                    instance.targetUnitId = toUnitId
                end
            end
        end
    end
end

---@param state BattleScrollsState
---@param sourceType number
---@param realUnitId number
---@param name string
local function rememberRealSourceUnitId(state, sourceType, realUnitId, name)
    local inferredUnitId = INFERRED_SOURCE_UNIT_ID_BY_TYPE[sourceType]
    if not inferredUnitId or realUnitId <= 0 or not name or name == "" then return end

    state:RememberPersonalUnitIdentity(sourceType, realUnitId, name)
end

---@param unitType number
---@param previousUnitId number|nil
---@param unitId number
function shields:OnPersonalUnitIdentityChanged(unitType, previousUnitId, unitId)
    if not isInferableSourceType(unitType)
        or not previousUnitId
        or not unitId
        or previousUnitId <= 0
        or unitId <= 0
        or previousUnitId == unitId then
        return
    end

    retconActiveShieldUnitId(previousUnitId, unitId)
end

---@param state BattleScrollsState
---@param sourceType number
---@param targetType number
---@param targetUnitId number
---@return number
local function getInferredSourceUnitId(state, sourceType, targetType, targetUnitId)
    if sourceType == COMBAT_UNIT_TYPE_PLAYER and targetType == COMBAT_UNIT_TYPE_PLAYER and targetUnitId > 0 then
        rememberRealSourceUnitId(state, sourceType, targetUnitId, GetRawUnitName("player") or "")
        return targetUnitId
    end

    return state:GetPersonalUnitId(sourceType) or INFERRED_SOURCE_UNIT_ID_BY_TYPE[sourceType] or 0
end

---@param unitType number
---@param unitId number
---@param name string
function shields:RememberUnitIdentity(unitType, unitId, name)
    local state = BattleScrolls.state
    if not state or not state.initialized then return end
    if not isInferableSourceType(unitType) then return end

    rememberRealSourceUnitId(state, unitType, unitId, name)
end

---@type fun(nowMs: number)|nil
local tryProcessPendingApplications

---@param unitTag string
---@return boolean
local function isTrackedUnitTag(unitTag)
    if unitTag == "player" then return true end
    if AreUnitsEqual and AreUnitsEqual("player", unitTag) then return false end
    if unitTag:find(PATTERN_GROUP) then
        return not (IsGroupCompanionUnitTag and IsGroupCompanionUnitTag(unitTag))
    end
    return false
end

---@param targetType number
---@return boolean
local function isTrackedTargetType(targetType)
    return targetType == COMBAT_UNIT_TYPE_PLAYER
        or targetType == COMBAT_UNIT_TYPE_GROUP
end

---@param unitTag string
---@return number|nil
local function getTargetTypeForUnitTag(unitTag)
    if unitTag == "player" then return COMBAT_UNIT_TYPE_PLAYER end
    if AreUnitsEqual and AreUnitsEqual("player", unitTag) then return nil end
    if unitTag:find(PATTERN_GROUP) then return COMBAT_UNIT_TYPE_GROUP end
    return nil
end

---@param name string
---@param nowMs number
---@return PendingShieldDelta[]|nil
local function prunePendingDeltas(name, nowMs)
    local queue = pendingDeltaByName[name]
    if not queue then return nil end

    local writeIndex = 1
    for i = 1, #queue do
        local entry = queue[i]
        if entry and nowMs - entry.arrivedAtMs <= PENDING_EVENT_WINDOW_MS then
            queue[writeIndex] = entry
            writeIndex = writeIndex + 1
        end
    end
    for i = writeIndex, #queue do
        queue[i] = nil
    end

    if #queue == 0 then
        pendingDeltaByName[name] = nil
        return nil
    end
    return queue
end

---@param unitTag string
---@param delta number
---@param nowMs number
local function queuePositiveDelta(unitTag, delta, nowMs)
    if delta <= 0 then return end

    local name = GetRawUnitName(unitTag)
    if not name or name == "" then return end

    local queue = prunePendingDeltas(name, nowMs)
    if not queue then
        queue = {}
        pendingDeltaByName[name] = queue
    end

    queue[#queue + 1] = {
        delta = delta,
        arrivedAtMs = nowMs,
    }

    if tryProcessPendingApplications then
        tryProcessPendingApplications(nowMs)
    end
end

---@param name string
---@param nowMs number
---@param preferredAtMs number|nil
---@return number|nil
---@return number|nil
local function popPendingDelta(name, nowMs, preferredAtMs)
    if not name or name == "" then return nil end
    local queue = prunePendingDeltas(name, nowMs)
    if not queue then return nil end

    local bestIndex = 1
    if preferredAtMs then
        local bestDistance = math.abs(queue[1].arrivedAtMs - preferredAtMs)
        for i = 2, #queue do
            local distance = math.abs(queue[i].arrivedAtMs - preferredAtMs)
            if distance < bestDistance then
                bestIndex = i
                bestDistance = distance
            end
        end
    end

    local entry = table.remove(queue, bestIndex)
    if #queue == 0 then
        pendingDeltaByName[name] = nil
    end
    if not entry then return nil, nil end
    return entry.delta, entry.arrivedAtMs
end

---@param nowMs number
local function pruneAllPendingDeltas(nowMs)
    for name in pairs(pendingDeltaByName) do
        prunePendingDeltas(name, nowMs)
    end
end

---@generic T : { arrivedAtMs: number }
---@param entries T[]
---@param nowMs number
local function prunePendingEvents(entries, nowMs)
    local writeIndex = 1
    for i = 1, #entries do
        local entry = entries[i]
        if entry and nowMs - entry.arrivedAtMs <= PENDING_EVENT_WINDOW_MS then
            entries[writeIndex] = entry
            writeIndex = writeIndex + 1
        end
    end
    for i = writeIndex, #entries do
        entries[i] = nil
    end
end

---@param sourceType number
---@param targetType number
---@return boolean
local function isCreditableShieldBucket(sourceType, targetType)
    if personalTypesSet[sourceType] and targetType == COMBAT_UNIT_TYPE_PLAYER then
        return true
    end
    if personalTypesSet[sourceType] and targetType == COMBAT_UNIT_TYPE_GROUP then
        return true
    end
    if sourceType == COMBAT_UNIT_TYPE_GROUP and targetType == COMBAT_UNIT_TYPE_PLAYER then
        return true
    end
    return false
end

---@param sourceType number
---@param targetType number
---@return boolean
local function isBlockingShieldBucket(sourceType, targetType)
    return sourceType == COMBAT_UNIT_TYPE_GROUP and targetType == COMBAT_UNIT_TYPE_GROUP
end

---@param sourceType number
---@param targetType number
---@return boolean
local function isObservableShieldBucket(sourceType, targetType)
    return isCreditableShieldBucket(sourceType, targetType)
        or isBlockingShieldBucket(sourceType, targetType)
end

---@param effect PendingShieldEffect
---@param gain PendingShieldCombatGain
---@return boolean
local function sourceTypesMatch(effect, gain)
    if personalTypesSet[effect.sourceType] and personalTypesSet[gain.sourceType] then
        return true
    end
    return effect.sourceType == gain.sourceType
end

---@param effect PendingShieldEffect
---@param gain PendingShieldCombatGain
---@return boolean
local function shieldEventsMatch(effect, gain)
    if effect.abilityId ~= gain.abilityId then return false end
    if effect.targetType ~= gain.targetType then return false end
    if not sourceTypesMatch(effect, gain) then return false end

    if effect.targetUnitId > 0 and gain.targetUnitId > 0 then
        return effect.targetUnitId == gain.targetUnitId
    end

    return effect.targetName ~= "" and effect.targetName == gain.targetName
end

---@param gain PendingShieldCombatGain
---@return number|nil index
---@return PendingShieldEffect|nil effect
local function findMatchingShieldEffect(gain)
    for i, effect in ipairs(pendingShieldEffects) do
        if shieldEventsMatch(effect, gain) then
            return i, effect
        end
    end
    return nil, nil
end

---@param state BattleScrollsState
---@param sourceUnitId number
---@param targetUnitId number
---@param abilityId number
---@param shieldValue number
---@param sourceType number
---@param targetType number
---@return boolean
local function creditShieldApplication(state, sourceUnitId, targetUnitId, abilityId, shieldValue, sourceType, targetType)
    local accumulators = BattleScrolls.accumulators

    if personalTypesSet[sourceType] and targetType == COMBAT_UNIT_TYPE_PLAYER then
        accumulators.healingDiffSource(state.healingStats.selfHealing, sourceUnitId, abilityId, 0, shieldValue, false)
        return true
    end

    if personalTypesSet[sourceType] and targetType == COMBAT_UNIT_TYPE_GROUP then
        if not state.healingStats.healingOutToGroup[targetUnitId] then
            state.healingStats.healingOutToGroup[targetUnitId] = BattleScrolls.structures.newHealingDoneDiffSource()
        end
        accumulators.healingDiffSource(state.healingStats.healingOutToGroup[targetUnitId], sourceUnitId, abilityId, 0, shieldValue, false)
        return true
    end

    if sourceType == COMBAT_UNIT_TYPE_GROUP and targetType == COMBAT_UNIT_TYPE_PLAYER then
        if not state.healingStats.healingInFromGroup[sourceUnitId] then
            state.healingStats.healingInFromGroup[sourceUnitId] = BattleScrolls.structures.newHealingDone()
        end
        accumulators.healingDone(state.healingStats.healingInFromGroup[sourceUnitId], abilityId, 0, shieldValue, false)
        return true
    end

    return false
end

---@param state BattleScrollsState
---@param instance ActiveShieldInstance
---@param abilityId number
---@param absorbed number
local function creditShieldAbsorb(state, instance, abilityId, absorbed)
    if not instance.creditable or instance.sourceUnitId <= 0 then return end

    local accumulators = BattleScrolls.accumulators

    if personalTypesSet[instance.sourceType] and instance.targetType == COMBAT_UNIT_TYPE_PLAYER then
        accumulators.shieldAbsorbDiffSource(state.healingStats.selfHealing, instance.sourceUnitId, abilityId, absorbed)
        return
    end

    if personalTypesSet[instance.sourceType] and instance.targetType == COMBAT_UNIT_TYPE_GROUP then
        local healingDone = state.healingStats.healingOutToGroup[instance.targetUnitId]
        if healingDone then
            accumulators.shieldAbsorbDiffSource(healingDone, instance.sourceUnitId, abilityId, absorbed)
        end
        return
    end

    if instance.sourceType == COMBAT_UNIT_TYPE_GROUP and instance.targetType == COMBAT_UNIT_TYPE_PLAYER then
        local healingDone = state.healingStats.healingInFromGroup[instance.sourceUnitId]
        if healingDone then
            accumulators.shieldAbsorbDone(healingDone, abilityId, absorbed)
        end
    end
end

---@param targetUnitId number
---@param abilityId number
---@param sourceUnitId number
---@param sourceType number
---@param targetType number
---@param appliedAtMs number
---@param remaining number
---@param creditable boolean
local function addActiveShield(targetUnitId, abilityId, sourceUnitId, sourceType, targetType, appliedAtMs, remaining, creditable)
    if targetUnitId <= 0 or abilityId <= 0 or remaining <= 0 then return end

    activeShields[targetUnitId] = activeShields[targetUnitId] or {}
    activeShields[targetUnitId][abilityId] = activeShields[targetUnitId][abilityId] or {}
    local queue = activeShields[targetUnitId][abilityId]
    local instance = {
        sourceUnitId = sourceUnitId,
        targetUnitId = targetUnitId,
        sourceType = sourceType,
        targetType = targetType,
        appliedAtMs = appliedAtMs,
        remaining = remaining,
        creditable = creditable,
    }

    local insertIndex = #queue + 1
    for i = #queue, 1, -1 do
        if appliedAtMs < queue[i].appliedAtMs then
            insertIndex = i
        else
            break
        end
    end

    table.insert(queue, insertIndex, instance)
end

---@param targetUnitId number
---@param abilityId number
---@return ActiveShieldInstance[]|nil
local function getActiveShieldQueue(targetUnitId, abilityId)
    local byTarget = activeShields[targetUnitId]
    return byTarget and byTarget[abilityId] or nil
end

---@param targetUnitId number
---@param abilityId number
local function cleanupActiveShieldQueue(targetUnitId, abilityId)
    local byTarget = activeShields[targetUnitId]
    local queue = byTarget and byTarget[abilityId]
    if not byTarget or not queue then return end

    if #queue == 0 then
        byTarget[abilityId] = nil
    end
    if not next(byTarget) then
        activeShields[targetUnitId] = nil
    end
end

---@param targetUnitId number
---@param abilityId number
local function removeOldestActiveShield(targetUnitId, abilityId)
    local queue = getActiveShieldQueue(targetUnitId, abilityId)
    if not queue then return end

    table.remove(queue, 1)
    cleanupActiveShieldQueue(targetUnitId, abilityId)
end

---@param state BattleScrollsState
---@param targetUnitId number
---@param abilityId number
---@param absorbed number
---@return boolean credited
local function consumeActiveShieldAbsorb(state, targetUnitId, abilityId, absorbed)
    local queue = getActiveShieldQueue(targetUnitId, abilityId)
    if not queue then return false end

    local remainingAbsorb = absorbed
    local credited = false
    for _, instance in ipairs(queue) do
        if remainingAbsorb <= 0 then break end
        if instance.remaining > 0 then
            local consumed = math.min(instance.remaining, remainingAbsorb)
            instance.remaining = instance.remaining - consumed
            remainingAbsorb = remainingAbsorb - consumed

            if instance.creditable then
                creditShieldAbsorb(state, instance, abilityId, consumed)
                credited = true
            end
        end
    end

    return credited
end

local function onShieldVisualAdded(_eventCode, unitTag, unitAttributeVisual, _statType, _attributeType, _powerType, value)
    if unitAttributeVisual ~= ATTRIBUTE_VISUAL_POWER_SHIELDING or not isTrackedUnitTag(unitTag) then
        return
    end

    local newTotal = value or 0
    shieldTotalsByTag[unitTag] = newTotal
    queuePositiveDelta(unitTag, newTotal, GetGameTimeMilliseconds())
end

local function onShieldVisualUpdated(_eventCode, unitTag, unitAttributeVisual, _statType, _attributeType, _powerType, oldValue, newValue)
    if unitAttributeVisual ~= ATTRIBUTE_VISUAL_POWER_SHIELDING or not isTrackedUnitTag(unitTag) then
        return
    end

    local oldTotal = shieldTotalsByTag[unitTag]
    if oldTotal == nil then
        oldTotal = oldValue or 0
    end

    newValue = newValue or 0
    shieldTotalsByTag[unitTag] = newValue
    queuePositiveDelta(unitTag, newValue - oldTotal, GetGameTimeMilliseconds())
end

local function onShieldVisualRemoved(_eventCode, unitTag, unitAttributeVisual)
    if unitAttributeVisual ~= ATTRIBUTE_VISUAL_POWER_SHIELDING or not isTrackedUnitTag(unitTag) then
        return
    end

    shieldTotalsByTag[unitTag] = nil
end

---@param state BattleScrollsState
---@param gain PendingShieldCombatGain
---@param shieldValue number
---@param appliedAtMs number
local function creditMatchedShieldApplication(state, gain, shieldValue, appliedAtMs)
    if gain.sourceUnitId <= 0 and isInferableSourceType(gain.sourceType) then
        gain.sourceUnitId = getInferredSourceUnitId(state, gain.sourceType, gain.targetType, gain.targetUnitId)
    end
    if gain.sourceType == COMBAT_UNIT_TYPE_PLAYER and gain.targetType == COMBAT_UNIT_TYPE_PLAYER then
        if gain.sourceUnitId <= 0 and gain.targetUnitId > 0 then
            gain.sourceUnitId = gain.targetUnitId
        elseif gain.targetUnitId <= 0 and gain.sourceUnitId > 0 then
            gain.targetUnitId = gain.sourceUnitId
        end
    end
    if (not gain.sourceName or gain.sourceName == "") and isInferableSourceType(gain.sourceType) then
        gain.sourceName = getInferredSourceName(gain.sourceType)
    end

    state:MarkShieldAbility(gain.abilityId)
    if gain.sourceUnitId > 0 then
        state:UpdateUnitName(gain.sourceUnitId, gain.sourceName)
        state:UpdateUnitFriendliness(gain.sourceUnitId, gain.sourceType)
    end
    if gain.targetUnitId > 0 then
        state:UpdateUnitName(gain.targetUnitId, gain.targetName)
        state:UpdateUnitFriendliness(gain.targetUnitId, gain.targetType)
    end

    if creditShieldApplication(state, gain.sourceUnitId, gain.targetUnitId, gain.abilityId, shieldValue, gain.sourceType, gain.targetType) then
        addActiveShield(gain.targetUnitId, gain.abilityId, gain.sourceUnitId, gain.sourceType, gain.targetType,
            appliedAtMs, shieldValue, true)
    end
end

---@param effect PendingShieldEffect
---@return boolean
local function canCreditShieldEffectWithInferredSource(effect)
    return not isFallbackSelfShieldAbility(effect.abilityId)
        and effect.targetUnitId > 0
        and isInferableSourceType(effect.sourceType)
end

---@param state BattleScrollsState
---@param effect PendingShieldEffect
---@param shieldValue number
---@param appliedAtMs number
local function creditInferredShieldEffectApplication(state, effect, shieldValue, appliedAtMs)
    local sourceUnitId = getInferredSourceUnitId(state, effect.sourceType, effect.targetType, effect.targetUnitId)
    if sourceUnitId <= 0 then return end

    local sourceName = getInferredSourceName(effect.sourceType)
    state:MarkShieldAbility(effect.abilityId)
    state:UpdateUnitName(sourceUnitId, sourceName)
    state:UpdateUnitName(effect.targetUnitId, effect.targetName)
    state:UpdateUnitFriendliness(sourceUnitId, effect.sourceType)
    state:UpdateUnitFriendliness(effect.targetUnitId, effect.targetType)

    if creditShieldApplication(state, sourceUnitId, effect.targetUnitId, effect.abilityId, shieldValue,
        effect.sourceType, effect.targetType) then
        addActiveShield(effect.targetUnitId, effect.abilityId, sourceUnitId, effect.sourceType, effect.targetType,
            appliedAtMs, shieldValue, true)
    end
end

---@param sourceName string
---@param sourceUnitId number
---@param targetName string
---@param targetUnitId number
---@return string sourceName
---@return number sourceUnitId
---@return string targetName
---@return number targetUnitId
local function normalizeFallbackSelfShieldIdentity(sourceName, sourceUnitId, targetName, targetUnitId)
    local playerName = GetRawUnitName("player")
    local unitId = targetUnitId > 0 and targetUnitId or sourceUnitId

    if not sourceName or sourceName == "" then
        sourceName = playerName
    end
    if not targetName or targetName == "" then
        targetName = playerName
    end
    if sourceUnitId <= 0 then
        sourceUnitId = unitId
    end
    if targetUnitId <= 0 then
        targetUnitId = unitId
    end

    return sourceName, sourceUnitId, targetName, targetUnitId
end

---@param state BattleScrollsState
---@param effect PendingShieldEffect
---@param shieldValue number
---@param appliedAtMs number
local function trackBlockingShieldApplication(state, effect, shieldValue, appliedAtMs)
    state:MarkShieldAbility(effect.abilityId)
    state:UpdateUnitName(effect.targetUnitId, effect.targetName)
    state:UpdateUnitFriendliness(effect.targetUnitId, effect.targetType)

    addActiveShield(effect.targetUnitId, effect.abilityId, 0, effect.sourceType, effect.targetType,
        appliedAtMs, shieldValue, false)
end

---@param targetName string
---@param targetUnitId number
---@return string
local function resolveAttributeBlockTargetName(targetName, targetUnitId)
    if targetName and targetName ~= "" then
        return targetName
    end

    local state = BattleScrolls.state
    local knownName = state and state.unitIdToName and state.unitIdToName[targetUnitId]
    if knownName and knownName ~= "" then
        return knownName
    end

    if targetUnitId > 0 then
        for _, effect in ipairs(pendingShieldEffects) do
            if effect.targetUnitId == targetUnitId and effect.targetName ~= "" then
                return effect.targetName
            end
        end
    end

    return ""
end

---@param targetName string
---@param targetUnitId number
---@param nowMs number
local function queueAttributeBlock(targetName, targetUnitId, nowMs)
    if (not targetName or targetName == "") and targetUnitId <= 0 then
        return
    end

    pendingAttributeBlocks[#pendingAttributeBlocks + 1] = {
        targetName = targetName,
        targetUnitId = targetUnitId,
        arrivedAtMs = nowMs,
    }

    if tryProcessPendingApplications then
        tryProcessPendingApplications(nowMs)
    end
end

tryProcessPendingApplications = function(nowMs)
    local state = BattleScrolls.state
    if not state or not state.initialized then return end

    pruneAllPendingDeltas(nowMs)
    prunePendingEvents(pendingShieldEffects, nowMs)
    prunePendingEvents(pendingCombatGains, nowMs)
    prunePendingEvents(pendingAttributeBlocks, nowMs)

    for i = #pendingAttributeBlocks, 1, -1 do
        local block = pendingAttributeBlocks[i]
        local targetName = resolveAttributeBlockTargetName(block.targetName, block.targetUnitId)
        local shieldValue = popPendingDelta(targetName, nowMs, block.arrivedAtMs)
        if shieldValue then
            table.remove(pendingAttributeBlocks, i)
        end
    end

    for i = #pendingCombatGains, 1, -1 do
        local gain = pendingCombatGains[i]
        local effectIndex, effect = findMatchingShieldEffect(gain)
        if effectIndex and effect then
            local targetName = gain.targetName ~= "" and gain.targetName or effect.targetName
            local shieldValue, deltaAtMs = popPendingDelta(targetName, nowMs, effect.arrivedAtMs)
            if not shieldValue and effect.targetName ~= "" and effect.targetName ~= targetName then
                shieldValue, deltaAtMs = popPendingDelta(effect.targetName, nowMs, effect.arrivedAtMs)
            end
            if shieldValue then
                table.remove(pendingCombatGains, i)
                table.remove(pendingShieldEffects, effectIndex)
                if gain.targetName == "" then
                    gain.targetName = effect.targetName
                end
                if gain.targetUnitId <= 0 and effect.targetUnitId > 0 then
                    gain.targetUnitId = effect.targetUnitId
                end
                creditMatchedShieldApplication(state, gain, shieldValue, deltaAtMs or effect.arrivedAtMs)
            end
        end
    end

    for i = #pendingCombatGains, 1, -1 do
        local gain = pendingCombatGains[i]
        if isFallbackSelfShieldAbility(gain.abilityId) then
            local shieldValue, deltaAtMs = popPendingDelta(gain.targetName, nowMs, gain.arrivedAtMs)
            if shieldValue then
                table.remove(pendingCombatGains, i)
                creditMatchedShieldApplication(state, gain, shieldValue, deltaAtMs or gain.arrivedAtMs)
            end
        end
    end

    for i = #pendingShieldEffects, 1, -1 do
        local effect = pendingShieldEffects[i]
        if canCreditShieldEffectWithInferredSource(effect) then
            local shieldValue, deltaAtMs = popPendingDelta(effect.targetName, nowMs, effect.arrivedAtMs)
            if shieldValue then
                table.remove(pendingShieldEffects, i)
                creditInferredShieldEffectApplication(state, effect, shieldValue, deltaAtMs or effect.arrivedAtMs)
            end
        end
    end

    for i = #pendingShieldEffects, 1, -1 do
        local effect = pendingShieldEffects[i]
        if isFallbackSelfShieldAbility(effect.abilityId) and isBlockingShieldBucket(effect.sourceType, effect.targetType) then
            local shieldValue = popPendingDelta(effect.targetName, nowMs, effect.arrivedAtMs)
            if shieldValue then
                table.remove(pendingShieldEffects, i)
            end
        elseif isBlockingShieldBucket(effect.sourceType, effect.targetType) then
            local shieldValue, deltaAtMs = popPendingDelta(effect.targetName, nowMs, effect.arrivedAtMs)
            if shieldValue then
                table.remove(pendingShieldEffects, i)
                trackBlockingShieldApplication(state, effect, shieldValue, deltaAtMs or effect.arrivedAtMs)
            end
        end
    end
end

local function onShieldEffectChanged(_eventCode, changeType, _effectSlot, _effectName, unitTag, _beginTime, _endTime,
                                     _stackCount, _iconName, _deprecatedBuffType, _effectType, abilityType,
                                     _statusEffectType, unitName, unitId, abilityId, sourceType)
    if not isTrackedUnitTag(unitTag) then
        return
    end

    if unitTag == "player" then
        shields:RememberUnitIdentity(COMBAT_UNIT_TYPE_PLAYER, unitId, unitName)
    end

    rememberAbilityType(abilityId, abilityType)

    if abilityType ~= ABILITY_TYPE_DAMAGESHIELD then
        return
    end

    local targetType = getTargetTypeForUnitTag(unitTag)
    if not targetType or not isObservableShieldBucket(sourceType, targetType) then
        return
    end

    if changeType == EFFECT_RESULT_FADED then
        removeOldestActiveShield(unitId, abilityId)
        return
    end

    if changeType ~= EFFECT_RESULT_GAINED and changeType ~= EFFECT_RESULT_UPDATED then
        return
    end

    local nowMs = GetGameTimeMilliseconds()
    local rawTargetName = GetRawUnitName(unitTag)
    pendingShieldEffects[#pendingShieldEffects + 1] = {
        abilityId = abilityId,
        targetName = rawTargetName ~= "" and rawTargetName or unitName,
        targetUnitId = unitId,
        targetType = targetType,
        sourceType = sourceType,
        arrivedAtMs = nowMs,
    }
    tryProcessPendingApplications(nowMs)
end

function shields:OnEffectChanged(...)
    onShieldEffectChanged(...)
end

local function onShieldGained(_eventCode, result, isError, _abilityName, _abilityGraphic, _abilityActionSlotType,
                              sourceName, sourceType, targetName, targetType, _hitValue, _powerType, _damageType,
                              _log, sourceUnitId, targetUnitId, abilityId, _overflow)
    if isError or result ~= ACTION_RESULT_EFFECT_GAINED then return end

    local state = BattleScrolls.state
    if not state or not state.initialized then return end

    local nowMs = GetGameTimeMilliseconds()
    if isFallbackSelfShieldAbility(abilityId) then
        if sourceType == COMBAT_UNIT_TYPE_PLAYER and targetType == COMBAT_UNIT_TYPE_PLAYER then
            sourceName, sourceUnitId, targetName, targetUnitId = normalizeFallbackSelfShieldIdentity(sourceName, sourceUnitId, targetName, targetUnitId)
        else
            queueAttributeBlock(targetName, targetUnitId, nowMs)
            return
        end
    else
        if not isTrackedTargetType(targetType) then return end
        if not isCreditableShieldBucket(sourceType, targetType) then return end
        if damageShieldAbilityById[abilityId] == false then return end
    end

    pendingCombatGains[#pendingCombatGains + 1] = {
        abilityId = abilityId,
        sourceName = sourceName,
        sourceUnitId = sourceUnitId,
        sourceType = sourceType,
        targetName = targetName,
        targetUnitId = targetUnitId,
        targetType = targetType,
        arrivedAtMs = nowMs,
    }
    tryProcessPendingApplications(nowMs)
end

local function onShieldFaded(_eventCode, result, isError, _abilityName, _abilityGraphic, _abilityActionSlotType,
                             _sourceName, _sourceType, _targetName, _targetType, _hitValue, _powerType, _damageType,
                             _log, sourceUnitId, targetUnitId, abilityId, _overflow)
    if isError or result ~= ACTION_RESULT_EFFECT_FADED then return end
    if not isFallbackSelfShieldAbility(abilityId) then return end

    local unitId = targetUnitId > 0 and targetUnitId or sourceUnitId
    if unitId <= 0 then return end

    removeOldestActiveShield(unitId, abilityId)
end

local function onShieldAbsorb(_eventCode, result, isError, _abilityName, _abilityGraphic, _abilityActionSlotType,
                              _sourceName, _sourceType, _targetName, _targetType, hitValue, _powerType, _damageType,
                              _log, _sourceUnitId, targetUnitId, abilityId, _overflow)
    if isError or result ~= ACTION_RESULT_DAMAGE_SHIELDED or hitValue <= 0 then return end

    local state = BattleScrolls.state
    if not state or not state.initialized then return end

    state:MarkShieldAbility(abilityId)
    consumeActiveShieldAbsorb(state, targetUnitId, abilityId, hitValue)
end

---@param name string
---@param callback fun(...)
---@param result number
---@param ... any
local function registerShieldCombatEvent(name, callback, result, ...)
    combatEventNames[#combatEventNames + 1] = name
    EVENT_MANAGER:RegisterForEvent(name, EVENT_COMBAT_EVENT, callback)
    EVENT_MANAGER:AddFilterForEvent(name, EVENT_COMBAT_EVENT,
        REGISTER_FILTER_COMBAT_RESULT, result,
        REGISTER_FILTER_IS_ERROR, false,
        ...)
end

---@param name string
---@param eventCode any
---@param callback fun(...)
---@param unitTagPrefix string
local function registerShieldVisualEvent(name, eventCode, callback, unitTagPrefix)
    visualEventNames[#visualEventNames + 1] = name
    EVENT_MANAGER:RegisterForEvent(name, eventCode, callback)
    EVENT_MANAGER:AddFilterForEvent(name, eventCode,
        REGISTER_FILTER_UNIT_TAG_PREFIX, unitTagPrefix)
end

local function subscribeVisualEvents()
    registerShieldVisualEvent("BS_Shields_VisualAdded_Player", EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED, onShieldVisualAdded, "player")
    registerShieldVisualEvent("BS_Shields_VisualUpdated_Player", EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED, onShieldVisualUpdated, "player")
    registerShieldVisualEvent("BS_Shields_VisualRemoved_Player", EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED, onShieldVisualRemoved, "player")
    registerShieldVisualEvent("BS_Shields_VisualAdded_Group", EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED, onShieldVisualAdded, "group")
    registerShieldVisualEvent("BS_Shields_VisualUpdated_Group", EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED, onShieldVisualUpdated, "group")
    registerShieldVisualEvent("BS_Shields_VisualRemoved_Group", EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED, onShieldVisualRemoved, "group")
end

local function unsubscribeVisualEvents()
    for _, name in ipairs(visualEventNames) do
        EVENT_MANAGER:UnregisterForEvent(name, EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED)
        EVENT_MANAGER:UnregisterForEvent(name, EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED)
        EVENT_MANAGER:UnregisterForEvent(name, EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED)
    end
    visualEventNames = {}
end

function shields:OnStateInitialized()
    clearTracking()
    subscribeVisualEvents()
end

function shields:OnStatePreReset()
    unsubscribeVisualEvents()
    clearTracking()
end

function shields:Initialize()
    BattleScrolls.state:RegisterObserver(self)
    registerShieldCombatEvent("BS_Shields_Gained_Pet", onShieldGained, ACTION_RESULT_EFFECT_GAINED,
        REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER_PET)
    registerShieldCombatEvent("BS_Shields_Gained_GroupToPlayer",
        function(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType,
                 sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log,
                 sourceUnitId, targetUnitId, abilityId, overflow)
            if sourceType ~= COMBAT_UNIT_TYPE_GROUP
                or targetType ~= COMBAT_UNIT_TYPE_PLAYER
                or isFallbackSelfShieldAbility(abilityId) then
                return
            end
            onShieldGained(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType,
                sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log,
                sourceUnitId, targetUnitId, abilityId, overflow)
        end,
        ACTION_RESULT_EFFECT_GAINED,
        REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
    registerShieldCombatEvent("BS_Shields_Gained_Fatecarver", onShieldGained, ACTION_RESULT_EFFECT_GAINED,
        REGISTER_FILTER_ABILITY_ID, 201265)
    registerShieldCombatEvent("BS_Shields_FallbackFaded", onShieldFaded, ACTION_RESULT_EFFECT_FADED,
        REGISTER_FILTER_ABILITY_ID, 201265)
    registerShieldCombatEvent("BS_Shields_Absorb", onShieldAbsorb, ACTION_RESULT_DAMAGE_SHIELDED)
end

function shields:Cleanup()
    unsubscribeVisualEvents()
    for _, name in ipairs(combatEventNames) do
        EVENT_MANAGER:UnregisterForEvent(name, EVENT_COMBAT_EVENT)
    end
    combatEventNames = {}
    clearTracking()
end
