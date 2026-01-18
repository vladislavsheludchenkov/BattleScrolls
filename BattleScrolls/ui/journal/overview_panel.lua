if not SemisPlaygroundCheckAccess() then
    return
end

local STATS_TAB = BattleScrolls_Journal_StatsTab
local utils = BattleScrolls.utils
local journal = BattleScrolls.journal

-------------------------
-- Overview Panel Class
-------------------------
---@class BattleScrolls_Journal_OverviewPanel
---@field control Control
---@field q2Container Control Summary stats container
---@field q3Container Control Top abilities container
---@field q4Container Control Targets/sources container
local OverviewPanel = ZO_InitializingObject:Subclass()

BattleScrolls_Journal_OverviewPanel = OverviewPanel

-------------------------
-- Lazy Control Arrays
-------------------------
-- Controls are created on-demand and reused. Arrays grow as needed, never shrink.

-- Control arrays (grow-only)
local statRows = {}
local sectionHeaders = {}  -- Q2 sections
local uptimeBars = {}
local q2EffectRows = {}
local abilityBars = {}
local q3Sections = {}
local targetRows = {}
local effectBars = {}
local effectRows = {}
local q4Sections = {}

-- Counters for unique control names (prefixed with BS_ to avoid collision with ESO controls)
local controlCounters = {
    statRow = 0,
    section = 0,
    uptimeBar = 0,
    q2EffectRow = 0,
    abilityBar = 0,
    q3Section = 0,
    targetRow = 0,
    effectBar = 0,
    effectRow = 0,
    q4Section = 0,
}

-- Control name prefix to avoid collision with ESO built-in controls (e.g., "Section" collides with tooltip sections)
local CONTROL_PREFIX = "BS_Overview_"

-- Parent containers (set during Initialize, guaranteed non-nil when used by Add* methods)
---@type Control
local q2Parent
---@type Control
local q3Parent
---@type Control
local q4Parent

---Creates a control from a virtual template
---@param virtualName string The virtual control template name
---@param parent Control The parent control
---@param suffix string Suffix for naming (combined with CONTROL_PREFIX)
---@param counter string Counter key for unique naming
---@return Control
local function createControl(virtualName, parent, suffix, counter)
    controlCounters[counter] = controlCounters[counter] + 1
    local control = CreateControlFromVirtual(
        CONTROL_PREFIX .. suffix .. controlCounters[counter],
        parent,
        virtualName
    )
    control:SetHidden(true)
    return control
end

