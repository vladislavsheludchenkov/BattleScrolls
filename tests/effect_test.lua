-- Tests for core/effect.lua: cancellation semantics, Ensure guarantees,
-- task-pool reuse, FromCallback, and the Semaphore.

local pump = TestEnv.pump

local Effect = dofile("BattleScrolls/core/effect.lua")

-- Collect unhandled errors instead of raising; asserted empty at the end
local unhandled = {}
Effect.OnUnhandledError = function(err) table.insert(unhandled, err) end

describe("Effect basics", function()
    it("async body succeeds and Ensure runs once", function()
        local ensures, result = 0, nil
        local fiber = Effect.Async(function()
            Effect.Yield():Await()
            return 42
        end):Ensure(function() ensures = ensures + 1 end):Run()
        fiber:OnComplete(function(f) result = f._value end)
        pump(10)
        assert_true(fiber:IsSucceeded(), "fiber should succeed")
        assert_eq(result, 42, "result")
        assert_eq(ensures, 1, "ensure count")
    end)

    it("async body error propagates and Ensure runs once", function()
        local ensures, err = 0, nil
        local fiber = Effect.Async(function()
            Effect.Yield():Await()
            error("boom")
        end):Ensure(function() ensures = ensures + 1 end):Run()
        fiber:OnComplete(function(f) err = f._error end)
        pump(10)
        assert_true(fiber:IsFailed(), "fiber should fail")
        assert_true(tostring(err):find("boom") ~= nil, "error should propagate")
        assert_eq(ensures, 1, "ensure count")
    end)

    it("releases a consumed await result while the next operation is pending", function()
        local weak = setmetatable({}, { __mode = "v" })
        local release
        local fiber = Effect.Async(function()
            local value = Effect.Sync(function()
                local result = {}
                weak[1] = result
                return result
            end):Await()
            assert_true(value == weak[1], "await must deliver the result")
            value = nil
            Effect.FromCallback(function(resolve) release = resolve end):Await()
            return 42
        end):Run()
        pump(10)
        assert_true(release ~= nil, "second operation should be pending")
        collectgarbage("collect")
        assert_eq(weak[1], nil, "the runner must not retain the previous result")
        release(true)
        pump(10)
        assert_true(fiber:IsSucceeded())
        assert_eq(fiber._value, 42)
    end)
end)

