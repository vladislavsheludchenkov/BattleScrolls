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
---@field q2Container Control Summary stats container (ZO_ScrollContainer_Gamepad)
---@field q2ScrollChild Control ScrollChild inside Q2's scroll area
---@field q3Container Control Top abilities container (ZO_ScrollContainer_Gamepad)
---@field q3ScrollChild Control ScrollChild inside Q3's scroll area
---@field q4Container Control Targets/sources container (ZO_ScrollContainer_Gamepad)
---@field q4ScrollChild Control ScrollChild inside Q4's scroll area
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
local groupMemberCards = {}
local deathAttackRows = {}

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
    groupMemberCard = 0,
    deathAttackRow = 0,
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
    groupMemberCard = 0,
    deathAttackRow = 0,
}

local function resetUsageCounters()
    for k in pairs(usageCounters) do
        usageCounters[k] = 0
    end
end

-- Q3 content Y offset tracking for direct anchoring.
-- Controls anchor directly to ScrollChild (not to each other) to avoid "Too many anchors"
-- when many ZO_GamepadArrowStatusBarWithBGMedium bars would form deep sibling chains.
local q3ContentHeight = 0

-- Horizontal inset for Q3 content inside the Scroll's clip region.
-- Status bar decorations (ZO_GamepadArrowStatusBarWithBGMedium borders) extend slightly
-- beyond control bounds; this prevents the Scroll from clipping them.
local Q3_CONTENT_INSET_X = 2

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
    EFFECT_BAR = 54,      -- BattleScrolls_OverviewEffectBar
    EFFECT_ROW = 54,      -- BattleScrolls_OverviewEffectRow
    STAT_ROW = 36,        -- BattleScrolls_OverviewStatRow
}

