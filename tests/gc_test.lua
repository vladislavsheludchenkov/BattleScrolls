-- Regression coverage for production collector completion and pacing.
-- Controlled clock and GC steps do not model ESO's native memory accounting.
local function withCollector(body)
    local state = { now = 0, steps = 0, frameSteps = 0, maxFrameSteps = 0 }
    local env = setmetatable({ BattleScrolls = {} }, { __index = _G })
    env.GetGameTimeMilliseconds = function() return state.now end
    env.collectgarbage = function(operation, size)
        assert_eq(operation, "step")
        assert_eq(size, 3000)
        state.steps = state.steps + 1
        state.frameSteps = state.frameSteps + 1
        state.maxFrameSteps = math.max(state.maxFrameSteps, state.frameSteps)
        state.now = state.now + 1
        if state.reclaimAfter and state.steps >= state.reclaimAfter then
            collectgarbage("collect")
        end
        return state.boundary or false
    end
    local function load(path) return assert(loadfile(path, "t", env))() end
    load("BattleScrolls/core/effect.lua")
    local gc = load("BattleScrolls/core/gc.lua")
    state.gc = gc
    function state.start()
        state.fiber = gc:CollectFullAsync():Run()
    end
    function state.pump()
        state.now = state.now + 16
        state.frameSteps = 0
        TestEnv.pump(1)
    end
    function state.finish()
        for _ = 1, 1000 do
            state.pump()
            if not state.fiber:IsRunning() then
                assert_true(state.fiber:IsSucceeded())
                return state.fiber._value
            end
        end
        error("collector did not settle")
    end

    -- Only the controlled primitive may reclaim the sentinel in these tests.
    collectgarbage("stop")
    local ok, err = pcall(body, state)
    if state.fiber then state.fiber:Cancel() end
    gc._remainingCycles = 0
    if gc._fiber then gc._fiber:Cancel() end
    collectgarbage("restart")
    collectgarbage("collect")
    if not ok then error(err, 0) end
end

describe("Garbage collection", function()
    it("confirms reclamation even when no step reports a cycle boundary", function()
        withCollector(function(state)
            state.reclaimAfter = 13
            state.start()
            assert_eq(state.finish(), true)
            assert_eq(state.steps, 13)
            assert_eq(state.maxFrameSteps, 10, "multiple steps fit in the bounded frame slice")
        end)
    end)

    it("times out when step boundaries report success without reclaiming the sentinel", function()
        withCollector(function(state)
            state.boundary = true
            state.start()
            assert_eq(state.finish(), false)
            assert_true(state.now >= 3000, "allow the full reclamation deadline")
            assert_true(state.now < 3100, "stop promptly after the deadline")
            assert_eq(state.maxFrameSteps, 10, "yield between bounded slices")
        end)
    end)

    it("cancels queued background cycles before starting a confirmed collection", function()
        withCollector(function(state)
            state.gc:RequestGC(5)
            local background = state.gc._fiber
            state.reclaimAfter = 13
            state.start()
            assert_eq(state.finish(), true)
            assert_true(not background:IsRunning())
            assert_eq(state.gc._fiber, nil)
            local steps = state.steps
            for _ = 1, 10 do state.pump() end
            assert_eq(state.steps, steps, "cancelled background cycles must not restart")
        end)
    end)
end)
