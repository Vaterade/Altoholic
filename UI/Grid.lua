-- A realm's characters side by side: a line of class icons, then a line per thing being
-- compared (a faction, an attunement). Used by Reputations and Attunements.
--
--   grid = UI.CharacterGrid(frame, labelWidth)
--   grid:SetData(chars, lines)
--     chars: refs from UI.Realms()
--     lines: { header = "text" } or { label = "text", cell = fn(ref) -> text, r, g, b,
--              onEnter = fn(button, ref), onClick = fn(button, ref, mouseButton) }
-- A view showing a grid puts a realm picker in its bar with UI.RealmPicker(bar, onPick).
local W = Altoholic.W
local UI = Altoholic.UI

local CELL, GAP = 34, 3

function UI.CharacterGrid(frame, labelWidth)
	labelWidth = labelWidth or 160
	local grid = {}
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
	holder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
	local columns = math.max(1, math.floor(((frame:GetWidth() or 686) - labelWidth - 30) / (CELL + GAP)))
	columns = math.min(columns, 14)
	grid.columns = columns

	grid.list = W.List(holder, 22,
		function(row)
			row.label = W.Text(row)
			row.label:SetPoint("LEFT", row, "LEFT", 4, 0)
			row.label:SetWidth(labelWidth - 8)
			row.cells = {}
			for i = 1, columns do
				local b = CreateFrame("Button", nil, row)
				b:SetWidth(CELL)
				b:SetHeight(20)
				b:SetPoint("LEFT", row, "LEFT", labelWidth + (i - 1) * (CELL + GAP), 0)
				b.text = W.Text(b, nil, "CENTER")
				b.text:SetAllPoints(b)
				b.icon = b:CreateTexture(nil, "ARTWORK")
				b.icon:SetPoint("CENTER", b, "CENTER", 0, 0)
				b.icon:SetWidth(20)
				b.icon:SetHeight(20)
				b.hl = b:CreateTexture(nil, "HIGHLIGHT")
				b.hl:SetAllPoints(b)
				b.hl:SetColorTexture(1, 1, 1, .1)
				b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				b:SetScript("OnEnter", function(self)
					local line = self:GetParent().item
					if not line or not self.ref then return end
					if line.classes then
						UI.CharacterTooltip(self, self.ref)
					elseif line.onEnter then
						line.onEnter(self, self.ref)
					end
				end)
				b:SetScript("OnLeave", function() GameTooltip:Hide() end)
				b:SetScript("OnClick", function(self, button)
					local line = self:GetParent().item
					if line and line.onClick and self.ref then line.onClick(self, self.ref, button) end
				end)
				row.cells[i] = b
			end
		end,
		function(row, line)
			if line.header then
				row.label:SetText(W.TEAL_HEX .. line.header)
			else
				row.label:SetText(line.label or "")
			end
			for i = 1, columns do
				local b, ref = row.cells[i], grid.chars[i]
				b.ref = ref
				if not ref or line.header then
					b:Hide()
				elseif line.classes then
					local id = Altoholic.Classes[ref.c.class]
					local tc = id and Altoholic.ClassInfo[id].texcoord
					b.icon:SetTexture(Altoholic.classicon)
					if tc then b.icon:SetTexCoord(tc[1], tc[2], tc[3], tc[4]) end
					b.icon:Show()
					b.text:SetText("")
					b:Show()
				else
					b.icon:Hide()
					local text, r, g, bl = line.cell(ref)
					b.text:SetText(text or "")
					b.text:SetTextColor(r or 1, g or 1, bl or 1)
					b:Show()
				end
			end
		end)

	function grid:SetData(chars, lines, keepOffset)
		self.chars = {}
		for i = 1, math.min(columns, #chars) do self.chars[i] = chars[i] end
		local all = { { classes = true } }
		for _, l in ipairs(lines) do table.insert(all, l) end
		self.list:SetData(all, keepOffset)
	end
	return grid
end

-- a dropdown of the realms, starting on the logged-in character's; onPick(realm) where
-- realm is an entry of UI.Realms(). Hidden while there is only one realm.
function UI.RealmPicker(bar, onPick)
	local picker = W.Dropdown(bar, 160, function()
		local items = {}
		for _, r in ipairs(UI.Realms()) do table.insert(items, { text = r.name, value = r.name }) end
		return items
	end, function(_, value)
		for _, r in ipairs(UI.Realms()) do
			if r.name == value then onPick(r) end
		end
	end)
	picker:SetPoint("LEFT", bar, "LEFT", 0, 0)
	-- the realm to show: the one picked, if it still exists, else the first
	function picker:Current()
		local realms = UI.Realms()
		if #realms > 1 then self:Show() else self:Hide() end
		for _, r in ipairs(realms) do
			if r.name == self.value then return r end
		end
		if realms[1] then self:SetValue(realms[1].name) end
		return realms[1]
	end
	return picker
end
