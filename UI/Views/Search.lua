-- Search: the second column narrows the search to an item class, the filters sit across
-- the top of the page, the results below. The text comes from the search box at the
-- bottom of the window. Data/Search.lua does the searching.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local WEAPON, ARMOR, RECIPE = Enum.ItemClass.Weapon, Enum.ItemClass.Armor, Enum.ItemClass.Recipe
local YELLOW = "|cFFFFFF00"

-- GetItemClassInfo returns nil for Consumable (class 0), so each class has an English fallback
local CLASS_ENGLISH = {
	[Enum.ItemClass.Consumable] = "Consumable", [WEAPON] = "Weapon", [ARMOR] = "Armor",
	[Enum.ItemClass.Tradegoods] = "Trade Goods", [RECIPE] = "Recipe",
}

local function ClassName(classID)
	return GetItemClassInfo(classID) or L[CLASS_ENGLISH[classID]]
end

local function Entry(text, classID, subClassID)
	return { text = text or (GetItemSubClassInfo(classID, subClassID)), view = "Search",
		key = "search/" .. tostring(classID) .. "/" .. tostring(subClassID),
		args = { classID = classID, subClassID = subClassID } }
end

local function Parent(classID, subclasses)
	local e = { text = ClassName(classID), key = "search/" .. classID, children = { Entry(L["Any"], classID) } }
	for _, s in ipairs(subclasses) do
		local text = type(s) == "table" and s[2] or nil
		local id = type(s) == "table" and s[1] or s
		table.insert(e.children, Entry(text, classID, id))
	end
	return e
end

-- the second column of the Search category
function UI.SearchEntries()
	return {
		Entry(L["All items"]),
		Parent(WEAPON, { { 0, L["1H Axes"] }, { 1, L["2H Axes"] }, { 4, L["1H Maces"] }, { 5, L["2H Maces"] },
			{ 7, L["1H Swords"] }, { 8, L["2H Swords"] }, 2, 3, 18, 10, 19, 6, 15, 13, 16, 14, 20 }),
		Parent(ARMOR, { 0, 1, 2, 3, 4, 6, 7, 8, 9 }),
		Entry(ClassName(Enum.ItemClass.Consumable), Enum.ItemClass.Consumable),
		Entry(ClassName(Enum.ItemClass.Tradegoods), Enum.ItemClass.Tradegoods),
		Parent(RECIPE, { 6, 4, 8, 3, 1, 2, 0, 5, 7 }),
	}
end

local function SlotItems()
	local items = { { text = L["Any"], value = 0 } }
	for i = 1, 18 do
		local name = Altoholic.EquipmentSlots[i]
		if i == 17 then name = GetItemSubClassInfo(ARMOR, 6) end	-- shields
		if name then table.insert(items, { text = name, value = i }) end
	end
	return items
end

local function RarityItems()
	local items = {}
	for i = 0, 6 do
		local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[i]
		table.insert(items, { text = (color and color.hex or "") .. _G["ITEM_QUALITY" .. i .. "_DESC"], value = i })
	end
	return items
end

local SCOPES = {
	{ text = XML_TEXT_MAIN_WINDOW_2 or L["This realm"], value = "realm" },
	{ text = XML_TEXT_MAIN_WINDOW_3 or L["All realms"], value = "all" },
	{ text = XML_TEXT_MAIN_WINDOW_4 or L["Loot tables"], value = "loots" },
}

local view = {}

-- the filters, kept for the session
local filters = { scope = "realm", rarity = 0, slot = 0, noMinLevel = true, mail = true, recipes = true }
local onlyUsable = true		-- upgrade results: only what the character can use

