-- Quests: a character's quest log as last seen, under its zone headers (which fold on
-- click). Hover a quest for its objectives and the alts who are on it too.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local GREEN, RED = "|cFF00FF00", "|cFFFF0000"

local view = {}
local folded = {}

local function Tooltip(row)
	local line = row.item
	if not line or not line.quest then return end
	local q, ref = line.quest, view.args
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine(q.title or q.name or "", 1, 1, 1)
	if q.questObjectives then GameTooltip:AddLine(q.questObjectives, 1, 1, 1, true) end
	local first = true
	for _, realm in ipairs(UI.Realms()) do
		if realm.name == ref.realm then
			for _, other in ipairs(realm.chars) do
				if other.name ~= ref.name then
					for _, oq in pairs(rawget(other.c, "questlog") or {}) do
						if type(oq) == "table" and not oq.isHeader and Altoholic:IsSameQuest(q, oq) then
							if first then
								GameTooltip:AddLine(" ")
								GameTooltip:AddLine(GREEN .. L["Are also on this quest:"])
								first = nil
							end
							GameTooltip:AddLine(UI.ClassHex(other.c.class) .. other.name)
							break
						end
					end
				end
			end
		end
	end
	GameTooltip:Show()
end

function view:Create(frame, bar)
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
	holder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
	self.list = W.List(holder, 20,
		function(row)
			row.text = W.Text(row)
			row.text:SetPoint("LEFT", row, "LEFT", 4, 0)
			row.text:SetWidth(330)
			row.tag = W.Text(row)
			row.tag:SetPoint("LEFT", row.text, "RIGHT", 8, 0)
			row.tag:SetWidth(90)
			row.status = W.Text(row)
			row.status:SetPoint("LEFT", row.tag, "RIGHT", 8, 0)
			row.status:SetWidth(70)
			row.money = W.Text(row, nil, "RIGHT")
			row.money:SetPoint("LEFT", row.status, "RIGHT", 8, 0)
			row.money:SetPoint("RIGHT", row, "RIGHT", -4, 0)
			row.hl = row:CreateTexture(nil, "HIGHLIGHT")
			row.hl:SetAllPoints(row)
			row.hl:SetColorTexture(1, 1, 1, .05)
			row:SetScript("OnEnter", Tooltip)
			row:SetScript("OnLeave", function() GameTooltip:Hide() end)
			row:SetScript("OnClick", function(r)
				local line = r.item
				if not line then return end
				if line.header then
					folded[line.header] = not folded[line.header]
					self:Update(self.args)
				elseif line.quest.link and IsShiftKeyDown() then
					if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
						ChatFrameEditBox:Insert(line.quest.link)
					elseif WIM_EditBoxInFocus then
						WIM_EditBoxInFocus:Insert(line.quest.link)
					end
				end
			end)
		end,
		function(row, line)
			if line.header then
				row.text:SetText("|cff888888" .. (folded[line.header] and "+ " or "- ") .. W.TEAL_HEX .. line.header)
				row.tag:SetText("")
				row.status:SetText("")
				row.money:SetText("")
				return
			end
			local q = line.quest
			row.text:SetText("   |cFFFFFFFF[" .. (q.level or "?") .. "] " .. (q.link or q.title or q.name or ""))
			row.tag:SetText(q.tag and Altoholic:GetQuestTypeString(q.tag, Altoholic:SuggestGroupSize(q.tag, q.level)) or "")
			if q.isComplete == 1 then
				row.status:SetText(GREEN .. COMPLETE)
			elseif q.isComplete == -1 then
				row.status:SetText(RED .. FAILED)
			else
				row.status:SetText("")
			end
			row.money:SetText(q.money and Altoholic:GetMoneyString(q.money) or "")
		end)
	self.message = W.Message(holder)
	self.status = W.Text(bar)
	self.status:SetPoint("LEFT", bar, "LEFT", 4, 0)
	self.status:SetTextColor(.7, .7, .7)
end

function view:Update(ref)
	self.args = ref
	local c = UI.Char(ref)
	local log = UI.Array(rawget(c, "questlog"))
	local lines, header, count = {}, nil, 0
	for i = 1, #log do
		local q = log[i]
		if q.isHeader then
			header = q.name
			table.insert(lines, { header = header })
		elseif not (header and folded[header]) then
			table.insert(lines, { quest = q })
			count = count + 1
		elseif not q.isHeader then
			count = count + 1
		end
	end
	self.list:SetData(lines, self.ref == ref)
	self.ref = ref
	if #log == 0 then
		self.message:SetText(L["No quests found"])
		self.message:Show()
	else
		self.message:Hide()
	end
	self.status:SetText(UI.ClassHex(c.class) .. ref.name .. "|r  " .. QUEST_LOG .. ": " .. count)
end

UI.RegisterView("Quests", view)
