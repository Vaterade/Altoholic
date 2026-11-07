-- The widget kit: every frame in the window is built from these, in pfUI's style (flat
-- black panels with a thin border, teal for what is selected). No Blizzard templates.
--
-- pfUI is never required. When it is loaded its own settings are used (background and
-- border colours, font, font size, pixel size), so the window matches the rest of the
-- player's UI; without it the same look is drawn with pfUI's defaults.
--
-- Script handlers set here take positional arguments (self, ...), which ClassicAPI supplies.

local W = {}
Altoholic.W = W

-- pfUI's highlight colour, used for what is selected and for captions
W.TEAL = { .2, 1, .8 }
W.TEAL_HEX = "|cff33ffcc"
W.GRAY_HEX = "|cff555555"

local WHITE8X8 = "Interface\\Buttons\\WHITE8X8"

-- *** Settings, from pfUI when it is there ***

local function PfConfig()
	return type(pfUI_config) == "table" and pfUI_config or nil
end

local function ParseColor(s, r, g, b, a)
	if type(s) ~= "string" then return r, g, b, a end
	local pr, pg, pb, pa = strsplit(",", s)
	return tonumber(pr) or r, tonumber(pg) or g, tonumber(pb) or b, tonumber(pa) or a
end

function W.BackgroundColor()
	local C = PfConfig()
	return ParseColor(C and C.appearance and C.appearance.border and C.appearance.border.background, 0, 0, 0, 1)
end

function W.BorderColor()
	local C = PfConfig()
	return ParseColor(C and C.appearance and C.appearance.border and C.appearance.border.color, .2, .2, .2, 1)
end

-- the size of one screen pixel in UI units, so borders stay one pixel thick at any scale
function W.Pixel()
	if pfUI and pfUI.pixel then return pfUI.pixel end
	local _, height = 0, nil
	if GetPhysicalScreenSize then _, height = GetPhysicalScreenSize() end
	local scale = UIParent:GetEffectiveScale()
	if height and height > 0 and scale and scale > 0 then
		return 768 / height / scale
	end
	return 1
end

function W.FontPath()
	return (pfUI and pfUI.font_default) or STANDARD_TEXT_FONT
end

function W.FontSize()
	local C = PfConfig()
	return tonumber(C and C.global and C.global.font_size) or 12
end

-- the colour of a class, by its localised name (what the saved data keeps)
function W.ClassColor(class)
	local id = class and Altoholic.Classes[class]
	local hex = id and Altoholic.ClassInfo[id] and Altoholic.ClassInfo[id].color
	if not hex then return 1, 1, 1 end
	return tonumber(hex:sub(5, 6), 16) / 255, tonumber(hex:sub(7, 8), 16) / 255, tonumber(hex:sub(9, 10), 16) / 255
end

-- the logged-in character's class colour: pfUI tints a hovered button's border with it
local function HoverColor()
	return W.ClassColor(UnitClass("player"))
end

-- *** Panels ***

-- A flat panel behind a frame: background plus one-pixel border, drawn `inset` units
-- outside it (pfUI's default border is 3). alpha overrides the background's opacity.
-- The panel is frame.backdrop, a child frame one level below.
function W.Backdrop(frame, inset, alpha)
	local px = W.Pixel()
	inset = (inset or 3) * px
	local b = frame.backdrop
	if not b then
		b = CreateFrame("Frame", nil, frame)
		local level = frame:GetFrameLevel()
		b:SetFrameLevel(level > 0 and level - 1 or 0)
		frame.backdrop = b
	end
	b:ClearAllPoints()
	b:SetPoint("TOPLEFT", frame, "TOPLEFT", -inset, inset)
	b:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", inset, -inset)
	b:SetBackdrop({
		bgFile = WHITE8X8, edgeFile = WHITE8X8, edgeSize = px,
		insets = { left = 0, right = 0, top = 0, bottom = 0 },
	})
	local r, g, bl, a = W.BackgroundColor()
	b:SetBackdropColor(r, g, bl, alpha or a)
	b:SetBackdropBorderColor(W.BorderColor())
	return b
end

-- the faint lighter fill pfUI puts behind its config pages
function W.Shade(frame, alpha)
	local t = frame:CreateTexture(nil, "BACKGROUND")
	t:SetAllPoints(frame)
	t:SetColorTexture(1, 1, 1, alpha or .05)
	return t
end

-- *** Text ***

-- size defaults to pfUI's font size; justify "LEFT" | "CENTER" | "RIGHT"
function W.Text(parent, size, justify, layer)
	local fs = parent:CreateFontString(nil, layer or "OVERLAY")
	fs:SetFont(W.FontPath(), size or W.FontSize(), "")
	fs:SetJustifyH(justify or "LEFT")
	fs:SetTextColor(1, 1, 1)
	return fs
end

-- *** Buttons ***

local function HoverBorder(self)
	if self.backdrop and self:IsEnabled() then
		self.backdrop:SetBackdropBorderColor(self.hr, self.hg, self.hb, 1)
	end
	if self.tooltip then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tooltip, 1, 1, 1, 1, true)
		GameTooltip:Show()
	end
