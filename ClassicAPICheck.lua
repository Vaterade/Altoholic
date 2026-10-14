-- ClassicAPI dependency gate.
--
-- ClassicAPI redirects the read of Altoholic.toc to Altoholic_ClassicAPI.toc, so the
-- plain Altoholic.toc is only ever reached when the DLL is missing. That TOC loads
-- nothing but this file, which is why it must stay valid Lua 5.0 (no #, %, or
-- string methods).
local MIN_VERSION = 11510		-- X*10000 + Y*100 + Z for vX.Y.Z
local URL = "https://github.com/brues-code/ClassicAPI/releases/latest"

local message
if not CLASSIC_API_VERSION then
	message = "Altoholic is disabled: the ClassicAPI DLL isn't loaded."
elseif CLASSIC_API_VERSION < MIN_VERSION then
	message = string.format("Altoholic needs ClassicAPI v%d.%d.%d or newer, any errors alongside this one are the APIs it is missing.",
		math.floor(MIN_VERSION / 10000),
		math.floor(math.mod(MIN_VERSION, 10000) / 100),
		math.mod(MIN_VERSION, 100))
end

if message then
	local frame = CreateFrame("Frame")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:SetScript("OnEvent", function()
		frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
		DEFAULT_CHAT_FRAME:AddMessage(message .. " " .. URL, 1, 0.3, 0.3)
		StaticPopupDialogs["ALTOHOLIC_CLASSICAPI_REQUIRED"] = {
			text = message .. "\n\n" .. URL,
			button1 = OKAY,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
		}
		StaticPopup_Show("ALTOHOLIC_CLASSICAPI_REQUIRED")
	end)
end
