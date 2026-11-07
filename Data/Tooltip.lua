-- What the item, recipe and quest tooltips add about the alts.
local L = Altoholic.L
local V = Altoholic.vars
local Professions = Altoholic.Professions
local WHITE		= "|cFFFFFFFF"
local RED		= "|cFFFF0000"
local GREEN		= "|cFF00FF00"
local YELLOW	= "|cFFFFFF00"
local ORANGE	= "|cFFFF7F00"
local TEAL		= "|cFF00FF9A"
local GOLD		= "|cFFFFD700"

-- ** Tooltip Hooks **
local function OnTooltipSetItem()
	-- these scripts get no arguments, the tooltip is the global 'this'
	local _, _, itemID = this:GetItem()
	if itemID then
		Altoholic:ProcessTooltip(this, itemID)
	end
end

function Altoholic:HookTooltip()
	GameTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
	ItemRefTooltip:HookScript("OnTooltipSetItem", OnTooltipSetItem)
	hooksecurefunc("SetItemRef", function(link, text)
		Altoholic:IsKnownQuest(text)
	end)
end

function Altoholic:RecipeOrBook(ttname)
    local isRecipe, isBook
    if ttname then
        local isMatch = nil
        local rb = Altoholic.RecipesBooks
        for r = 1, 5 do
            if string.find(ttname, rb[r]) then
                isMatch = "isRecipe"
            end
        end
        for b = 6, 17 do
            if string.find(ttname, rb[b]) then
                isMatch = "isBook"
            end
        end
        if isMatch then
            return isMatch
        end
    else
        return nil
    end
end

function Altoholic:AltHasTradeSkill(c, prof)
    local r = self.db.account.data[V.faction][V.realm].char[c]
    if c then
        local minSkillp, _ = Altoholic:GetSkillInfo(r.skill[L["Professions"]][prof])
        if minSkillp > 0 then
            return true
        end      
        local minSkills, _ = Altoholic:GetSkillInfo(r.skill[L["Secondary Skills"]][prof])
        if minSkills > 0 then
            return true
        end
    else
        return false
    end
end

