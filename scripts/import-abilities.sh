#!/bin/bash
# Uploads a BattleScrollsAbilityDump SavedVariables file (abilities, items,
# champion skills, scribing scripts, Vengeance perks, skill lines, item sets,
# enchants and traits) into the share site's database.
#
# Usage: scripts/import-abilities.sh [path-to-BattleScrollsAbilityDump.lua]
#        scripts/import-abilities.sh --resume <batch-directory>
# Token: reads ~/.bs-share-import-token (worker secret IMPORT_TOKEN).
#
# Imports all accumulated language/class/version passes in one run. Each row
# keeps its client and API versions; repeating an import updates that version.
set -euo pipefail

SV_PATH="${1:-$HOME/Documents/Elder Scrolls Online/pts/SavedVariables/BattleScrollsAbilityDump.lua}"
HOST="https://bs.sheludchenkov.com"
TOKEN_FILE="${BS_IMPORT_TOKEN_FILE:-$HOME/.bs-share-import-token}"

if [ "${1:-}" != "--resume" ] && [ ! -f "$SV_PATH" ]; then
    echo "SavedVariables not found: $SV_PATH" >&2
    echo "Run /bsabilitydump in game and /reloadui first, or pass the path explicitly." >&2
    exit 1
fi
if [ ! -f "$TOKEN_FILE" ]; then
    echo "Import token missing: $TOKEN_FILE" >&2
    exit 1
fi

if [ "${1:-}" = "--resume" ]; then
    WORK_DIR="${2:?Pass the batch directory printed by the failed import}"
    [ -f "$WORK_DIR/ready" ] || { echo "No complete import batches in $WORK_DIR" >&2; exit 1; }
else
    WORK_DIR="$(mktemp -d)"
fi
cleanup() {
    local status=$?
    rm -f "$WORK_DIR/auth.header"
    if [ "$status" -eq 0 ] || [ ! -f "$WORK_DIR/ready" ]; then
        rm -rf "$WORK_DIR"
    else
        printf 'Batches retained. Resume with: %q --resume %q\n' "$0" "$WORK_DIR" >&2
    fi
}
trap cleanup EXIT

# SavedVariables is plain Lua: load it and emit JSON batches per kind
if [ "${1:-}" != "--resume" ]; then
lua5.4 - "$SV_PATH" "$WORK_DIR" <<'LUA'
local svPath, workDir = ...
dofile(svPath)
assert(BattleScrollsAbilityDumpSV, "BattleScrollsAbilityDumpSV missing in file")

local saved = BattleScrollsAbilityDumpSV
assert(saved.formatVersion == 2 and type(saved.datasets) == "table" and #saved.datasets > 0,
    "Expected an additive format-2 dump. Run the updated miner from scratch.")
-- Validate every dataset before emitting anything or starting the upload.
for _, dataset in ipairs(saved.datasets) do
    assert(type(dataset.gameVersion) == "string" and dataset.gameVersion:match("%d+%.%d+%.%d+"), "Missing game version")
    assert(type(dataset.apiVersion) == "number" and dataset.apiVersion > 0
        and dataset.apiVersion % 1 == 0, "Missing API version")
    assert(type(dataset.language) == "string" and dataset.language:match("^%l%l$"), "Missing language")
end

local function jsonEscape(s)
    s = s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
    return (s:gsub("[%z\1-\31]", function(c) return string.format("\\u%04x", c:byte()) end))
end

-- ESO inline color markup (|cRRGGBB ... |r) has no place in the database
local function stripMarkup(s)
    return (s:gsub("|c%x%x%x%x%x%x", ""):gsub("|r", ""))
end

