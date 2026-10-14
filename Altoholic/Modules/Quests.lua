local L = Altoholic.L
local V = Altoholic.vars
local WHITE		= "|cFFFFFFFF"
local RED		= "|cFFFF0000"
local GREEN		= "|cFF00FF00"
local TEAL		= "|cFF00FF9A"

function Altoholic:Quests_Update()
	local c = self.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt]
	local VisibleLines = 14
	local frame = "AltoQuests"
	local entry = frame.."Entry"
	if #c.questlog == 0 then
		_G["AltoholicFrame_Status"]:SetText("|cFFFFD700" .. V.CurrentAlt .. " of ".. V.CurrentRealm .. " |cFFFFFFFF" .. "No quests found")
		_G["AltoholicFrame_Status"]:Show()
		self:ClearScrollFrame(_G[frame.."ScrollFrame"], entry, VisibleLines, 18)
		return
	else
		_G["AltoholicFrame_Status"]:SetText("|cFFFFD700" .. V.CurrentAlt .. " of ".. V.CurrentRealm .. " |cFFFFFFFF" .. QUEST_LOG)
		_G["AltoholicFrame_Status"]:Show()
	end
	local offset = FauxScrollFrame_GetOffset(_G[frame.."ScrollFrame"]);
	local DisplayedCount = 0
	local VisibleCount = 0
	local DrawGroup
	local i=1
	for line, s in pairs(c.questlog) do
		if (offset > 0) or (DisplayedCount >= VisibleLines) then
			if s.isHeader then
				if s.isCollapsed == false then
					DrawGroup = true
				else
					DrawGroup = false
				end
				VisibleCount = VisibleCount + 1
				offset = offset - 1
			elseif DrawGroup then
				VisibleCount = VisibleCount + 1
				offset = offset - 1
			end
		else
			if s.isHeader then
				if s.isCollapsed == false then
					_G[entry..i.."Collapse"]:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up"); 
					DrawGroup = true
				else
					_G[entry..i.."Collapse"]:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
					DrawGroup = false
				end
				_G[entry..i.."Collapse"]:Show()
				_G[entry..i.."QuestLinkNormalText"]:SetText(TEAL .. s.name)
				_G[entry..i.."QuestLink"]:SetID(0)
				_G[entry..i.."QuestLink"]:SetPoint("TOPLEFT", 25, 0)
				_G[entry..i.."Tag"]:Hide()
				_G[entry..i.."Status"]:Hide()
				_G[entry..i.."Money"]:Hide()
				_G[entry..i]:SetID(line)
				_G[entry..i]:Show()
				i = i + 1
				VisibleCount = VisibleCount + 1
				DisplayedCount = DisplayedCount + 1
			elseif DrawGroup then
				_G[entry..i.."Collapse"]:Hide()	
				local _, id, level = self:GetQuestDetails(s.link)
				_G[entry..i.."QuestLinkNormalText"]:SetText(WHITE .. "[" .. s.level .. "] " .. s.link)
				_G[entry..i.."QuestLink"]:SetID(line)
				_G[entry..i.."QuestLink"]:SetPoint("TOPLEFT", 15, 0)
				if s.tag then 
					_G[entry..i.."Tag"]:SetText(self:GetQuestTypeString(s.tag, self:SuggestGroupSize(s.tag, s.level)))
					_G[entry..i.."Tag"]:Show()
				else
					_G[entry..i.."Tag"]:Hide()
				end
				if s.isComplete then
					if s.isComplete == 1 then
						_G[entry..i.."Status"]:SetText(GREEN .. COMPLETE)
					elseif s.isComplete == -1 then
						_G[entry..i.."Status"]:SetText(RED .. FAILED)
					end
					_G[entry..i.."Status"]:Show()
				else
					_G[entry..i.."Status"]:Hide()
				end
				if s.money then
					_G[entry..i.."Money"]:SetText(self:GetMoneyString(s.money))
					_G[entry..i.."Money"]:Show()
				else
					_G[entry..i.."Money"]:Hide()
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

function Altoholic:GetQuestDetails(questString)
	if not questString then return nil end
	local _, _, questInfo, questName = Altoholic:strsplit("|", questString)
	local _, questId, questLevel = Altoholic:strsplit(":", questInfo)
	questName = string.sub(questName, 3, -2)
	return questName, questId, questLevel
end

function Altoholic:QuestLink_OnClick(button, id)
    if id == 0 then return end
    if ( button == "LeftButton" ) and ( IsShiftKeyDown() ) then
        if ( ChatFrameEditBox:IsShown() ) then
            local v = Altoholic.vars
            local link = self.db.account.data[v.CurrentFaction][v.CurrentRealm].char[v.CurrentAlt].questlog[id].link
            if not link then return end
            ChatFrameEditBox:Insert(link);
        elseif (WIM_EditBoxInFocus) then
            local v = Altoholic.vars
            local link = self.db.account.data[v.CurrentFaction][v.CurrentRealm].char[v.CurrentAlt].questlog[id].link
            if not link then return end
            WIM_EditBoxInFocus:Insert(link);
        end
    end
