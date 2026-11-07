-- Queueing crafts for a character in pfUI-trades, when that addon is loaded. pfUI-trades keeps
-- each character's task list by realm, so only characters on the logged-in realm can be given
-- work. A task is built from the recipe Altoholic saved; pfUI-trades fills in the rest (the
-- spell ID, how many one craft makes) when that character next opens the profession.
local V = Altoholic.vars

function Altoholic:CanQueueCrafts(realm)
	return pfUITrades and pfUITrades.QueueFor and (realm == nil or realm == V.realm) and true or false
end

-- "itemID:count|itemID:count|..." as Data/Professions.lua saves them
function Altoholic:ParseReagents(s)
	local list = {}
	for id, count in string.gmatch(s or "", "(%d+):(%d+)") do
		table.insert(list, { tonumber(id), tonumber(count) })
	end
	return list
end

local function ItemName(id)
	return (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)) or (GetItemInfo(id)) or ("item:" .. id)
end

local function ItemIcon(id)
	if C_Item and C_Item.GetItemIconByID then
		local icon = C_Item.GetItemIconByID(id)
		if icon then return icon end
	end
	local _, _, _, _, _, _, _, _, icon = GetItemInfo(id)
	return icon
end

-- the task pfUI-trades wants, from a saved recipe { name, link, id, reagents }
function Altoholic:TaskFromRecipe(recipe)
	local reagents = {}
	for _, r in ipairs(self:ParseReagents(recipe.reagents)) do
		table.insert(reagents, { id = r[1], name = ItemName(r[1]), icon = ItemIcon(r[1]), count = r[2] })
	end
	-- an enchant's link names its spell; a tradeskill's is the item it makes
	local spell = recipe.spell or (recipe.link and tonumber(string.match(recipe.link, "enchant:(%d+)")))
	return {
		name = recipe.name,
		spell = spell,
		icon = recipe.id and ItemIcon(recipe.id),
		item = recipe.id,
		made = recipe.id and 1 or 0,
		reagents = reagents,
	}
end

-- queues count crafts of a saved recipe on a character; returns the task, or nil and why not
function Altoholic:QueueCraft(name, realm, profession, recipe, count)
	if not self:CanQueueCrafts() then return nil, "pfUI-trades isn't loaded" end
	if realm ~= V.realm then return nil, "pfUI-trades only keeps lists for this realm" end
	if not recipe or not recipe.name or Altoholic:IsRecipeHeader(recipe) then return nil, "not a recipe" end
	return pfUITrades.QueueFor(name, profession, self:TaskFromRecipe(recipe), count or 1)
end

-- how many crafts of a recipe are already queued for a character
function Altoholic:QueuedCrafts(name, profession, recipeName)
	if not (pfUITrades and pfUITrades.QueuedFor) then return 0 end
	return pfUITrades.QueuedFor(name, profession, recipeName) or 0
end
