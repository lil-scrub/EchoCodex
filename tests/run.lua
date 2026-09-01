-- Echo Codex test suite.
--
--   cd tests && lua5.1 run.lua
--
-- Runs against Lua 5.1, the version the 3.3.5 client ships, so a construct
-- that parses here parses in-game too. Loads the real addon files in .toc
-- order against the WoW stub in wow_mock.lua.
--
-- The ownership fixtures below are REAL captures from a live session
-- (/eco debug, read back out of SavedVariables), not invented shapes --
-- including the two quirks that caused actual bugs:
--   * Quick Hands reports the SAME spellId twice across two stacks.
--   * Swift Step reports TWO DIFFERENT quality tiers across two stacks
--     even though both stacks are the same tier in-game.

package.path = "./?.lua;" .. package.path
local mock = require("wow_mock")

local ADDON_DIR = ".."
local TOC_ORDER = {
  "Data_Echoes.lua", "Data_Tomes.lua",
  "Init.lua", "Widgets.lua", "DB.lua", "Util.lua",
  "Ownership.lua", "Debug.lua", "ImportExport.lua",
  "Tab_Browse.lua", "Wishlists.lua", "Tab_MissingTomes.lua",
  "Tab_CurrentBuild.lua", "Core.lua",
}

----------------------------------------------------------------------
-- Tiny test framework
----------------------------------------------------------------------

local passed, failed = 0, 0
local failures = {}
local currentTest

local function fail(msg)
  failed = failed + 1
  table.insert(failures, currentTest .. ": " .. msg)
  print(string.format("  FAIL  %s\n        %s", currentTest, msg))
end

local function ok()
  passed = passed + 1
  print(string.format("  ok    %s", currentTest))
end

local function test(name, fn)
  currentTest = name
  local success, err = pcall(fn)
  if success then ok() else fail(tostring(err)) end
end

local function assertEq(actual, expected, what)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s",
      what or "value", tostring(expected), tostring(actual)), 2)
  end
end

local function assertTrue(v, what)
  if not v then error((what or "value") .. ": expected truthy, got " .. tostring(v), 2) end
end

local function assertFalse(v, what)
  if v then error((what or "value") .. ": expected falsy, got " .. tostring(v), 2) end
end

----------------------------------------------------------------------
-- Addon loading
----------------------------------------------------------------------

-- Fresh load: new namespace, cleared globals, addon files re-executed.
-- Each scenario gets its own so leftover state can't leak between tests.
local function loadAddon()
  mock.install()
  local ns = {}
  for _, file in ipairs(TOC_ORDER) do
    local path = ADDON_DIR .. "/" .. file
    local chunk, err = loadfile(path)
    if not chunk then error("could not load " .. path .. ": " .. tostring(err)) end
    chunk("EchoCodex", ns)
  end
  return ns
end

-- Builds the UI and initializes the DB, the same way ADDON_LOADED does
-- in-game. Needed for anything that touches the tab lists.
local function loadAddonReady()
  local ns = loadAddon()
  mock.FireEvent("ADDON_LOADED", "EchoCodex")
  return ns
end

----------------------------------------------------------------------
-- Fixtures
----------------------------------------------------------------------

local SWIFT_STEP_GREEN, SWIFT_STEP_BLUE = 200466, 200507
local QUICK_HANDS_WHITE, QUICK_HANDS_GREEN, QUICK_HANDS_BLUE = 200431, 200482, 200523

