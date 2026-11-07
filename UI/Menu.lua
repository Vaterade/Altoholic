-- The first column: the categories and what each lists in the second.
local L = Altoholic.L
local UI = Altoholic.UI

local function Add(cat) table.insert(UI.categories, cat) end

-- the account-wide pages
Add({ id = "summary", title = L["Account Summary"], entries = function()
	return {
		{ text = L["Characters"], key = "characters", view = "Summary" },
		{ text = L["Bag Usage"], key = "bags", view = "BagUsage" },
		{ text = SKILLS, key = "skills", view = "Skills" },
		{ text = L["Reputations"], key = "reputations", view = "Reputations" },
		{ text = L["Raids"], key = "raids", view = "Raids" },
		{ text = L["Attunements"], key = "attunements", view = "Attunements" },
	}
end })

Add({ id = "containers", title = L["Containers"], entries = function()
	return UI.CharacterEntries("Containers")
end })

-- equipment compares a realm's characters side by side, so it lists realms
Add({ id = "equipment", title = L["Equipment"], entries = function()
	local list = {}
	for _, realm in ipairs(UI.Realms()) do
		table.insert(list, { text = realm.name, key = realm.name, view = "Equipment", args = realm.name })
	end
	return list
end, default = function(list)
	for _, e in ipairs(list) do
		if e.args == Altoholic.vars.realm then return e end
	end
end })

Add({ id = "mail", title = L["E-Mail"], entries = function()
	return UI.CharacterEntries("Mail")
end })

Add({ id = "quests", title = L["Quests"], entries = function()
	return UI.CharacterEntries("Quests")
end })

-- a character's professions, in the order the client gave them
local function Professions(ref, c)
	local list = {}
	for name, p in pairs(rawget(c, "recipes") or {}) do
		if type(p) == "table" then
			table.insert(list, { text = name, key = ref.realm .. "/" .. ref.name .. "/" .. name, view = "Recipes",
				args = { faction = ref.faction, realm = ref.realm, name = ref.name, profession = name } })
		end
	end
	table.sort(list, function(a, b) return a.text < b.text end)
	return list
end

Add({ id = "recipes", title = L["Recipes"], empty = L["No profession has been opened yet."], entries = function()
	return UI.CharacterEntries(nil, function(c) return next(rawget(c, "recipes") or {}) ~= nil end, Professions)
end, default = function(list)
	-- the logged-in character's first profession
	for _, e in ipairs(list) do
		if e.args and UI.IsPlayer(e.args) and e.children and e.children[1] then return e.children[1] end
	end
	for _, e in ipairs(list) do
		if e.children and e.children[1] then return e.children[1] end
	end
end })

Add({ id = "auctions", title = AUCTIONS, entries = function()
	return UI.CharacterEntries("Auctions")
end })

Add({ id = "bids", title = BIDS, entries = function()
	return UI.CharacterEntries("Bids")
end })

Add({ id = "search", title = L["Search"], entries = function() return UI.SearchEntries() end })

Add({ id = "options", title = L["Options"], view = "Options" })
