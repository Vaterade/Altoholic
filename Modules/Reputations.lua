local L = Altoholic.L
local V = Altoholic.vars
local WHITE		= "|cFFFFFFFF"
local GREEN		= "|cFF00FF00"
local TEAL		= "|cFF00FF9A"
local YELLOW	= "|cFFFFFF00"
local ORANGE	= "|cFFFF7F00"


function Altoholic:Reputations_Update()
	local VisibleLines = 11
	local frame = "AltoReputations"
	local entry = frame.."Entry"
	-- ** draw class icons **
	local i = 1
	-- for CharacterName, c in pairs(self.db.account.data[V.faction][V.realm].char) do
	local byLevel = Altoholic:Get_Sorted_Character_List(V.faction, V.realm)
	for _, CharacterName in ipairs(byLevel) do
		-- DEFAULT_CHAT_FRAME:AddMessage("Handling "..CharacterName)
		local c = self.db.account.data[V.faction][V.realm].char[CharacterName]
		local itemName = "AltoReputationsClassesItem" .. i;
		local itemButton = _G[itemName];
		-- Only buttons for 10 columns defined; so we stop when buttons stop being defined
		if itemButton == nil then break end
		itemButton:SetScript("OnEnter", Altoholic_Reputations_OnEnter)
		itemButton:SetScript("OnLeave", function(self) AltoTooltip:Hide() end)
		itemButton:SetScript("OnClick", Altoholic_Equipment_OnClick)
		local tc = self.ClassInfo[ self.Classes[c.class] ].texcoord
		local itemTexture = _G[itemName .. "IconTexture"]
		itemTexture:SetTexture(self.classicon);
		itemTexture:SetTexCoord(tc[1], tc[2], tc[3], tc[4]);
		itemTexture:SetWidth(36);
		itemTexture:SetHeight(36);
		itemTexture:SetAllPoints(itemButton);
		itemButton.CharName = CharacterName
		_G[itemName]:Show()
		i = i + 1
	end
	while i <= 10 do
		_G["AltoReputationsClassesItem" .. i]:Hide()
		_G["AltoReputationsClassesItem" .. i].CharName = nil
		i = i + 1
	end
	_G[entry .. "1"]:Show()
	_G[entry .. "1"]:SetID(0)
	-- ** draw factions **
	local offset = FauxScrollFrame_GetOffset(_G[frame.."ScrollFrame"]);
	local DisplayedCount = 0
	local VisibleCount = 0
	local DrawFactionGroup
	i=1
	for line, s in pairs(V.Factions) do
		if (offset > 0) or (DisplayedCount >= VisibleLines) then		-- if the line will not be visible
			if type(s) == "table" then								-- then keep track of counters
				if s.isCollapsed == false then
					DrawFactionGroup = true
				else
					DrawFactionGroup = false
				end
				VisibleCount = VisibleCount + 1
				offset = offset - 1		-- no further control, nevermind if it goes negative
			elseif DrawFactionGroup then
				VisibleCount = VisibleCount + 1
				offset = offset - 1		-- no further control, nevermind if it goes negative
			end
		else		-- line will be displayed
			if type(s) == "table" then
				if s.isCollapsed == false then
					_G[entry..i.."Collapse"]:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
					DrawFactionGroup = true
				else
					_G[entry..i.."Collapse"]:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
					DrawFactionGroup = false
				end
				_G[entry..i.."Collapse"]:Show()
				_G[entry..i.."Name"]:SetText(s.name)
				_G[entry..i.."Name"]:SetJustifyH("LEFT")
				_G[entry..i.."Name"]:SetPoint("TOPLEFT", 25, 0)
				for j=1, 10 do		-- hide the 10 rep buttons
					itemButton = _G[entry.. i .. "Item" .. j];
					itemButton.CharName = nil
					itemButton:Hide()
				end
				_G[entry..i]:SetID(line)
				_G[entry..i]:Show()
				i = i + 1
				VisibleCount = VisibleCount + 1
				DisplayedCount = DisplayedCount + 1
			elseif DrawFactionGroup then
				local r = self.db.account.data[V.faction][V.realm].reputation[s]
				_G[entry..i.."Collapse"]:Hide()
				_G[entry..i.."Name"]:SetText(WHITE .. s)
				_G[entry..i.."Name"]:SetJustifyH("RIGHT")
				_G[entry..i.."Name"]:SetPoint("TOPLEFT", 15, 0)
				local j = 1
				-- for CharacterName, c in pairs(self.db.account.data[V.faction][V.realm].char) do
                for _, CharacterName in ipairs(byLevel) do
                    -- DEFAULT_CHAT_FRAME:AddMessage("Handling "..CharacterName)
                    c = self.db.account.data[V.faction][V.realm].char[CharacterName]
					local itemName = entry.. i .. "Item" .. j;
					local itemButton = _G[itemName];
                    if itemButton == nil then break end
					itemButton:SetScript("OnEnter", Altoholic_Reputations_OnEnter)
					itemButton:SetScript("OnClick", Altoholic_Reputations_OnClick)
					if r[CharacterName] ~= nil then		-- if the current char has info for this faction ..
						local itemTexture = _G[itemName .. "_Background"]
						local bottom, _, _, rate = self:GetReputationInfo(r[CharacterName])
						_G[itemName .. "Name"]:SetText(format("%2d", floor(rate)) .. "%")
						if bottom == -42000 then
							_G[itemName .. "Name"]:SetTextColor(0.8, 0.13, 0.13)
						elseif bottom == -6000 then
							_G[itemName .. "Name"]:SetTextColor(1.0, 0.0, 0.0)
						elseif bottom == -3000 then
							_G[itemName .. "Name"]:SetTextColor(0.93, 0.4, 0.13)
						elseif bottom == 0 then
							_G[itemName .. "Name"]:SetTextColor(1.0, 1.0, 0.0)
						elseif bottom == 3000 then
							_G[itemName .. "Name"]:SetTextColor(0.0, 1.0, 0.0)
						elseif bottom == 9000 then
							_G[itemName .. "Name"]:SetTextColor(0.0, 1.0, 0.53)
						elseif bottom == 21000 then
							_G[itemName .. "Name"]:SetTextColor(0.0, 1.0, 0.8)
						elseif bottom == 42000 then
							_G[itemName .. "Name"]:SetTextColor(0.0, 1.0, 1.0)
						end
						itemButton.CharName = CharacterName
						itemButton:Show()
					else
						itemButton.CharName = nil
						itemButton:Hide()
					end
					j = j + 1
				end
				_G[entry..i]:SetID(line)
				_G[entry..i]:Show()
				i = i + 1
				VisibleCount = VisibleCount + 1
				DisplayedCount = DisplayedCount + 1
			end
		end
	end
	while i <= VisibleLines do
		_G[entry..i]:SetID(0)
		_G[entry..i]:Hide()
		i = i + 1
	end
	FauxScrollFrame_Update(_G[frame.."ScrollFrame"], VisibleCount, VisibleLines, 41);
