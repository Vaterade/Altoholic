# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Altoholic for the WoW 1.12 client (Turtle WoW fork): a Lua addon that records every
character's bags, bank, mail, equipment, professions, quests, reputations and raid lockouts
into one account-wide saved variable (`AltoholicDB`) and shows them in a window styled like
pfUI's settings. There is no XML: every frame is made in Lua.

Since 1.4.0 it **requires [ClassicAPI](https://github.com/brues-code/ClassicAPI)**, a client DLL
that rewrites Lua 5.1 syntax onto the client's Lua 5.0 VM and backports parts of the modern
addon API. There is no stock-client fallback.

## Commands

There is no build step. The offline checks are syntax passes and a test of the data layer:

```sh
luajit tools/test.lua      # loads the TOC's Lua files without the window, fires the scan events
find . -name '*.lua' -not -path './private/*' -not -path './.git/*' -print0 | xargs -0 -n1 luac -p
```

`tools/test.lua` stubs the client API (unknown globals become no-op stubs, frames accept
any method) and also opens every page of the window, so a Lua error in a view shows up
offline. It can't show what the window looks like.

`luac` here is a current Lua, so it accepts the 5.1 syntax the addon uses but will not catch
5.0-only breakage in `ClassicAPICheck.lua` (see below).

The repo root is the addon folder. For testing, link the client's
`Interface/AddOns/Altoholic` to the repo (the folder must be named `Altoholic`); a `/reload` then
picks up changes, and the game loads whatever branch is checked out. Back up
`WTF/Account/<name>/SavedVariables/Altoholic.lua` before testing anything that touches the
database.

## Writing code for this client

- Lua 5.1 syntax and stdlib are available (`#t`, `%`, `...`, `s:match()`, `string.gmatch`,
  `select`, `strsplit`, `strtrim`). Nothing newer: no `goto`, no integer division, no `\z`.
- **`ClassicAPICheck.lua` must stay valid Lua 5.0.** It is the only file the plain
  `Altoholic.toc` loads, and it runs on clients without the DLL to show the "ClassicAPI
  required" notice. No `#`, no `%`, no string methods, no `...` there.
- The global `GetItemInfo` is still treated as the short 1.12 tuple
  (`name, link, rarity, minLevel, type, subType, stackCount, equipLoc, texture`), not the
  retail one.
- ClassicAPI's reference is one ~830 KB file, too large to fetch whole. Query it with
  `curl -sL https://raw.githubusercontent.com/brues-code/ClassicAPI/master/docs/API.md | grep …`
  (the branch is `master`).
- File encodings are mixed: `Items/Suggestions_zh*.lua` carry a UTF-8 BOM,
  and `Items/Suggestions.lua` contains non-UTF-8 bytes. Scripted bulk edits must be
  byte-preserving (read and write as latin-1) or they will fail or corrupt those files.
- `private/` is git-ignored. Files that should not reach players' downloads are marked
  `export-ignore` in `.gitattributes`.

## Architecture

### Two TOC files

ClassicAPI loads `Altoholic_ClassicAPI.toc` in preference to `Altoholic.toc`. The first is the
real manifest and defines the load order; the second is a stub that loads only
`ClassicAPICheck.lua` and still declares `SavedVariables` so stored data is written back
untouched. A new file must be added to `Altoholic_ClassicAPI.toc`. Keep `## Version` in
both TOCs and `Altoholic.vars.version` in `Init.lua` in step.

### The base (replaces Ace2)

Everything hangs off the single global table `Altoholic`.
Load order matters:

- `Init.lua` creates `Altoholic`, the event dispatcher and the `/alto` slash command.
  `Altoholic:RegisterEvent("X")` routes the event to the method of the same name **without the
  event name**: `BAG_UPDATE` calls `Altoholic:BAG_UPDATE(bag)`. Adding an event means
  registering it and defining that method.
- `Locale.lua` provides `Altoholic.L`. Keys are the English strings; a missing key returns
  itself. Only enUS and the client's locale are built. Every file starts with
  `local L = Altoholic.L`. Boss names are `L` strings too, translated in
  `Locale/Bosses.lua`; the addon bundles no libraries. Names the client already translates
  are read from its data by ID:
  profession, faction and zone names from `Altoholic.Professions`, `Altoholic.Factions`
  and `Altoholic.Zones` (Core.lua, by skill line, faction and area ID), item types with
  `GetItemClassInfo`/`GetItemSubClassInfo`, slot names from the `INVTYPE_*` and `*SLOT`
  global strings. Check IDs against the client's own DBCs: Turtle reuses some
  Burning Crusade IDs for its own factions. Do these lookups at `PLAYER_LOGIN`, not at
  file scope: `ReadClientNames()` fills those tables, and tables that use client names
  are built by functions called after it (`BuildFactionsRefTable`, `BuildLootTable`,
  `BuildSuggestions`, `BuildSearchSubMenu`). `GetItemClassInfo(0)` (Consumable) returns
  nil, so match items by class and subclass ID rather than by name, and give labels an
  English fallback.
- `Database.lua` owns the saved data. `Altoholic:InitDatabase()` runs at `PLAYER_LOGIN` and
  sets `self.db.account` to `AltoholicDB.account`, giving `self.db.account.options` and
  `self.db.account.data[faction][realm].{char,guild,reputation}[name]`. The layout is the one
  AceDB wrote, so it must not change without a migration.
  A `['*']` key in the defaults table means "any other key": **reading a missing entry creates
  it**. `CleanDatabase()` at `PLAYER_LOGOUT` strips whatever still equals its default, which is
  what removes characters that were only ever looked up. A new per-character field with a
  default belongs in that defaults table.
- `Core.lua` holds constants and shared helpers; `Items/` holds the loot tables (item IDs by
  source, from AtlasLoot) and the per-class suggestion data.

### Startup and scanning (`Data/`)

The data layer is `Core.lua`, `Data/*.lua` and `Items/`, and it doesn't touch the window:
`tools/test.lua` loads it alone. `Data/Scan.lua` (login, bags, bank, stats, events),
`Professions.lua`, `Mail.lua`, `Auctions.lua`, `Quests.lua` capture data; `Tooltip.lua`
extends tooltips; `Query.lua` holds formatting helpers and `Constants.lua` shared tables.
`Trades.lua` queues saved recipes in pfUI-trades (`pfUITrades.QueueFor`) when it is loaded;
pfUI-trades keeps lists by realm, so only the logged-in realm's characters can be queued.
Settings are read with `Altoholic:Option(name)` (1 or nil), never from a widget. A scan that
changes what the window lists calls `Altoholic:DataChanged(what)`, and the window, if loaded,
answers through `Altoholic:OnDataChanged(what)`; `PLAYER_LOGIN` likewise calls
`Altoholic:UI_OnLogin()` when it exists.

`PLAYER_LOGIN` initialises the database and registers the always-on events.
`PLAYER_ENTERING_WORLD` waits one second (to let the login burst of events pass) and calls
`StartScanning()`, which registers the bag, equipment, quest and tradeskill events, takes the
first snapshot of the current character and installs the tooltip hooks.

Data is only ever captured for the logged-in character, when the game makes it available:
bank at `BANKFRAME_OPENED`, mail at `MAIL_SHOW`, auctions at `AUCTION_HOUSE_SHOW`, recipes when
a profession window opens. Bags rescan on `BAG_UPDATE_DELAYED`; that event does not fire for the
keyring, so `BAG_UPDATE` is kept for bag `-2` only.

Completed quests cannot be queried through any API. They come from Turtle WoW's `.queststatus`
server command, whose reply arrives as `CHAT_MSG_ADDON` with prefix `TWQUEST`;
`QUEST_TURNED_IN` keeps the list current between polls. The Attunements tab depends on this.

Item tooltips are extended through `HookScript("OnTooltipSetItem")` on `GameTooltip` and
`ItemRefTooltip`. That handler receives the tooltip as the global `this`, not as an argument.

### The window (`UI/`)

- `UI/Widgets.lua` (`Altoholic.W`) is the only place that knows about pfUI. It draws every
  control in pfUI's style (panels, buttons, check boxes, edit boxes, dropdowns, sliders,
  item buttons, a right-click menu, a virtual `List` and a `Table` with column captions)
  and reads pfUI's colours, font and pixel size from `pfUI_config` / `pfUI` when present.
  pfUI is never required. Don't use Blizzard templates or `UIDropDownMenu`.
- `UI/Window.lua` (`Altoholic.UI`) builds `AltoholicWindow` like pfUI's config: categories,
  the category's entries (a second column), the page, and a bottom bar with the view's own
  strip on the left and the search box on the right. `UI/Menu.lua` lists the categories;
  `UI.CharacterEntries` makes the realm-grouped character entries. Characters are refs
  `{ faction, realm, name, c }` from `UI.Realms()`, which groups both factions of a realm.
- A page is a view, `UI.RegisterView(name, { Create(frame, bar), Update(args) })`, in
  `UI/Views/`. `UI.Open(categoryId, entryKey)` opens a page from anywhere.
  `UI/Grid.lua` lays out realm-wide comparisons (characters as columns).
- Read saved data with `rawget`, and give lists to widgets as `UI.Array(t)` copies: saved
  tables with `'*'` defaults create an entry for any key or index that is read, and a list
  widget reads past the end while it fills its rows.
- Pages are redrawn (throttled) on `GET_ITEM_INFO_RECEIVED` and when a scan calls
  `DataChanged`.

### Script handler conventions

- Handlers set with `SetScript`/`HookScript` take positional arguments
  (`function(self, button)`), which ClassicAPI supplies.
