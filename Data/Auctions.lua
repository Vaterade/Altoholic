-- Auctions and bids, read at the auction house.
local Zones = Altoholic.Zones
local V = Altoholic.vars

function Altoholic:UpdatePlayerBids()
	local c = self.db.account.data[V.faction][V.realm].char[UnitName("player")]
	local numItems = GetNumAuctionItems("bidder")

	local AHZone
	local zone = GetRealZoneText()
	if (zone == Zones["Stranglethorn Vale"]) or		-- if it's a goblin AH .. save the value 1
		(zone == Zones["Tanaris"]) or
		(zone == Zones["Winterspring"]) then
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
	if (zone == Zones["Stranglethorn Vale"]) or		-- if it's a goblin AH .. save the value 1
		(zone == Zones["Tanaris"]) or
		(zone == Zones["Winterspring"]) then
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
		self:DataChanged("auctions")
	end
	
	if self:IsEventRegistered("AUCTION_BIDDER_LIST_UPDATE") then
		self:UnregisterEvent("AUCTION_BIDDER_LIST_UPDATE")
		self:DataChanged("bids")
	end
end
