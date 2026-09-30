-- Exercise URL sizing and session IDs through the real share entry points.
local Effect = dofile("BattleScrolls/core/effect.lua")

local function newClient(overrides)
    local urls = {}
    local nowMs, dialogShown, watch = 1000, false, nil
    local env = setmetatable({
        BattleScrolls = {
            Effect = Effect,
        },
        GetDisplayName = function() return "@PlayerOne" end,
        GetWorldName = function() return "NA Megaserver" end,
        GetUIPlatform = function() return 2 end,
        GetTimeStamp = function() return 1790600000 end,
        GetGameTimeMilliseconds = function() return nowMs end,
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
            RegisterForUpdate = function(_, _, _, callback) watch = callback end,
            UnregisterForUpdate = function() watch = nil end,
        },
        ZO_DIALOG_SYNC_OBJECT = {
            IsShown = function() return dialogShown end,
            GetState = function() return "CONFIRM_UNSAFE_URL" end,
        },
        RequestOpenUnsafeURL = function(url) urls[#urls + 1] = url end,
    }, { __index = _G })
    for key, value in pairs(overrides or {}) do env[key] = value end
    assert(loadfile("BattleScrolls/storage/storage.lua", "t", env))()
    env.BattleScrolls.storage.savedVariables = { settings = {} }
    assert(loadfile("BattleScrolls/network/export.lua", "t", env))()
    env.BattleScrolls.export.buildEncounterShareAsync = function()
        return Effect.Succeed({ bytes = "fixture" })
    end
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
    local function settle()
        dialogShown = true
        watch()
        dialogShown = false
        watch()
        nowMs = nowMs + 600
        watch()
    end
    return share, env, urls, settle
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

