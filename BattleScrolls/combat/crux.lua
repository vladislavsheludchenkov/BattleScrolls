-----------------------------------------------------------
-- Crux
-- Arcanist Crux economy tracking for Battle Scrolls
--
-- Every observed stack gain is credited to exactly one bucket: a generator
-- cast (byAbility.gained), a conditional source (conditionalGains) or
-- unattributedGains, so gains always reconcile against drops. Explanations
-- for a gain are claimed first-come first-served by event time; synthetic
-- Cruxweaver Armor guesses claim last.
--
-- Drops with no spender cast nearby are split into death (the player was
-- dead when the buff faded) and passive (expiry or unexplained).
--
-- Conditional generation pairs stack gains with observable proc events:
-- gate passes, Spattering Disjunction procs and Tome-Bearer pulse hits
-- emit EVENT_COMBAT_EVENTs; Class Mastery generation comes with a
-- secondary-effect buff; scribed Class Flourish casts count as generators.
-- Cruxweaver Armor emits nothing and is reconstructed from damage taken
-- under its buff on a ~5s cooldown. Banner Bearer's in-combat crux pulse
-- emits nothing either and is reclaimed by elimination. Sources that only
-- generate at zero Crux (Tome-Bearer line, Banner) never count as wasted;
-- an unpaired proc of any other source found Crux full (conditionalWasted).
--
-- No class gate: Crux is reachable on any class via subclassing.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

local MAX_CRUX = 3
local CRUX_ABILITY_ID = 184220

-- Same-batch delivery jitter between a Crux effect event and the SLOT press
-- or proc event that explains it
local CRUX_EVENT_PAIR_WINDOW_MS = 400

-- A SLOT press fires client-side; its Crux effect arrives with the server
-- response (well past a second under load). One-shot: the first effect it
-- explains consumes it.
local CAST_EFFECT_WINDOW_MS = 1500

local DEATH_ORDER_GUARD_MS = 500

-- Gate passes: EFFECT_GAINED with player source AND player target (a cast
-- emits enemy/entity-targeted events only). Two sub-ids per morph, one per
-- pass direction.
---@type table<number, number>
local CRUX_GATE_PASS_SOURCES = {
    [183544] = 183542, [183547] = 183542, -- Apocryphal Gate
    [186212] = 186211, [186214] = 186211, -- Fleet-Footed Gate
    [186221] = 186220, [186223] = 186220, -- Passage Between Worlds
}

---@type table<number, number>
local CRUX_PROC_EFFECT_SOURCES = {
    [227565] = 227381, -- Spattering Disjunction
}

-- Tome-Bearer line pulse-empowered hits (the proc-tracking damage ids)
---@type table<number, number>
local CRUX_PROC_DAMAGE_SOURCES = {
    [185843] = 185842, -- Inspired Scholarship
    [186453] = 186452, -- Tome-Bearer's Inspiration
    [183048] = 183047, -- Recuperative Treatise
}

-- Proc sources that fire regardless of the stack count: an unpaired proc
-- of one of these means Crux was full
---@type table<number, boolean>
local CRUX_OVERCAP_SOURCES = {
    [183542] = true, [186211] = true, [186220] = true, -- gates
    [227381] = true, -- Spattering Disjunction
    [263419] = true, -- Ink-Scribe's Verve
}

-- Scribing: the Class Flourish signature script makes a scribed cast a
-- generator. Banner Bearer instead pulses every 5s (a Crux at 0 stacks,
-- else +3 ultimate): the crux pulse emits no event, the ult pulse
-- energizes as 252143, and out of combat the timer ticks as 227116.
local CLASS_FLOURISH_SCRIPT_ID = 31
local BANNER_BEARER_CRAFTED_ID = 12

-- Banner fallback: a gain still unexplained a second later is the banner's
-- silent pulse if a banner tick was ever sighted but none landed within the
-- pulse cycle around the gain (a visible tick there means that pulse slot
-- was an ult one)
local BANNER_TICK_OOC_ID = 227116
local BANNER_TICK_ULT_ID = 252143
local BANNER_FALLBACK_AFTER_MS = 1000
local BANNER_TICK_BEFORE_MS = 4000
local BANNER_TICK_AFTER_MS = 1000

