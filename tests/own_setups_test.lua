local function newModule(signed)
    local env = setmetatable({ BattleScrolls = {}, table = setmetatable({
        concat = function() error("personal pool must not concatenate chunks") end,
    }, { __index = table }) }, { __index = _G })
    -- Exercise double arithmetic, including platforms returning signed bitops.
    env.BitXor = function(a, b)
        local result = math.floor(a) ~ math.floor(b)
        if signed and result >= 2147483648 then result = result - 4294967296 end
        return result + 0.0
    end
    assert(loadfile("BattleScrolls/storage/ownsetups.lua", "t", env))()
    return env.BattleScrolls.ownSetupPool
end

describe("Personal build pool", function()
    it("matches independently truncated FNV-1a vectors using exact Lua double arithmetic", function()
        -- Expected values calculated independently with integer FNV-1a.
        for _, signed in ipairs({ false, true }) do
            local module = newModule(signed)
            assert_eq(module.hash({ v = 20, c = {} }), 59873)
            assert_eq(module.hash({ v = 20, c = { "hello" } }), 18991)
            assert_eq(module.hash({ v = 19, c = { "hello" } }), 56966)
            assert_eq(module.hash({ v = 20, c = { "foobar" } }), 61580)
            local allBytes = {}
            for i = 0, 255 do allBytes[#allBytes + 1] = string.char(i) end
            assert_eq(module.hash({ v = 4294967295, c = allBytes }), 20145)
        end
    end)

    it("ignores chunk boundaries and reuses the original encoded object without joining strings", function()
        local module = newModule()
        local pool = {}
        local original = { v = 20, c = { "hello" } }
        local key, added = module.intern(pool, original)
        assert_true(added)
        for _, chunks in ipairs({ { "he", "llo" }, { "", "h", "", "el", "l", "o", "" } }) do
            local entry = { v = 20, c = chunks }
            assert_eq(module.hash(entry), key)
            local reused, inserted = module.intern(pool, entry)
            assert_eq(reused, key)
            assert_eq(inserted, false)
            assert_eq(pool[key], original)
        end
    end)

    it("preserves different builds that naturally collide in the 16-bit hash", function()
        local module = newModule()
        local a, b = { v = 20, c = { "build49" } }, { v = 20, c = { "build1002" } }
        assert_eq(module.hash(a), 30264)
        assert_eq(module.hash(b), 30264)
        local pool = {}
        local first = module.intern(pool, a)
        local second = module.intern(pool, b)
        assert_eq(first, 30264)
        assert_eq(second, 30265)
        assert_eq(pool[first], a)
        assert_eq(pool[second], b)
        local reused, added = module.intern(pool, { v = 20, c = { "build", "1002" } })
        assert_eq(reused, second)
        assert_eq(added, false)
    end)

    it("resolves forced collisions, version differences and prefixes without replacing data", function()
        local module = newModule()
        module.hash = function() return 65535 end
        local pool = {}
        local a, b = { v = 20, c = { "abc" } }, { v = 20, c = { "ab" } }
        local c, d = { v = 19, c = { "abc" } }, { v = 20, c = { "abcd" } }
        assert_eq(module.intern(pool, a), 65535)
        assert_eq(module.intern(pool, b), 0)
        assert_eq(module.intern(pool, c), 1)
        assert_eq(module.intern(pool, d), 2)
        local key, added = module.intern(pool, { v = 20, c = { "a", "b" } })
        assert_eq(key, 0)
        assert_eq(added, false)
        assert_eq(pool[65535], a)
        assert_eq(pool[0], b)
        assert_eq(pool[1], c)
        assert_eq(pool[2], d)
        pool[65535] = nil -- normal pruning may leave a hole in a probe chain
        local e = { v = 20, c = { "different build" } }
        assert_eq(module.intern(pool, e), 65535)
        assert_eq(pool[0], b, "existing encounter keys remain valid after deletion and reuse")
    end)

    it("hashes full personal snapshots while excluding per-fight food uptime", function()
        local env = setmetatable({ BattleScrolls = {} }, { __index = _G })
        local function load(path) assert(loadfile("BattleScrolls/" .. path .. ".lua", "t", env))() end
        load("core/effect")
        load("storage/bitcodec")
        load("storage/binary")
        load("storage/ownsetups")
        load("storage/storage")
        local storage = env.BattleScrolls.storage
        storage.savedVariables = {}
        env.BattleScrolls.setupShare = setmetatable({}, {
            __index = function() error("personal identity must not use the sharing hash") end,
        })
        local setup = { abilities = { front = {}, back = {} }, classId = 7, raceId = 4,
            equipSlots = { "first item link" }, foods = { { abilityId = 100, uptimeMs = 1000 } } }
        local first, added = storage:InternOwnSetup(setup)
        assert_true(added)
        setup.foods[1].uptimeMs = 9000
        local repeated, repeatedAdded = storage:InternOwnSetup(setup)
        assert_eq(repeated, first)
        assert_eq(repeatedAdded, false)
        assert_eq(storage:GetOwnSetup(first).foods[1].uptimeMs, nil)
        setup.equipSlots[1] = "second item link"
        local second, secondAdded = storage:InternOwnSetup(setup)
        assert_true(secondAdded)
        assert_true(second ~= first)
        assert_eq(storage:GetOwnSetup(first).equipSlots[1], "first item link")
        assert_eq(storage:GetOwnSetup(second).equipSlots[1], "second item link")
    end)

    it("reports a full 16-bit pool instead of probing forever", function()
        local module = newModule()
        local pool, occupied = {}, { v = 19, c = {} }
        for key = 0, 65535 do pool[key] = occupied end
        assert_error(function() module.intern(pool, { v = 20, c = {} }) end, "Personal build pool is full")
        for key = 0, 65535 do assert_eq(pool[key], occupied) end
    end)
end)
