-----------------------------------------------------------
-- DeathRecap
-- Captures killing attack data from ESO API on player death
--
-- Subscribes to EVENT_PLAYER_DEAD and records death recaps
-- on the combat state for later sharing via encounter share.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class DeathRecapModule
local deathRecap = {}
BattleScrolls.deathRecap = deathRecap

function deathRecap:Initialize()
    EVENT_MANAGER:RegisterForEvent("BS_DeathRecap", EVENT_PLAYER_DEAD, function()
        local s = BattleScrolls.state
        if not s or not s.initialized then return end

        s.playerDeathCount = (s.playerDeathCount or 0) + 1

        local numAttacks = GetNumKillingAttacks()
        if numAttacks <= 0 then return end

        -- Collect all attacks with timing info for sorting
        local allAttacks = {}
        for i = 1, numAttacks do
            local _, attackDamage, _, wasKillingBlow, castTimeAgoMS, durationMS, _, abilityId = GetKillingAttackInfo(i)
            table.insert(allAttacks, {
                abilityId = abilityId,
                damage = attackDamage,
                wasKillingBlow = wasKillingBlow,
                lastUpdateAgoMS = castTimeAgoMS - durationMS,
            })
        end

        -- Sort chronologically (oldest first, killing blow last) -- matches ESO's deathrecap.lua
        table.sort(allAttacks, function(a, b)
            if a.wasKillingBlow then return false end
            if b.wasKillingBlow then return true end
            return a.lastUpdateAgoMS > b.lastUpdateAgoMS
        end)

        -- Take last 6 (most recent + killing blow)
        local attacks = {}
        local startIndex = math.max(1, #allAttacks - 5)
        for i = startIndex, #allAttacks do
            table.insert(attacks, {
                abilityId = allAttacks[i].abilityId,
                damage = allAttacks[i].damage,
            })
        end

        table.insert(s.deathRecaps, {
            timeMs = GetGameTimeMilliseconds() - s.fightStartTimeMs,
            attacks = attacks,
        })
    end)
end
