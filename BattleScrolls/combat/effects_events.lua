if not SemisPlaygroundCheckAccess() then
    return
end

-- Effect Event Registration for BattleScrolls
-- Lightweight event handlers that call effects module directly (no queue)

BattleScrolls = BattleScrolls or {}

---@type BattleScrollsEffects
local effects = BattleScrolls.effects

---@class EffectsEvents
---@field Initialize fun(self: EffectsEvents) Register all event handlers
---@field Cleanup fun(self: EffectsEvents) Unregister all event handlers
local effectsEvents = {}
BattleScrolls.effectsEvents = effectsEvents

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

local function onPlayerEffect(_eventCode, changeType, effectSlot, _effectName, _unitTag, beginTime, _endTime,
                              stackCount, _iconName, _deprecatedBuffType, effectType, _abilityType,
                              _statusEffectType, _unitName, _unitId, abilityId, sourceType)
    local s = BattleScrolls.state
    if not s or not s.inCombat then return end
    effects.handlePlayerEffect(s, changeType, effectSlot, effectType, stackCount, abilityId, sourceType, beginTime)
end

local function onBossEffect(_eventCode, changeType, effectSlot, _effectName, unitTag, beginTime, _endTime,
                            stackCount, _iconName, _deprecatedBuffType, effectType, _abilityType,
                            _statusEffectType, _unitName, unitId, abilityId, sourceType)
    local s = BattleScrolls.state
    if not s or not s.inCombat then return end
    effects.handleBossEffect(s, changeType, effectSlot, unitTag, effectType, stackCount, abilityId, unitId, sourceType, beginTime)
end

local function onGroupEffect(_eventCode, changeType, effectSlot, _effectName, unitTag, beginTime, endTime,
                             stackCount, _iconName, _deprecatedBuffType, effectType, _abilityType,
                             _statusEffectType, _unitName, unitId, abilityId, sourceType)
    local s = BattleScrolls.state
    if not s or not s.inCombat then return end
    effects.handleGroupEffect(s, changeType, effectSlot, unitTag, effectType, stackCount, abilityId, unitId, sourceType, beginTime, endTime)
end

local function onPlayerDeathState(_eventCode, unitTag, isDead)
    if not AreUnitsEqual("player", unitTag) then return end
    local s = BattleScrolls.state
    if not s or not s.inCombat then return end
    if isDead then
        effects.handlePlayerDeath(s)
    else
        effects.handlePlayerAlive(s)
    end
end

local function onBossDeathState(_eventCode, unitTag, isDead)
    local s = BattleScrolls.state
    if not s or not s.inCombat then return end
    if isDead then
        effects.handleUnitDeath(s, unitTag)
    else
        effects.handleUnitAlive(s, unitTag)
    end
end

local function onGroupDeathState(_eventCode, unitTag, isDead)
    if AreUnitsEqual("player", unitTag) then return end
    if IsGroupCompanionUnitTag(unitTag) then return end
    local s = BattleScrolls.state
    if not s or not s.inCombat then return end
    if isDead then
        effects.handleUnitDeath(s, unitTag)
    else
        effects.handleUnitAlive(s, unitTag)
    end
end

local function onBossDestroyed(_eventCode, unitTag)
    local s = BattleScrolls.state
    if not s or not s.inCombat then return end
    effects.handleUnitDeath(s, unitTag)
end

local function onGroupDestroyed(_eventCode, unitTag)
    if AreUnitsEqual("player", unitTag) then return end
    if IsGroupCompanionUnitTag(unitTag) then return end
    local s = BattleScrolls.state
    if not s or not s.inCombat then return end
    effects.handleUnitDeath(s, unitTag)
end

local function onBossCreated(_eventCode, unitTag)
    local s = BattleScrolls.state
    if not s or not s.inCombat then return end
    effects.handleUnitAlive(s, unitTag)
end

local function onGroupCreated(_eventCode, unitTag)
    if AreUnitsEqual("player", unitTag) then return end
    if IsGroupCompanionUnitTag(unitTag) then return end
    local s = BattleScrolls.state
    if not s or not s.inCombat then return end
    effects.handleUnitAlive(s, unitTag)
end

local function onEffectsFullUpdate(_eventCode)
    local s = BattleScrolls.state
    if not s or not s.inCombat then return end
    -- BattleScrolls.log.Info("Got EVENT_EFFECTS_FULL_UPDATE, triggering full refresh")
    effects.handleFullRefreshAll(s)
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

