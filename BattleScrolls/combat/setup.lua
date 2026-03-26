-----------------------------------------------------------
-- Setup Capture
-- Captures player build snapshot at combat start
--
-- StateObserver that records:
--   - Slotted abilities (with scribing detail)
--   - Champion stars
--   - Equipment per slot (set, trait, armor/weapon type, enchant)
--   - Race, class, class skill lines
--   - Mundus stone(s), food buff(s)
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class PlayerSetupAbility
---@field abilityId number           -- Resolved ability ID (for name/icon). 0 = empty slot.
---@field craftedAbilityId number|nil -- Non-nil if crafted (scribing). Base crafted ability ID.
---@field scriptIds number[]|nil      -- {primaryScriptId, secondaryScriptId, tertiaryScriptId}

---@class PlayerSetupAbilities
---@field front PlayerSetupAbility[] -- 6 entries
---@field back PlayerSetupAbility[]  -- 6 entries

---@class PlayerSetupChampionSkill
---@field skillId number
---@field disciplineId number

---@class PlayerSetupPoison
---@field itemLink string  -- Full item link

---@class PlayerSetupFood
---@field abilityId number -- Food buff ability ID
---@field uptimeMs number|nil -- Active time (nil if effect tracking was off)

---@class PlayerSetup
---@field abilities PlayerSetupAbilities
---@field champion PlayerSetupChampionSkill[]
---@field equipSlots (string|false)[] -- Item link string or false for empty slot, 14 entries (no poison slots)
---@field frontBarDisabled boolean -- true when bar swap locked and front bar is inaccessible
---@field backBarDisabled boolean -- true when bar swap locked and back bar is inaccessible
---@field frontPoison PlayerSetupPoison|nil
---@field backPoison PlayerSetupPoison|nil
---@field raceId number
---@field classId number
---@field classSkillLineIds number[] -- 3 entries (one per class skill line)
---@field mundusAbilityIds number[]|nil -- 0-2 mundus stone buff ability IDs
---@field foods PlayerSetupFood[]|nil -- Top 1-3 food buffs (nil if no food)
---@field werewolfAbilities PlayerSetupAbility[]|nil -- Werewolf bar (only if player transformed during fight)
---@field werewolfEntireFight boolean|nil -- true if player was in werewolf form the entire fight

local FOOD_ABILITY_INFO = BattleScrolls.constants.foodAbilityInfo

-- Fixed slot order (no slot IDs stored, position is implicit)
local EQUIP_SLOTS = {
    EQUIP_SLOT_HEAD,       -- 0
    EQUIP_SLOT_NECK,       -- 1
    EQUIP_SLOT_CHEST,      -- 2
    EQUIP_SLOT_SHOULDERS,  -- 3
    EQUIP_SLOT_MAIN_HAND,  -- 4
    EQUIP_SLOT_OFF_HAND,   -- 5
    EQUIP_SLOT_WAIST,      -- 6
    EQUIP_SLOT_HAND,       -- 16
    EQUIP_SLOT_LEGS,       -- 8
    EQUIP_SLOT_FEET,       -- 9
    EQUIP_SLOT_RING1,      -- 11
    EQUIP_SLOT_RING2,      -- 12
    EQUIP_SLOT_BACKUP_MAIN,-- 20
    EQUIP_SLOT_BACKUP_OFF, -- 21
}

---Checks if the werewolf transformation ultimate is slotted on either weapon bar.
---Note: ESO's ACTION_BAR_ASSIGNMENT_MANAGER:IsWerewolfUltimateSlottedOnAnyWeaponBar()
---uses ACTION_BAR_ULTIMATE_SLOT_INDEX which points to the wrong slot, so we use
---GetAssignableAbilityBarStartAndEndSlots() to find the actual ultimate slot.
---@return boolean
local function isWerewolfUltimateSlotted()
    local _, ultimateSlot = GetAssignableAbilityBarStartAndEndSlots()
    for _, cat in ipairs({ HOTBAR_CATEGORY_PRIMARY, HOTBAR_CATEGORY_BACKUP }) do
        local abilityId = GetSlotBoundId(ultimateSlot, cat)
        if abilityId and abilityId > 0 then
            local progressionData = SKILLS_DATA_MANAGER:GetProgressionDataByAbilityId(abilityId)
            if progressionData then
                if progressionData:GetSkillData():GetSkillLineData():IsWerewolf() then
                    return true
                end
            end
        end
    end
    return false
end

