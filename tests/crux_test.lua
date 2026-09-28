-- Exercise Crux attribution with explicit damage/stack event ordering.
local ARMOR_ID = 185908

local function newFixture(startStacks, withCombatState)
    local fixture = { nowMs = 10000 }
    local handlers = {}
    local state = {
        initialized = true,
        cruxStacks = startStacks,
        cruxRecentMax = startStacks,
        cruxWindowStartMs = 0,
        lastPlayerDeathMs = 0,
    }
    local env = setmetatable({
        BattleScrolls = {
            state = state,
            constants = { damageResultsSet = {} },
            log = { Debug = function() end },
        },
        GetGameTimeMilliseconds = function() return fixture.nowMs end,
        IsUnitDead = function() return false end,
        zo_min = math.min,
        zo_max = math.max,
        EVENT_ACTION_SLOT_ABILITY_USED = 1,
        EVENT_COMBAT_EVENT = 2,
        EVENT_EFFECT_CHANGED = 3,
        EFFECT_RESULT_GAINED = 1,
        EFFECT_RESULT_FADED = 2,
        ACTION_RESULT_EFFECT_GAINED = 3,
        ACTION_RESULT_DAMAGE_SHIELDED = 4,
        ACTION_RESULT_DAMAGE = 5,
        REGISTER_FILTER_ABILITY_ID = 1,
        REGISTER_FILTER_UNIT_TAG = 2,
        REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE = 3,
        REGISTER_FILTER_TARGET_COMBAT_UNIT_TYPE = 4,
        COMBAT_UNIT_TYPE_PLAYER = 1,
        COMBAT_UNIT_TYPE_PLAYER_COMPANION = 2,
        COMBAT_UNIT_TYPE_PLAYER_PET = 3,
        COMBAT_UNIT_TYPE_GROUP = 4,
        COMBAT_UNIT_TYPE_OTHER = 5,
        COMBAT_UNIT_TYPE_NONE = 6,
        EVENT_MANAGER = {
            RegisterForEvent = function(_, namespace, _, callback) handlers[namespace] = callback end,
            AddFilterForEvent = function() end,
        },
    }, { __index = _G })
    assert(loadfile("BattleScrolls/combat/crux.lua", "t", env))()
    local crux = env.BattleScrolls.crux
    crux:Initialize()

    if withCombatState then
        local bs = env.BattleScrolls
        bs.constants.personalTypesSet = { [1] = true, [2] = true, [3] = true }
        bs.constants.friendlyTypesSet = { [1] = true, [2] = true, [3] = true, [4] = true }
        bs.constants.damageResultsSet[env.ACTION_RESULT_DAMAGE] = true
        bs.constants.healingResultsSet = {}
        bs.constants.INFERRED_PLAYER_UNIT_ID = -1
        bs.constants.INFERRED_COMPANION_UNIT_ID = -2
        bs.constants.DAMAGE_SHIELDED_ABILITY_ID = 1048574
        bs.accumulators = {
            clear = function(s)
                s.damageUnknownByUnitId = {}
                s.damageTakenByUnitId = {}
                s.abilityInfo = {}
            end,
            damage = function() fixture.damageEvents = (fixture.damageEvents or 0) + 1 end,
            isOverTimeResult = function() return false end,
            isCriticalResult = function() return false end,
        }
        bs.weaving = { newState = function() return {} end }
        bs.ultimate = { newState = function() return {} end }
        bs.zen = { newState = function() return {} end }
        bs.effects = { clear = function() end }
        assert(loadfile("BattleScrolls/combat/state.lua", "t", env))()
        for key, value in pairs(state) do bs.state[key] = value end
        state = bs.state
    end

    function fixture:armor(active)
        handlers.BattleScrolls_Crux_Armor(nil, active and env.EFFECT_RESULT_GAINED or env.EFFECT_RESULT_FADED)
    end

    function fixture:hit(timeMs)
        self.nowMs = timeMs
        crux.onPlayerDamaged()
    end

    function fixture:damage(timeMs, shielded, targetType, amount)
        self.nowMs = timeMs
        state:OnCombatEvent(nil, shielded and env.ACTION_RESULT_DAMAGE_SHIELDED or env.ACTION_RESULT_DAMAGE,
            false, "", "", 0, "Enemy", env.COMBAT_UNIT_TYPE_NONE, "Target", targetType or env.COMBAT_UNIT_TYPE_PLAYER,
            amount or 100, 0, 0, "", 10, 20, 12345, 0)
    end

    function fixture:stacks(timeMs, count)
        self.nowMs = timeMs
        local previous = state.cruxStacks
        state.cruxRecentMax = math.max(previous, count)
        state.cruxWindowStartMs = timeMs
        state.cruxStacks = count
        crux.onCruxStacksChanged(state, previous, count)
    end

    function fixture:gate(timeMs)
        self.nowMs = timeMs
        handlers.BattleScrolls_Crux_Cond183544(nil, env.ACTION_RESULT_EFFECT_GAINED)
    end

    function fixture:finish()
        return crux.finalize(state.cruxActivity, self.nowMs, 0)
    end

    fixture.state = state
    fixture:armor(true)
    return fixture
end

