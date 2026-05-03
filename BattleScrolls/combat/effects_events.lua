if not SemisPlaygroundCheckAccess() then
    return
end

-- Effect Event Registration for BattleScrolls
-- Owns combat-time EVENT_EFFECT_CHANGED subscriptions and routes them to
-- lightweight core consumers (boss identity, shields) plus optional effect
-- uptime tracking.

BattleScrolls = BattleScrolls or {}

---@type BattleScrollsEffects
local effects = BattleScrolls.effects

---@class EffectsEvents : StateObserver
---@field Initialize fun(self: EffectsEvents) Register as state observer
---@field Cleanup fun(self: EffectsEvents) Unregister all event handlers
local effectsEvents = {}
BattleScrolls.effectsEvents = effectsEvents

---@type string
local PATTERN_GROUP = "^group"

local trackPlayerEffectsThisCombat = false
local trackBossEffectsThisCombat = false
local trackGroupEffectsThisCombat = false

-- =============================================================================
-- SETTINGS HELPERS
-- =============================================================================

---@return boolean
local function isPlayerEffectsNeeded()
    local settings = BattleScrolls.storage and BattleScrolls.storage.savedVariables and BattleScrolls.storage.savedVariables.settings
    if settings and settings.effectTrackingEnabled == false then return false end
    local buffs = not (settings and settings.trackPlayerBuffs == false)
    local debuffs = not (settings and settings.trackPlayerDebuffs == false)
    return buffs or debuffs
end

---@return boolean
local function isBossEffectsNeeded()
    local settings = BattleScrolls.storage and BattleScrolls.storage.savedVariables and BattleScrolls.storage.savedVariables.settings
    if settings and settings.effectTrackingEnabled == false then return false end
    return not (settings and settings.trackBossDebuffs == false)
end

---@return boolean
local function isGroupEffectsNeeded()
    local settings = BattleScrolls.storage and BattleScrolls.storage.savedVariables and BattleScrolls.storage.savedVariables.settings
    if settings and settings.effectTrackingEnabled == false then return false end
    return not (settings and settings.trackGroupBuffs == false)
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

local function onPlayerEffect(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime,
                              stackCount, iconName, deprecatedBuffType, effectType, abilityType,
                              statusEffectType, unitName, unitId, abilityId, sourceType)
    local s = BattleScrolls.state
    if not s then return end

    local shieldTracker = BattleScrolls.shields
    if shieldTracker and shieldTracker.OnEffectChanged then
        shieldTracker:OnEffectChanged(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime,
            stackCount, iconName, deprecatedBuffType, effectType, abilityType,
            statusEffectType, unitName, unitId, abilityId, sourceType)
    end

    if trackPlayerEffectsThisCombat then
        effects.handlePlayerEffect(s, changeType, effectSlot, effectType, stackCount, abilityId, sourceType, beginTime)
    end
end

local function onBossEffect(_eventCode, changeType, effectSlot, _effectName, unitTag, beginTime, _endTime,
                            stackCount, _iconName, _deprecatedBuffType, effectType, _abilityType,
                            _statusEffectType, unitName, unitId, abilityId, sourceType)
    local s = BattleScrolls.state
    if not s then return end
    -- Correlate boss unitTag↔unitId from authoritative effect events (non-faded only;
    -- faded events can maybe carry stale unitIds from despawned bosses)
    if changeType ~= EFFECT_RESULT_FADED then
        -- Detect tag reuse before CorrelateBossUnitId replaces old BossData
        if s.bossNames[unitTag] and s.bossNames[unitTag] ~= unitName then
            local oldBossData = s.bossesByTag[unitTag]
            effects.retireBossTag(s, unitTag, oldBossData and oldBossData.unitId)
        end
        s:CorrelateBossUnitId(unitTag, unitId, unitName)
    end
    if trackBossEffectsThisCombat then
        effects.handleBossEffect(s, changeType, effectSlot, unitTag, effectType, stackCount, abilityId, unitId, sourceType, beginTime)
    end
