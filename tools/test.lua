-- Offline test for Altoholic's data layer: loads the files the TOC lists (without the window:
-- no XML, no Altoholic.lua, no Modules), fires the login and scan events against stubbed
-- 1.12 / ClassicAPI functions and checks what lands in the saved data.
--
-- Run from the repo root:  luajit tools/test.lua
-- (LuaJIT for Lua 5.1 syntax, which the addon uses through ClassicAPI.)
--
-- Any global the addon reads that isn't stubbed below resolves to a stub too: an
-- ALL_CAPS name is a global string (returns its own name), a CamelCase name a function
-- returning nil, a C_Name a table of such functions. Unknown names are reported at the end,
-- so a missing stub shows up instead of hiding a typo; luacheck catches the typos.

local root = arg[1] or "."
local failures, unknown = 0, {}

local function check(cond, what)
	if cond then
		print("ok   " .. what)
	else
		failures = failures + 1
		print("FAIL " .. what)
	end
end

-- *** Lua 5.0 / WoW globals ***
getmetatable("").__index = string
bit = bit or require("bit")
strtrim = function(s) return (string.gsub(s, "^%s*(.-)%s*$", "%1")) end
strsplit = function(sep, s)
	local out = {}
	for part in string.gmatch(s .. sep, "(.-)" .. sep:gsub("%p", "%%%0")) do table.insert(out, part) end
	return unpack(out)
end
format, floor, tinsert, tremove, strlower = string.format, math.floor, table.insert, table.remove, string.lower
mod = math.fmod
cos, sin = function(d) return math.cos(math.rad(d)) end, function(d) return math.sin(math.rad(d)) end
time = os.time
date = os.date
local now = 1000
GetTime = function() return now end
debugstack = function() return "" end
hooksecurefunc = function(name, fn)
	local orig = _G[name]
	_G[name] = function(...) local r = { orig(...) } fn(...) return unpack(r) end
end

-- frames: any method not written out here does nothing and returns nil
local frames = {}
local noop = function() end
local frameMethods = {}
local function NewFrame(kind)
	local f = setmetatable({ scripts = {}, events = {}, kind = kind, shown = true, height = 300, width = 300,
		text = "", level = 1 }, { __index = function(_, k) return frameMethods[k] or (type(k) == "string" and k:match("^%u") and noop) or nil end })
	table.insert(frames, f)
	return f
end
function frameMethods:RegisterEvent(e) self.events[e] = true end
function frameMethods:UnregisterEvent(e) self.events[e] = nil end
function frameMethods:SetScript(name, fn) self.scripts[name] = fn end
function frameMethods:GetScript(name) return self.scripts[name] end
function frameMethods:HookScript(name, fn) self.scripts[name] = fn end
function frameMethods:Show()
	if not self.shown then
		self.shown = true
		if self.scripts.OnShow then self.scripts.OnShow(self) end
	end
end
function frameMethods:Hide()
	if self.shown then
		self.shown = false
		if self.scripts.OnHide then self.scripts.OnHide(self) end
	end
end
function frameMethods:IsShown() return self.shown end
function frameMethods:IsVisible() return self.shown end
function frameMethods:GetHeight() return self.height end
function frameMethods:GetWidth() return self.width end
function frameMethods:SetHeight(h) self.height = h end
function frameMethods:SetWidth(w) self.width = w end
function frameMethods:GetFrameLevel() return self.level end
function frameMethods:SetText(t) self.text = t end
function frameMethods:GetText() return self.text end
function frameMethods:GetStringWidth() return 50 end
function frameMethods:GetEffectiveScale() return 1 end
function frameMethods:GetChecked() return self.checked end
function frameMethods:SetChecked(c) self.checked = c end
function frameMethods:IsEnabled() return 1 end
function frameMethods:GetValue() return self.value or 0 end
function frameMethods:SetValue(v)
	self.value = v
	if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, v) end
end
function frameMethods:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
function frameMethods:CreateTexture() return NewFrame("Texture") end
function frameMethods:GetThumbTexture() self.thumb = self.thumb or NewFrame("Texture") return self.thumb end
function frameMethods:GetCheckedTexture() self.checkTex = self.checkTex or NewFrame("Texture") return self.checkTex end
function frameMethods:CreateFontString() return NewFrame("FontString") end
CreateFrame = function(kind, name)
	local f = NewFrame(kind)
	if name then rawset(_G, name, f) end
	return f
