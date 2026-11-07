-- Scans the logged-in character: login, bags, bank, equipment, stats, reputations,
-- skills, spells, lockouts and completed quests.
local V = Altoholic.vars
local WHITE		= "|cFFFFFFFF"

function Altoholic:PLAYER_LOGIN()
	self:ReadClientNames()
	self:BuildFactionsRefTable()
	self:BuildLootTable()
	self:BuildSuggestions()
	self:InitDatabase()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("PLAYER_LOGOUT")
	self:RegisterEvent("PLAYER_UPDATE_RESTING")
	self:RegisterEvent("PLAYER_GUILD_UPDATE")
	self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("ZONE_CHANGED_INDOORS")
	self:RegisterEvent("TIME_PLAYED_MSG")
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	self:RegisterEvent("MAIL_SHOW")
	self:RegisterEvent("MAIL_CLOSED")
	self:RegisterEvent("UPDATE_INSTANCE_INFO")
	self:RegisterEvent("CHAT_MSG_ADDON")
	V.faction = UnitFactionGroup("player")
	V.realm = GetRealmName()
  	V.player = UnitName("player")
	V.alt = V.player
	if self.db.account.data[V.faction][V.realm].char[V.player].playtime == nil then
		RequestTimePlayed()
	end
	self:CheckExpiredMail()
	self:RepairRecipeLists()
	-- the window, when it is loaded
	if self.UI_OnLogin then self:UI_OnLogin() end
end

function Altoholic:UpdatePlayerInventory()
	local r = self.db.account.data[V.faction][V.realm]
	local c = r.char[V.player]
	local nTotalSlots = 0
	local nSlots
	nTotalSlots = GetContainerNumSlots(0)
	c.bags = nTotalSlots .. "/"
	for i = 1, 4 do
		nSlots = GetContainerNumSlots(i)
		nTotalSlots = nTotalSlots + nSlots
		c.bags = c.bags .. WHITE .. nSlots
		if i ~= 4 then
			c.bags = c.bags .. "|r/"
		end
	end
	c.bags = c.bags .. " |r(|cFF00FF00" .. nTotalSlots .. "|r)"
end

function Altoholic:UpdatePlayerStats()
	local r = self.db.account.data[V.faction][V.realm]
	local c = r.char[V.player]
	self:PLAYER_XP_UPDATE()
	self:UpdatePlayerSkills()
	self:UpdatePlayerSpells()
	self:UpdatePlayerInventory()
	self:UpdateEquipment()
	self:UpdateRaidTimers()
	self:UpdateQuests()
	self:PLAYER_MONEY()
	self:UpdateReputations()
	self:UpdateQuestLog()
	self:UpdatePVPStats()
end

function Altoholic:UpdateReputation(name, bottom, top, earned)
	self.db.account.data[V.faction][V.realm].reputation[name][V.player] = bottom .. "|" .. top .. "|" .. earned
end

function Altoholic:UpdateReputations()
	-- factions under a collapsed header are not in the list, so open the headers for the scan ..
	local collapsed = {}
	for i = GetNumFactions(), 1, -1 do
		local name, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(i)
		if isHeader and isCollapsed then
			collapsed[name] = true
			ExpandFactionHeader(i)
		end
	end
	for i = 1, GetNumFactions() do
		local name, _, _, bottom, top, earned, _, _, isHeader = GetFactionInfo(i)
		if isHeader == nil then
			self:UpdateReputation(name, bottom, top, earned)
		end
	end
	-- .. and close them again, bottom up so the indices above stay valid
	for i = GetNumFactions(), 1, -1 do
		local name, _, _, _, _, _, _, _, isHeader = GetFactionInfo(i)
		if isHeader and collapsed[name] then
			CollapseFactionHeader(i)
		end
	end
end

-- keeps the reputations current between two logins
function Altoholic:FACTION_STANDING_CHANGED(factionID)
	local name, _, _, bottom, top, earned, _, _, isHeader = GetFactionInfoByID(factionID)
	if name and not isHeader then
		self:UpdateReputation(name, bottom, top, earned)
	end
end

