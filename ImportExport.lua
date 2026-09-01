-- Echo Codex -- wishlist import/export (Echo Journal EWL1/EBH1 and
-- EbonholdHub Build exports).

local ADDON_NAME, ns = ...

local EC = ns.EC
local myClassFile = ns.myClassFile

local ROW_HEIGHT = ns.ROW_HEIGHT
local FRAME_WIDTH = ns.FRAME_WIDTH
local FRAME_HEIGHT = ns.FRAME_HEIGHT
local QUALITY_NAMES = ns.QUALITY_NAMES
local QUALITY_COLORS = ns.QUALITY_COLORS
local ROLE_LIST = ns.ROLE_LIST
local CLASS_MASK_INFO = ns.CLASS_MASK_INFO
local CLASS_BY_FILE = ns.CLASS_BY_FILE
local FLAT_TEX = ns.FLAT_TEX
local THEME = ns.THEME

local Fill = ns.Fill
local ThinBorder = ns.ThinBorder
local SetBorderColor = ns.SetBorderColor
local CreateFlatButton = ns.CreateFlatButton
local CreateFlatCheckbox = ns.CreateFlatCheckbox
local CreateList = ns.CreateList

local NewWishlist = ns.NewWishlist

local ClassMaskToColoredString = ns.ClassMaskToColoredString
local RoleListToString = ns.RoleListToString
local GetFilteredEchoes = ns.GetFilteredEchoes
local LocationSummary = ns.LocationSummary
local ShowTomeTooltip = ns.ShowTomeTooltip

----------------------------------------------------------------------
-- EBH / Echo Journal wishlist import
--
-- The server's Echo Journal (ProjectEbonhold addon) exports a player's
-- tiered wishlist as "EWL1:CLASS:spellId:flag,spellId:flag,...", and
-- EbonholdHub exports a saved Build as "EBH1:spellId.code.stack,...:CLASS:Title".
-- Both use the same Echo spell IDs (>=200000) as our own data, so we can
-- pull the id list straight out of either string with a couple of gmatch
-- passes -- no dependency on EbonholdHub actually being installed/loaded.
----------------------------------------------------------------------

-- EbonholdHub's "Export" / "Copy export for site" buttons produce a
-- completely different format from the plain EWL1:/EBH1: strings above: a
-- base64-encoded JSON blob of the whole Build (talents, gear, echo tiers,
-- the works). EbonholdHub itself has to decode this to read it back, so we
-- lean on its own EbonholdHub.ExportImport.DecodeBuild() rather than
-- reimplementing base64+JSON -- this only works while EbonholdHub is
-- installed, but then again so does producing this string in the first place.
local function TryDecodeEbonholdHubBuildExport(text)
  if not (EbonholdHub and EbonholdHub.ExportImport and EbonholdHub.ExportImport.DecodeBuild) then
    return nil, "That doesn't look like an EWL1:/EBH1: string, and EbonholdHub isn't loaded to decode a Build export either."
  end
  local ok, build = pcall(EbonholdHub.ExportImport.DecodeBuild, text)
  if not ok or not build then
    return nil, "Couldn't decode that as an EbonholdHub Build export."
  end

  local ids, seen = {}, {}
  if type(build.loadoutEchoSpellIds) == "table" then
    for _, spellId in pairs(build.loadoutEchoSpellIds) do
      if type(spellId) == "number" and not seen[spellId] then
        seen[spellId] = true
        ids[#ids + 1] = spellId
      end
    end
  end
  if type(build.lockedEchoes) == "table" then
    for _, entry in pairs(build.lockedEchoes) do
      local spellId = type(entry) == "number" and entry
        or (type(entry) == "table" and (entry.spellId or entry.id)) or nil
      if type(spellId) == "number" and not seen[spellId] then
        seen[spellId] = true
        ids[#ids + 1] = spellId
      end
    end
  end

  if #ids == 0 then
    return nil, "Decoded that Build export fine, but it has no Echoes in it."
  end
  return ids
end

local function ParseEBHWishlistString(text)
  text = (text or ""):gsub("%s+", "")
  if text == "" then
    return nil, "Paste an export string first."
  end

  local ids, seen = {}, {}

  if text:match("^EWL%d+:") then
    for spellIdStr in text:gmatch("(%d+):%d+") do
      local id = tonumber(spellIdStr)
      if id and id >= 200000 and not seen[id] then
        seen[id] = true
        ids[#ids + 1] = id
      end
    end
  elseif text:match("^EBH%d+:") then
    for spellIdStr in text:gmatch("(%d+)%.%d+%.%d+") do
      local id = tonumber(spellIdStr)
      if id and id >= 200000 and not seen[id] then
        seen[id] = true
        ids[#ids + 1] = id
      end
    end
  else
    return TryDecodeEbonholdHubBuildExport(text)
  end

  if #ids == 0 then
    return nil, "No Echo IDs found in that string."
  end

  return ids
end

function EC.ImportEBHWishlist(text)
  local ids, err = ParseEBHWishlistString(text)
  if not ids then
    return false, err
  end

  local added, already, unknown = 0, 0, 0
  for _, id in ipairs(ids) do
    if EchoCodexDataEchoes[id] then
      if ns.activeWishlistItems[id] then
        already = already + 1
      else
        ns.activeWishlistItems[id] = true
        added = added + 1
      end
    else
      unknown = unknown + 1
    end
  end

  EC.RefreshAll()
  return true, { added = added, already = already, unknown = unknown, total = #ids }
end

-- The reverse direction: build an EBH1 string out of the active wishlist,
-- in the same spellId.quality.stack shape Nexus/EbonholdHub/the Echo
-- Journal all produce -- so it pastes straight into any of their own
-- import boxes (Nexus's "Import" button on the Wishlist Editor takes this
-- exact format, per its own Codec.DecodeEBH1).
function EC.ExportActiveWishlistString()
  local parts = {}
  for id in pairs(ns.activeWishlistItems) do
    local echo = EchoCodexDataEchoes[id]
    if echo then
      parts[#parts + 1] = string.format("%d.%d.%d", id, echo.q, 1)
    end
  end
  table.sort(parts)
  local classToken = myClassFile or "UNKNOWN"
  local name = ns.charDB.activeWishlist or "Echo Codex Wishlist"
  return "EBH1:" .. table.concat(parts, ",") .. ":" .. classToken .. ":" .. name, #parts
end

-- Drops every wishlist entry that doesn't need a Tome (auto-learned Echoes
-- you'll pick up naturally while leveling, so there's nothing to track down).
function EC.PruneNonTomeWishlist()
  local removed, keptTome, unknown = 0, 0, 0
  for id in pairs(ns.activeWishlistItems) do
    local echo = EchoCodexDataEchoes[id]
    if not echo then
      unknown = unknown + 1
    elseif not echo.t then
      ns.activeWishlistItems[id] = nil
      removed = removed + 1
    else
      keptTome = keptTome + 1
    end
  end
  EC.RefreshAll()
  return { removed = removed, keptTome = keptTome, unknown = unknown }
end
