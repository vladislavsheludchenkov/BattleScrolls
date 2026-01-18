-----------------------------------------------------------
-- Effect
-- Lazy, composable async computation with cancellation
--
-- Inspired by cats-effect IO, ZIO, and effect-ts Effect.
-- Effects are descriptions of computations - nothing runs
-- until you call :Run() which returns a cancellable Fiber.
--
-- Example:
--   local fiber = Effect.Async(function()
--       local data = fetchData():Await()
--       local result = processData(data):Await()
--       return result
--   end):Ensure(function()
--       cleanup()
--   end):Run()
--
--   fiber:Cancel()  -- Cleanly stops execution
--
-----------------------------------------------------------

---@class CancelledError
---@field message string
---@field isCancelled boolean
local CancelledError = {}
CancelledError.__index = CancelledError

function CancelledError:__tostring()
    return self.message
end

-- Immutable singleton for default cancelled error (zero allocation)
local ImmutableCancelledError = setmetatable({
    __newindex = function() end,
    __tostring = CancelledError.__tostring,
}, { __index = CancelledError })
local defaultCancelledError = setmetatable({
    message = "Effect cancelled",
    isCancelled = true
}, ImmutableCancelledError)

---@param message string|nil
---@return CancelledError
function CancelledError.New(message)
    if message then
        return setmetatable({
            message = message,
            isCancelled = true
        }, CancelledError)
    end
    return defaultCancelledError
end

-----------------------------------------------------------
-- Fiber Class (Running Effect Instance)
-----------------------------------------------------------

-- Forward declaration (defined in Effect Interpreter section)
local cleanupFiberTask

---@generic T
---@class Fiber<T>
---@field _status "running"|"succeeded"|"failed"|"cancelled"
---@diagnostic disable-next-line: undefined-doc-name -- LuaLS limitation with generic type parameters
---@field _value T|nil
---@field _error any
---@field _callbacks fun(fiber: Fiber<any>)[]
---@field _cancelFn fun()|nil
---@field _observed boolean|nil True if someone is listening (Await or OnComplete called)
---@field _task table|nil LibAsync task handle (pooled)
local Fiber = {}
Fiber.__index = Fiber

---@return Fiber<any>
function Fiber.New()
    return setmetatable({
        _status = "running",
        _value = nil,
        _error = nil,
        _callbacks = {},
        _cancelFn = nil,
    }, Fiber)
end

---Check if fiber is still running
---@return boolean
function Fiber:IsRunning()
    return self._status == "running"
end

---Check if fiber completed successfully
---@return boolean
function Fiber:IsSucceeded()
    return self._status == "succeeded"
end

---Check if fiber failed
---@return boolean
function Fiber:IsFailed()
    return self._status == "failed"
end

---Check if fiber was cancelled
---@return boolean
function Fiber:IsCancelled()
    return self._status == "cancelled"
end

---Get the status
---@return "running"|"succeeded"|"failed"|"cancelled"
function Fiber:Status()
    return self._status
end

---Internal: Complete with success
---@param value any
function Fiber:_Succeed(value)
    if self._status ~= "running" then return end
    self._status = "succeeded"
    self._value = value
    self:_NotifyCallbacks()
end

---Internal: Complete with failure
---@param err any
function Fiber:_Fail(err)
    if self._status ~= "running" then return end
    self._status = "failed"
    self._error = err
    self:_NotifyCallbacks()
end

---Internal: Mark as cancelled
function Fiber:_MarkCancelled()
    if self._status ~= "running" then return end
    self._status = "cancelled"
    self._error = CancelledError.New()
    self:_NotifyCallbacks()
end

-----------------------------------------------------------
-- Shared Callback Dispatcher
-- Single long-lived task for all completion callbacks
-----------------------------------------------------------

---@type table|nil LibAsync task for callback dispatch
local callbackDispatcher = nil

---Get the shared callback dispatcher (creates on first use)
---@return table LibAsync task
local function getCallbackDispatcher()
    if not callbackDispatcher then
        callbackDispatcher = LibAsync:Create("EffectCB")
    end
    return callbackDispatcher
end