end

local function RestoreBorder(self)
	if self.backdrop and not self.locked then
		self.backdrop:SetBackdropBorderColor(W.BorderColor())
	end
	if self.tooltip then GameTooltip:Hide() end
end

-- a text button; onClick(self, mouseButton)
function W.Button(parent, text, width, height, onClick)
	local b = CreateFrame("Button", nil, parent)
	b:SetWidth(width or 100)
	b:SetHeight(height or 22)
	W.Backdrop(b, 1)
	b.hr, b.hg, b.hb = HoverColor()
	b.label = W.Text(b, nil, "CENTER")
	b.label:SetPoint("CENTER", b, "CENTER", 0, 0)
	b.label:SetText(text or "")
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:SetScript("OnEnter", HoverBorder)
	b:SetScript("OnLeave", RestoreBorder)
	if onClick then b:SetScript("OnClick", onClick) end
	function b:SetLabel(t) self.label:SetText(t) end
	-- a toggle-style button keeps its border lit while it is "on"
	function b:SetLocked(on)
		self.locked = on
		if on then
			self.backdrop:SetBackdropBorderColor(W.TEAL[1], W.TEAL[2], W.TEAL[3], 1)
			self.label:SetTextColor(W.TEAL[1], W.TEAL[2], W.TEAL[3])
		else
			self.backdrop:SetBackdropBorderColor(W.BorderColor())
			self.label:SetTextColor(1, 1, 1)
		end
	end
	local enable, disable = b.Enable, b.Disable
	function b:Enable() enable(self) self.label:SetTextColor(1, 1, 1) end
	function b:Disable() disable(self) self.label:SetTextColor(.5, .5, .5) end
	return b
end

-- pfUI's small red close button: a 10x10 box with an x, its border turns red on hover
function W.CloseButton(parent, onClick)
	local b = CreateFrame("Button", nil, parent)
	b:SetWidth(10)
	b:SetHeight(10)
	W.Backdrop(b, 1)
	b.hr, b.hg, b.hb = 1, .25, .25
	local tex = pfUI and pfUI.media and pfUI.media["img:close"]
	if tex then
		b.icon = b:CreateTexture(nil, "OVERLAY")
		b.icon:SetTexture(tex)
		b.icon:SetAllPoints(b)
		b.icon:SetVertexColor(1, .25, .25, 1)
	else
		b.label = W.Text(b, 10, "CENTER")
		b.label:SetPoint("CENTER", b, "CENTER", 1, 0)
		b.label:SetText("x")
		b.label:SetTextColor(1, .25, .25)
	end
	b:SetScript("OnEnter", HoverBorder)
	b:SetScript("OnLeave", RestoreBorder)
	b:SetScript("OnClick", onClick or function(self) self:GetParent():Hide() end)
	return b
end

-- a square check box with a label to its right; onChange(self, checked)
function W.Checkbox(parent, label, onChange)
	local cb = CreateFrame("CheckButton", nil, parent)
	cb:SetWidth(14)
	cb:SetHeight(14)
	W.Backdrop(cb, 1)
	cb.hr, cb.hg, cb.hb = HoverColor()
	cb:SetCheckedTexture(WHITE8X8)
	local check = cb:GetCheckedTexture()
	check:ClearAllPoints()
	check:SetPoint("TOPLEFT", cb, "TOPLEFT", 3, -3)
	check:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", -3, 3)
	check:SetVertexColor(W.TEAL[1], W.TEAL[2], W.TEAL[3], 1)
	cb.label = W.Text(cb)
	cb.label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
	cb.label:SetText(label or "")
	cb:SetHitRectInsets(0, -(cb.label:GetStringWidth() + 6), 0, 0)
	cb:SetScript("OnEnter", HoverBorder)
	cb:SetScript("OnLeave", RestoreBorder)
	cb:SetScript("OnClick", function(self)
		if onChange then onChange(self, self:GetChecked() and true or false) end
	end)
	return cb
