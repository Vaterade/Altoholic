Altoholic.SearchResults = {}
Altoholic.CharacterInfo = {}
Altoholic.BagIndices = {}
Altoholic.MenuCache = {}
local L = Altoholic.L
local V = Altoholic.vars
local BZ = LibStub("LibBabble-Zone-3.0"):GetLookupTable()

-- Profession names as the client spells them, read from SkillLine.dbc by ID.
-- They are what GetSkillLineInfo returns, so they are also the keys of the
-- saved skill tables. A skill line the client lacks keeps its English name.
local PROFESSION_SKILL_LINES = {
	["Alchemy"] = 171,
	["Blacksmithing"] = 164,
	["Cooking"] = 185,
	["Enchanting"] = 333,
	["Engineering"] = 202,
	["First Aid"] = 129,
	["Fishing"] = 356,
	["Jewelcrafting"] = 755,
	["Leatherworking"] = 165,
	["Tailoring"] = 197,
}

Altoholic.Professions = {}
for name, skillLineID in pairs(PROFESSION_SKILL_LINES) do
	Altoholic.Professions[name] = C_SpellBook.GetSkillLineName(skillLineID) or name
end

-- Faction names as the client spells them, read from Faction.dbc by ID, so they
-- match the names in the reputation list. Factions not listed here, such as the
-- Burning Crusade ones, keep their English names: this client has no rows for
-- them, and Turtle reuses some of their IDs for its own factions.
local FACTION_IDS = {
	["Argent Dawn"] = 529,
	["Bloodsail Buccaneers"] = 87,
	["Brood of Nozdormu"] = 910,
	["Cenarion Circle"] = 609,
	["Darkmoon Faire"] = 909,
	["Frostwolf Clan"] = 729,
	["Gelkis Clan Centaur"] = 92,
	["Hydraxian Waterlords"] = 749,
	["Magram Clan Centaur"] = 93,
	["Silverwing Sentinels"] = 890,
	["Stormpike Guard"] = 730,
	["The Defilers"] = 510,
	["The League of Arathor"] = 509,
	["Thorium Brotherhood"] = 59,
	["Timbermaw Hold"] = 576,
	["Warsong Outriders"] = 889,
	["Wintersaber Trainers"] = 589,
	["Zandalar Tribe"] = 270,
}

Altoholic.Factions = setmetatable({}, { __index = function(self, name) return name end })
for name, factionID in pairs(FACTION_IDS) do
	Altoholic.Factions[name] = (GetFactionInfoByID(factionID)) or name
end
local Factions = Altoholic.Factions

Altoholic.Categories = {
	"AltoSummary", 
	"AltoBags",
	"AltoContainers",
	"AltoMail",
	"AltoSearch",
	"AltoEquipment",
	"AltoReputations",
	"AltoOptions",
	"AltoQuests",
	"AltoRecipes",
	"AltoAuctions",
	"AltoSkills",
	"AltoRaids",
	"AltoAttunements",
}

Altoholic.RecipesBooks = {
    --Craft Recipes:
    "Pattern:",
    "Plans:",
    "Formula:",
    "Schematic:",
    "Recipe:",
    --Class Books:
    "Book of",
    "Book:",
    "Codex of",
    "Codex:",
    "Grimoire of",
    "Grimoire:",
    "Guide:",
    "Handbook of",
    "Libram:",
    "Manual of",
    "Tablet of",
    "Tome of"
}

Altoholic.XPToNext	= { 
-- From: http://www.wowwiki.com/Formulas:XP_To_Level, retrieved Feb 6, 2008
-- read: at XPToNext[1], you need 400 xp to get to 2
    400,900,1400,2100,2800,3600,4500,5400,6500,7600,8800,10100,
    11400,12900,14400,16000,17700,19400,21300,23200,25200,27300,
    29400,31700,34000,36400,38900,41400,44300,47400,50800,54500,
    58600,62800,67100,71600,76100,80800,85700,90700,95800,101000,
    106300,111800,117500,123200,129100,135100,141200,147500,153900,
    160400,167100,173900,180800,187900,195000,202300,209800
}

