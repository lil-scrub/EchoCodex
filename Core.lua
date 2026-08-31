-- Echo Codex
-- Search Project Ebonhold's Echoes, build a wishlist, and check off Tomes as you find them.
-- Data is a static snapshot (see Data_Echoes.lua / Data_Tomes.lua) -- it will drift from the
-- live server as Echoes get added or rebalanced. Report stale data in the Ebonhold Discord.

local ADDON_NAME = ...

----------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------

local ROW_HEIGHT = 30
local FRAME_WIDTH = 720
local FRAME_HEIGHT = 600

local QUALITY_NAMES = { [0] = "Common", [1] = "Uncommon", [2] = "Rare", [3] = "Epic" }
local QUALITY_COLORS = {
  [0] = { r = 1,    g = 1,    b = 1 },
  [1] = { r = 0.12, g = 1,    b = 0 },
  [2] = { r = 0.15, g = 0.55, b = 1 },
  [3] = { r = 0.72, g = 0.35, b = 0.98 },
}

local ROLE_LIST = { "Tank", "Melee DPS", "Ranged DPS", "Caster DPS", "Healer", "Survivability" }

local CLASS_MASK_INFO = {
  { mask = 1,    file = "WARRIOR",     label = "Warrior" },
  { mask = 2,    file = "PALADIN",     label = "Paladin" },
  { mask = 4,    file = "HUNTER",      label = "Hunter" },
  { mask = 8,    file = "ROGUE",       label = "Rogue" },
  { mask = 16,   file = "PRIEST",      label = "Priest" },
  { mask = 32,   file = "DEATHKNIGHT", label = "Death Knight" },
  { mask = 64,   file = "SHAMAN",      label = "Shaman" },
  { mask = 128,  file = "MAGE",        label = "Mage" },
  { mask = 256,  file = "WARLOCK",     label = "Warlock" },
  { mask = 1024, file = "DRUID",       label = "Druid" },
}
local ALL_CLASS_MASK = 0
for _, c in ipairs(CLASS_MASK_INFO) do ALL_CLASS_MASK = ALL_CLASS_MASK + c.mask end

local CLASS_BY_FILE = {}
for _, c in ipairs(CLASS_MASK_INFO) do CLASS_BY_FILE[c.file] = c end

local band = bit and bit.band or function(a, b)
  -- Fallback bitwise AND in case the bit library isn't exposed (shouldn't happen in-client).
  local result, bitval = 0, 1
  while a > 0 and b > 0 do
    if a % 2 == 1 and b % 2 == 1 then result = result + bitval end
    a, b, bitval = math.floor(a / 2), math.floor(b / 2), bitval * 2
  end
  return result
end

----------------------------------------------------------------------
-- Flat theme
--
-- Visually similar to EbonholdHub's UI kit: flat colored panels (a plain
-- white texture tinted via SetVertexColor, no Blizzard dialog art), thin
-- 1px borders, and buttons/checkboxes whose whole rect is the click
-- target -- notably including the close button, which is what made the
-- old Blizzard dialog-border close icon annoying to hit.
----------------------------------------------------------------------

local FLAT_TEX = "Interface\\Buttons\\WHITE8X8"

local THEME = {
  bg         = { 29 / 255, 31 / 255, 41 / 255, 1 },
  bgHeader   = { 37 / 255, 40 / 255, 51 / 255, 1 },
  elementBg  = { 31 / 255, 31 / 255, 38 / 255, 1 },
  elementHov = { 40 / 255, 40 / 255, 48 / 255, 1 },
  border     = { 46 / 255, 46 / 255, 56 / 255, 1 },
  accent     = { 77 / 255, 191 / 255, 242 / 255, 1 },
  text       = { 0.92, 0.92, 0.94, 1 },
  textDim    = { 0.55, 0.55, 0.60, 1 },
  danger     = { 0.90, 0.35, 0.35, 1 },
}

local function Fill(parent, color, layer)
  local tex = parent:CreateTexture(nil, layer or "BACKGROUND")
  tex:SetTexture(FLAT_TEX)
  tex:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
  tex:SetAllPoints(parent)
  return tex
end

local function ThinBorder(frame, color, thickness)
  thickness = thickness or 1
  local function Edge()
    local t = frame:CreateTexture(nil, "BORDER")
    t:SetTexture(FLAT_TEX)
    t:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    return t
  end
  local top, bottom, left, right = Edge(), Edge(), Edge(), Edge()
  top:SetPoint("TOPLEFT", 0, 0); top:SetPoint("TOPRIGHT", 0, 0); top:SetHeight(thickness)
  bottom:SetPoint("BOTTOMLEFT", 0, 0); bottom:SetPoint("BOTTOMRIGHT", 0, 0); bottom:SetHeight(thickness)
  left:SetPoint("TOPLEFT", 0, 0); left:SetPoint("BOTTOMLEFT", 0, 0); left:SetWidth(thickness)
  right:SetPoint("TOPRIGHT", 0, 0); right:SetPoint("BOTTOMRIGHT", 0, 0); right:SetWidth(thickness)
  return { top = top, bottom = bottom, left = left, right = right }
end

local function SetBorderColor(border, color)
  border.top:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
  border.bottom:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
  border.left:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
  border.right:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
end

-- Flat button: fill + thin border + centered label, hover/press feedback.
-- Set its text via btn.label:SetText(...) -- plain Buttons only get a
-- working :SetText() from a Blizzard template, which this deliberately isn't.
local function CreateFlatButton(parent, name, width, height, text)
  local btn = CreateFrame("Button", name, parent)
  btn:SetSize(width, height)
  local bg = Fill(btn, THEME.elementBg)
  local border = ThinBorder(btn, THEME.border, 1)

  local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("CENTER")
  label:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3])
  if text then label:SetText(text) end

  btn:SetScript("OnEnter", function()
    bg:SetVertexColor(THEME.elementHov[1], THEME.elementHov[2], THEME.elementHov[3], 1)
    SetBorderColor(border, THEME.accent)
  end)
  btn:SetScript("OnLeave", function()
    bg:SetVertexColor(THEME.elementBg[1], THEME.elementBg[2], THEME.elementBg[3], 1)
    SetBorderColor(border, THEME.border)
  end)
  btn:SetScript("OnMouseDown", function() label:SetPoint("CENTER", 0, -1) end)
  btn:SetScript("OnMouseUp", function() label:SetPoint("CENTER", 0, 0) end)

  btn.label = label
  btn.bg = bg
  btn.border = border
  return btn
end

-- Flat checkbox: a small tick-box (filled with the accent color when
-- checked) plus an optional clickable label. This is a plain Frame, not a
-- real CheckButton -- use :SetChecked()/:GetChecked() and the
-- .OnValueChanged(checked) callback instead of the CheckButton API.
local function CreateFlatCheckbox(parent, name, text)
  local wrap = CreateFrame("Frame", name, parent)
  wrap:SetHeight(18)

  local box = CreateFrame("Button", nil, wrap)
  box:SetSize(18, 18)
  box:SetPoint("LEFT", 0, 0)
  Fill(box, THEME.elementBg)
  ThinBorder(box, THEME.border, 1)

  local mark = box:CreateTexture(nil, "OVERLAY")
  mark:SetTexture(FLAT_TEX)
  mark:SetVertexColor(THEME.accent[1], THEME.accent[2], THEME.accent[3], 1)
  mark:SetPoint("TOPLEFT", 4, -4)
  mark:SetPoint("BOTTOMRIGHT", -4, 4)
  mark:Hide()

  local labelBtn = CreateFrame("Button", nil, wrap)
  labelBtn:SetPoint("LEFT", box, "RIGHT", 6, 0)
  labelBtn:SetHeight(18)

  local label = labelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("LEFT", 0, 0)
  label:SetJustifyH("LEFT")
  label:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3])

  local totalWidth = 18
  if text and text ~= "" then
    label:SetText(text)
    local textW = math.ceil(label:GetStringWidth() or 0)
    labelBtn:SetWidth(textW + 4)
    totalWidth = 18 + 6 + textW + 4
  else
    labelBtn:SetWidth(1)
  end
  wrap:SetWidth(totalWidth)

  wrap.checked = false
  local function Toggle()
    wrap.checked = not wrap.checked
    if wrap.checked then mark:Show() else mark:Hide() end
    if wrap.OnValueChanged then wrap.OnValueChanged(wrap.checked) end
  end
  box:SetScript("OnClick", Toggle)
  labelBtn:SetScript("OnClick", Toggle)

  function wrap:SetChecked(value)
    self.checked = value and true or false
    if self.checked then mark:Show() else mark:Hide() end
  end
  function wrap:GetChecked()
    return self.checked
  end

  wrap.label = label
  wrap.box = box
  return wrap
