-- Production raw storage and merge, with isolated globals per login.
local function newClient(root, world, account)
    local env = setmetatable({ BattleScrolls = {}, BattleScrollsSavedVariables = root }, { __index = _G })
    env._G = env
    env.GetWorldName = function() return world or "EU Megaserver" end
    env.GetDisplayName = function() return account or "@me" end
    env.ZO_SavedVars = setmetatable({}, { __index = function() error("storage must not use ZO_SavedVars") end })
    local function load(path) return assert(loadfile(path, "t", env))() end
    local scheduler = load("tests/mocks/libasync.lua")
    env.pump = scheduler.pump
    load("BattleScrolls/core/effect.lua")
    load("BattleScrolls/storage/sizemodel.lua")
    load("BattleScrolls/storage/ownsetups.lua")
    load("BattleScrolls/storage/storage.lua")
    load("BattleScrolls/storage/servermerge.lua")
    env.BattleScrolls.gc = { RequestGC = function() error("merge must not request GC") end }
    env.BattleScrolls.binaryStorage = setmetatable({}, {
        __index = function() error("merge must not access a codec") end,
    })
    env.tasksCreated = scheduler.createdCount
    return env, env.BattleScrolls.storage
end

local function save(history, settings)
    return { version = 4, history = history or {}, settings = settings or {}, ownSetups = {}, sharedSetups = {},
        migrationDoneV20Setups = true }
end
local function instance(index, timestamp, hash)
    return { index = index, zone = "House", timestampS = timestamp, isHouse = true, isOverland = true,
        left = false, _estimatedSize = 54321, _estimatedSizeV = 3,
        _instanceData = { "instance payload" }, _instanceDataVersion = 20,
        encounters = { { _v = 20, timestampS = timestamp, durationMs = 10000, _setupHash = hash,
            _data = { "encounter payload" }, customName = "My parse" } } }
end
local function rootFor(na, eu)
    return { ["NA Megaserver"] = { ["@me"] = { ["$AccountWide"] = na } },
        ["EU Megaserver"] = { ["@me"] = { ["$AccountWide"] = eu } } }
end
local function query(index, timestamp)
    return { domain = "damage", rowDimension = "encounter", columnMode = "metrics", metrics = { "totalDamage" }, filters = {},
        scope = { instanceMode = "specific", instanceIds = { [index] = true }, timeMode = "all",
            encounterCategory = "specific", encounterIds = { [timestamp] = true } } }
end

-- Retain identities as well as values: preparation must not mutate any
-- reachable source table, including records, selection sets and other users.
local function snapshotGraph(value, snapshot)
    snapshot = snapshot or {}
    if type(value) == "table" and not snapshot[value] then
        local fields = {}
        snapshot[value] = fields
        for k, v in pairs(value) do
            fields[k] = v
            snapshotGraph(k, snapshot)
            snapshotGraph(v, snapshot)
        end
    end
    return snapshot
end

local function assertGraphUnchanged(snapshot)
    for original, fields in pairs(snapshot) do
        for k, v in pairs(fields) do assert_eq(original[k], v, "changed original field " .. tostring(k)) end
        for k, v in pairs(original) do assert_eq(v, fields[k], "added original field " .. tostring(k)) end
    end
end

-- Model saving and reloading plain SavedVariables: no metatables or shared
-- identities between the new session and the interrupted one.
local function reloadCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do copy[reloadCopy(k)] = reloadCopy(v) end
    return copy
end

