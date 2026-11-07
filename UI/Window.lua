-- The window, laid out like pfUI's config: the title and version top left, a small close
-- button top right, then a column of categories, a column of the selected category's
-- entries (characters under realm headers, item classes, ...) and the page. Under it, a
-- bar with the active view's controls on the left and the search box on the right.
--
-- A view is registered with UI.RegisterView(name, view):
--   view:Create(frame, bar)   once, the first time it is shown. frame fills the page, bar
--                             is the view's own strip of the bottom bar (shown with it)
--   view:Update(args)         each time it is shown, and when its data changes
-- A category lists entries; picking one shows entry.view with entry.args.

local L = Altoholic.L
local V = Altoholic.vars
local W = Altoholic.W

local UI = {}
Altoholic.UI = UI
UI.views = {}
UI.categories = {}

local WIDTH, HEIGHT = 960, 540
local COLUMN = 130		-- pfUI's menu column width
local ROW = 20			-- and row height
local SEARCH_DELAY = 0.4

function UI.RegisterView(name, view)
	UI.views[name] = view
end

-- *** Characters ***

-- the record of a character: ref = { faction, realm, name }
function UI.Char(ref)
	return Altoholic.db.account.data[ref.faction][ref.realm].char[ref.name]
end

function UI.IsPlayer(ref)
	return ref.name == V.player and ref.realm == V.realm
end

-- Every scanned character, grouped by realm, the logged-in character's realm first.
-- Both factions of a realm are listed together: this server lets them mail each other.
--   { { name = realm, chars = { { faction, realm, name, c }, ... } }, ... }
-- Characters by level, highest first, then by name.
function UI.Realms()
	local byRealm, list = {}, {}
	for faction, f in pairs(Altoholic.db.account.data) do
		for realm, r in pairs(f) do
			for name, c in pairs(rawget(r, "char") or {}) do
				-- no class: the record was only ever looked up, never scanned
				if type(c) == "table" and c.class and c.class ~= "" then
					if not byRealm[realm] then
						byRealm[realm] = { name = realm, chars = {} }
						table.insert(list, byRealm[realm])
					end
					table.insert(byRealm[realm].chars, { faction = faction, realm = realm, name = name, c = c })
				end
			end
		end
	end
	table.sort(list, function(a, b)
		if (a.name == V.realm) ~= (b.name == V.realm) then return a.name == V.realm end
		return a.name < b.name
	end)
	for _, realm in ipairs(list) do
		table.sort(realm.chars, function(a, b)
			if a.c.level ~= b.c.level then return a.c.level > b.c.level end
			return a.name < b.name
		end)
	end
	return list
end

function UI.ClassHex(class)
	local id = class and Altoholic.Classes[class]
	return id and Altoholic.ClassInfo[id].color or "|cFFFFFFFF"
end

-- the entries for a category that lists characters: realm headers, then each character
-- that passes filter(c, ref). children(ref, c), when given, makes a character expandable.
function UI.CharacterEntries(view, filter, children)
	local entries = {}
	for _, realm in ipairs(UI.Realms()) do
		local header
		for _, ref in ipairs(realm.chars) do
			if not filter or filter(ref.c, ref) then
				if not header then
					header = { header = realm.name }
					table.insert(entries, header)
				end
				table.insert(entries, {
					text = UI.ClassHex(ref.c.class) .. ref.name,
					key = realm.name .. "/" .. ref.name,
					view = view, args = ref,
					children = children and children(ref, ref.c),
				})
			end
		end
	end
	return entries
end

