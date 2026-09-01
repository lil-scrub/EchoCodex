-- Echo Codex -- "/eco debug" diagnostics.
--
-- Pure reporting: dumps what each ownership data source contains and where a
-- given Echo/Tome name turns up, into EchoCodexDB.lastDebug. Nothing here
-- feeds the UI, so it can be read (or ignored) independently of Ownership.lua.
--
-- Ownership state is fetched through ns.GetOwnershipState() at call time
-- rather than cached, because EC.RefreshOwnedCache replaces those tables on
-- every refresh.

local ADDON_NAME, ns = ...

local EC = ns.EC

local function CountKeys(t)
  if type(t) ~= "table" then return nil end
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

-- Like tostring(), but for tables it inlines a couple levels of shallow
-- contents ("{200482=true}") instead of just a key count -- the debug
-- search below needs to see what's actually INSIDE a per-name entry (e.g.
-- which spellId a granted-perk table keyed by Echo name actually holds),
-- not just that it has 1 key.
local function DescribeValue(v, depth)
  if type(v) ~= "table" then return tostring(v) end
  if depth <= 0 then return "table(" .. tostring(CountKeys(v)) .. " keys)" end
  local parts = {}
  for k, vv in pairs(v) do
    parts[#parts + 1] = tostring(k) .. "=" .. DescribeValue(vv, depth - 1)
    if #parts >= 8 then parts[#parts + 1] = "..."; break end
  end
  return "{" .. table.concat(parts, ", ") .. "}"
end

-- Flat "key=value" strings for up to `limit` entries of a table -- enough to
-- see its shape (is it keyed by name or by id? nested tables or plain?)
-- without dumping something unbounded into SavedVariables.
local function SampleKeys(t, limit)
  if type(t) ~= "table" then return nil end
  local out = {}
  for k, v in pairs(t) do
    out[#out + 1] = tostring(k) .. "=" .. DescribeValue(v, 2)
    if #out >= (limit or 8) then break end
  end
  return out
end

-- PerkDatabase entries are one level deeper (spellId -> {quality=, comment=,
-- requiredSpell=, ...}) -- sample those fields directly rather than just
-- "table(4 keys)", since the field names are exactly what detection needs.
local function SamplePerkDatabase(db, limit)
  if type(db) ~= "table" then return nil end
  local out = {}
  for spellId, data in pairs(db) do
    if type(data) == "table" then
      local fields = {}
      for k, v in pairs(data) do
        fields[#fields + 1] = tostring(k) .. "=" .. tostring(v)
      end
      out[#out + 1] = tostring(spellId) .. " -> {" .. table.concat(fields, ", ") .. "}"
      if #out >= (limit or 5) then break end
    end
  end
  return out
end

-- Case-insensitive substring search across every data source we know about,
-- for pinning down one specific Echo/Tome by name instead of reading through
-- truncated samples.
local function SearchOwnershipSources(term)
  local lowerTerm = string.lower(term)
  local results = { term = term }
  local own = ns.GetOwnershipState()

  for id, e in pairs(EchoCodexDataEchoes) do
    if string.find(string.lower(e.n), lowerTerm, 1, true) then
      results.ownData = results.ownData or {}
      results.ownData[#results.ownData + 1] = string.format(
        "id=%d name=%s tome=%s knownByUs=%s exactIdOwned=%s inCurrentBuild=%s",
        id, e.n, tostring(EchoCodexEchoToTome[id]), tostring(EC.IsEchoKnown(e)),
        tostring(own.ownedIds[id] == true), tostring(own.currentBuildIds[id] == true))
    end
  end

  local requiredSpellsToProbe = {}

  if ProjectEbonhold and type(ProjectEbonhold.PerkDatabase) == "table" then
    for spellId, data in pairs(ProjectEbonhold.PerkDatabase) do
      if type(data) == "table" and type(data.comment) == "string"
          and string.find(string.lower(data.comment), lowerTerm, 1, true) then
        results.perkDatabaseMatches = results.perkDatabaseMatches or {}
        local fields = {}
        for k, v in pairs(data) do
          if type(v) ~= "table" then fields[#fields + 1] = tostring(k) .. "=" .. tostring(v) end
        end
        results.perkDatabaseMatches[#results.perkDatabaseMatches + 1] =
          tostring(spellId) .. " -> {" .. table.concat(fields, ", ") .. "}"
        if type(data.requiredSpell) == "number" and data.requiredSpell > 0 then
          requiredSpellsToProbe[data.requiredSpell] = true
        end
      end
    end
  end

  -- Also probe (matched Echo's own id + 100000), even without PerkDatabase,
  -- since that convention held for the one case we've confirmed so far.
  if results.ownData then
    for id in pairs(EchoCodexDataEchoes) do
      if string.find(string.lower(EchoCodexDataEchoes[id].n), lowerTerm, 1, true) then
        requiredSpellsToProbe[id + 100000] = true
      end
    end
  end

  if next(requiredSpellsToProbe) then
    results.spellKnownProbes = {}
    results.spellKnownApisPresent = {
      IsSpellKnown = (IsSpellKnown ~= nil),
      IsPlayerSpell = (IsPlayerSpell ~= nil),
      IsUsableSpell = (IsUsableSpell ~= nil),
    }
    for reqSpell in pairs(requiredSpellsToProbe) do
      local line = "requiredSpell=" .. reqSpell .. ":"
      if IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, reqSpell)
        line = line .. " IsSpellKnown=" .. (ok and tostring(known) or "error")
      end
      if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, reqSpell)
        line = line .. " IsPlayerSpell=" .. (ok and tostring(known) or "error")
      end
      local nameOk, spellName = pcall(GetSpellInfo, reqSpell)
      line = line .. " GetSpellInfo=" .. (nameOk and tostring(spellName) or "error")
      results.spellKnownProbes[#results.spellKnownProbes + 1] = line
    end
  end

  if results.ownData and ProjectEbonhold then
    local service = ProjectEbonhold.PerkService
    local discovered
    if service and service.GetDiscoveredEchoes then
      local ok, d = pcall(service.GetDiscoveredEchoes)
      if ok and type(d) == "table" then discovered = d end
    end
    if not discovered and ProjectEbonhold.Perks and type(ProjectEbonhold.Perks.discoveredEchoes) == "table" then
      discovered = ProjectEbonhold.Perks.discoveredEchoes
    end
    results.discoveredEchoesAvailable = (discovered ~= nil)
    if discovered then
      results.discoveredEchoesProbes = {}
      for id in pairs(EchoCodexDataEchoes) do
        if string.find(string.lower(EchoCodexDataEchoes[id].n), lowerTerm, 1, true) then
          local groupId
          if ProjectEbonhold.PerkDatabase and ProjectEbonhold.PerkDatabase[id] then
            groupId = ProjectEbonhold.PerkDatabase[id].groupId
          end
          results.discoveredEchoesProbes[#results.discoveredEchoesProbes + 1] = string.format(
            "id=%d: discovered[id]=%s discovered[id+100000]=%s groupId=%s",
            id, tostring(discovered[id] ~= nil), tostring(discovered[id + 100000] ~= nil), tostring(groupId))
        end
      end
    end
  end

  local function SearchNamedTable(t, label)
    if type(t) ~= "table" then return end
    for k, v in pairs(t) do
      if type(k) == "string" and string.find(string.lower(k), lowerTerm, 1, true) then
        results[label] = results[label] or {}
        results[label][#results[label] + 1] = tostring(k) .. "=" .. DescribeValue(v, 2)
      end
    end
  end

  -- Indexed tables (locked slots are keyed 1..5, not by name) -- search the
  -- string fields *inside* each entry instead of the key.
  local function SearchIndexedTable(t, label)
    if type(t) ~= "table" then return end
    for k, v in pairs(t) do
      if type(v) == "table" then
        for vk, vv in pairs(v) do
          if type(vv) == "string" and string.find(string.lower(vv), lowerTerm, 1, true) then
            results[label] = results[label] or {}
            results[label][#results[label] + 1] = tostring(k) .. "." .. tostring(vk) .. "=" .. vv
          end
        end
      end
    end
  end

  if ProjectEbonhold then
    local service = ProjectEbonhold.PerkService
    if service and service.RequestGrantedPerks then
      pcall(service.RequestGrantedPerks)
    end
    if service and service.GetGrantedPerks then
      local ok, granted = pcall(service.GetGrantedPerks)
      if ok then
        SearchNamedTable(granted, "grantedPerksMatches")
        SearchIndexedTable(granted, "grantedPerksMatches")
      end
    end
    if service and service.GetLockedPerks then
      local ok, locked = pcall(service.GetLockedPerks)
      if ok then
        SearchNamedTable(locked, "lockedPerksMatches")
        SearchIndexedTable(locked, "lockedPerksMatches")
      end
    end
    if ProjectEbonhold.Perks then
      SearchNamedTable(ProjectEbonhold.Perks.grantedPerks, "perksGrantedMatches")
      SearchIndexedTable(ProjectEbonhold.Perks.grantedPerks, "perksGrantedMatches")
      SearchNamedTable(ProjectEbonhold.Perks.lockedPerks, "perksLockedMatches")
      SearchIndexedTable(ProjectEbonhold.Perks.lockedPerks, "perksLockedMatches")
    end
  end
  if ProjectEbonholdDB then
    SearchNamedTable(ProjectEbonholdDB.cachedPerkCounts, "cachedPerkCountsMatches")
  end

  return results
end

function EC.DebugOwnership(term)
  EC.RefreshOwnedCache()
  local own = ns.GetOwnershipState()
  local n = 0
  for _ in pairs(own.ownedIds) do n = n + 1 end

  local d = {
    time = date and date("%Y-%m-%d %H:%M:%S") or "?",
    foundEchoesTab = own.foundEchoesTab,
    spellTabsSeen = own.lastSeenTabNames,
    tomesSeenInSpellbook = #own.lastScanDebug.tomeSpellIds,
    matchedByName = own.lastScanDebug.matchedByName,
    matchedById = own.lastScanDebug.matchedById,
    matchedByReq = own.lastScanDebug.matchedByReq,
    unmatchedTomeNames = own.lastScanDebug.unmatchedNames,
    totalKnownEchoes = n,
    projectEbonholdPresent = (ProjectEbonhold ~= nil),
  }

  if ProjectEbonhold then
    local service = ProjectEbonhold.PerkService
    d.perkServicePresent = (service ~= nil)
    if service then
      d.getDiscoveredEchoesPresent = (service.GetDiscoveredEchoes ~= nil)
      if service.GetDiscoveredEchoes then
        local ok, discovered = pcall(service.GetDiscoveredEchoes)
        d.discoveredEchoesOk = ok
        d.discoveredEchoesType = ok and type(discovered) or nil
        d.discoveredEchoesKeyCount = ok and CountKeys(discovered) or nil
        d.discoveredEchoesSample = ok and SampleKeys(discovered, 100) or nil
      end
      d.requestGrantedPerksPresent = (service.RequestGrantedPerks ~= nil)
      -- (EC.RefreshOwnedCache(), called above, already called RequestGrantedPerks()
      -- before this reads GetGrantedPerks(), so this reflects the refreshed set.)
      if service.GetGrantedPerks then
        local ok, granted = pcall(service.GetGrantedPerks)
        d.grantedPerksOk = ok
        d.grantedPerksType = ok and type(granted) or nil
        d.grantedPerksKeyCount = ok and CountKeys(granted) or nil
        d.grantedPerksSample = ok and SampleKeys(granted, 100) or nil
      end
      if service.GetLockedPerks then
        local ok, locked = pcall(service.GetLockedPerks)
        d.lockedPerksOk = ok
        d.lockedPerksType = ok and type(locked) or nil
        d.lockedPerksKeyCount = ok and CountKeys(locked) or nil
        d.lockedPerksSample = ok and SampleKeys(locked, 100) or nil
      end
    end
    if ProjectEbonhold.Perks then
      d.perksGrantedPerksKeyCount = CountKeys(ProjectEbonhold.Perks.grantedPerks)
      d.perksGrantedPerksSample = SampleKeys(ProjectEbonhold.Perks.grantedPerks, 100)
      d.perksLockedPerksKeyCount = CountKeys(ProjectEbonhold.Perks.lockedPerks)
      d.perksLockedPerksSample = SampleKeys(ProjectEbonhold.Perks.lockedPerks, 100)
    end
    d.perkDatabaseKeyCount = CountKeys(ProjectEbonhold.PerkDatabase)
    d.perkDatabaseSample = SamplePerkDatabase(ProjectEbonhold.PerkDatabase, 5)
  end

  if ProjectEbonholdDB and type(ProjectEbonholdDB.cachedPerkCounts) == "table" then
    d.cachedPerkCountsKeyCount = CountKeys(ProjectEbonholdDB.cachedPerkCounts)
    d.cachedPerkCountsSample = SampleKeys(ProjectEbonholdDB.cachedPerkCounts, 100)
    local positive, zero, nonNumber = 0, 0, 0
    for _, count in pairs(ProjectEbonholdDB.cachedPerkCounts) do
      if type(count) == "number" then
        if count > 0 then positive = positive + 1 else zero = zero + 1 end
      else
        nonNumber = nonNumber + 1
      end
    end
    d.cachedPerkCountsPositive = positive
    d.cachedPerkCountsZero = zero
    d.cachedPerkCountsNonNumber = nonNumber
  end

  if term and term ~= "" then
    d.search = SearchOwnershipSources(term)
  end

  EchoCodexDB.lastDebug = d

  local p = "|cffffd100[Echo Codex]|r "
  DEFAULT_CHAT_FRAME:AddMessage(p .. "Debug info saved. Type |cff71d5ff/reload|r to flush it to disk, then it's in:")
  DEFAULT_CHAT_FRAME:AddMessage(p .. "WTF\\Account\\<ACCOUNT>\\SavedVariables\\EchoCodex.lua  (look for EchoCodexDB.lastDebug)")
  DEFAULT_CHAT_FRAME:AddMessage(p .. "Quick summary: Echoes tab found=" .. tostring(own.foundEchoesTab)
    .. ", tomes in spellbook=" .. d.tomesSeenInSpellbook
    .. ", ProjectEbonhold present=" .. tostring(d.projectEbonholdPresent)
    .. ", cachedPerkCounts>0=" .. tostring(d.cachedPerkCountsPositive)
    .. ", known Echoes=" .. n)
  if term and term ~= "" then
    DEFAULT_CHAT_FRAME:AddMessage(p .. "Searched for \"" .. term .. "\" -- see EchoCodexDB.lastDebug.search after reload.")
  end
end
