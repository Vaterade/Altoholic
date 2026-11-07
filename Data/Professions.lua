-- Recipes, read when a profession window opens.
local L = Altoholic.L
local V = Altoholic.vars
local WHITE		= "|cFFFFFFFF"
local YELLOW	= "|cFFFFFF00"
local TEAL		= "|cFF00FF9A"

function Altoholic:GetSkillInfo(skillString)
	if type(skillString) ~= "string" then
		return 0, 0
	end
	local rank, maxRank = strsplit("|", skillString)
	return tonumber(rank), tonumber(maxRank)
end

-- every craft's name in the client's language, from Items/Recipes.lua, built when first needed
local craftNames
local function IsCraftName(name)
	if not craftNames then
		craftNames = {}
		for _, crafts in pairs(Altoholic.RecipeDB or {}) do
			for _, craft in ipairs(crafts) do craftNames[Altoholic:RecipeKey(L[craft[2]])] = true end
		end
	end
	return craftNames[Altoholic:RecipeKey(name)]
end

-- A recipe list row is a header when the profession window said so. Rows saved before 2.0
-- could keep the header flag after a recipe took their place (or a recipe's link after a
-- header did). For those, the row is a recipe when its name is a known craft's or its link
-- names the row itself; header names ("Armor", "Smelting") are neither.
function Altoholic:IsRecipeHeader(row)
	if not row.isHeader then return false end
	if not row.link then return true end
	if IsCraftName(row.name) then return false end
	return string.match(row.link, "%[(.-)%]") ~= row.name
end

-- a row about to be rewritten by a scan: nothing of what it held before is kept
local function Clear(row)
	row.isHeader, row.link, row.id, row.reagents = nil, nil, nil, nil
end

-- rows past the end of the list the window gave, left from a longer earlier list
local function DropRowsAfter(list, last)
	local i = last + 1
	while rawget(list, i) do
		list[i] = nil
		i = i + 1
	end
end

-- Repairs the rows saved before 2.0 (see IsRecipeHeader), once, at login.
function Altoholic:RepairRecipeLists()
	for _, f in pairs(self.db.account.data) do
		for _, r in pairs(f) do
			for _, c in pairs(rawget(r, "char") or {}) do
				for _, p in pairs(type(c) == "table" and rawget(c, "recipes") or {}) do
					local list = type(p) == "table" and rawget(p, "list")
					local i = 1
					while list and rawget(list, i) do
						local row = rawget(list, i)
						if row.isHeader and row.link then
							if self:IsRecipeHeader(row) then
								row.link, row.id, row.reagents = nil, nil, nil
							else
								row.isHeader = nil
							end
						end
						i = i + 1
					end
				end
			end
		end
	end
end

function Altoholic:UpdateTradeSkill(tradeskillName)
	local c = self.db.account.data[V.faction][V.realm].char[V.player]
	local r = c.recipes[tradeskillName].list
    if c.recipes[0] then
        c.recipes[0] = {}
        c.recipes[0] = nil
    end
    if c.recipes[tradeskillName].list[0] then
        c.recipes[tradeskillName].list[0] = {}
        c.recipes[tradeskillName].list[0] = nil
    end
	for i = GetNumTradeSkills(), 1, -1 do
		local _, skillType, _, isExpanded  = GetTradeSkillInfo(i)
		if (skillType == "header") and (isExpanded ~= true)  then
			ExpandTradeSkillSubClass(i)
		end
	end
	for k, v in pairs(c.ProfessionCooldowns) do
		local skill = strsplit("-", k)
		if skill == tradeskillName	then
			v = nil
		end
	end
	local bScanFailed = false
	for i = 1, GetNumTradeSkills() do
		local skillName, skillType = GetTradeSkillInfo(i)
		Clear(r[i])
        r[i].name = skillName
		if skillType == "header" then
			r[i].isHeader = true
		else
			r[i].link = GetTradeSkillItemLink(i)
			r[i].id = GetTradeSkillItemID(i)
			if not r[i].link or not r[i].id then
				bScanFailed = true
				break
			end
			local cooldown = GetTradeSkillCooldown(i)
			if cooldown then
				c.ProfessionCooldowns[ tradeskillName .. "-" .. r[i].id ] = cooldown .. "|" .. time()
			end
			local numReagents = GetTradeSkillNumReagents(i)
			local s = ""
			for j=1, numReagents do
				local _, _, reagentCount = GetTradeSkillReagentInfo(i, j);
				local reagentID = GetTradeSkillReagentItemID(i, j)
				if reagentID then
					s = s .. reagentID .. ":" .. reagentCount .. "|"
				else
					bScanFailed = true
				end
			end
			r[i].reagents = string.sub(s, 1, -2)
		end
	end
	if not bScanFailed then DropRowsAfter(r, GetNumTradeSkills()) end
	c.recipes[tradeskillName].ScanFailed = bScanFailed
	if bScanFailed then
		DEFAULT_CHAT_FRAME:AddMessage(TEAL .. "Altoholic: " .. WHITE .. L["At least one recipe could not be read"])
		DEFAULT_CHAT_FRAME:AddMessage(TEAL .. "Altoholic: " .. YELLOW .. L["Please open this window again"])
	end
	V.RebuildRecipeMenu = true