local ROW_GAPS = {
    SECTION_HEADER = 15,
    ABILITY_BAR = 10,
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

-- For label-value row headers: prefer wrapping at full size over shrinking
local STAT_HEADER_FONTS = {
    { font = "ZoFontGamepad27", lineLimit = 1 },
    { font = "ZoFontGamepad27", lineLimit = 2 },
    { font = "ZoFontGamepad22", lineLimit = 2, dontUseForAdjusting = true },
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

-------------------------
-- Shared Label-Value Row Logic
-------------------------
-- Used by both Q2 stat rows and Q4 target rows (same template, dynamic sizing).

local LABEL_VALUE_PADDING = 10
local MAX_VALUE_WIDTH_RATIO = 0.5

---Sets up label widths and row height dynamically for a label-value row.
---Value gets its natural text width (capped at 50% of container).
---Header gets the remaining space. Row height adapts to content.
---@param row Control The row control (BattleScrolls_OverviewStatRow template)
---@param headerText string Header/name text
---@param valueText string Value text
---@param containerWidth number The parent container width
local function setupLabelValueRow(row, headerText, valueText, containerWidth)
    local headerLabel = row:GetNamedChild("Header")
    local valueLabel = row:GetNamedChild("Value")

    -- Measure value's natural width (unconstrain first for accurate measurement)
    valueLabel:SetWidth(containerWidth)
    valueLabel:SetText(valueText)
    local maxValueWidth = math.floor(containerWidth * MAX_VALUE_WIDTH_RATIO)
    local valueWidth = math.min(valueLabel:GetTextWidth(), maxValueWidth)
    valueLabel:SetWidth(valueWidth)

    -- Header gets remaining space
    local headerWidth = containerWidth - valueWidth - LABEL_VALUE_PADDING
    headerLabel:SetWidth(headerWidth)

    -- Initialize font-adjusting (once per control lifecycle)
    if not headerLabel.fontAdjustingInitialized then
        SetupFontAdjustingLabel(headerLabel, STAT_HEADER_FONTS)
        headerLabel.fontAdjustingInitialized = true
    end
    headerLabel:SetText(headerText)

    -- Dynamic height: adapt to actual text content
    local contentHeight = math.max(headerLabel:GetTextHeight(), valueLabel:GetTextHeight())
    row:SetHeight(contentHeight)
end

---Adds a label-value row to the specified container with dynamic sizing.
---@param headerText string Left-aligned label text
---@param valueText string Right-aligned value text
---@param previousControl Control|nil Previous control to anchor below
---@param parent Control Parent container (for sizing and default anchor)
---@param pool table Control pool array
---@param counterKey string Usage counter key
---@param prefix string Control name prefix
---@param activeArray table Active controls tracking array
---@return Control row The row control
local function addLabelValueRow(headerText, valueText, previousControl, parent, pool, counterKey, prefix, activeArray)
    usageCounters[counterKey] = usageCounters[counterKey] + 1
    local index = usageCounters[counterKey]

    ensureControls(pool, index, "BattleScrolls_OverviewStatRow", parent, prefix, counterKey)
    local row = pool[index]

    setupLabelValueRow(row, headerText, valueText, parent:GetWidth())

    row:ClearAnchors()
    if previousControl then
        row:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 10)
        row:SetAnchor(TOPRIGHT, previousControl, BOTTOMRIGHT, 0, 10)
    else
        row:SetAnchor(TOPLEFT, parent, TOPLEFT, 0, 0)
        row:SetAnchor(TOPRIGHT, parent, TOPRIGHT, 0, 0)
    end

    row:SetHidden(false)
    table.insert(activeArray, row)
    return row
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
    -- Q2/Q3/Q4 inherit ZO_ScrollContainer_Gamepad; look up ScrollChild and position indicators
    for _, entry in ipairs({
        { container = self.q2Container, field = "q2ScrollChild" },
        { container = self.q3Container, field = "q3ScrollChild" },
        { container = self.q4Container, field = "q4ScrollChild" },
    }) do
        if entry.container then
            self[entry.field] = entry.container:GetNamedChild("ScrollChild")
            local scrollIndicator = entry.container:GetNamedChild("ScrollIndicator")
            if scrollIndicator then
                ZO_Scroll_Gamepad_SetScrollIndicatorSide(scrollIndicator, self.control, RIGHT)
            end
        end
    end
    q2Parent = self.q2ScrollChild or self.q2Container or self.container
    q3Parent = self.q3ScrollChild or self.q3Container
    q4Parent = self.q4ScrollChild or self.q4Container

    -- Track which controls are currently in use (for anchoring)
    self.activeControls = {}
    self.q3ActiveControls = {}
    self.q4ActiveControls = {}
    self.groupMemberCardsActive = {}

    -- Q3/Q4 hidden state (for compact layouts)
    self.q3Hidden = false
    self.q4Hidden = false
end

---Hides or shows Q3 and re-anchors Q4 next to Q2 when Q3 is empty.
---Also shrinks the pane width so the background contracts.
---@param hidden boolean
function OverviewPanel:SetQ3Hidden(hidden)
    self.q3Hidden = hidden
    if self.q3Container then
        self.q3Container:SetHidden(hidden)
    end
    if self.q4Container then
        self.q4Container:ClearAnchors()
        if hidden then
            -- Q4 shifts left next to Q2 (left-anchored, keeps fixed 300px width from XML)
            self.q4Container:SetAnchor(TOPLEFT, self.q2Container, TOPRIGHT, 50, 0)
            self.q4Container:SetAnchor(BOTTOMLEFT, self.q2Container, BOTTOMRIGHT, 50, 0)
        else
            -- Restore default: Q4 anchored to right edge of pane
            self.q4Container:SetAnchor(TOPRIGHT, self.control, TOPRIGHT, -40, 90)
            self.q4Container:SetAnchor(BOTTOMRIGHT, self.control, BOTTOMRIGHT, -40, -10)
        end
    end
    -- Shrink/restore the pane width so NestedBg background follows
    if hidden then
        self.paneFullWidth = self.paneFullWidth or self.control:GetWidth()
        -- Compact: Q2 left pad(50) + Q2 width + gap(50) + Q4 width + right pad(40)
        local compactWidth = 50 + self.q2Container:GetWidth() + 50 + self.q4Container:GetWidth() + 40
        self.control:SetWidth(compactWidth)
    elseif self.paneFullWidth then
        self.control:SetWidth(self.paneFullWidth)
    end
end

---Hides or shows Q4 and re-anchors Q3 to fill the freed space
---@param hidden boolean
function OverviewPanel:SetQ4Hidden(hidden)
    self.q4Hidden = hidden
    if self.q4Container then
        self.q4Container:SetHidden(hidden)
    end
    if self.q3Container then
        self.q3Container:ClearAnchors()
        if hidden then
            -- Q3 expands to fill Q4's space: anchor right edge to overview pane
            self.q3Container:SetAnchor(TOPLEFT, self.q2Container, TOPRIGHT, 50, 0)
            self.q3Container:SetAnchor(BOTTOMRIGHT, self.control, BOTTOMRIGHT, -40, -10)
        else
            -- Restore default: Q3 anchored between Q2 and Q4
            self.q3Container:SetAnchor(TOPLEFT, self.q2Container, TOPRIGHT, 50, 0)
            self.q3Container:SetAnchor(BOTTOMRIGHT, self.q4Container, BOTTOMLEFT, -50, 0)
        end
    end
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
    return self:CalculateMaxItems(contentHeight, ROW_CONTENT.STAT_ROW, ROW_GAPS.STAT_ROW)
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
    hideControlsFrom(effectBars, 1)
    self.q3ActiveControls = {}

    -- Reset Q2 scroll state
    if self.q2Container and self.q2Container.ResetToTop then
        self.q2Container:ResetToTop()
    end

    -- Reset Q3 scroll state
    q3ContentHeight = 0
    if self.q3Container and self.q3Container.ResetToTop then
        self.q3Container:ResetToTop()
    end

    -- Reset Q4 scroll state
    if self.q4Container and self.q4Container.ResetToTop then
        self.q4Container:ResetToTop()
    end

    -- Hide all Q4 controls
    hideControlsFrom(targetRows, 1)
    hideControlsFrom(effectRows, 1)
    hideControlsFrom(q4Sections, 1)
    self.q4ActiveControls = {}

    -- Restore Q3/Q4 visibility and anchoring
    if self.q3Hidden then
        self:SetQ3Hidden(false)
    end
    if self.q4Hidden then
        self:SetQ4Hidden(false)
    end

    -- Hide all group member cards
    hideControlsFrom(groupMemberCards, 1)
    self.groupMemberCardsActive = {}

    -- Hide all death attack rows
    hideControlsFrom(deathAttackRows, 1)

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
    -- Show content containers (respect q3Hidden/q4Hidden state)
    if self.q2Container then self.q2Container:SetHidden(false) end
    if self.q3Container then self.q3Container:SetHidden(self.q3Hidden) end
    if self.q4Container then self.q4Container:SetHidden(self.q4Hidden) end
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
        section:SetAnchor(TOPLEFT, q2Parent, TOPLEFT, 0, 0)
        section:SetAnchor(TOPRIGHT, q2Parent, TOPRIGHT, 0, 0)
    end

    section:SetHidden(false)
    table.insert(self.activeControls, section)
    return section
end

---Adds a stat row (header + value pair) to Q2
---@param header string Label text
---@param value string Value text
---@param previousControl Control|nil Previous control to anchor below
---@return Control row The row control
function OverviewPanel:AddStatRow(header, value, previousControl)
    return addLabelValueRow(header, value, previousControl, q2Parent, statRows, "statRow", "Row", self.activeControls)
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

    -- Clear any timing label from previous render
    local timingLabel = section:GetNamedChild("Timing")
    if timingLabel then timingLabel:SetHidden(true) end

    -- Direct anchoring to ScrollChild (avoids deep sibling anchor chains with status bar internals)
    section:ClearAnchors()
    if previousControl then
        q3ContentHeight = q3ContentHeight + ROW_GAPS.SECTION_HEADER
    else
        q3ContentHeight = 0
    end
    section:SetAnchor(TOPLEFT, q3Parent, TOPLEFT, Q3_CONTENT_INSET_X, q3ContentHeight)
    section:SetAnchor(TOPRIGHT, q3Parent, TOPRIGHT, -Q3_CONTENT_INSET_X, q3ContentHeight)
    q3ContentHeight = q3ContentHeight + ROW_CONTENT.SECTION_HEADER

    section:SetHidden(false)
    table.insert(self.q3ActiveControls, section)
    return section
end

---Sets a right-aligned timing subtitle on a Q3 section header.
---Creates the label lazily on first use; hides it when text is nil.
---@param section Control|nil The section control returned by AddQ3Section
---@param text string|nil Timing text (e.g., "1:23") or nil to hide
function OverviewPanel:SetQ3SectionTiming(section, text)
    if not section then return end
    local timingLabel = section:GetNamedChild("Timing")
    if not timingLabel then
        timingLabel = CreateControl(section:GetName() .. "Timing", section, CT_LABEL)
        timingLabel:SetFont("ZoFontGamepad22")
        timingLabel:SetColor(ZO_NORMAL_TEXT:UnpackRGBA())
        timingLabel:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
        timingLabel:SetVerticalAlignment(TEXT_ALIGN_BOTTOM)
        timingLabel:SetAnchor(BOTTOMRIGHT, section, BOTTOMRIGHT, 0, -5)
        timingLabel:SetDimensions(120, 50)
    end
    if text then
        timingLabel:SetText(text)
        timingLabel:SetHidden(false)
    else
        timingLabel:SetHidden(true)
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
    local abilityIcon = abilityData.icon or GetAbilityIcon(abilityId)
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
    dpsLabel:SetText(zo_strformat(GetString(BATTLESCROLLS_STAT_PER_SECOND), journal.utils.formatDPS(dps)))

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

    -- Direct anchoring to ScrollChild (avoids deep sibling anchor chains with status bar internals)
    bar:ClearAnchors()
    if previousControl then
        q3ContentHeight = q3ContentHeight + ROW_GAPS.ABILITY_BAR
    else
        q3ContentHeight = 0
    end
    bar:SetAnchor(TOPLEFT, q3Parent, TOPLEFT, Q3_CONTENT_INSET_X, q3ContentHeight)
    bar:SetAnchor(TOPRIGHT, q3Parent, TOPRIGHT, -Q3_CONTENT_INSET_X, q3ContentHeight)
    q3ContentHeight = q3ContentHeight + ROW_CONTENT.ABILITY_BAR

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
        section:SetAnchor(TOPLEFT, q4Parent, TOPLEFT, 0, 0)
        section:SetAnchor(TOPRIGHT, q4Parent, TOPRIGHT, 0, 0)
    end

    section:SetHidden(false)
    table.insert(self.q4ActiveControls, section)
    return section
end

---Adds a target row with name and value to Q4
---@param targetName string Target name
---@param value string Damage/healing value
---@param previousControl Control|nil Previous control to anchor below
---@return Control|nil row The row control
function OverviewPanel:AddTargetRow(targetName, value, previousControl)
    if not self.q4Container then return nil end
    return addLabelValueRow(targetName, value, previousControl, q4Parent, targetRows, "targetRow", "Target", self.q4ActiveControls)
end

---Adds an effect bar with icon, name, uptime bar, and stats (matches ability bar style)
---@param abilityId number Ability ID for icon/name lookup
---@param percent number Uptime percentage (0-100)
---@param previousControl Control|nil Previous control to anchor below
---@param stats { applications: number|nil, playerPercent: number|nil, maxStacks: number|nil, suffix: string|nil }|nil Optional stats for second row
---@param isFavorite boolean|nil Whether this effect is favorited
---@return Control|nil bar The bar control
function OverviewPanel:AddEffectBar(abilityId, percent, previousControl, stats, isFavorite)
    if not self.q3Container then return nil end

    usageCounters.effectBar = usageCounters.effectBar + 1
    local index = usageCounters.effectBar

    ensureControls(effectBars, index, "BattleScrolls_OverviewEffectBar", q3Parent, "Effect", "effectBar")
    local bar = effectBars[index]

    -- Set icon
    local icon = bar:GetNamedChild("Icon")
    local abilityIcon = GetAbilityIcon(abilityId)
    icon:SetTexture(abilityIcon)

    -- Set icon frame (square for active, circle for passive)
    SetupIconFrame(bar, abilityIcon)

    -- Show/hide favorite star
    local favoriteIcon = bar:GetNamedChild("FavoriteIcon")
    if favoriteIcon then
        favoriteIcon:SetHidden(not isFavorite)
    end

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
        bar:SetAnchor(TOPLEFT, q3Parent, TOPLEFT, 0, 0)
        bar:SetAnchor(TOPRIGHT, q3Parent, TOPRIGHT, 0, 0)
    end

    bar:SetHidden(false)
    table.insert(self.q3ActiveControls, bar)
    return bar
end

---Adds a compact effect row with icon, name, uptime, and stats (no progress bar, for narrow spaces)
---@param abilityId number Ability ID for icon/name lookup
---@param percent number Uptime percentage (0-100)
---@param previousControl Control|nil Previous control to anchor below
---@param stats { applications: number|nil, playerPercent: number|nil, maxStacks: number|nil, suffix: string|nil }|nil Optional stats
---@param isFavorite boolean|nil Whether this effect is favorited
---@return Control|nil row The row control
function OverviewPanel:AddEffectRow(abilityId, percent, previousControl, stats, isFavorite)
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

    -- Show/hide favorite star
    local favoriteIcon = row:GetNamedChild("FavoriteIcon")
    if favoriteIcon then
        favoriteIcon:SetHidden(not isFavorite)
    end

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
        row:SetAnchor(TOPLEFT, q4Parent, TOPLEFT, 0, 0)
        row:SetAnchor(TOPRIGHT, q4Parent, TOPRIGHT, 0, 0)
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
---@param isFavorite boolean|nil Whether this effect is favorited
---@return Control|nil row The row control
function OverviewPanel:AddQ2EffectRow(abilityId, percent, previousControl, stats, isFavorite)
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

    -- Show/hide favorite star
    local favoriteIcon = row:GetNamedChild("FavoriteIcon")
    if favoriteIcon then
        favoriteIcon:SetHidden(not isFavorite)
    end

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
        row:SetAnchor(TOPLEFT, q2Parent, TOPLEFT, 0, 0)
        row:SetAnchor(TOPRIGHT, q2Parent, TOPRIGHT, 0, 0)
    end

    row:SetHidden(false)
    table.insert(self.activeControls, row)
    return row
end

-------------------------
-- Group Member Cards (Full-width cards for group overview)
-------------------------

local GROUP_CARD_HEIGHT = 100
local GROUP_CARD_GAP = 10

-- Font cascades for group member card names
local GROUP_CARD_NAME_FONTS = {
    { font = "ZoFontGamepadBold27", lineLimit = 1 },
    { font = "ZoFontGamepadBold22", lineLimit = 1 },
    { font = "ZoFontGamepadBold18", lineLimit = 1, dontUseForAdjusting = true },
}

-- Font cascades for group member card info line
local GROUP_CARD_INFO_FONTS = {
    { font = "ZoFontGamepad22", lineLimit = 1 },
    { font = "ZoFontGamepad18", lineLimit = 1, dontUseForAdjusting = true },
}

---Adds a group member card with full combat data
---@param memberData { displayName: string, primaryMetric: number, primaryLabel: string, barPercent: number, shareText: string, infoLine: string }
---@param previousControl Control|nil Previous control to anchor below
---@return Control|nil card The card control or nil if no container
function OverviewPanel:AddGroupMemberCard(memberData, previousControl)
    if not self.q3Container then return nil end

    usageCounters.groupMemberCard = usageCounters.groupMemberCard + 1
    local index = usageCounters.groupMemberCard

    ensureControls(groupMemberCards, index, "BattleScrolls_GroupMemberCard", q3Parent, "GroupCard", "groupMemberCard")
    local card = groupMemberCards[index]

    -- Row 1: Name + Primary Metric
    local nameLabel = card:GetNamedChild("Name")
    if nameLabel.fontCascade ~= GROUP_CARD_NAME_FONTS then
        SetupFontAdjustingLabel(nameLabel, GROUP_CARD_NAME_FONTS)
        nameLabel.fontCascade = GROUP_CARD_NAME_FONTS
    end
    nameLabel:SetText(zo_strformat("<<C:1>>", memberData.displayName))
    nameLabel:SetHeight(26)

    local metricLabel = card:GetNamedChild("Metric")
    metricLabel:SetText(memberData.primaryLabel)
    metricLabel:SetFont("ZoFontGamepadBold27")
    metricLabel:SetHeight(26)

    -- Row 2: Relative bar + Share
    local statusBar = card:GetNamedChild("Bar")
    statusBar:SetMinMax(0, 100)
    statusBar:SetValue(memberData.barPercent)
    ZO_StatusBar_SetGradientColor(statusBar, ZO_XP_BAR_GRADIENT_COLORS)
    statusBar:ClearAnchors()
    statusBar:SetAnchor(TOPLEFT, card, TOPLEFT, 0, 34)
    statusBar:SetAnchor(TOPRIGHT, card, TOPRIGHT, -115, 34)
    statusBar:SetHeight(20)

    local shareLabel = card:GetNamedChild("Share")
    shareLabel:SetText(memberData.shareText)
    shareLabel:ClearAnchors()
    shareLabel:SetAnchor(TOPRIGHT, card, TOPRIGHT, 0, 34)
    shareLabel:SetHeight(20)

    -- Row 3: Combined info line (boss breakdown + stats)
    local infoLineLabel = card:GetNamedChild("InfoLine")
    if infoLineLabel.fontCascade ~= GROUP_CARD_INFO_FONTS then
        SetupFontAdjustingLabel(infoLineLabel, GROUP_CARD_INFO_FONTS)
        infoLineLabel.fontCascade = GROUP_CARD_INFO_FONTS
    end
    infoLineLabel:SetText(memberData.infoLine or "")
    infoLineLabel:ClearAnchors()
    infoLineLabel:SetAnchor(TOPLEFT, card, TOPLEFT, 0, 60)
    infoLineLabel:SetAnchor(TOPRIGHT, card, TOPRIGHT, 0, 60)
    infoLineLabel:SetHeight(20)

    -- Card sizing and anchoring
    card:SetHeight(GROUP_CARD_HEIGHT)
    card:ClearAnchors()
    if previousControl then
        q3ContentHeight = q3ContentHeight + GROUP_CARD_GAP
    else
        q3ContentHeight = 0
    end
    card:SetAnchor(TOPLEFT, q3Parent, TOPLEFT, Q3_CONTENT_INSET_X, q3ContentHeight)
    card:SetAnchor(TOPRIGHT, q3Parent, TOPRIGHT, -Q3_CONTENT_INSET_X, q3ContentHeight)
    q3ContentHeight = q3ContentHeight + GROUP_CARD_HEIGHT

    card:SetHidden(false)
    table.insert(self.groupMemberCardsActive, card)
    return card
end

-------------------------
-- Death Attack Rows (Q3)
-------------------------

local DEATH_ATTACK_ROW_HEIGHT = 42
local DEATH_ATTACK_ROW_GAP = 6
local DEATH_ICON_OFFSET_X = 40  -- Reserve space for 36px killing blow skull + 4px gap

---Adds a death attack row to Q3 (icon + ability name + damage value)
---Styled to match boss card row 1: bold name left, bold value right.
---All rows use consistent icon offset to keep alignment when skull is shown.
---@param attack SharedDeathRecapAttack Attack data with abilityId and damage
---@param previousControl Control|nil Previous control to anchor below
---@param isKillingBlow boolean|nil Whether this was the killing blow
---@return Control|nil row The row control or nil if no container
function OverviewPanel:AddDeathAttackRow(attack, previousControl, isKillingBlow)
    if not self.q3Container then return nil end

    usageCounters.deathAttackRow = usageCounters.deathAttackRow + 1
    local index = usageCounters.deathAttackRow

    ensureControls(deathAttackRows, index, "BattleScrolls_DeathAttackRow", q3Parent, "DeathAttack", "deathAttackRow")
    local row = deathAttackRows[index]

    -- Set icon at consistent offset (reserves space for killing blow skull on all rows)
    local icon = row:GetNamedChild("Icon")
    local abilityIcon = GetAbilityIcon(attack.abilityId)
    icon:SetTexture(abilityIcon)
    icon:ClearAnchors()
    icon:SetAnchor(LEFT, row, LEFT, DEATH_ICON_OFFSET_X, 0)

    -- Set icon frame (square for active, circle for passive)
    SetupIconFrame(row, abilityIcon)

    -- Show/hide killing blow skull (anchored to icon's left in XML)
    local killingBlowIcon = row:GetNamedChild("KillingBlow")
    if killingBlowIcon then
        killingBlowIcon:SetHidden(not isKillingBlow)
    end

    -- Set name (styled like boss name in boss cards)
    local nameLabel = row:GetNamedChild("Name")
    nameLabel:SetText(journal.utils.getAbilityDisplayName(attack.abilityId))

    -- Set damage value (absolute, styled like boss DPS in boss cards)
    local valueLabel = row:GetNamedChild("Value")
    valueLabel:SetText(journal.utils.formatCompact(attack.damage))

    -- Direct anchoring to ScrollChild
    row:ClearAnchors()
    if previousControl then
        q3ContentHeight = q3ContentHeight + DEATH_ATTACK_ROW_GAP
    else
        q3ContentHeight = 0
    end
    row:SetAnchor(TOPLEFT, q3Parent, TOPLEFT, Q3_CONTENT_INSET_X, q3ContentHeight)
    row:SetAnchor(TOPRIGHT, q3Parent, TOPRIGHT, -Q3_CONTENT_INSET_X, q3ContentHeight)
    q3ContentHeight = q3ContentHeight + DEATH_ATTACK_ROW_HEIGHT

    row:SetHidden(false)
    table.insert(self.q3ActiveControls, row)
    return row
end

-------------------------
-- Per-Tab Refresh Functions
-------------------------

---Refreshes the overview panel content based on current tab (async with loading state)
---@param journalUI BattleScrolls_Journal_Gamepad
---@param selectedData table|nil Selected entry data (passed directly to avoid race conditions)
function OverviewPanel:Refresh(journalUI, selectedData)
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

    -- For GROUP tab, use the selectedData passed directly (avoids race condition)
    -- Fall back to reading from list for backwards compatibility
    local selectedListData = nil
    if selectedTab == STATS_TAB.GROUP then
        selectedListData = selectedData or journalUI.statsList:GetSelectedData()
    end

    -- Build context for renderers
    local ctx = {
        arithmancer = arithmancer,
        encounter = decodedEncounter,
        durationS = durationS,
        unitNames = unitNames,
        abilityInfo = abilityInfo,
        filters = filters,
        selectedListData = selectedListData,
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
        elseif selectedTab == STATS_TAB.GROUP then
            renderers.group.refreshPanelForGroupPlayer(self, ctx):Await()
        end

        BattleScrolls.gc:RequestGC(5)
    end):Ensure(function()
        -- Fallback sync hide in case of cancellation/error
        self:HideLoading()
    end):Ensure(function()
        -- Always clear fiber reference
        self.fiber = nil
    end):Run()
end

-------------------------
-- Q2 Section Renderers
-- Composable section builders for overview panel Q2 quadrant.
-- Used by overview renderer and tab-specific panel refreshers.
-------------------------

local jutils = journal.utils

---Renders damage summary section (DPS, Group DPS, Share)
---@param sectionLabel string Section header label
---@param lastControl Control|nil Previous control for anchoring
---@param dps number Personal DPS
---@param groupDps number|nil Group DPS (nil if solo)
---@param share number Personal share percentage (0-100)
---@return Control lastControl The last rendered control
function OverviewPanel:renderDamageSummarySection(sectionLabel, lastControl, dps, groupDps, share)
    lastControl = self:AddSection(sectionLabel, lastControl)
    lastControl = self:AddStatRow(GetString(BATTLESCROLLS_STAT_DPS), jutils.formatNumber(dps), lastControl)
    if groupDps then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_STAT_GROUP_DPS), jutils.formatNumber(groupDps), lastControl)
    end
    lastControl = self:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_SHARE), jutils.formatPercent(share), lastControl)
    return lastControl