local function split(line)
    local fields = {}
    for field in (line .. "\t"):gmatch("([^\t]*)\t") do
        fields[#fields + 1] = field
    end
    return fields
end

-- Mechanics have no language. Merge in the same order as the original imports,
-- retaining IDs unique to any language and the last value for repeated IDs.
local mechanicsByVersion = {}
for index, dataset in ipairs(saved.datasets) do
    local entry = mechanicsByVersion[dataset.gameVersion] or {rows={}}
    for id, row in pairs(dataset.abilities or {}) do entry.rows[id] = row end
    entry.lastIndex = index
    mechanicsByVersion[dataset.gameVersion] = entry
end

local manifest = assert(io.open(workDir .. "/requests.tsv", "w"))
local BATCH = 4000
local function emitDataset(dump, datasetIndex)
local metadata = string.format('"lang":"%s","gameVersion":"%s","apiVersion":%d',
    dump.language, jsonEscape(dump.gameVersion), dump.apiVersion)
print(string.format("Dataset %d: %s · %s · API %d", datasetIndex, dump.language, dump.gameVersion, dump.apiVersion))

-- `envelope` wraps the comma-joined item list into the endpoint's payload
local function emitBatchesAs(filePrefix, rows, mapRow, envelope)
    local batch, batchIdx, fileIdx = {}, 0, 0
    local function flush()
        if batchIdx == 0 then return end
        fileIdx = fileIdx + 1
        local name = string.format("%s_%03d_%03d.json", filePrefix, datasetIndex, fileIdx)
        local f = assert(io.open(workDir .. "/" .. name, "w"))
        assert(f:write(envelope(table.concat(batch, ",", 1, batchIdx))))
        assert(f:close())
        assert(manifest:write(name, "\t", filePrefix:match("^defs%-") and "defs" or filePrefix, "\t", batchIdx, "\n"))
        batchIdx = 0
    end
    local total = 0
    local keys = {}
    for key in pairs(rows or {}) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local json = mapRow(split(rows[key]))
        if json then
            total = total + 1
            batchIdx = batchIdx + 1
            batch[batchIdx] = json
            if batchIdx >= BATCH then flush() end
        end
    end
    flush()
    print(string.format("%s: %d rows in %d batches", filePrefix, total, fileIdx))
end

local function emitBatches(kind, rows, mapRow)
    emitBatchesAs(kind, rows, mapRow, function(items)
        return string.format('{%s,"%s":[%s]}', metadata, kind, items)
    end)
end

-- The generic defs store: every kind shares one endpoint and one row shape, so
-- the kind travels inside the payload and the file name carries it to curl.
local function emitDefs(defKind, rows)
    emitBatchesAs("defs-" .. defKind, rows, function(f)
        local id, name = tonumber(f[1]), f[2]
        if not id or not name or name == "" then return nil end
        local fields = { string.format('"id":%d,"name":"%s"', id, jsonEscape(name)) }
        local tooltip = stripMarkup(f[4] or "")
        if tooltip ~= "" then
            fields[#fields + 1] = string.format('"tooltip":"%s"', jsonEscape(tooltip))
        end
        if (f[3] or "") ~= "" then
            fields[#fields + 1] = string.format('"icon":"%s"', jsonEscape(f[3]))
        end
        return "{" .. table.concat(fields, ",") .. "}"
    end, function(items)
        return string.format('{%s,"kind":"%s","defs":[%s]}', metadata, defKind, items)
    end)
end

emitBatches("abilities", dump.abilities, function(f)
    local id, name, icon, tooltip = tonumber(f[1]), f[2], f[3], f[4]
    if not id or not name or name == "" then return nil end
    local craftedId = tonumber(f[16])
    local craftedField = craftedId and string.format(',"craftedAbilityId":%d', craftedId) or ""
    return string.format('{"id":%d,"name":"%s","icon":"%s","tooltip":"%s"%s}',
        id, jsonEscape(name), jsonEscape(icon or ""),
        jsonEscape(stripMarkup(tooltip or "")), craftedField)
end)

-- Exact valid recipes, not a concatenation of the generic script definitions.
emitBatches("scribing", dump.combinations, function(f)
    local craftedId, primary, secondary, tertiary, classId = tonumber(f[1]), tonumber(f[2]), tonumber(f[3]), tonumber(f[4]), tonumber(f[5])
    if not (craftedId and primary and secondary and tertiary and classId and f[6] and f[6] ~= "") then return nil end
    return string.format('{"craftedAbilityId":%d,"scriptIds":[%d,%d,%d],"classId":%d,"name":"%s","icon":"%s","tooltip":"%s"}',
        craftedId, primary, secondary, tertiary, classId, jsonEscape(f[6]), jsonEscape(f[7] or ""), jsonEscape(stripMarkup(f[8] or "")))
end)

-- Mechanics ride along in the ability rows. All language-neutral. Damage
-- type and dot/direct classification deliberately do NOT come from here:
-- component ids share names/descriptions with their parent cast (Force Pulse
-- is five ids), so text can't classify them. Each share carries its own
-- classification from the instance's recorded abilityInfo (export wire v2);
-- the tick interval here is informational.
local mechanics = mechanicsByVersion[dump.gameVersion]
if mechanics.lastIndex == datasetIndex then
emitBatches("mechanics", mechanics.rows, function(f)
    assert(#f >= 16, "Incomplete ability row")
    local id = tonumber(f[1])
    if not id then return nil end
    local duration, freq = tonumber(f[5]) or 0, tonumber(f[6]) or 0
    local castMs, channelMs = tonumber(f[7]) or 0, tonumber(f[8]) or 0
    local channeled, passive = tonumber(f[9]) or 0, tonumber(f[10]) or 0
    local ultimate, buffType = tonumber(f[11]) or 0, tonumber(f[12]) or 0
    local roles = tonumber(f[13]) or 0
    local radius, range = tonumber(f[14]) or 0, tonumber(f[15]) or 0

    -- Keep zero-valued mechanics: a newer version can remove an old duration.
    return string.format(
        '{"id":%d,"durationMs":%d,"tickMs":%d,"castMs":%d,"channelMs":%d,"channeled":%d,"passive":%d,"ultimate":%d,"buffType":%d,"roles":%d,"radiusCm":%d,"rangeCm":%d}',
        id, duration, freq, castMs, channelMs, channeled, passive, ultimate,
        buffType, roles, radius, range)
end)
end

emitBatches("items", dump.items, function(f)
    local id, name = tonumber(f[1]), f[2]
    if not id or not name or name == "" then return nil end
    return string.format(
        '{"id":%d,"name":"%s","icon":"%s","setName":"%s","trait":%d,"armorType":%d,"weaponType":%d,"equipType":%d,"setId":%d}',
        id, jsonEscape(name), jsonEscape(f[3] or ""), jsonEscape(f[4] or ""),
        tonumber(f[5]) or -1, tonumber(f[6]) or 0, tonumber(f[7]) or 0, tonumber(f[8]) or 0,
        tonumber(f[9]) or 0)
end)

emitBatches("champion", dump.champion, function(f)
    local id, name = tonumber(f[1]), f[2]
    if not id or not name or name == "" then return nil end
    return string.format('{"id":%d,"name":"%s","disciplineId":%d,"tooltip":"%s"}',
        id, jsonEscape(name), tonumber(f[3]) or 0, jsonEscape(stripMarkup(f[5] or "")))
end)

-- id / name / icon / tooltip rows, straight into the defs store
emitDefs("script", dump.scripts)
emitDefs("perk", dump.perks)
emitDefs("trait", dump.traits)
emitDefs("skillline", dump.skilllines)
emitDefs("set", dump.sets)
emitDefs("enchant", dump.enchants)
end

for index, dataset in ipairs(saved.datasets) do emitDataset(dataset, index) end
assert(manifest:close())
assert(assert(io.open(workDir .. "/ready", "w")):close())
LUA
fi

# curl reads the authorization header from a private file, not process arguments.
umask 077
printf 'authorization: Bearer %s\n' "$(cat "$TOKEN_FILE")" > "$WORK_DIR/auth.header"
post() {
    local name="$1" endpoint="$2" expected="$3" status attempt response
    local file="$WORK_DIR/$name"
    [ -f "$file.done" ] && return 0
    for attempt in 1 2 3 4 5; do
        status=$(curl -sS --connect-timeout 15 --max-time 120 -X POST "$HOST/api/$endpoint/import" \
            -H "content-type: application/json" -H "@$WORK_DIR/auth.header" \
            --data-binary @"$file" -o "$file.response" -w '%{http_code}') || status=000
        response=$(cat "$file.response" 2>/dev/null || true)
        if [ "$status" = 200 ] && [[ "$response" =~ ^\{\"imported\":([0-9]+)\}$ ]] && [ "${BASH_REMATCH[1]}" = "$expected" ]; then
            touch "$file.done"
            echo "$name: $response"
            return 0
        fi
        case "$status" in
            000|408|429|5??) echo "$name: HTTP $status, attempt $attempt/5" >&2 ;;
            *) echo "$name: HTTP $status: $response" >&2; return 1 ;;
        esac
        [ "$attempt" -eq 5 ] || sleep "$((attempt * 2))"
    done
    echo "$name: retries exhausted: $response" >&2
    return 1
}

# Four independent batches at a time; finish in-flight requests before stopping.
# Completed receipts make retrying an interrupted import safe and inexpensive.
pids=()
wait_batch() {
    local pid failed=0
    for pid in "${pids[@]}"; do wait "$pid" || failed=1; done
    pids=()
    return "$failed"
}
while IFS=$'\t' read -r name endpoint expected; do
    [ -f "$WORK_DIR/$name.done" ] && continue
    post "$name" "$endpoint" "$expected" &
    pids+=("$!")
    if [ "${#pids[@]}" -eq 4 ]; then wait_batch || exit 1; fi
done < "$WORK_DIR/requests.tsv"
if [ "${#pids[@]}" -gt 0 ]; then wait_batch || exit 1; fi
rm -f "$WORK_DIR/auth.header"
echo "Import complete (all accumulated datasets)."
