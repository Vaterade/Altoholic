-- *** TO DO's ***
-- **   (1) Profession Cooldowns - in BC there was a tidy API we could hit to return profession cooldowns.
-- **   In vanilla I'll have to figure out the best way to do this. Either scan the recipies tool tip
-- **   or save the time stamp when the player uses the recipe.

-- *** Open bugs ***

-- .Libs
local L = Altoholic.L
local V = Altoholic.vars
local Professions = Altoholic.Professions
local WHITE		= "|cFFFFFFFF"
local GREEN		= "|cFF00FF00"
local GOLD		= "|cFFFFD700"
local MENU_SUMMARY = 1
local MENU_CONTAINERS = 2
local MENU_MAIL = 3
local MENU_SEARCH = 4
local MENU_EQUIPMENT = 5
local MENU_QUESTS = 6
local MENU_RECIPES = 7
local MENU_AUCTIONS = 8
local MENU_BIDS = 9
local MENU_OPTIONS = 10
local INFO_REALM_LINE = 1
local INFO_CHARACTER_LINE = 2
local INFO_TOTAL_LINE = 3

-- Item class and subclass names from ItemClass.dbc / ItemSubClass.dbc, in the
-- client's language, label the Search menu; the search itself matches items by
-- class and subclass ID. GetItemClassInfo returns nil for class 0 (Consumable),
-- so a class keeps its English name when the client gives none.
local WEAPON = Enum.ItemClass.Weapon
local ARMOR = Enum.ItemClass.Armor
local RECIPE = Enum.ItemClass.Recipe

local ITEM_CLASS_ENGLISH = {
	[Enum.ItemClass.Consumable] = "Consumable",
	[WEAPON] = "Weapon",
	[ARMOR] = "Armor",
	[Enum.ItemClass.Tradegoods] = "Trade Goods",
	[RECIPE] = "Recipe",
}

local function ItemClassName(classID)
	return GetItemClassInfo(classID) or L[ITEM_CLASS_ENGLISH[classID]]
end

local function ItemSubClassName(classID, subClassID)
	return (GetItemSubClassInfo(classID, subClassID))
end

-- A search menu entry for an item class, or one of its subclasses. Without a
-- name the entry is labelled with the subclass name.
local function SearchEntry(name, classID, subClassID)
	return {
		name = name or ItemSubClassName(classID, subClassID),
		OnClick = function() Altoholic:SearchItem(classID, subClassID) end
	}
end

Altoholic.Menu = {
	{	name = L["Account Summary"], isCollapsed = false,
		subMenu = {
			{ name = L["Characters"], OnClick = function() Altoholic:ActivateMenuItem("AltoSummary") end },
			{ name = L["Bag Usage"], OnClick = function() Altoholic:ActivateMenuItem("AltoBags") end },
			{ name = SKILLS, OnClick = function() Altoholic:ActivateMenuItem("AltoSkills") end },
			{ name = L["Reputations"], OnClick = function() Altoholic:ActivateMenuItem("AltoReputations") end },
			{ name = "Raids", OnClick = function() Altoholic:ActivateMenuItem("AltoRaids") end },
			{ name = "Attunements", OnClick = function() Altoholic:ActivateMenuItem("AltoAttunements") end }
		}
	},
	{	name = L["Containers"], isCollapsed = true,
		subMenu = {}
	},
	{	name = L["E-Mail"], isCollapsed = true,
        subMenu = {}
	},
	{	name = L["Search"], isCollapsed = true,
        subMenu = {}		-- filled by BuildSearchSubMenu
	},
	{ name = L["Equipment"], isCollapsed = true,
		subMenu = {}
	},
	{ name = L["Quests"], isCollapsed = true,
		subMenu = {}
	},
	{ name = L["Recipes"], isCollapsed = true,
		subMenu = {}
	},
	{ name = AUCTIONS, isCollapsed = true,
		subMenu = {}
	},
	{ name = BIDS, isCollapsed = true,
		subMenu = {}
	},
	{ name = L["Options"], OnClick = function() Altoholic:ActivateMenuItem("AltoOptions") end	}
}

-- the menus to rebuild when a scan changes what they list (see DataChanged)
local REBUILD = { mail = "BuildMailSubMenu", auctions = "BuildAuctionsSubMenu", bids = "BuildBidsSubMenu" }

function Altoholic:OnDataChanged(what)
	if REBUILD[what] then self[REBUILD[what]](self) end
end