---Ensures an array has at least `count` controls, creating more if needed
---@param array table The control array
---@param count number Minimum number of controls needed
---@param virtualName string The virtual control template name
---@param parent Control The parent control
---@param prefix string Prefix for naming
---@param counter string Counter key for unique naming
local function ensureControls(array, count, virtualName, parent, prefix, counter)
    while #array < count do
        array[#array + 1] = createControl(virtualName, parent, prefix, counter)
    end
end

---Hides all controls in an array starting from index
---@param array table The control array
---@param fromIndex number Start hiding from this index (1-based)
local function hideControlsFrom(array, fromIndex)
    for i = fromIndex, #array do
        array[i]:SetHidden(true)
        array[i]:ClearAnchors()
    end
end

-- Usage counters (reset in Clear, track how many of each type used in current render)
local usageCounters = {
    statRow = 0,
    section = 0,
    uptimeBar = 0,
    q2EffectRow = 0,
    abilityBar = 0,
    q3Section = 0,
    targetRow = 0,
    effectBar = 0,
    effectRow = 0,
    q4Section = 0,
}

local function resetUsageCounters()
    for k in pairs(usageCounters) do
        usageCounters[k] = 0
    end
end

-------------------------
-- Shared Utility Functions
-------------------------

---Sets up the icon frame visibility based on whether it's a passive ability
---@param control Control The bar/row control with EdgeFrame and CircleFrame children
---@param abilityIcon string|nil The icon path
local function SetupIconFrame(control, abilityIcon)
    local edgeFrame = control:GetNamedChild("EdgeFrame")
    local circleFrame = control:GetNamedChild("CircleFrame")
    if edgeFrame and circleFrame then
        local isPassive = journal.utils.isPassiveIcon(abilityIcon)
        edgeFrame:SetHidden(isPassive)
        circleFrame:SetHidden(not isPassive)
    end
end

-- Row heights (from XML) and spacing gaps (separate for proper N items = N heights + (N-1) gaps calculation)
local ROW_CONTENT = {
    SECTION_HEADER = 50,  -- BattleScrolls_OverviewSectionHeader
    ABILITY_BAR = 54,     -- BattleScrolls_OverviewAbilityBar
    TARGET_ROW = 32,      -- BattleScrolls_OverviewTargetRow
    EFFECT_BAR = 54,      -- BattleScrolls_OverviewEffectBar
    EFFECT_ROW = 54,      -- BattleScrolls_OverviewEffectRow
    STAT_ROW = 36,        -- BattleScrolls_OverviewStatRow
}

local ROW_GAPS = {
    SECTION_HEADER = 15,
    ABILITY_BAR = 10,
    TARGET_ROW = 10,
    EFFECT_BAR = 10,
    EFFECT_ROW = 10,
    STAT_ROW = 10,
}

-- Fallback limits if container height unavailable
local DEFAULT_MAX_ITEMS = 10

-------------------------
-- Font-Adjusting for i18n
-------------------------
-- Font cascades for labels that may overflow in non-English locales
-- Each array lists fonts from largest to smallest; system tries each until text fits

-- For section headers (currently ZoFontGamepadBold34)
local SECTION_TITLE_FONTS = {
    { font = "ZoFontGamepadBold34", lineLimit = 1 },
    { font = "ZoFontGamepadBold27", lineLimit = 1 },
    { font = "ZoFontGamepad27", lineLimit = 1, dontUseForAdjusting = true },
}

-- For stat row headers (currently ZoFontGamepad27, 280px width)
local STAT_HEADER_FONTS = {
    { font = "ZoFontGamepad27", lineLimit = 1 },
    { font = "ZoFontGamepad22", lineLimit = 1 },
    { font = "ZoFontGamepad18", lineLimit = 1, dontUseForAdjusting = true },
}

-- For ability/effect names (currently ZoFontGamepad22)
local NAME_LABEL_FONTS = {
    { font = "ZoFontGamepad22", lineLimit = 1 },
    { font = "ZoFontGamepad18", lineLimit = 1, dontUseForAdjusting = true },
}

---Initializes a label with font-adjusting for i18n text overflow
---@param label Control The label control
---@param fonts table Array of font definitions with fallback sizes
local function SetupFontAdjustingLabel(label, fonts)
    ZO_FontAdjustingWrapLabel_OnInitialized(label, fonts, TEXT_WRAP_MODE_ELLIPSIS)
end

function OverviewPanel:Initialize(control)
    self.control = control

    -- Get references to three column containers
    self.q2Container = control:GetNamedChild("Q2Container")
    self.q3Container = control:GetNamedChild("Q3Container")
    self.q4Container = control:GetNamedChild("Q4Container")

    -- Loading label for async loading state
    self.loadingLabel = control:GetNamedChild("LoadingLabel")
    if self.loadingLabel then
        self.loadingLabel:SetText(GetString(BATTLESCROLLS_LIST_LOADING))
    end

    -- Fiber for tracking async loading (for cancellation)
    self.fiber = nil

    -- Fallback for compatibility
    self.container = self.q2Container or control:GetNamedChild("Container")

    -- Set parent containers for lazy control creation
    q2Parent = self.q2Container or self.container
    q3Parent = self.q3Container
    q4Parent = self.q4Container

    -- Track which controls are currently in use (for anchoring)
    self.activeControls = {}
    self.q3ActiveControls = {}
    self.q4ActiveControls = {}
end

-------------------------
-- Dynamic Limit Calculations
-------------------------

---Gets the available height for content in a container
---@param container Control The container control
---@return number availableHeight The available height in pixels
function OverviewPanel:GetContainerAvailableHeight(container)
    if not container then
        return 0
    end
    return container:GetHeight()
end

---Calculates how many items of a given type can fit in the remaining space
---N items require N × contentHeight + (N-1) × gap pixels
---@param availableHeight number Remaining available height
---@param contentHeight number Height per item (content only, no spacing)
---@param gap number Gap between items
---@return number maxItems Number of items that can fit
function OverviewPanel:CalculateMaxItems(availableHeight, contentHeight, gap)
    if availableHeight <= 0 or contentHeight <= 0 then
        return DEFAULT_MAX_ITEMS
    end
    -- N items need: N * contentHeight + (N-1) * gap = N * (contentHeight + gap) - gap
    -- So: N = (availableHeight + gap) / (contentHeight + gap)
    local count = math.floor((availableHeight + gap) / (contentHeight + gap))
    return math.max(1, count)  -- At least show 1 item
end

---Gets max abilities for Q3 based on available height, accounting for section header
---@return number maxAbilities
function OverviewPanel:GetMaxAbilities()
    if not self.q3Container then
        return DEFAULT_MAX_ITEMS
    end
    local availableHeight = self:GetContainerAvailableHeight(self.q3Container)
    -- Reserve space for section header (content + gap after it)
    local contentHeight = availableHeight - ROW_CONTENT.SECTION_HEADER - ROW_GAPS.SECTION_HEADER
    return self:CalculateMaxItems(contentHeight, ROW_CONTENT.ABILITY_BAR, ROW_GAPS.ABILITY_BAR)
end

---Gets max targets for Q4 based on available height, accounting for section header
---@return number maxTargets
function OverviewPanel:GetMaxTargets()
    if not self.q4Container then
        return DEFAULT_MAX_ITEMS
    end
    local availableHeight = self:GetContainerAvailableHeight(self.q4Container)
    -- Reserve space for section header (content + gap after it)
    local contentHeight = availableHeight - ROW_CONTENT.SECTION_HEADER - ROW_GAPS.SECTION_HEADER
    return self:CalculateMaxItems(contentHeight, ROW_CONTENT.TARGET_ROW, ROW_GAPS.TARGET_ROW)
end

---Gets max effect bars for Q3/Q4 based on available height
---@param container Control The container (q3Container or q4Container)
---@return number maxEffects
function OverviewPanel:GetMaxEffectBars(container)
    if not container then
        return DEFAULT_MAX_ITEMS
    end
    local availableHeight = self:GetContainerAvailableHeight(container)
    -- Reserve space for section header (content + gap after it)
    local contentHeight = availableHeight - ROW_CONTENT.SECTION_HEADER - ROW_GAPS.SECTION_HEADER
    return self:CalculateMaxItems(contentHeight, ROW_CONTENT.EFFECT_BAR, ROW_GAPS.EFFECT_BAR)
end

---Gets max effect rows for Q4 based on available height
---@return number maxEffects
function OverviewPanel:GetMaxEffectRows()
    if not self.q4Container then
        return DEFAULT_MAX_ITEMS
    end
    local availableHeight = self:GetContainerAvailableHeight(self.q4Container)
    -- Reserve space for section header (content + gap after it)
    local contentHeight = availableHeight - ROW_CONTENT.SECTION_HEADER - ROW_GAPS.SECTION_HEADER
    return self:CalculateMaxItems(contentHeight, ROW_CONTENT.EFFECT_ROW, ROW_GAPS.EFFECT_ROW)
end

---Gets max Q2 effect rows based on remaining height after other content
---@param usedHeight number Height already used by other content in Q2
---@return number maxEffects
function OverviewPanel:GetMaxQ2EffectRows(usedHeight)
    local container = self.q2Container or self.container
    if not container then
        return DEFAULT_MAX_ITEMS
    end
    local availableHeight = self:GetContainerAvailableHeight(container)
    -- Reserve space for section header (content + gap after it) and subtract used height
    local contentHeight = availableHeight - usedHeight - ROW_CONTENT.SECTION_HEADER - ROW_GAPS.SECTION_HEADER
    return self:CalculateMaxItems(contentHeight, ROW_CONTENT.EFFECT_ROW, ROW_GAPS.EFFECT_ROW)
end

function OverviewPanel:Clear()
    -- Reset usage counters for next render pass
    resetUsageCounters()

    -- Hide all Q2 controls
    hideControlsFrom(statRows, 1)
    hideControlsFrom(sectionHeaders, 1)
    hideControlsFrom(uptimeBars, 1)
    hideControlsFrom(q2EffectRows, 1)
    self.activeControls = {}

    -- Hide all Q3 controls
    hideControlsFrom(abilityBars, 1)
    hideControlsFrom(q3Sections, 1)
    self.q3ActiveControls = {}

    -- Hide all Q4 controls
    hideControlsFrom(targetRows, 1)
    hideControlsFrom(effectBars, 1)
    hideControlsFrom(effectRows, 1)
    hideControlsFrom(q4Sections, 1)
    self.q4ActiveControls = {}

    BattleScrolls.gc:RequestGC(5)
end


function OverviewPanel:Show()
    self.control:SetHidden(false)
end

function OverviewPanel:Hide()
    -- Cancel any pending async loading
    if self.fiber then
        self.fiber:Cancel()
        self.fiber = nil
    end
    self:HideLoading()
    self.control:SetHidden(true)
end

function OverviewPanel:IsHidden()
    return self.control:IsHidden()
end

---Shows the loading indicator and hides content containers
function OverviewPanel:ShowLoading()
    if self.loadingLabel then
        self.loadingLabel:SetHidden(false)
    end
    -- Hide content containers while loading
    if self.q2Container then self.q2Container:SetHidden(true) end
    if self.q3Container then self.q3Container:SetHidden(true) end
    if self.q4Container then self.q4Container:SetHidden(true) end
end

---Hides the loading indicator and shows content containers (sync version for cleanup)
function OverviewPanel:HideLoading()
    if self.loadingLabel then
        self.loadingLabel:SetHidden(true)
    end
    -- Show content containers
    if self.q2Container then self.q2Container:SetHidden(false) end
    if self.q3Container then self.q3Container:SetHidden(false) end
    if self.q4Container then self.q4Container:SetHidden(false) end
end

---Hides the loading indicator and shows content containers
---@return Effect<nil>
function OverviewPanel:HideLoadingAsync()
    return LibEffect.Async(function()
        if self.loadingLabel then
            self.loadingLabel:SetHidden(true)
        end
        -- Show all content containers (SetHidden is trivial, no yields needed)
        if self.q2Container then self.q2Container:SetHidden(false) end
        if self.q3Container then self.q3Container:SetHidden(false) end
        if self.q4Container then self.q4Container:SetHidden(false) end
    end)
end

-------------------------
-- Display Helpers
-------------------------

---Adds a section header with divider (Q2)
---@param title string Section title
---@param previousControl Control|nil Previous control to anchor below
---@return Control section The section control
function OverviewPanel:AddSection(title, previousControl)
    usageCounters.section = usageCounters.section + 1
    local index = usageCounters.section

    ensureControls(sectionHeaders, index, "BattleScrolls_OverviewSectionHeader", q2Parent, "Section", "section")
    local section = sectionHeaders[index]

    local titleLabel = section:GetNamedChild("Title")
    if not titleLabel.fontAdjustingInitialized then
        SetupFontAdjustingLabel(titleLabel, SECTION_TITLE_FONTS)
        titleLabel.fontAdjustingInitialized = true
    end
    titleLabel:SetText(title)

    section:ClearAnchors()
    if previousControl then
        section:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 15)
        section:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT, 0, 15)
    else
        section:SetAnchor(TOPLEFT, self.container, TOPLEFT, 0, 0)
        section:SetAnchor(TOPRIGHT, self.container, TOPRIGHT, 0, 0)
    end

    section:SetHidden(false)
    table.insert(self.activeControls, section)
    return section
