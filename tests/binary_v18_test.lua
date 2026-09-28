-- Round-trip tests for storage/binary.lua's encounter encoding (v18 core +
-- v19 EXT section): playerZero flag, single-tick elision, sorted gap-encoded
-- ability refs, and the trailing EXT sub-sections (ultimate, resurrections,
-- crux, zen, death attacker names).

local pump = TestEnv.pump

local Effect = dofile("BattleScrolls/core/effect.lua")
dofile("BattleScrolls/storage/bitcodec.lua")

-- Plain-table stand-ins for the Havok hstructure factories (hmake is not
-- plain Lua); field lists mirror havok/structures.lua exactly so decoded
-- output deep-compares against fixture input built with the same shims.
BattleScrolls.structures = {
    makeDamageBreakdown = function(total, rawTotal, ticks, critTicks, minTick, maxTick)
        return {
            total = total, rawTotal = rawTotal, ticks = ticks,
            critTicks = critTicks, minTick = minTick, maxTick = maxTick,
        }
    end,
    makeHealingTotals = function(raw, real, overheal)
        return { raw = raw, real = real, overheal = overheal }
    end,
    makeHealingBreakdown = function(raw, real, overheal, ticks, critTicks, minTick, maxTick)
        return {
            raw = raw, real = real, overheal = overheal, ticks = ticks,
            critTicks = critTicks, minTick = minTick, maxTick = maxTick,
        }
    end,
    makeEffectStats = function(abilityId, effectType, totalActiveTimeMs, timeAtMaxStacksMs,
                               applications, maxStacks, playerActiveTimeMs,
                               playerTimeAtMaxStacksMs, playerApplications, peakConcurrentInstances)
        return {
            abilityId = abilityId, effectType = effectType,
            totalActiveTimeMs = totalActiveTimeMs, timeAtMaxStacksMs = timeAtMaxStacksMs,
            applications = applications, maxStacks = maxStacks,
            playerActiveTimeMs = playerActiveTimeMs,
            playerTimeAtMaxStacksMs = playerTimeAtMaxStacksMs,
            playerApplications = playerApplications,
            peakConcurrentInstances = peakConcurrentInstances,
            lastFinalizedMs = 0, lastFinalizedMaxStacksMs = 0,
            lastFinalizedPlayerMs = 0, lastFinalizedPlayerMaxStacksMs = 0,
        }
    end,
}
BattleScrolls.constants = BattleScrolls.constants or {}
BattleScrolls.constants.BOSS_TAGS =
    { "boss1", "boss2", "boss3", "boss4", "boss5", "boss6" }

dofile("BattleScrolls/storage/binary.lua")
local binaryStorage = BattleScrolls.binaryStorage
local structures = BattleScrolls.structures

---Runs an Effect to completion on the pumped scheduler and returns its value.
local function runSync(effect, what)
    local value, failure
    local fiber = Effect.Async(function()
        return effect:Await()
    end):Run()
    fiber:OnComplete(function(f)
        if f:IsSucceeded() then
            value = f._value
        else
            failure = f._error
        end
    end)
    pump(500)
    assert_true(failure == nil, (what or "effect") .. " failed: " .. tostring(failure))
    assert_true(fiber:IsSucceeded(), (what or "effect") .. " did not complete")
    return value
end

---@return boolean ok
---@return string|nil err
local function deepEq(a, b, path)
    if type(a) ~= type(b) then
        return false, string.format("%s: type %s vs %s", path, type(a), type(b))
    end
    if type(a) ~= "table" then
        if a ~= b then
            return false, string.format("%s: %s vs %s", path, tostring(a), tostring(b))
        end
        return true
    end
    for k, v in pairs(a) do
        local ok, err = deepEq(v, b[k], path .. "." .. tostring(k))
        if not ok then
            return false, err
        end
    end
    for k in pairs(b) do
        if a[k] == nil then
            return false, path .. "." .. tostring(k) .. ": extra field"
        end
    end
    return true
end

local function assert_deepEq(a, b, path)
    local ok, err = deepEq(a, b, path)
    assert_true(ok, err or "")
end