-- the window's half of PLAYER_LOGIN (Data/Scan.lua has the rest)
function Altoholic:UI_OnLogin()
	_G["AltoholicFrameName"]:SetText("Altoholic |cFFFFFFFF"..V.version)
	local f = CreateFrame("Frame", "RarityDropDownMenu", AltoholicFrame, "UIDropDownMenuTemplate");
	f:SetPoint("LEFT", "AltoholicFrame_MaxLevel", "RIGHT", 0, -5)
	UIDropDownMenu_SetWidth(80, f)
	UIDropDownMenu_SetButtonWidth(20, f)
	UIDropDownMenu_Initialize(f, function(self)
		Altoholic:DropDownRarity_Initialize();
	end)
	f = CreateFrame("Frame", "SlotsDropDownMenu", AltoholicFrame, "UIDropDownMenuTemplate");
	f:SetPoint("LEFT", "AltoholicFrame_MaxLevel", "RIGHT", 110, -5)
	UIDropDownMenu_SetWidth(80, f)
	UIDropDownMenu_SetButtonWidth(20, f)
	UIDropDownMenu_Initialize(f, function(self)
		Altoholic:DropDownSlot_Initialize();
	end)
	-- *** Create Scroll Frames' children lines ***
	self:CreateScrollLines("AltoSummary", "CharacterSummaryTemplate", 14);
	self:CreateScrollLines("AltoBags", "BagUsageTemplate", 14);
	self:CreateScrollLines("AltoContainers", "ContainerTemplate", 7, 14);
	self:CreateScrollLines("AltoMail", "MailEntryTemplate", 7);
	self:CreateScrollLines("AltoSearch", "SearchEntryTemplate", 7);
	self:CreateScrollLines("AltoEquipment", "EquipmentEntryTemplate", 7, 10);
	-- Manually fill the reputation frame
	local repFrame = "AltoReputations"
	f = CreateFrame("Button", repFrame .. "Entry" .. 1, _G[repFrame], "ReputationEntryTemplate")
	f:SetPoint("TOPLEFT", repFrame .. "ScrollFrame", "TOPLEFT", 0, -45)
	for i = 2, 11 do
		f = CreateFrame("Button", repFrame .. "Entry" .. i, _G[repFrame], "ReputationEntryTemplate")
		f:SetPoint("TOPLEFT", repFrame .. "Entry" .. (i-1), "BOTTOMLEFT", 0, 0)
	end
	for i=1, 11 do
		_G[repFrame.."Entry"..i.."Item10"]:SetPoint("BOTTOMRIGHT", repFrame .. "Entry"..i, "BOTTOMRIGHT", -15, 0);
		for j=9, 1, -1 do
			_G[repFrame.."Entry"..i.."Item" .. j]:SetPoint("BOTTOMRIGHT", repFrame.."Entry"..i.."Item" .. (j + 1), "BOTTOMLEFT", -5, 0);
		end
	end
	_G[repFrame.."ClassesItem10"]:SetPoint("BOTTOMRIGHT", repFrame .. "Classes", "BOTTOMRIGHT", -15, 0);
	for j=9, 1, -1 do
		_G[repFrame.."ClassesItem" .. j]:SetPoint("BOTTOMRIGHT", repFrame.."ClassesItem" .. (j + 1), "BOTTOMLEFT", -5, 0);
	end
	-- and the same for Attunements
	local attFrame = "AltoAttunements"
	f = CreateFrame("Button", attFrame .. "Entry" .. 1, _G[attFrame], "AttunementEntryTemplate")
	f:SetPoint("TOPLEFT", attFrame .. "ScrollFrame", "TOPLEFT", 0, -45)
	for i = 2, 11 do
		f = CreateFrame("Button", attFrame .. "Entry" .. i, _G[attFrame], "AttunementEntryTemplate")
		f:SetPoint("TOPLEFT", attFrame .. "Entry" .. (i-1), "BOTTOMLEFT", 0, 0)
	end
	for i=1, 11 do
		_G[attFrame.."Entry"..i.."Item10"]:SetPoint("BOTTOMRIGHT", attFrame .. "Entry"..i, "BOTTOMRIGHT", -15, 0);
		for j=9, 1, -1 do
			_G[attFrame.."Entry"..i.."Item" .. j]:SetPoint("BOTTOMRIGHT", attFrame.."Entry"..i.."Item" .. (j + 1), "BOTTOMLEFT", -5, 0);
		end
	end
	_G[attFrame.."ClassesItem10"]:SetPoint("BOTTOMRIGHT", attFrame .. "Classes", "BOTTOMRIGHT", -15, 0);
	for j=9, 1, -1 do
		_G[attFrame.."ClassesItem" .. j]:SetPoint("BOTTOMRIGHT", attFrame.."ClassesItem" .. (j + 1), "BOTTOMLEFT", -5, 0);
	end
	self:CreateScrollLines("AltoSkills", "SkillsTemplate", 14);
	self:CreateScrollLines("AltoRaids", "RaidsTemplate", 14);
	self:CreateScrollLines("AltoQuests", "QuestEntryTemplate", 14);
	self:CreateScrollLines("AltoRecipes", "RecipesEntryTemplate", 14);
	self:CreateScrollLines("AltoAuctions", "AuctionEntryTemplate", 7);
	self:BuildSearchSubMenu()
	self:BuildContainersSubMenu()
	self:BuildMailSubMenu()
	self:BuildEquipmentSubMenu()
	self:BuildQuestsSubMenu()
	self:BuildRecipesSubMenu()
	self:BuildAuctionsSubMenu()
	self:BuildBidsSubMenu()
	local O = self.db.account.options
	_G["AltoOptions_SliderAngle"]:SetValue(O.MinimapIconAngle)
	_G["AltoOptions_SliderRadius"]:SetValue(O.MinimapIconRadius)
	_G["AltoOptions_SliderMailExpiry"]:SetValue(O.MailWarningThreshold)
	_G["AltoOptions_TooltipSource"]:SetChecked(O.TooltipSource)
	_G["AltoOptions_TooltipCount"]:SetChecked(O.TooltipCount)
	_G["AltoOptions_TooltipTotal"]:SetChecked(O.TooltipTotal)
	_G["AltoOptions_TooltipAlreadyKnown"]:SetChecked(O.TooltipAlreadyKnown)
	_G["AltoOptions_TooltipLearnableBy"]:SetChecked(O.TooltipLearnableBy)
	_G["AltoOptions_ShowMinimap"]:SetChecked(O.ShowMinimap)
	_G["AltoOptions_SortDescending"]:SetChecked(O.SortDescending)
	_G["AltoOptions_RestXPMode"]:SetChecked(O.RestXPMode)
	_G["AltoOptions_ScanMailBody"]:SetChecked(O.ScanMailBody)
	_G["AltoOptions_MatchPfUI"]:SetChecked(self:Skin_Enabled() and 1 or 0)
	_G["AltoOptionsLootInfo"]:SetText(GREEN .. O.TotalLoots .. "|r " .. L["Loots"] .. " / " .. GREEN .. O.UnknownLoots .. "|r " .. L["Unknown"])
	if AltoOptions_ShowMinimap:GetChecked() then
		self:MoveMinimapIcon()
		AltoholicMinimapButton:Show();
	else
		AltoholicMinimapButton:Hide();
	end
end

function Altoholic_MiniMapButton_OnClick(button)
    if button == "LeftButton" then
        Altoholic:ToggleUI()
    end
end

-- the icon only needs to follow the cursor while it is being dragged
function Altoholic_MiniMapButton_OnDragStart(self)
	self:SetScript("OnUpdate", function() Altoholic:UpdateMinimapIconCoords() end)
end

function Altoholic_MiniMapButton_OnDragStop(self)
	self:SetScript("OnUpdate", nil)
end

function Altoholic:SetLabel(frame, text)
	_G[frame:GetName() .. "Text"]:SetText(text)
end

-- flips a header line between collapsed and expanded, lines that can't collapse are left alone
function Altoholic:ToggleCollapsed(line)
	if type(line) == "table" and line.isCollapsed ~= nil then
		line.isCollapsed = not line.isCollapsed
	end
end

function Altoholic:ToggleCharacterLine(button)
	local id = button:GetParent():GetID()
	if id ~= 0 then
		self:ToggleCollapsed(self.CharacterInfo[id])
	end
end

