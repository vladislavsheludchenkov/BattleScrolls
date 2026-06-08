-----------------------------------------------------------
-- Setup Share
-- Demand-driven setup sharing via LibGroupBroadcast
--
-- Shares player build snapshots (class, race, abilities,
-- gear sets, traits, enchants, champion, food, mundus,
-- and Vengeance loadouts/perks)
-- with group members using a hash-based caching protocol.
--
-- Protocol 432: Setup Request (hash only)
-- Protocol 434: Setup Response V2 (legacy)
-- Protocol 436: Setup Response V3 (Class Mastery or Vengeance payload)
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

local log = BattleScrolls.log
local setupAnalysis = BattleScrolls.setupAnalysis

local ARMOR_SLOT_INDICES = setupAnalysis.ARMOR_SLOT_INDICES
local JEWELRY_SLOT_INDICES = setupAnalysis.JEWELRY_SLOT_INDICES

---@class SetupShare
---@field requestProtocol Protocol|nil Protocol 432
---@field responseProtocol Protocol|nil Protocol 434 legacy response
---@field responseProtocolV3 Protocol|nil Protocol 436 response with normal/Vengeance variants
local setupShare = {}
BattleScrolls.setupShare = setupShare

-- =============================================================================
-- LOCAL SETUP CACHE (hash → CompactSetup for local player's recent setups)
-- =============================================================================

---@type table<number, CompactSetup>
local localSetupCache = {}
local LOCAL_CACHE_MAX = 4

-- Selects the outbound setup response protocol. Protocol 436 stays registered
-- regardless so we can read data from newer clients.
local SEND_SETUP_RESPONSE_V3 = type(IsClassMasterySkillLine) == "function"

---@type number[]
local localCacheOrder = {} -- oldest first

-- =============================================================================
-- THROTTLE (don't respond to the same hash within 5 seconds)
-- =============================================================================

---@type table<number, number>
local lastResponseTime = {} -- hash → GetGameTimeMilliseconds

local RESPONSE_THROTTLE_MS = 5000

-- =============================================================================
-- CONVERT TO COMPACT
-- =============================================================================

---Extracts ability IDs from a bar's ability list
---@param abilities PlayerSetupAbility[]
---@return number[]
local function extractAbilityIds(abilities)
    local result = {}
    for i = 1, 6 do
        local ability = abilities[i]
        result[i] = ability and ability.abilityId or 0
    end
    return result
end

---Extracts weapon type from an equipment slot link (0 if empty)
---@param link string|false
---@return number weaponType
local function getWeaponType(link)
    if not link then return 0 end
    return GetItemLinkWeaponType(link) or 0
end

---Extracts trait type from an equipment slot link (0 if empty)
---@param link string|false
---@return number traitType
local function getTraitType(link)
    if not link then return 0 end
    return GetItemLinkTraitType(link) or 0
end

---Extracts enchant ID from an equipment slot link (0 if empty)
---@param link string|false
---@return number enchantId
local function getEnchantId(link)
    if not link then return 0 end
    return GetItemLinkFinalEnchantId(link) or 0
end

---Converts a full PlayerSetup into a numeric-only CompactSetup for network sharing.
---@param setup PlayerSetup
---@return CompactSetup
function setupShare.convertToCompact(setup)
    local equipSlots = setup.equipSlots

    -- Abilities: optional bars
    local frontAbilities = nil
    local backAbilities = nil
    local werewolfAbilities = nil

    if setup.werewolfEntireFight then
        -- WW entire fight: front/back nil, werewolf from captured bar
        if setup.werewolfAbilities then
            werewolfAbilities = extractAbilityIds(setup.werewolfAbilities)
        end
    else
        if not setup.frontBarDisabled then
            frontAbilities = extractAbilityIds(setup.abilities.front)
        end
        if not setup.backBarDisabled then
            backAbilities = extractAbilityIds(setup.abilities.back)
        end
        if setup.werewolfAbilities then
            werewolfAbilities = extractAbilityIds(setup.werewolfAbilities)
        end
    end

    ---@type CompactSetupSet[]
    local sets = {}
    local armorWeights = { 0, 0, 0 }
    local weaponTypes = setup.weaponTypes
    local armorTraits = {}
    local armorEnchants = {}
    local jewelryTraits = {}
    local jewelryEnchants = {}
    local weaponTraits = { 0, 0, 0, 0 }
    local weaponEnchants = { 0, 0, 0, 0 }

    if not setup.isVengeance then
        -- Sets: from computeSetData, extract {setId, frontCount, backCount}
        local setData = setupAnalysis.computeSetData(equipSlots)
        for groupId, data in pairs(setData) do
            if data.frontStep > 0 or data.backStep > 0 then
                local isPerfected = data.perfectedActiveFront or data.perfectedActiveBack
                local wireSetId = (isPerfected and data.perfectedSetId) and data.perfectedSetId or groupId
                sets[#sets + 1] = {
                    setId = wireSetId,
                    frontCount = data.frontCount,
                    backCount = data.backCount,
                }
            end
        end
        -- Sort by max count descending for deterministic ordering
        table.sort(sets, function(a, b)
            local aMax = math.max(a.frontCount, a.backCount)
            local bMax = math.max(b.frontCount, b.backCount)
            if aMax ~= bMax then return aMax > bMax end
            return a.setId < b.setId
        end)
        -- Limit to 6 sets
        while #sets > 6 do
            sets[#sets] = nil
        end

        -- Armor weights
        local light, medium, heavy = setupAnalysis.countArmorWeights(equipSlots)
        armorWeights = { light, medium, heavy }

        -- Weapon types: positional for slots 5, 6, 13, 14
        weaponTypes = {
            getWeaponType(equipSlots[5]),
            getWeaponType(equipSlots[6]),
            getWeaponType(equipSlots[13]),
            getWeaponType(equipSlots[14]),
        }

        -- Armor traits/enchants (grouped)
        armorTraits = setupAnalysis.groupTraitIds(equipSlots, ARMOR_SLOT_INDICES)
        armorEnchants = setupAnalysis.groupEnchantIds(equipSlots, ARMOR_SLOT_INDICES)

        -- Jewelry traits/enchants (grouped)
        jewelryTraits = setupAnalysis.groupTraitIds(equipSlots, JEWELRY_SLOT_INDICES)
        jewelryEnchants = setupAnalysis.groupEnchantIds(equipSlots, JEWELRY_SLOT_INDICES)

        -- Weapon traits/enchants: positional for slots 5, 6, 13, 14
        weaponTraits = {
            getTraitType(equipSlots[5]),
            getTraitType(equipSlots[6]),
            getTraitType(equipSlots[13]),
            getTraitType(equipSlots[14]),
        }
        weaponEnchants = {
            getEnchantId(equipSlots[5]),
            getEnchantId(equipSlots[6]),
            getEnchantId(equipSlots[13]),
            getEnchantId(equipSlots[14]),
        }
    end
    weaponTypes = weaponTypes or { 0, 0, 0, 0 }

    -- Champion: place skills at positional slots (4 per discipline)
    -- Decoder uses math.ceil(i / 4) to recover disciplineIndex, so positions must match.
    local champion = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
    if not setup.isVengeance then
        local disciplineOffset = {}
        for disciplineIndex = 1, GetNumChampionDisciplines() do
            disciplineOffset[GetChampionDisciplineId(disciplineIndex)] = (disciplineIndex - 1) * 4
        end
        local disciplineCount = {}
        for _, skill in ipairs(setup.champion) do
            local offset = disciplineOffset[skill.disciplineId]
            if offset then
                local count = (disciplineCount[skill.disciplineId] or 0) + 1
                if count <= 4 then
                    disciplineCount[skill.disciplineId] = count
                    champion[offset + count] = skill.skillId
                end
            end
        end
    end

    -- Food: up to 3 abilityIds
    local foodAbilityIds = {}
    if not setup.isVengeance and setup.foods then
        for _, food in ipairs(setup.foods) do
            if #foodAbilityIds < 3 then
                foodAbilityIds[#foodAbilityIds + 1] = food.abilityId
            end
        end
    end

    -- Mundus: direct copy
    local mundusAbilityIds = setup.isVengeance and {} or (setup.mundusAbilityIds or {})

    -- Class skill lines and Class Mastery passives: direct copy
    local sourceClassSkillLineIds = setup.classSkillLineIds or {}
    local classSkillLineIds = {}
    for i = 1, 3 do
        classSkillLineIds[i] = sourceClassSkillLineIds[i] or 0
    end
    local classMasteryAbilityIds = setup.classMasteryAbilityIds
    if setup.isVengeance then
        classMasteryAbilityIds = nil
    end

    -- Scribed abilities: collect from all bars (deduplicated by abilityId)
    ---@type CompactScribedAbility[]
    local scribedAbilities = {}
    local seenScribed = {}
    local function collectScribed(bar)
        if not bar then return end
        for _, ability in ipairs(bar) do
            if ability.craftedAbilityId and ability.scriptIds and not seenScribed[ability.abilityId] then
                seenScribed[ability.abilityId] = true
                scribedAbilities[#scribedAbilities + 1] = {
                    abilityId = ability.abilityId,
                    scriptIds = {
                        ability.scriptIds[1] or 0,
                        ability.scriptIds[2] or 0,
                        ability.scriptIds[3] or 0,
                    },
                }
            end
        end
    end
    if setup.abilities then
        collectScribed(setup.abilities.front)
        collectScribed(setup.abilities.back)
    end
    collectScribed(setup.werewolfAbilities)
    -- Limit to 7 (maxLength of protocol array)
    while #scribedAbilities > 7 do
        scribedAbilities[#scribedAbilities] = nil
    end

    -- Poisons: extract PotionEffect (crafted) or item ID (unique) from item link
    local frontPoisonEffect, frontPoisonItemId = nil, nil
    local backPoisonEffect, backPoisonItemId = nil, nil
    if not setup.isVengeance and setup.frontPoison then
        local pe = tonumber(setup.frontPoison.itemLink:match(":(%d+)|h"))
        if pe and pe > 0 then
            frontPoisonEffect = pe
        else
            frontPoisonItemId = tonumber(setup.frontPoison.itemLink:match("|H%d:item:(%d+)"))
        end
    end
    if not setup.isVengeance and setup.backPoison then
        local pe = tonumber(setup.backPoison.itemLink:match(":(%d+)|h"))
        if pe and pe > 0 then
            backPoisonEffect = pe
        else
            backPoisonItemId = tonumber(setup.backPoison.itemLink:match("|H%d:item:(%d+)"))
        end
    end

    ---@type CompactSetup
    return {
        classId = setup.classId,
        raceId = setup.raceId,
        isVengeance = setup.isVengeance or nil,
        frontAbilities = frontAbilities,
        backAbilities = backAbilities,
        werewolfAbilities = werewolfAbilities,
        sets = sets,
        armorWeights = armorWeights,
        weaponTypes = weaponTypes,
        armorTraits = armorTraits,
        armorEnchants = armorEnchants,
        jewelryTraits = jewelryTraits,
        jewelryEnchants = jewelryEnchants,
        weaponTraits = weaponTraits,
        weaponEnchants = weaponEnchants,
        champion = champion,
        foodAbilityIds = foodAbilityIds,
        mundusAbilityIds = mundusAbilityIds,
        classSkillLineIds = classSkillLineIds,
        classMasteryAbilityIds = classMasteryAbilityIds,
        loadoutSkillLineId = setup.loadoutSkillLineId,
        vengeancePerkDefIds = setup.vengeancePerkDefIds,
        scribedAbilities = scribedAbilities,
        frontPoisonEffect = frontPoisonEffect,
        frontPoisonItemId = frontPoisonItemId,
        backPoisonEffect = backPoisonEffect,
        backPoisonItemId = backPoisonItemId,
    }
end

-- =============================================================================
-- HASH
-- =============================================================================

---XOR-rotate-mix hash of all numeric fields in a CompactSetup.
---Simple, deterministic, 16-bit. Just needs to differentiate 2-3 setups per player.
---@param compact CompactSetup
---@return number hash 16-bit hash (0-65535)
function setupShare.computeHash(compact)
    local h = 0

    local function mix(value)
        h = BitXor(h, value)
        -- Rotate left by 3 bits within 16-bit space
        h = BitAnd(BitOr(BitLShift(h, 3), BitRShift(h, 13)), 0xFFFF)
    end

    mix(compact.classId)
    mix(compact.raceId)
    mix(compact.isVengeance and 1 or 0)

    if compact.frontAbilities then
        for _, id in ipairs(compact.frontAbilities) do mix(id) end
    end
    if compact.backAbilities then
        for _, id in ipairs(compact.backAbilities) do mix(id) end
    end
    if compact.werewolfAbilities then
        for _, id in ipairs(compact.werewolfAbilities) do mix(id) end
    end

    for _, set in ipairs(compact.sets) do
        mix(set.setId)
        mix(set.frontCount)
        mix(set.backCount)
    end

    for _, w in ipairs(compact.weaponTypes) do mix(w) end

    if compact.isVengeance then
        mix(compact.loadoutSkillLineId or 0)
        for _, perkDefId in ipairs(compact.vengeancePerkDefIds or {}) do mix(perkDefId) end
    else
        for _, w in ipairs(compact.armorWeights) do mix(w) end

        for _, entry in ipairs(compact.armorTraits) do
            mix(entry.traitType)
            mix(entry.count)
        end
        for _, entry in ipairs(compact.armorEnchants) do
            mix(entry.enchantId)
            mix(entry.count)
        end
        for _, entry in ipairs(compact.jewelryTraits) do
            mix(entry.traitType)
            mix(entry.count)
        end
        for _, entry in ipairs(compact.jewelryEnchants) do
            mix(entry.enchantId)
            mix(entry.count)
        end

        for _, t in ipairs(compact.weaponTraits) do mix(t) end
        for _, e in ipairs(compact.weaponEnchants) do mix(e) end
        for _, c in ipairs(compact.champion) do mix(c) end
        for _, f in ipairs(compact.foodAbilityIds) do mix(f) end
        for _, m in ipairs(compact.mundusAbilityIds) do mix(m) end

        if SEND_SETUP_RESPONSE_V3 and compact.classMasteryAbilityIds ~= nil and #compact.classMasteryAbilityIds > 0 then
            for _, abilityId in ipairs(compact.classMasteryAbilityIds) do mix(abilityId) end
        else
            for _, sl in ipairs(compact.classSkillLineIds) do mix(sl) end
        end
    end
    for _, sa in ipairs(compact.scribedAbilities) do
        mix(sa.abilityId)
        for _, sid in ipairs(sa.scriptIds) do mix(sid) end
    end
    if not compact.isVengeance then
        if compact.frontPoisonEffect then mix(compact.frontPoisonEffect) end
        if compact.frontPoisonItemId then mix(compact.frontPoisonItemId) end
        if compact.backPoisonEffect then mix(compact.backPoisonEffect) end
        if compact.backPoisonItemId then mix(compact.backPoisonItemId) end
    end

    return h
end

-- =============================================================================
-- LOCAL CACHE MANAGEMENT
-- =============================================================================

---Caches a local player setup for responding to protocol 432 requests.
---@param hash number 16-bit hash
---@param compact CompactSetup
function setupShare:cacheLocalSetup(hash, compact)
    if localSetupCache[hash] then
        -- log.Debug(function() return string.format("SetupShare: hash %d already in local cache", hash) end)
        return -- Already cached
    end
    localSetupCache[hash] = compact
    localCacheOrder[#localCacheOrder + 1] = hash
    -- log.Debug(function() return string.format("SetupShare: cached local setup hash %d (%d in cache)", hash, #localCacheOrder) end)

    -- Evict oldest if over limit
    while #localCacheOrder > LOCAL_CACHE_MAX do
        local oldest = table.remove(localCacheOrder, 1)
        localSetupCache[oldest] = nil
        -- log.Debug(function() return string.format("SetupShare: evicted hash %d from local cache", oldest) end)
    end
end

-- =============================================================================
-- PERSISTENT SHARED SETUP STORE
-- =============================================================================

---@type table<string, table<number, CompactSetup>>|nil
local sharedSetups = nil

---Checks if a setup is already stored for a player.
---@param displayName string
---@param hash number
---@return boolean
function setupShare:hasSetup(displayName, hash)
    if not sharedSetups then return false end
    local playerSetups = sharedSetups[displayName]
    return playerSetups ~= nil and playerSetups[hash] ~= nil
end

---Gets a stored setup for a player.
---@param displayName string
---@param hash number
---@return CompactSetup|nil
function setupShare:getSetup(displayName, hash)
    if not sharedSetups then return nil end
    local playerSetups = sharedSetups[displayName]
    return playerSetups and playerSetups[hash] or nil
end

---Stores a setup for a player.
---@param displayName string
---@param hash number
---@param compact CompactSetup
function setupShare:storeSetup(displayName, hash, compact)
    if not sharedSetups then return end
    if not sharedSetups[displayName] then
        sharedSetups[displayName] = {}
    end
    sharedSetups[displayName][hash] = compact
end

-- =============================================================================
-- ENCOUNTER HASH HANDLER
-- =============================================================================

---Called when an encounter share (protocol 437) provides a setupHash.
---Requests the full setup if not already cached.
---@param displayName string Sender's display name
---@param hash number 16-bit setup hash
function setupShare:onEncounterHashReceived(displayName, hash)
    if self:hasSetup(displayName, hash) then
        -- log.Debug(function() return string.format("SetupShare: already have setup for %s hash %d", displayName, hash) end)
        return -- Already have this setup
    end
    if not self.requestProtocol then
        return
    end
    if IsUnitGrouped("player") then
        -- log.Debug(function() return string.format("SetupShare: requesting setup for %s hash %d", displayName, hash) end)
        self.requestProtocol:Send({ setupHash = hash })
    end
end

-- =============================================================================
-- PROTOCOL HANDLERS
-- =============================================================================

---Copies compact set entries into the LGB wire shape.
---@param compact CompactSetup
---@return table[]
local function buildWireSets(compact)
    local wireSets = {}
    for _, set in ipairs(compact.sets or {}) do
        wireSets[#wireSets + 1] = {
            setId = set.setId,
            frontCount = set.frontCount,
            backCount = set.backCount,
        }
    end
    return wireSets
end

---Copies compact grouped trait entries into the LGB wire shape.
---@param entries CompactTraitEntry[]|nil
---@return table[]
local function buildWireTraits(entries)
    local wire = {}
    for _, entry in ipairs(entries or {}) do
        wire[#wire + 1] = { traitType = entry.traitType, count = entry.count }
    end
    return wire
end

---Copies compact grouped enchant entries into the LGB wire shape.
---@param entries CompactEnchantEntry[]|nil
---@return table[]
local function buildWireEnchants(entries)
    local wire = {}
    for _, entry in ipairs(entries or {}) do
        wire[#wire + 1] = { enchantId = entry.enchantId, count = entry.count }
    end
    return wire
end

---Copies compact scribed ability entries into the LGB wire shape.
---@param entries CompactScribedAbility[]|nil
---@return table[]
local function buildWireScribedAbilities(entries)
    local wire = {}
    for _, sa in ipairs(entries or {}) do
        wire[#wire + 1] = {
            abilityId = sa.abilityId,
            scriptId1 = sa.scriptIds[1],
            scriptId2 = sa.scriptIds[2],
            scriptId3 = sa.scriptIds[3],
        }
    end
    return wire
end

---Builds the normal build payload body for protocol 434 or protocol 436's normal variant.
---@param compact CompactSetup
---@param includeClassMastery boolean
---@return table
local function buildNormalWirePayload(compact, includeClassMastery)
    local payload = {
        frontAbilities = compact.frontAbilities,
        backAbilities = compact.backAbilities,
        werewolfAbilities = compact.werewolfAbilities,
        set = buildWireSets(compact),
        lightCount = compact.armorWeights[1],
        mediumCount = compact.armorWeights[2],
        heavyCount = compact.armorWeights[3],
        frontMHWeaponType = compact.weaponTypes[1],
        frontOHWeaponType = compact.weaponTypes[2],
        backMHWeaponType = compact.weaponTypes[3],
        backOHWeaponType = compact.weaponTypes[4],
        armorTrait = buildWireTraits(compact.armorTraits),
        armorEnchant = buildWireEnchants(compact.armorEnchants),
        jewelryTrait = buildWireTraits(compact.jewelryTraits),
        jewelryEnchant = buildWireEnchants(compact.jewelryEnchants),
        frontMHTrait = compact.weaponTraits[1],
        frontOHTrait = compact.weaponTraits[2],
        backMHTrait = compact.weaponTraits[3],
        backOHTrait = compact.weaponTraits[4],
        frontMHEnchant = compact.weaponEnchants[1],
        frontOHEnchant = compact.weaponEnchants[2],
        backMHEnchant = compact.weaponEnchants[3],
        backOHEnchant = compact.weaponEnchants[4],
        champion = compact.champion,
        foodAbilityIds = compact.foodAbilityIds,
        mundusAbilityIds = compact.mundusAbilityIds,
        scribedAbility = buildWireScribedAbilities(compact.scribedAbilities),
        frontPoisonEffect = compact.frontPoisonEffect,
        frontPoisonItemId = compact.frontPoisonItemId,
        backPoisonEffect = compact.backPoisonEffect,
        backPoisonItemId = compact.backPoisonItemId,
    }

    if includeClassMastery and compact.classMasteryAbilityIds ~= nil and #compact.classMasteryAbilityIds > 0 then
        payload.classMasteryAbilityIds = compact.classMasteryAbilityIds
    else
        payload.classSkillLineIds = compact.classSkillLineIds
    end

    return payload
end

---Builds the Vengeance payload body for protocol 436's Vengeance variant.
---@param compact CompactSetup
---@return table
local function buildVengeanceWirePayload(compact)
    local perkDefIds = compact.vengeancePerkDefIds or {}
    return {
        frontAbilities = compact.frontAbilities,
        backAbilities = compact.backAbilities,
        werewolfAbilities = compact.werewolfAbilities,
        frontMHWeaponType = compact.weaponTypes[1],
        frontOHWeaponType = compact.weaponTypes[2],
        backMHWeaponType = compact.weaponTypes[3],
        backOHWeaponType = compact.weaponTypes[4],
        loadoutSkillLineId = compact.loadoutSkillLineId or 0,
        vengeancePerkDefIds = { perkDefIds[1] or 0, perkDefIds[2] or 0, perkDefIds[3] or 0 },
        scribedAbility = buildWireScribedAbilities(compact.scribedAbilities),
    }
end

---Handles incoming setup request (protocol 432)
---@param unitTag string
---@param data table
local function onSetupRequest(unitTag, data)
    if AreUnitsEqual(unitTag, "player") then return end

    local hash = data.setupHash
    if not hash then return end

    local compact = localSetupCache[hash]
    if not compact then
        -- log.Debug(function() return string.format("SetupShare: request for hash %d - not in local cache", hash) end)
        return
    end

    -- Throttle: don't respond if we sent this hash recently
    local now = GetGameTimeMilliseconds()
    if lastResponseTime[hash] and now - lastResponseTime[hash] < RESPONSE_THROTTLE_MS then
        -- log.Debug(function() return string.format("SetupShare: request for hash %d - throttled", hash) end)
        return
    end

    local sent = false
    if SEND_SETUP_RESPONSE_V3 then
        if not setupShare.responseProtocolV3 then return end
        local payload = {
            setupHash = hash,
            classId = compact.classId,
            raceId = compact.raceId,
        }
        if compact.isVengeance then
            payload.vengeanceSetup = buildVengeanceWirePayload(compact)
        else
            payload.normalSetup = buildNormalWirePayload(compact, true)
        end
        setupShare.responseProtocolV3:Send(payload)
        sent = true
    else
        if compact.isVengeance then
            -- Protocol 434 is already live and has no Vengeance variant.
            return
        end
        if not setupShare.responseProtocol then return end
        local payload = buildNormalWirePayload(compact, false)
        payload.setupHash = hash
        payload.classId = compact.classId
        payload.raceId = compact.raceId
        setupShare.responseProtocol:Send(payload)
        sent = true
    end

    if sent then
        lastResponseTime[hash] = now
        -- log.Debug(function() return string.format("SetupShare: sent setup response for hash %d", hash) end)
    end
end

---Decodes set entries from LGB wire data.
---@param data table
---@return CompactSetupSet[]
local function decodeWireSets(data)
    local sets = {}
    if data.set then
        for _, s in ipairs(data.set) do
            sets[#sets + 1] = {
                setId = s.setId,
                frontCount = s.frontCount,
                backCount = s.backCount,
            }
        end
    end
    return sets
end

---Decodes grouped trait entries from LGB wire data.
---@param entries table[]|nil
---@return CompactTraitEntry[]
local function decodeWireTraits(entries)
    local traits = {}
    if entries then
        for _, t in ipairs(entries) do
            traits[#traits + 1] = { traitType = t.traitType, count = t.count }
        end
    end
    return traits
end

---Decodes grouped enchant entries from LGB wire data.
---@param entries table[]|nil
---@return CompactEnchantEntry[]
local function decodeWireEnchants(entries)
    local enchants = {}
    if entries then
        for _, e in ipairs(entries) do
            enchants[#enchants + 1] = { enchantId = e.enchantId, count = e.count }
        end
    end
    return enchants
end

---Decodes scribed ability entries from LGB wire data.
---@param entries table[]|nil
---@return CompactScribedAbility[]
local function decodeWireScribedAbilities(entries)
    local scribedAbilities = {}
    if entries then
        for _, sa in ipairs(entries) do
            scribedAbilities[#scribedAbilities + 1] = {
                abilityId = sa.abilityId,
                scriptIds = { sa.scriptId1, sa.scriptId2, sa.scriptId3 },
            }
        end
    end
    return scribedAbilities
end

local CLASS_PAYLOAD_VARIANT_KEY = "variants(classSkillLineIds, classMasteryAbilityIds)"
local CLASS_SKILL_LINE_ID_WIRE_MAX = 1023

---Decodes class skill lines or Class Mastery abilities from a normal setup body.
---LibGroupBroadcast's VariantField preserves variant labels at the top level,
---but when nested in a TableField the value is keyed by the synthetic
---"variants(...)" label. Recover that shape without changing the wire protocol.
---@param data table
---@return number[] classSkillLineIds
---@return number[]|nil classMasteryAbilityIds
local function decodeClassPayload(data)
    if data.classSkillLineIds or data.classMasteryAbilityIds then
        return data.classSkillLineIds or { 0, 0, 0 }, data.classMasteryAbilityIds
    end

    local nestedVariant = data[CLASS_PAYLOAD_VARIANT_KEY]
    if type(nestedVariant) ~= "table" then
        return { 0, 0, 0 }, nil
    end

    for _, value in ipairs(nestedVariant) do
        if value > CLASS_SKILL_LINE_ID_WIRE_MAX then
            return { 0, 0, 0 }, nestedVariant
        end
    end

    return nestedVariant, nil
end

---Reconstructs a normal CompactSetup from flat legacy fields or protocol 436 normal body fields.
---@param common table
---@param data table
---@return CompactSetup
local function decodeNormalCompact(common, data)
    local classSkillLineIds, classMasteryAbilityIds = decodeClassPayload(data)

    return {
        classId = common.classId,
        raceId = common.raceId,
        frontAbilities = data.frontAbilities,
        backAbilities = data.backAbilities,
        werewolfAbilities = data.werewolfAbilities,
        sets = decodeWireSets(data),
        armorWeights = { data.lightCount or 0, data.mediumCount or 0, data.heavyCount or 0 },
        weaponTypes = {
            data.frontMHWeaponType or 0,
            data.frontOHWeaponType or 0,
            data.backMHWeaponType or 0,
            data.backOHWeaponType or 0,
        },
        armorTraits = decodeWireTraits(data.armorTrait),
        armorEnchants = decodeWireEnchants(data.armorEnchant),
        jewelryTraits = decodeWireTraits(data.jewelryTrait),
        jewelryEnchants = decodeWireEnchants(data.jewelryEnchant),
        weaponTraits = {
            data.frontMHTrait or 0,
            data.frontOHTrait or 0,
            data.backMHTrait or 0,
            data.backOHTrait or 0,
        },
        weaponEnchants = {
            data.frontMHEnchant or 0,
            data.frontOHEnchant or 0,
            data.backMHEnchant or 0,
            data.backOHEnchant or 0,
        },
        champion = data.champion or {},
        foodAbilityIds = data.foodAbilityIds or {},
        mundusAbilityIds = data.mundusAbilityIds or {},
        classSkillLineIds = classSkillLineIds,
        classMasteryAbilityIds = classMasteryAbilityIds,
        scribedAbilities = decodeWireScribedAbilities(data.scribedAbility),
        frontPoisonEffect = data.frontPoisonEffect,
        frontPoisonItemId = data.frontPoisonItemId,
        backPoisonEffect = data.backPoisonEffect,
        backPoisonItemId = data.backPoisonItemId,
    }
end

---Reconstructs a Vengeance CompactSetup from protocol 436 Vengeance body fields.
---@param common table
---@param data table
---@return CompactSetup
local function decodeVengeanceCompact(common, data)
    local perkDefIds = data.vengeancePerkDefIds or {}
    return {
        classId = common.classId,
        raceId = common.raceId,
        isVengeance = true,
        frontAbilities = data.frontAbilities,
        backAbilities = data.backAbilities,
        werewolfAbilities = data.werewolfAbilities,
        sets = {},
        armorWeights = { 0, 0, 0 },
        weaponTypes = {
            data.frontMHWeaponType or 0,
            data.frontOHWeaponType or 0,
            data.backMHWeaponType or 0,
            data.backOHWeaponType or 0,
        },
        armorTraits = {},
        armorEnchants = {},
        jewelryTraits = {},
        jewelryEnchants = {},
        weaponTraits = { 0, 0, 0, 0 },
        weaponEnchants = { 0, 0, 0, 0 },
        champion = {},
        foodAbilityIds = {},
        mundusAbilityIds = {},
        classSkillLineIds = {},
        loadoutSkillLineId = data.loadoutSkillLineId,
        vengeancePerkDefIds = { perkDefIds[1] or 0, perkDefIds[2] or 0, perkDefIds[3] or 0 },
        scribedAbilities = decodeWireScribedAbilities(data.scribedAbility),
    }
end

---Stores a decoded compact setup for a sender.
---@param unitTag string
---@param hash number
---@param compact CompactSetup
local function storeDecodedSetup(unitTag, hash, compact)
    if AreUnitsEqual(unitTag, "player") then return end

    local displayName = BattleScrolls.utils.GetUndecoratedDisplayName(unitTag)
    if not displayName or displayName == "" then return end

    setupShare:storeSetup(displayName, hash, compact)
    -- log.Debug(function() return string.format("SetupShare: received and stored setup from %s hash %d", displayName, hash) end)
end

---Handles incoming legacy normal setup response (protocol 434).
---@param unitTag string
---@param data table
local function onLegacySetupResponse(unitTag, data)
    local hash = data.setupHash
    if not hash then return end
    storeDecodedSetup(unitTag, hash, decodeNormalCompact(data, data))
end

---Handles incoming setup response with normal/Vengeance variants (protocol 436).
---@param unitTag string
---@param data table
local function onSetupResponseV3(unitTag, data)
    local hash = data.setupHash
    if not hash then return end

    local compact
    if data.vengeanceSetup then
        compact = decodeVengeanceCompact(data, data.vengeanceSetup)
    elseif data.normalSetup then
        compact = decodeNormalCompact(data, data.normalSetup)
    else
        return
    end

    storeDecodedSetup(unitTag, hash, compact)
end

-- =============================================================================
-- PROTOCOL FIELD DECLARATIONS
-- =============================================================================

---Declares an optional ability bar array field (6 x 18-bit abilityId)
---@param LGB table LibGroupBroadcast reference
---@param name string Unique field name (e.g. "frontAbilities")
---@return table field
local function createAbilityBarField(LGB, name)
    return LGB.CreateOptionalField(
        LGB.CreateArrayField(
            LGB.CreateNumericField(name, { minValue = 0, numBits = 18, trimValues = true }),
            { maxLength = 6 }
        )
    )
end

---Appends field declarations to a protocol.
---@param protocol Protocol
---@param fields table[]
local function addFieldsToProtocol(protocol, fields)
    for _, field in ipairs(fields) do
        protocol:AddField(field)
    end
end

---Creates LGB fields for the normal build payload body.
---@param LGB table LibGroupBroadcast reference
---@param includeClassMasteryAbilities boolean
---@return table[] fields
local function createNormalSetupFields(LGB, includeClassMasteryAbilities)
    local fields = {
        createAbilityBarField(LGB, "frontAbilities"),
        createAbilityBarField(LGB, "backAbilities"),
        createAbilityBarField(LGB, "werewolfAbilities"),
        LGB.CreateArrayField(
            LGB.CreateTableField("set", {
                LGB.CreateNumericField("setId", { minValue = 0, numBits = 10, trimValues = true }),
                LGB.CreateNumericField("frontCount", { minValue = 0, numBits = 3, trimValues = true }),
                LGB.CreateNumericField("backCount", { minValue = 0, numBits = 3, trimValues = true }),
            }),
            { maxLength = 6 }
        ),
        LGB.CreateNumericField("lightCount", { minValue = 0, numBits = 3, trimValues = true }),
        LGB.CreateNumericField("mediumCount", { minValue = 0, numBits = 3, trimValues = true }),
        LGB.CreateNumericField("heavyCount", { minValue = 0, numBits = 3, trimValues = true }),
        LGB.CreateNumericField("frontMHWeaponType", { minValue = 0, numBits = 5, trimValues = true }),
        LGB.CreateNumericField("frontOHWeaponType", { minValue = 0, numBits = 5, trimValues = true }),
        LGB.CreateNumericField("backMHWeaponType", { minValue = 0, numBits = 5, trimValues = true }),
        LGB.CreateNumericField("backOHWeaponType", { minValue = 0, numBits = 5, trimValues = true }),
        LGB.CreateArrayField(
            LGB.CreateTableField("armorTrait", {
                LGB.CreateNumericField("traitType", { minValue = 0, numBits = 6, trimValues = true }),
                LGB.CreateNumericField("count", { minValue = 0, numBits = 3, trimValues = true }),
            }),
            { maxLength = 4 }
        ),
        LGB.CreateArrayField(
            LGB.CreateTableField("armorEnchant", {
                LGB.CreateNumericField("enchantId", { minValue = 0, numBits = 9, trimValues = true }),
                LGB.CreateNumericField("count", { minValue = 0, numBits = 3, trimValues = true }),
            }),
            { maxLength = 4 }
        ),
        LGB.CreateArrayField(
            LGB.CreateTableField("jewelryTrait", {
                LGB.CreateNumericField("traitType", { minValue = 0, numBits = 6, trimValues = true }),
                LGB.CreateNumericField("count", { minValue = 0, numBits = 3, trimValues = true }),
            }),
            { maxLength = 3 }
        ),
        LGB.CreateArrayField(
            LGB.CreateTableField("jewelryEnchant", {
                LGB.CreateNumericField("enchantId", { minValue = 0, numBits = 9, trimValues = true }),
                LGB.CreateNumericField("count", { minValue = 0, numBits = 3, trimValues = true }),
            }),
            { maxLength = 3 }
        ),
        LGB.CreateNumericField("frontMHTrait", { minValue = 0, numBits = 6, trimValues = true }),
        LGB.CreateNumericField("frontOHTrait", { minValue = 0, numBits = 6, trimValues = true }),
        LGB.CreateNumericField("backMHTrait", { minValue = 0, numBits = 6, trimValues = true }),
        LGB.CreateNumericField("backOHTrait", { minValue = 0, numBits = 6, trimValues = true }),
        LGB.CreateNumericField("frontMHEnchant", { minValue = 0, numBits = 9, trimValues = true }),
        LGB.CreateNumericField("frontOHEnchant", { minValue = 0, numBits = 9, trimValues = true }),
        LGB.CreateNumericField("backMHEnchant", { minValue = 0, numBits = 9, trimValues = true }),
        LGB.CreateNumericField("backOHEnchant", { minValue = 0, numBits = 9, trimValues = true }),
        LGB.CreateArrayField(
            LGB.CreateNumericField("champion", { minValue = 0, numBits = 10, trimValues = true }),
            { maxLength = 12 }
        ),
        LGB.CreateArrayField(
            LGB.CreateNumericField("foodAbilityIds", { minValue = 0, numBits = 18, trimValues = true }),
            { maxLength = 3 }
        ),
        LGB.CreateArrayField(
            LGB.CreateNumericField("mundusAbilityIds", { minValue = 0, numBits = 18, trimValues = true }),
            { maxLength = 2 }
        ),
    }

    if includeClassMasteryAbilities then
        fields[#fields + 1] = LGB.CreateVariantField({
            LGB.CreateArrayField(
                LGB.CreateNumericField("classSkillLineIds", { minValue = 0, numBits = 10, trimValues = true }),
                { maxLength = 3 }
            ),
            LGB.CreateArrayField(
                LGB.CreateNumericField("classMasteryAbilityIds", { minValue = 0, numBits = 20, trimValues = true }),
                { maxLength = 5 }
            ),
        })
    else
        fields[#fields + 1] = LGB.CreateArrayField(
            LGB.CreateNumericField("classSkillLineIds", { minValue = 0, numBits = 10, trimValues = true }),
            { maxLength = 3 }
        )
    end

    fields[#fields + 1] = LGB.CreateArrayField(
        LGB.CreateTableField("scribedAbility", {
            LGB.CreateNumericField("abilityId", { minValue = 0, numBits = 18, trimValues = true }),
            LGB.CreateNumericField("scriptId1", { minValue = 0, numBits = 8, trimValues = true }),
            LGB.CreateNumericField("scriptId2", { minValue = 0, numBits = 8, trimValues = true }),
            LGB.CreateNumericField("scriptId3", { minValue = 0, numBits = 8, trimValues = true }),
        }),
        { maxLength = 7 }
    )
    fields[#fields + 1] = LGB.CreateOptionalField(
        LGB.CreateVariantField({
            LGB.CreateNumericField("frontPoisonEffect", { minValue = 0, numBits = 24, trimValues = true }),
            LGB.CreateNumericField("frontPoisonItemId", { minValue = 0, numBits = 18, trimValues = true }),
        })
    )
    fields[#fields + 1] = LGB.CreateOptionalField(
        LGB.CreateVariantField({
            LGB.CreateNumericField("backPoisonEffect", { minValue = 0, numBits = 24, trimValues = true }),
            LGB.CreateNumericField("backPoisonItemId", { minValue = 0, numBits = 18, trimValues = true }),
        })
    )

    return fields
end

---Creates LGB fields for the Vengeance payload body.
---@param LGB table LibGroupBroadcast reference
---@return table[] fields
local function createVengeanceSetupFields(LGB)
    return {
        createAbilityBarField(LGB, "frontAbilities"),
        createAbilityBarField(LGB, "backAbilities"),
        createAbilityBarField(LGB, "werewolfAbilities"),
        LGB.CreateNumericField("frontMHWeaponType", { minValue = 0, numBits = 5, trimValues = true }),
        LGB.CreateNumericField("frontOHWeaponType", { minValue = 0, numBits = 5, trimValues = true }),
        LGB.CreateNumericField("backMHWeaponType", { minValue = 0, numBits = 5, trimValues = true }),
        LGB.CreateNumericField("backOHWeaponType", { minValue = 0, numBits = 5, trimValues = true }),
        LGB.CreateNumericField("loadoutSkillLineId", { minValue = 0, numBits = 10, trimValues = true }),
        LGB.CreateArrayField(
            LGB.CreateNumericField("vengeancePerkDefIds", { minValue = 0, numBits = 20, trimValues = true }),
            { maxLength = 3 }
        ),
        LGB.CreateArrayField(
            LGB.CreateTableField("scribedAbility", {
                LGB.CreateNumericField("abilityId", { minValue = 0, numBits = 18, trimValues = true }),
                LGB.CreateNumericField("scriptId1", { minValue = 0, numBits = 8, trimValues = true }),
                LGB.CreateNumericField("scriptId2", { minValue = 0, numBits = 8, trimValues = true }),
                LGB.CreateNumericField("scriptId3", { minValue = 0, numBits = 8, trimValues = true }),
            }),
            { maxLength = 7 }
        ),
    }
end

-- =============================================================================
-- INITIALIZE
-- =============================================================================

---Initialize setup sharing protocols with LibGroupBroadcast
function setupShare:Initialize()
    local LGB = LibGroupBroadcast
    if not LGB then return end

    local handler = BattleScrolls.lgbHandler
    if not handler then return end

    -- Load persistent store reference
    sharedSetups = BattleScrolls.storage.savedVariables.sharedSetups
    if not sharedSetups then
        BattleScrolls.storage.savedVariables.sharedSetups = {}
        sharedSetups = BattleScrolls.storage.savedVariables.sharedSetups
    end

    -- Protocol 432: Setup Request (hash only)
    local requestProtocol = handler:DeclareProtocol(432, "BattleScrolls_SetupRequest")
    requestProtocol:AddField(LGB.CreateNumericField("setupHash", { minValue = 0, numBits = 16, trimValues = true }))
    requestProtocol:OnData(onSetupRequest)
    if not requestProtocol:Finalize({ isRelevantInCombat = false, replaceQueuedMessages = false }) then
        log.Warn("SetupShare: request protocol 432 failed to finalize")
        return
    end
    self.requestProtocol = requestProtocol

    -- Protocol 434: Setup Response V2 (live legacy, normal builds only)
    local responseProtocol = handler:DeclareProtocol(434, "BattleScrolls_SetupResponseV2")
    responseProtocol:AddField(LGB.CreateNumericField("setupHash", { minValue = 0, numBits = 16, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("classId", { minValue = 0, numBits = 8, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("raceId", { minValue = 0, numBits = 8, trimValues = true }))
    addFieldsToProtocol(responseProtocol, createNormalSetupFields(LGB, false))
    responseProtocol:OnData(onLegacySetupResponse)
    if not responseProtocol:Finalize({ isRelevantInCombat = false, replaceQueuedMessages = false }) then
        log.Warn("SetupShare: response protocol 434 failed to finalize")
        return
    end
    self.responseProtocol = responseProtocol

    -- Protocol 436: Setup Response V3 (unreleased Class Mastery/Vengeance patch)
    local responseProtocolV3 = handler:DeclareProtocol(436, "BattleScrolls_SetupResponseV3")
    responseProtocolV3:AddField(LGB.CreateNumericField("setupHash", { minValue = 0, numBits = 16, trimValues = true }))
    responseProtocolV3:AddField(LGB.CreateNumericField("classId", { minValue = 0, numBits = 8, trimValues = true }))
    responseProtocolV3:AddField(LGB.CreateNumericField("raceId", { minValue = 0, numBits = 8, trimValues = true }))
    responseProtocolV3:AddField(LGB.CreateVariantField({
        LGB.CreateTableField("normalSetup", createNormalSetupFields(LGB, true)),
        LGB.CreateTableField("vengeanceSetup", createVengeanceSetupFields(LGB)),
    }))
    responseProtocolV3:OnData(onSetupResponseV3)
    if not responseProtocolV3:Finalize({ isRelevantInCombat = false, replaceQueuedMessages = false }) then
        log.Warn("SetupShare: response protocol 436 failed to finalize")
        return
    end
    self.responseProtocolV3 = responseProtocolV3
end
