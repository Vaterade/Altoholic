-- Account Summary > Reputations: a realm's characters side by side, a line per faction,
-- each cell the progress through the current standing, coloured by the standing.
-- Shift-click a cell to link it into chat.
local L = Altoholic.L
local UI = Altoholic.UI

local WHITE, TEAL, YELLOW, GREEN = "|cFFFFFFFF", "|cFF00FF9A", "|cFFFFFF00", "|cFF00FF00"

-- the colour of each standing, by the reputation it starts at
local COLORS = {
	[-42000] = { .8, .13, .13 }, [-6000] = { 1, 0, 0 }, [-3000] = { .93, .4, .13 }, [0] = { 1, 1, 0 },
	[3000] = { 0, 1, 0 }, [9000] = { 0, 1, .53 }, [21000] = { 0, 1, .8 }, [42000] = { 0, 1, 1 },
}

local view = {}

function view:Create(frame, bar)
	self.grid = UI.CharacterGrid(frame, 180)
	self.realm = UI.RealmPicker(bar, function() self:Update() end)
end

-- a character's standing with a faction, as stored: "bottom|top|earned"
local function Standing(ref, faction)
	local reps = rawget(Altoholic.db.account.data[ref.faction][ref.realm], "reputation") or {}
	local r = rawget(reps, faction)
	return r and r[ref.name]
end

local function Describe(ref, faction)
	local bottom, top, earned, rate = Altoholic:GetReputationInfo(Standing(ref, faction))
	return bottom, top, earned, rate, Altoholic:GetRepLevelString(bottom)
end

function view:Update()
	local realm = self.realm:Current()
	if not realm then self.grid:SetData({}, {}) return end
	local lines, group = {}, nil
	for _, f in ipairs(Altoholic.FactionsRefTable or {}) do
		if type(f) == "table" then
			group = f[1]
		else
			local known
			for _, ref in ipairs(realm.chars) do
				if Standing(ref, f) then known = true break end
			end
			if known then
				if group then
					table.insert(lines, { header = group })
					group = nil
				end
				table.insert(lines, {
					label = f,
					cell = function(ref)
						if not Standing(ref, f) then return "" end
						local bottom, _, _, rate = Altoholic:GetReputationInfo(Standing(ref, f))
						local c = COLORS[bottom] or { 1, 1, 1 }
						return format("%d%%", floor(rate)), c[1], c[2], c[3]
					end,
					onEnter = function(btn, ref)
						if not Standing(ref, f) then return end
						local bottom, top, earned, rate, level = Describe(ref, f)
						GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
						GameTooltip:AddLine(UI.ClassHex(ref.c.class) .. ref.name .. WHITE .. " @ " .. TEAL .. f)
						GameTooltip:AddLine(level .. ": " .. (earned - bottom) .. "/" .. (top - bottom) .. YELLOW .. " (" .. format("%d", floor(rate)) .. "%)", 1, 1, 1)
						local suggestion = Altoholic:GetSuggestion(f, bottom)
						if suggestion then
							GameTooltip:AddLine(" ")
							GameTooltip:AddLine(L["Suggestion"] .. ":", 1, 1, 1)
							GameTooltip:AddLine(TEAL .. suggestion, 1, 1, 1, true)
						end
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine(GREEN .. L["Shift-Click to link this info"])
						GameTooltip:Show()
					end,
					onClick = function(_, ref, button)
						if button ~= "LeftButton" or not IsShiftKeyDown() or not Standing(ref, f) then return end
						local bottom, top, earned, _, level = Describe(ref, f)
						local text = ref.name .. L[" is "] .. level .. L[" with "] .. f .. " (" .. (earned - bottom) .. "/" .. (top - bottom) .. ")"
						if ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
							ChatFrameEditBox:Insert(text)
						elseif WIM_EditBoxInFocus then
							WIM_EditBoxInFocus:Insert(text)
						end
					end,
				})
			end
		end
	end
	self.grid:SetData(realm.chars, lines, true)
end

UI.RegisterView("Reputations", view)
