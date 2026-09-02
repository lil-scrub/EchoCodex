-- Echo Codex -- formatting, filtering, and tooltip helpers.
--
-- Reads the static data snapshots (EchoCodexDataEchoes / EchoCodexTomes /
-- EchoCodexLocations / EchoCodexZones from Data/Echoes.lua and
-- Data/Tomes.lua) but holds no mutable addon state of its own.

local ADDON_NAME, ns = ...

local band = ns.band
local ALL_CLASS_MASK = ns.ALL_CLASS_MASK
local CLASS_MASK_INFO = ns.CLASS_MASK_INFO
local QUALITY_COLORS = ns.QUALITY_COLORS

local function ClassMaskToColoredString(cm)
  if cm == ALL_CLASS_MASK then return "All Classes" end
  local parts = {}
  for _, c in ipairs(CLASS_MASK_INFO) do
    if band(cm, c.mask) ~= 0 then
      local col = RAID_CLASS_COLORS and RAID_CLASS_COLORS[c.file]
      if col then
        parts[#parts + 1] = string.format("|cff%02x%02x%02x%s|r", col.r * 255, col.g * 255, col.b * 255, c.label)
      else
        parts[#parts + 1] = c.label
      end
    end
  end
  if #parts == 0 then return "Unknown" end
  return table.concat(parts, ", ")
end

local function RoleListToString(f)
  if not f or #f == 0 then return nil end
  return table.concat(f, ", ")
end

local function EchoMatchesFilters(e, state)
  if state.classMask and band(e.cm, state.classMask) == 0 then return false end
  if state.qualitySet and next(state.qualitySet) ~= nil and not state.qualitySet[e.q] then return false end
  if state.role then
    local found = false
    if e.f then
      for _, r in ipairs(e.f) do
        if r == state.role then found = true break end
      end
    end
    if not found then return false end
  end
  if state.tomeOnly and not e.t then return false end
  if state.search and state.search ~= "" then
    local hay = string.lower(e.n .. "  " .. e.d)
    if not string.find(hay, state.search, 1, true) then return false end
  end
  return true
end

local function GetFilteredEchoes(state, idFilter)
  local out = {}
  for id, e in pairs(EchoCodexDataEchoes) do
    if (not idFilter or idFilter[id]) and EchoMatchesFilters(e, state) then
      e.id = id
      out[#out + 1] = e
    end
  end
  table.sort(out, function(a, b)
    if a.q ~= b.q then return a.q > b.q end
    return a.n < b.n
  end)
  return out
end

local function LocationSummary(locs)
  if not locs or #locs == 0 then return "|cff888888Location not documented yet|r" end
  local zoneName = EchoCodexZones[locs[1].zone] or locs[1].zone
  local s = zoneName .. " - " .. (locs[1].placeName or "?")
  if #locs > 1 then
    s = s .. string.format(" (+%d more)", #locs - 1)
  end
  return s
end

local function ShowTomeTooltip(owner, tomeId)
  local tome = EchoCodexTomes[tomeId]
  if not tome then return end
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  local q = (tome.quality == "epic") and QUALITY_COLORS[3] or QUALITY_COLORS[2]
  GameTooltip:SetText(tome.name, q.r, q.g, q.b)
  if tome.description and tome.description ~= "" then
    GameTooltip:AddLine(tome.description, 0.9, 0.9, 0.9, true)
  end
  local locs = EchoCodexLocations[tomeId]
  GameTooltip:AddLine(" ")
  if not locs or #locs == 0 then
    GameTooltip:AddLine("Location not documented yet.", 0.6, 0.6, 0.6, true)
  else
    GameTooltip:AddLine("Drop locations:", 1, 0.82, 0)
    for _, loc in ipairs(locs) do
      local zoneName = EchoCodexZones[loc.zone] or loc.zone
      local line = zoneName .. " - " .. (loc.placeName or "?")
      GameTooltip:AddLine(line, 1, 1, 1)
      if loc.mobs and #loc.mobs > 0 then
        GameTooltip:AddLine("  " .. table.concat(loc.mobs, ", "), 0.7, 0.7, 0.7, true)
      end
      if loc.notes and loc.notes ~= "" then
        GameTooltip:AddLine("  " .. loc.notes, 0.5, 0.5, 0.5, true)
      end
    end
  end
  GameTooltip:Show()
end

ns.ClassMaskToColoredString = ClassMaskToColoredString
ns.RoleListToString = RoleListToString
ns.EchoMatchesFilters = EchoMatchesFilters
ns.GetFilteredEchoes = GetFilteredEchoes
ns.LocationSummary = LocationSummary
ns.ShowTomeTooltip = ShowTomeTooltip
