if not SemisPlaygroundCheckAccess() then
    return
end

-- Natural in-combat health recovery tracking.
-- Raw regen is integrated from alive time and the current health recovery stat.
-- Effective regen is reconciled from aggregate health movement.

BattleScrolls = BattleScrolls or {}

---@class HealthRecoveryEstimate
---@field raw number
---@field ticks number
---@field minTick number|nil
---@field maxTick number|nil

---@class BattleScrollsHealthRecovery : StateObserver
local healthRecovery = {}

BattleScrolls.healthRecovery = healthRecovery

local constants = BattleScrolls.constants
local TICK_INTERVAL_MS = 2000
local EVENT_NAMESPACE_POWER = "BattleScrolls_HealthRecovery_Power"
local EVENT_NAMESPACE_STATS = "BattleScrolls_HealthRecovery_Stats"

---@param value number
---@return number
local function round(value)
    return math.floor(value + 0.5)
end

---@param self BattleScrollsHealthRecovery
local function clearCombatState(self)
    self.active = false
    self.finalized = false
    self.lastHealthValue = 0
    self.lastHealthMax = 0
    self.positiveHealthGain = 0
    self.effectiveHealingToPlayer = 0
    self.currentRegen = 0
    self.lastAccountedMs = 0
    self.playerAlive = false
    self.aliveMs = 0
    self.rawRegenTotal = 0
    self.minTick = nil
    self.maxTick = nil
    self.estimate = self.estimate or {}
    self.estimate.raw = 0
    self.estimate.ticks = 0
    self.estimate.minTick = nil
    self.estimate.maxTick = nil
    self.appliedRaw = 0
    self.appliedEffective = 0
    self.appliedOverheal = 0
end

clearCombatState(healthRecovery)

---@return number
local function readCurrentRegen()
    return GetPlayerStat(STAT_HEALTH_REGEN_COMBAT, STAT_BONUS_OPTION_APPLY_BONUS) or 0
end

---@param self BattleScrollsHealthRecovery
local function resyncHealth(self)
    local current, max = GetUnitPower("player", COMBAT_MECHANIC_FLAGS_HEALTH)
    self.lastHealthValue = current or 0
    self.lastHealthMax = max or 0
end

---@param tracker BattleScrollsHealthRecovery
---@param now number
local function advanceRegen(tracker, now)
    local lastAccountedMs = tracker.lastAccountedMs or 0
    if not now or now <= lastAccountedMs then
        return
    end

    local deltaMs = now - lastAccountedMs
    if tracker.playerAlive and deltaMs > 0 then
        tracker.aliveMs = (tracker.aliveMs or 0) + deltaMs

        local regen = tracker.currentRegen or 0
        if regen > 0 then
            tracker.rawRegenTotal = (tracker.rawRegenTotal or 0) + regen * deltaMs / TICK_INTERVAL_MS
            tracker.minTick = tracker.minTick and math.min(tracker.minTick, regen) or regen
            tracker.maxTick = tracker.maxTick and math.max(tracker.maxTick, regen) or regen
        end
    end

    tracker.lastAccountedMs = now
end

---@param self BattleScrollsHealthRecovery
---@return HealthRecoveryEstimate
local function estimateRawRegen(self)
    local estimate = self.estimate
    estimate.raw = round(self.rawRegenTotal or 0)
    estimate.ticks = round((self.aliveMs or 0) / TICK_INTERVAL_MS)
    estimate.minTick = self.minTick
    estimate.maxTick = self.maxTick
    return estimate
end

---@param self BattleScrollsHealthRecovery
---@param state BattleScrollsState
---@param estimate HealthRecoveryEstimate
---@param effective number
local function materializeAggregateRegen(self, state, estimate, effective)
    local raw = math.max(0, estimate.raw or 0)
    effective = math.max(0, math.min(effective or 0, raw))
    local overheal = raw - effective
    local abilityId = constants.HEALTH_RECOVERY_ABILITY_ID
    local sourceUnitId = state:GetPersonalUnitId(COMBAT_UNIT_TYPE_PLAYER) or constants.INFERRED_PLAYER_UNIT_ID
    local previousRaw = self.appliedRaw or 0
    local previousEffective = self.appliedEffective or 0
    local previousOverheal = self.appliedOverheal or 0
    local selfHealing = state.healingStats.selfHealing

    selfHealing.total.raw = math.max(0, (selfHealing.total.raw or 0) - previousRaw + raw)
    selfHealing.total.real = math.max(0, (selfHealing.total.real or 0) - previousEffective + effective)
    selfHealing.total.overheal = math.max(0, (selfHealing.total.overheal or 0) - previousOverheal + overheal)

    if raw <= 0 then
        self.appliedRaw = 0
        self.appliedEffective = 0
        self.appliedOverheal = 0
        return
    end

    local playerName = GetRawUnitName("player") or ""

    state:MarkRegenAbility(abilityId)
    state:UpdateUnitName(sourceUnitId, playerName)
    state:UpdateUnitFriendliness(sourceUnitId, COMBAT_UNIT_TYPE_PLAYER)

    local bySource = selfHealing.bySourceUnitIdByAbilityId
    if not bySource[sourceUnitId] then
        bySource[sourceUnitId] = {}
    end

    local breakdown = bySource[sourceUnitId][abilityId]
    if not breakdown then
        breakdown = BattleScrolls.structures.newHealingBreakdown(estimate.minTick or raw)
        bySource[sourceUnitId][abilityId] = breakdown
    end

    breakdown.raw = raw
    breakdown.real = effective
    breakdown.overheal = overheal
    breakdown.ticks = math.max(1, estimate.ticks or 0)
    breakdown.critTicks = 0
    breakdown.minTick = estimate.minTick or raw
    breakdown.maxTick = estimate.maxTick or raw

    self.appliedRaw = raw
    self.appliedEffective = effective
    self.appliedOverheal = overheal