end

---Adds a stat row (header + value pair)
---@param header string Label text
---@param value string Value text
---@param previousControl Control|nil Previous control to anchor below
---@return Control row The row control
function OverviewPanel:AddStatRow(header, value, previousControl)
    usageCounters.statRow = usageCounters.statRow + 1
    local index = usageCounters.statRow

    ensureControls(statRows, index, "BattleScrolls_OverviewStatRow", q2Parent, "Row", "statRow")
    local row = statRows[index]

    local headerLabel = row:GetNamedChild("Header")
    -- Initialize font-adjusting for i18n (safe to call multiple times)
    if not headerLabel.fontAdjustingInitialized then
        SetupFontAdjustingLabel(headerLabel, STAT_HEADER_FONTS)
        headerLabel.fontAdjustingInitialized = true
    end
    headerLabel:SetText(header)
    row:GetNamedChild("Value"):SetText(value)

    row:ClearAnchors()
    if previousControl then
        row:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 10)
        row:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT, 0, 10)
    else
        row:SetAnchor(TOPLEFT, self.container, TOPLEFT, 0, 0)
        row:SetAnchor(TOPRIGHT, self.container, TOPRIGHT, 0, 0)
    end

    row:SetHidden(false)
    table.insert(self.activeControls, row)
    return row