describe("Cruxweaver Armor", function()
    it("counts one wasted proc per cooldown while remaining at three Crux", function()
        local f = newFixture(3)
        f:hit(10000)
        f:hit(10010)
        f:hit(14949)
        f:hit(15000)
        f:hit(15010)

        local result = f:finish()
        assert_true(result)
        assert_eq(result.conditionalWasted[ARMOR_ID], 2)
        assert_eq(result.conditionalGains[ARMOR_ID], nil)
        assert_eq(result.unattributedGains, 0)
    end)

    it("keeps the cooldown after spending full Crux and resumes generation when it expires", function()
        local f = newFixture(3)
        f:hit(10000)
        f:stacks(10010, 0)
        f:hit(10020)
        f:stacks(10030, 1)
        f:hit(15000)
        f:stacks(15010, 2)

        local result = f:finish()
        assert_eq(result.conditionalWasted[ARMOR_ID], 1)
        assert_eq(result.conditionalGains[ARMOR_ID], 1)
        assert_eq(result.unattributedGains, 1)
    end)

    it("credits a gain to three delivered before its damage event without counting waste", function()
        local f = newFixture(2)
        f:stacks(10000, 3)
        f:hit(10010)
        f:hit(10020)

        local result = f:finish()
        assert_eq(result.conditionalGains[ARMOR_ID], 1)
        assert_eq(result.conditionalWasted[ARMOR_ID], nil)
        assert_eq(result.unattributedGains, 0)
    end)

    it("credits a gain to three delivered after its damage event without counting waste", function()
        local f = newFixture(2)
        f:hit(10000)
        f:stacks(10010, 3)
        f:hit(10020)

        local result = f:finish()
        assert_eq(result.conditionalGains[ARMOR_ID], 1)
        assert_eq(result.conditionalWasted[ARMOR_ID], nil)
    end)

    it("does not infer waste or start the cooldown from unconfirmed hits below three", function()
        for stacks = 0, 2 do
            local f = newFixture(stacks)
            f:hit(10000)
            f:hit(11000)
            f:stacks(11010, stacks + 1)

            local result = f:finish()
            assert_eq(result.conditionalGains[ARMOR_ID], 1)
            assert_eq(result.conditionalWasted[ARMOR_ID], nil)
            assert_eq(result.unattributedGains, 0)
        end
    end)

    it("uses the current Crux count after a spend rather than the recent maximum", function()
        local f = newFixture(3)
        f:stacks(10000, 0)
        f:hit(10010)
        f:stacks(10020, 1)

        local result = f:finish()
        assert_eq(result.conditionalGains[ARMOR_ID], 1)
        assert_eq(result.conditionalWasted[ARMOR_ID], nil)
    end)

    it("ignores full-Crux hits without the armor buff or an active encounter", function()
        local f = newFixture(3)
        f:armor(false)
        f:hit(10000)
        assert_eq(f:finish(), nil)

        f:armor(true)
        f.state.initialized = false
        f:hit(10010)
        assert_eq(f:finish(), nil)
    end)

    it("preserves conditional-source attribution in both delivery orders", function()
        local f = newFixture(0)
        f:gate(10000)
        f:stacks(10010, 1)
        f:stacks(11000, 2)
        f:gate(11010)

        local result = f:finish()
        assert_eq(result.conditionalGains[183542], 2)
        assert_eq(result.conditionalWasted[183542], nil)
        assert_eq(result.conditionalGains[ARMOR_ID], nil)
        assert_eq(result.unattributedGains, 0)
    end)
end)

describe("Cruxweaver Armor combat event routing", function()
    it("attributes a gain after a hit absorbed entirely by the player's shield", function()
        local f = newFixture(1, true)
        f:damage(10000, true)
        f:stacks(10010, 2)

        local result = f:finish()
        assert_eq(result.conditionalGains[ARMOR_ID], 1)
        assert_eq(result.unattributedGains, 0)
        assert_eq(f.damageEvents, 1)
    end)

    it("attributes a gain delivered before its shielded damage event", function()
        local f = newFixture(2, true)
        f:stacks(10000, 3)
        f:damage(10010, true)

        local result = f:finish()
        assert_eq(result.conditionalGains[ARMOR_ID], 1)
        assert_eq(result.conditionalWasted[ARMOR_ID], nil)
        assert_eq(result.unattributedGains, 0)
    end)

    it("shares the cooldown between shielded and health damage at full Crux", function()
        local f = newFixture(3, true)
        f:damage(10000, true)
        f:damage(10000, false)
        f:damage(14949, true)
        f:damage(15000, false)

        local result = f:finish()
        assert_eq(result.conditionalWasted[ARMOR_ID], 2)
        assert_eq(f.damageEvents, 4)
    end)

    it("starts the cooldown for a wasted proc even when no damage reaches health", function()
        local f = newFixture(3, true)
        f:damage(10000, true)
        f:damage(10010, true)
        f:damage(14949, true)
        f:damage(15000, true)

        local result = f:finish()
        assert_eq(result.conditionalWasted[ARMOR_ID], 2)
        assert_eq(result.conditionalGains[ARMOR_ID], nil)
    end)

    it("ignores shield hits on pets and companions and zero-value player hits", function()
        local f = newFixture(1, true)
        f:damage(10000, true, 2)
        f:damage(10010, true, 3)
        f:damage(10020, true, 1, 0)
        f:stacks(10030, 2)

        local result = f:finish()
        assert_eq(result.conditionalGains[ARMOR_ID], nil)
        assert_eq(result.unattributedGains, 1)
        assert_eq(f.damageEvents, 2)
    end)
end)