end

function Altoholic:QuestLink_OnEnter(self)
	local id = self:GetID()
	if id == 0 then return end
	local r = Altoholic.db.account.data[V.CurrentFaction][V.CurrentRealm]
    local title = r.char[V.CurrentAlt].questlog[id].title
    local o = r.char[V.CurrentAlt].questlog[id]
	if not title then return end
	GameTooltip:ClearLines();
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:AddLine("|cffffffff"..o.questObjectives.."|r",1,1,1,true);
	local bOtherCharsOnQuest
	for CharacterName, c in pairs(r.char) do
		if CharacterName ~= V.CurrentAlt then
			for index, q in pairs(c.questlog) do
				if Altoholic:IsSameQuest(o, q) then
					if not bOtherCharsOnQuest then
						GameTooltip:AddLine(" ",1,1,1);
						GameTooltip:AddLine(GREEN .. L["Are also on this quest:"],1,1,1);
						bOtherCharsOnQuest = true
					end
					GameTooltip:AddLine(Altoholic:GetClassColor(c.class) .. CharacterName,1,1,1);
				end
			end
		end
	end
	GameTooltip:Show();
end

-- true when two saved quest log entries are the same quest; entries saved before the
-- quest ID was recorded can only be compared by title
function Altoholic:IsSameQuest(q1, q2)
	if q1.id and q2.id then
		return q1.id == q2.id
	end
	return q1.title ~= nil and q1.title == q2.title
end

function Altoholic:UpdateQuestLog()
	local q = {}
	-- the scan moves the selection, and the indices shift while the headers are open
	local selection = GetQuestLogSelection()
	local selectedID = selection > 0 and C_QuestLog.GetQuestIDForLogIndex(selection) or 0
	-- quests under a collapsed header are not in the list, so open the headers for the scan ..
	local collapsed = {}
	for i = GetNumQuestLogEntries(), 1, -1 do
		local title, _, _, isHeader, isCollapsed = GetQuestLogTitle(i);
		if isHeader and isCollapsed then
			collapsed[title] = true
			ExpandQuestHeader(i)
		end
	end
	-- the quest text and the reward can only be read for the selected quest
	for i = 1, GetNumQuestLogEntries() do
		q[i] = {}
		local title, level, questTag, isHeader, _, isComplete = GetQuestLogTitle(i);
		if not isHeader then
			local questID = C_QuestLog.GetQuestIDForLogIndex(i) or 0
			SelectQuestLogEntry(i);
			local questDescription, questObjectives = GetQuestLogQuestText();
			q[i].id = questID > 0 and questID or nil
			q[i].title = title
			q[i].tag = questTag
			q[i].isComplete = isComplete
			q[i].link = "|cffffff00|Hquest:" .. questID .. ":" .. level .. ":0:0|h["..title.."]|h|r"
			q[i].level = level
			q[i].questDescription = questDescription
			q[i].questObjectives = questObjectives
			q[i].money = GetQuestLogRewardMoney();
		else
			q[i].name = title
			q[i].isHeader = true
			q[i].isCollapsed = false
		end
	end
	-- .. and close them again, bottom up so the indices above stay valid
	for i = GetNumQuestLogEntries(), 1, -1 do
		local title, _, _, isHeader = GetQuestLogTitle(i);
		if isHeader and collapsed[title] then
			CollapseQuestHeader(i)
		end
	end
	SelectQuestLogEntry(selectedID > 0 and C_QuestLog.GetLogIndexForQuestID(selectedID) or 0)
	self.db.account.data[V.faction][V.realm].char[V.player].questlog = q
end

function Altoholic:SuggestGroupSize(tag, level)
    if tag == nil then return end

    if tag == "Elite" then
        return "2+"
    elseif tag == "Dungeon" then
        return "5"
    elseif tag == "PVP" then
        return "5+"
    elseif tag == "Raid" then
        return "10+"
    end
end

-- *** EVENT HANDLERS ***
function Altoholic:UNIT_QUEST_LOG_CHANGED()		-- triggered when accepting/validating a quest .. but too soon to refresh data
	self:RegisterEvent("QUEST_LOG_UPDATE")			-- so register for this one ..
end

-- an abandoned quest is not always announced by UNIT_QUEST_LOG_CHANGED
function Altoholic:QUEST_ACCEPTED()
	self:RegisterEvent("QUEST_LOG_UPDATE")
end

function Altoholic:QUEST_REMOVED()
	self:RegisterEvent("QUEST_LOG_UPDATE")
end

function Altoholic:QUEST_LOG_UPDATE()
	self:UnregisterEvent("QUEST_LOG_UPDATE")		-- .. and unregister it right away, since we only want it to be processed once (and it's triggered way too often otherwise)
	self:UpdateQuestLog()	
end

function Altoholic:Quests_ToggleHeader(button)
	local id = button:GetParent():GetID()
	if id ~= 0 then
		local c = self.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt]
		self:ToggleCollapsed(c.questlog[id])
	end
	self:Quests_Update()
end