end

---Adds an uptime bar for effects
---@param label string Effect name
---@param percent number Uptime percentage (0-100)
---@param previousControl Control|nil Previous control to anchor below
---@return Control bar The bar control
function OverviewPanel:AddUptimeBar(label, percent, previousControl)
    usageCounters.uptimeBar = usageCounters.uptimeBar + 1
    local index = usageCounters.uptimeBar

    ensureControls(uptimeBars, index, "BattleScrolls_OverviewUptimeBar", q2Parent, "Uptime", "uptimeBar")
    local bar = uptimeBars[index]

    bar:GetNamedChild("Label"):SetText(label)
    local statusBar = bar:GetNamedChild("Bar")
    statusBar:SetMinMax(0, 100)
    statusBar:SetValue(percent)
    bar:GetNamedChild("Value"):SetText(string.format("%.0f%%", percent))

    bar:ClearAnchors()
    if previousControl then
        bar:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 4)
        bar:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT, 0, 4)
    else
        bar:SetAnchor(TOPLEFT, self.container, TOPLEFT, 0, 0)
        bar:SetAnchor(TOPRIGHT, self.container, TOPRIGHT, 0, 0)
    end

    bar:SetHidden(false)
    table.insert(self.activeControls, bar)
    return bar
end

-------------------------
-- Q3 Display Helpers (Top Abilities)
-------------------------

---Adds a section header to Q3 column
---@param title string Section title
---@param previousControl Control|nil Previous control to anchor below
---@return Control|nil section The section control or nil if no container
function OverviewPanel:AddQ3Section(title, previousControl)
    if not self.q3Container then return nil end
    usageCounters.q3Section = usageCounters.q3Section + 1
    local index = usageCounters.q3Section

    ensureControls(q3Sections, index, "BattleScrolls_OverviewSectionHeader", q3Parent, "Q3Section", "q3Section")
    local section = q3Sections[index]

    local titleLabel = section:GetNamedChild("Title")
    if not titleLabel.fontAdjustingInitialized then
        SetupFontAdjustingLabel(titleLabel, SECTION_TITLE_FONTS)
        titleLabel.fontAdjustingInitialized = true
    end
    titleLabel:SetText(title)

    section:ClearAnchors()
    if previousControl then
        section:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 15)
        section:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT, 0, 15)
    else
        section:SetAnchor(TOPLEFT, self.q3Container, TOPLEFT, 0, 0)
        section:SetAnchor(TOPRIGHT, self.q3Container, TOPRIGHT, 0, 0)
    end

    section:SetHidden(false)
    table.insert(self.q3ActiveControls, section)
    return section
end

---Formats DPS value, rounding small values
---@param dps number Raw DPS value
---@return string|nil Formatted DPS string, or nil for very large numbers
local function FormatDPS(dps)
    if dps >= 1000 then
        -- USE_UPPERCASE_NUMBER_SUFFIXES = true
        return ZO_AbbreviateAndLocalizeNumber(dps, NUMBER_ABBREVIATION_PRECISION_TENTHS, true)
    elseif dps >= 10 then
        return string.format("%.0f", dps)
    elseif dps >= 1 then
        return string.format("%.1f", dps)
    else
        return string.format("%.2f", dps)
    end
end