end

-- *** Edit box ***

-- a flat edit box. placeholder: grey text shown while it is empty and not focused.
-- Escape only drops the focus; Enter calls onEnter(self) and drops it too.
function W.EditBox(parent, width, height, placeholder, onEnter)
	local e = CreateFrame("EditBox", nil, parent)
	e:SetWidth(width or 120)
	e:SetHeight(height or 20)
	e:SetAutoFocus(false)
	e:SetTextInsets(5, 5, 0, 0)
	e:SetFont(W.FontPath(), W.FontSize(), "")
	e:SetTextColor(1, 1, 1)
	W.Backdrop(e, 1)
	if placeholder then
		e.hint = W.Text(e, nil, "CENTER", "ARTWORK")
		e.hint:SetAllPoints(e)
		e.hint:SetText(placeholder)
		e.hint:SetTextColor(W.TEAL[1], W.TEAL[2], W.TEAL[3], .6)
	end
	local function UpdateHint(self)
		if not self.hint then return end
		if self.focused or self:GetText() ~= "" then self.hint:Hide() else self.hint:Show() end
	end
	e.UpdateHint = UpdateHint
	e:SetScript("OnEditFocusGained", function(self)
		self.focused = true
		self:HighlightText()
		UpdateHint(self)
	end)
	e:SetScript("OnEditFocusLost", function(self)
		self.focused = nil
		self:HighlightText(0, 0)
		UpdateHint(self)
	end)
	e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	e:SetScript("OnEnterPressed", function(self)
		if onEnter then onEnter(self) end
		self:ClearFocus()
	end)
	e:SetScript("OnTextChanged", function(self)
		UpdateHint(self)
		if self.onChange then self.onChange(self) end
	end)
	return e
end

-- *** Dropdown ***

-- One menu frame shared by every dropdown: a flat list under the button.
local menu
local function Menu()
	if menu then return menu end
	menu = CreateFrame("Frame", "AltoholicDropdownMenu", UIParent)
	menu:SetFrameStrata("TOOLTIP")
	menu:EnableMouse(true)
	menu:Hide()
	W.Backdrop(menu, 1)
	menu.rows = {}
	tinsert(UISpecialFrames, "AltoholicDropdownMenu")
	return menu
end

-- items: { { text = "...", value = v }, ... } or a function returning that list.
-- onSelect(dropdown, value, item). dd:SetValue(v) selects without calling onSelect.
function W.Dropdown(parent, width, items, onSelect)
	local dd = W.Button(parent, "", width or 120, 20)
	dd.label:ClearAllPoints()
	dd.label:SetPoint("LEFT", dd, "LEFT", 6, 0)
	dd.label:SetPoint("RIGHT", dd, "RIGHT", -16, 0)
	dd.label:SetJustifyH("LEFT")
	local arrow = W.Text(dd, nil, "RIGHT")
	arrow:SetPoint("RIGHT", dd, "RIGHT", -5, 0)
	arrow:SetText("v")
	arrow:SetTextColor(.6, .6, .6)

	local function Items()
		return type(items) == "function" and items() or items
	end

	function dd:SetValue(value)
		self.value = value
		for _, it in ipairs(Items()) do
			if it.value == value then self.label:SetText(it.text) return end
		end
		self.label:SetText("")
	end

	dd:SetScript("OnClick", function(self)
		local m = Menu()
		if m:IsShown() and m.owner == self then m:Hide() return end
		m.owner = self
		local list = Items()
		for i, it in ipairs(list) do
			local row = m.rows[i]
			if not row then
				row = CreateFrame("Button", nil, m)
				row:SetHeight(18)
				row.text = W.Text(row)
				row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
				row.hl = row:CreateTexture(nil, "HIGHLIGHT")
				row.hl:SetAllPoints(row)
				row.hl:SetColorTexture(1, 1, 1, .1)
				m.rows[i] = row
			end
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", m, "TOPLEFT", 1, -1 - (i - 1) * 18)
			row:SetPoint("RIGHT", m, "RIGHT", -1, 0)
			row.text:SetText(it.text)
			if it.value == self.value then
				row.text:SetTextColor(W.TEAL[1], W.TEAL[2], W.TEAL[3])
			else
				row.text:SetTextColor(1, 1, 1)
			end
			row:SetScript("OnClick", function()
				m:Hide()
				self:SetValue(it.value)
				if onSelect then onSelect(self, it.value, it) end
			end)
			row:Show()
		end
		for i = #list + 1, #m.rows do m.rows[i]:Hide() end
		m:SetWidth(math.max(self:GetWidth(), 80))
		m:SetHeight(#list * 18 + 2)
		m:ClearAllPoints()
		m:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4)
		m:Show()
	end)
	dd:SetScript("OnHide", function(self)
		if menu and menu.owner == self then menu:Hide() end
	end)
	return dd