-- Allow ESC to close the main frame
tinsert(UISpecialFrames, "AltoholicFrame");

-- Factions reference table, based on http://www.wowwiki.com/Factions
-- a table with a similar structure (but only with required lines) will be build to make the reputations frame
Altoholic.FactionsRefTable = {

	{ FACTION_ALLIANCE },
	BZ["Darnassus"],
	L["Exodar"],
	L["Gnomeregan Exiles"],
	BZ["Ironforge"],
	L["Silvermoon Remnant"],
	L["Stormwind"],

	{ FACTION_HORDE },
	L["Darkspear Trolls"],
	BZ["Orgrimmar"],
	BZ["Thunder Bluff"],
	BZ["Undercity"],
	BZ["Silvermoon City"],
	L["Durotar Labor Union"],

	{ L["Alliance Forces"] },
	Factions["The League of Arathor"],
	Factions["Silverwing Sentinels"],
	Factions["Stormpike Guard"],

	{ L["Horde Forces"] },
	Factions["The Defilers"],
	Factions["Warsong Outriders"],
	Factions["Frostwolf Clan"],

	{ L["Steamwheedle Cartel"] },
	BZ["Booty Bay"],
	BZ["Everlook"],
	BZ["Gadgetzan"],
	BZ["Ratchet"],

	{ BZ["Outland"] },
	Factions["Ashtongue Deathsworn"],
	Factions["Cenarion Expedition"],
	Factions["The Consortium"],
	Factions["Honor Hold"],
	Factions["Kurenai"],
	Factions["The Mag'har"],
	Factions["Netherwing"],
	Factions["Ogri'la"],
	Factions["Sporeggar"],
	Factions["Thrallmar"],

	{ BZ["Shattrath City"] },
	Factions["Lower City"],
	Factions["Sha'tari Skyguard"],
	Factions["Shattered Sun Offensive"],
	Factions["The Aldor"],
	Factions["The Scryers"],
	Factions["The Sha'tar"],

	{ L["Other"] },
	Factions["Argent Dawn"],
	Factions["Bloodsail Buccaneers"],
	Factions["Brood of Nozdormu"],
	Factions["Cenarion Circle"],
	Factions["Darkmoon Faire"],
	Factions["Gelkis Clan Centaur"],
	Factions["Hydraxian Waterlords"],
	L["Kul Tiras"],
	Factions["Keepers of Time"],
	Factions["Magram Clan Centaur"],
	L["Ravenholdt"],
	Factions["The Scale of the Sands"],
	L["Shen'dralar"],
	L["Syndicate"],
	L["Theramore"],
	Factions["Thorium Brotherhood"],
	Factions["Timbermaw Hold"],
	Factions["Tranquillien"],
	L["Wardens of Time"],
	L["Wildhammer Clan"],
	Factions["Wintersaber Trainers"],
	Factions["The Violet Eye"],
	Factions["Zandalar Tribe"]
}

-- The stats the upgrade search looks at, by the key C_Item.GetItemStats reports them under.
-- The crit, hit, dodge and block values are percentages.
local STAT_STR = "ITEM_MOD_STRENGTH_SHORT"
local STAT_AGI = "ITEM_MOD_AGILITY_SHORT"
local STAT_STA = "ITEM_MOD_STAMINA_SHORT"
local STAT_INT = "ITEM_MOD_INTELLECT_SHORT"
local STAT_SPI = "ITEM_MOD_SPIRIT_SHORT"
local STAT_CRIT = "ITEM_MOD_CRIT_MELEE_RATING"
local STAT_SPELLCRIT = "ITEM_MOD_CRIT_SPELL_RATING"
local STAT_HIT = "ITEM_MOD_HIT_MELEE_RATING"
local STAT_SPELLHIT = "ITEM_MOD_HIT_SPELL_RATING"
local STAT_HEALING = "ITEM_MOD_SPELL_HEALING_DONE_SHORT"
local STAT_SPELLDMG = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"
local STAT_AP = "ITEM_MOD_ATTACK_POWER_SHORT"
local STAT_RANGED_AP = "ITEM_MOD_RANGED_ATTACK_POWER_SHORT"
local STAT_DEFENSE = "ITEM_MOD_DEFENSE_SKILL_RATING"
local STAT_DODGE = "ITEM_MOD_DODGE_RATING"
local STAT_BLOCK = "ITEM_MOD_BLOCK_RATING"
local STAT_MP5 = "ITEM_MOD_MANA_REGENERATION"
local STAT_RESIST = "RESIST"		-- not a key of GetItemStats: the six resistances added up, see GetUpgradeStats

