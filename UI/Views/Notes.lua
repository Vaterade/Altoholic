-- Notes: leave a note for a character, and see it when they log in. The page is opened by
-- the Notes button at the bottom left of the window (where pfUI's config has Unlock); the
-- second column lists the characters with how many notes each has. Data/Notes.lua keeps them.
local L = Altoholic.L
local V = Altoholic.vars
local W = Altoholic.W
local UI = Altoholic.UI

-- "from Name, 3 days ago"
local function Byline(note)
	local days = math.floor((time() - (note.time or time())) / 86400)
	local when
	if days <= 0 then
		when = L["today"]
	elseif days == 1 then
		when = L["yesterday"]
	else
		when = format(L["%d days ago"], days)
	end
	return format(L["from %s, %s"], note.from or "?", when)
end

-- the second column: characters by realm, each with their note count
function UI.NoteEntries()
	local list = UI.CharacterEntries("Notes")
	for _, e in ipairs(list) do
		if e.args then
			local n = Altoholic:NoteCount(e.args.realm, e.args.name)
			if n > 0 then e.text = e.text .. " " .. W.TEAL_HEX .. "(" .. n .. ")" end
		end
	end
	return list
end

local view = {}

function view:Create(frame)
	self.title = W.Text(frame, W.FontSize() + 1)
	self.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -10)

	-- writing a note, along the bottom of the page
	local add = W.Button(frame, L["Add"], 70, 22, function() self:Add() end)
	add:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
	self.input = W.EditBox(frame, 100, 22, nil, function() self:Add() end)
	self.input:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 10)
	self.input:SetPoint("RIGHT", add, "LEFT", -6, 0)
	self.input:SetMaxLetters(255)
	self.input.hint = W.Text(self.input, nil, "LEFT", "ARTWORK")
	self.input.hint:SetPoint("LEFT", self.input, "LEFT", 6, 0)
	self.input.hint:SetTextColor(.5, .5, .5)

	local holder = CreateFrame("Frame", nil, frame)
	holder:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, -10)
	holder:SetPoint("BOTTOMRIGHT", add, "TOPRIGHT", 0, 10)
	self.list = W.List(holder, 36,
		function(row)
			row.text = W.Text(row)
			row.text:SetPoint("TOPLEFT", row, "TOPLEFT", 4, -3)
			row.text:SetPoint("RIGHT", row, "RIGHT", -70, 0)
			row.by = W.Text(row, W.FontSize() - 1)
			row.by:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, -3)
			row.by:SetTextColor(.55, .55, .55)
			row.done = W.Button(row, L["Done"], 56, 20, function()
				if row.item then Altoholic:RemoveNote(self.args.realm, self.args.name, row.item) end
			end)
			row.done:SetPoint("RIGHT", row, "RIGHT", -4, 0)
			row.done.tooltip = L["Remove this note"]
			row.hl = row:CreateTexture(nil, "HIGHLIGHT")
			row.hl:SetAllPoints(row)
			row.hl:SetColorTexture(1, 1, 1, .05)
			-- a long note doesn't fit on its line: the tooltip has all of it
			row:SetScript("OnEnter", function(r)
				if not r.item then return end
				GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
				GameTooltip:AddLine(r.item.text, 1, 1, 1, true)
				GameTooltip:AddLine(Byline(r.item), .55, .55, .55)
				GameTooltip:Show()
			end)
			row:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end,
		function(row, note)
			row.text:SetText(note.text)
			row.by:SetText(Byline(note))
		end)
	self.message = W.Message(holder)
end

function view:Add()
	if not self.args then return end
	if Altoholic:AddNote(self.args.realm, self.args.name, self.input:GetText()) then
		self.input:SetText("")
	end
	self.input:ClearFocus()
end

function view:Update(ref)
	self.args = ref
	local c = UI.Char(ref)
	local notes = UI.Array(Altoholic:GetNotes(ref.realm, ref.name))
	self.title:SetText(format(L["Notes for %s"], UI.ClassHex(c.class) .. ref.name .. "|r"))
	self.input.hint:SetText(format(L["Leave a note for %s..."], ref.name))
	self.list:SetData(notes, self.ref == ref)
	self.ref = ref
	if #notes == 0 then
		self.message:SetText(UI.IsPlayer(ref) and L["No notes for you."]
			or format(L["No notes for %s. Write one below; they'll see it when they log in."], ref.name))
		self.message:Show()
	else
		self.message:Hide()
	end
end

UI.RegisterView("Notes", view)

-- *** At login: the notes left for this character ***

local popup

