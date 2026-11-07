-- Item search over the saved data or the loot tables, and the equipment upgrade finder.
-- Nothing here reads the window: the filters come in as a table and the results go out
-- as a list.
--
--   Altoholic:Search({
--     text = "linen",            -- part of the name, any case; "" matches everything
--     classID, subClassID,       -- Enum.ItemClass and its subclass, either may be nil
--     scope = "realm" | "all" | "loots",
--     rarity = 0..6,             -- lowest quality
--     slot = 0..18,              -- Altoholic.EquipmentSlots index, 0 for any
--     minLevel, maxLevel,        -- required level; items without one only with noMinLevel
--     noMinLevel = true,
--     mail = true,               -- also the mailboxes
--     recipes = true,            -- also the crafts the characters know
--   })
-- Each result: { id, count, char, location, realm, iLvl, craftName, craftLink }; char,
-- location and realm are coloured text ready to show. A known recipe also has name,
-- realmName, profession and recipe: the character, and the saved recipe.

local L = Altoholic.L
local V = Altoholic.vars
local WHITE = "|cFFFFFFFF"
local GREEN = "|cFF00FF00"
local LEVEL_CAP = 60

-- the level loot is compared by: its required level plus 5, as the old code did
local function LootLevel(minLevel)
	if minLevel == 0 or minLevel == nil then minLevel = 57 end
	return minLevel + 5
end

local function MatchesClass(f, itemID)
	if f.classID == nil and f.subClassID == nil then return true end
	local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
	if f.classID ~= nil and f.classID ~= classID then return false end
	if f.subClassID ~= nil and f.subClassID ~= subClassID then return false end
	return true
end

-- the checks every item goes through; returns its GetItemInfo values when it passes
local function Matches(f, itemID)
	local name, _, rarity, minLevel, _, _, _, equipLoc = GetItemInfo(itemID)
	if not name or not rarity then return end		-- not in the client's cache
	if not MatchesClass(f, itemID) then return end
	if rarity < (f.rarity or 0) then return end
	if minLevel == 0 then
		if not f.noMinLevel then return end
	elseif minLevel < (f.minLevel or 0) or minLevel > (f.maxLevel or LEVEL_CAP) then
		return
	end
	if (f.slot or 0) ~= 0 and Altoholic.InvSlots[equipLoc] ~= f.slot then return end
	if not string.find(strlower(name), f.value, 1, true) then return end
	return name, rarity, minLevel, equipLoc
end

local function BagLocation(bagName)
	if bagName == "Bag100" then return L["Bank"] end
	if bagName == "Bag-2" then return KEYRING end
	local n = tonumber(string.sub(bagName, 4))
	if n and n >= 0 and n <= 4 then return L["Bags"] end
	return L["Bank"]
end

local function SearchRealm(f, results, faction, realm)
	local chars = rawget(Altoholic.db.account.data[faction][realm], "char") or {}
	local realmText = Altoholic:GetRealmString(faction, realm)
	for name, c in pairs(chars) do
		if type(c) == "table" and c.class and c.class ~= "" then
			local who = Altoholic:GetClassColor(c.class) .. name
			local function Add(id, count, location)
				if id and Matches(f, id) then
					table.insert(results, { id = id, count = count, char = who, location = location, realm = realmText })
				end
			end
			for bagName, b in pairs(rawget(c, "bag") or {}) do
				local ids, counts = rawget(b, "ids") or {}, rawget(b, "counts") or {}
				local location = BagLocation(bagName)
				for slot = 1, b.size or 0 do
					Add(ids[slot], counts[slot], location)
				end
			end
			for slot = 1, 19 do
				local item = (rawget(c, "inventory") or {})[slot]	-- an ID, or a link when enchanted
				if item then
					Add(type(item) == "number" and item or Altoholic:GetIDFromLink(item), 1, L["Equipped"])
				end
			end
			if f.mail then
				for _, m in ipairs(rawget(c, "mail") or {}) do
					if m.link then Add(Altoholic:GetIDFromLink(m.link), m.count, L["Mail"]) end
				end
			end
			if f.recipes and f.classID == nil then
				for profession, p in pairs(rawget(c, "recipes") or {}) do
					if type(p) == "table" and p.ScanFailed == false then
						for _, craft in pairs(rawget(p, "list") or {}) do
							local craftName = craft.link and Altoholic:GetCraftFromRecipe(craft.link)
							if craftName and string.find(strlower(craftName), f.value, 1, true) then
								table.insert(results, { id = craft.id, char = who, craftName = craftName,
									craftLink = craft.link, location = profession, realm = realmText,
									-- who knows it, for queueing it on them
									name = name, realmName = realm, profession = profession, recipe = craft })
							end
						end
					end
				end
			end
		end
	end
