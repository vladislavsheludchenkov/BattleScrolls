-- In-client data miner (the uespLog approach): iterates ids via game APIs and
-- dumps tab-separated rows to SavedVariables for import into the share site's
-- database. Runs in whatever language the client is set to, so this is also
-- the localization path.
-- Completed passes accumulate by game version and language. Combination rows
-- also include the script selection and class. Import once after all passes.
--
--   /bsabilitydump            - mine everything
--   /bsabilitydump abilities  - ability names/icons/descriptions
--   /bsabilitydump champion   - champion skills per discipline
--   /bsabilitydump items      - item names/set/trait/weight via synthesized links
--   /bsabilitydump scripts    - scribing scripts offered by the grimoires
--   /bsabilitydump combinations - valid scribed names and combined descriptions
--   /bsabilitydump perks      - Vengeance perk defs from the season track
--   /bsabilitydump skilllines - skill line names, all types and all classes
--   /bsabilitydump sets       - item set names/bonuses by itemSetId
--
-- Enchant names ride the items pass (they come off the same synthesized links,
-- glyphs included), so they have no subcommand of their own: mining them means
-- running `items`, or the full dump. Trait descriptions ride it the same way:
-- the canonical links are CP160 legendary (subtype 364), so the captured text
-- carries gold-quality values - the only tier the share viewer displays.
--
-- After the completion message: /reloadui to write the file, then run
-- scripts/import-abilities.sh from the repo.

local ABILITY_MAX = 300000
local ITEM_MAX = 260000
local IDS_PER_TICK = 2000
local TICK_MS = 25
local COMBINATIONS_PER_TICK = 50
local CLASS_FLOURISH_SCRIPT_ID = 31 -- formerly Class Mastery; text depends on base class
local DUMP_FORMAT_VERSION = 2
local DATA_KINDS = { "abilities", "items", "champion", "scripts", "combinations",
    "perks", "skilllines", "sets", "enchants", "traits" }
-- Headroom over the season track's rank count, not a scan: ranks past the end
-- return nothing and the walk stops early if the API rejects them outright
local VENGEANCE_MAX_RANK = 100

local state = nil -- { phases = {...}, phase, scanId, out = {abilities=..., items=...}, counts }

local function row(...)
    return table.concat({ ... }, "\t")
end

-- =============================================================================
-- PHASES
-- =============================================================================

-- Mechanics beyond name/description, mirroring what uespLog mines. All of
-- these are language-neutral; they ride along in every language dataset and
-- merge into one row per ability and game version. GetAbilityFrequencyMS is the DoT tick interval - the
-- reliable "does this ability tick" signal for combat-log component ids.
local function mechanicsCols(id)
    local channeled, castTime, channelTime = GetAbilityCastInfo(id)
    local roles = 0
    local okRoles, isTank, isHealer, isDamage = pcall(GetAbilityRoles, id)
    if okRoles then
        roles = (isTank and 1 or 0) + (isHealer and 2 or 0) + (isDamage and 4 or 0)
    end
    return
        GetAbilityDuration(id) or 0,
        GetAbilityFrequencyMS(id) or 0,
        castTime or 0,
        (channeled and channelTime or 0),
        channeled and 1 or 0,
        IsAbilityPassive(id) and 1 or 0,
        IsAbilityUltimate and (IsAbilityUltimate(id) and 1 or 0) or 0,
        GetAbilityBuffType(id) or 0,
        roles,
        GetAbilityRadius(id) or 0,
        GetAbilityRange(id) or 0,
        GetAbilityCraftedAbilityId(id) or 0
end

local function scanAbilities(out, from, to)
    local rows = out.abilities
    for id = from, to do
        if DoesAbilityExist(id) then
            local name = GetAbilityName(id)
            if name and name ~= "" then
                local ok, description = pcall(GetAbilityDescription, id)
                -- Plain <<1>> rendering strips the grammar flags (^F etc.)
                -- some names carry
                rows[#rows + 1] = row(id, zo_strformat("<<1>>", name),
                    GetAbilityIcon(id) or "",
                    ok and description or "",
                    mechanicsCols(id))
            end
        end
    end
end