function Altoholic:ToggleUI()
	if (AltoholicFrame:IsVisible()) then
		AltoholicFrame:Hide();
	else
		AltoholicFrame:Show();
	end
end

function Altoholic:ActivateMenuItem(frame)
	for k, v in pairs(self.Categories) do
       	_G[v]:Hide()
	end
	_G[frame]:Show()
	self:Menu_FollowTab(frame)
end

function Altoholic:OnShow()
	if V.ExpiredMail then
		_G["AltoholicFrame_Status"]:SetText(L["Mail expires in less than "].. self.db.account.options.MailWarningThreshold .. L[" days"])
		_G["AltoholicFrame_Status"]:Show()
		V.ExpiredMail = nil
	end
	self:UpdatePlayerStats()
	self:UpdatePlayerBags()
	self:UpdateTalents()
	V.guild = GetGuildInfo("player")
	if V.RebuildRecipeMenu then
		self:BuildRecipesSubMenu()
	end
	self:BuildFactionsTable()
	self:BuildCharacterInfoTable()
	self:SelectCategory(MENU_SUMMARY)
	self:Skin_Apply()
end

function Altoholic:BuildCharacterInfoTable()
	local money = 0
	local played = 0
	local levels = 0
	V.SkillsCache = {}
	V.Skills = {}
	self.CharacterInfo = {}
	for FactionName, f in pairs(self.db.account.data) do
		for RealmName, r in pairs(f) do
			local realmmoney = 0
			local realmplayed = 0
			local realmlevels = 0
			table.insert(self.CharacterInfo, { linetype = INFO_REALM_LINE,
				isCollapsed = false,
				faction = FactionName,
				realm = RealmName
			} )
			local byLevel = Altoholic:Get_Sorted_Character_List(FactionName, RealmName)
			for _, CharacterName in ipairs(byLevel) do
				-- DEFAULT_CHAT_FRAME:AddMessage(ORANGE .. "Handling " .. CharacterName .. " on " .. RealmName .. " for " .. FactionName)
				local c = self.db.account.data[FactionName][RealmName].char[CharacterName]

				V.Skills[1] = ""
				V.Skills[2] = ""
				V.SkillsCache[1] = 0
				V.SkillsCache[2] = 0
				local i = 1
				for SkillName, s in pairs(c.skill[L["Professions"]]) do
					V.SkillsCache[i] = self:GetSkillInfo(s)
					V.Skills[i] = SkillName
					i = i + 1
				end
				V.SkillsCache[3] = self:GetSkillInfo( c.skill[L["Secondary Skills"]][Professions["Cooking"]] )
				V.SkillsCache[4] = self:GetSkillInfo( c.skill[L["Secondary Skills"]][Professions["First Aid"]] )
				V.SkillsCache[5] = self:GetSkillInfo( c.skill[L["Secondary Skills"]][Professions["Fishing"]] )
				V.SkillsCache[6] = self:GetSkillInfo( c.skill[L["Secondary Skills"]][L["Riding"]] )
				V.SkillsCache[7] = self:GetSkillInfo( c.skill[L["Secondary Skills"]][L["Survival"]] )
				local color = self:GetClassColor(c.class)
				local bank
				if (c.bankslots == nil) or (c.bankslots == "") then
					bank = L["Bank not visited yet"]
				else
					bank = c.bankslots
				end
				table.insert(self.CharacterInfo, { linetype = INFO_CHARACTER_LINE,
					name = CharacterName,
					bankslots = bank,
					skillRank1 = V.SkillsCache[1],
					skillName1 = V.Skills[1],
					skillRank2 = V.SkillsCache[2],
					skillName2 = V.Skills[2],
					cooking = V.SkillsCache[3],
					firstaid = V.SkillsCache[4],
					fishing = V.SkillsCache[5],
					riding = V.SkillsCache[6],
					survival = V.SkillsCache[7],
				} )
				realmlevels = realmlevels + c.level
				realmmoney = realmmoney + c.money
				realmplayed = realmplayed + c.played
			end
			table.insert(self.CharacterInfo, { linetype = INFO_TOTAL_LINE,
				level = WHITE .. realmlevels .. " |r" .. L["Levels"],
				money = self:GetMoneyString(realmmoney, WHITE),
				played = self:GetTimeString(realmplayed)
			} )
			levels = levels + realmlevels
			money = money + realmmoney
			played = played + realmplayed
		end
	end
	_G["AltoholicFrameTotalLv"]:SetText(WHITE .. levels .. " |rLv")
	_G["AltoholicFrameTotalGold"]:SetText(floor( money / 10000 ) .. "|cFFFFD700g")
	_G["AltoholicFrameTotalPlayed"]:SetText(floor(played / 86400) .. "|cFFFFD700d")
	SkillsCache = {}
	V.Skills = {}
end

function Altoholic:DropDownRarity_Initialize()
	local info = Altoholic_UIDropDownMenu_CreateInfo();
	V.SearchRarity = 0
	for i = 0, 6 do
		info.text = ITEM_QUALITY_COLORS[i].hex .. _G["ITEM_QUALITY"..i.."_DESC"]
		info.value = i
		info.func = function(self)
			UIDropDownMenu_SetSelectedValue(this.owner, this.value);
			V.SearchRarity = this.value
		end
		info.owner = this:GetParent();
		info.checked = nil;
		info.icon = nil;
		UIDropDownMenu_AddButton(info, 1);
	end
end

function Altoholic:DropDownSlot_Initialize()
	local info = Altoholic_UIDropDownMenu_CreateInfo();
	V.SearchSlot = 0
	info.text = L["Any"]
	info.value = 0
	info.func = function(self)
		UIDropDownMenu_SetSelectedValue(this.owner, this.value);
		V.SearchSlot = this.value
	end
	info.owner = this:GetParent();
	info.checked = nil;
	info.icon = nil;
	UIDropDownMenu_AddButton(info, 1);
	for i = 1, 18 do
		info.text = Altoholic.EquipmentSlots[i]
		info.value = i
		info.func = function(self)
			UIDropDownMenu_SetSelectedValue(this.owner, this.value);
			V.SearchSlot = this.value
		end
		info.owner = this:GetParent();
		info.checked = nil;
		info.icon = nil;
		UIDropDownMenu_AddButton(info, 1);
	end
end

