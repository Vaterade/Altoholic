-- Account-wide saved data, kept in AltoholicDB.account.
--
-- A '*' key in the defaults stands for "any other key": reading a missing entry
-- creates it with those defaults, so data[faction][realm].char[name] can be used
-- without checking each level first. Whatever still equals its default is
-- stripped again at logout, which also drops entries that were only ever read.

--[[	*** Note on reputation ***
the "reputation" table is kept out of the "char" table for practical reasons, as the table will be populated with so many different entries for each alt,
it was much easier to organize things this way to ensure a more efficient parsing when data will be displayed, this also prevents from creating
a large temporary table that would have to be garbage collected later on. Character names will be duplicated in each sub-table, 
but this is a little trade-off I accept.
--]]

local defaults = {
	options = {
		MinimapIconAngle = 268,
		MinimapIconRadius = 78,
		MailWarningThreshold = 5,
		SortDescending = 0, 				-- display search results in the loot table in ascending (0) or descending (1) order ?
		RestXPMode = 0, 					-- display max rest xp in normal 100% mode or in level equivalent 150% mode (1) ?
		ScanMailBody = 0,					-- by default, scan the body of a mail (this action marks it as read)
		TooltipSource = 1,
		TooltipCount = 1,
		TooltipTotal = 1,
		TooltipAlreadyKnown = 0,
        TooltipLearnableBy = 1,
		ShowMinimap = 1,
		TotalLoots = 0,					-- make at least one search in the loot tables to initialize these values
		UnknownLoots = 0
	},
	data = {
		['*'] = {							-- Faction
			['*'] = {						-- Realm
				reputation = {
					['*'] = {				-- "Ironforge"
						['*'] = nil
					}
				},
				guild = {
					['*'] = {				-- guild["MyUberGuild"]
						lastbankvisitby = "",
						lastbankvisittime = 0,
						bankmoney = 0,
						bank = {
							['*'] = {
								tabID = nil,
								name = "",
								ids = { ['*'] = nil },
								links = { ['*'] = nil },
								counts = { ['*'] = nil }
							}
						}
					}
				},
				char = {
					['*'] = {					-- Character Name
						level = 0,
						race = "",
						class = "",
						talent = "",
						bags = "",
						bankslots = "",
						zone = "",				-- in which zone the player went offline
						subzone = "",			-- in which subzone .. 
						xp = 0,					-- current level xp
						xpmax = 0,				-- max xp at current level 
						restxp = 0,
						isResting = true,		-- most players will logout at an inn, so default to true
						money = 0,
						played = 0,				-- 57396 seconds = 0 days 15 hours 56 minutes 36 seconds
						lastlogout = 0,
						lastmailcheck = 0,	-- last time the mail was checked for this char
						lastAHcheck = 0,		-- last time the AH was checked for this char
						pvp_hk = 0,				-- pvp honorable kills
						pvp_dk = 0,				-- pvp dishonorable kills
						pvp_ArenaPoints = 0,
						pvp_HonorPoints = 0,
						skill = {
							['*'] = {			-- "Professions"
								['*'] = nil
							}
						},
						spells = {
                            ['*'] = {
                                name = nil,
                                rank = nil
                            }
						},
						inventory = {},		-- 19 inventory slots, a simple table containing item id's
						SavedInstance = {},	-- raid timers
						ProfessionCooldowns = {},
						questlog = {
							['*'] = {
								name = nil,		-- name: name of the header (usually the location)
								id = nil,			-- the quest ID, missing in logs saved before 1.4.0
								link = nil,		-- the quest link
								isHeader = nil,
								isCollapsed = false,
								tag = nil,			-- quest tag=  "Elite", "Dungeon", "PVP", "Raid", "Group", "Heroic" or nil
								groupsize = nil,
								money = nil,
								isComplete = nil
							}
						},
						recipes = {
							['*'] = {
								ScanFailed = true,	-- by default, consider that scanning this profession was not valid
								list = {
									['*'] = {
										id = nil,
										name = nil,
										link = nil,
										isHeader = nil,
										isCollapsed = false,
										reagents = nil,	-- itemID : count | itemID : count .. etc
									}
								}
							}
						},
						auctions = {
							['*'] = {
								id = nil,
								count = 1,
								AHLocation = nil,		-- nil = faction AH, 1 = goblin AH
								highBidder = nil,
								startPrice = nil,
								buyoutPrice = nil,
								timeLeft = nil
							}
						},
						bids = {
							['*'] = {
								id = nil,
								count = 1,
								AHLocation = nil,		-- nil = faction AH, 1 = goblin AH
								owner = nil,
								bidPrice = nil,
								buyoutPrice = nil,
								timeLeft = nil
							}
						},
						mail = {
							['*'] = {
								icon = nil,
								link = nil,
								count = 0,
								money = 0,
								lastcheck = 0,		-- last time "THIS" mail was checked (can be different than that of the mailbox)
								text = "",
								subject = "",
								sender = "",
								daysleft = 0,
								realm = ""
							}
						},
						bag = {
							['*'] = {					-- bag["Bag0"]
								icon = nil,				-- bag's texture
								link = nil,				-- bag's itemlink
								size = 0,
								freeslots = 0,
								bagtype = 0,
								ids = { ['*'] = nil },
								links = { ['*'] = nil },
								counts = { ['*'] = nil }
							}
						}
					}
				}
			}
		}
	}
}

