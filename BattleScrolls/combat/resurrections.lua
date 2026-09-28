-----------------------------------------------------------
-- Resurrections
-- Records the player's successful resurrection casts in combat
--
-- EVENT_RESURRECT_RESULT fires for the resurrector when their attempt
-- settles; RESURRECT_RESULT_SUCCESS means the cast completed and the
-- offer was presented (the soul gem was spent). Whether the target
-- accepts is their choice and not tracked.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class ResurrectionEvent
---@field displayName string Resurrected player's display name
---@field timeMs number Offset from fight start

---@class BattleScrollsResurrections
local resurrections = {}
BattleScrolls.resurrections = resurrections

function resurrections:Initialize()
    EVENT_MANAGER:RegisterForEvent("BattleScrolls_Resurrections", EVENT_RESURRECT_RESULT,
            function(_, _targetCharacterName, result, targetDisplayName)
                if result ~= RESURRECT_RESULT_SUCCESS then
                    return
                end
                local state = BattleScrolls.state
                if not state or not state.initialized then
                    return
                end
                local log = state.resurrectionLog
                log[#log + 1] = {
                    displayName = targetDisplayName or "",
                    timeMs = GetGameTimeMilliseconds() - state.fightStartTimeMs,
                }
            end)
end

function resurrections:Cleanup()
    EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Resurrections", EVENT_RESURRECT_RESULT)
end
