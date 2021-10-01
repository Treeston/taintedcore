local UnitName, C_ChatInfo, pairs, print, next, GetNumGroupMembers, GetRaidRosterInfo, IsInRaid, IsInInstance =
      UnitName, C_ChatInfo, pairs, print, next, GetNumGroupMembers, GetRaidRosterInfo, IsInRaid, IsInInstance
local RaidNotice_AddMessage, RaidWarningFrame, ChatTypeInfo, PlaySoundFile, SendChatMessage =
      RaidNotice_AddMessage, RaidWarningFrame, ChatTypeInfo, PlaySoundFile, SendChatMessage
local tinsert, tsort, tconcat = table.insert, table.sort, table.concat

local ITEM_LINK = "|Hitem:31088:"
local SPELL_ID = 38134

local f = CreateFrame("Frame")
local guids = {}
local checks
f:SetScript("OnEvent", function(_,e,arg1,arg2,arg3,arg4,arg5)
    if e == "UNIT_SPELLCAST_SENT" then
        if arg1 == "player" and arg4 == SPELL_ID then
            guids[arg3] = arg2
        end
    elseif e == "UNIT_SPELLCAST_SUCCEEDED" then
        if arg1 == "player" then
            local target = guids[arg2]
            if target then
                if IsInInstance() then
                    SendChatMessage(("Tainted Core to: --> %s <--"):format(target), "YELL")
                end
                SendChatMessage("Tainted Core to you!!", "WHISPER", nil, target)
                guids[arg2] = nil
            end
        end
    elseif e == "CHAT_MSG_ADDON" then
        if arg1 == "TaintedCore" then
            if arg2 == "req" then
                C_ChatInfo.SendAddonMessage("TaintedCore", "ok", "WHISPER", arg4)
            elseif arg2 == "ok" then
                checks[(("-"):split(arg4))] = nil
                if not next(checks) then f.timer = 0 end
            end
        end
    elseif e == "CHAT_MSG_LOOT" then
        if arg1:find(ITEM_LINK) and arg5 == (UnitName("player")) then
            if IsInInstance() then
                SendChatMessage("<< I have the core! >>", "YELL")
            end
            RaidNotice_AddMessage(RaidWarningFrame, arg1, ChatTypeInfo.BN_WHISPER)
            PlaySoundFile(558116, "Master")
        end
    end
end)
f:SetScript("OnUpdate", function(s,e)
    if e >= s.timer then
        s:Hide()
        local names = {}
        for name in pairs(checks) do tinsert(names, name) end
        tsort(names)
        local nMissing = #names
        local nTotal = s.total
        print(("TaintedCore: Check done - %d/%d installed."):format(nTotal-nMissing, nTotal))
        if nMissing > 0 then
            print(("- Not installed: %s"):format(tconcat(names,", ")))
        end
    else
        s.timer = s.timer - e
    end
end)
f:Hide()
f:RegisterEvent("UNIT_SPELLCAST_SENT")
f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("CHAT_MSG_LOOT")
C_ChatInfo.RegisterAddonMessagePrefix("TaintedCore")

SlashCmdList.TAINTEDCORE = function(msg)
    if msg:lower() == "check" then
        f.timer = 5
        checks = {}
        local n = GetNumGroupMembers()
        if n > 0 then
            f.total = n
            for i=1,n do
                checks[(GetRaidRosterInfo(i))] = true
            end
            C_ChatInfo.SendAddonMessage("TaintedCore", "req", IsInRaid() and "RAID" or "PARTY")
        else
            f.total = 1
            local n = UnitName("player")
            checks[n] = true
            C_ChatInfo.SendAddonMessage("TaintedCore", "req", "WHISPER", n)
        end
        f:Show()
        print(("TaintedCore: Running addon check on %d members..."):format(f.total))
    end
end
_G.SLASH_TAINTEDCORE1 = "/taintedcore"
