-- Minimal ESO environment for loading addon modules outside the game.
-- Extend as tested modules need more of the API - keep it to exactly what
-- the loaded modules touch, so missing dependencies fail loudly instead of
-- silently behaving differently from the game.

-- Access control: everything is allowed in tests
function SemisPlaygroundCheckAccess()
    return true
end

-- Device platform used by export metadata; fixtures can override the PC default.
UI_PLATFORM_XBOX = 0
UI_PLATFORM_PS4 = 1
UI_PLATFORM_PC = 2
UI_PLATFORM_PS5 = 4
function GetUIPlatform()
    return UI_PLATFORM_PC
end

BattleScrolls = BattleScrolls or {}
BattleScrolls.gc = BattleScrolls.gc or {
    RequestGC = function() end,
    CollectFullAsync = function()
        return BattleScrolls.Effect.Sync(function()
            collectgarbage("collect")
            return true
        end)
    end,
}

-- Chat output no-ops
d = d or function() end
df = df or function() end

-- Lua 5.1 baseline: Havok Script has the global unpack; 5.2+ moved it
unpack = unpack or table.unpack

-- Havok Script 32-bit intrinsics. Floor-coerce operands: the game's bitops
-- accept floats with integral value where Lua 5.4's native operators error.
function BitAnd(a, b) return math.floor(a) & math.floor(b) end
function BitOr(a, b) return math.floor(a) | math.floor(b) end
function BitLShift(a, n) return (math.floor(a) << n) & 0xFFFFFFFF end
function BitRShift(a, n) return (math.floor(a) & 0xFFFFFFFF) >> n end