-- Cruxweaver Armor: damage taken under the buff generates a Crux on a ~5s
-- cooldown with no client event. At full Crux an eligible hit wastes a
-- stack and starts the cooldown; otherwise it parks a synthetic proc until
-- a gain confirms it. Match gains delivered before the hit first.
-- The gate compensates observation jitter: an early observation lengthens
-- the next gate, a late one never shortens it below base. Recasting is
-- assumed to reset the cooldown (unverified in game).
local ARMOR_PROC_NOMINAL_MS = 5000
local ARMOR_PROC_MARGIN_MS = 50
local CRUX_ARMOR_BUFF_ID = 185908

-- Class Mastery: the secondary-effect buff appearing grants the mapped
-- number of Crux at once (fill-to-max sources, never counted as wasted)
---@type table<number, number>
local CRUX_MASTERY_BUFF_GAIN_SOURCES = {
    [263369] = 3, -- Abyssal Emergence
    [268372] = 3, -- Fate Realigned
}

-- Ink-Scribe's Verve: consuming the buff grants a Crux together with Major
-- Force; natural expiry grants nothing. A FADED paired with a Major Force
-- gain/refresh within the window is a consumption.
local VERVE_BUFF_ID = 263419
local MAJOR_FORCE_BUFF_ID = 61747
local VERVE_PAIR_WINDOW_MS = 100

local SKILL_SLOT_MIN = 3
local SKILL_SLOT_MAX = 8

-- Slotted abilities that generate 1 Crux on cast. Conditional generators are
-- excluded (recasting them at full Crux is upkeep, not waste). Alias pairs
-- share name/icon with a varying slotted id.
---@type table<number, boolean>
local CRUX_GENERATORS = {
    -- Herald of the Tome
    [185794] = true, [188658] = true, -- Runeblades
    [185803] = true, [188787] = true, -- Writhing Runeblades
    [182977] = true, [188780] = true, -- Escalating Runeblades
    [183006] = true,                  -- Cephaliarch's Flail
    -- Soldier of Apocrypha
    [183165] = true, -- Runic Jolt
    [183430] = true, -- Runic Sunder
    [186531] = true, -- Runic Embrace
    -- Curative Runeforms
    [183261] = true, [198282] = true, -- Runemend
    [186189] = true, [198288] = true, -- Evolving Runemend
    [186191] = true, [198292] = true, -- Audacious Runemend
    [186207] = true, [198564] = true, -- Chakram of Destiny
    -- Vengeance Apocryphal Gate teleports on cast
    [238545] = true,
}

-- Slotted abilities that consume all Crux
---@type table<number, boolean>
local CRUX_SPENDERS = {
    -- Herald of the Tome
    [185805] = true, [193331] = true, -- Fatecarver
    [183122] = true, [193397] = true, -- Exhausting Fatecarver
    [186366] = true, [193398] = true, -- Pragmatic Fatecarver
    [185823] = true,                  -- Tentacular Dread
    -- Soldier of Apocrypha
    [185894] = true, -- Runespite Ward
    [185901] = true, -- Spiteward of the Lucid Mind
    [183241] = true, -- Impervious Runeward
    [186477] = true, -- Unbreakable Fate
    -- Curative Runeforms
    [183537] = true, [198309] = true, -- Remedy Cascade
    [186193] = true, [198330] = true, -- Cascading Fortune
    [186200] = true, [198537] = true, -- Curative Surge
    [186209] = true, [198567] = true, -- Tidal Chakram
    -- Vengeance variants
    [238174] = true, -- Vengeance Fatecarver
    [238249] = true, -- Vengeance Runespite Ward
    [238482] = true, -- Vengeance Remedy Cascade
}

---Per-ability Crux activity
---@class CruxAbilityActivity
---@field casts number
---@field bad number Generator casts at full Crux, or spender casts under 3
---@field gained number Observed stack gains paired with this generator's casts

---@class CruxPendingProc
---@field ms number
---@field id number Canonical source id
---@field stacks number Crux left to claim
---@field synthetic boolean|nil Armor guess from a damage hit; claimed last

---@class CruxPendingStacks
---@field ms number
---@field stacks number
---@field dead boolean|nil Player was dead when the stacks dropped

