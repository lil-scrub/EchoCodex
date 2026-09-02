-- Echo Codex: INFERRED Tome sources.
--
-- Everything in this file is DERIVED, not sourced. It is kept separate from
-- Data/Tomes.lua on purpose: that file is a verbatim snapshot of the
-- community "World of Echoes" farming map, and mixing derivations into it
-- would destroy the one useful property it has -- that every row in it came
-- from someone who actually saw the drop.
--
-- WHY THIS FILE EXISTS
-- Project Ebonhold's own Echo data flags 148 Echoes as Tome-locked. The
-- farming map covers 128 Tomes. The 20 Echoes below are the difference: real,
-- learnable, Tome-locked Echoes that no published source says anything about.
-- Checked 2026-09-01 against all three:
--   * project-ebonhold.com /assets/dbc/echoes.json -- flags "tome": true but
--     carries no location field at all, for any Echo.
--   * worldofechoes.pages.dev /assets/data/tomes.json -- 128 Tomes, 173
--     location rows, none of them these.
--   * EbonholdHub's EchoMapData.lua -- embeds that same map data (its own
--     SOURCE_URL points at worldofechoes).
--
-- HOW THESE WERE DERIVED
-- Three independent signals agree, which is why this is worth shipping at
-- all rather than leaving the rows blank:
--   1. These 20 hold groupIds 286-305 -- the highest 20 of 305 in the entire
--      database, i.e. the newest content tier, which is exactly the tier a
--      crowd-sourced map would lag on.
--   2. Their Echo ids run in strict Icecrown Citadel boss order, then strict
--      Ruby Sanctum boss order.
--   3. Each one's effect text quotes its boss's signature ability verbatim
--      (see the `basis` field on each row).
-- The pattern itself is confirmed by rows we DO have from the map: Sapphiron
-- drops Chill of the Bone Wyrm, Kel'Thuzad drops Call of the Lich King,
-- Sartharion drops Cinders of the Sanctum. Project Ebonhold's own help page
-- states the rule outright: "Broodmother's Fury can be found on Onyxia".
--
-- WHAT IS DELIBERATELY ABSENT
-- No x/y map coordinates. Those cannot be derived from anything above, and a
-- plausible-looking wrong pin is worse than no pin. Zone and place name are
-- as far as the inference actually reaches.
--
-- Keyed by ECHO id, not Tome id -- these Echoes have no Tome record to key
-- against; that absence is the whole reason this file exists. If the map ever
-- covers one, delete its row here: Data/Tomes.lua always wins (see
-- ResolveTome in Tabs/Tab_MissingTomes.lua).

EchoCodexInferredLocations = {
  -- Icecrown Citadel, in encounter order.
  [201340] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"Lord Marrowgar"},
               basis="Effect text leaves Coldflame in your wake -- Marrowgar's signature ability." },
  [201344] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"Lady Deathwhisper"},
               basis="Named for the boss; grants Mana Barrier, her signature ability." },
  [201348] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"Icecrown Gunship Battle"},
               basis="Named for the encounter; calls down Cannon Blast." },
  [201354] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"Deathbringer Saurfang"},
               basis="Blood-themed execute effect at the Saurfang slot in encounter order. Weaker than the rest: position, not quoted ability text.",
               confidence="low" },
  [201356] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"Festergut"},
               basis="Inhaled Blight is Festergut's own ability name." },
  [201360] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"Rotface"},
               basis="Slime Spray is Rotface's own ability name." },
  [201366] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"Professor Putricide"},
               basis="Malleable Goo is Putricide's own ability name." },
  [201370] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"Blood Prince Council (Prince Valanar)"},
               basis="Shock Vortex is Valanar's ability." },
  [201378] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"Blood Prince Council (Prince Taldaram)"},
               basis="Dark Nucleus is Taldaram's ability." },
  [201382] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"Blood Prince Council (Prince Keleseth)"},
               basis="Conjured Flame is Keleseth's ability." },
  [201388] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"Blood-Queen Lana'thel"},
               basis="Blood Mirror is Lana'thel's own ability name." },
  [201394] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"Valithria Dreamwalker"},
               basis="Emerald Vigor is the Dream Portal buff from that encounter." },
  [201398] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"Sindragosa"},
               basis="Permeating Chill is Sindragosa's own ability name." },
  [201402] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"The Lich King"},
               basis="Defile is the Lich King's own ability name." },
  [201406] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"The Lich King"},
               basis="Necrotic Plague is the Lich King's own ability name." },
  [201410] = { zone="northrend", placeName="Icecrown - Icecrown Citadel", mobs={"The Lich King"},
               basis="Effect text marks enemies with Harvest Soul -- the Lich King's Frostmourne mechanic." },

  -- Ruby Sanctum, in encounter order.
  [201416] = { zone="northrend", placeName="Dragonblight - Ruby Sanctum", mobs={"Baltharus the Warborn"},
               basis="Effect text summons a Warborn Reflection and unleashes Blade Tempest -- both Baltharus's." },
  [201420] = { zone="northrend", placeName="Dragonblight - Ruby Sanctum", mobs={"General Zarithrian"},
               basis="Armor-sundering cleave at Zarithrian's slot in encounter order; he casts Cleave Armor. The weakest inference in this file -- no verbatim ability name.",
               confidence="low" },
  [201424] = { zone="northrend", placeName="Dragonblight - Ruby Sanctum", mobs={"Saviana Ragefire"},
               basis="Flame Beacon is Saviana's ability name, and the effect text releases a Conflagration -- also hers." },
  [201428] = { zone="northrend", placeName="Dragonblight - Ruby Sanctum", mobs={"Halion"},
               basis="Effect text names Fiery Combustion and Soul Consumption and opens a Twilight Rift -- all three are Halion's." },
}
