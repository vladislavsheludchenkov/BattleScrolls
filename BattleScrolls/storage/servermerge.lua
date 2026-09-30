-- One-time structural merge of legacy profiles into one raw saved table.
-- Prepares a replacement root synchronously before consumers bind to storage.
-- Original tables stay untouched; only metadata that changes is copied.
-- Encoded payloads are reused; no codec, size walk, GC or async work here.
if not SemisPlaygroundCheckAccess() then return end

---@class ServerMergeModule
local serverMerge = {}
BattleScrolls.serverMerge = serverMerge

---@alias LegacyStorageRoot table<string, table<string, table<string, StorageData>>>

---@class ServerMergeSource
---@field worldName string
---@field accountName string Used only to choose the preferred legacy settings
---@field characterKey string Stable ordering for legacy storage branches
---@field data StorageData
---@field instanceIds table<number, number> Old index to merged index
---@field ownSetupKeys table<number, number> Old personal hash to merged pool key

---Copy query/scope shells to remap instance selections. Encounter timestamps
---stay unchanged, so their selection sets can be reused.
---@param query PivotQuery
---@param source ServerMergeSource
---@return PivotQuery
local function remapQuery(query, source)
    ---@type PivotQuery
    local copy = ZO_ShallowTableCopy(query)
    ---@type PivotScope
    local scope = ZO_ShallowTableCopy(query.scope)
    copy.scope = scope
    if scope.instanceIds then
        local ids = {}
        for oldId, selected in pairs(scope.instanceIds) do
            local newId = source.instanceIds[oldId]
            if selected and newId then ids[newId] = true end
        end
        scope.instanceIds = ids
    end
    return copy
end

---@param root LegacyStorageRoot|StorageData|nil
---@param displayName string
---@param currentWorld string
---@return StorageData data Flat storage before defaults, or the original if already flat
function serverMerge.prepare(root, displayName, currentWorld)
    if root and root.history then
        ---@cast root StorageData
        return root
    end
    ---@cast root LegacyStorageRoot|nil
    ---@type ServerMergeSource[]
    local sources = {}
    for world, accounts in pairs(root or {}) do
        for accountName, characters in pairs(accounts) do
            for characterKey, data in pairs(characters) do
                if type(data) == "table" and data.version == 4 and data.history then
                    sources[#sources + 1] = {
                        worldName = world, accountName = accountName, characterKey = characterKey, data = data,
                        instanceIds = {}, ownSetupKeys = {},
                    }
                end
            end
        end
    end
    if #sources == 0 then return {} end

    -- Prefer the current login's legacy settings/builds. The remaining
    -- branches have a deterministic order, including on a first visit.
    table.sort(sources, function(a, b)
        if a.accountName ~= b.accountName then
            if a.accountName == displayName then return true end
            if b.accountName == displayName then return false end
        end
        if a.worldName ~= b.worldName then
            if a.worldName == currentWorld then return true end
            if b.worldName == currentWorld then return false end
            return a.worldName < b.worldName
        end
        if a.accountName ~= b.accountName then return a.accountName < b.accountName end
        return a.characterKey < b.characterKey
    end)

    local storage = BattleScrolls.storage
    ---@type StorageSettings
    local settings = ZO_ShallowTableCopy(sources[1].data.settings)
    settings.favoriteEffects = {}
    settings.pivotQueries = {}
    -- The format migration must examine all imported encounters and builds.
    ---@type StorageData
    local merged = { version = 4, settings = settings, history = {}, ownSetups = {}, sharedSetups = {} }

    ---@type table<InstanceWithIndex, number>
    local positions = {}
    local maxPreset = storage.sizePresets[settings.storageSizePreset] or storage.sizePresets.medium
    -- Reserve every original query name before disambiguating duplicates.
    local reservedNames = {}
    for _, source in ipairs(sources) do
        local data = source.data
        local sourceSettings = data.settings
        for k, v in pairs(sourceSettings) do
            if settings[k] == nil then settings[k] = v end
        end
        local preset = storage.sizePresets[sourceSettings.storageSizePreset] or storage.sizePresets.medium
        if preset.memoryMiB > maxPreset.memoryMiB then maxPreset = preset end
        for id, favorite in pairs(sourceSettings.favoriteEffects or {}) do
            if favorite then settings.favoriteEffects[id] = true end
        end
        for name in pairs(sourceSettings.pivotQueries or {}) do reservedNames[name] = true end

        for hash, setup in pairs(data.ownSetups or {}) do
            source.ownSetupKeys[hash] = BattleScrolls.ownSetupPool.intern(merged.ownSetups, setup)
        end
        -- Shared builds deliberately trust the first (player, hash) entry.
        for player, byHash in pairs(data.sharedSetups or {}) do
            local target = merged.sharedSetups[player]
            if not target then
                target = {}
                merged.sharedSetups[player] = target
            end
            for hash, setup in pairs(byHash) do
                if not target[hash] then target[hash] = setup end
            end
        end
        for _, instance in ipairs(data.history) do
            merged.history[#merged.history + 1] = instance
            positions[instance] = #merged.history
        end
    end
    settings.storageSizePreset = maxPreset.key

    table.sort(merged.history, function(a, b)
        if a.timestampS ~= b.timestampS then return a.timestampS < b.timestampS end
        return positions[a] < positions[b]
    end)
    for index, instance in ipairs(merged.history) do positions[instance] = index end
    for _, source in ipairs(sources) do
        for _, instance in ipairs(source.data.history) do
            if instance.index then source.instanceIds[instance.index] = positions[instance] end
        end
        for name, query in pairs(source.data.settings.pivotQueries or {}) do
            local targetName = name
            if settings.pivotQueries[targetName] then
                local base = string.format("%s (%s)", name, source.worldName)
                targetName = base
                local suffix = 2
                while reservedNames[targetName] or settings.pivotQueries[targetName] do
                    targetName = string.format("%s (%d)", base, suffix)
                    suffix = suffix + 1
                end
            end
            settings.pivotQueries[targetName] = remapQuery(query, source)
        end
    end

    -- Copy changed metadata rather than editing records in the saved root.
    -- An engine timeout can stop us at any instruction, even without yields.
    for _, source in ipairs(sources) do
        for _, instance in ipairs(source.data.history) do
            ---@type InstanceWithIndex
            local copy = ZO_ShallowTableCopy(instance)
            copy.index = positions[instance]
            copy.worldName = instance.worldName or source.worldName
            copy.encounters = {}
            for index, encounter in ipairs(instance.encounters) do
                local hash = encounter._setupHash
                if hash and source.ownSetupKeys[hash] ~= hash then
                    -- Preserve both sides of old collisions. Missing entries
                    -- stay detached even if another server used the same hash.
                    encounter = ZO_ShallowTableCopy(encounter)
                    encounter._setupHash = source.ownSetupKeys[hash]
                end
                copy.encounters[index] = encounter
            end
            merged.history[copy.index] = copy
        end
    end
    merged.nextInstanceIndex = #merged.history + 1
    -- The flat result replaces every legacy container at publication. Its
    -- history field identifies the new layout; no completion flag is needed.
    return merged
end
