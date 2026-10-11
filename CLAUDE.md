# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Altoholic for the WoW 1.12 client (Turtle WoW fork): a Lua + XML addon that records every
character's bags, bank, mail, equipment, professions, quests, reputations and raid lockouts
into one account-wide saved variable (`AltoholicDB`) and shows them in a tabbed window.

Since 1.4.0 it **requires [ClassicAPI](https://github.com/brues-code/ClassicAPI)**, a client DLL
that rewrites Lua 5.1 syntax onto the client's Lua 5.0 VM and backports parts of the modern
addon API. There is no stock-client fallback.

## Commands

There is no build step and no test suite. The only offline checks are syntax passes:

```sh
find Altoholic -name '*.lua' -not -path '*/private/*' -print0 | xargs -0 -n1 luac -p
find Altoholic -name '*.xml' -print0 | xargs -0 xmllint --noout
```

`luac` here is a current Lua, so it accepts the 5.1 syntax the addon uses but will not catch
5.0-only breakage in `ClassicAPICheck.lua` (see below).

Everything else has to be tested in the game client. The client's `Interface/AddOns/Altoholic`
is a separate copy, not a link to this repo, so changes must be deployed there by hand. Back up
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
- File encodings are mixed: the XML files and `Items/Suggestions_zh*.lua` carry a UTF-8 BOM,
  and `Items/Suggestions.lua` contains non-UTF-8 bytes. Scripted bulk edits must be
  byte-preserving (read and write as latin-1) or they will fail or corrupt those files.
- `Altoholic/private/` is git-ignored.

## Architecture

### Two TOC files

ClassicAPI loads `Altoholic_ClassicAPI.toc` in preference to `Altoholic.toc`. The first is the
real manifest and defines the load order; the second is a stub that loads only
`ClassicAPICheck.lua` and still declares `SavedVariables` so stored data is written back
untouched. A new file must be added to `Altoholic_ClassicAPI.toc` (or pulled in by a
`<Script file=…>` in a module's XML). Keep `## Version` in both TOCs and
`Altoholic.vars.version` in `Init.lua` in step.

### The base (replaces Ace2)

Everything hangs off the single global table `Altoholic`; the XML needs it to be global.
Load order matters:

- `Init.lua` creates `Altoholic`, the event dispatcher and the `/alto` slash command.
  `Altoholic:RegisterEvent("X")` routes the event to the method of the same name **without the
  event name**: `BAG_UPDATE` calls `Altoholic:BAG_UPDATE(bag)`. Adding an event means
  registering it and defining that method.
- `Locale.lua` provides `Altoholic.L`. Keys are the English strings; a missing key returns
  itself. Only enUS and the client's locale are built. Every file starts with
  `local L = Altoholic.L`. Zone, boss, faction and item-type names come from the bundled
  LibBabble libraries (via LibStub) instead.
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

### Startup and scanning (`Altoholic.lua`)

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

### UI modules

Each tab is a `Modules/<Name>.xml` + `<Name>.lua` pair; the XML loads its Lua through a
`<Script file>` element and defines a frame named `Alto<Something>`. The frame names are listed
in `Altoholic.Categories`, and `ActivateMenuItem(frame)` shows one and hides the rest. Each
module exposes `Altoholic:<Name>_Update()`, which redraws a `FauxScrollFrame` from the saved
data. The left-hand menu and its per-character submenus are built in `Altoholic.lua`
(`Menu_Update`, `Build*SubMenu`), and `BuildCharacterInfoTable()` builds the realm/character
line list that the summary-style tabs share.

Tabs that list items can be drawn before the client has the item cached. They are named in the
`ItemTabs` map in `Altoholic.lua` and get redrawn (throttled) on `GET_ITEM_INFO_RECEIVED`; a new
item-listing tab should be added there.

### Script handler conventions

- Handlers set from Lua with `SetScript`/`HookScript` take positional arguments
  (`function(self, button)`), which ClassicAPI supplies.
- Inline `<Scripts>` bodies in XML are kept to one line that passes the 1.12 globals into a
  named Lua function, e.g. `Altoholic_Equipment_OnClick(this, arg1)`. Put logic in the module's
  Lua, not in the XML, and do not rely on `self` inside an XML body.
- `UIDropDownMenu` callbacks still read the global `this`, as the stock 1.12 menu code does.
