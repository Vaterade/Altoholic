local BZ = LibStub("LibBabble-Zone-3.0"):GetLookupTable()
local L = Altoholic.L
local V = Altoholic.vars
local WHITE		= "|cFFFFFFFF"
local GREEN		= "|cFF00FF00"
local ORANGE	= "|cFFFF7F00"
local RED		= "|cFFFF0000"
local TEAL		= "|cFF00FF9A"

function Altoholic:Auctions_Update_Auctions()
	local c = self.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt]
	local VisibleLines = 7
	local frame = "AltoAuctions"
	local entry = frame.."Entry"

	if #c.auctions == 0 then
		_G["AltoholicFrame_Status"]:SetText("|cFFFFD700" .. V.CurrentAlt .. " of ".. V.CurrentRealm .. " |cFFFFFFFF" .. L[" has no auctions"])
		_G["AltoholicFrame_Status"]:Show()
		
		self:ClearScrollFrame(_G[frame.."ScrollFrame"], entry, VisibleLines, 41)
		return
	else
   		_G["AltoholicFrame_Status"]:SetText("|cFFFFD700" .. V.CurrentAlt .. " of ".. V.CurrentRealm .. " |cFFFFFFFF: " .. L["last check "] .. self:GetDelayInDays(c.lastAHcheck).. L[" days ago"])
		_G["AltoholicFrame_Status"]:Show()
	end

	local offset = FauxScrollFrame_GetOffset(_G[frame.."ScrollFrame"]);
	
	for i=1, VisibleLines do
		local line = i + offset
		if line <= #c.auctions then
			local s = c.auctions[line]
			local itemName, _, itemRarity = GetItemInfo(s.id)
			if itemRarity == nil then
				itemRarity = 0
			end
			if itemName == nil then
				itemName = "Unknown " .. s.id
			end
			-- DEFAULT_CHAT_FRAME:AddMessage(itemName .. ':' .. itemRarity)
			local _, _, _, itemQualityColor = GetItemQualityColor(itemRarity)
			_G[entry..i.."Name"]:SetText(itemQualityColor .. itemName)
			
			_G[entry..i.."TimeLeft"]:SetText( TEAL .. _G["AUCTION_TIME_LEFT"..s.timeLeft] 
								.. " (" .. _G["AUCTION_TIME_LEFT"..s.timeLeft .. "_DETAIL"] .. ")")

			local bidder
			if s.AHLocation then
				bidder = L["Goblin AH"] .. "\n"
			else
				bidder = ""
			end
			
			if s.highBidder then
				bidder = bidder .. WHITE .. s.highBidder
			else
				bidder = bidder .. RED .. NO_BIDS
			end
			_G[entry..i.."HighBidder"]:SetText(bidder)
			
			_G[entry..i.."Price"]:SetText(self:GetMoneyString(s.startPrice) .. "\n"  
					.. GREEN .. BUYOUT .. ": " ..  self:GetMoneyString(s.buyoutPrice))
            local _, _, _, _, _, _, _, _, itexture  = GetItemInfo(s.id)
			_G[entry..i.."ItemIconTexture"]:SetTexture(itexture);
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
	
	if #c.auctions < VisibleLines then
		FauxScrollFrame_Update(_G[frame.."ScrollFrame"], VisibleLines, VisibleLines, 41);
	else
		FauxScrollFrame_Update(_G[frame.."ScrollFrame"], #c.auctions, VisibleLines, 41);
	end
end

function Altoholic:Auctions_Update_Bids()
	local c = self.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt]		-- current alt
	local VisibleLines = 7
	local frame = "AltoAuctions"
	local entry = frame.."Entry"
	
	if #c.bids == 0 then
		_G["AltoholicFrame_Status"]:SetText("|cFFFFD700" .. V.CurrentAlt .. " of ".. V.CurrentRealm .. " |cFFFFFFFF" .. L[" has no bids"])
		_G["AltoholicFrame_Status"]:Show()
		
		self:ClearScrollFrame(_G[frame.."ScrollFrame"], entry, VisibleLines, 41)
		return
	else
		_G["AltoholicFrame_Status"]:SetText("|cFFFFD700" .. V.CurrentAlt .. " of ".. V.CurrentRealm .. " |cFFFFFFFF" .. BIDS .. ": " .. L["last check "] .. self:GetDelayInDays(c.lastAHcheck).. L[" days ago"])
		_G["AltoholicFrame_Status"]:Show()
	end

	local offset = FauxScrollFrame_GetOffset(_G[frame.."ScrollFrame"]);
	
	for i=1, VisibleLines do
		local line = i + offset
		if line <= #c.bids then
			local s = c.bids[line]
			
			local itemName, _, itemRarity = GetItemInfo(s.id)
            local _, _, _, itemQualityColor = GetItemQualityColor(itemRarity)
			_G[entry..i.."Name"]:SetText(itemQualityColor .. itemName)
			
			_G[entry..i.."TimeLeft"]:SetText( TEAL .. _G["AUCTION_TIME_LEFT"..s.timeLeft] 
								.. " (" .. _G["AUCTION_TIME_LEFT"..s.timeLeft .. "_DETAIL"] .. ")")
			
			if s.AHLocation then
				_G[entry..i.."HighBidder"]:SetText(L["Goblin AH"] .. "\n" .. WHITE .. s.owner)
			else
				_G[entry..i.."HighBidder"]:SetText(WHITE .. s.owner)
			end
			
			_G[entry..i.."Price"]:SetText(ORANGE .. CURRENT_BID .. ": " .. self:GetMoneyString(s.bidPrice) .. "\n"  
					.. GREEN .. BUYOUT .. ": " ..  self:GetMoneyString(s.buyoutPrice))
            local _, _, _, _, _, _, _, _, itexture  = GetItemInfo(s.id)
			_G[entry..i.."ItemIconTexture"]:SetTexture(itexture);
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
	
	if #c.bids < VisibleLines then
		FauxScrollFrame_Update(_G[frame.."ScrollFrame"], VisibleLines, VisibleLines, 41);
	else
		FauxScrollFrame_Update(_G[frame.."ScrollFrame"], #c.bids, VisibleLines, 41);
	end
end

function Altoholic:UpdatePlayerBids()
	local c = self.db.account.data[V.faction][V.realm].char[UnitName("player")]
	local numItems = GetNumAuctionItems("bidder")

	local AHZone
	local zone = GetRealZoneText()
	if (zone == BZ["Stranglethorn Vale"]) or		-- if it's a goblin AH .. save the value 1
		(zone == BZ["Tanaris"]) or
		(zone == BZ["Winterspring"]) then
		AHZone = 1
	end

	self:ClearAHEntries("bids", AHZone, UnitName("player"))
	
	c.lastAHcheck = time()
	if numItems == 0 then return end
	
	for i = 1, numItems do
		local itemName, _, itemCount, _, _, _,	_, 
			_, buyout, bidAmount, _, ownerName = GetAuctionItemInfo("bidder", i);
			
		if itemName then
			table.insert(c.bids, {
				id = GetAuctionItemID("bidder", i),
				count = itemCount,
				AHLocation = AHZone,
				bidPrice = bidAmount,
				buyoutPrice = buyout,
				owner = ownerName,
				timeLeft = GetAuctionItemTimeLeft("bidder", i)
			} )
		end
	end
	
end

function Altoholic:UpdatePlayerAuctions()
	local c = self.db.account.data[V.faction][V.realm].char[UnitName("player")]
	local numItems = GetNumAuctionItems("owner")

	local AHZone
	local zone = GetRealZoneText()
	if (zone == BZ["Stranglethorn Vale"]) or		-- if it's a goblin AH .. save the value 1
		(zone == BZ["Tanaris"]) or
		(zone == BZ["Winterspring"]) then
		AHZone = 1
	end	

	self:ClearAHEntries("auctions", AHZone, UnitName("player"))
	
	c.lastAHcheck = time()
	if numItems == 0 then return end
	
	for i = 1, numItems do
		local itemName, _, itemCount, _, _, _,	minBid, 
			_, buyout, _,	highBidderName = GetAuctionItemInfo("owner", i);

		if itemName then
			table.insert(c.auctions, {
				id = GetAuctionItemID("owner", i),
				count = itemCount,
				AHLocation = AHZone,
				highBidder = highBidderName,
				startPrice = minBid,
				buyoutPrice = buyout,
				timeLeft = GetAuctionItemTimeLeft("owner", i)
			} )
		end
	end
	
end

function Altoholic:ClearAHEntries(AHType, AHZone, character)
	local c = self.db.account.data[V.faction][V.realm].char[character]
	
	for i = #c[AHType], 1, -1 do			-- parse backwards to avoid messing up the index
		if c[AHType][i].AHLocation == AHZone then
			table.remove(c[AHType], i)
		end
	end
end


function AltoAuctions_RightClickMenu_OnLoad()
	local info = Altoholic_UIDropDownMenu_CreateInfo(); 

	info.text		= WHITE .. L["Clear your faction's entries"]
	info.value		= 1
	info.func		= Altoholic_ClearPlayerAHEntries;
	UIDropDownMenu_AddButton(info, 1); 

	info.text		= WHITE .. L["Clear goblin AH entries"]
	info.value		= 2
	info.func		= Altoholic_ClearPlayerAHEntries;
	UIDropDownMenu_AddButton(info, 1); 
	
	info.text		= WHITE .. L["Clear all entries"]
	info.value		= 3
	info.func		= Altoholic_ClearPlayerAHEntries;
	UIDropDownMenu_AddButton(info, 1); 
end

function errhandler(msg)
    print (msg .. "\nCall stack: \n" .. debugstack())
end

function Altoholic_ClearPlayerAHEntries()
	local c = Altoholic.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt]		-- current alt
	
	if (this.value == 1) or (this.value == 3) then	-- clean this faction's data
		for i = #c[V.AuctionType], 1, -1 do
			if c[V.AuctionType][i].AHLocation == nil then
				table.remove(c[V.AuctionType], i)
			end
		end
	end
	
	if (this.value == 2) or (this.value == 3) then	-- clean goblin AH
		for i = (c[V.AuctionType]), 1, -1 do
			if c[V.AuctionType][i].AHLocation == 1 then
				table.remove(c[V.AuctionType], i)
			end
		end
	end

	Altoholic:BuildAuctionsSubMenu()
	Altoholic:BuildBidsSubMenu()
	Altoholic:Menu_Update()
	Altoholic:Auctions_Update()