function Altoholic:UpdateContainerCache()
	local c = self.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt]
	Altoholic.BagIndices = {}
	for bagID = 0, 10 do
		if c.bag["Bag"..bagID] ~= nil then
			self:UpdateBagIndices(bagID, c.bag["Bag"..bagID].size)
		end
	end
	self:UpdateBagIndices(-2, 32)
	if c.bag["Bag100"] ~= nil then
		self:UpdateBagIndices(100, 28)
	end
end

function Altoholic:UpdateBagIndices(bag, size)
	local lowerLimit = 1
	while size > 0 do
		table.insert(self.BagIndices, { bagID=bag, from=lowerLimit} )
		if size <= 12 then
			return
		else
			size = size - 12
			lowerLimit = lowerLimit + 12
		end
	end
end

-- called from the server when .queststatus is running

-- *** The menu ***
-- Two columns, styled after pfUI's config window. The first lists Altoholic.Menu; the
-- second, the subMenu tree of the selected category, flattened: realms (isHeader) are
-- section titles and always expanded, entries with a subMenu of their own (Search
-- classes, Recipes characters) expand on click, and the rest open a tab. The selected
-- row is remembered by its key, the path of names to it, so it survives the
-- Build*SubMenu functions replacing the tables.
local MENU_ROWS = 15
local TEAL_R, TEAL_G, TEAL_B = .2, 1, .8	-- pfUI's highlight colour

-- the category each tab belongs to, for tabs opened from elsewhere (the Search button, ...)
local TAB_CATEGORY = {
	AltoSummary = MENU_SUMMARY, AltoBags = MENU_SUMMARY, AltoSkills = MENU_SUMMARY,
	AltoReputations = MENU_SUMMARY, AltoRaids = MENU_SUMMARY, AltoAttunements = MENU_SUMMARY,
	AltoContainers = MENU_CONTAINERS, AltoMail = MENU_MAIL, AltoSearch = MENU_SEARCH,
	AltoEquipment = MENU_EQUIPMENT, AltoQuests = MENU_QUESTS, AltoRecipes = MENU_RECIPES,
	AltoAuctions = MENU_AUCTIONS, AltoOptions = MENU_OPTIONS,
}

local function MenuRow_SetSelected(row, selected)
	local name = row:GetName()
	if selected then
		_G[name .. "Text"]:SetTextColor(TEAL_R, TEAL_G, TEAL_B)
		_G[name .. "Selected"]:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 0, 1, 1, 1, .05)
		_G[name .. "Selected"]:Show()
	else
		_G[name .. "Text"]:SetTextColor(1, 1, 1)
		_G[name .. "Selected"]:Hide()
	end
end

-- the second column's lines: { entry, depth, key, isHeader, isParent, isEmpty }, and
-- { isSpacer = true } for the gap above each realm after the first. isEmpty: nothing to
-- open or expand (a Recipes character without professions)
local function Flatten(list, entries, depth, key)
	for _, e in ipairs(entries) do
		local k = key .. "/" .. (e.name or "")
		local hasChildren = e.subMenu ~= nil and #e.subMenu > 0
		if e.isHeader and #list > 0 then
			table.insert(list, { isSpacer = true })
		end
		table.insert(list, { entry = e, depth = depth, key = k,
			isHeader = e.isHeader, isParent = hasChildren and not e.isHeader,
			isEmpty = not e.isHeader and not hasChildren and not e.OnClick })
		if hasChildren and (e.isHeader or e.isCollapsed == false) then
			Flatten(list, e.subMenu, e.isHeader and depth or depth + 1, k)
		end
	end
	return list
end

local function Menu_ResetScroll()
	FauxScrollFrame_SetOffset(AltoholicMenuScrollFrame, 0)
	AltoholicMenuScrollFrameScrollBar:SetValue(0)
end

