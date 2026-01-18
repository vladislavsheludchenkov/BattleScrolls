-----------------------------------------------------------
-- Stats List Controller
-- Orchestrates stats list population by dispatching to renderers
--
-- This controller handles:
-- - Decoding encounter/instance data
-- - Building the render context
-- - Dispatching to the appropriate renderer based on selected tab
-- - Managing async refresh with cancellation
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal
local utils = journal.utils
local renderers = journal.renderers
local StatsTab = journal.StatsTab

journal.controllers = journal.controllers or {}

local StatsListController = {}

-------------------------
-- Tab Rendering
-------------------------

---Renders the current stats tab to the list
---Filters in ctx are already normalized (targetFilter, sourceFilter, groupFilter keys)
---@param ctx JournalRenderContext
---@param selectedTab number The currently selected stats tab
---@return Effect
function StatsListController.renderTab(ctx, selectedTab)
    return LibEffect.Async(function()
        -- Add overview entry at the top of every tab
        utils.addOverviewEntry(ctx.list)

        if selectedTab == StatsTab.OVERVIEW then
            renderers.overview.renderOverview(ctx):Await()
        elseif selectedTab == StatsTab.BOSS_DAMAGE_DONE then
            renderers.damage.renderBossDamageDone(ctx):Await()
        elseif selectedTab == StatsTab.DAMAGE_DONE then
            renderers.damage.renderDamageDone(ctx):Await()
        elseif selectedTab == StatsTab.DAMAGE_TAKEN then
            renderers.damage.renderDamageTaken(ctx):Await()
        elseif selectedTab == StatsTab.HEALING_OUT then
            renderers.healing.renderHealingOut(ctx):Await()
        elseif selectedTab == StatsTab.SELF_HEALING then
            renderers.healing.renderSelfHealing(ctx):Await()
        elseif selectedTab == StatsTab.HEALING_IN then
            renderers.healing.renderHealingIn(ctx):Await()
        elseif selectedTab == StatsTab.EFFECTS then
            renderers.effects.renderEffects(ctx):Await()
        end
    end)
end

-------------------------
-- Full Refresh
-------------------------

---Performs a full stats list refresh (async, with decoding if needed)
---@param journalUI BattleScrolls_Journal_Gamepad The journal UI instance
---@return Effect The running effect (for cancellation)
function StatsListController.refresh(journalUI)
    local list = journalUI.statsList
    list:Clear()

    local rawEncounter = journalUI.selectedEncounter
    local instance = journalUI.selectedInstance

    if not rawEncounter then
        list:Commit()
        return LibEffect.Yield():Run()
    end

    -- Cancel any in-progress task
    if journalUI.taskInProgress then
        journalUI.taskInProgress:Cancel()
        journalUI.taskInProgress = nil
        BattleScrolls.gc:RequestGC(5)
    end

    -- Show loading state
    list:SetNoItemText(GetString(BATTLESCROLLS_LIST_LOADING))
    list:Commit()

    -- Check what needs to be decoded/computed
    local needsEncounterDecode = journalUI.decodedEncounter == nil
    local needsAbilityInfo = journalUI.abilityInfo == nil
    local needsArithmancer = journalUI.arithmancer == nil

    -- Async refresh
    journalUI.taskInProgress = LibEffect.Async(function()
        -- Decode encounter if needed
        local decodedEncounter = journalUI.decodedEncounter
        if needsEncounterDecode then
            decodedEncounter = BattleScrolls.storage.DecodeEncounterAsync(rawEncounter):Await()
            journalUI.decodedEncounter = decodedEncounter
        end

        -- Get unitNames from encounter, abilityInfo from instance
        local unitNames = journalUI.unitNames
        local abilityInfo = journalUI.abilityInfo

        -- unitNames are stored at encounter level
        if unitNames == nil then
            unitNames = decodedEncounter.unitNames
            journalUI.unitNames = unitNames
        end

        -- abilityInfo is stored at instance level
        if needsAbilityInfo then
            local instanceFields = BattleScrolls.storage.DecodeInstanceFieldsAsync(instance):Await()
            abilityInfo = instanceFields[1]
            journalUI.abilityInfo = abilityInfo
        end

        -- Refresh header after decode to show all tabs
        if needsEncounterDecode then
            LibEffect.YieldWithGC():Await()
            journalUI:RefreshHeader()
        end

        -- Compute arithmancer if needed (arithmancer:New is cheap - just creates object with references)
        if needsArithmancer then
            ---@cast decodedEncounter Encounter -- Guaranteed non-nil by control flow above
            local calc = BattleScrolls.arithmancer:New(decodedEncounter, abilityInfo)
            journalUI.arithmancer = calc
        end

        -- Build context and render
        list:Clear()

        local durationSec = decodedEncounter.durationMs / 1000
        local ctx = {
            list = list,
            encounter = decodedEncounter,
            abilityInfo = abilityInfo,
            unitNames = unitNames,
            durationSec = durationSec,
            arithmancer = journalUI.arithmancer,
            filters = journalUI:GetFiltersForTab(journalUI.selectedTab),
        }
        StatsListController.renderTab(ctx, journalUI.selectedTab):Await()

        LibEffect.Yield():Await()
        list:Commit()

        -- For non-overview tabs, scroll to index 2 (just below the overview entry)
        local numItems = list:GetNumItems()
        local targetIndex = 1
        if journalUI.selectedTab ~= StatsTab.OVERVIEW and numItems >= 2 then
            targetIndex = 2
        end
        if list:GetSelectedIndex() ~= targetIndex then
            list:SetSelectedIndexWithoutAnimation(targetIndex)
        end

        LibEffect.Yield():Await()

        -- Trigger tooltip/panel refresh for the selected entry
        journal.chronicler.refreshTooltip(journalUI, list:GetTargetData())
    end):Ensure(function()
        list:SetNoItemText(GetString(BATTLESCROLLS_LIST_NO_STATS))
        journalUI.taskInProgress = nil
        BattleScrolls.gc:RequestGC(5)
    end):Run()

    return journalUI.taskInProgress
end

-- Export to namespace
journal.controllers.statsList = StatsListController
