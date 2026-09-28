local newClient = dofile("tests/mocks/lgb.lua")
local legacy = dofile("tests/fixtures/group_share_v5.lua")
local function fixture() return dofile("tests/fixtures/group_share_data.lua") end

local function assertClean(client)
    assert_eq(#client.warnings, 0, table.concat(client.warnings, "\n"))
end

local function sendSetup(client, setup, hash)
    client.BattleScrolls.setupShare:cacheLocalSetup(hash, setup)
    client.protocols[432].onDataCallback("group2", { setupHash = hash })
    return client.messages[#client.messages]
end

local function listen(client)
    local received = {}
    client.BattleScrolls.encounterShare:RegisterCallback("test", function(tag, data)
        received[#received + 1] = { tag = tag, data = data }
    end)
    return received
end

local function attachScribe(client)
    -- Register its real matchShare callback, without running unrelated login work.
    client.LibEffect = { Async = function() return { Run = function() end } end }
    client.BattleScrolls.state = { inCombat = false }
    client.BattleScrolls.utils.getUnitRole = function() return 1 end
    client.BattleScrolls.constants.BOSS_TAGS = { "boss1", "boss2", "boss3", "boss4", "boss5", "boss6" }
    for _, path in ipairs({ "storage/bitcodec", "storage/binary", "combat/scribe" }) do
        assert(loadfile("BattleScrolls/" .. path .. ".lua", "t", client))()
    end
    client.BattleScrolls.scribe:Initialize()
end

describe("Group protocol migration", function()
    it("registers only the six current formats and two v5 readers", function()
        local client = newClient()
        local ids = {}
        for id in pairs(client.protocols) do ids[#ids + 1] = id end
        table.sort(ids)
        assert_eq(table.concat(ids, ","), "430,431,432,433,435,436,437,439")
        assert_eq(client.BattleScrolls.setupShare.responseProtocol:GetId(), 433)
        assert_eq(client.BattleScrolls.encounterShare.protocol:GetId(), 439)
        assertClean(client)
    end)

    it("reads frozen v5 builds, including mastery, skill lines, scripts and poisons", function()
        local client = newClient()
        for _, name in ipairs({ "mastery", "skillLines" }) do
            local data = legacy[name]
            client.receiveHex(data.id, data.hex)
        end
        local setups = client.BattleScrolls.setupShare
        local mastery = setups:getSetup("group1", 100)
        local lines = setups:getSetup("group1", 101)
        assert_eq(mastery.classMasteryAbilityIds[2], 253000)
        assert_eq(lines.classSkillLineIds[3], 220)
        assert_eq(lines.classMasteryAbilityIds, nil)
        for _, build in ipairs({ mastery, lines }) do
            assert_eq(build.frontAbilities[1], 185805)
            assert_eq(build.backAbilities[6], 261000)
            assert_eq(build.frontPoisonEffect, 12345678)
            assert_eq(build.backPoisonItemId, 150731)
            assert_eq(build.scribedAbilities[1].scriptIds[3], 24)
            assert_eq(build.sets[1].frontCount, 5)
        end
        assertClean(client)
    end)

    it("reads the frozen v5 Vengeance build", function()
        local client = newClient()
        client.receiveHex(legacy.vengeance.id, legacy.vengeance.hex)
        local build = client.BattleScrolls.setupShare:getSetup("group1", 102)
        assert_true(build.isVengeance)
        assert_eq(build.loadoutSkillLineId, 900)
        assert_eq(build.vengeancePerkDefIds[3], 30000)
        assert_eq(build.scribedAbilities[1].abilityId, 217784)
        assertClean(client)
    end)

    it("reads the frozen v5 encounter without inventing new metrics", function()
        local client = newClient()
        local received = listen(client)
        client.receiveHex(legacy.encounter.id, legacy.encounter.hex)
        assert_eq(#received, 1)
        local data = received[1].data
        assert_eq(data.timestampS, fixture().encounter.timestampS)
        assert_eq(data.durationMs, 70500)
        assert_eq(data.bossDamage[1].bossTag, "boss1")
        assert_eq(data.bossDamage[1].damage, 606864)
        assert_eq(data.healing.rawOut, 2919863)
        assert_eq(data.healing.effectiveOut, 202345)
        assert_eq(data.deaths.last.attacks[1].abilityId, 200100)
        assert_eq(data.setupHash, 100)
        assert_eq(data.resurrections, nil)
        assert_eq(data.zenByBoss, nil)
        assertClean(client)
    end)

    it("keeps both live meter formats byte-for-byte compatible and sends them once", function()
        local client = newClient()
        local received = {}
        client.BattleScrolls.dpsShare:RegisterCallback("test", function(tag, data)
            if tag ~= "player" then received[#received + 1] = data end
        end)
        client.BattleScrolls.dpsShare:SendData(254000, 96400, 50, 40)
        client.BattleScrolls.dpsShare:SendData(100, 40, 57300, 4100)
        for i, name in ipairs({ "damage", "healing" }) do
            local message = client.messages[i]
            assert_eq(message:GetId(), legacy[name].id)
            assert_eq(message:GetData():ToHexString(), legacy[name].hex)
            client.deliver(message)
        end
        assert_eq(received[1].messageType, "damage")
        assert_eq(received[2].messageType, "healing")
        client.advance(10000)
        assert_eq(#client.messages, 2)
        assertClean(client)
    end)

    it("preserves wider IDs and every armor group in normal builds", function()
        local sender, receiver = newClient(), newClient()
        local setup = fixture().setup
        setup.frontAbilities[1] = 273766
        setup.foodAbilityIds = { 267467 }
        setup.scribedAbilities[1].abilityId = 273000
        setup.armorTraits, setup.armorEnchants = {}, {}
        for i = 1, 7 do
            setup.armorTraits[i] = { traitType = i, count = 1 }
            setup.armorEnchants[i] = { enchantId = i + 10, count = 1 }
        end
        local message = sendSetup(sender, setup, 103)
        assert_eq(message:GetId(), 433)
        receiver.deliver(message)
        local result = receiver.BattleScrolls.setupShare:getSetup("group1", 103)
        assert_eq(result.frontAbilities[1], 273766)
        assert_eq(result.foodAbilityIds[1], 267467)
        assert_eq(result.scribedAbilities[1].abilityId, 273000)
        assert_eq(#result.armorTraits, 7)
        assert_eq(result.armorTraits[7].traitType, 7)
        assert_eq(#result.armorEnchants, 7)
        assert_eq(result.armorEnchants[7].enchantId, 17)
        assert_eq(result.frontPoisonEffect, 12345678)
        assert_eq(result.backPoisonItemId, 150731)
        assertClean(sender)
        assertClean(receiver)
    end)

    it("preserves wider IDs in Vengeance builds", function()
        local client = newClient()
        local setup = fixture().setup
        setup.isVengeance = true
        setup.frontAbilities[1] = 273766
        setup.scribedAbilities[1].abilityId = 273000
        setup.loadoutSkillLineId = 900
        setup.vengeancePerkDefIds = { 12345, 20000, 30000 }
        client.deliver(sendSetup(client, setup, 104))
        local result = client.BattleScrolls.setupShare:getSetup("group1", 104)
        assert_true(result.isVengeance)
        assert_eq(result.frontAbilities[1], 273766)
        assert_eq(result.scribedAbilities[1].abilityId, 273000)
        assert_eq(result.vengeancePerkDefIds[3], 30000)
        assertClean(client)
    end)

    it("refreshes unchanged builds after upgrading without deleting old history's cache", function()
        local client = newClient()
        local share = client.BattleScrolls.setupShare
        local setup = fixture().setup
        local oldHash = legacy.mastery.hash
        local hash = share.computeHash(setup)
        assert_true(hash ~= oldHash)
        share:storeSetup("group1", oldHash, setup)
        share:onEncounterHashReceived("group1", hash)
        assert_eq(client.messages[1]:GetId(), 432)
        assert_true(share:hasSetup("group1", oldHash))
        client.advance(10000)
        assert_eq(#client.messages, 1, "small build requests are not repeated")
        assertClean(client)
    end)
end)

describe("Group sharing delivery", function()
    it("queues two identical fight copies and notifies local listeners once", function()
        local sender, receiver = newClient(), newClient()
        local localEvents, remoteEvents = listen(sender), listen(receiver)
        local encounter = fixture().encounter
        sender.BattleScrolls.encounterShare:send(encounter, encounter.timestampS, 100)
        assert_eq(#sender.messages, 2)
        assert_eq(#sender.timers, 0)
        assert_eq(#localEvents, 1)
        for _, message in ipairs(sender.messages) do
            assert_eq(message:GetId(), 439)
            receiver.deliver(message)
        end
        assert_eq(sender.messages[1]:GetData():ToHexString(), sender.messages[2]:GetData():ToHexString())
        assert_eq(#localEvents, 1)
        assert_eq(#remoteEvents, 2)
        assert_eq(remoteEvents[2].data.resurrections, 2)
        assert_eq(remoteEvents[2].data.zenByBoss[1].timeAt5Ms, 50123)
        sender.advance(10000)
        assert_eq(#sender.messages, 2)
        assertClean(sender)
        assertClean(receiver)
    end)

    it("recovers a fight when its first copy is truncated", function()
        local sender, receiver = newClient(), newClient()
        local received = listen(receiver)
        local data = fixture().encounter
        sender.BattleScrolls.encounterShare:send(data, data.timestampS, 100)
        receiver.receiveHex(439, sender.messages[1]:GetData():ToHexString():sub(1, 26))
        assert_eq(#received, 0)
        assert_true(#receiver.warnings > 0)
        sender.advance(5000)
        receiver.deliver(sender.messages[2])
        assert_eq(#received, 1)
        assert_eq(received[1].data.totalDamage, data.totalDamage)
    end)

    it("keeps repeat fights idempotent in live and stored encounters", function()
        for _, mode in ipairs({ "live", "stored", "binary" }) do
            local sender, receiver = newClient(), newClient()
            attachScribe(receiver)
            local data = fixture().encounter
            local stored = { timestampS = data.timestampS, durationMs = data.durationMs }
            if mode == "live" then
                receiver.BattleScrolls.state = { inCombat = true, initialized = true, fightStartRealTimeS = data.timestampS }
            else
                if mode == "binary" then stored._v = 20 end
                receiver.BattleScrolls.storage.savedVariables.history = { {
                    timestampS = data.timestampS, encounters = { stored },
                } }
            end
            sender.BattleScrolls.encounterShare:send(data, data.timestampS, 100)
            sender.advance(5000)
            receiver.deliver(sender.messages[1])
            receiver.deliver(sender.messages[2])
            local entries = mode == "live" and receiver.BattleScrolls.state.pendingSharedData
                or mode == "binary" and stored._shared or stored.sharedData
            assert_eq(#entries, 1, mode)
            assert_eq(#receiver.messages, 1, mode .. " must request the missing build only once")
            assert_eq(receiver.messages[1]:GetId(), 432)
            assertClean(receiver)
        end
    end)

    it("repeats builds without adding cache entries or scheduling more repeats", function()
        local client = newClient()
        sendSetup(client, fixture().setup, 105)
        -- Other group members can ask for the same build; the five-second throttle coalesces them.
        client.protocols[432].onDataCallback("group3", { setupHash = 105 })
        assert_eq(#client.messages, 2)
        assert_eq(#client.timers, 0)
        for _, message in ipairs(client.messages) do
            assert_eq(message:GetId(), 433)
            client.deliver(message)
        end
        local count = 0
        for _ in pairs(client.BattleScrolls.storage.savedVariables.sharedSetups.group1) do count = count + 1 end
        assert_eq(count, 1)
        assert_eq(client.messages[1]:GetData():ToHexString(), client.messages[2]:GetData():ToHexString())
        client.advance(10000)
        assert_eq(#client.messages, 2)
        assertClean(client)
    end)

    it("does not throttle a build that failed to queue", function()
        local client = newClient()
        local protocol = client.BattleScrolls.setupShare.responseProtocol
        local realSend = protocol.Send
        protocol.Send = function() return false end
        sendSetup(client, fixture().setup, 106)
        assert_eq(#client.timers, 0)
        protocol.Send = realSend
        client.protocols[432].onDataCallback("group2", { setupHash = 106 })
        assert_eq(#client.messages, 2)
        assert_eq(#client.timers, 0)
        assertClean(client)
    end)

    it("does not queue either copy while solo", function()
        local client = newClient()
        local data = fixture().encounter
        client.grouped = false
        client.BattleScrolls.encounterShare:send(data, data.timestampS, 100)
        assert_eq(#client.messages, 0)
        assertClean(client)
    end)

    it("uses LGB's real queue to finish the first copy before starting the second", function()
        for _, kind in ipairs({ "fight", "build" }) do
            local client = newClient()
            if kind == "fight" then
                local data = fixture().encounter
                client.BattleScrolls.encounterShare:send(data, data.timestampS, 100)
            else
                sendSetup(client, fixture().setup, 107)
            end
            assert_eq(client.queue:GetSize(), 2)
            local first, second = client.messages[1], client.messages[2]
            local completed = 0
            while client.queue:GetSize() > 0 do
                local message = client.queue:GetNextRelevantEntry(false)
                assert_eq(message, completed == 0 and first or second)
                message:UpdateStatus(30)
                if message:ShouldRequeue() then
                    client.queue:EnqueueMessage(message)
                else
                    completed = completed + 1
                end
            end
            assert_eq(completed, 2)
            assertClean(client)
        end
    end)

    it("does not repeat small color preference messages", function()
        local client = newClient()
        client.BattleScrolls.storage.savedVariables.settings.groupBarColor = "AABBCC"
        client.BattleScrolls.prefsShare:Send()
        client.advance(10000)
        assert_eq(#client.messages, 1)
        assert_eq(client.messages[1]:GetId(), 435)
        assertClean(client)
    end)
end)
