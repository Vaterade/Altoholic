local L = Altoholic.L
local V = Altoholic.vars
local TEAL		= "|cFF00FF9A"

function Altoholic:Recipes_Update()
	local c = self.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt]		-- current alt
	local VisibleLines = 14
	local frame = "AltoRecipes"
	local entry = frame.."Entry"
	if c.recipes[V.CurrentProfession].ScanFailed then
		_G["AltoholicFrame_Status"]:SetText(L["No data: "] .. V.CurrentProfession .. L[" scan failed for "] .. ": |cFFFFD700" .. V.CurrentAlt .. " of ".. V.CurrentRealm)
		_G["AltoholicFrame_Status"]:Show()
		self:ClearScrollFrame(_G[frame.."ScrollFrame"], entry, VisibleLines, 18)
		return
	else
		_G["AltoholicFrame_Status"]:SetText("|cFFFFD700" .. V.CurrentAlt .. " of ".. V.CurrentRealm .. " |cFFFFFFFF" .. V.CurrentProfession .. ": " .. V.CurrentProfessionLevel)
		_G["AltoholicFrame_Status"]:Show()
	end
	local offset = FauxScrollFrame_GetOffset(_G[frame.."ScrollFrame"]);
	local DisplayedCount = 0
	local VisibleCount = 0
	local DrawGroup = true
	local i=1
    for line, s in pairs(c.recipes[V.CurrentProfession].list) do
		if (offset > 0) or (DisplayedCount >= VisibleLines) then		-- if the line will not be visible
			if s.isHeader then													-- then keep track of counters
				if s.isCollapsed == false then
					DrawGroup = true
				else
					DrawGroup = false
				end
				VisibleCount = VisibleCount + 1
				offset = offset - 1		-- no further control, nevermind if it goes negative
			elseif DrawGroup then
				VisibleCount = VisibleCount + 1
				offset = offset - 1		-- no further control, nevermind if it goes negative
			end
		else		-- line will be displayed
			if s.isHeader then
				if s.isCollapsed == false then
					_G[entry..i.."Collapse"]:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up"); 
					DrawGroup = true
				else
					_G[entry..i.."Collapse"]:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
					DrawGroup = false
				end
				_G[entry..i.."Collapse"]:Show()
				_G[entry..i.."RecipeLinkNormalText"]:SetText(TEAL .. s.name)
				_G[entry..i.."RecipeLink"]:SetID(0)
				_G[entry..i.."RecipeLink"]:SetPoint("TOPLEFT", 25, 0)
                for j=1, 8 do
					_G[entry..i .. "Item" .. j]:Hide()
				end
				_G[entry..i]:SetID(line)
				_G[entry..i]:Show()
				i = i + 1
				VisibleCount = VisibleCount + 1
				DisplayedCount = DisplayedCount + 1		
			elseif DrawGroup then
				_G[entry..i.."Collapse"]:Hide()
				_G[entry..i.."RecipeLinkNormalText"]:SetText(s.link)
				_G[entry..i.."RecipeLink"]:SetID(line)
				_G[entry..i.."RecipeLink"]:SetPoint("TOPLEFT", 15, 0)
                local numReagents = s.numReagents
				for j=1, 8 do
					local itemName = entry..i .. "Item" .. j;
                    local first, second, third, fourth, fifth, sixth, seventh, eighth = string.match(s.reagents, "(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)")
                    local first, second, third, fourth, fifth, sixth, seventh = string.match(s.reagents, "(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)")
                    local first, second, third, fourth, fifth, sixth = string.match(s.reagents, "(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)")
                    local first, second, third, fourth, fifth = string.match(s.reagents, "(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)")
                    local first, second, third, fourth = string.match(s.reagents, "(%d+:%d+)|(%d+:%d+)|(%d+:%d+)|(%d+:%d+)")
                    local first, second, third = string.match(s.reagents, "(%d+:%d+)|(%d+:%d+)|(%d+:%d+)")
                    local first, second = string.match(s.reagents, "(%d+:%d+)|(%d+:%d+)")
                    local first = string.match(s.reagents, "(%d+:%d+)")
                    if eighth ~= nil and j == 8 then
                        reagent = eighth
                    elseif seventh ~= nil and j == 7 then
                        reagent = seventh
                    elseif sixth ~= nil and j == 6 then
                        reagent = sixth
                    elseif fifth ~= nil and j == 5 then
                        reagent = fifth
                    elseif fourth ~= nil and j == 4 then
                        reagent = fourth
                    elseif third ~= nil and j == 3 then
                        reagent = third
                    elseif second ~= nil and j == 2 then
                        reagent = second
                    elseif first ~= nil and j == 1 then
                        reagent = first
                    else
                        reagent = nil
                    end
					if reagent then
                        local reagentID, reagentCount = string.match(reagent, "(%d+):(%d+)")
                        reagentID = tonumber(reagentID)
						reagentCount = tonumber(reagentCount)
						local itemButton = _G[itemName];
						itemButton:SetID(reagentID)
						local itemTexture = _G[itemName .. "IconTexture"]
                        local _, _, _, _, _, _, _, _, itexture  = GetItemInfo(reagentID)
						itemTexture:SetTexture(itexture);
						itemTexture:SetWidth(18);
						itemTexture:SetHeight(18);
						itemTexture:SetAllPoints(itemButton);
						local itemCount = _G[itemName .. "Count"]
						itemCount:SetText(reagentCount);
						itemCount:Show();
						_G[itemName]:Show()
					else
						_G[itemName]:Hide()
					end
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
	FauxScrollFrame_Update(_G[frame.."ScrollFrame"], VisibleCount, VisibleLines, 18);
end

function Altoholic:Recipes_OnClick(button, id)
    if ( button == "LeftButton" ) and ( IsShiftKeyDown() ) then
        if ( ChatFrameEditBox:IsShown() ) then
            local v = Altoholic.vars
            local c = Altoholic.db.account.data[v.CurrentFaction][v.CurrentRealm].char[v.CurrentAlt]
            local r = c.recipes[v.CurrentProfession].list
            if not r then return end
            local link = r[id].link
            if not link then return end
            ChatFrameEditBox:Insert(link);
        elseif (WIM_EditBoxInFocus) then
            local v = Altoholic.vars
            local c = Altoholic.db.account.data[v.CurrentFaction][v.CurrentRealm].char[v.CurrentAlt]
            local r = c.recipes[v.CurrentProfession].list
            if not r then return end
            local link = r[id].link
            if not link then return end
            WIM_EditBoxInFocus:Insert(link);
        end
    end
end

function Altoholic:Recipes_OnEnter(frame)
    local id = frame:GetParent():GetID()
    local c = Altoholic.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt]
    if c.recipes[V.CurrentProfession].list[id].isHeader then return end
    local itemLink = itemLink
    if V.CurrentProfession == "Enchanting" then
        local enchantlink = c.recipes[V.CurrentProfession].list[id].link
        itemLink = Altoholic:GetEnchantIDFromLink(tostring(enchantlink))
    else
        local item = c.recipes[V.CurrentProfession].list[id].id
        if not item then item=16893 end
        _, itemLink = GetItemInfo(item)
    end
    if not itemLink then return end
    GameTooltip:SetOwner(frame, "ANCHOR_LEFT");
    GameTooltip:SetHyperlink(itemLink);
    GameTooltip:Show();
end

function Altoholic:Recipes_ToggleHeader(button)
	local id = button:GetParent():GetID()
	if id ~= 0 then
		local c = self.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt]
		self:ToggleCollapsed(c.recipes[V.CurrentProfession].list[id])
	end
	self:Recipes_Update()
end
