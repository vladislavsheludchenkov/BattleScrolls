-----------------------------------------------------------
-- Settings Renderer
-- Standalone renderer for settings list population
--
-- Unlike other renderers, settings don't receive a render context.
-- Instead, settings are accessed via BattleScrolls.storage and
-- require a refresh callback for list updates.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal

local SettingsRenderer = {}

---Builds a text tooltip descriptor matching the dispatch format used by chronicler
---@param title string|nil
---@param text string|nil
---@return TooltipDescriptor|nil
local function textTooltip(title, text)
    if not text then return nil end
    return { type = "text", title = title or "", text = text }
end

-------------------------
-- Section Helpers
-------------------------

---Renders DPS Meter personal settings (linger, enabled, mode, design, offsets, scale)
---@return boolean personalEnabled
local function renderDpsMeterPersonalSettings(list, settings, defaults, onRefresh)
    -- Callback to show personal DPS meter preview when offset changes
    local function onPersonalOffsetChanged()
        if BattleScrolls.dpsMeter then
            BattleScrolls.dpsMeter:ApplyPersonalOffsets()
            BattleScrolls.dpsMeter:ApplyGroupPosition()
            BattleScrolls.dpsMeter:ShowPreview()
        end
    end

    -- DPS Meter section header + Linger duration
    local lingerData = {
        text = GetString(BATTLESCROLLS_SETTINGS_KEEP_AFTER_COMBAT),
        header = GetString(BATTLESCROLLS_SETTINGS_DPS_METER),
        valid = { 0, 10000, 30000, 120000, 300000, -1 },
        valueStrings = { GetString(BATTLESCROLLS_SETTINGS_HIDE_IMMEDIATELY), GetString(BATTLESCROLLS_SETTINGS_10_SECONDS), GetString(BATTLESCROLLS_SETTINGS_30_SECONDS), GetString(BATTLESCROLLS_SETTINGS_2_MINUTES), GetString(BATTLESCROLLS_SETTINGS_5_MINUTES), GetString(BATTLESCROLLS_SETTINGS_UNTIL_RELOAD) },
        getFunction = function()
            return settings and settings.dpsMeterLingerMs or defaults.dpsMeterLingerMs
        end,
        setFunction = function(value)
            if settings then
                local oldValue = settings.dpsMeterLingerMs
                settings.dpsMeterLingerMs = value
                if oldValue ~= value and BattleScrolls.dpsMeter then
                    BattleScrolls.dpsMeter:OnLingerSettingChanged()
                end
            end
        end,
    }
    list:AddEntry("ZO_GamepadHorizontalListRowWithHeader", lingerData)

    -- Personal Meter section
    local personalEnabledData = {
        text = GetString(BATTLESCROLLS_SETTINGS_ENABLED),
        header = GetString(BATTLESCROLLS_SETTINGS_PERSONAL_METER),
        getFunction = function()
            return settings and settings.dpsMeterPersonalEnabled ~= false
        end,
        setFunction = function(value)
            if settings then
                local oldValue = settings.dpsMeterPersonalEnabled ~= false
                settings.dpsMeterPersonalEnabled = value
                if oldValue ~= value and BattleScrolls.dpsMeter then
                    BattleScrolls.dpsMeter:ApplyGroupPosition()
                    BattleScrolls.dpsMeter:ShowPreview()
                end
                -- Refresh list to update group position dropdown visibility
                onRefresh()
            end
        end,
        toggleFunction = function()
            if settings then
                local oldValue = settings.dpsMeterPersonalEnabled ~= false
                settings.dpsMeterPersonalEnabled = not oldValue
                if BattleScrolls.dpsMeter then
                    BattleScrolls.dpsMeter:ApplyGroupPosition()
                    BattleScrolls.dpsMeter:ShowPreview()
                end
                -- Refresh list to update group position dropdown visibility
                onRefresh()
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRowWithHeader", personalEnabledData)

    -- Only show personal meter settings when enabled
    local personalEnabled = settings and settings.dpsMeterPersonalEnabled ~= false
    if personalEnabled then
        -- Mode dropdown (affects personal meter display)
        local currentMode = settings and settings.dpsMeterPersonalMode or defaults.dpsMeterPersonalMode
        local dpsMeterModeData = {
            text = GetString(BATTLESCROLLS_SETTINGS_MODE),
            valid = { "auto", "damage", "healing" },
            valueStrings = { GetString(BATTLESCROLLS_SETTINGS_MODE_AUTO), GetString(BATTLESCROLLS_SETTINGS_MODE_DAMAGE), GetString(BATTLESCROLLS_SETTINGS_MODE_HEALING) },
            tooltip = currentMode == "auto" and textTooltip(GetString(BATTLESCROLLS_SETTINGS_AUTO_MODE_TITLE), GetString(BATTLESCROLLS_SETTINGS_AUTO_MODE_TEXT)) or nil,
            getFunction = function()
                return settings and settings.dpsMeterPersonalMode or defaults.dpsMeterPersonalMode
            end,
            setFunction = function(value)
                if settings and settings.dpsMeterPersonalMode ~= value then
                    settings.dpsMeterPersonalMode = value
                    onRefresh()
                end
            end,
        }
        list:AddEntry("ZO_GamepadHorizontalListRow", dpsMeterModeData)

        -- Get personal designs from registry
        local personalDesignIds = BattleScrolls.dpsMeterDesigns.GetPersonalDesignIds()
        local personalDesignNames = {}
        for _, id in ipairs(personalDesignIds) do
            local design = BattleScrolls.dpsMeterDesigns.GetPersonalDesign(id)
            table.insert(personalDesignNames, design and design.displayName or id)
        end

        local personalDesignData = {
            text = GetString(BATTLESCROLLS_SETTINGS_DESIGN),
            valid = personalDesignIds,
            valueStrings = personalDesignNames,
            getFunction = function()
                return settings and settings.dpsMeterPersonalDesign or defaults.dpsMeterPersonalDesign
            end,
            setFunction = function(value)
                if settings and settings.dpsMeterPersonalDesign ~= value then
                    settings.dpsMeterPersonalDesign = value
                    if BattleScrolls.dpsMeter then
                        BattleScrolls.dpsMeter:ApplyPersonalDesign()
                        BattleScrolls.dpsMeter:ApplyGroupPosition()
                        BattleScrolls.dpsMeter:ShowPreview()
                    end
                    -- Refresh list to show/hide design-specific settings
                    onRefresh()
                end
            end,
        }
        list:AddEntry("ZO_GamepadHorizontalListRow", personalDesignData)

        -- Add design-specific settings for current personal design
        local currentPersonalDesignId = settings and settings.dpsMeterPersonalDesign or defaults.dpsMeterPersonalDesign
        local currentPersonalDesign = BattleScrolls.dpsMeterDesigns.GetPersonalDesign(currentPersonalDesignId)
        if currentPersonalDesign and currentPersonalDesign.settings then
            for _, settingDef in ipairs(currentPersonalDesign.settings) do
                local settingData = {
                    text = settingDef.displayName,
                    valid = settingDef.options,
                    valueStrings = settingDef.optionLabels or settingDef.options,
                    tooltip = textTooltip(settingDef.tooltipTitle, settingDef.tooltipText),
                    getFunction = function()
                        return BattleScrolls.dpsMeterDesigns.GetPersonalDesignSetting(currentPersonalDesignId, settingDef.id)
                    end,
                    setFunction = function(value)
                        local currentValue = BattleScrolls.dpsMeterDesigns.GetPersonalDesignSetting(currentPersonalDesignId, settingDef.id)
                        if currentValue ~= value then
                            BattleScrolls.dpsMeterDesigns.SetPersonalDesignSetting(currentPersonalDesignId, settingDef.id, value)
                            if currentPersonalDesign.OnSettingChanged then
                                currentPersonalDesign:OnSettingChanged(settingDef.id, value)
                            end
                            if BattleScrolls.dpsMeter then
                                BattleScrolls.dpsMeter:ShowPreview()
                            end
                        end
                    end,
                }
                list:AddEntry("ZO_GamepadHorizontalListRow", settingData)
            end
        end

        -- Personal offset X slider
        local personalOffsetXData = {
            text = GetString(BATTLESCROLLS_SETTINGS_OFFSET_FROM_LEFT),
            minValue = -400,
            maxValue = 2000,
            showValue = true,
            gamepadValueStepPercent = 0.1,        -- Precision mode (hold button)
            gamepadValueStepPercentFast = 3,      -- Fast mode (default)
            getFunction = function()
                return settings and settings.dpsMeterPersonalOffsetX or defaults.dpsMeterPersonalOffsetX
            end,
            setFunction = function(value)
                if settings then
                    settings.dpsMeterPersonalOffsetX = value
                end
            end,
            onChangeFunction = onPersonalOffsetChanged,
        }
        list:AddEntry("ZO_GamepadOptionsSliderRow", personalOffsetXData)

        -- Personal offset Y slider
        local personalOffsetYData = {
            text = GetString(BATTLESCROLLS_SETTINGS_OFFSET_FROM_TOP),
            minValue = -120,
            maxValue = 1250,
            showValue = true,
            gamepadValueStepPercent = 0.1,        -- Precision mode (hold button)
            gamepadValueStepPercentFast = 5,      -- Fast mode (default)
            getFunction = function()
                return settings and settings.dpsMeterPersonalOffsetY or defaults.dpsMeterPersonalOffsetY
            end,
            setFunction = function(value)
                if settings then
                    settings.dpsMeterPersonalOffsetY = value
                end
            end,
            onChangeFunction = onPersonalOffsetChanged,
        }
        list:AddEntry("ZO_GamepadOptionsSliderRow", personalOffsetYData)

        -- Personal scale dropdown
        local personalScaleData = {
            text = GetString(BATTLESCROLLS_SETTINGS_SIZE),
            valid = { 0.5, 0.75, 1.0, 1.25, 1.5 },
            valueStrings = { GetString(BATTLESCROLLS_SETTINGS_SIZE_EXTRA_SMALL), GetString(BATTLESCROLLS_SETTINGS_SIZE_SMALL), GetString(BATTLESCROLLS_SETTINGS_SIZE_MEDIUM), GetString(BATTLESCROLLS_SETTINGS_SIZE_LARGE), GetString(BATTLESCROLLS_SETTINGS_SIZE_EXTRA_LARGE) },
            getFunction = function()
                return settings and settings.dpsMeterPersonalScale or defaults.dpsMeterPersonalScale
            end,
            setFunction = function(value)
                if settings and settings.dpsMeterPersonalScale ~= value then
                    settings.dpsMeterPersonalScale = value
                    if BattleScrolls.dpsMeter then
                        BattleScrolls.dpsMeter:ApplyPersonalScale()
                        BattleScrolls.dpsMeter:ShowPreview()
                    end
                end
            end,
        }
        list:AddEntry("ZO_GamepadHorizontalListRow", personalScaleData)

        -- Reset personal position button
        local resetPersonalPositionData = {
            text = GetString(BATTLESCROLLS_SETTINGS_RESET_POSITION),
            callback = function()
                if settings then
                    settings.dpsMeterPersonalOffsetX = defaults.dpsMeterPersonalOffsetX
                    settings.dpsMeterPersonalOffsetY = defaults.dpsMeterPersonalOffsetY
                    onPersonalOffsetChanged()
                    onRefresh()
                end
            end,
        }
        list:AddEntry("ZO_GamepadOptionsLabelRow", resetPersonalPositionData)
    end

    return personalEnabled
end

---Renders DPS Meter group settings (enabled, show solo, design, position, offsets, scale)
local function renderDpsMeterGroupSettings(list, settings, defaults, onRefresh, personalEnabled)
    -- Callback to show group DPS meter preview when offset changes
    local function onGroupOffsetChanged()
        if BattleScrolls.dpsMeter then
            BattleScrolls.dpsMeter:ApplyGroupPosition()
            BattleScrolls.dpsMeter:ShowPreview()
        end
    end

    local groupEnabledData = {
        text = GetString(BATTLESCROLLS_SETTINGS_ENABLED),
        header = GetString(BATTLESCROLLS_SETTINGS_GROUP_METER),
        tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_GROUP_METER), GetString(BATTLESCROLLS_SETTINGS_GROUP_METER_TEXT)),
        getFunction = function()
            return settings and settings.dpsMeterGroupEnabled ~= false
        end,
        setFunction = function(value)
            if settings then
                local oldValue = settings.dpsMeterGroupEnabled ~= false
                settings.dpsMeterGroupEnabled = value
                if oldValue ~= value and BattleScrolls.dpsMeter then
                    BattleScrolls.dpsMeter:ShowPreview()
                end
                -- Refresh list to show/hide group settings
                onRefresh()
            end
        end,
        toggleFunction = function()
            if settings then
                local oldValue = settings.dpsMeterGroupEnabled ~= false
                settings.dpsMeterGroupEnabled = not oldValue
                if BattleScrolls.dpsMeter then
                    BattleScrolls.dpsMeter:ShowPreview()
                end
                -- Refresh list to show/hide group settings
                onRefresh()
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRowWithHeader", groupEnabledData)

    -- Only show group meter settings when enabled
    local groupEnabled = settings and settings.dpsMeterGroupEnabled ~= false
    if not groupEnabled then return end

    -- Show Without Group Data toggle (show group meter when only you have data)
    local groupShowSoloData = {
        text = GetString(BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA),
        tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA), GetString(BATTLESCROLLS_SETTINGS_SHOW_WITHOUT_GROUP_DATA_TEXT)),
        getFunction = function()
            return settings and settings.dpsMeterGroupShowSolo == true
        end,
        setFunction = function(value)
            if settings then
                settings.dpsMeterGroupShowSolo = value
                if BattleScrolls.dpsMeter then
                    BattleScrolls.dpsMeter:ShowPreview()
                end
            end
        end,
        toggleFunction = function()
            if settings then
                settings.dpsMeterGroupShowSolo = not (settings.dpsMeterGroupShowSolo == true)
                if BattleScrolls.dpsMeter then
                    BattleScrolls.dpsMeter:ShowPreview()
                end
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRow", groupShowSoloData)

    -- Get group designs from registry
    local groupDesignIds = BattleScrolls.dpsMeterDesigns.GetGroupDesignIds()
    local groupDesignNames = {}
    for _, id in ipairs(groupDesignIds) do
        local design = BattleScrolls.dpsMeterDesigns.GetGroupDesign(id)
        table.insert(groupDesignNames, design and design.displayName or id)
    end

    -- Get description for current design
    local currentGroupDesignId = settings and settings.dpsMeterGroupDesign or defaults.dpsMeterGroupDesign
    local currentGroupDesign = BattleScrolls.dpsMeterDesigns.GetGroupDesign(currentGroupDesignId)

    local groupDesignData = {
        text = GetString(BATTLESCROLLS_SETTINGS_DESIGN),
        valid = groupDesignIds,
        valueStrings = groupDesignNames,
        tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_GROUP_TRACKER_DESIGN), currentGroupDesign and currentGroupDesign.description or nil),
        getFunction = function()
            return settings and settings.dpsMeterGroupDesign or defaults.dpsMeterGroupDesign
        end,
        setFunction = function(value)
            if settings and settings.dpsMeterGroupDesign ~= value then
                settings.dpsMeterGroupDesign = value
                if BattleScrolls.dpsMeter then
                    BattleScrolls.dpsMeter:ApplyGroupDesign()
                    BattleScrolls.dpsMeter:ShowPreview()
                end
                -- Refresh list to show/hide design-specific settings
                onRefresh()
            end
        end,
    }
    list:AddEntry("ZO_GamepadHorizontalListRow", groupDesignData)

    -- Add design-specific settings for current group design
    if currentGroupDesign and currentGroupDesign.settings then
        for _, settingDef in ipairs(currentGroupDesign.settings) do
            local settingData = {
                text = settingDef.displayName,
                valid = settingDef.options,
                valueStrings = settingDef.optionLabels or settingDef.options,
                tooltip = textTooltip(settingDef.tooltipTitle, settingDef.tooltipText),
                getFunction = function()
                    return BattleScrolls.dpsMeterDesigns.GetGroupDesignSetting(currentGroupDesignId, settingDef.id)
                end,
                setFunction = function(value)
                    local currentValue = BattleScrolls.dpsMeterDesigns.GetGroupDesignSetting(currentGroupDesignId, settingDef.id)
                    if currentValue ~= value then
                        BattleScrolls.dpsMeterDesigns.SetGroupDesignSetting(currentGroupDesignId, settingDef.id, value)
                        if currentGroupDesign.OnSettingChanged then
                            currentGroupDesign:OnSettingChanged(settingDef.id, value)
                        end
                        if BattleScrolls.dpsMeter then
                            BattleScrolls.dpsMeter:ShowPreview()
                        end
                    end
                end,
            }
            list:AddEntry("ZO_GamepadHorizontalListRow", settingData)
        end
    end

    -- Group position dropdown (only shown when personal is also enabled)
    if personalEnabled then
        local groupPositionData = {
            text = GetString(BATTLESCROLLS_SETTINGS_POSITION),
            valid = { "below", "above", "separate" },
            valueStrings = { GetString(BATTLESCROLLS_SETTINGS_POSITION_BELOW), GetString(BATTLESCROLLS_SETTINGS_POSITION_ABOVE), GetString(BATTLESCROLLS_SETTINGS_POSITION_SEPARATE) },
            tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_GROUP_TRACKER_POSITION), GetString(BATTLESCROLLS_SETTINGS_GROUP_TRACKER_POSITION_TEXT)),
            getFunction = function()
                return settings and settings.dpsMeterGroupPosition or defaults.dpsMeterGroupPosition
            end,
            setFunction = function(value)
                if settings and settings.dpsMeterGroupPosition ~= value then
                    settings.dpsMeterGroupPosition = value
                    if BattleScrolls.dpsMeter then
                        BattleScrolls.dpsMeter:ApplyGroupPosition()
                        BattleScrolls.dpsMeter:ShowPreview()
                    end
                    -- Refresh list to show/hide separate offset controls
                    onRefresh()
                end
            end,
        }
        list:AddEntry("ZO_GamepadHorizontalListRow", groupPositionData)
    end

    -- Group offset controls (shown when personal is disabled OR position is "separate")
    local groupPosition = settings and settings.dpsMeterGroupPosition or defaults.dpsMeterGroupPosition
    local showGroupOffsets = not personalEnabled or groupPosition == "separate"
    if showGroupOffsets then
        -- Group offset X slider
        local groupOffsetXData = {
            text = GetString(BATTLESCROLLS_SETTINGS_OFFSET_FROM_LEFT),
            minValue = -400,
            maxValue = 2000,
            showValue = true,
            gamepadValueStepPercent = 0.1,        -- Precision mode (hold button)
            gamepadValueStepPercentFast = 3,      -- Fast mode (default)
            getFunction = function()
                return settings and settings.dpsMeterGroupOffsetX or defaults.dpsMeterGroupOffsetX
            end,
            setFunction = function(value)
                if settings then
                    settings.dpsMeterGroupOffsetX = value
                end
            end,
            onChangeFunction = onGroupOffsetChanged,
        }
        list:AddEntry("ZO_GamepadOptionsSliderRow", groupOffsetXData)

        -- Group offset Y slider
        local groupOffsetYData = {
            text = GetString(BATTLESCROLLS_SETTINGS_OFFSET_FROM_TOP),
            minValue = -120,
            maxValue = 1250,
            showValue = true,
            gamepadValueStepPercent = 0.1,        -- Precision mode (hold button)
            gamepadValueStepPercentFast = 5,      -- Fast mode (default)
            getFunction = function()
                return settings and settings.dpsMeterGroupOffsetY or defaults.dpsMeterGroupOffsetY
            end,
            setFunction = function(value)
                if settings then
                    settings.dpsMeterGroupOffsetY = value
                end
            end,
            onChangeFunction = onGroupOffsetChanged,
        }
        list:AddEntry("ZO_GamepadOptionsSliderRow", groupOffsetYData)

        -- Reset group position button
        local resetGroupPositionData = {
            text = GetString(BATTLESCROLLS_SETTINGS_RESET_POSITION),
            callback = function()
                if settings then
                    settings.dpsMeterGroupOffsetX = defaults.dpsMeterGroupOffsetX
                    settings.dpsMeterGroupOffsetY = defaults.dpsMeterGroupOffsetY
                    onGroupOffsetChanged()
                    onRefresh()
                end
            end,
        }
        list:AddEntry("ZO_GamepadOptionsLabelRow", resetGroupPositionData)
    end

    -- Group scale dropdown
    local groupScaleData = {
        text = GetString(BATTLESCROLLS_SETTINGS_SIZE),
        valid = { 0.5, 0.75, 1.0, 1.25, 1.5 },
        valueStrings = { GetString(BATTLESCROLLS_SETTINGS_SIZE_EXTRA_SMALL), GetString(BATTLESCROLLS_SETTINGS_SIZE_SMALL), GetString(BATTLESCROLLS_SETTINGS_SIZE_MEDIUM), GetString(BATTLESCROLLS_SETTINGS_SIZE_LARGE), GetString(BATTLESCROLLS_SETTINGS_SIZE_EXTRA_LARGE) },
        getFunction = function()
            return settings and settings.dpsMeterGroupScale or defaults.dpsMeterGroupScale
        end,
        setFunction = function(value)
            if settings and settings.dpsMeterGroupScale ~= value then
                settings.dpsMeterGroupScale = value
                if BattleScrolls.dpsMeter then
                    BattleScrolls.dpsMeter:ApplyGroupScale()
                    BattleScrolls.dpsMeter:ShowPreview()
                end
            end
        end,
    }
    list:AddEntry("ZO_GamepadHorizontalListRow", groupScaleData)