function Altoholic:UpdatePlayerSkills()
	local c = self.db.account.data[V.faction][V.realm].char[UnitName("player")]
    -- *** Skills inventory ***
	for i = GetNumSkillLines(), 1, -1 do
		local _, isHeader = GetSkillLineInfo(i)
		if isHeader then
			ExpandSkillHeader(i)
		end
	end
	local category
	for i = 1, GetNumSkillLines() do
		local skillName, isHeader, _, skillRank, _, _, skillMaxRank = GetSkillLineInfo(i)
		if isHeader then
			category = skillName
		else
			c.skill[category][skillName] = skillRank .. "|" .. skillMaxRank
		end
	end
end

function Altoholic:UpdatePlayerSpells()
	local c = self.db.account.data[V.faction][V.realm].char[UnitName("player")]
    -- *** Spells inventory ***
    local i = 1
    while true do
        local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
        if not spellName then
          do break end
        end
        if string.find(spellRank, ".*Rank.*") then
            c.spells[i] = spellName .. " (" .. spellRank .. ")"
        else
            c.spells[i] = spellName
        end
        i = i + 1
    end
end

function Altoholic:UpdatePVPStats()
	local c = self.db.account.data[V.faction][V.realm].char[UnitName("player")]
	c.pvp_hk, c.pvp_dk = GetPVPLifetimeStats()
    local _, _, contribution, _ = GetPVPLastWeekStats()
	c.pvp_HonorPoints = contribution
end

function Altoholic:UpdateTalents()
	local c = self.db.account.data[V.faction][V.realm].char[UnitName("player")]
	c.talent = ""
	for i = 1, GetNumTalentTabs() do
		local numTalents = GetNumTalents(i)
		local _, _, pointsSpent, _ = GetTalentTabInfo( i );
		c.talent = c.talent .. WHITE .. pointsSpent
		if i ~= 3 then
			c.talent = c.talent .. "|r/"
		end
	end
end

function Altoholic:UpdateEquipment()
	local c = self.db.account.data[V.faction][V.realm].char[UnitName("player")]
	for i = 1, 19 do
		local link = GetInventoryItemLink("player", i)
		if link ~= nil then
			if self:GetEnchantInfo(link) then
				c.inventory[i] = link
			else
				c.inventory[i] = self:GetIDFromLink(link)
			end
		else
			c.inventory[i] = nil
		end
	end
end

function Altoholic:UpdatePlayerBags()
	for bagID = 0, 4 do
		self:UpdatePlayerBag(bagID)
	end
	self:UpdateKeyRing()
end

