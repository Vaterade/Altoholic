-- The minimap button: a small square icon in pfUI's style on the minimap's edge. Left-click
-- opens the window, drag moves it round the minimap. Its angle and distance are options.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local button

function UI.PlaceMinimapButton()
	if not button then return end
	local O = Altoholic.db.account.options
	local angle = math.rad(O.MinimapIconAngle or 268)
	local radius = O.MinimapIconRadius or 78
	button:ClearAllPoints()
	-- the angle runs the way the old button's did, so a saved position stays where it was
	button:SetPoint("CENTER", Minimap, "CENTER", -math.cos(angle) * radius, math.sin(angle) * radius)
end

function UI.UpdateMinimapButton()
	if not button then return end
	if Altoholic:Option("ShowMinimap") then button:Show() else button:Hide() end
	UI.PlaceMinimapButton()
end

local function FollowCursor()
	local x, y = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	local cx, cy = Minimap:GetCenter()
	local angle = math.deg(math.atan2(y / scale - cy, cx - x / scale))
	if angle < 0 then angle = angle + 360 end
	Altoholic.db.account.options.MinimapIconAngle = math.floor(angle + .5)
	UI.PlaceMinimapButton()
	if UI.views.Options and UI.views.Options.frame then UI.views.Options:Update() end
end

function UI.CreateMinimapButton()
	if button then return end
	button = CreateFrame("Button", "AltoholicMinimapIcon", Minimap)
	button:SetWidth(22)
	button:SetHeight(22)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	W.Backdrop(button, 1)
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints(button)
	icon:SetTexture("Interface\\Icons\\INV_Drink_05")
	icon:SetTexCoord(.08, .92, .08, .92)
	button.hr, button.hg, button.hb = W.TEAL[1], W.TEAL[2], W.TEAL[3]
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnClick", function(_, mouse)
		if mouse == "RightButton" then UI.Open("options") else UI.Toggle() end
	end)
	button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", FollowCursor) end)
	button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	button:SetScript("OnEnter", function(self)
		self.backdrop:SetBackdropBorderColor(W.TEAL[1], W.TEAL[2], W.TEAL[3], 1)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine(W.TEAL_HEX .. "Alto|rholic")
		GameTooltip:AddLine(L["Left-click to open, right-click for options, drag to move"], .8, .8, .8)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function(self)
		self.backdrop:SetBackdropBorderColor(W.BorderColor())
		GameTooltip:Hide()
	end)
	UI.UpdateMinimapButton()
end

table.insert(UI.loginHooks, function()
	Altoholic.db.account.options.MatchPfUI = nil		-- the 1.x window's pfUI skin switch
	UI.CreateMinimapButton()
end)
