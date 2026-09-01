-- Echo Codex -- Browse tab: search and filter the full Echo list.

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

-- Widgets owned by this tab, populated in BuildBrowseTab.
local browseList, resultCountFS

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

  local inWishlist = ns.activeWishlistItems[echo.id]
  row.actionBtn.label:SetText(inWishlist and "Remove" or "Add")
  row.actionBtn:SetScript("OnClick", function()
    if ns.activeWishlistItems[echo.id] then
      ns.activeWishlistItems[echo.id] = nil
    else
      ns.activeWishlistItems[echo.id] = true
    end
    EC.RefreshAll()
  end)
end

local classDropdown, roleDropdown
local myClassFile = ns.myClassFile

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

-- Re-applies the current filters. Separate from the list's own :Refresh(),
-- which only re-renders the rows already selected.
function EC.RefreshBrowse()
  browseList:SetData(GetFilteredEchoes(EC.state))
  EC.UpdateResultCount()
end

ns.tabs.browse = {
  label = "Browse",
  build = BuildBrowseTab,
  refresh = EC.RefreshBrowse,
  -- Selecting the tab only re-renders: the filters haven't changed, and a
  -- full SetData would discard the reader's scroll position.
  onSelect = function() if browseList then browseList:Refresh() end end,
}

