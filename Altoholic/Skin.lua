local L = Altoholic.L
local TEAL		= "|cFF00FF9A"
local WHITE		= "|cFFFFFFFF"

-- Optional pfUI look for the Altoholic window. Purely cosmetic, and pfUI is never required:
-- its helpers are looked up at use and called through pcall, so a change on pfUI's side can
-- only cost the skin, never raise an error.
local applied = false
local env

local function Env()
	if env == nil then
		local ok, e = pcall(pfUI.GetEnvironment, pfUI)
		env = ok and e or false
	end
	return env
end

-- calls the pfUI helper of that name on a frame, does nothing if either is missing
local function Skin(helper, frame, ...)
	local e = Env()
	local f = e and e[helper]
	if f and frame then
		pcall(f, frame, ...)
	end
end

function Altoholic:Skin_Available()
	return (pfUI and pfUI.GetEnvironment) and true or false
end

-- MatchPfUI has no default: until the box is clicked, the skin is on when pfUI is there
function Altoholic:Skin_Enabled()
	if not self:Skin_Available() then return false end
	local stored = self.db and self.db.account.options.MatchPfUI
	if stored == nil then return true end
	return stored == 1
end

function Altoholic:Skin_Apply()
	if applied or not self:Skin_Enabled() or not Env() then return end
	applied = true

	-- the window: same size and art as the auction frame, skinned the way pfUI skins that one
	local frame = AltoholicFrame
	Skin("StripTextures", frame, true)
	Skin("CreateBackdrop", frame, nil, nil, .75)
	Skin("CreateBackdropShadow", frame)
	Skin("SkinCloseButton", AltoholicFrameCloseButton, frame.backdrop, -6, -6)
	if frame.backdrop then
		AltoholicFrameName:ClearAllPoints()
		AltoholicFrameName:SetPoint("TOP", frame.backdrop, "TOP", 0, -10)
	end

	-- left-hand menu
	for i = 1, 15 do
		local button = _G["CategoryButton" .. i]
		Skin("StripTextures", button, nil, "BACKGROUND")
		Skin("SkinButton", button)
	end
	Skin("StripTextures", AltoholicMenuScrollFrame)
	Skin("SkinScrollbar", AltoholicMenuScrollFrameScrollBar)

	-- search bar
	for _, name in ipairs({ "SearchEditBox", "MinLevel", "MaxLevel" }) do
		local box = _G["AltoholicFrame_" .. name]
		Skin("StripTextures", box, nil, "BACKGROUND")
		Skin("CreateBackdrop", box, nil, true)
	end
	Skin("SkinButton", AltoholicFrame_ResetButton)
	Skin("SkinButton", AltoholicFrame_SearchButton)
	Skin("SkinDropDown", RarityDropDownMenu)
	Skin("SkinDropDown", SlotsDropDownMenu)
	for _, name in ipairs({ "IncludeNoMinLevel", "CheckButton1", "CheckButton2", "CheckButton3" }) do
		Skin("SkinCheckbox", _G["AltoholicFrame_" .. name])
	end

	-- the list of each tab
	for _, name in ipairs(self.Categories) do
		local scrollFrame = _G[name .. "ScrollFrame"]
		if scrollFrame then
			Skin("StripTextures", scrollFrame)
			Skin("SkinScrollbar", _G[name .. "ScrollFrameScrollBar"])
		end
	end

	-- options tab
	for _, child in ipairs({ AltoOptions:GetChildren() }) do
		local objectType = child:GetObjectType()
		if objectType == "CheckButton" then
			Skin("SkinCheckbox", child)
		elseif objectType == "Slider" then
			Skin("SkinSlider", child)
		end
	end

	Skin("CreateBackdrop", AltoTooltip)
	Skin("CreateBackdropShadow", AltoTooltip)
end

-- pfUI's backdrops are frames of their own, so the skin can be put on at any time
-- but only comes off with a reload
function Altoholic:Skin_OnSettingChanged(on)
	if on then
		self:Skin_Apply()
	elseif applied then
		DEFAULT_CHAT_FRAME:AddMessage(TEAL .. "Altoholic: " .. WHITE .. L["pfUI styling stays until you /reload"])
	end
end
