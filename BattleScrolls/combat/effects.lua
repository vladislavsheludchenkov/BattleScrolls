if not SemisPlaygroundCheckAccess() then
    return
end

-- Effect tracking module for BattleScrolls
-- Self-sufficient module that handles buff/debuff tracking
-- Does NOT extend BattleScrolls.state - receives context as parameter

BattleScrolls = BattleScrolls or {}

---Tracks alive/dead state and alive time for a unit
---@class UnitAliveState
---@field aliveTimeMs number Total time unit was alive during combat
---@field lastAliveStartMs number|nil When unit became alive (nil if dead)
---@field isDead boolean Whether unit is currently dead

---@class EffectContext
---@field initialized boolean
---@field fightStartTimeMs number When combat started (for alive time calculations)
---@field effectsOnPlayer table<number, PlayerEffectStats>
---@field effectsOnBosses table<string, table<number, BossEffectStats>> Keyed by unitTag ("boss1", etc.)
---@field effectsOnGroup table<string, table<number, GroupEffectStats>> Keyed by displayName ("@player")
---@field activeEffects table<string, table<number, EffectInstance>> Nested: [storageKey][effectSlot] = instance
---@field lastDamageDoneMs number
---@field playerAliveState UnitAliveState|nil Tracks player alive/dead state
---@field unitAliveState table<string, UnitAliveState> Keyed by unitTag (bosses) or displayName (group)
---@field bossNames table<string, string> Maps unitTag to boss name (captured proactively)

---@class BattleScrollsEffects
local effects = {}

BattleScrolls.effects = effects

-- ============================================================================
-- Instance Recycling Pool
-- ============================================================================

---@type EffectInstance[]
local recyclingInstances = {}
local RECYCLING_POOL_LIMIT = 100

---Recycles an EffectInstance back to the pool
---@param instance EffectInstance
local function recycleInstance(instance)
    if #recyclingInstances < RECYCLING_POOL_LIMIT then
        table.insert(recyclingInstances, instance)
    end
end

---Gets a recycled instance or creates a new hstructure
---@return EffectInstance
local function getRecycledInstance()
    return table.remove(recyclingInstances) or BattleScrolls.structures.newEffectInstance(0, 0, 0, false, "", nil, nil)
end

-- ============================================================================
-- Pre-computed Constants (avoid string allocations in hot paths)
-- ============================================================================

-- Pattern strings for unit tag matching
---@type string
local PATTERN_BOSS = "^boss"
---@type string
local PATTERN_GROUP = "^group"

-- Local alias to constants (performance)
local BOSS_TAGS = BattleScrolls.constants.BOSS_TAGS

-- ============================================================================
-- Reconciliation Table Pooling (avoid allocations in periodic reconciliation)
-- ============================================================================

---@class BuffInfo
---@field abilityId number
---@field slot number
---@field beginTime number
---@field stackCount number
---@field effectType number
---@field appliedByPlayer boolean

-- Pooled tables for reconcileEffects - reused across calls
---@type table<number, BuffInfo>
local reconCurrentEffects = {}       -- Map effectSlot -> buffInfo
---@type table<number, boolean>
local reconTrackedKeys = {}          -- Set of tracked effectSlots
---@type BuffInfo[]
local reconBuffInfoPool = {}         -- Pool of reusable buff info tables
---@type number
local reconBuffInfoCount = 0         -- Current number of buff info tables in use

---Gets a buff info table from pool or creates new one
---@return BuffInfo
local function acquireBuffInfo()
    reconBuffInfoCount = reconBuffInfoCount + 1
    local info = reconBuffInfoPool[reconBuffInfoCount]
    if not info then
        info = {}
        reconBuffInfoPool[reconBuffInfoCount] = info
    end
    return info
end

---Clears all pooled reconciliation tables for reuse
local function clearReconTables()
    -- Clear the currentEffects map
    for k in pairs(reconCurrentEffects) do
        reconCurrentEffects[k] = nil
    end
    -- Clear the tracked keys set
    for k in pairs(reconTrackedKeys) do
        reconTrackedKeys[k] = nil
    end
    BattleScrolls.gc:RequestGC()
    -- Reset buff info counter (tables stay in pool for reuse)
    reconBuffInfoCount = 0
end

-- ============================================================================
-- Factory Functions
-- ============================================================================

---Creates a new EffectStats entry (uses hstructure)
---@param abilityId number
---@param effectType number
---@return EffectStats
function effects.newStats(abilityId, effectType)
    return BattleScrolls.structures.newEffectStats(abilityId, effectType)
end

---Creates a new EffectStatsWithAttribution entry (used for boss and group effects)
---Extends EffectStats with player attribution tracking (uses hstructure)
---@param abilityId number
---@param effectType number
---@return EffectStatsWithAttribution
function effects.newStatsWithAttribution(abilityId, effectType)
    return BattleScrolls.structures.newEffectStatsWithAttribution(abilityId, effectType)
end

---Creates a new EffectInstance for tracking active effects
---@param abilityId number
---@param effectType number
---@param stackCount number
---@param appliedByPlayer boolean
---@param unitTag string
---@param storageKey string|nil Key in storage table (unitTag for bosses, displayName for group, nil for player)
---@param beginTime number|nil ESO effect begin time (used to detect reapplications on UPDATED)
---@return EffectInstance
function effects.newInstance(abilityId, effectType, stackCount, appliedByPlayer, unitTag, storageKey, beginTime)
    local instance = getRecycledInstance()
    instance.abilityId = abilityId
    instance.effectType = effectType
    instance.startTimeMs = GetGameTimeMilliseconds()
    instance.stackCount = stackCount
    instance.maxStacksStartMs = nil  -- Will be set if stackCount > 1
    instance.currentMaxStacks = stackCount
    instance.appliedByPlayer = appliedByPlayer
    instance.unitTag = unitTag
    instance.storageKey = storageKey  -- Key for storage lookup (unitTag for bosses, displayName for group)
    instance.beginTime = beginTime  -- ESO's begin time, used to detect reapplications on UPDATED
    return instance
end

---Creates a new UnitAliveState for tracking unit alive time (uses hstructure)
---@param startAlive boolean Whether unit starts alive
---@param startTimeMs number|nil Start time (defaults to GetGameTimeMilliseconds())
---@return UnitAliveState
function effects.newUnitAliveState(startAlive, startTimeMs)
    return BattleScrolls.structures.newUnitAliveState(startAlive, startTimeMs)
end

-- ============================================================================
-- Helper Functions
-- ============================================================================

---Gets or creates the slot table for a storage key in activeEffects
---@param activeEffects table<string, table<number, EffectInstance>>
---@param storageKey string
---@return table<number, EffectInstance>
local function getOrCreateSlots(activeEffects, storageKey)
    local slots = activeEffects[storageKey]
    if not slots then
        slots = {}
        activeEffects[storageKey] = slots
    end
    return slots
end

---Gets displayName for a group unit tag
---@param unitTag string
---@return string displayName
local function getGroupDisplayName(unitTag)
    local displayName = BattleScrolls.utils.GetUndecoratedDisplayName(unitTag)
    if not displayName or displayName == "" then
        displayName = zo_strformat(SI_UNIT_NAME, GetRawUnitName(unitTag))
    end
    return displayName
