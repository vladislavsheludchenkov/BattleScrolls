-----------------------------------------------------------
-- Setup Analysis
-- Shared gear analysis constants and pure data functions
--
-- Extracted from renderers/setup.lua so both the renderer
-- and setupshare.lua can reuse them.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

local setupAnalysis = {}
BattleScrolls.setupAnalysis = setupAnalysis

-- =============================================================================
-- CONSTANTS
-- =============================================================================

-- 2H weapon types (count as 2 pieces for set bonuses, hide off-hand)
setupAnalysis.TWO_HANDED_TYPES = {
    [WEAPONTYPE_TWO_HANDED_SWORD] = true,
    [WEAPONTYPE_TWO_HANDED_AXE] = true,
    [WEAPONTYPE_TWO_HANDED_HAMMER] = true,
    [WEAPONTYPE_FIRE_STAFF] = true,
    [WEAPONTYPE_FROST_STAFF] = true,
    [WEAPONTYPE_LIGHTNING_STAFF] = true,
    [WEAPONTYPE_HEALING_STAFF] = true,
    [WEAPONTYPE_BOW] = true,
}

-- Shared armor slot indices (for weight counting): HEAD(1), CHEST(3), SHOULDERS(4), WAIST(7), HAND(8), LEGS(9), FEET(10)
setupAnalysis.ARMOR_SLOT_INDICES = { 1, 3, 4, 7, 8, 9, 10 }

-- Slot classification for set piece counting
-- Shared slots contribute to both bars, front/back weapons to their respective bar only
setupAnalysis.SHARED_SLOT_INDICES = { 1, 2, 3, 4, 7, 8, 9, 10, 11, 12 }
setupAnalysis.FRONT_WEAPON_INDICES = { 5, 6 }
setupAnalysis.BACK_WEAPON_INDICES = { 13, 14 }

-- Main hand slot indices (for 2H detection)
setupAnalysis.FRONT_MAIN_HAND_INDEX = 5
setupAnalysis.BACK_MAIN_HAND_INDEX = 13

-- Slot classification for trait grouping by equipment category
setupAnalysis.JEWELRY_SLOT_INDICES = { 2, 11, 12 }

---@type table<number, number|string>
setupAnalysis.ENCHANT_OVERRIDES = {
    [179] = 37, -- Prismatic Recovery: broken category, force correct one
    [178] = "|H1:item:166046:370:50:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0|h|h", -- Prismatic Cost Reduction: no valid category, resolve via glyph link
}

-- Local aliases for performance
local TWO_HANDED_TYPES = setupAnalysis.TWO_HANDED_TYPES
local ARMOR_SLOT_INDICES = setupAnalysis.ARMOR_SLOT_INDICES
local SHARED_SLOT_INDICES = setupAnalysis.SHARED_SLOT_INDICES
local FRONT_WEAPON_INDICES = setupAnalysis.FRONT_WEAPON_INDICES
local BACK_WEAPON_INDICES = setupAnalysis.BACK_WEAPON_INDICES
local FRONT_MAIN_HAND_INDEX = setupAnalysis.FRONT_MAIN_HAND_INDEX
local BACK_MAIN_HAND_INDEX = setupAnalysis.BACK_MAIN_HAND_INDEX
local ENCHANT_OVERRIDES = setupAnalysis.ENCHANT_OVERRIDES

-- =============================================================================
-- HELPERS
-- =============================================================================

---Extracts set ID from an item link, returns 0 if not a set item
---@param link string
---@return number setId
local function getSetIdFromLink(link)
    local hasSet, _, _, _, _, setId = GetItemLinkSetInfo(link, true)
    return (hasSet and setId > 0) and setId or 0
end

-- =============================================================================
-- SET DATA
-- =============================================================================

---@class SetBarData
---@field frontCount number Piece count on front bar
---@field backCount number Piece count on back bar
---@field perfectedFrontCount number Perfected piece count on front bar
---@field perfectedBackCount number Perfected piece count on back bar
---@field frontStep number Highest active bonus threshold for front bar
---@field backStep number Highest active bonus threshold for back bar
---@field perfectedActiveFront boolean Whether perfected bonus is active on front
---@field perfectedActiveBack boolean Whether perfected bonus is active on back
---@field perfectedSetId number|nil Raw perfected setId for bonus queries
---@field name string Set display name

