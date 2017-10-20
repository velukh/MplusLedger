local MplusLedger = MplusLedger
local SharedMedia = LibStub("LibSharedMedia-3.0")
local ColorText = LibStub("MplusLedgerColorText-1.0")

local function ShowChatCommands()
  local commands = {
    help = "Show this list of commands.",
    reset = "Force the reset of your currently running dungeon.",
    show = "Show the current dungeon for your M+ Ledger",
    history = "Show the history for your M+ Ledger"
  }

  print(ColorText:Yellow(MplusLedger:Title() .. " v" .. MplusLedger:Version()))
  for command, description in pairs(commands) do
    print("/mplus " .. command .. " - " .. description)
  end
end

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
    ShowChatCommands()
  elseif command == "dev" then
    MplusLedger:DumpCache()
  else
    print(ColorText:Red("You MUST pass something valid to the /mplus command"))
    ShowChatCommands()
  end
end)