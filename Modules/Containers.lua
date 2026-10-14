local L = Altoholic.L
local V = Altoholic.vars

function Altoholic:Containers_Update()
	local VisibleLines = 7
	local frame = "AltoContainers"
	local entry = frame.."Entry"
	if #self.BagIndices == 0 then
		self:ClearScrollFrame(_G[frame.."ScrollFrame"], entry, VisibleLines, 41)
		return
	else
		_G["AltoholicFrame_Status"]:SetText("|cFFFFD700" .. V.CurrentAlt .. " of ".. V.CurrentRealm .. " |cFFFFFFFF" .. L["Containers"])
		_G["AltoholicFrame_Status"]:Show()
	end
	local c = self.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt]
	local offset = FauxScrollFrame_GetOffset(_G[frame.."ScrollFrame"]);
	for i=1, VisibleLines do
		local line = i + offset
		local b = c.bag["Bag" .. self.BagIndices[line].bagID]
		local itemName = entry..i .. "Item1";
		if self.BagIndices[line].from == 1 then
			local itemButton = _G[itemName];	
			itemButton:SetID(0)
			local itemTexture = _G[itemName .. "IconTexture"]
			if b.icon ~= nil then
				itemTexture:SetTexture(b.icon);
			else
				itemTexture:SetTexture("Interface\\Icons\\INV_Box_03");
			end
			itemTexture:SetWidth(36);
			itemTexture:SetHeight(36);
			itemTexture:SetAllPoints(itemButton);
			_G[itemName]:Show()
		else
			_G[itemName]:Hide()
		end
		for j=3, 14 do
			local itemName = entry..i .. "Item" .. j;
			local itemButton = _G[itemName];
			local itemIndex = self.BagIndices[line].from - 3 + j
			if (itemIndex <= b.size) then 
				itemButton:SetID(itemIndex)
				local itemTexture = _G[itemName .. "IconTexture"]
				if b.ids[itemIndex] ~= nil then
                    local _, _, _, _, _, _, _, _, itemTextureIcon = GetItemInfo(b.ids[itemIndex]); 
					itemTexture:SetTexture(itemTextureIcon);
				else
					itemTexture:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot");
				end
				itemTexture:SetWidth(36);
				itemTexture:SetHeight(36);
				itemTexture:SetAllPoints(itemButton);
				local itemCount = _G[itemName .. "Count"]
				if (b.counts[itemIndex] == nil) or (b.counts[itemIndex] < 2)then
					itemCount:Hide();
				else
					itemCount:SetText(b.counts[itemIndex]);
					itemCount:Show();
				end
			
				_G[itemName]:Show()
			else
				_G[itemName]:Hide()
			end
		end
		_G[entry..i]:Show()
		_G[entry..i]:SetID(self.BagIndices[line].bagID)
	end
	if #self.BagIndices < VisibleLines then
		FauxScrollFrame_Update(_G[frame.."ScrollFrame"], VisibleLines, VisibleLines, 41);
	else
		FauxScrollFrame_Update(_G[frame.."ScrollFrame"], #self.BagIndices, VisibleLines, 41);
	end	
end	

function Altoholic:Item_OnEnter(frame, bagID, itemID)
	local id, link
    local r = self.db.account.data[V.CurrentFaction][V.CurrentRealm]
    if itemID == 0	then
        GameTooltip:SetOwner(frame, "ANCHOR_LEFT");
        if bagID == -2 then
            GameTooltip:AddLine(KEYRING,1,1,1);
            GameTooltip:AddLine(L["32 Keys Max"],1,1,1);
        elseif bagID == 0 then
            GameTooltip:AddLine(BACKPACK_TOOLTIP,1,1,1);
            GameTooltip:AddLine(format(CONTAINER_SLOTS, 16, BAGSLOT),1,1,1);
            
        elseif bagID == 100 then
            GameTooltip:AddLine(L["Bank"],0.5,0.5,1);
            GameTooltip:AddLine(L["28 Slot"],1,1,1);
        else
            GameTooltip:SetHyperlink(self:GetItemString(r.char[V.CurrentAlt].bag["Bag" .. bagID].link));
            if (bagID >= 5) and (bagID <= 11) then
                GameTooltip:AddLine(L["Bank bag"],0,1,0);
            end
        end
        GameTooltip:Show();
        return
    else
        id = r.char[V.CurrentAlt].bag["Bag" .. bagID].ids[itemID]
        link = r.char[V.CurrentAlt].bag["Bag" .. bagID].links[itemID]
    end
	if id ~= nil then
		GameTooltip:SetOwner(frame, "ANCHOR_LEFT");
		if not link then
            local _, itemLink = GetItemInfo(id)
			link = itemLink
		end
		if not link then
			GameTooltip:AddLine(L["Unknown link, please relog this character"],1,1,1);
		else
			GameTooltip:SetHyperlink(self:GetItemString(link));
		end
		GameTooltip:Show();
	end
end

function Altoholic:Item_OnClick(frame, button)
    local item, link
    local bagID = frame:GetParent():GetID()
    local itemID = frame:GetID()
    local b = self.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt].bag["Bag" .. bagID]
    item = b.ids[itemID]
    if not item then return end
	-- an enchanted or suffixed item also has its full link stored, which is what goes into chat
	local fullLink = b.links[itemID]
	if fullLink then
		link = self:GetItemString(fullLink)
	else
		_, link = GetItemInfo(item)
	end
    if ( button == "LeftButton" ) and ( IsControlKeyDown() ) then
        DressUpItemLink(link);
	elseif ( button == "LeftButton" ) and ( IsShiftKeyDown() ) then
		if ( ChatFrameEditBox:IsShown() ) then
			ChatFrameEditBox:Insert(fullLink or Altoholic_GetItemLink(link));
        elseif (WIM_EditBoxInFocus) then
            WIM_EditBoxInFocus:Insert(fullLink or Altoholic_GetItemLink(link));
		else
			AltoholicFrame_SearchEditBox:SetText(GetItemInfo(link))
		end
	end
end