-- PerkDatabase groups every quality tier of one Echo under a shared
-- groupId. This has to be populated for the tests to mean anything: the
-- original Quick Hands bug lived in the group-expansion path, which is
-- inert when PerkDatabase is empty.
--
-- Quick Hands' groupId (69) and tiers are verbatim from the live capture.
-- Swift Step's group id isn't in that capture, so 70 is synthetic -- only
-- its *shape* (three tiers sharing one group) matters here.
local PERK_DATABASE = {
  [QUICK_HANDS_WHITE] = { groupId = 69, quality = 0, comment = "Quick Hands" },
  [QUICK_HANDS_GREEN] = { groupId = 69, quality = 1, comment = "Quick Hands" },
  [QUICK_HANDS_BLUE]  = { groupId = 69, quality = 2, comment = "Quick Hands - Rare" },
  [200019]            = { groupId = 70, quality = 0, comment = "Swift Step" },
  [SWIFT_STEP_GREEN]  = { groupId = 70, quality = 1, comment = "Swift Step" },
  [SWIFT_STEP_BLUE]   = { groupId = 70, quality = 2, comment = "Swift Step - Rare" },
}

-- Shape of ProjectEbonhold.PerkService.GetGrantedPerks(): keyed by Echo
-- name, one nested sub-table per stack held.
local function grantedPerks(entries)
  return {
    PerkService = {
      GetGrantedPerks = function() return entries end,
      GetLockedPerks = function() return {} end,
      GetDiscoveredEchoes = function() return {} end,
    },
    PerkDatabase = PERK_DATABASE,
  }
end

local function stack(spellId, quality)
  return { maxStack = 80, stack = 1, spellId = spellId, quality = quality }
end

----------------------------------------------------------------------
-- Tests: loading
----------------------------------------------------------------------

print("\n-- loading --")

test("all addon files load without error", function()
  local ns = loadAddon()
  assertTrue(ns.EC, "ns.EC")
  assertTrue(ns.THEME, "ns.THEME")
  assertTrue(ns.CreateList, "ns.CreateList")
end)

test("ADDON_LOADED builds the UI and seeds the DB", function()
  local ns = loadAddonReady()
  assertTrue(ns.charDB, "ns.charDB")
  assertTrue(ns.charDB.activeWishlist, "activeWishlist")
  assertTrue(ns.activeWishlistItems, "activeWishlistItems")
end)

test("band() fallback computes bitwise AND without the bit library", function()
  local ns = loadAddon()
  assertEq(ns.band(12, 10), 8, "12 & 10")
  assertEq(ns.band(1535, 256), 256, "1535 & 256")
  assertEq(ns.band(1, 2), 0, "1 & 2")
end)

----------------------------------------------------------------------
-- Tests: current-build tier + stack counting
--
-- These are direct regressions for the three bugs hit in development.
----------------------------------------------------------------------

print("\n-- current build: tiers and stacks --")

test("same tier reported twice counts as 2 picks", function()
  local ns = loadAddonReady()
  _G.ProjectEbonhold = grantedPerks({
    ["Quick Hands"] = { stack(QUICK_HANDS_BLUE, 2), stack(QUICK_HANDS_BLUE, 2) },
  })
  ns.EC.RefreshOwnedCache()
  assertTrue(ns.EC.IsEchoInCurrentBuild({ id = QUICK_HANDS_BLUE }), "blue in build")
  assertEq(ns.EC.GetCurrentBuildCount({ id = QUICK_HANDS_BLUE }), 2, "blue pick count")
end)

test("lower tiers of a held Echo are NOT marked in-build", function()
  -- The original Quick Hands bug: holding blue also lit up white and green.
  local ns = loadAddonReady()
  _G.ProjectEbonhold = grantedPerks({
    ["Quick Hands"] = { stack(QUICK_HANDS_BLUE, 2), stack(QUICK_HANDS_BLUE, 2) },
  })
  ns.EC.RefreshOwnedCache()
  assertFalse(ns.EC.IsEchoInCurrentBuild({ id = QUICK_HANDS_GREEN }), "green in build")
  assertFalse(ns.EC.IsEchoInCurrentBuild({ id = QUICK_HANDS_WHITE }), "white in build")
end)

test("stacks tagged with mismatched tiers still count as 2 picks", function()
  -- The Swift Step bug: two real blue stacks, but the API tagged one green,
  -- so counting occurrences of the winning id undercounted to 1.
  local ns = loadAddonReady()
  _G.ProjectEbonhold = grantedPerks({
    ["Swift Step"] = { stack(SWIFT_STEP_GREEN, 1), stack(SWIFT_STEP_BLUE, 2) },
  })
  ns.EC.RefreshOwnedCache()
  assertEq(ns.EC.GetCurrentBuildCount({ id = SWIFT_STEP_BLUE }), 2, "blue pick count")
end)

