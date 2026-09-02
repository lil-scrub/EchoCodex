Echo Codex
==========

An in-game addon for Project Ebonhold (WotLK 3.3.5) that lets you search every
Echo (name AND description, unlike the website's search), build a wishlist,
and check off Tomes as you find them -- with drop locations included.

INSTALL
-------
1. Unzip this so you end up with a folder literally named "EchoCodex"
   containing EchoCodex.toc, Core.lua, and the Data/ folder.
2. Drop that "EchoCodex" folder into:
     World of Warcraft\Interface\AddOns\
   (so the .toc file is at ...\AddOns\EchoCodex\EchoCodex.toc)
3. Restart WoW / reload UI, and make sure "Echo Codex" is checked at the
   AddOns list on the character-select screen.

USE
---
/eco  or  /echocodex   opens the window (same command closes it, ESC also works)

/eco cleanup  (or "/eco prune") -- drops every wishlist item that's learned
automatically while leveling (no Tome to farm for those, so there's nothing
for the Missing Tomes list to track). Command-only, no button for it in the
window.

Browse tab
  - Type in the search box to match against BOTH the Echo name and its full
    effect description (e.g. search "movement speed" or "execute").
  - Filter by class, role, quality, or Tome-locked-only.
  - Hover an Echo for its full tooltip. Click "Add" to put it on your wishlist.

Wishlist tab
  - Multiple named wishlists, per character. Each character you play keeps
    its own separate set of wishlists (a Warlock alt and a Priest alt never
    share one) -- switch between them with the "Wishlist:" dropdown at the
    top, or make more with "New" (Rename/Delete are there too). Everything
    below -- items, the Missing Tomes list and its found-Tome checkmarks -- belongs
    to whichever wishlist is currently selected.
  - Everything you've added. Remove anything you change your mind on.
  - Import from Echo Journal / EbonholdHub / Nexus: paste an export string
    and click Import to add every Echo it references to your wishlist in
    one go. Accepts four formats:
      EWL1:...    the wishlist export from the server's own Echo Journal
                  (spellbook Echoes tab / ProjectEbonhold addon)
      EBH1:...    a plain-text loadout export -- from the Echo Journal, OR
                  from Nexus's Wishlist Editor ("Export" button, top right
                  of that panel -- it targets this exact same EBH1 shape on
                  purpose, so it needed no special-casing here)
      (base64)    an EbonholdHub Build export -- get this from EITHER:
                    - the "Export" button in the footer bar while editing a
                      Build (Talents/Gear/Echoes/Automation tabs), or
                    - the "Copy export for site" button on the Build
                      Overview page (top of the stats area)
                  Both open the same export dialog; the text is already
                  selected, so Ctrl+C copies it, then Ctrl+V into Echo
                  Codex's import box. This format needs EbonholdHub to
                  still be installed/loaded to decode (Echo Codex hands it
                  to EbonholdHub's own decoder rather than reimplementing
                  base64+JSON) -- if EbonholdHub isn't loaded, you'll get an
                  error saying so instead of a silent failure.
    Only the Echo IDs are read out -- tiers, locked slots, talents, gear,
    etc. are ignored either way. IDs the addon doesn't recognize (stale data
    snapshot, or not an Echo) are reported but skipped rather than guessed at.
    This import box only ever adds to Echo Codex's own wishlist. Earlier
    builds could get an "Import to EbonholdHub" button grafted onto this
    box by EbonholdHub's own cross-addon hook, which scans other addons'
    windows for anything holding EWL/EBH-formatted text; the window is now
    named so that scanner skips it.
  - "Export" button: the reverse of Import -- produces an EBH1 string for
    the current wishlist (already selected in the popup, Ctrl+A/Ctrl+C to
    copy) that pastes straight into Nexus's own Import dialog, EbonholdHub,
    or the Echo Journal.