end

---Renders damage composition section (DOT/Direct, AOE/ST)
---@param lastControl Control|nil Previous control for anchoring
---@param dotPercent number|nil DOT damage percentage (0-100)
---@param directPercent number|nil Direct damage percentage (0-100)
---@param aoePercent number|nil AOE damage percentage (0-100)
---@param stPercent number|nil Single target damage percentage (0-100)
---@return Control lastControl The last rendered control
function OverviewPanel:renderDamageCompositionSection(lastControl, dotPercent, directPercent, aoePercent, stPercent)
    lastControl = self:AddSection(GetString(BATTLESCROLLS_OVERVIEW_COMPOSITION), lastControl)
    if directPercent and dotPercent then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_DELIVERY_DIRECT), jutils.formatPercent(directPercent), lastControl)
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_DELIVERY_DOT), jutils.formatPercent(dotPercent), lastControl)
    end
    if aoePercent and stPercent then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_AOE), jutils.formatPercent(aoePercent), lastControl)
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_SINGLE_TARGET), jutils.formatPercent(stPercent), lastControl)
    end
    return lastControl
end

---Renders damage quality section (Crit Rate, Max Hit)
---@param lastControl Control|nil Previous control for anchoring
---@param critRate number Crit rate percentage (0-100)
---@param maxHit number Maximum hit value
---@return Control lastControl The last rendered control
function OverviewPanel:renderDamageQualitySection(lastControl, critRate, maxHit)
    lastControl = self:AddSection(GetString(BATTLESCROLLS_OVERVIEW_QUALITY), lastControl)
    if critRate > 0 then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_CRIT_RATE), jutils.formatPercent(critRate), lastControl)
    end
    if maxHit > 0 then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_MAX_HIT), jutils.formatNumber(maxHit), lastControl)
    end
    return lastControl
