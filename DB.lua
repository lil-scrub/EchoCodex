-- Echo Codex -- saved variables.
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
--
-- NOTE ON STATE: ns.charDB, ns.activeWishlistItems and ns.activeWishlistFound
-- are REASSIGNED at runtime (here on load, and again in EC.SetActiveWishlist
-- every time the active wishlist changes). Always read them through `ns.` at
-- the point of use -- a file-local copy taken at load time would silently go
-- stale the moment the player switches wishlists.

local ADDON_NAME, ns = ...

local DEFAULT_WISHLIST_NAME = ns.DEFAULT_WISHLIST_NAME

local function NewWishlist()
  return { items = {}, found = {} }
end

local function CharacterKey()
  local realm = (GetRealmName and GetRealmName()) or "UnknownRealm"
  local name = (UnitName and UnitName("player")) or "UnknownCharacter"
  return realm .. " - " .. name
end

local function InitDB()
  EchoCodexDB = EchoCodexDB or {}
  EchoCodexDB.framePos = EchoCodexDB.framePos or nil
  EchoCodexDB.characters = EchoCodexDB.characters or {}

  local key = CharacterKey()
  local charDB = EchoCodexDB.characters[key]
  if not charDB then
    charDB = {}
    EchoCodexDB.characters[key] = charDB
  end
  charDB.wishlists = charDB.wishlists or {}
  ns.charDB = charDB

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
  ns.activeWishlistItems = active.items
  ns.activeWishlistFound = active.found
end

ns.NewWishlist = NewWishlist
ns.CharacterKey = CharacterKey
ns.InitDB = InitDB