end

function Altoholic_Reputations_OnEnter(self)
	local repID = self:GetParent():GetID()
	if repID == 0 then		-- class icon
		V.CurrentFaction = V.faction
		V.CurrentRealm = V.realm
		Altoholic:DrawCharacterTooltip(self, self.CharName)
		return
	end
	local r = Altoholic.db.account.data[V.faction][V.realm]
	local repName = V.Factions[repID]
	local charName = self.CharName
	local c = Altoholic.db.account.data[V.faction][V.realm].char[charName]
	local bottom, top, earned, rate = Altoholic:GetReputationInfo( r.reputation[repName][charName] )
	AltoTooltip:SetOwner(self, "ANCHOR_LEFT");
	AltoTooltip:ClearLines();
	AltoTooltip:AddLine(Altoholic:GetClassColor(c.class) .. charName .. WHITE .. " @ " ..	TEAL .. repName,1,1,1);
	local repLevel = Altoholic:GetRepLevelString(bottom)
	AltoTooltip:AddLine(repLevel .. ": " ..(earned - bottom) .. "/" .. (top - bottom) .. YELLOW .. " (" .. format("%d", floor(rate)) .. "%)",1,1,1);
	local suggestion = Altoholic:GetSuggestion(repName, bottom)
	if suggestion then
		AltoTooltip:AddLine(" ",1,1,1);
		AltoTooltip:AddLine("Suggestion: ",1,1,1);
		AltoTooltip:AddLine(TEAL .. suggestion,1,1,1);
	end
	AltoTooltip:AddLine(" ",1,1,1);
	AltoTooltip:AddLine(GREEN .. L["Shift-Click to link this info"],1,1,1);
	AltoTooltip:Show();
end

function Altoholic_Reputations_OnClick(self, button)
	local repID = self:GetParent():GetID()
	if repID == 0 then
		Altoholic:DrawCharacterTooltip(self, self.CharName)
		return
	end
	local r = Altoholic.db.account.data[V.faction][V.realm]
	local bottom, top, earned = Altoholic:GetReputationInfo( r.reputation[V.Factions[repID]][self.CharName] )
	local repLevel = Altoholic:GetRepLevelString(bottom)
    if button == "LeftButton" and IsShiftKeyDown() then
        if ( ChatFrameEditBox:IsShown() ) then
            ChatFrameEditBox:Insert(self.CharName .. L[" is "] .. repLevel .. L[" with "] .. V.Factions[repID] .. " (" .. (earned - bottom) .. "/" .. (top - bottom) .. ")");
        elseif (WIM_EditBoxInFocus) then
            WIM_EditBoxInFocus:Insert(self.CharName .. L[" is "] .. repLevel .. L[" with "] .. V.Factions[repID] .. " (" .. (earned - bottom) .. "/" .. (top - bottom) .. ")");
        end
	end
end

function Altoholic:GetReputationInfo(repString)
	local bottom, top, earned = strsplit("|", repString)
	bottom = tonumber(bottom)
	top = tonumber(top)
	earned = tonumber(earned)
	local rate = (earned - bottom) / (top - bottom) * 100

	return bottom, top, earned, rate
end

function Altoholic:GetRepLevelString(bottom)
	if bottom == -42000 then
		return FACTION_STANDING_LABEL1 -- "Hated"
	elseif bottom == -6000 then
		return FACTION_STANDING_LABEL2 -- "Hostile"
	elseif bottom == -3000 then
		return FACTION_STANDING_LABEL3 -- "Unfriendly"
	elseif bottom == 0 then
		return FACTION_STANDING_LABEL4 -- "Neutral"
	elseif bottom == 3000 then
		return FACTION_STANDING_LABEL5 -- "Friendly"
	elseif bottom == 9000 then
		return FACTION_STANDING_LABEL6 -- "Honored"
	elseif bottom == 21000 then
		return FACTION_STANDING_LABEL7 -- "Revered"
	elseif bottom == 42000 then
		return FACTION_STANDING_LABEL8 -- "Exalted"
	end
end

function Altoholic:Reputations_ToggleHeader(button)
	local id = button:GetParent():GetID()
	if id ~= 0 then
		self:ToggleCollapsed(V.Factions[id])
	end
	self:Reputations_Update()
end
