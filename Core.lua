-- Echo Codex
-- Search Project Ebonhold's Echoes, build a wishlist, and check off Tomes as you find them.
-- Data is a static snapshot (see Data/Echoes.lua / Data/Tomes.lua) -- it will drift from the
-- live server as Echoes get added or rebalanced. Report stale data in the Ebonhold Discord.
--
-- This file holds ownership detection, the four tabs, and the main frame.
-- Shared pieces live alongside it (see EchoCodex.toc for load order):
--   Init.lua     namespace, constants, theme
--   Widgets.lua  flat button/checkbox/list primitives
--   DB.lua       saved variables
--   Util.lua     filtering, formatting, tooltips

local ADDON_NAME, ns = ...

-- Assign-once values, re-localized for brevity and lookup speed. Safe to
-- copy because nothing ever reassigns them -- unlike ns.charDB and the
-- active-wishlist pointers below, which MUST stay `ns.`-qualified at every
-- use site since they're swapped whenever the active wishlist changes.
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
local InitDB = ns.InitDB

local ClassMaskToColoredString = ns.ClassMaskToColoredString
local RoleListToString = ns.RoleListToString
local GetFilteredEchoes = ns.GetFilteredEchoes
local LocationSummary = ns.LocationSummary
local ShowTomeTooltip = ns.ShowTomeTooltip


-- Per-tab widgets now live in the file that builds them; the main frame
-- reaches tabs only through the ns.tabs registry.
local mainFrame, tabButtons, tabFrames, activeTab

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
  local tab = ns.tabs[name]
  if tab and tab.onSelect then tab.onSelect() end
end

----------------------------------------------------------------------
-- Refresh-all + frame construction
----------------------------------------------------------------------

function EC.RefreshAll()
  EC.RefreshOwnedCache()
  for _, name in ipairs(ns.tabOrder) do
    local tab = ns.tabs[name]
    if tab and tab.refresh then tab.refresh() end
  end
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

  local prevTab
  for i, n in ipairs(ns.tabOrder) do
    local btn = BuildTabButton(tabHolder, "EchoCodexTabButton" .. i, ns.tabs[n].label)
    if prevTab then btn:SetPoint("LEFT", prevTab, "RIGHT", 18, 0) else btn:SetPoint("LEFT", 0, 0) end
    btn:SetScript("OnClick", function() SelectTab(n) end)
    tabButtons[n] = btn
    prevTab = btn
  end

  local contentHolder = CreateFrame("Frame", nil, mainFrame)
  contentHolder:SetPoint("TOPLEFT", tabHolder, "BOTTOMLEFT", 0, -8)
  contentHolder:SetPoint("BOTTOMRIGHT", -12, 12)

  for _, n in ipairs(ns.tabOrder) do
    tabFrames[n] = ns.tabs[n].build(contentHolder)
  end

  if EchoCodexDB.framePos then
    mainFrame:ClearAllPoints()
    mainFrame:SetPoint(EchoCodexDB.framePos.point, UIParent, EchoCodexDB.framePos.point, EchoCodexDB.framePos.x, EchoCodexDB.framePos.y)
  end

  EC.RefreshOwnedCache()
  EC.RefreshBrowse()
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
    local tab = ns.tabs[activeTab]
    if tab and tab.onSelect then tab.onSelect() end
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

local hookedEbonholdHubBuild = false

local function TryHookEbonholdHubBuild()
  if hookedEbonholdHubBuild then return end
  if EbonholdHub and EbonholdHub.Build and EbonholdHub.Build.OnActiveChanged then
    EbonholdHub.Build.OnActiveChanged(function() MarkOwnershipDirty() end)
    hookedEbonholdHubBuild = true
  end
end

local ownershipEvents = CreateFrame("Frame")
ownershipEvents:RegisterEvent("SPELLS_CHANGED")
ownershipEvents:RegisterEvent("LEARNED_SPELL_IN_TAB")
ownershipEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
ownershipEvents:SetScript("OnEvent", function(self, event)
  TryHookEchoJournal() -- ProjectEbonhold may not have existed yet at ADDON_LOADED
  TryHookEbonholdHubBuild() -- ditto for EbonholdHub
  MarkOwnershipDirty()
end)

----------------------------------------------------------------------
-- Loading + slash commands
----------------------------------------------------------------------

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event, name)
  if event == "ADDON_LOADED" then
    if name ~= ADDON_NAME then return end
    InitDB()
    BuildMainFrame()
    TryHookEchoJournal()
    TryHookEbonholdHubBuild()
    self:UnregisterEvent("ADDON_LOADED")
    return
  end

  if event == "PLAYER_LOGIN" then
    self:UnregisterEvent("PLAYER_LOGIN")

    -- /echocodex is specific enough to claim unconditionally. /eco is short
    -- and more likely to be used by another addon, so only claim it if no
    -- other addon has already bound it by this point (all addons have
    -- finished registering their SLASH_ commands by PLAYER_LOGIN) -- we
    -- don't want to steal a command another addon is already using.
    local shortCmd = "eco"
    local takenBy = hash_SlashCmdList and hash_SlashCmdList["/" .. shortCmd:upper()]
    local shortHint = "/echocodex"
    if not takenBy or takenBy == "ECHOCODEX" then
      SLASH_ECHOCODEX2 = "/" .. shortCmd
      shortHint = "/" .. shortCmd
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cffffd100Echo Codex|r loaded. Type |cff71d5ff" .. shortHint .. "|r to open it.")
  end
end)

SLASH_ECHOCODEX1 = "/echocodex"
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
