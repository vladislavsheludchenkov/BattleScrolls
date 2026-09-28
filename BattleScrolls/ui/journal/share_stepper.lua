-----------------------------------------------------------
-- Share Stepper
-- First-class journal view for multi-part browser sharing. The journal scene
-- survives RequestOpenUnsafeURL round-trips (dialogs do not), so each part is
-- fired by a real keybind press: send part, confirm the browser prompt,
-- return to the game with this screen still open, press again.
--
-- Stateless renderer over BattleScrolls.shareUrl.getState(); the shareUrl
-- observer wired in journal.lua re-renders on every transition.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}
BattleScrolls.journal = BattleScrolls.journal or {}

local shareStepper = {}
BattleScrolls.journal.shareStepper = shareStepper

local ICON_SENT = "EsoUI/Art/Miscellaneous/Gamepad/gp_checkmark.dds"
local ICON_NEXT = "EsoUI/Art/Miscellaneous/Gamepad/gp_rightArrow.dds"

-- The part row a settled resend should leave selected (so a multi-part
-- resend session does not get yanked back to the done row after each part)
---@type number|nil
local previousResendSeq = nil

---Renders the stepper into the share list.
---@param list ZO_ParametricScrollList
function shareStepper.render(list)
    local entryBuilder = BattleScrolls.journal.EntryBuilder
    local state = BattleScrolls.shareUrl.getState()
    local justSettledResendSeq = previousResendSeq
    previousResendSeq = state.resendingSeq
    list:Clear()

    if state.phase == "building" then
        entryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_SHARE_PREPARING),
            header = GetString(BATTLESCROLLS_SHARE_TITLE),
        })
    elseif state.phase == "failed" then
        entryBuilder.addEntry(list, {
            label = GetString(BATTLESCROLLS_SHARE_FAILED),
            header = GetString(BATTLESCROLLS_SHARE_TITLE),
        })
    elseif state.phase == "choosing" then
        -- Mixed instance built both ways and the part counts differ: the
        -- user picks how much to send before the chain starts
        local function addChoiceRow(labelId, tooltipId, info, variant, isFirst)
            local entry = entryBuilder.addEntry(list, {
                label = zo_strformat(GetString(labelId), info.encounterCount),
                sublabel = zo_strformat(GetString(BATTLESCROLLS_SHARE_CHOICE_PARTS), info.parts),
                icon = ICON_NEXT,
                header = isFirst and GetString(BATTLESCROLLS_SHARE_CHOICE_HEADER) or nil,
                tooltip = {
                    type = "text",
                    title = GetString(BATTLESCROLLS_SHARE_CHOICE_HEADER),
                    text = GetString(tooltipId),
                },
            })
            entry.shareVariant = variant
        end
        addChoiceRow(BATTLESCROLLS_SHARE_CHOICE_FULL, BATTLESCROLLS_SHARE_TT_CHOICE_FULL,
            state.choiceFull, "full", true)
        addChoiceRow(BATTLESCROLLS_SHARE_CHOICE_BOSSES, BATTLESCROLLS_SHARE_TT_CHOICE_BOSSES,
            state.choiceBosses, "bosses", false)
    elseif state.phase == "sending" or state.phase == "done" then
        for seq = 1, state.total do
            local label
            local icon
            local tooltipText
            if state.resendingSeq == seq then
                label = zo_strformat(GetString(BATTLESCROLLS_SHARE_PART_RESENDING), seq)
                icon = ICON_NEXT
                tooltipText = GetString(BATTLESCROLLS_SHARE_TT_READY)
            elseif seq <= state.sentCount then
                label = zo_strformat(GetString(BATTLESCROLLS_SHARE_PART_SENT), seq)
                icon = ICON_SENT
                tooltipText = GetString(BATTLESCROLLS_SHARE_TT_SENT)
            elseif state.phase == "sending" and seq == state.sentCount + 1 then
                label = zo_strformat(GetString(BATTLESCROLLS_SHARE_PART_READY), seq)
                icon = ICON_NEXT
                tooltipText = GetString(BATTLESCROLLS_SHARE_TT_READY)
            else
                label = zo_strformat(GetString(BATTLESCROLLS_SHARE_PART_PENDING), seq)
                tooltipText = GetString(BATTLESCROLLS_SHARE_TT_PENDING)
            end
            if seq == 1 then
                tooltipText = zo_strformat(GetString(BATTLESCROLLS_SHARE_PRIVACY_NOTICE),
                    BattleScrolls.shareUrl.PRIVACY_URL) .. "\n\n" .. tooltipText
            end
            local entry = entryBuilder.addEntry(list, {
                label = label,
                sublabel = seq == 1 and GetString(BATTLESCROLLS_SHARE_PRIVACY_TITLE) or nil,
                icon = icon,
                header = seq == 1 and GetString(BATTLESCROLLS_SHARE_PROGRESS_HEADER) or nil,
                tooltip = {
                    type = "text",
                    title = seq <= state.sentCount and label
                        or GetString(BATTLESCROLLS_SHARE_HINT_HEADER),
                    text = tooltipText,
                },
            })
            -- Selecting a sent part offers a resend (crashed browser tabs
            -- lose their chunk; the upload page names the missing parts)
            entry.partSeq = seq
        end
        if state.phase == "done" then
            entryBuilder.addEntry(list, {
                label = GetString(BATTLESCROLLS_SHARE_DONE_HINT),
                header = GetString(BATTLESCROLLS_SHARE_DONE_HEADER),
                tooltip = {
                    type = "text",
                    title = GetString(BATTLESCROLLS_SHARE_DONE_HEADER),
                    text = GetString(BATTLESCROLLS_SHARE_TT_DONE),
                },
            })
        end
    end

    list:Commit()

    -- Keep the actionable row selected. The parametric list resets to row 1
    -- on every rebuild, which used to leave "Resend Part 1" armed right
    -- after part 1 settled - the natural next press resent part 1 instead
    -- of sending part 2. The done row keeps the send keybind hidden until
    -- the user deliberately picks a part row to resend.
    if state.phase == "sending" or state.phase == "done" then
        local index
        if state.resendingSeq then
            index = state.resendingSeq
        elseif state.phase == "sending" then
            index = math.min(state.sentCount + 1, state.total)
        elseif justSettledResendSeq then
            index = justSettledResendSeq
        else
            index = state.total + 1
        end
        list:SetSelectedIndexWithoutAnimation(index)
    end
end
