if not SemisPlaygroundCheckAccess() then
    return
end

-- Effect Reconciliation Scheduler for BattleScrolls
-- Periodically reconciles effect tracking with game state to catch missed events
-- Uses LibEffect for frame-aware scheduling

BattleScrolls = BattleScrolls or {}

---@class EffectsReconciler
---@field reconFiber any|nil Active reconciliation fiber
local reconciler = {}
BattleScrolls.effectsReconciler = reconciler

---Gets the current reconciliation preset settings
---@return { checkIntervalMs: number, cooldownPerUnitMs: number }
local function getPresetSettings()
    local settings = BattleScrolls.storage.savedVariables and BattleScrolls.storage.savedVariables.settings
    local presetKey = settings and settings.effectReconciliationPreset or "normal"
    local preset = BattleScrolls.storage.reconciliationPresets[presetKey]
    return preset or BattleScrolls.storage.reconciliationPresets.normal
end

---@type table<string, number>
local lastReconMs = {}             -- storageKey -> timestamp of last reconciliation
---@type number
local roundRobinIndex = 0

---@class ReconUnit
---@field key string Storage key (e.g., "player", "boss1", "@DisplayName")
---@field tag string Unit tag (e.g., "player", "boss1", "group3")

---@type ReconUnit[]
local existingUnits = {}           -- Reused table for unit list
---@type number
local existingUnitsCount = 0

-- Local alias to constants (performance)
local BOSS_TAGS = BattleScrolls.constants.BOSS_TAGS

-- =============================================================================
-- UNIT ENUMERATION
-- =============================================================================

---Gets list of units that can be reconciled in round-robin order
---Returns: player, then existing bosses, then existing group members
---Reuses the same table across calls to avoid allocations
---@return ReconUnit[] units Array of {key, tag} pairs
---@return number count Number of valid entries
local function getUnitsForRecon()
    local idx = 0

    local function addUnit(storageKey, unitTag)
        idx = idx + 1
        local entry = existingUnits[idx]
        if entry then
            entry.key = storageKey
            entry.tag = unitTag
        else
            existingUnits[idx] = { key = storageKey, tag = unitTag }
        end
    end

    -- Player is always first
    addUnit("player", "player")

    -- Bosses (only existing)
    for i = BOSS_RANK_ITERATION_BEGIN, BOSS_RANK_ITERATION_END do
        local bossTag = BOSS_TAGS[i]
        if DoesUnitExist(bossTag) then
            addUnit(bossTag, bossTag)
        end
    end

    -- Group members (only existing, not player, not companion)
    for i = 1, GetGroupSize() do
        local groupTag = GetGroupUnitTagByIndex(i)
        if groupTag
            and not AreUnitsEqual("player", groupTag)
            and not IsGroupCompanionUnitTag(groupTag) then
            local displayName = BattleScrolls.utils.GetUndecoratedDisplayName(groupTag)
            if displayName and displayName ~= "" then
                addUnit(displayName, groupTag)
            end
        end
    end

    -- Clear stale entries from previous calls
    for i = idx + 1, existingUnitsCount do
        existingUnits[i] = nil
    end
    if idx < existingUnitsCount then
        BattleScrolls.gc:RequestGC()
    end
    existingUnitsCount = idx

    return existingUnits, idx
end

-- =============================================================================
-- RECONCILIATION LOGIC
-- =============================================================================

---Attempts to reconcile the next unit that's due
---Called periodically by the update handler
local function tryReconcileNext()
    local state = BattleScrolls.state
    if not state or not state.inCombat then return end
    if reconciler.reconFiber then return end  -- Already running

    local preset = getPresetSettings()
    if preset.checkIntervalMs == 0 then return end  -- Reconciliation disabled

    local nowMs = GetGameTimeMilliseconds()
    local units, numUnits = getUnitsForRecon()

    if numUnits == 0 then return end

    -- Find next unit that's due for reconciliation
    for _ = 1, numUnits do
        roundRobinIndex = (roundRobinIndex % numUnits) + 1
        local unit = units[roundRobinIndex]
        local lastTime = lastReconMs[unit.key] or 0

        if (nowMs - lastTime) >= preset.cooldownPerUnitMs then
            lastReconMs[unit.key] = nowMs

            -- BattleScrolls.log.Trace(function()
            --     return string.format("[RECONCILE] Starting reconciliation for %s (tag=%s)", unit.key, unit.tag)
            -- end)

            BattleScrolls.effects.handleUnitFullRefresh(state, unit.tag)
            BattleScrolls.gc:RequestGC()

            return
        end
    end
end

-- =============================================================================
-- STATE OBSERVER
-- =============================================================================

function reconciler:OnStateInitialized()
    lastReconMs = {}
    roundRobinIndex = 0
    local preset = getPresetSettings()
    if preset.checkIntervalMs > 0 then
        EVENT_MANAGER:RegisterForUpdate("BS_EffectsReconcile", preset.checkIntervalMs, tryReconcileNext)
    end
end

function reconciler:OnStatePreReset()
    EVENT_MANAGER:UnregisterForUpdate("BS_EffectsReconcile")
    if self.reconFiber then
        self.reconFiber:Cancel()
        self.reconFiber = nil
    end
    lastReconMs = {}
    roundRobinIndex = 0
    BattleScrolls.gc:RequestGC()
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

function reconciler:Initialize()
    BattleScrolls.state:RegisterObserver(self)
end

function reconciler:Cleanup()
    EVENT_MANAGER:UnregisterForUpdate("BS_EffectsReconcile")
    if self.reconFiber then
        self.reconFiber:Cancel()
        self.reconFiber = nil
    end
end