end
UIParent = NewFrame("Frame")
Minimap = NewFrame("Frame")
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
UISpecialFrames = {}
GameTooltip, ItemRefTooltip = NewFrame("GameTooltip"), NewFrame("GameTooltip")
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}

local timers = {}
C_Timer = { After = function(_, fn) table.insert(timers, fn) end }
local function RunTimers()
	local t = timers
	timers = {}
	for _, fn in ipairs(t) do fn() end
end

local function Fire(event, ...)
	for _, f in ipairs(frames) do
		if f.events[event] and f.scripts.OnEvent then
			f.scripts.OnEvent(f, event, ...)
		end
	end
end

-- *** the character ***
CLASSIC_API_VERSION = 11810
GetLocale = function() return "enUS" end
GetBuildInfo = function() return "1.12.1", "5875" end
GetAddOnInfo = function(name) return name, name, "", nil, nil, "MISSING" end
UnitName = function() return "Testchar" end
UnitFactionGroup = function() return "Alliance" end
GetRealmName = function() return "Testrealm" end
UnitLevel = function() return 42 end
UnitRace = function() return "Dwarf" end
UnitClass = function() return "Hunter" end
UnitXP, UnitXPMax, GetXPExhaustion = function() return 100 end, function() return 1000 end, function() return 500 end
GetMoney = function() return 123456 end
GetRealZoneText, GetSubZoneText = function() return "Ironforge" end, function() return "The Commons" end
IsResting = function() return 1 end
GetPVPLifetimeStats = function() return 0, 0 end
GetPVPLastWeekStats = function() return 0, 0, 0, 0 end
GetNumTalentTabs = function() return 3 end
GetNumTalents = function() return 0 end
GetTalentTabInfo = function(i) return "Tab", "", ({ 10, 21, 0 })[i] end
GetNumSkillLines = function() return 2 end
GetSkillLineInfo = function(i)
	if i == 1 then return "Professions", 1 end
	return "Mining", nil, nil, 150, nil, nil, 225
end
GetSpellName = function(i) if i == 1 then return "Auto Shot", "" end end
GetNumFactions = function() return 0 end
GetNumSavedInstances = function() return 0 end
GetInventoryItemLink = function(_, slot) if slot == 1 then return "|cffffffff|Hitem:2589:0:0:0|h[Linen Cloth]|h|r" end end
GetInventoryItemTexture = function() return "icon" end
ContainerIDToInventoryID = function(bag) return 19 + bag end

-- bag 0 holds 5 Linen Cloth in slot 1, bag 1 is a 6-slot bag with an enchanted sword in slot 2
local bags = {
	[0] = { size = 16, items = { [1] = { link = "|cffffffff|Hitem:2589:0:0:0|h[Linen Cloth]|h|r", count = 5 } } },
	[1] = { size = 6, items = { [2] = { link = "|cff1eff00|Hitem:15248:1:0:0|h[Gleaming Claymore]|h|r", count = 1 } } },
}
GetContainerNumSlots = function(bag) return bags[bag] and bags[bag].size or 0 end
GetContainerItemLink = function(bag, slot) local b = bags[bag] return b and b.items[slot] and b.items[slot].link end
GetContainerItemInfo = function(bag, slot)
	local it = bags[bag] and bags[bag].items[slot]
	if it then return "icon", it.count end
end

-- a profession window with one header and one recipe
GetTradeSkillLine = function() return "Mining" end
GetNumTradeSkills = function() return 2 end
GetTradeSkillInfo = function(i)
	if i == 1 then return "Smelting", "header", 0, 1 end
	return "Smelt Copper", "trivial", 0
end
GetTradeSkillItemLink = function() return "|cffffffff|Hitem:2840:0:0:0|h[Copper Bar]|h|r" end
GetTradeSkillRecipeLink = function() return "|cffffd000|Henchant:2657|h[Smelt Copper]|h|r" end
GetTradeSkillNumReagents = function() return 1 end
GetTradeSkillReagentInfo = function() return "Copper Ore", "icon", 1, 0 end
GetTradeSkillReagentItemLink = function() return "|cffffffff|Hitem:2770:0:0:0|h[Copper Ore]|h|r" end
GetTradeSkillReagentItemID = function() return 2770 end
GetTradeSkillItemID = function() return 2840 end
GetItemClassInfo = function(c) return "Class" .. c end
GetItemSubClassInfo = function(c, s) return "Sub" .. c .. "." .. s end
GetQuestLogSelection, GetNumQuestLogEntries = function() return 0 end, function() return 0 end
ERR_LEARN_RECIPE_S = "You have learned how to create a new item: %s."
SendMail = function() end
SetItemRef = function() end

