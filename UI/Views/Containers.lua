-- Containers: a character's bags, keyring, bank and bank bags, one line of slots each
-- (a bag bigger than a line continues on the next). The bag's icon starts its first line.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local SLOTS = 16		-- per line
local SIZE, GAP = 32, 4

-- in the order they are listed: bags, keyring, bank, bank bags
local ORDER = { 0, 1, 2, 3, 4, -2, 100, 5, 6, 7, 8, 9, 10 }

local function BagTooltip(self)
	local bagID, b = self.bagID, self.bag
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if bagID == -2 then
		GameTooltip:AddLine(KEYRING, 1, 1, 1)
	elseif bagID == 0 then
		GameTooltip:AddLine(BACKPACK_TOOLTIP, 1, 1, 1)
	elseif bagID == 100 then
		GameTooltip:AddLine(L["Bank"], .5, .5, 1)
	elseif b.link then
		GameTooltip:SetHyperlink(Altoholic:GetItemString(b.link))
	end
	if bagID >= 5 and bagID <= 10 then
		GameTooltip:AddLine(L["Bank bag"], 0, 1, 0)
	end
	GameTooltip:AddLine(format(CONTAINER_SLOTS, b.size or 0, BAGSLOT), .6, .6, .6)
	GameTooltip:Show()
end

local view = {}

function view:Create(frame, bar)
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
	holder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
	self.list = W.List(holder, SIZE + GAP,
		function(row)
			row.bagIcon = W.ItemButton(row, SIZE)
			row.bagIcon:SetPoint("LEFT", row, "LEFT", 0, 0)
			row.bagIcon.onEnter = BagTooltip
			row.slots = {}
			for i = 1, SLOTS do
				local s = W.ItemButton(row, SIZE)
				s:SetPoint("LEFT", row, "LEFT", SIZE + 12 + (i - 1) * (SIZE + GAP), 0)
				row.slots[i] = s
			end
		end,
		function(row, line)
			local b = line.bag
			if line.from == 1 then
				row.bagIcon.bagID, row.bagIcon.bag = line.bagID, b
				row.bagIcon:SetItem(nil, nil, b.icon or "Interface\\Icons\\INV_Box_03")
				row.bagIcon:Show()
			else
				row.bagIcon:Hide()
			end
			for i = 1, SLOTS do
				local slot = line.from + i - 1
				local s = row.slots[i]
				if slot <= b.size then
					local ids, counts, links = rawget(b, "ids") or {}, rawget(b, "counts") or {}, rawget(b, "links") or {}
					s:SetItem(links[slot] or ids[slot], counts[slot])
					s:Show()
				else
					s:Hide()
				end
			end
		end)
	self.summary = W.Text(bar)
	self.summary:SetPoint("LEFT", bar, "LEFT", 4, 0)
	self.summary:SetTextColor(.7, .7, .7)
end

function view:Update(ref)
	local c = UI.Char(ref)
	local bags = rawget(c, "bag") or {}
	local lines, slots, free = {}, 0, 0
	for _, bagID in ipairs(ORDER) do
		local b = rawget(bags, "Bag" .. bagID)
		if b and (b.size or 0) > 0 then
			for from = 1, b.size, SLOTS do
				table.insert(lines, { bagID = bagID, bag = b, from = from })
			end
			if bagID >= 0 and bagID <= 4 then
				slots, free = slots + b.size, free + (b.freeslots or 0)
			end
		end
	end
	self.list:SetData(lines, self.ref == ref)
	self.ref = ref
	local text = UI.ClassHex(c.class) .. ref.name .. "|r  " .. format(L["%d of %d bag slots free"], free, slots)
	if not rawget(bags, "Bag100") then text = text .. "  |cff888888" .. L["Bank not visited yet"] end
	self.summary:SetText(text)
end

UI.RegisterView("Containers", view)
