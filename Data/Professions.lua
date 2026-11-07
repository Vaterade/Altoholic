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