-- a character's tooltip: class, level, where they are, rest and when they were last on
function UI.CharacterTooltip(owner, ref)
	local c = UI.Char(ref)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:AddLine(UI.ClassHex(c.class) .. ref.name)
	GameTooltip:AddLine(L["Level"] .. " |cff00ff00" .. c.level .. "|r " .. c.race .. " " .. c.class, 1, 1, 1)
	if c.zone and c.zone ~= "" then
		local where = c.zone
		if c.subzone and c.subzone ~= "" and c.subzone ~= c.zone then where = where .. " (" .. c.subzone .. ")" end
		GameTooltip:AddLine(where, 1, .82, 0)
	end
	if c.level < 60 then
		local logout = UI.IsPlayer(ref) and 0 or c.lastlogout
		GameTooltip:AddLine(L["Rest XP"] .. ": " .. Altoholic:GetRestedXP(c.level, c.restxp, logout, c.isResting), 1, 1, 1)
	end
	if not UI.IsPlayer(ref) and c.lastlogout and c.lastlogout > 0 then
		GameTooltip:AddLine(format(L["Last seen %d days ago"], Altoholic:GetDelayInDays(c.lastlogout)), .6, .6, .6)
	end
	GameTooltip:Show()
end

-- *** The window ***

local win, area, page, col2, content, bar, search
local catRows = {}
local selectedKey = {}		-- the entry last picked in each category, by its key
local entries = {}			-- the second column, flattened
local expanded = {}			-- keys of expanded entries

local function SavePosition()
	local point, _, relPoint, x, y = win:GetPoint()
	Altoholic.db.account.options.WindowPoint = { point, relPoint, x, y }
end

local function RestorePosition()
	win:ClearAllPoints()
	local p = Altoholic.db.account.options.WindowPoint
	if type(p) == "table" and p[1] then
		win:SetPoint(p[1], UIParent, p[2], p[3], p[4])
	else
		win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
end

-- the second column, flattened: children of expanded entries follow them, one step in
local function Flatten(list, out, depth)
	for _, e in ipairs(list) do
		if e.header and #out > 0 then table.insert(out, { spacer = true }) end
		e.depth = depth
		table.insert(out, e)
		if e.children and #e.children > 0 and expanded[e.key] then
			Flatten(e.children, out, depth + 1)
		end
	end
	return out
end

local function RefreshColumn()
	col2.list:SetData(entries, true)
end

-- shows a view on the page with these args
function UI.ShowView(name, args)
	local view = UI.views[name] or UI.views.Placeholder
	for _, v in pairs(UI.views) do
		if v ~= view and v.frame then
			v.frame:Hide()
			v.bar:Hide()
		end
	end
	if not view.frame then
		view.frame = CreateFrame("Frame", nil, content)
		view.frame:SetAllPoints(content)
		view.bar = CreateFrame("Frame", nil, bar)
		view.bar:SetAllPoints(bar)
		view:Create(view.frame, view.bar)
	end
	view.args = args
	view.frame:Show()
	view.bar:Show()
	UI.current = view
	view:Update(args)
end

-- redraws the view on show, for scans that change what it lists
function UI.Refresh()
	if win and win:IsShown() and UI.current then
		UI.current:Update(UI.current.args)
	end
end

local function OpenEntry(e)
	local cat = UI.categories[UI.category]
	if e.children and #e.children > 0 and not e.view then
		expanded[e.key] = not expanded[e.key]
		entries = Flatten(cat.entries(), {}, 0)
		RefreshColumn()
		return
	end
	if not e.view then return end
	if e.children and #e.children > 0 then
		expanded[e.key] = true
	end
	selectedKey[UI.category] = e.key
	entries = Flatten(cat.entries(), {}, 0)
	RefreshColumn()
	UI.ShowView(e.view, e.args)
end

-- the entry with this key, searching children too
local function FindEntry(list, key)
	for _, e in ipairs(list) do
		if e.key == key then return e end
		if e.children then
			local found = FindEntry(e.children, key)
			if found then return found end
		end
	end
end

-- the entry a category opens on: the one picked last, else its default, else the
-- logged-in character, else its first entry that opens something
local function DefaultEntry(cat, list)
	local e = selectedKey[UI.category] and FindEntry(list, selectedKey[UI.category])
	if e then return e end
	if cat.default then
		e = cat.default(list)
		if e then return e end
	end
	e = FindEntry(list, V.realm .. "/" .. V.player)
	if e and e.view then return e end
	for _, x in ipairs(list) do
		if x.view then return x end
	end
end

