local MplusLedger = MplusLedger
local SharedMedia = LibStub("LibSharedMedia-3.0")

MplusLedger:RegisterChatCommand("mplus", function(args)
	local command = MplusLedger:GetArgs(args)
	if command == "show" then
		MplusLedger:ToggleFrame()
  elseif command == "history" then
    MplusLedger:ToggleFrame("history")
	elseif command == "reset" then
		if MplusLedger:IsRunningMythicPlus() then
			MplusLedger:EndMythicPlusAsFailed("Dungeon was intentionally reset using the /mplus reset command")
		end
	elseif command == "help" then
		MplusLedger:ShowChatCommands()
	elseif command == "dev" then
		for dungeonIndex, dungeon in ipairs(MplusLedger.db.char.finishedMythicRuns) do
      for partyIndex, partyMember in ipairs(dungeon.party) do
        local classToken = string.upper(partyMember.class)
        classToken = string.gsub(classToken, " ", "")
        MplusLedger.db.char.finishedMythicRuns[dungeonIndex].party[partyIndex].classToken = classToken
      end
    end
	else
		print("You MUST pass something valid to the /mplus command.")
		MplusLedger:ShowChatCommands()
	end
end)
