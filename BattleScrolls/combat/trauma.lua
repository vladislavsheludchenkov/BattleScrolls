if not SemisPlaygroundCheckAccess() then
    return
end

-- Heal absorption (Trauma) tracking for damage-taken attribution.
-- Trauma applications are credited as one non-critical damage-taken tick for
-- the full applied heal-absorption amount.

BattleScrolls = BattleScrolls or {}

---@class PendingTraumaDelta
---@field delta number
---@field arrivedAtMs number

---@class PendingTraumaEffect
---@field abilityId number
---@field targetName string
---@field targetUnitId number
---@field targetType number
---@field sourceType number
---@field arrivedAtMs number

---@class PendingTraumaCombatGain
---@field abilityId number
---@field sourceName string
---@field sourceUnitId number
---@field sourceType number
---@field targetName string
---@field targetUnitId number
---@field targetType number
---@field arrivedAtMs number

---@class BattleScrollsTrauma : StateObserver
local trauma = {}
BattleScrolls.trauma = trauma

local PENDING_EVENT_WINDOW_MS = 250

---@type number|nil
local traumaTotal = nil

---@type PendingTraumaDelta[]
local pendingDeltas = {}

---@type PendingTraumaEffect[]
local pendingTraumaEffects = {}

---@type PendingTraumaCombatGain[]
local pendingCombatGains = {}

---@type table<number, boolean>
local traumaAbilityById = {}

---@type string[]
local visualEventNames = {}

---@type string[]
local combatEventNames = {}

---@type fun(nowMs: number)|nil
local tryProcessPendingApplications

---@param state BattleScrollsState|nil
---@param unitId number
---@return number
local function resolvePlayerUnitId(state, unitId)
    if unitId and unitId > 0 then
        return unitId
    end
    return (state and state:GetPersonalUnitId(COMBAT_UNIT_TYPE_PLAYER)) or 0
end

local function clearTracking()
    traumaTotal = nil
    pendingDeltas = {}
    pendingTraumaEffects = {}
    pendingCombatGains = {}
end

---@param abilityId number
---@param abilityType number
local function rememberAbilityType(abilityId, abilityType)
    if abilityId and abilityId > 0 then
        if abilityType == ABILITY_TYPE_TRAUMA then
            traumaAbilityById[abilityId] = true
        elseif traumaAbilityById[abilityId] == nil then
            traumaAbilityById[abilityId] = false
        end
    end
end

---@param unitTag string
---@return boolean
local function isTrackedUnitTag(unitTag)
    return unitTag == "player"
end

---@param targetType number
---@return boolean
local function isTrackedTargetType(targetType)
    return targetType == COMBAT_UNIT_TYPE_PLAYER
end

---@param unitTag string
---@return number|nil
local function getTargetTypeForUnitTag(unitTag)
    if unitTag == "player" then return COMBAT_UNIT_TYPE_PLAYER end
    return nil
end

---@param nowMs number
---@return PendingTraumaDelta[]|nil
local function prunePendingDeltas(nowMs)
    local writeIndex = 1
    for i = 1, #pendingDeltas do
        local entry = pendingDeltas[i]
        if entry and nowMs - entry.arrivedAtMs <= PENDING_EVENT_WINDOW_MS then
            pendingDeltas[writeIndex] = entry
            writeIndex = writeIndex + 1
        end
    end
    for i = writeIndex, #pendingDeltas do
        pendingDeltas[i] = nil
    end

    if #pendingDeltas == 0 then
        return nil
    end
    return pendingDeltas
end

---@param delta number
---@param nowMs number
local function queuePositiveDelta(delta, nowMs)
    if delta <= 0 then return end

    prunePendingDeltas(nowMs)

    pendingDeltas[#pendingDeltas + 1] = {
        delta = delta,
        arrivedAtMs = nowMs,
    }

    if tryProcessPendingApplications then
        tryProcessPendingApplications(nowMs)
    end
end

---@param nowMs number
---@param preferredAtMs number|nil
---@return number|nil
---@return number|nil
local function popPendingDelta(nowMs, preferredAtMs)
    local queue = prunePendingDeltas(nowMs)
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
    if not entry then return nil, nil end
    return entry.delta, entry.arrivedAtMs
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