end

----------------------------------------------------------------------
-- Saved variables
--
-- Wishlists are per-character: each character keeps its own named,
-- switchable wishlists, since what a Warlock alt wants has nothing to do
-- with what a Priest alt wants. This used to ride on WoW's own
-- SavedVariablesPerCharacter mechanism (a separate EchoCodexCharDB global,
-- declared via "## SavedVariablesPerCharacter:" in the .toc) -- dropped
-- after it never once produced a saved file on the account this was tested
-- on (verified directly: zero EchoCodex.lua under any character's
-- SavedVariables folder, while EbonholdHub's own per-character file sitting
-- right next to it saved and updated normally). Rather than chase why that
-- WoW mechanism silently didn't work here, character separation is now
-- done ourselves, keyed by realm+name, inside the account-wide EchoCodexDB
-- -- the file that demonstrably has been saving correctly the whole time.
----------------------------------------------------------------------

local DEFAULT_WISHLIST_NAME = "Default"

local function NewWishlist()
  return { items = {}, found = {} }
end

local function CharacterKey()
  local realm = (GetRealmName and GetRealmName()) or "UnknownRealm"
  local name = (UnitName and UnitName("player")) or "UnknownCharacter"
  return realm .. " - " .. name
end

-- This character's own slice of the account-wide DB -- everything that used
-- to hang off the old (non-functional) per-character global now hangs off
-- this instead. Same shape, different, proven-reliable root table.
local charDB

-- Live pointers into the currently-active wishlist's tables. These ARE the
-- same table objects stored in charDB.wishlists[name] -- reassigned (not
-- copied) whenever the active wishlist switches, so every existing
-- read/write against them stays correct without threading a wishlist
-- parameter through the whole file.
local activeWishlistItems, activeWishlistFound

local function InitDB()
  EchoCodexDB = EchoCodexDB or {}
  EchoCodexDB.framePos = EchoCodexDB.framePos or nil
  EchoCodexDB.characters = EchoCodexDB.characters or {}

  local key = CharacterKey()
  charDB = EchoCodexDB.characters[key]
  if not charDB then
    charDB = {}
    EchoCodexDB.characters[key] = charDB
  end
  charDB.wishlists = charDB.wishlists or {}

  if not next(charDB.wishlists) then
    local seed = NewWishlist()
    -- One-time migration: pull in whatever this account's old shared
    -- (pre-per-character) wishlist/found tables held, if any.
    for id in pairs(EchoCodexDB.wishlist or {}) do seed.items[id] = true end
    for tomeId in pairs(EchoCodexDB.found or {}) do seed.found[tomeId] = true end
    charDB.wishlists[DEFAULT_WISHLIST_NAME] = seed
    charDB.activeWishlist = DEFAULT_WISHLIST_NAME
  end

  if not charDB.activeWishlist or not charDB.wishlists[charDB.activeWishlist] then
    -- Stale/missing pointer (deleted wishlist, corrupted save) -- fall back
    -- to whatever wishlist happens to exist.
    charDB.activeWishlist = next(charDB.wishlists)
  end

  local active = charDB.wishlists[charDB.activeWishlist]
  active.items = active.items or {}
  active.found = active.found or {}
  activeWishlistItems = active.items
  activeWishlistFound = active.found
end

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

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

----------------------------------------------------------------------
-- Generic recyclable row list (FauxScrollFrame based)
----------------------------------------------------------------------

local listSerial = 0

