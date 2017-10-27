local MplusLedger = MplusLedger
local SharedMedia = LibStub("LibSharedMedia-3.0")
local ColorText = LibStub("MplusLedgerColorText-1.0")
local icon = LibStub("LibDBIcon-1.0", true)

local function ShowChatCommands()
  local commands = {
    help = "Show this list of commands.",
    reset = "Force the reset of your currently running dungeon.",
    show = "Show the current dungeon for your M+ Ledger",
    keys = "Show the keystones you have for your characters",
    history = "Show the history for your M+ Ledger",
    button = "(on|off|show|hide) Pass an option to show or hide the minimap button"
  }

  print(ColorText:Yellow(MplusLedger:Title() .. " v" .. MplusLedger:Version()))
  for command, description in pairs(commands) do
    print("/mplus " .. command .. " - " .. description)
  end
end

MplusLedger:RegisterChatCommand("mplus", function(args)
  local command, commandArg1 = MplusLedger:GetArgs(args, 2)
  if command == "show" then
    MplusLedger:ToggleFrame()
  elseif command == "history" or command == "keys" then
    MplusLedger:ToggleFrame(command)
  elseif command == "reset" then
    if MplusLedger:IsRunningMythicPlus() then
      MplusLedger:EndMythicPlusAsFailed("Dungeon was intentionally reset using the /mplus reset command")
    end
  elseif command == "button" then
    print(commandArg1)
    if commandArg1 == "on" or commandArg1 == "show" then
      icon:Show("MplusLedger")
    elseif commandArg1 == "off" or commandArg1 == "hide" then
      icon:Hide("MplusLedger")
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