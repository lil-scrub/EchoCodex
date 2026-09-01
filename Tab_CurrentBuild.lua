-- Echo Codex -- Current Build tab: this run's active Echo picks diffed
-- against the active wishlist.

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
local ShowTomeTooltip = ns.ShowTomeTooltip

-- Widgets owned by this tab, populated in BuildCurrentBuildTab.
local currentBuildList, currentBuildProgressFS, currentBuildEmptyText

----------------------------------------------------------------------
-- Current Build tab
--
-- Diffs the current run's active Echo picks (EC.IsEchoInCurrentBuild, fed by
-- GetGrantedPerks -- see the comment above ScanForCurrentBuild) against the
-- active wishlist: what you have and want, what you still need to track
-- down, and -- the reverse case -- what's equipped right now but never made
-- the wishlist, i.e. a safe reroll candidate.
----------------------------------------------------------------------

local CURRENT_BUILD_STATUS = {
  have    = { order = 0, label = "|cff4ade80In build|r" },
  missing = { order = 1, label = "|cffffd100Missing|r" },
  reroll  = { order = 2, label = "|cfff87171Not wishlisted -- reroll?|r" },
}

local function CurrentBuildRowFactory(parent, i)
  local row = CreateFrame("Button", "EchoCodexBuildRow" .. i, parent)
  row:SetHeight(ROW_HEIGHT - 2)

  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints()
  row.bg:SetTexture(1, 1, 1, (i % 2 == 0) and 0.04 or 0.0)

  row.nameText = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  row.nameText:SetPoint("LEFT", 8, 0)
  row.nameText:SetJustifyH("LEFT")
  row.nameText:SetWidth(320)

  row.statusText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  row.statusText:SetPoint("LEFT", row.nameText, "RIGHT", 6, 0)
  row.statusText:SetJustifyH("LEFT")
  row.statusText:SetWidth(190)

  row.tomeText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  row.tomeText:SetPoint("LEFT", row.statusText, "RIGHT", 6, 0)
  row.tomeText:SetJustifyH("LEFT")
  row.tomeText:SetWidth(110)
  row.tomeText:SetWordWrap(false)

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
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)

  return row
end

