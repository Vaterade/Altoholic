-- Where an item comes from, read from pfQuest's database when pfQuest is loaded: the
-- vendors that sell it, the mobs that drop it, the objects (chests, ...) that hold it, each
-- with its zone. pfQuest-octo-plus fills that database with OctoWoW's data. Without pfQuest
-- nothing here finds anything, and the callers fall back to what Items/Recipes.lua says.

-- pfDB's tables, or nil while pfQuest isn't loaded
local function DB(kind)
	local t = pfDB and pfDB[kind]
	return t and t.data, t and t.loc
end

function Altoholic:HasItemSources()
	return (DB("items")) ~= nil
end

-- the zones a unit or object is found in, by name, at most two
local function Zones(data)
	local _, zoneNames = DB("zones")
	local seen, names = {}, {}
	for _, coord in pairs(data and data.coords or {}) do
		local zone = coord[3]
		if zone and zone > 0 and not seen[zone] then
			seen[zone] = true
			local name = zoneNames and zoneNames[zone]
			if not name and C_Map and C_Map.GetAreaInfo then name = C_Map.GetAreaInfo(zone) end
			if name then table.insert(names, name) end
		end
	end
	table.sort(names)
	if #names > 2 then return names[1] .. ", " .. names[2] .. ", ..." end
	return table.concat(names, ", ")
end

-- { vendors = { { name, zone, count } }, drops = { { name, zone, chance } },
--   objects = { { name, zone, chance } } }, or nil when pfQuest has nothing on the item.
-- Drops and objects come highest chance first; reference loot (pfQuest's shared loot
-- tables) counts as a drop from each of its mobs and objects.
function Altoholic:ItemSources(itemID)
	local items = DB("items")
	local item = items and items[itemID]
	if not item then return nil end
	local units, unitNames = DB("units")
	local objects, objectNames = DB("objects")
	local refloot = DB("refloot")
	local out = { vendors = {}, drops = {}, objects = {} }

	local function Unit(list, id, value)
		local name = unitNames and unitNames[id]
		if name then table.insert(list, { name = name, zone = Zones(units and units[id]), value = value }) end
	end
	local function Object(id, chance)
		local name = objectNames and objectNames[id]
		if name then table.insert(out.objects, { name = name, zone = Zones(objects and objects[id]), value = chance }) end
	end

	for id, count in pairs(item.V or {}) do Unit(out.vendors, id, count) end
	for id, chance in pairs(item.U or {}) do Unit(out.drops, id, chance) end
	for id, chance in pairs(item.O or {}) do Object(id, chance) end
	for ref, chance in pairs(item.R or {}) do
		local r = refloot and refloot[ref]
		for id in pairs(r and r.U or {}) do Unit(out.drops, id, chance) end
		for id in pairs(r and r.O or {}) do Object(id, chance) end
	end

	local function ByChance(a, b)
		if (a.value or 0) ~= (b.value or 0) then return (a.value or 0) > (b.value or 0) end
		return a.name < b.name
	end
	table.sort(out.vendors, function(a, b) return a.name < b.name end)
	table.sort(out.drops, ByChance)
	table.sort(out.objects, ByChance)
	if #out.vendors + #out.drops + #out.objects == 0 then return nil end
	return out
end

-- Adds the sources to a tooltip, at most `max` lines of them (8 by default).
function Altoholic:AddItemSources(tooltip, itemID, max)
	local s = self:ItemSources(itemID)
	if not s then return false end
	local L = self.L
	max = max or 8
	local shown, total = 0, #s.vendors + #s.drops + #s.objects
	local function Line(left, right)
		if shown >= max then return end
		tooltip:AddDoubleLine(left, right, 1, 1, 1, .7, .7, .7)
		shown = shown + 1
	end
	for _, v in ipairs(s.vendors) do Line("|cff33ffcc" .. L["Sold by"] .. "|r " .. v.name, v.zone) end
	for _, d in ipairs(s.drops) do
		local chance = d.value and d.value > 0 and format(" (%.1f%%)", d.value) or ""
		Line("|cffffd200" .. L["Dropped by"] .. "|r " .. d.name .. chance, d.zone)
	end
	for _, o in ipairs(s.objects) do
		local chance = o.value and o.value > 0 and format(" (%.1f%%)", o.value) or ""
		Line("|cffffd200" .. L["Found in"] .. "|r " .. o.name .. chance, o.zone)
	end
	if total > shown then
		tooltip:AddLine(format(L["and %d more"], total - shown), .6, .6, .6)
	end
	return true
end

-- Puts the item's vendors, drops and objects on pfQuest's world map, as pfQuest's own
-- database browser does, replacing what that browser last showed. Returns false without
-- pfQuest or when it knows no place for the item.
function Altoholic:ShowItemOnMap(itemID)
	if not (pfDatabase and pfDatabase.SearchItemID and pfMap and pfMap.ShowMapID) then return false end
	if pfMap.DeleteNode then pfMap:DeleteNode("PFDB") end
	local maps = pfDatabase:SearchItemID(itemID, { ["addon"] = "PFDB" })
	local best = maps and pfDatabase:GetBestMap(maps)
	if not best then return false end
	pfMap.queue_update = GetTime()
	pfMap:ShowMapID(best)
	return true
end
