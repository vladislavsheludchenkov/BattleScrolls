-- Stored group builds share the export writer, with a Lua reader and an
-- interruption-safe extension of the one-time history migration.
local newClient = dofile("tests/mocks/lgb.lua")
local function fixture() return dofile("tests/fixtures/group_share_data.lua").setup end
local function loadModule(client, path)
    return assert(loadfile("BattleScrolls/" .. path .. ".lua", "t", client))()
end
local function equal(actual, expected, path)
    path = path or "setup"
    assert_eq(type(actual), type(expected), path)
    if type(expected) ~= "table" then assert_eq(actual, expected, path); return end
    for k, v in pairs(expected) do equal(actual[k], v, path .. "." .. tostring(k)) end
    for k in pairs(actual) do assert_true(expected[k] ~= nil, path .. ": unexpected " .. tostring(k)) end
end

-- Captured from the original network/export.lua writer before extraction.
local ORIGINAL_EXPORT = "FgQHzasLo7EL2asL0a4L3pUL8qsL0gmuLACgjQbAmgyI9w8BmwUFAwEFAQwAAwMBEgcBGQcBHgMBCgMEAAgJMgAtPAECAwQFBgcICQoLDAGK3wMB92wD2gHbAdwBAuCwD8i4DwG4pQ0BCxgGy5kJzsLxBQ=="