end

local function SortLoots(results)
	local descending = Altoholic:Option("SortDescending")
	table.sort(results, function(a, b)
		if descending then return a.iLvl > b.iLvl end
		return a.iLvl < b.iLvl
	end)
end

-- calls fn(instance, boss, itemID) for every item in the loot tables
local function EachLoot(fn)
	for instance, bosses in pairs(Altoholic.LootTable) do
		for boss, loots in pairs(bosses) do
			for _, itemID in pairs(loots) do
				fn(instance, boss, itemID)
			end
		end
	end
end

function Altoholic:Search(f)
	f.value = strlower(f.text or "")
	local results = {}
	if f.scope == "loots" then
		local total, unknown = 0, 0
		EachLoot(function(instance, boss, itemID)
			total = total + 1
			if not GetItemInfo(itemID) then
				unknown = unknown + 1
				return
			end
			local _, _, minLevel = Matches(f, itemID)
			if minLevel then
				table.insert(results, { id = itemID, iLvl = LootLevel(minLevel),
					char = GREEN .. boss, location = WHITE .. instance })
			end
		end)
		local O = self.db.account.options
		O.TotalLoots, O.UnknownLoots = total, unknown
		SortLoots(results)
	elseif f.scope == "all" then
		for faction, realms in pairs(self.db.account.data) do
			for realm in pairs(realms) do
				SearchRealm(f, results, faction, realm)
			end
		end
	else
		-- this realm, both factions: they can mail each other here
		for faction, realms in pairs(self.db.account.data) do
			if rawget(realms, V.realm) then
				SearchRealm(f, results, faction, V.realm)
			end
		end
	end
	return results
end

-- The loot that would replace an equipped item: same slot, same class and subclass, higher
-- level. role (e.g. "2Tank", from Altoholic.UpgradeRoles) also compares the stats that
-- matter to it and lists the equipped item first; without it, only the level counts.
function Altoholic:FindUpgrade(item, role)
	local itemID = type(item) == "number" and item or self:GetIDFromLink(item)
	local _, _, _, minLevel, _, _, _, equipLoc = GetItemInfo(itemID)
	local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
	local level = LootLevel(minLevel)
	local slot = self.InvSlots[equipLoc]
	local results = {}
	local reference
	if role then
		reference = self:GetUpgradeStats(item) or {}
		table.insert(results, { id = itemID, iLvl = level, char = self:FormatUpgradeStats(role, reference),
			location = L["Currently equipped"] })
	end
	local f = { classID = classID, subClassID = subClassID }
	EachLoot(function(instance, boss, lootID)
		local name, _, rarity, lootMin, _, _, _, lootLoc = GetItemInfo(lootID)
		if not name or not rarity then return end
		local lootLevel = LootLevel(lootMin)
		if lootLevel <= level or not MatchesClass(f, lootID) or self.InvSlots[lootLoc] ~= slot then return end
		if role then
			local stats = self:GetUpgradeStats(lootID)
			if not stats or self:IsUpgradeExcluded(role, lootID, stats) then return end
			table.insert(results, { id = lootID, iLvl = lootLevel, char = self:FormatUpgradeStats(role, stats, reference),
				location = WHITE .. instance .. ", " .. GREEN .. boss })
		else
			table.insert(results, { id = lootID, iLvl = lootLevel, char = GREEN .. boss, location = WHITE .. instance })
		end
	end)
	-- the equipped item stays on top
	local first = role and table.remove(results, 1)
	SortLoots(results)
	if first then table.insert(results, 1, first) end
	return results
end

-- The kinds of upgrade a class can look for, as { label, role } (role nil: by level only).
-- Class numbers are Altoholic.Classes'.
local CLASS_WARRIOR, CLASS_DRUID, CLASS_SHAMAN, CLASS_PALADIN, CLASS_PRIEST = 2, 6, 7, 8, 9
function Altoholic:UpgradeRoles(class)
	local id = self.Classes[class]
	local roles = { { L["Find Upgrade"] .. " " .. GREEN .. L["(based on iLvl)"] } }
	if not id then return roles end
	local function Add(label, suffix)
		table.insert(roles, { L["Find Upgrade"] .. " " .. GREEN .. "(" .. label .. ")", id .. suffix })
	end
	if id == CLASS_WARRIOR or id == CLASS_DRUID or id == CLASS_PALADIN then Add(L["Tank"], "Tank") end
	Add(L["DPS"], "DPS")
	if id == CLASS_DRUID then Add(L["Balance"], "Balance") end
	if id == CLASS_SHAMAN then Add(L["Elemental Shaman"], "Elemental") end
	if id == CLASS_PRIEST or id == CLASS_SHAMAN or id == CLASS_DRUID or id == CLASS_PALADIN then Add(L["Heal"], "Heal") end
	return roles
