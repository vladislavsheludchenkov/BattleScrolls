-----------------------------------------------------------
-- ShareUrl
-- Sends export streams to the share site through the only egress consoles
-- have: RequestOpenUnsafeURL. The payload rides in the URL fragment of
-- https://<share host>/u; the page posts it to the API and redirects to the
-- share link.
--
-- Transport facts this module is built on (measured + esoui source):
--   * Xbox caps at 32655 total URL chars and FAILS SILENTLY above - chunk
--     sizes must be clamped client-side.
--   * PlayStation reports the same silent failure for larger shares. Its
--     default is conservative and adjustable until the limit is measured.
--   * There is no queue in the open-URL pipeline: bursts lose everything.
--     Only serial user-confirmed stepping works for multi-part payloads.
--   * The "Confirm Open URL" dialog (CONFIRM_UNSAFE_URL) lives in the
--     internalingame GUI environment. Nothing in this environment sees it
--     through ZO_Dialogs (ZO_Dialogs_IsShowingDialog() stays false); the
--     one cross-environment window is ZO_DIALOG_SYNC_OBJECT, a
--     SynchronizingObject shared by name between the GUI environments.
--   * Cancelling that dialog with B makes internalingame request the base
--     scene (ZO_Dialogs_CloseKeybindPressed -> RequestShowLeaderBaseScene),
--     which tears down whatever gamepad scene is open here. Observable via
--     EVENT_REMOTE_SCENE_REQUEST; doubles as decline evidence. Confirming,
--     or declining via the "No" button, leaves the scene alone - so the
--     journal scene survives the normal round-trip and hosts the stepper
--     as a first-class view (ui/journal/share_stepper.lua), each part
--     fired by a real keybind press.
--   * Closing the console browser with B delivers that same B to our
--     keybind strip as the game resumes (the app-switcher return path
--     delivers nothing) - stepper presses landing right after a suspend
--     gap are discarded (browser-exit leak guard in ui/journal/keybinds.lua).
--
-- Because RequestOpenUnsafeURL reports nothing back, a fired part is held
-- "in flight" and only counted as sent once its confirm dialog has come and
-- gone without decline evidence. Declining via the "No" button is
-- indistinguishable from confirming (both just close the dialog); that
-- residual gap surfaces as a missing part on the upload page.
--
-- Parts can also vanish AFTER a clean hand-off: the console browser crashes
-- under tab load and a part's tab never posts its chunk. The game cannot
-- observe that - only the upload page knows which parts arrived - so the
-- chain survives "done" in full: the upload page lists missing parts and
-- any already-fired part can be re-fired (resendPart) until the user
-- explicitly finishes the chain (stop).
--
-- This module is presentation-free: it owns the chain state machine and
-- notifies an observer (the journal) on every transition.
-----------------------------------------------------------

if not SemisPlaygroundCheckAccess() then
    return
end

BattleScrolls = BattleScrolls or {}

---@class BattleScrollsShareUrl
---@field playstationChunkSizes number[] Supported base64 data sizes for PlayStation browser parts
---@field _browserTripPending boolean|nil One-shot: a URL confirm round trip completed and no press has passed the leak guard since (ui/journal/keybinds.lua consumes it)
---@field _sourceInstance InstanceStorage|nil What the active chain/build was started for; "Continue" is offered only on an exact source match, any other share entry point silently supersedes the chain
---@field _sourceEncounter CompactEncounter|nil Set for encounter shares, nil for instance uploads
local shareUrl = {}
BattleScrolls.shareUrl = shareUrl

local BASE_URL = "https://bs.sheludchenkov.com/u"
shareUrl.PRIVACY_URL = "https://bs.sheludchenkov.com/privacy"
-- Multiple of 4 so every part is independently valid base64; leaves ample
-- headroom for the scheme/host/fragment params under the 32655
-- Xbox cap
local CHUNK_DATA_CHARS = 32000
shareUrl.playstationChunkSizes = { 1000, 2000, 4000, 6000, 7000, 7800, 8000, 8192, 9000, 12000, 16000, 24000, 32000 }
local SESSION_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
local UINT32_MODULUS = 4294967296
local sessionCounter = 0

