-----------------------------------------------------------
-- Zen
-- Z'en's Redress stack tracking for Battle Scrolls
--
-- For each boss, integrates time spent with 0..5 of the player's
-- damage-over-time effects active on it, each split by whether the
-- player's own Touch of Z'en was applied. Tracked regardless of
-- whether the player wears Z'en's, so the "what uptime WOULD I have"
-- question is answerable.
--
-- DoT classification: a player-sourced debuff whose ability type
-- is ABILITY_TYPE_DAMAGE - taken straight from the EFFECT_CHANGED
-- event arguments (the LibCombat approach; verified in game that
-- non-DoT damage effects like Haunting Curse report
-- ABILITY_TYPE_NONE). Distinct ability ids count once, matching
-- how the set stacks.
--
-- Hooked from effects_events' boss effect/death handlers, gated
-- by the boss effect tracking setting like the rest of them.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

-- Touch of Z'en (Z'en's Redress 5pc debuff)
local ZEN_DEBUFF_ABILITY_ID = 126597

local MAX_DOTS = 5
local BUCKET_COUNT = (MAX_DOTS + 1) * 2

---Per-boss Z'en tracking
---@class ZenTargetState
---@field dotSlots table<number, number> effectSlot -> abilityId for active player DoT debuffs
---@field countByAbility table<number, number> abilityId -> active instance count
---@field distinctDots number Count of distinct DoT ability ids currently active
---@field zenSlots table<number, boolean> effectSlot set for active Touch of Z'en instances
---@field zenActive boolean
---@field buckets number[] 12 time buckets in ms: index = dots*2 + (zen and 2 or 1)
---@field lastChangeMs number
---@field frozen boolean True while the boss is dead (no integration)

---Live Z'en tracking state (attached to BattleScrollsState)
---@class ZenState
---@field perTarget table<string, ZenTargetState> keyed by "bossTag:tagSeq" (different bosses can reuse a tag over a fight)

---@class BattleScrollsZen
local zen = {}
BattleScrolls.zen = zen

---Storage key for a boss target: "bossN:seq". state.bossesByTag carries the
---live sequence number - the same source the damage path's
---bossTagSeqByUnitId uses, so zen rows line up with damage rows.
---@param state BattleScrollsState
---@param unitTag string
---@return string
local function targetKey(state, unitTag)
    local bossData = state.bossesByTag[unitTag]
    return unitTag .. ":" .. (bossData and bossData.tagSeq or 0)
end


---Creates a fresh ZenState for a new combat encounter
---@return ZenState
function zen.newState()
    return { perTarget = {} }
end

---@param z ZenState
---@param unitTag string
---@param nowMs number
---@return ZenTargetState
local function getOrCreateTarget(z, unitTag, nowMs)
    local target = z.perTarget[unitTag]
    if not target then
        target = {
            dotSlots = {},
            countByAbility = {},
            distinctDots = 0,
            zenSlots = {},
            zenActive = false,
            buckets = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
            lastChangeMs = nowMs,
            frozen = false,
        }
        z.perTarget[unitTag] = target
    end
    return target
end

---Accumulates elapsed time into the current bucket
---@param target ZenTargetState
---@param nowMs number
local function integrate(target, nowMs)
    if not target.frozen then
        local dots = target.distinctDots
        if dots > MAX_DOTS then dots = MAX_DOTS end
        local idx = dots * 2 + (target.zenActive and 2 or 1)
        target.buckets[idx] = target.buckets[idx] + (nowMs - target.lastChangeMs)
    end
    target.lastChangeMs = nowMs
end

---Integrates and freezes a target, clearing tracked effect instances
---@param target ZenTargetState
---@param nowMs number
local function freezeTarget(target, nowMs)
    if target.frozen then return end
    integrate(target, nowMs)
    target.frozen = true
    target.dotSlots = {}
    target.countByAbility = {}
    target.distinctDots = 0
    target.zenSlots = {}
    target.zenActive = false
end

