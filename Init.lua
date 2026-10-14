Altoholic = {}
Altoholic.vars = {}
Altoholic.vars.version = "v1.4.0"

-- *** Events ***
-- Events are dispatched to the method of the same name, without the event name:
-- BAG_UPDATE fires Altoholic:BAG_UPDATE(bag)
local eventFrame = CreateFrame("Frame")
local registeredEvents = {}

function Altoholic:RegisterEvent(event)
	registeredEvents[event] = true
	eventFrame:RegisterEvent(event)
end

function Altoholic:UnregisterEvent(event)
	registeredEvents[event] = nil
	eventFrame:UnregisterEvent(event)
end

function Altoholic:IsEventRegistered(event)
	return registeredEvents[event]
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
	local handler = Altoholic[event]
	if handler then
		handler(Altoholic, ...)
	end
end)

Altoholic:RegisterEvent("PLAYER_LOGIN")

-- *** Slash commands ***
SLASH_ALTOHOLIC1 = "/altoholic"
SLASH_ALTOHOLIC2 = "/alto"
SlashCmdList["ALTOHOLIC"] = function(msg)
	local L = Altoholic.L
	local command, text = strtrim(msg or ""):match("^(%S*)%s*(.-)$")
	command = command:lower()
	if command == L["search"] and text ~= "" then
		Altoholic:CmdSearchBags(text)
	elseif command == L["show"] then
		AltoholicFrame:Show()
	elseif command == L["hide"] then
		AltoholicFrame:Hide()
	elseif command == L["toggle"] then
		Altoholic:ToggleUI()
	else
		local usage = {
			{ L["search"] .. " <item name>", L["Search in bags"] },
			{ L["show"], L["Shows the UI"] },
			{ L["hide"], L["Hides the UI"] },
			{ L["toggle"], L["Toggles the UI"] },
		}
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700Altoholic " .. Altoholic.vars.version)
		for _, line in ipairs(usage) do
			DEFAULT_CHAT_FRAME:AddMessage("  |cFF00FF00/alto " .. line[1] .. "|r - " .. line[2])
		end
	end
end