---Internal: Notify all completion callbacks
function Fiber:_NotifyCallbacks()
    local dispatcher = getCallbackDispatcher()
    for _, cb in ipairs(self._callbacks) do
        local fiber = self
        dispatcher:Call(function()
            cb(fiber)
        end)
    end
    self._callbacks = {}
    cleanupFiberTask(self)
end

---Internal: Register completion callback without marking as observed
---@param fn fun(fiber: Fiber<any>)
function Fiber:_OnCompleteInternal(fn)
    if self._status == "running" then
        table.insert(self._callbacks, fn)
    else
        local fiber = self
        getCallbackDispatcher():Call(function()
            fn(fiber)
        end)
    end
end

---Register a completion callback
---@generic T
---@param fn fun(fiber: Fiber<T>)
function Fiber:OnComplete(fn)
    self._observed = true
    self:_OnCompleteInternal(fn)
end

---Cancel this fiber
function Fiber:Cancel()
    if self._status ~= "running" then return end

    if self._cancelFn then
        self._cancelFn()
    end

    self:_MarkCancelled()
end

---Await this fiber's result (must be called from within Effect.Async)
---@generic T
---@return T
function Fiber:Await()
    local co = coroutine.running()
    if not co then
        error("Fiber:Await() must be called from within Effect.Async()", 2)
    end

    -- Mark as observed - someone is listening to the result
    self._observed = true

    if self._status == "succeeded" then
        return self._value
    elseif self._status == "failed" or self._status == "cancelled" then
        error(self._error, 0)
    end

    -- Yield the fiber directly to the scheduler (detected via IsFiber)
    -- The interpreter resumes us with (success, value) arguments
    local success, value = coroutine.yield(self)

    if success then
        return value
    else
        error(value, 0)
    end
end

-----------------------------------------------------------
-- Effect Class (Lazy Computation Description)
-----------------------------------------------------------

---@generic T
---@class Effect<T>
---@field _tag "succeed"|"fail"|"sync"|"async"|"sleep"|"yield"|"yieldGC"|"map"|"flatMap"|"tapError"|"mapError"|"recover"|"recoverWith"|"ensure"|"fork"|"all"|"race"|"allSettled"
---@field _isEffect boolean
---@diagnostic disable-next-line: undefined-doc-name -- LuaLS limitation with generic type parameters
---@field _value T|nil For succeed
---@field _error any For fail
---@field _fn function|nil For sync/async/map/flatMap/tapError/mapError/recover/recoverWith/ensure
---@field _ms number|nil For sleep
---@field _source Effect<any>|nil For map/flatMap/tapError/mapError/recover/recoverWith/ensure/fork
---@field _effects Effect<any>[]|nil For all/race/allSettled
local Effect = {}
Effect.__index = Effect

-- Marker for identifying Effect instances
Effect._isEffect = true

---Check if a value is an Effect
---@param value any
---@return boolean
function Effect.IsEffect(value)
    return type(value) == "table" and value._isEffect == true
end

---Check if a value is a Fiber
---@param value any
---@return boolean
function Effect.IsFiber(value)
    return getmetatable(value) == Fiber
end

---Check if an error is a CancelledError
---@param err any
---@return boolean
function Effect.IsCancelledError(err)
    return type(err) == "table" and err.isCancelled == true
end

-----------------------------------------------------------
-- Effect Constructors
-----------------------------------------------------------

---Create an Effect that succeeds with a value
---@generic T
---@param value T
---@return Effect<T>
function Effect.Succeed(value)
    return setmetatable({ _tag = "succeed", _isEffect = true, _value = value }, Effect)
end

---Create an Effect that fails with an error
---@param err any
---@return Effect<any>
function Effect.Fail(err)
    return setmetatable({ _tag = "fail", _isEffect = true, _error = err }, Effect)
end

---Create an Effect from a synchronous function
---@generic T
---@param fn fun(): T
---@return Effect<T>
function Effect.Sync(fn)
    return setmetatable({ _tag = "sync", _isEffect = true, _fn = fn }, Effect)
end

---Create an Effect from an async coroutine function
---@generic T
---@param fn (fun(): T) | (fun())
---@return Effect<T>
function Effect.Async(fn)
    return setmetatable({ _tag = "async", _isEffect = true, _fn = fn }, Effect)
end

---Create an Effect that sleeps for a duration
---@param ms number Milliseconds to sleep
---@return Effect<nil>
function Effect.Sleep(ms)
    return setmetatable({ _tag = "sleep", _isEffect = true, _ms = ms }, Effect)
