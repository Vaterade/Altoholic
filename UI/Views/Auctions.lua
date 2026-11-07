-- Auctions and Bids: a character's auctions or bids, as last seen at the auction house.
-- Right-click the list to clear old entries.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local WHITE, RED, TEAL = "|cFFFFFFFF", "|cFFFF0000", "|cFF00FF9A"

-- kind: "auctions" or "bids", the field of the character record
local function NewView(kind)
	local view = {}

	-- removes this faction's entries (goblin = nil), the goblin AH's (goblin = 1) or all (goblin = "all")
	local function Clear(ref, goblin)
		local list = rawget(UI.Char(ref), kind)
		if not list then return end
		-- each entry is real here: the loop stays within #list
		for i = #list, 1, -1 do
			if goblin == "all" or list[i].AHLocation == goblin then table.remove(list, i) end
		end
		view:Update(ref)
	end

	local function Menu(ref)
		W.ShowMenu(view.frame, {
			{ text = L["Clear your faction's entries"], func = function() Clear(ref, nil) end },
			{ text = L["Clear goblin AH entries"], func = function() Clear(ref, 1) end },
			{ text = L["Clear all entries"], func = function() Clear(ref, "all") end },
		})
	end

	-- the columns: x offset and width; the last one runs to the right edge
	local COLUMNS = {
		{ L["Item"], 0, 236 },
		{ L["Time Left"], 240, 86 },
		{ kind == "auctions" and L["High Bidder"] or L["Seller"], 330, 116 },
		{ L["Bid"], 450, 110, "RIGHT" },
		{ BUYOUT or L["Buyout"], 564, nil, "RIGHT" },
	}

	local function Place(fs, parent, col)
		local c = COLUMNS[col]
		fs:ClearAllPoints()
		fs:SetPoint("LEFT", parent, "LEFT", c[2] + 4, 0)
		if c[3] then fs:SetWidth(c[3] - 8) else fs:SetPoint("RIGHT", parent, "RIGHT", -4, 0) end
		fs:SetJustifyH(c[4] or "LEFT")
	end

	-- the time left's long form ("Greater than 8 hours"), shown on hover
	local function TimeTooltip(self)
		local s = self:GetParent().item
		local detail = s and s.timeLeft and _G["AUCTION_TIME_LEFT" .. s.timeLeft .. "_DETAIL"]
		if not detail then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(_G["AUCTION_TIME_LEFT" .. s.timeLeft], 1, 1, 1)
		GameTooltip:AddLine(detail, .8, .8, .8)
		GameTooltip:Show()
	end

	function view:Create(frame, bar)
		local head = CreateFrame("Frame", nil, frame)
		head:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -6)
		head:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -6)
		head:SetHeight(18)
		for col, c in ipairs(COLUMNS) do
			local fs = W.Text(head)
			Place(fs, head, col)
			fs:SetText(c[1])
			fs:SetTextColor(.6, .6, .6)
		end
		local line = frame:CreateTexture(nil, "ARTWORK")
		line:SetHeight(1)
		line:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -2)
		line:SetPoint("TOPRIGHT", head, "BOTTOMRIGHT", 0, -2)
		line:SetColorTexture(1, 1, 1, .1)

		local holder = CreateFrame("Frame", nil, frame)
		holder:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -5)
		holder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
		holder:EnableMouse(true)
		holder:SetScript("OnMouseUp", function(_, button)
			if button == "RightButton" and view.args then Menu(view.args) end
		end)
		self.list = W.List(holder, 32,
			function(row)
				row.icon = W.ItemButton(row, 26)
				row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
				row.icon.onClick = function(_, button) if button == "RightButton" then Menu(view.args) end end
				row.name = W.Text(row)
				row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
				row.name:SetWidth(COLUMNS[1][3] - 40)
				row.time = CreateFrame("Button", nil, row)
				row.time:SetPoint("LEFT", row, "LEFT", COLUMNS[2][2], 0)
				row.time:SetWidth(COLUMNS[2][3])
				row.time:SetHeight(20)
				row.time.text = W.Text(row.time)
				row.time.text:SetPoint("LEFT", row.time, "LEFT", 4, 0)
				row.time:RegisterForClicks("RightButtonUp")
				row.time:SetScript("OnClick", function() Menu(view.args) end)
				row.time:SetScript("OnEnter", TimeTooltip)
				row.time:SetScript("OnLeave", function() GameTooltip:Hide() end)
				row.who = W.Text(row)
				Place(row.who, row, 3)
				row.bid = W.Text(row)
				Place(row.bid, row, 4)
				row.buyout = W.Text(row)
				Place(row.buyout, row, 5)
				row:RegisterForClicks("RightButtonUp")
				row:SetScript("OnClick", function() Menu(view.args) end)
			end,
			function(row, s)
				row.icon:SetItem(s.id, s.count)
				local name, _, quality = GetItemInfo(s.id)
				local _, _, _, hex = GetItemQualityColor(quality or 1)
				row.name:SetText((hex or WHITE) .. (name or ("item:" .. s.id)))
				local left = s.timeLeft and _G["AUCTION_TIME_LEFT" .. s.timeLeft]
				row.time.text:SetText(left and (TEAL .. left) or "")
				local who, bid
				if kind == "auctions" then
					who = s.highBidder and (WHITE .. s.highBidder) or (RED .. NO_BIDS)
					bid = s.startPrice
				else
					who = WHITE .. (s.owner or "")
					bid = s.bidPrice
				end
				if s.AHLocation then who = who .. " |cff888888(" .. L["Goblin AH"] .. ")" end
				row.who:SetText(who)
				row.bid:SetText(Altoholic:GetMoneyString(bid or 0))
				row.buyout:SetText((s.buyoutPrice or 0) > 0 and Altoholic:GetMoneyString(s.buyoutPrice) or "|cff555555-")
			end)
		self.message = W.Message(holder)
		self.status = W.Text(bar)
		self.status:SetPoint("LEFT", bar, "LEFT", 4, 0)
		self.status:SetTextColor(.7, .7, .7)
	end

	function view:Update(ref)
		self.args = ref
		local c = UI.Char(ref)
		local list = UI.Array(rawget(c, kind))
		self.list:SetData(list, self.ref == ref)
		self.ref = ref
		if #list == 0 then
			self.message:SetText(ref.name .. L[kind == "auctions" and " has no auctions" or " has no bids"])
			self.message:Show()
		else
			self.message:Hide()
		end
		local status = UI.ClassHex(c.class) .. ref.name .. "|r"
		if (c.lastAHcheck or 0) > 0 then
			status = status .. "  " .. L["last check "] .. Altoholic:GetDelayInDays(c.lastAHcheck) .. L[" days ago"]
		end
		self.status:SetText(status .. "  |cff888888" .. L["Right-click to clear old entries"])
	end
	return view
end

UI.RegisterView("Auctions", NewView("auctions"))
UI.RegisterView("Bids", NewView("bids"))