---Computes per-set piece counts and active bonus data across both bars.
---Groups by unperfected setId; derives perfected status from raw setIds at display time.
---@param equipSlots (string|false)[]
---@return table<number, SetBarData> setData Keyed by unperfected setId
function setupAnalysis.computeSetData(equipSlots)
    local setData = {}

    ---Adds piece contribution to a set for a given bar
    ---@param rawSetId number Raw setId from equipment (may be perfected)
    ---@param bar "front"|"back"
    ---@param count number Pieces to add (1 for normal, 2 for 2H)
    local function addPiece(rawSetId, bar, count)
        if rawSetId == 0 then return end
        local unperfectedId = GetItemSetUnperfectedSetId(rawSetId)
        local isPerfected = unperfectedId > 0
        local groupId = isPerfected and unperfectedId or rawSetId

        if not setData[groupId] then
            setData[groupId] = {
                frontCount = 0,
                backCount = 0,
                perfectedFrontCount = 0,
                perfectedBackCount = 0,
                frontStep = 0,
                backStep = 0,
                perfectedActiveFront = false,
                perfectedActiveBack = false,
                perfectedSetId = nil,
                name = zo_strformat("<<C:1>>", GetItemSetName(groupId)),
            }
        end
        local data = setData[groupId]
        if isPerfected then data.perfectedSetId = rawSetId end
        if bar == "front" then
            data.frontCount = data.frontCount + count
        else
            data.backCount = data.backCount + count
        end
        if isPerfected then
            if bar == "front" then
                data.perfectedFrontCount = data.perfectedFrontCount + count
            else
                data.perfectedBackCount = data.perfectedBackCount + count
            end
        end
    end

    -- Process shared slots (contribute to both bars)
    for _, slotIdx in ipairs(SHARED_SLOT_INDICES) do
        local link = equipSlots[slotIdx]
        if link then
            local setId = getSetIdFromLink(link)
            if setId > 0 then
                addPiece(setId, "front", 1)
                addPiece(setId, "back", 1)
            end
        end
    end

    -- Process front weapon slots
    for _, slotIdx in ipairs(FRONT_WEAPON_INDICES) do
        local link = equipSlots[slotIdx]
        if link then
            local setId = getSetIdFromLink(link)
            if setId > 0 then
                local count = 1
                if slotIdx == FRONT_MAIN_HAND_INDEX and TWO_HANDED_TYPES[GetItemLinkWeaponType(link)] then
                    count = 2
                end
                addPiece(setId, "front", count)
            end
        end
    end

    -- Process back weapon slots
    for _, slotIdx in ipairs(BACK_WEAPON_INDICES) do
        local link = equipSlots[slotIdx]
        if link then
            local setId = getSetIdFromLink(link)
            if setId > 0 then
                local count = 1
                if slotIdx == BACK_MAIN_HAND_INDEX and TWO_HANDED_TYPES[GetItemLinkWeaponType(link)] then
                    count = 2
                end
                addPiece(setId, "back", count)
            end
        end
    end

    -- Compute active bonus thresholds and perfected status per bar
    for groupId, data in pairs(setData) do
        local querySetId = data.perfectedSetId or groupId
        local _, _, numBonuses = GetItemSetInfo(querySetId)

        for i = 1, numBonuses do
            local numRequired, _, isPerfectedBonus = GetItemSetBonusInfo(querySetId, i)
            if not isPerfectedBonus then
                if data.frontCount >= numRequired then
                    data.frontStep = math.max(data.frontStep, numRequired)
                end
                if data.backCount >= numRequired then
                    data.backStep = math.max(data.backStep, numRequired)
                end
            else
                if data.perfectedFrontCount >= numRequired then
                    data.perfectedActiveFront = true
                end
                if data.perfectedBackCount >= numRequired then
                    data.perfectedActiveBack = true
                end
            end
        end
    end

    return setData