end

-- *** Slider ***

-- a thin horizontal slider with its caption above; onChange(self, value)
function W.Slider(parent, width, low, high, step, onChange)
	local s = CreateFrame("Slider", nil, parent)
	s:SetOrientation("HORIZONTAL")
	s:SetWidth(width or 160)
	s:SetHeight(8)
	s:SetMinMaxValues(low, high)
	s:SetValueStep(step or 1)
	W.Backdrop(s, 1)
	s:SetThumbTexture(WHITE8X8)
	local thumb = s:GetThumbTexture()
	thumb:SetWidth(8)
	thumb:SetHeight(12)
	thumb:SetVertexColor(W.TEAL[1], W.TEAL[2], W.TEAL[3], 1)
	s:EnableMouseWheel(true)
	s:SetScript("OnMouseWheel", function(self, delta)
		self:SetValue(self:GetValue() + delta * (step or 1))
	end)
	s.caption = W.Text(s)
	s.caption:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 5)
	s:SetScript("OnValueChanged", function(self, value)
		value = value or self:GetValue()
		if onChange then onChange(self, value) end
	end)
	return s
end

-- *** Item button ***

-- An item icon: border in the item's quality colour, stack count, tooltip, and
-- shift-click links it into chat (or the search box), ctrl-click tries it on.
-- btn:SetItem(itemIDOrLink, count) / btn:SetItem(nil) to clear.
function W.ItemButton(parent, size)
	local b = CreateFrame("Button", nil, parent)
	size = size or 32
	b:SetWidth(size)
	b:SetHeight(size)
	W.Backdrop(b, 1)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetAllPoints(b)
	b.icon:SetTexCoord(.08, .92, .08, .92)
	b.count = W.Text(b, math.max(9, W.FontSize() - 1), "RIGHT")
	b.count:SetFont(W.FontPath(), math.max(9, W.FontSize() - 1), "OUTLINE")
	b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 2)
	b.hl = b:CreateTexture(nil, "HIGHLIGHT")
	b.hl:SetAllPoints(b)
	b.hl:SetColorTexture(1, 1, 1, .15)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	function b:SetItem(item, count, texture)
		self.item = item
		if not item then
			self.icon:SetTexture(texture)
			self.count:SetText("")
			self.backdrop:SetBackdropBorderColor(W.BorderColor())
			return
		end
		local _, _, rarity, _, _, _, _, _, tex = GetItemInfo(Altoholic:GetItemString(item))
		self.icon:SetTexture(tex or texture or "Interface\\Icons\\INV_Misc_QuestionMark")
		self.count:SetText((count and count > 1) and count or "")
		if rarity and rarity > 1 then
			local r, g, bl = GetItemQualityColor(rarity)
			self.backdrop:SetBackdropBorderColor(r, g, bl, 1)
		else
			self.backdrop:SetBackdropBorderColor(W.BorderColor())
		end
	end

	b:SetScript("OnEnter", function(self)
		if not self.item then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		local item = self.item
		if type(item) == "number" then item = "item:" .. item .. ":0:0:0" end
		GameTooltip:SetHyperlink(Altoholic:GetItemString(item))
		if self.onTooltip then self.onTooltip(self, GameTooltip) end
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	b:SetScript("OnClick", function(self, button)
		if not self.item then return end
		if IsShiftKeyDown() or IsControlKeyDown() then
			W.ItemClick(self.item)
		elseif self.onClick then
			self.onClick(self, button)
		end
	end)
	return b
end

-- shift-click: the link into an open chat box; ctrl-click: try it on
function W.ItemClick(item)
	local link = type(item) == "string" and item:find("|H") and item
	if not link then
		local _, l = GetItemInfo(Altoholic:GetItemString(item))
		link = l
	end
	if not link then return end
	if IsControlKeyDown() then
		DressUpItemLink(link)
	elseif ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
		ChatFrameEditBox:Insert(link)
	end
end

-- *** Scrolling list ***

-- A virtual list: only the visible rows exist, and scrolling redraws them from the data.
--   list = W.List(parent, rowHeight, createRow, updateRow)
--   createRow(row)                builds a row's widgets once (row is a Button)
--   updateRow(row, item, index)   fills it for one entry of the data
--   list:SetData(t)  list:Refresh()  list:ScrollTo(index)
-- The list fills its parent unless it is anchored otherwise; a thin scrollbar appears on
-- the right while there is more than fits.
function W.List(parent, rowHeight, createRow, updateRow)
	local list = CreateFrame("Frame", nil, parent)
	list:SetAllPoints(parent)
	list.rowHeight = rowHeight
	list.rows = {}
	list.data = {}
	list.offset = 0
	list:EnableMouseWheel(true)

	local bar = CreateFrame("Slider", nil, list)
	bar:SetOrientation("VERTICAL")
	bar:SetWidth(6)
	bar:SetPoint("TOPRIGHT", list, "TOPRIGHT", -2, -2)
	bar:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -2, 2)
	bar:SetValueStep(1)
	bar:SetThumbTexture(WHITE8X8)
	local thumb = bar:GetThumbTexture()
	thumb:SetWidth(6)
	thumb:SetHeight(24)
	thumb:SetVertexColor(.6, .6, .6, .8)
	local track = bar:CreateTexture(nil, "BACKGROUND")
	track:SetAllPoints(bar)
	track:SetColorTexture(1, 1, 1, .05)
	list.bar = bar

	local function Visible()
		return math.max(1, math.floor((list:GetHeight() or 0) / rowHeight))
	end

	function list:Refresh()
		local visible = Visible()
		local maxOffset = math.max(0, #self.data - visible)
		if self.offset > maxOffset then self.offset = maxOffset end
		local scrolls = maxOffset > 0
		for i = 1, visible do
			local row = self.rows[i]
			if not row then
				row = CreateFrame("Button", nil, self)
				row:SetHeight(rowHeight)
				row:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -(i - 1) * rowHeight)
				createRow(row)
				self.rows[i] = row
			end
			row:SetPoint("RIGHT", self, "RIGHT", scrolls and -10 or 0, 0)
			local index = self.offset + i
			local item = self.data[index]
			if item ~= nil then
				row.index, row.item = index, item
				updateRow(row, item, index)
				row:Show()
			else
				row.index, row.item = nil, nil
				row:Hide()
			end
		end
		for i = visible + 1, #self.rows do self.rows[i]:Hide() end
		self.updating = true
		bar:SetMinMaxValues(0, maxOffset)
		bar:SetValue(self.offset)
		self.updating = nil
		if scrolls then bar:Show() else bar:Hide() end
	end

	function list:SetData(t, keepOffset)
		self.data = t or {}
		if not keepOffset then self.offset = 0 end
		self:Refresh()
	end

	function list:ScrollTo(index)
		local visible = Visible()
		if index <= self.offset then
			self.offset = index - 1
		elseif index > self.offset + visible then
			self.offset = index - visible
		end
		self:Refresh()
	end

	bar:SetScript("OnValueChanged", function(_, value)
		if list.updating then return end
		list.offset = math.floor((value or bar:GetValue()) + .5)
		list:Refresh()
	end)
	list:SetScript("OnMouseWheel", function(self, delta)
		local maxOffset = math.max(0, #self.data - Visible())
		local step = IsShiftKeyDown() and Visible() or 3
		self.offset = math.min(maxOffset, math.max(0, self.offset - delta * step))
		self:Refresh()
	end)
	list:SetScript("OnSizeChanged", function(self) self:Refresh() end)
	return list
end

-- *** Menu rows ***

-- A row of one of the window's menu columns, drawn like pfUI's config tabs: white text,
-- teal with a faint gradient while selected.
function W.MenuRow(parent, height)
	local row = CreateFrame("Button", nil, parent)
	row:SetHeight(height or 20)
	row.bg = row:CreateTexture(nil, "BACKGROUND")
	row.bg:SetAllPoints(row)
	row.bg:SetColorTexture(0, 0, 0, 0)
	row.hl = row:CreateTexture(nil, "HIGHLIGHT")
	row.hl:SetAllPoints(row)
	row.hl:SetColorTexture(1, 1, 1, .05)
	row.text = W.Text(row, nil, "CENTER")
	row.text:SetPoint("LEFT", row, "LEFT", 4, 0)
	row.text:SetPoint("RIGHT", row, "RIGHT", -4, 0)

	function row:SetSelected(on)
		if on then
			self.text:SetTextColor(W.TEAL[1], W.TEAL[2], W.TEAL[3])
			self.bg:SetColorTexture(1, 1, 1, 1)
			self.bg:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0, 1, 1, 1, .05)
		else
			self.text:SetTextColor(1, 1, 1)
			self.bg:SetColorTexture(0, 0, 0, 0)
		end
	end
	return row
