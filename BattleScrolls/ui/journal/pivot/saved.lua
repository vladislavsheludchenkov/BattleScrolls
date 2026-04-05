-----------------------------------------------------------
-- Pivot Saved Queries
-- Persistence for saved pivot queries in SavedVariables
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local pivot = BattleScrolls.journal.pivot
local storage = BattleScrolls.storage

local saved = {}
pivot.saved = saved

---Ensure the pivotQueries table exists in settings
---@return table<string, PivotQuery>
local function getStore()
    local settings = storage.savedVariables.settings
    if not settings.pivotQueries then
        settings.pivotQueries = {}
    end
    return settings.pivotQueries
end

---Deep copy a table (for saving queries without shared references)
---@param t table
---@return table
local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deepCopy(v)
    end
    return copy
end

---Save a query with the given name
---@param name string
---@param query PivotQuery
function saved.saveQuery(name, query)
    local store = getStore()
    store[name] = deepCopy(query)
end

---Load a query by name
---@param name string
---@return PivotQuery|nil
function saved.loadQuery(name)
    local store = getStore()
    local query = store[name]
    if query then
        return deepCopy(query)
    end
    return nil
end

---Get sorted list of saved query names
---@return string[]
function saved.listQueries()
    local store = getStore()
    local names = {}
    for name in pairs(store) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

---Delete a saved query by name
---@param name string
function saved.deleteQuery(name)
    local store = getStore()
    store[name] = nil
end

---Check if a query with the given name exists
---@param name string
---@return boolean
function saved.queryExists(name)
    local store = getStore()
    return store[name] ~= nil
end