end

---Gets the storage key for a unit and captures boss name if needed
---@param ctx EffectContext
---@param unitTag string
---@return string storageKey
---@return boolean isBoss
local function getUnitStorageKey(ctx, unitTag)
    if unitTag:find(PATTERN_BOSS) then
        if not ctx.bossNames[unitTag] and DoesUnitExist(unitTag) then
            ctx.bossNames[unitTag] = GetRawUnitName(unitTag)
        end
        return unitTag, true
    else
        return getGroupDisplayName(unitTag), false
    end
end

---Updates EffectStats when an effect duration ends
---@param stats EffectStats
---@param instance EffectInstance
---@param endTimeMs number
local function finalizeStats(stats, instance, endTimeMs)
    local duration = endTimeMs - instance.startTimeMs
    stats.totalActiveTimeMs = stats.totalActiveTimeMs + duration

    -- Finalize max stacks time if we were at max stacks
    if instance.maxStacksStartMs and instance.currentMaxStacks > 1 and instance.currentMaxStacks >= stats.maxStacks then
        local maxStacksDuration = endTimeMs - instance.maxStacksStartMs
        stats.timeAtMaxStacksMs = stats.timeAtMaxStacksMs + maxStacksDuration
    end
end

---Updates stats with player attribution when an effect duration ends (used for all effect types)
---@param stats BossEffectStats|GroupEffectStats|PlayerEffectStats
---@param instance EffectInstance
---@param endTimeMs number
local function finalizeStatsWithAttribution(stats, instance, endTimeMs)
    -- First update total stats
    finalizeStats(stats, instance, endTimeMs)

    -- Then update player-specific stats if this was applied by player
    if instance.appliedByPlayer then
        local duration = endTimeMs - instance.startTimeMs
        stats.playerActiveTimeMs = stats.playerActiveTimeMs + duration

        if instance.maxStacksStartMs and instance.currentMaxStacks > 1 and instance.currentMaxStacks >= stats.maxStacks then
            local maxStacksDuration = endTimeMs - instance.maxStacksStartMs
            stats.playerTimeAtMaxStacksMs = stats.playerTimeAtMaxStacksMs + maxStacksDuration
        end
    end
end

---Counts current active instances of an ability for a storage key
---@param ctx EffectContext
---@param storageKey string "player" for player effects, unitTag for bosses, displayName for group
---@param abilityId number
---@return number count Number of active instances
local function countActiveInstances(ctx, storageKey, abilityId)
    local slots = ctx.activeEffects[storageKey]
    if not slots then return 0 end

    local count = 0
    for _, instance in pairs(slots) do
        if instance.abilityId == abilityId then
            count = count + 1
        end
    end
    return count
end

---Updates peak concurrent instances if current count is higher
---Call AFTER adding the new instance to activeEffects
---When about to increase peak above 1, triggers a full reconciliation first to catch out-of-order events
---@param ctx EffectContext
---@param stats EffectStatsWithAttribution
---@param storageKey string
---@param abilityId number
---@param unitTag string Unit tag for reconciliation (e.g., "player", "boss1", "group3")
---@param skipReconcile boolean|nil If true, skip reconciliation (used when called from reconcileEffects)
local function updatePeakConcurrentInstances(ctx, stats, storageKey, abilityId, unitTag, skipReconcile)
    local currentCount = countActiveInstances(ctx, storageKey, abilityId)

    -- About to record peak > 1? Reconcile first to catch out-of-order events
    if not skipReconcile and currentCount > stats.peakConcurrentInstances and currentCount > 1 then
        effects.handleUnitFullRefresh(ctx, unitTag)
        currentCount = countActiveInstances(ctx, storageKey, abilityId)
    end

    if currentCount > stats.peakConcurrentInstances then
        stats.peakConcurrentInstances = currentCount
    end
end

---Updates stats on GAINED: increments applications and updates maxStacks
---@param stats BossEffectStats|GroupEffectStats|PlayerEffectStats
---@param stackCount number
---@param appliedByPlayer boolean
local function updateStatsOnGained(stats, stackCount, appliedByPlayer)
    stats.applications = stats.applications + 1
    if stackCount > stats.maxStacks then
        stats.maxStacks = stackCount
        stats.timeAtMaxStacksMs = 0
    end
    if appliedByPlayer then
        stats.playerApplications = stats.playerApplications + 1
    end
end

---Handles reapplication detection and max stacks updates on UPDATED
---@param stats BossEffectStats|GroupEffectStats|PlayerEffectStats
---@param instance EffectInstance
---@param stackCount number
---@param appliedByPlayer boolean
---@param beginTime number
---@param nowMs number
local function updateStatsOnUpdated(stats, instance, stackCount, appliedByPlayer, beginTime, nowMs)
    -- Check if this is a reapplication (beginTime changed)
    if instance.beginTime < beginTime then
        stats.applications = stats.applications + 1
        if appliedByPlayer then
            stats.playerApplications = stats.playerApplications + 1
        end
        instance.beginTime = beginTime
    end

    -- Update max stacks tracking
    if stackCount > instance.currentMaxStacks then
        -- Reached new max stacks
        instance.currentMaxStacks = stackCount
        if stackCount > stats.maxStacks then
            stats.maxStacks = stackCount
            stats.timeAtMaxStacksMs = 0
        end
        instance.maxStacksStartMs = nowMs
    elseif stackCount < instance.currentMaxStacks and instance.maxStacksStartMs then
        -- Dropped below max stacks, finalize max stacks time
        local maxStacksDuration = nowMs - instance.maxStacksStartMs
        if instance.currentMaxStacks >= stats.maxStacks then
            stats.timeAtMaxStacksMs = stats.timeAtMaxStacksMs + maxStacksDuration
            if instance.appliedByPlayer then
                stats.playerTimeAtMaxStacksMs = stats.playerTimeAtMaxStacksMs + maxStacksDuration
            end
        end
        instance.maxStacksStartMs = nil
    elseif stackCount == instance.currentMaxStacks and not instance.maxStacksStartMs then
        -- Returned to max stacks, resume tracking
        instance.maxStacksStartMs = nowMs
    end

    instance.stackCount = stackCount
end

---Ensures a unit has alive state initialized, starting as alive from fightStartTimeMs
---@param ctx EffectContext
---@param key string unitTag for bosses, displayName for group members
---@param startAlive boolean|nil Whether to start alive (default true)
local function ensureUnitAliveState(ctx, key, startAlive)
    if not ctx.unitAliveState[key] then
        -- Use fightStartTimeMs so alive time counts from combat start, not first event
        ctx.unitAliveState[key] = effects.newUnitAliveState(startAlive ~= false, ctx.fightStartTimeMs)
    end
end

---Finalizes alive time for a unit (call when unit dies or combat ends)
---@param aliveState UnitAliveState
---@param endTimeMs number
local function finalizeUnitAliveTime(aliveState, endTimeMs)
    if aliveState.lastAliveStartMs then
        aliveState.aliveTimeMs = aliveState.aliveTimeMs + (endTimeMs - aliveState.lastAliveStartMs)
        aliveState.lastAliveStartMs = nil
    end
end

