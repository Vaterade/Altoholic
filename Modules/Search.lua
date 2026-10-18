local L = Altoholic.L
local V = Altoholic.vars
local LEVEL_CAP = 60
local WHITE		= "|cFFFFFFFF"
local GREEN		= "|cFF00FF00"
local RED		= "|cFFFF0000"
local TEAL		= "|cFF00FF9A"
local YELLOW	= "|cFFFFFF00"

function Altoholic:Search_Update()
	local VisibleLines = 7
	local frame = "AltoSearch"
	local entry = frame.."Entry"
	if #self.SearchResults == 0 then
		self:ClearScrollFrame(_G[frame.."ScrollFrame"], entry, VisibleLines, 41)
		return
	end
	local offset = FauxScrollFrame_GetOffset(_G[frame.."ScrollFrame"]);
	for i=1, VisibleLines do
		local line = i + offset
		local s = self.SearchResults[line]
		if s ~= nil then
			local itemID = s.id
			local itemName, itemRarity, itemIcon, hex
			if not itemID then
				hex = WHITE
				_G[entry..i.."ItemIconTexture"]:SetTexture("Interface\\Icons\\Trade_Engraving");
			else
				itemName, _, itemRarity, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
				_, _, _, hex = GetItemQualityColor(itemRarity)
    			_G[entry..i.."ItemIconTexture"]:SetTexture(itemIcon);
			end
			if V.SearchLoots ~= nil then
				_G[entry..i.."Realm"]:SetText(WHITE .. L["Item Level"] .. ": " .. YELLOW .. s.iLvl)
			else
				_G[entry..i.."Realm"]:SetText(s.realm)
			end
			if s.craftName then
				_G[entry..i.."Name"]:SetText(hex .. s.craftName)
				_G[entry..i.."SourceNormalText"]:SetText(s.craftLink)
				_G[entry..i.."Source"]:SetID(line)
			else 
				_G[entry..i.."Name"]:SetText(hex .. itemName)
				_G[entry..i.."Source"]:SetText(TEAL .. s.location)
				_G[entry..i.."Source"]:SetID(0)
			end
			_G[entry..i.."Character"]:SetText(s.char)
			if (s.count ~= nil) and (s.count > 1) then
				_G[entry..i.."ItemCount"]:SetText(s.count)
				_G[entry..i.."ItemCount"]:Show()
			else
				_G[entry..i.."ItemCount"]:Hide()
			end
			_G[entry..i.."Item"]:SetID(line)
			_G[entry..i]:Show()
		else
			_G[entry..i]:Hide()
		end
	end
	if (offset+VisibleLines) <= #self.SearchResults then
		_G["AltoholicFrame_Status"]:SetText(#self.SearchResults .. L[" results found (Showing "] .. (offset+1) .. "-" .. (offset+VisibleLines) .. ")")
	else
		_G["AltoholicFrame_Status"]:SetText(#self.SearchResults .. L[" results found (Showing "] .. (offset+1) .. "-" .. #self.SearchResults .. ")")
	end
	_G["AltoholicFrame_Status"]:Show()
	if #self.SearchResults < VisibleLines then
		FauxScrollFrame_Update(_G[frame.."ScrollFrame"], VisibleLines, VisibleLines, 41);
	else
		FauxScrollFrame_Update(_G[frame.."ScrollFrame"], #self.SearchResults, VisibleLines, 41);
	end
end

-- *** Search Functions ***
function Altoholic:SearchReset()
	AltoholicFrame_SearchEditBox:SetText("")
	AltoholicFrame_MinLevel:SetText("")
	AltoholicFrame_MaxLevel:SetText("")
	for i=1, 7 do
		_G["AltoSearchEntry" .. i]:Hide()
	end
	_G["AltoholicFrame_Status"]:Hide()
    self.SearchResults = {}
end

-- classID and subClassID restrict the search to one item class / subclass (Enum.ItemClass)
function Altoholic:SearchItem(classID, subClassID)
	if (V.ongoingsearch ~= nil) then
		return
	end
	V.ongoingsearch = 1
	V.SearchLoots = nil
	V.SearchClassID = classID
	V.SearchSubClassID = subClassID
	local value = AltoholicFrame_SearchEditBox:GetText()
	V.SearchValue = strlower(value)
	V.MinLevel = AltoholicFrame_MinLevel:GetNumber()
	V.MaxLevel = AltoholicFrame_MaxLevel:GetNumber()
	if V.MaxLevel == 0 then
		V.MaxLevel = LEVEL_CAP
	end
    self.SearchResults = {}
	if AltoholicFrame_RadioButton1:GetChecked() then
		V.SearchFaction = V.faction
		V.SearchRealm = V.realm
		self:SearchRealm()
	elseif AltoholicFrame_RadioButton2:GetChecked() then
		for FactionName, f in pairs(self.db.account.data) do
			for RealmName, _ in pairs(f) do
				V.SearchFaction = FactionName
				V.SearchRealm = RealmName
				self:SearchRealm()
			end
		end
	else
		V.TotalLoots = 0
		V.TotalUnknown = 0
		V.SearchLoots = true
		for Instance, BossList in pairs(Altoholic.LootTable) do
			for Boss, LootList in pairs(BossList) do
				for itemID, _ in pairs(LootList) do
					self:VerifyLoot(Instance, Boss, LootList[itemID])
				end
			end
		end
		local O = self.db.account.options
		O.TotalLoots = V.TotalLoots
		O.UnknownLoots = V.TotalUnknown
		_G["AltoOptionsLootInfo"]:SetText(GREEN .. O.TotalLoots .. "|r " .. L["Loots"] .. " / " .. GREEN .. O.UnknownLoots .. "|r " .. L["Unknown"])								
		V.TotalLoots = nil
		V.TotalUnknown = nil
	end
	if #self.SearchResults == 0 then
		if V.SearchValue == "" then 
			_G["AltoholicFrame_Status"]:SetText(L["No match found!"])
		else
			_G["AltoholicFrame_Status"]:SetText(value .. L[" not found!"])
		end
		_G["AltoholicFrame_Status"]:Show()
	end
	V.ongoingsearch = nil
	V.SearchValue = nil
	V.SearchFaction = nil
	V.SearchRealm = nil
	V.SearchClassID = nil
	V.SearchSubClassID = nil
	if V.SearchLoots then
		if AltoOptions_SortDescending:GetChecked() then
			table.sort(self.SearchResults, function(a,b)
				return a.iLvl > b.iLvl
			end)
		else
			table.sort(self.SearchResults, function(a,b)
				return a.iLvl < b.iLvl
			end)
		end
	end
	self:ActivateMenuItem("AltoSearch")
end

function Altoholic:SearchRealm()
	for CharacterName, c in pairs(self.db.account.data[V.SearchFaction][V.SearchRealm].char) do
		V.SearchCharacter = self:GetClassColor(c.class) .. CharacterName
		for BagName, b in pairs(c.bag) do
			if (BagName == "Bag100") then
				V.SearchLocation = L["Bank"]
			elseif (BagName == "Bag-2") then
				V.SearchLocation = KEYRING
			else
				local bagNum = tonumber(string.sub(BagName, 4))
				if bagNum == nil then 
					DEFAULT_CHAT_FRAME:AddMessage("Encountered unknown bag "..BagName)
				elseif (bagNum >= 0) and (bagNum <= 4) then
					V.SearchLocation = L["Bags"]
				else
					V.SearchLocation = L["Bank"]
				end			
			end
			for slotID=1, b.size do
				if b.ids[slotID] ~= nil then
					self:VerifyItem(b.ids[slotID], b.counts[slotID])
				end
			end
		end
		V.SearchLocation = L["Equipped"]
		for slotID=1, 19 do
			if c.inventory[slotID] ~= nil then
				local item = c.inventory[slotID]	-- an ID, or a link when enchanted
				self:VerifyItem(type(item) == "number" and item or self:GetIDFromLink(item), 1)
			end
		end
		if AltoholicFrame_CheckButton1:GetChecked() then
			V.SearchLocation = L["Mail"]
			for slotID=1, #c.mail do
				local s = c.mail[slotID]
				if s.link ~= nil then
					self:VerifyItem(self:GetIDFromLink(s.link), s.count)
				end
			end
		end
		if AltoholicFrame_CheckButton3:GetChecked() and (V.SearchClassID == nil) then
			for ProfessionName, p in pairs(c.recipes) do
				if p.ScanFailed == false then
					for CraftNumber, craft in pairs(p.list) do
						self:VerifyRecipe(craft.link, ProfessionName, craft.id, CraftNumber, CharacterName)
					end
				end
			end
		end
	end
	V.SearchLocation = nil
	V.SearchCharacter = nil
end

function Altoholic:VerifyRecipe(link, profession, itemID, CraftNumber, charName)
	if not link then return end
	local itemName = self:GetCraftFromRecipe(link)
	if not itemName then return end
	if string.find(strlower(itemName), V.SearchValue, 1, true) == nil then
		return 
	end
	table.insert(self.SearchResults, {
		id = itemID,
		char = V.SearchCharacter,
		craftName = itemName,
		craftLink = link,
		realm = self:GetRealmString(V.SearchFaction, V.SearchRealm),
		searchRealm = V.SearchRealm,
		searchFaction = V.SearchFaction,
		location = profession,
		craftNum = CraftNumber,
		altName = charName
	} )
end

-- false when the item is not of the class / subclass the search is restricted to
local function MatchesItemClass(itemID)
	local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
	if (V.SearchClassID ~= nil) and (V.SearchClassID ~= classID) then
		return false
	end
	if (V.SearchSubClassID ~= nil) and (V.SearchSubClassID ~= subClassID) then
		return false
	end
	return true
end

function Altoholic:VerifyItem(itemID, itemCount)
	local itemName, _, itemRarity, itemMinLevel, _, _, _, itemEquipLoc = GetItemInfo(itemID)
	if (itemName == nil) and (itemRarity == nil) then
		return
	end
	if not MatchesItemClass(itemID) then
		return
	end
	if (itemRarity < V.SearchRarity) then
		return
	end
	if (itemMinLevel == 0) then
		if (AltoholicFrame_IncludeNoMinLevel:GetChecked() == nil) then
			return
		end
	else
		if (itemMinLevel < V.MinLevel) or (itemMinLevel > V.MaxLevel) then
			return
		end
	end
	if V.SearchSlot ~= 0 then
		if self.InvSlots[itemEquipLoc] ~= V.SearchSlot then
			return
		end
	end
	if string.find(strlower(itemName), V.SearchValue, 1, true) == nil then
		return
	end
	table.insert(self.SearchResults, {
		id = itemID,
		char = V.SearchCharacter,
		count = itemCount,
		realm = self:GetRealmString(V.SearchFaction, V.SearchRealm),
		location = V.SearchLocation
	} )
end

function Altoholic:VerifyLoot(Instance, Boss, itemID)
	V.TotalLoots = V.TotalLoots + 1
	local itemName, itemLink, itemRarity, itemMinLevel, _, _, _, itemEquipLoc, itemIcon = GetItemInfo(itemID)
    if itemMinLevel == 0 or itemMinLevel == nil then
        itemMinLevel = 57
    end    
    local itemLevel = itemMinLevel + 5
	if (itemName == nil) and (itemRarity == nil) then
		V.TotalUnknown = V.TotalUnknown + 1
		return
	end
	if not MatchesItemClass(itemID) then
		return		-- if there's a type or subtype and it's invalid .. Exit
	end
	if (itemRarity < V.SearchRarity) then
		return		-- if rarity is too low .. exit
	end
	if (itemMinLevel == 0) then
		if (AltoholicFrame_IncludeNoMinLevel:GetChecked() == nil) then
			return		-- no minimum requireement & should not be included ? .. exit
		end
	else
		if (itemMinLevel < V.MinLevel) or (itemMinLevel > V.MaxLevel) then
			return		-- not within the right level boundaries ? .. exit
		end
	end
	if V.SearchSlot ~= 0 then	-- if a specific equipment slot is specified ..
		if self.InvSlots[itemEquipLoc] ~= V.SearchSlot then
			return		-- not the right slot ? .. exit
		end
	end
	if string.find(strlower(itemName), V.SearchValue, 1, true) == nil then
		return		-- item name does not match search value ? .. exit
	end
	table.insert(self.SearchResults, {
		id = itemID,
		iLvl = itemLevel,
		char = GREEN .. Boss,
		location = WHITE .. Instance
	} )
end

function Altoholic:VerifyUpgrade()
	local itemName, _, itemRarity, itemMinLevel, _, _, _, itemEquipLoc = GetItemInfo(V.SearchLootItemID)
    if itemMinLevel == 0 or itemMinLevel == nil then
        itemMinLevel = 57
    end
    local itemLevel = itemMinLevel + 5
	if (itemName == nil) and (itemRarity == nil) then
		return			-- with these 2 being nil, the item isn't in the item cache, so its link would be invalid: don't list it
	end
	if (itemLevel <= V.Search_iLvl) or not MatchesItemClass(V.SearchLootItemID) then
		return		-- not within the right level boundaries ? invalid type or subtype ? .. exit
	end
	if Altoholic.InvSlots[itemEquipLoc] ~= V.SearchEquipLoc then
		return		-- not the right slot ? .. exit
	end
	table.insert(Altoholic.SearchResults, {
		id = V.SearchLootItemID,
		iLvl = itemLevel,
		char = GREEN .. V.SearchBoss,
		location = WHITE .. V.SearchInstance
	} )
end

function Altoholic:VerifyUpgradeByStats()
	local itemName, itemLink, itemRarity, itemMinLevel, _, _, _, itemEquipLoc = GetItemInfo(V.SearchLootItemID)
    if itemMinLevel == 0 or itemMinLevel == nil then
        itemMinLevel = 57
    end
    local itemLevel = itemMinLevel + 5
	if (itemName == nil) and (itemRarity == nil) then
		return			-- with these 2 being nil, the item isn't in the item cache, so its link would be invalid: don't list it
	end
	if (itemLevel <= V.Search_iLvl) or not MatchesItemClass(V.SearchLootItemID) then
		return		-- not within the right level boundaries ? invalid type or subtype ? .. exit
	end
	if Altoholic.InvSlots[itemEquipLoc] ~= V.SearchEquipLoc then
		return		-- not the right slot ? .. exit
	end
	local stats = Altoholic:GetUpgradeStats(V.SearchLootItemID)
	if not stats or Altoholic:IsUpgradeExcluded(V.CharacterClass, V.SearchLootItemID, stats) then
		return
	end
	local statLine = Altoholic:FormatUpgradeStats(V.CharacterClass, stats, V.SearchItemStats)
	table.insert(Altoholic.SearchResults, {
		id = V.SearchLootItemID,
		iLvl = itemLevel,
		char = statLine,
		location = WHITE .. V.SearchInstance .. ", " .. GREEN .. V.SearchBoss
	} )
end

function Altoholic:Search_OnClick(button, id)
    local s = Altoholic.SearchResults[id]
    if s.id ~= nil then
        local _, link = GetItemInfo(s.id)
        if ( button == "LeftButton" ) and ( IsControlKeyDown() ) then
            DressUpItemLink(link);
        elseif ( button == "LeftButton" ) and ( IsShiftKeyDown() ) then
            if ( ChatFrameEditBox:IsShown() ) then
                ChatFrameEditBox:Insert(Altoholic_GetItemLink(link));
            elseif (WIM_EditBoxInFocus) then
                WIM_EditBoxInFocus:Insert(Altoholic_GetItemLink(link));
            else
                AltoholicFrame_SearchEditBox:SetText(GetItemInfo(link))
            end
        end
    end
end

-- *** FRAME HANDLERS ***
function Altoholic:Search_OnEnter(frame)
	local s = Altoholic.SearchResults[frame:GetID()]
	if s.id ~= nil then
		local _, link = GetItemInfo(s.id)
		GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
		GameTooltip:SetHyperlink(link);
		GameTooltip:Show();
	end
end

-- link of the craft shown on a search result line, nil when the line isn't a known recipe
local function GetCraftLink(id)
	if id == 0 then return end
	local s = Altoholic.SearchResults[id]
	if s.craftLink == nil then return end
	local c = Altoholic.db.account.data[s.searchFaction][s.searchRealm].char[s.altName]
	local r = c.recipes[s.location].list
	if not r then return end
	return r[s.craftNum].link
end

function Altoholic:SearchCraft_OnEnter(frame)
	local link = GetCraftLink(frame:GetID())
	if link then
		GameTooltip:ClearLines();
		GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
		GameTooltip:SetHyperlink(link);
		GameTooltip:AddLine(" ",1,1,1);
		GameTooltip:Show();
	end
end

function Altoholic:SearchCraft_OnClick(frame, button)
	if ( button == "LeftButton" ) and ( IsShiftKeyDown() ) and ( ChatFrameEditBox:IsShown() ) then
		local link = GetCraftLink(frame:GetID())
		if link then
			ChatFrameEditBox:Insert(link);
		end
	end
end