---@param effect PendingTraumaEffect
---@param gain PendingTraumaCombatGain
---@return boolean
local function traumaEventsMatch(effect, gain)
    if effect.abilityId ~= gain.abilityId then return false end
    if effect.targetType ~= gain.targetType then return false end
    if effect.sourceType ~= gain.sourceType then return false end

    if effect.targetUnitId > 0 and gain.targetUnitId > 0 then
        return effect.targetUnitId == gain.targetUnitId
    end

    return effect.targetName ~= "" and effect.targetName == gain.targetName
end

---@param gain PendingTraumaCombatGain
---@return number|nil index
---@return PendingTraumaEffect|nil effect
local function findMatchingTraumaEffect(gain)
    for i, effect in ipairs(pendingTraumaEffects) do
        if traumaEventsMatch(effect, gain) then
            return i, effect
        end
    end
    return nil, nil
end

---@param state BattleScrollsState
---@param gain PendingTraumaCombatGain
---@param traumaValue number
local function creditMatchedTraumaApplication(state, gain, traumaValue)
    if gain.targetUnitId <= 0 then
        gain.targetUnitId = resolvePlayerUnitId(state, gain.targetUnitId)
    end
    if gain.targetUnitId <= 0 then return end

    state:UpdateUnitName(gain.sourceUnitId, gain.sourceName)
    state:UpdateUnitName(gain.targetUnitId, gain.targetName)
    state:UpdateUnitFriendliness(gain.sourceUnitId, gain.sourceType)
    state:UpdateUnitFriendliness(gain.targetUnitId, gain.targetType)

    state:OnDamageTaken(0, ACTION_RESULT_HEAL_ABSORBED, false, "", "", 0,
        gain.sourceName, gain.sourceType, gain.targetName, gain.targetType,
        traumaValue, 0, DAMAGE_TYPE_NONE, "", gain.sourceUnitId, gain.targetUnitId,
        gain.abilityId, 0)
end

local function onTraumaVisualAdded(_eventCode, unitTag, unitAttributeVisual, _statType, _attributeType, _powerType, value)
    if unitAttributeVisual ~= ATTRIBUTE_VISUAL_TRAUMA or not isTrackedUnitTag(unitTag) then
        return
    end

    local newTotal = value or 0
    traumaTotal = newTotal
    queuePositiveDelta(newTotal, GetGameTimeMilliseconds())
end

local function onTraumaVisualUpdated(_eventCode, unitTag, unitAttributeVisual, _statType, _attributeType, _powerType, oldValue, newValue)
    if unitAttributeVisual ~= ATTRIBUTE_VISUAL_TRAUMA or not isTrackedUnitTag(unitTag) then
        return
    end

    local oldTotal = traumaTotal
    if oldTotal == nil then
        oldTotal = oldValue or 0
    end

    newValue = newValue or 0
    traumaTotal = newValue
    queuePositiveDelta(newValue - oldTotal, GetGameTimeMilliseconds())
end

local function onTraumaVisualRemoved(_eventCode, unitTag, unitAttributeVisual)
    if unitAttributeVisual ~= ATTRIBUTE_VISUAL_TRAUMA or not isTrackedUnitTag(unitTag) then
        return
    end

    traumaTotal = nil
end

tryProcessPendingApplications = function(nowMs)
    local state = BattleScrolls.state
    if not state or not state.initialized then return end

    prunePendingDeltas(nowMs)
    prunePendingEvents(pendingTraumaEffects, nowMs)
    prunePendingEvents(pendingCombatGains, nowMs)

    for i = #pendingCombatGains, 1, -1 do
        local gain = pendingCombatGains[i]
        local effectIndex, effect = findMatchingTraumaEffect(gain)
        if effectIndex and effect then
            local traumaValue = popPendingDelta(nowMs, effect.arrivedAtMs)
            if traumaValue then
                table.remove(pendingCombatGains, i)
                table.remove(pendingTraumaEffects, effectIndex)
                if gain.targetName == "" then
                    gain.targetName = effect.targetName
                end
                if gain.targetUnitId <= 0 and effect.targetUnitId > 0 then
                    gain.targetUnitId = effect.targetUnitId
                end
                creditMatchedTraumaApplication(state, gain, traumaValue)
            end
        end
    end
end

