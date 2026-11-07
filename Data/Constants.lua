-- Constant tables shared by the scanners and the window.
local L = Altoholic.L
local WHITE		= "|cFFFFFFFF"
local ORANGE	= "|cFFFF7F00"

Altoholic.InvSlots = {
	["INVTYPE_HEAD"] = 1,
	["INVTYPE_SHOULDER"] = 2,
	["INVTYPE_CHEST"] = 3,
	["INVTYPE_ROBE"] = 3,
	["INVTYPE_WRIST"] = 4,
	["INVTYPE_HAND"] = 5,
	["INVTYPE_WAIST"] = 6,
	["INVTYPE_LEGS"] = 7,
	["INVTYPE_FEET"] = 8,
	["INVTYPE_NECK"] = 9,
	["INVTYPE_CLOAK"] = 10,
	["INVTYPE_FINGER"] = 11,
	["INVTYPE_TRINKET"] = 12,
	["INVTYPE_WEAPON"] = 13,
	["INVTYPE_2HWEAPON"] = 14,
	["INVTYPE_WEAPONMAINHAND"] = 15,
	["INVTYPE_WEAPONOFFHAND"] = 16,
	["INVTYPE_HOLDABLE"] = 16,
	["INVTYPE_SHIELD"] = 17,
	["INVTYPE_RANGED"] = 18,
	["INVTYPE_THROWN"] = 18,
	["INVTYPE_RANGEDRIGHT"] = 18,
	["INVTYPE_RELIC"] = 18
}

Altoholic.EquipmentSlots = {
	[1] = INVTYPE_HEAD,
	[2] = INVTYPE_SHOULDER,
	[3] = INVTYPE_CHEST,		-- also "INVTYPE_ROBE"
	[4] = INVTYPE_WRIST,
	[5] = INVTYPE_HAND,
	[6] = INVTYPE_WAIST,
	[7] = INVTYPE_LEGS,
	[8] = INVTYPE_FEET,
	[9] = INVTYPE_NECK,
	[10] = INVTYPE_CLOAK,
	[11] = INVTYPE_FINGER,
	[12] = INVTYPE_TRINKET,
	[13] = INVTYPE_WEAPON,
	[14] = INVTYPE_2HWEAPON,
	[15] = INVTYPE_WEAPONMAINHAND,
	[16] = INVTYPE_WEAPONOFFHAND,	-- also "INVTYPE_HOLDABLE"
	-- [17] "INVTYPE_SHIELD" is set by BuildSearchSubMenu
	[18] = L["Ranged"]		-- "INVTYPE_RANGED",  "INVTYPE_THROWN", "INVTYPE_RANGEDRIGHT", "INVTYPE_RELIC"
}

-- ** texture coordinates found in a scrub.lua somewhere on the web
Altoholic.classicon = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes";

Altoholic.ClassInfo = {
	[1] = { color = "|cFF69CCF0", texcoord = {0.25, 0.49609375, 0, 0.25} },
	[2] = { color = "|cFFC79C6E", texcoord = {0, 0.25, 0, 0.25} },
	[3] = { color = "|cFFABD473", texcoord = {0, 0.25, 0.25, 0.5} },
	[4] = { color = "|cFFFFF569", texcoord = {0.49609375, 0.7421875, 0, 0.25} },
	[5] = { color = "|cFF9482CA", texcoord = {0.7421875, 0.98828125, 0.25, 0.5} },
	[6] = { color = "|cFFFF7D0A", texcoord = {0.7421875, 0.98828125, 0, 0.25} },
	[7] = { color = "|cFF2459FF", texcoord = {0.25, 0.49609375, 0.25, 0.5} },
	[8] = { color = "|cFFF58CBA", texcoord = {0, 0.25, 0.5, 0.75} },
	[9] = { color = WHITE, texcoord = {0.49609375, 0.7421875, 0.25, 0.5} }
}

Altoholic.Classes = {
	[L["Mage"]]		= 1,
	[L["Warrior"]]	= 2,
	[L["Hunter"]]	= 3,
	[L["Rogue"]]	= 4,
	[L["Warlock"]]	= 5,
	[L["Druid"]]	= 6,
	[L["Shaman"]]	= 7,
	[L["Paladin"]]	= 8,
	[L["Priest"]]	= 9,
	-- frFR female class names
	["Guerrière"] = 2,			-- Warrior
	["Chasseresse"] = 3,			-- Hunter
	["Voleuse"] = 4,				-- Rogue
	["Druidesse"] = 6,			-- Druid
	["Chamane"] = 7,				-- Shaman
	["Prêtresse"] = 9,			-- Priest
	-- deDE female class names
	["Magierin"] = 1,				-- Mage
	["Kriegerin"] = 2,			-- Warrior
	["J\195\164gerin"] = 3,		-- Hunter
	["Schurkin"] = 4,				-- Rogue
	["Hexenmeisterin"] = 5,		-- Warlock
	["Druidin"] = 6,				-- Druid
	["Schamanin"] = 7,			-- Shaman
	["Priesterin"] = 9			-- Priest
}

Altoholic.Books = {
	[L["Mage"]]		= "Tome",
	[L["Warrior"]]	= "Manual",
	[L["Hunter"]]	= "Guide",
	[L["Rogue"]]	= "Handbook",
	[L["Warlock"]]	= "Grimoire",
	[L["Druid"]]	= "Book",
	[L["Shaman"]]	= "Tablet",
	[L["Paladin"]]	= "Libram",
	[L["Priest"]]	= "Codex",
}

Altoholic.equipment = {
	{ color = "|cFF69CCF0", name = HEADSLOT, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Head"},
	{ color = "|cFFABD473", name = NECKSLOT, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Neck"},
	{ color = "|cFF69CCF0", name = SHOULDERSLOT, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shoulder"},
	{ color = WHITE, name = SHIRTSLOT, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shirt"},
	{ color = "|cFF69CCF0", name = CHESTSLOT, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest"},
	{ color = "|cFF69CCF0", name = WAISTSLOT, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Waist"},
	{ color = "|cFF69CCF0", name = LEGSSLOT, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Legs"},
	{ color = "|cFF69CCF0", name = FEETSLOT, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Feet"},
	{ color = "|cFF69CCF0", name = WRISTSLOT, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Wrists"},
	{ color = "|cFF69CCF0", name = HANDSSLOT, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Hands"},
	{ color = ORANGE, name = FINGER0SLOT .. " 1", icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger"},
	{ color = ORANGE, name = FINGER1SLOT .. " 2", icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger"},
	{ color = ORANGE, name = TRINKET0SLOT .. " 1", icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket"},
	{ color = ORANGE, name = TRINKET1SLOT .. " 2", icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket"},
	{ color = "|cFFABD473", name = BACKSLOT, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest"},
	{ color = "|cFFFFFF00", name = MAINHANDSLOT, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand"},
	{ color = "|cFFFFFF00", name = SECONDARYHANDSLOT, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-SecondaryHand"},
	{ color = "|cFFABD473", name = L["Ranged"], icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Ranged"},
	{ color = WHITE, name = TABARDSLOT, icon = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Tabard"}
}
