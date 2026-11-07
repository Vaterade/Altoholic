-- Account Summary > Raids: each character's raid lockouts, the instance ID while it lasts.
-- Per realm, a line says when each raid next resets, and a total counts the lockouts.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local WHITE, GREEN, RED, ORANGE = "|cFFFFFFFF", "|cFF00FF00", "|cFFFF0000", "|cFFFF7F00"

-- abbreviation, and the start of the name GetSavedInstanceInfo gives
local RAIDS = {
	{ "K10", "Lower" }, { "ZG", "Zul'Gurub" }, { "AQ20", "Ruins" }, { "MC", "Molten" }, { "Ony", "Onyxia" },
	{ "BWL", "Blackw" }, { "ES", "Emerald" }, { "AQ40", "Ahn'Qir" }, { "Naxx", "Naxxram" }, { "K40", "Upper" },
}

-- When raid i resets on a realm: a reset it is known to have had, and the days between.
-- Turtle's schedules; Nordanaar's differs, every other realm follows Tel'Abim's.
local function Schedule(realm, i)
	local base = 1663128000
	if realm == "Nordanaar" then
		if i == 1 then return base - 86400, 5 end
		if i == 2 or i == 3 then return base - 2 * 86400, 3 end
		if i == 5 then return base - 2 * 86400, 5 end
		return base, 7
	end
	if i == 1 then return base + 2 * 86400, 5 end
	if i == 2 or i == 3 then return base - 86400, 3 end
	if i == 5 then return base + 2 * 86400, 5 end
	return base + 86400, 7
end

local function NextReset(realm, i)
	local base, days = Schedule(realm, i)
	local now = time()
	local last = base + math.floor((now - base) / (days * 86400)) * days * 86400
	return last, last + days * 86400
end

-- the lockouts a character has for raid i: { { name, id, left } }
local function Lockouts(c, i)
	local out = {}
	local prefix = RAIDS[i][2]
	for name, info in pairs(rawget(c, "SavedInstance") or {}) do
		if string.sub(name, 1, string.len(prefix)) == prefix then
			local id, reset, lastcheck = strsplit("|", info)
			table.insert(out, { name = name, id = id, left = tonumber(reset) - (time() - tonumber(lastcheck)) })
		end
	end
	return out
end

local view = {}

function view:Create(frame)
	local columns = { { title = L["Name"], width = 120 } }
	for i, r in ipairs(RAIDS) do
		columns[i + 1] = { title = r[1], width = i < #RAIDS and 54 or nil, justify = "CENTER" }
	end
	self.table = W.Table(frame, columns)
end

local function Short(seconds)
	local d = math.floor(seconds / 86400)
	local h = math.floor((seconds % 86400) / 3600)
	if d > 0 then return d .. "d " .. h .. "h" end
	return h .. "h " .. math.floor((seconds % 3600) / 60) .. "m"
end

function view:Update()
	local data = {}
	for _, realm in ipairs(UI.Realms()) do
		table.insert(data, { header = realm.name })
		local resets = { "|cff888888" .. L["Next reset"] }
		for i = 1, #RAIDS do
			local _, nextReset = NextReset(realm.name, i)
			resets[i + 1] = "|cff888888" .. Short(nextReset - time())
		end
		table.insert(data, { cells = resets, onEnter = function(row, col)
			if col < 2 then return end
			local last, nextReset = NextReset(realm.name, col - 1)
			GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
			GameTooltip:AddLine(RAIDS[col - 1][1], 1, 1, 1)
			GameTooltip:AddLine("Last reset: " .. Altoholic:GetTimeString(time() - last) .. " ago")
			GameTooltip:AddLine("Next reset: in " .. Altoholic:GetTimeString(nextReset - time()))
			GameTooltip:AddLine("Next reset date: " .. ORANGE .. date("%A, %H:%M", nextReset))
			GameTooltip:Show()
		end })
		local totals = { L["Totals"] }
		for i = 1, #RAIDS do totals[i + 1] = 0 end
		for _, ref in ipairs(realm.chars) do
			local cells = { UI.ClassHex(ref.c.class) .. ref.name }
			for i = 1, #RAIDS do
				local text = "|cff555555-"
				for _, lock in ipairs(Lockouts(ref.c, i)) do
					if lock.left > 0 then
						text = WHITE .. lock.id
						totals[i + 1] = totals[i + 1] + 1
					end
				end
				cells[i + 1] = text
			end
			table.insert(data, { cells = cells, onEnter = function(row, col)
				if col < 2 then UI.CharacterTooltip(row, ref) return end
				local locks = Lockouts(ref.c, col - 1)
				if #locks == 0 then return end
				GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
				for _, lock in ipairs(locks) do
					GameTooltip:AddLine(lock.name, 1, 1, 1)
					if lock.left > 0 then
						GameTooltip:AddLine("Expires in " .. RED .. Altoholic:GetTimeString(lock.left))
					else
						GameTooltip:AddLine("Expired " .. GREEN .. Altoholic:GetTimeString(-lock.left) .. WHITE .. " ago")
					end
				end
				GameTooltip:Show()
			end })
		end
		for i = 1, #RAIDS do
			totals[i + 1] = totals[i + 1] > 0 and (WHITE .. totals[i + 1]) or ""
		end
		table.insert(data, { total = true, cells = totals })
	end
	self.table:SetData(data, true)
end

UI.RegisterView("Raids", view)