local function CreateList(parent, width, height, rowFactory)
  listSerial = listSerial + 1
  local container = CreateFrame("Frame", "EchoCodexList" .. listSerial, parent)
  container:SetSize(width, height)

  -- FauxScrollFrameTemplate hangs its scrollbar off the RIGHT of this frame's
  -- own edge (Blizzard's standard scrollbar art is ~31px wide), not inside
  -- it -- so this needs the same gutter the rows reserve below, or the bar
  -- renders mostly outside the container (and often outside the window).
  local scroll = CreateFrame("ScrollFrame", "EchoCodexListScroll" .. listSerial, container, "FauxScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 0, 0)
  scroll:SetPoint("BOTTOMRIGHT", -26, 0)

  local list = { data = {}, rows = {}, container = container, scroll = scroll }
  list.numVisible = math.floor(height / ROW_HEIGHT)

  for i = 1, list.numVisible do
    local row = rowFactory(container, i)
    row:SetPoint("TOPLEFT", container, "TOPLEFT", 2, -((i - 1) * ROW_HEIGHT))
    row:SetPoint("RIGHT", container, "RIGHT", -26, 0)
    row:SetHeight(ROW_HEIGHT - 2)
    row:Hide()
    list.rows[i] = row
  end

  scroll:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, function() list:Refresh() end)
  end)

  -- resetScroll defaults to false/omitted: most SetData calls are just "the
  -- same list, something in it changed" (a background ownership refresh, an
  -- add/remove) and should hold the scroll position, not yank the reader
  -- back to the top mid-scroll. Pass true only where the result set itself
  -- is genuinely new -- a search/filter change, or switching wishlists.
  function list:SetData(data, resetScroll)
    self.data = data
    if resetScroll then
      -- FauxScrollFrame_SetOffset isn't in the 3.3.5 API; set the field directly.
      self.scroll.offset = 0
      self.scroll:SetVerticalScroll(0)
    end
    self:Refresh()
  end

  function list:Refresh()
    -- Clamp defensively if the data shrank (e.g. Checklist entries
    -- auto-clearing) past the currently scrolled-to offset.
    local maxOffset = math.max(0, #self.data - self.numVisible)
    if (self.scroll.offset or 0) > maxOffset then
      self.scroll.offset = maxOffset
      self.scroll:SetVerticalScroll(maxOffset * ROW_HEIGHT)
    end
    FauxScrollFrame_Update(self.scroll, #self.data, self.numVisible, ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(self.scroll)
    for i = 1, self.numVisible do
      local row = self.rows[i]
      local item = self.data[offset + i]
      if item then
        self.updateRow(row, item, offset + i)
        row:Show()
      else
        row:Hide()
      end
    end
  end

  return list
end

----------------------------------------------------------------------
-- Main frame + tabs
----------------------------------------------------------------------

local EC = {}
EC.state = {
  search = "",
  classMask = nil,
  qualitySet = {},
  role = nil,
  tomeOnly = false,
}

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

local function CountKeys(t)
  if type(t) ~= "table" then return nil end
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

-- Flat "key=value" strings for up to `limit` entries of a table -- enough to
-- see its shape (is it keyed by name or by id? nested tables or plain?)
-- without dumping something unbounded into SavedVariables.
local function SampleKeys(t, limit)
  if type(t) ~= "table" then return nil end
  local out = {}
  for k, v in pairs(t) do
    local vDesc
    if type(v) == "table" then
      vDesc = "table(" .. tostring(CountKeys(v)) .. " keys)"
    else
      vDesc = tostring(v)
    end
    out[#out + 1] = tostring(k) .. "=" .. vDesc
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

  for id, e in pairs(EchoCodexDataEchoes) do
    if string.find(string.lower(e.n), lowerTerm, 1, true) then
      results.ownData = results.ownData or {}
      results.ownData[#results.ownData + 1] = string.format(
        "id=%d name=%s tome=%s knownByUs=%s",
        id, e.n, tostring(EchoCodexEchoToTome[id]), tostring(EC.IsEchoKnown(e)))
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
        local vDesc = type(v) == "table" and ("table(" .. tostring(CountKeys(v)) .. " keys)") or tostring(v)
        results[label][#results[label] + 1] = tostring(k) .. "=" .. vDesc
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
  local n = 0
  for _ in pairs(ownedIds) do n = n + 1 end

  local d = {
    time = date and date("%Y-%m-%d %H:%M:%S") or "?",
    foundEchoesTab = foundEchoesTab,
    spellTabsSeen = lastSeenTabNames,
    tomesSeenInSpellbook = #lastScanDebug.tomeSpellIds,
    matchedByName = lastScanDebug.matchedByName,
    matchedById = lastScanDebug.matchedById,
    matchedByReq = lastScanDebug.matchedByReq,
    unmatchedTomeNames = lastScanDebug.unmatchedNames,
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
  DEFAULT_CHAT_FRAME:AddMessage(p .. "Quick summary: Echoes tab found=" .. tostring(foundEchoesTab)
    .. ", tomes in spellbook=" .. d.tomesSeenInSpellbook
    .. ", ProjectEbonhold present=" .. tostring(d.projectEbonholdPresent)
    .. ", cachedPerkCounts>0=" .. tostring(d.cachedPerkCountsPositive)
    .. ", known Echoes=" .. n)
  if term and term ~= "" then
    DEFAULT_CHAT_FRAME:AddMessage(p .. "Searched for \"" .. term .. "\" -- see EchoCodexDB.lastDebug.search after reload.")
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

function EC.RefreshOwnedCache()
  ownedIds, ownedNames = {}, {}
  foundEchoesTab = false

  -- Kept as a secondary check: permanently-learned Tomes, if they ever do
  -- show up in a spellbook tab (standard Blizzard API, no ProjectEbonhold
  -- dependency) -- hasn't fired on the one account this was verified
  -- against, but costs nothing to leave in for other classes/specs.
  ScanSpellbookTomes()

  if not ProjectEbonhold then return end

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
      if ok then ScanForOwnership(granted, {}) end
    end
    if service.GetLockedPerks then
      local ok, locked = pcall(service.GetLockedPerks)
      if ok then ScanForOwnership(locked, {}) end
    end
  end

  if ProjectEbonhold.Perks then
    ScanForOwnership(ProjectEbonhold.Perks.grantedPerks, {})
    ScanForOwnership(ProjectEbonhold.Perks.lockedPerks, {})
  end

  if ProjectEbonholdDB and type(ProjectEbonholdDB.cachedPerkCounts) == "table" then
    for name, count in pairs(ProjectEbonholdDB.cachedPerkCounts) do
      if type(name) == "string" and (type(count) ~= "number" or count > 0) then
        local norm = NormalizeOwnedName(name)
        if norm then ownedNames[norm] = true end
      end
    end
  end
end

function EC.HasOwnershipData()
  return foundEchoesTab or ProjectEbonhold ~= nil
end

function EC.IsEchoKnown(echo)
  if ownedIds[echo.id] then return true end
  local norm = NormalizeOwnedName(echo.n)
  return norm ~= nil and ownedNames[norm] == true
end

local mainFrame, tabButtons, tabFrames, activeTab
local browseList, wishlistList, checklistList
local resultCountFS, wishlistCountFS, checklistProgressFS
local wishlistEmptyText, checklistEmptyText

local function BuildTabButton(parent, name, text)
  local btn = CreateFrame("Button", name, parent)
  btn:SetHeight(24)

  local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("CENTER")
  label:SetText(text)
  btn:SetWidth(math.max(70, math.ceil(label:GetStringWidth() or 0) + 20))

  local underline = btn:CreateTexture(nil, "ARTWORK")
  underline:SetTexture(FLAT_TEX)
  underline:SetVertexColor(THEME.accent[1], THEME.accent[2], THEME.accent[3], 1)
  underline:SetPoint("BOTTOMLEFT", 0, 0)
  underline:SetPoint("BOTTOMRIGHT", 0, 0)
  underline:SetHeight(2)
  underline:Hide()

  btn.label = label
  btn.underline = underline
  return btn
end

local function SelectTab(name)
  EC.RefreshOwnedCache()
  activeTab = name
  for n, f in pairs(tabFrames) do
    if n == name then f:Show() else f:Hide() end
  end
  for n, b in pairs(tabButtons) do
    if n == name then
      b.underline:Show()
      b.label:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3])
    else
      b.underline:Hide()
      b.label:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3])
    end
  end
  if name == "browse" and browseList then browseList:Refresh()
  elseif name == "wishlist" then EC.RefreshWishlist()
  elseif name == "checklist" then EC.RefreshChecklist()
  end
end

----------------------------------------------------------------------
-- Browse tab
----------------------------------------------------------------------

local function BrowseRowFactory(parent, i)
  local row = CreateFrame("Button", "EchoCodexBrowseRow" .. i, parent)
  row:SetHeight(ROW_HEIGHT - 2)

  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints()
  row.bg:SetTexture(1, 1, 1, (i % 2 == 0) and 0.04 or 0.0)

  row.nameText = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  row.nameText:SetPoint("LEFT", 6, 0)
  row.nameText:SetJustifyH("LEFT")
  row.nameText:SetWidth(310)

  row.metaText = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  row.metaText:SetPoint("LEFT", row.nameText, "RIGHT", 6, 0)
  row.metaText:SetJustifyH("LEFT")
  row.metaText:SetWidth(175)

  row.actionBtn = CreateFlatButton(row, "EchoCodexBrowseRowBtn" .. i, 64, 20, "Add")
  row.actionBtn:SetPoint("RIGHT", -2, 0)

  row:SetScript("OnEnter", function(self)
    if not self.echo then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local c = QUALITY_COLORS[self.echo.q]
    GameTooltip:SetText(self.echo.n, c.r, c.g, c.b)
    GameTooltip:AddLine(self.echo.d, 0.9, 0.9, 0.9, true)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(ClassMaskToColoredString(self.echo.cm), 1, 1, 1, true)
    local roles = RoleListToString(self.echo.f)
    if roles then GameTooltip:AddLine(roles, 0.6, 0.6, 0.6) end
    if self.echo.t then
      GameTooltip:AddLine("Requires learning a Tome", 1, 0.82, 0)
    end
    if EC.IsEchoKnown(self.echo) then
      GameTooltip:AddLine("You already know this Echo", 0.29, 0.82, 0.5)
    end
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)

  return row
end

local function BrowseUpdateRow(row, echo)
  row.echo = echo
  local c = QUALITY_COLORS[echo.q]
  row.nameText:SetText(echo.n)
  row.nameText:SetTextColor(c.r, c.g, c.b)

  local bits = {}
  if echo.lvl and echo.lvl > 1 then bits[#bits + 1] = "Lv " .. echo.lvl end
  if echo.t then bits[#bits + 1] = "|cffffd100Tome|r" end
  if EC.IsEchoKnown(echo) then bits[#bits + 1] = "|cff4ade80Known|r" end
  row.metaText:SetText(table.concat(bits, "   "))

  local inWishlist = activeWishlistItems[echo.id]
  row.actionBtn.label:SetText(inWishlist and "Remove" or "Add")
  row.actionBtn:SetScript("OnClick", function()
    if activeWishlistItems[echo.id] then
      activeWishlistItems[echo.id] = nil
    else
      activeWishlistItems[echo.id] = true
    end
    EC.RefreshAll()
  end)
end

local classDropdown, roleDropdown
local myClassFile = select(2, UnitClass("player"))

local function ClassDropdown_Init(self, level)
  local info = UIDropDownMenu_CreateInfo()
  local myClassInfo = CLASS_BY_FILE[myClassFile]
  if myClassInfo then
    info = UIDropDownMenu_CreateInfo()
    info.text = "My Class (" .. myClassInfo.label .. ")"
    info.func = function()
      EC.state.classMask = myClassInfo.mask
      UIDropDownMenu_SetText(classDropdown, info.text)
      browseList:SetData(GetFilteredEchoes(EC.state), true)
      EC.UpdateResultCount()
    end
    UIDropDownMenu_AddButton(info)
  end

  info = UIDropDownMenu_CreateInfo()
  info.text = "All Classes"
  info.func = function()
    EC.state.classMask = nil
    UIDropDownMenu_SetText(classDropdown, "All Classes")
    browseList:SetData(GetFilteredEchoes(EC.state), true)
    EC.UpdateResultCount()
  end
  UIDropDownMenu_AddButton(info)

  local sorted = {}
  for _, c in ipairs(CLASS_MASK_INFO) do sorted[#sorted + 1] = c end
  table.sort(sorted, function(a, b) return a.label < b.label end)

  for _, c in ipairs(sorted) do
    info = UIDropDownMenu_CreateInfo()
    info.text = c.label
    info.func = function()
      EC.state.classMask = c.mask
      UIDropDownMenu_SetText(classDropdown, c.label)
      browseList:SetData(GetFilteredEchoes(EC.state), true)
      EC.UpdateResultCount()
    end
    UIDropDownMenu_AddButton(info)
  end
end

local function RoleDropdown_Init(self, level)
  local info = UIDropDownMenu_CreateInfo()
  info.text = "All Roles"
  info.func = function()
    EC.state.role = nil
    UIDropDownMenu_SetText(roleDropdown, "All Roles")
    browseList:SetData(GetFilteredEchoes(EC.state), true)
    EC.UpdateResultCount()
  end
  UIDropDownMenu_AddButton(info)

  for _, r in ipairs(ROLE_LIST) do
    info = UIDropDownMenu_CreateInfo()
    info.text = r
    info.func = function()
      EC.state.role = r
      UIDropDownMenu_SetText(roleDropdown, r)
      browseList:SetData(GetFilteredEchoes(EC.state), true)
      EC.UpdateResultCount()
    end
    UIDropDownMenu_AddButton(info)
  end
end

local function BuildBrowseTab(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:SetAllPoints()

  local searchHolder = CreateFrame("Frame", nil, f)
  searchHolder:SetSize(300, 22)
  searchHolder:SetPoint("TOPLEFT", 12, -14)
  Fill(searchHolder, THEME.elementBg)
  local searchBorder = ThinBorder(searchHolder, THEME.border, 1)

  local search = CreateFrame("EditBox", "EchoCodexSearchBox", searchHolder)
  search:SetPoint("TOPLEFT", 6, -3)
  search:SetPoint("BOTTOMRIGHT", -6, 3)
  search:SetAutoFocus(false)
  search:SetFontObject(GameFontHighlightSmall)
  search:SetTextInsets(0, 0, 0, 0)
  search:SetScript("OnTextChanged", function(self)
    EC.state.search = string.lower(self:GetText() or "")
    browseList:SetData(GetFilteredEchoes(EC.state), true)
    EC.UpdateResultCount()
  end)
  search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  search:SetScript("OnEditFocusGained", function() SetBorderColor(searchBorder, THEME.accent) end)
  search:SetScript("OnEditFocusLost", function() SetBorderColor(searchBorder, THEME.border) end)

  local searchLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  searchLabel:SetPoint("BOTTOMLEFT", searchHolder, "TOPLEFT", 0, 2)
  searchLabel:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3])
  searchLabel:SetText("Search name or description")

  classDropdown = CreateFrame("Frame", "EchoCodexClassDropdown", f, "UIDropDownMenuTemplate")
  classDropdown:SetPoint("LEFT", searchHolder, "RIGHT", 2, -2)
  UIDropDownMenu_SetWidth(classDropdown, 130)
  UIDropDownMenu_Initialize(classDropdown, ClassDropdown_Init)
  UIDropDownMenu_SetText(classDropdown, "All Classes")

  roleDropdown = CreateFrame("Frame", "EchoCodexRoleDropdown", f, "UIDropDownMenuTemplate")
  roleDropdown:SetPoint("LEFT", classDropdown, "RIGHT", 6, 0)
  UIDropDownMenu_SetWidth(roleDropdown, 130)
  UIDropDownMenu_Initialize(roleDropdown, RoleDropdown_Init)
  UIDropDownMenu_SetText(roleDropdown, "All Roles")

  -- Quality toggle chips + tome-only, chained left-to-right by measured width.
  local qualityRow = CreateFrame("Frame", nil, f)
  qualityRow:SetSize(500, 20)
  qualityRow:SetPoint("TOPLEFT", searchHolder, "BOTTOMLEFT", 0, -14)

  local prevChip
  for q = 0, 3 do
    local cb = CreateFlatCheckbox(qualityRow, "EchoCodexQualityCB" .. q, QUALITY_NAMES[q])
    if prevChip then cb:SetPoint("LEFT", prevChip, "RIGHT", 16, 0) else cb:SetPoint("LEFT", 0, 0) end
    local c = QUALITY_COLORS[q]
    cb.label:SetTextColor(c.r, c.g, c.b)
    cb.OnValueChanged = function(checked)
      if checked then
        EC.state.qualitySet[q] = true
      else
        EC.state.qualitySet[q] = nil
      end
      browseList:SetData(GetFilteredEchoes(EC.state), true)
      EC.UpdateResultCount()
    end
    prevChip = cb
  end

  local tomeCB = CreateFlatCheckbox(qualityRow, "EchoCodexTomeOnlyCB", "Tome-locked only")
  tomeCB:SetPoint("LEFT", prevChip, "RIGHT", 20, 0)
  tomeCB.OnValueChanged = function(checked)
    EC.state.tomeOnly = checked and true or false
    browseList:SetData(GetFilteredEchoes(EC.state), true)
    EC.UpdateResultCount()
  end

  resultCountFS = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  resultCountFS:SetPoint("TOPLEFT", qualityRow, "BOTTOMLEFT", 0, -10)
  resultCountFS:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3])
  resultCountFS:SetText("0 of 0 echoes")

  browseList = CreateList(f, FRAME_WIDTH - 40, FRAME_HEIGHT - 235, BrowseRowFactory)
  browseList.container:SetPoint("TOPLEFT", resultCountFS, "BOTTOMLEFT", 0, -8)
  browseList.updateRow = BrowseUpdateRow

  return f
end

function EC.UpdateResultCount()
  resultCountFS:SetText(#browseList.data .. " of " .. EC.totalCount .. " echoes")
end

----------------------------------------------------------------------
-- Wishlist tab
----------------------------------------------------------------------

local function WishlistRowFactory(parent, i)
  local row = CreateFrame("Button", "EchoCodexWishRow" .. i, parent)
  row:SetHeight(ROW_HEIGHT - 2)

  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints()
  row.bg:SetTexture(1, 1, 1, (i % 2 == 0) and 0.04 or 0.0)

  row.nameText = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  row.nameText:SetPoint("LEFT", 6, 0)
  row.nameText:SetJustifyH("LEFT")
  row.nameText:SetWidth(360)

  row.metaText = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  row.metaText:SetPoint("LEFT", row.nameText, "RIGHT", 6, 0)
  row.metaText:SetJustifyH("LEFT")
  row.metaText:SetWidth(150)

  row.removeBtn = CreateFlatButton(row, "EchoCodexWishRowBtn" .. i, 70, 20, "Remove")
  row.removeBtn:SetPoint("RIGHT", -2, 0)

  row:SetScript("OnEnter", function(self)
    if not self.echo then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local c = QUALITY_COLORS[self.echo.q]
    GameTooltip:SetText(self.echo.n, c.r, c.g, c.b)
    GameTooltip:AddLine(self.echo.d, 0.9, 0.9, 0.9, true)
    if EC.IsEchoKnown(self.echo) then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine("You already know this Echo", 0.29, 0.82, 0.5)
    end
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)

  return row
end

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
      if activeWishlistItems[id] then
        already = already + 1
      else
        activeWishlistItems[id] = true
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
  for id in pairs(activeWishlistItems) do
    local echo = EchoCodexDataEchoes[id]
    if echo then
      parts[#parts + 1] = string.format("%d.%d.%d", id, echo.q, 1)
    end
  end
  table.sort(parts)
  local classToken = myClassFile or "UNKNOWN"
  local name = charDB.activeWishlist or "Echo Codex Wishlist"
  return "EBH1:" .. table.concat(parts, ",") .. ":" .. classToken .. ":" .. name, #parts
end

-- Drops every wishlist entry that doesn't need a Tome (auto-learned Echoes
-- you'll pick up naturally while leveling, so there's nothing to track down).
function EC.PruneNonTomeWishlist()
  local removed, keptTome, unknown = 0, 0, 0
  for id in pairs(activeWishlistItems) do
    local echo = EchoCodexDataEchoes[id]
    if not echo then
      unknown = unknown + 1
    elseif not echo.t then
      activeWishlistItems[id] = nil
      removed = removed + 1
    else
      keptTome = keptTome + 1
    end
  end
  EC.RefreshAll()
  return { removed = removed, keptTome = keptTome, unknown = unknown }
end

local function WishlistUpdateRow(row, echo)
  row.echo = echo
  local c = QUALITY_COLORS[echo.q]
  row.nameText:SetText(echo.n)
  row.nameText:SetTextColor(c.r, c.g, c.b)
  local metaBits = {}
  metaBits[#metaBits + 1] = echo.t and "|cffffd100Needs Tome|r" or "|cff888888Auto-learned|r"
  if EC.IsEchoKnown(echo) then metaBits[#metaBits + 1] = "|cff4ade80Known|r" end
  row.metaText:SetText(table.concat(metaBits, "  "))
  row.removeBtn:SetScript("OnClick", function()
    activeWishlistItems[echo.id] = nil
    EC.RefreshAll()
  end)
end

function EC.RefreshWishlist()
  local ids = {}
  for id in pairs(activeWishlistItems) do ids[id] = true end
  local data = GetFilteredEchoes({}, ids)
  wishlistList:SetData(data)
  local tomeCount = 0
  for _, e in ipairs(data) do if e.t then tomeCount = tomeCount + 1 end end
  wishlistCountFS:SetText(string.format("%d item%s in \"%s\"  (%d require a Tome)",
    #data, #data == 1 and "" or "s", charDB.activeWishlist or "?", tomeCount))
  if wishlistEmptyText then
    if #data == 0 then wishlistEmptyText:Show() else wishlistEmptyText:Hide() end
  end
end

----------------------------------------------------------------------
-- Multiple named wishlists (per character)
----------------------------------------------------------------------

local wishlistDropdown

function EC.ListWishlistNames()
  local names = {}
  for name in pairs(charDB.wishlists) do names[#names + 1] = name end
  table.sort(names)
  return names
end

function EC.GetActiveWishlistName()
  return charDB.activeWishlist
end

function EC.SetActiveWishlist(name)
  local ws = charDB.wishlists[name]
  if not ws then return false end
  charDB.activeWishlist = name
  activeWishlistItems = ws.items
  activeWishlistFound = ws.found
  if wishlistDropdown then UIDropDownMenu_SetText(wishlistDropdown, name) end
  -- A different wishlist is a genuinely new list, not an in-place update --
  -- start both its views at the top rather than holding whatever offset the
  -- previously-active wishlist happened to be scrolled to.
  if wishlistList then wishlistList.scroll.offset = 0; wishlistList.scroll:SetVerticalScroll(0) end
  if checklistList then checklistList.scroll.offset = 0; checklistList.scroll:SetVerticalScroll(0) end
  EC.RefreshAll()
  return true
end

function EC.CreateWishlist(name)
  name = strtrim(name or "")
  if name == "" then return false, "Name can't be empty." end
  if charDB.wishlists[name] then
    return false, "A wishlist named \"" .. name .. "\" already exists."
  end
  charDB.wishlists[name] = NewWishlist()
  EC.SetActiveWishlist(name)
  return true
end

function EC.RenameActiveWishlist(newName)
  newName = strtrim(newName or "")
  local oldName = charDB.activeWishlist
  if newName == "" then return false, "Name can't be empty." end
  if newName == oldName then return true end
  if charDB.wishlists[newName] then
    return false, "A wishlist named \"" .. newName .. "\" already exists."
  end
  charDB.wishlists[newName] = charDB.wishlists[oldName]
  charDB.wishlists[oldName] = nil
  charDB.activeWishlist = newName
  if wishlistDropdown then UIDropDownMenu_SetText(wishlistDropdown, newName) end
  return true
end

function EC.DeleteActiveWishlist()
  if #EC.ListWishlistNames() <= 1 then
    return false, "Can't delete your only wishlist."
  end
  local oldName = charDB.activeWishlist
  charDB.wishlists[oldName] = nil
  EC.SetActiveWishlist(next(charDB.wishlists))
  return true, oldName
end

-- This client doesn't reliably expose the hasEditBox popup's edit box as
-- self.editBox -- fall back to the classic $parentEditBox global name, same
-- workaround EbonholdHub uses for its own rename-gear-set popup.
local function ResolvePopupEditBox(frame)
  if not frame then return nil end
  if frame.editBox then return frame.editBox end
  return _G[frame:GetName() .. "EditBox"]
end

StaticPopupDialogs["ECHOCODEX_NEW_WISHLIST"] = {
  text = "Name for the new wishlist:",
  button1 = "Create",
  button2 = "Cancel",
  hasEditBox = true,
  maxLetters = 40,
  OnShow = function(self)
    local editBox = ResolvePopupEditBox(self)
    if editBox then
      editBox:SetText("")
      editBox:SetFocus()
    end
  end,
  OnAccept = function(self)
    local editBox = ResolvePopupEditBox(self)
    local ok, err = EC.CreateWishlist(editBox and editBox:GetText())
    if not ok then DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[Echo Codex]|r " .. err) end
  end,
  EditBoxOnEnterPressed = function(self)
    local parent = self:GetParent()
    if parent and parent.button1 then parent.button1:Click() end
  end,
  EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["ECHOCODEX_RENAME_WISHLIST"] = {
  text = "Rename wishlist:",
  button1 = "Rename",
  button2 = "Cancel",
  hasEditBox = true,
  maxLetters = 40,
  OnShow = function(self)
    local editBox = ResolvePopupEditBox(self)
    if editBox then
      editBox:SetText(charDB.activeWishlist)
      editBox:HighlightText()
      editBox:SetFocus()
    end
  end,
  OnAccept = function(self)
    local editBox = ResolvePopupEditBox(self)
    local ok, err = EC.RenameActiveWishlist(editBox and editBox:GetText())
    if not ok then DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[Echo Codex]|r " .. err) end
  end,
  EditBoxOnEnterPressed = function(self)
    local parent = self:GetParent()
    if parent and parent.button1 then parent.button1:Click() end
  end,
  EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["ECHOCODEX_DELETE_WISHLIST"] = {
  text = "Delete wishlist \"%s\"? This removes its items and checklist progress permanently.",
  button1 = "Delete",
  button2 = "Cancel",
  OnAccept = function()
    local ok, removedName = EC.DeleteActiveWishlist()
    if ok then
      DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[Echo Codex]|r Deleted wishlist \"" .. removedName .. "\".")
    end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["ECHOCODEX_EXPORT_WISHLIST"] = {
  text = "\"%s\" as an EBH1 string -- paste into Nexus, EbonholdHub, or the Echo Journal's own import:\nCtrl+A, Ctrl+C to copy:",
  button1 = "Close",
  hasEditBox = true,
  editBoxWidth = 350,
  OnShow = function(self)
    local editBox = ResolvePopupEditBox(self)
    if editBox then
      local str = EC.ExportActiveWishlistString()
      editBox:SetText(str)
      editBox:HighlightText()
      editBox:SetFocus()
    end
  end,
  EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
  EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

local function WishlistDropdown_Init(self, level)
  for _, name in ipairs(EC.ListWishlistNames()) do
    local info = UIDropDownMenu_CreateInfo()
    info.text = name
    info.checked = (name == charDB.activeWishlist)
    info.func = function() EC.SetActiveWishlist(name) end
    UIDropDownMenu_AddButton(info)
  end
end

local importStatusFS

local function BuildWishlistTab(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:SetAllPoints()

  local wishlistLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  wishlistLabel:SetPoint("TOPLEFT", 12, -12)
  wishlistLabel:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3])
  wishlistLabel:SetText("Wishlist:")

  wishlistDropdown = CreateFrame("Frame", "EchoCodexWishlistDropdown", f, "UIDropDownMenuTemplate")
  wishlistDropdown:SetPoint("LEFT", wishlistLabel, "RIGHT", -2, -2)
  UIDropDownMenu_SetWidth(wishlistDropdown, 160)
  UIDropDownMenu_Initialize(wishlistDropdown, WishlistDropdown_Init)
  UIDropDownMenu_SetText(wishlistDropdown, charDB.activeWishlist)

  local newWishlistBtn = CreateFlatButton(f, "EchoCodexNewWishlistBtn", 46, 20, "New")
  newWishlistBtn:SetPoint("LEFT", wishlistDropdown, "RIGHT", 2, 2)
  newWishlistBtn:HookScript("OnClick", function() StaticPopup_Show("ECHOCODEX_NEW_WISHLIST") end)

  local renameWishlistBtn = CreateFlatButton(f, "EchoCodexRenameWishlistBtn", 66, 20, "Rename")
  renameWishlistBtn:SetPoint("LEFT", newWishlistBtn, "RIGHT", 6, 0)
  renameWishlistBtn:HookScript("OnClick", function() StaticPopup_Show("ECHOCODEX_RENAME_WISHLIST") end)

  local deleteWishlistBtn = CreateFlatButton(f, "EchoCodexDeleteWishlistBtn", 66, 20, "Delete")
  deleteWishlistBtn:SetPoint("LEFT", renameWishlistBtn, "RIGHT", 6, 0)
  deleteWishlistBtn:HookScript("OnClick", function()
    StaticPopup_Show("ECHOCODEX_DELETE_WISHLIST", charDB.activeWishlist)
  end)

  local hint = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  -- Y comes from the dropdown row's bottom, but X is pinned back to the tab's
  -- left margin (via wishlistLabel) rather than the dropdown's own position --
  -- otherwise every element below inherits the dropdown's rightward offset,
  -- and the wishlist list ends up overflowing past the window's right edge.
  hint:SetPoint("TOP", wishlistDropdown, "BOTTOM", 0, -10)
  hint:SetPoint("LEFT", wishlistLabel, "LEFT", 0, 0)
  hint:SetWidth(FRAME_WIDTH - 60)
  hint:SetJustifyH("LEFT")
  hint:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3])
  hint:SetText("Echoes you're planning to pick up. Add them from the Browse tab. Wishlist items that need a Tome show up on the Checklist tab so you can track down and mark off where to farm them.")

  local importLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  importLabel:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -14)
  importLabel:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3])
  importLabel:SetText("Import from Echo Journal / EbonholdHub / Nexus")

  local importHolder = CreateFrame("Frame", nil, f)
  importHolder:SetSize(430, 22)
  importHolder:SetPoint("TOPLEFT", importLabel, "BOTTOMLEFT", 6, -6)
  Fill(importHolder, THEME.elementBg)
  local importBorder = ThinBorder(importHolder, THEME.border, 1)

  local importBox = CreateFrame("EditBox", "EchoCodexImportBox", importHolder)
  importBox:SetPoint("TOPLEFT", 6, -3)
  importBox:SetPoint("BOTTOMRIGHT", -6, 3)
  importBox:SetAutoFocus(false)
  importBox:SetFontObject(GameFontHighlightSmall)
  importBox:SetTextInsets(0, 0, 0, 0)
  importBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  importBox:SetScript("OnEditFocusGained", function() SetBorderColor(importBorder, THEME.accent) end)
  importBox:SetScript("OnEditFocusLost", function() SetBorderColor(importBorder, THEME.border) end)

  local importBtn = CreateFlatButton(f, "EchoCodexImportBtn", 70, 22, "Import")
  importBtn:SetPoint("LEFT", importHolder, "RIGHT", 10, 0)

  importStatusFS = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  importStatusFS:SetPoint("TOPLEFT", importHolder, "BOTTOMLEFT", -6, -6)
  importStatusFS:SetWidth(FRAME_WIDTH - 60)
  importStatusFS:SetJustifyH("LEFT")
  importStatusFS:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3])
  importStatusFS:SetText("Paste an Echo Journal export (EWL1:/EBH1:...), a Nexus wishlist export (Wishlist Editor's Export button), or an EbonholdHub Build export (the base64 blob from its Export button), then click Import.")

  local function DoImport()
    local text = importBox:GetText()
    local ok, result = EC.ImportEBHWishlist(text)
    if not ok then
      importStatusFS:SetTextColor(1, 0.35, 0.35)
      importStatusFS:SetText(result)
      return
    end
    importStatusFS:SetTextColor(0.4, 1, 0.4)
    local msg = string.format("Imported %d new Echo%s", result.added, result.added == 1 and "" or "es")
    if result.already > 0 then
      msg = msg .. string.format(" (%d already on your wishlist)", result.already)
    end
    if result.unknown > 0 then
      msg = msg .. string.format(" -- %d id%s not recognized (stale data snapshot?)", result.unknown, result.unknown == 1 and "" or "s")
    end
    importStatusFS:SetText(msg .. ".")
    importBox:SetText("")
    importBox:ClearFocus()
  end

  importBtn:SetScript("OnClick", DoImport)
  importBox:SetScript("OnEnterPressed", function(self) DoImport() self:ClearFocus() end)

  wishlistCountFS = f:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  wishlistCountFS:SetPoint("TOPLEFT", importStatusFS, "BOTTOMLEFT", 6, -14)
  wishlistCountFS:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3])

  local exportBtn = CreateFlatButton(f, "EchoCodexExportBtn", 70, 20, "Export")
  exportBtn:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Export this wishlist", 1, 0.82, 0)
    GameTooltip:AddLine("Produces an EBH1 string for this wishlist -- paste it into Nexus, EbonholdHub, or the Echo Journal's own import.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  exportBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
  exportBtn:HookScript("OnClick", function()
    local str, count = EC.ExportActiveWishlistString()
    if count == 0 then
      DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[Echo Codex]|r This wishlist is empty -- nothing to export.")
      return
    end
    StaticPopup_Show("ECHOCODEX_EXPORT_WISHLIST", charDB.activeWishlist)
  end)

  local pruneBtn = CreateFlatButton(f, "EchoCodexPruneBtn", 140, 20, "Remove non-Tome")
  pruneBtn:SetPoint("TOPRIGHT", importStatusFS, "BOTTOMRIGHT", -6, -12)
  exportBtn:SetPoint("RIGHT", pruneBtn, "LEFT", -6, 0)
  pruneBtn:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText("Remove non-Tome Echoes", 1, 0.82, 0)
    GameTooltip:AddLine("Drops every wishlist item that's learned automatically while leveling, since there's no Tome to track down for those.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  pruneBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
  pruneBtn:HookScript("OnClick", function()
    local result = EC.PruneNonTomeWishlist()
    local msg = string.format("Removed %d non-Tome item%s (%d Tome-locked item%s kept)",
      result.removed, result.removed == 1 and "" or "s",
      result.keptTome, result.keptTome == 1 and "" or "s")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[Echo Codex]|r " .. msg .. ".")
  end)

  wishlistList = CreateList(f, FRAME_WIDTH - 40, FRAME_HEIGHT - 285, WishlistRowFactory)
  wishlistList.container:SetPoint("TOPLEFT", wishlistCountFS, "BOTTOMLEFT", 0, -8)
  wishlistList.updateRow = WishlistUpdateRow

  wishlistEmptyText = f:CreateFontString(nil, "ARTWORK", "GameFontDisable")
  wishlistEmptyText:SetPoint("CENTER", wishlistList.container, "CENTER", 0, 40)
  wishlistEmptyText:SetText("Your wishlist is empty. Add Echoes from the Browse tab, or import one above.")
  wishlistEmptyText:Hide()

  return f
end

----------------------------------------------------------------------
-- Checklist tab
----------------------------------------------------------------------

local function ChecklistRowFactory(parent, i)
  local row = CreateFrame("Button", "EchoCodexCheckRow" .. i, parent)
  row:SetHeight(ROW_HEIGHT - 2)

  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints()
  row.bg:SetTexture(1, 1, 1, (i % 2 == 0) and 0.04 or 0.0)

  row.checkBtn = CreateFlatCheckbox(row, "EchoCodexCheckRowCB" .. i, nil)
  row.checkBtn:SetPoint("LEFT", 4, 0)

  row.nameText = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  row.nameText:SetPoint("LEFT", row.checkBtn, "RIGHT", 6, 0)
  row.nameText:SetJustifyH("LEFT")
  row.nameText:SetWidth(200)

  row.knownText = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  row.knownText:SetPoint("LEFT", row.nameText, "RIGHT", 4, 0)
  row.knownText:SetJustifyH("LEFT")
  row.knownText:SetWidth(50)

  row.locText = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  row.locText:SetPoint("LEFT", row.knownText, "RIGHT", 4, 0)
  row.locText:SetJustifyH("LEFT")
  row.locText:SetWidth(250)

  row:SetScript("OnEnter", function(self)
    if not self.tomeId then return end
    ShowTomeTooltip(self, self.tomeId)
  end)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)

  return row
end

local function ChecklistUpdateRow(row, entry)
  row.tomeId = entry.tomeId
  local found = activeWishlistFound[entry.tomeId]
  row.checkBtn:SetChecked(found and true or false)
  row.checkBtn.OnValueChanged = function(checked)
    if checked then
      activeWishlistFound[entry.tomeId] = true
    else
      activeWishlistFound[entry.tomeId] = nil
    end
    EC.RefreshChecklist()
  end

  local c = QUALITY_COLORS[entry.echo.q]
  row.nameText:SetText(entry.tome.name)
  if found then
    row.nameText:SetTextColor(0.5, 0.5, 0.5)
  else
    row.nameText:SetTextColor(c.r, c.g, c.b)
  end

  row.knownText:SetText(EC.IsEchoKnown(entry.echo) and "|cff4ade80known|r" or "")
  row.locText:SetText(LocationSummary(entry.locs))
end

local checklistShowCompleted = false

function EC.SetChecklistShowCompleted(show)
  checklistShowCompleted = show and true or false
  EC.RefreshChecklist()
end

-- Auto-populates from the active wishlist (any Tome-locked item shows up
-- here without you doing anything extra) and auto-clears: once an entry is
-- known, it drops off this list by default -- still on the wishlist, still
-- counted as found, just not cluttering the "what do I still need" view.
-- "Show completed" brings hidden/finished entries back into view.
function EC.RefreshChecklist()
  EC.RefreshOwnedCache()

  local allEntries = {}
  for echoId in pairs(activeWishlistItems) do
    local tomeId = EchoCodexEchoToTome[echoId]
    local echo = EchoCodexDataEchoes[echoId]
    if tomeId and echo then
      local tome = EchoCodexTomes[tomeId]
      if tome then
        allEntries[#allEntries + 1] = {
          echoId = echoId,
          echo = echo,
          tomeId = tomeId,
          tome = tome,
          locs = EchoCodexLocations[tomeId],
        }
      end
    end
  end

  -- Auto-check off anything the character already knows, so the list only
  -- ever asks you to manually track down what you're actually missing.
  for _, e in ipairs(allEntries) do
    if not activeWishlistFound[e.tomeId] and EC.IsEchoKnown(e.echo) then
      activeWishlistFound[e.tomeId] = true
    end
  end

  table.sort(allEntries, function(a, b)
    local fa = activeWishlistFound[a.tomeId] and 1 or 0
    local fb = activeWishlistFound[b.tomeId] and 1 or 0
    if fa ~= fb then return fa < fb end
    if a.echo.q ~= b.echo.q then return a.echo.q > b.echo.q end
    return a.tome.name < b.tome.name
  end)

  local foundCount = 0
  for _, e in ipairs(allEntries) do
    if activeWishlistFound[e.tomeId] then foundCount = foundCount + 1 end
  end

  local visible = allEntries
  if not checklistShowCompleted then
    visible = {}
    for _, e in ipairs(allEntries) do
      if not activeWishlistFound[e.tomeId] then visible[#visible + 1] = e end
    end
  end

  checklistList:SetData(visible)

  local nonTome = 0
  for echoId in pairs(activeWishlistItems) do
    if not EchoCodexEchoToTome[echoId] then nonTome = nonTome + 1 end
  end

  local msg = string.format("\"%s\": %d / %d Tomes found", charDB.activeWishlist or "?", foundCount, #allEntries)
  if not checklistShowCompleted and foundCount > 0 then
    msg = msg .. string.format("  |cff4ade80(%d completed, hidden)|r", foundCount)
  end
  if nonTome > 0 then
    msg = msg .. string.format("   |cff888888(%d wishlist item%s learned automatically, no Tome needed)|r", nonTome, nonTome == 1 and "" or "s")
  end
  if not EC.HasOwnershipData() then
    msg = msg .. "   |cff886644(auto-detect unavailable this session)|r"
  end
  checklistProgressFS:SetText(msg)

  if checklistEmptyText then
    if #allEntries == 0 then
      checklistEmptyText:SetText("No Tome-locked Echoes on your wishlist yet. Add some from the Browse tab.")
      checklistEmptyText:Show()
    elseif #visible == 0 then
      checklistEmptyText:SetText("All caught up! Every Tome-locked Echo on this wishlist is already known.\n(Tick \"Show completed\" above to see them.)")
      checklistEmptyText:Show()
    else
      checklistEmptyText:Hide()
    end
  end
end

local function BuildChecklistTab(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:SetAllPoints()

  local hint = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  hint:SetPoint("TOPLEFT", 12, -12)
  hint:SetWidth(FRAME_WIDTH - 60)
  hint:SetJustifyH("LEFT")
  hint:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3])
  hint:SetText("Tome-locked Echoes from your wishlist. Echoes you already know get ticked off and drop off this list automatically; hover a row for full drop locations.")

  checklistProgressFS = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  checklistProgressFS:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -10)
  checklistProgressFS:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3])

  -- Own row below the progress line, anchored off hint (fixed width) rather
  -- than checklistProgressFS (whose text -- and so its width -- changes
  -- every refresh), so there's no risk of the two ever overlapping.
  local showCompletedCB = CreateFlatCheckbox(f, "EchoCodexShowCompletedCB", "Show completed")
  showCompletedCB:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -32)
  showCompletedCB:SetChecked(checklistShowCompleted)
  showCompletedCB.OnValueChanged = function(checked) EC.SetChecklistShowCompleted(checked) end

  checklistList = CreateList(f, FRAME_WIDTH - 40, FRAME_HEIGHT - 195, ChecklistRowFactory)
  checklistList.container:SetPoint("TOPLEFT", showCompletedCB, "BOTTOMLEFT", 0, -10)
  checklistList.updateRow = ChecklistUpdateRow

  checklistEmptyText = f:CreateFontString(nil, "ARTWORK", "GameFontDisable")
  checklistEmptyText:SetPoint("CENTER", checklistList.container, "CENTER", 0, 40)
  checklistEmptyText:SetWidth(FRAME_WIDTH - 100)
  checklistEmptyText:SetText("No Tome-locked Echoes on your wishlist yet. Add some from the Browse tab.")
  checklistEmptyText:Hide()

  return f
