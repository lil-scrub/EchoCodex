-- Echo Codex -- UI primitives built on the flat theme (see Init.lua).
--
-- Everything here is a pure constructor: it takes a parent frame and
-- returns a widget, touching no addon state. That's what makes this the
-- safest file in the addon to change in isolation.

local ADDON_NAME, ns = ...

local THEME = ns.THEME
local FLAT_TEX = ns.FLAT_TEX
local ROW_HEIGHT = ns.ROW_HEIGHT

----------------------------------------------------------------------
-- Fills and borders
----------------------------------------------------------------------

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

----------------------------------------------------------------------
-- Buttons and checkboxes
----------------------------------------------------------------------

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
    -- Clamp defensively if the data shrank (e.g. Missing Tomes entries
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

ns.Fill = Fill
ns.ThinBorder = ThinBorder
ns.SetBorderColor = SetBorderColor
ns.CreateFlatButton = CreateFlatButton
ns.CreateFlatCheckbox = CreateFlatCheckbox
ns.CreateList = CreateList
