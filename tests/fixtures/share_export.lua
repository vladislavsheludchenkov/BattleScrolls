-- Emits a wire stream using the real addon writer for the web API tests.
-- Run from the repository root: lua tests/fixtures/share_export.lua <uiPlatform> <world> <service>
dofile("tests/mocks/eso.lua")
local scheduler = dofile("tests/mocks/libasync.lua")
local Effect = dofile("BattleScrolls/core/effect.lua")
dofile("BattleScrolls/storage/bitcodec.lua")
dofile("BattleScrolls/storage/binary.lua")
dofile("BattleScrolls/network/export.lua")

PLATFORM_SERVICE_TYPE_XBL = 2
PLATFORM_SERVICE_TYPE_PSN = 1
GetUIPlatform = function() return tonumber(arg[1]) or UI_PLATFORM_PC end
GetPlatformServiceType = function() return tonumber(arg[3]) or 0 end
GetWorldName = function() return arg[2] or "EU Megaserver" end
GetTimeStamp = function() return 1700000000 end
BattleScrolls.utils = { GetUndecoratedDisplayName = function() return "Recorder" end }

local encounter = {
    displayName = "Fixture fight", timestampS = 1699999999, durationMs = 9000,
    playerUnitId = 1,
    unitNames = { [1] = "Recorder", [2] = "Éowyn", [3] = "NPC", [4] = "Recorder" },
    resurrections = 1,
    resurrectionLog = { { displayName = "Resurrected", timeMs = 4000 } },
    unitAliveTimeMs = { ["Healer"] = 8000 },
    _shared = { BattleScrolls.binaryStorage.encodeSharedEntry({
        displayName = "SharedMember", role = 1,
        data = { timestampS = 1699999999, durationMs = 9000, setupHash = 0,
            totalDamage = 1000, maxHit = 1000, totalDamageTaken = 0 },
    }) },
}
BattleScrolls.storage = { DecodeEncounterAsync = function() return Effect.Async(function() return encounter end) end }
local instance = { zone = "Fixture zone", timestampS = 1699999900, abilityInfo = {}, encounters = { encounter } }
local fiber = BattleScrolls.export.buildEncounterShareAsync(instance, encounter):Run()
scheduler.pump(1000)
assert(fiber:IsSucceeded(), tostring(fiber._error))
io.write(BattleScrolls.export.bytesToBase64(fiber._value.bytes))