end

----------------------------------------------------------------------
-- Refresh-all + frame construction
----------------------------------------------------------------------

function EC.RefreshAll()
  EC.RefreshOwnedCache()
  browseList:SetData(GetFilteredEchoes(EC.state))
  EC.UpdateResultCount()
  EC.RefreshWishlist()
  EC.RefreshChecklist()
end

local function BuildMainFrame()
  EC.totalCount = 0
  for _ in pairs(EchoCodexDataEchoes) do EC.totalCount = EC.totalCount + 1 end

  -- Deliberately NOT named "...Echo..." / "...Journal..." / "...Loadout..." /
  -- "...Perk...": EbonholdHub's JournalLoadoutHook scans top-level frames whose
  -- name contains one of those words and grafts its own "Import to EbonholdHub"
  -- button onto any EditBox inside that currently holds EWL/EBH-formatted text --
  -- which included our own import box. This name keeps that scanner out.
  mainFrame = CreateFrame("Frame", "ECCodexWindow", UIParent)
  mainFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
  mainFrame:SetPoint("CENTER")
  mainFrame:SetFrameStrata("DIALOG")
  mainFrame:SetMovable(true)
  mainFrame:EnableMouse(true)
  mainFrame:SetClampedToScreen(true)
  Fill(mainFrame, THEME.bg)
  ThinBorder(mainFrame, THEME.border, 1)
  mainFrame:Hide()
  tinsert(UISpecialFrames, "ECCodexWindow")

  local titleBar = CreateFrame("Frame", nil, mainFrame)
  titleBar:SetPoint("TOPLEFT", 0, 0)
  titleBar:SetPoint("TOPRIGHT", 0, 0)
  titleBar:SetHeight(30)
  Fill(titleBar, THEME.bgHeader)
  local titleSep = titleBar:CreateTexture(nil, "ARTWORK")
  titleSep:SetTexture(FLAT_TEX)
  titleSep:SetVertexColor(THEME.border[1], THEME.border[2], THEME.border[3], 1)
  titleSep:SetPoint("BOTTOMLEFT", 0, 0)
  titleSep:SetPoint("BOTTOMRIGHT", 0, 0)
  titleSep:SetHeight(1)

  titleBar:EnableMouse(true)
  titleBar:RegisterForDrag("LeftButton")
  titleBar:SetScript("OnDragStart", function() mainFrame:StartMoving() end)
  titleBar:SetScript("OnDragStop", function()
    mainFrame:StopMovingOrSizing()
    local point, _, _, x, y = mainFrame:GetPoint()
    EchoCodexDB.framePos = { point = point, x = x, y = y }
  end)

  local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("LEFT", 12, 0)
  title:SetText("Echo Codex")
  title:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3])

  -- Deliberately oversized, unambiguous hit target -- this replaces the old
  -- Blizzard dialog-border close icon, whose small hit region (further
  -- confused by the ornate corner art around it) was hard to click reliably.
  local closeBtn = CreateFrame("Button", "EchoCodexCloseButton", titleBar)
  closeBtn:SetSize(26, 26)
  closeBtn:SetPoint("RIGHT", -2, 0)
  local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  closeText:SetPoint("CENTER")
  closeText:SetText("x")
  closeText:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3])
  closeBtn:SetScript("OnEnter", function() closeText:SetTextColor(THEME.danger[1], THEME.danger[2], THEME.danger[3]) end)
  closeBtn:SetScript("OnLeave", function() closeText:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3]) end)
  closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)

  tabButtons = {}
  tabFrames = {}

  local tabHolder = CreateFrame("Frame", nil, mainFrame)
  tabHolder:SetPoint("TOPLEFT", 12, -38)
  tabHolder:SetSize(FRAME_WIDTH - 24, 26)
  local tabSep = tabHolder:CreateTexture(nil, "ARTWORK")
  tabSep:SetTexture(FLAT_TEX)
  tabSep:SetVertexColor(THEME.border[1], THEME.border[2], THEME.border[3], 1)
  tabSep:SetPoint("BOTTOMLEFT", 0, 0)
  tabSep:SetPoint("BOTTOMRIGHT", 0, 0)
  tabSep:SetHeight(1)

  local names = { "browse", "wishlist", "checklist" }
  local labels = { browse = "Browse", wishlist = "Wishlist", checklist = "Checklist" }
  local prevTab
  for i, n in ipairs(names) do
    local btn = BuildTabButton(tabHolder, "EchoCodexTabButton" .. i, labels[n])
    if prevTab then btn:SetPoint("LEFT", prevTab, "RIGHT", 18, 0) else btn:SetPoint("LEFT", 0, 0) end
    btn:SetScript("OnClick", function() SelectTab(n) end)
    tabButtons[n] = btn
    prevTab = btn
  end

  local contentHolder = CreateFrame("Frame", nil, mainFrame)
  contentHolder:SetPoint("TOPLEFT", tabHolder, "BOTTOMLEFT", 0, -8)
  contentHolder:SetPoint("BOTTOMRIGHT", -12, 12)

  tabFrames.browse = BuildBrowseTab(contentHolder)
  tabFrames.wishlist = BuildWishlistTab(contentHolder)
  tabFrames.checklist = BuildChecklistTab(contentHolder)

  if EchoCodexDB.framePos then
    mainFrame:ClearAllPoints()
    mainFrame:SetPoint(EchoCodexDB.framePos.point, UIParent, EchoCodexDB.framePos.point, EchoCodexDB.framePos.x, EchoCodexDB.framePos.y)
  end

  EC.RefreshOwnedCache()
  browseList:SetData(GetFilteredEchoes(EC.state))
  EC.UpdateResultCount()
  SelectTab("browse")
