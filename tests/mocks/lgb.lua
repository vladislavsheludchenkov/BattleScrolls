-- Real LGB fields, buffers and protocols with only the ESO/group transport mocked.
-- Each client has its own Lua environment, caches and protocol registry.
return function(sourceRoot)
    local env = setmetatable({
        BattleScrolls = {
            constants = { huge = 2 ^ 20 },
            setupAnalysis = { ARMOR_SLOT_INDICES = {}, JEWELRY_SLOT_INDICES = {} },
            storage = { savedVariables = { sharedSetups = {}, settings = {} } },
            utils = { GetUndecoratedDisplayName = function(tag) return tag or "player" end },
        },
        messages = {}, protocols = {}, warnings = {}, timers = {}, now = 10000, grouped = true,
        SemisPlaygroundCheckAccess = function() return true end,
        GetCVar = function() return "0" end,
        AreUnitsEqual = function(a, b) return a == b end,
        GetTimeStamp = function() return 1790500000 end,
        IsClassMasterySkillLine = function() return false end,
        zo_round = function(n) return math.floor(n + 0.5) end,
        BitXor = function(a, b) return math.floor(a) ~ math.floor(b) end,
        BitNot = function(a, bits) return (~a) & ((1 << bits) - 1) end,
        EVENT_PLAYER_ACTIVATED = 1, EVENT_GROUP_MEMBER_JOINED = 2, EVENT_GROUP_MEMBER_LEFT = 3,
        EVENT_MANAGER = { RegisterForEvent = function() end, UnregisterForEvent = function() end },
    }, { __index = _G })
    env.GetGameTimeMilliseconds = function() return env.now end
    env.IsUnitGrouped = function() return env.grouped end
    env.ZO_ShallowTableCopy = function(source, dest)
        dest = dest or {}
        for key, value in pairs(source) do dest[key] = value end
        return dest
    end
    env.zo_mixin = function(dest, ...)
        for _, source in ipairs({ ... }) do env.ZO_ShallowTableCopy(source, dest) end
    end
    env.ZO_CombineNumericallyIndexedTables = function(dest, ...)
        for _, source in ipairs({ ... }) do
            for _, value in ipairs(source) do dest[#dest + 1] = value end
        end
    end
    local logger = {
        Debug = function() end,
        Warn = function(_, format, ...)
            env.warnings[#env.warnings + 1] = string.format(format, ...)
        end,
    }
    env.BattleScrolls.log = {
        Warn = function(message) env.warnings[#env.warnings + 1] = message end,
    }
    env.zo_callLater = function(callback, delay)
        env.timers[#env.timers + 1] = { callback = callback, at = env.now + delay }
    end
    env.advance = function(ms)
        env.now = env.now + ms
        local pending = env.timers
        env.timers = {}
        for _, timer in ipairs(pending) do
            if timer.at <= env.now then timer.callback() else env.timers[#env.timers + 1] = timer end
        end
    end
    env.LibGroupBroadcast = { internal = { class = {}, logger = logger }, Initialize = function() end }
    local function load(path) assert(loadfile(path, "t", env))() end
    load("esoui/esoui/libraries/utility/baseobject.lua")
    for _, file in ipairs({
        "BinaryBuffer", "protocol/FieldBase", "protocol/NumericField", "protocol/FlagField",
        "protocol/EnumField", "protocol/PercentageField", "protocol/ReservedField",
        "protocol/ArrayField", "protocol/TableField", "protocol/VariantField", "protocol/OptionalField",
        "messages/MessageBase", "messages/DataMessageBase", "messages/FixedSizeDataMessage",
        "messages/FlexSizeDataMessage", "MessageQueue", "protocol/Protocol", "PublicApi",
    }) do load("LibGroupBroadcast/" .. file .. ".lua") end
    env.queue = env.LibGroupBroadcast.internal.class.MessageQueue:New()
    local manager = {
        IsGrouped = function() return env.grouped end,
        IsProtocolEnabled = function() return true end,
        QueueDataMessage = function(_, message)
            env.messages[#env.messages + 1] = message
            env.queue:EnqueueMessage(message)
        end,
    }
    env.BattleScrolls.lgbHandler = {
        SetDisplayName = function() end,
        SetDescription = function() end,
        DeclareProtocol = function(_, id, name)
            assert(not env.protocols[id], "duplicate protocol ID")
            local protocol = env.LibGroupBroadcast.internal.class.Protocol:New(id, name, manager)
            env.protocols[id] = protocol
            return protocol
        end,
    }
    env.LibGroupBroadcast.RegisterHandler = function() return env.BattleScrolls.lgbHandler end
    sourceRoot = sourceRoot or "BattleScrolls"
    load(sourceRoot .. "/storage/bitcodec.lua")
    load(sourceRoot .. "/storage/binary.lua")
    load(sourceRoot .. "/network/lgb.lua")
    for _, name in ipairs({ "dpsshare", "setupshare", "encountershare" }) do
        load(sourceRoot .. "/network/" .. name .. ".lua")
        env.BattleScrolls[name == "dpsshare" and "dpsShare" or name == "setupshare" and "setupShare" or "encounterShare"]:Initialize()
    end
    if sourceRoot == "BattleScrolls" then
        load(sourceRoot .. "/network/prefsshare.lua")
        env.BattleScrolls.prefsShare:Initialize()
    end
    -- LGB transmits whole bytes; keep their padding in decoder tests.
    env.receiveHex = function(id, hex, tag)
        local data = env.LibGroupBroadcast.internal.class.BinaryBuffer.FromHexString(hex)
        local protocol = env.protocols[id]
        if protocol then protocol:Receive(tag or "group1", { GetData = function() return data end }) end
    end
    env.deliver = function(message, tag)
        env.receiveHex(message:GetId(), message:GetData():ToHexString(), tag)
    end
    return env
end