describe("Cancellation", function()
    it("Ensure runs synchronously on cancel during Yield await", function()
        local ensures, advanced = 0, false
        local fiber = Effect.Async(function()
            Effect.Yield():Await()
            Effect.Yield():Await()
            Effect.Yield():Await()
            advanced = true
        end):Ensure(function() ensures = ensures + 1 end):Run()
        pump(2) -- body started, suspended in some Yield
        fiber:Cancel()
        assert_eq(ensures, 1, "ensure should have run during Cancel()")
        pump(10)
        assert_eq(ensures, 1, "ensure must not run twice")
        assert_true(not advanced, "body must not complete")
    end)

    it("Ensure runs on cancel before the first step", function()
        local ensures, started = 0, false
        local fiber = Effect.Async(function()
            started = true
        end):Ensure(function() ensures = ensures + 1 end):Run()
        fiber:Cancel() -- before the body ever ran
        pump(10)
        assert_eq(ensures, 1, "ensure count")
        assert_true(not started, "body must never start")
    end)

    it("Ensure runs on cancel in the resume-pending window", function()
        -- Child (yield) completed and scheduled the parent step; cancel
        -- lands before the step runs
        local ensures = 0
        local fiber = Effect.Async(function()
            Effect.Yield():Await()
            Effect.Yield():Await()
        end):Ensure(function() ensures = ensures + 1 end):Run()
        pump(1) -- first step runs, suspends on yield
        pump(1) -- child completes, parent step scheduled but not run
        fiber:Cancel()
        pump(10)
        assert_eq(ensures, 1, "ensure count")
    end)

    it("Ensure runs exactly once on cancel during Sleep", function()
        local ensures = 0
        local fiber = Effect.Async(function()
            Effect.Sleep(80):Await()
        end):Ensure(function() ensures = ensures + 1 end):Run()
        pump(2) -- body started, sleeping
        fiber:Cancel()
        assert_eq(ensures, 1, "ensure should run during Cancel()")
        pump(20) -- let the timer window pass
        assert_eq(ensures, 1, "timer must not re-trigger ensure")
    end)

    it("inner Ensure runs before outer on cancel", function()
        local log = {}
        local inner = Effect.Async(function()
            while true do Effect.Yield():Await() end
        end):Ensure(function() table.insert(log, "inner") end)
        local fiber = Effect.Async(function()
            inner:Await()
        end):Ensure(function() table.insert(log, "outer") end):Run()
        pump(3)
        fiber:Cancel()
        assert_eq(table.concat(log, ","), "inner,outer", "ensure order")
    end)

    it("self-cancel from within the body stops at the next await", function()
        local ensures, afterYield = 0, false
        local fiber
        fiber = Effect.Async(function()
            Effect.Yield():Await()
            fiber:Cancel()
            Effect.Yield():Await()
            afterYield = true
        end):Ensure(function() ensures = ensures + 1 end):Run()
        pump(10)
        assert_eq(ensures, 1, "ensure count")
        assert_true(not afterYield, "body must not continue past self-cancel")
    end)

    it("cancelling an awaiter leaves the awaited fiber running", function()
        local ensures, sharedDone = 0, false
        local shared = Effect.Async(function()
            Effect.Yield():Await()
            Effect.Yield():Await()
            sharedDone = true
        end):Run()
        local fiber = Effect.Async(function()
            shared:Await()
        end):Ensure(function() ensures = ensures + 1 end):Run()
        pump(1)
        fiber:Cancel()
        assert_eq(ensures, 1, "awaiter ensure should run at Cancel()")
        pump(10)
        assert_true(sharedDone, "awaited fiber should run to completion")
        assert_eq(ensures, 1, "ensure must not run twice")
    end)
end)

describe("Effect.All / Race", function()
    it("cancel of All runs every child's Ensure", function()
        local e1, e2 = 0, 0
        local fiber = Effect.All({
            Effect.Async(function()
                while true do Effect.Yield():Await() end
            end):Ensure(function() e1 = e1 + 1 end),
            Effect.Async(function()
                while true do Effect.Yield():Await() end
            end):Ensure(function() e2 = e2 + 1 end),
        }):Run()
        pump(3)
        fiber:Cancel()
        pump(5)
        assert_eq(e1, 1, "first child ensure")
        assert_eq(e2, 1, "second child ensure")
    end)

    it("one failure in All cancels siblings and runs their Ensure", function()
        local sib, err = 0, nil
        local fiber = Effect.All({
            Effect.Async(function()
                Effect.Yield():Await()
                error("kaput")
            end),
            Effect.Async(function()
                while true do Effect.Yield():Await() end
            end):Ensure(function() sib = sib + 1 end),
        }):Run()
        fiber:OnComplete(function(f) err = f._error end)
        pump(10)
        assert_true(fiber:IsFailed(), "All should fail")
        assert_true(tostring(err):find("kaput") ~= nil, "failure should propagate")
        assert_eq(sib, 1, "sibling ensure")
    end)

    it("Race winner completes, loser's Ensure runs", function()
        local loser, result = 0, nil
        local fiber = Effect.Race({
            Effect.Async(function()
                Effect.Yield():Await()
                return "fast"
            end),
            Effect.Async(function()
                while true do Effect.Yield():Await() end
            end):Ensure(function() loser = loser + 1 end),
        }):Run()
        fiber:OnComplete(function(f) result = f._value end)
        pump(10)
        assert_eq(result, "fast", "winner result")
        assert_eq(loser, 1, "loser ensure")
    end)
end)

