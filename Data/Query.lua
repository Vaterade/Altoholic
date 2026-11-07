-- Formatting and lookup helpers for the saved data. Nothing here draws anything.
local L = Altoholic.L
local V = Altoholic.vars
local Professions = Altoholic.Professions
local WHITE		= "|cFFFFFFFF"
local RED		= "|cFFFF0000"
local GREEN		= "|cFF00FF00"
local YELLOW	= "|cFFFFFF00"
local ORANGE	= "|cFFFF7F00"
local LEVEL_CAP = 60

-- 1 when an on/off option is on, nil when off (options are stored as 1 or 0)
function Altoholic:Option(name)
	local O = self.db and self.db.account.options
	if O and O[name] == 1 then return 1 end
end

-- tells the window that a scan changed something it lists ("mail", "auctions", "bids")
function Altoholic:DataChanged(what)
	if self.OnDataChanged then self:OnDataChanged(what) end
end

function Altoholic_GetItemLink(itemID)
    if not itemID then return end
    local itemName, itemString, itemQuality = GetItemInfo(itemID)
    local _, _, _, itemColor = GetItemQualityColor(itemQuality)
    local itemLink = itemColor .. "|H" .. itemString .. "|h[" .. itemName .. "]|h|r"
    return itemLink
end

function Altoholic:GetIDFromLink(link)
	if not link then return end
	return tonumber(string.match(link, "item:(%d+)"))
end

-- the "item:id:enchant:suffix:unique" part of a link, which is the form SetHyperlink and
-- GetItemInfo take; an item ID or an item string comes back as it is
function Altoholic:GetItemString(link)
	if type(link) ~= "string" then return link end
	return string.match(link, "item:[%-%d:]+") or link
end

function Altoholic:GetEnchantIDFromLink(link)
    if not link then return end
    local itemId = string.match(link, ".*(enchant:%d+).*")
    return tostring(itemId)
end

-- true when the link carries an enchant or a random suffix, which the bare item ID would lose
function Altoholic:GetEnchantInfo(link)
	local enchantId, suffixId = string.match(link, "item:%d+:(%-?%d+):(%-?%d+)")
	local isEnchanted = (enchantId ~= nil and enchantId ~= "0") or (suffixId ~= nil and suffixId ~= "0")
	return isEnchanted, enchantId, suffixId
end

function Altoholic:GetMoneyString(copper, color)
	local gold = floor( copper / 10000 );
	copper = copper - (gold * 10000)
	local silver = floor( copper / 100 );
	copper = copper - (silver * 100)
	if color == nil then
		color = "|cFFFFD700"
	end
	return color .. gold .. "|cFFFFD700g " .. color .. silver .. "|cFFC7C7CFs " .. color .. copper .. "|cFFEDA55Fc"
end

function Altoholic:GetTimeString(seconds)
	local days = floor(seconds / 86400);
	seconds = seconds - (days * 86400)
	local hours = floor(seconds / 3600);
	seconds = seconds - (hours * 3600)
	local minutes = floor(seconds / 60);
	seconds = seconds - (minutes * 60)
	local c1 = WHITE
	local c2 = "|r"
	return c1 .. days .. c2 .. "d " .. c1 .. hours .. c2 .. "h " .. c1 .. minutes .. c2 .. "m"
end

function Altoholic:GetRealmString(faction, realm)
	if faction == FACTION_ALLIANCE then
		return "|cFF2459FF" .. realm
	else
		return "|cFFFF0000" .. realm
	end
end

function Altoholic:GetFullRealmString(faction, realm)
	if faction == "Alliance" then
		return "|cFF2459FF[" .. FACTION_ALLIANCE .. "] " .. WHITE .. realm
	else
		return "|cFFFF0000[" .. FACTION_HORDE .. "] " .. WHITE .. realm
	end
end

function Altoholic:GetQuestTypeString(tag, size)
	if size == 0 then
		return WHITE .. tag
	elseif size == 2 then
		return WHITE .. tag .. GREEN .. " (" .. size .. ")"
	elseif size == 3 then
		return WHITE .. tag .. YELLOW .. " (" .. size .. ")"
	elseif size == 4 then
		return WHITE .. tag .. ORANGE .. " (" .. size .. ")"
	end
	return WHITE .. tag .. RED .. " (" .. size .. ")"
end

function Altoholic:GetClassColor(class)
	if class == nil or class == "" then 
		DEFAULT_CHAT_FRAME:AddMessage(WHITE .. debugstack())
		return WHITE 
	end

	return self.ClassInfo[self.Classes[class]].color
end

function Altoholic:GetDelayInDays(delay)
	return floor((time() - delay) / 86400)
end

function Altoholic:GetRestedXP(level, restXP, logout, isResting)
	if level >= LEVEL_CAP then
		return L["No rest XP"]
	end
	local rate = self:GetRestXPRate(level, restXP)
	if logout ~= 0 then
		if isResting then
			rate = rate + ((time() - logout) / 8640)
		else
			rate = rate + ((time() - logout) / 34560)
		end
	end
	local coeff
	if Altoholic:Option("RestXPMode") then
		coeff = 1.5
		rate = rate * coeff
	else
		coeff = 1
	end
	if rate >= (100 * coeff) then
		return "|cFF00FF00" .. format("%d", (100 * coeff)) .. L["% rested"]
	else
		local color
		if rate < (30 * coeff) then
			color = "|cFFFF0000"
		elseif rate < (60 * coeff) then
			color = "|cFFFFFF00"
		else
			color = GREEN
		end
		return color .. format("%d", rate) .. L["% rested"]
	end