---Adds an ability bar with icon, name, stats, and relative progress bar
---@param abilityData table Ability data { abilityId, name, total, ticks, critTicks, maxHit }
---@param topValue number The highest value (for relative bar scaling)
---@param totalDamage number Total damage for share calculation
---@param durationS number Fight duration for DPS calculation
---@param previousControl Control|nil Previous control to anchor below
---@return Control|nil bar The bar control
function OverviewPanel:AddAbilityBar(abilityData, topValue, totalDamage, durationS, previousControl)
    if not self.q3Container then return nil end

    usageCounters.abilityBar = usageCounters.abilityBar + 1
    local index = usageCounters.abilityBar

    ensureControls(abilityBars, index, "BattleScrolls_OverviewAbilityBar", q3Parent, "Ability", "abilityBar")
    local bar = abilityBars[index]
    local abilityId = abilityData.abilityId

    -- Set icon
    local icon = bar:GetNamedChild("Icon")
    local abilityIcon = GetAbilityIcon(abilityId)
    icon:SetTexture(abilityIcon)

    -- Set icon frame (square for active, circle for passive)
    SetupIconFrame(bar, abilityIcon)

    -- Set name (use pre-computed name if available, else look up)
    local nameLabel = bar:GetNamedChild("Name")
    -- Initialize font-adjusting for i18n
    if not nameLabel.fontAdjustingInitialized then
        SetupFontAdjustingLabel(nameLabel, NAME_LABEL_FONTS)
        nameLabel.fontAdjustingInitialized = true
    end
    local abilityName = abilityData.name or utils.GetScribeAwareAbilityDisplayName(abilityId)
    nameLabel:SetText(abilityName)

    -- Set relative progress bar (StatusBar with gamepad style)
    local statusBar = bar:GetNamedChild("Bar")
    local barPercent = topValue > 0 and (abilityData.total / topValue * 100) or 0
    statusBar:SetMinMax(0, 100)
    statusBar:SetValue(barPercent)
    -- Use gold gradient color (similar to XP bar but gold-tinted)
    ZO_StatusBar_SetGradientColor(statusBar, ZO_XP_BAR_GRADIENT_COLORS)

    -- Set share percentage (prominent, top right)
    local shareLabel = bar:GetNamedChild("Share")
    local sharePercent = totalDamage > 0 and (abilityData.total / totalDamage * 100) or 0
    shareLabel:SetText(string.format("%.1f%%", sharePercent))

    -- Set DPS/HPS (rounded for small values)
    local dpsLabel = bar:GetNamedChild("DPS")
    local dps = durationS > 0 and (abilityData.total / durationS) or 0
    dpsLabel:SetText(zo_strformat(GetString(BATTLESCROLLS_STAT_PER_SECOND), FormatDPS(dps)))

    -- Set crit % (if available - damage has crit stats, healing doesn't)
    local critLabel = bar:GetNamedChild("Crit")
    local ticks = abilityData.ticks or 0
    local critTicks = abilityData.critTicks or 0
    if ticks > 0 then
        local critPercent = (critTicks / ticks * 100)
        critLabel:SetText(zo_strformat(GetString(BATTLESCROLLS_STAT_CRIT_PERCENT), string.format("%.0f", critPercent)))
    else
        critLabel:SetText("")
    end

    -- Set max hit (if available)
    local maxHitLabel = bar:GetNamedChild("MaxHit")
    local maxHit = abilityData.maxHit or 0
    if maxHit > 0 then
        local maxHitFormatted = ZO_AbbreviateAndLocalizeNumber(maxHit, NUMBER_ABBREVIATION_PRECISION_TENTHS, true)
        maxHitLabel:SetText(zo_strformat(GetString(BATTLESCROLLS_STAT_MAX_PREFIX), maxHitFormatted))
    else
        maxHitLabel:SetText("")
    end

    bar:ClearAnchors()
    if previousControl then
        bar:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 10)
        bar:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT, 0, 10)
    else
        bar:SetAnchor(TOPLEFT, self.q3Container, TOPLEFT, 0, 0)
        bar:SetAnchor(TOPRIGHT, self.q3Container, TOPRIGHT, 0, 0)
    end

    -- Anchor Share to right edge of bar (must be done in Lua after bar is sized)
    shareLabel:ClearAnchors()
    shareLabel:SetAnchor(TOPRIGHT, bar, TOPRIGHT, 0, 0)

    bar:SetHidden(false)
    table.insert(self.q3ActiveControls, bar)
    return bar
end

-------------------------
-- Q4 Display Helpers (Targets/Sources)
-------------------------

---Adds a section header to Q4 column
---@param title string Section title
---@param previousControl Control|nil Previous control to anchor below
---@return Control|nil section The section control or nil if no container
function OverviewPanel:AddQ4Section(title, previousControl)
    if not self.q4Container then return nil end
    usageCounters.q4Section = usageCounters.q4Section + 1
    local index = usageCounters.q4Section

    ensureControls(q4Sections, index, "BattleScrolls_OverviewSectionHeader", q4Parent, "Q4Section", "q4Section")
    local section = q4Sections[index]

    local titleLabel = section:GetNamedChild("Title")
    if not titleLabel.fontAdjustingInitialized then
        SetupFontAdjustingLabel(titleLabel, SECTION_TITLE_FONTS)
        titleLabel.fontAdjustingInitialized = true
    end
    titleLabel:SetText(title)

    section:ClearAnchors()
    if previousControl then
        section:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 15)
        section:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT, 0, 15)
    else
        section:SetAnchor(TOPLEFT, self.q4Container, TOPLEFT, 0, 0)
        section:SetAnchor(TOPRIGHT, self.q4Container, TOPRIGHT, 0, 0)
    end

    section:SetHidden(false)
    table.insert(self.q4ActiveControls, section)
    return section
