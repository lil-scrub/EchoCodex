-- Echo Codex -- character Echo ownership detection.
--
-- Answers three questions the UI asks constantly:
--   EC.IsEchoKnown         have I ever unlocked this Echo (any run)?
--   EC.IsEchoInCurrentBuild is it one of THIS run's active picks?
--   EC.GetCurrentBuildCount how many times did I pick it?
--
-- Everything here reads server-side tables that are not a published API --
-- shapes are undocumented and can change with a patch -- so every access is
-- guarded and a missing or renamed field means "can't tell", never an error.
--
-- The diagnostics that report on this file's findings live in Debug.lua,
-- which reaches them through ns.GetOwnershipState().

local ADDON_NAME, ns = ...

local EC = ns.EC

----------------------------------------------------------------------
-- Character echo ownership, via the ProjectEbonhold API -- the server's
-- own Echo Journal addon, which EbonholdHub reads from too. Best-effort
-- and defensive throughout: the exact table shapes aren't documented and
-- can change with server patches, so every access is guarded and a
-- missing/renamed field just means "can't tell," never an error.
----------------------------------------------------------------------

local function NormalizeOwnedName(name)
  if not name or name == "" then return nil end
  name = name:gsub("’", "'"):gsub("‘", "'"):gsub("`", "'")
  local n = string.lower(name)
  n = n:gsub("^%s+", ""):gsub("%s+$", "")
  n = n:gsub("%s*%-%s*%a+$", "") -- strip a trailing " - <quality>" decoration
  if n == "" then return nil end
  return n
end

local ownedIds, ownedNames = {}, {}

local function ScanForOwnership(t, seen)
  if type(t) ~= "table" or seen[t] then return end
  seen[t] = true
  for k, v in pairs(t) do
    if type(k) == "number" and k >= 200000 and k < 300000 then ownedIds[k] = true end
    if type(v) == "number" and v >= 200000 and v < 300000 then ownedIds[v] = true end
    if type(k) == "string" and k ~= "" then
      local norm = NormalizeOwnedName(k)
      if norm then ownedNames[norm] = true end
    end
    if type(v) == "table" then ScanForOwnership(v, seen) end
  end
end

-- "Current build" -- what's actively equipped THIS run, per GetGrantedPerks,
-- UNION'd with whatever EbonholdHub's active Build has selected (see
-- ScanEbonholdHubActiveBuild below) -- distinct from ownedIds above, which
-- also folds in GetDiscoveredEchoes (everything ever unlocked, any run).
-- The Current Build tab diffs this narrower set against the wishlist.
local currentBuildIds = {}

-- id -> how many times that exact tier was picked/stacked this run, per the
-- single source that reported the most (see ScanForCurrentBuild below).
-- Absent/1 means "picked once" -- EC.GetCurrentBuildCount treats both the
-- same, so callers don't need a nil check.
local currentBuildCounts = {}

-- Collect every spellId (200000-299999) nested anywhere under `entry`.
local function CollectSpellIds(entry, seen, out)
  if type(entry) ~= "table" or seen[entry] then return end
  seen[entry] = true
  for k, v in pairs(entry) do
    if type(k) == "number" and k >= 200000 and k < 300000 then out[k] = true end
    if type(v) == "number" and v >= 200000 and v < 300000 then out[v] = true end
    if type(v) == "table" then CollectSpellIds(v, seen, out) end
  end
end