end

---Renders damage taken summary section (DTPS, Total)
---@param lastControl Control|nil Previous control for anchoring
---@param dtps number Damage taken per second
---@param total number Total damage taken
---@return Control lastControl The last rendered control
function OverviewPanel:renderDamageTakenSummarySection(lastControl, dtps, total)
    lastControl = self:AddSection(GetString(BATTLESCROLLS_OVERVIEW_SUMMARY), lastControl)
    lastControl = self:AddStatRow(GetString(BATTLESCROLLS_STAT_DTPS), jutils.formatNumber(dtps), lastControl)
    lastControl = self:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_TOTAL), jutils.formatNumber(total), lastControl)
    return lastControl
end

---Renders healing summary section (Raw HPS, Effective HPS, Total)
---@param sectionLabel string|nil Section header label (defaults to "Summary")
---@param lastControl Control|nil Previous control for anchoring
---@param rawHps number Raw healing per second
---@param effectiveHps number Effective healing per second
---@param total number Total effective healing
---@return Control lastControl The last rendered control
function OverviewPanel:renderHealingSummarySection(sectionLabel, lastControl, rawHps, effectiveHps, total)
    lastControl = self:AddSection(sectionLabel or GetString(BATTLESCROLLS_OVERVIEW_SUMMARY), lastControl)
    lastControl = self:AddStatRow(GetString(BATTLESCROLLS_HEALING_RAW_HPS), jutils.formatNumber(rawHps), lastControl)
    lastControl = self:AddStatRow(GetString(BATTLESCROLLS_HEALING_EFFECTIVE_HPS), jutils.formatNumber(effectiveHps), lastControl)
    lastControl = self:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_TOTAL), jutils.formatNumber(total), lastControl)
    return lastControl