function Altoholic:Menu_Update(MenuLevel1, MenuLevel2, MenuLevel3)
	-- with levels: toggle that entry, then redraw
	if MenuLevel1 ~= nil then
		local m
		if MenuLevel2 ~= nil then
			if MenuLevel3 ~= nil then
				m = self.Menu[MenuLevel1].subMenu[MenuLevel2].subMenu[MenuLevel3]
			else
				m = self.Menu[MenuLevel1].subMenu[MenuLevel2]
            end
		else
			m = self.Menu[MenuLevel1]
		end
		if m.isCollapsed == true then
			m.isCollapsed = false
		else
			m.isCollapsed = true
		end
	end
	V.MenuCategory = V.MenuCategory or MENU_SUMMARY

	for i = 1, 10 do
		local row = _G["AltoholicCategory" .. i]
		local m = self.Menu[i]
		if m then
			_G["AltoholicCategory" .. i .. "Text"]:SetText(m.name)
			MenuRow_SetSelected(row, i == V.MenuCategory)
			row:Show()
		else
			row:Hide()
		end
	end

	local m = self.Menu[V.MenuCategory]
	self.MenuCache = (m and m.subMenu) and Flatten({}, m.subMenu, 0, "") or {}
	local offset = FauxScrollFrame_GetOffset(AltoholicMenuScrollFrame)
	for i = 1, MENU_ROWS do
		local row = _G["AltoholicMenuRow" .. i]
		local text = _G["AltoholicMenuRow" .. i .. "Text"]
		local line = self.MenuCache[i + offset]
		row.line = line
		if line and not line.isSpacer then
			text:ClearAllPoints()
			text:SetPoint("LEFT", row, "LEFT", 6 + line.depth * 10, 0)
			text:SetPoint("RIGHT", row, "RIGHT", -2, 0)
			text:SetJustifyH("LEFT")
			local label = line.entry.name or ""
			if line.isParent then
				label = (line.entry.isCollapsed == false and "|cFF808080- |r" or "|cFF808080+ |r") .. label
			end
			text:SetText(label)
			if line.isHeader then
				row:EnableMouse(false)
				MenuRow_SetSelected(row, false)
				text:SetTextColor(TEAL_R, TEAL_G, TEAL_B)
			elseif line.isEmpty then
				row:EnableMouse(false)
				MenuRow_SetSelected(row, false)
				text:SetTextColor(.5, .5, .5)
			else
				row:EnableMouse(true)
				MenuRow_SetSelected(row, not line.isParent and line.key == V.MenuSelected)
			end
			row:Show()
		else
			row:Hide()
		end
	end
	FauxScrollFrame_Update(AltoholicMenuScrollFrame, #self.MenuCache, MENU_ROWS, 20)
end

local function Menu_ScrollTo(index)
	local offset = FauxScrollFrame_GetOffset(AltoholicMenuScrollFrame)
	if index <= offset then
		offset = index - 1
	elseif index > offset + MENU_ROWS then
		offset = index - MENU_ROWS
	else
		return
	end
	FauxScrollFrame_SetOffset(AltoholicMenuScrollFrame, offset)
	AltoholicMenuScrollFrameScrollBar:SetValue(offset * 20)
end

-- opens the tab of a second-column line and marks it selected
function Altoholic:Menu_Open(line)
	V.MenuSelected = line.key
	if line.entry.OnClick then
		line.entry.OnClick(line.entry)
	end
	self:Menu_Update()
end

-- the line a category opens when it is selected: the logged-in character's entry, else
-- the first one that opens or expands. An entry that expands (a Recipes character) is
-- expanded and its first child opened.
function Altoholic:Menu_DefaultLine()
	local me = V.faction .. ":" .. V.realm .. ":" .. V.player
	local myRealm = V.faction .. ":" .. V.realm
	local function Usable(line) return line.entry and not line.isHeader and not line.isEmpty end
	local target
	for index, line in ipairs(self.MenuCache) do
		local e = line.entry
		if Usable(line) and (e.altID == me or e.realm == myRealm) then
			target = index
			break
		end
	end
	if not target then
		for index, line in ipairs(self.MenuCache) do
			if Usable(line) then
				target = index
				break
			end
		end
	end
	local line = target and self.MenuCache[target]
	if not line or not line.isParent then
		return target
	end
	line.entry.isCollapsed = false
	self:Menu_Update()
	local child = self.MenuCache[target + 1]
	if child and Usable(child) and not child.isParent and child.depth > line.depth then
		return target + 1
	end
end

function Altoholic:SelectCategory(category)
	local m = self.Menu[category]
	if not m then return end
	V.MenuCategory = category
	V.MenuSelected = nil
	Menu_ResetScroll()
	self:Menu_Update()

	if not m.subMenu then
		-- Options: no second column
		if m.OnClick then m.OnClick(m) end
		return
	end
	if category == MENU_SEARCH then
		-- every entry here starts a search, so open none: show the last results
		self:ActivateMenuItem("AltoSearch")
		return
	end
	local index = self:Menu_DefaultLine()
	if index then
		Menu_ScrollTo(index)
		self:Menu_Open(self.MenuCache[index])
	end
end

function Altoholic:MenuRow_OnClick(row)
	if string.find(row:GetName(), "^AltoholicCategory") then
		self:SelectCategory(row:GetID())
		return
	end
	local line = row.line
	if not line or not line.entry or line.isHeader then return end
	if line.isParent then
		line.entry.isCollapsed = (line.entry.isCollapsed == false)
		self:Menu_Update()
	else
		self:Menu_Open(line)
	end
end

-- a tab opened from elsewhere (the Search button, a link in another tab) selects its
-- category, so the first column never names a different tab than the one shown
function Altoholic:Menu_FollowTab(frame)
	local category = TAB_CATEGORY[frame]
	if not category or category == V.MenuCategory then return end
	if frame == "AltoAuctions" and V.MenuCategory == MENU_BIDS then return end
	V.MenuCategory = category
	V.MenuSelected = nil
	Menu_ResetScroll()
	self:Menu_Update()
end

-- *** The search box ***
-- Here, not in Modules/Search.lua: the box is in Altoholic.xml, whose OnLoad runs
-- before the modules load.
-- Like pfUI's config search: no button, it searches by itself once typing stops for
-- SEARCH_DELAY seconds (a search can walk every loot table, too slow for each key), or
-- at once on Enter. Emptying it clears the results. A shift-clicked item that fills it
-- is searched the same way.
local SEARCH_DELAY = 0.4
local HINT_R, HINT_G, HINT_B = .2, 1, .8	-- pfUI's teal

function Altoholic:Search_OnLoad(box)
	box:SetTextColor(HINT_R, HINT_G, HINT_B)
	box:SetJustifyH("CENTER")
	local hint = _G[box:GetName() .. "Hint"]
	hint:SetText(L["Search"] .. "...")
	hint:SetTextColor(HINT_R, HINT_G, HINT_B)
end

-- the "Search..." hint shows while the box is empty and not being typed in
function Altoholic:Search_UpdateHint(box, focused)
	box.focused = focused
	local hint = _G[box:GetName() .. "Hint"]
	if focused or box:GetText() ~= "" then
		hint:Hide()
	else
		hint:Show()
	end
end

function Altoholic:Search_OnTextChanged(box)
	self:Search_UpdateHint(box, box.focused)
	box.searchAt = GetTime() + SEARCH_DELAY
end

function Altoholic:Search_OnUpdate(box)
	if box.searchAt and GetTime() >= box.searchAt then
		box.searchAt = nil
		if box:GetText() == "" then
			self:SearchClearResults()
		else
			self:SearchItem()
		end
	end
end

-- The Search menu and the slot filter are labelled with the client's item class
-- names, so they are built at PLAYER_LOGIN like the other tables (see Core.lua).
function Altoholic:BuildSearchSubMenu()
	self.EquipmentSlots[17] = ItemSubClassName(ARMOR, 6)
	self.Menu[MENU_SEARCH].subMenu = {
		{ name = ItemClassName(WEAPON), isCollapsed = true,
			subMenu = {
				SearchEntry(L["Any"], WEAPON),
				SearchEntry(L["1H Axes"], WEAPON, 0),
				SearchEntry(L["2H Axes"], WEAPON, 1),
				SearchEntry(L["1H Maces"], WEAPON, 4),
				SearchEntry(L["2H Maces"], WEAPON, 5),
				SearchEntry(L["1H Swords"], WEAPON, 7),
				SearchEntry(L["2H Swords"], WEAPON, 8),
				SearchEntry(nil, WEAPON, 2),		-- Bows
				SearchEntry(nil, WEAPON, 3),		-- Guns
				SearchEntry(nil, WEAPON, 18),		-- Crossbows
				SearchEntry(nil, WEAPON, 10),		-- Staves
				SearchEntry(nil, WEAPON, 19),		-- Wands
				SearchEntry(nil, WEAPON, 6),		-- Polearms
				SearchEntry(nil, WEAPON, 15),		-- Daggers
				SearchEntry(nil, WEAPON, 13),		-- Fist Weapons
				SearchEntry(nil, WEAPON, 16),		-- Thrown
				SearchEntry(nil, WEAPON, 14),		-- Miscellaneous
				SearchEntry(nil, WEAPON, 20)		-- Fishing Poles
			},
			OnClick = function() Altoholic:Menu_Update(MENU_SEARCH, 1 )	end
		},
		{ name = ItemClassName(ARMOR), isCollapsed = true,
			subMenu = {
				SearchEntry(L["Any"], ARMOR),
				SearchEntry(nil, ARMOR, 0),		-- Miscellaneous
				SearchEntry(nil, ARMOR, 1),		-- Cloth
				SearchEntry(nil, ARMOR, 2),		-- Leather
				SearchEntry(nil, ARMOR, 3),		-- Mail
				SearchEntry(nil, ARMOR, 4),		-- Plate
				SearchEntry(nil, ARMOR, 6),		-- Shields
				SearchEntry(nil, ARMOR, 7),		-- Librams
				SearchEntry(nil, ARMOR, 8),		-- Idols
				SearchEntry(nil, ARMOR, 9)		-- Totems
			},
			OnClick = function() Altoholic:Menu_Update(MENU_SEARCH, 2 )	end
		},
		{ name = ItemClassName(Enum.ItemClass.Consumable),	isCollapsed = true,
			subMenu = {},
			OnClick = function() Altoholic:SearchItem(Enum.ItemClass.Consumable)	end
		},
		{ name = ItemClassName(Enum.ItemClass.Tradegoods),	isCollapsed = true,
			subMenu = {},
			OnClick = function()	Altoholic:SearchItem(Enum.ItemClass.Tradegoods)	end
		},
		{ name = ItemClassName(RECIPE), isCollapsed = true,
			subMenu = {
				SearchEntry(L["Any"], RECIPE),
				SearchEntry(nil, RECIPE, 6),		-- Alchemy
				SearchEntry(nil, RECIPE, 4),		-- Blacksmithing
				SearchEntry(nil, RECIPE, 8),		-- Enchanting
				SearchEntry(nil, RECIPE, 3),		-- Engineering
				SearchEntry(nil, RECIPE, 1),		-- Leatherworking
				SearchEntry(nil, RECIPE, 2),		-- Tailoring
				SearchEntry(nil, RECIPE, 0),		-- Book
				SearchEntry(nil, RECIPE, 5),		-- Cooking
				SearchEntry(nil, RECIPE, 7)		-- First Aid
			},
			OnClick = function() Altoholic:Menu_Update(MENU_SEARCH, 5 )	end
		}
	}
end

-- *** Menu Management ***
function Altoholic:SelectAlt(id)
	local FactionName, RealmName, CharacterName = strsplit(":", id)
	V.CurrentFaction = FactionName
	V.CurrentRealm = RealmName
	V.CurrentAlt = CharacterName
end

function Altoholic:BuildContainersSubMenu()
    self.Menu[MENU_CONTAINERS].subMenu = {}
	local n = 1
	for FactionName, f in pairs(self.db.account.data) do
		for RealmName, r in pairs(f) do
			table.insert(self.Menu[MENU_CONTAINERS].subMenu, {
				name = self:GetRealmString(FactionName, RealmName),
				isHeader = true,
				id = n,
				subMenu = {}
			} )
			local i = 1

			local byLevel = Altoholic:Get_Sorted_Character_List(FactionName, RealmName)
			for _, CharacterName in ipairs(byLevel) do
				local c = self.db.account.data[FactionName][RealmName].char[CharacterName]
				local altID = FactionName .. ":" .. RealmName .. ":" .. CharacterName
				table.insert(self.Menu[MENU_CONTAINERS].subMenu[n].subMenu, {
					name = CharacterName,
					altID = altID,
					id = (n*100)+i,
					OnClick = function(self)
						Altoholic:SelectAlt(altID)
						Altoholic:UpdateContainerCache()
						Altoholic:ClearScrollFrame(_G["AltoContainersScrollFrame"], "AltoContainersEntry", 7, 41)
						Altoholic:ActivateMenuItem("AltoContainers")
					end
				} )
				i = i + 1
			end
			n = n + 1
		end
	end
end

function Altoholic:BuildMailSubMenu()
    self.Menu[MENU_MAIL].subMenu = {}
	local n = 1
	for FactionName, f in pairs(self.db.account.data) do
		for RealmName, r in pairs(f) do
			table.insert(self.Menu[MENU_MAIL].subMenu, {
				name = self:GetRealmString(FactionName, RealmName),
				isHeader = true,
				id = n,
				subMenu = {}
			} )
			local i = 1
			local byLevel = Altoholic:Get_Sorted_Character_List(FactionName, RealmName)
			for _, CharacterName in ipairs(byLevel) do
				local c = self.db.account.data[FactionName][RealmName].char[CharacterName]
				if #c.mail >= 1 then
					CharacterNameM = CharacterName .. " " .. GREEN .. L["(has mail)"]
				end
				local altID = FactionName .. ":" .. RealmName .. ":" .. CharacterName
				table.insert(self.Menu[MENU_MAIL].subMenu[n].subMenu, {
					name = CharacterName,
					altID = altID,
					hasmail = CharacterNameM,
					id = (n*100)+i,
					OnClick = function(self)
						Altoholic:SelectAlt(altID)
						Altoholic:ActivateMenuItem("AltoMail")
					end
				} )
				i = i + 1
			end
			n = n + 1
		end
	end
end

function Altoholic:BuildEquipmentSubMenu()
    self.Menu[MENU_EQUIPMENT].subMenu = {}
	local n = 1
	for FactionName, f in pairs(self.db.account.data) do
		for RealmName, r in pairs(f) do
			local byLevel = Altoholic:Get_Sorted_Character_List(FactionName, RealmName)
			CharacterName = byLevel[1]
			local altID = FactionName .. ":" .. RealmName .. ":" .. CharacterName
			table.insert(self.Menu[MENU_EQUIPMENT].subMenu, {
				name = self:GetRealmString(FactionName, RealmName),
				realm = FactionName .. ":" .. RealmName,
				id = (n*100)+1,
				subMenu = {},
				OnClick = function(self)
					Altoholic:SelectAlt(altID)
					Altoholic:ActivateMenuItem("AltoEquipment")
				end
			} )
			n = n + 1
		end
	end
end

function Altoholic:BuildQuestsSubMenu()
    self.Menu[MENU_QUESTS].subMenu = {}
	local n = 1
	for FactionName, f in pairs(self.db.account.data) do
		for RealmName, r in pairs(f) do
			table.insert(self.Menu[MENU_QUESTS].subMenu, {
				name = self:GetRealmString(FactionName, RealmName),
				isHeader = true,
				id = n,
				subMenu = {}
			} )
			local i = 1
			local byLevel = Altoholic:Get_Sorted_Character_List(FactionName, RealmName)
			for _, CharacterName in ipairs(byLevel) do
				local c = self.db.account.data[FactionName][RealmName].char[CharacterName]
				local altID = FactionName .. ":" .. RealmName .. ":" .. CharacterName
				table.insert(self.Menu[MENU_QUESTS].subMenu[n].subMenu, {
					name = CharacterName,
					altID = altID,
					id = (n*100)+i,
					OnClick = function(self)
						Altoholic:SelectAlt(altID)
						Altoholic:ActivateMenuItem("AltoQuests")
					end
				} )
				i = i + 1
			end
			n = n + 1
		end
	end
end

function Altoholic:BuildRecipesSubMenu()
    self.Menu[MENU_RECIPES].subMenu = nil
    self.Menu[MENU_RECIPES].subMenu = {}
	self.Menu[MENU_RECIPES].isCollapsed = true
	local n = 1
	for FactionName, f in pairs(self.db.account.data) do
		for RealmName, r in pairs(f) do
			table.insert(self.Menu[MENU_RECIPES].subMenu, {
				name = self:GetRealmString(FactionName, RealmName),
				isHeader = true,
				id = n,
				subMenu = {}
			} )
			local i = 1
			local byLevel = Altoholic:Get_Sorted_Character_List(FactionName, RealmName)
			for _, CharacterName in ipairs(byLevel) do
				local c = self.db.account.data[FactionName][RealmName].char[CharacterName]
				local altID = FactionName .. ":" .. RealmName .. ":" .. CharacterName
				-- a character only expands to its professions (Altoholic:MenuRow_OnClick);
				-- without any it is shown greyed out
				table.insert(self.Menu[MENU_RECIPES].subMenu[n].subMenu, {
					name = CharacterName,
					altID = altID,
					isCollapsed = true,
					subMenu = {}
				} )
				for TradeSkillName, _ in pairs(c.recipes) do
					local skillName = Altoholic:GetProfessionID(TradeSkillName)
					if skillName then
						local skillsID = skillName + (n * 10000) + (i * 100)
						table.insert(self.Menu[MENU_RECIPES].subMenu[n].subMenu[i].subMenu, {
							name = TradeSkillName,
							id = skillName + (n * 10000) + (i * 100),
							OnClick = function(self)
								if skillName == 14 then return end -- disguise has no recipes
								local id = skillsID
								local skillID = (id % 100)
								id = floor(id / 100)
								Altoholic:SelectAlt(altID)
								Altoholic:SelectProfession(skillID)
								Altoholic:ActivateMenuItem("AltoRecipes")
							end
						} )
					end
				end
				i = i + 1
			end
			n = n + 1
		end
	end
end

function Altoholic:BuildAuctionsSubMenu()
    self.Menu[MENU_AUCTIONS].subMenu = {}
    local n = 1
	for FactionName, f in pairs(self.db.account.data) do
		for RealmName, r in pairs(f) do
			table.insert(self.Menu[MENU_AUCTIONS].subMenu, {
				name = self:GetRealmString(FactionName, RealmName),
				isHeader = true,
				id = n,
				subMenu = {}
			} )
			local i = 1
			local byLevel = Altoholic:Get_Sorted_Character_List(FactionName, RealmName)
			for _, CharacterName in ipairs(byLevel) do
				local c = self.db.account.data[FactionName][RealmName].char[CharacterName]
				local CharacterName = CharacterName
				local altID = FactionName .. ":" .. RealmName .. ":" .. CharacterName
				if #c.auctions >= 1 then
					CharacterName = CharacterName .. " " .. GREEN .. L["(has auctions)"]
				end
				table.insert(self.Menu[MENU_AUCTIONS].subMenu[n].subMenu, {
					name = CharacterName,
					altID = altID,
					id = (n*100)+i,
					OnClick = function(self)
						Altoholic.Auctions_Update = Altoholic.Auctions_Update_Auctions
						V.AuctionType = "auctions"
						Altoholic:SelectAlt(altID)
						Altoholic:ActivateMenuItem("AltoAuctions")
					end
				} )
				i = i + 1
			end
            n = n + 1
		end
	end
end

function Altoholic:BuildBidsSubMenu()
	self.Menu[MENU_BIDS].subMenu = {}
	local n = 1
	for FactionName, f in pairs(self.db.account.data) do
		for RealmName, r in pairs(f) do
			table.insert(self.Menu[MENU_BIDS].subMenu, {
				name = self:GetRealmString(FactionName, RealmName),
				isHeader = true,
				id = n,
				subMenu = {}
			} )
			local i = 1
			local byLevel = Altoholic:Get_Sorted_Character_List(FactionName, RealmName)
			for _, CharacterName in ipairs(byLevel) do
				local c = self.db.account.data[FactionName][RealmName].char[CharacterName]
				local altID = FactionName .. ":" .. RealmName .. ":" .. CharacterName
				local CharacterName = CharacterName
				if #c.bids > 0 then
					CharacterName = CharacterName .. " " .. GREEN .. L["(has bids)"]
				end
				table.insert(self.Menu[MENU_BIDS].subMenu[n].subMenu, {
					name = CharacterName,
					altID = altID,
					id = (n*100)+i,
					OnClick = function(self)
						Altoholic.Auctions_Update = Altoholic.Auctions_Update_Bids
						V.AuctionType = "bids"
						Altoholic:SelectAlt(altID)
						Altoholic:ActivateMenuItem("AltoAuctions")
					end
				} )
				i = i + 1
			end
			n = n + 1
		end
	end
end

function Altoholic:BuildFactionsTable()
	local repDB = self.db.account.data[V.faction][V.realm].reputation
	if V.Factions then
        Altoholic.vars.Factions = {}
	else
		V.Factions = {}
	end
	local factionGroup
	for i, f in pairs(self.FactionsRefTable) do
		if type(f) == "string" then
			for repName, _ in pairs(repDB) do
				if repName == f then
					if factionGroup ~= nil then
						table.insert(V.Factions, {
							name = self.FactionsRefTable[factionGroup][1],
							isHeader = true,
							isCollapsed = false
						} )
						factionGroup = nil
					end
					table.insert(V.Factions, f)
					break
				end
			end
		else
			factionGroup = i
		end
	end
end

function Altoholic:SelectProfession(id)
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
        if id == i then
            local ProfessionLevel
            V.CurrentProfession = v
            if id < 8 then
                ProfessionLevel = Altoholic.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt].skill[L["Professions"]][V.CurrentProfession]
            elseif id == 8 or id == 9 or id == 10 or id == 11 or id == 15 then
                ProfessionLevel = Altoholic.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt].skill[L["Secondary Skills"]][V.CurrentProfession]
            elseif id == 12 or id == 13 then
                if c.class ~= L["Rogue"] then
			        return
		        end
                ProfessionLevel = Altoholic.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt].skill[L["Rogue Proficiencies"]][V.CurrentProfession]
            end
            local rank, maxRank
            if ProfessionLevel then
                rank, maxRank = strsplit("|", ProfessionLevel)
            end
            if rank == nil then rank = '0' end
            if maxRank == nil then maxRank = '?' end
            V.CurrentProfessionLevel = Altoholic:GetSkillColor(tonumber(rank)) .. rank .. "/" .. maxRank
        end
    end