---Finalizes all active effects for a specific unit (used when unit dies)
---@param ctx EffectContext
---@param storageKey string The key in storage (unitTag for bosses, displayName for group)
---@param storage table<string, table<number, EffectStatsWithAttribution|BossEffectStats|GroupEffectStats>> The storage table (effectsOnBosses or effectsOnGroup)
---@param endTimeMs number
local function finalizeEffectsForUnit(ctx, storageKey, storage, endTimeMs)
    local slots = ctx.activeEffects[storageKey]
    if not slots then return end

    for effectSlot, instance in pairs(slots) do
        if storage[storageKey] and storage[storageKey][instance.abilityId] then
            finalizeStatsWithAttribution(storage[storageKey][instance.abilityId], instance, endTimeMs)
        end
        recycleInstance(instance)
        slots[effectSlot] = nil
    end
end

---Backfills effects for a unit tag (used when unit becomes alive or combat starts)
---@param ctx EffectContext
---@param unitTag string
---@param storage table<number, EffectStatsWithAttribution|BossEffectStats|GroupEffectStats|PlayerEffectStats> Storage table for stats (effectsOnPlayer or storage[storageKey])
---@param effectTypeFilter number|nil Filter by effect type (nil = track all)
---@param storageKey string|nil Storage key for instance (unitTag for bosses, displayName for group, nil for player)
local function backfillEffectsForUnitTag(ctx, unitTag, storage, effectTypeFilter, storageKey)
    local nowMs = GetGameTimeMilliseconds()

    for i = 1, GetNumBuffs(unitTag) do
        local _, beginTime, _, buffSlot, stackCount, _,
              _, effectType, _, _,
              abilityId, _, castByPlayer = GetUnitBuffInfo(unitTag, i)

        if abilityId and abilityId > 0 and (not effectTypeFilter or effectType == effectTypeFilter) then
            -- Initialize stats if first time seeing this effect
            if not storage[abilityId] then
                storage[abilityId] = effects.newStatsWithAttribution(abilityId, effectType)
            end

            local stats = storage[abilityId]
            stats.applications = stats.applications + 1
            if (stackCount or 0) > stats.maxStacks then
                stats.maxStacks = stackCount or 0
            end
            if castByPlayer then
                stats.playerApplications = stats.playerApplications + 1
            end

            -- Track as active (use beginTime from GetUnitBuffInfo for reapplication detection)
            -- Use storageKey for the active effect key to ensure stability across unitTag changes
            local instance = effects.newInstance(abilityId, effectType, stackCount or 0, castByPlayer, unitTag, storageKey, beginTime)
            if (stackCount or 0) > 1 then
                instance.maxStacksStartMs = nowMs
            end
            getOrCreateSlots(ctx.activeEffects, storageKey or "player")[buffSlot] = instance

            -- Update peak concurrent instances (after adding to activeEffects)
            -- skipReconcile=true because backfill reads current game state, so data is fresh
            updatePeakConcurrentInstances(ctx, stats, storageKey or "player", abilityId, unitTag, true)
        end
    end
end

---Handles GAINED/FADED/UPDATED for unit effects (boss or group)
---@param ctx EffectContext
---@param storage table<string, table<number, EffectStatsWithAttribution|BossEffectStats|GroupEffectStats>> The storage table (effectsOnBosses or effectsOnGroup)
---@param storageKey string Key in storage (unitTag for bosses, displayName for group)
---@param effectSlot number The effect slot number
---@param unitTag string
---@param changeType number
---@param abilityId number
---@param effectType number
---@param stackCount number
---@param appliedByPlayer boolean
---@param beginTime number
local function handleUnitEffectChange(ctx, storage, storageKey, effectSlot, unitTag, changeType, abilityId, effectType, stackCount, appliedByPlayer, beginTime)
    local slots = ctx.activeEffects[storageKey]

    if changeType == EFFECT_RESULT_GAINED then
        -- Ensure nested table exists
        if not storage[storageKey] then
            storage[storageKey] = {}
        end

        -- Initialize stats if first time seeing this effect
        if not storage[storageKey][abilityId] then
            storage[storageKey][abilityId] = effects.newStatsWithAttribution(abilityId, effectType)
        end

        -- Finalize old instance if exists (rapid reapplication case)
        local existingInstance = slots and slots[effectSlot]

        if existingInstance and existingInstance.beginTime >= beginTime then
            -- Ignore duplicate GAINED with same or older beginTime
            return
        end

        updateStatsOnGained(storage[storageKey][abilityId], stackCount, appliedByPlayer)

        if existingInstance then
            local existingKey = existingInstance.storageKey or storageKey
            if storage[existingKey] and storage[existingKey][existingInstance.abilityId] then
                finalizeStatsWithAttribution(storage[existingKey][existingInstance.abilityId], existingInstance, GetGameTimeMilliseconds())
            end
            recycleInstance(existingInstance)
        end

        -- Track active instance
        local instance = effects.newInstance(abilityId, effectType, stackCount, appliedByPlayer, unitTag, storageKey, beginTime)
        if stackCount > 1 then
            instance.maxStacksStartMs = instance.startTimeMs
        end
        getOrCreateSlots(ctx.activeEffects, storageKey)[effectSlot] = instance

        -- Update peak concurrent instances (after adding to activeEffects)
        updatePeakConcurrentInstances(ctx, storage[storageKey][abilityId], storageKey, abilityId, unitTag)

    elseif changeType == EFFECT_RESULT_FADED then
        local instance = slots and slots[effectSlot]
        if instance then
            local instanceKey = instance.storageKey or storageKey
            if storage[instanceKey] and storage[instanceKey][instance.abilityId] then
                finalizeStatsWithAttribution(storage[instanceKey][instance.abilityId], instance, GetGameTimeMilliseconds())
            end
            recycleInstance(instance)
        end
        if slots then slots[effectSlot] = nil end

    elseif changeType == EFFECT_RESULT_UPDATED then
        local instance = slots and slots[effectSlot]
        if instance then
            local instanceKey = instance.storageKey or storageKey
            if storage[instanceKey] and storage[instanceKey][instance.abilityId] then
                updateStatsOnUpdated(storage[instanceKey][instance.abilityId], instance, stackCount, appliedByPlayer, beginTime, GetGameTimeMilliseconds())
            end
        end
    end
end

-- ============================================================================
-- Settings Check
-- ============================================================================

---Check if effect tracking is enabled in settings (master switch)
---@return boolean
function effects.isEnabled()
    local settings = BattleScrolls.storage and BattleScrolls.storage.savedVariables and BattleScrolls.storage.savedVariables.settings
    return not (settings and settings.effectTrackingEnabled == false)
end

---Check if player buff tracking is enabled
---@return boolean
local function isPlayerBuffsEnabled()
    local settings = BattleScrolls.storage and BattleScrolls.storage.savedVariables and BattleScrolls.storage.savedVariables.settings
    return not (settings and settings.trackPlayerBuffs == false)
end

---Check if player debuff tracking is enabled
---@return boolean
local function isPlayerDebuffsEnabled()
    local settings = BattleScrolls.storage and BattleScrolls.storage.savedVariables and BattleScrolls.storage.savedVariables.settings
    return not (settings and settings.trackPlayerDebuffs == false)