end

---Renders recording settings (enabled, zone filters, fight type filters)
---@return boolean recordingEnabled
local function renderRecordingSettings(list, settings, defaults, onRefresh)
    local recordingEnabledData = {
        text = GetString(BATTLESCROLLS_SETTINGS_ENABLED),
        header = GetString(BATTLESCROLLS_SETTINGS_RECORDING),
        getFunction = function()
            return settings and settings.recordingEnabled ~= false
        end,
        setFunction = function(value)
            if settings then
                settings.recordingEnabled = value
                onRefresh()
            end
        end,
        toggleFunction = function()
            if settings then
                settings.recordingEnabled = not (settings.recordingEnabled ~= false)
                onRefresh()
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRowWithHeader", recordingEnabledData)

    -- Only show granular recording settings when recording is enabled
    local recordingEnabled = settings and settings.recordingEnabled ~= false
    if not recordingEnabled then return false end

    local function getZonesSet()
        return settings and settings.recordInZones or defaults.recordInZones
    end

    local function getFightsSet()
        return settings and settings.recordInFights or defaults.recordInFights
    end

    local recordInstancedData = {
        text = GetString(BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED),
        tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED), GetString(BATTLESCROLLS_SETTINGS_RECORD_IN_INSTANCED_TEXT) .. "\n\n" .. GetString(BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT)),
        getFunction = function()
            return getZonesSet().instanced == true
        end,
        toggleFunction = function()
            if settings then
                local zones = getZonesSet()
                zones.instanced = not zones.instanced
                settings.recordInZones = zones
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRow", recordInstancedData)

    local recordOverlandData = {
        text = GetString(BATTLESCROLLS_SETTINGS_RECORD_IN_OVERLAND),
        tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TITLE), GetString(BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT)),
        getFunction = function()
            return getZonesSet().overland == true
        end,
        toggleFunction = function()
            if settings then
                local zones = getZonesSet()
                zones.overland = not zones.overland
                settings.recordInZones = zones
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRow", recordOverlandData)

    local recordHouseData = {
        text = GetString(BATTLESCROLLS_SETTINGS_RECORD_IN_HOUSES),
        tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TITLE), GetString(BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT)),
        getFunction = function()
            return getZonesSet().house == true
        end,
        toggleFunction = function()
            if settings then
                local zones = getZonesSet()
                zones.house = not zones.house
                settings.recordInZones = zones
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRow", recordHouseData)

    local recordPvPData = {
        text = GetString(BATTLESCROLLS_SETTINGS_RECORD_IN_PVP),
        tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TITLE), GetString(BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT)),
        getFunction = function()
            return getZonesSet().pvp == true
        end,
        toggleFunction = function()
            if settings then
                local zones = getZonesSet()
                zones.pvp = not zones.pvp
                settings.recordInZones = zones
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRow", recordPvPData)

    if IsAdventureZoneActive and IsAdventureZoneActive() then
        local adventureZoneName = GetAdventureZoneDisplayName and GetAdventureZoneDisplayName() or ""
        local formattedName = zo_strformat("<<1>>", adventureZoneName)
        local recordAdventureZoneData = {
            text = formattedName,
            tooltip = textTooltip(formattedName, zo_strformat(GetString(BATTLESCROLLS_SETTINGS_RECORD_IN_ADVENTURE_ZONE_TEXT), adventureZoneName)),
            getFunction = function()
                if not settings or settings.recordInAdventureZone == nil then
                    return defaults.recordInAdventureZone
                end
                return settings.recordInAdventureZone == true
            end,
            toggleFunction = function()
                if settings then
                    local current = settings.recordInAdventureZone
                    if current == nil then current = defaults.recordInAdventureZone end
                    settings.recordInAdventureZone = not current
                end
            end,
        }
        list:AddEntry("ZO_GamepadOptionsCheckboxRow", recordAdventureZoneData)
    end

    local recordBossData = {
        text = GetString(BATTLESCROLLS_SETTINGS_RECORD_BOSS_FIGHTS),
        tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TITLE), GetString(BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT)),
        getFunction = function()
            return getFightsSet().boss == true
        end,
        toggleFunction = function()
            if settings then
                local fights = getFightsSet()
                fights.boss = not fights.boss
                settings.recordInFights = fights
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRow", recordBossData)

    local recordTrashData = {
        text = GetString(BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS),
        tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS), GetString(BATTLESCROLLS_SETTINGS_RECORD_TRASH_FIGHTS_TEXT) .. "\n\n" .. GetString(BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT)),
        getFunction = function()
            return getFightsSet().trash == true
        end,
        toggleFunction = function()
            if settings then
                local fights = getFightsSet()
                fights.trash = not fights.trash
                settings.recordInFights = fights
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRow", recordTrashData)

    local recordPlayerData = {
        text = GetString(BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS),
        tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS), GetString(BATTLESCROLLS_SETTINGS_RECORD_PLAYER_FIGHTS_TEXT) .. "\n\n" .. GetString(BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT)),
        getFunction = function()
            return getFightsSet().player == true
        end,
        toggleFunction = function()
            if settings then
                local fights = getFightsSet()
                fights.player = not fights.player
                settings.recordInFights = fights
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRow", recordPlayerData)

    local recordDummyData = {
        text = GetString(BATTLESCROLLS_SETTINGS_RECORD_DUMMY_FIGHTS),
        tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TITLE), GetString(BATTLESCROLLS_SETTINGS_RECORDING_FILTERS_TEXT)),
        getFunction = function()
            return getFightsSet().dummy == true
        end,
        toggleFunction = function()
            if settings then
                local fights = getFightsSet()
                fights.dummy = not fights.dummy
                settings.recordInFights = fights
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRow", recordDummyData)

    return true
