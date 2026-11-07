-- Account Summary > Attunements: which of a realm's characters have done the quests that
-- open dungeons and raids, this week's weeklies, and the boss trophies. Completed quests
-- come from Turtle's .queststatus (see Data/Scan.lua).
local UI = Altoholic.UI

local WHITE, TEAL = "|cFFFFFFFF", "|cFF00FF9A"

-- id: the quest, or several where any one counts ("a|b"); 0 starts a group
local ATTUNEMENTS = {
	{ id = "0", name = "Dungeons" },
	{ id = "7046", name = "Maraudon Princess", item = "The Scepter of Celebras" },
	{ id = "5505", name = "Scholomance", item = "The Key to Scholomance" },
	{ id = "40316|40309", name = "Karazan Crypt", item = "Karazan Crypt Key" },
	{ id = "0", name = "Weeklies" },
	{ id = "41888|41891", name = "Small raids" },
	{ id = "41897|41890", name = "Dungeons" },
	{ id = "41889|41892", name = "Molten Core" },
	{ id = "0", name = "Raids" },
	{ id = "4743", name = "Upper BRS", item = "Seal of Ascension" },
	{ id = "7848", name = "Molten Core" },
	{ id = "6502", name = "Onyxia's Lair", item = "Drakefire Amulet" },
	{ id = "7761", name = "Blackwing Lair" },
	{ id = "40962", name = "Emerald Sanctum", item = "Gemstone of Ysera" },
	{ id = "9378", name = "Naxxramas" },
	{ id = "40829", name = "Upper Karazan", item = "Upper Karazan Tower Key" },
	{ id = "0", name = "Boss organ turn ins" },
	{ id = "7496|7491", name = "Onyxia's Head" },
	{ id = "8183", name = "The Heart of Hakkar" },
	{ id = "8791", name = "The Head of Ossirian" },
	{ id = "7781|7783", name = "Head of Nefarian" },
	{ id = "8802", name = "Eye of C'thun" },
	{ id = "40963", name = "Head of Solnius" },
	{ id = "41038", name = "The Claw of Erennius" },
}

local function Done(c, ids)
	local done = rawget(c, "CompletedQuests")
	if not done then return false end
	for id in string.gmatch(ids, "[^|]+") do
		if done[id] then return true end
	end
	return false
end

local view = {}

function view:Create(frame, bar)
	self.grid = UI.CharacterGrid(frame, 180)
	self.realm = UI.RealmPicker(bar, function() self:Update() end)
end

function view:Update()
	local realm = self.realm:Current()
	if not realm then self.grid:SetData({}, {}) return end
	for _, ref in ipairs(realm.chars) do Altoholic:ResetWeeklyQuestsIfExpired(ref.c) end
	local lines = {}
	for _, a in ipairs(ATTUNEMENTS) do
		if a.id == "0" then
			table.insert(lines, { header = a.name })
		else
			table.insert(lines, {
				label = a.name,
				cell = function(ref)
					if Done(ref.c, a.id) then return "ok", 0, 1, 0 end
					return "-", .4, .4, .4
				end,
				onEnter = function(btn, ref)
					GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
					GameTooltip:AddLine(UI.ClassHex(ref.c.class) .. ref.name .. WHITE .. " @ " .. ref.realm)
					if Done(ref.c, a.id) then
						GameTooltip:AddLine("completed this quest (id " .. a.id .. ")", 1, 1, 1)
					else
						GameTooltip:AddLine("not completed (quest id " .. a.id .. ")", .6, .6, .6)
					end
					GameTooltip:AddLine(a.item and (TEAL .. a.item) or "No item needed", 1, 1, 1)
					GameTooltip:Show()
				end,
			})
		end
	end
	self.grid:SetData(realm.chars, lines, true)
end

UI.RegisterView("Attunements", view)