-- Class constants, for readability, these values match the ones in Altoholic.Classes (altoholic.lua)
local CLASS_MAGE	= 1
local CLASS_WARRIOR	= 2
local CLASS_HUNTER	= 3
local CLASS_ROGUE	= 4
local CLASS_WARLOCK	= 5
local CLASS_DRUID	= 6
local CLASS_SHAMAN	= 7
local CLASS_PALADIN	= 8
local CLASS_PRIEST	= 9

-- An item carrying one of these stats is no upgrade for the class and role
Altoholic.ExcludeStats = {
	[CLASS_MAGE.."DPS"] = { 
		STAT_RESIST,
		STAT_STR,
		STAT_AGI, 
		STAT_HEALING,
		STAT_AP,
		STAT_DEFENSE,
		STAT_DODGE,
		STAT_BLOCK
	},
	[CLASS_WARRIOR.."Tank"]	= { 
		STAT_RESIST,
		STAT_INT,
		STAT_SPI, 
		STAT_MP5, 
		STAT_HEALING, 
		STAT_AP, 
		STAT_SPELLDMG
	},
	[CLASS_WARRIOR.."DPS"] = { 
		STAT_RESIST,
		STAT_INT,
		STAT_SPI, 
		STAT_MP5, 
		STAT_HEALING, 
		STAT_DEFENSE, 
		STAT_SPELLDMG
	},
	[CLASS_HUNTER.."DPS"] = { 
		STAT_RESIST, 
		STAT_STR, 
		STAT_HEALING, 
		STAT_DODGE, 
		STAT_DEFENSE, 
		STAT_SPELLDMG, 
		STAT_BLOCK
	},
	[CLASS_ROGUE.."DPS"] = { 
		STAT_RESIST, 
		STAT_INT,
		STAT_SPI,
		STAT_MP5, 
		STAT_HEALING, 
		STAT_SPELLDMG, 
		STAT_BLOCK, 
		STAT_DEFENSE
	},
	[CLASS_WARLOCK.."DPS"] = { 
		STAT_RESIST, 
		STAT_STR,
		STAT_AGI, 
		STAT_HEALING, 
		STAT_AP, 
		STAT_DEFENSE, 
		STAT_DODGE, 
		STAT_BLOCK
	},
	[CLASS_DRUID.."Tank"] = { 
		STAT_RESIST, 
		STAT_HEALING, 
		STAT_SPELLDMG,
		STAT_AP,
		STAT_BLOCK,
		STAT_SPELLCRIT,
		STAT_SPELLHIT,
		STAT_MP5
	},

	[CLASS_DRUID.."Heal"] = { 
		STAT_RESIST, 
		STAT_STR,
		STAT_AGI,
		STAT_SPELLDMG, 
		STAT_AP,
		STAT_SPELLHIT,  
		STAT_DEFENSE, 
		STAT_DODGE,
		STAT_BLOCK
	},
	[CLASS_DRUID.."DPS"] = { 
		STAT_RESIST, 
		STAT_INT,
		STAT_SPI, 
		STAT_HEALING, 
		STAT_DEFENSE, 
		STAT_BLOCK, 
		STAT_SPELLDMG
	},
	[CLASS_DRUID.."Balance"] = { 
		STAT_RESIST, 
		STAT_STR,
		STAT_AGI,
		STAT_DODGE, 
		STAT_DEFENSE, 
		STAT_HEALING, 
		STAT_BLOCK, 
		STAT_AP
	},
	[CLASS_SHAMAN.."Heal"] = { 
		STAT_RESIST, 
		STAT_CRIT, 
        STAT_STR,
		STAT_AGI,
		STAT_DODGE, 
		STAT_DEFENSE, 
		STAT_BLOCK, 
		STAT_SPELLDMG,
		STAT_AP
	},
	[CLASS_SHAMAN.."DPS"] = { 
		STAT_RESIST, 
		STAT_HEALING, 
		STAT_SPELLDMG, 
		STAT_SPELLCRIT, 
		STAT_DODGE, 
		STAT_DEFENSE, 
		STAT_BLOCK
	},
	[CLASS_SHAMAN.."Elemental"] = { 
		STAT_RESIST, 
		STAT_STR,
		STAT_AGI,
		STAT_HEALING, 
		STAT_HIT, 
		STAT_DEFENSE, 
		STAT_DODGE, 
		STAT_BLOCK, 
		STAT_AP, 
		STAT_CRIT
	},
	[CLASS_PALADIN.."Tank"]	= { 
		STAT_RESIST, 
		STAT_AGI, 
		STAT_AP, 
		STAT_HEALING, 
		STAT_CRIT
	},
	[CLASS_PALADIN.."Heal"]	= { 
		STAT_RESIST, 
		STAT_STR,
		STAT_AGI, 
		STAT_CRIT, 
		STAT_AP, 
		STAT_DODGE, 
		STAT_BLOCK, 
		STAT_DEFENSE, 
		STAT_HIT
	},
	[CLASS_PALADIN.."DPS"] = { 
		STAT_RESIST, 
		STAT_HEALING, 
		STAT_SPELLDMG, 
		STAT_DODGE, 
		STAT_BLOCK, 
		STAT_DEFENSE
	},

	[CLASS_PRIEST.."Heal"] = { 
		STAT_RESIST, 
		STAT_STR,
		STAT_AGI,
		STAT_SPELLDMG, 
		STAT_AP,
        STAT_SPELLHIT,    
		STAT_DEFENSE, 
		STAT_DODGE, 
		STAT_BLOCK
	},
	[CLASS_PRIEST.."DPS"] = { 
		STAT_RESIST,
		STAT_STR, 
		STAT_AGI,
		STAT_HEALING, 
		STAT_AP,
		STAT_DEFENSE, 
		STAT_DODGE, 
		STAT_BLOCK
	}
}