function UI.SelectCategory(index)
	local cat = UI.categories[index]
	if not cat then return end
	UI.category = index
	for i, row in ipairs(catRows) do row:SetSelected(i == index) end
	content:ClearAllPoints()
	content:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
	if cat.entries then
		col2:Show()
		content:SetPoint("TOPLEFT", page, "TOPLEFT", COLUMN, 0)
		local list = cat.entries()
		local e = DefaultEntry(cat, list)
		entries = Flatten(list, {}, 0)
		col2.list:SetData(entries)
		if e then
			OpenEntry(e)
			for i, x in ipairs(entries) do
				if x == e then col2.list:ScrollTo(i) break end
			end
		else
			UI.ShowView("Placeholder", { text = cat.empty or L["Nothing to show yet"] })
		end
	else
		col2:Hide()
		content:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
		UI.ShowView(cat.view, cat.args)
	end
end

-- opens a category by its id, on the entry with this key when it is given
function UI.Open(id, key)
	if not win then UI.Create() end
	win:Show()
	for i, cat in ipairs(UI.categories) do
		if cat.id == id then
			if key then selectedKey[i] = key end
			UI.SelectCategory(i)
			return
		end
	end
end

local function Column2Row(row)
	row.menu = W.MenuRow(row, ROW)
	row.menu:SetAllPoints(row)
	row.menu:SetScript("OnClick", function(self)
		local e = self:GetParent().item
		if e and not e.header and not e.spacer then OpenEntry(e) end
	end)
	row.menu:SetScript("OnEnter", function(self)
		local e = self:GetParent().item
		if e and e.args and e.args.realm and e.args.name then
			UI.CharacterTooltip(self, e.args)
		end
	end)
	row.menu:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function Column2Update(row, e)
	local m = row.menu
	m.text:ClearAllPoints()
	if e.spacer then
		m.text:SetText("")
		m:SetSelected(false)
		m:EnableMouse(false)
		m.hl:Hide()
		return
	end
	if e.header then
		m.text:SetPoint("LEFT", m, "LEFT", 6, 0)
		m.text:SetPoint("RIGHT", m, "RIGHT", -4, 0)
		m.text:SetJustifyH("LEFT")
		m:SetSelected(false)
		m.text:SetText(e.header)
		m.text:SetTextColor(W.TEAL[1], W.TEAL[2], W.TEAL[3], .7)
		m:EnableMouse(false)
		m.hl:Hide()
		return
	end
	m:EnableMouse(true)
	m.hl:Show()
	local indent = (e.depth or 0) * 12
	m.text:SetPoint("LEFT", m, "LEFT", 4 + indent, 0)
	m.text:SetPoint("RIGHT", m, "RIGHT", -4, 0)
	m.text:SetJustifyH(indent > 0 and "LEFT" or "CENTER")
	local text = e.text
	if e.children and #e.children > 0 then
		text = text .. (expanded[e.key] and " |cff888888-" or " |cff888888+")
	end
	m.text:SetText(text)
	local selected = e.key and e.key == selectedKey[UI.category]
	m:SetSelected(selected)
	if not selected then
		if indent > 0 then m.text:SetTextColor(.8, .8, .8) else m.text:SetTextColor(1, 1, 1) end
	end
end