describe("Task pool", function()
    it("awaited yields reuse pooled tasks instead of creating new ones", function()
        local before = TestEnv.libAsyncCreatedCount()
        local fiber = Effect.Async(function()
            for _ = 1, 100 do
                Effect.Yield():Await()
            end
        end):Run()
        pump(250)
        assert_true(fiber:IsSucceeded(), "yield loop should complete")
        assert_eq(TestEnv.libAsyncCreatedCount() - before, 0, "new tasks created")
    end)
end)

describe("Effect.FromCallback", function()
    it("synchronous resolve passes the value through", function()
        local result = nil
        Effect.FromCallback(function(resolve)
            resolve("sync")
        end):Run():OnComplete(function(f) result = f._value end)
        pump(2)
        assert_eq(result, "sync", "result")
    end)

    it("late resolve from an external callback", function()
        local captured = nil
        local fiber = Effect.FromCallback(function(resolve)
            captured = resolve
        end):Run()
        pump(3)
        assert_true(fiber:IsRunning(), "should still be pending")
        captured("late")
        assert_true(fiber:IsSucceeded(), "should settle on resolve")
        assert_eq(fiber._value, "late", "result")
    end)

    it("reject fails the effect", function()
        local err = nil
        local fiber = Effect.FromCallback(function(_, reject)
            reject("nope")
        end):Run()
        fiber:OnComplete(function(f) err = f._error end)
        pump(2)
        assert_true(fiber:IsFailed(), "should fail")
        assert_eq(err, "nope", "error value")
    end)

    it("executor throw becomes a rejection", function()
        local err = nil
        local fiber = Effect.FromCallback(function()
            error("executor blew up")
        end):Run()
        fiber:OnComplete(function(f) err = f._error end)
        pump(2)
        assert_true(fiber:IsFailed(), "should fail")
        assert_true(tostring(err):find("executor blew up") ~= nil, "error should propagate")
    end)

    it("first settle wins, later calls ignored", function()
        local result, err = nil, nil
        local fiber = Effect.FromCallback(function(resolve, reject)
            resolve("first")
            resolve("second")
            reject("third")
        end):Run()
        fiber:OnComplete(function(f) result, err = f._value, f._error end)
        pump(2)
        assert_true(fiber:IsSucceeded(), "should succeed")
        assert_eq(result, "first", "result")
        assert_eq(err, nil, "no error")
    end)

    it("cancel runs the canceler and unwinds Ensure synchronously", function()
        local ensures, cancelerRan = 0, false
        local captured = nil
        local fiber = Effect.FromCallback(function(resolve)
            captured = resolve
            return function() cancelerRan = true end
        end):Ensure(function() ensures = ensures + 1 end):Run()
        pump(2)
        fiber:Cancel()
        assert_true(cancelerRan, "canceler should run")
        assert_eq(ensures, 1, "ensure should run during Cancel()")
        captured("too late") -- must be ignored
        pump(5)
        assert_eq(ensures, 1, "ensure must not run twice")
        assert_true(not fiber:IsSucceeded(), "late resolve must be ignored")
    end)

    it("canceler does not run on normal completion", function()
        local cancelerRan = false
        local fiber = Effect.FromCallback(function(resolve)
            resolve(1)
            return function() cancelerRan = true end
        end):Run()
        pump(2)
        assert_true(fiber:IsSucceeded(), "should succeed")
        fiber:Cancel() -- already settled: no-op
        assert_true(not cancelerRan, "canceler must not run after settling")
    end)

    it("cancel from within the executor still runs the returned canceler", function()
        local cancelerRan = false
        local fiber
        local eff = Effect.FromCallback(function()
            fiber:Cancel()
            return function() cancelerRan = true end
        end)
        -- Await inside an Async so a fiber handle exists before the executor runs
        fiber = Effect.Async(function()
            eff:Await()
        end):Run()
        pump(2)
        assert_true(cancelerRan, "canceler should run when cancelled mid-executor")
        assert_true(not fiber:IsRunning(), "fiber should be settled")
    end)
end)

