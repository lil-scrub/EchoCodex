-- Minimal stand-in for the WoW 3.3.5 client API, enough to load Echo Codex
-- outside the game and drive its logic from tests.
--
-- The frame stub distinguishes METHODS from DATA FIELDS by capitalization,
-- which works because the two follow different conventions here: every WoW
-- widget method is PascalCase (SetPoint, CreateFontString, Show), while the
-- addon's own per-frame data is camelCase (offset, updateRow, echo, rows).
-- An unknown PascalCase key returns a no-op method; an unknown camelCase key
-- returns nil, so `(self.scroll.offset or 0)` still yields a number instead
-- of a function that would blow up the comparison.

local M = {}

local frameMeta
local noopCache = {}

local function noop() return nil end

local function isMethodName(k)
  return type(k) == "string" and k:match("^%u") ~= nil
end

frameMeta = {
  __index = function(t, k)
    if isMethodName(k) then
      local fn = noopCache[k]
      if not fn then
        fn = function(...) return nil end
        noopCache[k] = fn
      end
      return fn
    end
    return nil
  end,
}

local function NewWidget(kind, name)
  local w = { _kind = kind, _name = name, _children = {} }
  setmetatable(w, frameMeta)

  function w:GetName() return self._name end
  function w:CreateTexture() return NewWidget("Texture") end
  function w:CreateFontString() return NewWidget("FontString") end
  -- Numeric getters must return numbers: they feed arithmetic in the widget
  -- code (math.ceil(label:GetStringWidth() or 0), etc.).
  function w:GetStringWidth() return 0 end
  function w:GetHeight() return 0 end
  function w:GetWidth() return 0 end
  function w:GetText() return self._text or "" end
  function w:SetText(v) self._text = v end
  function w:IsShown() return self._shown and true or false end
  function w:Show() self._shown = true end
  function w:Hide() self._shown = false end
  function w:SetScript(evt, fn) self._scripts = self._scripts or {}; self._scripts[evt] = fn end
  function w:HookScript(evt, fn) self._scripts = self._scripts or {}; self._scripts[evt] = fn end
  function w:GetScript(evt) return self._scripts and self._scripts[evt] end
  function w:RegisterEvent(e) self._events = self._events or {}; self._events[e] = true end
  function w:UnregisterEvent(e) if self._events then self._events[e] = nil end end
  -- GetPoint feeds the saved window position; return a plausible tuple.
  function w:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end

  return w
end

M.NewWidget = NewWidget

-- Fire a registered event on every frame that asked for it.
function M.FireEvent(event, ...)
  for _, f in ipairs(M.frames) do
    if f._events and f._events[event] and f._scripts and f._scripts.OnEvent then
      f._scripts.OnEvent(f, event, ...)
    end
  end
end

function M.install()
  M.frames = {}
  M.chat = {}

  _G.UIParent = NewWidget("Frame", "UIParent")
  _G.UISpecialFrames = {}

  _G.CreateFrame = function(frameType, name, parent, template)
    local f = NewWidget(frameType, name)
    f._parent, f._template = parent, template
    if name then _G[name] = f end
    table.insert(M.frames, f)
    return f
  end

  _G.GameTooltip = NewWidget("GameTooltip", "GameTooltip")
  _G.GameFontHighlightSmall = NewWidget("Font", "GameFontHighlightSmall")

  _G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(_, msg) table.insert(M.chat, msg) end,
  }

  -- Scroll helpers: offset stays 0 so Refresh renders from the top.
  _G.FauxScrollFrame_Update = noop
  _G.FauxScrollFrame_OnVerticalScroll = noop
  _G.FauxScrollFrame_GetOffset = function() return 0 end

  _G.UIDropDownMenu_CreateInfo = function() return {} end
  _G.UIDropDownMenu_AddButton = noop
  _G.UIDropDownMenu_Initialize = noop
  _G.UIDropDownMenu_SetText = noop
  _G.UIDropDownMenu_SetWidth = noop

  _G.StaticPopupDialogs = {}
  _G.StaticPopup_Show = noop

  _G.SlashCmdList = {}
  _G.hash_SlashCmdList = {}

  _G.RAID_CLASS_COLORS = {
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    WARLOCK = { r = 0.53, g = 0.53, b = 0.93 },
    PRIEST  = { r = 1.00, g = 1.00, b = 1.00 },
  }

  _G.GetRealmName = function() return "TestRealm" end
  _G.UnitName = function() return "Tester" end
  _G.UnitClass = function() return "Warlock", "WARLOCK" end

  -- Spellbook: empty by default. The addon treats a missing "Echoes" tab as
  -- normal (foundEchoesTab stays false), which matches the live account this
  -- was developed against.
  _G.BOOKTYPE_SPELL = "spell"
  _G.GetNumSpellTabs = function() return 0 end
  _G.GetSpellTabInfo = function() return nil end
  _G.GetSpellLink = function() return nil end
  _G.GetSpellInfo = function() return nil end
  _G.IsSpellKnown = function() return false end
  _G.IsPlayerSpell = nil
  _G.IsUsableSpell = function() return false end

  _G.strtrim = function(s, chars)
    if not s then return "" end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
  end
  _G.tinsert = table.insert
  _G.date = os.date

  -- `bit` is deliberately left nil so Init.lua exercises its own pure-Lua
  -- band() fallback -- the same path a client without the bit library takes.
  _G.bit = nil

  -- Server addons: absent unless a test opts in.
  _G.ProjectEbonhold = nil
  _G.ProjectEbonholdDB = nil
  _G.EbonholdHub = nil
  _G.EchoCodexDB = nil
end

return M