end

function Altoholic:ClearScrollFrame(name, entry, lines, height)
	for i=1, lines do
		_G[entry..i]:Hide()
	end
	FauxScrollFrame_Update(name, lines, lines, height);
end

function Altoholic:CreateScrollLines(parentFrame, inheritsFrom, numLines, numItems)
	local f = CreateFrame("Button", parentFrame .. "Entry" .. 1, _G[parentFrame], inheritsFrom)
	f:SetPoint("TOPLEFT", parentFrame .. "ScrollFrame", "TOPLEFT", 0, 0)
	for i = 2, numLines do
		f = CreateFrame("Button", parentFrame .. "Entry" .. i, _G[parentFrame], inheritsFrom)
		f:SetPoint("TOPLEFT", parentFrame .. "Entry" .. (i-1), "BOTTOMLEFT", 0, 0)
	end
	if not numItems then return end
	for i=1, numLines do
		_G[parentFrame.."Entry"..i.."Item" .. numItems]:SetPoint("BOTTOMRIGHT", parentFrame .. "Entry"..i, "BOTTOMRIGHT", -15, 0);
		for j=(numItems-1), 1, -1 do
			_G[parentFrame.."Entry"..i.."Item" .. j]:SetPoint("BOTTOMRIGHT", parentFrame.."Entry"..i.."Item" .. (j + 1), "BOTTOMLEFT", -5, 0);
		end
	end
