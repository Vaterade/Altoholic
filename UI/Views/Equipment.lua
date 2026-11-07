-- Equipment: a realm's characters side by side, a line per equipment slot. Right-click an
-- item to look for an upgrade in the loot tables.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local SIZE, GAP = 30, 4
local LABEL = 110
local COLUMNS = 16

local view = {}

local function FindUpgrade(item, role, title)
	UI.ShowSearchResults(Altoholic:FindUpgrade(item, role), title)
end

local function ItemMenu(button)
	local ref, item = button.ref, button.item
	local items = {}
	local _, link = GetItemInfo(Altoholic:GetItemString(item))
	for _, r in ipairs(Altoholic:UpgradeRoles(ref.c.class)) do
		table.insert(items, { text = r[1], func = function() FindUpgrade(item, r[2], link or "") end })
	end
	W.ShowMenu(button, items)
end

function view:Create(frame)
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
	holder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
	self.list = W.List(holder, SIZE + GAP,
		function(row)
			row.label = W.Text(row)
			row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
			row.label:SetWidth(LABEL - 6)
			row.cells = {}
			for i = 1, COLUMNS do
				local b = W.ItemButton(row, SIZE)
				b:SetPoint("LEFT", row, "LEFT", LABEL + (i - 1) * (SIZE + GAP), 0)
				row.cells[i] = b
			end
		end,
		function(row, line)
			for i = 1, COLUMNS do
				local b = row.cells[i]
				local ref = self.chars[i]
				b.ref = ref
				if not ref then
					b:Hide()
				elseif line.classes then
					-- the first line: who each column is
					local id = Altoholic.Classes[ref.c.class]
					b:SetItem(nil, nil, Altoholic.classicon)
					b.icon:SetAlpha(1)
					local tc = id and Altoholic.ClassInfo[id].texcoord
					if tc then b.icon:SetTexCoord(tc[1], tc[2], tc[3], tc[4]) end
					b.onEnter = function(btn) UI.CharacterTooltip(btn, btn.ref) end
					b.onClick = nil
					b:Show()
				else
					local item = (rawget(ref.c, "inventory") or {})[line.slot]
					b.onEnter = nil
					b:SetItem(item, nil, line.info.icon)
					if not item then b.icon:SetAlpha(.3) else b.icon:SetAlpha(1) end
					b.onTooltip = function(_, tip)
						tip:AddLine(UI.ClassHex(ref.c.class) .. ref.name)
						tip:AddLine("|cFF00FF00" .. L["Right-Click to find an upgrade"])
					end
					b.onClick = function(btn, button)
						if button == "RightButton" and btn.item then ItemMenu(btn) end
					end
					b:Show()
				end
			end
			if line.classes then
				row.label:SetText("")
			else
				row.label:SetText(line.info.color .. line.info.name)
			end
		end)
end

function view:Update(realmName)
	self.chars = {}
	for _, realm in ipairs(UI.Realms()) do
		if realm.name == realmName then
			for i = 1, math.min(COLUMNS, #realm.chars) do self.chars[i] = realm.chars[i] end
		end
	end
	local lines = { { classes = true } }
	for slot, info in ipairs(Altoholic.equipment) do
		table.insert(lines, { slot = slot, info = info })
	end
	self.list:SetData(lines, self.realm == realmName)
	self.realm = realmName
end

UI.RegisterView("Equipment", view)