describe("Encoded shared setups", function()
    it("preserves the existing export bytes and every normal build field", function()
        local client = newClient()
        local codec = client.BattleScrolls.binaryStorage
        local setup = fixture()
        local encoded = codec.encodeSharedSetup(setup)
        assert_eq(table.concat(encoded.c), ORIGINAL_EXPORT)
        equal(codec.decodeSharedSetup(encoded), setup)
        assert_error(function() codec.decodeSharedSetup({ v = 999, c = encoded.c }) end, "version")
    end)

    it("round-trips disabled bars, werewolf, Vengeance, zero IDs and multiple chunks", function()
        local client = newClient()
        local codec = client.BattleScrolls.binaryStorage
        local setup = fixture()
        setup.frontAbilities = nil
        setup.werewolfAbilities = { 0, 127, 128, 16384, 273766, 1048575 }
        setup.isVengeance = true
        setup.loadoutSkillLineId = 900
        setup.vengeancePerkDefIds = { 0, 20000, 30000 }
        setup.classMasteryAbilityIds = nil
        setup.frontPoisonItemId, setup.backPoisonEffect = 150731, 4294967295
        for i = 1, 20 do
            setup.scribedAbilities[i] = { abilityId = 273000 + i, scriptIds = { 1, 11, 24 } }
        end
        local encoded = codec.encodeSharedSetup(setup)
        assert_true(#encoded.c > 1)
        equal(codec.decodeSharedSetup(encoded), setup)
    end)

    it("stores only the encoded build and decodes on demand without retaining a cache", function()
        local client = newClient()
        local share = client.BattleScrolls.setupShare
        local sv = client.BattleScrolls.storage.savedVariables
        local setup = fixture()
        share:storeSetup("group1", 123, setup)
        local stored = sv.sharedSetups.group1[123]
        assert_true(stored.c ~= nil)
        assert_eq(stored.frontAbilities, nil)
        local decoded = share:getSetup("group1", 123)
        equal(decoded, setup)
        decoded.frontAbilities[1] = 42
        equal(share:getSetup("group1", 123), setup)
        assert_eq(share:getSetup("missing", 123), nil)
        assert_true(share:hasSetup("group1", 123))
        local weak = setmetatable({ decoded }, { __mode = "v" })
        decoded = nil
        collectgarbage("collect")
        assert_eq(weak[1], nil)
        loadModule(client, "storage/sizemodel")
        local model = client.BattleScrolls.sizeModel
        assert_true(model.measure(stored) < model.measure(setup) / 4, "numeric tables should shrink substantially")
        -- Pending migration entries still work through the same public API.
        sv.sharedSetups.group1[124] = setup
        equal(share:getSetup("group1", 124), setup)
    end)
end)

local function migrationClient(saved)
    local client = newClient()
    -- A private scheduler lets a test stop pumping one client to model a
    -- reload midway through migration without finishing its old fibers.
    client._G = client
    local scheduler = assert(loadfile("tests/mocks/libasync.lua", "t", client))()
    client.pump = scheduler.pump
    loadModule(client, "core/effect")
    loadModule(client, "storage/sizemodel")
    loadModule(client, "storage/ownsetups")
    loadModule(client, "storage/storage")
    local Effect = client.LibEffect
    client.BattleScrolls.storage.savedVariables = saved or { history = {}, sharedSetups = {}, settings = {} }
    client.protocols = {} -- rebind setupShare to this test's saved pool
    client.BattleScrolls.setupShare:Initialize()
    client.BattleScrolls.state = { inCombat = false }
    client.BattleScrolls.scribe = {}
    client.BattleScrolls.gc = { RequestGC = function() end, CollectFullAsync = function() return Effect.Yield() end }
    client.announcements, client.chat = {}, {}
    client.GetString = function(id) return tostring(id) end
    client.zo_strformat = function(_, fights, freed) return fights .. ":" .. freed end
    client.d = function(message) client.chat[#client.chat + 1] = message end
    client.SOUNDS = { DEFER_NOTIFICATION = "start", QUEST_COMPLETED = "done" }
    client.CENTER_SCREEN_ANNOUNCE = {
        CreateMessageParams = function()
            return { SetText = function(self, _, text) self.text = text end, SetCSAType = function() end }
        end,
        AddMessageWithParams = function(_, message)
            client.announcements[#client.announcements + 1] = message.text
        end,
    }
    client.EVENT_MANAGER = {
        RegisterForEvent = function(_, _, _, callback) client.activation = callback end,
        UnregisterForEvent = function() client.activation = nil end,
    }
    loadModule(client, "storage/migration")
    client.start = function()
        client.BattleScrolls.migration:Initialize()
        if client.activation then client.activation() end
        client.advance(60000)
    end
    return client, client.BattleScrolls.storage.savedVariables
end

describe("Migration size caches", function()
    it("paces forced measurements and publishes each commit with a fresh cache", function()
        local history = {}
        for i = 1, 2 do
            history[i] = {
                index = i, encounters = { { _v = 19, _data = { string.rep(tostring(i), 128 * 1024) } } },
                _estimatedSize = 99999999, _estimatedSizeV = 1,
            }
        end
        local client, saved = migrationClient({ history = history, sharedSetups = {}, settings = {} })
        local Effect = client.LibEffect
        local storage, codec = client.BattleScrolls.storage, client.BattleScrolls.binaryStorage
        local model = client.BattleScrolls.sizeModel
        -- Codec round trips have their own tests. Suspend both writers here
        -- so UI reads can observe every boundary of the migration commit.
        codec.decodeEncounterAsync = function() return Effect.Succeed({}) end
        codec.encodeEncounterAsync = function()
            return Effect.Yield():Map(function() return { _v = codec.CURRENT_VERSION, _data = { "new" } } end)
        end
        codec.encodeInstanceFieldsAsync = function()
            return Effect.Yield():Map(function()
                return { _instanceData = { "fields" }, _instanceDataVersion = codec.CURRENT_VERSION }
            end)
        end

        local frame, measurements, counts = 0, {}, {}
        local measure = model.measure
        model.measure = function(value, visited)
            if not visited and (value == history[1] or value == history[2]) then
                assert_true(measurements[frame] == nil, "must yield between instance measurements")
                measurements[frame] = value
                counts[value] = (counts[value] or 0) + 1
            end
            return measure(value, visited)
        end

        local expectedBefore = 0
        for _, instance in ipairs(history) do
            expectedBefore = expectedBefore + measure(instance, {}) * model.GAUGE_PER_CHUNK_BYTE
        end
        client.start()
        for i = 1, 500 do
            frame = i
            client.pump(1)
            for _, instance in ipairs(history) do
                if instance.encounters[1]._v == codec.CURRENT_VERSION then
                    assert_eq(instance._estimatedSizeV, model.VERSION)
                    assert_eq(instance._estimatedSize, measure(instance, {}), "fresh cache visible with committed data")
                    assert_eq(instance._instanceDataVersion, codec.CURRENT_VERSION)
                end
            end
            if saved.migrationDoneV20Setups then break end
        end
        assert_true(saved.migrationDoneV20Setups)
        assert_eq(#client.warnings, 0)
        for _, instance in ipairs(history) do
            assert_eq(counts[instance], 3, "fresh before, at commit and after, regardless of cached version")
        end
        local freedMiB = (expectedBefore - storage:EstimateSavedSize().historyBytes) / model.MIB
        assert_eq(client.announcements[2], "2:" .. string.format("%.1f", freedMiB), "comparison ignores stale estimates")
    end)
end)

describe("Personal setup format migration", function()
    it("pools legacy builds with independent keys and verifies the full encounter round trip", function()
        local visit = { index = 1, timestampS = 100, encounters = {}, abilityInfo = {} }
        local client, saved = migrationClient({ history = { visit }, settings = {} })
        client.BattleScrolls.structures = { makeHealingTotals = function(raw, effective, overheal)
            return { raw = raw, effective = effective, overheal = overheal }
        end }
        loadModule(client, "combat/setup")
        client.BattleScrolls.setupShare.computeHash = function() error("format migration must not use the sharing hash") end
        client.BattleScrolls.ownSetupPool.hash = function() return 0 end
        local codec, storage = client.BattleScrolls.binaryStorage, client.BattleScrolls.storage
        local setup = { abilities = { front = {}, back = {} }, classId = 7, raceId = 4,
            foods = { { abilityId = 100, uptimeMs = 5000 } } }
        for i = 1, 2 do
            local encode = codec.encodeEncounterAsync({ timestampS = 100 + i, durationMs = 10000,
                playerAliveTimeMs = 9000, setup = setup }, false, codec.newRegistry()):Run()
            client.pump(100)
            assert_true(encode:IsSucceeded(), tostring(encode._error))
            -- These sections have the same layout in v19 and v20.
            encode._value._v = 19
            visit.encounters[i] = encode._value
        end
        client.start()
        client.pump(1000)
        assert_true(saved.migrationDoneV20Setups)
        assert_eq(#client.warnings, 0)
        assert_eq(visit._migrationFailed, nil)
        assert_eq(visit.encounters[1]._v, codec.CURRENT_VERSION)
        assert_eq(visit.encounters[1]._setupHash, 0)
        assert_eq(visit.encounters[2]._setupHash, 0)
        local count = 0
        for _ in pairs(saved.ownSetups) do count = count + 1 end
        assert_eq(count, 1, "both migrated encounters reuse the same personal build")
        local decode = storage.DecodeEncounterAsync(visit.encounters[1], visit):Run()
        client.pump(100)
        assert_true(decode:IsSucceeded(), tostring(decode._error))
        assert_eq(decode._value.setup.raceId, 4)
        assert_eq(decode._value.setup.foods[1].uptimeMs, 5000)
        assert_eq(decode._value.playerAliveTimeMs, 9000)
    end)
end)

describe("Shared setup startup migration", function()
    it("checks imported server data despite the current server's completed format migration", function()
        local eu = { version = 4, history = {}, settings = {}, migrationDoneV20Setups = true }
        local na = { version = 4, history = {}, settings = {}, sharedSetups = { group1 = { [100] = fixture() } } }
        local root = { ["EU Megaserver"] = { ["@me"] = { ["$AccountWide"] = eu } },
            ["NA Megaserver"] = { ["@me"] = { ["$AccountWide"] = na } } }
        local client = migrationClient()
        loadModule(client, "storage/servermerge")
        root = client.BattleScrolls.serverMerge.prepare(root, "@me", "EU Megaserver")
        local merged = root
        assert_eq(merged.migrationDoneV20Setups, nil)
        local restarted, saved = migrationClient(merged)
        restarted.start()
        restarted.pump(500)
        assert_true(saved.migrationDoneV20Setups)
        assert_true(saved.sharedSetups.group1[100].c ~= nil)
        equal(restarted.BattleScrolls.setupShare:getSetup("group1", 100), fixture())
        assert_eq(#restarted.warnings, 0)
    end)

    it("migrates a setup-only save with existing caches", function()
        local setup = fixture()
        setup._estimatedSize, setup._estimatedSizeV = 999999, 3
        local client, saved = migrationClient({
            history = {}, sharedSetups = { group1 = { [100] = setup } }, settings = {},
        })
        client.start()
        assert_eq(saved.migrationDoneV20Setups, nil)
        client.pump(500)
        assert_true(saved.migrationDoneV20Setups)
        local stored = saved.sharedSetups.group1[100]
        assert_true(stored.c ~= nil)
        assert_eq(stored._estimatedSize, nil, "discard the stale plain-graph estimate")
        equal(client.BattleScrolls.setupShare:getSetup("group1", 100), fixture())
        assert_eq(#client.warnings, 0)
        assert_eq(#client.announcements, 2)
        local reloaded = migrationClient(saved)
        reloaded.start()
        assert_eq(reloaded.activation, nil)
        assert_eq(#reloaded.timers, 0)
    end)

    it("normalizes empty fixed arrays in legacy Vengeance builds without changing their meaning", function()
        local setup = fixture()
        setup.isVengeance, setup.loadoutSkillLineId = true, 900
        setup.vengeancePerkDefIds = { 1, 2, 3 }
        setup.champion = {}
        local client, saved = migrationClient({ history = {}, sharedSetups = { group1 = { [1] = setup } } })
        client.start(); client.pump(500)
        assert_true(saved.sharedSetups.group1[1].c ~= nil)
        assert_eq(client.BattleScrolls.setupShare:getSetup("group1", 1).champion[12], 0)
        assert_eq(#client.warnings, 0)
    end)

    it("resumes partial migration without replacing entries already encoded", function()
        local client, saved = migrationClient({ history = {}, sharedSetups = { group1 = {
            [1] = fixture(), [2] = fixture(), [3] = fixture(),
        } } })
        client.start()
        local completedHash, completed
        for _ = 1, 200 do
            client.pump(1)
            for hash, stored in pairs(saved.sharedSetups.group1) do
                if stored.c then completedHash, completed = hash, stored; break end
            end
            if completed then break end
        end
        assert_true(completed ~= nil)
        assert_eq(saved.migrationDoneV20Setups, nil)
        local restarted = migrationClient(saved)
        restarted.start(); restarted.pump(500)
        assert_true(saved.migrationDoneV20Setups)
        assert_eq(saved.sharedSetups.group1[completedHash], completed)
        for _, stored in pairs(saved.sharedSetups.group1) do assert_true(stored.c ~= nil) end
    end)

    it("waits out combat and re-reads a setup replaced while waiting for the write mutex", function()
        local client, saved = migrationClient({ history = {}, sharedSetups = { group1 = { [1] = fixture() } } })
        client.BattleScrolls.state.inCombat = true
        client.start(); client.pump(20)
        assert_eq(saved.sharedSetups.group1[1].c, nil)
        local mutex = client.BattleScrolls.storage.writeMutex
        local holder = mutex:WithPermit(client.LibEffect.FromCallback(function() end)):Run()
        client.pump(10)
        client.BattleScrolls.state.inCombat = false
        client.pump(350)
        local fresh = fixture()
        fresh.raceId = 9
        client.BattleScrolls.setupShare:storeSetup("group1", 1, fresh)
        local replacement = saved.sharedSetups.group1[1]
        holder:Cancel(); client.pump(500)
        assert_true(saved.migrationDoneV20Setups)
        assert_eq(saved.sharedSetups.group1[1], replacement)
        assert_eq(client.BattleScrolls.setupShare:getSetup("group1", 1).raceId, 9)
    end)

    it("keeps unverified builds readable and does not retry them each login", function()
        local setup = fixture()
        setup.unrecognizedField = { 123 } -- round-trip must not silently discard unknown data
        local client, saved = migrationClient({ history = {}, sharedSetups = { group1 = { [1] = setup } } })
        client.start(); client.pump(500)
        assert_eq(saved.sharedSetups.group1[1], setup)
        assert_true(setup._migrationFailed)
        assert_true(saved.migrationDoneV20Setups)
        assert_eq(#client.warnings, 1)
        assert_eq(client.BattleScrolls.setupShare:getSetup("group1", 1).unrecognizedField[1], 123)
    end)

    it("does not mark an untouched live legacy encounter complete after setup migration", function()
        local live = { encounters = { { _v = 19 } } }
        local client, saved = migrationClient({ history = { live }, sharedSetups = { group1 = { [1] = fixture() } } })
        client.BattleScrolls.scribe.instance = live
        client.start(); client.pump(500)
        assert_true(saved.sharedSetups.group1[1].c ~= nil)
        assert_eq(saved.migrationDoneV20Setups, nil)
        assert_eq(live.encounters[1]._v, 19)
    end)
end)

describe("Shared setup export integration", function()
    it("exports the same build bytes from encoded storage", function()
        local client = migrationClient()
        loadModule(client, "network/export")
        client.GetWorldName = function() return "EU Megaserver" end
        client.BattleScrolls.setupShare:storeSetup("group1", 100, fixture())
        local encounter = {
            displayName = "Test Fight", timestampS = 1700000000, durationMs = 9000,
            _shared = { client.BattleScrolls.binaryStorage.encodeSharedEntry({
                displayName = "group1", role = 1,
                data = { timestampS = 1700000000, durationMs = 9000, setupHash = 100,
                    totalDamage = 1000, maxHit = 1000, totalDamageTaken = 0 },
            }) },
        }
        client.BattleScrolls.storage.DecodeEncounterAsync = function() return client.LibEffect.Succeed(encounter) end
        local instance = { zone = "Test Zone", worldName = "NA Megaserver", timestampS = 1699999900, abilityInfo = {}, encounters = { encounter } }
        local exporter = client.BattleScrolls.export
        local fiber = exporter.buildEncounterShareAsync(instance, encounter):Run()
        client.pump(1000)
        assert_true(fiber:IsSucceeded(), tostring(fiber._error))
        assert_true(fiber._value.bytes:find("NA Megaserver", 1, true) ~= nil, "export must use the recorded server")
        assert_eq(fiber._value.bytes:find("EU Megaserver", 1, true), nil)
        local originalBytes = exporter.chunksToBytes({ ORIGINAL_EXPORT })
        assert_true(fiber._value.bytes:find(originalBytes, 1, true) ~= nil,
            "the pooled member setup must retain the original export layout")
    end)
end)