function view:Create(frame, bar)
	local strip = CreateFrame("Frame", nil, frame)
	strip:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
	strip:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
	strip:SetHeight(48)
	-- the filters; upgrade results show the "only usable" box in their place
	local top = CreateFrame("Frame", nil, strip)
	top:SetAllPoints(strip)
	self.filters = top
	self.usable = W.Checkbox(strip, "", function(_, on)
		onlyUsable = on
		if self.upgrade then self:ShowUpgrades() end
	end)
	self.usable:SetPoint("TOPLEFT", strip, "TOPLEFT", 0, -4)
	self.usable:Hide()
	local function Rerun() self:Run() end

	local scope = W.Dropdown(top, 160, SCOPES, function(_, v) filters.scope = v Rerun() end)
	scope:SetPoint("TOPLEFT", top, "TOPLEFT", 0, 0)
	scope:SetValue(filters.scope)
	local rarity = W.Dropdown(top, 110, RarityItems, function(_, v) filters.rarity = v Rerun() end)
	rarity:SetPoint("LEFT", scope, "RIGHT", 8, 0)
	rarity:SetValue(filters.rarity)
	local slot = W.Dropdown(top, 120, SlotItems, function(_, v) filters.slot = v Rerun() end)
	slot:SetPoint("LEFT", rarity, "RIGHT", 8, 0)
	slot:SetValue(filters.slot)

	local levels = W.Text(top)
	levels:SetPoint("LEFT", slot, "RIGHT", 12, 0)
	levels:SetText(L["Level"])
	levels:SetTextColor(.7, .7, .7)
	local function Level(box, key)
		box:SetNumeric(true)
		box:SetMaxLetters(2)
		box.onChange = function(b)
			filters[key] = tonumber(b:GetText())
			b.runAt = GetTime() + .4
		end
		box:SetScript("OnUpdate", function(b)
			if b.runAt and GetTime() >= b.runAt then b.runAt = nil Rerun() end
		end)
	end
	local minLevel = W.EditBox(top, 30, 20, nil, Rerun)
	minLevel:SetPoint("LEFT", levels, "RIGHT", 6, 0)
	Level(minLevel, "minLevel")
	local dash = W.Text(top)
	dash:SetPoint("LEFT", minLevel, "RIGHT", 4, 0)
	dash:SetText("-")
	local maxLevel = W.EditBox(top, 30, 20, nil, Rerun)
	maxLevel:SetPoint("LEFT", dash, "RIGHT", 4, 0)
	Level(maxLevel, "maxLevel")

	local function Toggle(label, key, anchor, x)
		local cb = W.Checkbox(top, label, function(_, on) filters[key] = on Rerun() end)
		cb:SetPoint("TOPLEFT", anchor or top, anchor and "TOPRIGHT" or "TOPLEFT", x or 0, anchor and 0 or -30)
		cb:SetChecked(filters[key])
		return cb
	end
	local noMin = Toggle(XML_TEXT_MAIN_WINDOW_1 or L["Include items without level requirement"], "noMinLevel")
	local mail = Toggle(XML_TEXT_MAIN_WINDOW_5 or L["Include mailboxes"], "mail", noMin, noMin.label:GetStringWidth() + 24)
	Toggle(XML_TEXT_MAIN_WINDOW_7 or L["Include known recipes"], "recipes", mail, mail.label:GetStringWidth() + 24)

	local holder = CreateFrame("Frame", nil, frame)
	holder:SetPoint("TOPLEFT", strip, "BOTTOMLEFT", 0, -6)
	holder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
	self.list = W.List(holder, 26,
		function(row)
			row.icon = W.ItemButton(row, 22)
			row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
			row.name = W.Text(row)
			row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
			row.name:SetWidth(200)
			row.who = W.Text(row)
			row.who:SetPoint("LEFT", row.name, "RIGHT", 8, 0)
			row.who:SetWidth(150)
			row.where = W.Text(row)
			row.where:SetPoint("LEFT", row.who, "RIGHT", 8, 0)
			row.where:SetWidth(160)
			row.extra = W.Text(row, nil, "RIGHT")
			row.extra:SetPoint("LEFT", row.where, "RIGHT", 8, 0)
			row.extra:SetPoint("RIGHT", row, "RIGHT", -4, 0)
			row.hl = row:CreateTexture(nil, "HIGHLIGHT")
			row.hl:SetAllPoints(row)
			row.hl:SetColorTexture(1, 1, 1, .05)
			-- a recipe's line shows the recipe, not the item it makes
			row:SetScript("OnEnter", function(r)
				if r.item and r.item.craftLink then
					GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
					GameTooltip:SetHyperlink(r.item.craftLink)
					if r.item.recipe and Altoholic:CanQueueCrafts(r.item.realmName) then
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine(L["Right-click to queue it in pfUI-trades"], .2, 1, .8)
					end
					GameTooltip:Show()
				end
			end)
			row:SetScript("OnLeave", function() GameTooltip:Hide() end)
			row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			row:SetScript("OnClick", function(r, button)
				local s = r.item
				if not s or not s.craftLink then return end
				if button == "RightButton" then
					-- queue the recipe on whoever knows it, in pfUI-trades
					if not s.recipe or not Altoholic:CanQueueCrafts(s.realmName) then return end
					local items = {}
					for _, n in ipairs({ 1, 5, 10, 20 }) do
						table.insert(items, { text = format(L["Queue %d on %s"], n, s.char), func = function()
							if Altoholic:QueueCraft(s.name, s.realmName, s.profession, s.recipe, n) then
								DEFAULT_CHAT_FRAME:AddMessage(W.TEAL_HEX .. "Altoholic:|r " .. format(L["queued %d x %s for %s"], n, s.recipe.name, s.name))
							end
						end })
					end
					W.ShowMenu(r, items)
				elseif IsShiftKeyDown() and ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
					ChatFrameEditBox:Insert(s.craftLink)
				end
			end)
		end,
		function(row, s)
			row.icon:SetItem(s.id, s.count, s.id and nil or "Interface\\Icons\\Trade_Engraving")
			local name, quality
			if s.id then name, _, quality = GetItemInfo(s.id) end
			local hex = "|cFFFFFFFF"
			if quality then
				local _, _, _, h = GetItemQualityColor(quality)
				hex = h or hex
			end
			row.name:SetText(hex .. (s.craftName or name or ("item:" .. tostring(s.id))))
			row.who:SetText(s.char or "")
			row.where:SetText(s.craftLink and (W.TEAL_HEX .. s.location) or (s.location or ""))
			if s.iLvl then
				row.extra:SetText(L["Item Level"] .. ": " .. YELLOW .. s.iLvl)
			else
				row.extra:SetText(s.realm or "")
			end
		end)
	self.message = W.Message(holder)
	self.status = W.Text(bar)
	self.status:SetPoint("LEFT", bar, "LEFT", 4, 0)
	self.status:SetTextColor(.7, .7, .7)
