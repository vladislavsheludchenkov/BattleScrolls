-----------------------------------------------------------
-- Main
-- Entry point and initialization orchestration for Battle Scrolls
--
-- Handles EVENT_ADD_ON_LOADED and initializes all modules
-- in the correct order based on their dependencies.
--
-- Initialization order:
--   1. Infrastructure (binaryStorage, storage) - SavedVariables
--   2. Combat tracking (state, scribe) - Event subscriptions
--   3. Network (dpsShare, dpsSender) - Group communication
--   4. UI (dpsMeter, onboarding) - Display components
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}
BattleScrolls.addonName = "BattleScrolls"

---Handles addon loaded event, initializes all BattleScrolls modules
---@param _ number Event code (unused)
---@param addonName string Name of the loaded addon
function BattleScrolls.OnAddOnLoaded(_, addonName)
    if addonName == BattleScrolls.addonName then
        BattleScrolls.binaryStorage:Initialize()
        BattleScrolls.storage:Initialize()
        BattleScrolls.state:Initialize()
        BattleScrolls.effectsEvents:Initialize()
        BattleScrolls.effectsReconciler:Initialize()
        BattleScrolls.scribe:Initialize()
        BattleScrolls.dpsShare:Initialize()
        BattleScrolls.dpsSender:Initialize()
        BattleScrolls.dpsMeter:Initialize()
        BattleScrolls.onboarding:Initialize()
        EVENT_MANAGER:UnregisterForEvent("BattleScrolls_Main", EVENT_ADD_ON_LOADED)
    end
end

EVENT_MANAGER:RegisterForEvent("BattleScrolls_Main", EVENT_ADD_ON_LOADED, BattleScrolls.OnAddOnLoaded)