Missing Tomes tab
  - Auto-populates from your wishlist: just the Echoes that require learning
    a Tome.
  - Auto-clears: once an entry is known (auto-detected, see "Known Echo
    detection" below), it drops off this list by default -- decluttered
    down to just what you still need. Nothing is deleted: it's still on
    your wishlist and still counted, just hidden from view. Tick "Show
    completed" (top right) to bring finished entries back. There's no
    manual checkbox -- if auto-detection ever misses one, it'll stay
    listed rather than silently disappear.
  - Hover a row to see the drop location(s): zone, spot, mobs, and any
    notes. Entries with a Tome we don't have a location for yet are marked
    "Location not documented yet."
  - Three different kinds of row, kept visually distinct so you always know
    how much to trust what you're reading:
      normal (white)             a location the farming map documents.
      "Location not documented    we know which Tome you need, the map just
       yet" (grey)                hasn't mapped where it drops.
      "... (inferred)" (tan)      NOT from the map. Our own derivation --
                                  see INFERRED TOME SOURCES below.
      "No Tome recorded in this   the Echo is flagged Tome-locked, we have
       data snapshot" (brown)     no Tome row AND no inference for it.
    Membership of this list is decided by the Echo's own Tome-locked flag,
    NOT by the Echo->Tome table: those are two separate snapshots and the
    Tome one has thinner coverage (currently 128 Tomes against 148
    Tome-locked Echoes). Gating on the Echo->Tome table instead used to hide
    exactly those 20 -- the ones you can't look up in the addon anywhere
    else either -- and worse, counted them in the footer as "learned
    automatically, no Tome needed".

INFERRED TOME SOURCES
---------------------
Data/TomesInferred.lua covers the 20 Tome-locked Echoes that NO published
source says anything about. Checked 2026-09-01 against all three:
  * project-ebonhold.com's own /assets/dbc/echoes.json -- flags "tome": true
    but carries no location field at all, for any Echo.
  * worldofechoes.pages.dev /assets/data/tomes.json -- 128 Tomes, 173
    location rows, none of them these. Our Data/Tomes.lua is already an exact
    match for it, so re-snapshotting will NOT fill these in.
  * EbonholdHub's own EchoMapData.lua -- embeds that same map data.

So these rows are derived, and are labelled "(inferred)" everywhere they
appear. Three signals agree:
  1. The 20 hold groupIds 286-305 -- the highest 20 of 305 in the whole
     database, i.e. the newest content tier, exactly what a crowd-sourced
     map lags on.
  2. Their Echo ids run in strict Icecrown Citadel boss order, then strict
     Ruby Sanctum boss order.
  3. Each one's effect text quotes its boss's signature ability verbatim
     (Coldflame, Mana Barrier, Malleable Goo, Permeating Chill, Harvest
     Soul, Warborn Reflection, Fiery Combustion...). Each row records its
     own evidence in a `basis` field, shown in the tooltip.
The pattern is confirmed by rows the map DOES have: Sapphiron drops Chill of
the Bone Wyrm, Kel'Thuzad drops Call of the Lich King, Sartharion drops
Cinders of the Sanctum. Ebonhold's own help page states the rule outright:
"Broodmother's Fury can be found on Onyxia".

Two rows (Scent of Blood -> Deathbringer Saurfang, Sundered Formation ->
General Zarithrian) rest on encounter-order position rather than a quoted
ability name. Those carry confidence="low" and say so in the tooltip.

No x/y coordinates are recorded, deliberately -- those can't be derived, and
a plausible-looking wrong pin is worse than no pin.

Sourced data always wins: if Data/Tomes.lua ever gains a real row for one of
these, the inferred one goes quiet automatically. Delete it at that point --
there's a test that fails if an inferred row outlives its usefulness.

KNOWN ECHO DETECTION
---------------------
Echo Codex reads ProjectEbonhold.PerkService.GetDiscoveredEchoes() as the
main signal -- this is the "ever-obtained, cross-run" record, confirmed by
reading the Nexus addon's own code (it documents this exact field for the
exact same purpose, and notes the server's own Echo Journal gates its
Tome-disable toggle on it). A Tome's discovery can register against one
quality tier's spell id while our data references a sibling tier of the
same Tome -- handled by cross-referencing ProjectEbonhold.PerkDatabase's
groupId, same as Nexus does.

