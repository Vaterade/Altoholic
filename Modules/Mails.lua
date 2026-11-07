local L = Altoholic.L
local V = Altoholic.vars

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

-- *** Hooks ***