describe("Server history merge", function()
    it("copies changed metadata and reuses payloads without decoding, eviction or async work", function()
        local a, b = instance(7, 100, 1), instance(7, 200, 1)
        a.locked, a.customName, a._migrationFailed = true, "Keep this run", true
        local na = save({ a }, { storageSizePreset = "large", recordingEnabled = false, favoriteEffects = { [10] = true } })
        local eu = save({ b }, { storageSizePreset = "xs", recordingEnabled = true, favoriteEffects = { [20] = true } })
        na.ownSetups[1], eu.ownSetups[1] = { v = 20, c = { "AAAA" } }, { v = 20, c = { "AAAA" } }
        na.sharedSetups.friend = { [2] = { classId = 1 }, [3] = { classId = 2 } }
        eu.sharedSetups.friend = { [2] = { v = 1, c = { "BBBB" } } }
        local payload, fields = a.encounters[1]._data, a._instanceData
        local root = rootFor(na, eu)
        local snapshot = snapshotGraph(root)
        local env, storage = newClient(root)
        env.BattleScrolls.sizeModel.measure = function() error("merge must not measure the graph") end
        local tasks = env.tasksCreated()
        storage:Initialize()
        assert_eq(env.tasksCreated(), tasks)
        assertGraphUnchanged(snapshot)
        assert_true(env.BattleScrollsSavedVariables ~= root)
        local merged = storage.savedVariables
        assert_eq(#merged.history, 2)
        assert_true(merged.history[1] ~= a)
        assert_true(merged.history[2] ~= b)
        assert_true(merged.history[1].encounters ~= a.encounters)
        assert_true(merged.history[1].encounters[1] ~= a.encounters[1])
        a, b = merged.history[1], merged.history[2]
        assert_eq(a.encounters[1]._data, payload)
        assert_eq(a._instanceData, fields)
        assert_eq(a._estimatedSize, 54321, "keep caches instead of forcing a full remeasure")
        assert_eq(a.locked, true)
        assert_eq(a.customName, "Keep this run")
        assert_eq(a.encounters[1].customName, "My parse")
        assert_eq(a._migrationFailed, true)
        assert_eq(a.worldName, "NA Megaserver")
        assert_eq(b.worldName, "EU Megaserver")
        assert_eq(a.index, 1)
        assert_eq(b.index, 2)
        assert_eq(merged.nextInstanceIndex, 3)
        assert_eq(merged.settings.storageSizePreset, "large")
        assert_eq(merged.settings.recordingEnabled, true)
        assert_true(merged.settings.favoriteEffects[10] and merged.settings.favoriteEffects[20])
        local ownKey = a.encounters[1]._setupHash
        assert_eq(merged.ownSetups[ownKey], eu.ownSetups[1])
        assert_eq(b.encounters[1]._setupHash, ownKey)
        assert_eq(merged.sharedSetups.friend[2], eu.sharedSetups.friend[2], "trust current server's shared build")
        assert_eq(merged.sharedSetups.friend[3], na.sharedSetups.friend[3])
        assert_eq(merged.migrationDoneV20Setups, nil)
        for key in pairs(merged.ownSetups) do
            assert_true(key >= 0 and key <= 65535 and key % 1 == 0, "personal keys must be unsigned 16-bit")
        end
        local published = env.BattleScrollsSavedVariables
        assert_eq(published["NA Megaserver"], nil)
        assert_eq(published["EU Megaserver"], nil)
        assert_eq(published.Default, nil)
        assert_eq(published, merged)
        assert_eq(getmetatable(published), nil)
    end)

    it("preserves both personal builds on collisions and clears only dangling references", function()
        local a, b, dangling = instance(1, 100, 1), instance(1, 200, 1), instance(2, 300, 2)
        local versionConflict = instance(3, 400, 3)
        local na, eu = save({ a, dangling, versionConflict }), save({ b })
        na.ownSetups[1] = { v = 20, c = { "AAAA" } }
        eu.ownSetups[1] = { v = 20, c = { "BBBB" } }
        eu.ownSetups[2] = { v = 20, c = { "CCCC" } }
        na.ownSetups[3], eu.ownSetups[3] = { v = 19, c = { "DDDD" } }, { v = 20, c = { "DDDD" } }
        local root = rootFor(na, eu)
        local env, storage = newClient(root)
        -- Force the personal hashes to collide, including at wraparound.
        env.BattleScrolls.ownSetupPool.hash = function() return 65535 end
        storage:Initialize()
        local history = storage.savedVariables.history
        a, b, dangling, versionConflict = history[1], history[2], history[3], history[4]
        local merged = storage.savedVariables.ownSetups
        assert_eq(merged[b.encounters[1]._setupHash], eu.ownSetups[1])
        assert_eq(merged[a.encounters[1]._setupHash], na.ownSetups[1])
        assert_true(a.encounters[1]._setupHash ~= b.encounters[1]._setupHash)
        assert_eq(dangling.encounters[1]._setupHash, nil, "other server must not repair a dangling reference")
        assert_eq(merged[versionConflict.encounters[1]._setupHash], na.ownSetups[3])
        local count = 0
        for _ in pairs(merged) do count = count + 1 end
        assert_eq(count, 5, "version and content conflicts retain every distinct build")
        assert_true(merged[0] ~= nil, "pool key zero is valid")
    end)

    it("decodes the original personal build and combat data after remapping a collision", function()
        local a, b = instance(1, 100, 1), instance(1, 200, 1)
        local na, eu = save({ a }), save({ b })
        local env, storage = newClient(rootFor(na, eu))
        assert(loadfile("BattleScrolls/storage/bitcodec.lua", "t", env))()
        assert(loadfile("BattleScrolls/storage/binary.lua", "t", env))()
        env.BattleScrolls.structures = { makeHealingTotals = function(raw, effective, overheal)
            return { raw = raw, effective = effective, overheal = overheal }
        end }
        local codec = env.BattleScrolls.binaryStorage
        local registry = codec.newRegistry()
        local rejectGC = env.BattleScrolls.gc.RequestGC
        env.BattleScrolls.gc.RequestGC = function() end
        local setup = { abilities = { front = {}, back = {} }, raceId = 1, classId = 2,
            foods = { { abilityId = 100, uptimeMs = 5000 }, { abilityId = 200 } } }
        local function encodedSetup()
            local chunks, version = codec.encodeSetupStandalone(codec.buildPoolableSetup(setup))
            return { v = version, c = chunks }
        end
        eu.ownSetups[1] = encodedSetup()
        setup.raceId = 3
        na.ownSetups[1] = encodedSetup()
        local original = { timestampS = 100, durationMs = 10000, playerAliveTimeMs = 9000,
            setup = setup,
            resurrections = 2, resurrectionLog = { { displayName = "@friend", timeMs = 2500 } } }
        local encode = codec.encodeEncounterAsync(original, true, registry):Run()
        env.pump(100)
        assert_true(encode:IsSucceeded(), tostring(encode._error))
        local compact = encode._value
        compact._setupHash = 1
        a.encounters[1] = compact
        local payload = compact._data
        env.BattleScrolls.gc.RequestGC = rejectGC
        storage:Initialize()
        assert_eq(compact._setupHash, 1, "source reference remains unchanged")
        compact = storage.savedVariables.history[1].encounters[1]
        b = storage.savedVariables.history[2]
        assert_eq(storage.savedVariables.ownSetups[compact._setupHash], na.ownSetups[1])
        assert_eq(compact._data, payload)
        env.BattleScrolls.gc.RequestGC = function() end
        local decode = codec.decodeEncounterAsync(compact, registry):Run()
        env.pump(100)
        assert_true(decode:IsSucceeded(), tostring(decode._error))
        assert_eq(decode._value.setup.raceId, 3, "resolves the original server's build")
        assert_eq(storage:GetOwnSetup(b.encounters[1]._setupHash).raceId, 1)
        assert_eq(decode._value.setup.foods[1].uptimeMs, 5000)
        assert_eq(decode._value.setup.foods[2].uptimeMs, nil)
        assert_eq(decode._value.playerAliveTimeMs, 9000)
        assert_eq(decode._value.resurrections, 2, "sections after the food overlay stay aligned")
        assert_eq(decode._value.resurrectionLog[1].displayName, "@friend")
        assert_eq(decode._value.resurrectionLog[1].timeMs, 2500)
    end)

    it("preserves named queries and encounter selections while remapping instance selections", function()
        local a, b = instance(1, 100), instance(1, 200)
        local na = save({ a }, { pivotQueries = { ["My query"] = query(1, 100) } })
        local eu = save({ b }, { pivotQueries = { ["My query"] = query(1, 200),
            ["My query (NA Megaserver)"] = query(1, 200) } })
        local root = rootFor(na, eu)
        local env, storage = newClient(root)
        storage:Initialize()
        a, b = storage.savedVariables.history[1], storage.savedVariables.history[2]
        local queries = storage.savedVariables.settings.pivotQueries
        assert_true(queries["My query"].scope.instanceIds[b.index])
        assert_true(queries["My query"].scope.encounterIds[200])
        local imported = queries["My query (NA Megaserver) (2)"]
        assert_true(imported.scope.instanceIds[a.index])
        assert_true(imported.scope.encounterIds[100])
        assert_eq(imported.scope.encounterIds[200], nil)
        assert_eq(imported.scope.encounterIds, na.settings.pivotQueries["My query"].scope.encounterIds)
        assert_eq(na.settings.pivotQueries["My query"].scope.encounterIds[100], true, "staging did not edit the source query")
        assert(loadfile("BattleScrolls/ui/journal/pivot/types.lua", "t", env))()
        assert(loadfile("BattleScrolls/ui/journal/pivot/engine.lua", "t", env))()
        local currentResolved = env.BattleScrolls.journal.pivot.engine.resolveScope(queries["My query"].scope)
        assert_eq(#currentResolved, 1)
        assert_eq(currentResolved[1].instance, b)
        imported.scope.instanceMode = "everything"
        local resolved = env.BattleScrolls.journal.pivot.engine.resolveScope(imported.scope)
        assert_eq(#resolved, 1)
        assert_eq(resolved[1].instance, a)
    end)

    it("leaves sources untouched when staging fails and can retry without duplicates", function()
        local a, b = instance(1, 100, 1), instance(1, 200, 1)
        local na, eu = save({ a }), save({ b })
        na.ownSetups[1], eu.ownSetups[1] = { v = 20 }, { v = 20, c = { "AAAA" } }
        local root = rootFor(na, eu)
        local env, storage = newClient(root)
        assert_error(function() storage:Initialize() end)
        assert_eq(env.BattleScrollsSavedVariables, root)
        assert_eq(root.Default, nil)
        assert_eq(root["NA Megaserver"]["@me"]["$AccountWide"], na)
        assert_eq(a.index, 1)
        assert_eq(a.worldName, nil)
        assert_eq(a.encounters[1]._setupHash, 1)
        na.ownSetups[1].c = { "AAAA" }
        storage:Initialize()
        assert_eq(#storage.savedVariables.history, 2)
    end)

    it("reuses encounter records when their personal reference does not change", function()
        local visit = instance(7, 100, 1)
        local inline = { _v = 16, _data = { "old inline payload" }, timestampS = 200 }
        visit.encounters[2] = inline
        local data = save({ visit })
        data.ownSetups[1] = { v = 20, c = { "AAAA" } }
        local env, storage = newClient(rootFor(data, save()))
        env.BattleScrolls.ownSetupPool.hash = function() return 1 end
        storage:Initialize()
        local merged = storage.savedVariables.history[1]
        assert_true(merged ~= visit)
        assert_eq(merged.encounters[1], visit.encounters[1])
        assert_eq(merged.encounters[2], inline)
        assert_eq(visit.index, 7)
        assert_eq(visit.worldName, nil)
    end)

    it("can reload and retry after interruption at every Lua instruction of initialization", function()
        local function fixture()
            local na = save({ instance(17, 100, 9) }, { storageSizePreset = "medium",
                pivotQueries = { Saved = query(17, 100) } })
            local eu = save({ instance(17, 200, 9) }, { storageSizePreset = "xs",
                pivotQueries = { Saved = query(17, 200) }, recordInZones = { house = false } })
            local previous = save({ instance(17, 150, 9) }, { storageSizePreset = "large",
                pivotQueries = { Saved = query(17, 150) } })
            previous.history[1].worldName = "NA Megaserver"
            na.ownSetups[9] = { v = 20, c = { "NA" } }
            eu.ownSetups[9] = { v = 20, c = { "EU" } }
            previous.ownSetups[9] = { v = 20, c = { "Default" } }
            local root = rootFor(na, eu)
            root["NA Megaserver"]["@other"] = { ["$AccountWide"] = { marker = "other NA" } }
            root["EU Megaserver"]["@me"].character = { marker = "EU character" }
            root.Default = { ["@me"] = { ["$AccountWide"] = previous, character = { marker = "Default character" } },
                ["@other"] = { ["$AccountWide"] = { marker = "other Default" } } }
            return root
        end

        local function assertMerged(root)
            local saved = root
            assert_eq(saved.migrationDoneV20Setups, nil)
            assert_eq(saved.nextInstanceIndex, 4)
            assert_eq(#saved.history, 3)
            assert_eq(saved.settings.storageSizePreset, "large")
            assert_eq(saved.settings.recordInZones.house, false)
            assert_eq(saved.settings.recordInZones.instanced, true, "nested defaults are complete at publication")
            local queries = saved.settings.pivotQueries
            for i, expected in ipairs({ { 100, "NA", "NA Megaserver", "Saved (NA Megaserver)" },
                { 150, "Default", "NA Megaserver", "Saved (Default)" },
                { 200, "EU", "EU Megaserver", "Saved" } }) do
                local visit = saved.history[i]
                assert_eq(visit.index, i)
                assert_eq(visit.timestampS, expected[1])
                assert_eq(visit.worldName, expected[3])
                assert_eq(saved.ownSetups[visit.encounters[1]._setupHash].c[1], expected[2])
                local scope = queries[expected[4]].scope
                assert_true(scope.instanceIds[i])
                assert_eq(scope.instanceIds[17], nil)
                assert_true(scope.encounterIds[expected[1]])
            end
            assert_eq(root["NA Megaserver"], nil)
            assert_eq(root["EU Megaserver"], nil)
            assert_eq(root.Default, nil)
        end

        local env, storage = newClient(fixture())
        -- Exercise old-key collisions and wraparound while sweeping aborts.
        env.BattleScrolls.ownSetupPool.hash = function() return 65535 end
        local function initializeUntil(stopAt)
            local instructions = 0
            local thread = coroutine.create(function() storage:Initialize() end)
            debug.sethook(thread, function()
                instructions = instructions + 1
                if instructions == stopAt then error("simulated engine stop", 0) end
            end, "", 1)
            local ok, err = coroutine.resume(thread)
            debug.sethook(thread)
            if not ok then assert_eq(err, "simulated engine stop") end
            return instructions, ok
        end

        local instructionCount, completed = initializeUntil(math.huge)
        assert_true(completed)
        local beforePublish, afterPublish = 0, 0
        for stopAt = 1, instructionCount do
            local original = fixture()
            local snapshot = snapshotGraph(original)
            env.BattleScrollsSavedVariables = original
            storage.savedVariables = nil
            local _, ok = initializeUntil(stopAt)
            local published = env.BattleScrollsSavedVariables
            assertGraphUnchanged(snapshot)
            if published == original then
                assert_true(not ok)
                beforePublish = beforePublish + 1
            else
                assertMerged(published)
                afterPublish = afterPublish + 1
            end

            -- Save/reload whichever root survived the stop, then initialize
            -- normally. Both sides of publication must produce the same data.
            env.BattleScrollsSavedVariables = reloadCopy(published)
            storage.savedVariables = nil
            storage:Initialize()
            assertMerged(env.BattleScrollsSavedVariables)
            assert_eq(storage.savedVariables, env.BattleScrollsSavedVariables)
        end
        assert_true(beforePublish > 0)
        assert_true(afterPublish > 0)
        print(string.format("  interrupted initialization at %d instruction boundaries (%d before, %d after publication)",
            instructionCount, beforePublish, afterPublish))
    end)

    it("imports every supported legacy branch into one history and skips subsequent logins", function()
        local na = save({ instance(1, 100, 1) }, { recordingEnabled = false, pivotQueries = { Saved = query(1, 100) } })
        local eu = save({ instance(1, 200, 1) }, { recordingEnabled = true })
        na.ownSetups[1], eu.ownSetups[1] = { v = 20, c = { "NA" } }, { v = 20, c = { "EU" } }
        local root = rootFor(na, eu)
        local other = save({ instance(1, 50, 1) }, { storageSizePreset = "yolo", recordingEnabled = false,
            pivotQueries = { Saved = query(1, 50) } })
        other.ownSetups[1] = { v = 20, c = { "other" } }
        root["NA Megaserver"]["@other"] = { ["$AccountWide"] = other }
        root["EU Megaserver"]["@me"].character = save({ instance(1, 150) })
        local snapshot = snapshotGraph(root)
        local env, storage = newClient(root)
        storage:Initialize()
        local published = env.BattleScrollsSavedVariables
        assertGraphUnchanged(snapshot)
        assert_eq(#published.history, 4)
        for i, timestamp in ipairs({ 50, 100, 150, 200 }) do
            assert_eq(published.history[i].timestampS, timestamp)
        end
        assert_eq(published.settings.storageSizePreset, "yolo")
        assert_eq(published.settings.recordingEnabled, true, "current login settings win")
        assert_true(published.settings.pivotQueries.Saved.scope.instanceIds[2])
        assert_true(published.settings.pivotQueries["Saved (NA Megaserver)"].scope.instanceIds[1])
        for _, pair in ipairs({ { 1, "other" }, { 2, "NA" }, { 4, "EU" } }) do
            local key = published.history[pair[1]].encounters[1]._setupHash
            assert_eq(published.ownSetups[key].c[1], pair[2])
        end
        assert_eq(published["NA Megaserver"], nil)
        assert_eq(published["EU Megaserver"], nil)
        published.settings.storageSizePreset = "small"
        published.migrationDoneV20Setups = true
        local restartedEnv, restarted = newClient(published, "NA Megaserver", "@other")
        restartedEnv.BattleScrolls.ownSetupPool.hash = function() error("flat saves must not be rehashed") end
        restarted:Initialize()
        assert_eq(restartedEnv.BattleScrollsSavedVariables, published, "completed merge does not copy the root again")
        assert_eq(restarted.savedVariables, published)
        assert_eq(restarted.savedVariables.settings.storageSizePreset, "small")
        assert_eq(restarted.savedVariables.migrationDoneV20Setups, true)
    end)

    it("creates fresh raw storage and imports single-server saves on a first visit elsewhere", function()
        for _, root in ipairs({ {}, false }) do
            local env, storage = newClient(root or nil)
            storage:Initialize()
            assert_eq(storage.savedVariables.version, 4)
            assert_eq(storage.savedVariables, env.BattleScrollsSavedVariables)
            assert_eq(#storage.savedVariables.history, 0)
            assert_eq(storage.savedVariables.settings.storageSizePreset, "medium")
        end
        local na = save({ instance(1, 100) }, { storageSizePreset = "xs", recordingEnabled = true })
        local root = { ["NA Megaserver"] = { ["@me"] = { ["$AccountWide"] = na } } }
        local _, firstVisit = newClient(root)
        firstVisit:Initialize()
        assert_eq(firstVisit.savedVariables.settings.storageSizePreset, "xs", "absent server must not raise the limit to defaults")
        assert_eq(firstVisit.savedVariables.settings.recordingEnabled, true)
        assert_eq(firstVisit.savedVariables.history[1].worldName, "NA Megaserver")
    end)

    it("fills raw storage defaults without overwriting values, sharing defaults or resetting history", function()
        local visit = instance(77, 100, 123)
        local original = save({ visit }, { recordingEnabled = false, dpsMeterPersonalOffsetX = 0,
            recordInZones = { house = false }, dpsMeterPersonalDesignSettings = { minimal = { opacity = 0 } } })
        original.version = 1 -- versions no longer trigger a destructive wrapper reset
        local snapshot = snapshotGraph(original)
        local env, storage = newClient(original)
        local defaultsSnapshot = snapshotGraph(storage.defaults)
        storage:Initialize()
        assertGraphUnchanged(snapshot)
        assertGraphUnchanged(defaultsSnapshot)
        local raw = storage.savedVariables
        assert_eq(raw, env.BattleScrollsSavedVariables)
        assert_true(raw ~= original)
        assert_eq(getmetatable(raw), nil)
        assert_eq(raw.version, 1)
        assert_eq(raw.history, original.history)
        assert_eq(raw.history[1].index, 77)
        assert_eq(raw.history[1].encounters[1]._setupHash, 123)
        assert_true(raw.migrationDoneV20Setups)
        assert_eq(raw.settings.recordingEnabled, false)
        assert_eq(raw.settings.dpsMeterPersonalOffsetX, 0)
        assert_eq(raw.settings.recordInZones.house, false)
        assert_eq(raw.settings.recordInZones.instanced, true)
        assert_eq(raw.settings.dpsMeterPersonalDesignSettings.minimal.opacity, 0)
        raw.settings.favoriteEffects[42] = true
        raw.settings.recordInZones.instanced = false
        assertGraphUnchanged(defaultsSnapshot)
        storage:Initialize()
        assert_eq(storage.savedVariables, raw, "complete defaults do not allocate a replacement on every login")
    end)

    it("applies the maximum allowance to the combined history on normal cleanup, preserving locks and newest", function()
        local a, b, c = instance(1, 100), instance(1, 200), instance(2, 300)
        a.locked = true
        a._estimatedSize, b._estimatedSize, c._estimatedSize = 4 * 1048576, 4 * 1048576, 4 * 1048576
        local na = save({ a }, { storageSizePreset = "xs" })
        local eu = save({ b, c }, { storageSizePreset = "small" })
        local env, storage = newClient(rootFor(na, eu))
        storage:Initialize()
        assert_eq(#storage.savedVariables.history, 3, "merge itself must not evict")
        a, c = storage.savedVariables.history[1], storage.savedVariables.history[3]
        env.BattleScrolls.gc.RequestGC = function() end
        storage:CleanupIfNecessaryAsync()
        env.pump(100)
        assert_eq(#storage.savedVariables.history, 2)
        assert_eq(storage.savedVariables.history[1], a)
        assert_eq(storage.savedVariables.history[2], c)
    end)

    it("keeps large-save merge overhead independent of encoded payload size", function()
        local na, eu = save({}, { storageSizePreset = "yolo" }), save({}, { storageSizePreset = "yolo" })
        for i = 1, 20 do
            na.ownSetups[i] = { v = 20, c = { string.rep("A", 1000), tostring(i) } }
            eu.ownSetups[i] = { v = 20, c = { string.rep("B", 1000), tostring(i) } }
        end
        for i = 1, 500 do
            local visit = instance(i, i)
            for j = 1, 20 do
                local chunks = {}
                for k = 1, 16 do chunks[k] = string.format("%d:%d:%d:", i, j, k) .. string.rep("A", 220) end
                visit.encounters[j] = { _v = 20, timestampS = i * 100 + j, durationMs = 10000,
                    _data = chunks, _setupHash = j }
            end
            local target = i % 2 == 0 and na or eu
            target.history[#target.history + 1] = visit
        end
        local _, storage = newClient(rootFor(na, eu))
        collectgarbage("collect")
        collectgarbage("stop")
        local before, started = collectgarbage("count"), os.clock()
        local ok, err = pcall(function() storage:Initialize() end)
        local elapsed, allocated = (os.clock() - started) * 1000, collectgarbage("count") - before
        collectgarbage("restart")
        assert_true(ok, tostring(err))
        assert_eq(#storage.savedVariables.history, 500)
        assert_true(allocated < 5 * 1024, "metadata copies unexpectedly allocated over 5 MiB")
        print(string.format("  10,000 encounters, 40 personal builds: %.2f ms CPU, %.1f KiB extra Lua heap (desktop Lua; GC stopped)", elapsed, allocated))
    end)

    it("resumes recording only on the recorded server, even when zone names match", function()
        for _, recordedWorld in ipairs({ "NA Megaserver", "EU Megaserver" }) do
            local visit = instance(1, 100)
            visit.worldName = recordedWorld
            local saved = save({ visit })
            local env, storage = newClient(saved)
            storage:Initialize()
            env.BattleScrolls.constants = { BOSS_TAGS = {} }
            env.BattleScrolls.utils = { FormattedZoneName = function() return "House" end, MaybeLocationName = function() end }
            env.BattleScrolls.encounterShare = { RegisterCallback = function() end }
            env.BattleScrolls.state = { ShouldReset = function() return false end }
            env.BattleScrolls.migration = { hasLegacyEncounters = function() return false end }
            env.BattleScrolls.binaryStorage = { newRegistry = function() return { abilityIds = {}, names = {} } end }
            env.BattleScrolls.gc.RequestGC = function() end
            local decodes = 0
            storage.DecodeInstanceFieldsAsync = function()
                decodes = decodes + 1
                return env.LibEffect.Succeed({ {}, {}, {}, {} })
            end
            env.CanExitInstanceImmediately = function() return false end
            env.GetCurrentZoneHouseId = function() return 1 end
            env.IsPlayerInAvAWorld = function() return false end
            env.IsActiveWorldBattleground = function() return false end
            env.GetTimeStamp = function() return 300 end
            local registrations = 0
            env.EVENT_MANAGER = {
                RegisterForEvent = function() registrations = registrations + 1 end,
                AddFilterForEvent = function() end,
            }
            assert(loadfile("BattleScrolls/combat/scribe.lua", "t", env))()
            local scribe = env.BattleScrolls.scribe
            scribe:Initialize()
            env.pump(100)
            assert_eq(registrations, 6, "initialization must finish without an async error")
            assert_eq(scribe.instance.worldName, "EU Megaserver")
            if recordedWorld == "NA Megaserver" then
                assert_true(scribe.instance ~= visit)
                assert_eq(decodes, 0)
                assert_eq(visit.left, true)
            else
                assert_eq(scribe.instance, visit)
                assert_eq(decodes, 1)
            end
        end
    end)
end)
