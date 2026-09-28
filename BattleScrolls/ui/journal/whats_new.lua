---@diagnostic disable: undefined-field, inject-field -- ESO UI control stubs are incomplete
if not SemisPlaygroundCheckAccess() then return end

local journal = BattleScrolls.journal

---@class JournalRelease
---@field version string
---@field date string ISO calendar date, independent of player timezone
---@field notesId number Localized full release notes

local whatsNew = {}

---@type JournalRelease[]
whatsNew.releases = {
    { version = "6.0.0", date = "2026-09-28", notesId = BATTLESCROLLS_RELEASE_6_0_0 },
    { version = "5.3.1", date = "2026-06-08", notesId = BATTLESCROLLS_RELEASE_5_3_1 },
    { version = "5.3.0", date = "2026-05-31", notesId = BATTLESCROLLS_RELEASE_5_3_0 },
    { version = "5.2.0", date = "2026-05-24", notesId = BATTLESCROLLS_RELEASE_5_2_0 },
    { version = "5.1.0", date = "2026-05-03", notesId = BATTLESCROLLS_RELEASE_5_1_0 },
    { version = "5.0.0", date = "2026-04-17", notesId = BATTLESCROLLS_RELEASE_5_0_0 },
    { version = "4.0.0", date = "2026-04-05", notesId = BATTLESCROLLS_RELEASE_4_0_0 },
    { version = "3.1.0", date = "2026-03-27", notesId = BATTLESCROLLS_RELEASE_3_1_0 },
    { version = "3.0.2", date = "2026-03-27", notesId = BATTLESCROLLS_RELEASE_3_0_2 },
    { version = "3.0.1", date = "2026-03-27", notesId = BATTLESCROLLS_RELEASE_3_0_1 },
    { version = "3.0.0", date = "2026-03-26", notesId = BATTLESCROLLS_RELEASE_3_0_0 },
    { version = "2.1.2", date = "2026-03-22", notesId = BATTLESCROLLS_RELEASE_2_1_2 },
    { version = "2.1.1", date = "2026-03-10", notesId = BATTLESCROLLS_RELEASE_2_1_1 },
    { version = "2.1.0", date = "2026-03-04", notesId = BATTLESCROLLS_RELEASE_2_1_0 },
    { version = "2.0.1", date = "2026-02-28", notesId = BATTLESCROLLS_RELEASE_2_0_1 },
    { version = "1.3.6", date = "2026-02-24", notesId = BATTLESCROLLS_RELEASE_1_3_6 },
    { version = "1.3.5", date = "2026-02-24", notesId = BATTLESCROLLS_RELEASE_1_3_5 },
    { version = "1.3.4", date = "2026-02-22", notesId = BATTLESCROLLS_RELEASE_1_3_4 },
    { version = "1.3.3", date = "2026-02-17", notesId = BATTLESCROLLS_RELEASE_1_3_3 },
    { version = "1.3.2", date = "2026-02-09", notesId = BATTLESCROLLS_RELEASE_1_3_2 },
    { version = "1.3.1", date = "2026-02-08", notesId = BATTLESCROLLS_RELEASE_1_3_1 },
    { version = "1.3.0", date = "2026-02-01", notesId = BATTLESCROLLS_RELEASE_1_3_0 },
    { version = "1.2.0", date = "2026-01-25", notesId = BATTLESCROLLS_RELEASE_1_2_0 },
    { version = "1.1.0", date = "2026-01-24", notesId = BATTLESCROLLS_RELEASE_1_1_0 },
    { version = "1.0.3", date = "2026-01-23", notesId = BATTLESCROLLS_RELEASE_1_0_3 },
    { version = "1.0.2", date = "2026-01-22", notesId = BATTLESCROLLS_RELEASE_1_0_2 },
    { version = "1.0.1", date = "2026-01-18", notesId = BATTLESCROLLS_RELEASE_1_0_1 },
    { version = "1.0.0", date = "2026-01-18", notesId = BATTLESCROLLS_RELEASE_1_0_0 },
}

---@param release JournalRelease
---@return PanelSpec
local function releasePanel(release)
    return {
        layout = "reading",
        build = function(column)
            ---@type Control[]
            local paragraphs = {}
            local notes = GetString(release.notesId)
            for paragraph in (notes .. "\n\n"):gmatch("(.-)\n%s*\n") do
                paragraphs[#paragraphs + 1] = column:PlainTextRow(paragraph)
            end
            column:mount(24, 0, column:Section(release.version,
                column:PlainTextRow(release.date), paragraphs))
        end,
    }
end

---@param journalUI BattleScrolls_Journal_Gamepad
function whatsNew.refresh(journalUI)
    local list = journalUI.whatsNewList
    list:Clear()
    for _, release in ipairs(whatsNew.releases) do
        journal.EntryBuilder.addEntry(list, {
            label = release.version,
            sublabel = release.date,
            tooltip = { type = "panel", panelSpec = releasePanel(release) },
        })
    end
    list:Commit()
    journalUI:RefreshTargetTooltip(list:GetTargetData())
end

journal.whatsNew = whatsNew
