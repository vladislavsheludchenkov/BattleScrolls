-----------------------------------------------------------
-- Log
-- Leveled logging for Battle Scrolls
--
-- Provides leveled logging with lazy evaluation support.
-- Log level is controlled via settings.logLevel.
--
-- Usage:
--   BattleScrolls.log.Info("Simple message")
--   BattleScrolls.log.Debug(function()
--       return "Expensive: " .. computeDebugInfo()
--   end)
--
-- Levels: NONE(0), ERROR(1), WARN(2), INFO(3), DEBUG(4), TRACE(5)
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@alias LogLevel 0|1|2|3|4|5

---@class BattleScrollsLog
---@field Error fun(message: string|fun():string|nil) Log at ERROR level
---@field Warn fun(message: string|fun():string|nil) Log at WARN level
---@field Info fun(message: string|fun():string|nil) Log at INFO level
---@field Debug fun(message: string|fun():string|nil) Log at DEBUG level

---@type BattleScrollsLog
local log = {}
BattleScrolls.log = log

---@param level LogLevel
---@return fun(message: string|fun():string|nil)
local function makeLogger(level)
    return function(message)
        local settings = BattleScrolls.storage.savedVariables.settings
        if not settings.logLevel or settings.logLevel < level then
            return
        end
        local str
        if type(message) == "function" then
            str = message()
            if str == nil then
                return
            end
        else
            str = message
        end
        d(string.format("[%s]|cffffff %s", os.date("%X"), str))
    end
end

log.Error = makeLogger(1)
log.Warn = makeLogger(2)
log.Info = makeLogger(3)
log.Debug = makeLogger(4)