Altoholic.BaseStats = {	-- the order of these stats should match the "-s" in the associated entry of the FormatStats table
	[CLASS_MAGE.."DPS"]		    = { STAT_STA, STAT_INT, STAT_SPI, STAT_SPELLCRIT, STAT_SPELLHIT, STAT_SPELLDMG },
	[CLASS_WARRIOR.."Tank"]	    = { STAT_STA, STAT_STR, STAT_DEFENSE, STAT_DODGE, STAT_HIT },
	[CLASS_WARRIOR.."DPS"]	    = { STAT_STA, STAT_STR, STAT_AGI, STAT_CRIT, STAT_HIT, STAT_AP },
	[CLASS_HUNTER.."DPS"]	    = { STAT_STA, STAT_AGI, STAT_INT, STAT_CRIT, STAT_HIT, STAT_AP },
	[CLASS_ROGUE.."DPS"]		= { STAT_STA, STAT_AGI, STAT_CRIT, STAT_HIT, STAT_AP },
	[CLASS_WARLOCK.."DPS"]	    = { STAT_STA, STAT_INT, STAT_SPELLCRIT, STAT_SPELLHIT, STAT_SPELLDMG },
	[CLASS_DRUID.."Tank"]	    = { STAT_STA, STAT_STR, STAT_AGI, STAT_DEFENSE, STAT_DODGE, STAT_HIT },
	[CLASS_DRUID.."Heal"]	    = { STAT_STA, STAT_INT, STAT_SPI, STAT_SPELLCRIT, STAT_MP5, STAT_HEALING },
	[CLASS_DRUID.."DPS"]		= { STAT_STA, STAT_STR, STAT_AGI, STAT_CRIT, STAT_HIT, STAT_AP },
	[CLASS_DRUID.."Balance"]	= { STAT_STA, STAT_INT, STAT_MP5, STAT_SPELLCRIT, STAT_SPELLHIT, STAT_SPELLDMG },
	[CLASS_SHAMAN.."Heal"]	    = { STAT_STA, STAT_INT, STAT_SPELLCRIT, STAT_MP5, STAT_HEALING },
	[CLASS_SHAMAN.."DPS"]	    = { STAT_STA, STAT_STR, STAT_AGI, STAT_CRIT, STAT_HIT, STAT_AP },
	[CLASS_SHAMAN.."Elemental"]	= { STAT_STA, STAT_INT, STAT_MP5, STAT_SPELLCRIT, STAT_SPELLHIT, STAT_SPELLDMG },
	[CLASS_PALADIN.."Tank"]	    = { STAT_STA, STAT_STR, STAT_DEFENSE, STAT_DODGE, STAT_HIT, STAT_SPELLDMG },
	[CLASS_PALADIN.."Heal"] 	= { STAT_STA, STAT_INT, STAT_SPELLCRIT, STAT_MP5, STAT_HEALING },
	[CLASS_PALADIN.."DPS"]	    = { STAT_STA, STAT_STR, STAT_INT, STAT_CRIT, STAT_HIT, STAT_AP },
	[CLASS_PRIEST.."Heal"]	    = { STAT_STA, STAT_INT, STAT_SPI, STAT_SPELLCRIT, STAT_MP5, STAT_HEALING },
	[CLASS_PRIEST.."DPS"]	    = { STAT_STA, STAT_INT, STAT_SPI, STAT_SPELLCRIT, STAT_SPELLHIT, STAT_SPELLDMG },
}