function Altoholic:WhoKnowsRecipe(tooltip)
    if (Altoholic:Option("TooltipAlreadyKnown") or Altoholic:Option("TooltipLearnableBy")) == nil then return end
    if tooltip == nil then return end
    local ttype = tooltip:GetName()
    local ttname = _G[ttype..'TextLeft1']:GetText()
    if ttname == nil then return end
    if Altoholic:RecipeOrBook(ttname) == "isBook" then
        local ttuse = _G[ttype..'TextLeft4']:GetText()
        local spellName, reqClass, reqLevel
        if string.find(ttuse, "%sTeaches") and not string.find(_G[ttype..'TextLeft4']:GetText(), USED) then
            spellName = string.match(ttuse, ".*Teaches%s(.+%s%(.+%))")
            reqClass = string.match(_G[ttype..'TextLeft2']:GetText(), string.gsub(ITEM_CLASSES_ALLOWED,"%%s","(.+)"))
            reqLevel = string.match(_G[ttype..'TextLeft3']:GetText(), string.gsub(ITEM_MIN_LEVEL,"%%d","(.+)"))
            local book
            for CharacterName, c in pairs(Altoholic.db.account.data[V.faction][V.realm].char) do
                local isNotKnownByChar = false
                for _, SpellName in pairs(c.spells) do
                    if SpellName ~= spellName then
                        isNotKnownByChar = true
                        break
                    end
                end
                local ttlines
                if isNotKnownByChar and reqClass == c.class then
                    if Altoholic:Option("TooltipLearnableBy") then
                        if c.level < tonumber(reqLevel) then
                            ttlines = RED .. L["Will be learnable by "] .. WHITE .. CharacterName .. YELLOW .. " ("..c.level..")" .. "\n"
                        else
                            ttlines = YELLOW .. L["Could be learned by "] .. WHITE .. CharacterName .. "\n"
                        end
                    else
                        ttlines = ""
                    end
                elseif reqClass == c.class then
                    if Altoholic:Option("TooltipAlreadyKnown") then 
                        ttlines = TEAL .. L["Already known by "] .. WHITE .. CharacterName .. "\n"
                    else
                        ttlines = ""
                    end
                end
                if book == nil then
                    book = ttlines
                elseif ttlines then
                    book = book .. ttlines
                end
            end
            if book then
                tooltip:AddLine(" ",1,1,1)
                tooltip:AddLine(book,1,1,1)
            end
        end
    elseif Altoholic:RecipeOrBook(ttname) == "isRecipe" then        
        local recipeName, ttProfession, profName, profLevel, recipeTT, msg
        recipeName = string.match(ttname, ".*:%s(.+)")
        ttProfession = _G[ttype..'TextLeft2']:GetText()
        profName, profLevel = string.match(ttProfession, ".*%s(.+)%s%((.+)%)")
        profLevel = tonumber(profLevel)
        for CharacterName, c in pairs(Altoholic.db.account.data[V.faction][V.realm].char) do
            if Altoholic:AltHasTradeSkill(CharacterName, profName) and c.recipes[profName].ScanFailed then
                tooltip:AddLine(" ",1,1,1)
                tooltip:AddLine("------------------------------------------------",1,1,1)
                tooltip:AddLine("Recipe database is empty for " .. CharacterName .. ".",1,0,0)
                tooltip:AddLine("Please open your " .. profName .. " tradeskill.",1,0,0)
                tooltip:AddLine("------------------------------------------------",1,1,1)
            end
            for ProfessionName, p in pairs(c.recipes) do
                if ProfessionName == profName then
                    local isKnownByChar = false
                    for _, TradeSkillInfo in pairs (p.list) do
                        if TradeSkillInfo.name ~= nil then
                            local skillName = TradeSkillInfo.name
                            if skillName == recipeName then
                                isKnownByChar = true
                                break
                            end
                        end
                    end
					local ttlines = ""
                    if isKnownByChar then
                        if Altoholic:Option("TooltipAlreadyKnown") then 
                            ttlines = TEAL .. L["Already known by "] .. WHITE .. CharacterName .. "\n"
                        else
                            ttlines = ""
                        end
                    else
                        if Altoholic:Option("TooltipLearnableBy") then 
                            local curRank
                            if (ProfessionName == Professions["Cooking"]) or
                                (ProfessionName == Professions["First Aid"]) or
                                (ProfessionName == Professions["Fishing"]) or
                                (ProfessionName == L["Survival"]) then
                                curRank = Altoholic:GetSkillInfo( c.skill[L["Secondary Skills"]][ProfessionName] )
                            else
                                curRank = Altoholic:GetSkillInfo( c.skill[L["Professions"]][ProfessionName] )
                            end
                            if curRank < profLevel and curRank > 0 then
                                ttlines = RED .. L["Will be learnable by "] .. WHITE .. CharacterName .. YELLOW .. " ("..curRank..")" .. "\n"
                            elseif curRank > profLevel then
                                ttlines = YELLOW .. L["Could be learned by "] .. WHITE .. CharacterName .. "\n"
                            end
                        else
                            ttlines = ""
                        end
                    end
                    if recipeTT == nil then
                        recipeTT = ttlines
                    else
                        recipeTT = recipeTT .. ttlines
                    end
                end                
            end
        end
        if recipeTT ~= nil and recipeTT ~= "" then
            tooltip:AddLine(" ",1,1,1)
            tooltip:AddLine(recipeTT,1,1,1)
        end
    end
end

function Altoholic:GetCraftFromRecipe(link)
	local _, _, _, recipeName = strsplit("|", link)
	local craftName
	local pos = string.find(recipeName, L["Transmute"])
	if pos then
		return string.sub(recipeName, pos, -2)
	else
        _, _, _, craftName = strsplit(":", recipeName)
	end
	if craftName == nil then
		return string.sub(recipeName, 3, -2)
	end
	return string.sub(craftName, 2, -2)