end

---Renders storage size settings
local function renderStorageSettings(list, settings, defaults)
    -- Build valid keys and labels from presets
    local storageSizePresetKeys = {}
    local storageSizePresetLabels = {}
    for _, key in ipairs(BattleScrolls.storage.sizePresetOrder) do
        local preset = BattleScrolls.storage.sizePresets[key]
        table.insert(storageSizePresetKeys, key)
        table.insert(storageSizePresetLabels, GetString(_G[preset.labelStringId]))
    end

    local bytes, _, _ = BattleScrolls.storage:EstimateHistorySize()

    local storageSizeData = {}
    storageSizeData.text = GetString(BATTLESCROLLS_SETTINGS_HISTORY_SIZE_LIMIT)
    storageSizeData.valid = storageSizePresetKeys
    storageSizeData.valueStrings = storageSizePresetLabels
    storageSizeData.tooltip = { type = "text", title = GetString(BATTLESCROLLS_SETTINGS_HISTORY_SIZE_LIMIT_TITLE), text = "" }
    storageSizeData.refreshTooltipText = function()
        -- Calculate current usage for tooltip
        local currentPreset = BattleScrolls.storage:GetCurrentSizePreset()
        local usagePercent = currentPreset.memoryMB > 0 and (bytes / currentPreset.memoryMB / 1000000 * 100) or 0
        local memoryMB = bytes / 1000000  -- Approximate memory in MB

        storageSizeData.tooltip.text = table.concat({
            GetString(BATTLESCROLLS_SETTINGS_STORAGE_TT_DESC),
            "",
            GetString(BATTLESCROLLS_SETTINGS_STORAGE_TT_NOTE),
            "",
            zo_strformat(GetString(BATTLESCROLLS_SETTINGS_STORAGE_TT_CURRENT), string.format("%.1f", memoryMB), currentPreset.memoryMB, string.format("%.0f", usagePercent)),
            "",
            GetString(BATTLESCROLLS_SETTINGS_STORAGE_TT_PRESETS),
            GetString(BATTLESCROLLS_SETTINGS_STORAGE_TT_XS),
            GetString(BATTLESCROLLS_SETTINGS_STORAGE_TT_SMALL),
            GetString(BATTLESCROLLS_SETTINGS_STORAGE_TT_MEDIUM),
            GetString(BATTLESCROLLS_SETTINGS_STORAGE_TT_LARGE),
            GetString(BATTLESCROLLS_SETTINGS_STORAGE_TT_XL),
            GetString(BATTLESCROLLS_SETTINGS_STORAGE_TT_CAUTION),
            GetString(BATTLESCROLLS_SETTINGS_STORAGE_TT_YOLO),
            "",
            GetString(BATTLESCROLLS_SETTINGS_STORAGE_TT_WARNING),
        }, "\n")
    end
    storageSizeData.refreshTooltipText()

    storageSizeData.getFunction = function()
        return settings and settings.storageSizePreset or defaults.storageSizePreset
    end
    storageSizeData.setFunction = function(value)
        if settings then
            local oldValue = settings.storageSizePreset
            settings.storageSizePreset = value
            if oldValue ~= value then
                storageSizeData.refreshTooltipText()
                local selectedData = list:GetSelectedData()
                if selectedData and BattleScrolls.journalUI then
                    BattleScrolls.journalUI:RefreshTargetTooltip(list:GetSelectedData())
                end
            end
        end
    end

    list:AddEntry("ZO_GamepadHorizontalListRow", storageSizeData)