---Captures abilities from a single hotbar category.
---@param category HotBarCategory
---@return PlayerSetupAbility[]
local function captureBar(category)
    local result = {}
    local startSlot, endSlot = GetAssignableAbilityBarStartAndEndSlots()
    local emptyEntry = { abilityId = 0 }
    for slot = startSlot, endSlot do
        local slotType = GetSlotType(slot, category)
        ---@type PlayerSetupAbility
        local entry

        if slotType == ACTION_TYPE_CRAFTED_ABILITY then
            local craftedAbilityId = GetSlotBoundId(slot, category)
            local abilityId = GetAbilityIdForCraftedAbilityId(craftedAbilityId)
            local primary, secondary, tertiary = GetCraftedAbilityActiveScriptIds(craftedAbilityId)
            entry = {
                abilityId = abilityId,
                craftedAbilityId = craftedAbilityId,
                scriptIds = { primary, secondary, tertiary },
            }
        elseif slotType == ACTION_TYPE_ABILITY then
            entry = { abilityId = GetSlotBoundId(slot, category) }
        else
            entry = emptyEntry
        end

        result[#result + 1] = entry
    end
    return result
end

---Captures abilities from front and back hotbars.
---@return PlayerSetupAbilities
local function captureAbilities()
    return {
        front = captureBar(HOTBAR_CATEGORY_PRIMARY),
        back = captureBar(HOTBAR_CATEGORY_BACKUP),
    }
end

---Captures werewolf bar abilities. Returns nil if all slots are empty.
---@return PlayerSetupAbility[]|nil
local function captureWerewolfBar()
    local bar = captureBar(HOTBAR_CATEGORY_WEREWOLF)
    for _, ability in ipairs(bar) do
        if ability.abilityId ~= 0 then
            return bar
        end
    end
    return nil
end

---Captures slotted champion stars
---@return PlayerSetupChampionSkill[]
local function captureChampion()
    -- Build skillId → disciplineId lookup (no direct API exists)
    local skillToDiscipline = {}
    for disciplineIndex = 1, GetNumChampionDisciplines() do
        local disciplineId = GetChampionDisciplineId(disciplineIndex)
        for skillIndex = 1, GetNumChampionDisciplineSkills(disciplineIndex) do
            local skillId = GetChampionSkillId(disciplineIndex, skillIndex)
            skillToDiscipline[skillId] = disciplineId
        end
    end

    local result = {}
    local startSlot, endSlot = GetAssignableChampionBarStartAndEndSlots()
    for slot = startSlot, endSlot do
        local skillId = GetSlotBoundId(slot, HOTBAR_CATEGORY_CHAMPION)
        if skillId and skillId > 0 then
            result[#result + 1] = {
                skillId = skillId,
                disciplineId = skillToDiscipline[skillId] or 0,
            }
        end
    end
    return result
end

---Captures poison from an equip slot
---@param equipSlot number EQUIP_SLOT_POISON or EQUIP_SLOT_BACKUP_POISON
---@return PlayerSetupPoison|nil
local function capturePoison(equipSlot)
    local link = GetItemLink(BAG_WORN, equipSlot, LINK_STYLE_DEFAULT)
    if not link or link == "" then return nil end
    return { itemLink = link }
end

---Captures equipment item links from fixed slots (excludes poisons).
---Slots 5-6 are front weapons (MAIN_HAND, OFF_HAND), slots 13-14 are back weapons (BACKUP_MAIN, BACKUP_OFF).
---@return (string|false)[]
local function captureEquipSlots()
    local result = {}
    for i = 1, #EQUIP_SLOTS do
        local link = GetItemLink(BAG_WORN, EQUIP_SLOTS[i], LINK_STYLE_DEFAULT)
        result[i] = (link and link ~= "") and link or false
    end
    return result
end

---Captures active class skill line IDs (up to 3, may include lines from other classes via subclassing)
---@return number[]
local function captureClassSkillLines()
    local result = {}
    for skillLineIndex = 1, GetNumSkillLines(SKILL_TYPE_CLASS) do
        local _, _, isActive = GetSkillLineDynamicInfo(SKILL_TYPE_CLASS, skillLineIndex)
        if isActive then
            result[#result + 1] = GetSkillLineId(SKILL_TYPE_CLASS, skillLineIndex)
        end
    end
    return result
end

---Scans active buffs for mundus stone ability IDs (0-2 results)
---@return number[]|nil
local function captureMundus()
    local result = {}
    for i = 1, GetNumBuffs("player") do
        local _, _, _, _, _, _, _, _, _, _, abilityId = GetUnitBuffInfo("player", i)
        if GetAbilityMundusStoneType(abilityId) ~= 0 then
            result[#result + 1] = abilityId
        end
    end
    return #result > 0 and result or nil
end

---Scans active buffs for food buff (fallback when effect tracking is off)
---@return PlayerSetupFood|nil
local function captureFoodFromBuffs()
    for i = 1, GetNumBuffs("player") do
        local _, _, _, _, _, _, _, _, _, _, abilityId = GetUnitBuffInfo("player", i)
        if FOOD_ABILITY_INFO[abilityId] then
            return { abilityId = abilityId }
        end
    end
    return nil
end

---Extracts food buffs from effect tracking data, sorted by uptime descending, limited to top 3.
---@param effectsOnPlayer table<number, EffectStats>
---@return PlayerSetupFood[]|nil
local function extractFoodsFromEffects(effectsOnPlayer)
    local foods = {}
    for abilityId, stats in pairs(effectsOnPlayer) do
        if FOOD_ABILITY_INFO[abilityId] then
            foods[#foods + 1] = { abilityId = abilityId, uptimeMs = stats.totalActiveTimeMs }
        end
    end
    if #foods == 0 then return nil end
    table.sort(foods, function(a, b) return a.uptimeMs > b.uptimeMs end)
    -- Limit to top 3
    if #foods > 3 then
        for i = #foods, 4, -1 do
            foods[i] = nil
        end
    end
    return foods
end

---@class SetupCapture : StateObserver
local setupCapture = {}
BattleScrolls.setupCapture = setupCapture

local EVENT_NAMESPACE = "BattleScrolls_Setup"

---Whether bar swap was locked for the entire fight (never saw an unlock).
---@type boolean
local barSwapLockedEntireFight = false

---Which weapon pair was active at combat start (only meaningful when barSwapLockedEntireFight is true).
---@type number|nil
local activeWeaponPairAtStart = nil

---Werewolf bar abilities captured at combat start (nil if player has no WW bar).
---@type PlayerSetupAbility[]|nil
local capturedWerewolfBar = nil

---Whether the player was ever in werewolf form during the fight.
---@type boolean
local wasWerewolf = false

---Whether the player was in werewolf form the entire fight (never saw human form).
---@type boolean
local werewolfEntireFight = false

function setupCapture:Initialize()
    BattleScrolls.state:RegisterObserver(self)
end

---Captures full player setup at combat start
function setupCapture:OnStateInitialized()
    local activeWeaponPair, barSwapLocked = GetActiveWeaponPairInfo()
    activeWeaponPairAtStart = activeWeaponPair
    barSwapLockedEntireFight = barSwapLocked

    if barSwapLocked then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_WEAPON_PAIR_LOCK_CHANGED,
            function(_, locked)
                if not locked then
                    barSwapLockedEntireFight = false
                    EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_WEAPON_PAIR_LOCK_CHANGED)
                end
            end)
    end

    -- Capture werewolf bar (readable even when not transformed) and track WW state
    capturedWerewolfBar = captureWerewolfBar()
    local isWW = IsPlayerInWerewolfForm()
    wasWerewolf = isWW
    werewolfEntireFight = isWW
    if capturedWerewolfBar then
        EVENT_MANAGER:RegisterForEvent(EVENT_NAMESPACE, EVENT_WEREWOLF_STATE_CHANGED,
            function(_, isWerewolf)
                if isWerewolf then
                    wasWerewolf = true
                else
                    werewolfEntireFight = false
                end
            end)
    end

    ---@type PlayerSetup
    BattleScrolls.state.playerSetup = {
        abilities = captureAbilities(),
        champion = captureChampion(),
        equipSlots = captureEquipSlots(),
        frontBarDisabled = false,
        backBarDisabled = false,
        frontPoison = capturePoison(EQUIP_SLOT_POISON),
        backPoison = capturePoison(EQUIP_SLOT_BACKUP_POISON),
        raceId = GetUnitRaceId("player"),
        classId = GetUnitClassId("player"),
        classSkillLineIds = captureClassSkillLines(),
        mundusAbilityIds = captureMundus(),
    }
    -- Capture food from active buffs as fallback (in case effect tracking is off)
    local food = captureFoodFromBuffs()
    if food then
        BattleScrolls.state.playerSetup.foods = { food }
    end
end

---Wipes ability data for a bar, replacing all entries with empty.
---@param abilities PlayerSetupAbility[]
local function wipeAbilities(abilities)
    local emptyEntry = { abilityId = 0 }
    for i = 1, #abilities do
        abilities[i] = emptyEntry
    end
end

---Finalizes bar-swap lock state: if bar swap was locked the entire fight, mark
---the inactive bar as disabled and wipe its captured data.
---Also unregisters the lock-change event listener.
---@param setup PlayerSetup
local function finalizeBarSwapLock(setup)
    EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_WEAPON_PAIR_LOCK_CHANGED)

    if not barSwapLockedEntireFight then return end

    local onFrontBar = activeWeaponPairAtStart == ACTIVE_WEAPON_PAIR_MAIN
    if onFrontBar then
        setup.backBarDisabled = true
        setup.backPoison = nil
        wipeAbilities(setup.abilities.back)
        -- Wipe back weapon slots (indices 13-14)
        setup.equipSlots[13] = false
        setup.equipSlots[14] = false
    else
        setup.frontBarDisabled = true
        setup.frontPoison = nil
        wipeAbilities(setup.abilities.front)
        -- Wipe front weapon slots (indices 5-6)
        setup.equipSlots[5] = false
        setup.equipSlots[6] = false
    end
end

---Finalize setup at combat end
function setupCapture:OnStatePreReset()
    local setup = BattleScrolls.state.playerSetup
    if setup then
        if wasWerewolf and capturedWerewolfBar then
            setup.werewolfAbilities = capturedWerewolfBar
            if werewolfEntireFight then
                setup.werewolfEntireFight = true
                wipeAbilities(setup.abilities.front)
                wipeAbilities(setup.abilities.back)
            end
        end
        -- Skip bar swap lock finalization for werewolf-entire-fight —
        -- bar swap is locked as a side effect of transformation
        if not werewolfEntireFight then
            finalizeBarSwapLock(setup)
        else
            EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_WEAPON_PAIR_LOCK_CHANGED)
        end
    end
    EVENT_MANAGER:UnregisterForEvent(EVENT_NAMESPACE, EVENT_WEREWOLF_STATE_CHANGED)
    capturedWerewolfBar = nil
    wasWerewolf = false
    werewolfEntireFight = false