end

---Check if group buff tracking is enabled
---@return boolean
local function isGroupBuffsEnabled()
    local settings = BattleScrolls.storage and BattleScrolls.storage.savedVariables and BattleScrolls.storage.savedVariables.settings
    return not (settings and settings.trackGroupBuffs == false)
end

---Check if boss debuff tracking is enabled
---@return boolean
local function isBossDebuffsEnabled()
    local settings = BattleScrolls.storage and BattleScrolls.storage.savedVariables and BattleScrolls.storage.savedVariables.settings
    return not (settings and settings.trackBossDebuffs == false)
end

---Check if a player effect should be tracked based on its type
---@param effectType number BUFF_EFFECT_TYPE_BUFF or BUFF_EFFECT_TYPE_DEBUFF
---@return boolean
local function shouldTrackPlayerEffect(effectType)
    if effectType == BUFF_EFFECT_TYPE_BUFF then
        return isPlayerBuffsEnabled()
    elseif effectType == BUFF_EFFECT_TYPE_DEBUFF then
        return isPlayerDebuffsEnabled()
    end
    return true -- Track unknown types by default
end

-- ============================================================================
-- Effect Handlers
-- ============================================================================

---Handles effect changes on the player
---@param ctx EffectContext
---@param changeType number EFFECT_RESULT_GAINED, EFFECT_RESULT_FADED, or EFFECT_RESULT_UPDATED
---@param effectSlot number
---@param effectType number
---@param stackCount number
---@param abilityId number
---@param sourceType number
---@param beginTime number ESO effect begin time
function effects.handlePlayerEffect(ctx, changeType, effectSlot, effectType, stackCount, abilityId, sourceType, beginTime)
    if not ctx.initialized then return end
    if not effects.isEnabled() then return end
    if not shouldTrackPlayerEffect(effectType) then return end

    -- Initialize player alive state if we haven't yet
    if not ctx.playerAliveState then
        local isDead = IsUnitDead("player")
        ctx.playerAliveState = effects.newUnitAliveState(not isDead, ctx.fightStartTimeMs)
    end

    -- If player is dead, ignore ALL effect events (effects were finalized on death)
    if ctx.playerAliveState and ctx.playerAliveState.isDead then
        return
    end

    local appliedByPlayer = (sourceType == COMBAT_UNIT_TYPE_PLAYER)
    local playerSlots = ctx.activeEffects["player"]

    if changeType == EFFECT_RESULT_GAINED then
        -- Initialize stats if first time seeing this effect
        if not ctx.effectsOnPlayer[abilityId] then
            ctx.effectsOnPlayer[abilityId] = effects.newStatsWithAttribution(abilityId, effectType)
        end

        local stats = ctx.effectsOnPlayer[abilityId]
        updateStatsOnGained(stats, stackCount, appliedByPlayer)

        -- Finalize old instance if exists (rapid reapplication case)
        local existingInstance = playerSlots and playerSlots[effectSlot]
        if existingInstance then
            if ctx.effectsOnPlayer[existingInstance.abilityId] then
                finalizeStatsWithAttribution(ctx.effectsOnPlayer[existingInstance.abilityId], existingInstance, GetGameTimeMilliseconds())
            end
            recycleInstance(existingInstance)
        end

        -- Track active instance (nil storageKey for player - not nested)
        local instance = effects.newInstance(abilityId, effectType, stackCount, appliedByPlayer, "player", nil, beginTime)
        if stackCount > 1 then
            instance.maxStacksStartMs = instance.startTimeMs
        end
        getOrCreateSlots(ctx.activeEffects, "player")[effectSlot] = instance

        -- Update peak concurrent instances (after adding to activeEffects)
        updatePeakConcurrentInstances(ctx, stats, "player", abilityId, "player")

    elseif changeType == EFFECT_RESULT_FADED then
        local instance = playerSlots and playerSlots[effectSlot]
        if instance then
            if ctx.effectsOnPlayer[instance.abilityId] then
                finalizeStatsWithAttribution(ctx.effectsOnPlayer[instance.abilityId], instance, GetGameTimeMilliseconds())
            end
            recycleInstance(instance)
        end
        -- If no instance found, we missed the GAINED event - periodic reconciliation will catch sync issues
        if playerSlots then playerSlots[effectSlot] = nil end

    elseif changeType == EFFECT_RESULT_UPDATED then
        local instance = playerSlots and playerSlots[effectSlot]
        if instance and ctx.effectsOnPlayer[instance.abilityId] then
            updateStatsOnUpdated(ctx.effectsOnPlayer[instance.abilityId], instance, stackCount, appliedByPlayer, beginTime, GetGameTimeMilliseconds())
        end
    else
        -- Unexpected change type (e.g., EFFECT_RESULT_FULL_REFRESH) → do a full refresh
        -- BattleScrolls.log.Info(function()
        --     return string.format("[REFRESH] Player unexpected changeType=%d, triggering full refresh", changeType)
        -- end)
        effects.handlePlayerFullRefresh(ctx)
    end
end

---Handles effect changes on bosses
---@param ctx EffectContext
---@param changeType number EFFECT_RESULT_GAINED, EFFECT_RESULT_FADED, or EFFECT_RESULT_UPDATED
---@param effectSlot number
---@param unitTag string
---@param effectType number
---@param stackCount number
---@param abilityId number
---@param _unitId number (unused - we store by unitTag instead)
---@param sourceType number
---@param beginTime number ESO effect begin time
function effects.handleBossEffect(ctx, changeType, effectSlot, unitTag, effectType, stackCount, abilityId, _unitId, sourceType, beginTime)
    if not ctx.initialized then return end
    if not effects.isEnabled() then return end
    if not isBossDebuffsEnabled() then return end

    -- Capture boss name and initialize alive state
    if not ctx.bossNames[unitTag] then
        ctx.bossNames[unitTag] = GetRawUnitName(unitTag)
    end
    if not ctx.unitAliveState[unitTag] then
        ensureUnitAliveState(ctx, unitTag, not IsUnitDead(unitTag))
    end

    -- If unit is dead, ignore ALL effect events (effects were finalized on death)
    if ctx.unitAliveState[unitTag] and ctx.unitAliveState[unitTag].isDead then
        return
    end

    -- Only track debuffs on bosses
    if effectType ~= BUFF_EFFECT_TYPE_DEBUFF and changeType ~= EFFECT_RESULT_FADED then return end

    -- Handle unexpected change types with full refresh
    if changeType ~= EFFECT_RESULT_GAINED and changeType ~= EFFECT_RESULT_FADED and changeType ~= EFFECT_RESULT_UPDATED then
        -- BattleScrolls.log.Info(function()
        --     return string.format("[REFRESH] Boss %s unexpected changeType=%d, triggering full refresh", unitTag, changeType)
        -- end)
        effects.handleBossFullRefresh(ctx, unitTag)
        return
    end

    local appliedByPlayer = (sourceType == COMBAT_UNIT_TYPE_PLAYER)

    -- Store by unitTag (e.g., "boss1")
    -- If FADED without tracked instance, periodic reconciliation will catch sync issues
    handleUnitEffectChange(ctx, ctx.effectsOnBosses, unitTag, effectSlot, unitTag, changeType, abilityId, effectType, stackCount, appliedByPlayer, beginTime)
