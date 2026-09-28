-- storage:EstimateSavedSize composition: history, setup pools and the other
-- saved roots, on top of storage/sizemodel.lua.

dofile("BattleScrolls/core/effect.lua")
dofile("BattleScrolls/storage/sizemodel.lua")
dofile("BattleScrolls/storage/storage.lua")
local storage = BattleScrolls.storage
local sizeModel = BattleScrolls.sizeModel
local FACTOR = sizeModel.GAUGE_PER_CHUNK_BYTE

local function near(actual, expected, message)
    assert_true(math.abs(actual - expected) < 1e-6, (message or "") .. string.format(" expected %.3f got %.3f", expected, actual))
end

describe("Storage saved-size estimate", function()
    it("adds history, both setup pools and the rest of the saved global", function()
        local ownPayload = { v = 20, c = { "AAAA", "BBBB" } }
        local sharedPayload = { setupHash = 7, gear = { "sword" } }
        local instance1 = { zone = "Sunspire", encounters = { { name = "Yolnahkriin" }, { name = "Lokkestiiz" } }, locked = true }
        local instance2 = { zone = "Cloudrest", encounters = { { name = "Z'Maja" } } }
        local sv = {
            version = 1,
            history = { instance1, instance2 },
            ownSetups = { [513] = ownPayload },
            sharedSetups = { ["@friend"] = { [7] = sharedPayload } },
            settings = { storageSizePreset = "medium" },
        }
        local otherWorld = { history = { { zone = "Maw of Lorkhaj", encounters = {} } } }
        BattleScrollsSavedVariables = { Default = { ["@me"] = { ["$AccountWide"] = { ["NA Megaserver"] = sv, ["EU Megaserver"] = otherWorld } } } }
        storage.savedVariables = sv
        -- Measured before the estimate adds its cache fields to instances and payloads
        local model1, model2 = sizeModel.measure(instance1), sizeModel.measure(instance2)
        local ownModel, sharedModel = sizeModel.measure(ownPayload), sizeModel.measure(sharedPayload)

        local estimate = storage:EstimateSavedSize()

        near(estimate.historyBytes, (model1 + model2) * FACTOR, "history")
        near(estimate.lockedBytes, model1 * FACTOR, "locked share")
        assert_eq(estimate.encounterCount, 3)
        assert_eq(estimate.instanceCount, 2)
        local pools = ownModel + sizeModel.tableShell(1)
            + sharedModel + sizeModel.tableShell(1) + sizeModel.tableShell(1)
        near(estimate.setupBytes, pools * FACTOR, "setup pools with their containers")
        assert_eq(ownPayload._estimatedSize, ownModel, "payload cache persisted on the entry")
        assert_eq(ownPayload._estimatedSizeV, sizeModel.VERSION)
        assert_eq(sharedPayload._estimatedSizeV, sizeModel.VERSION)
        local visited = { [sv.history] = true, [sv.ownSetups] = true, [sv.sharedSetups] = true }
        near(estimate.otherBytes, sizeModel.measure(BattleScrollsSavedVariables, visited) * FACTOR, "other roots, other world included")
        assert_true(estimate.otherBytes > sizeModel.measure(otherWorld) * FACTOR, "the other world's history is in the other roots")
        near(estimate.totalBytes, estimate.historyBytes + estimate.setupBytes + estimate.otherBytes, "total")

        -- Instance caches carry the model version; the estimate is stable across calls
        assert_eq(instance1._estimatedSizeV, sizeModel.VERSION)
        assert_eq(instance1._estimatedSize, model1)
        near(storage:EstimateSavedSize().totalBytes, estimate.totalBytes, "repeat call")
    end)

    it("retains older instance estimates until explicitly refreshed", function()
        local instance = { zone = "Rockgrove", encounters = {}, _estimatedSize = 123456, _estimatedSizeV = 1 }
        local unversioned = { zone = "Sunspire", encounters = {}, _estimatedSize = 345678, locked = true }
        storage.savedVariables = { history = { instance, unversioned }, settings = {} }
        near(storage:EstimateInstanceSize(instance), 123456 * FACTOR, "older cache reused")
        near(storage:EstimateSavedSize().historyBytes, (123456 + 345678) * FACTOR, "whole history reuses caches")
        near(storage:GetLockedInstancesSize(), 345678 * FACTOR, "locking reuses caches too")
        assert_eq(instance._estimatedSizeV, 1, "a read must not mark stale bytes current")
        assert_eq(unversioned._estimatedSizeV, nil)

        local model = sizeModel.measure(instance)
        near(storage:EstimateInstanceSize(instance, true), model * FACTOR, "explicit refresh uses current model")
        assert_eq(instance._estimatedSize, model)
        assert_eq(instance._estimatedSizeV, sizeModel.VERSION)
        near(storage:EstimateSavedSize().historyBytes, (model + 345678) * FACTOR, "fresh cache reused")
    end)

    it("still recomputes payload caches written by an older model", function()
        local payload = { v = 20, c = { "CCCC" }, _estimatedSize = 654321, _estimatedSizeV = 1 }
        storage.savedVariables = { history = {}, ownSetups = { [1] = payload }, settings = {} }
        local payloadModel = sizeModel.measure(payload)
        near(storage:EstimateSavedSize().setupBytes, (payloadModel + sizeModel.tableShell(1)) * FACTOR, "payload recomputed")
        assert_eq(payload._estimatedSize, payloadModel)
        assert_eq(payload._estimatedSizeV, sizeModel.VERSION)
    end)

    it("reports the limit of the current preset in MiB", function()
        storage.savedVariables = { history = {}, settings = { storageSizePreset = "yolo" } }
        assert_eq(storage:GetSizeLimitBytes(), 50 * sizeModel.MIB)
        storage.savedVariables = { history = {}, settings = { storageSizePreset = "unknown" } }
        assert_eq(storage:GetSizeLimitBytes(), 12 * sizeModel.MIB, "falls back to medium")
    end)
end)