end

function Altoholic:GetRestXPRate(level, restXP)
	local xpToNext = self.XPToNext[level]
	-- no entry for a character whose level was never scanned (0) or is past the table
	if not restXP or not xpToNext then return 0 end
	return (restXP / ((xpToNext / 100) * 1.5))
end

function Altoholic:GetSkillColor(rank)
	if rank == nil then
        return WHITE
    elseif rank < 75 then
		return RED
	elseif rank < 150 then
		return ORANGE
	elseif rank < 225 then
		return YELLOW
	else
		return GREEN
	end
end

local function compare_Character_By_Level(c1, c2)
	local l1 = Altoholic.db.account.data[Altoholic_compare_faction][Altoholic_compare_realm].char[c1].level
	local l2 = Altoholic.db.account.data[Altoholic_compare_faction][Altoholic_compare_realm].char[c2].level
	if l1 == l2 then
		return c1 < c2  -- alphabetically when same level
	else
		return l1 > l2  -- highest level first
	end
end

function Altoholic:Get_Sorted_Character_List(faction, realm)
	Altoholic_sorted_character_list = {}
	Altoholic_compare_faction = faction
	Altoholic_compare_realm = realm
	-- DEFAULT_CHAT_FRAME:AddMessage(TEAL .. "getting list for "..faction.." on "..realm)
	for CharacterName, c in pairs(self.db.account.data[faction][realm].char) do
		-- no class: the record was only ever looked up, never scanned
		if c.class ~= "" then
			table.insert(Altoholic_sorted_character_list, CharacterName)
		end
	end
	table.sort(Altoholic_sorted_character_list, compare_Character_By_Level)
	return Altoholic_sorted_character_list
end

function Altoholic:GetProfessionID(skill)
    local Profs = {
    [1] = Professions["Tailoring"],
    [2] = Professions["Leatherworking"],
    [3] = Professions["Engineering"],
    [4] = Professions["Enchanting"],
    [5] = Professions["Blacksmithing"],
    [6] = Professions["Alchemy"],
    [7] = L["Mining"],
    [8] = Professions["First Aid"],
    [9] = Professions["Cooking"],
    [10] = Professions["Fishing"],
    [11] = L["Riding"],
    [12] = L["Poisons"],
    [13] = L["Lockpicking"],
	[14] = "Disguise",
	[15] = L["Survival"]
    }
	for i,v in (Profs) do
		if skill == v then
			return i
		end
	end
	return nil
end

function Altoholic:FormatMailExpiry(lastcheck, mailexpiry)
	if (lastcheck == nil) or (lastcheck == 0) then
		return GREEN .. string.format("%.2f", mailexpiry)
	end
	local expiry = self:GetMailExpiry(lastcheck, mailexpiry)
	if expiry > 10 then
		return GREEN .. string.format("%.2f", expiry)
	elseif expiry > 5 then
		return "|cFFFFFF00" .. string.format("%.2f", expiry)
	end
	return "|cFFFF0000" .. string.format("%.2f", expiry)
end

function Altoholic:GetReputationInfo(repString)
	local bottom, top, earned = strsplit("|", repString)
	bottom = tonumber(bottom)
	top = tonumber(top)
	earned = tonumber(earned)
	local rate = (earned - bottom) / (top - bottom) * 100

	return bottom, top, earned, rate
end

function Altoholic:GetRepLevelString(bottom)
	if bottom == -42000 then
		return FACTION_STANDING_LABEL1 -- "Hated"
	elseif bottom == -6000 then
		return FACTION_STANDING_LABEL2 -- "Hostile"
	elseif bottom == -3000 then
		return FACTION_STANDING_LABEL3 -- "Unfriendly"
	elseif bottom == 0 then
		return FACTION_STANDING_LABEL4 -- "Neutral"
	elseif bottom == 3000 then
		return FACTION_STANDING_LABEL5 -- "Friendly"
	elseif bottom == 9000 then
		return FACTION_STANDING_LABEL6 -- "Honored"
	elseif bottom == 21000 then
		return FACTION_STANDING_LABEL7 -- "Revered"
	elseif bottom == 42000 then
		return FACTION_STANDING_LABEL8 -- "Exalted"
	end
end

-- The kind of a specialty bag ("Soul Bag", "Quiver"...) from the bag item's own
-- subclass, so Turtle's custom bag types are named too. nil for a plain bag or
-- one the client has not cached.
function Altoholic:GetBagTypeString(link)
	local _, _, subType, _, _, classID, subClassID = C_Item.GetItemInfoInstant(link)
	if classID == Enum.ItemClass.Quiver or (classID == Enum.ItemClass.Container and subClassID ~= 0) then
		return subType
	end
end

-- Forgets a character: its record and its reputations, then the realm and the faction if
-- nothing is left in them. The logged-in character can't be deleted. Returns true if done.
function Altoholic:DeleteCharacter(faction, realm, name)
	if faction == V.faction and realm == V.realm and name == V.player then return false end
	local data = self.db.account.data
	local r = rawget(data, faction) and rawget(data[faction], realm)
	if not r then return false end
	for _, reps in pairs(rawget(r, "reputation") or {}) do
		if type(reps) == "table" then reps[name] = nil end
	end
	local chars = rawget(r, "char")
	if chars then chars[name] = nil end
	if not chars or next(chars) == nil then data[faction][realm] = nil end
	if next(data[faction]) == nil then data[faction] = nil end
	return true
end