end

---Adds a target row with name and value
---@param targetName string Target name
---@param value number|string Damage/healing value
---@param previousControl Control|nil Previous control to anchor below
---@return Control|nil row The row control
function OverviewPanel:AddTargetRow(targetName, value, previousControl)
    if not self.q4Container then return nil end

    usageCounters.targetRow = usageCounters.targetRow + 1
    local index = usageCounters.targetRow

    ensureControls(targetRows, index, "BattleScrolls_OverviewTargetRow", q4Parent, "Target", "targetRow")
    local row = targetRows[index]
    local nameLabel = row:GetNamedChild("Name")
    -- Initialize font-adjusting for i18n
    if not nameLabel.fontAdjustingInitialized then
        SetupFontAdjustingLabel(nameLabel, NAME_LABEL_FONTS)
        nameLabel.fontAdjustingInitialized = true
    end
    nameLabel:SetText(targetName)
    -- USE_UPPERCASE_NUMBER_SUFFIXES = true
    row:GetNamedChild("Value"):SetText(type(value) == "number" and ZO_AbbreviateAndLocalizeNumber(value, NUMBER_ABBREVIATION_PRECISION_TENTHS, true) or value)

    row:ClearAnchors()
    if previousControl then
        row:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 10)
        row:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT, 0, 10)
    else
        row:SetAnchor(TOPLEFT, self.q4Container, TOPLEFT, 0, 0)
        row:SetAnchor(TOPRIGHT, self.q4Container, TOPRIGHT, 0, 0)
    end

    row:SetHidden(false)
    table.insert(self.q4ActiveControls, row)
    return row
end

---Adds an effect bar with icon, name, uptime bar, and stats (matches ability bar style)
---@param abilityId number Ability ID for icon/name lookup
---@param percent number Uptime percentage (0-100)
---@param previousControl Control|nil Previous control to anchor below
---@param stats { applications: number|nil, playerPercent: number|nil, maxStacks: number|nil, suffix: string|nil }|nil Optional stats for second row
---@return Control|nil bar The bar control
function OverviewPanel:AddEffectBar(abilityId, percent, previousControl, stats)
    if not self.q4Container then return nil end

    usageCounters.effectBar = usageCounters.effectBar + 1
    local index = usageCounters.effectBar

    ensureControls(effectBars, index, "BattleScrolls_OverviewEffectBar", q4Parent, "Effect", "effectBar")
    local bar = effectBars[index]

    -- Set icon
    local icon = bar:GetNamedChild("Icon")
    local abilityIcon = GetAbilityIcon(abilityId)
    icon:SetTexture(abilityIcon)

    -- Set icon frame (square for active, circle for passive)
    SetupIconFrame(bar, abilityIcon)

    -- Set name with optional suffix
    local nameLabel = bar:GetNamedChild("Name")
    -- Initialize font-adjusting for i18n
    if not nameLabel.fontAdjustingInitialized then
        SetupFontAdjustingLabel(nameLabel, NAME_LABEL_FONTS)
        nameLabel.fontAdjustingInitialized = true
    end
    local abilityName = utils.GetScribeAwareAbilityDisplayName(abilityId)
    if stats and stats.suffix then
        nameLabel:SetText(abilityName .. " " .. stats.suffix)
    else
        nameLabel:SetText(abilityName)
    end

    -- Set progress bar (StatusBar with gamepad style)
    local statusBar = bar:GetNamedChild("Bar")
    statusBar:SetMinMax(0, 100)
    statusBar:SetValue(percent)
    -- Use gold gradient color (matching ability bars)
    ZO_StatusBar_SetGradientColor(statusBar, ZO_XP_BAR_GRADIENT_COLORS)

    -- Set uptime value (prominent, right side)
    local valueLabel = bar:GetNamedChild("Value")
    valueLabel:SetText(string.format("%.0f%%", percent))

    -- Anchor value to right edge of bar
    valueLabel:ClearAnchors()
    valueLabel:SetAnchor(TOPRIGHT, bar, TOPRIGHT, 0, 0)

    -- Set stats row
    local appsLabel = bar:GetNamedChild("Apps")
    local playerLabel = bar:GetNamedChild("Player")
    local stacksLabel = bar:GetNamedChild("Stacks")

    if stats then
        -- Applications count
        if stats.applications and stats.applications > 0 then
            appsLabel:SetText(zo_strformat(GetString(BATTLESCROLLS_EFFECT_APPS_COUNT), stats.applications))
        else
            appsLabel:SetText("")
        end

        -- Player contribution
        if stats.playerPercent and stats.playerPercent > 0 then
            playerLabel:SetText(zo_strformat(GetString(BATTLESCROLLS_EFFECT_YOURS_PERCENT), string.format("%.0f", stats.playerPercent)))
        else
            playerLabel:SetText("")
        end

        -- Max stacks
        if stats.maxStacks and stats.maxStacks > 1 then
            stacksLabel:SetText(zo_strformat(GetString(BATTLESCROLLS_EFFECT_STACKS_COUNT), stats.maxStacks))
        else
            stacksLabel:SetText("")
        end
    else
        appsLabel:SetText("")
        playerLabel:SetText("")
        stacksLabel:SetText("")
    end

    bar:ClearAnchors()
    if previousControl then
        bar:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 10)
        bar:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT, 0, 10)
    else
        bar:SetAnchor(TOPLEFT, self.q4Container, TOPLEFT, 0, 0)
        bar:SetAnchor(TOPRIGHT, self.q4Container, TOPRIGHT, 0, 0)
    end

    bar:SetHidden(false)
    table.insert(self.q4ActiveControls, bar)
    return bar
