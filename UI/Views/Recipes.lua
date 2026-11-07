-- Recipes: what a character can make with one profession, by the window's headers, with
-- the reagents each recipe takes. Headers fold on click.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local REAGENTS = 8
local SIZE = 18

local view = {}
local folded = {}		-- headers folded this session, by profession and name

-- "itemID:count|itemID:count|..." (see Data/Professions.lua)
local function Reagents(s)
	local list = {}
	for id, count in string.gmatch(s or "", "(%d+):(%d+)") do
		table.insert(list, { tonumber(id), tonumber(count) })
	end
	return list
end
UI.ParseReagents = Reagents

local function RecipeTooltip(row)
	local r = row.item and row.item.recipe
	if not r then return end
	local link
	if r.link and string.find(r.link, "enchant:", 1, true) and not r.id then
		link = string.match(r.link, "(enchant:%d+)")
	elseif r.id then
		link = "item:" .. r.id .. ":0:0:0"
	end
	if not link then return end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:SetHyperlink(link)
	GameTooltip:Show()
end

function view:Create(frame, bar)
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
	holder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
	self.list = W.List(holder, 22,
		function(row)
			row.text = W.Text(row)
			row.text:SetPoint("LEFT", row, "LEFT", 4, 0)
			row.text:SetWidth(300)
			row.reagents = {}
			for i = 1, REAGENTS do
				local b = W.ItemButton(row, SIZE)
				b:SetPoint("LEFT", row, "LEFT", 320 + (i - 1) * (SIZE + 6), 0)
				b.count:SetFont(W.FontPath(), 9, "OUTLINE")
				row.reagents[i] = b
			end
			row.hl = row:CreateTexture(nil, "HIGHLIGHT")
			row.hl:SetAllPoints(row)
			row.hl:SetColorTexture(1, 1, 1, .05)
			row:SetScript("OnEnter", RecipeTooltip)
			row:SetScript("OnLeave", function() GameTooltip:Hide() end)
			row:SetScript("OnClick", function(r)
				local line = r.item
				if not line then return end
				if line.header then
					local key = self.args.profession .. "/" .. line.header
					folded[key] = not folded[key]
					self:Update(self.args)
				elseif line.recipe.link and IsShiftKeyDown() then
					if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
						ChatFrameEditBox:Insert(line.recipe.link)
					elseif WIM_EditBoxInFocus then
						WIM_EditBoxInFocus:Insert(line.recipe.link)
					end
				end
			end)
		end,
		function(row, line)
			if line.header then
				local sign = folded[self.args.profession .. "/" .. line.header] and "+ " or "- "
				row.text:SetText("|cff888888" .. sign .. W.TEAL_HEX .. line.header)
				for i = 1, REAGENTS do row.reagents[i]:Hide() end
				return
			end
			row.text:SetText("   " .. (line.recipe.link or line.recipe.name or ""))
			local reagents = Reagents(line.recipe.reagents)
			for i = 1, REAGENTS do
				local b, rg = row.reagents[i], reagents[i]
				if rg then
					b:SetItem(rg[1], rg[2])
					b.count:SetText(rg[2] > 1 and rg[2] or "")
					b:Show()
				else
					b:Hide()
				end
			end
		end)
	self.message = W.Message(holder)
	self.status = W.Text(bar)
	self.status:SetPoint("LEFT", bar, "LEFT", 4, 0)
	self.status:SetTextColor(.7, .7, .7)
	self.bar = bar
end

-- the rank in the profession, coloured as the old window did
local function Level(c, profession)
	for _, category in pairs(rawget(c, "skill") or {}) do
		local s = type(category) == "table" and rawget(category, profession)
		if s then
			local rank, maxRank = strsplit("|", s)
			return Altoholic:GetSkillColor(tonumber(rank)) .. rank .. "/" .. (maxRank or "?")
		end
	end
	return ""
end

function view:Update(args)
	self.args = args
	local c = UI.Char(args)
	local p = rawget(rawget(c, "recipes") or {}, args.profession)
	local lines = {}
	local header
	if p and not p.ScanFailed then
		local list = UI.Array(rawget(p, "list"))
		for i = 1, #list do
			local s = list[i]
			if s.isHeader then
				header = s.name
				table.insert(lines, { header = header })
			elseif not (header and folded[args.profession .. "/" .. header]) then
				table.insert(lines, { recipe = s, index = i })
			end
		end
		self.message:Hide()
	else
		self.message:SetText(L["No data: "] .. args.profession .. L[" scan failed for "] .. args.name)
		self.message:Show()
	end
	self.lines = lines
	self.list:SetData(lines, self.key == args.name .. args.profession)
	self.key = args.name .. args.profession
	self.status:SetText(UI.ClassHex(c.class) .. args.name .. "|r  " .. args.profession .. " " .. Level(c, args.profession))
	if self.OnUpdated then self:OnUpdated(args, c) end
end

UI.RegisterView("Recipes", view)
