-----------------------------------------------------------
-- Control Pool
-- Generic grow-only control pool.
--
-- Controls are created on demand, never destroyed. Acquire()
-- returns controls hidden; the caller or mount() shows them.
-- ReleaseAll() hides everything for the next render pass.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}
BattleScrolls.journal = BattleScrolls.journal or {}

---@class ControlPool
---@field _controls Control[]
---@field _count number Controls in use this render pass
---@field _total number Total controls ever created
---@field _template string|nil Virtual template name (nil = plain CT_CONTROL)
---@field _parent Control Default parent for new controls
---@field _prefix string Control name prefix
---@field _onInit (fun(control: Control))|nil One-time init callback for new controls
local ControlPool = {}
ControlPool.__index = ControlPool

---Creates a new control pool.
---@param template string|nil XML virtual template name, or nil for plain CT_CONTROL containers
---@param parent Control Default parent control
---@param prefix string Short name prefix (prepended with "BS_")
---@param onInit (fun(control: Control))|nil Called once when a control is first created
---@return ControlPool
function ControlPool.new(template, parent, prefix, onInit)
    return setmetatable({
        _controls = {},
        _count = 0,
        _total = 0,
        _template = template,
        _parent = parent,
        _prefix = "BS_" .. prefix .. "_",
        _onInit = onInit,
    }, ControlPool)
end

---Acquires the next control (returned hidden). The caller or mount() shows it.
---Creates a new control if the pool is exhausted.
---@return Control
function ControlPool:Acquire()
    self._count = self._count + 1
    if self._count > #self._controls then
        self._total = self._total + 1
        local control
        if self._template then
            control = CreateControlFromVirtual(
                self._prefix .. self._total,
                self._parent,
                self._template
            )
        else
            control = CreateControl(
                self._prefix .. self._total,
                self._parent,
                CT_CONTROL
            )
        end
        control:SetHidden(true)
        self._controls[#self._controls + 1] = control
        if self._onInit then
            self._onInit(control)
        end
    end
    local control = self._controls[self._count]
    control:SetHidden(true)
    control:ClearAnchors()
    return control
end

---Hides all controls and resets the usage counter for the next render pass.
function ControlPool:ReleaseAll()
    for i = 1, #self._controls do
        self._controls[i]:SetHidden(true)
        self._controls[i]:ClearAnchors()
    end
    self._count = 0
end

BattleScrolls.journal.ControlPool = ControlPool