Altoholic.FormatStats = {
	[CLASS_MAGE.."DPS"]		    = L["Sta:-s |rInt:-s |rSpi:-s\n|rCrit:-s |rHit:-s |rDmg:-s"],
	[CLASS_WARRIOR.."Tank"]	    = L["Sta:-s |rStr:-s |rDef:-s\n|rDodge:-s |rHit:-s"],
	[CLASS_WARRIOR.."DPS"]	    = L["Sta:-s |rStr:-s |rAgi:-s\n|rCrit:-s |rHit:-s |rAP:-s"],
	[CLASS_HUNTER.."DPS"]	    = L["Sta:-s |rAgi:-s |rInt:-s\n|rCrit:-s |rHit:-s |rAP:-s"],
	[CLASS_ROGUE.."DPS"]		= L["Sta:-s |rAgi:-s\n|rCrit:-s |rHit:-s |rAP:-s"],
	[CLASS_WARLOCK.."DPS"]	    = L["Sta:-s |rInt:-s\n|rCrit:-s |rHit:-s |rDmg:-s"],
	[CLASS_DRUID.."Tank"]	    = L["Sta:-s |rStr:-s |rAgi:-s\n|rDef:-s |rDodge:-s |rHit:-s"],
	[CLASS_DRUID.."Heal"]	    = L["Sta:-s |rInt:-s |rSpi:-s\n|rCrit:-s |rMP5:-s |rHeal:-s"],
	[CLASS_DRUID.."DPS"]		= L["Sta:-s |rStr:-s |rAgi:-s\n|rCrit:-s |rHit:-s |rAP:-s"],
	[CLASS_DRUID.."Balance"]	= L["Sta:-s |rInt:-s |rMP5:-s\n|rCrit:-s |rHit:-s |rDmg:-s"],
	[CLASS_SHAMAN.."Heal"]	    = L["Sta:-s |rInt:-s\n|rCrit:-s |rMP5:-s |rHeal:-s"],
	[CLASS_SHAMAN.."DPS"]	    = L["Sta:-s |rStr:-s |rAgi:-s\n|rCrit:-s |rHit:-s |rAP:-s"],
	[CLASS_SHAMAN.."Elemental"]	= L["Sta:-s |rInt:-s |rMP5:-s\n|rCrit:-s |rHit:-s |rDmg:-s"],
	[CLASS_PALADIN.."Tank"]	    = L["Sta:-s |rInt:-s |rDef:-s\n|rDodge:-s |rHit:-s |rDmg:-s"],
	[CLASS_PALADIN.."Heal"]	    = L["Sta:-s |rInt:-s\n|rCrit:-s |rMP5:-s |rHeal:-s"],
	[CLASS_PALADIN.."DPS"]	    = L["Sta:-s |rStr:-s |rInt:-s\n|rCrit:-s |rHit:-s |rAP:-s"],
	[CLASS_PRIEST.."Heal"]	    = L["Sta:-s |rInt:-s |rSpi:-s\n|rCrit:-s |rMP5:-s |rHeal:-s"],
	[CLASS_PRIEST.."DPS"]	    = L["Sta:-s |rInt:-s |rSpi:-s\n|rCrit:-s |rHit:-s |rDmg:-s"],
}