end

-- Shows a list that was worked out elsewhere: an equipment upgrade search for ref, whose
-- results the "only usable" box can narrow to what that character can use.
function UI.ShowSearchResults(results, title, ref)
	UI.pendingResults = { results = results, title = title, ref = ref }
	UI.Open("search")
end

function view:Show(results, emptyText)
	self.list:SetData(results)
	if #results == 0 then
		self.message:SetText(emptyText)
		self.message:Show()
	else
		self.message:Hide()
	end
end

-- upgrade results, narrowed to what the character can use while the box is ticked; the
-- equipped item they are compared with stays on top
function view:ShowUpgrades()
	local u = self.upgrade
	local shown = u.results
	if u.ref then
		self.usable.label:SetText(format(L["Only what %s can use"], UI.ClassHex(u.ref.c.class) .. u.ref.name .. "|r"))
		self.usable:SetChecked(onlyUsable)
		self.usable:Show()
		if onlyUsable then
			shown = {}
			for i, r in ipairs(u.results) do
				if (i == 1 and r.location == L["Currently equipped"]) or not r.id or Altoholic:CanUseItem(u.ref.c, r.id) then
					table.insert(shown, r)
				end
			end
		end
	else
		self.usable:Hide()
	end
	self.filters:Hide()
	self:Show(shown, L["No match found!"])
	self.status:SetText((u.title or "") .. "  " .. format(L["%d results"], #shown))
end

function view:Run()
	local args = self.args or {}
	local text = UI.searchText or ""
	if text == "" and not args.classID and filters.scope ~= "loots" then
		self:Show({}, L["Type in the search box below, or pick an item class."])
		self.status:SetText("")
		return
	end
	local f = {
		text = text, classID = args.classID, subClassID = args.subClassID, scope = filters.scope,
		rarity = filters.rarity, slot = filters.slot, minLevel = filters.minLevel, maxLevel = filters.maxLevel,
		noMinLevel = filters.noMinLevel, mail = filters.mail, recipes = filters.recipes,
	}
	local results = Altoholic:Search(f)
	self:Show(results, text ~= "" and (text .. L[" not found!"]) or L["No match found!"])
	local status = format(L["%d results"], #results)
	if filters.scope == "loots" then
		local O = Altoholic.db.account.options
		status = status .. "  |cff888888" .. O.TotalLoots .. " " .. L["Loots"] .. " / " .. O.UnknownLoots .. " " .. L["Unknown"]
	end
	self.status:SetText(status)
end

function view:Update(args)
	local pending = UI.pendingResults
	if pending then
		UI.pendingResults = nil
		self.upgrade = pending
		self:ShowUpgrades()
		return
	end
	self.upgrade = nil
	self.usable:Hide()
	self.filters:Show()
	self.args = args
	self:Run()
end

UI.RegisterView("Search", view)
