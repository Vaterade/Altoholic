local BI = LibStub("LibBabble-Inventory-3.0"):GetLookupTable()
local L = Altoholic.L
local V = Altoholic.vars
local INFO_REALM_LINE = 1
local INFO_CHARACTER_LINE = 2
local INFO_TOTAL_LINE = 3
local WHITE		= "|cFFFFFFFF"
local TEAL		= "|cFF00FF9A"
local RED		= "|cFFFF0000"
local ORANGE	= "|cFFFF7F00"
local YELLOW	= "|cFFFFFF00"
local GREEN		= "|cFF00FF00"

-- sorted
local RaidNames = {
	"K10",
	"ZG",
	"AQ20",
	"MC",
	"Ony",
	"BWL",
	"ES",
	"AQ40",
	"Naxx",
	"K40",
}

-- map to raid info name
local RaidLongNames = { 
	["K10"]	 = "Lower",
	["ZG"]	 = "Zul'Gurub",
	["AQ20"] = "Ruins",
	["MC"]   = "Molten",
	["Ony"]  = "Onyxia",
	["BWL"]  = "Blackw",
	["ES"]   = "Emerald",
	["AQ40"] = "Ahn'Qir",
	["Naxx"] = "Naxxram",
	["K40"]  = "Upper",
}


local TotalLockouts = {}


-- we have already found the correct row, check times
local function raidid(info, abbr)
	-- DEFAULT_CHAT_FRAME:AddMessage(YELLOW .. "parsing " .. info)
	local id, reset, lastcheck = strsplit("|", info)
	reset = tonumber(reset)
	lastcheck = tonumber(lastcheck)
	local expiresIn = reset - (time() - lastcheck)
	if expiresIn > 0 then
		if TotalLockouts[abbr] == nil then 
			TotalLockouts[abbr] = 1
		else
			TotalLockouts[abbr] = TotalLockouts[abbr] + 1
		end
		return id
	else
		return GREEN .. "-"
	end
end	

-- check where the raid is in our table if at all
local function getraidid(instancelist, raidabbrev)
	for name, info in pairs(instancelist) do
		local longname = RaidLongNames[raidabbrev]
		if (string.sub(name, 1, string.len(longname)) == longname) then
			return raidid(info, raidabbrev)
		end
	end
	return "-"
end

function Altoholic:Raids_Update()
	local VisibleLines = 14
	local frame = "AltoRaids"
	local entry = frame.."Entry"
	if #self.CharacterInfo == 0 then
		self:ClearScrollFrame(_G[frame.."ScrollFrame"], entry, VisibleLines, 18)
		return
	end
	local offset = FauxScrollFrame_GetOffset(_G[frame.."ScrollFrame"]);
	local DisplayedCount = 0
	local VisibleCount = 0
	local DrawRealm
	local CurrentFaction, CurrentRealm
	local i=1
	TotalLockouts = {}
	for line, s in pairs(self.CharacterInfo) do
		if (offset > 0) or (DisplayedCount >= VisibleLines) then		-- if the line will not be visible
			if s.linetype == INFO_REALM_LINE then								-- then keep track of counters
				CurrentFaction = s.faction
				CurrentRealm = s.realm
				if s.isCollapsed == false then
					DrawRealm = true
				else
					DrawRealm = false
				end
				VisibleCount = VisibleCount + 1
				offset = offset - 1		-- no further control, nevermind if it goes negative
			elseif DrawRealm then
				VisibleCount = VisibleCount + 1
				offset = offset - 1		-- no further control, nevermind if it goes negative
			end
		else		-- line will be displayed
			for _, raidname in pairs(RaidNames) do
				_G[entry..i..raidname]:SetWidth(35)
			end

			if s.linetype == INFO_REALM_LINE then
				CurrentFaction = s.faction
				CurrentRealm = s.realm
				TotalLockouts = {}
				if s.isCollapsed == false then
					_G[entry..i.."Collapse"]:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up"); 
					DrawRealm = true
				else
					_G[entry..i.."Collapse"]:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
					DrawRealm = false
				end
				_G[entry..i.."Collapse"]:Show()
				_G[entry..i.."Name"]:SetText(self:GetFullRealmString(s.faction, s.realm))
				_G[entry..i.."Name"]:SetJustifyH("LEFT")
				_G[entry..i.."Name"]:SetPoint("TOPLEFT", 25, 0)
				_G[entry..i.."Name"]:SetWidth(100)

				for _, raidname in pairs(RaidNames) do
					_G[entry..i..raidname]:SetText(WHITE .. raidname)
				end

				_G[entry..i]:SetID(line)
				_G[entry..i]:Show()
				i = i + 1
				VisibleCount = VisibleCount + 1
				DisplayedCount = DisplayedCount + 1
			elseif DrawRealm then
				if (s.linetype == INFO_CHARACTER_LINE) then
					local c = self.db.account.data[CurrentFaction][CurrentRealm].char[s.name]
					local color = self:GetClassColor(c.class)
					_G[entry..i.."Collapse"]:Hide()
					_G[entry..i.."Name"]:SetText(color .. s.name)
					_G[entry..i.."Name"]:SetJustifyH("LEFT")
					_G[entry..i.."Name"]:SetPoint("TOPLEFT", 25, 0)
					_G[entry..i.."Name"]:SetWidth(100)
					for _, raidname in pairs(RaidNames) do
						_G[entry..i..raidname]:SetText(getraidid(c.SavedInstance, raidname))
					end
				elseif (s.linetype == INFO_TOTAL_LINE) then
					_G[entry..i.."Collapse"]:Hide()
					_G[entry..i.."Name"]:SetText(L["Totals"])
					_G[entry..i.."Name"]:SetJustifyH("LEFT")
					_G[entry..i.."Name"]:SetPoint("TOPLEFT", 25, 0)
					_G[entry..i.."Name"]:SetWidth(100)
					for _, raidname in pairs(RaidNames) do
						_G[entry..i..raidname]:SetText(TotalLockouts[raidname] or "")
					end
				end
				_G[entry..i]:SetID(line)
				_G[entry..i]:Show()
				i = i + 1
				VisibleCount = VisibleCount + 1
				DisplayedCount = DisplayedCount + 1
			end
		end
	end
	while i <= VisibleLines do
		_G[entry..i]:SetID(0)
		_G[entry..i]:Hide()
		i = i + 1
	end
	FauxScrollFrame_Update(_G[frame.."ScrollFrame"], VisibleCount, VisibleLines, 18);
