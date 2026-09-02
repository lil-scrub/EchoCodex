-- Echo Codex -- Missing Tomes tab: wishlist entries that still need a
-- Tome, with drop locations. Entries clear themselves once detected as known.

local ADDON_NAME, ns = ...

local EC = ns.EC

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
local InferredLocationSummary = ns.InferredLocationSummary
local ShowTomeTooltip = ns.ShowTomeTooltip

-- Widgets owned by this tab, populated in BuildChecklistTab.
local checklistList, checklistProgressFS, checklistEmptyText

----------------------------------------------------------------------
-- Checklist tab
----------------------------------------------------------------------

local function ChecklistRowFactory(parent, i)
  local row = CreateFrame("Button", "EchoCodexCheckRow" .. i, parent)
  row:SetHeight(ROW_HEIGHT - 2)

  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints()
  row.bg:SetTexture(1, 1, 1, (i % 2 == 0) and 0.04 or 0.0)

  row.nameText = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  row.nameText:SetPoint("LEFT", 6, 0)
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
    if not self.entry then return end
    ShowTomeTooltip(self, self.entry.tomeId, self.entry.echo, self.entry.inferred)
  end)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)

  return row
end

local function ChecklistUpdateRow(row, entry)
  row.entry = entry
  local found = ns.activeWishlistFound[entry.key]

  local c = QUALITY_COLORS[entry.echo.q]
  row.nameText:SetText(entry.name)
  if found then
    row.nameText:SetTextColor(0.5, 0.5, 0.5)
  else
    row.nameText:SetTextColor(c.r, c.g, c.b)
  end

  row.knownText:SetText(EC.IsEchoKnown(entry.echo) and "|cff4ade80known|r" or "")
  -- Three distinct states, deliberately worded apart so a derived guess never
  -- reads like something the farming map actually documents:
  --   tome + locs  -> the real thing (or "Location not documented yet")
  --   inferred     -> our own derivation, tagged as such
  --   neither      -> we genuinely have nothing
  if entry.tome then
    row.locText:SetText(LocationSummary(entry.locs))
  elseif entry.inferred then
    row.locText:SetText(InferredLocationSummary(entry.inferred))
  else
    row.locText:SetText("|cff886644No Tome recorded in this data snapshot|r")
  end
end

local checklistShowCompleted = false

function EC.SetChecklistShowCompleted(show)
  checklistShowCompleted = show and true or false
  EC.RefreshChecklist()
end

-- Resolves the Tome an Echo needs, or nil when our Tome snapshot has no row
-- for it. Also returns the key its found-state lives under: normally the Tome
-- id, but Tome-less entries need a key of their own or they'd all collide on
-- one slot and tick each other off.
local function ResolveTome(echoId)
  local tomeId = EchoCodexEchoToTome[echoId]
  local tome = tomeId and EchoCodexTomes[tomeId]
  if not tome then return nil, nil, "echo:" .. echoId end
  return tomeId, tome, tomeId
end

-- Builds the entry list for the active wishlist, sorted for display. Split
-- out of RefreshChecklist so the tests can exercise it without a frame.
--
-- Whether an Echo needs a Tome is the Echo's own `t` flag -- the same signal
-- the Browse filter and "/eco cleanup" use. EchoCodexEchoToTome is a SEPARATE
-- and less complete snapshot, so gating on it (as this did) silently dropped
-- every Tome-locked Echo whose Tome isn't in our Tome data: exactly the ones
-- you can't look up elsewhere either. Those are listed here without Tome
-- detail rather than hidden, and never counted as auto-learned.
function EC.GetMissingTomeEntries()
  local entries, nonTome = {}, 0

  for echoId in pairs(ns.activeWishlistItems) do
    local echo = EchoCodexDataEchoes[echoId]
    if echo then
      if echo.t then
        local tomeId, tome, key = ResolveTome(echoId)
        entries[#entries + 1] = {
          echoId = echoId,
          echo = echo,
          tomeId = tomeId,
          tome = tome,
          key = key,
          name = tome and tome.name or echo.n,
          locs = tomeId and EchoCodexLocations[tomeId] or nil,
          -- Only ever consulted when there's no real Tome record: sourced
          -- data always wins over our own derivation.
          inferred = (not tome) and EchoCodexInferredLocations[echoId] or nil,
        }
      else
        nonTome = nonTome + 1
      end
    end
  end

  table.sort(entries, function(a, b)
    local fa = ns.activeWishlistFound[a.key] and 1 or 0
    local fb = ns.activeWishlistFound[b.key] and 1 or 0
    if fa ~= fb then return fa < fb end
    if a.echo.q ~= b.echo.q then return a.echo.q > b.echo.q end
    if a.name ~= b.name then return a.name < b.name end
    return a.echoId < b.echoId
  end)

  return entries, nonTome
end

-- Auto-populates from the active wishlist (any Tome-locked item shows up
-- here without you doing anything extra) and auto-clears: once an entry is
-- known, it drops off this list by default -- still on the wishlist, still
-- counted as found, just not cluttering the "what do I still need" view.
-- "Show completed" brings hidden/finished entries back into view.
function EC.RefreshChecklist()
  EC.RefreshOwnedCache()

  -- Auto-check off anything the character already knows, so the list only
  -- ever asks you to manually track down what you're actually missing. Done
  -- before GetMissingTomeEntries, whose sort reads the same flags, so the
  -- ordering matches what's displayed.
  for echoId in pairs(ns.activeWishlistItems) do
    local echo = EchoCodexDataEchoes[echoId]
    if echo and echo.t and EC.IsEchoKnown(echo) then
      local _, _, key = ResolveTome(echoId)
      ns.activeWishlistFound[key] = true
    end
  end

  local allEntries, nonTome = EC.GetMissingTomeEntries()

  local foundCount = 0
  for _, e in ipairs(allEntries) do
    if ns.activeWishlistFound[e.key] then foundCount = foundCount + 1 end
  end

  local visible = allEntries
  if not checklistShowCompleted then
    visible = {}
    for _, e in ipairs(allEntries) do
      if not ns.activeWishlistFound[e.key] then visible[#visible + 1] = e end
    end
  end

  checklistList:SetData(visible)

  local msg = string.format("\"%s\": %d / %d Tomes found", ns.charDB.activeWishlist or "?", foundCount, #allEntries)
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


ns.tabs.checklist = {
  label = "Missing Tomes",
  build = BuildChecklistTab,
  refresh = EC.RefreshChecklist,
  onSelect = EC.RefreshChecklist,
  resetScroll = function()
    if checklistList then
      checklistList.scroll.offset = 0
      checklistList.scroll:SetVerticalScroll(0)
    end
  end,
}
