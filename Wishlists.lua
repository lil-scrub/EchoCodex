-- Echo Codex -- Wishlist tab: the per-character named wishlists, their
-- create/rename/delete/duplicate popups, and the wishlist row list.

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

-- Widgets owned by this tab, populated in BuildWishlistTab.
local wishlistList, wishlistCountFS, wishlistEmptyText

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
-- Multiple named wishlists (per character)
----------------------------------------------------------------------

local wishlistDropdown

function EC.ListWishlistNames()
  local names = {}
  for name in pairs(ns.charDB.wishlists) do names[#names + 1] = name end
  table.sort(names)
  return names
end

function EC.GetActiveWishlistName()
  return ns.charDB.activeWishlist
end

function EC.SetActiveWishlist(name)
  local ws = ns.charDB.wishlists[name]
  if not ws then return false end
  ns.charDB.activeWishlist = name
  ns.activeWishlistItems = ws.items
  ns.activeWishlistFound = ws.found
  if wishlistDropdown then UIDropDownMenu_SetText(wishlistDropdown, name) end
  -- A different wishlist is a genuinely new list, not an in-place update --
  -- start both its views at the top rather than holding whatever offset the
  -- previously-active wishlist happened to be scrolled to.
  for _, tabName in ipairs(ns.tabOrder) do
    local tab = ns.tabs[tabName]
    if tab and tab.resetScroll then tab.resetScroll() end
  end
  EC.RefreshAll()
  return true
end

function EC.CreateWishlist(name)
  name = strtrim(name or "")
  if name == "" then return false, "Name can't be empty." end
  if ns.charDB.wishlists[name] then
    return false, "A wishlist named \"" .. name .. "\" already exists."
  end
  ns.charDB.wishlists[name] = NewWishlist()
  EC.SetActiveWishlist(name)
  return true
end

function EC.RenameActiveWishlist(newName)
  newName = strtrim(newName or "")
  local oldName = ns.charDB.activeWishlist
  if newName == "" then return false, "Name can't be empty." end
  if newName == oldName then return true end
  if ns.charDB.wishlists[newName] then
    return false, "A wishlist named \"" .. newName .. "\" already exists."
  end
  ns.charDB.wishlists[newName] = ns.charDB.wishlists[oldName]
  ns.charDB.wishlists[oldName] = nil
  ns.charDB.activeWishlist = newName
  if wishlistDropdown then UIDropDownMenu_SetText(wishlistDropdown, newName) end
  return true
end

function EC.DeleteActiveWishlist()
  if #EC.ListWishlistNames() <= 1 then
    return false, "Can't delete your only wishlist."
  end
  local oldName = ns.charDB.activeWishlist
  ns.charDB.wishlists[oldName] = nil
  EC.SetActiveWishlist(next(ns.charDB.wishlists))
  return true, oldName
end

-- "<name> Copy", then "<name> Copy 2", "<name> Copy 3", ... -- first name
-- in that sequence that isn't already taken.
local function SuggestDuplicateName(baseName)
  local candidate = baseName .. " Copy"
  if not ns.charDB.wishlists[candidate] then return candidate end
  local n = 2
  while ns.charDB.wishlists[baseName .. " Copy " .. n] do n = n + 1 end
  return baseName .. " Copy " .. n
end

function EC.DuplicateActiveWishlist(newName)
  newName = strtrim(newName or "")
  if newName == "" then return false, "Name can't be empty." end
  if ns.charDB.wishlists[newName] then
    return false, "A wishlist named \"" .. newName .. "\" already exists."
  end
  local source = ns.charDB.wishlists[ns.charDB.activeWishlist]
  local copy = { items = {}, found = {} }
  for id in pairs(source.items) do copy.items[id] = true end
  for key in pairs(source.found) do copy.found[key] = true end
  ns.charDB.wishlists[newName] = copy
  EC.SetActiveWishlist(newName)
  return true
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
      editBox:SetText(ns.charDB.activeWishlist)
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
  text = "Delete wishlist \"%s\"? This removes its items and Missing Tomes progress permanently.",
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

StaticPopupDialogs["ECHOCODEX_DUPLICATE_WISHLIST"] = {
  text = "Name for the duplicate of \"%s\":",
  button1 = "Duplicate",
  button2 = "Cancel",
  hasEditBox = true,
  maxLetters = 40,
  OnShow = function(self)
    local editBox = ResolvePopupEditBox(self)
    if editBox then
      editBox:SetText(SuggestDuplicateName(ns.charDB.activeWishlist))
      editBox:HighlightText()
      editBox:SetFocus()
    end
  end,
  OnAccept = function(self)
    local editBox = ResolvePopupEditBox(self)
    local ok, err = EC.DuplicateActiveWishlist(editBox and editBox:GetText())
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
    info.checked = (name == ns.charDB.activeWishlist)
    info.func = function() EC.SetActiveWishlist(name) end
    UIDropDownMenu_AddButton(info)
  end
end

local importStatusFS

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
    ns.activeWishlistItems[echo.id] = nil
    EC.RefreshAll()
  end)
end

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
  UIDropDownMenu_SetText(wishlistDropdown, ns.charDB.activeWishlist)

  local newWishlistBtn = CreateFlatButton(f, "EchoCodexNewWishlistBtn", 46, 20, "New")
  newWishlistBtn:SetPoint("LEFT", wishlistDropdown, "RIGHT", 2, 2)
  newWishlistBtn:HookScript("OnClick", function() StaticPopup_Show("ECHOCODEX_NEW_WISHLIST") end)

  local renameWishlistBtn = CreateFlatButton(f, "EchoCodexRenameWishlistBtn", 66, 20, "Rename")
  renameWishlistBtn:SetPoint("LEFT", newWishlistBtn, "RIGHT", 6, 0)
  renameWishlistBtn:HookScript("OnClick", function() StaticPopup_Show("ECHOCODEX_RENAME_WISHLIST") end)

  local deleteWishlistBtn = CreateFlatButton(f, "EchoCodexDeleteWishlistBtn", 66, 20, "Delete")
  deleteWishlistBtn:SetPoint("LEFT", renameWishlistBtn, "RIGHT", 6, 0)
  deleteWishlistBtn:HookScript("OnClick", function()
    StaticPopup_Show("ECHOCODEX_DELETE_WISHLIST", ns.charDB.activeWishlist)
  end)

  local duplicateWishlistBtn = CreateFlatButton(f, "EchoCodexDuplicateWishlistBtn", 86, 20, "Duplicate")
  duplicateWishlistBtn:SetPoint("LEFT", deleteWishlistBtn, "RIGHT", 6, 0)
  duplicateWishlistBtn:HookScript("OnClick", function()
    StaticPopup_Show("ECHOCODEX_DUPLICATE_WISHLIST", ns.charDB.activeWishlist)
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
  hint:SetText("Echoes you're planning to pick up. Add them from the Browse tab. Wishlist items that need a Tome show up on the Missing Tomes tab so you can track down and mark off where to farm them.")

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
  exportBtn:SetPoint("TOPRIGHT", importStatusFS, "BOTTOMRIGHT", -6, -12)
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
    StaticPopup_Show("ECHOCODEX_EXPORT_WISHLIST", ns.charDB.activeWishlist)
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



function EC.RefreshWishlist()
  local ids = {}
  for id in pairs(ns.activeWishlistItems) do ids[id] = true end
  local data = GetFilteredEchoes({}, ids)
  wishlistList:SetData(data)
  local tomeCount = 0
  for _, e in ipairs(data) do if e.t then tomeCount = tomeCount + 1 end end
  wishlistCountFS:SetText(string.format("%d item%s in \"%s\"  (%d require a Tome)",
    #data, #data == 1 and "" or "s", ns.charDB.activeWishlist or "?", tomeCount))
  if wishlistEmptyText then
    if #data == 0 then wishlistEmptyText:Show() else wishlistEmptyText:Hide() end
  end
end

ns.tabs.wishlist = {
  label = "Wishlist",
  build = BuildWishlistTab,
  refresh = EC.RefreshWishlist,
  onSelect = EC.RefreshWishlist,
  resetScroll = function()
    if wishlistList then
      wishlistList.scroll.offset = 0
      wishlistList.scroll:SetVerticalScroll(0)
    end
  end,
}