end

function Altoholic_Raid_OnEnter(self)
	local line = self:GetParent():GetID()
	local s = Altoholic.CharacterInfo[line]
	-- DEFAULT_CHAT_FRAME:AddMessage("Onenter linetype "..s.linetype.."id"..self:GetID())
	if s.linetype ~= INFO_CHARACTER_LINE and s.linetype ~= INFO_REALM_LINE then
		-- DEFAULT_CHAT_FRAME:AddMessage("returning as linetype is "..s.linetype)
		return
	end
	local id = self:GetID()
	if id <= 0 or id > 10 then
		-- DEFAULT_CHAT_FRAME:AddMessage("returning as ID is "..id)
		return 
	end

	AltoTooltip:ClearLines();
	AltoTooltip:SetOwner(self, "ANCHOR_RIGHT");

	local longname = RaidLongNames[RaidNames[id]]

	if s.linetype == INFO_REALM_LINE then
		-- DEFAULT_CHAT_FRAME:AddMessage(GREEN .. "In realm info")
		local basetime, resetdays
		if s.realm == "Nordanaar" then
			-- There is no common base as Kara and Ony share 5 days
			-- reset but Kara is 1 day later on Nordanaar
			if id == 1 then		-- K10
				basetime = 1663128000 - 86400
				resetdays = 5
			elseif id == 2 or id == 3 then -- AQ20 ZG
				basetime = 1663128000 - 2 * 86400
				resetdays = 3
			elseif id == 5 then	-- ONY
				basetime = 1663128000 - 2 * 86400
				resetdays = 5
			else
				basetime = 1663128000
				resetdays = 7
			end
		else				-- Tel'Abim
			if id == 1 then		-- K10
				basetime = 1663128000 + 2 * 86400
				resetdays = 5
			elseif id == 2 or id == 3 then -- AQ20 ZG
				basetime = 1663128000 - 86400
				resetdays = 3
			elseif id == 5 then	-- ONY
				basetime = 1663128000 + 2 * 86400
				resetdays = 5
			else
				basetime = 1663128000 + 86400
				resetdays = 7
			end
		end
		local now = time()
		local passedresets = math.floor((now - basetime) / (resetdays * 86400))
		local lastreset = basetime + passedresets * resetdays * 86400
		local nextreset = lastreset + resetdays * 86400
		AltoTooltip:AddLine("Last reset: "..Altoholic:GetTimeString(now - lastreset) .. " ago")
		AltoTooltip:AddLine("Next reset: in "..Altoholic:GetTimeString(nextreset - now))
		local wallclockdate = date("%A, %H:%M", nextreset)
		AltoTooltip:AddLine("Next reset date: " .. ORANGE .. wallclockdate)
	end

	if s.linetype == INFO_CHARACTER_LINE then
		local Faction, Realm = Altoholic:GetCharacterInfo(line)
		local c = Altoholic.db.account.data[Faction][Realm].char[s.name]
		for name, info in pairs(c.SavedInstance) do
			if (string.sub(name, 1, string.len(longname)) == longname) then
				local id, reset, lastcheck = strsplit("|", info)
				reset = tonumber(reset)
				lastcheck = tonumber(lastcheck)
				local expiresIn = reset - (time() - lastcheck)

				AltoTooltip:AddLine(name, 1, 1, 1);
				if (expiresIn > 0) then
					AltoTooltip:AddLine("Expires in ".. RED .. Altoholic:GetTimeString(expiresIn))
				else
					AltoTooltip:AddLine("Expired ".. GREEN .. Altoholic:GetTimeString(-expiresIn) .. WHITE .. " ago")
				end
			end
		end
	end

	AltoTooltip:Show();

	return
end