end

function Altoholic:GetCharacterInfo(line)
	for i = line-1, 1, -1 do
		local s = self.CharacterInfo[i]
		if s.linetype == INFO_REALM_LINE then
			return s.faction, s.realm
		end
	end
end

function Altoholic:UpdateMinimapIconCoords()
	local xPos, yPos = GetCursorPosition()
	local left, bottom = Minimap:GetLeft(), Minimap:GetBottom()
	xPos = left - xPos/UIParent:GetScale() + 70
	yPos = yPos/UIParent:GetScale() - bottom - 70
	local O = self.db.account.options
	O.MinimapIconAngle = math.deg(math.atan2(yPos, xPos))
	if(O.MinimapIconAngle < 0) then
		O.MinimapIconAngle = O.MinimapIconAngle + 360
	end
	_G["AltoOptions_SliderAngle"]:SetValue(O.MinimapIconAngle)
end

function Altoholic:UpdateSlider(name, text, field)
	local s = _G[name]
	_G[name .. "Text"]:SetText(text .. " (" .. s:GetValue() ..")");
	local a = self.db and self.db.account
	if a == nil then return	end
	a.options[field] = s:GetValue()
	self:MoveMinimapIcon()
end

function Altoholic:MoveMinimapIcon()
	local O = self.db.account.options
	AltoholicMinimapButton:SetPoint(	"TOPLEFT", "Minimap", "TOPLEFT",
		54 - (O.MinimapIconRadius * cos(O.MinimapIconAngle)),
		(O.MinimapIconRadius * sin(O.MinimapIconAngle)) - 55	);
