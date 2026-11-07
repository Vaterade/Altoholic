-- Account Summary > Skills: each character's professions and secondary skills. Hover a
-- skill for its rank, a suggestion where to level it, and its cooldowns.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI
local Professions = Altoholic.Professions

local view = {}

local function Skill(c, category, name)
	local cat = rawget(rawget(c, "skill") or {}, category)
	return Altoholic:GetSkillInfo(cat and rawget(cat, name))
end

local function Rank(rank)
	if not rank or rank == 0 then return "|cff555555-" end
	return Altoholic:GetSkillColor(rank) .. rank
end

-- the columns after the name: what each shows, by category and skill name
local function Secondary()
	return {
		{ L["Secondary Skills"], Professions["Cooking"] },
		{ L["Secondary Skills"], Professions["First Aid"] },
		{ L["Secondary Skills"], Professions["Fishing"] },
		{ L["Secondary Skills"], L["Riding"] },
		{ L["Secondary Skills"], L["Survival"] },
	}
end

function view:Create(frame)
	self.table = W.Table(frame, {
		{ title = L["Name"], width = 110 },
		{ title = L["Prof. 1"], width = 120 },
		{ title = L["Prof. 2"], width = 120 },
		{ title = Professions["Cooking"], width = 64, justify = "CENTER" },
		{ title = Professions["First Aid"], width = 64, justify = "CENTER" },
		{ title = Professions["Fishing"], width = 64, justify = "CENTER" },
		{ title = L["Riding"], width = 64, justify = "CENTER" },
		{ title = L["Survival"], justify = "CENTER" },
	})
end

local function Tooltip(row, ref, skills, col)
	local s = skills[col - 1]
	if col < 2 then UI.CharacterTooltip(row, ref) return end
	if not s or not s.name then return end
	local rank, maxRank = Skill(ref.c, s.category, s.name)
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine(s.name, 1, 1, 1)
	GameTooltip:AddLine(Altoholic:GetSkillColor(rank) .. rank .. "/" .. maxRank)
	local suggestion = Altoholic:GetSuggestion(s.name, rank)
	if suggestion then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Suggestion"] .. ":", 1, 1, 1)
		GameTooltip:AddLine(suggestion, .2, 1, .8, true)
	end
	-- cooldowns, keyed "Tailoring-21845" = "seconds|when"
	local first = true
	for k, v in pairs(rawget(ref.c, "ProfessionCooldowns") or {}) do
		local skillName, itemID = strsplit("-", k)
		if skillName == s.name then
			local reset, lastcheck = strsplit("|", v)
			local left = tonumber(reset) - (time() - tonumber(lastcheck))
			if left > 0 then
				if first then GameTooltip:AddLine(" ") first = nil end
				GameTooltip:AddDoubleLine(GetItemInfo(tonumber(itemID)) or itemID, Altoholic:GetTimeString(left), 1, 1, 1, 1, 1, 1)
			end
		end
	end
	GameTooltip:Show()
end

function view:Update()
	local data = {}
	for _, realm in ipairs(UI.Realms()) do
		table.insert(data, { header = realm.name })
		for _, ref in ipairs(realm.chars) do
			local c = ref.c
			local skills = {}
			for name in pairs(rawget(rawget(c, "skill") or {}, L["Professions"]) or {}) do
				table.insert(skills, { category = L["Professions"], name = name })
			end
			table.sort(skills, function(a, b) return a.name < b.name end)
			local cells = { UI.ClassHex(c.class) .. ref.name }
			for i = 1, 2 do
				local s = skills[i] or {}
				skills[i] = s
				cells[i + 1] = s.name and (s.name .. " " .. Rank((Skill(c, s.category, s.name)))) or "|cff555555-"
			end
			for i, sec in ipairs(Secondary()) do
				skills[i + 2] = { category = sec[1], name = sec[2] }
				cells[i + 3] = Rank((Skill(c, sec[1], sec[2])))
			end
			table.insert(data, { cells = cells, onEnter = function(row, col) Tooltip(row, ref, skills, col) end })
		end
	end
	self.table:SetData(data, true)
end

UI.RegisterView("Skills", view)