---Live Crux tracking state (attached to BattleScrollsState)
---@class CruxActivityState
---@field generatorCasts number
---@field generatorAtFull number
---@field spenderCasts number
---@field spenderUnder number[] Spender casts by pre-cast Crux: [1]=at 0, [2]=at 1, [3]=at 2
---@field byAbility table<number, CruxAbilityActivity>
---@field passiveEvents number Drops with neither a spender cast nor a death nearby
---@field passiveStacks number
---@field deathEvents number Drops while the player was dead
---@field deathStacks number
---@field pendingSpenderCastMs number Spender press awaiting its drop (0 = none)
---@field pendingDrops CruxPendingStacks[] Drops awaiting a late spender press
---@field conditionalGains table<number, number> Canonical source id -> Crux paired with its procs
---@field conditionalWasted table<number, number> Canonical source id -> procs that found Crux full
---@field unattributedGains number
---@field pendingGeneratorCastMs number Generator press awaiting its gain (0 = none)
---@field pendingGeneratorAbilityId number
---@field pendingProcs CruxPendingProc[] Proc events awaiting their gain
---@field pendingGains CruxPendingStacks[] Unexplained gains awaiting a late proc event

---@class BattleScrollsCrux : StateObserver
local crux = {}
BattleScrolls.crux = crux

local armorBuffActive = false
local lastArmorProcMs = 0
local armorIcdFloorMs = ARMOR_PROC_NOMINAL_MS - ARMOR_PROC_MARGIN_MS
local lastVerveFadedMs = 0
local lastMajorForceMs = 0
local bannerLastSeenMs = 0

crux.CRUX_GENERATORS = CRUX_GENERATORS
crux.CRUX_SPENDERS = CRUX_SPENDERS

---@param nowMs number
---@return boolean
local function armorIcdReady(nowMs)
    return lastArmorProcMs == 0 or (nowMs - lastArmorProcMs) >= armorIcdFloorMs
end

---@param nowMs number
local function onArmorProc(nowMs)
    if lastArmorProcMs > 0 then
        local interval = nowMs - lastArmorProcMs
        armorIcdFloorMs = zo_max(ARMOR_PROC_NOMINAL_MS - ARMOR_PROC_MARGIN_MS,
            2 * ARMOR_PROC_NOMINAL_MS - ARMOR_PROC_MARGIN_MS - interval)
    end
    lastArmorProcMs = nowMs
end

---@return CruxActivityState
function crux.newState()
    return {
        generatorCasts = 0,
        generatorAtFull = 0,
        spenderCasts = 0,
        spenderUnder = { 0, 0, 0 },
        byAbility = {},
        passiveEvents = 0,
        passiveStacks = 0,
        deathEvents = 0,
        deathStacks = 0,
        pendingSpenderCastMs = 0,
        pendingDrops = {},
        conditionalGains = {},
        conditionalWasted = {},
        unattributedGains = 0,
        pendingGeneratorCastMs = 0,
        pendingGeneratorAbilityId = 0,
        pendingProcs = {},
        pendingGains = {},
    }
end

---Current Crux stack count from the player's buff list
---@return number
function crux.readCurrentStacks()
    for i = 1, GetNumBuffs("player") do
        local _, _, _, _, stackCount, _, _, _, _, _, abilityId = GetUnitBuffInfo("player", i)
        if abilityId == CRUX_ABILITY_ID then
            return stackCount or 0
        end
    end
    return 0
end

---@param state BattleScrollsState
---@return CruxActivityState
local function getOrCreateActivity(state)
    local c = state.cruxActivity
    if not c then
        c = crux.newState()
        state.cruxActivity = c
    end
    return c
end

---@param c CruxActivityState
---@param abilityId number
---@return CruxAbilityActivity
local function getOrCreateEntry(c, abilityId)
    local entry = c.byAbility[abilityId]
    if not entry then
        entry = { casts = 0, bad = 0, gained = 0 }
        c.byAbility[abilityId] = entry
    end
    return entry
end