end

function Altoholic:UpdateCraft(tradeskillName)
	if Altoholic:GetProfessionID(tradeskillName) == 0 then return end -- unsupported/custom skill
	local c = self.db.account.data[V.faction][V.realm].char[V.player]
	local r = c.recipes[tradeskillName].list
    if c.recipes[0] then
        c.recipes[0] = {}
        c.recipes[0] = nil
    end
    if c.recipes[tradeskillName].list[0] then
        c.recipes[tradeskillName].list[0] = {}
        c.recipes[tradeskillName].list[0] = nil
    end
	for i = GetNumCrafts(), 1, -1 do
		local _, _, craftType, _, isExpanded = GetCraftInfo(i)
		if (craftType == "header") and (isExpanded ~= true)  then
			ExpandCraftSkillLine(i)
		end
	end
	for k, v in pairs(c.ProfessionCooldowns) do
		local skill = strsplit("-", k)
		if skill == tradeskillName	then
			v = nil
		end
	end
	local bScanFailed = false
	for i = 1, GetNumCrafts() do
		local craftName, _, craftType = GetCraftInfo(i)
		Clear(r[i])
        r[i].name = craftName
		if craftType == "header" then
			r[i].isHeader = true
		else
			r[i].link = GetCraftItemLink(i)
			local itemLink = GetCraftItemLink(i)
			if not itemLink then
				bScanFailed = true
				break
			end
			r[i].id = self:GetIDFromLink(itemLink)
			local numReagents = GetCraftNumReagents(i)
			local s = ""
			for j=1, numReagents do
				local _, _, reagentCount = GetCraftReagentInfo(i, j);
				local reagentID = GetCraftReagentItemID(i, j)
				if reagentID then
					s = s .. reagentID .. ":" .. reagentCount .. "|"
				else
					bScanFailed = true
				end
			end
			r[i].reagents = string.sub(s, 1, -2)
		end
	end
	if not bScanFailed then DropRowsAfter(r, GetNumCrafts()) end
	c.recipes[tradeskillName].ScanFailed = bScanFailed
	if bScanFailed then
		DEFAULT_CHAT_FRAME:AddMessage(TEAL .. "Altoholic: " .. WHITE .. L["At least one recipe could not be read"])
		DEFAULT_CHAT_FRAME:AddMessage(TEAL .. "Altoholic: " .. YELLOW .. L["Please open this window again"])
	end
	V.RebuildRecipeMenu = true
end

hooksecurefunc("DoTradeSkill", function()
	Altoholic:RegisterEvent("TRADE_SKILL_UPDATE")
end)

hooksecurefunc("DoCraft", function()
	Altoholic:RegisterEvent("CRAFT_UPDATE")
end)

function Altoholic:TRADE_SKILL_SHOW()
	self:UpdateTradeSkill(GetTradeSkillLine())
end

function Altoholic:TRADE_SKILL_UPDATE()
	self:UnregisterEvent("TRADE_SKILL_UPDATE")
	self:UpdateTradeSkill(GetTradeSkillLine())
end

function Altoholic:TRADE_SKILL_CLOSE()
	if self:IsEventRegistered("TRADE_SKILL_UPDATE") then
		self:UnregisterEvent("TRADE_SKILL_UPDATE")
	end
	self:UpdatePlayerSkills()
end

function Altoholic:CRAFT_SHOW()
	self:UpdateCraft(GetCraftName())
end

function Altoholic:CRAFT_UPDATE()
	self:UnregisterEvent("CRAFT_UPDATE")
	self:UpdateCraft(GetCraftName())
end

function Altoholic:CRAFT_CLOSE()
	if self:IsEventRegistered("CRAFT_UPDATE") then
		self:UnregisterEvent("CRAFT_UPDATE")
	end
	self:UpdatePlayerSkills()
end

function Altoholic:LEARNED_SPELL_IN_TAB()
	if self:IsEventRegistered("LEARNED_SPELL_IN_TAB") then
		self:UnregisterEvent("LEARNED_SPELL_IN_TAB")
	end
	self:UpdatePlayerSpells()
end