end

function Altoholic:ProcessTooltip(tooltip, itemID)
	if itemID ~= V.ToolTipCachedItemID then
		V.ToolTipCachedItemID = itemID
		V.TooltipRecipeCache = nil
        V.ItemCount = nil
		if Altoholic:Option("TooltipSource") then
			local Instance, Boss = self:GetItemDropLocation(itemID)
			if (Instance == nil) then
				V.ToolTipCachedSource = nil
			else
				V.ToolTipCachedSource = GOLD .. L["Source"]..  ": |cff00ff9a" .. Instance .. ": " .. Boss
			end
		else
			V.ToolTipCachedSource = nil
		end
		if Altoholic:Option("TooltipCount") or Altoholic:Option("TooltipTotal") then
			V.ToolTipCachedCount = self:GetItemCount(itemID)
			if V.ToolTipCachedCount > 0 then
				V.ToolTipCachedTotal = GOLD .. L["Total owned"] .. ": |cff00ff9a" .. V.ToolTipCachedCount
			else
				V.ToolTipCachedTotal = nil
			end
		else
			V.ToolTipCachedCount = 0
			V.ToolTipCachedTotal = nil
		end
	end
	if (Altoholic:Option("TooltipCount")) and (V.ToolTipCachedCount > 0) then
		tooltip:AddLine(" ",1,1,1);
		for CharacterName, c in pairs (V.ItemCount) do
			tooltip:AddDoubleLine(CharacterName .. ":",  TEAL .. c);
		end
	end
	if (Altoholic:Option("TooltipTotal")) and (V.ToolTipCachedTotal) then
		tooltip:AddLine(V.ToolTipCachedTotal,1,1,1,true);
	end
	if V.ToolTipCachedSource then
		tooltip:AddLine(" ",1,1,1);
		tooltip:AddLine(V.ToolTipCachedSource,1,1,1,true);
	end
	-- Keep here if necessary, can be useful for debugging
	-- local iLevel = select(4, GetItemInfo(itemID))
	-- if iLevel then
		-- tooltip:AddLine(" ",1,1,1);
		-- tooltip:AddDoubleLine("Item ID: " .. GREEN .. itemID,  "iLvl: " .. GREEN .. iLevel);
		-- tooltip:AddLine(TEAL .. select(10, GetItemInfo(itemID)));
	-- end
	if not V.TooltipRecipeCache then
        self:WhoKnowsRecipe(tooltip)
	end
    tooltip:Show()
end

-- adds the alts on the quest of a clicked quest link to its tooltip
function Altoholic:IsKnownQuest(quest)
	if not quest or not string.find(quest, "Hquest:", 1, true) then return nil end
	local clicked = {
		id = tonumber(string.match(quest, "quest:(%d+)")),
		title = string.match(quest, "%[(.+)%]"),
	}
	if clicked.id == 0 then clicked.id = nil end	-- a link made before the quest ID was recorded
	local bOtherCharsOnQuest
	for CharacterName, c in pairs(self.db.account.data[V.faction][V.realm].char) do
		if CharacterName ~= V.player then
			for index, q in pairs(c.questlog) do
				if self:IsSameQuest(clicked, q) then
					if not bOtherCharsOnQuest then
						ItemRefTooltip:AddLine(" ",1,1,1);
						ItemRefTooltip:AddLine(GREEN .. L["Are also on this quest:"],1,1,1);
						bOtherCharsOnQuest = true
					end
					ItemRefTooltip:AddLine(Altoholic:GetClassColor(c.class) .. CharacterName,1,1,1);
					ItemRefTooltip:Show();
				end
			end
		end
	end
end