---@param c CruxActivityState
---@param nowMs number
---@param lastDeathMs number Game time of the last player death (0 = none)
local function settlePendingDrops(c, nowMs, lastDeathMs)
    local pending = c.pendingDrops
    local i = 1
    while i <= #pending do
        local drop = pending[i]
        if (nowMs - drop.ms) > CRUX_EVENT_PAIR_WINDOW_MS then
            local deathAfterDrop = lastDeathMs >= drop.ms and (lastDeathMs - drop.ms) <= DEATH_ORDER_GUARD_MS
            if drop.dead or deathAfterDrop then
                c.deathEvents = c.deathEvents + 1
                c.deathStacks = c.deathStacks + drop.stacks
            else
                c.passiveEvents = c.passiveEvents + 1
                c.passiveStacks = c.passiveStacks + drop.stacks
            end
            table.remove(pending, i)
        else
            i = i + 1
        end
    end
end

---@param c CruxActivityState
---@param nowMs number
local function settlePendingProcs(c, nowMs)
    local pending = c.pendingProcs
    local i = 1
    while i <= #pending do
        local proc = pending[i]
        if (nowMs - proc.ms) > CRUX_EVENT_PAIR_WINDOW_MS then
            if not proc.synthetic and proc.stacks > 0 and CRUX_OVERCAP_SOURCES[proc.id] then
                c.conditionalWasted[proc.id] = (c.conditionalWasted[proc.id] or 0) + proc.stacks
            end
            table.remove(pending, i)
        else
            i = i + 1
        end
    end
end

---@param c CruxActivityState
---@param nowMs number
local function settlePendingGains(c, nowMs)
    local pending = c.pendingGains
    local i = 1
    while i <= #pending do
        local entry = pending[i]
        if (nowMs - entry.ms) > BANNER_FALLBACK_AFTER_MS then
            local sinceSighting = entry.ms - bannerLastSeenMs
            local silentPulse = bannerLastSeenMs > 0
                and (sinceSighting >= BANNER_TICK_BEFORE_MS
                    or -sinceSighting >= BANNER_TICK_AFTER_MS)
            if silentPulse then
                c.conditionalGains[BANNER_TICK_OOC_ID] =
                    (c.conditionalGains[BANNER_TICK_OOC_ID] or 0) + entry.stacks
            else
                c.unattributedGains = c.unattributedGains + entry.stacks
            end
            table.remove(pending, i)
        else
            i = i + 1
        end
    end
end

---Claims unexplained gains delivered before their source event
---@param c CruxActivityState
---@param canonicalId number
---@param stacks number
---@param nowMs number
---@return number claimedNow
local function claimPendingGains(c, canonicalId, stacks, nowMs)
    settlePendingGains(c, nowMs)
    local pending = c.pendingGains
    local remaining = stacks
    local i = 1
    while remaining > 0 and i <= #pending do
        local gainEntry = pending[i]
        if (nowMs - gainEntry.ms) <= CRUX_EVENT_PAIR_WINDOW_MS then
            local take = zo_min(remaining, gainEntry.stacks)
            c.conditionalGains[canonicalId] = (c.conditionalGains[canonicalId] or 0) + take
            gainEntry.stacks = gainEntry.stacks - take
            remaining = remaining - take
            if gainEntry.stacks <= 0 then
                table.remove(pending, i)
            else
                i = i + 1
            end
        else
            i = i + 1
        end
    end
    return stacks - remaining
end

