-----------------------------------------------------------
-- Character Stats Integration
-- Injects a "Battle Scrolls" entry into the Gamepad Character
-- screen after the "Description" entry, showing setup overview.
--
-- Reuses the Journal's OverviewPanel directly by temporarily
-- re-parenting it to the stats control when the entry is selected.
-- The OverviewPane anchors are relative to GuiRoot, so positioning
-- is correct regardless of parent — we just need a visible parent.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

local BS_DISPLAY_MODE = 118 -- Custom display mode (ESO uses 1-10)
local ICON = "EsoUI/Art/TreeIcons/Gamepad/gp_tutorial_idexIcon_combat.dds"

local characterStats = {}
BattleScrolls.characterStats = characterStats

local journal = BattleScrolls.journal

local setupEntry = nil    ---@type table|nil
local initialized = false
local originalParent = nil ---@type Control|nil  -- stashed parent for restore
local panelShown = false
local fadeAnimation = nil  ---@type table|nil -- FadeSceneAnimation timeline

---Returns the Journal's OverviewPanel (nil if journal not yet initialized).
---@return BattleScrolls_Journal_OverviewPanel|nil
local function getOverviewPanel()
    local journalUI = BATTLESCROLLS_JOURNAL_GAMEPAD
    return journalUI and journalUI.overviewPanel or nil
end

---Shows the overview panel in the stats screen by re-parenting to the stats control.
---@param statsControl Control The stats screen's top-level control (visible during the scene)
local function showOverviewPanel(statsControl)
    local panel = getOverviewPanel()
    if not panel then return end
    if panelShown then return end

    local control = panel.control
    if not originalParent then
        originalParent = control:GetParent()
    end
    control:SetParent(statsControl)
    control:SetAlpha(1)

    -- Create fade animation lazily (needs the control to exist)
    if not fadeAnimation then
        fadeAnimation = ANIMATION_MANAGER:CreateTimelineFromVirtual("FadeSceneAnimation", control)
    end

    -- Capture current setup and render
    local setupData = BattleScrolls.setupCapture:captureCurrentSetup()
    if not setupData then
        panel:Show()
        return
    end

    local ctx = { encounter = { setup = setupData }, durationS = 0 }
    local spec = journal.renderers.setup.buildSetupPanelSpec(ctx)
    panel:Show()
    panel:Render(spec)
    panelShown = true
end

---Hides the overview panel immediately and restores its parent.
local function hideOverviewPanel()
    if not panelShown then return end
    panelShown = false

    if fadeAnimation then
        fadeAnimation:Stop()
    end

    local panel = getOverviewPanel()
    if not panel then return end

    panel.control:SetAlpha(1)
    panel:Hide()
    panel:Clear()

    if originalParent then
        panel.control:SetParent(originalParent)
        originalParent = nil
    end
end

---Starts fade-out animation on the overview panel (does not hide or clean up).
local function fadeOutOverviewPanel()
    if panelShown and fadeAnimation then
        fadeAnimation:PlayFromEnd()
    end
end

local function createSetupEntry()
    local entry = ZO_GamepadEntryData:New(GetString(BATTLESCROLLS_UI_NAME), ICON)
    entry.displayMode = BS_DISPLAY_MODE
    entry:SetIconTintOnSelection(true)
    entry:SetIconDisabledTintOnSelection(true)
    return entry
end

function characterStats:Initialize()
    if initialized then return end
    if not GAMEPAD_STATS then return end
    initialized = true

    setupEntry = createSetupEntry()

    -- Pre-hook Commit on mainList: inject our entry after "Description" (characterEntry)
    -- before the commit runs. This avoids a double-commit which breaks selection state.
    ZO_PreHook(GAMEPAD_STATS.mainList, "Commit", function(list)
        if not GAMEPAD_STATS.characterEntry then return end
        local dataList = list.dataList
        -- Don't inject if already present (guard against nested commits)
        for i = 1, #dataList do
            if dataList[i] == setupEntry then return end
        end
        for i = 1, #dataList do
            if dataList[i] == GAMEPAD_STATS.characterEntry then
                list:AddEntryAtIndex(i + 1, "ZO_GamepadMenuEntryTemplate", setupEntry)
                return
            end
        end
    end)

    -- Post-hook UpdateScreenVisibility: handle our custom display mode
    ZO_PostHook(ZO_GamepadStats, "UpdateScreenVisibility", function(stats)
        if stats.displayMode == BS_DISPLAY_MODE then
            -- Hide all stock panels
            stats.characterStatsPanel:SetHidden(true)
            stats.attributesPanel:SetHidden(true)
            stats.characterEffects:SetHidden(true)
            stats.advancedAttributesPanel:SetHidden(true)
            -- Don't show the stats RightPane — we show the Journal's panel instead
            GAMEPAD_STATS_ROOT_SCENE:RemoveFragment(GAMEPAD_NAV_QUADRANT_2_3_BACKGROUND_FRAGMENT)
            GAMEPAD_STATS_ROOT_SCENE:RemoveFragment(GAMEPAD_STATS_CHARACTER_INFO_PANEL_FRAGMENT)
            showOverviewPanel(stats.control)
        else
            hideOverviewPanel()
        end
    end)

    -- Restore panel parent when leaving the stats scene (user may dismiss
    -- without navigating to another entry first)
    GAMEPAD_STATS_ROOT_SCENE:RegisterCallback("StateChange", function(_, newState)
        if newState == SCENE_HIDING then
            fadeOutOverviewPanel()
        elseif newState == SCENE_HIDDEN then
            hideOverviewPanel()
        end
    end)
end

