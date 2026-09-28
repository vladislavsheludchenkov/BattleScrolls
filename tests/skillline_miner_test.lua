describe("Skill line miner", function()
    it("uses mastery collectible icons across classes and preserves other lines' detailed icons", function()
        local callback
        local env = setmetatable({ SLASH_COMMANDS = {} }, { __index = _G })
        local names = { [218] = "Herald of the Tome", [36] = "Draconic Power", [41] = "Dark Magic", [76] = "Provisioning" }
        local collectibles = { [218] = 1001, [36] = 1002, [41] = 1003 }
        local icons = {
            [1001] = "/esoui/art/icons/arcanist_herald_of_the_tome.dds",
            [1002] = "/esoui/art/icons/dragonknight_draconic_power.dds",
            [1003] = "",
        }
        local counts = {}
        env.SKILL_TYPE_ITERATION_BEGIN, env.SKILL_TYPE_ITERATION_END = 1, 2
        env.GetNumSkillLines = function() return 1 end
        env.GetSkillLineId = function(skillType) return skillType == 1 and 218 or 76 end
        env.GetNumClasses = function() return 3 end
        env.GetClassIdByIndex = function(index) return ({ 117, 1, 2 })[index] end
        env.GetNumSkillLinesForClass = function() return 1 end
        env.GetSkillLineIdForClass = function(classId) return ({ [117] = 218, [1] = 36, [2] = 41 })[classId] end
        env.GetSkillLineNameById = function(id)
            counts[id] = (counts[id] or 0) + 1
            return names[id]
        end
        env.GetSkillLineMasteryCollectibleId = function(id) return collectibles[id] or 0 end
        env.GetCollectibleIcon = function(id) return icons[id] end
        env.GetSkillLineDetailedIconById = function(id)
            assert_true(id == 76 or id == 41, "class collectible art takes precedence over detailed icons")
            return id == 76 and "/esoui/art/icons/skilllinexp_provisioner.dds" or nil
        end
        env.GetAPIVersion = function() return 101051 end
        env.GetESOVersionString = function() return "eso.rc.12.1.4.3294972" end
        env.GetCVar = function() return "en" end
        env.zo_strformat = function(_, text) return text end
        env.d = function() end
        env.EVENT_MANAGER = {
            RegisterForUpdate = function(_, _, _, fn) callback = fn end,
            UnregisterForUpdate = function() callback = nil end,
        }
        assert(loadfile("BattleScrollsAbilityDump/main.lua", "t", env))()
        env.SLASH_COMMANDS["/bsabilitydump"]("skilllines")
        callback()
        callback()
        assert_eq(callback, nil)
        local rows = env.BattleScrollsAbilityDumpSV.datasets[1].skilllines
        assert_eq(rows["218"], "218\tHerald of the Tome\t" .. icons[1001] .. "\t")
        assert_eq(rows["36"], "36\tDraconic Power\t" .. icons[1002] .. "\t")
        assert_eq(rows["41"], "41\tDark Magic\t\t")
        assert_eq(rows["76"], "76\tProvisioning\t/esoui/art/icons/skilllinexp_provisioner.dds\t")
        for id in pairs(names) do assert_eq(counts[id], 1, "each skill line is mined once") end
    end)
end)