---Handles boss effect changes (called from effects_events.onBossEffect)
---@param state BattleScrollsState
---@param changeType number
---@param effectSlot number
---@param unitTag string
---@param effectType number
---@param abilityType number ABILITY_TYPE_* from the effect event
---@param abilityId number
---@param sourceType number
function zen.handleBossEffect(state, changeType, effectSlot, unitTag, effectType, abilityType, abilityId, sourceType)
    local z = state.zen
    if not z then return end

    local isZen = abilityId == ZEN_DEBUFF_ABILITY_ID and sourceType == COMBAT_UNIT_TYPE_PLAYER
    local isPlayerDot = sourceType == COMBAT_UNIT_TYPE_PLAYER
        and effectType == BUFF_EFFECT_TYPE_DEBUFF
        and abilityType == ABILITY_TYPE_DAMAGE

    if changeType == EFFECT_RESULT_FADED then
        -- FADED events can carry sparse info; act on tracked slots only
        local target = z.perTarget[targetKey(state, unitTag)]
        if not target then return end
        local nowMs = GetGameTimeMilliseconds()
        if target.zenSlots[effectSlot] then
            integrate(target, nowMs)
            target.zenSlots[effectSlot] = nil
            target.zenActive = next(target.zenSlots) ~= nil
            return
        end
        local slotAbility = target.dotSlots[effectSlot]
        if slotAbility then
            integrate(target, nowMs)
            target.dotSlots[effectSlot] = nil
            local count = (target.countByAbility[slotAbility] or 1) - 1
            if count <= 0 then
                target.countByAbility[slotAbility] = nil
                target.distinctDots = target.distinctDots - 1
            else
                target.countByAbility[slotAbility] = count
            end
        end
        return
    end

    if changeType ~= EFFECT_RESULT_GAINED and changeType ~= EFFECT_RESULT_UPDATED then
        return
    end
    if not isZen and not isPlayerDot then
        return
    end

    local nowMs = GetGameTimeMilliseconds()
    local target = getOrCreateTarget(z, targetKey(state, unitTag), nowMs)

    if isZen then
        if not target.zenSlots[effectSlot] then
            integrate(target, nowMs)
            target.zenSlots[effectSlot] = true
            target.zenActive = true
        end
        return
    end

    if not target.dotSlots[effectSlot] then
        integrate(target, nowMs)
        target.dotSlots[effectSlot] = abilityId
        local count = (target.countByAbility[abilityId] or 0) + 1
        target.countByAbility[abilityId] = count
        if count == 1 then
            target.distinctDots = target.distinctDots + 1
        end
    end
end

---Handles boss death/despawn: integrate and freeze (effects are wiped on
---death, so tracked instances are cleared too)
---@param state BattleScrollsState
---@param unitTag string
function zen.handleUnitDeath(state, unitTag)
    local z = state.zen
    local target = z and z.perTarget[targetKey(state, unitTag)]
    if not target then return end
    freezeTarget(target, GetGameTimeMilliseconds())
end

---Handles boss revival/respawn: unfreeze from now
---@param state BattleScrollsState
---@param unitTag string
function zen.handleUnitAlive(state, unitTag)
    local z = state.zen
    local target = z and z.perTarget[targetKey(state, unitTag)]
    if not target or not target.frozen then return end
    target.lastChangeMs = GetGameTimeMilliseconds()
    target.frozen = false
end

---Called by state when a boss tag gets reused by a different boss (tagSeq
---rotation): the old incarnation's tracking must freeze, or its lingering
---DoT slots would keep accumulating bucket time until combat end.
---@param state BattleScrollsState
---@param unitTag string
---@param oldSeq number The sequence number being retired
function zen.onBossTagRotated(state, unitTag, oldSeq)
    local z = state.zen
    local target = z and z.perTarget[unitTag .. ":" .. oldSeq]
    if not target then return end
    freezeTarget(target, GetGameTimeMilliseconds())
end

---Encounter-ready Z'en data: per "bossTag:tagSeq" key, 12 time buckets in
---ms (index = dots*2 + (zenApplied and 2 or 1), dots 0..5)
---@alias ZenData table<string, number[]>

---Finalizes zen state into encounter-ready data
---@param z ZenState
---@param endTimeMs number Fight end (absolute game time ms)
---@return ZenData|nil data Nil when nothing was tracked
function zen.finalize(z, endTimeMs)
    ---@type ZenData
    local result = {}
    local any = false
    for unitTag, target in pairs(z.perTarget) do
        integrate(target, endTimeMs)
        -- Only keep targets with recorded time under a DoT or Z'en.
        -- Bucket 1 alone is idle time and carries no signal.
        local meaningful = false
        for i = 2, BUCKET_COUNT do
            if target.buckets[i] > 0 then
                meaningful = true
                break
            end
        end
        if meaningful then
            result[unitTag] = target.buckets
            any = true
        end
    end
    if any then
        return result
    end
    return nil
end

---Aggregates ZenData into per-boss group-share metrics, counting only time
---the player's Z'en debuff was up on that boss. Bosses it never touched
---are omitted.
---@param zenData ZenData|nil
---@return SharedZenBoss[]|nil entries Sorted by boss tag; nil when Z'en never landed
function zen.shareByBoss(zenData)
    if not zenData then
        return nil
    end
    ---@type SharedZenBoss[]
    local result = {}
    for key, buckets in pairs(zenData) do
        local withZenMs, weightedMs = 0, 0
        for dots = 0, 5 do
            local ms = buckets[dots * 2 + 2] or 0
            withZenMs = withZenMs + ms
            weightedMs = weightedMs + dots * ms
        end
        if withZenMs > 0 then
            local bossTag, tagSeq = key:match("^(.-):(%d+)$")
            result[#result + 1] = {
                bossTag = bossTag or key,
                tagSeq = tonumber(tagSeq) or 0,
                avgStacksTenths = math.floor(weightedMs / withZenMs * 10 + 0.5),
                timeAt5Ms = buckets[12] or 0,
            }
        end
    end
    if #result == 0 then
        return nil
    end
    table.sort(result, function(a, b)
        if a.bossTag ~= b.bossTag then return a.bossTag < b.bossTag end
        return a.tagSeq < b.tagSeq
    end)
    return result
end