---Handles a conditional-generation proc worth `stacks` Crux: claims recent
---unexplained gains (either delivery order is possible) or parks the rest
---for the gain still to arrive
---@param canonicalId number
---@param stacks number
local function onConditionalProc(canonicalId, stacks)
    local state = BattleScrolls.state
    if not state or not state.initialized then
        return
    end
    local c = getOrCreateActivity(state)
    local now = GetGameTimeMilliseconds()
    local remaining = stacks - claimPendingGains(c, canonicalId, stacks, now)
    if remaining > 0 then
        c.pendingProcs[#c.pendingProcs + 1] =
            { ms = now, id = canonicalId, stacks = remaining }
    end
end

---Called from state on every damage hit the player takes
function crux.onPlayerDamaged()
    local state = BattleScrolls.state
    if not state or not state.initialized or not armorBuffActive then
        return
    end
    local now = GetGameTimeMilliseconds()
    if not armorIcdReady(now) then
        return
    end
    local c = getOrCreateActivity(state)
    if claimPendingGains(c, CRUX_ARMOR_BUFF_ID, 1, now) > 0 then
        onArmorProc(now)
    elseif state.cruxStacks == MAX_CRUX then
        -- Use the current count, not the burst-window maximum: a recent
        -- spend may already have made room for this proc's gain.
        c.conditionalWasted[CRUX_ARMOR_BUFF_ID] = (c.conditionalWasted[CRUX_ARMOR_BUFF_ID] or 0) + 1
        onArmorProc(now)
    else
        c.pendingProcs[#c.pendingProcs + 1] =
            { ms = now, id = CRUX_ARMOR_BUFF_ID, stacks = 1, synthetic = true }
    end
end

---@param c CruxActivityState
---@param nowMs number
---@return boolean
local function generatorArmed(c, nowMs)
    return c.pendingGeneratorCastMs > 0 and (nowMs - c.pendingGeneratorCastMs) <= CAST_EFFECT_WINDOW_MS
end

---Called from state's Crux effect handler on every stack change
---@param state BattleScrollsState
---@param oldStacks number
---@param newStacks number
function crux.onCruxStacksChanged(state, oldStacks, newStacks)
    if not state.initialized then
        return
    end
    local c = getOrCreateActivity(state)
    local now = GetGameTimeMilliseconds()
    BattleScrolls.log.Debug(function()
        return string.format("Crux %d->%d spender=%d gen=%d procs=%d gains=%d drops=%d",
            oldStacks, newStacks,
            c.pendingSpenderCastMs > 0 and (now - c.pendingSpenderCastMs) or -1,
            c.pendingGeneratorCastMs > 0 and (now - c.pendingGeneratorCastMs) or -1,
            #c.pendingProcs, #c.pendingGains, #c.pendingDrops)
    end)

    local gain = newStacks - oldStacks
    if gain > 0 then
        settlePendingProcs(c, now)
        settlePendingGains(c, now)
        local procs = c.pendingProcs
        local genArmed = generatorArmed(c, now)
        local genMs = c.pendingGeneratorCastMs
        local function claimGenerator()
            if genArmed and gain > 0 then
                genArmed = false
                c.pendingGeneratorCastMs = 0
                local entry = getOrCreateEntry(c, c.pendingGeneratorAbilityId)
                entry.gained = entry.gained + 1
                gain = gain - 1
            end
        end
        local i = 1
        while gain > 0 and i <= #procs do
            local proc = procs[i]
            if proc.synthetic then
                i = i + 1
            else
                if genArmed and genMs <= proc.ms then
                    claimGenerator()
                end
                if gain > 0 then
                    local take = zo_min(gain, proc.stacks)
                    c.conditionalGains[proc.id] = (c.conditionalGains[proc.id] or 0) + take
                    gain = gain - take
                    proc.stacks = proc.stacks - take
                    if proc.stacks <= 0 then
                        table.remove(procs, i)
                    else
                        i = i + 1
                    end
                end
            end
        end
        claimGenerator()
        i = 1
        while gain > 0 and i <= #procs do
            if procs[i].synthetic and armorIcdReady(now) then
                local proc = table.remove(procs, i)
                c.conditionalGains[proc.id] = (c.conditionalGains[proc.id] or 0) + 1
                onArmorProc(now)
                gain = gain - 1
            else
                i = i + 1
            end
        end
        if gain > 0 then
            c.pendingGains[#c.pendingGains + 1] = { ms = now, stacks = gain }
        end
        return
    end

    local drop = -gain
    if drop <= 0 then
        return
    end
    settlePendingDrops(c, now, state.lastPlayerDeathMs)
    if c.pendingSpenderCastMs > 0 and (now - c.pendingSpenderCastMs) <= CAST_EFFECT_WINDOW_MS then
        c.pendingSpenderCastMs = 0
        return
    end
    c.pendingDrops[#c.pendingDrops + 1] = { ms = now, stacks = drop, dead = IsUnitDead("player") }
end

---@param actionSlotIndex number
local function onActionSlotUsed(actionSlotIndex)
    if actionSlotIndex < SKILL_SLOT_MIN or actionSlotIndex > SKILL_SLOT_MAX then
        return
    end
    local state = BattleScrolls.state
    if not state or not state.initialized then
        return
    end
    local abilityId
    local craftedId
    if GetSlotType(actionSlotIndex) == ACTION_TYPE_CRAFTED_ABILITY then
        craftedId = GetSlotBoundId(actionSlotIndex)
        abilityId = GetAbilityIdForCraftedAbilityId(craftedId)
    else
        abilityId = GetSlotBoundId(actionSlotIndex)
    end
    if not abilityId or abilityId <= 0 then
        return
    end

    local isGenerator = CRUX_GENERATORS[abilityId]
    local isSpender = CRUX_SPENDERS[abilityId]
    if not isGenerator and not isSpender and craftedId and craftedId ~= BANNER_BEARER_CRAFTED_ID then
        local _, signatureScriptId = GetCraftedAbilityActiveScriptIds(craftedId)
        isGenerator = signatureScriptId == CLASS_FLOURISH_SCRIPT_ID
    end
    if not isGenerator and not isSpender then
        return
    end
    local c = getOrCreateActivity(state)

    -- Pre-cast stacks: Crux effect events race the SLOT event, so use the
    -- burst-window max like weaving does for Fatecarver duration
    local now = GetGameTimeMilliseconds()
    local stacks = state.cruxStacks
    if (now - state.cruxWindowStartMs) < 100 then
        stacks = zo_max(state.cruxRecentMax, stacks)
    end
    BattleScrolls.log.Debug(function()
        return string.format("Crux %s %d at %d stacks", isGenerator and "generator" or "spender", abilityId, stacks)
    end)

    local entry = getOrCreateEntry(c, abilityId)
    entry.casts = entry.casts + 1

    if isGenerator then
        c.generatorCasts = c.generatorCasts + 1
        if stacks >= MAX_CRUX then
            c.generatorAtFull = c.generatorAtFull + 1
            entry.bad = entry.bad + 1
            return
        end
        local pending = c.pendingGains
        for i = #pending, 1, -1 do
            if (now - pending[i].ms) <= CRUX_EVENT_PAIR_WINDOW_MS then
                pending[i].stacks = pending[i].stacks - 1
                if pending[i].stacks <= 0 then
                    table.remove(pending, i)
                end
                entry.gained = entry.gained + 1
                return
            end
        end
        c.pendingGeneratorCastMs = now
        c.pendingGeneratorAbilityId = abilityId
    else
        c.spenderCasts = c.spenderCasts + 1
        local claimed = false
        local pending = c.pendingDrops
        for i = #pending, 1, -1 do
            if (now - pending[i].ms) <= CRUX_EVENT_PAIR_WINDOW_MS then
                table.remove(pending, i)
                claimed = true
                break
            end
        end
        if not claimed then
            c.pendingSpenderCastMs = now
        end
        if stacks < MAX_CRUX then
            c.spenderUnder[stacks + 1] = c.spenderUnder[stacks + 1] + 1
            entry.bad = entry.bad + 1
        end
    end
end

---Encounter-ready Crux data (stored per encounter)
---@class CruxData
---@field generatorCasts number
---@field generatorAtFull number
---@field spenderCasts number
---@field spenderUnder number[] [1]=at 0 Crux, [2]=at 1, [3]=at 2
---@field byAbility table<number, CruxAbilityActivity>
---@field passiveEvents number Drops with neither a spender cast nor a death nearby
---@field passiveStacks number
---@field deathEvents number Drops while the player was dead
---@field deathStacks number
---@field conditionalGains table<number, number> Canonical source id -> Crux paired with its procs
---@field conditionalWasted table<number, number> Canonical source id -> procs that found Crux full
---@field unattributedGains number

---Finalizes crux state into encounter-ready data
---@param c CruxActivityState|nil
---@param endTimeMs number|nil Absolute game time of combat end
---@param lastDeathMs number Game time of the last player death (0 = none)
---@return CruxData|nil data Nil when no Crux activity was seen
function crux.finalize(c, endTimeMs, lastDeathMs)
    if not c then
        return nil
    end
    local settleMs = (endTimeMs or GetGameTimeMilliseconds()) + BANNER_FALLBACK_AFTER_MS + 1
    settlePendingDrops(c, settleMs, lastDeathMs)
    settlePendingProcs(c, settleMs)
    settlePendingGains(c, settleMs)
    local hasConditional = next(c.conditionalGains) ~= nil or next(c.conditionalWasted) ~= nil
        or c.unattributedGains > 0
    if c.generatorCasts == 0 and c.spenderCasts == 0 and c.passiveEvents == 0 and c.deathEvents == 0
            and not hasConditional then
        return nil
    end
    return {
        generatorCasts = c.generatorCasts,
        generatorAtFull = c.generatorAtFull,
        spenderCasts = c.spenderCasts,
        spenderUnder = c.spenderUnder,
        byAbility = c.byAbility,
        passiveEvents = c.passiveEvents,
        passiveStacks = c.passiveStacks,
        deathEvents = c.deathEvents,
        deathStacks = c.deathStacks,
        conditionalGains = c.conditionalGains,
        conditionalWasted = c.conditionalWasted,
        unattributedGains = c.unattributedGains,
    }
end

---@param eventAbilityId number
---@param canonicalId number
---@param isDamageProc boolean
---@param filterTargetPlayer boolean
local function registerConditionalSource(eventAbilityId, canonicalId, isDamageProc, filterTargetPlayer)
    local namespace = "BattleScrolls_Crux_Cond" .. eventAbilityId
    local damageResults = BattleScrolls.constants.damageResultsSet
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_COMBAT_EVENT, function(_, result)
        local matches
        if isDamageProc then
            matches = damageResults[result]
        else
            matches = result == ACTION_RESULT_EFFECT_GAINED
        end
        if matches then
            onConditionalProc(canonicalId, 1)
        end
    end)
    EVENT_MANAGER:AddFilterForEvent(namespace, EVENT_COMBAT_EVENT,
            REGISTER_FILTER_ABILITY_ID, eventAbilityId,
            REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
    if filterTargetPlayer then
        EVENT_MANAGER:AddFilterForEvent(namespace, EVENT_COMBAT_EVENT,
                REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
    end
end

---@param buffAbilityId number
---@param grantedStacks number
local function registerBuffGainSource(buffAbilityId, grantedStacks)
    local namespace = "BattleScrolls_Crux_Buff" .. buffAbilityId
    EVENT_MANAGER:RegisterForEvent(namespace, EVENT_EFFECT_CHANGED, function(_, changeType)
        if changeType == EFFECT_RESULT_GAINED then
            onConditionalProc(buffAbilityId, grantedStacks)
        end
    end)
    EVENT_MANAGER:AddFilterForEvent(namespace, EVENT_EFFECT_CHANGED,
            REGISTER_FILTER_ABILITY_ID, buffAbilityId,
            REGISTER_FILTER_UNIT_TAG, "player")
end

local function onVerveFaded()
    local now = GetGameTimeMilliseconds()
    if lastMajorForceMs > 0 and (now - lastMajorForceMs) <= VERVE_PAIR_WINDOW_MS then
        lastMajorForceMs = 0
        onConditionalProc(VERVE_BUFF_ID, 1)
    else
        lastVerveFadedMs = now
    end
end

local function onMajorForceGained()
    local now = GetGameTimeMilliseconds()
    if lastVerveFadedMs > 0 and (now - lastVerveFadedMs) <= VERVE_PAIR_WINDOW_MS then
        lastVerveFadedMs = 0
        onConditionalProc(VERVE_BUFF_ID, 1)
    else
        lastMajorForceMs = now
    end
end

function crux:Initialize()
    EVENT_MANAGER:RegisterForEvent("BattleScrolls_Crux_Slot", EVENT_ACTION_SLOT_ABILITY_USED,
            function(_, actionSlotIndex)
                onActionSlotUsed(actionSlotIndex)
            end)
    for eventAbilityId, canonicalId in pairs(CRUX_GATE_PASS_SOURCES) do
        registerConditionalSource(eventAbilityId, canonicalId, false, true)
    end
    for eventAbilityId, canonicalId in pairs(CRUX_PROC_EFFECT_SOURCES) do
        registerConditionalSource(eventAbilityId, canonicalId, false, false)
    end
    for eventAbilityId, canonicalId in pairs(CRUX_PROC_DAMAGE_SOURCES) do
        registerConditionalSource(eventAbilityId, canonicalId, true, false)
    end
    EVENT_MANAGER:RegisterForEvent("BattleScrolls_Crux_Armor", EVENT_EFFECT_CHANGED, function(_, changeType)
        if changeType == EFFECT_RESULT_FADED then
            armorBuffActive = false
        else
            armorBuffActive = true
            lastArmorProcMs = 0
            armorIcdFloorMs = ARMOR_PROC_NOMINAL_MS - ARMOR_PROC_MARGIN_MS
        end
    end)
    EVENT_MANAGER:AddFilterForEvent("BattleScrolls_Crux_Armor", EVENT_EFFECT_CHANGED,
            REGISTER_FILTER_ABILITY_ID, CRUX_ARMOR_BUFF_ID,
            REGISTER_FILTER_UNIT_TAG, "player")
    for buffAbilityId, grantedStacks in pairs(CRUX_MASTERY_BUFF_GAIN_SOURCES) do
        registerBuffGainSource(buffAbilityId, grantedStacks)
    end
    EVENT_MANAGER:RegisterForEvent("BattleScrolls_Crux_Verve", EVENT_EFFECT_CHANGED, function(_, changeType)
        if changeType == EFFECT_RESULT_FADED then
            onVerveFaded()
        end
    end)
    EVENT_MANAGER:AddFilterForEvent("BattleScrolls_Crux_Verve", EVENT_EFFECT_CHANGED,
            REGISTER_FILTER_ABILITY_ID, VERVE_BUFF_ID,
            REGISTER_FILTER_UNIT_TAG, "player")
    EVENT_MANAGER:RegisterForEvent("BattleScrolls_Crux_Force", EVENT_EFFECT_CHANGED, function(_, changeType)
        if changeType ~= EFFECT_RESULT_FADED then
            onMajorForceGained()
        end
    end)
    EVENT_MANAGER:AddFilterForEvent("BattleScrolls_Crux_Force", EVENT_EFFECT_CHANGED,
            REGISTER_FILTER_ABILITY_ID, MAJOR_FORCE_BUFF_ID,
            REGISTER_FILTER_UNIT_TAG, "player")
    EVENT_MANAGER:RegisterForEvent("BattleScrolls_Crux_BannerOoc", EVENT_COMBAT_EVENT, function()
        bannerLastSeenMs = GetGameTimeMilliseconds()
    end)
    EVENT_MANAGER:AddFilterForEvent("BattleScrolls_Crux_BannerOoc", EVENT_COMBAT_EVENT,
            REGISTER_FILTER_ABILITY_ID, BANNER_TICK_OOC_ID,
            REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
    EVENT_MANAGER:RegisterForEvent("BattleScrolls_Crux_BannerUlt", EVENT_COMBAT_EVENT, function()
        bannerLastSeenMs = GetGameTimeMilliseconds()
    end)
    EVENT_MANAGER:AddFilterForEvent("BattleScrolls_Crux_BannerUlt", EVENT_COMBAT_EVENT,
            REGISTER_FILTER_ABILITY_ID, BANNER_TICK_ULT_ID,
            REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
end

function crux:Cleanup()
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Crux_Slot", EVENT_ACTION_SLOT_ABILITY_USED)
    for _, sources in ipairs({ CRUX_GATE_PASS_SOURCES, CRUX_PROC_EFFECT_SOURCES, CRUX_PROC_DAMAGE_SOURCES }) do
        for eventAbilityId in pairs(sources) do
            EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Crux_Cond" .. eventAbilityId, EVENT_COMBAT_EVENT)
        end
    end
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Crux_Armor", EVENT_EFFECT_CHANGED)
    for buffAbilityId in pairs(CRUX_MASTERY_BUFF_GAIN_SOURCES) do
        EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Crux_Buff" .. buffAbilityId, EVENT_EFFECT_CHANGED)
    end
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Crux_Verve", EVENT_EFFECT_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Crux_Force", EVENT_EFFECT_CHANGED)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Crux_BannerOoc", EVENT_COMBAT_EVENT)
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Crux_BannerUlt", EVENT_COMBAT_EVENT)
end
