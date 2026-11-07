-- Account Summary > Characters: one line per character, a total per realm.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local WHITE = "|cFFFFFFFF"

local view = {}

function view:Create(frame)
	self.table = W.Table(frame, {
		{ title = L["Name"], width = 100 },
		{ title = L["Level"], width = 40, justify = "RIGHT" },
		{ title = "", width = 115 },
		{ title = L["Talents"], width = 60, justify = "CENTER" },
		{ title = L["Money"], width = 115, justify = "RIGHT" },
		{ title = L["Played"], width = 85, justify = "RIGHT" },
		{ title = L["Last Played"], width = 75, justify = "RIGHT" },
		{ title = L["Rest XP"], justify = "RIGHT" },
	})
end

-- when the character was last logged out: "online" for the one playing now
local function LastPlayed(ref, c)
	if UI.IsPlayer(ref) then return "|cff00ff00" .. L["Online"] end
	if not c.lastlogout or c.lastlogout == 0 then return "|cff555555-" end
	local days = Altoholic:GetDelayInDays(c.lastlogout)
	if days == 0 then return L["Today"] end
	if days == 1 then return L["1 day ago"] end
	return format(L["%d days ago"], days)
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
					LastPlayed(ref, c),
					Rested(ref, c),
				},
				onEnter = function(row) UI.CharacterTooltip(row, ref) end,
				onClick = function(row, button)
					if button == "RightButton" then
						view:Menu(row, ref)
					else
						UI.Open("containers", ref.realm .. "/" .. ref.name)
					end
				end,
			})
			rLevels, rMoney, rPlayed = rLevels + c.level, rMoney + c.money, rPlayed + c.played
		end
		table.insert(data, { total = true, cells = {
			L["Totals"], WHITE .. rLevels, "", "",
			Altoholic:GetMoneyString(rMoney, WHITE), Altoholic:GetTimeString(rPlayed), "", "",
		} })
		levels, money, played = levels + rLevels, money + rMoney, played + rPlayed
	end
	if realms > 1 then
		table.insert(data, { header = L["Account"] })
		table.insert(data, { total = true, cells = {
			L["Totals"], WHITE .. levels, "", "",
			Altoholic:GetMoneyString(money, WHITE), Altoholic:GetTimeString(played), "", "",
		} })
	end
	self.table:SetData(data, true)
end

-- right-click on a character: open one of their pages, or forget them
function view:Menu(row, ref)
	local key = ref.realm .. "/" .. ref.name
	local items = {
		{ text = L["View bags"], func = function() UI.Open("containers", key) end },
		{ text = L["View mailbox"], func = function() UI.Open("mail", key) end },
		{ text = L["View quest log"], func = function() UI.Open("quests", key) end },
		{ text = L["View auctions"], func = function() UI.Open("auctions", key) end },
		{ text = L["View bids"], func = function() UI.Open("bids", key) end },
		{ text = L["Notes"], func = function() UI.Open("notes", key) end },
	}
	if not UI.IsPlayer(ref) then
		table.insert(items, { text = "|cffff5555" .. L["Delete this Alt"], func = function()
			W.ShowMenu(row, {
				{ text = format(L["Forget %s and everything saved about them?"], UI.ClassHex(ref.c.class) .. ref.name .. "|r") },
				{ text = "|cffff5555" .. L["Delete"], func = function()
					if Altoholic:DeleteCharacter(ref.faction, ref.realm, ref.name) then
						DEFAULT_CHAT_FRAME:AddMessage(W.TEAL_HEX .. "Altoholic: |r" .. L["Character "] .. ref.name .. L[" successfully deleted"])
						view:Update()
					end
				end },
				{ text = CANCEL or "Cancel" },
			})
		end })
	end
	W.ShowMenu(row, items)
end

UI.RegisterView("Summary", view)