end

---Handles effect changes on group members (only tracks effects cast by player)
---@param ctx EffectContext
---@param changeType number EFFECT_RESULT_GAINED, EFFECT_RESULT_FADED, or EFFECT_RESULT_UPDATED
---@param effectSlot number
---@param unitTag string
---@param effectType number
---@param stackCount number
---@param abilityId number
---@param _unitId number (unused - we store by displayName instead)
---@param sourceType number
---@param beginTime number
---@param _endTime number (unused)
function effects.handleGroupEffect(ctx, changeType, effectSlot, unitTag, effectType, stackCount, abilityId, _unitId, sourceType, beginTime, _endTime)
    if not ctx.initialized then return end
    if AreUnitsEqual("player", unitTag) then return end
    if IsGroupCompanionUnitTag(unitTag) then return end
    if not effects.isEnabled() then return end
    if not isGroupBuffsEnabled() then return end

    local displayName = getGroupDisplayName(unitTag)

    -- Initialize alive state if we haven't seen this member yet
    if not ctx.unitAliveState[displayName] then
        ensureUnitAliveState(ctx, displayName, not IsUnitDead(unitTag))
    end

    -- If unit is dead, ignore ALL effect events (effects were finalized on death)
    if ctx.unitAliveState[displayName] and ctx.unitAliveState[displayName].isDead then
        return
    end

    -- Only track buffs on group members (we provide buffs, not debuffs)
    if effectType ~= BUFF_EFFECT_TYPE_BUFF and changeType ~= EFFECT_RESULT_FADED then return end

    -- Handle unexpected change types with full refresh
    if changeType ~= EFFECT_RESULT_GAINED and changeType ~= EFFECT_RESULT_FADED and changeType ~= EFFECT_RESULT_UPDATED then
        -- BattleScrolls.log.Info(function()
        --     return string.format("[REFRESH] Group %s unexpected changeType=%d, triggering full refresh", displayName, changeType)
        -- end)
        effects.handleGroupFullRefresh(ctx, unitTag)
        return
    end

    -- Use displayName as storageKey to ensure stability across unitTag changes
    local appliedByPlayer = (sourceType == COMBAT_UNIT_TYPE_PLAYER)

    -- Store by displayName (e.g., "@PlayerName")
    -- If FADED without tracked instance, periodic reconciliation will catch sync issues
    handleUnitEffectChange(ctx, ctx.effectsOnGroup, displayName, effectSlot, unitTag, changeType, abilityId, effectType, stackCount, appliedByPlayer, beginTime)
end

-- ============================================================================
-- Unit Death State Handlers
-- ============================================================================

---Handles a unit dying - finalizes all effects on that unit and stops alive tracking
---@param ctx EffectContext
---@param unitTag string
function effects.handleUnitDeath(ctx, unitTag)
    if not ctx.initialized then return end
    if not effects.isEnabled() then return end

    local storageKey, isBoss = getUnitStorageKey(ctx, unitTag)
    local nowMs = GetGameTimeMilliseconds()

    -- Finalize alive time for this unit
    if ctx.unitAliveState[storageKey] then
        finalizeUnitAliveTime(ctx.unitAliveState[storageKey], nowMs)
        ctx.unitAliveState[storageKey].isDead = true
    end

    -- Finalize all active effects for this unit
    local storage = isBoss and ctx.effectsOnBosses or ctx.effectsOnGroup
    finalizeEffectsForUnit(ctx, storageKey, storage, nowMs)

    -- BattleScrolls.log.Debug(function()
    --     local aliveMs = ctx.unitAliveState[storageKey] and ctx.unitAliveState[storageKey].aliveTimeMs or 0
    --     return string.format("[DEATH] %s died: key=%s tag=%s aliveTimeMs=%d",
    --         isBoss and "Boss" or "Group member", storageKey, unitTag, aliveMs)
    -- end)
end

---Handles a unit becoming alive - resumes alive time tracking and backfills effects
---Only resets alive time tracking if unit was actually dead (not just changing unitTag positions)
---@param ctx EffectContext
---@param unitTag string
function effects.handleUnitAlive(ctx, unitTag)
    if not ctx.initialized then return end
    if not effects.isEnabled() then return end

    local storageKey, isBoss = getUnitStorageKey(ctx, unitTag)

    -- Check granular setting
    if isBoss and not isBossDebuffsEnabled() then return end
    if not isBoss and not isGroupBuffsEnabled() then return end

    -- Check if this unit was actually dead (vs just changing unitTag position)
    local wasActuallyDead = ctx.unitAliveState[storageKey] and ctx.unitAliveState[storageKey].isDead

    -- Resume alive time tracking (or initialize if new)
    if ctx.unitAliveState[storageKey] then
        -- Only reset lastAliveStartMs if unit was actually dead (resurrection)
        -- If unit wasn't dead, this is just a unitTag change - don't reset alive tracking
        if wasActuallyDead then
            ctx.unitAliveState[storageKey].isDead = false
            ctx.unitAliveState[storageKey].lastAliveStartMs = GetGameTimeMilliseconds()
        end
        -- else: unit wasn't dead, keep existing alive tracking
    else
        ensureUnitAliveState(ctx, storageKey, true)
    end

    -- Backfill effects that are currently active on this unit
    -- With stable storageKey-based activeEffect keys, this will update existing entries
    -- rather than creating duplicates
    local storage = isBoss and ctx.effectsOnBosses or ctx.effectsOnGroup
    local effectTypeFilter = isBoss and BUFF_EFFECT_TYPE_DEBUFF or BUFF_EFFECT_TYPE_BUFF

    if not storage[storageKey] then
        storage[storageKey] = {}
    end

    backfillEffectsForUnitTag(ctx, unitTag, storage[storageKey], effectTypeFilter, storageKey)

    -- BattleScrolls.log.Debug(function()
    --     return string.format("[ALIVE] Unit alive: key=%s tag=%s wasActuallyDead=%s (backfilled effects)",
    --         storageKey, unitTag, tostring(wasActuallyDead))
    -- end)
end

---Handles player death - finalizes all effects on player and stops alive tracking
---@param ctx EffectContext
function effects.handlePlayerDeath(ctx)
    if not ctx.initialized then return end
    if not effects.isEnabled() then return end

    local nowMs = GetGameTimeMilliseconds()

    -- Finalize alive time for player
    if ctx.playerAliveState then
        finalizeUnitAliveTime(ctx.playerAliveState, nowMs)
        ctx.playerAliveState.isDead = true
    end

    -- Finalize all active player effects
    local playerSlots = ctx.activeEffects["player"]
    if playerSlots then
        for effectSlot, instance in pairs(playerSlots) do
            if ctx.effectsOnPlayer[instance.abilityId] then
                finalizeStatsWithAttribution(ctx.effectsOnPlayer[instance.abilityId], instance, nowMs)
            end
            recycleInstance(instance)
            playerSlots[effectSlot] = nil
        end
    end

    -- BattleScrolls.log.Debug(function()
    --     local aliveMs = ctx.playerAliveState and ctx.playerAliveState.aliveTimeMs or 0
    --     return string.format("[DEATH] Player died: aliveTimeMs=%d", aliveMs)
    -- end)