local function inheritDefaults(t, defaults)
	local wildcard = defaults["*"]
	for k, v in pairs(defaults) do
		if k ~= "*" then
			if type(v) == "table" then
				if type(t[k]) ~= "table" then
					t[k] = {}
				end
				inheritDefaults(t[k], v)
			elseif t[k] == nil then
				t[k] = v
			end
		end
	end
	if wildcard then
		for k, v in pairs(t) do
			if defaults[k] == nil and type(v) == "table" then
				inheritDefaults(v, wildcard)
			end
		end
		setmetatable(t, {
			__index = function(self, key)
				if key == nil then return nil end
				local entry = inheritDefaults({}, wildcard)
				rawset(self, key, entry)
				return entry
			end
		})
	end
	return t
end

-- returns true when nothing but defaults was left in t
local function cleanDefaults(t, defaults)
	local wildcard = defaults["*"]
	for k, v in pairs(t) do
		local default = defaults[k]
		if k == "*" or default == nil then
			default = wildcard
		end
		if type(v) == "table" then
			if type(default) == "table" and cleanDefaults(v, default) then
				t[k] = nil
			end
		elseif v == default then
			t[k] = nil
		end
	end
	return next(t) == nil
end

-- Mail sent to an alt of the other faction used to be filed under the sender's faction,
-- leaving a record there with mail but no class or level. Hand the mail that is still
-- pending to the real character and drop the record.
-- Runs on the stored data, before the defaults are applied: a missing field is a default.
local function mergeMisfiledCharacters(data)
	if type(data) ~= "table" then return end
	for faction, realms in pairs(data) do
		for realm, r in pairs(realms) do
			for name, c in pairs(type(r.char) == "table" and r.char or {}) do
				if not c.class or c.class == "" then
					for otherFaction, otherRealms in pairs(data) do
						local other = otherRealms[realm]
						local real = otherFaction ~= faction and other and other.char and other.char[name]
						if real and real.class and real.class ~= "" then
							for _, m in ipairs(c.mail or {}) do
								-- anything older was already there when the mailbox was last scanned
								if (m.lastcheck or 0) > (real.lastmailcheck or 0) then
									real.mail = real.mail or {}
									table.insert(real.mail, m)
								end
							end
							break
						end
					end
					r.char[name] = nil
				end
			end
		end
	end
end

-- The auto-query option and the list of items it had asked the server about are gone;
-- without a default they would never be stripped from the stored data again.
local function dropAutoQueryData(account)
	if type(account.options) == "table" then
		account.options.SearchAutoQuery = nil
	end
	if type(account.data) ~= "table" then return end
	for faction, realms in pairs(account.data) do
		for realm, r in pairs(realms) do
			r.unsafeItems = nil
		end
	end
end

function Altoholic:InitDatabase()
	if type(AltoholicDB) ~= "table" then
		AltoholicDB = {}
	end
	if type(AltoholicDB.account) ~= "table" then
		AltoholicDB.account = {}
	end
	mergeMisfiledCharacters(AltoholicDB.account.data)
	dropAutoQueryData(AltoholicDB.account)
	self.db = { account = inheritDefaults(AltoholicDB.account, defaults) }
end

function Altoholic:CleanDatabase()
	if cleanDefaults(AltoholicDB.account, defaults) then
		AltoholicDB.account = nil
	end
end