end

---@param combatEndMs number|nil
---@return number
local function resolveAccountEndMs(combatEndMs)
    return combatEndMs or GetGameTimeMilliseconds()
end

---@param state BattleScrollsState
---@param combatEndMs number|nil
function healthRecovery:Refresh(state, combatEndMs)
    if not self.active or self.finalized or not state or not state.initialized then
        return
    end

    combatEndMs = resolveAccountEndMs(combatEndMs)
    advanceRegen(self, combatEndMs)

    local estimate = estimateRawRegen(self)
    local effective = math.max(0, self.positiveHealthGain - self.effectiveHealingToPlayer)
    effective = math.min(effective, estimate.raw)
    materializeAggregateRegen(self, state, estimate, effective)
end

---@param _eventCode number
---@param _unitTag string
---@param _powerIndex number
---@param _powerType number
---@param powerValue number
---@param powerMax number
local function onPowerUpdate(_eventCode, _unitTag, _powerIndex, _powerType, powerValue, powerMax)
    if not healthRecovery.active or healthRecovery.finalized then
        return
    end

    local previousValue = healthRecovery.lastHealthValue or powerValue
    local previousMax = healthRecovery.lastHealthMax or powerMax
    local delta = powerValue - previousValue
    local maxChanged = powerMax ~= previousMax

    if not maxChanged and delta > 0 and healthRecovery.playerAlive and not IsUnitDead("player") then
        healthRecovery.positiveHealthGain = healthRecovery.positiveHealthGain + delta
    end

    healthRecovery.lastHealthValue = powerValue
    healthRecovery.lastHealthMax = powerMax
end

local function onStatsUpdated()
    if healthRecovery.active and not healthRecovery.finalized then
        local now = GetGameTimeMilliseconds()
        advanceRegen(healthRecovery, now)
        healthRecovery.currentRegen = readCurrentRegen()
    end
end

---@param hitValue number
function healthRecovery:OnPlayerHealthHealing(hitValue)
    if not self.active or not hitValue or hitValue <= 0 then
        return
    end
    self.effectiveHealingToPlayer = self.effectiveHealingToPlayer + hitValue
end

---@param isDead boolean
function healthRecovery:OnPlayerDeathState(isDead)
    if not self.active then
        return
    end

    local now = GetGameTimeMilliseconds()
    advanceRegen(self, now)
    self.playerAlive = not isDead
    resyncHealth(self)
end

function healthRecovery:OnStateInitialized()
    clearCombatState(self)
    self.active = true
    local now = GetGameTimeMilliseconds()
    self.currentRegen = readCurrentRegen()
    self.lastAccountedMs = now
    self.playerAlive = not IsUnitDead("player")
    resyncHealth(self)
end

function healthRecovery:OnStatePreReset()
    if self.active and not self.finalized then
        self:Finalize(BattleScrolls.state)
    end
    clearCombatState(self)
end

---@param state BattleScrollsState
function healthRecovery:OnStatePreTick(state)
    self:Refresh(state)
end

---@param state BattleScrollsState
---@param combatEndMs number|nil
function healthRecovery:Finalize(state, combatEndMs)
    if self.finalized or not self.active or not state or not state.initialized then
        return
    end

    self:Refresh(state, combatEndMs)
    self.finalized = true
end

function healthRecovery:Initialize()
    BattleScrolls.state:RegisterObserver(self)

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE_POWER, EVENT_POWER_UPDATE, onPowerUpdate)
    EVENT_MANAGER:AddFilterForEvent(EVENT_NAMESPACE_POWER, EVENT_POWER_UPDATE,
        REGISTER_FILTER_UNIT_TAG, "player",
        REGISTER_FILTER_POWER_TYPE, COMBAT_MECHANIC_FLAGS_HEALTH)

    EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE_STATS, EVENT_STATS_UPDATED, onStatsUpdated)
    EVENT_MANAGER:AddFilterForEvent(EVENT_NAMESPACE_STATS, EVENT_STATS_UPDATED,
        REGISTER_FILTER_UNIT_TAG, "player")
end
