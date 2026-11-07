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
-- location and realm are coloured text ready to show.

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
									craftLink = craft.link, location = profession, realm = realmText })
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
