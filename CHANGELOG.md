# Changelog

Each release gets a section here, newest first. The release workflow copies the section for
the version in the `.toc` files into the GitHub release notes, so write it for players.

Versions follow [semantic versioning](https://semver.org/): a fix raises the last number, a
new feature the middle one, and a change that breaks the old way of doing things the first.

## [2.0.0] - 2026-11-07

The first release of this overhaul for OctoWoW. It needs
[ClassicAPI](https://github.com/brues-code/ClassicAPI). Your saved data carries over from 1.x.

### Added
- A new window in pfUI's style: a column of categories, a column of characters under their
  realms, and a search box at the bottom that searches as you type. pfUI isn't required;
  with it loaded, the window takes pfUI's colours, font and borders.
- **Notes**: leave notes for any character, from the Notes button or with
  `/alto note <name> <text>`; they pop up when that character logs in.
- **Missing Recipes**: on the Recipes page, the recipes of a profession a character hasn't
  learned, by skill level, with where each is learned or found. With pfQuest loaded, a
  recipe item names who sells or drops it and where, and a click shows them on the map.
- With pfUI-tradeskill loaded, a **Queue** button on each recipe adds crafts to that
  character's task list there; right-click a recipe in Search to queue it too.
- **Find Upgrade** results can be narrowed to what the character can use.
- A **Last Played** column on Account Summary, and column headers on Auctions and Bids with
  the bid and buyout apart.
- An **About** page, under Options, with the version and which optional addons are loaded.

### Changed
- Equipment, Reputations and Attunements compare a realm's characters side by side, both
  factions together.
- Known recipes are tracked by spell ID through ClassicAPI, so a recipe learned from an item
  counts without reopening the profession window.

### Fixed
- Recipes saved under the wrong row type (shown as headers, and listed as missing) are
  repaired at login.
- The text of mails with money in them is kept when "Scan mail body" is on.
- Clearing the goblin auction house's entries works again.

### Removed
- The old Blizzard-style window.

[2.0.0]: https://github.com/Vaterade/Altoholic/releases/tag/v2.0.0
