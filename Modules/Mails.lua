local L = Altoholic.L
local V = Altoholic.vars
local GREEN		= "|cFF00FF00"

function Altoholic:Mail_Update()
	local c = self.db.account.data[V.CurrentFaction][V.CurrentRealm].char[V.CurrentAlt]
	local VisibleLines = 7
	local frame = "AltoMail"
	local entry = frame.."Entry"
	if #c.mail == 0 then
		if c.lastmailcheck == 0 then
			_G["AltoholicFrame_Status"]:SetText("|cFFFFD700" .. V.CurrentAlt .. " of ".. V.CurrentRealm .. " |cFFFFFFFF" .. L[" has not visited his/her mailbox yet"])
		else
			_G["AltoholicFrame_Status"]:SetText("|cFFFFD700" .. V.CurrentAlt .. " of ".. V.CurrentRealm .. " |cFFFFFFFF" .. L[" has no mail, last check "] .. self:GetDelayInDays(c.lastmailcheck).. L[" days ago"])
		end
		_G["AltoholicFrame_Status"]:Show()
		
		self:ClearScrollFrame(_G[frame.."ScrollFrame"], entry, VisibleLines, 41)
		return
	else
		_G["AltoholicFrame_Status"]:SetText("|cFFFFD700" .. V.CurrentAlt .. " of ".. V.CurrentRealm .. " |cFFFFFFFF" .. L["Mailbox"])
		_G["AltoholicFrame_Status"]:Show()
	end
	local offset = FauxScrollFrame_GetOffset(_G[frame.."ScrollFrame"]);
	for i=1, VisibleLines do
		local line = i + offset
		if line <= #c.mail then
			local s = c.mail[line]
			_G[entry..i.."Name"]:SetText(s.subject)
			_G[entry..i.."Character"]:SetText(s.sender)
			_G[entry..i.."Expiry"]:SetText(self:FormatMailExpiry(s.lastcheck, s.daysleft) .. L[" days"])
			_G[entry..i.."ItemIconTexture"]:SetTexture(s.icon);
			if (s.count ~= nil) and (s.count > 1) then
				_G[entry..i.."ItemCount"]:SetText(s.count)
				_G[entry..i.."ItemCount"]:Show()
			else
				_G[entry..i.."ItemCount"]:Hide()
			end
			_G[entry..i.."Item"]:SetID(line)
			_G[entry..i]:Show()
		else
			_G[entry..i]:Hide()
		end
	end
	_G["AltoholicFrame_Status"]:SetText(L["Mail was last checked "] .. self:GetDelayInDays(c.lastmailcheck).. L[" days ago"])
	_G["AltoholicFrame_Status"]:Show()
	if #c.mail < VisibleLines then
		FauxScrollFrame_Update(_G[frame.."ScrollFrame"], VisibleLines, VisibleLines, 41);
	else
		FauxScrollFrame_Update(_G[frame.."ScrollFrame"], #c.mail, VisibleLines, 41);
	end
end

function Altoholic:FormatMailExpiry(lastcheck, mailexpiry)
	if (lastcheck == nil) or (lastcheck == 0) then
		return GREEN .. string.format("%.2f", mailexpiry)
	end
	local expiry = self:GetMailExpiry(lastcheck, mailexpiry)
	if expiry > 10 then
		return GREEN .. string.format("%.2f", expiry)
	elseif expiry > 5 then
		return "|cFFFFFF00" .. string.format("%.2f", expiry)
	end
	return "|cFFFF0000" .. string.format("%.2f", expiry)
end

function Altoholic:GetMailExpiry(lastcheck, mailexpiry)
	return mailexpiry - ((time() - lastcheck) / 86400)
end

function Altoholic:CheckExpiredMail()
	local O = self.db.account.options
	for FactionName, f in pairs(self.db.account.data) do
		for RealmName, r in pairs(f) do
			for CharacterName, c in pairs(r.char) do
				for k, v in pairs(c.mail) do
					if self:GetMailExpiry(v.lastcheck, v.daysleft) < O.MailWarningThreshold then
						V.ExpiredMail = true
						return
					end
				end
			end
		end
	end
end

function Altoholic:UpdatePlayerMail()
	local c = self.db.account.data[V.faction][V.realm].char[V.player]
	local numItems = GetInboxNumItems();
    c.mail = {}
	if numItems == 0 then
		return
	end
	for i = 1, numItems do
        local packageIcon , stationeryIcon, mailSender, mailSubject, mailMoney, _, daysLeft = GetInboxHeaderInfo(i);
    	local name, mailIcon, itemCount, quality, canUse = GetInboxItem(i)
		if name ~= nil then
			table.insert(c.mail, {
                icon = packageIcon,
                -- what the item counts and the search go by
                link = GetInboxItemLink(i),
                count = itemCount,
                subject = name,
                sender = mailSender,
                quality = quality,
                lastcheck = time(),
                daysleft = daysLeft
			} )
		end
        if AltoOptions_ScanMailBody:GetChecked() then
            local inboxText = GetInboxText(i)
            if inboxText then
                if IsAddOnLoaded("GMail") and string.find(inboxText, GMAIL_ITEMNUM) then
                    inboxText = false
                else
                    inboxText = inboxText
                end
            end
        end
        local gold, silver, copper, mSent
		if (mailMoney > 0) or inboxText then
			if mailMoney > 0 then
                copper = tostring(mailMoney)
                silver = tostring(mailMoney / 100)
                gold = tostring((mailMoney - (mailMoney % COPPER_PER_SILVER)) / 10000)
                if mailMoney < 100 then
                    mailIcon = "Interface\\Icons\\INV_Misc_Coin_05"
                    mSent = copper .. " Copper"
                elseif mailMoney < 10000 then
                    mailIcon = "Interface\\Icons\\INV_Misc_Coin_03"
                    mSent = silver .. " Silver"
                elseif mailMoney >= 10000 then
                    mailIcon = "Interface\\Icons\\INV_Misc_Coin_01"
                    mSent = gold .. " Gold"
                else
                    mailIcon = "Interface\\Icons\\INV_Misc_Note_01"
                end
                table.insert(c.mail, {
                    icon = mailIcon,
                    money = mailMoney,
                    text = inboxText,
                    subject = mSent,
                    sender = mailSender,
                    lastcheck = time(),
                    daysleft = daysLeft
                } )
            end
        end
    end
	table.sort(c.mail, function(a, b)
		return a.daysleft < b.daysleft
	end)
end

-- *** Hooks ***
-- the record of one of this account's characters on this realm, whichever faction it is in
local function FindRecipient(name)
    for _, f in pairs(Altoholic.db.account.data) do
        -- rawget: a plain lookup would create the realm or the character
        local r = rawget(f, V.realm)
        local c = r and rawget(r.char, name)
        if c and c.class ~= "" then
            return c
        end
    end
end

-- this has to run before the mail leaves: the attachments and the money are gone afterwards,
-- so a post-hook (hooksecurefunc) is no use here
local Orig_SendMail = SendMail
function SendMail(recipient, ...)
    local c = FindRecipient(recipient)
    if c then
        for k, v in pairs(V.Attachments) do
            table.insert(c.mail, {
                icon = v.icon,
                link = v.link,
                subject = v.subject,
                count = v.count,
                sender = V.player,
                lastcheck = time(),
                daysleft = 30,
                realm = V.realm
            } )
        end
        local moneySent = GetSendMailMoney()
        local gold, silver, copper, mSent, altText, mailIcon
        if (moneySent > 0) then
            copper = tostring(moneySent)
            silver = tostring(moneySent / 100)
            gold = tostring((moneySent - (moneySent % COPPER_PER_SILVER)) / 10000)
            if moneySent < 100 then
                mailIcon = "Interface\\Icons\\INV_Misc_Coin_05"
                mSent = copper .. " Copper"
            elseif moneySent < 10000 then
                mailIcon = "Interface\\Icons\\INV_Misc_Coin_03"
                mSent = silver .. " Silver"
            elseif moneySent >= 10000 then
                mailIcon = "Interface\\Icons\\INV_Misc_Coin_01"
                mSent = gold .. " Gold"
            else
                mailIcon = "Interface\\Icons\\INV_Misc_Note_01"
            end
            table.insert(c.mail, {
                money = moneySent,
                icon = mailIcon,
                subject = mSent,
                sender = V.player,
                lastcheck = time(),
                daysleft = 30,
                realm = V.realm
            } )
        end
        if (c.lastmailcheck == nil) or (c.lastmailcheck == 0) then
            c.lastmailcheck = time()
        end
        table.sort(c.mail, function(a, b)
            return a.daysleft < b.daysleft
        end)
    end
    V.Attachments = {}
    return Orig_SendMail(recipient, ...)
end

-- *** EVENT HANDLERS ***
function Altoholic:MAIL_SHOW()
	CheckInbox()
	self:RegisterEvent("MAIL_INBOX_UPDATE")
	self:RegisterEvent("MAIL_SEND_INFO_UPDATE")
	V.Attachments = {}
	V.AllowMailUpdate = true
	V.isMailBoxOpen = true
    self:UpdatePlayerMail()
end

function Altoholic:MAIL_CLOSED()
	V.isMailBoxOpen = nil
	if V.mailclose == nil then
		V.mailclose = 1
		self:UpdatePlayerMail()
		self.db.account.data[V.faction][V.realm].char[V.player].lastmailcheck = time()
		self:BuildMailSubMenu()
		self:UpdatePlayerBags()
		self:UnregisterEvent("MAIL_INBOX_UPDATE");
		self:UnregisterEvent("MAIL_SEND_INFO_UPDATE");
	else
		V.mailclose = nil
	end
	V.Attachments = nil
end

function Altoholic:MAIL_INBOX_UPDATE()
	if V.AllowMailUpdate then
		self:UpdatePlayerMail()
		V.AllowMailUpdate = false
	end
end

function Altoholic:MAIL_SEND_INFO_UPDATE()
    V.Attachments = {}
	local itemName, itemIcon, itemCount = GetSendMailItem()
	if itemName then
		table.insert(V.Attachments, {
            subject = itemName,
			link = GetSendMailItemLink(),
			icon = itemIcon,
			count = itemCount
        } )
	end
end