end

-- =============================================================================
-- ARMOR WEIGHTS
-- =============================================================================

---Counts armor types across armor slots
---@param equipSlots (string|false)[]
---@return number light, number medium, number heavy
function setupAnalysis.countArmorWeights(equipSlots)
    local light, medium, heavy = 0, 0, 0
    for _, slotIdx in ipairs(ARMOR_SLOT_INDICES) do
        local link = equipSlots[slotIdx]
        if link then
            local armorType = GetItemLinkArmorType(link)
            if armorType == ARMORTYPE_LIGHT then
                light = light + 1
            elseif armorType == ARMORTYPE_MEDIUM then
                medium = medium + 1
            elseif armorType == ARMORTYPE_HEAVY then
                heavy = heavy + 1
            end
        end
    end
    return light, medium, heavy
end

-- =============================================================================
-- TRAITS
-- =============================================================================

---Groups and formats traits from equipment slots
---@param equipSlots (string|false)[]
---@param slotIndices? number[] Specific slot indices to examine (defaults to all slots)
---@return string formatted Trait summary (e.g. "4x Divines, 2x Sturdy")
function setupAnalysis.groupTraits(equipSlots, slotIndices)
    local traitCounts = {}
    local traitOrder = {}
    local indices = slotIndices or {}
    if not slotIndices then
        for i = 1, #equipSlots do
            table.insert(indices, i)
        end
    end
    for _, i in ipairs(indices) do
        local link = equipSlots[i]
        if link then
            local trait = GetItemLinkTraitType(link)
            if trait and trait > 0 then
                if not traitCounts[trait] then
                    traitCounts[trait] = 0
                    table.insert(traitOrder, trait)
                end
                traitCounts[trait] = traitCounts[trait] + 1
            end
        end
    end

    local details = {}
    for _, trait in ipairs(traitOrder) do
        local name = zo_strformat("<<1>>", GetString("SI_ITEMTRAITTYPE", trait))
        table.insert(details, { trait = trait, count = traitCounts[trait], name = name })
    end
    table.sort(details, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.name < b.name
    end)

    local parts = {}
    for _, detail in ipairs(details) do
        table.insert(parts, string.format("%dx %s", detail.count, detail.name))
    end

    return table.concat(parts, ", ")
end

---Groups trait IDs from equipment slots (numeric-only, for CompactSetup conversion)
---@param equipSlots (string|false)[]
---@param slotIndices number[] Slot indices to examine
---@return CompactTraitEntry[] entries Sorted by count descending
function setupAnalysis.groupTraitIds(equipSlots, slotIndices)
    local traitCounts = {}
    local traitOrder = {}
    for _, i in ipairs(slotIndices) do
        local link = equipSlots[i]
        if link then
            local trait = GetItemLinkTraitType(link)
            if trait and trait > 0 then
                if not traitCounts[trait] then
                    traitCounts[trait] = 0
                    table.insert(traitOrder, trait)
                end
                traitCounts[trait] = traitCounts[trait] + 1
            end
        end
    end

    ---@type CompactTraitEntry[]
    local result = {}
    for _, trait in ipairs(traitOrder) do
        table.insert(result, { traitType = trait, count = traitCounts[trait] })
    end
    table.sort(result, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.traitType < b.traitType
    end)
    return result
end

-- =============================================================================
-- ENCHANTS
-- =============================================================================

