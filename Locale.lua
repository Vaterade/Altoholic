-- Localised strings: Altoholic.L["English text"] returns the translation for the
-- client's locale, the enUS text when there is none, and the key itself for a
-- string that was never registered.
local strings = {}
local clientLocale = GetLocale()

Altoholic.L = setmetatable({}, {
	__index = function(self, key)
		return strings[key] or key
	end
})

-- loader is a function returning the translation table, a value of true means
-- "same as the key". Only enUS and the client's own locale are ever built.
function Altoholic:RegisterTranslations(locale, loader)
	if locale ~= "enUS" and locale ~= clientLocale then return end
	for key, text in pairs(loader()) do
		strings[key] = (text == true) and key or text
	end
end
