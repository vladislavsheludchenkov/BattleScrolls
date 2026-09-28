-- Fake LibAsync with a manually pumped frame scheduler. Deterministic frame
-- control lets tests land cancellations (or any event) on an exact frame.
--
-- Model: a call scheduled during frame N runs in frame N+1 (one pump). This
-- is stricter than the real LibAsync (which may continue within the same
-- frame's time budget) - deliberately so, since it maximizes the suspension
-- windows race-sensitive tests need to hit. task:Cancel() invalidates
-- entries even when already snapshotted for the current frame (generation
-- check), matching the real library clearing the live callstack.
--
-- Installs _G.LibAsync and returns { pump = ..., createdCount = ... }.

local allTasks = {}
local currentTimeMs = 0
local FRAME_MS = 16
local created = 0

local fakeAsync = {}

function fakeAsync:Create(name)
    created = created + 1
    local task = {
        name = name,
        gen = 0,
        queue = {},  -- { gen, fn } scheduled calls, run on the next pump
        delays = {}, -- { gen, fireAt, fn }
    }
    function task:Call(fn)
        table.insert(self.queue, { gen = self.gen, fn = fn })
        return self
    end
    function task:Cancel()
        self.gen = self.gen + 1
        self.queue = {}
        return self
    end
    function task:StopTimer()
        self.delays = {}
        return self
    end
    function task:Delay(ms, fn)
        self:StopTimer()
        table.insert(self.delays, { gen = self.gen, fireAt = currentTimeMs + ms, fn = fn })
        return self
    end
    table.insert(allTasks, task)
    return task
end

---Advances n frames (default 1), running due calls and expired delays.
---@param frames number|nil
local function pump(frames)
    for _ = 1, (frames or 1) do
        currentTimeMs = currentTimeMs + FRAME_MS
        local batch = {}
        for _, t in ipairs(allTasks) do
            for _, entry in ipairs(t.queue) do
                batch[#batch + 1] = { task = t, gen = entry.gen, fn = entry.fn }
            end
            t.queue = {}
            local remaining = {}
            for _, d in ipairs(t.delays) do
                if d.fireAt <= currentTimeMs then
                    batch[#batch + 1] = { task = t, gen = d.gen, fn = d.fn }
                else
                    remaining[#remaining + 1] = d
                end
            end
            t.delays = remaining
        end
        for _, entry in ipairs(batch) do
            if entry.gen >= entry.task.gen then
                entry.fn()
            end
        end
    end
end

_G.LibAsync = fakeAsync

return {
    pump = pump,
    ---Total LibAsync:Create calls; lets tests assert task-pool reuse.
    createdCount = function() return created end,
}