-- `t` is granted/locked perks, keyed by Echo name (or by slot index for
-- locked). A granted-perks entry nests one sub-table PER STACK the player
-- holds of that perk ({1={spellId=X, quality=..}, 2={spellId=Y, quality=..},
-- ...} -- see the "stack"/"maxStack" fields); a locked-perks entry is a
-- single flat record instead (one slot, one pick). Stack count is therefore
-- how many sub-tables `entry` itself directly contains (1 if it's already
-- flat), completely separate from WHICH tier to trust:
--
-- GetGrantedPerks can report DIFFERENT quality-tier spellIds across a
-- single Echo's stacks even when the character holds the SAME tier in
-- both (confirmed live: two Swift Step stacks, both blue in-game, reported
-- as one blue + one stale green spellId) -- so which id to display comes
-- from the highest tier found across every stack, while the stack COUNT
-- comes from the number of stacks itself, regardless of what tier each one
-- claims. Otherwise a stale per-stack tier tag would silently undercount a
-- real duplicate down to "picked once".
local function ScanForCurrentBuild(t)
  if type(t) ~= "table" then return end
  for _, entry in pairs(t) do
    if type(entry) == "table" then
      local subEntries = {}
      for _, v in pairs(entry) do
        if type(v) == "table" then subEntries[#subEntries + 1] = v end
      end
      -- Not actually nested (a flat locked-slot record) -- treat the whole
      -- entry as its own single stack.
      if #subEntries == 0 then subEntries[1] = entry end

      local foundIds = {}
      local bestId, bestQ
      for _, sub in ipairs(subEntries) do
        local ids = {}
        CollectSpellIds(sub, {}, ids)
        for id in pairs(ids) do
          foundIds[id] = true
          local echo = EchoCodexDataEchoes[id]
          if echo and (not bestQ or echo.q > bestQ) then bestId, bestQ = id, echo.q end
        end
      end

      if bestId then
        currentBuildIds[bestId] = true
        currentBuildCounts[bestId] = math.max(currentBuildCounts[bestId] or 0, #subEntries)
      else
        -- Nothing found matches one of our own rows (e.g. only a sibling
        -- tier we don't track) -- seed the raw ids so ExpandCurrentBuildGroups
        -- can still resolve a tracked sibling via PerkDatabase's groupId.
        for id in pairs(foundIds) do currentBuildIds[id] = true end
      end
    end
  end
end

-- Name -> id index over our own static Echo data (built once and cached --
-- the snapshot doesn't change at runtime), used to resolve EbonholdHub's
-- Build.echoTiers (keyed by Echo NAME, not spell id) below. Several Echoes
-- have one row PER QUALITY TIER sharing the exact same name (e.g. "Quick
-- Hands" is white/green/blue rows 200431/200482/200523) -- and Build's
-- "tier" value is an unrelated internal S/A/B/C weighting grade, not the
-- WoW quality, so it can't tell us which row the player actually has.
-- Deterministically keep the HIGHEST-quality row per name (pairs() order is
-- otherwise unspecified, so without this a name could resolve to any tier
-- from run to run) -- same convention EC.RefreshCurrentBuild's rerollByName
-- dedup already uses when multiple tiers of one name are in play.
local echoIdByName

local function EchoIdByName(name)
  if not echoIdByName then
    echoIdByName = {}
    for id, e in pairs(EchoCodexDataEchoes) do
      local norm = NormalizeOwnedName(e.n)
      if norm then
        local existing = echoIdByName[norm]
        if not existing or e.q > EchoCodexDataEchoes[existing].q then
          echoIdByName[norm] = id
        end
      end
    end
  end
  local norm = NormalizeOwnedName(name)
  return norm and echoIdByName[norm]
end

-- EbonholdHub's "Build" feature (Talents/Gear/Echoes/Automation presets, see
-- its BuildTabs/BuildList UI) is a separate concept from the live in-game
-- state above -- switching the active Build there doesn't fire
-- SPELLS_CHANGED at all, since nothing about the character actually
-- changes. It's exactly what players mean by "switch builds" day to day
-- though, so it feeds the same currentBuildIds set GetGrantedPerks does.
--
-- A saved Build is just a plan, though -- it can reference Echoes the
-- character hasn't actually unlocked yet (planning ahead, a build copied
-- from someone else, etc). Only fold in entries backed by EXACT-id evidence
-- in ownedIds (real spellIds seen in granted/locked perks or discovery) --
-- deliberately NOT EC.IsEchoKnown/ownedNames, whose name-only fallback (fed
-- by ProjectEbonholdDB.cachedPerkCounts, keyed by Echo name with no tier)
-- reports every quality tier of a name as "known" the moment ANY tier is.
-- Gating on that would rubber-stamp a stale Build entry for the WRONG tier
-- (e.g. a green Quick Hands the Build remembers, when only blue is
-- currently granted) as long as some tier of that name was ever known.
-- This means the call site matters: run this AFTER ownedIds is populated.
local function ScanEbonholdHubActiveBuild()
  if not (EbonholdHub and EbonholdHub.Build and EbonholdHub.Build.GetActive) then return end
  local ok, build = pcall(EbonholdHub.Build.GetActive)
  if not ok or type(build) ~= "table" then return end

  if type(build.echoTiers) == "table" then
    for name in pairs(build.echoTiers) do
      local id = EchoIdByName(name)
      if id and ownedIds[id] then currentBuildIds[id] = true end
    end
  end

  -- Permanent/Tome-locked slots are a SEPARATE array on the build, keyed by
  -- slot index rather than folded into echoTiers -- and already spell ids
  -- (see EbonholdHub's CharacterEchoes.lua CollectLockedSlots), not names.
  if type(build.lockedEchoes) == "table" then
    for _, spellId in pairs(build.lockedEchoes) do
      if type(spellId) == "number" and EchoCodexDataEchoes[spellId] and ownedIds[spellId] then
        currentBuildIds[spellId] = true
      end
    end
  end
end

-- Learning a Tome permanently adds it to the "Echoes" tab of the spellbook --
-- this is the actual source of truth for "have I learned this Tome," not
-- PerkService's granted/locked tables, which only reflect the current
-- run's active picks (and can be empty between runs). The server places
-- each Tome at (its Echo's spell id + 100000); a smaller number of Echoes
-- instead point back at their Tome via PerkDatabase[echoId].requiredSpell,
-- so both conventions are checked.
local foundEchoesTab = false

local lastSeenTabNames = {}

local function CollectSpellbookTomeIds()
  local ids = {}
  lastSeenTabNames = {}
  if not GetNumSpellTabs then return ids end
  local ok, numTabs = pcall(GetNumSpellTabs)
  if not ok or not numTabs then return ids end
  for tabIdx = 1, numTabs do
    local tabName, _, offset, numSpells = GetSpellTabInfo(tabIdx)
    lastSeenTabNames[#lastSeenTabNames + 1] = string.format("%s (%d spells)", tostring(tabName), numSpells or 0)
    if tabName == "Echoes" then
      foundEchoesTab = true
      for slot = offset + 1, offset + numSpells do
        local link
        if GetSpellLink then
          link = GetSpellLink(slot, BOOKTYPE_SPELL or "spell")
          if not link then link = GetSpellLink(slot, "spell") end
        end
        local tomeSpellId = link and tonumber(link:match("spell:(%d+)"))
        if tomeSpellId then ids[tomeSpellId] = true end
      end
      break
    end
  end
  return ids
end

local function BuildRequiredSpellIndex()
  local index = {}
  if ProjectEbonhold and ProjectEbonhold.PerkDatabase then
    pcall(function()
      for spellId, data in pairs(ProjectEbonhold.PerkDatabase) do
        if type(data) == "table" and data.requiredSpell then
          index[data.requiredSpell] = index[data.requiredSpell] or {}
          index[data.requiredSpell][spellId] = true
        end
      end
    end)
  end
  return index
end

-- Tome item/spell names carry a flavor prefix ("Tome of X", "Codex of X",
-- "Grimoire of X", ...) that our own Tome database (sourced from the
-- community World of Echoes map) doesn't store -- strip it before comparing.
local TOME_NAME_PREFIXES = {
  "tome of ", "codex of ", "scroll of ", "manual of ", "grimoire of ", "libram of ", "tablet of ",
}

local function NormalizeTomeName(name)
  local n = NormalizeOwnedName(name)
  if not n then return nil end
  for _, prefix in ipairs(TOME_NAME_PREFIXES) do
    if n:sub(1, #prefix) == prefix then
      n = n:sub(#prefix + 1)
      break
    end
  end
  return n
end

-- Built once from our own static data (not from anything server-injected),
-- so this index is always available regardless of what ProjectEbonhold
-- exposes at the moment we scan.
local tomeNameToTomeId, tomeIdToEchoIds

local function BuildTomeNameIndex()
  if tomeNameToTomeId then return end
  tomeNameToTomeId = {}
  for tomeId, tome in pairs(EchoCodexTomes) do
    local norm = NormalizeTomeName(tome.name)
    if norm then tomeNameToTomeId[norm] = tomeId end
  end
  tomeIdToEchoIds = {}
  for echoId, tomeId in pairs(EchoCodexEchoToTome) do
    tomeIdToEchoIds[tomeId] = tomeIdToEchoIds[tomeId] or {}
    tomeIdToEchoIds[tomeId][#tomeIdToEchoIds[tomeId] + 1] = echoId
  end
end

local lastScanDebug = { tomeSpellIds = {}, matchedByName = 0, matchedById = 0, matchedByReq = 0, unmatchedNames = {} }

local function ScanSpellbookTomes()
  lastScanDebug = { tomeSpellIds = {}, matchedByName = 0, matchedById = 0, matchedByReq = 0, unmatchedNames = {} }

  local ok, tomeIds = pcall(CollectSpellbookTomeIds)
  if not ok or not tomeIds or not next(tomeIds) then return end

  BuildTomeNameIndex()
  local reqIndex = BuildRequiredSpellIndex()

  for tomeSpellId in pairs(tomeIds) do
    lastScanDebug.tomeSpellIds[#lastScanDebug.tomeSpellIds + 1] = tomeSpellId
    local matched = false

    -- Path 1: match the tome's spell NAME against our own Tome database.
    -- Doesn't depend on any internal id convention, so it's the most
    -- reliable path -- it only needs GetSpellInfo() and our own data.
    local tomeName = GetSpellInfo and GetSpellInfo(tomeSpellId)
    if tomeName then
      local norm = NormalizeTomeName(tomeName)
      local matchedTomeId = norm and tomeNameToTomeId[norm]
      if matchedTomeId then
        local echoIds = tomeIdToEchoIds[matchedTomeId]
        if echoIds then
          for _, eid in ipairs(echoIds) do ownedIds[eid] = true end
          matched = true
          lastScanDebug.matchedByName = lastScanDebug.matchedByName + 1
        end
      elseif norm then
        lastScanDebug.unmatchedNames[#lastScanDebug.unmatchedNames + 1] = tomeName
      end
    end

    -- Path 2: id arithmetic some Tomes follow (tomeId = echoId + 100000).
    local echoId = tomeSpellId - 100000
    if EchoCodexDataEchoes[echoId] then
      ownedIds[echoId] = true
      matched = true
      lastScanDebug.matchedById = lastScanDebug.matchedById + 1
    end

    -- Path 3: PerkDatabase.requiredSpell cross-reference, when exposed.
    local reqMatches = reqIndex[tomeSpellId]
    if reqMatches then
      for spellId in pairs(reqMatches) do
        if EchoCodexDataEchoes[spellId] then
          ownedIds[spellId] = true
          matched = true
          lastScanDebug.matchedByReq = lastScanDebug.matchedByReq + 1
        end
      end
    end
  end
end
-- spellId -> groupId, and groupId -> {spellIds sharing it}, built live from
-- PerkDatabase. Discovering a Tome can mark just ONE quality tier's spellId
-- as discovered even though our own data references a sibling tier of the
-- same Tome/group -- Nexus's addon calls this grouping a "lever" and checks
-- every member before concluding a Tome is unknown; same idea here.
local function BuildGroupIndex()
  local byId, byGroup = {}, {}
  if ProjectEbonhold and type(ProjectEbonhold.PerkDatabase) == "table" then
    pcall(function()
      for spellId, data in pairs(ProjectEbonhold.PerkDatabase) do
        if type(data) == "table" and data.groupId then
          byId[spellId] = data.groupId
          byGroup[data.groupId] = byGroup[data.groupId] or {}
          byGroup[data.groupId][#byGroup[data.groupId] + 1] = spellId
        end
      end
    end)
  end
  return byId, byGroup
end

-- The actual cross-run "have you ever learned this" signal (h/t Nexus's own
-- GameAdapter.lua, which documents this explicitly and is the reason it was
-- found at all): GetGrantedPerks/GetLockedPerks only ever reflect the
-- CURRENT run, but GetDiscoveredEchoes is described there as "ever-obtained"
-- -- ProjectEbonhold's own Echo Journal gates a Tome's disable toggle on
-- this exact same field. This is what should actually drive the Checklist.
local function ScanDiscoveredEchoes(service)
  local discovered
  if service and service.GetDiscoveredEchoes then
    local ok, d = pcall(service.GetDiscoveredEchoes)
    if ok and type(d) == "table" then discovered = d end
  end
  if not discovered and ProjectEbonhold.Perks and type(ProjectEbonhold.Perks.discoveredEchoes) == "table" then
    discovered = ProjectEbonhold.Perks.discoveredEchoes
  end
  if type(discovered) ~= "table" then return end

  local byId, byGroup = BuildGroupIndex()
  for spellId in pairs(discovered) do
    if type(spellId) == "number" then
      if EchoCodexDataEchoes[spellId] then ownedIds[spellId] = true end
      local groupId = byId[spellId]
      if groupId and byGroup[groupId] then
        for _, sibling in ipairs(byGroup[groupId]) do
          if EchoCodexDataEchoes[sibling] then ownedIds[sibling] = true end
        end
      end
    end
  end
end

-- Same lever/group problem as ScanDiscoveredEchoes above, but for the
-- current-build signal: GetGrantedPerks can report a sibling quality
-- tier's spellId for an Echo whose only entry in our own snapshot is a
-- DIFFERENT tier (e.g. Armor Mastery only has an Epic-tier row here) --
-- fall back to its PerkDatabase group so the Echo still reads as "in
-- build" even when the reported id doesn't match any row we track.
--
-- Only fall back when the reported spellId ISN'T already one of our own
-- rows: Echoes like "Quick Hands" have one row PER QUALITY TIER
-- (white/green/blue), all in the same group -- expanding unconditionally
-- would mark every tier "in build" just because one of them is, which is
-- wrong (equipping blue doesn't mean you also currently have green). When
-- the reported id IS already a row we track, trust it exactly as reported
-- instead of fanning out to its siblings.
local function ExpandCurrentBuildGroups()
  local byId, byGroup = BuildGroupIndex()
  local seedIds = {}
  for spellId in pairs(currentBuildIds) do seedIds[spellId] = true end
  for spellId in pairs(seedIds) do
    if not EchoCodexDataEchoes[spellId] then
      local groupId = byId[spellId]
      if groupId and byGroup[groupId] then
        for _, sibling in ipairs(byGroup[groupId]) do
          if EchoCodexDataEchoes[sibling] then currentBuildIds[sibling] = true end
        end
      end
    end
  end
end

function EC.RefreshOwnedCache()
  ownedIds, ownedNames = {}, {}
  currentBuildIds = {}
  currentBuildCounts = {}
  foundEchoesTab = false

  -- Kept as a secondary check: permanently-learned Tomes, if they ever do
  -- show up in a spellbook tab (standard Blizzard API, no ProjectEbonhold
  -- dependency) -- hasn't fired on the one account this was verified
  -- against, but costs nothing to leave in for other classes/specs.
  ScanSpellbookTomes()

  if not ProjectEbonhold then
    -- No PerkService to pull ownership from, but ScanSpellbookTomes above
    -- may still have populated ownedIds -- run the EbonholdHub Build check
    -- against whatever we've got rather than skipping it outright.
    ScanEbonholdHubActiveBuild()
    return
  end

  local ok1, service = pcall(function() return ProjectEbonhold.PerkService end)
  service = ok1 and service or nil

  -- Primary signal now: see ScanDiscoveredEchoes above.
  if service then
    ScanDiscoveredEchoes(service)
  end

  -- Tertiary signal: the current run's active/locked Echo picks -- catches
  -- auto-learned (non-Tome) Echoes, which never get discovery-tracked since
  -- there's no Tome gating them in the first place.
  if service then
    if service.RequestGrantedPerks then
      pcall(service.RequestGrantedPerks)
    end
    if service.GetGrantedPerks then
      local ok, granted = pcall(service.GetGrantedPerks)
      if ok then
        ScanForOwnership(granted, {})
        ScanForCurrentBuild(granted)
      end
    end
    if service.GetLockedPerks then
      local ok, locked = pcall(service.GetLockedPerks)
      if ok then
        ScanForOwnership(locked, {})
        -- Permanent/Tome-locked Echoes (e.g. Armor Mastery) live here, not
        -- in GetGrantedPerks -- EbonholdHub's own CharacterEchoes.lua reads
        -- its locked build slots from this exact same API for this exact
        -- same reason. Current Build needs both to be complete.
        ScanForCurrentBuild(locked)
      end
    end
  end

  if ProjectEbonhold.Perks then
    ScanForOwnership(ProjectEbonhold.Perks.grantedPerks, {})
    ScanForOwnership(ProjectEbonhold.Perks.lockedPerks, {})
    ScanForCurrentBuild(ProjectEbonhold.Perks.grantedPerks)
    ScanForCurrentBuild(ProjectEbonhold.Perks.lockedPerks)
  end

  if ProjectEbonholdDB and type(ProjectEbonholdDB.cachedPerkCounts) == "table" then
    for name, count in pairs(ProjectEbonholdDB.cachedPerkCounts) do
      if type(name) == "string" and (type(count) ~= "number" or count > 0) then
        local norm = NormalizeOwnedName(name)
        if norm then ownedNames[norm] = true end
      end
    end
  end

  -- Run last: ScanEbonholdHubActiveBuild checks each Build entry against
  -- ownedIds/ownedNames, so it needs every ownership signal above to have
  -- already landed.
  ScanEbonholdHubActiveBuild()

  ExpandCurrentBuildGroups()
end

function EC.HasOwnershipData()
  return foundEchoesTab or ProjectEbonhold ~= nil
end

function EC.IsEchoKnown(echo)
  if ownedIds[echo.id] then return true end
  local norm = NormalizeOwnedName(echo.n)
  return norm ~= nil and ownedNames[norm] == true
end

-- Narrower than IsEchoKnown: only true if the Echo is one of THIS run's
-- active picks (GetGrantedPerks), not merely ever-discovered.
function EC.IsEchoInCurrentBuild(echo)
  return currentBuildIds[echo.id] == true
end

-- How many times this exact tier was picked/stacked this run. 1 (not 0)
-- when there's no count on record, so a plain "== 1" check is enough to
-- decide whether a "picked Nx" badge is worth showing.
function EC.GetCurrentBuildCount(echo)
  return currentBuildCounts[echo.id] or 1
end

-- Live view of the scan results, for Debug.lua and the Current Build tab.
--
-- Returns the CURRENT tables: EC.RefreshOwnedCache REPLACES them wholesale
-- rather than clearing in place, so callers must call this AFTER a refresh
-- and must not hold the result across one.
function ns.GetOwnershipState()
  return {
    ownedIds = ownedIds,
    ownedNames = ownedNames,
    currentBuildIds = currentBuildIds,
    currentBuildCounts = currentBuildCounts,
    foundEchoesTab = foundEchoesTab,
    lastSeenTabNames = lastSeenTabNames,
    lastScanDebug = lastScanDebug,
  }
end
