-- About, like pfUI's About page: the name drawn in blocks, the version, and what Altoholic
-- needs (ClassicAPI) or can use (pfUI, pfUI-tradeskill, pfQuest...) with whether each is there.
-- The credits are in README.md.
local L = Altoholic.L
local V = Altoholic.vars
local W = Altoholic.W
local UI = Altoholic.UI

-- *** The name in blocks, as pfUI draws its own ***
-- 3 x 5 glyphs, a row per line, # for a block
local GLYPHS = {
	A = { ".#.", "#.#", "###", "#.#", "#.#" },
	L = { "#..", "#..", "#..", "#..", "###" },
	T = { "###", ".#.", ".#.", ".#.", ".#." },
	O = { "###", "#.#", "#.#", "#.#", "###" },
	H = { "#.#", "#.#", "###", "#.#", "#.#" },
	I = { "###", ".#.", ".#.", ".#.", "###" },
	C = { "###", "#..", "#..", "#..", "###" },
}

local function DrawLogo(parent, x, y, pencil)
	local word = "ALTOHOLIC"
	for n = 1, string.len(word) do
		local glyph = GLYPHS[string.sub(word, n, n)]
		local r, g, b = 1, 1, 1
		if n <= 4 then r, g, b = W.TEAL[1], W.TEAL[2], W.TEAL[3] end		-- "Alto" teal, "holic" white
		local left = x + (n - 1) * 4 * pencil
		for row = 1, 5 do
			for col = 1, 3 do
				if string.sub(glyph[row], col, col) == "#" then
					local t = parent:CreateTexture(nil, "OVERLAY")
					t:SetColorTexture(r, g, b, 1)
					t:SetPoint("TOPLEFT", parent, "TOPLEFT", left + (col - 1) * pencil, y - (row - 1) * pencil)
					t:SetWidth(pencil)
					t:SetHeight(pencil)
				end
			end
		end
	end
	return string.len(word) * 4 * pencil - pencil
end

-- *** What the client has ***

local function CountCharacters()
	local chars, realms = 0, 0
	for _, realm in ipairs(UI.Realms()) do
		realms = realms + 1
		chars = chars + #realm.chars
	end
	return chars, realms
end

local INFO = {
	{ L["Version"], function() return V.version end },
	{ L["Characters"], function() local chars, realms = CountCharacters() return format(L["%d on %d realm(s)"], chars, realms) end },
	{ L["Game client"], function() return (GetBuildInfo()) .. " (" .. GetLocale() .. ")" end },
}

-- *** What Altoholic needs, and what it can use (README.md says what each is for) ***
-- kind: a client DLL or an addon. A DLL's status comes from what it defines; an addon's from
-- the client's addon list, which tells a disabled addon from a missing one.
local GREEN, RED, GRAY = "|cff00ff00", "|cffff5555", "|cff888888"

-- An addon's state: its version ("v1.2"), or true when it is loaded but gives no version;
-- else nil and why not ("disabled", "not installed")
local function AddonState(name)
	if IsAddOnLoaded(name) then
		local version = GetAddOnMetadata(name, "Version")
		-- a copy not built for release keeps the packager's placeholder
		if not version or string.find(version, "@", 1, true) then return true end
		return "v" .. string.gsub(version, "^v", "")
	end
	local found, _, _, enabled, _, reason = GetAddOnInfo(name)
	if not found or reason == "MISSING" then return nil, L["not installed"] end
	if not enabled then return nil, L["disabled"] end
	return nil, L["not loaded"]
end

local DEPENDENCIES = {
	{ "ClassicAPI", "DLL", true, function()
		local v = CLASSIC_API_VERSION
		if not v then return nil, L["missing"] end
		return format("v%d.%d.%d", math.floor(v / 10000), math.floor((v % 10000) / 100), v % 100)
	end },
	{ "pfUI", L["AddOn"], false, function()
		if pfUI then
			local v = pfUI.version and pfUI.version.string
			return (v and v ~= "dev") and ("v" .. v) or true
		end
		return AddonState("pfUI")
	end },
	{ "pfUI-tradeskill", L["AddOn"], false, function() return AddonState("pfUI-tradeskill") end },
	{ "pfQuest", L["AddOn"], false, function() return AddonState("pfQuest") end },
	{ "pfQuest-octo-plus", L["AddOn"], false, function() return AddonState("pfQuest-octo-plus") end },
}

-- the Needed cell: the version or Loaded when it is there, else Required or Optional and why not
local function Needed(d)
	local state, why = d[4]()
	if state then return GREEN .. (state == true and L["Loaded"] or state) end
	if d[3] then return RED .. L["Required"] .. " - " .. why end
	return GRAY .. L["Optional"] .. " - " .. why
end

-- *** About: logo, facts, dependencies ***

local view = {}

function view:Create(frame)
	local logoWidth = DrawLogo(frame, 40, -30, 7)
	local tagline = W.Text(frame, W.FontSize() - 1, "CENTER")
	tagline:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -74)
	tagline:SetWidth(logoWidth)
	tagline:SetText(L["Every character's bags, bank, mail, gear, professions and more, in one window"])
	tagline:SetTextColor(.7, .7, .7)

	-- the facts, to the right of the logo as pfUI puts its own
	local x = 40 + logoWidth + 60
	self.info = {}
	for i, line in ipairs(INFO) do
		local y = -32 - (i - 1) * 20
		local caption = W.Text(frame)
		caption:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
		caption:SetText(line[1] .. ":")
		local value = W.Text(frame, nil, "RIGHT")
		value:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
		value:SetWidth(260)
		self.info[i] = value
	end
	local copy = W.Button(frame, L["Copy GitHub link"], 140, 22, function()
		self:Copy("https://github.com/Vaterade/Altoholic")
	end)
	copy:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -32 - #INFO * 20 - 6)
	self.copied = W.Text(frame)
	self.copied:SetPoint("LEFT", copy, "RIGHT", 10, 0)
	self.copied:SetTextColor(W.TEAL[1], W.TEAL[2], W.TEAL[3])

	local header = W.Text(frame, W.FontSize() + 1)
	header:SetPoint("TOPLEFT", frame, "TOPLEFT", 40, -140)
	header:SetText(W.TEAL_HEX .. L["Dependencies"])
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetPoint("TOPLEFT", header, "BOTTOMLEFT", -8, -6)
	holder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 12)
	self.deps = W.Table(holder, {
		{ title = L["Name"], width = 140 },
		{ title = L["Kind"], width = 60 },
		{ title = L["Needed"] },
	}, 20)
end

-- copies a link, or shows it for copying by hand without ClassicAPI's clipboard
function view:Copy(url)
	if CopyToClipboard then
		CopyToClipboard(url)
		self.copied:SetText(L["Copied"])
	else
		self.copied:SetText(url)
	end
end

function view:Update()
	for i, line in ipairs(INFO) do self.info[i]:SetText(line[2]()) end
	self.copied:SetText("")
	local rows = {}
	for _, d in ipairs(DEPENDENCIES) do
		table.insert(rows, { cells = { d[1], "|cffaaaaaa" .. d[2], Needed(d) } })
	end
	self.deps:SetData(rows)
end

UI.RegisterView("About", view)