function Altoholic:GetItemCount(searchedID)
	if V.ItemCount == nil then
		V.ItemCount = {}
	end
	local count = 0
	for faction,_ in pairs(self.db.account.data) do
		for realm in pairs(self.db.account.data[faction]) do
			if V.realm == realm then
				for CharacterName, c in pairs(self.db.account.data[faction][realm].char) do
					local bagCount = 0
					local bankCount = 0
					for BagName, b in pairs(c.bag) do
						for slotID=1, b.size do
							local id = b.ids[slotID]
							if (id) and (id == searchedID) then
								local itemCount
								if (b.counts[slotID] == nil) or (b.counts[slotID] == 0) then
									itemCount = 1
								else
									itemCount = b.counts[slotID]
								end
								if (BagName == "Bag100") then
									bankCount = bankCount + itemCount
								elseif (BagName == "Bag-2") then
									bagCount = bagCount + itemCount
								else
									local bagNum = tonumber(string.sub(BagName, 4))
									if (bagNum >= 0) and (bagNum <= 4) then
										bagCount = bagCount + itemCount
									else
										bankCount = bankCount + itemCount
									end
								end
							end
						end
					end
					local equipCount = 0
					for slotID=1, 19 do
						local s = c.inventory[slotID]
						if (s ~= nil) then
							if type(s) == "number" then
								if (s == searchedID) then
									equipCount = equipCount + 1
								end
							elseif self:GetIDFromLink(s) == searchedID then
								equipCount = equipCount + 1
							end
						end
					end
					local mailCount = 0
					for slotID=1, #c.mail do
						local s = c.mail[slotID]
						if (s.link ~= nil) and (self:GetIDFromLink(s.link) == searchedID) then
							if (s.count == nil) or (s.count == 0) then
								mailCount = mailCount + 1
							else
								mailCount = mailCount + s.count
							end
						end
					end
					local charCount = bagCount + bankCount + equipCount + mailCount
					count = count + charCount
					if charCount > 0 then
						local charInfo = ORANGE .. charCount .. WHITE .. " ("
						if bagCount > 0 then
							charInfo = charInfo .. WHITE .. L["Bags"] .. ": "  .. TEAL .. bagCount
							charCount = charCount - bagCount
							if charCount > 0 then
								charInfo = charInfo .. WHITE .. L[", "]
							end
						end
						if bankCount > 0 then
							charInfo = charInfo .. WHITE .. L["Bank"] .. ": " .. TEAL .. bankCount
							charCount = charCount - bankCount
							if charCount > 0 then
								charInfo = charInfo .. WHITE .. L[", "]
							end
						end
						if equipCount > 0 then
							charInfo = charInfo .. WHITE .. L["Equipped"] .. ": "  .. TEAL .. equipCount
							charCount = charCount - equipCount
							if charCount > 0 then
								charInfo = charInfo .. WHITE .. L[", "]
							end
						end
						if mailCount > 0 then
							charInfo = charInfo .. WHITE .. L["Mail"] .. ": "  .. TEAL .. mailCount
						end
						charInfo = charInfo .. WHITE .. ")"
						V.ItemCount[Altoholic:GetClassColor(c.class) .. CharacterName] = charInfo
					end
				end
			end
		end
	end
	return count
end

function Altoholic:GetItemDropLocation(searchedID)
	for Instance, BossList in pairs(Altoholic.LootTable) do
		for Boss, LootList in pairs(BossList) do
			for itemID, _ in pairs(LootList) do
				if LootList[itemID] == searchedID then
					return Instance, Boss
				end
			end
		end
	end
	return nil
end

function Altoholic:IsGatheringNode(name)
	if name == nil then return nil end
	for k, v in pairs( self.Gathering ) do
		if name == k then
			return v
		end
	end
	return nil
end

function Altoholic:GetSuggestion(index, level)
	if self.Suggestions[index] == nil then return nil end
	for k, v in pairs( self.Suggestions[index] ) do
		if level < v[1] then
			return v[2]
		end
	end
	return nil
end
