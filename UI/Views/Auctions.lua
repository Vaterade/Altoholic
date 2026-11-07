-- Auctions and Bids: a character's auctions or bids, as last seen at the auction house.
-- Right-click the list to clear old entries.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local WHITE, GREEN, ORANGE, RED, TEAL = "|cFFFFFFFF", "|cFF00FF00", "|cFFFF7F00", "|cFFFF0000", "|cFF00FF9A"

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

	function view:Create(frame, bar)
		local holder = CreateFrame("Frame", nil, frame)
		holder:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
		holder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
		holder:EnableMouse(true)
		holder:SetScript("OnMouseUp", function(_, button)
			if button == "RightButton" and view.args then Menu(view.args) end
		end)
		self.list = W.List(holder, 34,
			function(row)
				row.icon = W.ItemButton(row, 28)
				row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
				row.icon.onClick = function(_, button) if button == "RightButton" then Menu(view.args) end end
				row.name = W.Text(row)
				row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
				row.name:SetWidth(200)
				row.left = W.Text(row)
				row.left:SetPoint("LEFT", row.name, "RIGHT", 8, 0)
				row.left:SetWidth(130)
				row.who = W.Text(row)
				row.who:SetPoint("LEFT", row.left, "RIGHT", 8, 0)
				row.who:SetWidth(110)
				row.price = W.Text(row, nil, "RIGHT")
				row.price:SetPoint("LEFT", row.who, "RIGHT", 8, 0)
				row.price:SetPoint("RIGHT", row, "RIGHT", -4, 0)
				row:RegisterForClicks("RightButtonUp")
				row:SetScript("OnClick", function() Menu(view.args) end)
			end,
			function(row, s)
				row.icon:SetItem(s.id, s.count)
				local name, _, quality = GetItemInfo(s.id)
				local _, _, _, hex = GetItemQualityColor(quality or 1)
				row.name:SetText((hex or WHITE) .. (name or ("item:" .. s.id)))
				local left = s.timeLeft and _G["AUCTION_TIME_LEFT" .. s.timeLeft]
				row.left:SetText(left and (TEAL .. left .. " (" .. _G["AUCTION_TIME_LEFT" .. s.timeLeft .. "_DETAIL"] .. ")") or "")
				local who
				if kind == "auctions" then
					who = s.highBidder and (WHITE .. s.highBidder) or (RED .. NO_BIDS)
					row.price:SetText(Altoholic:GetMoneyString(s.startPrice or 0) .. "\n" .. GREEN .. BUYOUT .. ": " .. Altoholic:GetMoneyString(s.buyoutPrice or 0))
				else
					who = WHITE .. (s.owner or "")
					row.price:SetText(ORANGE .. CURRENT_BID .. ": " .. Altoholic:GetMoneyString(s.bidPrice or 0) .. "\n" .. GREEN .. BUYOUT .. ": " .. Altoholic:GetMoneyString(s.buyoutPrice or 0))
				end
				if s.AHLocation then who = L["Goblin AH"] .. "\n" .. who end
				row.who:SetText(who)
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