end

---Renders effect tracking settings (enabled, granular toggles, clear favorites)
---@return boolean effectTrackingEnabled
local function renderEffectTrackingSettings(list, settings, _defaults, onRefresh)
    local effectTrackingEnabledData = {
        text = GetString(BATTLESCROLLS_SETTINGS_ENABLED),
        header = GetString(BATTLESCROLLS_SETTINGS_EFFECT_TRACKING),
        getFunction = function()
            return settings and settings.effectTrackingEnabled ~= false
        end,
        setFunction = function(value)
            if settings then
                settings.effectTrackingEnabled = value
                onRefresh()
            end
        end,
        toggleFunction = function()
            if settings then
                settings.effectTrackingEnabled = not (settings.effectTrackingEnabled ~= false)
                onRefresh()
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRowWithHeader", effectTrackingEnabledData)

    -- Only show granular effect settings when effect tracking is enabled
    local effectTrackingEnabled = settings and settings.effectTrackingEnabled ~= false
    if effectTrackingEnabled then

    local trackPlayerBuffsData = {
        text = GetString(BATTLESCROLLS_SETTINGS_PLAYER_BUFFS),
        getFunction = function()
            return settings and settings.trackPlayerBuffs ~= false
        end,
        setFunction = function(value)
            if settings then
                settings.trackPlayerBuffs = value
            end
        end,
        toggleFunction = function()
            if settings then
                settings.trackPlayerBuffs = not (settings.trackPlayerBuffs ~= false)
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRow", trackPlayerBuffsData)

    local trackPlayerDebuffsData = {
        text = GetString(BATTLESCROLLS_SETTINGS_PLAYER_DEBUFFS),
        getFunction = function()
            return settings and settings.trackPlayerDebuffs ~= false
        end,
        setFunction = function(value)
            if settings then
                settings.trackPlayerDebuffs = value
            end
        end,
        toggleFunction = function()
            if settings then
                settings.trackPlayerDebuffs = not (settings.trackPlayerDebuffs ~= false)
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRow", trackPlayerDebuffsData)

    local trackGroupBuffsData = {
        text = GetString(BATTLESCROLLS_SETTINGS_GROUP_BUFFS),
        getFunction = function()
            return settings and settings.trackGroupBuffs ~= false
        end,
        setFunction = function(value)
            if settings then
                settings.trackGroupBuffs = value
            end
        end,
        toggleFunction = function()
            if settings then
                settings.trackGroupBuffs = not (settings.trackGroupBuffs ~= false)
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRow", trackGroupBuffsData)

    local trackBossDebuffsData = {
        text = GetString(BATTLESCROLLS_SETTINGS_BOSS_DEBUFFS),
        getFunction = function()
            return settings and settings.trackBossDebuffs ~= false
        end,
        setFunction = function(value)
            if settings then
                settings.trackBossDebuffs = value
            end
        end,
        toggleFunction = function()
            if settings then
                settings.trackBossDebuffs = not (settings.trackBossDebuffs ~= false)
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRow", trackBossDebuffsData)

    end -- if effectTrackingEnabled

    -- Clear All Favorites button (only shown when favorites exist)
    local favorites = settings and settings.favoriteEffects
    if favorites and next(favorites) ~= nil then
        local clearFavoritesData = {
            text = GetString(BATTLESCROLLS_CLEAR_ALL_FAVORITES),
            tooltip = textTooltip(GetString(BATTLESCROLLS_CLEAR_ALL_FAVORITES), GetString(BATTLESCROLLS_CLEAR_ALL_FAVORITES_TOOLTIP)),
            callback = function()
                BattleScrolls.journal.dialogs.showBasicDialog({
                    title = GetString(BATTLESCROLLS_CLEAR_ALL_FAVORITES),
                    mainText = GetString(BATTLESCROLLS_CLEAR_ALL_FAVORITES_TOOLTIP),
                    onConfirm = function()
                        -- Wipe the favorites table (replace with empty table so defaults merge correctly)
                        if settings then
                            -- Clear all entries from the table
                            for k in pairs(settings.favoriteEffects) do
                                settings.favoriteEffects[k] = nil
                            end
                        end
                        onRefresh()
                    end,
                })
            end,
        }
        list:AddEntry("ZO_GamepadOptionsLabelRow", clearFavoritesData)
    end

    return effectTrackingEnabled
end

---Renders performance settings (async speed, effect reconciliation precision)
local function renderPerformanceSettings(list, settings, defaults, onRefresh, effectTrackingEnabled)
    -- Build valid values and labels for async speed presets
    local asyncSpeedValues = {}
    local asyncSpeedLabels = {}
    local asyncSpeedPresets = BattleScrolls.storage.asyncSpeedPresets
    local asyncSpeedOrder = BattleScrolls.storage.asyncSpeedPresetOrder
    local currentPresetKey = BattleScrolls.storage:GetAsyncSpeedPresetKey()
    local currentFPS = BattleScrolls.storage:GetAsyncStallThreshold()

    -- If we have a custom value (not matching any preset), add it as the first option
    local hasCustomValue = (currentPresetKey == nil)

    if hasCustomValue then
        table.insert(asyncSpeedValues, currentFPS)
        table.insert(asyncSpeedLabels, zo_strformat(GetString(BATTLESCROLLS_SETTINGS_ASYNC_SPEED_CUSTOM), currentFPS))
    end

    -- Add standard presets
    for _, presetKey in ipairs(asyncSpeedOrder) do
        local preset = asyncSpeedPresets[presetKey]
        local labelStringId = _G["BATTLESCROLLS_SETTINGS_ASYNC_SPEED_" .. string.upper(presetKey)]
        table.insert(asyncSpeedValues, preset.fps)
        table.insert(asyncSpeedLabels, GetString(labelStringId))
    end

    local asyncSpeedData = {}
    asyncSpeedData.text = GetString(BATTLESCROLLS_SETTINGS_ASYNC_SPEED)
    asyncSpeedData.header = GetString(BATTLESCROLLS_SETTINGS_PERFORMANCE)
    asyncSpeedData.tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TITLE), GetString(BATTLESCROLLS_SETTINGS_ASYNC_SPEED_TEXT))
    asyncSpeedData.valid = asyncSpeedValues
    asyncSpeedData.valueStrings = asyncSpeedLabels
    asyncSpeedData.getFunction = function()
        return BattleScrolls.storage:GetAsyncStallThreshold()
    end
    asyncSpeedData.setFunction = function(fps)
        BattleScrolls.storage:SetAsyncStallThreshold(fps)
        -- Check if we need to rebuild the list (when moving from custom to preset)
        local newPresetKey = BattleScrolls.storage:GetAsyncSpeedPresetKey()
        if hasCustomValue and newPresetKey ~= nil then
            -- Switching from custom to a standard preset - rebuild list without custom entry
            onRefresh()
        end
    end

    list:AddEntry("ZO_GamepadHorizontalListRowWithHeader", asyncSpeedData)

    -- Effect reconciliation precision (only shown when effect tracking is enabled)
    if effectTrackingEnabled then
        local reconPresetKeys = {}
        local reconPresetLabels = {}
        for _, key in ipairs(BattleScrolls.storage.reconciliationPresetOrder) do
            local preset = BattleScrolls.storage.reconciliationPresets[key]
            table.insert(reconPresetKeys, key)
            table.insert(reconPresetLabels, GetString(_G[preset.labelStringId]))
        end

        local reconPresetData = {
            text = GetString(BATTLESCROLLS_SETTINGS_RECON_PRECISION),
            valid = reconPresetKeys,
            valueStrings = reconPresetLabels,
            tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_RECON_PRECISION), GetString(BATTLESCROLLS_SETTINGS_RECON_PRECISION_TOOLTIP)),
            getFunction = function()
                return settings and settings.effectReconciliationPreset or defaults.effectReconciliationPreset
            end,
            setFunction = function(value)
                if settings then
                    settings.effectReconciliationPreset = value
                end
            end,
        }
        list:AddEntry("ZO_GamepadHorizontalListRow", reconPresetData)
    end
end

---Renders sharing/privacy settings. Live combat data is always shared; only
---encounter history and build are opt-out (and bidirectional when off).
local function renderPrivacySettings(list, settings)
    local shareHistoryData = {
        text = GetString(BATTLESCROLLS_SETTINGS_SHARE_ENCOUNTER_HISTORY),
        header = GetString(BATTLESCROLLS_SETTINGS_SHARING),
        tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_SHARE_ENCOUNTER_HISTORY), GetString(BATTLESCROLLS_SETTINGS_SHARE_ENCOUNTER_HISTORY_TT)),
        getFunction = function()
            return settings and settings.shareEncounterHistory ~= false
        end,
        setFunction = function(value)
            if settings then
                settings.shareEncounterHistory = value
            end
        end,
        toggleFunction = function()
            if settings then
                settings.shareEncounterHistory = not (settings.shareEncounterHistory ~= false)
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRowWithHeader", shareHistoryData)

    local shareBuildData = {
        text = GetString(BATTLESCROLLS_SETTINGS_SHARE_BUILD),
        tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_SHARE_BUILD), GetString(BATTLESCROLLS_SETTINGS_SHARE_BUILD_TT)),
        getFunction = function()
            return settings and settings.shareBuild ~= false
        end,
        setFunction = function(value)
            if settings then
                settings.shareBuild = value
            end
        end,
        toggleFunction = function()
            if settings then
                settings.shareBuild = not (settings.shareBuild ~= false)
            end
        end,
    }
    list:AddEntry("ZO_GamepadOptionsCheckboxRow", shareBuildData)

    -- Non-interactive note: live combat data is always shared.
    local liveAlwaysData = {
        text = GetString(BATTLESCROLLS_SETTINGS_SHARE_LIVE_ALWAYS),
        tooltip = textTooltip(GetString(BATTLESCROLLS_SETTINGS_SHARING), GetString(BATTLESCROLLS_SETTINGS_SHARE_LIVE_ALWAYS_TT)),
    }
    list:AddEntry("ZO_GamepadOptionsLabelRow", liveAlwaysData)
end

-------------------------
-- Public API
-------------------------
---Renders the Settings list
---@param list any The parametric list
---@param onRefresh function Callback to refresh the list when settings change
function SettingsRenderer.renderSettings(list, onRefresh)
    list:Clear()

    local settings = BattleScrolls.storage and BattleScrolls.storage.savedVariables and BattleScrolls.storage.savedVariables.settings
    local defaults = BattleScrolls.storage.defaults.settings

    local personalEnabled = renderDpsMeterPersonalSettings(list, settings, defaults, onRefresh)
    renderDpsMeterGroupSettings(list, settings, defaults, onRefresh, personalEnabled)

    renderPrivacySettings(list, settings)

    local recordingEnabled = renderRecordingSettings(list, settings, defaults, onRefresh)
    if not recordingEnabled then
        list:Commit()
        return
    end

    renderStorageSettings(list, settings, defaults)
    local effectTrackingEnabled = renderEffectTrackingSettings(list, settings, defaults, onRefresh)
    renderPerformanceSettings(list, settings, defaults, onRefresh, effectTrackingEnabled)

    list:Commit()
end

-- Export to namespace
journal.renderers.settings = SettingsRenderer