---Fixture exercising every v18-changed path: single-tick elision (damage +
---healing), rawTotal delta, playerZero and explicit player fields, peak > 1,
---multi-ability maps whose pairs() order differs from sorted registry order.
local function buildEncounter()
    local mk = structures.makeDamageBreakdown
    local mkHeal = structures.makeHealingBreakdown
    local mkEffect = structures.makeEffectStats
    return {
        displayName = "Test Fight",
        timestampS = 1700000000,
        durationMs = 90000,
        bossesUnits = { 2001 },
        damageByUnitId = {
            [1001] = {
                [2001] = {
                    [30001] = mk(5000, 5000, 1, 1, 5000, 5000),   -- single hit: elided
                    [30002] = mk(800, 950, 3, 0, 100, 400),       -- rawTotal differs
                    [30003] = mk(0, 0, 0, 0, 0, 0),               -- empty row: elided
                },
                [2002] = {
                    [30002] = mk(1200, 1200, 100, 40, 5, 30),     -- ticks past the 63 doubling boundary
                    [30001] = mk(700, 700, 1, 0, 700, 700),
                },
            },
        },
        damageTakenByUnitId = {
            [2001] = { [1001] = { [30010] = mk(4000, 4400, 2, 1, 1500, 2500) } },
        },
        healingStats = {
            selfHealing = {
                total = structures.makeHealingTotals(600, 500, 100),
                bySourceUnitIdByAbilityId = {
                    [1001] = {
                        [40001] = mkHeal(300, 300, 0, 1, 0, 300, 300),  -- single tick: elided
                        [40002] = mkHeal(300, 200, 100, 4, 2, 20, 120),
                    },
                },
            },
            healingOutToGroup = {
                [3001] = {
                    total = structures.makeHealingTotals(900, 700, 200),
                    bySourceUnitIdByAbilityId = {
                        [1001] = { [40001] = mkHeal(900, 700, 200, 6, 3, 50, 250) },
                    },
                },
            },
            healingInFromGroup = {
                [3002] = {
                    total = structures.makeHealingTotals(450, 450, 0),
                    byAbilityId = { [40003] = mkHeal(450, 450, 0, 1, 1, 450, 450) },
                },
            },
        },
        procs = {
            {
                abilityId = 30001, totalProcs = 7,
                meanIntervalMs = 1200, medianIntervalMs = 1100,
                procsByEnemy = { { unitId = 2001, procCount = 7 } },
            },
        },
        effectsOnPlayer = {
            [50001] = mkEffect(50001, 1, 60000, 60000, 12, 0, 60000, 60000, 12, 1),  -- playerSame
            [50002] = mkEffect(50002, 2, 45000, 20000, 8, 3, 15000, 5000, 2, 3),     -- explicit player fields, peak 3
        },
        effectsOnBosses = {
            boss1 = {
                [50003] = mkEffect(50003, 2, 9000, 9000, 4, 5, 0, 0, 0, 1),          -- playerZero
            },
        },
        effectsOnGroup = {
            ["@Member1"] = {
                [50001] = mkEffect(50001, 1, 30000, 30000, 6, 0, 0, 0, 0, 1),        -- playerZero
                [50004] = mkEffect(50004, 1, 12000, 12000, 2, 0, 12000, 12000, 2, 1),-- playerSame
            },
            ["@Member2"] = {
                [50002] = mkEffect(50002, 2, 22000, 8000, 5, 3, 0, 0, 0, 2),         -- playerZero + peak 2
            },
        },
        bossNames = { boss1 = "Big Bad" },
        playerAliveTimeMs = 85000,
        unitAliveTimeMs = { boss1 = 60000, ["@Member1"] = 90000 },
        unitNames = { [1001] = "Player One", [2001] = "Big Bad", [2002] = "Add" },
        -- v19 EXT sub-sections
        deaths = {
            deathCount = 2,
            recaps = {
                { timeOffsetMs = 30000, attacks = {
                    { abilityId = 30010, damage = 4000, attackerName = "Big Bad" },
                    { abilityId = 30011, damage = 2500 },  -- no attacker known
                } },
                { timeOffsetMs = 80000, attacks = {
                    { abilityId = 30010, damage = 6000, attackerName = "Add" },
                } },
            },
        },
        ultimate = {
            startUlt = 250, maxUlt = 500, totalGained = 940, totalDrained = 700,
            gainByAbilityId = {
                [0] = { total = 400, ticks = 0, minTick = 0, maxTick = 0 },        -- base bucket: no ticks
                [172055] = { total = 340, ticks = 34, minTick = 5, maxTick = 15 }, -- explicit bounds
                [30001] = { total = 200, ticks = 1, minTick = 200, maxTick = 200 },-- single tick: elided
            },
            casts = {
                { timeMs = 12000, abilityId = 40100, cost = 175, poolBefore = 260 },
                { timeMs = 55000, abilityId = 40100 },                              -- pre-v20 cast: no pool info
                { timeMs = 82000, abilityId = 40200, cost = 250, poolBefore = 250 },
            },
        },
        crux = {
            generatorCasts = 40, generatorAtFull = 6, spenderCasts = 18,
            spenderUnder = { 2, 3, 5 },
            passiveEvents = 4, passiveStacks = 7,
            deathEvents = 2, deathStacks = 5,
            byAbility = {
                [185805] = { casts = 18, bad = 10, gained = 0 },
                [183006] = { casts = 40, bad = 6, gained = 31 },
            },
            conditionalGains = {
                [186211] = 5,  -- Fleet-Footed Gate
                [227381] = 2,  -- Spattering Disjunction
            },
            conditionalWasted = {
                [227381] = 9,
            },
            unattributedGains = 3,
        },
        weaving = {
            lightAttackHits = 40, heavyAttackHits = 2, skillActivations = 60,
            totalWeavingErrors = 15, doubleLaErrors = 1,
            downtimeMs = 12500, downtimeGaps = 3,
            byAbility = {
                { abilityId = 30001, activations = 35, afterSum = 4200, afterCount = 34,
                  beforeSum = -300, beforeCount = 35, weavingErrors = 9 },
                { abilityId = 30002, activations = 25, afterSum = 900, afterCount = 25,
                  beforeSum = 1100, beforeCount = 24, weavingErrors = 6 },
            },
        },
        resurrections = 3,
        resurrectionLog = {
            { displayName = "@Member1", timeMs = 20000 },
            { displayName = "@Member2", timeMs = 41000 },
            { displayName = "@Member1", timeMs = 70000 },
        },
        zen = {
            ["boss1:0"] = { 1000, 0, 2000, 500, 3000, 4500, 0, 0, 0, 6000, 0, 0 },
        },
    }
