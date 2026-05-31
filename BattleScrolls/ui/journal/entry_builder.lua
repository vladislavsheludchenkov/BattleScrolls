-----------------------------------------------------------
-- Entry Builder
-- Unified Q1 parametric list entry construction.
-- Replaces scattered ZO_GamepadEntryData construction in
-- renderers with a single addEntry(list, spec) function.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

local journal = BattleScrolls.journal

---@class EntrySpec
---@field label string Display text
---@field sublabel string|nil Right-side value text
---@field icon string|nil Icon path
---@field header string|nil Section header (first-in-group)
---@field frame boolean|nil Show icon edge/circle frame (true -> BattleScrolls_AbilityEntryTemplate)
---@field vengeanceSlotFlag number|nil Show the icon with a Vengeance slot frame
---@field tooltip TooltipDescriptor|nil
---@field isFavorite boolean|nil Whether this is a favorited effect
---@field onFavoriteToggle (fun())|nil Callback when user toggles favorite
---@field nameColors table|nil Custom name colors (from SetNameColors)

---@class DetailRow
---@field icon string Pre-resolved texture path
---@field label string Display text
---@field value string|nil Right-aligned value text
---@field isHighlighted boolean|nil Killing blow skull indicator

---@class TooltipAbility
---@field abilityId number ESO ability ID (populateAbilityRow resolves icon/name/frame)
---@field isUltimate boolean|nil
---@field scripts { icon: string, name: string }[]|nil Pre-resolved scribing scripts

---@class IconGroup
---@field headerLabel string Group header text
---@field headerIcon string|nil Group header icon
---@field rows IconRow[]

---@class IconRow
---@field label string
---@field icon string|nil
---@field abilityId number|nil Use a framed ability row instead of the plain icon-list row
---@field isUltimate boolean|nil
---@field vengeanceSlotFlag number|nil Use a Vengeance slot frame for the row icon

---@alias TooltipDescriptor
---| { type: "text", title: string, text: string }
---| { type: "item", itemLink: string }
---| { type: "panel", panelSpec: PanelSpec }
---| { type: "groupTable" }
---| { type: "detailRows", title: string, subtitle: string|nil, rows: DetailRow[] }
---| { type: "abilityList", title: string, abilities: TooltipAbility[] }
---| { type: "iconList", title: string, groups: IconGroup[]|nil, rows: IconRow[]|nil }
---| { type: "vengeancePerk", perkDefId: number, slotFlag: number }

---@class PanelSpec
---@field layout string|nil Layout mode: "three-column" (default), "two-column", "wide-right", "wide-left"
---@field build fun(q2: ColumnBuilder, q3: ColumnBuilder, q4: ColumnBuilder)

local EntryBuilder = {}

---Creates a list entry from a spec and adds it to the parametric list.
---@param list ZO_ParametricScrollList
---@param spec EntrySpec
---@diagnostic disable-next-line: undefined-doc-name -- ESO API type not in LuaLS definitions
---@return ZO_GamepadEntryData entryData
function EntryBuilder.addEntry(list, spec)
    local usesVengeanceFrame = spec.vengeanceSlotFlag ~= nil
    local template
    if usesVengeanceFrame then
        template = "BattleScrolls_VengeancePerkEntryTemplate"
    elseif spec.frame then
        template = "BattleScrolls_AbilityEntryTemplate"
    else
        template = "ZO_GamepadItemSubEntryTemplate"
    end

    local entryIcon = spec.icon
    if usesVengeanceFrame then
        entryIcon = nil
    end
    local entryData = ZO_GamepadEntryData:New(spec.label, entryIcon)

    if spec.icon then
        entryData.iconFile = spec.icon
        if not usesVengeanceFrame then
            entryData:SetIconTintOnSelection(true)
        end
    end
    if usesVengeanceFrame then
        entryData.vengeanceSlotFlag = spec.vengeanceSlotFlag
    end

    if spec.sublabel then
        entryData:AddSubLabel(tostring(spec.sublabel))
    end

    if spec.isFavorite ~= nil then
        entryData.isFavorite = spec.isFavorite
    end

    if spec.onFavoriteToggle then
        entryData.onFavoriteToggle = spec.onFavoriteToggle
    end

    if spec.nameColors then
        entryData:SetNameColors(unpack(spec.nameColors))
    end

    entryData.tooltip = spec.tooltip

    if spec.header then
        entryData:SetHeader(spec.header)
        list:AddEntryWithHeader(template, entryData)
    else
        list:AddEntry(template, entryData)
    end

    return entryData
end

---Creates the standard "Overview" entry (first entry in every stats tab).
---@param list ZO_ParametricScrollList
---@param selectedTab number|nil The current stats tab (GROUP tab uses "groupTable" tooltip)
---@param panelSpec PanelSpec|nil Default panel spec for the tab's overview
---@diagnostic disable-next-line: undefined-doc-name -- ESO API type not in LuaLS definitions
---@return ZO_GamepadEntryData entryData
function EntryBuilder.addOverviewEntry(list, selectedTab, panelSpec)
    local tooltipType = selectedTab == journal.StatsTab.GROUP and "groupTable" or "panel"
    return EntryBuilder.addEntry(list, {
        label = GetString(BATTLESCROLLS_TAB_OVERVIEW),
        icon = journal.StatIcons.SUMMARY,
        tooltip = { type = tooltipType, panelSpec = panelSpec },
    })
end

journal.EntryBuilder = EntryBuilder