-- the bit of each class (Altoholic.Classes numbering) in an item's allowableClass mask
local ClassMask = {
	[CLASS_MAGE] = 128, [CLASS_WARRIOR] = 1, [CLASS_HUNTER] = 4, [CLASS_ROGUE] = 8, [CLASS_WARLOCK] = 256,
	[CLASS_DRUID] = 1024, [CLASS_SHAMAN] = 64, [CLASS_PALADIN] = 2, [CLASS_PRIEST] = 16,
}

-- The stats of an item (ID or link, a link includes its random suffix) for the upgrade search,
-- nil while the client doesn't have the item.
function Altoholic:GetUpgradeStats(item)
	local itemStats = C_Item.GetItemStats(item)
	if not itemStats then return nil end
	local stats = {}
	for k, v in pairs(itemStats) do
		stats[k] = v
	end
	local resist = 0
	for i = 1, 6 do
		resist = resist + (stats["RESISTANCE" .. i .. "_NAME"] or 0)
	end
	stats[STAT_RESIST] = resist
	-- ranged-only attack power (bows, scopes) is reported apart from the general one
	stats[STAT_AP] = (stats[STAT_AP] or 0) + (stats[STAT_RANGED_AP] or 0)
	return stats
end

-- true when an item with these stats is of no use to the class and role ("7Heal")
function Altoholic:IsUpgradeExcluded(classRole, itemID, stats)
	local data = C_Item.GetItemDataByID(itemID)
	local mask = data and data.allowableClass
	local class = ClassMask[tonumber(string.sub(classRole, 1, 1))]
	if mask and mask > 0 and class and bit.band(mask, class) == 0 then
		return true		-- for other classes only
	end
	for _, stat in ipairs(self.ExcludeStats[classRole]) do
		local value = stats[stat] or 0
		if stat == STAT_HEALING then
			-- "damage and healing" carries a healing bonus as well, only pure healing gear counts
			value = value - (stats[STAT_SPELLDMG] or 0)
		end
		if value > 0 then
			return true
		end
	end
	return false
end

-- The class and role's stat line with its "-s" filled in; with the stats of the equipped item
-- as 'reference', each value is coloured by how it compares.
function Altoholic:FormatUpgradeStats(classRole, stats, reference)
	local statLine = self.FormatStats[classRole]
	for _, stat in ipairs(self.BaseStats[classRole]) do
		local value = stats[stat] or 0
		local color = "|cFFFFFFFF"
		if reference then
			local current = reference[stat] or 0
			if value > current then
				color = "|cFF00FF00"
			elseif value < current then
				color = "|cFFFF0000"
			end
		end
		statLine = string.gsub(statLine, "-s", color .. value, 1)
	end
	return statLine
end

