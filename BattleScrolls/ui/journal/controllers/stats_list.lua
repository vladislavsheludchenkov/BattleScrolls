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
local renderers = journal.renderers
local StatsTab = journal.StatsTab

journal.controllers = journal.controllers or {}

local StatsListController = {}

---@type table<number, fun(ctx: table): PanelSpec>
local panelSpecBuilders = {
    [StatsTab.OVERVIEW]          = renderers.overview.buildOverviewPanelSpec,
    [StatsTab.BOSS_DAMAGE_DONE]  = renderers.damage.buildBossDamagePanelSpec,
    [StatsTab.DAMAGE_DONE]       = renderers.damage.buildDamageDonePanelSpec,
    [StatsTab.DAMAGE_TAKEN]      = renderers.damage.buildDamageTakenPanelSpec,
    [StatsTab.HEALING_OUT]       = renderers.healing.buildHealingOutPanelSpec,
    [StatsTab.SELF_HEALING]      = renderers.healing.buildSelfHealingPanelSpec,
    [StatsTab.HEALING_IN]        = renderers.healing.buildHealingInPanelSpec,
    [StatsTab.EFFECTS_PLAYER]    = renderers.effects.buildEffectsPanelSpec,
    [StatsTab.EFFECTS_BOSS]      = renderers.effects.buildEffectsPanelSpec,
    [StatsTab.EFFECTS_GROUP]     = renderers.effects.buildEffectsPanelSpec,
    [StatsTab.SETUP]             = renderers.setup.buildSetupPanelSpec,
}

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
        -- Add overview entry at the top of every tab, with the default panel spec attached
        local builder = panelSpecBuilders[selectedTab]
        local panelSpec = builder and builder({
            arithmancer = ctx.arithmancer,
            encounter = ctx.encounter,
            durationS = ctx.durationSec,
            unitNames = ctx.unitNames,
            abilityInfo = ctx.abilityInfo,
            filters = ctx.filters,
        }) or nil
        journal.EntryBuilder.addOverviewEntry(ctx.list, selectedTab, panelSpec)

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
        elseif selectedTab == StatsTab.EFFECTS_PLAYER then
            renderers.effects.renderEffectsPlayer(ctx):Await()
        elseif selectedTab == StatsTab.EFFECTS_BOSS then
            renderers.effects.renderEffectsBoss(ctx):Await()
        elseif selectedTab == StatsTab.EFFECTS_GROUP then
            renderers.effects.renderEffectsGroup(ctx):Await()
        elseif selectedTab == StatsTab.GROUP then
            renderers.group.renderGroup(ctx):Await()
        elseif selectedTab == StatsTab.SETUP then
            renderers.setup.renderSetup(ctx):Await()
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

    -- Check what needs to be decoded/computed
    local needsEncounterDecode = journalUI.decodedEncounter == nil
    local needsAbilityInfo = journalUI.abilityInfo == nil
    local needsArithmancer = journalUI.arithmancer == nil

    -- Show loading state
    list:SetNoItemText(GetString(BATTLESCROLLS_LIST_LOADING))
    list:Commit()


    -- Async refresh
    journalUI.taskInProgress = LibEffect.Async(function()
        -- Decode encounter if needed
        local decodedEncounter = journalUI.decodedEncounter
        if needsEncounterDecode then
            decodedEncounter = BattleScrolls.storage.DecodeEncounterAsync(rawEncounter):Await()
            journal.chronicler.computeTabVisibility(decodedEncounter)
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

        -- Compute arithmancer if needed (arithmancer:Make is cheap - just creates object with references)
        if needsArithmancer then
            ---@cast decodedEncounter Encounter -- Guaranteed non-nil by control flow above
            local calc = BattleScrolls.arithmancer:Make(decodedEncounter, abilityInfo)
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
            journalUI = journalUI,
        }
        StatsListController.renderTab(ctx, journalUI.selectedTab):Await()

        LibEffect.Yield():Await()
        journalUI.statsRefreshPending = false
        list:Commit()

        -- Restore saved index (e.g. after favorite toggle) or default to index 2
        local numItems = list:GetNumItems()
        local restoreIndex = journalUI.restoreSelectedIndex
        journalUI.restoreSelectedIndex = nil

        local targetIndex = 1
        if restoreIndex and restoreIndex >= 1 and restoreIndex <= numItems then
            targetIndex = restoreIndex
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