end

-- Immutable metatable for singleton effects (prevents modification, inherits methods)
local ImmutableEffect = setmetatable({
    __newindex = function() end,  -- silently ignore writes
}, { __index = Effect })
ImmutableEffect.__index = Effect

-- Singleton instances for parameterless effects (zero allocation, immutable)
local yieldEffect = setmetatable({ _tag = "yield", _isEffect = true }, ImmutableEffect)
local yieldWithGCEffect = setmetatable({ _tag = "yieldGC", _isEffect = true }, ImmutableEffect)

---Create an Effect that yields to the next frame
---@return Effect<nil>
function Effect.Yield()
    return yieldEffect
end

---Create an Effect that yields and requests GC
---@return Effect<nil>
function Effect.YieldWithGC()
    return yieldWithGCEffect
end

-----------------------------------------------------------
-- Effect Combinators
-----------------------------------------------------------

---Transform the success value
---@generic T, U
---@param fn fun(value: T): U
---@return Effect<U>
function Effect:Map(fn)
    return setmetatable({ _tag = "map", _isEffect = true, _source = self, _fn = fn }, Effect)
end

---Replace value with provided one
---@generic A
---@param a A
---@return Effect<A>
function Effect:As(a)
    return self:Map(function() return a end)
end

---Chain with a function that returns an Effect
---@generic T, U
---@param fn fun(value: T): Effect<U>
---@return Effect<U>
function Effect:FlatMap(fn)
    return setmetatable({ _tag = "flatMap", _isEffect = true, _source = self, _fn = fn }, Effect)
end

---Execute side effect on success, pass value through
---@generic T
---@param fn fun(value: T)
---@return Effect<T>
function Effect:Tap(fn)
    return self:Map(function(value)
        fn(value)
        return value
    end)
end

---Execute side effect on error, pass error through
---@generic T
---@param fn fun(err: any)
---@return Effect<T>
function Effect:TapError(fn)
    return setmetatable({ _tag = "tapError", _isEffect = true, _source = self, _fn = fn }, Effect)
end

---Transform the error
---@generic T
---@param fn fun(err: any): any
---@return Effect<T>
function Effect:MapError(fn)
    return setmetatable({ _tag = "mapError", _isEffect = true, _source = self, _fn = fn }, Effect)
end

---Recover from an error with a value
---@generic T
---@param fn fun(err: any): T
---@return Effect<T>
function Effect:Recover(fn)
    return setmetatable({ _tag = "recover", _isEffect = true, _source = self, _fn = fn }, Effect)
end

---Recover from an error with an Effect
---@generic T
---@param fn fun(err: any): Effect<T>
---@return Effect<T>
function Effect:RecoverWith(fn)
    return setmetatable({ _tag = "recoverWith", _isEffect = true, _source = self, _fn = fn }, Effect)
end

---Execute cleanup regardless of outcome (success, failure, or cancellation)
---@generic T
---@param fn fun()
---@return Effect<T>
function Effect:Ensure(fn)
    return setmetatable({ _tag = "ensure", _isEffect = true, _source = self, _fn = fn }, Effect)
end

---Fork this effect to run concurrently, returns Effect<Fiber<T>>
---@generic T
---@return Effect<Fiber<T>>
function Effect:Fork()
    return setmetatable({ _tag = "fork", _isEffect = true, _source = self }, Effect)
end

-----------------------------------------------------------
-- Effect Composition
-----------------------------------------------------------

---Wait for all effects to succeed, fail fast on first failure
---@generic T
---@param effects Effect<T>[]
---@return Effect<T[]>
function Effect.All(effects)
    return setmetatable({ _tag = "all", _isEffect = true, _effects = effects }, Effect)
end

---Race effects, first to complete wins (others keep running)
---@generic T
---@param effects Effect<T>[]
---@return Effect<T>
function Effect.Race(effects)
    return setmetatable({ _tag = "race", _isEffect = true, _effects = effects }, Effect)
end

---@class EffectSucceededResult
---@field status "succeeded"
---@field value any

---@class EffectFailedResult
---@field status "failed"
---@field error any

---@alias EffectSettledResult EffectSucceededResult | EffectFailedResult

