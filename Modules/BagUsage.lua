local L = Altoholic.L
local V = Altoholic.vars
local INFO_REALM_LINE = 1
local INFO_CHARACTER_LINE = 2
local INFO_TOTAL_LINE = 3
local GREEN		= "|cFF00FF00"
local YELLOW	= "|cFFFFFF00"
local GOLD		= "|cFFFFD700"
local CYAN		= "|cFF1CFAFE"

function Altoholic:BagUsage_Update()
	local VisibleLines = 14
	local frame = "AltoBags"
	local entry = frame.."Entry"
	
	if #self.CharacterInfo == 0 then
		self:ClearScrollFrame(_G[frame.."ScrollFrame"], entry, VisibleLines, 18)
		return
	end
	
	local offset = FauxScrollFrame_GetOffset(_G[frame.."ScrollFrame"]);
	local DisplayedCount = 0
	local VisibleCount = 0
	local DrawRealm
	local CurrentFaction, CurrentRealm
	local i=1
	
	for line, s in pairs(self.CharacterInfo) do
		if (offset > 0) or (DisplayedCount >= VisibleLines) then		-- if the line will not be visible
			if s.linetype == INFO_REALM_LINE then								-- then keep track of counters
				CurrentFaction = s.faction
				CurrentRealm = s.realm
				if s.isCollapsed == false then
					DrawRealm = true
				else
					DrawRealm = false
				end
				VisibleCount = VisibleCount + 1
				offset = offset - 1		-- no further control, nevermind if it goes negative
			elseif DrawRealm then
				VisibleCount = VisibleCount + 1
				offset = offset - 1		-- no further control, nevermind if it goes negative
			end
		else		-- line will be displayed
			if s.linetype == INFO_REALM_LINE then
				CurrentFaction = s.faction
				CurrentRealm = s.realm
				if s.isCollapsed == false then
					_G[entry..i.."Collapse"]:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up"); 
					DrawRealm = true
				else
					_G[entry..i.."Collapse"]:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
					DrawRealm = false
				end
				_G[entry..i.."Collapse"]:Show()
				_G[entry..i.."Name"]:SetText(self:GetFullRealmString(s.faction, s.realm))
				_G[entry..i.."Name"]:SetJustifyH("LEFT")
				_G[entry..i.."Name"]:SetPoint("TOPLEFT", 25, 0)
				_G[entry..i.."Name"]:SetWidth(210)
				_G[entry..i.."Level"]:SetText("")
				_G[entry..i.."BagSlotsNormalText"]:SetText("")
				_G[entry..i.."BankSlotsNormalText"]:SetText("")
				_G[entry..i]:SetID(line)
				_G[entry..i]:Show()
				i = i + 1
				VisibleCount = VisibleCount + 1
				DisplayedCount = DisplayedCount + 1
			elseif DrawRealm then
				if (s.linetype == INFO_CHARACTER_LINE) then
					local c = self.db.account.data[CurrentFaction][CurrentRealm].char[s.name]
					local color = self:GetClassColor(c.class)
				
					_G[entry..i.."Collapse"]:Hide()
					_G[entry..i.."Name"]:SetText(color .. s.name)
					_G[entry..i.."Name"]:SetJustifyH("RIGHT")
					_G[entry..i.."Name"]:SetPoint("TOPLEFT", 15, 0)
					_G[entry..i.."Name"]:SetWidth(70)
					_G[entry..i.."Level"]:SetText(color .. "Lv |cFF00FF00" .. c.level .. color .. " " .. c.race .. " " .. c.class)
					_G[entry..i.."Level"]:SetJustifyH("LEFT")
					_G[entry..i.."BagSlotsNormalText"]:SetText(c.bags)
					_G[entry..i.."BankSlotsNormalText"]:SetText(s.bankslots)
				elseif (s.linetype == INFO_TOTAL_LINE) then
					_G[entry..i.."Collapse"]:Hide()
					_G[entry..i.."Name"]:SetText(L["Totals"])
					_G[entry..i.."Name"]:SetJustifyH("LEFT")
					_G[entry..i.."Name"]:SetPoint("TOPLEFT", 15, 0)
					_G[entry..i.."Name"]:SetWidth(70)
					_G[entry..i.."Level"]:SetText(s.level)
					_G[entry..i.."Level"]:SetJustifyH("RIGHT")
					_G[entry..i.."BagSlotsNormalText"]:SetText("")
					_G[entry..i.."BankSlotsNormalText"]:SetText("")
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

