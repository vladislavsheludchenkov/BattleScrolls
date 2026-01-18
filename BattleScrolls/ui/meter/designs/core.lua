if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}
BattleScrolls.dpsMeterDesigns = BattleScrolls.dpsMeterDesigns or {}

local registry = BattleScrolls.dpsMeterDesigns
local utils = BattleScrolls.dpsMeterUtils

-- ==================== Registry Storage ====================

---@type table<string, PersonalDesignModule>
registry.personal = {}

---@type table<string, GroupDesignModule>
registry.group = {}

---@type string[] Ordered list of personal design IDs
registry.personalOrder = {}

---@type string[] Ordered list of group design IDs
registry.groupOrder = {}

-- ==================== Registration Functions ====================

local REQUIRED_PERSONAL_METHODS = { "Initialize", "GetContainer", "Render", "Show", "Hide" }
local REQUIRED_GROUP_METHODS = { "Initialize", "GetContainer", "Render", "Show", "Hide", "Release" }

---Validate that a design module has all required methods
---@param design table
---@param requiredMethods string[]
---@param designType string "personal" or "group"
---@return boolean valid
---@return string|nil errorMessage
local function validateDesign(design, requiredMethods, designType)
    if not design.id then
        return false, string.format("%s design missing required 'id' field", designType)
    end
    if type(design.id) ~= "string" or design.id == "" then
        return false, string.format("%s design 'id' must be a non-empty string", designType)
    end
    if not design.displayName then
        return false, string.format("%s design '%s' missing required 'displayName' field", designType, design.id)
    end

    for _, method in ipairs(requiredMethods) do
        if type(design[method]) ~= "function" then
            return false, string.format("%s design '%s' missing required method: %s", designType, design.id, method)
        end
    end

    -- Validate settings if present
    if design.settings then
        if type(design.settings) ~= "table" then
            return false, string.format("Design '%s' settings must be a table", design.id)
        end
        for i, setting in ipairs(design.settings) do
            if not setting.id or not setting.displayName or not setting.options or not setting.default then
                return false, string.format("Design '%s' setting #%d missing required fields (id, displayName, options, default)", design.id, i)
            end
            if type(setting.options) ~= "table" or #setting.options < 2 then
                return false, string.format("Design '%s' setting '%s' must have at least 2 options", design.id, setting.id)
            end
        end
    end

    return true, nil
end

-- Safe logging helper (log module may not be initialized during registration)
local function safeLog(level, message)
    local log = BattleScrolls.log
    if log and log[level] then
        log[level](message)
    end
end

---Register a personal meter design
---@param design PersonalDesignModule
---@return boolean success
function registry.RegisterPersonalDesign(design)
    local valid, err = validateDesign(design, REQUIRED_PERSONAL_METHODS, "personal")
    if not valid then
        safeLog("Error", "DPSMeter: Cannot register personal design - " .. err)
        return false
    end

    if registry.personal[design.id] then
        safeLog("Error", "DPSMeter: Personal design with ID '" .. design.id .. "' already registered")
        return false
    end

    registry.personal[design.id] = design
    table.insert(registry.personalOrder, design.id)

    -- Sort by order field
    table.sort(registry.personalOrder, function(a, b)
        return (registry.personal[a].order or 100) < (registry.personal[b].order or 100)
    end)

    return true
end

---Register a group meter design
---@param design GroupDesignModule
---@return boolean success
function registry.RegisterGroupDesign(design)
    local valid, err = validateDesign(design, REQUIRED_GROUP_METHODS, "group")
    if not valid then
        safeLog("Error", "DPSMeter: Cannot register group design - " .. err)
        return false
    end

    if registry.group[design.id] then
        safeLog("Error", "DPSMeter: Group design with ID '" .. design.id .. "' already registered")
        return false
    end

    registry.group[design.id] = design
    table.insert(registry.groupOrder, design.id)

    -- Sort by order field
    table.sort(registry.groupOrder, function(a, b)
        return (registry.group[a].order or 100) < (registry.group[b].order or 100)
    end)

    return true
end

-- ==================== Discovery Functions ====================

---Get all registered personal design IDs in order
---@return string[]
function registry.GetPersonalDesignIds()
    return registry.personalOrder
end

---Get all registered group design IDs in order
---@return string[]
function registry.GetGroupDesignIds()
    return registry.groupOrder
end

---Get personal design by ID
---@param id string
---@return PersonalDesignModule|nil
function registry.GetPersonalDesign(id)
    return registry.personal[id]
end

---Get group design by ID
---@param id string
---@return GroupDesignModule|nil
function registry.GetGroupDesign(id)
    return registry.group[id]
end

-- ==================== Design Settings Access ====================

---Get a personal design setting value
---@param designId string
---@param settingId string
---@return any value
function registry.GetPersonalDesignSetting(designId, settingId)
    local settings = utils.GetSetting("dpsMeterPersonalDesignSettings")
    if settings and settings[designId] and settings[designId][settingId] ~= nil then
        return settings[designId][settingId]
    end

    -- Return default from design definition
    local design = registry.personal[designId]
    if design and design.settings then
        for _, setting in ipairs(design.settings) do
            if setting.id == settingId then
                return setting.default
            end
        end
    end

    return nil
end

---Set a personal design setting value
---@param designId string
---@param settingId string
---@param value any
function registry.SetPersonalDesignSetting(designId, settingId, value)
    local allSettings = utils.GetSettings()
    allSettings.dpsMeterPersonalDesignSettings = allSettings.dpsMeterPersonalDesignSettings or {}
    allSettings.dpsMeterPersonalDesignSettings[designId] = allSettings.dpsMeterPersonalDesignSettings[designId] or {}
    allSettings.dpsMeterPersonalDesignSettings[designId][settingId] = value

    -- Notify design of change
    local design = registry.personal[designId]
    if design and design.OnSettingChanged then
        design:OnSettingChanged(settingId, value)
    end
end

---Get a group design setting value
---@param designId string
---@param settingId string
---@return any value
function registry.GetGroupDesignSetting(designId, settingId)
    local settings = utils.GetSetting("dpsMeterGroupDesignSettings")
    if settings and settings[designId] and settings[designId][settingId] ~= nil then
        return settings[designId][settingId]
    end

    -- Return default from design definition
    local design = registry.group[designId]
    if design and design.settings then
        for _, setting in ipairs(design.settings) do
            if setting.id == settingId then
                return setting.default
            end
        end
    end

    return nil
end

---Set a group design setting value
---@param designId string
---@param settingId string
---@param value any
function registry.SetGroupDesignSetting(designId, settingId, value)
    local allSettings = utils.GetSettings()
    allSettings.dpsMeterGroupDesignSettings = allSettings.dpsMeterGroupDesignSettings or {}
    allSettings.dpsMeterGroupDesignSettings[designId] = allSettings.dpsMeterGroupDesignSettings[designId] or {}
    allSettings.dpsMeterGroupDesignSettings[designId][settingId] = value

    -- Notify design of change
    local design = registry.group[designId]
    if design and design.OnSettingChanged then
        design:OnSettingChanged(settingId, value)
    end
end

-- ==================== Initialization ====================

---Initialize all registered designs
---@param dpsMeter DPSMeter Reference to the main DPS meter module
function registry.InitializeAllDesigns(dpsMeter)
    for _, id in ipairs(registry.personalOrder) do
        local design = registry.personal[id]
        if design then
            design:Initialize(dpsMeter)
        end
    end

    for _, id in ipairs(registry.groupOrder) do
        local design = registry.group[id]
        if design then
            design:Initialize(dpsMeter)
        end
    end
end
