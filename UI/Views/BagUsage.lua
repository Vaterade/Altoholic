-- Account Summary > Bag Usage: each character's bag and bank slots. Hover them for the
-- bags themselves and what is free.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local GOLD, GREEN, YELLOW, CYAN = "|cFFFFD700", "|cFF00FF00", "|cFFFFFF00", "|cFF1CFAFE"

local view = {}

function view:Create(frame)
	self.table = W.Table(frame, {
		{ title = L["Name"], width = 110 },
		{ title = L["Level"], width = 170 },
		{ title = L["Bags"], width = 190 },
		{ title = L["Bank"] },
	})
end

local function BagLine(size, free, what)
	return GOLD .. size .. " |r" .. L["slots"] .. " (" .. GREEN .. free .. "|r " .. L["free"] .. ") " .. what
end

local function Tooltip(row, ref, col)
	if col < 3 then UI.CharacterTooltip(row, ref) return end
	local c = ref.c
	local bags = rawget(c, "bag") or {}
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine(UI.ClassHex(c.class) .. ref.name)
	local first, from, to, base
	if col == 3 then
		first, from, to, base = bags.Bag0, 1, 4, "[" .. BACKPACK_TOOLTIP .. "]"
	else
		first, from, to, base = rawget(bags, "Bag100"), 5, 10, "[" .. L["Bank"] .. "]"
		if not first then
			GameTooltip:AddLine(L["Bank not visited yet"], 1, 1, 1)
			GameTooltip:Show()
			return
		end
	end
	local slots, free = 0, 0
	if first then
		GameTooltip:AddLine(BagLine(first.size or 0, first.freeslots or 0, base), 1, 1, 1)
		slots, free = first.size or 0, first.freeslots or 0
	end
	for i = from, to do
		local b = rawget(bags, "Bag" .. i)
		if b and b.link then
			local kind = Altoholic:GetBagTypeString(b.link)
			GameTooltip:AddLine(BagLine(b.size, b.freeslots or 0, b.link .. (kind and (" " .. YELLOW .. "(" .. kind .. ")") or "")), 1, 1, 1)
			slots, free = slots + b.size, free + (b.freeslots or 0)
		end
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(CYAN .. slots .. " |r" .. L["slots"] .. " (" .. GREEN .. free .. "|r " .. L["free"] .. ")", 1, 1, 1)
	GameTooltip:Show()
end

function view:Update()
	local data = {}
	for _, realm in ipairs(UI.Realms()) do
		table.insert(data, { header = realm.name })
		for _, ref in ipairs(realm.chars) do
			local c = ref.c
			local hex = UI.ClassHex(c.class)
			local bank = (c.bankslots and c.bankslots ~= "") and c.bankslots or ("|cff888888" .. L["Bank not visited yet"])
			table.insert(data, {
				cells = { hex .. ref.name, hex .. "Lv |cFF00FF00" .. c.level .. hex .. " " .. c.race .. " " .. c.class, c.bags or "", bank },
				onEnter = function(row, col) Tooltip(row, ref, col) end,
			})
		end
	end
	self.table:SetData(data, true)
end

UI.RegisterView("BagUsage", view)
