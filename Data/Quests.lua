-- The quest log.
local V = Altoholic.vars

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

function Altoholic:ResetWeeklyQuestsIfExpired(charInfo)
	if not charInfo then return end
	if not charInfo.CompletedQuests then return end

	-- code stolen from raid module
	local basetime = 1663128000 + 86400	-- this is for Nordanaar, every Thu
	local resetdays = 7
	local now = time()
	local passedresets = math.floor((now - basetime) / (resetdays * 86400))
	local lastreset = basetime + passedresets * resetdays * 86400

	if not charInfo.CompletedQuestsLastCheck or charInfo.CompletedQuestsLastCheck < lastreset then
		charInfo.CompletedQuests["41888"] = nil
		charInfo.CompletedQuests["41891"] = nil
		charInfo.CompletedQuests["41897"] = nil
		charInfo.CompletedQuests["41890"] = nil
		charInfo.CompletedQuests["41889"] = nil
		charInfo.CompletedQuests["41892"] = nil
	end

end