-- Item sets, keyed by the itemSetId GetItemLinkSetInfo reports - the id group
-- setups broadcast. Bonus lines make up the tooltip, the way ZOS lays out a set
-- from an id alone; sets have no icon of their own.
local function addSet(out, itemSetId)
    if not itemSetId or itemSetId <= 0 or out.setIds[itemSetId] then
        return
    end
    out.setIds[itemSetId] = true
    local hasSet, setName, numBonuses = GetItemSetInfo(itemSetId)
    if not hasSet or not setName or setName == "" then
        return
    end
    local bonuses = {}
    for bonusIndex = 1, numBonuses do
        local _, bonusDescription = GetItemSetBonusInfo(itemSetId, bonusIndex)
        if bonusDescription and bonusDescription ~= "" then
            bonuses[#bonuses + 1] = bonusDescription
        end
    end
    out.sets[#out.sets + 1] = row(itemSetId, zo_strformat("<<1>>", setName), "",
        table.concat(bonuses, "\n"))
end

-- The collection ids are the authoritative list and enumerate themselves, so no
-- id scan: same walk ZO_ItemSetCollectionsDataManager does. The item phase adds
-- anything wearable whose set has no collection - see scanItems.
local function scanSets(out)
    local itemSetId = GetNextItemSetCollectionId(nil)
    while itemSetId do
        addSet(out, itemSetId)
        itemSetId = GetNextItemSetCollectionId(itemSetId)
    end
end

-- Enchant defs, keyed by the enchantId Battle Scrolls records for gear. Final,
-- not Default: a synthesized link carries no applied glyph, so the two return
-- the same id here, but Final is the one setup sharing keys on and the one the
-- enchant text below describes - and it's the accessor ZOS themselves use on
-- glyph links. Header/description are the two lines ZO_Tooltip:AddEnchant lays
-- out (name, then effect text); enchants have no icon, so that column is empty.
local function addEnchant(out, link)
    local enchantId = GetItemLinkFinalEnchantId(link)
    if not enchantId or enchantId <= 0 or out.enchantIds[enchantId] then
        return
    end
    local _, enchantHeader, enchantDescription = GetItemLinkEnchantInfo(link)
    -- Nameless on this item: leave the id open for a link that does name it
    if not enchantHeader or enchantHeader == "" then
        return
    end
    out.enchantIds[enchantId] = true
    out.enchants[#out.enchants + 1] = row(enchantId,
        zo_strformat("<<1>>", enchantHeader), "", enchantDescription or "")
end

-- Trait defs, keyed by ItemTraitType - the id the wire carries per equip slot
-- and per member trait-count group. One reference row per trait type, taken
-- from a CP160 legendary item. Potency can also depend on the equipment slot
-- and active bonuses; the viewer labels this as reference text.
local function addTrait(out, link)
    local traitType, traitDescription = GetItemLinkTraitInfo(link)
    if not traitType or traitType <= 0 or out.traitIds[traitType] then
        return
    end
    -- Undescribed on this item: leave the id open for a link that has text
    if not traitDescription or traitDescription == "" then
        return
    end
    out.traitIds[traitType] = true
    out.traits[#out.traits + 1] = row(traitType,
        zo_strformat("<<1>>", GetString("SI_ITEMTRAITTYPE", traitType)), "",
        traitDescription)
end

-- Synthesized canonical link per itemId: name/set/trait/weight/equip slot are
-- itemId-intrinsic, so one subtype variant is enough
local function scanItems(out, from, to)
    local rows = out.items
    for id = from, to do
        local link = string.format(
            "|H1:item:%d:364:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", id)
        local name = GetItemLinkName(link)
        if name and name ~= "" then
            -- Ahead of the gear filter on purpose: glyphs are equipType 0, and
            -- a glyph is where most enchant ids get their text
            addEnchant(out, link)
            local equipType = GetItemLinkEquipType(link)
            -- Equippable gear (poisons included: EQUIP_TYPE_POISON = 15)
            if equipType and equipType > 0 then
                local _, setName, _, _, _, setId = GetItemLinkSetInfo(link, false)
                -- Catches sets the collection walk doesn't list, at no extra cost
                addSet(out, setId)
                addTrait(out, link)
                name = zo_strformat("<<1>>", name)
                rows[#rows + 1] = row(id, name, GetItemLinkIcon(link) or "",
                    setName or "",
                    GetItemLinkTraitType(link) or -1,
                    GetItemLinkArmorType(link) or 0,
                    GetItemLinkWeaponType(link) or 0,
                    equipType,
                    (setId and setId > 0) and setId or 0)
            end
        end
    end
end

local function scanChampion(out)
    local rows = out.champion
    for disciplineIndex = 1, GetNumChampionDisciplines() do
        local disciplineId = GetChampionDisciplineId(disciplineIndex)
        local disciplineName = GetChampionDisciplineName(disciplineId)
        for skillIndex = 1, GetNumChampionDisciplineSkills(disciplineIndex) do
            local skillId = GetChampionSkillId(disciplineIndex, skillIndex)
            if skillId and skillId > 0 then
                local name = GetChampionSkillName(skillId)
                local ok, description = pcall(GetChampionSkillDescription, skillId)
                rows[#rows + 1] = row(skillId, zo_strformat("<<1>>", name or ""), disciplineId,
                    disciplineName or "", ok and description or "")
            end
        end
    end
end

-- Scribing scripts, walked the way ZO_ScribingDataManager walks them: every
-- grimoire, every scribing slot, every script offered in that slot. Scripts are
-- shared between grimoires, hence the dedupe. The general description is the
-- grimoire-independent one - the right text for a store keyed by script id.
local function scanScripts(out)
    local rows = out.scripts
    local seen = {}
    for index = 1, GetNumCraftedAbilities() do
        local craftedAbilityId = GetCraftedAbilityIdAtIndex(index)
        -- ZOS skips skill-type-less grimoires; those are unreleased data
        if craftedAbilityId > 0
            and GetSkillTypeForCraftedAbilityId(craftedAbilityId) ~= SKILL_TYPE_NONE then
            for slot = SCRIBING_SLOT_ITERATION_BEGIN, SCRIBING_SLOT_ITERATION_END do
                for slotIndex = 1, GetNumScriptsInSlotForCraftedAbility(craftedAbilityId, slot) do
                    local scriptId = GetScriptIdAtSlotIndexForCraftedAbility(
                        craftedAbilityId, slot, slotIndex)
                    if scriptId > 0 and not seen[scriptId] then
                        seen[scriptId] = true
                        local name = GetCraftedAbilityScriptDisplayName(scriptId)
                        if name and name ~= "" then
                            rows[#rows + 1] = row(scriptId, zo_strformat("<<1>>", name),
                                GetCraftedAbilityScriptIcon(scriptId) or "",
                                GetCraftedAbilityScriptGeneralDescription(scriptId) or "")
                        end
                    end
                end
            end
        end
    end
end

-- Walk only scripts offered by each released grimoire, then ask the game to
-- validate the entire selection. Ownership is deliberately irrelevant: the
-- preview API can describe a valid recipe without unlocking or crafting it.
local function combinationIterator(out)
    return coroutine.create(function()
        for index = 1, GetNumCraftedAbilities() do
            local craftedId = GetCraftedAbilityIdAtIndex(index)
            if craftedId > 0 and GetSkillTypeForCraftedAbilityId(craftedId) ~= SKILL_TYPE_NONE
                and not IsCraftedAbilityDisabled(craftedId) then
                local slots = {}
                for slot = SCRIBING_SLOT_ITERATION_BEGIN, SCRIBING_SLOT_ITERATION_END do
                    slots[slot] = {}
                    for scriptIndex = 1, GetNumScriptsInSlotForCraftedAbility(craftedId, slot) do
                        local scriptId = GetScriptIdAtSlotIndexForCraftedAbility(craftedId, slot, scriptIndex)
                        if scriptId > 0 and not IsCraftedAbilityScriptDisabled(scriptId) then
                            slots[slot][#slots[slot] + 1] = scriptId
                        end
                    end
                end
                for _, primary in ipairs(slots[SCRIBING_SLOT_PRIMARY]) do
                    for _, secondary in ipairs(slots[SCRIBING_SLOT_SECONDARY]) do
                        for _, tertiary in ipairs(slots[SCRIBING_SLOT_TERTIARY]) do
                            if IsScribableScriptCombinationForCraftedAbility(craftedId, primary, secondary, tertiary)
                                and IsCraftedAbilityScriptCompatibleWithSelections(primary, craftedId, primary, secondary, tertiary)
                                and IsCraftedAbilityScriptCompatibleWithSelections(secondary, craftedId, primary, secondary, tertiary)
                                and IsCraftedAbilityScriptCompatibleWithSelections(tertiary, craftedId, primary, secondary, tertiary) then
                                SetCraftedAbilityScriptSelectionOverride(craftedId, primary, secondary, tertiary)
                                local abilityId = GetCraftedAbilityRepresentativeAbilityId(craftedId)
                                if abilityId and abilityId > 0 then
                                    local parts = {}
                                    local function append(text)
                                        if text and text ~= "" then parts[#parts + 1] = text end
                                    end
                                    -- Same assembly as ZO_Tooltip:LayoutAbility, including
                                    -- the contextual script text rather than general defs.
                                    append(GetAbilityDescriptionHeader(abilityId))
                                    append(GetAbilityDescription(abilityId))
                                    for slot = SCRIBING_SLOT_ITERATION_BEGIN, SCRIBING_SLOT_ITERATION_END do
                                        append(GenerateCraftedAbilityScriptSlotDescriptionForAbilityDescription(abilityId, slot))
                                    end
                                    local classId = secondary == CLASS_FLOURISH_SCRIPT_ID and GetUnitClassId("player") or 0
                                    out.combinations[#out.combinations + 1] = row(craftedId, primary, secondary, tertiary,
                                        classId, zo_strformat("<<1>>", GetAbilityName(abilityId)),
                                        GetAbilityIcon(abilityId) or "", table.concat(parts, "\n"))
                                end
                            end
                            coroutine.yield()
                        end
                    end
                end
            end
        end
    end)
end

-- Preview overrides are global game UI state. Restore the previous selection
-- before returning control to the UI, including when a preview call fails.
local function scanCombinations(out)
    state.combinations = state.combinations or combinationIterator(out)
    local craftedId, primary, secondary, tertiary = GetCraftedAbilityScriptSelectionOverride()
    local ok, err = true, nil
    for _ = 1, COMBINATIONS_PER_TICK do
        ok, err = coroutine.resume(state.combinations)
        if not ok or coroutine.status(state.combinations) == "dead" then break end
    end
    if craftedId and craftedId > 0 then
        SetCraftedAbilityScriptSelectionOverride(craftedId, primary, secondary, tertiary)
    else
        ResetCraftedAbilityScriptSelectionOverride()
    end
    if not ok then
        EVENT_MANAGER:UnregisterForUpdate("BattleScrollsAbilityDump")
        state = nil
        d("[AbilityDump] Scribing preview failed; previous dump preserved: " .. tostring(err))
        return false
    end
    return coroutine.status(state.combinations) == "dead"
end

-- Skill lines. The type/index walk covers the lines this character can see; the
-- per-class walk adds every other class's lines, which turn up in shared setups
-- through subclassing.
local function scanSkillLines(out)
    local rows = out.skilllines
    local seen = {}
    local function add(skillLineId)
        if not skillLineId or skillLineId <= 0 or seen[skillLineId] then
            return
        end
        seen[skillLineId] = true
        local name = GetSkillLineNameById(skillLineId)
        if name and name ~= "" then
            -- Class lines use their subclassing collectible artwork, as in
            -- the journal. Detailed icons are XP reward art and return the
            -- missing-icon texture for class lines.
            local collectibleId = GetSkillLineMasteryCollectibleId(skillLineId)
            local icon = collectibleId and collectibleId > 0 and GetCollectibleIcon(collectibleId) or ""
            if icon == "" then
                icon = GetSkillLineDetailedIconById(skillLineId) or ""
            end
            rows[#rows + 1] = row(skillLineId, zo_strformat("<<1>>", name),
                icon, "")
        end
    end
    for skillType = SKILL_TYPE_ITERATION_BEGIN, SKILL_TYPE_ITERATION_END do
        for skillLineIndex = 1, GetNumSkillLines(skillType) do
            add(GetSkillLineId(skillType, skillLineIndex))
        end
    end
    for classIndex = 1, GetNumClasses() do
        local classId = GetClassIdByIndex(classIndex)
        for classSkillLineIndex = 1, GetNumSkillLinesForClass(classId) do
            add(GetSkillLineIdForClass(classId, classSkillLineIndex))
        end
    end
end

-- The Vengeance perk APIs postdate the rest of the surface used here, so every
-- entry point is resolved defensively; on a client without them the phase
-- reports the gap instead of erroring.
local function optionalApi(name)
    local fn = _G[name]
    return type(fn) == "function" and fn or nil
end

-- Vengeance perks. Perk *def ids* - the stable ids Battle Scrolls records in
-- setups - are reachable only through the current season's veterancy track:
-- the loadout APIs address perks by index, and indices are per-client state.
-- So: bounded walk over the track's ranks, once per role, deduped by def id.
-- Consequence worth knowing: perks outside the active season aren't listed.
local function scanPerks(out)
    local rows = out.perks
    local getNumPerksAtRank = optionalApi("GetNumberOfPerksUnlockedAtVeterancyRank")
    local getPerkDefId = optionalApi("GetPerkDefIdForPerkAtVeterancyRank")
    local getPerkName = optionalApi("GetVengeancePerkName")
    if not (getNumPerksAtRank and getPerkDefId and getPerkName) then
        d("[AbilityDump] Vengeance perk API not present on this client - skipping perks.")
        return
    end
    local getPerkIcon = optionalApi("GetVengeancePerkIcon")
    local getPerkTooltip = optionalApi("GetVengeancePerkTooltipText")
    local requestPerks = optionalApi("RequestParsedPerkAvailabilityForCurrentSeason")
    if requestPerks then
        requestPerks()
    end

    local seen = {}
    local function collectRole(roleIndex)
        for rank = 1, VENGEANCE_MAX_RANK do
            local rankOk, numPerks = pcall(getNumPerksAtRank, rank, roleIndex)
            if not rankOk then
                return
            end
            for unlockIndex = 1, numPerks or 0 do
                local idOk, defId = pcall(getPerkDefId, rank, unlockIndex, roleIndex)
                if idOk and defId and defId > 0 and not seen[defId] then
                    seen[defId] = true
                    local name = getPerkName(defId)
                    if name and name ~= "" then
                        rows[#rows + 1] = row(defId, zo_strformat("<<1>>", name),
                            getPerkIcon and getPerkIcon(defId) or "",
                            getPerkTooltip and getPerkTooltip(defId) or "")
                    end
                end
            end
        end
    end

    collectRole(nil) -- active role
    local getNumRoles = optionalApi("GetNumberOfVengeanceRolesAvailableToPlayer")
    if getNumRoles then
        local rolesOk, numRoles = pcall(getNumRoles)
        for roleIndex = 1, (rolesOk and numRoles or 0) do
            collectRole(roleIndex)
        end
    end
    if #rows == 0 then
        d("[AbilityDump] No perks listed - the perk track needs an active Vengeance season.")
    end
end

-- =============================================================================
-- DRIVER
-- =============================================================================

-- Phases small enough to finish inside one tick
local singleTickPhases = {
    champion = scanChampion,
    scripts = scanScripts,
    skilllines = scanSkillLines,
    sets = scanSets,
    perks = scanPerks,
}

local function finish()
    EVENT_MANAGER:UnregisterForUpdate("BattleScrollsAbilityDump")
    local saved = BattleScrollsAbilityDumpSV
    if type(saved) ~= "table" or saved.formatVersion ~= DUMP_FORMAT_VERSION then
        saved = { formatVersion = DUMP_FORMAT_VERSION, datasets = {} }
    end
    local dataset
    for _, candidate in ipairs(saved.datasets) do
        if candidate.gameVersion == state.gameVersion and candidate.apiVersion == state.apiVersion
            and candidate.language == state.language then
            dataset = candidate
            break
        end
    end
    if not dataset then
        dataset = { gameVersion = state.gameVersion, apiVersion = state.apiVersion, language = state.language }
        saved.datasets[#saved.datasets + 1] = dataset
    end
    for _, kind in ipairs(DATA_KINDS) do
        dataset[kind] = dataset[kind] or {}
        for _, value in ipairs(state.out[kind]) do
            -- The first five combination fields are grimoire/scripts/class;
            -- ordinary definition rows have a single id in the first field.
            local key = kind == "combinations"
                and value:match("^([^\t]+\t[^\t]+\t[^\t]+\t[^\t]+\t[^\t]+)\t")
                or value:match("^([^\t]+)\t")
            dataset[kind][key] = value
        end
    end
    BattleScrollsAbilityDumpSV = saved
    d(string.format(
        "[AbilityDump] Done (%s): %d abilities, %d items, %d champion skills, %d scripts, %d perks, %d skill lines, %d sets, %d enchants, %d traits, %d combinations. All passes retained in %d version/language datasets. /reloadui to save; import once after your last pass.",
        state.language, #state.out.abilities, #state.out.items, #state.out.champion,
        #state.out.scripts, #state.out.perks, #state.out.skilllines, #state.out.sets,
        #state.out.enchants, #state.out.traits, #state.out.combinations, #saved.datasets))
    state = nil
end

local function tick()
    if GetCVar("Language.2") ~= state.language then
        EVENT_MANAGER:UnregisterForUpdate("BattleScrollsAbilityDump")
        state = nil
        d("[AbilityDump] Language changed during the pass; previous completed passes preserved. Start the pass again.")
        return
    end
    local phase = state.phases[state.phase]
    if not phase then
        finish()
        return
    end
    if phase == "combinations" then
        if scanCombinations(state.out) then
            d(string.format("[AbilityDump] combinations phase complete (%d rows).", #state.out.combinations))
            state.phase = state.phase + 1
        end
        return
    end
    local scanPhase = singleTickPhases[phase]
    if scanPhase then
        scanPhase(state.out)
        d(string.format("[AbilityDump] %s phase complete (%d rows).",
            phase, #state.out[phase]))
        state.phase = state.phase + 1
        state.scanId = 1
        return
    end
    local max = phase == "abilities" and ABILITY_MAX or ITEM_MAX
    local stop = math.min(state.scanId + IDS_PER_TICK - 1, max)
    if phase == "abilities" then
        scanAbilities(state.out, state.scanId, stop)
    else
        scanItems(state.out, state.scanId, stop)
    end
    state.scanId = stop + 1
    if state.scanId > max then
        d(string.format("[AbilityDump] %s phase complete (%d rows).",
            phase, #state.out[phase]))
        state.phase = state.phase + 1
        state.scanId = 1
    elseif state.scanId % 50000 < IDS_PER_TICK then
        d(string.format("[AbilityDump] %s: %dk ids scanned...", phase,
            math.floor(state.scanId / 1000)))
    end
end

SLASH_COMMANDS["/bsabilitydump"] = function(args)
    if state then
        d("[AbilityDump] Already running.")
        return
    end
    local mode = args:match("^%s*(.-)%s*$")
    local allPhases = {
        "abilities", "champion", "scripts", "combinations", "skilllines", "sets", "perks", "items",
    }
    local phases = allPhases
    for _, name in ipairs(allPhases) do
        if mode == name then
            phases = { mode }
            break
        end
    end
    if mode ~= "" and phases == allPhases then
        d("[AbilityDump] Unknown mode. Use /bsabilitydump or one of: " .. table.concat(allPhases, ", "))
        return
    end
    state = {
        gameVersion = GetESOVersionString(),
        apiVersion = GetAPIVersion(),
        language = GetCVar("Language.2"),
        phases = phases,
        phase = 1,
        scanId = 1,
        out = {
            abilities = {},
            items = {},
            champion = {},
            scripts = {},
            combinations = {},
            perks = {},
            skilllines = {},
            sets = {},
            enchants = {}, -- filled by the items phase, no phase of its own
            traits = {}, -- filled by the items phase, no phase of its own
            setIds = {}, -- scratch: dedupes the two paths into out.sets
            enchantIds = {}, -- scratch: dedupes enchants across the item walk
            traitIds = {}, -- scratch: dedupes traits across the item walk
        },
    }
    d(string.format("[AbilityDump] Mining (%s): %s...",
        GetCVar("Language.2"), table.concat(phases, ", ")))
    EVENT_MANAGER:RegisterForUpdate("BattleScrollsAbilityDump", TICK_MS, tick)
end
