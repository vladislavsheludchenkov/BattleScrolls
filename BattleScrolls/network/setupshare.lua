-----------------------------------------------------------
-- Setup Share
-- Demand-driven setup sharing via LibGroupBroadcast
--
-- Shares player build snapshots (class, race, abilities,
-- gear sets, traits, enchants, champion, food, mundus)
-- with group members using a hash-based caching protocol.
--
-- Protocol 432: Setup Request (hash only)
-- Protocol 433: Setup Response (full CompactSetup)
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
---@field responseProtocol Protocol|nil Protocol 433
local setupShare = {}
BattleScrolls.setupShare = setupShare

-- =============================================================================
-- LOCAL SETUP CACHE (hash → CompactSetup for local player's recent setups)
-- =============================================================================

---@type table<number, CompactSetup>
local localSetupCache = {}
local LOCAL_CACHE_MAX = 4

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

    -- Sets: from computeSetData, extract {setId, frontCount, backCount}
    local setData = setupAnalysis.computeSetData(equipSlots)
    ---@type CompactSetupSet[]
    local sets = {}
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

    -- Weapon types: positional for slots 5, 6, 13, 14
    local weaponTypes = {
        getWeaponType(equipSlots[5]),
        getWeaponType(equipSlots[6]),
        getWeaponType(equipSlots[13]),
        getWeaponType(equipSlots[14]),
    }

    -- Armor traits/enchants (grouped)
    local armorTraits = setupAnalysis.groupTraitIds(equipSlots, ARMOR_SLOT_INDICES)
    local armorEnchants = setupAnalysis.groupEnchantIds(equipSlots, ARMOR_SLOT_INDICES)

    -- Jewelry traits/enchants (grouped)
    local jewelryTraits = setupAnalysis.groupTraitIds(equipSlots, JEWELRY_SLOT_INDICES)
    local jewelryEnchants = setupAnalysis.groupEnchantIds(equipSlots, JEWELRY_SLOT_INDICES)

    -- Weapon traits/enchants: positional for slots 5, 6, 13, 14
    local weaponTraits = {
        getTraitType(equipSlots[5]),
        getTraitType(equipSlots[6]),
        getTraitType(equipSlots[13]),
        getTraitType(equipSlots[14]),
    }
    local weaponEnchants = {
        getEnchantId(equipSlots[5]),
        getEnchantId(equipSlots[6]),
        getEnchantId(equipSlots[13]),
        getEnchantId(equipSlots[14]),
    }

    -- Champion: pad to 12 with 0
    local champion = {}
    for i = 1, 12 do
        local skill = setup.champion[i]
        champion[i] = skill and skill.skillId or 0
    end

    -- Food: up to 3 abilityIds
    local foodAbilityIds = {}
    if setup.foods then
        for _, food in ipairs(setup.foods) do
            if #foodAbilityIds < 3 then
                foodAbilityIds[#foodAbilityIds + 1] = food.abilityId
            end
        end
    end

    -- Mundus: direct copy
    local mundusAbilityIds = setup.mundusAbilityIds or {}

    -- Class skill lines: direct copy
    local classSkillLineIds = setup.classSkillLineIds or { 0, 0, 0 }
    -- Pad to 3 entries
    while #classSkillLineIds < 3 do
        classSkillLineIds[#classSkillLineIds + 1] = 0
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
    if setup.frontPoison then
        local pe = tonumber(setup.frontPoison.itemLink:match(":(%d+)|h"))
        if pe and pe > 0 then
            frontPoisonEffect = pe
        else
            frontPoisonItemId = tonumber(setup.frontPoison.itemLink:match("|H%d:item:(%d+)"))
        end
    end
    if setup.backPoison then
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
        frontAbilities = frontAbilities,
        backAbilities = backAbilities,
        werewolfAbilities = werewolfAbilities,
        sets = sets,
        armorWeights = { light, medium, heavy },
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

    for _, w in ipairs(compact.armorWeights) do mix(w) end
    for _, w in ipairs(compact.weaponTypes) do mix(w) end

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

    for _, sl in ipairs(compact.classSkillLineIds) do mix(sl) end
    for _, sa in ipairs(compact.scribedAbilities) do
        mix(sa.abilityId)
        for _, sid in ipairs(sa.scriptIds) do mix(sid) end
    end
    if compact.frontPoisonEffect then mix(compact.frontPoisonEffect) end
    if compact.frontPoisonItemId then mix(compact.frontPoisonItemId) end
    if compact.backPoisonEffect then mix(compact.backPoisonEffect) end
    if compact.backPoisonItemId then mix(compact.backPoisonItemId) end

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

---Called when an encounter share (protocol 437) includes a setupHash.
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

---Handles incoming setup request (protocol 432)
---@param unitTag string
---@param data table
local function onSetupRequest(unitTag, data)
    if AreUnitsEqual(unitTag, "player") then return end

    local hash = data.setupHash
    if not hash then return end

    local compact = localSetupCache[hash]
    if not compact then
        -- log.Debug(function() return string.format("SetupShare: request for hash %d — not in local cache", hash) end)
        return
    end

    -- Throttle: don't respond if we sent this hash recently
    local now = GetGameTimeMilliseconds()
    if lastResponseTime[hash] and now - lastResponseTime[hash] < RESPONSE_THROTTLE_MS then
        -- log.Debug(function() return string.format("SetupShare: request for hash %d — throttled", hash) end)
        return
    end

    if not setupShare.responseProtocol then return end

    -- Build wire payload from CompactSetup
    local wireSets = {}
    for _, set in ipairs(compact.sets) do
        wireSets[#wireSets + 1] = {
            setId = set.setId,
            frontCount = set.frontCount,
            backCount = set.backCount,
        }
    end

    local wireArmorTraits = {}
    for _, entry in ipairs(compact.armorTraits) do
        wireArmorTraits[#wireArmorTraits + 1] = { traitType = entry.traitType, count = entry.count }
    end

    local wireArmorEnchants = {}
    for _, entry in ipairs(compact.armorEnchants) do
        wireArmorEnchants[#wireArmorEnchants + 1] = { enchantId = entry.enchantId, count = entry.count }
    end

    local wireJewelryTraits = {}
    for _, entry in ipairs(compact.jewelryTraits) do
        wireJewelryTraits[#wireJewelryTraits + 1] = { traitType = entry.traitType, count = entry.count }
    end

    local wireJewelryEnchants = {}
    for _, entry in ipairs(compact.jewelryEnchants) do
        wireJewelryEnchants[#wireJewelryEnchants + 1] = { enchantId = entry.enchantId, count = entry.count }
    end

    -- Scribed abilities for wire format
    local wireScribedAbilities = {}
    for _, sa in ipairs(compact.scribedAbilities) do
        wireScribedAbilities[#wireScribedAbilities + 1] = {
            abilityId = sa.abilityId,
            scriptId1 = sa.scriptIds[1],
            scriptId2 = sa.scriptIds[2],
            scriptId3 = sa.scriptIds[3],
        }
    end

    ---@type table
    local payload = {
        setupHash = hash,
        classId = compact.classId,
        raceId = compact.raceId,
        frontAbilities = compact.frontAbilities,
        backAbilities = compact.backAbilities,
        werewolfAbilities = compact.werewolfAbilities,
        set = wireSets,
        lightCount = compact.armorWeights[1],
        mediumCount = compact.armorWeights[2],
        heavyCount = compact.armorWeights[3],
        frontMHWeaponType = compact.weaponTypes[1],
        frontOHWeaponType = compact.weaponTypes[2],
        backMHWeaponType = compact.weaponTypes[3],
        backOHWeaponType = compact.weaponTypes[4],
        armorTrait = wireArmorTraits,
        armorEnchant = wireArmorEnchants,
        jewelryTrait = wireJewelryTraits,
        jewelryEnchant = wireJewelryEnchants,
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
        classSkillLineIds = compact.classSkillLineIds,
        scribedAbility = wireScribedAbilities,
        frontPoisonEffect = compact.frontPoisonEffect,
        frontPoisonItemId = compact.frontPoisonItemId,
        backPoisonEffect = compact.backPoisonEffect,
        backPoisonItemId = compact.backPoisonItemId,
    }

    if IsUnitGrouped("player") then
        setupShare.responseProtocol:Send(payload)
        lastResponseTime[hash] = now
        -- log.Debug(function() return string.format("SetupShare: sent setup response for hash %d", hash) end)
    end
end

---Handles incoming setup response (protocol 433)
---@param unitTag string
---@param data table
local function onSetupResponse(unitTag, data)
    if AreUnitsEqual(unitTag, "player") then return end

    local displayName = BattleScrolls.utils.GetUndecoratedDisplayName(unitTag)
    if not displayName or displayName == "" then return end

    local hash = data.setupHash
    if not hash then return end

    -- Reconstruct CompactSetup from wire data
    ---@type CompactSetupSet[]
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

    ---@type CompactTraitEntry[]
    local armorTraits = {}
    if data.armorTrait then
        for _, t in ipairs(data.armorTrait) do
            armorTraits[#armorTraits + 1] = { traitType = t.traitType, count = t.count }
        end
    end

    ---@type CompactEnchantEntry[]
    local armorEnchants = {}
    if data.armorEnchant then
        for _, e in ipairs(data.armorEnchant) do
            armorEnchants[#armorEnchants + 1] = { enchantId = e.enchantId, count = e.count }
        end
    end

    ---@type CompactTraitEntry[]
    local jewelryTraits = {}
    if data.jewelryTrait then
        for _, t in ipairs(data.jewelryTrait) do
            jewelryTraits[#jewelryTraits + 1] = { traitType = t.traitType, count = t.count }
        end
    end

    ---@type CompactEnchantEntry[]
    local jewelryEnchants = {}
    if data.jewelryEnchant then
        for _, e in ipairs(data.jewelryEnchant) do
            jewelryEnchants[#jewelryEnchants + 1] = { enchantId = e.enchantId, count = e.count }
        end
    end

    -- Scribed abilities
    ---@type CompactScribedAbility[]
    local scribedAbilities = {}
    if data.scribedAbility then
        for _, sa in ipairs(data.scribedAbility) do
            scribedAbilities[#scribedAbilities + 1] = {
                abilityId = sa.abilityId,
                scriptIds = { sa.scriptId1, sa.scriptId2, sa.scriptId3 },
            }
        end
    end

    ---@type CompactSetup
    local compact = {
        classId = data.classId,
        raceId = data.raceId,
        frontAbilities = data.frontAbilities,
        backAbilities = data.backAbilities,
        werewolfAbilities = data.werewolfAbilities,
        sets = sets,
        armorWeights = { data.lightCount, data.mediumCount, data.heavyCount },
        weaponTypes = { data.frontMHWeaponType, data.frontOHWeaponType, data.backMHWeaponType, data.backOHWeaponType },
        armorTraits = armorTraits,
        armorEnchants = armorEnchants,
        jewelryTraits = jewelryTraits,
        jewelryEnchants = jewelryEnchants,
        weaponTraits = { data.frontMHTrait, data.frontOHTrait, data.backMHTrait, data.backOHTrait },
        weaponEnchants = { data.frontMHEnchant, data.frontOHEnchant, data.backMHEnchant, data.backOHEnchant },
        champion = data.champion or {},
        foodAbilityIds = data.foodAbilityIds or {},
        mundusAbilityIds = data.mundusAbilityIds or {},
        classSkillLineIds = data.classSkillLineIds or { 0, 0, 0 },
        scribedAbilities = scribedAbilities,
        frontPoisonEffect = data.frontPoisonEffect,
        frontPoisonItemId = data.frontPoisonItemId,
        backPoisonEffect = data.backPoisonEffect,
        backPoisonItemId = data.backPoisonItemId,
    }

    setupShare:storeSetup(displayName, hash, compact)
    -- log.Debug(function() return string.format("SetupShare: received and stored setup from %s hash %d", displayName, hash) end)
end

-- =============================================================================
-- PROTOCOL FIELD DECLARATIONS
-- =============================================================================

---Declares an optional ability bar array field (6 × 18-bit abilityId)
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

    -- Protocol 433: Setup Response (full CompactSetup)
    local responseProtocol = handler:DeclareProtocol(433, "BattleScrolls_SetupResponse")

    -- Header
    responseProtocol:AddField(LGB.CreateNumericField("setupHash", { minValue = 0, numBits = 16, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("classId", { minValue = 0, numBits = 4, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("raceId", { minValue = 0, numBits = 4, trimValues = true }))

    -- Abilities: optional bars (each needs a unique field name for LGB)
    responseProtocol:AddField(createAbilityBarField(LGB, "frontAbilities"))
    responseProtocol:AddField(createAbilityBarField(LGB, "backAbilities"))
    responseProtocol:AddField(createAbilityBarField(LGB, "werewolfAbilities"))

    -- Sets (grouped with per-bar counts)
    responseProtocol:AddField(LGB.CreateArrayField(
        LGB.CreateTableField("set", {
            LGB.CreateNumericField("setId", { minValue = 0, numBits = 10, trimValues = true }),
            LGB.CreateNumericField("frontCount", { minValue = 0, numBits = 3, trimValues = true }),
            LGB.CreateNumericField("backCount", { minValue = 0, numBits = 3, trimValues = true }),
        }),
        { maxLength = 6 }
    ))

    -- Armor weights
    responseProtocol:AddField(LGB.CreateNumericField("lightCount", { minValue = 0, numBits = 3, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("mediumCount", { minValue = 0, numBits = 3, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("heavyCount", { minValue = 0, numBits = 3, trimValues = true }))

    -- Weapon types (positional)
    responseProtocol:AddField(LGB.CreateNumericField("frontMHWeaponType", { minValue = 0, numBits = 5, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("frontOHWeaponType", { minValue = 0, numBits = 5, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("backMHWeaponType", { minValue = 0, numBits = 5, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("backOHWeaponType", { minValue = 0, numBits = 5, trimValues = true }))

    -- Armor traits: grouped {traitType, count}
    responseProtocol:AddField(LGB.CreateArrayField(
        LGB.CreateTableField("armorTrait", {
            LGB.CreateNumericField("traitType", { minValue = 0, numBits = 6, trimValues = true }),
            LGB.CreateNumericField("count", { minValue = 0, numBits = 3, trimValues = true }),
        }),
        { maxLength = 4 }
    ))
    -- Armor enchants: grouped {enchantId, count}
    responseProtocol:AddField(LGB.CreateArrayField(
        LGB.CreateTableField("armorEnchant", {
            LGB.CreateNumericField("enchantId", { minValue = 0, numBits = 9, trimValues = true }),
            LGB.CreateNumericField("count", { minValue = 0, numBits = 3, trimValues = true }),
        }),
        { maxLength = 4 }
    ))

    -- Jewelry traits
    responseProtocol:AddField(LGB.CreateArrayField(
        LGB.CreateTableField("jewelryTrait", {
            LGB.CreateNumericField("traitType", { minValue = 0, numBits = 6, trimValues = true }),
            LGB.CreateNumericField("count", { minValue = 0, numBits = 3, trimValues = true }),
        }),
        { maxLength = 3 }
    ))
    -- Jewelry enchants
    responseProtocol:AddField(LGB.CreateArrayField(
        LGB.CreateTableField("jewelryEnchant", {
            LGB.CreateNumericField("enchantId", { minValue = 0, numBits = 9, trimValues = true }),
            LGB.CreateNumericField("count", { minValue = 0, numBits = 3, trimValues = true }),
        }),
        { maxLength = 3 }
    ))

    -- Weapon traits (positional, 4 slots)
    responseProtocol:AddField(LGB.CreateNumericField("frontMHTrait", { minValue = 0, numBits = 6, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("frontOHTrait", { minValue = 0, numBits = 6, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("backMHTrait", { minValue = 0, numBits = 6, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("backOHTrait", { minValue = 0, numBits = 6, trimValues = true }))

    -- Weapon enchants (positional, 4 slots)
    responseProtocol:AddField(LGB.CreateNumericField("frontMHEnchant", { minValue = 0, numBits = 9, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("frontOHEnchant", { minValue = 0, numBits = 9, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("backMHEnchant", { minValue = 0, numBits = 9, trimValues = true }))
    responseProtocol:AddField(LGB.CreateNumericField("backOHEnchant", { minValue = 0, numBits = 9, trimValues = true }))

    -- Champion: fixed 12 slots
    responseProtocol:AddField(LGB.CreateArrayField(
        LGB.CreateNumericField("champion", { minValue = 0, numBits = 10, trimValues = true }),
        { maxLength = 12 }
    ))

    -- Food (up to 3 buff ability IDs) + Mundus
    responseProtocol:AddField(LGB.CreateArrayField(
        LGB.CreateNumericField("foodAbilityIds", { minValue = 0, numBits = 18, trimValues = true }),
        { maxLength = 3 }
    ))
    responseProtocol:AddField(LGB.CreateArrayField(
        LGB.CreateNumericField("mundusAbilityIds", { minValue = 0, numBits = 18, trimValues = true }),
        { maxLength = 2 }
    ))

    -- Class skill lines (3 IDs)
    responseProtocol:AddField(LGB.CreateArrayField(
        LGB.CreateNumericField("classSkillLineIds", { minValue = 0, numBits = 10, trimValues = true }),
        { maxLength = 3 }
    ))

    -- Scribed ability details (sparse: only scribed abilities)
    responseProtocol:AddField(LGB.CreateArrayField(
        LGB.CreateTableField("scribedAbility", {
            LGB.CreateNumericField("abilityId", { minValue = 0, numBits = 18, trimValues = true }),
            LGB.CreateNumericField("scriptId1", { minValue = 0, numBits = 8, trimValues = true }),
            LGB.CreateNumericField("scriptId2", { minValue = 0, numBits = 8, trimValues = true }),
            LGB.CreateNumericField("scriptId3", { minValue = 0, numBits = 8, trimValues = true }),
        }),
        { maxLength = 7 }
    ))

    -- Poisons (variant: crafted = PotionEffect 24-bit, unique = item ID 18-bit)
    responseProtocol:AddField(LGB.CreateOptionalField(
        LGB.CreateVariantField({
            LGB.CreateNumericField("frontPoisonEffect", { minValue = 0, numBits = 24, trimValues = true }),
            LGB.CreateNumericField("frontPoisonItemId", { minValue = 0, numBits = 18, trimValues = true }),
        })
    ))
    responseProtocol:AddField(LGB.CreateOptionalField(
        LGB.CreateVariantField({
            LGB.CreateNumericField("backPoisonEffect", { minValue = 0, numBits = 24, trimValues = true }),
            LGB.CreateNumericField("backPoisonItemId", { minValue = 0, numBits = 18, trimValues = true }),
        })
    ))

    responseProtocol:OnData(onSetupResponse)
    if not responseProtocol:Finalize({ isRelevantInCombat = false, replaceQueuedMessages = false }) then
        log.Warn("SetupShare: response protocol 433 failed to finalize")
        return
    end
    self.responseProtocol = responseProtocol
end
