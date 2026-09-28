-- Exercise the real bulk-processing loops with a manually settled collector.
-- Weak references check that collection can reclaim the decoded graph while
-- the workflow is waiting, not merely after it has started the next decode.
local function newWorkload(kind, failAt, encounterCount)
    local env = setmetatable({ BattleScrolls = {} }, { __index = _G })
    local function load(path) return assert(loadfile(path, "t", env))() end
    env._G = env
    local scheduler = load("tests/mocks/libasync.lua")
    local Effect = load("BattleScrolls/core/effect.lua")
    local state = { decodes = 0, collections = 0, weak = setmetatable({}, { __mode = "v" }) }
    state.pump = scheduler.pump
    env.BattleScrolls.gc = {
        RequestGC = function() end,
        CollectFullAsync = function()
            return Effect.FromCallback(function(resolve)
                state.collections = state.collections + 1
                state.release = resolve
            end)
        end,
    }
    env.BattleScrolls.storage = {
        DecodeEncounterAsync = function()
            return Effect.Sync(function()
                state.decodes = state.decodes + 1
                if state.decodes == failAt then error("broken encounter") end
                local breakdown = { total = 100, ticks = 1, minTick = 100, maxTick = 100 }
                local decoded = {
                    durationMs = 1000,
                    damageByUnitId = { [1] = { [2] = { [10] = breakdown } } },
                    unitNames = { [1] = "Player", [2] = "Target" },
                }
                state.weak.decoded = decoded
                state.weak.breakdown = breakdown
                return decoded
            end)
        end,
    }
    local instance = { zone = "Zone", abilityInfo = {}, encounters = {} }
    local scoped = {}
    for i = 1, encounterCount or 20 do
        local encounter = { displayName = "Fight", durationMs = 1000, timestampS = i }
        instance.encounters[i] = encounter
        scoped[i] = { encounter = encounter, instance = instance, instanceIndex = 1, encounterIndex = i }
    end
    if kind == "aggregate" then
        load("BattleScrolls/ui/journal/pivot/types.lua")
        local pivot = env.BattleScrolls.journal.pivot
        pivot.extractors = {
            getMetricLabel = function(id) return id end,
            getDimensionLabel = function(id) return id end,
            metrics = { totalDamage = { extract = function(breakdown) return breakdown.total end } },
        }
        load("BattleScrolls/ui/journal/pivot/engine.lua")
        state.effect = pivot.engine.runDecodeQueryAsync({
            domain = pivot.Domain.DAMAGE, rowDimension = pivot.Dimension.INSTANCE,
            columnMode = pivot.ColumnMode.METRICS, metrics = { pivot.Metric.TOTAL_DAMAGE },
            aggregation = pivot.Aggregation.SUM,
        }, scoped)
    else
        env.GetTimeStamp = function() return 1700000000 end
        env.GetWorldName = function() return "EU Megaserver" end
        env.BattleScrolls.utils = { GetUndecoratedDisplayName = function() return "Player" end }
        load("BattleScrolls/storage/bitcodec.lua")
        load("BattleScrolls/storage/binary.lua")
        load("BattleScrolls/network/export.lua")
        state.effect = env.BattleScrolls.export.buildInstanceArchiveAsync(instance)
    end
    function state.waitForCollection(fiber)
        for _ = 1, 500 do
            if state.release then return end
            state.pump(1)
            assert_true(fiber:IsRunning(), tostring(fiber._error or "workflow ended before collection"))
        end
        error("collection was not awaited")
    end
    function state.finishCollection(result)
        local release = state.release
        state.release = nil
        release(result)
    end
    return state
end

describe("Bulk encounter GC", function()
    for _, kind in ipairs({ "aggregate", "export" }) do
        local batchSize = kind == "aggregate" and 5 or 1
        it(kind .. " releases decoded data and waits before processing the next batch", function()
            -- A partial final aggregate batch must be collected too.
            local encounterCount = kind == "aggregate" and 23 or 20
            local state = newWorkload(kind, nil, encounterCount)
            local fiber = state.effect:Run()
            for i = 1, math.ceil(encounterCount / batchSize) do
                state.waitForCollection(fiber)
                state.pump(10)
                assert_eq(state.decodes, math.min(i * batchSize, encounterCount),
                    "next batch must wait for collection")
                collectgarbage("collect")
                assert_eq(state.weak.decoded, nil, "decoded encounter must be reclaimable during the wait")
                assert_eq(state.weak.breakdown, nil, "extracted breakdowns must also be reclaimable")
                -- The real collector may time out: false must still allow progress.
                state.finishCollection(i % 2 == 0)
            end
            state.pump(500)
            assert_true(fiber:IsSucceeded(), tostring(fiber._error))
            assert_eq(state.collections, math.ceil(encounterCount / batchSize))
            assert_eq(fiber._value.encounterCount, encounterCount)
            if kind == "aggregate" then
                assert_eq(fiber._value.rows[1].values.totalDamage, encounterCount * 100)
            else
                assert_eq(fiber._value.skipped, 0)
                assert_true(#fiber._value.bytes > 0)
            end
        end)

        it(kind .. " can be cancelled while waiting without decoding more encounters", function()
            local state = newWorkload(kind)
            local fiber = state.effect:Run()
            state.waitForCollection(fiber)
            fiber:Cancel()
            state.finishCollection(true)
            state.pump(500)
            assert_true(not fiber:IsRunning())
            assert_eq(state.decodes, batchSize)
        end)
    end

    it("export still skips failed decodes and waits before continuing", function()
        local state = newWorkload("export", 2)
        local fiber = state.effect:Run()
        for i = 1, 20 do
            state.waitForCollection(fiber)
            assert_eq(state.decodes, i)
            state.finishCollection(true)
        end
        state.pump(500)
        assert_true(fiber:IsSucceeded(), tostring(fiber._error))
        assert_eq(fiber._value.encounterCount, 19)
        assert_eq(fiber._value.skipped, 1)
    end)
end)
