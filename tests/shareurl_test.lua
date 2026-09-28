-- Exercise session IDs through the real share entry point with a stuck RNG.
local Effect = dofile("BattleScrolls/core/effect.lua")

local function newClient(overrides)
    local urls = {}
    local env = setmetatable({
        BattleScrolls = {
            Effect = Effect,
            export = {
                buildEncounterShareAsync = function()
                    return Effect.Succeed({ bytes = "fixture" })
                end,
                bytesToBase64 = function() return "Zml4dHVyZQ==" end,
            },
        },
        GetDisplayName = function() return "@PlayerOne" end,
        GetWorldName = function() return "NA Megaserver" end,
        GetUIPlatform = function() return 2 end,
        GetTimeStamp = function() return 1790600000 end,
        GetGameTimeMilliseconds = function() return 1000 end,
        GetCVar = function() return "en" end,
        -- The native hash is unavailable offline; this deterministic stand-in
        -- tests identity composition and formatting, not hash distribution.
        HashString = function(text)
            local hash = 0
            for i = 1, #text do
                hash = (hash * 31 + text:byte(i)) % 4294967296
            end
            return hash
        end,
        math = setmetatable({
            random = function() return 1 end,
            randomseed = function() error("must not reseed ESO's shared RNG") end,
        }, { __index = math }),
        EVENT_MANAGER = {
            RegisterForEvent = function() end,
            RegisterForUpdate = function() end,
            UnregisterForUpdate = function() end,
        },
        RequestOpenUnsafeURL = function(url) urls[#urls + 1] = url end,
    }, { __index = _G })
    for key, value in pairs(overrides or {}) do env[key] = value end
    assert(loadfile("BattleScrolls/network/shareurl.lua", "t", env))()
    local shareUrl = env.BattleScrolls.shareUrl
    local function share()
        shareUrl.stop()
        shareUrl.shareEncounter({}, {})
        TestEnv.pump(10)
        assert_eq(shareUrl.getState().phase, "sending")
        shareUrl.sendNextPart()
        local url = urls[#urls]
        local session = assert(url:match("#s=([^&]+)&"))
        assert_true(#session >= 4 and #session <= 32, "upload API session length")
        assert_true(session:match("^[A-Za-z0-9]+$"), "upload API session alphabet")
        assert_true(#url <= 32655, "console URL length limit")
        return session
    end
    return share
end

describe("Share URL session IDs", function()
    it("separates accounts, worlds and platforms with identical RNG state and time", function()
        local baseline = newClient()()
        for _, overrides in ipairs({
            { GetDisplayName = function() return "@PlayerTwo" end },
            { GetWorldName = function() return "EU Megaserver" end },
            { GetUIPlatform = function() return 0 end },
        }) do
            assert_true(newClient(overrides)() ~= baseline)
        end
    end)

    it("separates repeated shares in the same second even with a stuck RNG", function()
        local share = newClient()
        local sessions = {}
        for _ = 1, 100 do
            local session = share()
            assert_true(not sessions[session], "session ID reused")
            sessions[session] = true
        end
    end)

    it("separates reloads at different timestamps even with identical RNG state", function()
        local first = newClient()()
        local afterReload = newClient({ GetTimeStamp = function() return 1790600001 end })()
        assert_true(first ~= afterReload)
    end)

    it("accepts signed and unsigned native hashes without exceeding the API limit", function()
        for _, hash in ipairs({ -2147483648, -1, 0, 2147483647, 4294967295 }) do
            newClient({ HashString = function() return hash end })()
        end
    end)
end)