end

---Adds a compact effect row with icon, name, uptime, and stats (no progress bar, for narrow spaces)
---@param abilityId number Ability ID for icon/name lookup
---@param percent number Uptime percentage (0-100)
---@param previousControl Control|nil Previous control to anchor below
---@param stats { applications: number|nil, playerPercent: number|nil, maxStacks: number|nil, suffix: string|nil }|nil Optional stats
---@return Control|nil row The row control
function OverviewPanel:AddEffectRow(abilityId, percent, previousControl, stats)
    if not self.q4Container then return nil end

    usageCounters.effectRow = usageCounters.effectRow + 1
    local index = usageCounters.effectRow

    ensureControls(effectRows, index, "BattleScrolls_OverviewEffectRow", q4Parent, "EffectRow", "effectRow")
    local row = effectRows[index]

    -- Set icon
    local icon = row:GetNamedChild("Icon")
    local abilityIcon = GetAbilityIcon(abilityId)
    icon:SetTexture(abilityIcon)

    -- Set icon frame (square for active, circle for passive)
    SetupIconFrame(row, abilityIcon)

    -- Set name with optional suffix
    local nameLabel = row:GetNamedChild("Name")
    -- Initialize font-adjusting for i18n
    if not nameLabel.fontAdjustingInitialized then
        SetupFontAdjustingLabel(nameLabel, NAME_LABEL_FONTS)
        nameLabel.fontAdjustingInitialized = true
    end
    local abilityName = utils.GetScribeAwareAbilityDisplayName(abilityId)
    if stats and stats.suffix then
        nameLabel:SetText(abilityName .. " " .. stats.suffix)
    else
        nameLabel:SetText(abilityName)
    end

    -- Set uptime value
    local valueLabel = row:GetNamedChild("Value")
    valueLabel:SetText(string.format("%.0f%%", percent))

    -- Set stats line (compact, single label)
    local statsLabel = row:GetNamedChild("Stats")
    local statParts = {}

    if stats then
        if stats.applications and stats.applications > 0 then
            table.insert(statParts, zo_strformat(GetString(BATTLESCROLLS_EFFECT_APPS_COUNT), stats.applications))
        end
        if stats.playerPercent and stats.playerPercent > 0 then
            table.insert(statParts, zo_strformat(GetString(BATTLESCROLLS_EFFECT_YOURS_PERCENT), string.format("%.0f", stats.playerPercent)))
        end
        if stats.maxStacks and stats.maxStacks > 1 then
            table.insert(statParts, zo_strformat(GetString(BATTLESCROLLS_EFFECT_STACKS_COUNT), stats.maxStacks))
        end
    end

    statsLabel:SetText(table.concat(statParts, " · "))

    row:ClearAnchors()
    if previousControl then
        row:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 10)
        row:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT, 0, 10)
    else
        row:SetAnchor(TOPLEFT, self.q4Container, TOPLEFT, 0, 0)
        row:SetAnchor(TOPRIGHT, self.q4Container, TOPRIGHT, 0, 0)
    end

    row:SetHidden(false)
    table.insert(self.q4ActiveControls, row)
    return row
end