---@return number
local function getChunkDataChars()
    if GetUIPlatform() ~= UI_PLATFORM_PS5 then
        return CHUNK_DATA_CHARS
    end
    local storage = BattleScrolls.storage
    local settings = storage.savedVariables and storage.savedVariables.settings
    local configured = settings and settings.playstationShareChunkChars
    for _, size in ipairs(shareUrl.playstationChunkSizes) do
        if size == configured then
            return size
        end
    end
    return storage.defaults.settings.playstationShareChunkChars
end

---@alias SharePhase "idle"|"building"|"choosing"|"sending"|"done"|"failed"

---@class ShareChain
---@field parts string[] Base64 data parts
---@field session string Upload session id
---@field lang string Game client language (drives the upload page's texts)
---@field nextSeq number Next unfired part (1-based; total+1 once every part has been fired)
---@field total number

---@class ShareVariantInfo
---@field parts number URL parts this variant needs
---@field encounterCount number Encounters it contains

---@class ShareState
---@field phase SharePhase
---@field sentCount number Parts already fired
---@field total number Part count (0 while building)
---@field resendingSeq number|nil Already-sent part currently re-firing
---@field choiceFull ShareVariantInfo|nil Offered while phase is "choosing"
---@field choiceBosses ShareVariantInfo|nil Offered while phase is "choosing"

---@type ShareChain|nil
local chain = nil
---@type Fiber|nil
local buildFiber = nil
---@type SharePhase
local phase = "idle"

-- Archive variant choice: a mixed instance (bosses + trash) is built both
-- ways; when the part counts differ the user picks before sending starts
---@class ShareVariant
---@field result ExportResult
---@field parts number
---@field chunkDataChars number Part size captured when this variant was prepared
---@type ShareVariant|nil
local choiceFull = nil
---@type ShareVariant|nil
local choiceBosses = nil

-- In-flight part settlement (see header): the fired part whose confirm
-- dialog has not resolved yet, plus the evidence gathered while watching it
local WATCH_NAMESPACE = "BattleScrollsShareUrlInFlight"
local WATCH_INTERVAL_MS = 300
local NO_DIALOG_TIMEOUT_MS = 4000
local SETTLE_GRACE_MS = 400
---@type number|nil
local inFlightSeq = nil
local inFlightIsResend = false
local confirmDialogSeen = false
local declineSeen = false
local firedAtMs = 0
---@type number|nil
local settleAtMs = nil

local function clearInFlight()
    EVENT_MANAGER:UnregisterForUpdate(WATCH_NAMESPACE)
    inFlightSeq = nil
    inFlightIsResend = false
    confirmDialogSeen = false
    declineSeen = false
    firedAtMs = 0
    settleAtMs = nil
end

---Observer for state transitions (the journal's stepper view). Called with
---no arguments after every phase/progress change.
---@type fun()|nil
shareUrl.onStateChanged = nil

local function notify()
    if shareUrl.onStateChanged then
        shareUrl.onStateChanged()
    end
end

---@param newPhase SharePhase
local function setPhase(newPhase)
    phase = newPhase
    notify()
end

-- =============================================================================
-- STATE
-- =============================================================================

---Snapshot for the stepper view.
---@return ShareState
function shareUrl.getState()
    return {
        phase = phase,
        sentCount = chain and math.min(chain.nextSeq - 1, chain.total) or 0,
        total = chain and chain.total or 0,
        resendingSeq = inFlightIsResend and inFlightSeq or nil,
        choiceFull = choiceFull and {
            parts = choiceFull.parts,
            encounterCount = choiceFull.result.encounterCount,
        } or nil,
        choiceBosses = choiceBosses and {
            parts = choiceBosses.parts,
            encounterCount = choiceBosses.result.encounterCount,
        } or nil,
    }
end

---True while a build, a pending variant choice or a chain is alive. A
---"done" chain still counts: it is kept for part resends until the user
---explicitly finishes it.
---@return boolean
function shareUrl.isBusy()
    return chain ~= nil or buildFiber ~= nil or choiceFull ~= nil
end

---Cancels any build or send in progress and discards a kept "done" chain.
function shareUrl.stop()
    if buildFiber then
        buildFiber:Cancel()
        buildFiber = nil
    end
    chain = nil
    choiceFull = nil
    choiceBosses = nil
    clearInFlight()
    shareUrl._browserTripPending = nil
    shareUrl._sourceInstance = nil
    shareUrl._sourceEncounter = nil
    setPhase("idle")
end

---True when the active chain (or build) is exactly this instance-wide
---upload - the only case the journal offers "Continue" for it.
---@param instance InstanceStorage|nil
---@return boolean
function shareUrl.isChainForInstance(instance)
    return shareUrl.isBusy() and instance ~= nil
        and shareUrl._sourceInstance == instance
        and shareUrl._sourceEncounter == nil
end

---True when the active chain (or build) is exactly this encounter's share.
---@param instance InstanceStorage|nil
---@param encounter CompactEncounter|nil
---@return boolean
function shareUrl.isChainForEncounter(instance, encounter)
    return shareUrl.isBusy() and instance ~= nil and encounter ~= nil
        and shareUrl._sourceInstance == instance
        and shareUrl._sourceEncounter == encounter
end

-- =============================================================================
-- BROWSER-RETURN ONE-SHOT (leak-guard support, see ui/journal/keybinds.lua)
-- =============================================================================

---Consumes the one-shot browser-return marker. True means a URL confirm
---round trip completed and no press has passed the leak guard since - the
---caller should treat the current B press as the browser-exit press.
---@return boolean
function shareUrl.consumeBrowserReturnGuard()
    local was = shareUrl._browserTripPending
    shareUrl._browserTripPending = nil
    return was == true
end

---Clears the marker: a press passed the guard, so the user is provably back
---and interacting.
function shareUrl.clearBrowserReturnGuard()
    shareUrl._browserTripPending = nil
end

-- =============================================================================
-- CHAIN
-- =============================================================================

---@return string
local function newSessionId()
    -- ESO seeds the shared RNG from seconds since midnight. Keep its random
    -- suffix, but separate players and repeated uploads without reseeding it.
    -- The hash is a namespace, not a privacy or cryptographic guarantee.
    local identity = string.format("%s:%s:%d", GetDisplayName(), GetWorldName(), GetUIPlatform())
    local playerHash = HashString(identity) % UINT32_MODULUS
    sessionCounter = (sessionCounter + 1) % UINT32_MODULUS
    local out = {}
    for i = 1, 8 do
        local idx = math.random(1, #SESSION_ALPHABET)
        out[i] = SESSION_ALPHABET:sub(idx, idx)
    end
    -- Exactly 32 alphanumeric chars, matching the upload API's session limit.
    return string.format("%08x%08x%08x%s", playerHash,
        GetTimeStamp() % UINT32_MODULUS, sessionCounter, table.concat(out))
end

---@param seq number
---@return string
local function partUrl(seq)
    return string.format("%s#s=%s&i=%d&n=%d&l=%s&d=%s",
        BASE_URL, chain.session, seq, chain.total, chain.lang, chain.parts[seq])
end

---Counts the in-flight part as sent (or leaves it pending if declined) and
---moves the chain forward. Runs a beat after the confirm dialog goes away.
local function settleInFlight()
    local seq = inFlightSeq
    local wasResend = inFlightIsResend
    local wasDeclined = declineSeen
    local sawDialog = confirmDialogSeen
    clearInFlight()
    if not chain or not seq then
        return
    end
    if sawDialog and not wasDeclined then
        -- The browser really opened: the next B on the stepper may be the
        -- press that closes it
        shareUrl._browserTripPending = true
    end
    if wasDeclined or wasResend then
        -- A declined part stays pending; a resend was already counted.
        -- Neither advances the next part to send.
        notify()
    elseif seq >= chain.total then
        chain.nextSeq = chain.total + 1
        setPhase("done")
    else
        chain.nextSeq = seq + 1
        notify()
    end
end

---Watches the cross-environment dialog state while a part is in flight.
local function watchInFlight()
    if not inFlightSeq then
        clearInFlight()
        return
    end
    if ZO_DIALOG_SYNC_OBJECT:IsShown()
        and ZO_DIALOG_SYNC_OBJECT:GetState() == "CONFIRM_UNSAFE_URL" then
        confirmDialogSeen = true
        settleAtMs = nil
        return
    end
    local nowMs = GetGameTimeMilliseconds()
    if confirmDialogSeen then
        -- Dialog came and went; give decline evidence (the remote
        -- base-scene request) a beat to arrive before settling
        settleAtMs = settleAtMs or (nowMs + SETTLE_GRACE_MS)
        if nowMs >= settleAtMs then
            settleInFlight()
        end
    elseif nowMs - firedAtMs >= NO_DIALOG_TIMEOUT_MS then
        -- No confirm dialog ever appeared - count the part as not sent
        -- rather than pretend it was
        declineSeen = true
        settleInFlight()
    end
end

---Fires one part's browser link and starts the in-flight watch.
---@param seq number
---@param isResend boolean
local function firePart(seq, isResend)
    RequestOpenUnsafeURL(partUrl(seq))
    inFlightSeq = seq
    inFlightIsResend = isResend
    confirmDialogSeen = false
    declineSeen = false
    firedAtMs = GetGameTimeMilliseconds()
    settleAtMs = nil
    EVENT_MANAGER:RegisterForUpdate(WATCH_NAMESPACE, WATCH_INTERVAL_MS, watchInFlight)
    notify()
end

---Fires the next pending part's browser link. The caller (stepper keybind)
---invokes this once per user press; the part stays pending until its confirm
---dialog resolves without decline evidence.
function shareUrl.sendNextPart()
    if not chain or inFlightSeq or chain.nextSeq > chain.total then
        return
    end
    firePart(chain.nextSeq, false)
end

---Re-fires an already-sent part: the upload page reported it missing (its
---browser tab crashed before posting the chunk). Valid any time after the
---part's first send, including at "done".
---@param seq number
function shareUrl.resendPart(seq)
    if not chain or inFlightSeq or seq < 1 or seq >= chain.nextSeq then
        return
    end
    firePart(seq, true)
end

---True while the stepper must not fire another URL: a part's confirmation
---round-trip has not settled, or a dialog (any GUI environment) owns input.
---@return boolean
function shareUrl.isSendBlocked()
    return inFlightSeq ~= nil or ZO_DIALOG_SYNC_OBJECT:IsShown()
end

-- Decline evidence: cancelling the confirm dialog with B makes the internal
-- environment kick the ingame scene manager to the base scene
EVENT_MANAGER:RegisterForEvent("BattleScrollsShareUrlDecline", EVENT_REMOTE_SCENE_REQUEST,
    function(_, messageOrigin, requestType)
        if messageOrigin ~= SCENE_MANAGER_MESSAGE_ORIGIN_INTERNAL then
            return
        end
        if inFlightSeq and requestType == REMOTE_SCENE_REQUEST_TYPE_SHOW_BASE_SCENE then
            declineSeen = true
        end
    end)

---URL parts a byte stream will need once base64-coded (4 chars per 3 bytes,
---padded) and split at the selected size. Used to compare archive variants
---without materializing their base64.
---@param byteCount number
---@param chunkDataChars number
---@return number
local function partsForBytes(byteCount, chunkDataChars)
    local b64Len = math.ceil(byteCount / 3) * 4
    return math.max(1, math.ceil(b64Len / chunkDataChars))
end

---@param exportResult ExportResult
---@param chunkDataChars number
local function startChain(exportResult, chunkDataChars)
    local b64 = BattleScrolls.export.bytesToBase64(exportResult.bytes)
    local parts = {}
    for start = 1, #b64, chunkDataChars do
        parts[#parts + 1] = b64:sub(start, start + chunkDataChars - 1)
    end
    chain = {
        parts = parts,
        session = newSessionId(),
        lang = GetCVar("Language.2") or "en",
        nextSeq = 1,
        total = #parts,
    }
    setPhase("sending")
end

-- =============================================================================
-- PUBLIC ENTRY POINTS
-- =============================================================================

---Runs a build body on the shared build fiber with the common failure and
---cleanup handling.
---@param body fun()
local function runBuildFiber(body)
    setPhase("building")
    buildFiber = BattleScrolls.Effect.Async(body):Recover(function()
        chain = nil
        choiceFull = nil
        choiceBosses = nil
        setPhase("failed")
        return nil
    end):Ensure(function()
        buildFiber = nil
    end):Run()
end

---Shares one encounter (view profile) via the browser.
---@param instance InstanceStorage
---@param encounter CompactEncounter
function shareUrl.shareEncounter(instance, encounter)
    if shareUrl.isBusy() then
        return
    end
    shareUrl._sourceInstance = instance
    shareUrl._sourceEncounter = encounter
    local chunkDataChars = getChunkDataChars()
    runBuildFiber(function()
        startChain(BattleScrolls.export.buildEncounterShareAsync(instance, encounter):Await(), chunkDataChars)
    end)
end

---Uploads a whole instance (archive profile) via the browser. A mixed
---instance (bosses + trash) is built both full and bosses-only; when the
---URL part counts differ the chain waits in "choosing" for chooseVariant -
---trash usually dominates archive size, so the difference can be several
---browser round trips.
---@param instance InstanceStorage
function shareUrl.uploadInstance(instance)
    if shareUrl.isBusy() then
        return
    end
    shareUrl._sourceInstance = instance
    shareUrl._sourceEncounter = nil
    local chunkDataChars = getChunkDataChars()
    local bossCount, total = 0, 0
    for _, encounter in ipairs(instance.encounters or {}) do
        total = total + 1
        if next(encounter.bossesUnits or {}) ~= nil then
            bossCount = bossCount + 1
        end
    end
    runBuildFiber(function()
        local export = BattleScrolls.export
        local full = export.buildInstanceArchiveAsync(instance):Await()
        if bossCount == 0 or bossCount == total then
            startChain(full, chunkDataChars)
            return
        end
        local bosses = export.buildInstanceArchiveAsync(instance, true):Await()
        local fullParts = partsForBytes(#full.bytes, chunkDataChars)
        local bossParts = partsForBytes(#bosses.bytes, chunkDataChars)
        if bossParts == fullParts then
            startChain(full, chunkDataChars)
            return
        end
        choiceFull = { result = full, parts = fullParts, chunkDataChars = chunkDataChars }
        choiceBosses = { result = bosses, parts = bossParts, chunkDataChars = chunkDataChars }
        setPhase("choosing")
    end)
end

---Starts the chain for one of the offered archive variants.
---@param which "full"|"bosses"
function shareUrl.chooseVariant(which)
    if phase ~= "choosing" then
        return
    end
    local chosen = which == "bosses" and choiceBosses or choiceFull
    choiceFull = nil
    choiceBosses = nil
    if chosen then
        startChain(chosen.result, chosen.chunkDataChars)
    end
end