describe("Semaphore", function()
    it("WithPermit serializes FIFO", function()
        local sem = Effect.Semaphore.New(1)
        local log = {}
        local function worker(id)
            return sem:WithPermit(Effect.Async(function()
                table.insert(log, id .. ":start")
                Effect.Yield():Await()
                Effect.Yield():Await()
                table.insert(log, id .. ":end")
            end))
        end
        worker("a"):Run()
        worker("b"):Run()
        worker("c"):Run()
        pump(30)
        assert_eq(table.concat(log, ","),
            "a:start,a:end,b:start,b:end,c:start,c:end", "execution order")
    end)

    it("permits > 1 allows exactly that much concurrency", function()
        local sem = Effect.Semaphore.New(2)
        local active, maxActive = 0, 0
        local function worker()
            return sem:WithPermit(Effect.Async(function()
                active = active + 1
                if active > maxActive then maxActive = active end
                Effect.Yield():Await()
                active = active - 1
            end))
        end
        for _ = 1, 5 do worker():Run() end
        pump(30)
        assert_eq(maxActive, 2, "max concurrency")
        assert_eq(active, 0, "all workers finished")
    end)

    it("permit is released when the body errors", function()
        local sem = Effect.Semaphore.New(1)
        local secondRan = false
        local f1 = sem:WithPermit(Effect.Async(function()
            Effect.Yield():Await()
            error("dead body")
        end)):Run()
        f1:OnComplete(function() end) -- observe the error
        sem:WithPermit(Effect.Async(function()
            secondRan = true
        end)):Run()
        pump(20)
        assert_true(f1:IsFailed(), "first should fail")
        assert_true(secondRan, "permit should be released after the error")
    end)

    it("cancelling a queued waiter unwinds it and skips its turn", function()
        local sem = Effect.Semaphore.New(1)
        local bEnsure, bRan, cRan = 0, false, false
        local releaseA = false
        sem:WithPermit(Effect.Async(function()
            while not releaseA do Effect.Yield():Await() end
        end)):Run()
        pump(2) -- a holds the permit
        local b = sem:WithPermit(Effect.Async(function()
            bRan = true
        end)):Ensure(function() bEnsure = bEnsure + 1 end):Run()
        sem:WithPermit(Effect.Async(function()
            cRan = true
        end)):Run()
        pump(2) -- b and c queued
        b:Cancel()
        assert_eq(bEnsure, 1, "queued waiter ensure should run at Cancel()")
        releaseA = true
        pump(20)
        assert_true(not bRan, "cancelled waiter body must not run")
        assert_true(cRan, "next waiter should get the permit")
        assert_eq(bEnsure, 1, "ensure must not run twice")
    end)

    it("cancel between grant and delivery unwinds now, recycles the permit", function()
        local sem = Effect.Semaphore.New(1)
        local bEnsure, bRan, cRan = 0, false, false
        local releaseA = false
        local a = sem:WithPermit(Effect.Async(function()
            while not releaseA do Effect.Yield():Await() end
        end)):Run()
        pump(2)
        local b = sem:WithPermit(Effect.Async(function()
            bRan = true
        end)):Ensure(function() bEnsure = bEnsure + 1 end):Run()
        local c = sem:WithPermit(Effect.Async(function()
            cRan = true
        end)):Run()
        pump(2) -- b, c queued
        releaseA = true
        while a:IsRunning() do pump(1) end
        -- a released: the permit is committed to b, delivery not yet dispatched
        b:Cancel()
        assert_eq(bEnsure, 1, "grantee ensure should run synchronously at Cancel()")
        pump(20)
        assert_true(not bRan, "cancelled grantee body must not run")
        assert_true(cRan, "permit should be recycled to the next waiter")
        assert_true(not c:IsRunning(), "c should complete")
    end)

    it("over-release errors", function()
        local sem = Effect.Semaphore.New(1)
        assert_error(function() sem:Release() end, "without matching Acquire")
    end)
end)

describe("Unhandled errors", function()
    it("no unexpected unhandled errors escaped any test", function()
        for _, err in ipairs(unhandled) do
            assert_true(Effect.IsCancelledError(err),
                "unexpected unhandled error: " .. tostring(err))
        end
    end)
end)