function Altoholic_BagUsage_OnEnter(self)
	local line = self:GetParent():GetID()
	local s = Altoholic.CharacterInfo[line]
	
	if s.linetype ~= INFO_CHARACTER_LINE then		
		return
	end
	
	local Faction, Realm = Altoholic:GetCharacterInfo(line)
	local c = Altoholic.db.account.data[Faction][Realm].char[s.name]
	
	AltoTooltip:ClearLines();
	AltoTooltip:SetOwner(self, "ANCHOR_RIGHT");
	AltoTooltip:AddLine(Altoholic:GetClassColor(c.class) .. s.name,1,1,1);
	AltoTooltip:AddLine(L["Level"] .. " " .. GREEN .. c.level .. " |r".. c.race .. " " .. c.class,1,1,1);
	AltoTooltip:AddLine(" ",1,1,1);

	local id = self:GetID()
	local numSlots
	local numFree = 0
	
	if id == 1 then		-- 1 for player bags, 2 for bank bags
		AltoTooltip:AddLine(GOLD .. "16 |r" .. L["slots"] .. " (" .. GREEN 
			.. c.bag["Bag0"].freeslots .. "|r " .. L["free"] .. ") [" .. BACKPACK_TOOLTIP .. "]",1,1,1);
				
		numSlots = 16
		numFree = c.bag["Bag0"].freeslots
		for i = 1, 4 do
			local b = c.bag["Bag"..i]
			if b.link ~= nil then
				local bagType = Altoholic:GetBagTypeString(b.link)
				local bag = bagType and (YELLOW .. "(" .. bagType .. ")") or ""

				AltoTooltip:AddLine(GOLD .. b.size .. " |r" .. L["slots"] .. " ("  .. GREEN
						.. b.freeslots ..  "|r " ..L["free"] .. ") " .. b.link .. " " .. bag ,1,1,1);
				numSlots = numSlots + b.size
				numFree = numFree + b.freeslots
			end
		end	
	elseif (c.bankslots == nil) or (c.bankslots == "") then
		AltoTooltip:AddLine(L["Bank not visited yet"],1,1,1);
		AltoTooltip:Show();	
		return
	else
		AltoTooltip:AddLine(GOLD .. "28 |r" .. L["slots"] .. " (" .. GREEN 
						.. c.bag["Bag100"].freeslots ..  "|r " .. L["free"] .. ") [" .. L["Bank"] .. "]",1,1,1);
		numSlots = 28
		numFree = c.bag["Bag100"].freeslots
		for i = 5, 11 do
			local b = c.bag["Bag"..i]
			if b.link ~= nil then
				local bagType = Altoholic:GetBagTypeString(b.link)
				local bag = bagType and (YELLOW .. "(" .. bagType .. ")") or ""
			
				AltoTooltip:AddLine(GOLD .. b.size .. " |r" .. L["slots"] .. " ("  .. GREEN
						.. b.freeslots ..  "|r " ..L["free"] .. ") " .. b.link .. " " .. bag ,1,1,1);
				numSlots = numSlots + b.size
				numFree = numFree + b.freeslots
			end
		end
	end
	
	AltoTooltip:AddLine(" ",1,1,1);
	AltoTooltip:AddLine(CYAN .. numSlots .. " |r" .. L["slots"] .. " ("  .. GREEN .. numFree .. "|r " ..L["free"] .. ") ",1,1,1);
	AltoTooltip:Show();	
end

-- The kind of a specialty bag ("Soul Bag", "Quiver"...) from the bag item's own
-- subclass, so Turtle's custom bag types are named too. nil for a plain bag or
-- one the client has not cached.
function Altoholic:GetBagTypeString(link)
	local _, _, subType, _, _, classID, subClassID = C_Item.GetItemInfoInstant(link)
	if classID == Enum.ItemClass.Quiver or (classID == Enum.ItemClass.Container and subClassID ~= 0) then
		return subType
	end
end