end

----------------------------------------------------------------------
-- Live ownership refresh
--
-- Switching to the Checklist tab already forces a fresh ownership check
-- (SelectTab calls EC.RefreshOwnedCache() directly) -- but if the window is
-- left open on that tab, or GetDiscoveredEchoes() only becomes accurate
-- slightly after the server confirms a new discovery, a click-driven-only
-- refresh can read stale data. So: also listen for the same signals
-- EbonholdHub does (SPELLS_CHANGED / LEARNED_SPELL_IN_TAB, and the actual
-- Echo Journal's own OnDataChanged callback, hooked the same way
-- EbonholdHub hooks it) and refresh reactively. Debounced, since
-- SPELLS_CHANGED fires on every mount/dismount too (EbonholdHub's own
-- CHANGELOG documents chasing a stutter from handling that naively) --
-- coalesce bursts into one refresh instead of one per event.
----------------------------------------------------------------------

local ownershipDebounceFrame

local function RefreshOwnershipLive()
  EC.RefreshOwnedCache()
  if mainFrame and mainFrame:IsShown() then
    if activeTab == "browse" and browseList then browseList:Refresh()
    elseif activeTab == "wishlist" then EC.RefreshWishlist()
    elseif activeTab == "checklist" then EC.RefreshChecklist()
    end
  end
