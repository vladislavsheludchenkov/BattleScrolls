-- Exercise the actual journal renderer with captured ultimate events.
local function renderUltimate(casts, drained)
    local journal = { renderers = {}, StatIcons = {}, EntryBuilder = {} }
    journal.EntryBuilder.addEntry = function(list, entry) list[#list + 1] = entry end
    journal.utils = {
        getAbilityDisplayName = function(id) return "Ability " .. id end,
        getAbilityIcon = function() return "icon" end,
        formatDuration = tostring,
        appendAbilityIdLine = function() end,
    }
    local env = setmetatable({
        BattleScrolls = { journal = journal, ultimate = { TIMIDITY_DEBUFFS = {} } },
        SemisPlaygroundCheckAccess = function() return true end,
        GetString = function(id) return id end,
        zo_strformat = function(text, ...) return text .. " " .. table.concat({...}, " ") end,
        LibEffect = {
            Async = function(body) return body() end,
            Yield = function() return { Await = function() end } end,
        },
    }, { __index = function(_, key)
        if key:match("^BATTLESCROLLS_") then return key end
        return _G[key]
    end })
    assert(loadfile("BattleScrolls/ui/journal/renderers/activity.lua", "t", env))()
    local list = {}
    journal.renderers.activity.renderActivity({ list = list, durationSec = 10, encounter = {
        ultimate = { startUlt = 500, maxUlt = 500, totalGained = 0, totalDrained = drained, gainByAbilityId = {}, casts = casts },
    } })
    local byLabel = {}
    for _, row in ipairs(list) do byLabel[row.label] = row end
    return byLabel
end

describe("Ultimate presentation", function()
    it("counts Crypt Transfer's full donation as spent and preserves normal excess and drains", function()
        local rows = renderUltimate({
            { abilityId = 195031, timeMs = 1000, poolBefore = 500, cost = 1 },
            { abilityId = 101, timeMs = 9000, poolBefore = 200, cost = 150 },
        }, 750)
        assert_eq(rows.BATTLESCROLLS_STAT_ULT_SPENT.sublabel, "650")
        assert_eq(rows.BATTLESCROLLS_STAT_ULT_LOST.sublabel, "50")
        assert_eq(rows.BATTLESCROLLS_STAT_ULT_DRAINED.sublabel, "50")
        assert(rows["<<C:1>> Ability 195031"].sublabel:find("BATTLESCROLLS_DETAIL_LOST 0", 1, true))
    end)

    it("does not infer spent or lost values for recordings missing cast costs", function()
        local rows = renderUltimate({ { abilityId = 195031, timeMs = 1000, poolBefore = 500 } }, 500)
        assert_eq(rows.BATTLESCROLLS_STAT_ULT_SPENT, nil)
        assert_eq(rows.BATTLESCROLLS_STAT_ULT_LOST, nil)
        assert_eq(rows.BATTLESCROLLS_STAT_ULT_SPENT_DRAINED.sublabel, "500")
    end)
end)
