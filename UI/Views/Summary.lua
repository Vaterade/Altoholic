-- Account Summary > Characters: one line per character, a total per realm.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local WHITE = "|cFFFFFFFF"

local view = {}

function view:Create(frame)
	self.table = W.Table(frame, {
		{ title = L["Name"], width = 110 },
		{ title = L["Level"], width = 40, justify = "RIGHT" },
		{ title = "", width = 130 },
		{ title = L["Talents"], width = 70, justify = "CENTER" },
		{ title = L["Money"], width = 130, justify = "RIGHT" },
		{ title = L["Played"], width = 100, justify = "RIGHT" },
		{ title = L["Rest XP"], justify = "RIGHT" },
	})
end

local function Rested(ref, c)
	if c.level >= 60 then return "" end
	local logout = UI.IsPlayer(ref) and 0 or c.lastlogout
	return Altoholic:GetRestedXP(c.level, c.restxp, logout, c.isResting)
end

function view:Update()
	local data = {}
	local levels, money, played, realms = 0, 0, 0, 0
	for _, realm in ipairs(UI.Realms()) do
		realms = realms + 1
		table.insert(data, { header = realm.name })
		local rLevels, rMoney, rPlayed = 0, 0, 0
		for _, ref in ipairs(realm.chars) do
			local c = ref.c
			local hex = UI.ClassHex(c.class)
			table.insert(data, {
				cells = {
					hex .. ref.name,
					"|cff00ff00" .. c.level,
					hex .. c.race .. " " .. c.class,
					c.talent,
					Altoholic:GetMoneyString(c.money),
					Altoholic:GetTimeString(c.played),
					Rested(ref, c),
				},
				onEnter = function(row) UI.CharacterTooltip(row, ref) end,
				onClick = function() UI.Open("containers", ref.realm .. "/" .. ref.name) end,
			})
			rLevels, rMoney, rPlayed = rLevels + c.level, rMoney + c.money, rPlayed + c.played
		end
		table.insert(data, { total = true, cells = {
			L["Totals"], WHITE .. rLevels, "", "",
			Altoholic:GetMoneyString(rMoney, WHITE), Altoholic:GetTimeString(rPlayed), "",
		} })
		levels, money, played = levels + rLevels, money + rMoney, played + rPlayed
	end
	if realms > 1 then
		table.insert(data, { header = L["Account"] })
		table.insert(data, { total = true, cells = {
			L["Totals"], WHITE .. levels, "", "",
			Altoholic:GetMoneyString(money, WHITE), Altoholic:GetTimeString(played), "",
		} })
	end
	self.table:SetData(data, true)
end

UI.RegisterView("Summary", view)