local function Popup()
	if popup then return popup end
	popup = CreateFrame("Frame", "AltoholicNotesPopup", UIParent)
	popup:SetWidth(380)
	popup:SetFrameStrata("DIALOG")
	popup:SetToplevel(true)
	popup:SetPoint("TOP", UIParent, "TOP", 0, -140)
	popup:EnableMouse(true)
	popup:SetMovable(true)
	popup:RegisterForDrag("LeftButton")
	popup:SetScript("OnDragStart", function(self) self:StartMoving() end)
	popup:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	W.Backdrop(popup, 0, .9)
	tinsert(UISpecialFrames, "AltoholicNotesPopup")
	popup.title = W.Text(popup, W.FontSize() + 1)
	popup.title:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -10)
	local close = W.CloseButton(popup)
	close:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -7, -7)
	popup.lines = {}
	popup.later = W.Button(popup, L["Later"], 90, 22, function() popup:Hide() end)
	popup.later.tooltip = L["Keep the notes; they show again at the next login"]
	popup.done = W.Button(popup, L["Done with all"], 110, 22, function()
		for _, note in ipairs(UI.Array(Altoholic:GetNotes(V.realm, V.player))) do
			Altoholic:RemoveNote(V.realm, V.player, note)
		end
		popup:Hide()
	end)
	popup.open = W.Button(popup, L["Open"], 70, 22, function()
		popup:Hide()
		UI.Open("notes", V.realm .. "/" .. V.player)
	end)
	return popup
end

local MAX_SHOWN = 6

-- shows the logged-in character's notes, if there are any; returns whether it did
function UI.ShowLoginNotes()
	local notes = UI.Array(Altoholic:GetNotes(V.realm, V.player))
	if #notes == 0 then
		if popup then popup:Hide() end
		return false
	end
	local p = Popup()
	p.title:SetText(W.TEAL_HEX .. format(L["Notes for %s"], V.player))
	local y = -34
	for i = 1, math.max(#notes, #p.lines) do
		local line = p.lines[i]
		local note = i <= MAX_SHOWN and notes[i]
		if note and not line then
			line = {}
			line.text = W.Text(p)
			line.text:SetWidth(290)
			line.text:SetJustifyV("TOP")
			line.by = W.Text(p, W.FontSize() - 1)
			line.by:SetTextColor(.55, .55, .55)
			line.done = W.Button(p, L["Done"], 50, 18)
			p.lines[i] = line
		end
		if line then
			if note then
				line.text:ClearAllPoints()
				line.text:SetPoint("TOPLEFT", p, "TOPLEFT", 12, y)
				line.text:SetText(note.text)
				line.by:ClearAllPoints()
				line.by:SetPoint("TOPLEFT", line.text, "BOTTOMLEFT", 0, -2)
				line.by:SetText(Byline(note))
				line.done:ClearAllPoints()
				line.done:SetPoint("TOPRIGHT", p, "TOPRIGHT", -10, y + 2)
				line.done:SetScript("OnClick", function()
					Altoholic:RemoveNote(V.realm, V.player, note)
					UI.ShowLoginNotes()
				end)
				line.text:Show()
				line.by:Show()
				line.done:Show()
				y = y - (line.text:GetHeight() or 14) - (line.by:GetHeight() or 12) - 12
			else
				line.text:Hide()
				line.by:Hide()
				line.done:Hide()
			end
		end
	end
	if not p.more then
		p.more = W.Text(p)
		p.more:SetTextColor(.55, .55, .55)
	end
	p.more:ClearAllPoints()
	p.more:SetPoint("TOPLEFT", p, "TOPLEFT", 12, y)
	if #notes > MAX_SHOWN then
		p.more:SetText(format(L["and %d more: Open shows them all"], #notes - MAX_SHOWN))
		y = y - 20
	else
		p.more:SetText("")
	end
	p.done:ClearAllPoints()
	p.done:SetPoint("TOPRIGHT", p, "TOPRIGHT", -10, y - 6)
	p.later:ClearAllPoints()
	p.later:SetPoint("RIGHT", p.done, "LEFT", -6, 0)
	p.open:ClearAllPoints()
	p.open:SetPoint("TOPLEFT", p, "TOPLEFT", 10, y - 6)
	p:SetHeight(-y + 40)
	p:Show()
	return true
end

-- a few seconds after login, once the chat and the login burst have settled
table.insert(UI.loginHooks, function()
	C_Timer.After(5, UI.ShowLoginNotes)
end)

-- leaves a note from chat: /alto note <name> <text>
function Altoholic:CmdNote(text)
	local typed, rest = string.match(text or "", "^(%S+)%s+(.+)$")
	local say = function(msg) DEFAULT_CHAT_FRAME:AddMessage(W.TEAL_HEX .. "Altoholic:|r " .. msg) end
	if not typed then
		say(L["/alto note <name> <text> leaves a note for one of your characters on this realm"])
		return
	end
	local name = self:FindCharacter(V.realm, typed)
	if not name then
		say(format(L["no character called %s on this realm"], typed))
		return
	end
	if self:AddNote(V.realm, name, rest) then
		say(format(L["note left for %s"], name))
	end
end