end

local COMPARED_FIELDS = {
    "damageByUnitId", "damageTakenByUnitId", "healingStats", "procs",
    "effectsOnPlayer", "effectsOnBosses", "effectsOnGroup", "bossNames",
    "playerAliveTimeMs", "unitAliveTimeMs", "unitNames",
    "deaths", "weaving", "ultimate", "crux", "resurrections", "resurrectionLog", "zen",
}

describe("Binary v18", function()
    it("round-trips a full encounter through encode/decode", function()
        local encounter = buildEncounter()
        local registry = binaryStorage.newRegistry()

        local compact = runSync(
            binaryStorage.encodeEncounterAsync(encounter, false, registry), "encode")
        assert_eq(compact._v, binaryStorage.CURRENT_VERSION, "encoded version")

        local decoded = runSync(
            binaryStorage.decodeEncounterAsync(compact, registry), "decode")
        for _, field in ipairs(COMPARED_FIELDS) do
            assert_deepEq(encounter[field], decoded[field], field)
        end
    end)

    it("round-trips again against a pre-populated registry (gap refs on a busy index space)", function()
        local encounter = buildEncounter()
        -- Simulate an instance registry with many earlier abilities so the
        -- fixture's refs land at high, spread-out indices
        local priorIds = {}
        for i = 1, 200 do
            priorIds[i] = 10000 + i * 7
        end
        local registry = binaryStorage.newRegistry(priorIds, { "warmup" })

        local compact = runSync(
            binaryStorage.encodeEncounterAsync(encounter, false, registry), "encode")
        local decoded = runSync(
            binaryStorage.decodeEncounterAsync(compact, registry), "decode")
        for _, field in ipairs(COMPARED_FIELDS) do
            assert_deepEq(encounter[field], decoded[field], field)
        end
    end)

    it("re-encode of the decoded encounter is size-identical (the migration grow-guard invariant)", function()
        -- Outer maps iterate in pairs() order, so the exact byte order can
        -- differ between encodes of equal tables - but every block's length
        -- is order-independent (same refs, same varints), so total size must
        -- match exactly. A mis-read field would shift the re-encoded size.
        local encounter = buildEncounter()
        local registry = binaryStorage.newRegistry()
        local first = runSync(
            binaryStorage.encodeEncounterAsync(encounter, false, registry), "encode 1")
        local decoded = runSync(
            binaryStorage.decodeEncounterAsync(first, registry), "decode")
        local second = runSync(
            binaryStorage.encodeEncounterAsync(decoded, false, registry), "encode 2")
        assert_eq(#table.concat(second._data), #table.concat(first._data),
            "re-encoded stream size differs")
        local redecoded = runSync(
            binaryStorage.decodeEncounterAsync(second, registry), "re-decode")
        for _, field in ipairs(COMPARED_FIELDS) do
            assert_deepEq(encounter[field], redecoded[field], "re-decoded " .. field)
        end
    end)
end)