end

---Renders overheal row
---@param lastControl Control|nil Previous control for anchoring
---@param overhealPercent number Overheal percentage (0-100)
---@return Control lastControl The last rendered control
function OverviewPanel:renderOverhealRow(lastControl, overhealPercent)
    lastControl = self:AddStatRow(GetString(BATTLESCROLLS_HEALING_OVERHEAL), jutils.formatPercent(overhealPercent), lastControl)
    return lastControl
end

---Renders healing composition section (HoT vs Direct)
---@param lastControl Control|nil Previous control for anchoring
---@param hotPercent number|nil HoT healing percentage (0-100)
---@param directPercent number|nil Direct healing percentage (0-100)
---@return Control lastControl The last rendered control
function OverviewPanel:renderHealingCompositionSection(lastControl, hotPercent, directPercent)
    lastControl = self:AddSection(GetString(BATTLESCROLLS_OVERVIEW_COMPOSITION), lastControl)
    if hotPercent and directPercent then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_DELIVERY_HOT), jutils.formatPercent(hotPercent), lastControl)
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_DELIVERY_DIRECT), jutils.formatPercent(directPercent), lastControl)
    end
    return lastControl
end

---Renders healing quality section (Crit Rate, Max Heal)
---@param lastControl Control|nil Previous control for anchoring
---@param critRate number Crit rate percentage (0-100)
---@param maxHeal number Maximum heal value
---@return Control lastControl The last rendered control
function OverviewPanel:renderHealingQualitySection(lastControl, critRate, maxHeal)
    lastControl = self:AddSection(GetString(BATTLESCROLLS_OVERVIEW_QUALITY), lastControl)
    if critRate > 0 then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_CRIT_RATE), jutils.formatPercent(critRate), lastControl)
    end
    if maxHeal > 0 then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_MAX_HEAL), jutils.formatNumber(maxHeal), lastControl)
    end
    return lastControl
