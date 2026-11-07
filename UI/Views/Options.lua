-- Options: tooltips, the window and search, the minimap button, mail warnings.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local view = {}

-- check boxes: option key and label, in sections
local SECTIONS = {
	{ XML_TEXT_8 or "Tooltip Options", {
		{ "TooltipSource", XML_TEXT_20 or "Display Item Source" },
		{ "TooltipCount", XML_TEXT_21 or "Display Item Count Per Character" },
		{ "TooltipTotal", XML_TEXT_22 or "Display Total Item Count" },
		{ "TooltipAlreadyKnown", XML_TEXT_24 or "Show which alts already know a recipe" },
		{ "TooltipLearnableBy", XML_TEXT_27 or "Show which alts could learn a recipe" },
	} },
	{ L["General"], {
		{ "ShowMinimap", XML_TEXT_16 or "Show Minimap Icon" },
		{ "RestXPMode", XML_TEXT_18 or "Max rest XP displayed as 150%" },
		{ "ScanMailBody", XML_TEXT_19 or "Scan mail body (marks it as read)" },
	} },
	{ XML_TEXT_9 or "Search Options", {
		{ "SortDescending", XML_TEXT_17 or "Sort loots in descending order" },
	} },
}

local function Header(parent, text, y)
	local h = W.Text(parent, W.FontSize() + 1)
	h:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
	h:SetText(W.TEAL_HEX .. text)
	return h
end

function view:Create(frame)
	local O = function() return Altoholic.db.account.options end
	self.boxes = {}
	local y = -14
	for _, section in ipairs(SECTIONS) do
		Header(frame, section[1], y)
		y = y - 24
		for _, opt in ipairs(section[2]) do
			local key = opt[1]
			local cb = W.Checkbox(frame, opt[2], function(_, on)
				O()[key] = on and 1 or 0
				if key == "ShowMinimap" then UI.UpdateMinimapButton() end
				if key == "RestXPMode" then UI.Refresh() end
			end)
			cb:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, y)
			self.boxes[key] = cb
			y = y - 22
		end
		y = y - 10
	end

	-- the sliders, in a second column
	local x = 360
	local caption = W.Text(frame, W.FontSize() + 1)
	caption:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -14)
	caption:SetText(W.TEAL_HEX .. L["Minimap Icon"] .. " & " .. L["Mail"])
	local function Slider(label, key, low, high, y2, after)
		local s = W.Slider(frame, 220, low, high, 1, function(sl, value)
			value = math.floor(value + .5)
			sl.caption:SetText(label .. ": |cffffffff" .. value)
			if Altoholic.db and not sl.updating then
				O()[key] = value
				if after then after() end
			end
		end)
		s:SetPoint("TOPLEFT", frame, "TOPLEFT", x + 8, y2)
		return s
	end
	self.angle = Slider(L["Minimap icon angle"], "MinimapIconAngle", 1, 360, -60, UI.PlaceMinimapButton)
	self.radius = Slider(L["Minimap icon radius"], "MinimapIconRadius", 1, 200, -110, UI.PlaceMinimapButton)
	self.expiry = Slider(L["Warn when mail expires in fewer days than"], "MailWarningThreshold", 1, 15, -160)

	self.loots = W.Text(frame)
	self.loots:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -200)
	self.loots:SetTextColor(.7, .7, .7)
end

function view:Update()
	local O = Altoholic.db.account.options
	for key, cb in pairs(self.boxes) do cb:SetChecked(O[key] == 1) end
	for slider, key in pairs({ [self.angle] = "MinimapIconAngle", [self.radius] = "MinimapIconRadius", [self.expiry] = "MailWarningThreshold" }) do
		slider.updating = true
		slider:SetValue(O[key])
		slider.updating = nil
		slider:GetScript("OnValueChanged")(slider, O[key])
	end
	self.loots:SetText(L["Loot tables"] .. ": |cff00ff00" .. O.TotalLoots .. "|r " .. L["Loots"] .. " / |cff00ff00" .. O.UnknownLoots .. "|r " .. L["Unknown"])
end

UI.RegisterView("Options", view)