describe("Storage setup pools after deletion", function()
    local function fixture()
        local ownA, ownShared, sharedOnlyA, sharedBoth, sharedLegacy = { c = { "AAAA" } }, { c = { "SS" } },
            { gear = { "bow" } }, { gear = { "staff" } }, { gear = { "axe" } }
        local encA1 = { _setupHash = 1, _shared = { { d = "@p", h = 5 }, { d = "@q", h = 9 } } }
        local encA2 = { _setupHash = 2, sharedData = { { displayName = "@r", data = { setupHash = 3 } } } }
        local encB1 = { _setupHash = 2, _shared = { { d = "@q", h = 9 } } }
        local instanceA = { index = 1, zone = "A", encounters = { encA1, encA2 } }
        local instanceB = { index = 2, zone = "B", encounters = { encB1 } }
        local sv = {
            history = { instanceA, instanceB },
            ownSetups = { [1] = ownA, [2] = ownShared },
            sharedSetups = { ["@p"] = { [5] = sharedOnlyA }, ["@q"] = { [9] = sharedBoth }, ["@r"] = { [3] = sharedLegacy } },
            settings = {},
        }
        storage.savedVariables = sv
        return sv, instanceA, instanceB, encA1, encA2, encB1,
            { ownA = ownA, ownShared = ownShared, sharedOnlyA = sharedOnlyA, sharedBoth = sharedBoth, sharedLegacy = sharedLegacy }
    end

    it("estimates only the setups nothing else references, binary and legacy entries alike", function()
        local sv, instanceA, _, encA1, encA2, encB1, p = fixture()
        -- Measured before the estimate stamps its cache fields on the payloads
        local m = {}
        for name, payload in pairs(p) do m[name] = sizeModel.measure(payload) end
        near(storage:EstimateOrphanedSetupBytes(instanceA.encounters),
            (m.ownA + m.sharedOnlyA + m.sharedLegacy) * FACTOR,
            "own 1, @p/5 and the legacy @r/3 go with instance A; own 2 and @q/9 stay with B")
        near(storage:EstimateOrphanedSetupBytes({ encA1 }), (m.ownA + m.sharedOnlyA) * FACTOR, "encounter A1 alone")
        near(storage:EstimateOrphanedSetupBytes({ encA2 }), m.sharedLegacy * FACTOR, "A2 shares own 2 with B")
        near(storage:EstimateOrphanedSetupBytes({ encB1 }), 0, "everything B1 references is also referenced by A")
        sv.ownSetups[1] = nil
        near(storage:EstimateOrphanedSetupBytes({ encA1 }), m.sharedOnlyA * FACTOR, "a missing pool entry counts nothing")
    end)

    it("prunes orphaned own and shared setups when an instance is deleted manually", function()
        local sv, _, _, _, _, _, p = fixture()
        assert_true(storage:DeleteInstance(1))
        assert_eq(#sv.history, 1)
        TestEnv.pump(5)  -- the prune runs under the write mutex
        assert_eq(sv.ownSetups[1], nil, "own 1 was only A's")
        assert_eq(sv.ownSetups[2], p.ownShared, "own 2 is still B's")
        assert_eq(sv.sharedSetups["@p"], nil, "the player table goes when its last hash goes")
        assert_eq(sv.sharedSetups["@r"], nil)
        assert_eq(sv.sharedSetups["@q"][9], p.sharedBoth)
    end)

    it("prunes after an encounter delete, including the one that removes its instance", function()
        local sv, instanceA, instanceB, encA1, encA2, encB1, p = fixture()
        local deleted, instanceDeleted = storage:DeleteEncounter(instanceA, encA1)
        assert_true(deleted and not instanceDeleted)
        TestEnv.pump(5)
        assert_eq(sv.ownSetups[1], nil)
        assert_eq(sv.sharedSetups["@p"], nil)
        assert_eq(sv.sharedSetups["@q"][9], p.sharedBoth, "still referenced by B1")
        assert_eq(sv.sharedSetups["@r"][3], p.sharedLegacy, "still referenced by A2")
        deleted, instanceDeleted = storage:DeleteEncounter(instanceB, encB1)
        assert_true(deleted and instanceDeleted)
        TestEnv.pump(5)
        assert_eq(#sv.history, 1, "B is gone with its last encounter")
        assert_eq(sv.sharedSetups["@q"], nil, "@q/9 was only referenced by B1 after A1 went")
        assert_eq(sv.ownSetups[2], p.ownShared, "A2 still references own 2")
        assert_true(storage:DeleteEncounter(instanceA, encA2))
        TestEnv.pump(5)
        assert_eq(next(sv.ownSetups), nil)
        assert_eq(next(sv.sharedSetups), nil)
        assert_eq(#sv.history, 0)
    end)
end)

describe("Storage pool writes under the mutex", function()
    -- InternOwnSetup encodes the setup through binaryStorage; the stub keys
    -- the chunks on the gear string so identical builds compare equal
    local function withStubs(body)
        local previousBinary, previousScribe = BattleScrolls.binaryStorage, BattleScrolls.scribe
        BattleScrolls.binaryStorage = {
            buildPoolableSetup = function(setup) return setup end,
            encodeSetupStandalone = function(setup) return { setup.gear }, 1 end,
        }
        local removed = {}
        BattleScrolls.scribe = { OnInstanceRemoved = function(_, instance) removed[#removed + 1] = instance end }
        local ok, err = pcall(body, removed)
        BattleScrolls.binaryStorage, BattleScrolls.scribe = previousBinary, previousScribe
        if not ok then error(err, 0) end
    end

    local function fixture()
        local stored = { _setupHash = 7 }
        local instance = { index = 1, zone = "A", encounters = { stored } }
        storage.savedVariables = {
            history = { instance },
            ownSetups = { [7] = { v = 1, c = { "bow" } } },
            sharedSetups = {},
            settings = {},
            nextInstanceIndex = 2,
        }
        return instance, stored
    end

    ---A finalize as the mutex sees it: intern, encode across frames, then
    ---insert and push in one step
    local function finalizeLike(instance, frames, setup)
        local landed = false
        storage.writeMutex:WithPermit(LibEffect.Async(function()
            if setup then
                assert_true(storage:InternOwnSetup(7, setup))
            end
            for _ = 1, frames do
                LibEffect.Yield():Await()
            end
            if setup then
                instance.encounters[#instance.encounters + 1] = { _setupHash = 7 }
                if not storage:IsInHistory(instance) then
                    storage:PushInstance(instance)
                end
            end
            landed = true
        end)):Run()
        return function() return landed end
    end

    it("prunes right after a delete when nothing is encoding", function()
        withStubs(function()
            local instance, stored = fixture()
            local sv = storage.savedVariables
            assert_true(storage:DeleteEncounter(instance, stored))
            assert_true(sv.ownSetups[7] ~= nil, "the prune is deferred to the mutex, not run inline")
            TestEnv.pump(5)
            assert_eq(sv.ownSetups[7], nil)
        end)
    end)

    it("waits for the finalize holding the mutex before pruning", function()
        withStubs(function()
            local instance, stored = fixture()
            local sv = storage.savedVariables
            local entry = sv.ownSetups[7]
            local landed = finalizeLike(instance, 6, nil)
            TestEnv.pump(2)
            assert_true(storage:DeleteEncounter(instance, stored))
            TestEnv.pump(3)
            assert_true(not landed(), "the finalize is still encoding")
            assert_eq(sv.ownSetups[7], entry, "the prune is queued behind it")
            TestEnv.pump(10)
            assert_true(landed())
            assert_eq(sv.ownSetups[7], nil, "and runs once the mutex is free")
        end)
    end)

    it("keeps a setup the in-flight encounter reuses, and re-pushes its deleted instance", function()
        withStubs(function(removed)
            local instance, stored = fixture()
            local sv = storage.savedVariables
            local entry = sv.ownSetups[7]
            local landed = finalizeLike(instance, 6, { gear = "bow" })
            TestEnv.pump(2)
            assert_eq(sv.ownSetups[7], entry, "an identical build reuses the entry")
            local _, instanceDeleted = storage:DeleteEncounter(instance, stored)
            assert_true(instanceDeleted)
            assert_eq(removed[1], instance, "the scribe is told before the table leaves the history")
            assert_true(not storage:IsInHistory(instance))
            TestEnv.pump(15)
            assert_true(landed())
            assert_eq(sv.ownSetups[7], entry, "the landed encounter references it, so the prune keeps it")
            assert_true(storage:IsInHistory(instance), "the fight re-entered the history as its own entry")
            assert_eq(instance.index, 2, "under a fresh index")
            assert_eq(#instance.encounters, 1)
        end)
    end)

    it("keeps a hash collision inline", function()
        withStubs(function()
            fixture()
            assert_true(not storage:InternOwnSetup(7, { gear = "staff" }))
        end)
    end)
end)
