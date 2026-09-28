-- Minimal describe/it test framework, busted/Taneth-inspired, for running
-- addon logic outside the game on plain Lua. Test files call the globals
-- describe/it plus the assert_* helpers; run.lua invokes framework.report()
-- after loading all files.

local framework = {}

---@class RegisteredTest
---@field name string Full path including describe prefixes
---@field fn fun()

---@type RegisteredTest[]
local tests = {}
---@type string[]
local describeStack = {}

---Groups tests. Nestable; the names join into the reported test path.
---@param name string
---@param body fun()
function describe(name, body)
    table.insert(describeStack, name)
    body()
    table.remove(describeStack)
end

---Registers one test case.
---@param name string
---@param fn fun()
function it(name, fn)
    local path = table.concat(describeStack, " > ")
    if path ~= "" then
        path = path .. " > " .. name
    else
        path = name
    end
    table.insert(tests, { name = path, fn = fn })
end

---@param cond any
---@param label string|nil
function assert_true(cond, label)
    if not cond then
        error((label or "assertion failed") .. " (expected truthy, got " .. tostring(cond) .. ")", 2)
    end
end

---@param actual any
---@param expected any
---@param label string|nil
function assert_eq(actual, expected, label)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s",
            label or "assert_eq", tostring(expected), tostring(actual)), 2)
    end
end

---Asserts fn throws; optionally that the error message contains pattern.
---@param fn fun()
---@param pattern string|nil
function assert_error(fn, pattern)
    local ok, err = pcall(fn)
    if ok then
        error("expected an error, got none", 2)
    end
    if pattern and not tostring(err):find(pattern, 1, true) then
        error(string.format("error %q does not contain %q", tostring(err), pattern), 2)
    end
end

local GREEN, RED, RESET = "\27[0;32m", "\27[0;31m", "\27[0m"

---Runs every registered test, prints a report, returns the failure count.
---@return number failures
function framework.report()
    local failures = 0
    for _, test in ipairs(tests) do
        local ok, err = pcall(test.fn)
        if ok then
            print(string.format("%sPASS%s %s", GREEN, RESET, test.name))
        else
            failures = failures + 1
            print(string.format("%sFAIL%s %s\n     %s", RED, RESET, test.name, tostring(err)))
        end
    end
    print(string.format("\n%d tests, %s%d failed%s",
        #tests, failures > 0 and RED or GREEN, failures, RESET))
    return failures
end

return framework
