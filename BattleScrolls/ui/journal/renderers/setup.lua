-----------------------------------------------------------
-- Setup Renderer
-- Renders the Setup tab: abilities, gear items, champion, poisons
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal
local constants = BattleScrolls.constants
local FOOD_ABILITY_INFO = constants.foodAbilityInfo
local FOOD_COMBO_STRINGS = constants.FOOD_COMBO_STRINGS
local RACE_ICONS = constants.raceIcons

local analysis = BattleScrolls.setupAnalysis

local setup = {}
journal.renderers.setup = setup

---Extracts the PotionEffect field (field 20) from an item link.
---@param itemLink string
---@return number potionEffect The packed effect integer (0 if not found)
local function getPotionEffect(itemLink)
    return tonumber(itemLink:match(":(%d+)|h")) or 0
end

---Returns the localized alchemy trait name for the given effect ID (1-32).
---@param effectId number
---@return string
local function getAlchemyTraitName(effectId)
    local stringId = _G["BATTLESCROLLS_ALCHEMY_TRAIT" .. effectId]
    return stringId and GetString(stringId) or ""
end

---Parses effect IDs from a PotionEffect integer (up to 3 packed bytes).
---@param potionEffect number The packed PotionEffect integer
---@return number[] effectIds Array of 1-based effect IDs (1-32 range)
local function parsePoisonEffects(potionEffect)
    if potionEffect == 0 then return {} end
    local effects = {}
    local byte3 = zo_floor(potionEffect / 65536) % 128  -- bits 16-22 (mask out 3-reagent flag at bit 23)
    local byte2 = zo_floor(potionEffect / 256) % 256     -- bits 8-15
    local byte1 = potionEffect % 256                      -- bits 0-7
    if byte3 > 0 then effects[#effects + 1] = byte3 end
    if byte2 > 0 then effects[#effects + 1] = byte2 end
    if byte1 > 0 then effects[#effects + 1] = byte1 end
    return effects
end

---Builds a display label for a poison from its item link.
---Returns trait names joined with " + " for crafted poisons, or item name for unique poisons.
---@param itemLink string
---@return string label Display label
---@return string icon Icon texture path
local function getPoisonDisplay(itemLink)
    local potionEffect = getPotionEffect(itemLink)
    local icon = GetItemLinkIcon(itemLink)
    if potionEffect > 0 then
        -- Crafted poison: show trait names
        local effects = parsePoisonEffects(potionEffect)
        local names = {}
        for _, effectId in ipairs(effects) do
            local name = getAlchemyTraitName(effectId)
            if name ~= "" then
                names[#names + 1] = name
            end
        end
        return table.concat(names, " + "), icon
    else
        -- Unique poison: show item name
        return zo_strformat("<<C:1>>", GetItemLinkName(itemLink)), icon
    end
end

-- Import shared constants from setup_analysis
local TWO_HANDED_TYPES = analysis.TWO_HANDED_TYPES
local ARMOR_SLOT_INDICES = analysis.ARMOR_SLOT_INDICES
local FRONT_MAIN_HAND_INDEX = analysis.FRONT_MAIN_HAND_INDEX
local BACK_MAIN_HAND_INDEX = analysis.BACK_MAIN_HAND_INDEX
local JEWELRY_SLOT_INDICES = analysis.JEWELRY_SLOT_INDICES

-- Import shared functions from setup_analysis
local computeSetData = analysis.computeSetData
local countArmorWeights = analysis.countArmorWeights
local groupTraits = analysis.groupTraits
local getEnchantName = analysis.getEnchantName
local getEnchantNameById = analysis.getEnchantNameById
local groupEnchants = analysis.groupEnchants

-- Warfare → Fitness → Craft (Craft last so it clips first if space is tight)
local DISCIPLINE_SORT = {
    [CHAMPION_DISCIPLINE_TYPE_COMBAT] = 1,       -- Warfare
    [CHAMPION_DISCIPLINE_TYPE_CONDITIONING] = 2, -- Fitness
    [CHAMPION_DISCIPLINE_TYPE_WORLD] = 3,        -- Craft
}

---Groups champion skills by discipline, sorted Warfare → Fitness → Craft.
---@param skills PlayerSetupChampionSkill[]
---@return table<number, PlayerSetupChampionSkill[]> disciplines Keyed by disciplineId
---@return number[] disciplineOrder Ordered discipline IDs
local function groupChampionByDiscipline(skills)
    local disciplines = {}
    local disciplineOrder = {}
    for _, skill in ipairs(skills) do
        if not disciplines[skill.disciplineId] then
            disciplines[skill.disciplineId] = {}
            table.insert(disciplineOrder, skill.disciplineId)
        end
        table.insert(disciplines[skill.disciplineId], skill)
    end
    table.sort(disciplineOrder, function(a, b)
        local typeA = GetChampionDisciplineType(a)
        local typeB = GetChampionDisciplineType(b)
        return (DISCIPLINE_SORT[typeA] or 99) < (DISCIPLINE_SORT[typeB] or 99)
    end)
    return disciplines, disciplineOrder
end

-- Fallback champion icon
local CHAMPION_ICON = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_champion.dds"

-- Inline icon size for text rows (race, class, mundus, food, scribing)
local INLINE_ICON_SIZE = 28

-- Left indent for Q3 detail lines under sub-headers
local Q3_INDENT = 16

-- Custom display names for 2H weapons (ESO's SI_WEAPONTYPE gives generic 1H names)
local TWO_HANDED_WEAPON_NAMES = {
    [WEAPONTYPE_TWO_HANDED_SWORD] = BATTLESCROLLS_WEAPON_GREATSWORD,
    [WEAPONTYPE_TWO_HANDED_AXE] = BATTLESCROLLS_WEAPON_BATTLE_AXE,
    [WEAPONTYPE_TWO_HANDED_HAMMER] = BATTLESCROLLS_WEAPON_MAUL,
}

-- ESO slot IDs mapped from our data index → equip slot constant
local INDEX_TO_ESO_SLOT = {
    [1]  = EQUIP_SLOT_HEAD,
    [2]  = EQUIP_SLOT_NECK,
    [3]  = EQUIP_SLOT_CHEST,
    [4]  = EQUIP_SLOT_SHOULDERS,
    [5]  = EQUIP_SLOT_MAIN_HAND,
    [6]  = EQUIP_SLOT_OFF_HAND,
    [7]  = EQUIP_SLOT_WAIST,
    [8]  = EQUIP_SLOT_HAND,
    [9]  = EQUIP_SLOT_LEGS,
    [10] = EQUIP_SLOT_FEET,
    [11] = EQUIP_SLOT_RING1,
    [12] = EQUIP_SLOT_RING2,
    [13] = EQUIP_SLOT_BACKUP_MAIN,
    [14] = EQUIP_SLOT_BACKUP_OFF,
}

-- Display order for gear items (matches armory gamepad order from GAMPAD_EQUIPMENT_SLOT_TYPES)
local GEAR_DISPLAY_ORDER = {
    -- Weapons
    { index = 5,  category = EQUIP_SLOT_VISUAL_CATEGORY_WEAPONS },
    { index = 6,  category = EQUIP_SLOT_VISUAL_CATEGORY_WEAPONS },
    { index = 13, category = EQUIP_SLOT_VISUAL_CATEGORY_WEAPONS },
    { index = 14, category = EQUIP_SLOT_VISUAL_CATEGORY_WEAPONS },
    -- Apparel (armor)
    { index = 1,  category = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL },
    { index = 3,  category = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL },
    { index = 4,  category = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL },
    { index = 7,  category = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL },
    { index = 8,  category = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL },
    { index = 9,  category = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL },
    { index = 10, category = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL },
    -- Accessories (jewelry)
    { index = 2,  category = EQUIP_SLOT_VISUAL_CATEGORY_ACCESSORIES },
    { index = 11, category = EQUIP_SLOT_VISUAL_CATEGORY_ACCESSORIES },
    { index = 12, category = EQUIP_SLOT_VISUAL_CATEGORY_ACCESSORIES },
}

-------------------------
-- Set Data Display
-------------------------

---Sorts sets by max piece count descending, filters to active, formats each line.
---Name is colorized with COLOR_TYPE; count and bar indicator are plain (for COLOR_TRAIT rows).
---@param equipSlots (string|false)[]
---@return string[] lines Formatted set strings (e.g. "5x |cFFFFFF Pillar of Nirn|r (Back Bar)")
local function formatActiveSets(equipSlots)
    local sets = computeSetData(equipSlots)

    local sortedSets = {}
    for setId, data in pairs(sets) do
        sortedSets[#sortedSets + 1] = { setId = setId, data = data }
    end
    table.sort(sortedSets, function(a, b)
        local aMax = math.max(a.data.frontCount, a.data.backCount)
        local bMax = math.max(b.data.frontCount, b.data.backCount)
        if aMax ~= bMax then return aMax > bMax end
        return a.data.name < b.data.name
    end)

    local result = {}
    for _, setEntry in ipairs(sortedSets) do
        local data = setEntry.data
        if data.frontStep > 0 or data.backStep > 0 then
            local isPerfected = data.perfectedActiveFront or data.perfectedActiveBack
            local name = (isPerfected and data.perfectedSetId)
                and zo_strformat("<<C:1>>", GetItemSetName(data.perfectedSetId))
                or data.name
            local coloredName = ZO_SELECTED_TEXT:Colorize(name)

            local line
            if data.frontStep == data.backStep then
                line = string.format("%dx %s", data.frontStep, coloredName)
            elseif data.frontStep == 0 then
                line = string.format("%dx %s (%s)", data.backStep, coloredName,
                    GetString(BATTLESCROLLS_SETUP_BACK_BAR))
            elseif data.backStep == 0 then
                line = string.format("%dx %s (%s)", data.frontStep, coloredName,
                    GetString(BATTLESCROLLS_SETUP_FRONT_BAR))
            else
                line = string.format("%dx/%dx %s", data.frontStep, data.backStep, coloredName)
            end

            result[#result + 1] = line
        end
    end
    return result
end

---Resolves race and class display info from IDs.
---@param raceId number
---@param classId number
---@return string raceName, string className, string raceIcon, string classIcon
local function resolveRaceClass(raceId, classId)
    local gender = GetUnitGender("player")
    local raceName = zo_strformat("<<1>>", GetRaceName(gender, raceId))
    local className = zo_strformat("<<1>>", GetClassName(gender, classId))
    local raceIcon = RACE_ICONS[raceId] or ""
    local classIcon = ""
    local classIndex = GetClassIndexById(classId)
    if classIndex then
        local _, _, _, _, _, _, _, ingameIconGamepad = GetClassInfo(classIndex)
        classIcon = ingameIconGamepad or ""
    end
    return raceName, className, raceIcon, classIcon
end

---Resolves class skill line display info (name + collectible icon).
---@param classSkillLineIds number[]
---@return { name: string, icon: string }[]
local function resolveClassSkillLines(classSkillLineIds)
    local result = {}
    for _, skillLineId in ipairs(classSkillLineIds) do
        if skillLineId > 0 then
            local name = GetSkillLineNameById(skillLineId)
            if name and name ~= "" then
                local formatted = ZO_CachedStrFormat(SI_SKILLS_ENTRY_LINE_NAME_FORMAT, name)
                local icon = ""
                local collectibleId = GetSkillLineMasteryCollectibleId(skillLineId)
                if collectibleId and collectibleId > 0 then
                    icon = GetCollectibleIcon(collectibleId) or ""
                end
                result[#result + 1] = { name = formatted, icon = icon }
            end
        end
    end
    return result
end

---Resolves food display info from a food entry.
---@param food PlayerSetupFood
---@param playerAliveTimeMs number|nil Player alive time in ms (for uptime calculation, matches effects tab)
---@return string name, string icon, string|nil uptimeSuffix, string|nil itemLink
local function resolveFoodDisplay(food, playerAliveTimeMs)
    local info = FOOD_ABILITY_INFO[food.abilityId]
    local itemId = type(info) == "number" and info or nil
    local statIds = type(info) == "table" and info or nil
    local itemLink = itemId
        and string.format("|H1:item:%d:1:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", itemId)
        or nil
    local name
    if itemLink then
        local rawName = GetItemLinkName(itemLink)
        name = rawName ~= "" and zo_strformat("<<C:1>>", rawName) or ""
    elseif statIds then
        local key = table.concat(statIds, ",")
        local stringId = FOOD_COMBO_STRINGS[key]
        name = stringId and GetString(stringId) or ""
    else
        local rawName = GetAbilityName(food.abilityId, "")
        name = rawName ~= "" and zo_strformat("<<C:1>>", rawName) or ""
    end
    local icon = itemLink
        and GetItemLinkIcon(itemLink)
        or GetAbilityIcon(food.abilityId)
    local uptimeSuffix = nil
    if food.uptimeMs and playerAliveTimeMs and playerAliveTimeMs > 0 then
        local uptimePercent = food.uptimeMs / playerAliveTimeMs * 100
        if uptimePercent < 99.75 then
            uptimeSuffix = string.format(" · %.0f%%", uptimePercent)
        end
    end
    return name or "", icon or "", uptimeSuffix, itemLink
end

---Builds inline icon markup for text rows
---@param texture string
---@return string
local function inlineIcon(texture)
    return string.format("|t%d:%d:%s|t ", INLINE_ICON_SIZE, INLINE_ICON_SIZE, texture)
end

---Gets the constellation icon for a mundus stone ability (matches ESO character screen).
---Falls back to ability icon if lookup fails.
---@param abilityId number
---@return string icon
local function getMundusConstellationIcon(abilityId)
    local mundusType = GetAbilityMundusStoneType(abilityId)
    if mundusType and ZO_STAT_MUNDUS_ICONS then
        local icon = ZO_STAT_MUNDUS_ICONS[mundusType]
        if icon then return icon end
    end
    return GetAbilityIcon(abilityId)
end

---Builds the CHARACTER section (race/class, skill lines, mundus, food).
---@param col ColumnBuilder
---@param setupData PlayerSetup
---@param playerAliveTimeMs number|nil
---@return Control|nil section
local function buildCharacterSection(col, setupData, playerAliveTimeMs)
    local charRows = {}

    -- Race + Class line (with mundus constellation icons)
    -- local log = BattleScrolls.log
    -- log.Debug(string.format("[setup] buildCharacterSection: raceId=%s classId=%s mundus=%s",
    --     tostring(setupData.raceId), tostring(setupData.classId),
    --     setupData.mundusAbilityIds and ("#" .. #setupData.mundusAbilityIds) or "nil"))
    if setupData.raceId and setupData.classId then
        local raceName, className, raceIcon, classIcon = resolveRaceClass(setupData.raceId, setupData.classId)
        -- log.Debug(string.format("[setup] resolveRaceClass: raceName='%s' className='%s' raceIcon='%s' classIcon='%s'",
        --     raceName, className, raceIcon, classIcon))
        if raceName ~= "" and className ~= "" then
            local racePart = raceIcon ~= "" and inlineIcon(raceIcon) .. raceName or raceName
            local classPart = classIcon ~= "" and inlineIcon(classIcon) .. className or className
            local line = racePart .. "  " .. classPart
            if setupData.mundusAbilityIds then
                for _, abilityId in ipairs(setupData.mundusAbilityIds) do
                    local name = zo_strformat("<<C:1>>", GetAbilityName(abilityId, ""))
                    if name ~= "" then
                        line = line .. "  " .. inlineIcon(getMundusConstellationIcon(abilityId)) .. name
                    end
                end
            end
            charRows[#charRows + 1] = col:PlainTextRow(line, ZO_SELECTED_TEXT)
        end
    end

    -- Class skill lines (with collectible icons)
    if setupData.classSkillLineIds then
        local skillLines = resolveClassSkillLines(setupData.classSkillLineIds)
        if #skillLines > 0 then
            local skillParts = {}
            for _, sl in ipairs(skillLines) do
                local part = sl.icon ~= "" and inlineIcon(sl.icon) .. sl.name or sl.name
                skillParts[#skillParts + 1] = part
            end
            charRows[#charRows + 1] = col:PlainTextRow(table.concat(skillParts, "  "), ZO_HIGHLIGHT_TEXT)
        end
    end

    -- Food
    if setupData.foods and #setupData.foods > 0 then
        for _, food in ipairs(setupData.foods) do
            local name, icon, uptimeSuffix = resolveFoodDisplay(food, playerAliveTimeMs)
            if name ~= "" then
                local line = icon ~= "" and inlineIcon(icon) .. name or name
                if uptimeSuffix then line = line .. uptimeSuffix end
                charRows[#charRows + 1] = col:PlainTextRow(line, ZO_HIGHLIGHT_TEXT)
            end
        end
    end

    -- log.Debug(string.format("[setup] buildCharacterSection: %d charRows", #charRows))
    if #charRows == 0 then return nil end
    return col:Section(GetString(BATTLESCROLLS_SETUP_CHARACTER), charRows)
end

---Collects scribed abilities from both bars (deduplicated).
---@param abilities PlayerSetupAbilities
---@return { abilityId: number, scripts: string }[]
local function collectScribedAbilities(abilities)
    local result = {}
    local seen = {}
    for _, bar in ipairs({ abilities.front, abilities.back }) do
        for _, ability in ipairs(bar) do
            if ability.craftedAbilityId and ability.scriptIds
                and not seen[ability.abilityId] then
                seen[ability.abilityId] = true
                local scriptNames = {}
                for _, scriptId in ipairs(ability.scriptIds) do
                    if scriptId > 0 then
                        scriptNames[#scriptNames + 1] = zo_strformat("<<1>>", GetCraftedAbilityScriptDisplayName(scriptId))
                    end
                end
                if #scriptNames > 0 then
                    result[#result + 1] = {
                        abilityId = ability.abilityId,
                        scripts = table.concat(scriptNames, ", "),
                    }
                end
            end
        end
    end
    return result
end

---Resolves champion data into structured discipline groups with names and icons.
---@param champion PlayerSetupChampionSkill[]
---@return { name: string, icon: string, skills: { name: string, icon: string }[] }[], number[] disciplineOrder
local function resolveChampionDisciplines(champion)
    local disciplines, disciplineOrder = groupChampionByDiscipline(champion)

    local resolved = {}
    for _, disciplineId in ipairs(disciplineOrder) do
        local skills = disciplines[disciplineId]
        local disciplineType = GetChampionDisciplineType(disciplineId)
        local disciplineIcon = journal.ChampionDisciplineIcons[disciplineType]
        local disciplineName = ZO_CachedStrFormat(
            SI_CHAMPION_CONSTELLATION_NAME_FORMAT,
            GetChampionDisciplineName(disciplineId))

        local skillList = {}
        for _, skill in ipairs(skills) do
            local name = GetChampionSkillName(skill.skillId)
            if name and name ~= "" then
                name = ZO_CachedStrFormat(SI_CHAMPION_STAR_NAME, name)
                skillList[#skillList + 1] = { name = name, icon = disciplineIcon }
            end
        end
        resolved[#resolved + 1] = { name = disciplineName, icon = disciplineIcon, skills = skillList }
    end
    return resolved, disciplineOrder
end

---Determines which off-hand slots should be hidden (2H weapons).
---@param equipSlots (string|false)[]
---@return boolean hideFrontOff, boolean hideBackOff
local function getHiddenOffHands(equipSlots)
    local frontMainLink = equipSlots[FRONT_MAIN_HAND_INDEX]
    local backMainLink = equipSlots[BACK_MAIN_HAND_INDEX]
    local hideFrontOff = frontMainLink and TWO_HANDED_TYPES[GetItemLinkWeaponType(frontMainLink)] or false
    local hideBackOff = backMainLink and TWO_HANDED_TYPES[GetItemLinkWeaponType(backMainLink)] or false
    return hideFrontOff, hideBackOff
end

-------------------------
-- Icon Helpers
-------------------------

-- Fallback icon for bars with no equipped weapon
local EMPTY_MAIN_HAND_ICON = "EsoUI/Art/CharacterWindow/gearSlot_mainHand.dds"

---Gets the weapon icon for a bar from the equipped main-hand slot
---@param equipSlots (string|false)[]|nil
---@param mainHandIndex number Slot index for the main hand weapon
---@return string icon
local function getBarIcon(equipSlots, mainHandIndex)
    if equipSlots then
        local link = equipSlots[mainHandIndex]
        if link then
            local icon = GetItemLinkIcon(link)
            if icon and icon ~= "" then
                return icon
            end
        end
    end
    return EMPTY_MAIN_HAND_ICON
end

---Gets generic weapon type icon(s) for a bar.
-------------------------
-- Armor Weight Helpers (used by overview panel)
-------------------------


---Formats armor weight counts with localized names (e.g. "5 Light / 1 Medium / 1 Heavy")
---@param light number
---@param medium number
---@param heavy number
---@return string
local function formatArmorWeights(light, medium, heavy)
    local parts = {}
    if light > 0 then table.insert(parts, string.format("%d %s", light, zo_strformat("<<1>>", GetString("SI_ARMORTYPE", ARMORTYPE_LIGHT)))) end
    if medium > 0 then table.insert(parts, string.format("%d %s", medium, zo_strformat("<<1>>", GetString("SI_ARMORTYPE", ARMORTYPE_MEDIUM)))) end
    if heavy > 0 then table.insert(parts, string.format("%d %s", heavy, zo_strformat("<<1>>", GetString("SI_ARMORTYPE", ARMORTYPE_HEAVY)))) end
    if #parts == 0 then
        return ""
    end
    return table.concat(parts, " / ")
end

-------------------------
-- Trait Helpers (used by overview panel)
-------------------------


-------------------------
-- Enchant Helpers (used by overview panel)
-------------------------


-- Off-hand slot indices
local FRONT_OFF_HAND_INDEX = 6
local BACK_OFF_HAND_INDEX = 14

---Checks if a bar is dual-wield (main hand is not 2H and off-hand has a weapon)
---@param equipSlots (string|false)[]
---@param mainIdx number Main hand slot index
---@param offIdx number Off-hand slot index
---@return boolean
local function isDualWield(equipSlots, mainIdx, offIdx)
    local mainLink = equipSlots[mainIdx]
    if mainLink and TWO_HANDED_TYPES[GetItemLinkWeaponType(mainLink)] then return false end
    local offLink = equipSlots[offIdx]
    return offLink and offLink ~= "" and true or false
end

---Joins main + off values with " + " for DW, combining duplicates as "2x Name"
---@param main string
---@param off string
---@return string
local function joinBarWeapons(main, off)
    if off ~= "" then
        if main == off then
            return "2x " .. main
        end
        return main .. " + " .. off
    end
    return main
end

---Extracts a property from a weapon slot link
---@param link string|false
---@param extractor fun(link: string): string
---@return string
local function extractWeaponProp(link, extractor)
    if link then return extractor(link) end
    return ""
end

---Gets enchant names for front and back weapon slots, including off-hand for DW
---@param equipSlots (string|false)[]
---@return string frontEnchant, string backEnchant
local function getWeaponEnchants(equipSlots)
    local frontMain = extractWeaponProp(equipSlots[FRONT_MAIN_HAND_INDEX], getEnchantName)
    local backMain = extractWeaponProp(equipSlots[BACK_MAIN_HAND_INDEX], getEnchantName)

    local front = frontMain
    if isDualWield(equipSlots, FRONT_MAIN_HAND_INDEX, FRONT_OFF_HAND_INDEX) then
        front = joinBarWeapons(front, extractWeaponProp(equipSlots[FRONT_OFF_HAND_INDEX], getEnchantName))
    end
    local back = backMain
    if isDualWield(equipSlots, BACK_MAIN_HAND_INDEX, BACK_OFF_HAND_INDEX) then
        back = joinBarWeapons(back, extractWeaponProp(equipSlots[BACK_OFF_HAND_INDEX], getEnchantName))
    end

    return front, back
end

---Gets trait name from item link
---@param link string
---@return string
local function getTraitName(link)
    local trait = GetItemLinkTraitType(link)
    if trait and trait > 0 then
        return zo_strformat("<<1>>", GetString("SI_ITEMTRAITTYPE", trait))
    end
    return ""
end

---Gets trait names for front and back weapon slots, including off-hand for DW
---@param equipSlots (string|false)[]
---@return string frontTrait, string backTrait
local function getWeaponTraitsByBar(equipSlots)
    local frontMain = extractWeaponProp(equipSlots[FRONT_MAIN_HAND_INDEX], getTraitName)
    local backMain = extractWeaponProp(equipSlots[BACK_MAIN_HAND_INDEX], getTraitName)

    local front = frontMain
    if isDualWield(equipSlots, FRONT_MAIN_HAND_INDEX, FRONT_OFF_HAND_INDEX) then
        front = joinBarWeapons(front, extractWeaponProp(equipSlots[FRONT_OFF_HAND_INDEX], getTraitName))
    end
    local back = backMain
    if isDualWield(equipSlots, BACK_MAIN_HAND_INDEX, BACK_OFF_HAND_INDEX) then
        back = joinBarWeapons(back, extractWeaponProp(equipSlots[BACK_OFF_HAND_INDEX], getTraitName))
    end

    return front, back
end

-------------------------
-- Weapon Type Helpers (used by overview panel)
-------------------------

---Gets a readable weapon type name
---@param weaponType number WEAPONTYPE_* constant
---@return string
local function getWeaponTypeName(weaponType)
    if weaponType == 0 then return "" end
    local customName = TWO_HANDED_WEAPON_NAMES[weaponType]
    local raw = customName and GetString(customName) or GetString("SI_WEAPONTYPE", weaponType)
    return zo_strformat("<<1>>", raw)
end

---Gets a readable weapon type name from both bars.
---Returns localized "Disabled" for a bar that is disabled (bar swap locked).
---@param setupData PlayerSetup
---@return string frontWeapon, string backWeapon
local function getWeaponTypes(setupData)
    local equipSlots = setupData.equipSlots
    local disabledText = zo_strformat("<<1>>", GetString(SI_CHECK_BUTTON_DISABLED))

    local function weaponName(slotIdx)
        local link = equipSlots[slotIdx]
        if link then
            local wt = GetItemLinkWeaponType(link)
            if wt > 0 then return getWeaponTypeName(wt) end
        end
        return zo_strformat("<<1>>", GetString(SI_WEAPONCONFIGTYPE11))
    end

    local front
    if setupData.frontBarDisabled then
        front = disabledText
    else
        front = weaponName(FRONT_MAIN_HAND_INDEX)
        if isDualWield(equipSlots, FRONT_MAIN_HAND_INDEX, FRONT_OFF_HAND_INDEX) then
            front = joinBarWeapons(front, weaponName(FRONT_OFF_HAND_INDEX))
        end
    end

    local back
    if setupData.backBarDisabled then
        back = disabledText
    else
        back = weaponName(BACK_MAIN_HAND_INDEX)
        if isDualWield(equipSlots, BACK_MAIN_HAND_INDEX, BACK_OFF_HAND_INDEX) then
            back = joinBarWeapons(back, weaponName(BACK_OFF_HAND_INDEX))
        end
    end

    return front, back
end

---Builds ability bar rows: SideBySideBars + scribed ability details + optional werewolf bar.
---@param col ColumnBuilder
---@param setupData PlayerSetup
---@param showWeaponTypes boolean Show weapon type suffix on bar labels
---@param tightFit boolean|nil Tight layout (back bar follows front)
---@param compact boolean|nil When true, hide normal bars entirely if werewolf bar is present
---@return Control[]|nil rows Nil if no abilities
local function buildAbilityRows(col, setupData, showWeaponTypes, tightFit, compact)
    if not setupData.abilities then return nil end

    local hasWerewolf = setupData.werewolfAbilities ~= nil
    local hideNormalBars = setupData.werewolfEntireFight or (compact and hasWerewolf)

    local rows = {}

    -- Skip normal bars if player was in werewolf form the entire fight,
    -- or in compact mode when any werewolf data is present
    if not hideNormalBars then
        if #setupData.abilities.front == 0 and #setupData.abilities.back == 0 then return nil end

        local frontWeapon, backWeapon
        if showWeaponTypes and setupData.equipSlots then
            frontWeapon, backWeapon = getWeaponTypes(setupData)
        end

        rows[#rows + 1] = col:SideBySideBars(
            setupData.abilities.front, setupData.abilities.back,
            GetString(BATTLESCROLLS_SETUP_FRONT_BAR), GetString(BATTLESCROLLS_SETUP_BACK_BAR),
            frontWeapon, backWeapon, tightFit)

        local allAbilities = collectScribedAbilities(setupData.abilities)
        for _, scribed in ipairs(allAbilities) do
            local icon = GetAbilityIcon(scribed.abilityId)
            local name = BattleScrolls.utils.GetScribeAwareAbilityDisplayName(scribed.abilityId)
            local text = ZO_SELECTED_TEXT:Colorize(name) .. ": " .. scribed.scripts
            local row = col:IconTextRow(icon, text, ZO_NORMAL_TEXT)
            row._topGap = 3
            rows[#rows + 1] = row
        end
    end

    -- Werewolf bar (shown below front/back, or alone if normal bars hidden)
    if hasWerewolf then
        local wwRow = col:LabeledBar(setupData.werewolfAbilities, GetString(SI_HOTBARCATEGORY8))
        if #rows > 0 then
            wwRow._topGap = 6
        end
        rows[#rows + 1] = wwRow
    end

    if #rows == 0 then return nil end
    return rows
end

-------------------------
-- Gear Item Helpers
-------------------------

---Extracts set ID from an item link, returns 0 if not a set item
---@param link string
---@return number setId
local function getSetIdFromLink(link)
    local hasSet, _, _, _, _, setId = GetItemLinkSetInfo(link, true)
    return (hasSet and setId > 0) and setId or 0
end

---Gets the display name for a gear item (set name or slot name)
---@param link string Item link
---@param esoSlot number EQUIP_SLOT_* constant
---@return string name
local function getGearItemName(link, esoSlot)
    local setId = getSetIdFromLink(link)
    if setId > 0 then
        local unperfectedId = GetItemSetUnperfectedSetId(setId)
        local groupId = (unperfectedId > 0) and unperfectedId or setId
        local name = GetItemSetName(groupId)
        if name and name ~= "" then
            return zo_strformat("<<C:1>>", name)
        end
    end
    local weaponType = GetItemLinkWeaponType(link)
    if weaponType > 0 then
        return getWeaponTypeName(weaponType)
    end
    return zo_strformat("<<C:1>>", GetString("SI_EQUIPSLOT", esoSlot))
end

---Builds the sublabel for a gear item entry
---@param link string Item link
---@param esoSlot number EQUIP_SLOT_* constant
---@return string
local function buildGearSublabel(link, esoSlot)
    local armorType = GetItemLinkArmorType(link)
    local slotName = zo_strformat("<<1>>", GetString("SI_EQUIPSLOT", esoSlot))

    if armorType > 0 then
        return zo_strformat("<<1>>", GetString("SI_ARMORTYPE", armorType)) .. " " .. slotName
    end

    return slotName
end

-------------------------
-- Public API: List Renderer
-------------------------

local EntryBuilder = journal.EntryBuilder

---Builds an icon-list tooltip for character info (class skill lines with collectible icons).
---@param classSkillLineIds number[]|nil
---@return TooltipDescriptor
local function buildCharacterTooltip(classSkillLineIds)
    local rows = {}
    if classSkillLineIds then
        local skillLines = resolveClassSkillLines(classSkillLineIds)
        for _, sl in ipairs(skillLines) do
            rows[#rows + 1] = { label = sl.name, icon = sl.icon }
        end
    end
    return { type = "iconList", title = GetString(BATTLESCROLLS_SETUP_CLASS_SKILLS), rows = rows }
end

---Builds a tooltip for champion skills grouped by discipline.
---@param champion PlayerSetupChampionSkill[]
---@return TooltipDescriptor
local function buildChampionTooltip(champion)
    local resolved = resolveChampionDisciplines(champion)
    local groups = {}
    for _, discipline in ipairs(resolved) do
        local rows = {}
        for _, skill in ipairs(discipline.skills) do
            rows[#rows + 1] = { label = skill.name, icon = skill.icon }
        end
        groups[#groups + 1] = { headerLabel = discipline.name, headerIcon = discipline.icon, rows = rows }
    end
    return { type = "iconList", title = GetString(SI_MAIN_MENU_CHAMPION), groups = groups }
end

---Pre-resolves a bar's abilities into TooltipAbility format with scripts and isUltimate.
---@param bar PlayerSetupAbility[]
---@return TooltipAbility[]
local function resolveBarAbilities(bar)
    local resolved = {}
    for i, ability in ipairs(bar) do
        if ability.abilityId > 0 then
            local scripts
            if ability.craftedAbilityId and ability.scriptIds then
                scripts = {}
                for _, scriptId in ipairs(ability.scriptIds) do
                    if scriptId > 0 then
                        scripts[#scripts + 1] = {
                            icon = GetCraftedAbilityScriptIcon(scriptId),
                            name = zo_strformat("<<1>>", GetCraftedAbilityScriptDisplayName(scriptId)),
                        }
                    end
                end
                if #scripts == 0 then scripts = nil end
            end
            resolved[#resolved + 1] = {
                abilityId = ability.abilityId,
                isUltimate = (i == #bar),
                scripts = scripts,
            }
        end
    end
    return resolved
end

---Renders the Setup tab into the parametric scroll list
---@param ctx JournalRenderContext
---@return Effect
function setup.renderSetup(ctx)
    return LibEffect.Async(function()
        local setupData = ctx.encounter.setup
        if not setupData then return end

        local list = ctx.list

        -------------------------
        -- Section 0: Character (race/class, mundus, food)
        -------------------------
        if setupData.raceId or setupData.classId or setupData.mundusAbilityIds or setupData.foods then
            local isFirst = true

            -- Race + Class entry
            if setupData.raceId and setupData.classId then
                local raceName, className, raceIcon, classIcon = resolveRaceClass(setupData.raceId, setupData.classId)
                if raceName ~= "" and className ~= "" then
                    EntryBuilder.addEntry(list, {
                        label = raceName .. " " .. className,
                        icon = (classIcon ~= "" and classIcon) or (raceIcon ~= "" and raceIcon) or nil,
                        header = isFirst and GetString(BATTLESCROLLS_SETUP_CHARACTER) or nil,
                        tooltip = buildCharacterTooltip(setupData.classSkillLineIds),
                    })
                    isFirst = false
                end
            end

            -- Mundus stone entries
            if setupData.mundusAbilityIds then
                for _, abilityId in ipairs(setupData.mundusAbilityIds) do
                    local name = zo_strformat("<<C:1>>", GetAbilityName(abilityId, ""))
                    if name ~= "" then
                        local desc = GetAbilityDescription(abilityId, nil, "")
                        EntryBuilder.addEntry(list, {
                            label = name,
                            icon = getMundusConstellationIcon(abilityId),
                            sublabel = GetString(BATTLESCROLLS_SETUP_MUNDUS),
                            header = isFirst and GetString(BATTLESCROLLS_SETUP_CHARACTER) or nil,
                            tooltip = { type = "text", title = name, text = desc or "" },
                        })
                        isFirst = false
                    end
                end
            end

            -- Food entries
            if setupData.foods then
                for _, food in ipairs(setupData.foods) do
                    local name, icon, _, itemLink = resolveFoodDisplay(food)
                    if name ~= "" then
                        local foodTooltip
                        if itemLink then
                            foodTooltip = { type = "item", itemLink = itemLink }
                        else
                            local desc = GetAbilityDescription(food.abilityId, nil, "")
                            foodTooltip = { type = "text", title = name, text = desc or "" }
                        end
                        EntryBuilder.addEntry(list, {
                            label = name,
                            icon = icon ~= "" and icon or nil,
                            sublabel = GetString(BATTLESCROLLS_SETUP_FOOD),
                            header = isFirst and GetString(BATTLESCROLLS_SETUP_CHARACTER) or nil,
                            tooltip = foodTooltip,
                        })
                        isFirst = false
                    end
                end
            end

            LibEffect.Yield():Await()
        end

        -------------------------
        -- Section 1: Abilities
        -------------------------
        local frontIcon = getBarIcon(setupData.equipSlots, FRONT_MAIN_HAND_INDEX)
        local backIcon = getBarIcon(setupData.equipSlots, BACK_MAIN_HAND_INDEX)

        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_SETUP_FRONT_BAR),
            icon = frontIcon,
            header = GetString(BATTLESCROLLS_SETUP_ABILITIES),
            tooltip = {
                type = "abilityList",
                title = GetString(BATTLESCROLLS_SETUP_FRONT_BAR),
                abilities = resolveBarAbilities(setupData.abilities.front),
            },
        })

        EntryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_SETUP_BACK_BAR),
            icon = backIcon,
            tooltip = {
                type = "abilityList",
                title = GetString(BATTLESCROLLS_SETUP_BACK_BAR),
                abilities = resolveBarAbilities(setupData.abilities.back),
            },
        })

        LibEffect.Yield():Await()

        -------------------------
        -- Section 2: Champion (single entry, tooltip shows individual skills)
        -------------------------
        if setupData.champion and #setupData.champion > 0 then
            EntryBuilder.addEntry(list, {
                label = GetString(SI_MAIN_MENU_CHAMPION),
                icon = CHAMPION_ICON,
                header = GetString(SI_MAIN_MENU_CHAMPION),
                tooltip = buildChampionTooltip(setupData.champion),
            })

            LibEffect.Yield():Await()
        end

        -------------------------
        -- Section 3: Gear Items (individual entries per equip slot, like armory)
        -------------------------
        if setupData.equipSlots then
            local headersUsed = {}

            -- Determine which off-hand slots to hide (2H main hand)
            local hideFrontOff, hideBackOff = getHiddenOffHands(setupData.equipSlots)

            for _, gearEntry in ipairs(GEAR_DISPLAY_ORDER) do
                local slotIdx = gearEntry.index
                local esoSlot = INDEX_TO_ESO_SLOT[slotIdx]
                local link = setupData.equipSlots[slotIdx]

                -- Skip hidden off-hand slots (2H main hand)
                if slotIdx == 6 and hideFrontOff then
                    -- skip front off-hand
                elseif slotIdx == 14 and hideBackOff then
                    -- skip back off-hand
                else
                    -- First entry of each visual category gets a header
                    local header = nil
                    if headersUsed[gearEntry.category] == nil then
                        header = zo_strformat("<<C:1>>", GetString("SI_EQUIPSLOTVISUALCATEGORY", gearEntry.category))
                        headersUsed[gearEntry.category] = true
                    end

                    if link then
                        local name = getGearItemName(link, esoSlot)
                        local sublabel = buildGearSublabel(link, esoSlot)
                        local icon = GetItemLinkIcon(link)

                        -- Quality coloring
                        local quality = GetItemLinkDisplayQuality(link)
                        local nameColors = nil
                        if quality > 0 then
                            ---@diagnostic disable-next-line: undefined-field -- ZO_GamepadEntryData static method
                            local selected, unselected = ZO_GamepadEntryData.GetColorsBasedOnQuality(nil, quality)
                            nameColors = { selected, unselected }
                        end

                        EntryBuilder.addEntry(list, {
                            label = name,
                            icon = icon,
                            sublabel = sublabel,
                            header = header,
                            nameColors = nameColors,
                            tooltip = { type = "item", itemLink = link },
                        })
                    else
                        local slotName = zo_strformat("<<C:1>>", GetString("SI_EQUIPSLOT", esoSlot))
                        local emptyIcon = ZO_Character_GetEmptyEquipSlotTexture(esoSlot)
                        EntryBuilder.addEntry(list, {
                            label = slotName,
                            icon = emptyIcon,
                            header = header,
                        })
                    end
                end
            end

            LibEffect.Yield():Await()
        end

        -------------------------
        -- Section 4: Poisons
        -------------------------
        if setupData.frontPoison or setupData.backPoison then
            local isFirst = true

            if setupData.frontPoison then
                local poisonName, poisonIcon = getPoisonDisplay(setupData.frontPoison.itemLink)
                EntryBuilder.addEntry(list, {
                    label = poisonName,
                    icon = poisonIcon,
                    sublabel = GetString(BATTLESCROLLS_SETUP_FRONT_BAR),
                    header = isFirst and GetString(BATTLESCROLLS_SETUP_POISONS) or nil,
                    tooltip = { type = "item", itemLink = setupData.frontPoison.itemLink },
                })
                isFirst = false
            end

            if setupData.backPoison then
                local poisonName, poisonIcon = getPoisonDisplay(setupData.backPoison.itemLink)
                EntryBuilder.addEntry(list, {
                    label = poisonName,
                    icon = poisonIcon,
                    sublabel = GetString(BATTLESCROLLS_SETUP_BACK_BAR),
                    header = isFirst and GetString(BATTLESCROLLS_SETUP_POISONS) or nil,
                    tooltip = { type = "item", itemLink = setupData.backPoison.itemLink },
                })
            end
        end

        LibEffect.Yield():Await()
    end)
end

-------------------------
-- Public API: Overview Panel
-------------------------

local SECTION_GAP = journal.SECTION_GAP
local Q3_INSET = journal.Q3_INSET

---Formats a front/back pair. When only one is present, appends "(Front Bar)"/"(Back Bar)".
---@param front string
---@param back string
---@return string
local function formatFrontBack(front, back)
    if front ~= "" and back ~= "" then
        return front .. " / " .. back
    elseif front ~= "" then
        return string.format("%s (%s)", front, GetString(BATTLESCROLLS_SETUP_FRONT_BAR))
    elseif back ~= "" then
        return string.format("%s (%s)", back, GetString(BATTLESCROLLS_SETUP_BACK_BAR))
    end
    return ""
end

---Builds a PanelSpec for the Setup tab (2-column layout).
---Q2 (left, 700px): Character info + Abilities + Champion
---Q3 (right, expanded): Gear sets, Equipment summary, Poisons
---@param ctx { arithmancer: ArithmancerInstance, encounter: DecodedEncounter, durationS: number, unitNames: table<number, string>, abilityInfo: table<number, AbilityInfo> }
---@return PanelSpec
function setup.buildSetupPanelSpec(ctx)
    return {
        layout = "wide-left",
        ---@diagnostic disable-next-line: unused-local -- wide-left layout doesn't use Q4
        build = function(q2, q3, q4)
            local setupData = ctx.encounter.setup
            if not setupData then return end

            -- Row color scheme: types (bright) -> traits (standard) -> enchants (distinct)
            local COLOR_TYPE = ZO_SELECTED_TEXT
            local COLOR_TRAIT = ZO_HIGHLIGHT_TEXT
            local COLOR_ENCHANT = ZO_NORMAL_TEXT

            local col2 = q2

            -------------------------
            -- Q2: Character Info
            -------------------------
            local durationMs = ctx.encounter.durationMs or (ctx.durationS * 1000)
            local playerAliveTimeMs = ctx.encounter.playerAliveTimeMs or durationMs
            local charSection = buildCharacterSection(col2, setupData, playerAliveTimeMs)

            -------------------------
            -- Q2: Abilities (side by side) + scribing
            -------------------------
            local abilityItems = buildAbilityRows(col2, setupData, false, true) or {}

            -------------------------
            -- Q2: Champion Stars (2-column layout)
            -------------------------
            local championSection
            if setupData.champion and #setupData.champion > 0 then
                local champRows = {}
                local resolvedDisciplines = resolveChampionDisciplines(setupData.champion)

                for _, disc in ipairs(resolvedDisciplines) do
                    champRows[#champRows + 1] = col2:SubHeader(disc.name)

                    local i = 1
                    while i <= #disc.skills do
                        local left = disc.skills[i]
                        local right = disc.skills[i + 1]
                        if left then
                            champRows[#champRows + 1] = col2:ChampionRow2Col(
                                left.name, left.icon,
                                right and right.name or nil, right and right.icon or nil)
                        end
                        i = i + 2
                    end
                end

                championSection = col2:Section(GetString(SI_MAIN_MENU_CHAMPION), champRows)
            end

            col2:mount(SECTION_GAP, 0, charSection, abilityItems, championSection)

            LibEffect.YieldWithGC():Await()

            -------------------------
            -- Q3: Gear Sets + Equipment by Category + Poisons
            -------------------------
            if setupData.equipSlots then
                local col3 = q3
                local q3Sections = {}

                local setLines = formatActiveSets(setupData.equipSlots)

                if #setLines > 0 then
                    local setRows = {}
                    for _, line in ipairs(setLines) do
                        setRows[#setRows + 1] = col3:PlainTextRow(line, COLOR_TRAIT)
                    end
                    q3Sections[#q3Sections + 1] = col3:Section(GetString(BATTLESCROLLS_SETUP_GEAR_SETS), setRows)
                end

                -------------------------
                -- Q3: Equipment by Category
                -------------------------
                local hideFrontOff, hideBackOff = getHiddenOffHands(setupData.equipSlots)

                local CATEGORY_ORDER = {
                    {
                        category = EQUIP_SLOT_VISUAL_CATEGORY_APPAREL,
                        indices = { 1, 3, 4, 7, 8, 9, 10 },
                        traitFn = function() return groupTraits(setupData.equipSlots, ARMOR_SLOT_INDICES) end,
                        enchantFn = function() return groupEnchants(setupData.equipSlots, ARMOR_SLOT_INDICES) end,
                        weightFn = function()
                            local light, medium, heavy = countArmorWeights(setupData.equipSlots)
                            return formatArmorWeights(light, medium, heavy)
                        end,
                    },
                    {
                        category = EQUIP_SLOT_VISUAL_CATEGORY_ACCESSORIES,
                        indices = { 2, 11, 12 },
                        traitFn = function() return groupTraits(setupData.equipSlots, JEWELRY_SLOT_INDICES) end,
                        enchantFn = function() return groupEnchants(setupData.equipSlots, JEWELRY_SLOT_INDICES) end,
                    },
                    {
                        category = EQUIP_SLOT_VISUAL_CATEGORY_WEAPONS,
                        indices = { 5, 6, 13, 14 },
                        traitFn = function()
                            local ft, bt = getWeaponTraitsByBar(setupData.equipSlots)
                            return formatFrontBack(ft, bt)
                        end,
                        enchantFn = function()
                            local fe, be = getWeaponEnchants(setupData.equipSlots)
                            return formatFrontBack(fe, be)
                        end,
                        typeFn = function()
                            local fw, bw = getWeaponTypes(setupData)
                            return formatFrontBack(fw, bw)
                        end,
                    },
                }

                for _, catDef in ipairs(CATEGORY_ORDER) do
                    local hasItems = false
                    for _, slotIdx in ipairs(catDef.indices) do
                        if slotIdx == 6 and hideFrontOff then
                            -- skip hidden front off-hand
                        elseif slotIdx == 14 and hideBackOff then
                            -- skip hidden back off-hand
                        elseif setupData.equipSlots[slotIdx] then
                            hasItems = true
                            break
                        end
                    end

                    if hasItems then
                        local categoryName = zo_strformat("<<C:1>>", GetString("SI_EQUIPSLOTVISUALCATEGORY", catDef.category))
                        local catRows = {}

                        catRows[#catRows + 1] = col3:SubHeader(categoryName)

                        if catDef.typeFn then
                            local typeStr = catDef.typeFn()
                            if typeStr ~= "" then
                                local row = col3:PlainTextRow(typeStr, COLOR_TYPE, Q3_INDENT)
                                row._topGap = 3
                                catRows[#catRows + 1] = row
                            end
                        end

                        if catDef.weightFn then
                            local weightStr = catDef.weightFn()
                            if weightStr ~= "" then
                                local row = col3:PlainTextRow(weightStr, COLOR_TYPE, Q3_INDENT)
                                row._topGap = 3
                                catRows[#catRows + 1] = row
                            end
                        end

                        local traitStr = catDef.traitFn()
                        if traitStr ~= "" then
                            local row = col3:PlainTextRow(traitStr, COLOR_TRAIT, Q3_INDENT)
                            row._topGap = 3
                            catRows[#catRows + 1] = row
                        end

                        local enchantStr = catDef.enchantFn()
                        if enchantStr ~= "" then
                            local row = col3:PlainTextRow(enchantStr, COLOR_ENCHANT, Q3_INDENT)
                            row._topGap = 3
                            catRows[#catRows + 1] = row
                        end

                        -- Equipment categories are sub-sections without a Section header;
                        -- flatten their rows directly into q3Sections
                        for _, row in ipairs(catRows) do
                            q3Sections[#q3Sections + 1] = row
                        end
                    end
                end

                -- Poisons
                if setupData.frontPoison or setupData.backPoison then
                    local poisonRows = {}
                    poisonRows[#poisonRows + 1] = col3:SubHeader(GetString(BATTLESCROLLS_SETUP_POISONS))
                    local frontPoisonName = setupData.frontPoison
                        and (getPoisonDisplay(setupData.frontPoison.itemLink)) or ""
                    local backPoisonName = setupData.backPoison
                        and (getPoisonDisplay(setupData.backPoison.itemLink)) or ""
                    local poisonStr = formatFrontBack(frontPoisonName, backPoisonName)
                    if poisonStr ~= "" then
                        local row = col3:PlainTextRow(poisonStr, COLOR_TYPE, Q3_INDENT)
                        row._topGap = 3
                        poisonRows[#poisonRows + 1] = row
                    end
                    for _, row in ipairs(poisonRows) do
                        q3Sections[#q3Sections + 1] = row
                    end
                end

                col3:mount(SECTION_GAP, Q3_INSET, q3Sections)
            end
        end,
    }
end

-------------------------
-- Public API: Overview Panel Q3 Setup Renderer
-------------------------

---Renders setup data into the overview panel's Q3 area (3-column layout).
---Replaces old Q3 abilities and Q4 targets with a compact setup view.
---@param col3 ColumnBuilder
---@param setupData PlayerSetup|nil
---@param playerAliveTimeMs number|nil Player alive time in ms (for food uptime)
function setup.renderSetupToQ3(col3, setupData, playerAliveTimeMs)
    if not setupData then return end

    local COLOR_TRAIT = ZO_HIGHLIGHT_TEXT

    local q3Sections = {}

    -------------------------
    -- CHARACTER section
    -------------------------
    q3Sections[#q3Sections + 1] = buildCharacterSection(col3, setupData, playerAliveTimeMs)

    -------------------------
    -- ABILITY BARS section (side by side)
    -------------------------
    local abilityRows = buildAbilityRows(col3, setupData, true, false, true)
    if abilityRows then
        q3Sections[#q3Sections + 1] = col3:Section(GetString(BATTLESCROLLS_SETUP_ABILITIES), abilityRows)
    end

    -------------------------
    -- GEAR SETS section
    -------------------------
    if setupData.equipSlots then
        local setLines = formatActiveSets(setupData.equipSlots)

        if #setLines > 0 then
            local setRows = {}
            for i = 1, #setLines, 2 do
                local rowItems = {}
                for j = i, math.min(i + 1, #setLines) do
                    rowItems[#rowItems + 1] = { text = setLines[j], color = COLOR_TRAIT }
                end
                setRows[#setRows + 1] = col3:TextRow3Col(rowItems)
            end
            q3Sections[#q3Sections + 1] = col3:Section(GetString(BATTLESCROLLS_SETUP_GEAR_SETS), setRows)
        end
    end

    -------------------------
    -- CHAMPION section (3-column aligned by discipline)
    -------------------------
    if setupData.champion and #setupData.champion > 0 then
        local champRows = {}
        local resolvedDisciplines = resolveChampionDisciplines(setupData.champion)

        -- Discipline sub-headers as one 3-column text row
        local headerItems = {}
        for _, disc in ipairs(resolvedDisciplines) do
            headerItems[#headerItems + 1] = { text = disc.name, color = COLOR_TRAIT, uppercase = true }
        end
        champRows[#champRows + 1] = col3:TextRow3Col(headerItems)

        -- Skills aligned per discipline: row N = discipline1[N], discipline2[N], discipline3[N]
        local maxSkills = 0
        for _, disc in ipairs(resolvedDisciplines) do
            maxSkills = math.max(maxSkills, #disc.skills)
        end

        for row = 1, maxSkills do
            local names = {}
            local rowIcons = {}
            for colIdx, disc in ipairs(resolvedDisciplines) do
                local skill = disc.skills[row]
                if skill then
                    names[colIdx] = skill.name
                    rowIcons[colIdx] = skill.icon
                end
            end
            champRows[#champRows + 1] = col3:ChampionRow3Col(names, rowIcons)
        end

        q3Sections[#q3Sections + 1] = col3:Section(GetString(SI_MAIN_MENU_CHAMPION), champRows)
    end

    col3:mount(SECTION_GAP, Q3_INSET, q3Sections)
end

-------------------------
-- CompactSetup Panel Helpers
-------------------------

---Formats active set lines from CompactSetupSet[] (no equipSlots needed).
---Queries ESO API for bonus thresholds and perfected status.
---@param compactSets CompactSetupSet[]
---@return string[] lines Formatted set strings
local function formatActiveSetsFromCompact(compactSets)
    local result = {}
    for _, set in ipairs(compactSets) do
        local setId = set.setId
        local unperfectedId = GetItemSetUnperfectedSetId(setId)
        local isPerfected = unperfectedId > 0
        local groupId = isPerfected and unperfectedId or setId

        local _, _, numBonuses = GetItemSetInfo(setId)
        local frontStep = 0
        local backStep = 0
        local perfectedActiveFront = false
        local perfectedActiveBack = false

        for i = 1, numBonuses do
            local numRequired, _, isPerfectedBonus = GetItemSetBonusInfo(setId, i)
            if not isPerfectedBonus then
                if set.frontCount >= numRequired then frontStep = math.max(frontStep, numRequired) end
                if set.backCount >= numRequired then backStep = math.max(backStep, numRequired) end
            else
                if set.frontCount >= numRequired then perfectedActiveFront = true end
                if set.backCount >= numRequired then perfectedActiveBack = true end
            end
        end

        if frontStep > 0 or backStep > 0 then
            local name
            if isPerfected and (perfectedActiveFront or perfectedActiveBack) then
                name = zo_strformat("<<C:1>>", GetItemSetName(setId))
            else
                name = zo_strformat("<<C:1>>", GetItemSetName(groupId))
            end
            local coloredName = ZO_SELECTED_TEXT:Colorize(name)

            local line
            if frontStep == backStep then
                line = string.format("%dx %s", frontStep, coloredName)
            elseif frontStep == 0 then
                line = string.format("%dx %s (%s)", backStep, coloredName,
                    GetString(BATTLESCROLLS_SETUP_BACK_BAR))
            elseif backStep == 0 then
                line = string.format("%dx %s (%s)", frontStep, coloredName,
                    GetString(BATTLESCROLLS_SETUP_FRONT_BAR))
            else
                line = string.format("%dx/%dx %s", frontStep, backStep, coloredName)
            end

            result[#result + 1] = line
        end
    end
    return result
end

---Formats grouped trait entries as "Nx TraitName, Mx TraitName"
---@param entries CompactTraitEntry[]
---@return string
local function formatGroupedTraits(entries)
    local parts = {}
    for _, entry in ipairs(entries) do
        local name = zo_strformat("<<1>>", GetString("SI_ITEMTRAITTYPE", entry.traitType))
        if name ~= "" then
            parts[#parts + 1] = string.format("%dx %s", entry.count, name)
        end
    end
    return table.concat(parts, ", ")
end

---Formats grouped enchant entries as "Nx EnchantName, Mx EnchantName"
---@param entries CompactEnchantEntry[]
---@return string
local function formatGroupedEnchants(entries)
    local parts = {}
    for _, entry in ipairs(entries) do
        local name = getEnchantNameById(entry.enchantId)
        if name ~= "" then
            parts[#parts + 1] = string.format("%dx %s", entry.count, name)
        end
    end
    return table.concat(parts, ", ")
end

---Gets weapon type display for compact setup (front/back from weaponTypes array).
---@param weaponTypes number[] {frontMH, frontOH, backMH, backOH}
---@return string formatted "Front / Back" weapon type string
local function getCompactWeaponTypes(weaponTypes)
    local frontMH = getWeaponTypeName(weaponTypes[1])
    local backMH = getWeaponTypeName(weaponTypes[3])

    local front = frontMH
    if not TWO_HANDED_TYPES[weaponTypes[1]] and weaponTypes[2] > 0 then
        front = joinBarWeapons(frontMH, getWeaponTypeName(weaponTypes[2]))
    end

    local back = backMH
    if not TWO_HANDED_TYPES[weaponTypes[3]] and weaponTypes[4] > 0 then
        back = joinBarWeapons(backMH, getWeaponTypeName(weaponTypes[4]))
    end

    return formatFrontBack(front, back)
end

---Formats a trait name from a trait type ID
---@param traitType number
---@return string
local function formatTraitType(traitType)
    if traitType and traitType > 0 then
        return zo_strformat("<<1>>", GetString("SI_ITEMTRAITTYPE", traitType))
    end
    return ""
end

---Gets weapon traits display for compact setup (front/back from positional arrays).
---@param weaponTraits number[] {frontMH, frontOH, backMH, backOH}
---@param weaponTypes number[] {frontMH, frontOH, backMH, backOH}
---@return string formatted "Front / Back" trait string
local function getCompactWeaponTraits(weaponTraits, weaponTypes)
    local frontMH = formatTraitType(weaponTraits[1])
    local backMH = formatTraitType(weaponTraits[3])

    local front = frontMH
    if not TWO_HANDED_TYPES[weaponTypes[1]] and weaponTypes[2] > 0 then
        front = joinBarWeapons(frontMH, formatTraitType(weaponTraits[2]))
    end

    local back = backMH
    if not TWO_HANDED_TYPES[weaponTypes[3]] and weaponTypes[4] > 0 then
        back = joinBarWeapons(backMH, formatTraitType(weaponTraits[4]))
    end

    return formatFrontBack(front, back)
end

---Gets weapon enchants display for compact setup (front/back from positional arrays).
---@param weaponEnchants number[] {frontMH, frontOH, backMH, backOH}
---@param weaponTypes number[] {frontMH, frontOH, backMH, backOH}
---@return string formatted "Front / Back" enchant string
local function getCompactWeaponEnchants(weaponEnchants, weaponTypes)
    local frontMH = getEnchantNameById(weaponEnchants[1])
    local backMH = getEnchantNameById(weaponEnchants[3])

    local front = frontMH
    if not TWO_HANDED_TYPES[weaponTypes[1]] and weaponTypes[2] > 0 then
        front = joinBarWeapons(frontMH, getEnchantNameById(weaponEnchants[2]))
    end

    local back = backMH
    if not TWO_HANDED_TYPES[weaponTypes[3]] and weaponTypes[4] > 0 then
        back = joinBarWeapons(backMH, getEnchantNameById(weaponEnchants[4]))
    end

    return formatFrontBack(front, back)
end

-------------------------
-- Public API: CompactSetup Panel
-------------------------

---Builds a PanelSpec for a CompactSetup (received from network).
---Reuses existing helper functions by adapting CompactSetup fields into
---the shapes those helpers expect (PlayerSetup-like tables).
---Q2 (left): Character + Abilities + Champion
---Q3 (right): Gear sets, Equipment summary, Poisons
---@param compact CompactSetup
---@return PanelSpec
function setup.buildCompactSetupPanelSpec(compact)
    return {
        layout = "wide-left",
        ---@diagnostic disable-next-line: unused-local -- wide-left layout doesn't use Q4
        build = function(q2, q3, q4)
            local COLOR_TYPE = ZO_SELECTED_TEXT
            local COLOR_TRAIT = ZO_HIGHLIGHT_TEXT
            local COLOR_ENCHANT = ZO_NORMAL_TEXT

            -------------------------
            -- Q2: Character Info
            -------------------------
            ---@type PlayerSetup
            local adapted = {
                raceId = compact.raceId,
                classId = compact.classId,
                mundusAbilityIds = compact.mundusAbilityIds,
                classSkillLineIds = compact.classSkillLineIds,
                foods = {},
            }
            for _, abilityId in ipairs(compact.foodAbilityIds) do
                adapted.foods[#adapted.foods + 1] = { abilityId = abilityId }
            end

            local charSection = buildCharacterSection(q2, adapted, nil)

            -------------------------
            -- Q2: Abilities
            -------------------------
            adapted.abilities = { front = {}, back = {} }
            adapted.frontBarDisabled = compact.frontAbilities == nil
            adapted.backBarDisabled = compact.backAbilities == nil

            local scribedLookup = {}
            for _, sa in ipairs(compact.scribedAbilities) do
                scribedLookup[sa.abilityId] = sa
            end

            if compact.frontAbilities then
                for _, id in ipairs(compact.frontAbilities) do
                    ---@type PlayerSetupAbility
                    local ability = { abilityId = id }
                    local sa = scribedLookup[id]
                    if sa then
                        ability.craftedAbilityId = sa.abilityId
                        ability.scriptIds = sa.scriptIds
                    end
                    adapted.abilities.front[#adapted.abilities.front + 1] = ability
                end
            end
            if compact.backAbilities then
                for _, id in ipairs(compact.backAbilities) do
                    ---@type PlayerSetupAbility
                    local ability = { abilityId = id }
                    local sa = scribedLookup[id]
                    if sa then
                        ability.craftedAbilityId = sa.abilityId
                        ability.scriptIds = sa.scriptIds
                    end
                    adapted.abilities.back[#adapted.abilities.back + 1] = ability
                end
            end

            if compact.werewolfAbilities then
                adapted.werewolfAbilities = {}
                for _, id in ipairs(compact.werewolfAbilities) do
                    adapted.werewolfAbilities[#adapted.werewolfAbilities + 1] = { abilityId = id }
                end
            end

            local abilityItems = buildAbilityRows(q2, adapted, false, true, true) or {}

            -------------------------
            -- Q2: Champion Stars
            -------------------------
            local championSection
            if compact.champion then
                ---@type PlayerSetupChampionSkill[]
                local champSkills = {}
                for i, skillId in ipairs(compact.champion) do
                    if skillId > 0 then
                        local disciplineId = GetChampionDisciplineId(math.ceil(i / 4))
                        champSkills[#champSkills + 1] = { skillId = skillId, disciplineId = disciplineId }
                    end
                end
                if #champSkills > 0 then
                    local champRows = {}
                    local resolvedDisciplines = resolveChampionDisciplines(champSkills)

                    for _, disc in ipairs(resolvedDisciplines) do
                        champRows[#champRows + 1] = q2:SubHeader(disc.name)

                        local i = 1
                        while i <= #disc.skills do
                            local left = disc.skills[i]
                            local right = disc.skills[i + 1]
                            if left then
                                champRows[#champRows + 1] = q2:ChampionRow2Col(
                                    left.name, left.icon,
                                    right and right.name or nil, right and right.icon or nil)
                            end
                            i = i + 2
                        end
                    end

                    championSection = q2:Section(GetString(SI_MAIN_MENU_CHAMPION), champRows)
                end
            end

            q2:mount(SECTION_GAP, 0, charSection, abilityItems, championSection)

            LibEffect.YieldWithGC():Await()

            -------------------------
            -- Q3: Gear Sets + Equipment by Category + Poisons
            -------------------------
            local col3 = q3
            local q3Sections = {}

            -- Gear Sets
            local setLines = formatActiveSetsFromCompact(compact.sets)
            if #setLines > 0 then
                local setRows = {}
                for _, line in ipairs(setLines) do
                    setRows[#setRows + 1] = col3:PlainTextRow(line, COLOR_TRAIT)
                end
                q3Sections[#q3Sections + 1] = col3:Section(GetString(BATTLESCROLLS_SETUP_GEAR_SETS), setRows)
            end

            -- Apparel category
            local armorWeightStr = formatArmorWeights(
                compact.armorWeights[1], compact.armorWeights[2], compact.armorWeights[3])
            local armorTraitStr = formatGroupedTraits(compact.armorTraits)
            local armorEnchantStr = formatGroupedEnchants(compact.armorEnchants)
            if armorWeightStr ~= "" or armorTraitStr ~= "" or armorEnchantStr ~= "" then
                local catRows = {}
                local categoryName = zo_strformat("<<C:1>>",
                    GetString("SI_EQUIPSLOTVISUALCATEGORY", EQUIP_SLOT_VISUAL_CATEGORY_APPAREL))
                catRows[#catRows + 1] = col3:SubHeader(categoryName)
                if armorWeightStr ~= "" then
                    local row = col3:PlainTextRow(armorWeightStr, COLOR_TYPE, Q3_INDENT)
                    row._topGap = 3
                    catRows[#catRows + 1] = row
                end
                if armorTraitStr ~= "" then
                    local row = col3:PlainTextRow(armorTraitStr, COLOR_TRAIT, Q3_INDENT)
                    row._topGap = 3
                    catRows[#catRows + 1] = row
                end
                if armorEnchantStr ~= "" then
                    local row = col3:PlainTextRow(armorEnchantStr, COLOR_ENCHANT, Q3_INDENT)
                    row._topGap = 3
                    catRows[#catRows + 1] = row
                end
                for _, row in ipairs(catRows) do
                    q3Sections[#q3Sections + 1] = row
                end
            end

            -- Weapons category
            local weaponTypeStr = getCompactWeaponTypes(compact.weaponTypes)
            local weaponTraitStr = getCompactWeaponTraits(compact.weaponTraits, compact.weaponTypes)
            local weaponEnchantStr = getCompactWeaponEnchants(compact.weaponEnchants, compact.weaponTypes)
            if weaponTypeStr ~= "" or weaponTraitStr ~= "" or weaponEnchantStr ~= "" then
                local catRows = {}
                local categoryName = zo_strformat("<<C:1>>",
                    GetString("SI_EQUIPSLOTVISUALCATEGORY", EQUIP_SLOT_VISUAL_CATEGORY_WEAPONS))
                catRows[#catRows + 1] = col3:SubHeader(categoryName)
                if weaponTypeStr ~= "" then
                    local row = col3:PlainTextRow(weaponTypeStr, COLOR_TYPE, Q3_INDENT)
                    row._topGap = 3
                    catRows[#catRows + 1] = row
                end
                if weaponTraitStr ~= "" then
                    local row = col3:PlainTextRow(weaponTraitStr, COLOR_TRAIT, Q3_INDENT)
                    row._topGap = 3
                    catRows[#catRows + 1] = row
                end
                if weaponEnchantStr ~= "" then
                    local row = col3:PlainTextRow(weaponEnchantStr, COLOR_ENCHANT, Q3_INDENT)
                    row._topGap = 3
                    catRows[#catRows + 1] = row
                end
                for _, row in ipairs(catRows) do
                    q3Sections[#q3Sections + 1] = row
                end
            end

            -- Accessories category
            local jewelryTraitStr = formatGroupedTraits(compact.jewelryTraits)
            local jewelryEnchantStr = formatGroupedEnchants(compact.jewelryEnchants)
            if jewelryTraitStr ~= "" or jewelryEnchantStr ~= "" then
                local catRows = {}
                local categoryName = zo_strformat("<<C:1>>",
                    GetString("SI_EQUIPSLOTVISUALCATEGORY", EQUIP_SLOT_VISUAL_CATEGORY_ACCESSORIES))
                catRows[#catRows + 1] = col3:SubHeader(categoryName)
                if jewelryTraitStr ~= "" then
                    local row = col3:PlainTextRow(jewelryTraitStr, COLOR_TRAIT, Q3_INDENT)
                    row._topGap = 3
                    catRows[#catRows + 1] = row
                end
                if jewelryEnchantStr ~= "" then
                    local row = col3:PlainTextRow(jewelryEnchantStr, COLOR_ENCHANT, Q3_INDENT)
                    row._topGap = 3
                    catRows[#catRows + 1] = row
                end
                for _, row in ipairs(catRows) do
                    q3Sections[#q3Sections + 1] = row
                end
            end

            -- Poisons
            local hasFrontPoison = compact.frontPoisonEffect or compact.frontPoisonItemId
            local hasBackPoison = compact.backPoisonEffect or compact.backPoisonItemId
            if hasFrontPoison or hasBackPoison then
                local poisonRows = {}
                poisonRows[#poisonRows + 1] = col3:SubHeader(GetString(BATTLESCROLLS_SETUP_POISONS))
                local frontPoisonName = ""
                local backPoisonName = ""
                if compact.frontPoisonEffect then
                    local effects = parsePoisonEffects(compact.frontPoisonEffect)
                    local names = {}
                    for _, id in ipairs(effects) do names[#names + 1] = getAlchemyTraitName(id) end
                    frontPoisonName = table.concat(names, " + ")
                elseif compact.frontPoisonItemId then
                    local link = string.format("|H1:item:%d:0:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", compact.frontPoisonItemId)
                    frontPoisonName = zo_strformat("<<C:1>>", GetItemLinkName(link))
                end
                if compact.backPoisonEffect then
                    local effects = parsePoisonEffects(compact.backPoisonEffect)
                    local names = {}
                    for _, id in ipairs(effects) do names[#names + 1] = getAlchemyTraitName(id) end
                    backPoisonName = table.concat(names, " + ")
                elseif compact.backPoisonItemId then
                    local link = string.format("|H1:item:%d:0:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", compact.backPoisonItemId)
                    backPoisonName = zo_strformat("<<C:1>>", GetItemLinkName(link))
                end
                local poisonStr = formatFrontBack(frontPoisonName, backPoisonName)
                if poisonStr ~= "" then
                    local row = col3:PlainTextRow(poisonStr, COLOR_TYPE, Q3_INDENT)
                    row._topGap = 3
                    poisonRows[#poisonRows + 1] = row
                end
                for _, row in ipairs(poisonRows) do
                    q3Sections[#q3Sections + 1] = row
                end
            end

            if #q3Sections > 0 then
                col3:mount(SECTION_GAP, Q3_INSET, q3Sections)
            end
        end,
    }
end
