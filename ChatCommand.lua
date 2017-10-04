local MplusLedger = MplusLedger

MplusLedger:RegisterChatCommand("mplus", function(args)
	local command = MplusLedger:GetArgs(args)
	if command == "show" then
		MplusLedger:ToggleFrame()
	elseif command == "reset" then
		if MplusLedger:IsRunningMythicPlus() then
			MplusLedger:EndMythicPlusAsFailed("Dungeon was intentionally reset using the /mplus reset command")
		end
	elseif command == "help" then
		MplusLedger:ShowChatCommands()
	else
		print("You MUST pass something to the /mplus command.")
		MplusLedger:ShowChatCommands()
	end
end)
