-- The recipes a character doesn't know yet, from Items/Recipes.lua (Altoholic.RecipeDB,
-- converted from LibCrafts-1.0). Known recipes are matched by name in the client's language,
-- as the character's profession window gave them; Locale/Recipes.lua has the translations.
local L = Altoholic.L

-- what the source letters of Items/Recipes.lua mean
local LEARNED = { a = L["Learned automatically"], q = L["Quest"], t = L["Trainer"], o = L["World object"] }
local RECIPE = { c = L["Chest"], e = L["Made by an engineer"], d = L["Drop"], f = L["Fishing"],
	g = L["Gift"], p = L["Pickpocketing"], q = L["Quest"], v = L["Vendor"] }

local function Describe(letters, map)
	local parts = {}
	for letter in string.gmatch(letters or "", ".") do
		if map[letter] then table.insert(parts, map[letter]) end
	end
	return table.concat(parts, ", ")
end

-- A recipe name as compared: the client writes some apostrophes curly (Turtle's own
-- recipes, "Herbalist’s"), the recipe list straight.
function Altoholic:RecipeKey(name)
	return (string.gsub(name or "", "\226\128\153", "'"))
end

-- the English name RecipeDB uses for a profession as the client named it
function Altoholic:EnglishProfession(profession)
	for en in pairs(self.RecipeDB or {}) do
		if en == profession or L[en] == profession or rawget(self.Professions, en) == profession then
			return en
		end
	end
end

-- the character's rank in a profession, 0 when it isn't saved
function Altoholic:ProfessionRank(c, profession)
	for _, category in pairs(rawget(c, "skill") or {}) do
		local s = type(category) == "table" and rawget(category, profession)
		if s then return (self:GetSkillInfo(s)) end
	end
	return 0
end

-- The crafts of a profession a character hasn't learned, by skill level:
--   { { spell, name, skill, how, item, reagents, recipes = { { id, sources } }, level }, ... }
-- name is in the client's language, how says where it is learned. Also returns how many
-- crafts the profession has, and nil when Altoholic has no list for it.
function Altoholic:MissingRecipes(c, profession)
	local en = self:EnglishProfession(profession)
	if not en then return nil end
	local p = rawget(rawget(c, "recipes") or {}, profession)
	local list = p and rawget(p, "list")
	local known = {}
	local i = 1
	while list and rawget(list, i) do
		local r = rawget(list, i)
		if r.name and not self:IsRecipeHeader(r) then known[self:RecipeKey(r.name)] = true end
		i = i + 1
	end
	local missing, all = {}, self.RecipeDB[en]
	for _, craft in ipairs(all) do
		local name = L[craft[2]]
		if not known[self:RecipeKey(name)] and not known[self:RecipeKey(craft[2])] then
			local recipes, how = {}, {}
			for _, r in ipairs(craft[7] or {}) do
				table.insert(recipes, { id = r[1], sources = Describe(r[2], RECIPE) })
				table.insert(how, Describe(r[2], RECIPE))
			end
			local learned = Describe(craft[4], LEARNED)
			if learned ~= "" then table.insert(how, 1, learned) end
			table.insert(missing, {
				spell = craft[1], name = name, skill = craft[3], how = table.concat(how, "; "),
				item = craft[5], reagents = craft[6], recipes = recipes, level = craft[8],
			})
		end
	end
	return missing, #all
end