-- *** unknown globals become stubs ***
local stubTable
local function Stub(name)
	if name:match("^Altoholic") then
		return nil
	elseif name:match("^C_") or name == "Enum" then
		return stubTable(name)
	elseif name:match("^[A-Z0-9_]+$") then
		return name
	elseif name:match("^%u") then
		return function() end
	end
end
stubTable = function(prefix)
	return setmetatable({}, { __index = function(t, k)
		local v = type(k) == "string" and (k:match("^%u%l") and prefix ~= "Enum" and function() end
			or stubTable(prefix .. "." .. k)) or nil
		if prefix == "Enum" or prefix:match("^Enum%.") then v = 0 end
		if prefix == "Enum" then v = stubTable("Enum." .. k) end
		rawset(t, k, v)
		return v
	end })
end
setmetatable(_G, { __index = function(_, name)
	local v = Stub(name)
	if v ~= nil then
		unknown[name] = true
		rawset(_G, name, v)
	end
	return v
end })

-- *** load the TOC, data layer only ***
local skip = { ["Altoholic.lua"] = true }
local toc = assert(io.open(root .. "/Altoholic_ClassicAPI.toc"))
for raw in toc:lines() do
	local line = raw:gsub("\r", ""):gsub("\\", "/")
	if line ~= "" and not line:match("^#") and line:match("%.lua$") and not skip[line] then
		local chunk = assert(loadfile(root .. "/" .. line))
		chunk()
	end
end
toc:close()

-- *** the session ***
Fire("PLAYER_LOGIN")
check(Altoholic.db and Altoholic.db.account, "PLAYER_LOGIN sets up the database without the window")
Fire("PLAYER_ENTERING_WORLD")
RunTimers()	-- StartScanning, one second later

local c = Altoholic.db.account.data.Alliance.Testrealm.char.Testchar
check(c.level == 42 and c.class == "Hunter" and c.race == "Dwarf", "level, class and race")
check(c.money == 123456, "money")
check(c.zone == "Ironforge" or c.zone == "", "zone")
check(c.bag.Bag0.size == 16 and c.bag.Bag0.ids[1] == 2589 and c.bag.Bag0.counts[1] == 5, "backpack contents")
check(c.bag.Bag1.ids[2] == 15248 and c.bag.Bag1.links[2] ~= nil, "an enchanted item keeps its link")
check(c.bag.Bag0.freeslots == 15, "free slots")
check(c.inventory[1] == 2589, "equipment")
check(c.skill.Professions.Mining == "150|225", "skills")
check(GameTooltip.scripts.OnTooltipSetItem ~= nil, "tooltip hook installed")

-- a stack grows, BAG_UPDATE_DELAYED rescans
bags[0].items[1].count = 7
Fire("BAG_UPDATE_DELAYED")
check(c.bag.Bag0.counts[1] == 7, "bags rescan on BAG_UPDATE_DELAYED")

-- opening a profession records its recipes
Fire("TRADE_SKILL_SHOW")
local mining = rawget(c.recipes, "Mining")
check(mining and mining.ScanFailed == false or (mining and mining.ScanFailed == nil), "profession scan completed")
local found
for _, r in pairs(mining and mining.list or {}) do
	if type(r) == "table" and r.name and r.name:find("Smelt Copper") then found = r end
end
check(found ~= nil, "recipe recorded")
check(found and found.reagents and found.reagents:find("2770"), "recipe reagents recorded")

-- a list saved before 2.0: a recipe still flagged as the header its row once was, a header
-- still holding an old recipe's link, and a row left from a longer list
local list = c.recipes.Mining.list
list[2].isHeader = true
list[3] = { name = "Old Header", isHeader = true, link = "|cffffffff|Hitem:1:0:0:0|h[Gone Item]|h|r", id = 1 }
check(not Altoholic:IsRecipeHeader(list[2]) and Altoholic:IsRecipeHeader(list[3]), "stale rows: the recipe reads as a recipe, the header as a header")
Altoholic:RepairRecipeLists()
check(list[2].isHeader == nil and list[3].isHeader and list[3].link == nil, "the login repair fixes both")
Fire("TRADE_SKILL_SHOW")
check(rawget(list, 3) == nil and list[1].isHeader and not list[2].isHeader, "a rescan drops leftover rows")