---Resolves enchant display name from an enchant ID using overrides and category lookup.
---Returns nil when the name cannot be resolved (caller decides on fallback).
---@param enchantId number
---@return string|nil name Short enchant name, or nil if unresolvable
local function resolveEnchantName(enchantId)
    local override = ENCHANT_OVERRIDES[enchantId]
    if type(override) == "number" then
        local raw = GetString("SI_ENCHANTMENTSEARCHCATEGORYTYPE", override)
        if raw and raw ~= "" then
            return zo_strformat("<<1>>", raw)
        end
    elseif type(override) == "string" then
        -- Item link override for enchants with no valid search category
        local _, header = GetItemLinkEnchantInfo(override)
        if header and header ~= "" then
            return zo_strformat("<<1>>", header)
        end
    elseif override == nil then
        local category = GetEnchantSearchCategoryType(enchantId)
        if not category or category == ENCHANTMENT_SEARCH_CATEGORY_NONE then return nil end
        local raw = GetString("SI_ENCHANTMENTSEARCHCATEGORYTYPE", category)
        if raw and raw ~= "" then
            return zo_strformat("<<1>>", raw)
        end
    end
    return nil
end

---Gets the short enchant category name from an item link.
---Uses the enchantment search category (e.g. "Berserker", "Prismatic Defense")
---instead of the verbose tooltip header ("Multi-Effect Enchantment").
---@param link string Item link
---@return string name Short enchant name, or "" if no enchant
function setupAnalysis.getEnchantName(link)
    local enchantId = GetItemLinkFinalEnchantId(link)
    if not enchantId or enchantId == 0 then return "" end

    local name = resolveEnchantName(enchantId)
    if name then return name end

    -- Fallback: extract name from the equipped item's enchant header
    local _, header = GetItemLinkEnchantInfo(link)
    if header and header ~= "" then
        return zo_strformat("<<1>>", header)
    end
    return ""
end

---Gets the short enchant category name from an enchant ID (no item link required).
---Used by receiver to resolve display names from wire enchantIds.
---@param enchantId number The enchant ID from GetItemLinkFinalEnchantId
---@return string name Short enchant name, or "" if unknown
function setupAnalysis.getEnchantNameById(enchantId)
    if not enchantId or enchantId == 0 then return "" end
    return resolveEnchantName(enchantId) or ""
end

---Groups and formats enchants from equipment slots (same pattern as groupTraits)
---@param equipSlots (string|false)[]
---@param slotIndices number[] Specific slot indices to examine
---@return string formatted Enchant summary (e.g. "3x Prismatic Defense, 2x Stamina")
function setupAnalysis.groupEnchants(equipSlots, slotIndices)
    local enchantCounts = {}
    local enchantOrder = {}
    for _, i in ipairs(slotIndices) do
        local link = equipSlots[i]
        if link then
            local name = setupAnalysis.getEnchantName(link)
            if name ~= "" then
                if not enchantCounts[name] then
                    enchantCounts[name] = 0
                    table.insert(enchantOrder, name)
                end
                enchantCounts[name] = enchantCounts[name] + 1
            end
        end
    end

    local details = {}
    for _, name in ipairs(enchantOrder) do
        table.insert(details, { name = name, count = enchantCounts[name] })
    end
    table.sort(details, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.name < b.name
    end)

    local parts = {}
    for _, detail in ipairs(details) do
        table.insert(parts, string.format("%dx %s", detail.count, detail.name))
    end

    return table.concat(parts, ", ")
end

---Groups enchant IDs from equipment slots (numeric-only, for CompactSetup conversion)
---@param equipSlots (string|false)[]
---@param slotIndices number[] Slot indices to examine
---@return CompactEnchantEntry[] entries Sorted by count descending
function setupAnalysis.groupEnchantIds(equipSlots, slotIndices)
    local enchantCounts = {}
    local enchantOrder = {}
    for _, i in ipairs(slotIndices) do
        local link = equipSlots[i]
        if link then
            local enchantId = GetItemLinkFinalEnchantId(link)
            if enchantId and enchantId > 0 then
                if not enchantCounts[enchantId] then
                    enchantCounts[enchantId] = 0
                    table.insert(enchantOrder, enchantId)
                end
                enchantCounts[enchantId] = enchantCounts[enchantId] + 1
            end
        end
    end

    ---@type CompactEnchantEntry[]
    local result = {}
    for _, enchantId in ipairs(enchantOrder) do
        table.insert(result, { enchantId = enchantId, count = enchantCounts[enchantId] })
    end
    table.sort(result, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.enchantId < b.enchantId
    end)
    return result
end