-- Add herb/ore possession info to Plants/Mines, thanks to Tempus on wowace for gathering this.
Altoholic.Gathering = {

	[L["Adamantite Deposit"]]              = 23425, -- Adamantite Ore
	[L["Copper Vein"]]                     =  2770, -- Copper Ore
	[L["Dark Iron Deposit"]]               = 11370, -- Dark Iron Ore
	[L["Fel Iron Deposit"]]                = 23424, -- Fel Iron Ore
	[L["Gold Vein"]]                       =  2776, -- Gold Ore
	[L["Hakkari Thorium Vein"]]            = 10620, -- Thorium Ore
	[L["Iron Deposit"]]                    =  2772, -- Iron Ore
	[L["Khorium Vein"]]                    = 23426, -- Khorium Ore
	[L["Mithril Deposit"]]                 =  3858, -- Mithril Ore
	[L["Ooze Covered Gold Vein"]]          =  2776, -- Gold Ore
	[L["Ooze Covered Mithril Deposit"]]    =  3858, -- Mithril Ore
	[L["Ooze Covered Rich Thorium Vein"]]  = 10620, -- Thorium Ore
	[L["Ooze Covered Silver Vein"]]        =  2775, -- Silver Ore
	[L["Ooze Covered Thorium Vein"]]       = 10620, -- Thorium Ore
	[L["Ooze Covered Truesilver Deposit"]] =  7911, -- Truesilver Ore
	[L["Rich Adamantite Deposit"]]         = 23425, -- Adamantite Ore
	[L["Rich Thorium Vein"]]               = 10620, -- Thorium Ore
	[L["Silver Vein"]]                     =  2775, -- Silver Ore
	[L["Small Thorium Vein"]]              = 10620, -- Thorium Ore
	[L["Tin Vein"]]                        =  2771, -- Tin Ore
	[L["Truesilver Deposit"]]              =  7911, -- Truesilver Ore

	[L["Lesser Bloodstone Deposit"]]       =  4278, -- Lesser Bloodstone Ore
	[L["Incendicite Mineral Vein"]]        =  3340, -- Incendicite Ore
	[L["Indurium Mineral Vein"]]           =  5833, -- Indurium Ore
	[L["Nethercite Deposit"]]              = 32464, -- Nethercite Ore
	-- [L["Large Obsidian Chunk"]] = ??,
	-- [L["Small Obsidian Chunk"]] = ??,

	[L["Ancient Lichen"]]       = 22790,
	[L["Arthas' Tears"]]        =  8836,
	[L["Black Lotus"]]          = 13768,
	[L["Blindweed"]]            =  8839,
	[L["Bloodthistle"]]         = 22710,
	[L["Briarthorn"]]           =  2450,
	[L["Bruiseweed"]]           =  2453,
	[L["Dreamfoil"]]            = 13463,
	[L["Dreaming Glory"]]       = 22786,
	[L["Earthroot"]]            =  2449,
	[L["Fadeleaf"]]             =  3818,
	[L["Felweed"]]              = 22785,
	[L["Firebloom"]]            =  4625,
	[L["Flame Cap"]]            = 22788,
	[L["Ghost Mushroom"]]       =  8845,
	[L["Golden Sansam"]]        = 13464,
	[L["Goldthorn"]]            =  3821,
	[L["Grave Moss"]]           =  3369,
	[L["Gromsblood"]]           =  8846,
	[L["Icecap"]]               = 13469,
	[L["Khadgar's Whisker"]]    =  3358,
	[L["Kingsblood"]]           =  3356,
	[L["Liferoot"]]             =  3357,
	[L["Mageroyal"]]            =   785,
	[L["Mana Thistle"]]         = 22793,
	[L["Mountain Silversage"]]  = 13465,
	[L["Netherbloom"]]          = 22791,
	[L["Nightmare Vine"]]       = 22792,
	[L["Peacebloom"]]           =  2447,
	[L["Plaguebloom"]]          = 13466,
	[L["Purple Lotus"]]         =  8831,
	[L["Ragveil"]]              = 22787,
	[L["Silverleaf"]]           =   765,
	[L["Stranglekelp"]]         =  3820,
	[L["Sungrass"]]             =  8838,
	[L["Terocone"]]             = 22789,
	[L["Wild Steelbloom"]]      =  3355,
	[L["Wintersbite"]]          =  3819,

	[L["Glowcap"]]              = 24245,
	[L["Netherdust Bush"]]      = 32468, -- Netherdust Pollen
	[L["Sanguine Hibiscus"]]    = 24246,
}

function Altoholic:CmdSearchBags(text)
	if not (AltoholicFrame:IsVisible()) then
		AltoholicFrame:Show();
	end
	AltoholicFrame_SearchEditBox:SetText(strlower(text))
	Altoholic:SearchItem();
end

Altoholic_UIDropDownMenu_CreateInfo = Altoholic_UIDropDownMenu_CreateInfo or loadstring("local t = {} return function() for k in pairs(t) do t[k] = nil t[k] = {} end return t end")()