end

---Handles player becoming alive - resumes alive time tracking and backfills effects
---@param ctx EffectContext
function effects.handlePlayerAlive(ctx)
    if not ctx.initialized then return end
    if not effects.isEnabled() then return end

    -- Resume alive time tracking
    if ctx.playerAliveState then
        ctx.playerAliveState.isDead = false
        ctx.playerAliveState.lastAliveStartMs = GetGameTimeMilliseconds()
    end

    -- Backfill player effects based on granular settings
    local playerBuffsEnabled = isPlayerBuffsEnabled()
    local playerDebuffsEnabled = isPlayerDebuffsEnabled()

    if playerBuffsEnabled and playerDebuffsEnabled then
        -- Both enabled - track all
        backfillEffectsForUnitTag(ctx, "player", ctx.effectsOnPlayer, nil, nil)
    elseif playerBuffsEnabled then
        -- Only buffs enabled
        backfillEffectsForUnitTag(ctx, "player", ctx.effectsOnPlayer, BUFF_EFFECT_TYPE_BUFF, nil)
    elseif playerDebuffsEnabled then
        -- Only debuffs enabled
        backfillEffectsForUnitTag(ctx, "player", ctx.effectsOnPlayer, BUFF_EFFECT_TYPE_DEBUFF, nil)
    end
    -- If neither enabled, skip backfill entirely

    -- BattleScrolls.log.Debug(function()
    --     return "[ALIVE] Player alive (backfilled effects)"
    -- end)
end

---Gets the player's alive time
---@param ctx EffectContext|BattleScrollsState
---@param fightDurationMs number Fallback if not tracked
---@return number aliveTimeMs
function effects.getPlayerAliveTime(ctx, fightDurationMs)
    if not ctx.playerAliveState then
        return fightDurationMs
    end
    return ctx.playerAliveState.aliveTimeMs
end

---Gets the total alive time for a unit in milliseconds
---Returns fight duration if unit was never tracked (e.g., player)
---@param ctx EffectContext
---@param unitId number
---@param fightDurationMs number Fallback if unit not tracked
---@return number aliveTimeMs
function effects.getUnitAliveTime(ctx, unitId, fightDurationMs)
    local aliveState = ctx.unitAliveState[unitId]
    if not aliveState then
        return fightDurationMs
    end
    return aliveState.aliveTimeMs
end

---Gets the final alive times for all tracked units (for export to encounter)
---@param ctx EffectContext|BattleScrollsState
---@return table<string, number> storageKey -> aliveTimeMs (unitTag for bosses, displayName for group)
function effects.getUnitAliveTimes(ctx)
    local result = {}
    for unitId, aliveState in pairs(ctx.unitAliveState) do
        result[unitId] = aliveState.aliveTimeMs
    end
    return result
end

-- ============================================================================
-- Full Effect Refresh
-- ============================================================================

---Reconciles player alive state before effect reconciliation
---@param ctx EffectContext
---@return boolean shouldContinue Whether to continue with effect reconciliation (false if dead)
local function reconcilePlayerAliveState(ctx)
    local isActuallyDead = IsUnitDead("player")

    if not ctx.playerAliveState then
        ctx.playerAliveState = effects.newUnitAliveState(not isActuallyDead, ctx.fightStartTimeMs)
        return not isActuallyDead
    end

    if isActuallyDead ~= ctx.playerAliveState.isDead then
        -- BattleScrolls.log.Debug(function()
        --     return string.format("[RECONCILE] Player alive state mismatch: tracked=%s actual=%s",
        --         ctx.playerAliveState.isDead and "dead" or "alive",
        --         isActuallyDead and "dead" or "alive")
        -- end)

        if isActuallyDead then
            effects.handlePlayerDeath(ctx)
        else
            effects.handlePlayerAlive(ctx)
        end
        return not isActuallyDead
    end

    return not isActuallyDead
end

---Reconciles unit alive state before effect reconciliation (for bosses and group members)
---@param ctx EffectContext
---@param storageKey string The storage key (unitTag for bosses, displayName for group)
---@param unitTag string The unit tag to check
---@return boolean shouldContinue Whether to continue with effect reconciliation (false if dead)
local function reconcileUnitAliveState(ctx, storageKey, unitTag)
    local isActuallyDead = IsUnitDead(unitTag)
    local aliveState = ctx.unitAliveState[storageKey]

    if not aliveState then
        -- No tracking yet - initialize
        ensureUnitAliveState(ctx, storageKey, not isActuallyDead)
        return not isActuallyDead
    end

    if isActuallyDead ~= aliveState.isDead then
        -- BattleScrolls.log.Debug(function()
        --     return string.format("[RECONCILE] Unit %s alive state mismatch: tracked=%s actual=%s",
        --         storageKey,
        --         aliveState.isDead and "dead" or "alive",
        --         isActuallyDead and "dead" or "alive")
        -- end)

        if isActuallyDead then
            effects.handleUnitDeath(ctx, unitTag)
        else
            effects.handleUnitAlive(ctx, unitTag)
        end
        return not isActuallyDead
    end

    return not isActuallyDead
end