end

local function MarkOwnershipDirty()
  if not ownershipDebounceFrame then
    ownershipDebounceFrame = CreateFrame("Frame")
    ownershipDebounceFrame:Hide()
    ownershipDebounceFrame:SetScript("OnUpdate", function(self, elapsed)
      self.wait = (self.wait or 0) + elapsed
      if self.wait < 0.75 then return end
      self.wait = 0
      self:Hide()
      RefreshOwnershipLive()
    end)
  end
  ownershipDebounceFrame.wait = 0
  ownershipDebounceFrame:Show()
end

local function TryHookEchoJournal()
  local ej = ProjectEbonhold and ProjectEbonhold.EchoJournal
  if ej and ej.OnDataChanged and not ej._echoCodexWrapped then
    local orig = ej.OnDataChanged
    ej.OnDataChanged = function(...)
      if orig then orig(...) end
      MarkOwnershipDirty()
    end
    ej._echoCodexWrapped = true
  end
end

local ownershipEvents = CreateFrame("Frame")
ownershipEvents:RegisterEvent("SPELLS_CHANGED")
ownershipEvents:RegisterEvent("LEARNED_SPELL_IN_TAB")
ownershipEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
ownershipEvents:SetScript("OnEvent", function(self, event)
  TryHookEchoJournal() -- ProjectEbonhold may not have existed yet at ADDON_LOADED
  MarkOwnershipDirty()
end)