test("mismatched-tier stacks resolve to the highest tier only", function()
  local ns = loadAddonReady()
  _G.ProjectEbonhold = grantedPerks({
    ["Swift Step"] = { stack(SWIFT_STEP_GREEN, 1), stack(SWIFT_STEP_BLUE, 2) },
  })
  ns.EC.RefreshOwnedCache()
  assertTrue(ns.EC.IsEchoInCurrentBuild({ id = SWIFT_STEP_BLUE }), "blue in build")
  assertFalse(ns.EC.IsEchoInCurrentBuild({ id = SWIFT_STEP_GREEN }), "green in build")
end)

test("a single pick reports a count of 1", function()
  local ns = loadAddonReady()
  _G.ProjectEbonhold = grantedPerks({
    ["Quick Hands"] = { stack(QUICK_HANDS_BLUE, 2) },
  })
  ns.EC.RefreshOwnedCache()
  assertEq(ns.EC.GetCurrentBuildCount({ id = QUICK_HANDS_BLUE }), 1, "pick count")
end)

test("an Echo not in the build reports count 1 and is not in-build", function()
  local ns = loadAddonReady()
  _G.ProjectEbonhold = grantedPerks({})
  ns.EC.RefreshOwnedCache()
  assertFalse(ns.EC.IsEchoInCurrentBuild({ id = SWIFT_STEP_BLUE }), "in build")
  assertEq(ns.EC.GetCurrentBuildCount({ id = SWIFT_STEP_BLUE }), 1, "default count")
end)

----------------------------------------------------------------------
-- Tests: cross-file ownership state access
--
-- Ownership.lua owns the scan tables and REPLACES them on every refresh, so
-- Debug.lua and the Current Build tab reach them via ns.GetOwnershipState()
-- rather than holding a reference. These cover those seams.
----------------------------------------------------------------------

print("\n-- ownership state accessor --")

test("GetOwnershipState reflects the latest refresh, not a stale snapshot", function()
  local ns = loadAddonReady()
  _G.ProjectEbonhold = grantedPerks({
    ["Quick Hands"] = { stack(QUICK_HANDS_BLUE, 2) },
  })
  ns.EC.RefreshOwnedCache()
  local first = ns.GetOwnershipState()
  assertTrue(first.currentBuildIds[QUICK_HANDS_BLUE], "first refresh sees the pick")

  _G.ProjectEbonhold = grantedPerks({
    ["Swift Step"] = { stack(SWIFT_STEP_BLUE, 2) },
  })
  ns.EC.RefreshOwnedCache()
  local second = ns.GetOwnershipState()
  assertTrue(second.currentBuildIds[SWIFT_STEP_BLUE], "second refresh sees the new pick")
  assertFalse(second.currentBuildIds[QUICK_HANDS_BLUE], "old pick cleared")
end)

test("RefreshCurrentBuild lists an equipped, unwishlisted Echo as a reroll", function()
  local ns = loadAddonReady()
  _G.ProjectEbonhold = grantedPerks({
    ["Swift Step"] = { stack(SWIFT_STEP_BLUE, 2) },
  })
  ns.EC.RefreshCurrentBuild()  -- must not error; reads via GetOwnershipState
  assertTrue(ns.EC.IsEchoInCurrentBuild({ id = SWIFT_STEP_BLUE }), "equipped")
end)

test("DebugOwnership writes a snapshot without erroring", function()
  local ns = loadAddonReady()
  _G.ProjectEbonhold = grantedPerks({
    ["Quick Hands"] = { stack(QUICK_HANDS_BLUE, 2), stack(QUICK_HANDS_BLUE, 2) },
  })
  ns.EC.DebugOwnership()
  local d = _G.EchoCodexDB.lastDebug
  assertTrue(d, "lastDebug written")
  assertEq(d.projectEbonholdPresent, true, "sees ProjectEbonhold")
  assertEq(type(d.totalKnownEchoes), "number", "known count type")
  assertEq(d.foundEchoesTab, false, "no Echoes spellbook tab in the stub")
end)