end

-- *** Table ***

-- A list with column captions, for the account-wide views. columns:
--   { { title = "Level", width = 40, justify = "RIGHT" }, ... }   (the last column takes what's left)
-- Each data item is one of
--   { cells = { "text", ... }, onEnter = fn(row), onClick = fn(row, button) }
--   { header = "text" }   a section title across the whole width (a realm), in teal
--   { total = true, cells = { ... } }   a totals line, dimmed caption
function W.Table(parent, columns, rowHeight)
	rowHeight = rowHeight or 18
	local t = CreateFrame("Frame", nil, parent)
	t:SetAllPoints(parent)

	local head = CreateFrame("Frame", nil, t)
	head:SetPoint("TOPLEFT", t, "TOPLEFT", 4, -4)
	head:SetPoint("TOPRIGHT", t, "TOPRIGHT", -14, -4)
	head:SetHeight(rowHeight)

	local function Layout(frame, cells)
		local x = 0
		for i, col in ipairs(columns) do
			local fs = cells[i]
			fs:ClearAllPoints()
			fs:SetPoint("LEFT", frame, "LEFT", x + 4, 0)
			if i == #columns then
				fs:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
			else
				fs:SetWidth(col.width - 8)
			end
			fs:SetJustifyH(col.justify or "LEFT")
			x = x + (col.width or 0)
		end
	end

	head.cells = {}
	for i, col in ipairs(columns) do
		head.cells[i] = W.Text(head)
		head.cells[i]:SetText(col.title or "")
		head.cells[i]:SetTextColor(.6, .6, .6)
	end
	Layout(head, head.cells)
	local line = t:CreateTexture(nil, "ARTWORK")
	line:SetHeight(1)
	line:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -2)
	line:SetPoint("TOPRIGHT", head, "BOTTOMRIGHT", 0, -2)
	line:SetColorTexture(1, 1, 1, .1)

	local body = CreateFrame("Frame", nil, t)
	body:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -5)
	body:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT", -4, 4)

	t.list = W.List(body, rowHeight,
		function(row)
			row.cells = {}
			for i = 1, #columns do row.cells[i] = W.Text(row) end
			Layout(row, row.cells)
			row.title = W.Text(row)
			row.title:SetPoint("LEFT", row, "LEFT", 4, 0)
			row.title:SetPoint("RIGHT", row, "RIGHT", -4, 0)
			row.title:SetTextColor(W.TEAL[1], W.TEAL[2], W.TEAL[3])
			row.hl = row:CreateTexture(nil, "HIGHLIGHT")
			row.hl:SetAllPoints(row)
			row.hl:SetColorTexture(1, 1, 1, .05)
			row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			row:SetScript("OnEnter", function(self)
				if self.item and self.item.onEnter then self.item.onEnter(self) end
			end)
			row:SetScript("OnLeave", function() GameTooltip:Hide() end)
			row:SetScript("OnClick", function(self, button)
				if self.item and self.item.onClick then self.item.onClick(self, button) end
			end)
		end,
		function(row, item)
			if item.header then
				row.title:SetText(item.header)
				row.title:Show()
				for i = 1, #columns do row.cells[i]:SetText("") end
			else
				row.title:Hide()
				for i = 1, #columns do
					row.cells[i]:SetText(item.cells[i] or "")
					if item.total and i == 1 then
						row.cells[i]:SetTextColor(.6, .6, .6)
					else
						row.cells[i]:SetTextColor(1, 1, 1)
					end
				end
			end
		end)

	function t:SetData(data, keepOffset) self.list:SetData(data, keepOffset) end
	return t
end

-- A caption plus a line of grey help text, for empty pages
function W.Message(parent)
	local fs = W.Text(parent, nil, "CENTER")
	fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -40)
	fs:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -20, -40)
	fs:SetTextColor(.6, .6, .6)
	return fs
end