---Adds a compact effect row to Q2 (no progress bar, for narrow left column)
---@param abilityId number Ability ID for icon/name lookup
---@param percent number Uptime percentage (0-100)
---@param previousControl Control|nil Previous control to anchor below
---@param stats { applications: number|nil, playerPercent: number|nil, maxStacks: number|nil, peakInstances: number|nil }|nil Optional stats
---@return Control|nil row The row control
function OverviewPanel:AddQ2EffectRow(abilityId, percent, previousControl, stats)
    usageCounters.q2EffectRow = usageCounters.q2EffectRow + 1
    local index = usageCounters.q2EffectRow

    ensureControls(q2EffectRows, index, "BattleScrolls_OverviewEffectRow", q2Parent, "Q2Effect", "q2EffectRow")
    local row = q2EffectRows[index]

    -- Set icon
    local icon = row:GetNamedChild("Icon")
    local abilityIcon = GetAbilityIcon(abilityId)
    icon:SetTexture(abilityIcon)

    -- Set icon frame (square for active, circle for passive)
    SetupIconFrame(row, abilityIcon)

    -- Set name
    local nameLabel = row:GetNamedChild("Name")
    -- Initialize font-adjusting for i18n
    if not nameLabel.fontAdjustingInitialized then
        SetupFontAdjustingLabel(nameLabel, NAME_LABEL_FONTS)
        nameLabel.fontAdjustingInitialized = true
    end
    local abilityName = utils.GetScribeAwareAbilityDisplayName(abilityId)
    nameLabel:SetText(abilityName)

    -- Set uptime value (show "avg" suffix if multiple instances)
    local valueLabel = row:GetNamedChild("Value")
    local peakInstances = stats and stats.peakInstances or 1
    if peakInstances > 1 then
        valueLabel:SetText(string.format("%.0f%% %s", percent, GetString(BATTLESCROLLS_EFFECT_AVG)))
    else
        valueLabel:SetText(string.format("%.0f%%", percent))
    end

    -- Set stats line (compact, single label)
    local statsLabel = row:GetNamedChild("Stats")
    local statParts = {}

    if stats then
        -- Show peak instances first (most important for understanding the uptime)
        if stats.peakInstances and stats.peakInstances > 1 then
            table.insert(statParts, string.format("×%d", stats.peakInstances))
        end
        if stats.applications and stats.applications > 0 then
            table.insert(statParts, zo_strformat(GetString(BATTLESCROLLS_EFFECT_APPS_COUNT), stats.applications))
        end
        if stats.playerPercent and stats.playerPercent > 0 then
            table.insert(statParts, zo_strformat(GetString(BATTLESCROLLS_EFFECT_YOURS_PERCENT), string.format("%.0f", stats.playerPercent)))
        end
        if stats.maxStacks and stats.maxStacks > 1 then
            table.insert(statParts, zo_strformat(GetString(BATTLESCROLLS_EFFECT_STACKS_COUNT), stats.maxStacks))
        end
    end

    statsLabel:SetText(table.concat(statParts, " · "))

    row:ClearAnchors()
    if previousControl then
        row:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 10)
        row:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT, 0, 10)
    else
        row:SetAnchor(TOPLEFT, self.q2Container or self.container, TOPLEFT, 0, 0)
        row:SetAnchor(TOPRIGHT, self.q2Container or self.container, TOPRIGHT, 0, 0)
    end

    row:SetHidden(false)
    table.insert(self.activeControls, row)
    return row
end

-------------------------
-- Per-Tab Refresh Functions
-------------------------

---Refreshes the overview panel content based on current tab (async with loading state)
---@param journalUI BattleScrolls_Journal_Gamepad
function OverviewPanel:Refresh(journalUI)
    -- Cancel any existing async load
    if self.fiber then
        self.fiber:Cancel()
        self.fiber = nil
    end

    -- Clear existing content
    self:Clear()

    BattleScrolls.gc:RequestGC(5)

    local selectedTab = journalUI.selectedTab
    local arithmancer = journalUI.arithmancer
    local decodedEncounter = journalUI.decodedEncounter
    local unitNames = journalUI.unitNames or {}
    local abilityInfo = journalUI.abilityInfo or {}

    if not arithmancer or not decodedEncounter or not selectedTab then
        self:HideLoading()
        return
    end

    -- Show loading state
    self:ShowLoading()

    -- Capture values before async (they may change if user navigates)
    local durationS = arithmancer:getDurationS()

    -- Get normalized filters for the current tab (already stored in normalized form)
    local filters = journalUI:GetFiltersForTab(selectedTab)

    -- Build context for renderers
    local ctx = {
        arithmancer = arithmancer,
        encounter = decodedEncounter,
        durationS = durationS,
        unitNames = unitNames,
        abilityInfo = abilityInfo,
        filters = filters,
    }

    -- Get renderer references
    local renderers = journal.renderers

    -- Start async refresh
    self.fiber = LibEffect.Async(function()
        -- Yield to allow loading state to render
        LibEffect.Yield():Await()

        -- Dispatch to renderer-specific panel refresh (all return Effects, await them)
        if selectedTab == STATS_TAB.OVERVIEW then
            renderers.overview.refreshPanelForOverview(self, ctx):Await()
        elseif selectedTab == STATS_TAB.BOSS_DAMAGE_DONE then
            renderers.damage.refreshPanelForBossDamage(self, ctx):Await()
        elseif selectedTab == STATS_TAB.DAMAGE_DONE then
            renderers.damage.refreshPanelForDamageDone(self, ctx):Await()
        elseif selectedTab == STATS_TAB.DAMAGE_TAKEN then
            renderers.damage.refreshPanelForDamageTaken(self, ctx):Await()
        elseif selectedTab == STATS_TAB.HEALING_OUT then
            renderers.healing.refreshPanelForHealingOut(self, ctx):Await()
        elseif selectedTab == STATS_TAB.SELF_HEALING then
            renderers.healing.refreshPanelForSelfHealing(self, ctx):Await()
        elseif selectedTab == STATS_TAB.HEALING_IN then
            renderers.healing.refreshPanelForHealingIn(self, ctx):Await()
        elseif selectedTab == STATS_TAB.EFFECTS then
            renderers.effects.refreshPanelForEffects(self, ctx):Await()
        end

        -- Show panels with yields between each
        self:HideLoadingAsync():Await()
        BattleScrolls.gc:RequestGC(5)
    end):Ensure(function()
        -- Fallback sync hide in case of cancellation/error
        self:HideLoading()
    end):Ensure(function()
        -- Always clear fiber reference
        self.fiber = nil
    end):Run()
end