end

local function onGroupEffect(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime,
                             stackCount, iconName, deprecatedBuffType, effectType, abilityType,
                             statusEffectType, unitName, unitId, abilityId, sourceType)
    local s = BattleScrolls.state
    if not s then return end
    if AreUnitsEqual("player", unitTag) then return end
    if IsGroupCompanionUnitTag(unitTag) then return end

    local shieldTracker = BattleScrolls.shields
    if shieldTracker and shieldTracker.OnEffectChanged then
        shieldTracker:OnEffectChanged(eventCode, changeType, effectSlot, effectName, unitTag, beginTime, endTime,
            stackCount, iconName, deprecatedBuffType, effectType, abilityType,
            statusEffectType, unitName, unitId, abilityId, sourceType)
    end

    if trackGroupEffectsThisCombat then
        effects.handleGroupEffect(s, changeType, effectSlot, unitTag, effectType, stackCount, abilityId, unitId, sourceType, beginTime, endTime)
    end
end

local function onPlayerDeathState(_eventCode, unitTag, isDead)
    if not AreUnitsEqual("player", unitTag) then return end
    local s = BattleScrolls.state
    if not s then return end
    if isDead then
        effects.handlePlayerDeath(s)
    else
        effects.handlePlayerAlive(s)
    end
end

local function onBossDeathState(_eventCode, unitTag, isDead)
    local s = BattleScrolls.state
    if not s then return end
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
    if not s then return end
    if isDead then
        effects.handleUnitDeath(s, unitTag)
    else
        effects.handleUnitAlive(s, unitTag)
    end
end

local function onBossDestroyed(_eventCode, unitTag)
    local s = BattleScrolls.state
    if not s then return end
    effects.handleUnitDeath(s, unitTag)
end

local function onGroupDestroyed(_eventCode, unitTag)
    if AreUnitsEqual("player", unitTag) then return end
    if IsGroupCompanionUnitTag(unitTag) then return end
    local s = BattleScrolls.state
    if not s then return end
    -- Treat as death if offline OR actually dead
    -- Portal entry = online and not dead = still alive
    if not IsUnitOnline(unitTag) or IsUnitDead(unitTag) then
        effects.handleUnitDeath(s, unitTag)
    end
end

local function onBossCreated(_eventCode, unitTag)
    local s = BattleScrolls.state
    if not s then return end
    -- Detect tag reuse before state update (old BossData still accessible)
    if s.bossNames[unitTag] then
        local newName = GetRawUnitName(unitTag)
        if s.bossNames[unitTag] ~= newName then
            local oldBossData = s.bossesByTag[unitTag]
            effects.retireBossTag(s, unitTag, oldBossData and oldBossData.unitId)
        end
    end
    -- Notify state of boss unit creation (detects tag reuse for damage tracking)
    s:OnBossUnitCreated(unitTag)
    -- Do full refresh which reconciles both alive state and effects
    effects.handleBossFullRefresh(s, unitTag)
end

local function onGroupCreated(_eventCode, unitTag)
    if AreUnitsEqual("player", unitTag) then return end
    if IsGroupCompanionUnitTag(unitTag) then return end
    local s = BattleScrolls.state
    if not s then return end
    -- Do full refresh which reconciles both alive state and effects
    effects.handleGroupFullRefresh(s, unitTag)
end

local function onGroupConnectedStatus(_eventCode, unitTag, isOnline)
    if AreUnitsEqual("player", unitTag) then return end
    if IsGroupCompanionUnitTag(unitTag) then return end
    if not unitTag:find(PATTERN_GROUP) then return end
    local s = BattleScrolls.state
    if not s then return end
    if isOnline then
        -- Do full refresh which reconciles both alive state and effects
        effects.handleGroupFullRefresh(s, unitTag)
    else
        -- Offline = treat as dead for effect tracking purposes
        effects.handleUnitDeath(s, unitTag)
    end