check(Altoholic:RecipeKey("Simple Herbalist\226\128\153s Backpack") == "Simple Herbalist's Backpack"
	and not Altoholic:IsRecipeHeader({ isHeader = true, name = "Simple Herbalist\226\128\153s Backpack", link = "x" }),
	"a curly apostrophe matches the recipe list's straight one")

-- known recipes by spell ID: the scan saves each recipe's spell, IsPlayerSpell the rest
check(list[2].spell == 2657, "the scan saves the recipe's spell ID from its recipe link")
IsPlayerSpell = function(spell) return spell == 2657 or spell == 2658 end	-- Smelt Copper, Smelt Silver
Altoholic:ScanKnownRecipes()
check(c.knownRecipes.Mining and c.knownRecipes.Mining[2658] and not c.knownRecipes.Mining[3304], "IsPlayerSpell finds the known recipes")
local m2 = Altoholic:MissingRecipes(c, "Mining")
local silverMissing
for _, m in ipairs(m2) do if m.spell == 2658 then silverMissing = true end end
check(#m2 == 11 and not silverMissing, "a recipe known by spell ID isn't missing, though the window never listed it")
-- a recipe learned from an item: the chat line triggers a new check
IsPlayerSpell = function(spell) return spell == 2657 or spell == 2658 or spell == 3304 end	-- + Smelt Tin
Altoholic:CHAT_MSG_SYSTEM("You have learned how to create a new item: Smelt Tin.")
RunTimers()
check(c.knownRecipes.Mining[3304], "learning a recipe is noticed from its chat line")
IsPlayerSpell = nil

-- the options read from the database, not from the old check buttons
check(Altoholic:Option("TooltipSource") == 1 and Altoholic:Option("TooltipAlreadyKnown") == nil, "Option() reads the stored setting")

-- *** the window ***
local UI = Altoholic.UI
UI.Toggle()
check(AltoholicWindow and AltoholicWindow:IsShown(), "/alto opens the new window")
check(UI.current == UI.views.Summary, "it opens on the account summary")
local rows = UI.views.Summary.table.list.data
check(#rows == 3 and rows[1].header == "Testrealm" and rows[2].cells[1]:find("Testchar") and rows[3].total,
	"summary: realm, character, total")
check(#rows[2].cells == 8 and rows[2].cells[7]:find("Online") and #rows[3].cells == 8, "summary: Last Played after Played, the player online")
local ok, err = true, nil
for i, cat in ipairs(UI.categories) do
	local good, e = pcall(UI.SelectCategory, i)
	if not good then ok, err = false, cat.id .. ": " .. tostring(e) end
end
check(ok, "every category opens" .. (err and (" (" .. err .. ")") or ""))
for _, name in ipairs({ "Skills", "BagUsage" }) do
	local good, e = pcall(UI.ShowView, name)
	check(good and #UI.views[name].table.list.data == 2, name .. " lists the realm and the character" .. (good and "" or (": " .. tostring(e))))
end
for _, name in ipairs({ "Reputations", "Attunements", "Raids" }) do
	local good, e = pcall(UI.ShowView, name)
	check(good, name .. " opens" .. (good and "" or (": " .. tostring(e))))
end
-- deleting an alt: a second character, then gone again
local alt = Altoholic.db.account.data.Alliance.Testrealm.char.Altchar
alt.class, alt.level, alt.race = "Mage", 10, "Gnome"
check(#UI.Realms()[1].chars == 2, "a second character shows up")
check(not Altoholic:DeleteCharacter("Alliance", "Testrealm", "Testchar"), "the logged-in character can't be deleted")
check(Altoholic:DeleteCharacter("Alliance", "Testrealm", "Altchar") and #UI.Realms()[1].chars == 1, "an alt can")
UI.Open("about")
check(UI.current == UI.views.About and UI.current.info[1]:GetText() == Altoholic.vars.version, "About shows the version")
local deps = UI.current.deps.list.data
check(#deps == 5 and deps[1].cells[1] == "ClassicAPI" and deps[1].cells[3]:find("v1%.18%.10")
	and deps[2].cells[3]:find("Optional %- not installed"), "About's Needed column: ClassicAPI's version, pfUI optional and not installed")
UI.Open("options")
check(UI.current == UI.views.Options and UI.current.boxes.TooltipSource:GetChecked(), "options show the stored settings")
check(AltoholicMinimapIcon ~= nil, "the minimap button is made at login")
UI.Open("recipes")
check(UI.current and UI.current.args and UI.current.args.profession == "Mining", "Recipes opens the logged-in character's profession")
local rl = UI.current.lines
check(not UI.current.canQueue and not UI.current.list.rows[2].queue:IsShown(), "recipes: no Queue button without pfUI-trades")
-- with pfUI-trades: queue 3 Smelt Copper for the logged-in character
local queuedArgs
pfUITrades = {
	QueueFor = function(name, profession, task, count) queuedArgs = { name, profession, task, count } return task end,
	QueuedFor = function() return queuedArgs and queuedArgs[4] or 0 end,
}
C_Item = C_Item or {}
C_Item.GetItemNameByID = function(id) return "Item " .. id end
C_Item.GetItemIconByID = function() return "icon" end
UI.Open("recipes")
UI.current.count:SetText("3")
UI.current.list.rows[2].queue.scripts.OnClick(UI.current.list.rows[2].queue)
check(queuedArgs and queuedArgs[1] == "Testchar" and queuedArgs[2] == "Mining" and queuedArgs[4] == 3
	and queuedArgs[3].name == "Smelt Copper" and queuedArgs[3].reagents[1].id == 2770 and queuedArgs[3].reagents[1].count == 1,
	"recipes: Queue sends the recipe and its reagents to pfUI-trades")
check(UI.current.list.rows[2].queued:GetText():find("3"), "recipes: the row shows how many are queued")
pfUITrades = nil
-- item sources from pfQuest's database
check(not Altoholic:HasItemSources() and Altoholic:ItemSources(3396) == nil, "no sources without pfQuest")
pfDB = {
	items = { data = { [3396] = { V = { [10] = 1 }, U = { [20] = 2.5 }, R = { [5] = 0.4 } } } },
	units = { data = { [10] = { coords = { { 50, 50, 1519, 0 } } }, [20] = { coords = { { 1, 1, 40, 300 }, { 2, 2, 12, 300 } } } },
		loc = { [10] = "Vendor Vic", [20] = "Mob Max" } },
	objects = { data = { [30] = { coords = { { 5, 5, 40, 0 } } } }, loc = { [30] = "Battered Chest" } },
	refloot = { data = { [5] = { O = { [30] = true } } } },
	zones = { loc = { [1519] = "Stormwind City", [40] = "Westfall", [12] = "Elwynn Forest" } },
}
local src = Altoholic:ItemSources(3396)
check(src and src.vendors[1].name == "Vendor Vic" and src.vendors[1].zone == "Stormwind City"
	and src.drops[1].name == "Mob Max" and src.drops[1].zone == "Elwynn Forest, Westfall"
	and src.objects[1].name == "Battered Chest", "sources: vendor, drop with zones, and a chest from reference loot")
local tipLines = {}
local tip = { AddDoubleLine = function(_, l) table.insert(tipLines, l) end, AddLine = function(_, l) table.insert(tipLines, l) end }
check(Altoholic:AddItemSources(tip, 3396) and #tipLines == 3, "the tooltip gets a line per source")
local mapped
pfDatabase = { SearchItemID = function(_, id) mapped = id return { [1519] = 1 } end, GetBestMap = function(_, m) return next(m) end }
pfMap = { ShowMapID = function(_, map) mapped = mapped and map end, DeleteNode = function() end }
check(Altoholic:ShowItemOnMap(3396) and mapped == 1519, "an item goes on pfQuest's map")
pfDB, pfDatabase, pfMap = nil, nil, nil

-- missing recipes: Mining has 13, Testchar knows Smelt Copper (scanned), Silver and Tin (by spell ID)
local missing, total = Altoholic:MissingRecipes(c, "Mining")
check(total == 13 and #missing == 10, "missing recipes: all of Mining but the three known (" .. tostring(missing and #missing) .. "/" .. tostring(total) .. ")")
UI.Open("recipes")
check(UI.current.missing:IsShown(), "recipes: the Missing Recipes button shows for a known profession")
UI.current.missing.scripts.OnClick(UI.current.missing)
check(UI.current == UI.views.MissingRecipes and #UI.current.list.data == 10, "the button opens the missing list")
UI.views.MissingRecipes.only.checked = true	-- a click checks it before OnClick runs
UI.views.MissingRecipes.only.scripts.OnClick(UI.views.MissingRecipes.only)
local learnable = #UI.current.list.data
check(learnable > 0 and learnable < 10, "and it narrows to what skill 150 can learn (" .. learnable .. ")")
UI.views.MissingRecipes.only.checked = nil
UI.views.MissingRecipes.only.scripts.OnClick(UI.views.MissingRecipes.only)
check(rl and #rl == 2 and rl[1].header == "Smelting" and rl[2].recipe, "recipes: the header and the recipe")
for _, id in ipairs({ "quests", "auctions", "bids" }) do
	local good, e = pcall(UI.Open, id)
	check(good and UI.current.args and UI.current.args.name == "Testchar", id .. " opens on the logged-in character" .. (good and "" or (": " .. tostring(e))))
end
-- an auction: short time left in the cell, bid and buyout in their own columns
c.auctions[1] = { id = 2589, count = 5, timeLeft = 4, startPrice = 150, buyoutPrice = 300 }
AUCTION_TIME_LEFT4, AUCTION_TIME_LEFT4_DETAIL = "Very Long", "Greater than 8 hours"
UI.Open("auctions")
local arow = UI.views.Auctions.list.rows[1]
check(arow.time.text:GetText():find("Very Long") and not arow.time.text:GetText():find("8 hours")
	and arow.bid:GetText() ~= "" and arow.buyout:GetText() ~= arow.bid:GetText(), "auctions: short time left, bid and buyout apart")
c.auctions[1] = nil
UI.Open("bids")
check(rawget(c.auctions, 1) == nil and rawget(c.bids, 1) == nil, "listing auctions and bids adds no empty entries")
UI.Open("mail")
check(UI.current == UI.views.Mail and rawget(c.mail, 1) == nil, "mail opens and adds no empty mail")
UI.Open("containers")
check(UI.current.args and UI.current.args.name == "Testchar", "Containers opens on the logged-in character")
local lines = UI.views.Containers.list.data
check(#lines == 2 and lines[1].bagID == 0 and lines[2].bagID == 1, "containers: a line per bag")
-- the height arrives late: the list notices on its next frame and draws more rows
local clist = UI.views.Containers.list
local before = #clist.rows
clist.height = 700
clist.scripts.OnUpdate(clist)
check(#clist.rows > before, "a list redraws when its height turns out larger (" .. before .. " -> " .. #clist.rows .. " rows)")
clist.height = 300
clist.scripts.OnUpdate(clist)
local slot = UI.views.Containers.list.rows[2].slots[2]
check(slot.item and tostring(slot.item):find("15248"), "containers: the enchanted item shows by its link")
-- searching: the text from the box, over this realm
GetItemInfo = function(id)
	local items = { [2589] = { "Linen Cloth", 1, 0, "" }, [15248] = { "Gleaming Claymore", 2, 20, "INVTYPE_2HWEAPON" } }
	local it = items[tonumber(id) or tonumber(tostring(id):match("item:(%d+)"))]
	if it then return it[1], "item:" .. id, it[2], it[3], "", "", 1, it[4], "icon" end
end
GetItemQualityColor = function() return 1, 1, 1, "|cffffffff" end
UI.searchBox:SetText("linen")
UI.Search("linen")
local found = UI.views.Search.list.data
check(UI.current == UI.views.Search and #found == 2 and found[1].id == 2589 and found[1].count == 7, "search finds the linen in the bags and the equipped slot")
UI.Search("claymore")
check(#UI.views.Search.list.data == 1, "and the claymore")
UI.Search("nothing like this")
check(#UI.views.Search.list.data == 0, "and nothing for a name no item has")
UI.Open("equipment")
check(UI.current == UI.views.Equipment and #UI.current.list.data == 20 and UI.current.chars[1].name == "Testchar",
	"equipment: the realm's characters, a line per slot")
C_Item = C_Item or {}
C_Item.GetItemInfoInstant = function() return 15248, "", "", "", "", 2, 8 end
Altoholic.LootTable = { ["Molten Core"] = { ["Ragnaros"] = { 15248 } } }
check(type(Altoholic:FindUpgrade(2589)) == "table", "an upgrade search runs")
-- who can use what: a hunter (class 3) at 42 can wear mail but not plate, and use bows not wands
local hunter = { class = "Hunter", level = 42 }
local kinds = { [101] = { 4, 3 }, [102] = { 4, 4 }, [103] = { 2, 2 }, [104] = { 2, 19 } }	-- mail, plate, bow, wand
C_Item.GetItemInfoInstant = function(id) local k = kinds[id] or { 15, 0 } return id, "", "", "", "", k[1], k[2] end
Enum.ItemClass.Armor, Enum.ItemClass.Weapon = 4, 2
check(Altoholic:CanUseItem(hunter, 101) and not Altoholic:CanUseItem(hunter, 102)
	and Altoholic:CanUseItem(hunter, 103) and not Altoholic:CanUseItem(hunter, 104), "a hunter: mail and bows yes, plate and wands no")
C_Item.GetItemDataByID = function(id) return id == 103 and { allowableClass = 128, requiredLevel = 1 } or nil end	-- mage only
check(not Altoholic:CanUseItem(hunter, 103), "an item for another class only isn't usable")
check(not Altoholic:CanUseItem({ class = "Hunter", level = 30 }, 101), "mail waits for level 40")
C_Item.GetItemDataByID = nil
-- the upgrade results page narrows to them
UI.ShowSearchResults({ { id = 101, iLvl = 50, location = "x" }, { id = 102, iLvl = 50, location = "y" } }, "test",
	{ name = "Hunt", c = hunter })
check(UI.views.Search.usable:IsShown() and #UI.views.Search.list.data == 1, "upgrade results show only what the character can use")
UI.views.Search.usable.checked = nil
UI.views.Search.usable.scripts.OnClick(UI.views.Search.usable)
check(#UI.views.Search.list.data == 2, "and all of them with the box unticked")
UI.views.Search.usable.checked = true
UI.views.Search.usable.scripts.OnClick(UI.views.Search.usable)
Altoholic:DataChanged("mail")
UI.Toggle()
check(not AltoholicWindow:IsShown(), "and closes again")

-- *** notes ***
check(Altoholic:AddNote("Testrealm", "Testchar", "  ") == nil, "an empty note isn't kept")
Altoholic:AddNote("Testrealm", "Testchar", "Sell the linen")
Altoholic:AddNote("Testrealm", "Testchar", "Train Mining")
check(Altoholic:NoteCount("Testrealm", "Testchar") == 2, "two notes kept")
UI.Toggle()
UI.notesButton.scripts.OnClick(UI.notesButton)
check(UI.current == UI.views.Notes and UI.current.args.name == "Testchar" and #UI.current.list.data == 2,
	"the Notes button opens the logged-in character's notes")
check(UI.notesButton.label:GetText():find("2"), "the Notes button counts them")
check(UI.ShowLoginNotes() and AltoholicNotesPopup:IsShown(), "the login popup shows them")
AltoholicNotesPopup.lines[1].done.scripts.OnClick(AltoholicNotesPopup.lines[1].done)
check(Altoholic:NoteCount("Testrealm", "Testchar") == 1 and #UI.current.list.data == 1, "Done removes one, the page follows")
UI.current.input:SetText("Buy coal")
UI.current:Add()
check(Altoholic:NoteCount("Testrealm", "Testchar") == 2 and UI.current.input:GetText() == "", "the page adds a note")
Altoholic:CmdNote("testchar Bank the ore")
check(Altoholic:NoteCount("Testrealm", "Testchar") == 3, "/alto note finds the character whatever the case")
AltoholicNotesPopup.done.scripts.OnClick(AltoholicNotesPopup.done)
check(Altoholic:NoteCount("Testrealm", "Testchar") == 0 and rawget(AltoholicDB.account, "notes") and next(AltoholicDB.account.notes) == nil,
	"Done with all clears them, and the empty tables go")
check(not UI.ShowLoginNotes(), "no popup without notes")
UI.Toggle()

Fire("PLAYER_LOGOUT")
check(AltoholicDB.account.data.Alliance.Testrealm.char.Testchar.level == 42, "data survives the logout cleanup")

local names = {}
for name in pairs(unknown) do table.insert(names, name) end
table.sort(names)
print("\nstubbed automatically: " .. table.concat(names, " "))
print(failures == 0 and "\nall passed" or ("\n" .. failures .. " failed"))
os.exit(failures == 0 and 0 or 1)
