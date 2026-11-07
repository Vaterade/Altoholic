-- Notes left for a character, shown when they next log in. Kept by realm, not by faction:
-- this server lets the factions mail each other, so an Alliance character can leave work for
-- a Horde one.
--   AltoholicDB.account.notes[realm][character] = { { text, from, time }, ... }
-- The notes table has no defaults, so reading it never creates anything and the logout
-- cleanup leaves it alone.
local V = Altoholic.vars

local MAX_LENGTH = 255

local function Notes(create, realm, name)
	local account = Altoholic.db.account
	local all = rawget(account, "notes")
	if not all then
		if not create then return end
		all = {}
		account.notes = all
	end
	local r = all[realm]
	if not r then
		if not create then return end
		r = {}
		all[realm] = r
	end
	local list = r[name]
	if not list and create then
		list = {}
		r[name] = list
	end
	return list
end

-- a character's notes, oldest first (an empty list when there are none)
function Altoholic:GetNotes(realm, name)
	return Notes(false, realm, name) or {}
end

function Altoholic:NoteCount(realm, name)
	return #self:GetNotes(realm, name)
end

-- leaves a note for a character; returns the note, or nil when the text is empty
function Altoholic:AddNote(realm, name, text)
	text = strtrim(text or "")
	if text == "" then return end
	if string.len(text) > MAX_LENGTH then text = string.sub(text, 1, MAX_LENGTH) end
	local note = { text = text, from = V.player, time = time() }
	table.insert(Notes(true, realm, name), note)
	self:DataChanged("notes")
	return note
end

-- removes one note; the character's list and the realm go too once they are empty
function Altoholic:RemoveNote(realm, name, note)
	local list = Notes(false, realm, name)
	if not list then return end
	for i = #list, 1, -1 do
		if list[i] == note then table.remove(list, i) end
	end
	if #list == 0 then
		local all = self.db.account.notes
		all[realm][name] = nil
		if next(all[realm]) == nil then all[realm] = nil end
	end
	self:DataChanged("notes")
end

-- Every character name the realm knows, for checking a name typed in /alto note. Both
-- factions; case as saved.
function Altoholic:FindCharacter(realm, typed)
	typed = strlower(typed or "")
	for _, f in pairs(self.db.account.data) do
		local r = rawget(f, realm)
		for name in pairs(r and rawget(r, "char") or {}) do
			if strlower(name) == typed then return name end
		end
	end
end
