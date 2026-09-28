-- Load the actual display helpers in an isolated ESO environment.
local function displayHelpers(lang, names)
    local env = setmetatable({
        BattleScrolls = { journal = {}, constants = {} },
        LFG_ROLE_DPS = 1, LFG_ROLE_HEAL = 2, LFG_ROLE_TANK = 3,
        GetCVar = function() return lang end,
        GetAbilityName = function(id) return names[id] or "" end,
        GetAbilityIcon = function(id) return "icon:" .. id end,
        GetAbilityCraftedAbilityId = function(id) return id == 216940 and 2 or 0 end,
        GetCraftedAbilityDisplayName = function() return "Wield Soul" end,
        zo_strformat = function(_, name) return name end,
    }, { __index = _G })
    assert(loadfile("BattleScrolls/core/utils.lua", "t", env))()
    assert(loadfile("BattleScrolls/ui/journal/utils.lua", "t", env))()
    return env.BattleScrolls.utils, env.BattleScrolls.journal.utils
end

describe("Ability display overrides", function()
    it("uses Soul Harvest's localized name in every supported language", function()
        local names = { en = "Soul Harvest", de = "Seelenernte", es = "cosecha de almas", fr = "Moisson d'âmes",
            jp = "魂の収穫者", ru = "Жатва душ", zh = "灵魂收割" }
        for lang, name in pairs(names) do
            local core, journal = displayHelpers(lang, { [36519] = "Rapid Stroke Passive", [36514] = name })
            assert_eq(core.GetScribeAwareAbilityDisplayName(36519), name)
            assert_eq(journal.getAbilityDisplayName(36519), name)
            assert_eq(journal.getAbilityIcon(36519), "icon:36514")
        end
    end)

    it("corrects Crypt Transfer only in Russian, including the ability-bar name helper", function()
        for _, lang in ipairs({ "en", "ru" }) do
            local core, journal = displayHelpers(lang, { [195031] = "Crypt Transfer", [196775] = "Одеяние могильного каноника" })
            local expected = lang == "ru" and "Одеяние могильного каноника" or "Crypt Transfer"
            assert_eq(core.GetScribeAwareAbilityDisplayName(195031), expected)
            assert_eq(journal.GetScribeAwareAbilityDisplayName(195031), expected)
            assert_eq(journal.getAbilityIcon(195031), "icon:195031")
        end
    end)

    it("distinguishes Deaden Pain from Necrotic Potency and retains grimoire naming", function()
        local core, journal = displayHelpers("en", { [124166] = "Necrotic Potency", [118623] = "Deaden Pain",
            [124192] = "Necrotic Potency", [216940] = "Potent Soul" })
        assert_eq(core.GetScribeAwareAbilityDisplayName(124166), "Deaden Pain")
        assert_eq(journal.getAbilityIcon(124166), "icon:118623")
        assert_eq(core.GetScribeAwareAbilityDisplayName(124192), "Necrotic Potency")
        assert_eq(journal.getAbilityIcon(124192), "icon:118639")
        assert_eq(core.GetScribeAwareAbilityDisplayName(216940), "Wield Soul")
    end)

    it("replaces incorrect real icons as well as placeholders", function()
        local _, journal = displayHelpers("en", {})
        assert_eq(journal.getAbilityIcon(108943), "icon:85564")
        assert_eq(journal.getAbilityIcon(108945), "icon:85858")
        assert_eq(journal.getAbilityIcon(108947), "icon:85859")
        assert_eq(journal.getAbilityIcon(238144), "icon:238141")
        assert_eq(journal.getAbilityIcon(137261), "icon:137261")
    end)
end)