end

-- *** EVENT HANDLERS ***
function Altoholic:AUCTION_HOUSE_SHOW()
	V.isAHOpen = true
	self:RegisterEvent("AUCTION_BIDDER_LIST_UPDATE")
	self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
end

function Altoholic:AUCTION_BIDDER_LIST_UPDATE()
	self:UpdatePlayerBids()
end

function Altoholic:AUCTION_OWNED_LIST_UPDATE()
	self:UpdatePlayerAuctions()
end

function Altoholic:AUCTION_HOUSE_CLOSED()
	V.isAHOpen = nil
	
	if self:IsEventRegistered("AUCTION_OWNED_LIST_UPDATE") then
		self:UnregisterEvent("AUCTION_OWNED_LIST_UPDATE")
		self:BuildAuctionsSubMenu()
	end
	
	if self:IsEventRegistered("AUCTION_BIDDER_LIST_UPDATE") then
		self:UnregisterEvent("AUCTION_BIDDER_LIST_UPDATE")
		self:BuildBidsSubMenu()
	end
end

-- *** FRAME HANDLERS ***
local function GetAuctionEntry(id)
	return Altoholic.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt][V.AuctionType][id]
end

function Altoholic:Auction_OnEnter(frame)
	local s = GetAuctionEntry(frame:GetID())
	if s.id ~= nil then
		local _, link = GetItemInfo(s.id)
		GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
		GameTooltip:SetHyperlink(link);
		GameTooltip:Show();
	end
end

function Altoholic:Auction_OnClick(frame, button)
	local s = GetAuctionEntry(frame:GetID())
	if s.id ~= nil then
		local _, link = GetItemInfo(s.id)
		if ( button == "LeftButton" ) and ( IsControlKeyDown() ) then
			DressUpItemLink(link);
		elseif ( button == "LeftButton" ) and ( IsShiftKeyDown() ) then
			if ( ChatFrameEditBox:IsShown() ) then
				ChatFrameEditBox:Insert(link);
			else
				AltoholicFrame_SearchEditBox:SetText(GetItemInfo(link))
			end
		end
	end
end

function Altoholic:AuctionMenu_OnClick(frame, button)
	if button == "RightButton" then
		ToggleDropDownMenu(1, nil, AltoAuctionsRightClickMenu, frame:GetName(), 0, -5);
	end
end
