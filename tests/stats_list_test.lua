-- Exercise async rebuilds against ESO's actual list state and resize handler.
-- Only control creation/layout and the stats renderer are replaced with mocks.
local function fixture()
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.BattleScrolls = { journal = {}, gc = { RequestGC = function() end } }
    local function load(path) return assert(loadfile(path, "t", env))() end
    local scheduler = load("tests/mocks/libasync.lua")
    local effect = load("BattleScrolls/core/effect.lua")
    local errors = {}
    effect.OnUnhandledError = function(err) errors[#errors + 1] = err end

    env.ZO_InitializingCallbackObject = { Subclass = function() return {} end }
    env.zo_clamp = function(n, lo, hi) return math.min(hi, math.max(lo, n)) end
    env.zo_abs = math.abs
    env.zo_floatsAreEqual = function(a, b) return a == b end
    load("esoui/esoui/libraries/zo_parametricscrolllist/zo_parametricscrolllist.lua")

    local scrollControl = { top = 192 }
    function scrollControl:SetHandler(event, handler) self[event] = handler end
    local list = setmetatable({
        mode = env.PARAMETRIC_SCROLL_LIST_VERTICAL,
        scrollControl = scrollControl,
        enabled = true,
        defaultSelectedIndex = 1,
        reselectBehavior = env.ZO_PARAMETRIC_SCROLL_LIST_RESELECT_BEHAVIOR.RESELECT_OLD_INDEX,
        dataTypes = {
            row = {
                hasEditControl = false,
                pool = {
                    AcquireObject = function() return {}, 1 end,
                    ReleaseAllObjects = function() end,
                },
            },
        },
        FireCallbacks = function() end,
        SetNoItemText = function(self, text) self.noItemsText = text end,
        UpdateAnchors = function(self, index)
            -- Keep the real acquisition path: index 0 reproduces the reported
            -- nil dataTypes[templateName] error before any mocked layout runs.
            self:AcquireControlAtDataIndex(index)
            self.selectedIndex = index
            self.selectedData = self.dataList[index]
            self.renderedTop = self.scrollControl.top
        end,
    }, { __index = env.ZO_ParametricScrollList })
    list:Clear()
    list:SetHandleDynamicViewProperties(true)
    local function resize()
        local oldTop = scrollControl.top
        scrollControl.top = oldTop + 95
        if scrollControl.OnRectChanged then
            scrollControl.OnRectChanged(scrollControl, 96, scrollControl.top, 876, 955, 96, oldTop, 876, 955)
        end
    end

    env.GetString = function(id) return id end
    env.BATTLESCROLLS_LIST_LOADING = "loading"
    env.BATTLESCROLLS_LIST_NO_STATS = "no stats"
    local journal = env.BattleScrolls.journal
    journal.StatsTab = {}
    for i, name in ipairs({ "OVERVIEW", "BOSS_DAMAGE_DONE", "DAMAGE_DONE", "DAMAGE_TAKEN",
        "HEALING_OUT", "SELF_HEALING", "HEALING_IN", "EFFECTS_PLAYER", "EFFECTS_BOSS",
        "EFFECTS_GROUP", "SETUP", "ACTIVITY", "GROUP_DAMAGE", "GROUP" }) do
        journal.StatsTab[name] = i
    end
    journal.EntryBuilder = {
        addOverviewEntry = function(target) target:AddEntry("row", { name = "overview" }) end,
    }
    local pending = {}
    journal.renderers = { damage = {}, healing = {}, effects = {}, setup = {}, activity = {}, overview = {
        renderOverview = function(ctx)
            return effect.Async(function()
                ctx.list:AddEntry("row", { name = "duration" })
                effect.FromCallback(function(resolve, reject)
                    pending.resolve, pending.reject = resolve, reject
                end):Await()
                ctx.list:AddEntry("row", { name = "damage" })
            end)
        end,
    } }
    journal.chronicler = { refreshTooltip = function(ui, data) ui.tooltip = data end }
    load("BattleScrolls/ui/journal/controllers/stats_list.lua")
    local ui = {
        statsList = list,
        selectedEncounter = {}, selectedInstance = {},
        decodedEncounter = { durationMs = 7200 }, abilityInfo = {}, unitNames = {}, arithmancer = {},
        selectedTab = journal.StatsTab.OVERVIEW,
        GetFiltersForTab = function() return {} end,
        GetSearchText = function() return "" end,
    }
    return {
        ui = ui, list = list, resize = resize, pending = pending, errors = errors, pump = scheduler.pump,
        refresh = function() return journal.controllers.statsList.refresh(ui) end,
        start = function()
            local fiber = journal.controllers.statsList.refresh(ui)
            scheduler.pump(20)
            assert_true(fiber:IsRunning())
            assert_true(pending.resolve ~= nil)
            return fiber
        end,
    }
end

describe("Stats list resize during async refresh", function()
    it("reproduces ESO's index-zero error with uncommitted rows", function()
        local f = fixture()
        f.list:AddEntry("row", {})
        assert_eq(f.list:GetTargetIndex(), 0)
        assert_error(f.resize, "attempt to index a nil value")
    end)

    it("survives resizing during loading and resumes layout after commit", function()
        local f = fixture()
        f.ui.restoreSelectedIndex = 2
        local fiber = f.start()
        assert_eq(f.list:GetNumItems(), 2)
        assert_eq(f.list:GetTargetIndex(), 0)
        f.resize()
        f.pending.resolve()
        f.pump(30)
        assert_true(fiber:IsSucceeded(), tostring(fiber._error))
        assert_eq(f.list:GetNumItems(), 3)
        assert_eq(f.list:GetSelectedIndex(), 2)
        assert_eq(f.ui.tooltip.name, "duration")
        assert_eq(f.list.renderedTop, f.list.scrollControl.top)
        f.resize()
        assert_eq(f.list.renderedTop, f.list.scrollControl.top)
        assert_eq(f.ui.taskInProgress, nil)
        assert_eq(#f.errors, 0)
    end)

    for _, phase in ipairs({ "before rendering", "during rendering", "after commit" }) do
        it("cleans up cancellation " .. phase, function()
            local f = fixture()
            local fiber = phase == "before rendering" and f.refresh() or f.start()
            if phase == "after commit" then
                f.pending.resolve()
                for _ = 1, 30 do
                    if f.list:GetSelectedIndex() then break end
                    f.pump(1)
                end
                assert_true(f.list:GetSelectedIndex() ~= nil)
                assert_true(fiber:IsRunning())
            end
            fiber:Cancel()
            f.resize()
            assert_true(not fiber:IsRunning() and fiber._error.isCancelled)
            assert_eq(f.list:GetNumItems(), phase == "after commit" and 3 or 0)
            assert_true(f.list.handleDynamicViewProperties)
            assert_eq(f.list.noItemsText, "no stats")
            assert_eq(f.ui.taskInProgress, nil)
            f.pump(30)
            assert_eq(#f.errors, 0)
        end)
    end

    it("clears partial rows on renderer failure", function()
        local f = fixture()
        local fiber = f.start()
        f.pending.reject("render failed")
        f.pump(30)
        assert_true(fiber:IsFailed())
        assert_eq(f.list:GetNumItems(), 0)
        assert_true(f.list.handleDynamicViewProperties)
        f.resize()
        assert_eq(#f.errors, 1)
        assert_eq(f.errors[1], "render failed")
    end)

    it("cancels a previous rebuild before starting another", function()
        local f = fixture()
        local oldFiber = f.start()
        local oldResolve = f.pending.resolve
        local newFiber = f.start()
        assert_true(not oldFiber:IsRunning() and oldFiber._error.isCancelled)
        oldResolve()
        f.resize()
        f.pending.resolve()
        f.pump(30)
        assert_true(newFiber:IsSucceeded())
        assert_eq(f.list:GetNumItems(), 3)
        assert_eq(f.list:GetSelectedIndex(), 1)
        assert_eq(#f.errors, 0)
    end)

    it("cancels an old rebuild even if the encounter was cleared", function()
        local f = fixture()
        local fiber = f.start()
        f.ui.selectedEncounter = nil
        f.refresh()
        assert_true(not fiber:IsRunning() and fiber._error.isCancelled)
        f.resize()
        f.pump(30)
        assert_eq(f.list:GetNumItems(), 0)
        assert_true(f.list.handleDynamicViewProperties)
        assert_eq(f.ui.taskInProgress, nil)
        assert_eq(#f.errors, 0)
    end)
end)
