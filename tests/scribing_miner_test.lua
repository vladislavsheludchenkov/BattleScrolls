-- Preview the real miner with a constrained grimoire catalogue. No crafting,
-- ownership or character UI is needed to enumerate valid combinations.
local function miner(failPreview, initialOverride, options)
    options = options or {}
    local override = initialOverride or { 0, 0, 0, 0 }
    local callback, previews, ticks = nil, {}, 0
    local env = setmetatable({ SLASH_COMMANDS = {}, BattleScrollsAbilityDumpSV = options.saved or "previous dump" }, { __index = _G })
    env.SCRIBING_SLOT_ITERATION_BEGIN, env.SCRIBING_SLOT_ITERATION_END = 1, 3
    env.SCRIBING_SLOT_PRIMARY, env.SCRIBING_SLOT_SECONDARY, env.SCRIBING_SLOT_TERTIARY = 1, 2, 3
    env.SKILL_TYPE_NONE = 0
    env.d = function() end
    env.GetNumCraftedAbilities = function() return 3 end
    env.GetCraftedAbilityIdAtIndex = function(index) return index end
    env.GetSkillTypeForCraftedAbilityId = function(id) return id == 3 and 0 or 1 end
    env.IsCraftedAbilityDisabled = function(id) return id == 2 end
    local slots = { { 1, 2, 3, 4, 5, 6 }, { 21, 31 }, { 41, 42, 43, 44, 45, 46 } }
    env.GetNumScriptsInSlotForCraftedAbility = function(id, slot)
        assert_eq(id, 1, "disabled and unreleased grimoires are skipped")
        return #slots[slot]
    end
    env.GetScriptIdAtSlotIndexForCraftedAbility = function(_, slot, index) return slots[slot][index] end
    env.IsCraftedAbilityScriptDisabled = function(id) return id == 44 end
    env.IsScribableScriptCombinationForCraftedAbility = function(_, p, s) return not (p == 2 and s == 21) end
    env.IsCraftedAbilityScriptCompatibleWithSelections = function(_, _, p, _, t) return not (p == 3 and t == 42) end
    env.GetCraftedAbilityScriptSelectionOverride = function() return table.unpack(override) end
    env.SetCraftedAbilityScriptSelectionOverride = function(...) override = { ... } end
    env.ResetCraftedAbilityScriptSelectionOverride = function() override = { 0, 0, 0, 0 } end
    env.GetCraftedAbilityRepresentativeAbilityId = function() return 100 + override[2] end
    env.GetCraftedAbilityIcon = function() return "/esoui/recipe.dds" end
    env.GetAbilityIcon = function(id)
        assert_eq(id, 100 + override[2], "icon uses the currently previewed ability")
        return "/esoui/ability_" .. override[2] .. ".dds"
    end
    env.GetAbilityName = function() return "Focus " .. override[2] end
    env.GetAbilityDescriptionHeader = function() return "Header" end
    env.GetAbilityDescription = function()
        if failPreview then error("preview failed") end
        previews[#previews + 1] = table.concat(override, ":")
        return options.text or "Base"
    end
    env.GenerateCraftedAbilityScriptSlotDescriptionForAbilityDescription = function(_, slot) return "Script " .. override[slot + 1] end
    env.GetUnitClassId = function() return options.classId or 117 end
    env.GetAPIVersion = function() return 101048 end
    env.GetESOVersionString = function() return options.gameVersion or "eso.live.12.0.5.123456" end
    env.GetCVar = function() return options.language or "en" end
    env.zo_strformat = function(_, text) return text end
    env.EVENT_MANAGER = {
        RegisterForUpdate = function(_, _, _, fn) callback = fn end,
        UnregisterForUpdate = function() callback = nil end,
    }
    assert(loadfile("BattleScrollsAbilityDump/main.lua", "t", env))()
    env.SLASH_COMMANDS["/bsabilitydump"]("combinations")
    while callback do
        ticks = ticks + 1
        assert_true(ticks < 20, "scan finishes")
        if options.changeLanguage then options.language = "de" end
        callback()
        assert_eq(table.concat(override, ":"), table.concat(initialOverride or { 0, 0, 0, 0 }, ":"), "override restored between frames")
    end
    return env.BattleScrollsAbilityDumpSV, previews, ticks
end

local function count(rows)
    local n = 0
    for _ in pairs(rows) do n = n + 1 end
    return n
end

describe("Scribing miner", function()
    it("enumerates offered and mutually compatible scripts, with full contextual descriptions", function()
        local dump, previews, ticks = miner(false, { 88, 8, 9, 10 })
        assert_true(ticks > 2, "work is spread across ticks")
        dump = dump.datasets[1]
        assert_eq(count(dump.combinations), 53) -- 6*2*5 minus 5 unscribable and 2 incompatible
        assert_eq(#previews, 53)
        assert_eq(dump.gameVersion, "eso.live.12.0.5.123456")
        assert_eq(dump.apiVersion, 101048)
        local foundClass = false
        for _, row in pairs(dump.combinations) do
            assert_true(row:find("Header\nBase\nScript ", 1, true))
            local primary = row:match("^1\t(%d+)\t")
            assert_true(row:find("\t/esoui/ability_" .. primary .. ".dds\t", 1, true))
            assert_true(not row:find("/esoui/recipe.dds", 1, true))
            if row:find("\t31\t", 1, true) then
                assert_true(row:match("^1\t%d+\t31\t%d+\t117\t"))
                foundClass = true
            else
                assert_true(row:match("^1\t%d+\t21\t%d+\t0\t"))
            end
        end
        assert_true(foundClass)
    end)

    it("resets an initially empty override and preserves the last dump on preview failure", function()
        local dump = miner(true)
        assert_eq(dump, "previous dump")
        local success = miner(false)
        assert_eq(count(success.datasets[1].combinations), 53)
    end)

    it("accumulates classes, languages and versions across reloads, updating repeated identities", function()
        local saved = miner(false)
        local data = saved.datasets[1]
        data.items["42"] = "42\tExisting gear"
        data.abilities["100"] = "100\tExisting ability"
        saved = miner(false, nil, { saved = saved, classId = 1 })
        assert_eq(#saved.datasets, 1)
        assert_eq(count(data.combinations), 82) -- 24 shared + 29 for each class
        assert_eq(data.items["42"], "42\tExisting gear")
        assert_eq(data.abilities["100"], "100\tExisting ability")
        saved = miner(false, nil, { saved = saved, text = "Updated" })
        assert_eq(count(data.combinations), 82)
        assert_true(data.combinations["1\t1\t31\t41\t117"]:find("Updated", 1, true))
        saved = miner(false, nil, { saved = saved, language = "de" })
        saved = miner(false, nil, { saved = saved, gameVersion = "eso.live.12.0.6.123457" })
        assert_eq(#saved.datasets, 3)
        assert_eq(saved.datasets[2].language, "de")
        assert_eq(saved.datasets[3].gameVersion, "eso.live.12.0.6.123457")
        assert_eq(count(saved.datasets[1].combinations), 82)
    end)

    it("keeps completed datasets unchanged on preview failure or a mid-pass language change", function()
        local saved = miner(false)
        local before = saved.datasets[1].combinations["1\t1\t31\t41\t117"]
        local failed = miner(true, nil, { saved = saved, classId = 1 })
        assert_eq(failed, saved)
        local cancelled = miner(false, nil, { saved = saved, changeLanguage = true })
        assert_eq(cancelled, saved)
        assert_eq(#saved.datasets, 1)
        assert_eq(count(saved.datasets[1].combinations), 53)
        assert_eq(saved.datasets[1].combinations["1\t1\t31\t41\t117"], before)
    end)

end)