---Core reconciliation logic for full effect refresh
---Compares current game state with tracked effects and reconciles differences
---Uses slot-based keys to correctly handle multiple instances of the same ability
---(e.g., two players applying Relequen to the same boss get different slots)
---@param ctx EffectContext
---@param unitTag string The unit tag to read effects from
---@param storage table<number, EffectStatsWithAttribution|BossEffectStats|GroupEffectStats|PlayerEffectStats> The storage table for stats (effectsOnPlayer or effectsOnBosses[key] or effectsOnGroup[key])
---@param storageKey string|nil The storage key for new instances (nil for player)
---@param effectTypeFilter number|nil Filter by effect type (nil = all)
local function reconcileEffects(ctx, unitTag, storage, storageKey, effectTypeFilter)
    local nowMs = GetGameTimeMilliseconds()
    local effectiveStorageKey = storageKey or "player"

    -- Clear pooled tables from previous call
    clearReconTables()

    -- Build map of current effects from game state, keyed by buffSlot
    -- This correctly handles multiple instances of the same ability in different slots
    -- Uses pooled tables to avoid allocations
    for i = 1, GetNumBuffs(unitTag) do
        local _, beginTime, _, buffSlot, stackCount, _,
              _, effectType, _, _,
              abilityId, _, castByPlayer = GetUnitBuffInfo(unitTag, i)

        if abilityId and abilityId > 0 and (not effectTypeFilter or effectType == effectTypeFilter) then
            local info = acquireBuffInfo()
            info.abilityId = abilityId
            info.slot = buffSlot
            info.beginTime = beginTime
            info.stackCount = stackCount or 0
            info.effectType = effectType
            info.appliedByPlayer = castByPlayer
            reconCurrentEffects[buffSlot] = info
        end
    end

    -- Build set of tracked effectSlots for this storage key
    local slots = ctx.activeEffects[effectiveStorageKey]
    if slots then
        for effectSlot in pairs(slots) do
            reconTrackedKeys[effectSlot] = true
        end
    end

    -- Reconcile: check tracked effects against current game state
    for effectSlot in pairs(reconTrackedKeys) do
        local instance = slots[effectSlot]
        local current = reconCurrentEffects[effectSlot]

        if not current then
            -- Effect no longer present in this slot → treat as faded
            if storage[instance.abilityId] then
                finalizeStatsWithAttribution(storage[instance.abilityId], instance, nowMs)
            end
            recycleInstance(instance)
            slots[effectSlot] = nil
        elseif current.abilityId ~= instance.abilityId then
            -- Different ability now occupies this slot → old effect faded, new one gained
            -- Finalize old instance
            if storage[instance.abilityId] then
                finalizeStatsWithAttribution(storage[instance.abilityId], instance, nowMs)
            end
            recycleInstance(instance)

            -- Track new effect in this slot
            local newAbilityId = current.abilityId
            if not storage[newAbilityId] then
                storage[newAbilityId] = effects.newStatsWithAttribution(newAbilityId, current.effectType)
            end
            updateStatsOnGained(storage[newAbilityId], current.stackCount, current.appliedByPlayer)

            local newInstance = effects.newInstance(newAbilityId, current.effectType, current.stackCount,
                current.appliedByPlayer, unitTag, storageKey, current.beginTime)
            if current.stackCount > 1 then
                newInstance.maxStacksStartMs = nowMs
            end
            slots[effectSlot] = newInstance

            -- Update peak concurrent instances (after adding to activeEffects)
            -- skipReconcile=true because we're already inside reconciliation
            updatePeakConcurrentInstances(ctx, storage[newAbilityId], effectiveStorageKey, newAbilityId, unitTag, true)
        elseif current.beginTime > instance.beginTime then
            -- Same ability but different beginTime → reapplication
            if storage[instance.abilityId] then
                finalizeStatsWithAttribution(storage[instance.abilityId], instance, nowMs)
            end
            recycleInstance(instance)

            local abilityId = current.abilityId
            if not storage[abilityId] then
                storage[abilityId] = effects.newStatsWithAttribution(abilityId, current.effectType)
            end
            updateStatsOnGained(storage[abilityId], current.stackCount, current.appliedByPlayer)

            local newInstance = effects.newInstance(abilityId, current.effectType, current.stackCount,
                current.appliedByPlayer, unitTag, storageKey, current.beginTime)
            if current.stackCount > 1 then
                newInstance.maxStacksStartMs = nowMs
            end
            slots[effectSlot] = newInstance

            -- Update peak concurrent instances (after adding to activeEffects)
            -- skipReconcile=true because we're already inside reconciliation
            updatePeakConcurrentInstances(ctx, storage[abilityId], effectiveStorageKey, abilityId, unitTag, true)
        else
            -- Same ability, same beginTime - just update unitTag in case it changed
            instance.unitTag = unitTag
        end
    end

    -- Check for new effects not previously tracked
    for effectSlot, current in pairs(reconCurrentEffects) do
        if not reconTrackedKeys[effectSlot] then
            local abilityId = current.abilityId
            if not storage[abilityId] then
                storage[abilityId] = effects.newStatsWithAttribution(abilityId, current.effectType)
            end
            updateStatsOnGained(storage[abilityId], current.stackCount, current.appliedByPlayer)

            local instance = effects.newInstance(abilityId, current.effectType, current.stackCount,
                current.appliedByPlayer, unitTag, storageKey, current.beginTime)
            if current.stackCount > 1 then
                instance.maxStacksStartMs = nowMs
            end
            getOrCreateSlots(ctx.activeEffects, effectiveStorageKey)[effectSlot] = instance

            -- Update peak concurrent instances (after adding to activeEffects)
            -- skipReconcile=true because we're already inside reconciliation
            updatePeakConcurrentInstances(ctx, storage[abilityId], effectiveStorageKey, abilityId, unitTag, true)
        end
    end
end

---Handles full effect refresh for the player
---@param ctx EffectContext
function effects.handlePlayerFullRefresh(ctx)
    if not ctx.initialized then return end
    if not effects.isEnabled() then return end

    local playerBuffsEnabled = isPlayerBuffsEnabled()
    local playerDebuffsEnabled = isPlayerDebuffsEnabled()

    -- Skip if both player buffs and player debuffs are disabled
    if not playerBuffsEnabled and not playerDebuffsEnabled then return end

    -- Reconcile alive state first - this may call handlePlayerDeath/handlePlayerAlive
    if not reconcilePlayerAliveState(ctx) then
        return  -- Player is dead, no effect reconciliation needed
    end

    -- Determine effect type filter based on granular settings
    local effectTypeFilter = nil
    if playerBuffsEnabled and not playerDebuffsEnabled then
        effectTypeFilter = BUFF_EFFECT_TYPE_BUFF
    elseif playerDebuffsEnabled and not playerBuffsEnabled then
        effectTypeFilter = BUFF_EFFECT_TYPE_DEBUFF
    end
    -- If both enabled, effectTypeFilter stays nil (track all)

    reconcileEffects(ctx, "player", ctx.effectsOnPlayer, nil, effectTypeFilter)
end

---Handles full effect refresh for a boss unit
---@param ctx EffectContext
---@param unitTag string Boss unit tag (e.g., "boss1")
function effects.handleBossFullRefresh(ctx, unitTag)
    if not ctx.initialized then return end
    if not effects.isEnabled() then return end
    if not isBossDebuffsEnabled() then return end
    if not DoesUnitExist(unitTag) then return end

    -- Capture boss name if not already captured
    if not ctx.bossNames[unitTag] then
        ctx.bossNames[unitTag] = GetRawUnitName(unitTag)
    end

    -- Reconcile alive state first - this may call handleUnitDeath/handleUnitAlive
    if not reconcileUnitAliveState(ctx, unitTag, unitTag) then
        return  -- Boss is dead, no effect reconciliation needed
    end

    -- Ensure storage exists
    if not ctx.effectsOnBosses[unitTag] then
        ctx.effectsOnBosses[unitTag] = {}
    end

    reconcileEffects(ctx, unitTag, ctx.effectsOnBosses[unitTag], unitTag, BUFF_EFFECT_TYPE_DEBUFF)
end

---Handles full effect refresh for a group member
---@param ctx EffectContext
---@param unitTag string Group unit tag (e.g., "group1")
function effects.handleGroupFullRefresh(ctx, unitTag)
    if not ctx.initialized then return end
    if not effects.isEnabled() then return end
    if not isGroupBuffsEnabled() then return end
    if AreUnitsEqual("player", unitTag) then return end
    if IsGroupCompanionUnitTag(unitTag) then return end

    local displayName = getGroupDisplayName(unitTag)

    -- Reconcile alive state first - this may call handleUnitDeath/handleUnitAlive
    if not reconcileUnitAliveState(ctx, displayName, unitTag) then
        return  -- Group member is dead, no effect reconciliation needed
    end

    -- Ensure storage exists
    if not ctx.effectsOnGroup[displayName] then
        ctx.effectsOnGroup[displayName] = {}
    end

    reconcileEffects(ctx, unitTag, ctx.effectsOnGroup[displayName], displayName, BUFF_EFFECT_TYPE_BUFF)
end