---Wait for all effects to settle
---@generic T
---@param effects Effect<T>[]
---@return Effect<EffectSettledResult[]>
function Effect.AllSettled(effects)
    return setmetatable({ _tag = "allSettled", _isEffect = true, _effects = effects }, Effect)
end

---Raise an error to ESO's error UI without interrupting the current computation.
---Forks a failing effect that triggers the unhandled error handler.
---@param err any The error to raise
function Effect.RaiseError(err)
    Effect.Fail(err):Run()
end

-----------------------------------------------------------
-- Effect Interpreter (Run)
-----------------------------------------------------------

-- Forward declaration for mutual recursion
local runEffect

-----------------------------------------------------------
-- LibAsync Task Pool
-- Pre-allocated task objects to avoid allocation per fiber
-- (LibAsync tasks are reusable after Cancel())
-----------------------------------------------------------

---@type table[]
local taskPool = {}
---@type number
local poolHighWaterMark = 0

-- Pre-populate with task objects
for i = 1, 32 do
    taskPool[i] = LibAsync:Create("E" .. i)
    poolHighWaterMark = i
end

---Reset a task to clean state before returning to pool
---@param task table
local function resetTask(task)
    task:Cancel()       -- Clears callstack, removes from scheduler
    task:StopTimer()    -- Cancel any pending delays
    task.finally = nil
    task.onError = nil
    task.oncePerFrame = nil
    task.Error = nil
end

