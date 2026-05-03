-----------------------------------------------------------
-- Weaving
-- Light attack weaving and rotation tracking for Battle Scrolls
--
-- Tracks skill activations, confirmed LA/HA hits, cast delay between
-- skills, and weaving errors (missed LAs, double LAs).
--
-- Uses EVENT_ACTION_SLOT_ABILITY_USED for activation timing
-- and per-abilityId combat event handlers for LA confirmation.
--
-- Interface:
--   weaving:Initialize()          -- Register events, discover LA IDs
--   weaving:Cleanup()             -- Unregister all events
--   weaving:OnCombatStart()       -- Re-discover LA IDs on combat entry
--   weaving:OnLightAttackConfirmed() -- LA confirmed by combat event
--   weaving:FlushPendingGaps()    -- Finalize pending skill gaps at combat end
--   weaving.newState()            -- Factory for WeavingState subtable
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class WeavingState
---@field lastSkillStartTime number|nil Effective start time of last skill activation (transient)
---@field lastSkillEndTime number|nil Estimated end time of last skill activation (transient)
---@field lastSkillAbilityId number|nil Ability ID of last skill activation (transient)
---@field currentGapCandidateLaCount number LA inputs after the last skill, before the next skill closes the gap
---@field currentGapConfirmedLaCount number Confirmed LAs assigned to the open gap after the last skill
---@field currentGapHeavyAttackCount number Confirmed HAs assigned to the open gap after the last skill
---@field ungappedLaCandidateCount number LA inputs before the first tracked skill
---@field ungappedLaCandidateDeadlineMs number Last timestamp that can accept ungapped LA confirmations
---@field pendingGaps table<number, WeavingPendingGap> Closed skill gaps waiting for delayed LA confirmations
---@field pendingGapHead number Queue head index for pendingGaps
---@field pendingGapTail number Queue tail index for pendingGaps
---@field pendingGapPool WeavingPendingGap[] Reusable gap records
---@field weavingByAbilityId table<number, WeavingAccumulator> Per-ability weaving accumulators
---@field lightAttackHits number Light attack count (confirmed by combat events)
---@field heavyAttackHits number Heavy attack count (from ACTION_RESULT_BEGIN)
---@field skillActivations number Total skill/ultimate activations
---@field totalWeavingErrors number Total skill->skill count (no LA in between)
---@field doubleLaErrors number Total la->la count (double light attack without a skill)

---@class WeavingPendingGap
---@field prevSkillAbilityId number Skill before the closed gap
---@field deadlineMs number Last timestamp that can accept delayed LA confirmations for this gap
---@field candidateLaCount number LA inputs observed inside this gap
---@field confirmedLaCount number Confirmed LAs assigned to this gap
---@field heavyAttackCount number Confirmed HAs assigned to this gap

---@class BattleScrollsWeaving
local weaving = {}

BattleScrolls.weaving = weaving

-- ============================================================================
-- Constants
-- ============================================================================

-- Slot 1 = light attack, slot 2 = heavy attack, slots 3-8 = skills/ultimate
local LA_SLOT = 1
local SKILL_SLOT_MIN = 3
local SKILL_SLOT_MAX = 8
local LA_CONFIRM_GRACE_MS = 500

-- Exhausting Fatecarver: channel time extends by 338ms per Crux stack consumed
local CRUX_MS_PER_STACK = 338
local EXHAUSTING_FATECARVER_ID = 193397

-- Event tracking for cleanup
local combatEventNames = {}

-- LA abilityId tracking (persists across combats, not part of WeavingState)
weaving.laAbilityIds = {}
weaving.laUsesEffectGained = {}

-- ============================================================================
-- Event Registration Helpers
-- ============================================================================