GetGrantedPerks()/GetLockedPerks() (what an earlier build relied on before
GetDiscoveredEchoes was found) only ever reflect the CURRENT run's active
picks, not everything you've permanently unlocked -- kept as a fallback
signal for auto-learned (non-Tome) Echoes, which have no Tome/discovery
record at all. A spellbook "Echoes" tab was also tried early on, on the
assumption that's where learned Tomes show up; that tab doesn't exist on
this account/server, so that path is dead code, left in only in case it's
real for a different class/spec ("/eco debug" reports foundEchoesTab).

Refreshed: every time you switch to the Missing Tomes tab (always immediate),
and live while the window is open -- listening for SPELLS_CHANGED,
LEARNED_SPELL_IN_TAB, and the Echo Journal's own OnDataChanged callback
(hooked the same way EbonholdHub hooks it), debounced to one refresh per
~0.75s so it can't cause the mount/dismount-spam stutter EbonholdHub's own
changelog describes hitting from handling SPELLS_CHANGED naively.

Browse and Wishlist rows get a green "Known" tag for Echoes you already
have, in any quality. Missing Tomes entries for Echoes you already know get
auto-cleared off the list -- see the Missing Tomes tab notes above.

Note: the game's own Echo Journal browser highlights Echoes you've
tiered/wishlisted there too, in the same visual style as owned ones -- don't
mistake that for an ownership indicator when comparing against Echo Codex.
The Journal's left-hand "my Echoes" panel is the actual owned list.

DEBUG / SEARCH COMMANDS
-------------------------
"/eco debug" dumps a full diagnostic snapshot into EchoCodexDB.lastDebug --
which data sources exist, how many entries each has, and how many Echoes
ended up marked known overall.

"/eco debug <search term>" does all of the above plus a case-insensitive
search for that term across every source (our own data, PerkDatabase,
granted/locked perks, cachedPerkCounts) and reports exactly where -- or
whether -- it turns up. Use this to check one specific Echo/Tome by name
when something looks wrong, e.g. "/eco debug Accelerated Decay".

Either way: WoW only writes SavedVariables to disk on /reload or logout, so
the flow is always: run the command, /reload, then read
WTF\Account\<ACCOUNT>\SavedVariables\EchoCodex.lua -- the file is easier to
read there than to copy out of the in-game chat log.

This is best-effort: none of this is a published API, just what
EbonholdHub's own code does and what testing against a real account
confirmed. If a server patch changes these tables' shape, detection can
silently miss things rather than error -- rerun "/eco debug" if Known tags
stop looking right.

SOURCE LAYOUT
--------------
Load order is set in EchoCodex.toc; Init.lua must come first because it
creates the shared namespace (`ns`) the other files read from, using WoW's
own private per-addon table -- nothing is added to _G. Paths in the .toc use
backslashes, which is what the client's parser expects for subdirectories.

  Data/         Echoes.lua, Tomes.lua -- static snapshots (auto-generated;
                do not hand-edit). TomesInferred.lua -- hand-written
                derivations, kept out of the snapshots on purpose so a
                regeneration can't silently launder them into sourced data.
  Init.lua      namespace, constants, theme, the tab registry
  Widgets.lua   flat button / checkbox / scrolling list primitives
  DB.lua        saved variables
  Util.lua      filtering, formatting, tooltips
  Ownership.lua what you own and what's in this run's build
  Debug.lua     "/eco debug" reporting
  ImportExport.lua  EWL1 / EBH1 / EbonholdHub Build parsing
  Wishlists.lua the named wishlists, their popups, and the Wishlist tab
  Tabs/         one file per tab; each registers itself in ns.tabs
    Tab_Browse.lua, Tab_MissingTomes.lua, Tab_CurrentBuild.lua
  Core.lua      main frame, live refresh, loader, slash commands

