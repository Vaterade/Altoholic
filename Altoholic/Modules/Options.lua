-- *** FRAME HANDLERS ***
-- the widgets can fire before the saved variables are loaded, there is nothing to store then

function Altoholic:Options_InitSlider(slider, tooltip, low, high, label)
	local name = slider:GetName()
	slider.tooltipText = tooltip
	_G[name .. "Low"]:SetText(low)
	_G[name .. "High"]:SetText(high)
	_G[name .. "Text"]:SetText(label .. slider:GetValue() .. ")")
end

function Altoholic:Options_MailExpiry_OnValueChanged(slider)
	_G[slider:GetName() .. "Text"]:SetText(XML_TEXT_15 .. slider:GetValue() .. ")")
	if self.db then
		self.db.account.options.MailWarningThreshold = slider:GetValue()
	end
end

-- stores the state of a check button as 1 or 0
function Altoholic:Options_Toggle(button, option)
	if self.db then
		self.db.account.options[option] = button:GetChecked() and 1 or 0
	end
end

function Altoholic:Options_ShowMinimap_OnClick(button)
	if not self.db then return end
	self:Options_Toggle(button, "ShowMinimap")
	if button:GetChecked() then
		AltoholicMinimapButton:Show()
	else
		AltoholicMinimapButton:Hide()
	end
end

-- only a click stores the setting, see Skin_Enabled
function Altoholic:Options_MatchPfUI_OnClick(button)
	if not self.db then return end
	if not self:Skin_Available() then
		button:SetChecked(nil)
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF9AAltoholic: |cFFFFFFFF" .. Altoholic.L["pfUI is not installed, so there is nothing to match"])
		return
	end
	self:Options_Toggle(button, "MatchPfUI")
	self:Skin_OnSettingChanged(button:GetChecked())
end

function Altoholic:Options_AutoQuery_OnEnter(button)
	AltoTooltip:SetOwner(button, "ANCHOR_LEFT");
	AltoTooltip:ClearLines();
	AltoTooltip:AddLine(XML_TEXT_26)
	AltoTooltip:Show();
end
