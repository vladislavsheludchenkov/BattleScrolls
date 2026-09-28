-- Release history is data, but missing translations or truncated paragraphs
-- silently remove information in-game. Exercise real locale files/rendering.
local function releaseEnv(language)
    local values, translated = {}, {}
    local env = setmetatable({
        BattleScrolls = { journal = {}, storage = { savedVariables = { history = {} } } },
        SemisPlaygroundCheckAccess = function() return true end,
    }, { __index = _G })
    env.ZO_CreateStringId = function(name, text)
        env[name] = name
        values[name] = text
    end
    env.SafeAddString = function(id, text)
        assert(id, "translation references an undefined string ID")
        values[id] = text
        translated[id] = true
    end
    env.GetString = function(id) return values[id] or "" end
    local function load(path) assert(loadfile(path, "t", env))() end
    load("BattleScrolls/lang/default.lua")
    if language ~= "default" then load("BattleScrolls/lang/" .. language .. ".lua") end
    env.ZO_GamepadEntryData = {
        New = function(_, text, icon)
            return {
                text = text, icon = icon,
                AddSubLabel = function(self, label) self.sublabel = label end,
                SetIconTintOnSelection = function() end,
                SetIconDisabledTintOnSelection = function() end,
                SetLocked = function() end,
                SetHeader = function() end,
            }
        end,
    }
    load("BattleScrolls/ui/journal/entry_builder.lua")
    load("BattleScrolls/ui/journal/whats_new.lua")
    return env, translated, load
end