---Acquire a task from the pool (or create new one if exhausted)
---@return table
local function acquireTask()
    local task = taskPool[#taskPool]
    if task then
        taskPool[#taskPool] = nil
        return task
    end
    -- Pool exhausted - expand it
    poolHighWaterMark = poolHighWaterMark + 1
    return LibAsync:Create("E" .. poolHighWaterMark)
end

---Return a task to the pool for reuse
---@param task table|nil
local function releaseTask(task)
    if task then
        resetTask(task)
        taskPool[#taskPool + 1] = task
    end
end

---Cleanup fiber's LibAsync task and return to pool
---@param fiber Fiber<any>
cleanupFiberTask = function(fiber)
    if fiber._task then
        releaseTask(fiber._task)
        fiber._task = nil
    end
end

---Get or create task for a fiber (lazy initialization)
---@param fiber Fiber<any>
---@return table
local function getTask(fiber)
    if not fiber._task then
        fiber._task = acquireTask()
    end
    return fiber._task
end

---Internal: Run an async coroutine effect
---@param effect Effect<any>
---@param fiber Fiber<any>
---@param onDone fun(success: boolean, value: any)
local function runAsync(effect, fiber, onDone)
    local co = coroutine.create(effect._fn)
    local cancelled = false
    local nextSuccess, nextValue  -- arguments for next resume
    local task = getTask(fiber)

    -- Set up cancellation
    fiber._cancelFn = function()
        cancelled = true
        task:Cancel()
    end

    local function step()
        if cancelled then
            onDone(false, CancelledError.New())
            return
        end

        if coroutine.status(co) == "dead" then
            return
        end

        -- Resume with success/value arguments
        local ok, yielded = coroutine.resume(co, nextSuccess, nextValue)

        if not ok then
            onDone(false, yielded)
            return
        end

        if coroutine.status(co) == "dead" then
            onDone(true, yielded)
            return
        end

        -- Check what was yielded - directly yield Effect or Fiber
        if Effect.IsFiber(yielded) then
            -- Awaiting a Fiber
            yielded:OnComplete(function(f)
                if cancelled then
                    onDone(false, CancelledError.New())
                    return
                end
                nextSuccess = f:IsSucceeded()
                nextValue = f:IsSucceeded() and f._value or f._error
                task:Call(step)
            end)
            return
        elseif Effect.IsEffect(yielded) then
            -- Awaiting an Effect - run it and continue
            local childFiber = Fiber.New()

            -- Cancel child if parent is cancelled
            local oldCancelFn = fiber._cancelFn
            fiber._cancelFn = function()
                cancelled = true
                childFiber:Cancel()
                task:Cancel()
                if oldCancelFn then oldCancelFn() end
            end

            runEffect(yielded, childFiber, function(success, value)
                if cancelled then
                    onDone(false, CancelledError.New())
                    return
                end
                nextSuccess = success
                nextValue = value
                task:Call(step)
            end)
            return
        end

        -- Regular yield - continue on next frame
        task:Call(step)
    end

    -- Start on next frame
    task:Call(step)
end

---Internal: Main effect interpreter
---@param effect Effect<any>
---@param fiber Fiber<any>
---@param onDone fun(success: boolean, value: any)
runEffect = function(effect, fiber, onDone)
    local tag = effect._tag

    if tag == "succeed" then
        onDone(true, effect._value)

    elseif tag == "fail" then
        onDone(false, effect._error)

    elseif tag == "sync" then
        local ok, result = pcall(effect._fn)
        onDone(ok, result)

    elseif tag == "async" then
        runAsync(effect, fiber, onDone)

    elseif tag == "sleep" then
        local task = getTask(fiber)
        local cancelled = false

        fiber._cancelFn = function()
            cancelled = true
            task:Cancel()
            onDone(false, CancelledError.New())
        end

        task:Delay(effect._ms, function()
            if not cancelled then
                onDone(true, nil)
            end
        end)

    elseif tag == "yield" then
        getTask(fiber):Call(function()
            onDone(true, nil)
        end)

    elseif tag == "yieldGC" then
        getTask(fiber):Call(function()
            BattleScrolls.gc:RequestGC()
            onDone(true, nil)
        end)

    elseif tag == "map" then
        runEffect(effect._source, fiber, function(success, value)
            if not success then
                onDone(false, value)
            else
                local ok, result = pcall(effect._fn, value)
                onDone(ok, result)
            end
        end)

    elseif tag == "flatMap" then
        runEffect(effect._source, fiber, function(success, value)
            if not success then
                onDone(false, value)
            else
                local ok, nextEffect = pcall(effect._fn, value)
                if not ok then
                    onDone(false, nextEffect)
                elseif not Effect.IsEffect(nextEffect) then
                    onDone(false, "FlatMap: function must return an Effect, got " .. type(nextEffect))
                else
                    runEffect(nextEffect, fiber, onDone)
                end
            end
        end)

    elseif tag == "tapError" then
        runEffect(effect._source, fiber, function(success, value)
            if success then
                onDone(true, value)
            else
                pcall(effect._fn, value)
                onDone(false, value)
            end
        end)

    elseif tag == "mapError" then
        runEffect(effect._source, fiber, function(success, value)
            if success then
                onDone(true, value)
            else
                local ok, newErr = pcall(effect._fn, value)
                if ok then
                    onDone(false, newErr)
                else
                    onDone(false, newErr)
                end
            end
        end)

    elseif tag == "recover" then
        runEffect(effect._source, fiber, function(success, value)
            if success then
                onDone(true, value)
            else
                local ok, result = pcall(effect._fn, value)
                onDone(ok, result)
            end
        end)

    elseif tag == "recoverWith" then
        runEffect(effect._source, fiber, function(success, value)
            if success then
                onDone(true, value)
            else
                local ok, nextEffect = pcall(effect._fn, value)
                if not ok then
                    onDone(false, nextEffect)
                elseif not Effect.IsEffect(nextEffect) then
                    onDone(false, "RecoverWith: function must return an Effect, got " .. type(nextEffect))
                else
                    runEffect(nextEffect, fiber, onDone)
                end
            end
        end)

    elseif tag == "ensure" then
        runEffect(effect._source, fiber, function(success, value)
            -- Always run the ensure function
            pcall(effect._fn)
            onDone(success, value)
        end)

    elseif tag == "fork" then
        local forkedFiber = Fiber.New()
        runEffect(effect._source, forkedFiber, function(success, value)
            if success then
                forkedFiber:_Succeed(value)
            else
                forkedFiber:_Fail(value)
            end
        end)
        -- Immediately return the fiber handle
        onDone(true, forkedFiber)

    elseif tag == "all" then
        local effects = effect._effects
        local count = #effects

        if count == 0 then
            onDone(true, {})
            return
        end

        local results = {}
        local remaining = count
        local failed = false
        local childFibers = {}

        fiber._cancelFn = function()
            for _, f in ipairs(childFibers) do
                f:Cancel()
            end
        end

        for i, eff in ipairs(effects) do
            local childFiber = Fiber.New()
            childFibers[i] = childFiber

            runEffect(eff, childFiber, function(success, value)
                if failed then return end

                if not success then
                    failed = true
                    -- Cancel all other fibers
                    for j, f in ipairs(childFibers) do
                        if j ~= i then f:Cancel() end
                    end
                    onDone(false, value)
                else
                    results[i] = value
                    remaining = remaining - 1
                    if remaining == 0 then
                        onDone(true, results)
                    end
                end
            end)
        end

    elseif tag == "race" then
        local effects = effect._effects
        local count = #effects

        if count == 0 then
            onDone(false, "Race: empty effects list")
            return
        end

        local settled = false
        local childFibers = {}

        fiber._cancelFn = function()
            for _, f in ipairs(childFibers) do
                f:Cancel()
            end
        end

        for i, eff in ipairs(effects) do
            local childFiber = Fiber.New()
            childFibers[i] = childFiber

            runEffect(eff, childFiber, function(success, value)
                if settled then return end
                settled = true
                -- Cancel all other fibers
                for j, f in ipairs(childFibers) do
                    if j ~= i then f:Cancel() end
                end
                onDone(success, value)
            end)
        end

    elseif tag == "allSettled" then
        local effects = effect._effects
        local count = #effects

        if count == 0 then
            onDone(true, {})
            return
        end

        local results = {}
        local remaining = count
        local childFibers = {}

        fiber._cancelFn = function()
            for _, f in ipairs(childFibers) do
                f:Cancel()
            end
        end

        for i, eff in ipairs(effects) do
            local childFiber = Fiber.New()
            childFibers[i] = childFiber

            runEffect(eff, childFiber, function(success, value)
                if success then
                    results[i] = { status = "succeeded", value = value }
                else
                    results[i] = { status = "failed", error = value }
                end
                remaining = remaining - 1
                if remaining == 0 then
                    onDone(true, results)
                end
            end)
        end

    else
        onDone(false, "Unknown effect tag: " .. tostring(tag))
    end
end

-----------------------------------------------------------
-- Default unhandled error handler
-----------------------------------------------------------

---@param err any
---@param _fiber Fiber<any>
local function defaultUnhandledErrorHandler(err, _fiber)
    local message
    if type(err) == "string" then
        message = err
    elseif type(err) == "table" and err.message then
        message = tostring(err.message)
    else
        message = tostring(err)
    end
    error("Unhandled Effect error: " .. message, 0)
end

---@type fun(err: any, fiber: Fiber<any>)
Effect.OnUnhandledError = defaultUnhandledErrorHandler

---Run this effect, returning a Fiber
---Unhandled errors (non-cancelled) are reported via Effect.OnUnhandledError
---@generic T
---@return Fiber<T>
function Effect:Run()
    local fiber = Fiber.New()

    runEffect(self, fiber, function(success, value)
        if fiber:IsRunning() then
            if success then
                fiber:_Succeed(value)
            else
                fiber:_Fail(value)
            end
        end
    end)

    -- Report unhandled errors (cancellation is not an error, observed errors are handled by caller)
    fiber:_OnCompleteInternal(function(f)
        if f:IsFailed() and not Effect.IsCancelledError(f._error) and not f._observed then
            if Effect.OnUnhandledError then
                Effect.OnUnhandledError(f._error, f)
            end
        end
    end)

    return fiber
end

-----------------------------------------------------------
-- Effect:Await (for use inside Effect.Async)
-----------------------------------------------------------

---Await this effect's result (must be called from within Effect.Async)
---@generic T
---@return T
function Effect:Await()
    local co = coroutine.running()
    if not co then
        error("Effect:Await() must be called from within Effect.Async()", 2)
    end

    -- Yield this effect directly to the scheduler (detected via IsEffect)
    -- The interpreter resumes us with (success, value) arguments
    local success, value = coroutine.yield(self)

    if success then
        return value
    else
        error(value, 0)
    end
end

-----------------------------------------------------------
-- Export
-----------------------------------------------------------

-- Export CancelledError for external use
Effect.CancelledError = CancelledError
Effect.Fiber = Fiber

-- Make globally available
_G.LibEffect = Effect

-- Also export to BattleScrolls namespace if available
if BattleScrolls then
    BattleScrolls.Effect = Effect
end

return Effect