end

---Renders consolidated damage output section (DPS, Composition, Quality in one section)
---Used by Overview tab for a cleaner, more compact display
---@param lastControl Control|nil Previous control for anchoring
---@param bossDps number|nil Boss DPS (nil if not boss fight or no boss damage)
---@param totalDps number Total DPS
---@param groupDps number|nil Group DPS (nil if solo)
---@param share number Personal share percentage (0-100)
---@param critRate number Crit rate percentage (0-100)
---@param maxHit number Maximum hit value
---@param directPercent number|nil Direct damage percentage
---@param aoePercent number|nil AOE damage percentage
---@return Control lastControl The last rendered control
function OverviewPanel:renderDamageOutputSection(lastControl, bossDps, totalDps, groupDps, share, critRate, maxHit, directPercent, aoePercent)
    lastControl = self:AddSection(GetString(BATTLESCROLLS_OVERVIEW_DAMAGE_OUTPUT), lastControl)

    -- Boss DPS if applicable
    if bossDps and bossDps > 0 then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_BOSS_DAMAGE), jutils.formatNumber(bossDps) .. " DPS", lastControl)
    end

    -- Total DPS
    lastControl = self:AddStatRow(GetString(BATTLESCROLLS_DAMAGE_DONE), jutils.formatNumber(totalDps) .. " DPS", lastControl)

    -- Share (only if group data exists)
    if groupDps and groupDps > totalDps then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_SHARE), jutils.formatPercent(share), lastControl)
    end

    -- Quality metrics inline
    if critRate > 0 then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_CRIT_RATE), jutils.formatPercent(critRate), lastControl)
    end
    if maxHit > 0 then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_MAX_HIT), jutils.formatNumber(maxHit), lastControl)
    end

    -- Composition inline
    if directPercent then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_DELIVERY_DIRECT), jutils.formatPercent(directPercent), lastControl)
    end
    if aoePercent then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_AOE), jutils.formatPercent(aoePercent), lastControl)
    end

    return lastControl