test("DebugOwnership term search reports per-tier ownership", function()
  local ns = loadAddonReady()
  _G.ProjectEbonhold = grantedPerks({
    ["Quick Hands"] = { stack(QUICK_HANDS_BLUE, 2) },
  })
  ns.EC.DebugOwnership("Quick Hands")
  local search = _G.EchoCodexDB.lastDebug.search
  assertTrue(search, "search section written")
  assertEq(search.term, "Quick Hands", "term recorded")
  assertTrue(#search.ownData >= 3, "all three tiers listed")
  local blueLine
  for _, line in ipairs(search.ownData) do
    if line:find("id=" .. QUICK_HANDS_BLUE, 1, true) then blueLine = line end
  end
  assertTrue(blueLine, "blue tier line present")
  assertTrue(blueLine:find("inCurrentBuild=true", 1, true), "blue reported in build: " .. blueLine)
end)

----------------------------------------------------------------------
-- Tests: wishlists
----------------------------------------------------------------------

print("\n-- wishlists --")

test("duplicate copies items and leaves the original intact", function()
  local ns = loadAddonReady()
  local EC = ns.EC
  ns.activeWishlistItems[QUICK_HANDS_BLUE] = true
  ns.activeWishlistItems[SWIFT_STEP_BLUE] = true
  local original = EC.GetActiveWishlistName()

  assertTrue(EC.DuplicateActiveWishlist("Copy A"), "duplicate succeeded")
  assertEq(EC.GetActiveWishlistName(), "Copy A", "switched to the copy")
  assertTrue(ns.activeWishlistItems[QUICK_HANDS_BLUE], "item carried over")
  assertTrue(ns.activeWishlistItems[SWIFT_STEP_BLUE], "item carried over")

  -- Mutating the copy must not touch the source.
  ns.activeWishlistItems[QUICK_HANDS_BLUE] = nil
  EC.SetActiveWishlist(original)
  assertTrue(ns.activeWishlistItems[QUICK_HANDS_BLUE], "source unchanged")
end)

test("duplicate rejects an existing name", function()
  local ns = loadAddonReady()
  local okDup = ns.EC.DuplicateActiveWishlist(ns.EC.GetActiveWishlistName())
  assertFalse(okDup, "duplicate onto existing name")
end)

test("create, rename, and delete round-trip", function()
  local ns = loadAddonReady()
  local EC = ns.EC
  assertTrue(EC.CreateWishlist("Temp"), "create")
  assertEq(EC.GetActiveWishlistName(), "Temp", "active after create")
  assertTrue(EC.RenameActiveWishlist("Renamed"), "rename")
  assertEq(EC.GetActiveWishlistName(), "Renamed", "active after rename")
  assertTrue(EC.DeleteActiveWishlist(), "delete")
  assertFalse(ns.charDB.wishlists["Renamed"], "deleted entry gone")
end)

test("the last remaining wishlist cannot be deleted", function()
  local ns = loadAddonReady()
  for name in pairs(ns.charDB.wishlists) do
    if name ~= ns.charDB.activeWishlist then ns.charDB.wishlists[name] = nil end
  end
  assertFalse(ns.EC.DeleteActiveWishlist(), "delete of only wishlist")
end)

test("switching wishlists repoints the live item table", function()
  -- Guards the refactor's riskiest seam: ns.activeWishlistItems is
  -- REASSIGNED on switch, so any stale file-local copy would break here.
  local ns = loadAddonReady()
  local EC = ns.EC
  ns.activeWishlistItems[QUICK_HANDS_BLUE] = true
  EC.CreateWishlist("Empty One")
  assertFalse(ns.activeWishlistItems[QUICK_HANDS_BLUE], "new list starts empty")
end)

----------------------------------------------------------------------
-- Tests: tab registry
--
-- Tabs register themselves in ns.tabs instead of exposing widgets, so the
-- main frame can build/switch/refresh without reaching into another file.
----------------------------------------------------------------------

print("\n-- tab registry --")

test("every tab in tabOrder registers a label and a build function", function()
  local ns = loadAddon()
  assertEq(#ns.tabOrder, 4, "tab count")
  for _, name in ipairs(ns.tabOrder) do
    local tab = ns.tabs[name]
    assertTrue(tab, "tab registered: " .. name)
    assertEq(type(tab.label), "string", "label on " .. name)
    assertEq(type(tab.build), "function", "build on " .. name)
    assertEq(type(tab.refresh), "function", "refresh on " .. name)
    assertEq(type(tab.onSelect), "function", "onSelect on " .. name)
  end
end)

test("no tab registers a key missing from tabOrder", function()
  local ns = loadAddon()
  local ordered = {}
  for _, name in ipairs(ns.tabOrder) do ordered[name] = true end
  for name in pairs(ns.tabs) do
    assertTrue(ordered[name], "unreachable tab registered: " .. tostring(name))
  end
end)

test("RefreshAll refreshes every registered tab", function()
  local ns = loadAddonReady()
  _G.ProjectEbonhold = grantedPerks({})
  local seen = {}
  for _, name in ipairs(ns.tabOrder) do
    local tab, realRefresh = ns.tabs[name], ns.tabs[name].refresh
    tab.refresh = function(...) seen[name] = true; return realRefresh(...) end
  end
  ns.EC.RefreshAll()
  for _, name in ipairs(ns.tabOrder) do
    assertTrue(seen[name], "refreshed " .. name)
  end
end)

test("switching wishlists resets the wishlist-scoped scroll offsets", function()
  local ns = loadAddonReady()
  local reset = {}
  for _, name in ipairs(ns.tabOrder) do
    local tab = ns.tabs[name]
    if tab.resetScroll then
      local real = tab.resetScroll
      tab.resetScroll = function(...) reset[name] = true; return real(...) end
    end
  end
  ns.EC.CreateWishlist("Scroll Test")
  assertTrue(reset.wishlist, "wishlist scroll reset")
  assertTrue(reset.checklist, "checklist scroll reset")
end)

----------------------------------------------------------------------
-- Tests: import / export
----------------------------------------------------------------------

print("\n-- import / export --")

test("EBH1 import adds recognized Echo ids", function()
  local ns = loadAddonReady()
  local str = string.format("EBH1:%d.0.1,%d.0.1:WARLOCK:Test", QUICK_HANDS_BLUE, SWIFT_STEP_BLUE)
  local okImp, res = ns.EC.ImportEBHWishlist(str)
  assertTrue(okImp, "import succeeded: " .. tostring(res))
  assertTrue(ns.activeWishlistItems[QUICK_HANDS_BLUE], "first id added")
  assertTrue(ns.activeWishlistItems[SWIFT_STEP_BLUE], "second id added")
end)

test("import reports unrecognized ids instead of adding them", function()
  local ns = loadAddonReady()
  local okImp, res = ns.EC.ImportEBHWishlist("EBH1:299999.0.1:WARLOCK:Test")
  assertTrue(okImp, "import succeeded")
  assertEq(res.unknown, 1, "unknown count")
  assertFalse(ns.activeWishlistItems[299999], "bogus id not added")
end)

test("import rejects malformed input", function()
  local ns = loadAddonReady()
  local okImp = ns.EC.ImportEBHWishlist("not a real export string")
  assertFalse(okImp, "malformed import")
end)

test("export round-trips through import", function()
  local ns = loadAddonReady()
  local EC = ns.EC
  ns.activeWishlistItems[QUICK_HANDS_BLUE] = true
  ns.activeWishlistItems[SWIFT_STEP_BLUE] = true
  local str, count = EC.ExportActiveWishlistString()
  assertEq(count, 2, "exported count")

  EC.CreateWishlist("Round Trip")
  assertTrue(EC.ImportEBHWishlist(str), "reimport")
  assertTrue(ns.activeWishlistItems[QUICK_HANDS_BLUE], "id survived round trip")
  assertTrue(ns.activeWishlistItems[SWIFT_STEP_BLUE], "id survived round trip")
end)

----------------------------------------------------------------------
-- Tests: filtering
----------------------------------------------------------------------

print("\n-- filtering --")

test("search matches the effect description, not just the name", function()
  local ns = loadAddon()
  local hits = ns.GetFilteredEchoes({ search = "haste rating", qualitySet = {} })
  assertTrue(#hits > 0, "description search returned results")
  local sawNonNameMatch = false
  for _, e in ipairs(hits) do
    if not e.n:lower():find("haste rating", 1, true) then sawNonNameMatch = true break end
  end
  assertTrue(sawNonNameMatch, "matched on description text")
end)

test("quality filter keeps only the requested tiers", function()
  local ns = loadAddon()
  local hits = ns.GetFilteredEchoes({ qualitySet = { [3] = true } })
  assertTrue(#hits > 0, "epic results exist")
  for _, e in ipairs(hits) do assertEq(e.q, 3, "quality of " .. e.n) end
end)

test("tomeOnly keeps only Tome-gated Echoes", function()
  local ns = loadAddon()
  local hits = ns.GetFilteredEchoes({ qualitySet = {}, tomeOnly = true })
  assertTrue(#hits > 0, "tome results exist")
  for _, e in ipairs(hits) do assertTrue(e.t, "tome flag on " .. e.n) end
end)

test("results sort by quality descending, then name", function()
  local ns = loadAddon()
  local hits = ns.GetFilteredEchoes({ qualitySet = {} })
  for i = 2, #hits do
    local prev, cur = hits[i - 1], hits[i]
    assertTrue(prev.q > cur.q or (prev.q == cur.q and prev.n <= cur.n),
      string.format("order at %d: %s(q%d) before %s(q%d)", i, prev.n, prev.q, cur.n, cur.q))
  end
end)

----------------------------------------------------------------------
-- Tests: data integrity
----------------------------------------------------------------------

print("\n-- data integrity --")

test("every Echo row has the fields the UI reads", function()
  loadAddon()
  local n = 0
  for id, e in pairs(EchoCodexDataEchoes) do
    assertEq(type(id), "number", "echo id type")
    assertTrue(type(e.n) == "string" and e.n ~= "", "name on " .. id)
    assertEq(type(e.d), "string", "description on " .. id)
    assertTrue(type(e.q) == "number" and e.q >= 0 and e.q <= 3, "quality on " .. id)
    assertEq(type(e.cm), "number", "class mask on " .. id)
    n = n + 1
  end
  assertTrue(n > 100, "echo count sanity (" .. n .. ")")
end)

test("every Echo->Tome mapping points at a real Echo and a real Tome", function()
  loadAddon()
  for echoId, tomeId in pairs(EchoCodexEchoToTome) do
    assertTrue(EchoCodexDataEchoes[echoId], "echo " .. echoId .. " exists")
    assertTrue(EchoCodexTomes[tomeId], "tome " .. tostring(tomeId) .. " exists")
  end
end)

test("every documented drop location names a known zone", function()
  loadAddon()
  for tomeId, locs in pairs(EchoCodexLocations) do
    assertTrue(EchoCodexTomes[tomeId], "tome " .. tostring(tomeId) .. " exists")
    for _, loc in ipairs(locs) do
      assertTrue(EchoCodexZones[loc.zone] or type(loc.zone) == "string",
        "zone " .. tostring(loc.zone))
    end
  end
end)

----------------------------------------------------------------------

print(string.format("\n%d passed, %d failed", passed, failed))
if failed > 0 then
  print("\nFailures:")
  for _, f in ipairs(failures) do print("  - " .. f) end
  os.exit(1)
end
os.exit(0)
