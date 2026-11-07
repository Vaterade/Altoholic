-- Missing Recipes: the recipes of a profession a character hasn't learned, from the recipe
-- database converted from LibCrafts-1.0 (Data/MissingRecipes.lua). Opened from the Recipes
-- page's bottom right corner, like Equipment's upgrade search; Known Recipes in the same
-- corner goes back. Hover a line for its reagents; the recipe item's icon has its tooltip.
-- With pfQuest loaded, that tooltip names the vendors, mobs and chests the recipe comes from
-- and their zones, and clicking the icon shows them on pfQuest's map (Data/Sources.lua).
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local view = {}
local onlyLearnable = false

local function SkillText(skill, rank)
	if skill <= rank then return "|cff00ff00" .. skill end	-- can learn it now
	return "|cffff5555" .. skill
end

local function Tooltip(row)
	local m = row.item
	if not m then return end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine(m.name, 1, 1, 1)
	GameTooltip:AddLine(L["Skill"] .. ": " .. m.skill, .8, .8, .8)
	if m.level then GameTooltip:AddLine(format(L["Requires level %d"], m.level), .8, .8, .8) end
	if m.how ~= "" then GameTooltip:AddLine(m.how, .2, 1, .8, true) end
	local reagents = Altoholic:ParseReagents(m.reagents)
	if #reagents > 0 then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Reagents"] .. ":", 1, 1, 1)
		for _, r in ipairs(reagents) do
			local name = (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(r[1])) or GetItemInfo(r[1]) or ("item:" .. r[1])
			GameTooltip:AddLine(r[2] .. " x " .. name, .8, .8, .8)
		end
	end
	GameTooltip:Show()
end

function view:Create(frame)
	self.title = W.Text(frame, W.FontSize() + 1)
	self.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -10)
	self.only = W.Checkbox(frame, L["Only what can be learned at this skill"], function(_, on)
		onlyLearnable = on
		self:Update(self.args)
	end)
	self.only:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -230, -9)

	local back = W.Button(frame, L["Known Recipes"], 120, 22, function()
		UI.ShowView("Recipes", self.args)
	end)
	back:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 8)

	local holder = CreateFrame("Frame", nil, frame)
	holder:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -32)
	holder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 36)
	self.list = W.List(holder, 26,
		function(row)
			row.skill = W.Text(row, nil, "RIGHT")
			row.skill:SetPoint("LEFT", row, "LEFT", 0, 0)
			row.skill:SetWidth(32)
			row.icon = W.ItemButton(row, 22)
			row.icon:SetPoint("LEFT", row, "LEFT", 40, 0)
			row.name = W.Text(row)
			row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
			row.name:SetWidth(230)
			row.how = W.Text(row)
			row.how:SetPoint("LEFT", row.name, "RIGHT", 8, 0)
			row.how:SetPoint("RIGHT", row, "RIGHT", -64, 0)
			row.how:SetTextColor(.7, .7, .7)
			row.recipes = {}
			for i = 1, 2 do
				local b = W.ItemButton(row, 22)
				b:SetPoint("RIGHT", row, "RIGHT", -4 - (i - 1) * 26, 0)
				row.recipes[i] = b
			end
			row.hl = row:CreateTexture(nil, "HIGHLIGHT")
			row.hl:SetAllPoints(row)
			row.hl:SetColorTexture(1, 1, 1, .05)
			row:SetScript("OnEnter", Tooltip)
			row:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end,
		function(row, m)
			row.skill:SetText(SkillText(m.skill, self.rank))
			row.icon:SetItem(m.item, nil, not m.item and "Interface\\Icons\\Trade_Engraving" or nil)
			local hex = "|cFFFFFFFF"
			if m.item then
				local _, _, q = GetItemInfo(m.item)
				if q then
					local _, _, _, h = GetItemQualityColor(q)
					hex = h or hex
				end
			end
			row.name:SetText(hex .. m.name)
			row.how:SetText(m.how)
			for i = 1, 2 do
				local r, b = m.recipes[i], row.recipes[i]
				if r then
					b:SetItem(r.id)
					b.onTooltip = function(_, tip)
						tip:AddLine(" ")
						-- pfQuest knows who sells or drops it, and where; else just the kind of source
						if not Altoholic:AddItemSources(tip, r.id) then
							tip:AddLine(r.sources, .2, 1, .8, true)
						end
						if Altoholic:HasItemSources() then
							tip:AddLine(L["Click to show on the map"], .2, 1, .8)
						end
					end
					b.onClick = function()
						if not Altoholic:ShowItemOnMap(r.id) and Altoholic:HasItemSources() then
							DEFAULT_CHAT_FRAME:AddMessage(W.TEAL_HEX .. "Altoholic:|r " .. L["pfQuest knows no place for this recipe"])
						end
					end
					b:Show()
				else
					b:Hide()
				end
			end
		end)
	self.message = W.Message(holder)
end

function view:Update(args)
	self.args = args
	local c = UI.Char(args)
	self.rank = Altoholic:ProfessionRank(c, args.profession)
	local missing, total = Altoholic:MissingRecipes(c, args.profession)
	missing = missing or {}
	local shown = missing
	if onlyLearnable then
		shown = {}
		for _, m in ipairs(missing) do
			if m.skill <= self.rank then table.insert(shown, m) end
		end
	end
	self.only:SetChecked(onlyLearnable)
	self.title:SetText(format(L["%s: %d of %d recipes missing"],
		UI.ClassHex(c.class) .. args.name .. "|r " .. args.profession .. " " .. Altoholic:GetSkillColor(self.rank) .. self.rank .. "|r",
		#missing, total or 0))
	self.list:SetData(shown, self.key == args.name .. args.profession)
	self.key = args.name .. args.profession
	if not total then
		self.message:SetText(L["Altoholic has no recipe list for this profession."])
		self.message:Show()
	elseif #shown == 0 then
		self.message:SetText(#missing == 0 and L["Every recipe is known."] or L["Nothing more to learn at this skill."])
		self.message:Show()
	else
		self.message:Hide()
	end
end

UI.RegisterView("MissingRecipes", view)
