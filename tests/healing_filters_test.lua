-- Healing In must use the same selected sources for totals and quality as
-- the journal's ability, delivery and healer breakdowns. -1 denotes Self.

BattleScrolls.constants = BattleScrolls.constants or {}
BattleScrolls.constants.DAMAGE_SHIELDED_ABILITY_ID = 1048574
BattleScrolls.constants.HEAL_ABSORBED_ABILITY_ID = 1048573
dofile("BattleScrolls/combat/arithmancer.lua")
local arithmancer = BattleScrolls.arithmancer

local function fixture()
    return {
        durationMs = 10000,
        healingStats = {
            selfHealing = {
                total = { raw = 1000, real = 250, overheal = 750 },
                bySourceUnitIdByAbilityId = {
                    [1] = {
                        [10] = { raw = 1000, real = 250, overheal = 750,
                            ticks = 4, critTicks = 2, minTick = 100, maxTick = 700 },
                    },
                },
            },
            healingInFromGroup = {
                [101] = {
                    total = { raw = 2000, real = 500, overheal = 1500 },
                    byAbilityId = {
                        [20] = { raw = 2000, real = 500, overheal = 1500,
                            ticks = 4, critTicks = 1, minTick = 200, maxTick = 600 },
                    },
                },
                [202] = {
                    total = { raw = 3000, real = 2250, overheal = 750 },
                    byAbilityId = {
                        [30] = { raw = 3000, real = 2250, overheal = 750,
                            ticks = 2, critTicks = 2, minTick = 500, maxTick = 2500 },
                    },
                },
            },
        },
    }
end

describe("Healing In filters", function()
    local cases = {
        { name = "includes self and all healers without a filter",
            raw = 6000, effective = 3000, overheal = 50, crit = 50, maxHeal = 2500 },
        { name = "includes only self when Self is selected",
            filter = { [-1] = true },
            raw = 1000, effective = 250, overheal = 75, crit = 50, maxHeal = 700 },
        { name = "includes self alongside a selected healer",
            filter = { [-1] = true, [101] = true },
            raw = 3000, effective = 750, overheal = 75, crit = 37.5, maxHeal = 700 },
        { name = "excludes self and unselected healers",
            filter = { [-1] = false, [101] = true },
            raw = 2000, effective = 500, overheal = 75, crit = 25, maxHeal = 600 },
        { name = "includes both healers without self",
            filter = { [101] = true, [202] = true },
            raw = 5000, effective = 2750, overheal = 45, crit = 50, maxHeal = 2500 },
        { name = "returns zero when every source is deselected",
            filter = {},
            raw = 0, effective = 0, overheal = 0, crit = 0, maxHeal = 0 },
    }

    for _, case in ipairs(cases) do
        it(case.name, function()
            local calc = arithmancer:Make(fixture(), nil, { sourceFilter = case.filter })
            local summary = calc:getHealingInSummary()
            local quality = calc:getHealingInQuality()

            assert_eq(summary.rawTotal, case.raw, "raw total")
            assert_eq(summary.total, case.effective, "effective total")
            assert_eq(summary.rawHps, case.raw / 10, "raw HPS")
            assert_eq(summary.effectiveHps, case.effective / 10, "effective HPS")
            assert_eq(summary.overhealPercent, case.overheal, "overheal percent")
            assert_eq(quality.critRate, case.crit, "crit rate")
            assert_eq(quality.maxHeal, case.maxHeal, "maximum raw heal")
        end)
    end

    it("includes self even when there is no group healing map", function()
        local encounter = fixture()
        encounter.healingStats.healingInFromGroup = nil
        local calc = arithmancer:Make(encounter, nil, { sourceFilter = { [-1] = true } })
        assert_eq(calc:getHealingInSummary().rawTotal, 1000)
        assert_eq(calc:getHealingInSummary().total, 250)
        assert_eq(calc:getHealingInQuality().maxHeal, 700)
    end)

    it("handles an encounter without healing", function()
        local calc = arithmancer:Make({ durationMs = 10000 })
        assert_eq(calc:getHealingInSummary().rawTotal, 0)
        assert_eq(calc:getHealingInSummary().effectiveHps, 0)
        assert_eq(calc:getHealingInQuality().critRate, 0)
    end)

    it("keeps selected totals but reports zero HPS for zero duration", function()
        local encounter = fixture()
        encounter.durationMs = 0
        local calc = arithmancer:Make(encounter, nil, { sourceFilter = { [-1] = true } })
        local summary = calc:getHealingInSummary()
        assert_eq(summary.rawTotal, 1000)
        assert_eq(summary.total, 250)
        assert_eq(summary.rawHps, 0)
        assert_eq(summary.effectiveHps, 0)
    end)
end)