local function CurrentBuildUpdateRow(row, entry)
  row.echo = entry.echo
  local c = QUALITY_COLORS[entry.echo.q]
  local name = entry.echo.n
  -- Only "have"/"reroll" rows are actually backed by currentBuildIds --
  -- "missing" rows aren't in the current build at all, so GetCurrentBuildCount
  -- would just report its harmless default of 1 (no badge) for those anyway.
  local count = EC.GetCurrentBuildCount(entry.echo)
  if (entry.status == "have" or entry.status == "reroll") and count > 1 then
    name = name .. "  |cff71d5ffx" .. count .. "|r"
  end
  row.nameText:SetText(name)
  row.nameText:SetTextColor(c.r, c.g, c.b)
  row.statusText:SetText(CURRENT_BUILD_STATUS[entry.status].label)

  -- t=false Echoes are auto-learned while leveling -- no Tome to be
  -- missing, so leave the column blank rather than flagging every one of
  -- them. Otherwise: known already (via EC.IsEchoKnown, same signal that
  -- drives the Missing Tomes tab's auto-check) means its Tome is in hand;
  -- unknown means you don't actually have permanent access to this Echo
  -- yet, even if it's active in your build (or wishlisted) this run.
  if entry.echo.t and not EC.IsEchoKnown(entry.echo) then
    row.tomeText:SetText("|cfff87171Tome missing|r")
  else
    row.tomeText:SetText("")
  end
end

function EC.RefreshCurrentBuild()
  EC.RefreshOwnedCache()

  local entries = {}
  local seen = {}

  for echoId in pairs(ns.activeWishlistItems) do
    local echo = EchoCodexDataEchoes[echoId]
    if echo then
      echo.id = echoId
      seen[echoId] = true
      entries[#entries + 1] = {
        echo = echo,
        status = EC.IsEchoInCurrentBuild(echo) and "have" or "missing",
      }
    end
  end

  -- Reverse direction: currently equipped, but never made the wishlist.
  -- currentBuildIds is exact-tier by this point (ExpandCurrentBuildGroups
  -- only fans a reported id out to siblings when that id ISN'T one of our
  -- own rows), so each id here is a real, distinct tier the player
  -- actually has -- show one row per id, including both tiers of the same
  -- Echo if the player genuinely has more than one active.
  for echoId in pairs(ns.GetOwnershipState().currentBuildIds) do
    if not seen[echoId] then
      local echo = EchoCodexDataEchoes[echoId]
      if echo then
        echo.id = echoId
        entries[#entries + 1] = { echo = echo, status = "reroll" }
      end
    end
  end

  table.sort(entries, function(a, b)
    local oa, ob = CURRENT_BUILD_STATUS[a.status].order, CURRENT_BUILD_STATUS[b.status].order
    if oa ~= ob then return oa < ob end
    if a.echo.q ~= b.echo.q then return a.echo.q > b.echo.q end
    return a.echo.n < b.echo.n
  end)

  currentBuildList:SetData(entries)

  local have, missing, reroll = 0, 0, 0
  for _, e in ipairs(entries) do
    if e.status == "have" then have = have + 1
    elseif e.status == "missing" then missing = missing + 1
    else reroll = reroll + 1 end
  end

  local msg = string.format("\"%s\": %d / %d wishlist Echoes already in your current build", ns.charDB.activeWishlist or "?", have, have + missing)
  if reroll > 0 then
    msg = msg .. string.format("   |cfff87171(%d equipped Echo%s not on this wishlist -- reroll candidates)|r", reroll, reroll == 1 and "" or "s")
  end
  if not EC.HasOwnershipData() then
    msg = msg .. "   |cff886644(auto-detect unavailable this session)|r"
  end
  currentBuildProgressFS:SetText(msg)

  if currentBuildEmptyText then
    if #entries == 0 then
      currentBuildEmptyText:SetText("Nothing to compare yet -- add Echoes to your wishlist, and make sure the server's Echo Journal has loaded this session.")
      currentBuildEmptyText:Show()
    else
      currentBuildEmptyText:Hide()
    end
  end
end

local function BuildCurrentBuildTab(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:SetAllPoints()

  local hint = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  hint:SetPoint("TOPLEFT", 12, -12)
  hint:SetWidth(FRAME_WIDTH - 60)
  hint:SetJustifyH("LEFT")
  hint:SetTextColor(THEME.textDim[1], THEME.textDim[2], THEME.textDim[3])
  hint:SetText("Your current build (live picks, or EbonholdHub's active Build) vs. this wishlist: what you have, what you're still missing, and what's in the build but not wishlisted -- safe to reroll away.")

  currentBuildProgressFS = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  currentBuildProgressFS:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -10)
  currentBuildProgressFS:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3])

  currentBuildList = CreateList(f, FRAME_WIDTH - 40, FRAME_HEIGHT - 165, CurrentBuildRowFactory)
  currentBuildList.container:SetPoint("TOPLEFT", currentBuildProgressFS, "BOTTOMLEFT", 0, -10)
  currentBuildList.updateRow = CurrentBuildUpdateRow

  currentBuildEmptyText = f:CreateFontString(nil, "ARTWORK", "GameFontDisable")
  currentBuildEmptyText:SetPoint("CENTER", currentBuildList.container, "CENTER", 0, 40)
  currentBuildEmptyText:SetWidth(FRAME_WIDTH - 100)
  currentBuildEmptyText:SetText("Nothing to compare yet -- add Echoes to your wishlist.")
  currentBuildEmptyText:Hide()

  return f
end


ns.tabs.currentbuild = {
  label = "Current Build",
  build = BuildCurrentBuildTab,
  refresh = EC.RefreshCurrentBuild,
  onSelect = EC.RefreshCurrentBuild,
}