function UI.Create()
	if win then return win end
	win = CreateFrame("Frame", "AltoholicWindow", UIParent)
	win:SetWidth(WIDTH)
	win:SetHeight(HEIGHT)
	win:SetFrameStrata("HIGH")
	win:SetToplevel(true)
	win:SetMovable(true)
	win:SetClampedToScreen(true)
	win:EnableMouse(true)
	win:RegisterForDrag("LeftButton")
	win:SetScript("OnDragStart", function(self) self:StartMoving() end)
	win:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SavePosition()
	end)
	win:Hide()
	W.Backdrop(win, 0, .85)
	tinsert(UISpecialFrames, "AltoholicWindow")

	local title = W.Text(win, 11)
	title:SetPoint("TOPLEFT", win, "TOPLEFT", 8, -8)
	title:SetText(W.TEAL_HEX .. "Alto|rholic")
	local version = W.Text(win, 10)
	version:SetPoint("LEFT", title, "RIGHT", 2, 0)
	version:SetText(W.GRAY_HEX .. "[|r" .. V.version .. W.GRAY_HEX .. "]|r")

	local close = W.CloseButton(win)
	close:SetPoint("TOPRIGHT", win, "TOPRIGHT", -7, -7)

	area = CreateFrame("Frame", nil, win)
	area:SetPoint("TOPLEFT", win, "TOPLEFT", 7, -25)
	area:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -7, 37)
	W.Backdrop(area)

	for i, cat in ipairs(UI.categories) do
		local row = W.MenuRow(area, ROW)
		row:SetPoint("TOPLEFT", area, "TOPLEFT", 0, -(i - 1) * ROW)
		row:SetWidth(COLUMN)
		row.text:SetText(cat.title)
		row:SetScript("OnClick", function() UI.SelectCategory(i) end)
		catRows[i] = row
	end

	page = CreateFrame("Frame", nil, area)
	page:SetPoint("TOPLEFT", area, "TOPLEFT", COLUMN, 0)
	page:SetPoint("BOTTOMRIGHT", area, "BOTTOMRIGHT", 0, 0)
	W.Shade(page)

	col2 = CreateFrame("Frame", nil, page)
	col2:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
	col2:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 0)
	col2:SetWidth(COLUMN)
	col2.list = W.List(col2, ROW, Column2Row, Column2Update)

	content = CreateFrame("Frame", nil, page)
	W.Shade(content)

	-- the bottom bar: the view's controls, then the search box out to the right edge
	search = W.EditBox(win, 260, 25, L["Search"] .. "...", function(self)
		self.searchAt = nil
		UI.Search(self:GetText())
	end)
	search:SetPoint("TOPRIGHT", area.backdrop, "BOTTOMRIGHT", 0, -5)
	search:SetJustifyH("CENTER")
	search:SetTextColor(W.TEAL[1], W.TEAL[2], W.TEAL[3])
	search.onChange = function(self)
		self.searchAt = self.focused and (GetTime() + SEARCH_DELAY) or nil
	end
	search:SetScript("OnUpdate", function(self)
		if self.searchAt and GetTime() >= self.searchAt then
			self.searchAt = nil
			UI.Search(self:GetText())
		end
	end)
	UI.searchBox = search

	bar = CreateFrame("Frame", nil, win)
	bar:SetPoint("TOPLEFT", area.backdrop, "BOTTOMLEFT", 0, -5)
	bar:SetPoint("BOTTOMRIGHT", search, "BOTTOMLEFT", -5, 0)

	win:SetScript("OnShow", function()
		-- the logged-in character is rescanned, so the window shows them as they are now
		Altoholic:UpdatePlayerStats()
		Altoholic:UpdatePlayerBags()
		Altoholic:UpdateTalents()
		if UI.category then
			UI.SelectCategory(UI.category)
		else
			UI.SelectCategory(1)
		end
	end)
	win:SetScript("OnHide", function()
		if UI.searchBox then UI.searchBox:ClearFocus() end
	end)
	RestorePosition()
	return win
end

-- a search typed in the box; the Search view does the work, an empty box goes back
function UI.Search(text)
	UI.searchText = text
	if UI.views.Search then
		UI.Open("search")
	end
end

function UI.Toggle()
	UI.Create()
	if win:IsShown() then win:Hide() else win:Show() end
end

function UI.Show()
	UI.Create()
	win:Show()
end

function UI.Hide()
	if win then win:Hide() end
end

-- the scans tell the window when what it lists has changed
local oldOnDataChanged = Altoholic.OnDataChanged
function Altoholic:OnDataChanged(what)
	if oldOnDataChanged then oldOnDataChanged(self, what) end
	UI.Refresh()
end

-- *** A page for views not rebuilt yet, and for empty categories ***

UI.RegisterView("Placeholder", {
	Create = function(self, frame)
		self.text = W.Message(frame)
	end,
	Update = function(self, args)
		self.text:SetText(args and args.text or L["This page hasn't been rebuilt yet.\n/alto old opens the old window."])
	end,
})
