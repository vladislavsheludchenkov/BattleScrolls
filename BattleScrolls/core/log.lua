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

---@class LogLevelConstants
---@field NONE 0
---@field ERROR 1
---@field WARN 2
---@field INFO 3
---@field DEBUG 4
---@field TRACE 5

---@class BattleScrollsLog
---@field Level LogLevelConstants Log level constants
---@field DoOnLevel fun(level: LogLevel): fun(action: fun()) Execute action if current log level is at least the given level (curried)
---@field DoOnError fun(action: fun()) Execute action if current log level is at least ERROR
---@field DoOnWarn fun(action: fun()) Execute action if current log level is at least WARN
---@field DoOnInfo fun(action: fun()) Execute action if current log level is at least INFO
---@field DoOnDebug fun(action: fun()) Execute action if current log level is at least DEBUG
---@field DoOnTrace fun(action: fun()) Execute action if current log level is at least TRACE
---@field Log fun(level: LogLevel): fun(message: string|fun():string|nil) Log at the given level (curried)
---@field Error fun(message: string|fun():string|nil) Log at ERROR level
---@field Warn fun(message: string|fun():string|nil) Log at WARN level
---@field Info fun(message: string|fun():string|nil) Log at INFO level
---@field Debug fun(message: string|fun():string|nil) Log at DEBUG level
---@field Trace fun(message: string|fun():string|nil) Log at TRACE level

---@type BattleScrollsLog
local log = {}
BattleScrolls.log = log

log.Level = {
    NONE = 0,
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4,
    TRACE = 5
}

log.DoOnLevel = function(level)
    return function(action)
        local settings = BattleScrolls.storage.savedVariables.settings
        if settings.logLevel and settings.logLevel >= level then
            action()
        end
    end
end

log.DoOnError = log.DoOnLevel(log.Level.ERROR)
log.DoOnWarn = log.DoOnLevel(log.Level.WARN)
log.DoOnInfo = log.DoOnLevel(log.Level.INFO)
log.DoOnDebug = log.DoOnLevel(log.Level.DEBUG)
log.DoOnTrace = log.DoOnLevel(log.Level.TRACE)

log.Log = function(level)
    return function(message)
        log.DoOnLevel(level)(function()
            local string
            if type(message) == "function" then
                string = message()
                if string == nil then
                    return
                end
            else
                string = message
            end
            d(string.format("[%s]|cffffff %s", os.date("%X"), string))
        end)
    end
end

log.Error = log.Log(log.Level.ERROR)

log.Warn = log.Log(log.Level.WARN)

log.Info = log.Log(log.Level.INFO)

log.Debug = log.Log(log.Level.DEBUG)

log.Trace = log.Log(log.Level.TRACE)