end

local function onEffectsFullUpdate(_eventCode)
    local s = BattleScrolls.state
    if not s then return end
    effects.handleFullRefreshAll(s)
end

-- =============================================================================
-- EVENT SUBSCRIPTION
-- =============================================================================

---Subscribes to death/alive/lifecycle events (always needed during combat for alive tracking)
local function subscribeAliveEvents()
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

    -- Group connected status (online/offline)
    EVENT_MANAGER:RegisterForEvent("BS_Effects_Connected_Group", EVENT_GROUP_MEMBER_CONNECTED_STATUS, onGroupConnectedStatus)

    -- Full effect refresh (runs alive reconciliation unconditionally)
    EVENT_MANAGER:RegisterForEvent("BS_Effects_FullUpdate", EVENT_EFFECTS_FULL_UPDATE, onEffectsFullUpdate)
end

---Subscribes to effect change events needed by core combat plumbing.
local function subscribeEffectEvents()
    trackPlayerEffectsThisCombat = isPlayerEffectsNeeded()
    trackBossEffectsThisCombat = isBossEffectsNeeded()
    trackGroupEffectsThisCombat = isGroupEffectsNeeded()

    EVENT_MANAGER:RegisterForEvent("BS_Effects_Player", EVENT_EFFECT_CHANGED, onPlayerEffect)
    EVENT_MANAGER:AddFilterForEvent("BS_Effects_Player", EVENT_EFFECT_CHANGED,
        REGISTER_FILTER_UNIT_TAG, "player")

    EVENT_MANAGER:RegisterForEvent("BS_Effects_Boss", EVENT_EFFECT_CHANGED, onBossEffect)
    EVENT_MANAGER:AddFilterForEvent("BS_Effects_Boss", EVENT_EFFECT_CHANGED,
        REGISTER_FILTER_UNIT_TAG_PREFIX, "boss")

    EVENT_MANAGER:RegisterForEvent("BS_Effects_Group", EVENT_EFFECT_CHANGED, onGroupEffect)
    EVENT_MANAGER:AddFilterForEvent("BS_Effects_Group", EVENT_EFFECT_CHANGED,
        REGISTER_FILTER_UNIT_TAG_PREFIX, "group")
end

---Unsubscribes from all events
local function unsubscribeAll()
    -- Effect events (may not be registered — UnregisterForEvent is safe to call regardless)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Player", EVENT_EFFECT_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Boss", EVENT_EFFECT_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Group", EVENT_EFFECT_CHANGED)

    -- Alive/lifecycle events
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Death_Player", EVENT_UNIT_DEATH_STATE_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Death_Boss", EVENT_UNIT_DEATH_STATE_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Death_Group", EVENT_UNIT_DEATH_STATE_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Destroyed_Boss", EVENT_UNIT_DESTROYED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Destroyed_Group", EVENT_UNIT_DESTROYED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Created_Boss", EVENT_UNIT_CREATED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Created_Group", EVENT_UNIT_CREATED)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_Connected_Group", EVENT_GROUP_MEMBER_CONNECTED_STATUS)
    EVENT_MANAGER:UnregisterForEvent("BS_Effects_FullUpdate", EVENT_EFFECTS_FULL_UPDATE)

    trackPlayerEffectsThisCombat = false
    trackBossEffectsThisCombat = false
    trackGroupEffectsThisCombat = false
end

-- =============================================================================
-- STATE OBSERVER
-- =============================================================================

function effectsEvents:OnStateInitialized()
    subscribeAliveEvents()
    subscribeEffectEvents()
end

function effectsEvents:OnStatePreReset()
    unsubscribeAll()
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

function effectsEvents:Initialize()
    BattleScrolls.state:RegisterObserver(self)
end

function effectsEvents:Cleanup()
    unsubscribeAll()
end