function effectsEvents:Initialize()
    -- Player effects
    EVENT_MANAGER:RegisterForEvent("BS_Effects_Player", EVENT_EFFECT_CHANGED, onPlayerEffect)
    EVENT_MANAGER:AddFilterForEvent("BS_Effects_Player", EVENT_EFFECT_CHANGED,
        REGISTER_FILTER_UNIT_TAG, "player")

    -- Boss effects
    EVENT_MANAGER:RegisterForEvent("BS_Effects_Boss", EVENT_EFFECT_CHANGED, onBossEffect)
    EVENT_MANAGER:AddFilterForEvent("BS_Effects_Boss", EVENT_EFFECT_CHANGED,
        REGISTER_FILTER_UNIT_TAG_PREFIX, "boss")

    -- Group effects
    EVENT_MANAGER:RegisterForEvent("BS_Effects_Group", EVENT_EFFECT_CHANGED, onGroupEffect)
    EVENT_MANAGER:AddFilterForEvent("BS_Effects_Group", EVENT_EFFECT_CHANGED,
        REGISTER_FILTER_UNIT_TAG_PREFIX, "group")

    -- Player death state
    EVENT_MANAGER:RegisterForEvent("BS_Effects_Death_Player", EVENT_UNIT_DEATH_STATE_CHANGED, onPlayerDeathState)
    EVENT_MANAGER:AddFilterForEvent("BS_Effects_Death_Player", EVENT_UNIT_DEATH_STATE_CHANGED,
        REGISTER_FILTER_UNIT_TAG, "player")

    -- Boss death state
    EVENT_MANAGER:RegisterForEvent("BS_Effects_Death_Boss", EVENT_UNIT_DEATH_STATE_CHANGED, onBossDeathState)
    EVENT_MANAGER:AddFilterForEvent("BS_Effects_Death_Boss", EVENT_UNIT_DEATH_STATE_CHANGED,
        REGISTER_FILTER_UNIT_TAG_PREFIX, "boss")

    -- Group death state
    EVENT_MANAGER:RegisterForEvent("BS_Effects_Death_Group", EVENT_UNIT_DEATH_STATE_CHANGED, onGroupDeathState)
    EVENT_MANAGER:AddFilterForEvent("BS_Effects_Death_Group", EVENT_UNIT_DEATH_STATE_CHANGED,
        REGISTER_FILTER_UNIT_TAG_PREFIX, "group")

    -- Boss destroyed (despawn = treat like death)
    EVENT_MANAGER:RegisterForEvent("BS_Effects_Destroyed_Boss", EVENT_UNIT_DESTROYED, onBossDestroyed)
    EVENT_MANAGER:AddFilterForEvent("BS_Effects_Destroyed_Boss", EVENT_UNIT_DESTROYED,
        REGISTER_FILTER_UNIT_TAG_PREFIX, "boss")

    -- Group destroyed
    EVENT_MANAGER:RegisterForEvent("BS_Effects_Destroyed_Group", EVENT_UNIT_DESTROYED, onGroupDestroyed)
    EVENT_MANAGER:AddFilterForEvent("BS_Effects_Destroyed_Group", EVENT_UNIT_DESTROYED,
        REGISTER_FILTER_UNIT_TAG_PREFIX, "group")

    -- Boss created (spawn = treat like becoming alive)
    EVENT_MANAGER:RegisterForEvent("BS_Effects_Created_Boss", EVENT_UNIT_CREATED, onBossCreated)
    EVENT_MANAGER:AddFilterForEvent("BS_Effects_Created_Boss", EVENT_UNIT_CREATED,
        REGISTER_FILTER_UNIT_TAG_PREFIX, "boss")

    -- Group created
    EVENT_MANAGER:RegisterForEvent("BS_Effects_Created_Group", EVENT_UNIT_CREATED, onGroupCreated)
    EVENT_MANAGER:AddFilterForEvent("BS_Effects_Created_Group", EVENT_UNIT_CREATED,
        REGISTER_FILTER_UNIT_TAG_PREFIX, "group")

    -- Full effect refresh
    EVENT_MANAGER:RegisterForEvent("BS_Effects_FullUpdate", EVENT_EFFECTS_FULL_UPDATE, onEffectsFullUpdate)
end

function effectsEvents:Cleanup()
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Player", EVENT_EFFECT_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Boss", EVENT_EFFECT_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Group", EVENT_EFFECT_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Death_Player", EVENT_UNIT_DEATH_STATE_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Death_Boss", EVENT_UNIT_DEATH_STATE_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Death_Group", EVENT_UNIT_DEATH_STATE_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Destroyed_Boss", EVENT_UNIT_DESTROYED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Destroyed_Group", EVENT_UNIT_DESTROYED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Created_Boss", EVENT_UNIT_CREATED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Created_Group", EVENT_UNIT_CREATED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_FullUpdate", EVENT_EFFECTS_FULL_UPDATE)
end