Tabs don't expose their widgets. Each registers a small table in ns.tabs
(label / build / onSelect / refresh / resetScroll) and Core.lua drives them
through that, so no file reaches into another's frames.

PACKAGING
---------
  ./tools/package.sh [output-dir]      (default: ~/Downloads)

Builds EchoCodex-<version>.zip, taking the version and the file list from
EchoCodex.toc rather than a glob -- a glob silently drops files when the
layout changes, producing a zip that looks right but fails to load.

Convention: values assigned once (constants, functions) are re-localized at
the top of each file that uses them. Values REASSIGNED at runtime --
ns.charDB and the two active-wishlist pointers, which are swapped whenever
the active wishlist changes -- must always be read through `ns.` at the
point of use, or a file-local copy goes stale on the next switch.

TESTS
-----
  ./tests/run.sh

Runs under Lua 5.1 (the version the 3.3.5 client ships, so a construct that
passes here parses in-game) against a stubbed WoW API in tests/wow_mock.lua.
Syntax-checks every file, then exercises ownership/tier detection, wishlist
CRUD, EBH import/export round-trips, filtering, and data integrity.

The ownership fixtures are real captures from "/eco debug" read back out of
SavedVariables, including the two quirks that caused actual bugs: an Echo
reporting the same spellId across two stacks, and one reporting two
DIFFERENT quality tiers across stacks that are the same tier in-game. Those
cases are pinned by tests specifically, and the tests were verified to fail
when the fixes are reverted -- a test that cannot fail is not protecting
anything.

DATA / ACCURACY
----------------
Echo data is a snapshot pulled from Project Ebonhold's own Echo Builder tool
(https://project-ebonhold.com/tools/echo-builder). Tome drop locations come
from the community-run "World of Echoes" farming map
(https://worldofechoes.pages.dev/), which has partial coverage -- some Tomes
aren't mapped yet, and you'll see "Location not documented yet" for those.

Both are point-in-time snapshots. If Ebonhold patches Echoes or someone maps
a new Tome location, this addon won't know until it's rebuilt against fresh
data -- it does not phone home or auto-update (no addon does, on a private
server or otherwise).

The exception is Data/TomesInferred.lua, which is NOT sourced from either:
it is our own derivation for the 20 Tome-locked Echoes no published source
covers, and everything from it is labelled "(inferred)" in the UI. See
INFERRED TOME SOURCES above for how those were derived and how far to trust
them.

This is an unofficial, fan-made tool. Not affiliated with Project Ebonhold.

SAVED DATA
----------
Everything -- wishlists, Missing Tomes/found-Tome state, and the window
position -- lives in one account-wide file:
WTF\Account\<ACCOUNT>\SavedVariables\EchoCodex.lua, under EchoCodexDB.

Wishlists are still per-character: EchoCodexDB.characters["<Realm> -
<CharacterName>"] holds each character's own wishlists, keyed by realm+name
rather than by WoW's SavedVariablesPerCharacter mechanism. That mechanism
never actually produced a saved file when tested (confirmed directly: zero
per-character EchoCodex.lua anywhere, while EbonholdHub's own per-character
file next to it saved normally) -- so character separation is done by hand
here instead, inside the account-wide file that's demonstrably reliable.
One side effect: since it's one shared file, any character can in principle
see the list of realm+character keys (not their contents at a glance, but
the names) if you go looking at the raw file; not a concern for solo play,
worth knowing if the account is ever shared.

Upgrading from a version before named/per-character wishlists: the first
time each character loads this version, whatever was in the old shared
single wishlist gets copied into that character's new "Default" wishlist
automatically (every character that logs in afterward gets its own copy of
that same starting point, since it can't tell which character it "really"
belonged to). The old flat wishlist/found fields are left in place
afterward rather than deleted, so they're still there if something looks
wrong.