end

-- *** Overloaded events (OnEnter, OnClick ..) ***
function Altoholic:DrawCharacterTooltip(frame, charName)
	local c = self.db.account.data[V.CurrentFaction][V.CurrentRealm].char[charName]
	AltoTooltip:SetOwner(frame, "ANCHOR_LEFT");
	AltoTooltip:ClearLines();
	AltoTooltip:AddLine(Altoholic:GetClassColor(c.class)..charName,1,1,1);
	AltoTooltip:AddLine(L["Level"] .. " " .. GREEN .. c.level .. " |r".. c.race .. " " .. c.class,1,1,1);
	AltoTooltip:AddLine(L["Zone"] .. ": " .. GOLD .. c.zone .. " |r(" .. GOLD .. c.subzone .."|r)",1,1,1);
	if c.restxp then
		AltoTooltip:AddLine(L["Rest XP"] .. ": " .. GREEN .. c.restxp,1,1,1);
	end
	AltoTooltip:Show();
end

Altoholic_sorted_character_list = nil
Altoholic_compare_faction = nil
Altoholic_compare_realm = nil

-- *** EVENT HANDLERS ***
-- tabs listing items, which may have been drawn before the client knew the item
local ItemTabs = {
	AltoContainers = "Containers_Update",
	AltoMail = "Mail_Update",
	AltoSearch = "Search_Update",
	AltoEquipment = "Equipment_Update",
	AltoRecipes = "Recipes_Update",
	AltoAuctions = "Auctions_Update",
}

function Altoholic:GET_ITEM_INFO_RECEIVED(itemID, success)
	-- a failed query must not trigger a redraw, the redraw would only query the item again
	if not success or V.ItemRefreshPending or not AltoholicFrame:IsVisible() then return end
	V.ItemRefreshPending = true
	C_Timer.After(0.5, function()
		V.ItemRefreshPending = nil
		for frame, update in pairs(ItemTabs) do
			if _G[frame]:IsVisible() and Altoholic[update] then
				Altoholic[update](Altoholic)
			end
		end
	end)
end
