-- Offline test entry point. Run from the repo root:
--   lua tests/run.lua tests/effect_test.lua [more files...]
-- scripts/test.sh does exactly that for every tests/*_test.lua.

dofile("tests/mocks/eso.lua")

---Shared handles for test files.
---@class TestEnv
---@field pump fun(frames: number|nil) Advance the fake LibAsync scheduler
---@field libAsyncCreatedCount fun(): number Total fake tasks ever created
TestEnv = {}

local libasync = dofile("tests/mocks/libasync.lua")
TestEnv.pump = libasync.pump
TestEnv.libAsyncCreatedCount = libasync.createdCount

local framework = dofile("tests/framework.lua")

if #arg == 0 then
    print("usage: lua tests/run.lua <test files...>")
    os.exit(1)
end

for _, file in ipairs(arg) do
    dofile(file)
end

os.exit(framework.report() == 0 and 0 or 1)