end

-- *** Can a character use an item ***
-- Worked out from the character's class and level, since the game's own check only answers
-- for the character being played: the item's class restriction (ClassicAPI's allowableClass,
-- which covers tier sets), its required level, and the armour and weapon types the class can
-- learn. Classes by Altoholic.Classes' numbers.

-- the game's class bit for each of Altoholic's class numbers
local CLASS_BIT = { [1] = 128, [2] = 1, [3] = 4, [4] = 8, [5] = 256, [6] = 1024, [7] = 64, [8] = 2, [9] = 16 }

-- armour subclasses: 0 misc, 1 cloth, 2 leather, 3 mail, 4 plate, 6 shield, 7 libram, 8 idol,
-- 9 totem; a number is the level the class can first wear it at
local ARMOR = {
	[1] = { [0] = 1, [1] = 1 },											-- Mage
	[2] = { [0] = 1, [1] = 1, [2] = 1, [3] = 1, [4] = 40, [6] = 1 },	-- Warrior
	[3] = { [0] = 1, [1] = 1, [2] = 1, [3] = 40 },						-- Hunter
	[4] = { [0] = 1, [1] = 1, [2] = 1 },								-- Rogue
	[5] = { [0] = 1, [1] = 1 },											-- Warlock
	[6] = { [0] = 1, [1] = 1, [2] = 1, [8] = 1 },						-- Druid
	[7] = { [0] = 1, [1] = 1, [2] = 1, [3] = 40, [6] = 1, [9] = 1 },	-- Shaman
	[8] = { [0] = 1, [1] = 1, [2] = 1, [3] = 1, [4] = 40, [6] = 1, [7] = 1 },	-- Paladin
	[9] = { [0] = 1, [1] = 1 },											-- Priest
}

-- weapon subclasses: 0 1H axe, 1 2H axe, 2 bow, 3 gun, 4 1H mace, 5 2H mace, 6 polearm,
-- 7 1H sword, 8 2H sword, 10 staff, 13 fist, 14 misc, 15 dagger, 16 thrown, 18 crossbow,
-- 19 wand, 20 fishing pole
local function Set(...)
	local t = { [14] = true, [20] = true }
	for _, v in ipairs({ ... }) do t[v] = true end
	return t
end
local WEAPON = {
	[1] = Set(7, 10, 15, 19),											-- Mage
	[2] = Set(0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 15, 16, 18),			-- Warrior
	[3] = Set(0, 1, 2, 3, 6, 7, 8, 10, 13, 15, 16, 18),				-- Hunter
	[4] = Set(2, 3, 4, 7, 13, 15, 16, 18),								-- Rogue
	[5] = Set(7, 10, 15, 19),											-- Warlock
	[6] = Set(4, 5, 10, 13, 15),										-- Druid
	[7] = Set(0, 1, 4, 5, 10, 13, 15),									-- Shaman
	[8] = Set(0, 1, 4, 5, 6, 7, 8),										-- Paladin
	[9] = Set(4, 10, 15, 19),											-- Priest
}

-- true when the character (a saved record, with class and level) can use the item; true too
-- when the item isn't cached yet, rather than hiding it
function Altoholic:CanUseItem(c, itemID)
	local class = self.Classes[c.class]
	if not class then return true end
	local level = c.level or 60
	local data = C_Item and C_Item.GetItemDataByID and C_Item.GetItemDataByID(itemID)
	if data then
		if data.allowableClass and data.allowableClass ~= -1 and bit.band(data.allowableClass, CLASS_BIT[class]) == 0 then
			return false
		end
		if (data.requiredLevel or 0) > level then return false end
	else
		local _, _, _, minLevel = GetItemInfo(itemID)
		if minLevel and minLevel > level then return false end
	end
	local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
	if classID == Enum.ItemClass.Armor then
		local from = ARMOR[class][subClassID]
		return from ~= nil and level >= from
	elseif classID == Enum.ItemClass.Weapon then
		return WEAPON[class][subClassID] == true
	end
	return true
end