---Handles full effect refresh for a specific unit tag (dispatches to appropriate handler)
---@param ctx EffectContext
---@param unitTag string
function effects.handleUnitFullRefresh(ctx, unitTag)
    if unitTag == "player" then
        effects.handlePlayerFullRefresh(ctx)
    elseif unitTag:find(PATTERN_BOSS) then
        effects.handleBossFullRefresh(ctx, unitTag)
    elseif unitTag:find(PATTERN_GROUP) then
        effects.handleGroupFullRefresh(ctx, unitTag)
    end
end

---Handles full effect refresh for all tracked units
---Called on EVENT_EFFECTS_FULL_UPDATE or unexpected change types
---@param ctx EffectContext
function effects.handleFullRefreshAll(ctx)
    if not ctx.initialized then return end
    if not effects.isEnabled() then return end

    effects.handlePlayerFullRefresh(ctx)

    for i = BOSS_RANK_ITERATION_BEGIN, BOSS_RANK_ITERATION_END do
        local bossTag = BOSS_TAGS[i]
        if DoesUnitExist(bossTag) then
            effects.handleBossFullRefresh(ctx, bossTag)
        end
    end

    for i = 1, GetGroupSize() do
        local groupTag = GetGroupUnitTagByIndex(i)
        if groupTag then
            effects.handleGroupFullRefresh(ctx, groupTag)
        end
    end
end

-- ============================================================================
-- Effect Lifecycle
-- ============================================================================

---Finalizes all active effects before state reset (closes any still-active effects)
---Also finalizes alive times for all tracked units
---@param ctx EffectContext|BattleScrollsState
function effects.finalize(ctx)
    local nowMs = GetGameTimeMilliseconds()

    -- Finalize player alive time if still being tracked
    if ctx.playerAliveState and not ctx.playerAliveState.isDead then
        finalizeUnitAliveTime(ctx.playerAliveState, nowMs)
    end

    -- Finalize alive times for all units still being tracked (bosses, group)
    for _unitId, aliveState in pairs(ctx.unitAliveState) do
        if not aliveState.isDead then
            finalizeUnitAliveTime(aliveState, nowMs)
        end
    end

    for _, slots in pairs(ctx.activeEffects) do
        for _, instance in pairs(slots) do
            local unitTag = instance.unitTag

            if unitTag == "player" then
                if ctx.effectsOnPlayer[instance.abilityId] then
                    finalizeStatsWithAttribution(ctx.effectsOnPlayer[instance.abilityId], instance, nowMs)
                end
            elseif unitTag:find(PATTERN_BOSS) then
                -- Bosses use unitTag as storageKey
                local effectStorageKey = instance.storageKey or unitTag
                if ctx.effectsOnBosses[effectStorageKey] and ctx.effectsOnBosses[effectStorageKey][instance.abilityId] then
                    finalizeStatsWithAttribution(ctx.effectsOnBosses[effectStorageKey][instance.abilityId], instance, nowMs)
                end
            elseif unitTag:find(PATTERN_GROUP) then
                -- Group members use displayName as storageKey
                local effectStorageKey = instance.storageKey
                if effectStorageKey and ctx.effectsOnGroup[effectStorageKey] and ctx.effectsOnGroup[effectStorageKey][instance.abilityId] then
                    finalizeStatsWithAttribution(ctx.effectsOnGroup[effectStorageKey][instance.abilityId], instance, nowMs)
                end
            end
            recycleInstance(instance)
        end
    end

    ctx.activeEffects = {}

    -- Request GC after finalizing effects (lots of data potentially freed)
    BattleScrolls.gc:RequestGC()
end

---Backfills active effects when combat starts (captures effects already active)
---@param ctx EffectContext
function effects.backfill(ctx)
    if not effects.isEnabled() then return end

    -- Backfill player effects based on granular settings
    local playerBuffsEnabled = isPlayerBuffsEnabled()
    local playerDebuffsEnabled = isPlayerDebuffsEnabled()

    if playerBuffsEnabled and playerDebuffsEnabled then
        -- Both enabled - track all
        backfillEffectsForUnitTag(ctx, "player", ctx.effectsOnPlayer, nil, nil)
    elseif playerBuffsEnabled then
        -- Only buffs enabled
        backfillEffectsForUnitTag(ctx, "player", ctx.effectsOnPlayer, BUFF_EFFECT_TYPE_BUFF, nil)
    elseif playerDebuffsEnabled then
        -- Only debuffs enabled
        backfillEffectsForUnitTag(ctx, "player", ctx.effectsOnPlayer, BUFF_EFFECT_TYPE_DEBUFF, nil)
    end

    -- Backfill boss effects directly (keyed by unitTag)
    if isBossDebuffsEnabled() then
        for i = BOSS_RANK_ITERATION_BEGIN, BOSS_RANK_ITERATION_END do
            local bossTag = BOSS_TAGS[i]
            if DoesUnitExist(bossTag) then
                local isDead = IsUnitDead(bossTag)

                -- Skip dead bosses - don't track effects on them
                if not isDead then
                    -- Capture boss name proactively
                    if not ctx.bossNames[bossTag] then
                        ctx.bossNames[bossTag] = GetRawUnitName(bossTag)
                    end

                    -- Initialize alive state for this boss
                    ensureUnitAliveState(ctx, bossTag, true)

                    -- Ensure storage exists
                    if not ctx.effectsOnBosses[bossTag] then
                        ctx.effectsOnBosses[bossTag] = {}
                    end

                    -- Backfill debuffs on this boss
                    backfillEffectsForUnitTag(ctx, bossTag, ctx.effectsOnBosses[bossTag], BUFF_EFFECT_TYPE_DEBUFF, bossTag)
                end
            end
        end
    end

    -- Backfill group member effects directly (keyed by displayName)
    if isGroupBuffsEnabled() then
        for i = 1, GetGroupSize() do
            local groupTag = GetGroupUnitTagByIndex(i)
            if groupTag and not AreUnitsEqual("player", groupTag) and not IsGroupCompanionUnitTag(groupTag) then
                local isDead = IsUnitDead(groupTag)

                -- Skip dead group members - don't track effects on them
                if not isDead then
                    local displayName = getGroupDisplayName(groupTag)

                    -- Initialize alive state for this member
                    ensureUnitAliveState(ctx, displayName, true)

                    -- Ensure storage exists
                    if not ctx.effectsOnGroup[displayName] then
                        ctx.effectsOnGroup[displayName] = {}
                    end

                    -- Backfill buffs on this group member
                    backfillEffectsForUnitTag(ctx, groupTag, ctx.effectsOnGroup[displayName], BUFF_EFFECT_TYPE_BUFF, displayName)
                end
            end
        end
    end
end

---Clears effect tracking state (called after finalize, when state is reset)
---@param ctx EffectContext
function effects.clear(ctx)
    ctx.effectsOnPlayer = {}
    ctx.effectsOnBosses = {}
    ctx.effectsOnGroup = {}
    ctx.activeEffects = {}
    ctx.playerAliveState = nil
    ctx.unitAliveState = {}
    ctx.bossNames = {}

    -- Request GC after clearing (old tables now garbage)
    BattleScrolls.gc:RequestGC()
end