local function listMock()
    return {
        dataList = {}, selectedIndex = 1,
        Clear = function(self) self.dataList = {} end,
        AddEntry = function(self, _, entry) self.dataList[#self.dataList + 1] = entry end,
        AddEntryWithHeader = function(self, _, entry) self.dataList[#self.dataList + 1] = entry end,
        Commit = function() end,
        GetNumEntries = function(self) return #self.dataList end,
        GetSelectedData = function(self) return self.dataList[self.selectedIndex] end,
        GetTargetData = function(self) return self.dataList[self.selectedIndex] end,
        SetSelectedIndexWithoutAnimation = function(self, index) self.selectedIndex = index end,
    }
end

local function normalized(text) return text:gsub("%s+", " "):match("^%s*(.-)%s*$") end

-- Publishing notes stay plain text and may be condensed to fit the limit;
-- the in-game edition keeps the full detail with color and spacing.
-- The ASCII replacement avoids loading ESO's large fallback font for U+2192.
local function publishingText(text)
    return normalized(text:gsub("|c%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub(string.char(0xE2, 0x86, 0x92), "->"))
end

-- Release assets live at the root after exporting to the public repository.
local releaseNotesDir = "release-assets/release-notes/"
local publicManifest = io.open("BattleScrolls/BattleScrolls.addon")
if publicManifest then
    publicManifest:close()
    releaseNotesDir = "release-notes/"
end

local function readFile(path)
    local file = assert(io.open(path))
    local text = file:read("*a")
    file:close()
    return text
end

describe("What's New", function()
    it("keeps the publishing notes under Bethesda's 2000-character limit", function()
        local notes = readFile(releaseNotesDir .. "v6.0.0.txt")
        assert_true(utf8.len(notes) < 2000)
        assert_true(io.open(releaseNotesDir .. "v5.4.0.txt") == nil)
    end)

    it("includes only the published history plus the dated major release", function()
        local env = releaseEnv("default")
        local releases = env.BattleScrolls.journal.whatsNew.releases
        assert_eq(#releases, 28)
        assert_eq(releases[1].version, "6.0.0")
        assert_eq(releases[1].date, "2026-09-28")
        assert_eq(releases[2].version, "5.3.1")
        assert_eq(releases[2].date, "2026-06-08")
        assert_eq(releases[#releases].date, "2026-01-18")
        local seen, lastDate = {}, "9999-12-31"
        for _, release in ipairs(releases) do
            assert_true(not seen[release.version], "duplicate version")
            seen[release.version] = true
            assert_true(release.date:match("^%d%d%d%d%-%d%d%-%d%d$"))
            assert_true(release.date <= lastDate, "release dates must be newest first")
            lastDate = release.date
            assert_true(release.version ~= "5.4.0")
            local published = readFile(releaseNotesDir .. "v" .. release.version .. ".txt")
            assert_true(#normalized(published) > 0)
            -- v6 has a condensed publishing edition; older releases match.
            if release.version ~= "6.0.0" then
                assert_eq(publishingText(env.GetString(release.notesId)), publishingText(published))
            end
        end
    end)

    for _, language in ipairs({ "default", "de", "es", "fr", "jp", "ru", "zh" }) do
        it("renders every release completely in " .. language, function()
            local env, translated = releaseEnv(language)
            local journal = env.BattleScrolls.journal
            local ui = { whatsNewList = listMock(), RefreshTargetTooltip = function(self, row) self.target = row end }
            journal.whatsNew.refresh(ui)
            assert_eq(ui.target.text, "6.0.0")
            for i, release in ipairs(journal.whatsNew.releases) do
                local notes = env.GetString(release.notesId)
                assert_true(notes:find("|c", 1, true) ~= nil, "release has no formatting: " .. release.version)
                assert_true(notes:find(string.char(0xE2, 0x86, 0x92), 1, true) == nil,
                    "release contains the font-loading U+2192 glyph")
                local unformatted = notes:gsub("|c%x%x%x%x%x%x", ""):gsub("|r", "")
                assert_true(unformatted:find("|", 1, true) == nil, "invalid release markup")
                local colorOpen = false
                local plain = notes:gsub("|c%x%x%x%x%x%x", "|c")
                for token in plain:gmatch("|.") do
                    if token == "|c" then
                        assert_true(not colorOpen, "nested release color")
                        colorOpen = true
                    elseif token == "|r" then
                        assert_true(colorOpen, "release color reset without an opening tag")
                        colorOpen = false
                    else
                        error("unsupported release markup: " .. token)
                    end
                end
                assert_true(not colorOpen, "release color is not reset")
                if language ~= "default" then
                    assert_true(translated[release.notesId], "missing translation: " .. release.version)
                    assert_true(translated[env.BATTLESCROLLS_WHATS_NEW])
                    assert_true(translated[env.BATTLESCROLLS_WHATS_NEW_DESC])
                end
                local row = ui.whatsNewList.dataList[i]
                assert_eq(row.sublabel, release.date)
                local paragraphs = {}
                local column = {
                    PlainTextRow = function(_, text) paragraphs[#paragraphs + 1] = text; return {} end,
                    Section = function() return {} end,
                    mount = function() end,
                }
                row.tooltip.panelSpec.build(column)
                -- The date is a separate final row creation; the body must survive
                -- splitting intact, including the longest historical release.
                assert_eq(table.remove(paragraphs), release.date)
                assert_eq(normalized(table.concat(paragraphs, "\n\n")), normalized(env.GetString(release.notesId)))
                assert_true(#normalized(env.GetString(release.notesId)) > 0)
            end
        end)
    end

    it("skips What's New, Settings and Aggregate to select the newest real instance", function()
        local env, _, load = releaseEnv("default")
        local journal = env.BattleScrolls.journal
        journal.InstanceTab = { ALL = 1 }
        journal.utils = { getInstanceIcon = function() end, getTimeGroupHeader = function() return "Today" end }
        env.BattleScrolls.utils = { formatTime = function() return "12:00" end }
        local history = { { zone = "Older", timestampS = 1 }, { zone = "Newest", timestampS = 2 } }
        env.BattleScrolls.storage.savedVariables.history = history
        load("BattleScrolls/ui/journal/controllers/instance_list.lua")
        local ui = { instanceList = listMock(), defaultInstancePosition = 4 }
        journal.controllers.instanceList.refresh(ui)
        assert_true(ui.instanceList.dataList[1].isWhatsNew)
        assert_true(ui.instanceList.dataList[2].isSettings)
        assert_true(ui.instanceList.dataList[3].isPivot)
        assert_eq(ui.instanceList:GetSelectedData().data, history[2])
        assert_eq(ui.defaultInstancePosition, nil)
    end)

    it("uses Aggregate when there are no instances yet", function()
        local env, _, load = releaseEnv("default")
        local journal = env.BattleScrolls.journal
        journal.InstanceTab, journal.utils = { ALL = 1 }, {}
        load("BattleScrolls/ui/journal/controllers/instance_list.lua")
        local ui = { instanceList = listMock(), defaultInstancePosition = 4 }
        journal.controllers.instanceList.refresh(ui)
        assert_true(ui.instanceList:GetSelectedData().isPivot)
        assert_eq(ui.defaultInstancePosition, 4)
    end)

    it("opens the release reader and returns to the selected journal tab and row", function()
        local env, _, load = releaseEnv("default")
        local journal = env.BattleScrolls.journal
        journal.NavigationMode = { INSTANCES = 1, WHATS_NEW = 7 }
        journal.InstanceTab = { ALL = 1 }
        env.GetTimeStamp, env.GetGameTimeMilliseconds = function() return 0 end, function() return 0 end
        env.EVENT_MANAGER = { RegisterForUpdate = function() end, RegisterForEvent = function() end }
        env.SOUNDS = {}
        env.ZO_Gamepad_AddBackNavigationKeybindDescriptors = function() end
        env.ZO_ConveyorSceneFragment_SetMovingForward = function() end
        env.ZO_ConveyorSceneFragment_SetMovingBackward = function() end
        load("BattleScrolls/ui/journal/keybinds.lua")
        local ui = {
            mode = 1, selectedInstanceTab = 4,
            instanceList = listMock(), whatsNewList = listMock(),
            SetCurrentList = function(self, list) self.currentList = list end,
            SetActiveKeybinds = function(self, keys) self.keys = keys end,
            RefreshList = function() end,
        }
        ui.instanceList.dataList[1] = { isWhatsNew = true }
        journal.keybinds.initializeKeybindStripDescriptors(ui)
        assert_true(ui.instanceKeybindStripDescriptor[1].enabled())
        ui.instanceKeybindStripDescriptor[1].callback()
        assert_eq(ui.mode, 7)
        assert_eq(ui.currentList, ui.whatsNewList)
        assert_eq(ui.keys, ui.whatsNewKeybindStripDescriptor)
        ui.whatsNewKeybindStripDescriptor[1].callback()
        assert_eq(ui.mode, 1)
        assert_eq(ui.currentList, ui.instanceList)
        assert_eq(ui.keys, ui.instanceKeybindStripDescriptor)
        assert_eq(ui.pendingTabIndex, 4)
        assert_true(ui.instanceList:GetSelectedData().isWhatsNew)
    end)
end)