local function sendAll(env, urls, settle, maxDataChars)
    local shareUrl = env.BattleScrolls.shareUrl
    local total = shareUrl.getState().total
    local decoded = {}
    for seq = 1, total do
        shareUrl.sendNextPart()
        local url = urls[#urls]
        local data = assert(url:match("&d=(.*)$"))
        assert_true(#data <= maxDataChars)
        assert_eq(#data % 4, 0, "each part must be independently decodable")
        assert_eq(tonumber(url:match("&i=(%d+)")), seq)
        assert_eq(tonumber(url:match("&n=(%d+)")), total)
        decoded[seq] = env.BattleScrolls.export.chunksToBytes({ data })
        settle()
    end
    assert_eq(shareUrl.getState().phase, "done")
    return table.concat(decoded)
end

local function encounterBytes(env, bytes)
    env.BattleScrolls.export.buildEncounterShareAsync = function()
        return Effect.Succeed({ bytes = bytes })
    end
    env.BattleScrolls.shareUrl.shareEncounter({}, {})
    TestEnv.pump(10)
end

describe("Share URL part sizes", function()
    it("offers the setting only on PlayStation, including with recording disabled", function()
        for _, platform in ipairs({ UI_PLATFORM_PS5, UI_PLATFORM_XBOX, UI_PLATFORM_PC }) do
            local _, env = newClient({ GetUIPlatform = function() return platform end })
            local settings = env.BattleScrolls.storage.savedVariables.settings
            settings.dpsMeterPersonalEnabled = false
            settings.dpsMeterGroupEnabled = false
            settings.recordingEnabled = false
            env.BattleScrolls.journal = { renderers = {} }
            env.BattleScrolls.utils = { GetUndecoratedDisplayName = function() return "Player" end }
            env.BattleScrolls.dpsMeterUtils = { ColorFromName = function() return 1, 1, 1 end }
            env.ZO_ColorDef = { New = function() return { Colorize = function(_, text) return text end } end }
            env.zo_iconFormatInheritColor = function(icon) return icon end
            env.SOUNDS = { NONE = "none" }
            env.ZO_CreateStringId = function(id) env[id] = id end
            env.GetString = function(id) assert(id); return id end
            assert(loadfile("BattleScrolls/lang/default.lua", "t", env))()
            assert(loadfile("BattleScrolls/ui/journal/renderers/settings.lua", "t", env))()
            local entries = {}
            local list = {
                Clear = function() end,
                Commit = function() end,
                AddEntry = function(_, _, data) entries[data.text] = data end,
            }
            env.BattleScrolls.journal.renderers.settings.renderSettings(list, function() end)
            local row = entries[env.BATTLESCROLLS_SETTINGS_SHARE_PART_SIZE]
            if platform == UI_PLATFORM_PS5 then
                assert_true(row ~= nil)
                assert_eq(row.getFunction(), 7000)
                assert_eq(#row.valid, #row.valueStrings)
                for _, size in ipairs(row.valid) do
                    row.setFunction(size)
                    assert_eq(settings.playstationShareChunkChars, size)
                end
            else
                assert_eq(row, nil)
            end
        end
    end)

    it("defaults PlayStation to 7000 data chars and preserves boundary payloads", function()
        for _, size in ipairs({ 5247, 5250, 5251, 5782, 24086 }) do
            local _, env, urls, settle = newClient({ GetUIPlatform = function() return UI_PLATFORM_PS5 end })
            local bytes = string.rep("\0\255\127", math.ceil(size / 3)):sub(1, size)
            encounterBytes(env, bytes)
            assert_eq(env.BattleScrolls.shareUrl.getState().total, math.ceil(size / 5250))
            assert_eq(sendAll(env, urls, settle, 7000), bytes)
        end
    end)

    it("supports every PlayStation preset with independently decodable parts", function()
        local _, baseline = newClient()
        for _, size in ipairs(baseline.BattleScrolls.shareUrl.playstationChunkSizes) do
            local _, env, urls, settle = newClient({ GetUIPlatform = function() return UI_PLATFORM_PS5 end })
            env.BattleScrolls.storage.savedVariables.settings.playstationShareChunkChars = size
            local bytes = string.rep("\255", size / 4 * 3 + 1)
            encounterBytes(env, bytes)
            assert_eq(env.BattleScrolls.shareUrl.getState().total, 2)
            assert_eq(sendAll(env, urls, settle, size), bytes)
            assert_eq(#assert(urls[1]:match("&d=(.*)$")), size)
        end
    end)

    it("keeps Xbox and PC at 32000 even with a saved PlayStation preference", function()
        for _, platform in ipairs({ UI_PLATFORM_XBOX, UI_PLATFORM_PC }) do
            local _, env, urls, settle = newClient({ GetUIPlatform = function() return platform end })
            env.BattleScrolls.storage.savedVariables.settings.playstationShareChunkChars = 1000
            local bytes = string.rep("a", 24001)
            encounterBytes(env, bytes)
            assert_eq(env.BattleScrolls.shareUrl.getState().total, 2)
            assert_eq(sendAll(env, urls, settle, 32000), bytes)
            assert_eq(#assert(urls[1]:match("&d=(.*)$")), 32000)
        end
    end)

    it("falls back to the PlayStation default for an unsupported saved value", function()
        local _, env, urls, settle = newClient({ GetUIPlatform = function() return UI_PLATFORM_PS5 end })
        env.BattleScrolls.storage.savedVariables.settings.playstationShareChunkChars = 0
        local bytes = string.rep("a", 5251)
        encounterBytes(env, bytes)
        assert_eq(env.BattleScrolls.shareUrl.getState().total, 2)
        assert_eq(sendAll(env, urls, settle, 7000), bytes)
    end)

    for _, variant in ipairs({ "full", "bosses" }) do
        it("keeps archive estimates and the " .. variant .. " selection at the captured size", function()
            local _, env, urls, settle = newClient({ GetUIPlatform = function() return UI_PLATFORM_PS5 end })
            local full, bosses = string.rep("f", 15000), string.rep("b", 9000)
            local shareUrl = env.BattleScrolls.shareUrl
            env.BattleScrolls.export.buildInstanceArchiveAsync = function(_, bossesOnly)
                return Effect.Succeed({ bytes = bossesOnly and bosses or full, encounterCount = bossesOnly and 1 or 2 })
            end
            shareUrl.uploadInstance({ encounters = { { bossesUnits = { 1 } }, { bossesUnits = {} } } })
            -- Changes during preparation affect the next share, not this one.
            env.BattleScrolls.storage.savedVariables.settings.playstationShareChunkChars = 32000
            TestEnv.pump(10)
            local state = shareUrl.getState()
            assert_eq(state.phase, "choosing")
            assert_eq(state.choiceFull.parts, 3)
            assert_eq(state.choiceBosses.parts, 2)
            shareUrl.chooseVariant(variant)
            assert_eq(shareUrl.getState().total, variant == "full" and 3 or 2)
            assert_eq(sendAll(env, urls, settle, 7000), variant == "full" and full or bosses)
            shareUrl.stop()
            encounterBytes(env, full)
            assert_eq(shareUrl.getState().total, 1, "new shares use the changed setting")
        end)
    end

    it("applies the PlayStation size to archives without a variant choice", function()
        local _, env, urls, settle = newClient({ GetUIPlatform = function() return UI_PLATFORM_PS5 end })
        local bytes = string.rep("a", 5782)
        env.BattleScrolls.export.buildInstanceArchiveAsync = function()
            return Effect.Succeed({ bytes = bytes, encounterCount = 6 })
        end
        env.BattleScrolls.shareUrl.uploadInstance({ encounters = { { bossesUnits = {} } } })
        TestEnv.pump(10)
        assert_eq(env.BattleScrolls.shareUrl.getState().total, 2)
        assert_eq(sendAll(env, urls, settle, 7000), bytes)
    end)
end)