end

---Renders healing section with overheal and HoT% inline (no separate sections)
---Used by Overview tab for a cleaner, more compact display
---@param sectionLabel string Section header label (e.g., "Healing Out", "Self Healing")
---@param lastControl Control|nil Previous control for anchoring
---@param rawHps number Raw healing per second
---@param effectiveHps number Effective healing per second
---@param overhealPercent number Overheal percentage (0-100)
---@param hotPercent number|nil HoT percentage (0-100), only shown if meaningful split
---@return Control lastControl The last rendered control
function OverviewPanel:renderHealingSectionCompact(sectionLabel, lastControl, rawHps, effectiveHps, overhealPercent, hotPercent)
    lastControl = self:AddSection(sectionLabel, lastControl)
    lastControl = self:AddStatRow(GetString(BATTLESCROLLS_HEALING_RAW_HPS), jutils.formatNumber(rawHps), lastControl)
    lastControl = self:AddStatRow(GetString(BATTLESCROLLS_HEALING_EFFECTIVE_HPS), jutils.formatNumber(effectiveHps), lastControl)
    lastControl = self:AddStatRow(GetString(BATTLESCROLLS_HEALING_OVERHEAL), jutils.formatPercent(overhealPercent), lastControl)
    if hotPercent then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_DELIVERY_HOT), jutils.formatPercent(hotPercent), lastControl)
    end
    return lastControl
end

---Renders damage taken section with proper header
---@param lastControl Control|nil Previous control for anchoring
---@param dtps number Damage taken per second
---@param total number Total damage taken
---@param deathCount number|nil Optional death count (shown if > 0)
---@return Control lastControl The last rendered control
function OverviewPanel:renderDamageTakenSection(lastControl, dtps, total, deathCount)
    lastControl = self:AddSection(GetString(BATTLESCROLLS_OVERVIEW_DAMAGE_TAKEN), lastControl)
    lastControl = self:AddStatRow(GetString(BATTLESCROLLS_STAT_DTPS), jutils.formatNumber(dtps), lastControl)
    lastControl = self:AddStatRow(GetString(BATTLESCROLLS_OVERVIEW_TOTAL), jutils.formatNumber(total), lastControl)
    if deathCount and deathCount > 0 then
        lastControl = self:AddStatRow(GetString(BATTLESCROLLS_STAT_DEATH_COUNT), tostring(deathCount), lastControl)
    end
    return lastControl
end