---Registers a combat event with filter pairs and tracks the name for cleanup
---@param name string Unique event namespace
---@param callback fun(...)
---@param ... any Filter pairs (filterType, filterValue, ...)
local function registerCombatEvent(name, callback, ...)
    combatEventNames[#combatEventNames + 1] = name
    EVENT_MANAGER:RegisterForEvent(name, EVENT_COMBAT_EVENT, callback)
    EVENT_MANAGER:AddFilterForEvent(name, EVENT_COMBAT_EVENT, ...)
end

-- ============================================================================
-- State Factory and Clear
-- ============================================================================

---Creates a fresh WeavingState for a new combat encounter
---@return WeavingState
function weaving.newState()
    return {
        lastSkillStartTime = nil,
        lastSkillEndTime = nil,
        lastSkillAbilityId = nil,
        currentGapCandidateLaCount = 0,
        currentGapConfirmedLaCount = 0,
        currentGapHeavyAttackCount = 0,
        ungappedLaCandidateCount = 0,
        ungappedLaCandidateDeadlineMs = 0,
        pendingGaps = {},
        pendingGapHead = 1,
        pendingGapTail = 0,
        pendingGapPool = {},
        weavingByAbilityId = {},
        lightAttackHits = 0,
        heavyAttackHits = 0,
        skillActivations = 0,
        totalWeavingErrors = 0,
        doubleLaErrors = 0,
    }
end

-- ============================================================================
-- Helpers
-- ============================================================================

---@param w WeavingState
---@param abilityId number
---@return WeavingAccumulator
local function getOrCreateWeavingEntry(w, abilityId)
    local entry = w.weavingByAbilityId[abilityId]
    if not entry then
        entry = { activations = 0, afterSum = 0, afterCount = 0, beforeSum = 0, beforeCount = 0, errors = 0 }
        w.weavingByAbilityId[abilityId] = entry
    end
    return entry
end

---Attributes weaving time for a confirmed LA weave between two skills
---@param w WeavingState
---@param prevSkillAbilityId number|nil Skill before the LA (for "after" attribution)
---@param thisSkillAbilityId number Skill after the LA (for "before" attribution)
---@param thisSkillTime number Timestamp of the skill after the LA
---@param prevSkillEndTime number Estimated end time of the skill before the LA
local function attributeWeavingTime(w, prevSkillAbilityId, thisSkillAbilityId, thisSkillTime, prevSkillEndTime)
    local weavingTime = zo_max(0, thisSkillTime - prevSkillEndTime)

    -- "After" attribution: weave time after the previous skill
    if prevSkillAbilityId then
        local afterEntry = getOrCreateWeavingEntry(w, prevSkillAbilityId)
        afterEntry.afterSum = afterEntry.afterSum + weavingTime
        afterEntry.afterCount = afterEntry.afterCount + 1
    end

    -- "Before" attribution: weave time before this skill
    local beforeEntry = getOrCreateWeavingEntry(w, thisSkillAbilityId)
    beforeEntry.beforeSum = beforeEntry.beforeSum + weavingTime
    beforeEntry.beforeCount = beforeEntry.beforeCount + 1
end

---@param w WeavingState
---@return WeavingPendingGap
local function acquirePendingGap(w)
    local pool = w.pendingGapPool
    local gap = pool[#pool]
    if gap then
        pool[#pool] = nil
        return gap
    end
    return {}
end

---@param w WeavingState
---@param gap WeavingPendingGap
local function releasePendingGap(w, gap)
    gap.prevSkillAbilityId = nil
    gap.deadlineMs = nil
    gap.candidateLaCount = nil
    gap.confirmedLaCount = nil
    gap.heavyAttackCount = nil
    w.pendingGapPool[#w.pendingGapPool + 1] = gap
end

---@param w WeavingState
local function resetCurrentGap(w)
    w.currentGapCandidateLaCount = 0
    w.currentGapConfirmedLaCount = 0
    w.currentGapHeavyAttackCount = 0
end

---Classifies a closed skill gap after delayed LA confirmations have settled.
---@param w WeavingState
---@param gap WeavingPendingGap
local function finalizeGap(w, gap)
    if gap.confirmedLaCount == 0 and gap.heavyAttackCount == 0 then
        local entry = getOrCreateWeavingEntry(w, gap.prevSkillAbilityId)
        entry.errors = entry.errors + 1
        w.totalWeavingErrors = w.totalWeavingErrors + 1
    elseif gap.confirmedLaCount > 1 then
        w.doubleLaErrors = w.doubleLaErrors + gap.confirmedLaCount - 1
    end
end

---@param w WeavingState
---@param prevSkillAbilityId number
---@param now number
local function enqueuePendingGap(w, prevSkillAbilityId, now)
    local gap = acquirePendingGap(w)
    gap.prevSkillAbilityId = prevSkillAbilityId
    gap.deadlineMs = now + LA_CONFIRM_GRACE_MS
    gap.candidateLaCount = w.currentGapCandidateLaCount
    gap.confirmedLaCount = w.currentGapConfirmedLaCount
    gap.heavyAttackCount = w.currentGapHeavyAttackCount

    w.pendingGapTail = w.pendingGapTail + 1
    w.pendingGaps[w.pendingGapTail] = gap
    resetCurrentGap(w)
end

---@param w WeavingState
---@param now number
local function finalizeExpiredGaps(w, now)
    if w.ungappedLaCandidateCount > 0 and w.ungappedLaCandidateDeadlineMs <= now then
        w.ungappedLaCandidateCount = 0
        w.ungappedLaCandidateDeadlineMs = 0
    end

    while w.pendingGapHead <= w.pendingGapTail do
        local gap = w.pendingGaps[w.pendingGapHead]
        if not gap or gap.deadlineMs > now then
            return
        end
        w.pendingGaps[w.pendingGapHead] = nil
        w.pendingGapHead = w.pendingGapHead + 1
        finalizeGap(w, gap)
        releasePendingGap(w, gap)
    end

    w.pendingGapHead = 1
    w.pendingGapTail = 0
end

---@param w WeavingState
local function finalizeAllPendingGaps(w)
    while w.pendingGapHead <= w.pendingGapTail do
        local gap = w.pendingGaps[w.pendingGapHead]
        w.pendingGaps[w.pendingGapHead] = nil
        w.pendingGapHead = w.pendingGapHead + 1
        if gap then
            finalizeGap(w, gap)
            releasePendingGap(w, gap)
        end
    end

    w.pendingGapHead = 1
    w.pendingGapTail = 0
end

---@param w WeavingState
---@param now number
local function recordLightAttackCandidate(w, now)
    if w.lastSkillAbilityId then
        w.currentGapCandidateLaCount = w.currentGapCandidateLaCount + 1
    else
        w.ungappedLaCandidateCount = w.ungappedLaCandidateCount + 1
        w.ungappedLaCandidateDeadlineMs = now + LA_CONFIRM_GRACE_MS
    end
end

---@param w WeavingState
local function attachHeavyAttackConfirmation(w)
    if w.lastSkillAbilityId then
        w.currentGapHeavyAttackCount = w.currentGapHeavyAttackCount + 1
    end
end

---@param w WeavingState
---@param now number
---@return boolean
local function attachLightAttackConfirmation(w, now)
    for i = w.pendingGapHead, w.pendingGapTail do
        local gap = w.pendingGaps[i]
        if gap and now <= gap.deadlineMs and gap.confirmedLaCount < gap.candidateLaCount then
            gap.confirmedLaCount = gap.confirmedLaCount + 1
            return true
        end
    end

    if w.lastSkillAbilityId and w.currentGapConfirmedLaCount < w.currentGapCandidateLaCount then
        w.currentGapConfirmedLaCount = w.currentGapConfirmedLaCount + 1
        return true
    end

    if w.ungappedLaCandidateCount > 0 and now <= w.ungappedLaCandidateDeadlineMs then
        w.ungappedLaCandidateCount = w.ungappedLaCandidateCount - 1
        return true
    end

    return false
end

-- ============================================================================
-- Event Handlers
-- ============================================================================

---Finalizes closed skill gaps at combat end.
---The currently open gap after the last skill is not classified because it has no following skill.
function weaving:FlushPendingGaps()
    local state = BattleScrolls.state
    if not state then return end
    local w = state.weaving
    finalizeAllPendingGaps(w)
end

---Handles ability slot activation for weaving time tracking
---@param actionSlotIndex number
function weaving:OnActionSlotAbilityUsed(actionSlotIndex)
    local state = BattleScrolls.state
    if not state or not state.initialized then
        return
    end
    local w = state.weaving
    local now = GetGameTimeMilliseconds()
    finalizeExpiredGaps(w, now)

    if actionSlotIndex == LA_SLOT then
        -- Runtime discovery: register EFFECT_GAINED handler for new LA ability IDs
        local laId = GetSlotBoundId(actionSlotIndex)
        if laId and laId > 0 and not self.laAbilityIds[laId] then
            self.laAbilityIds[laId] = true
            self:RegisterLaConfirmHandler(laId)
        end

        recordLightAttackCandidate(w, now)
    elseif actionSlotIndex >= SKILL_SLOT_MIN and actionSlotIndex <= SKILL_SLOT_MAX then
        -- Skill or ultimate
        -- Resolve ability ID: scribing abilities return craftedAbilityId from GetSlotBoundId
        local abilityId
        local slotType = GetSlotType(actionSlotIndex)
        if slotType == ACTION_TYPE_CRAFTED_ABILITY then
            local craftedAbilityId = GetSlotBoundId(actionSlotIndex)
            abilityId = GetAbilityIdForCraftedAbilityId(craftedAbilityId)
        else
            abilityId = GetSlotBoundId(actionSlotIndex)
        end

        -- Compute cast delay for every closed skill gap.
        if w.lastSkillEndTime then
            attributeWeavingTime(w, w.lastSkillAbilityId, abilityId, now, w.lastSkillEndTime)
            enqueuePendingGap(w, w.lastSkillAbilityId, now)
        else
            resetCurrentGap(w)
        end

        -- Track per-ability activation count
        local entry = getOrCreateWeavingEntry(w, abilityId)
        entry.activations = entry.activations + 1

        -- Estimate when this skill's GCD/cast ends
        -- Use max(now, prevStart+GCD) as effective activation: a queued skill
        -- can't start before the previous GCD ends. We anchor to startTime+1000
        -- (not endTime) so canceled channels don't cascade errors forward —
        -- GCD is always 1000ms regardless of cast/channel duration.
        -- GetAbilityCastInfo returns: channeled (bool|nil), durationMs (int|nil)
        local _, durationMs = GetAbilityCastInfo(abilityId, nil, "player")
        -- Exhausting Fatecarver: channel extends by 338ms per Crux stack consumed.
        -- Race: Crux events may fire before or after this SLOT in the same frame.
        -- Use cruxRecentMax if within the event burst window; otherwise current stacks.
        if EXHAUSTING_FATECARVER_ID == abilityId then
            local stacks = state.cruxStacks
            if (now - state.cruxWindowStartMs) < 100 then
                stacks = zo_max(state.cruxRecentMax, stacks)
            end
            if stacks > 0 then
                durationMs = (durationMs or 0) + stacks * CRUX_MS_PER_STACK
            end
        end
        local effectiveStart = now
        local lastSkillStartTime = w.lastSkillStartTime or 0
        -- if it hasn't been a second since the last skill fired, current skill is queued and will fire
        -- once GCD is over
        if lastSkillStartTime < now and now < lastSkillStartTime + 1000 then
            effectiveStart = (w.lastSkillStartTime or 0) + 1000
        end
        w.lastSkillStartTime = effectiveStart
        w.lastSkillEndTime = effectiveStart + zo_max(1000, durationMs or 0)
        w.lastSkillAbilityId = abilityId
        w.skillActivations = w.skillActivations + 1
    end
    -- Slot 2 (heavy attack) intentionally ignored here — counted via ACTION_RESULT_BEGIN
end

---Handles combat event confirmation that an LA actually executed.
---Called from per-abilityId EFFECT_GAINED handlers (projectile) or from state's OnCombatEvent (melee).
---@param _abilityId number|nil
function weaving:OnLightAttackConfirmed(_abilityId)
    local state = BattleScrolls.state
    if not state or not state.initialized then
        return
    end
    local w = state.weaving
    local now = GetGameTimeMilliseconds()
    if attachLightAttackConfirmation(w, now) then
        w.lightAttackHits = w.lightAttackHits + 1
    end
    finalizeExpiredGaps(w, now)
end

---Handles ACTION_RESULT_BEGIN for heavy attack counting
---@param abilityActionSlotType number
function weaving:OnHeavyAttackBegin(abilityActionSlotType)
    local state = BattleScrolls.state
    if not state or not state.initialized then
        return
    end
    if abilityActionSlotType == ACTION_SLOT_TYPE_HEAVY_ATTACK then
        local now = GetGameTimeMilliseconds()
        local w = state.weaving
        finalizeExpiredGaps(w, now)
        attachHeavyAttackConfirmation(w)
        w.heavyAttackHits = w.heavyAttackHits + 1
    end
end

-- ============================================================================
-- LA Ability ID Discovery
-- ============================================================================

---Discovers LA ability IDs from both action bars and registers confirm handlers.
---Called at init and on combat start (swaps between fights pick up new weapon IDs).
function weaving:RegisterLaAbilityIds()
    local bar1Id = GetSlotBoundId(1, HOTBAR_CATEGORY_PRIMARY)
    local bar2Id = GetSlotBoundId(1, HOTBAR_CATEGORY_BACKUP)

    for _, laId in ipairs({ bar1Id, bar2Id }) do
        if laId and laId > 0 and not self.laAbilityIds[laId] then
            self.laAbilityIds[laId] = true
            self:RegisterLaConfirmHandler(laId)
        end
    end
end

---Registers an EFFECT_GAINED combat event handler for a specific LA ability ID
---@param laAbilityId number
function weaving:RegisterLaConfirmHandler(laAbilityId)
    local self_ = self
    local eventName = "BattleScrolls_LAConfirm_" .. laAbilityId
    registerCombatEvent(eventName,
            function()
                self_.laUsesEffectGained[laAbilityId] = true
                self_:OnLightAttackConfirmed(laAbilityId)
            end,
            REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_EFFECT_GAINED,
            REGISTER_FILTER_ABILITY_ID, laAbilityId,
            REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

---Called when combat starts to re-discover LA ability IDs (handles swaps between fights)
function weaving:OnCombatStart()
    self:RegisterLaAbilityIds()
end

---Registers all weaving event handlers
function weaving:Initialize()
    local self_ = self

    -- Skill/LA slot activation
    EVENT_MANAGER:RegisterForEvent("BattleScrolls_Weaving", EVENT_ACTION_SLOT_ABILITY_USED,
            function(_, actionSlotIndex)
                self_:OnActionSlotAbilityUsed(actionSlotIndex)
            end)

    -- Heavy attack counting via ACTION_RESULT_BEGIN (fires exactly once per HA)
    registerCombatEvent("BattleScrolls_HABegin",
            function(_, _, _, _, _, abilityActionSlotType)
                self_:OnHeavyAttackBegin(abilityActionSlotType)
            end,
            REGISTER_FILTER_COMBAT_RESULT, ACTION_RESULT_BEGIN,
            REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)

    -- LA confirmation: register per-abilityId EFFECT_GAINED handlers
    -- Projectile weapons (bow, destruction staves) fire EFFECT_GAINED ~200ms after LA
    -- Melee weapons (2H, DW, 1H+S, resto) are confirmed via DAMAGE in state's OnCombatEvent
    self.laAbilityIds = {}
    self.laUsesEffectGained = {}
    self:RegisterLaAbilityIds()
end

---Unregisters all weaving event handlers
function weaving:Cleanup()
    for _, name in ipairs(combatEventNames) do
        EVENT_MANAGER:UnregisterForEvent(name, EVENT_COMBAT_EVENT)
    end
    combatEventNames = {}

    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Weaving", EVENT_ACTION_SLOT_ABILITY_USED)
end
