-- Mail: what was in a character's mailbox the last time they opened it, and when each
-- mail runs out.
local L = Altoholic.L
local W = Altoholic.W
local UI = Altoholic.UI

local view = {}

function view:Create(frame, bar)
	local holder = CreateFrame("Frame", nil, frame)
	holder:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
	holder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
	self.list = W.List(holder, 30,
		function(row)
			row.icon = W.ItemButton(row, 26)
			row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
			row.subject = W.Text(row)
			row.subject:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
			row.subject:SetWidth(280)
			row.sender = W.Text(row)
			row.sender:SetPoint("LEFT", row.subject, "RIGHT", 8, 0)
			row.sender:SetWidth(150)
			row.expiry = W.Text(row, nil, "RIGHT")
			row.expiry:SetPoint("LEFT", row.sender, "RIGHT", 8, 0)
			row.expiry:SetPoint("RIGHT", row, "RIGHT", -4, 0)
		end,
		function(row, m)
			row.icon:SetItem(m.link, m.count, m.icon)
			row.icon.onEnter = not m.link and function(btn)
				if not m.text and not m.money then return end
				GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
				if m.money then GameTooltip:AddLine(Altoholic:GetMoneyString(m.money, "|cFFFFFFFF")) end
				if m.text then GameTooltip:AddLine(m.text, 1, 1, 1, true) end
				GameTooltip:Show()
			end or nil
			local hex = "|cFFFFFFFF"
			if m.quality then
				local _, _, _, h = GetItemQualityColor(m.quality)
				hex = h or hex
			end
			row.subject:SetText(hex .. (m.subject or ""))
			row.sender:SetText(m.sender or "")
			local left = Altoholic:GetMailExpiry(m.lastcheck, m.daysleft)
			local color = left < Altoholic.db.account.options.MailWarningThreshold and "|cFFFF0000" or "|cFFFFFFFF"
			row.expiry:SetText(color .. Altoholic:FormatMailExpiry(m.lastcheck, m.daysleft) .. "|r" .. L[" days"])
		end)
	self.message = W.Message(holder)
	self.status = W.Text(bar)
	self.status:SetPoint("LEFT", bar, "LEFT", 4, 0)
	self.status:SetTextColor(.7, .7, .7)
end

function view:Update(ref)
	local c = UI.Char(ref)
	local mail = rawget(c, "mail") or {}
	self.list:SetData(mail, self.ref == ref)
	self.ref = ref
	local who = UI.ClassHex(c.class) .. ref.name .. "|r  "
	if (c.lastmailcheck or 0) == 0 then
		self.message:SetText(ref.name .. L[" has not visited his/her mailbox yet"])
		self.message:Show()
		self.status:SetText(who)
	else
		local checked = L["Mail was last checked "] .. Altoholic:GetDelayInDays(c.lastmailcheck) .. L[" days ago"]
		if #mail == 0 then
			self.message:SetText(ref.name .. L[" has no mail, last check "] .. Altoholic:GetDelayInDays(c.lastmailcheck) .. L[" days ago"])
			self.message:Show()
		else
			self.message:Hide()
		end
		self.status:SetText(who .. checked)
	end
end

UI.RegisterView("Mail", view)