-- the number of empty slots in a bag (C_Container's count leaves out the bank bags)
function Altoholic:CheckPlayerInventory(bagID)
	local free = 0
	for slot = 1, GetContainerNumSlots(bagID) or 0 do
		if not GetContainerItemInfo(bagID, slot) then
			free = free + 1
		end
	end
	return free
end

function Altoholic:UpdatePlayerBag(bagID)
	if bagID < 0 then return end
    local c = self.db.account.data[V.faction][V.realm].char
	local b = c[V.player].bag["Bag" .. bagID]
    if c[0] then
        c[0] = {}
        c[0] = nil
    end
    if b[0] then
        b[0] = {}
        b[0] = nil
    end
	if bagID == 0 then	-- Bag 0
		b.icon = "Interface\\Buttons\\Button-Backpack-Up";
		b.link = nil;
	else	-- Bags 1 through 11
		b.icon = GetInventoryItemTexture("player", ContainerIDToInventoryID(bagID))
		b.link = GetInventoryItemLink("player", ContainerIDToInventoryID(bagID))
	end
	b.freeslots = Altoholic:CheckPlayerInventory(bagID)
	b.size = GetContainerNumSlots(bagID)
	self:PopulateContainer(bagID)
end

function Altoholic:PopulateContainer(bagID)
	local b = self.db.account.data[V.faction][V.realm].char[V.player].bag["Bag" .. bagID]
	for slotID = 1, b.size do
		b.ids[slotID] = nil
		b.counts[slotID] = nil
		b.links[slotID] = nil
		local link = GetContainerItemLink(bagID, slotID)
		if link ~= nil then
			b.ids[slotID] = self:GetIDFromLink(link)
			if self:GetEnchantInfo(link) then
				b.links[slotID] = link
			end
			local _, count = GetContainerItemInfo(bagID, slotID)
			if (count ~= nil) and (count > 1)  then
				b.counts[slotID] = count
			end
		end
	end
end

function Altoholic:UpdateKeyRing()
	local b = self.db.account.data[V.faction][V.realm].char[V.player].bag["Bag-2"]
	b.size = GetContainerNumSlots(-2)
	b.icon = "Interface\\Icons\\INV_Misc_Key_14";
	b.link = nil
	self:PopulateContainer(-2)
end

function Altoholic:UpdatePlayerBank(scanBags)
	if scanBags == nil then
		scanBags = true
	end
	local c = self.db.account.data[V.faction][V.realm].char[V.player]
	if scanBags then
		local nTotalSlots = 28
		c.bankslots = "28/"
		for bagID = 5, 10 do
			self:UpdatePlayerBag(bagID)
			local nSlots = GetContainerNumSlots(bagID)
			nTotalSlots = nTotalSlots + nSlots
			c.bankslots = c.bankslots .. WHITE .. nSlots
			if bagID ~= 11 then
				c.bankslots = c.bankslots .. "|r/"
			end
		end
		c.bankslots = c.bankslots .. " |r(|cFF00FF00" .. nTotalSlots .. "|r)"
	end
	local b = c.bag["Bag100"]
	b.size = 28
	for slotID = 40, 67 do
		local index = slotID-39
		b.ids[index] = nil
		b.counts[index] = nil
		b.links[index] = nil
		local link = GetInventoryItemLink("player", slotID)
		if link ~= nil then
			b.ids[index] = self:GetIDFromLink(link)
			if self:GetEnchantInfo(link) then
				b.links[index] = link
			end
			local count = GetInventoryItemCount("player", slotID)
			if (count ~= nil) and (count > 1)  then
				b.counts[index] = count
			end
		end
	end
end

function Altoholic:UpdateRaidTimers()
	RequestRaidInfo()
end

local QuestQueryTime = 0

function Altoholic:UpdateQuests()
	-- need to clear them here as to not set the questquerytime before
	-- the weeklies code removes them
	local c = self.db.account.data[V.faction][V.realm].char[V.player]
	Altoholic:ResetWeeklyQuestsIfExpired(c)
	QuestQueryTime = GetTime()
	SendChatMessage(".queststatus", "GUILD")
end

-- called when RequestRaidInfo() has results
function Altoholic:UPDATE_INSTANCE_INFO()
	local c = self.db.account.data[V.faction][V.realm].char[V.player]
	-- DEFAULT_CHAT_FRAME:AddMessage(ORANGE .. "Update timers, there are "..GetNumSavedInstances())
	c.SavedInstance = {}
	for i=1, GetNumSavedInstances() do
		local instanceName, instanceID, instanceReset = GetSavedInstanceInfo(i)
		c.SavedInstance[instanceName] = instanceID .. "|" .. instanceReset .. "|" .. time()
	end
end

-- keeps the completed quests current between two .queststatus polls
function Altoholic:QUEST_TURNED_IN(questID)
	local c = self.db.account.data[V.faction][V.realm].char[V.player]
	c.CompletedQuests = c.CompletedQuests or {}
	c.CompletedQuests[tostring(questID)] = true
end

function Altoholic:CHAT_MSG_ADDON(a1, a2)
	-- If we have many quests completed we'll get more than one chat line.
	-- So only ever add to the quest list; can't uncomplete a Q anyway.
	if a1 and a1 == "TWQUEST" then
		if GetTime() > QuestQueryTime + 3 then return end
		-- DEFAULT_CHAT_FRAME:AddMessage(a1)
		-- DEFAULT_CHAT_FRAME:AddMessage(ORANGE .. string.sub(a2, 1, 20) .. "..." .. string.sub(a2, -20))
		local c = self.db.account.data[V.faction][V.realm].char[V.player]
		local completedQuests = c.CompletedQuests or {}
		for qid in a2:gmatch("[^ ]+") do
			completedQuests[qid] = true
		end
		c.CompletedQuests = completedQuests
		c.CompletedQuestsLastCheck = time()
	end
end

function Altoholic:PLAYER_ALIVE()
	local c = self.db.account.data[V.faction][V.realm].char[V.player]
	c.level = UnitLevel("player")
	c.race = UnitRace("player")
	c.class = UnitClass("player")
	self:UpdatePlayerStats()
	self:UpdateTalents()
end

function Altoholic:PLAYER_ENTERING_WORLD()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	-- let the login burst of bag and spell events pass before the first scan
	C_Timer.After(1, function() Altoholic:StartScanning() end)
end

function Altoholic:StartScanning()
	self:RegisterEvent("BAG_UPDATE")
	self:RegisterEvent("BAG_UPDATE_DELAYED")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
	self:RegisterEvent("QUEST_TURNED_IN")
	self:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
	self:RegisterEvent("QUEST_ACCEPTED")
	self:RegisterEvent("QUEST_REMOVED")
	self:RegisterEvent("FACTION_STANDING_CHANGED")
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("TRADE_SKILL_CLOSE")
	self:RegisterEvent("CRAFT_SHOW")
	self:RegisterEvent("CRAFT_CLOSE")
	self:RegisterEvent("LEARNED_SPELL_IN_TAB")
	local c = self.db.account.data[V.faction][V.realm].char[V.player]
	c.level = UnitLevel("player")
	c.race = UnitRace("player")
	c.class = UnitClass("player")
	self:UpdatePlayerStats()
	self:UpdateTalents()
	self:UpdatePlayerBags()
	self:HookTooltip()
end

function Altoholic:PLAYER_LEVEL_UP(newLevel)
	self.db.account.data[V.faction][V.realm].char[V.player].level = newLevel
end

function Altoholic:PLAYER_XP_UPDATE()
	local c = self.db.account.data[V.faction][V.realm].char[V.player]
	c.xp = UnitXP("player")
	c.xpmax = UnitXPMax("player")
	c.restxp = GetXPExhaustion()
end

function Altoholic:PLAYER_MONEY()
	self.db.account.data[V.faction][V.realm].char[V.player].money = GetMoney();
end

function Altoholic:PLAYER_UPDATE_RESTING()
	self.db.account.data[V.faction][V.realm].char[V.player].isResting = IsResting();
end

function Altoholic:PLAYER_GUILD_UPDATE()
	V.guild = GetGuildInfo("player")
end

function Altoholic:ZONE_CHANGED()
	self:UpdatePlayerLocation()
end

function Altoholic:ZONE_CHANGED_NEW_AREA()
	self:UpdatePlayerLocation()
end

function Altoholic:ZONE_CHANGED_INDOORS()
	self:UpdatePlayerLocation()
end

function Altoholic:UpdatePlayerLocation()
	local c = self.db.account.data[V.faction][V.realm].char[V.player]
	c.zone = GetRealZoneText()
	c.subzone = GetSubZoneText()
end

function Altoholic:PLAYER_LOGOUT()
	self.db.account.data[V.faction][V.realm].char[V.player].lastlogout = time()
	self:CleanDatabase()
end

function Altoholic:TIME_PLAYED_MSG(TotalTime, CurrentLevelTime)
	self.db.account.data[V.faction][V.realm].char[V.player].played = TotalTime
end

function Altoholic:PLAYER_EQUIPMENT_CHANGED()
	self:UpdateEquipment()
end

function Altoholic:BAG_UPDATE(bag)
	-- the keyring is the one container BAG_UPDATE_DELAYED doesn't cover
	if bag == -2 then
		V.ToolTipCachedItemID = nil
		self:UpdateKeyRing()
	end
end

-- fires once per frame, however many bag slots changed in it
function Altoholic:BAG_UPDATE_DELAYED()
	V.ToolTipCachedItemID = nil
	if V.isMailBoxOpen then
		self:UpdatePlayerMail()
	end
    self:UpdatePlayerBags()
    self:UpdatePlayerInventory()
	if V.isBankOpen then
		self:UpdatePlayerBank()
	end
end

function Altoholic:BANKFRAME_OPENED()
    self:UpdatePlayerBank()
	V.isBankOpen = true
	self:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
end

function Altoholic:BANKFRAME_CLOSED()
	V.isBankOpen = nil
	if self:IsEventRegistered("PLAYERBANKSLOTS_CHANGED") then
		self:UnregisterEvent("PLAYERBANKSLOTS_CHANGED")
	end
end

function Altoholic:PLAYERBANKSLOTS_CHANGED()
	self:UpdatePlayerBank(false)
end