local function onTraumaEffectChanged(_eventCode, changeType, _effectSlot, _effectName, unitTag, _beginTime, _endTime,
                                     _stackCount, _iconName, _deprecatedBuffType, _effectType, abilityType,
                                     _statusEffectType, unitName, unitId, abilityId, sourceType)
    if not isTrackedUnitTag(unitTag) then
        return
    end

    local state = BattleScrolls.state
    if state then
        state:RememberPersonalUnitIdentity(COMBAT_UNIT_TYPE_PLAYER, unitId, unitName)
        unitId = resolvePlayerUnitId(state, unitId)
    end

    rememberAbilityType(abilityId, abilityType)

    if abilityType ~= ABILITY_TYPE_TRAUMA then
        return
    end

    local targetType = getTargetTypeForUnitTag(unitTag)
    if not targetType then
        return
    end

    if changeType ~= EFFECT_RESULT_GAINED and changeType ~= EFFECT_RESULT_UPDATED then
        return
    end

    local nowMs = GetGameTimeMilliseconds()
    local rawTargetName = GetRawUnitName(unitTag)
    pendingTraumaEffects[#pendingTraumaEffects + 1] = {
        abilityId = abilityId,
        targetName = rawTargetName ~= "" and rawTargetName or unitName,
        targetUnitId = unitId,
        targetType = targetType,
        sourceType = sourceType,
        arrivedAtMs = nowMs,
    }
    tryProcessPendingApplications(nowMs)
end

function trauma:OnEffectChanged(...)
    onTraumaEffectChanged(...)
end

local function onTraumaGained(_eventCode, result, isError, _abilityName, _abilityGraphic, _abilityActionSlotType,
                              sourceName, sourceType, targetName, targetType, _hitValue, _powerType, _damageType,
                              _log, sourceUnitId, targetUnitId, abilityId, _overflow)
    if isError or result ~= ACTION_RESULT_EFFECT_GAINED then return end
    if not isTrackedTargetType(targetType) then return end
    if traumaAbilityById[abilityId] == false then return end

    local state = BattleScrolls.state
    if not state or not state.initialized then return end

    local nowMs = GetGameTimeMilliseconds()
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

---@param name string
---@param callback fun(...)
---@param result number
---@param ... any
local function registerTraumaCombatEvent(name, callback, result, ...)
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
local function registerTraumaVisualEvent(name, eventCode, callback, unitTagPrefix)
    visualEventNames[#visualEventNames + 1] = name
    EVENT_MANAGER:RegisterForEvent(name, eventCode, callback)
    EVENT_MANAGER:AddFilterForEvent(name, eventCode,
        REGISTER_FILTER_UNIT_TAG_PREFIX, unitTagPrefix)
end

local function subscribeVisualEvents()
    registerTraumaVisualEvent("BS_Trauma_VisualAdded_Player", EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED, onTraumaVisualAdded, "player")
    registerTraumaVisualEvent("BS_Trauma_VisualUpdated_Player", EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED, onTraumaVisualUpdated, "player")
    registerTraumaVisualEvent("BS_Trauma_VisualRemoved_Player", EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED, onTraumaVisualRemoved, "player")
end

local function unsubscribeVisualEvents()
    for _, name in ipairs(visualEventNames) do
        EVENT_MANAGER:UnregisterForEvent(name, EVENT_UNIT_ATTRIBUTE_VISUAL_ADDED)
        EVENT_MANAGER:UnregisterForEvent(name, EVENT_UNIT_ATTRIBUTE_VISUAL_UPDATED)
        EVENT_MANAGER:UnregisterForEvent(name, EVENT_UNIT_ATTRIBUTE_VISUAL_REMOVED)
    end
    visualEventNames = {}
end

function trauma:OnStateInitialized()
    clearTracking()
    subscribeVisualEvents()
end

function trauma:OnStatePreReset()
    unsubscribeVisualEvents()
    clearTracking()
end

function trauma:Initialize()
    BattleScrolls.state:RegisterObserver(self)
    registerTraumaCombatEvent("BS_Trauma_Gained_Player", onTraumaGained, ACTION_RESULT_EFFECT_GAINED,
        REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
end

function trauma:Cleanup()
    unsubscribeVisualEvents()
    for _, name in ipairs(combatEventNames) do
        EVENT_MANAGER:UnregisterForEvent(name, EVENT_COMBAT_EVENT)
    end
    combatEventNames = {}
    clearTracking()
end