end

---Captures a PlayerSetup snapshot from current live player data (works outside combat).
---@return PlayerSetup
function setupCapture:captureCurrentSetup()
    local food = captureFoodFromBuffs()
    ---@type PlayerSetup
    local setup = {
        abilities = captureAbilities(),
        champion = captureChampion(),
        equipSlots = captureEquipSlots(),
        frontBarDisabled = false,
        backBarDisabled = false,
        frontPoison = capturePoison(EQUIP_SLOT_POISON),
        backPoison = capturePoison(EQUIP_SLOT_BACKUP_POISON),
        raceId = GetUnitRaceId("player"),
        classId = GetUnitClassId("player"),
        classSkillLineIds = captureClassSkillLines(),
        mundusAbilityIds = captureMundus(),
        foods = food and { food } or nil,
    }

    -- Werewolf: show WW bar only if currently transformed or WW ult is slotted
    local werewolfBar = captureWerewolfBar()
    local isWerewolf = werewolfBar and IsPlayerInWerewolfForm()
    if isWerewolf then
        setup.werewolfAbilities = werewolfBar
        setup.werewolfEntireFight = true
        wipeAbilities(setup.abilities.front)
        wipeAbilities(setup.abilities.back)
    elseif werewolfBar and isWerewolfUltimateSlotted() then
        setup.werewolfAbilities = werewolfBar
    end

    -- Bar swap lock (one-bar builds): disable the inactive bar
    -- Skip during werewolf — bar swap is locked as a side effect of transformation
    if not isWerewolf then
        local activeWeaponPair, barSwapLocked = GetActiveWeaponPairInfo()
        if barSwapLocked then
            if activeWeaponPair == ACTIVE_WEAPON_PAIR_MAIN then
                setup.backBarDisabled = true
                setup.backPoison = nil
                wipeAbilities(setup.abilities.back)
                setup.equipSlots[13] = false
                setup.equipSlots[14] = false
            else
                setup.frontBarDisabled = true
                setup.frontPoison = nil
                wipeAbilities(setup.abilities.front)
                setup.equipSlots[5] = false
                setup.equipSlots[6] = false
            end
        end
    end

    return setup
end

---Finalizes food data from effect tracking (replaces fallback if available).
---Called by scribe at encounter finalization.
---@param setup PlayerSetup
---@param effectsOnPlayer table<number, EffectStats>
function setupCapture.finalizeEffectData(setup, effectsOnPlayer)
    local foods = extractFoodsFromEffects(effectsOnPlayer)
    if foods then
        setup.foods = foods
    end
end
