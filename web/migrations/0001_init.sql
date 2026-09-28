-- Blob-centric on purpose: a share is one opaque export stream plus the few
-- fields needed to list/serve it. Encounters are never decomposed into rows.

CREATE TABLE shares (
    id TEXT PRIMARY KEY,
    created_at INTEGER NOT NULL,
    profile INTEGER NOT NULL, -- 1 view, 2 archive
    title TEXT NOT NULL,
    encounter_count INTEGER NOT NULL,
    payload BLOB NOT NULL,
    platform TEXT CHECK (platform IN ('pc', 'xbox', 'playstation')), -- Device running the exporting client; NULL if unknown.
    world_name TEXT
);

-- In-flight multi-URL uploads: one row per received chunk, assembled and
-- deleted when the last chunk arrives. Stale sessions are swept opportunistically.
CREATE TABLE upload_chunks (
    session_id TEXT NOT NULL,
    idx INTEGER NOT NULL,
    total INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    data BLOB NOT NULL,
    PRIMARY KEY (session_id, idx)
);

-- Candidate names, not verified identities: the export's dictionary includes
-- player handles, character names and NPC names. There is no public lookup API.
CREATE TABLE share_names (
    share_id TEXT NOT NULL REFERENCES shares(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    name_key TEXT NOT NULL,
    PRIMARY KEY (share_id, display_name)
);
CREATE INDEX share_names_lookup ON share_names(name_key, share_id);

-- Versioned game metadata. Current views select the newest client version
-- per entity and language; version_order sorts numeric release/build parts.
CREATE TABLE abilities (
    id INTEGER NOT NULL,
    lang TEXT NOT NULL,
    name TEXT NOT NULL,
    icon TEXT,
    tooltip TEXT,
    crafted_ability_id INTEGER,
    game_version TEXT NOT NULL CHECK (length(game_version) > 0),
    api_version INTEGER NOT NULL CHECK (api_version > 0),
    version_order TEXT NOT NULL,
    PRIMARY KEY (id, lang, game_version)
);
CREATE INDEX idx_abilities_current ON abilities (id, lang, version_order DESC, game_version DESC);
CREATE VIEW abilities_current AS
SELECT row.* FROM abilities AS row
WHERE NOT EXISTS (
    SELECT 1 FROM abilities AS newer
    WHERE newer.id = row.id AND newer.lang = row.lang
      AND (newer.version_order, newer.game_version) > (row.version_order, row.game_version)
);

CREATE TABLE items (
    id INTEGER NOT NULL,
    lang TEXT NOT NULL,
    name TEXT NOT NULL,
    icon TEXT,
    set_name TEXT,
    trait INTEGER,
    armor_type INTEGER,
    weapon_type INTEGER,
    equip_type INTEGER,
    set_id INTEGER,
    game_version TEXT NOT NULL CHECK (length(game_version) > 0),
    api_version INTEGER NOT NULL CHECK (api_version > 0),
    version_order TEXT NOT NULL,
    PRIMARY KEY (id, lang, game_version)
);
CREATE INDEX idx_items_current ON items (id, lang, version_order DESC, game_version DESC);
CREATE VIEW items_current AS
SELECT row.* FROM items AS row
WHERE NOT EXISTS (
    SELECT 1 FROM items AS newer
    WHERE newer.id = row.id AND newer.lang = row.lang
      AND (newer.version_order, newer.game_version) > (row.version_order, row.game_version)
);

CREATE TABLE champion_skills (
    id INTEGER NOT NULL,
    lang TEXT NOT NULL,
    name TEXT NOT NULL,
    discipline_id INTEGER,
    tooltip TEXT,
    game_version TEXT NOT NULL CHECK (length(game_version) > 0),
    api_version INTEGER NOT NULL CHECK (api_version > 0),
    version_order TEXT NOT NULL,
    PRIMARY KEY (id, lang, game_version)
);
CREATE INDEX idx_champion_skills_current ON champion_skills (id, lang, version_order DESC, game_version DESC);
CREATE VIEW champion_skills_current AS
SELECT row.* FROM champion_skills AS row
WHERE NOT EXISTS (
    SELECT 1 FROM champion_skills AS newer
    WHERE newer.id = row.id AND newer.lang = row.lang
      AND (newer.version_order, newer.game_version) > (row.version_order, row.game_version)
);

CREATE TABLE ability_mechanics (
    id INTEGER NOT NULL,
    duration_ms INTEGER,
    tick_ms INTEGER,
    cast_ms INTEGER,
    channel_ms INTEGER,
    channeled INTEGER,
    passive INTEGER,
    ultimate INTEGER,
    buff_type INTEGER,
    roles INTEGER,
    radius_cm INTEGER,
    range_cm INTEGER,
    aoe INTEGER,
    game_version TEXT NOT NULL CHECK (length(game_version) > 0),
    api_version INTEGER NOT NULL CHECK (api_version > 0),
    version_order TEXT NOT NULL,
    PRIMARY KEY (id, game_version)
);
CREATE INDEX idx_ability_mechanics_current ON ability_mechanics (id, version_order DESC, game_version DESC);
CREATE VIEW ability_mechanics_current AS
SELECT row.* FROM ability_mechanics AS row
WHERE NOT EXISTS (
    SELECT 1 FROM ability_mechanics AS newer
    WHERE newer.id = row.id
      AND (newer.version_order, newer.game_version) > (row.version_order, row.game_version)
);

CREATE TABLE defs (
    kind TEXT NOT NULL,
    id INTEGER NOT NULL,
    lang TEXT NOT NULL,
    name TEXT,
    tooltip TEXT,
    icon TEXT,
    game_version TEXT NOT NULL CHECK (length(game_version) > 0),
    api_version INTEGER NOT NULL CHECK (api_version > 0),
    version_order TEXT NOT NULL,
    PRIMARY KEY (kind, id, lang, game_version)
);
CREATE INDEX idx_defs_current ON defs (kind, id, lang, version_order DESC, game_version DESC);
CREATE VIEW defs_current AS
SELECT row.* FROM defs AS row
WHERE NOT EXISTS (
    SELECT 1 FROM defs AS newer
    WHERE newer.kind = row.kind AND newer.id = row.id AND newer.lang = row.lang
      AND (newer.version_order, newer.game_version) > (row.version_order, row.game_version)
);

CREATE TABLE scribed_abilities (
    crafted_ability_id INTEGER NOT NULL,
    primary_script_id INTEGER NOT NULL,
    secondary_script_id INTEGER NOT NULL,
    tertiary_script_id INTEGER NOT NULL,
    class_id INTEGER NOT NULL DEFAULT 0,
    lang TEXT NOT NULL,
    name TEXT NOT NULL,
    icon TEXT,
    tooltip TEXT,
    game_version TEXT NOT NULL CHECK (length(game_version) > 0),
    api_version INTEGER NOT NULL CHECK (api_version > 0),
    version_order TEXT NOT NULL,
    PRIMARY KEY (crafted_ability_id, primary_script_id, secondary_script_id, tertiary_script_id, class_id, lang, game_version)
);
CREATE INDEX idx_scribed_abilities_current ON scribed_abilities (crafted_ability_id, primary_script_id, secondary_script_id, tertiary_script_id, class_id, lang, version_order DESC, game_version DESC);
CREATE VIEW scribed_abilities_current AS
SELECT row.* FROM scribed_abilities AS row
WHERE NOT EXISTS (
    SELECT 1 FROM scribed_abilities AS newer
    WHERE newer.crafted_ability_id = row.crafted_ability_id AND newer.primary_script_id = row.primary_script_id AND newer.secondary_script_id = row.secondary_script_id AND newer.tertiary_script_id = row.tertiary_script_id AND newer.class_id = row.class_id AND newer.lang = row.lang
      AND (newer.version_order, newer.game_version) > (row.version_order, row.game_version)
);

CREATE INDEX idx_abilities_lang_name ON abilities (lang, name);
