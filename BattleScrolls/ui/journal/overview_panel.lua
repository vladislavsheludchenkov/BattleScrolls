if not SemisPlaygroundCheckAccess() then
    return
end

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
---@field cf ComponentFactory
---@field fiber Effect|nil Async fiber for cancellation
---@field loadingLabel Control|nil
---@field q3Hidden boolean
---@field q4Hidden boolean
local OverviewPanel = ZO_InitializingObject:Subclass()

BattleScrolls_Journal_OverviewPanel = OverviewPanel

---@type table<string, fun(panel: BattleScrolls_Journal_OverviewPanel)>
local layoutHandlers = {
    ["three-column"] = function(_)
        -- Default: all columns visible, default widths (no-op)
    end,
    ["two-column"] = function(panel)
        panel:SetQ3Hidden(true)
    end,
    ["wide-right"] = function(panel)
        panel:SetQ4Hidden(true)
    end,
    ["wide-left"] = function(panel)
        panel:SetQ4Hidden(true)
        panel:SetQ2Width(700)
    end,
}

-------------------------
-- Initialization
-------------------------

function OverviewPanel:Initialize(control)
    self.control = control
    self.expectedParent = control:GetParent()

    -- Get references to three column containers
    self.q2Container = control:GetNamedChild("Q2Container")
    self.q3Container = control:GetNamedChild("Q3Container")
    self.q4Container = control:GetNamedChild("Q4Container")

    -- Loading label for async loading state
    self.loadingLabel = control:GetNamedChild("LoadingLabel")
    if self.loadingLabel then
        self.loadingLabel:SetText(GetString(BATTLESCROLLS_LIST_LOADING))
    end

    self.fiber = nil

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

    self.q3Hidden = false
    self.q4Hidden = false

    -- Create ComponentFactory
    self.cf = journal.ComponentFactory.new()
    self.cf:Initialize(self)
end

-------------------------
-- Layout Methods
-------------------------

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
            self.q4Container:SetAnchor(TOPLEFT, self.q2Container, TOPRIGHT, 50, 0)
            self.q4Container:SetAnchor(BOTTOMLEFT, self.q2Container, BOTTOMRIGHT, 50, 0)
        else
            self.q4Container:SetAnchor(TOPRIGHT, self.control, TOPRIGHT, -40, 54)
            self.q4Container:SetAnchor(BOTTOMRIGHT, self.control, BOTTOMRIGHT, -40, -10)
        end
    end
    if hidden then
        self.paneFullWidth = self.paneFullWidth or self.control:GetWidth()
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
            self.q3Container:SetAnchor(TOPLEFT, self.q2Container, TOPRIGHT, 50, 0)
            self.q3Container:SetAnchor(BOTTOMRIGHT, self.control, BOTTOMRIGHT, -40, -10)
        else
            self.q3Container:SetAnchor(TOPLEFT, self.q2Container, TOPRIGHT, 50, 0)
            self.q3Container:SetAnchor(BOTTOMRIGHT, self.q4Container, BOTTOMLEFT, -50, 0)
        end
    end
end

---Sets Q2 container width (stores original for restoration in Clear)
---@param width number
function OverviewPanel:SetQ2Width(width)
    if self.q2Container then
        self.q2OrigWidth = self.q2OrigWidth or self.q2Container:GetWidth()
        self.q2Container:SetWidth(width)
    end
end

-------------------------
-- Visibility and State
-------------------------

function OverviewPanel:Clear()
    self.cf:ReleaseAll()

    -- Restore Q2 width
    if self.q2OrigWidth and self.q2Container then
        self.q2Container:SetWidth(self.q2OrigWidth)
        self.q2OrigWidth = nil
    end

    -- Restore Q3/Q4 visibility and anchoring
    if self.q3Hidden then self:SetQ3Hidden(false) end
    if self.q4Hidden then self:SetQ4Hidden(false) end

    -- Reset scroll states
    for _, container in ipairs({self.q2Container, self.q3Container, self.q4Container}) do
        if container and container.ResetToTop then
            container:ResetToTop()
        end
    end

    BattleScrolls.gc:RequestGC(5)
end

function OverviewPanel:Show()
    self.control:SetHidden(false)
end

---Restores the panel to its original parent if it was re-parented away.
---Called by the Journal fragment callback as a failsafe.
function OverviewPanel:RestoreParent()
    if self.expectedParent and self.control:GetParent() ~= self.expectedParent then
        self.control:SetParent(self.expectedParent)
        self.control:SetAlpha(1)
    end
end

function OverviewPanel:Hide()
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
    if self.q2Container then self.q2Container:SetHidden(true) end
    if self.q3Container then self.q3Container:SetHidden(true) end
    if self.q4Container then self.q4Container:SetHidden(true) end
end

---Hides the loading indicator and shows content containers
function OverviewPanel:HideLoading()
    if self.loadingLabel then
        self.loadingLabel:SetHidden(true)
    end
    if self.q2Container then self.q2Container:SetHidden(false) end
    if self.q3Container then self.q3Container:SetHidden(self.q3Hidden) end
    if self.q4Container then self.q4Container:SetHidden(self.q4Hidden) end
end

-------------------------
-- Render
-------------------------

---Renders a panel spec: applies layout, then runs the build function asynchronously.
---@param spec PanelSpec|nil If nil, hides the panel loading state.
function OverviewPanel:Render(spec)
    -- Cancel any existing async load
    if self.fiber then
        self.fiber:Cancel()
        self.fiber = nil
    end

    -- Clear existing content
    self:Clear()

    if not spec then
        self:HideLoading()
        return
    end

    -- Show loading state
    self:ShowLoading()

    -- Apply layout
    local handler = layoutHandlers[spec.layout or "three-column"]
    if handler then handler(self) end

    -- Build content async
    local thisFiber
    self.fiber = LibEffect.Async(function()
        LibEffect.Yield():Await()
        local q2 = self.cf:column(self.q2ScrollChild)
        local q3 = self.cf:column(self.q3ScrollChild)
        local q4 = self.cf:column(self.q4ScrollChild)
        spec.build(q2, q3, q4)
        BattleScrolls.gc:RequestGC(5)
    end):Ensure(function()
        self:HideLoading()
    end):Ensure(function()
        if self.fiber == thisFiber then
            self.fiber = nil
        end
    end):Run()
    thisFiber = self.fiber
end

