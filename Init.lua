-- Echo Codex -- shared namespace, constants, and theme.
--
-- Loaded FIRST (see EchoCodex.toc): every other file starts with
--   local ADDON_NAME, ns = ...
-- and pulls what it needs off `ns`. That second vararg is WoW's built-in
-- per-addon private table -- shared across all of this addon's Lua files,
-- invisible to other addons, and no globals involved.
--
-- Convention used throughout: anything assigned ONCE (constants, widget
-- constructors, helper functions) gets re-localized at the top of each
-- consuming file for speed and brevity. Anything REASSIGNED at runtime
-- (ns.charDB and the active-wishlist pointers) must always be read through
-- `ns.` at the point of use -- a file-local copy of those would go stale
-- the moment the active wishlist switches.

local ADDON_NAME, ns = ...

ns.ADDON_NAME = ADDON_NAME

----------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------

ns.ROW_HEIGHT = 30
ns.FRAME_WIDTH = 720
ns.FRAME_HEIGHT = 600

ns.QUALITY_NAMES = { [0] = "Common", [1] = "Uncommon", [2] = "Rare", [3] = "Epic" }
ns.QUALITY_COLORS = {
  [0] = { r = 1,    g = 1,    b = 1 },
  [1] = { r = 0.12, g = 1,    b = 0 },
  [2] = { r = 0.15, g = 0.55, b = 1 },
  [3] = { r = 0.72, g = 0.35, b = 0.98 },
}

ns.ROLE_LIST = { "Tank", "Melee DPS", "Ranged DPS", "Caster DPS", "Healer", "Survivability" }

ns.CLASS_MASK_INFO = {
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

ns.ALL_CLASS_MASK = 0
for _, c in ipairs(ns.CLASS_MASK_INFO) do ns.ALL_CLASS_MASK = ns.ALL_CLASS_MASK + c.mask end

ns.CLASS_BY_FILE = {}
for _, c in ipairs(ns.CLASS_MASK_INFO) do ns.CLASS_BY_FILE[c.file] = c end

ns.band = bit and bit.band or function(a, b)
  -- Fallback bitwise AND in case the bit library isn't exposed (shouldn't happen in-client).
  local result, bitval = 0, 1
  while a > 0 and b > 0 do
    if a % 2 == 1 and b % 2 == 1 then result = result + bitval end
    a, b, bitval = math.floor(a / 2), math.floor(b / 2), bitval * 2
  end
  return result
end

ns.DEFAULT_WISHLIST_NAME = "Default"

-- The player's class file token ("WARLOCK"), used by the Browse tab's
-- "My Class" filter and stamped into wishlist export strings.
ns.myClassFile = select(2, UnitClass("player"))

----------------------------------------------------------------------
-- Flat theme
--
-- Visually similar to EbonholdHub's UI kit: flat colored panels (a plain
-- white texture tinted via SetVertexColor, no Blizzard dialog art), thin
-- 1px borders, and buttons/checkboxes whose whole rect is the click
-- target -- notably including the close button, which is what made the
-- old Blizzard dialog-border close icon annoying to hit.
----------------------------------------------------------------------

ns.FLAT_TEX = "Interface\\Buttons\\WHITE8X8"

ns.THEME = {
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

----------------------------------------------------------------------
-- Addon-wide API table
--
-- Holds the cross-cutting functions the UI calls (EC.RefreshAll,
-- EC.IsEchoKnown, EC.SetActiveWishlist, ...). Defined here so every file
-- can do `local EC = ns.EC` regardless of load order.
----------------------------------------------------------------------

ns.EC = {}
ns.EC.state = {
  search = "",
  classMask = nil,
  qualitySet = {},
  role = nil,
  tomeOnly = false,
}

----------------------------------------------------------------------
-- Tab registry
--
-- Each Tab_*.lua / Wishlists.lua file registers itself here instead of
-- exposing its widgets, so the main frame can build, switch, and refresh
-- tabs without any file reaching into another's frames. Each entry:
--
--   label        text on the tab button
--   build(parent)  -> the tab's content frame, called once at ADDON_LOADED
--   onSelect()     when this tab becomes the visible one
--   refresh()      full rebuild of its contents (used by EC.RefreshAll)
--   resetScroll()  optional; called when the active wishlist changes, so a
--                  wishlist-scoped list starts at the top instead of
--                  holding the previous list's scroll offset
--
-- tabOrder fixes the left-to-right button order; the keys must match.
----------------------------------------------------------------------

ns.tabs = {}
ns.tabOrder = { "browse", "wishlist", "checklist", "currentbuild" }