----------------------------------------------------------------------
-- Loading + slash commands
----------------------------------------------------------------------

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
  if name ~= ADDON_NAME then return end
  InitDB()
  BuildMainFrame()
  TryHookEchoJournal()
  self:UnregisterEvent("ADDON_LOADED")
  DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Echo Codex|r loaded. Type |cff71d5ff/ec|r to open it.")
end)

SLASH_ECHOCODEX1 = "/echocodex"
SLASH_ECHOCODEX2 = "/ec"
SlashCmdList["ECHOCODEX"] = function(msg)
  msg = strtrim(msg or "")
  if msg == "debug" then
    EC.DebugOwnership()
    return
  end
  local searchTerm = msg:match("^debug%s+(.+)$")
  if searchTerm then
    EC.DebugOwnership(searchTerm)
    return
  end
  if msg == "cleanup" or msg == "prune" then
    local result = EC.PruneNonTomeWishlist()
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
      "|cffffd100[Echo Codex]|r Removed %d non-Tome item%s (%d Tome-locked item%s kept).",
      result.removed, result.removed == 1 and "" or "s",
      result.keptTome, result.keptTome == 1 and "" or "s"))
    return
  end
  if not mainFrame then return end
  if mainFrame:IsShown() then
    mainFrame:Hide()
  else
    mainFrame:Show()
    EC.RefreshAll()
  end
end
