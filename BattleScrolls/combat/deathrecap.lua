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
        s.lastPlayerDeathMs = GetGameTimeMilliseconds()

        local numAttacks = GetNumKillingAttacks()
        if numAttacks <= 0 then return end

        -- Collect all attacks with timing info for sorting
        local allAttacks = {}
        for i = 1, numAttacks do
            local _, attackDamage, _, wasKillingBlow, castTimeAgoMS, durationMS, _, abilityId = GetKillingAttackInfo(i)
            -- Attacker name is kept locally only - it is never sent to
            -- group members (they only receive ability ids). Formatted with
            -- the base game's death recap strings so minions render exactly
            -- like the stock recap screen (owner grammar included).
            local attackerName
            if DoesKillingAttackHaveAttacker(i) then
                local rawName, _, _, _, _, _, _, minionName = GetKillingAttackerInfo(i)
                if rawName and rawName ~= "" then
                    if minionName and minionName ~= "" then
                        attackerName = zo_strformat(SI_DEATH_RECAP_ATTACKER_NAME_MINION, rawName, minionName)
                    else
                        attackerName = zo_strformat(SI_DEATH_RECAP_ATTACKER_NAME, rawName)
                    end
                end
            end
            table.insert(allAttacks, {
                abilityId = abilityId,
                damage = attackDamage,
                attackerName = attackerName,
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
                attackerName = allAttacks[i].attackerName,
            })
        end

        table.insert(s.deathRecaps, {
            timeMs = GetGameTimeMilliseconds() - s.fightStartTimeMs,
            attacks = attacks,
        })
    end)
end

function deathRecap:Cleanup()
    EVENT_MANAGER:UnregisterForEvent("BS_DeathRecap", EVENT_PLAYER_DEAD)
end
