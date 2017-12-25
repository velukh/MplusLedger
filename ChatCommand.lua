local MplusLedger = MplusLedger
local SharedMedia = LibStub("LibSharedMedia-3.0")
local ColorText = LibStub("MplusLedgerColorText-1.0")
local UiUtils = LibStub("MplusLedgerUiUtils-1.0")
local icon = LibStub("LibDBIcon-1.0", true)
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local function ShowChatCommands()
  local commands = {
    help = "Show this list of commands.",
    reset = "Force the reset of your currently running dungeon.",
    show = "Show the current dungeon for your M+ Ledger",
    button = "(on|off|show|hide) Pass an option to show or hide the minimap button",
    keys = "Show the keystones you ahve for your characters",
    party = "Show in party chat what keys your party members have; party members must have M+ Ledger installed for this to function",
    config = "Show the options for this addon"
  }

  print(ColorText:Yellow(MplusLedger:Title() .. " v" .. MplusLedger:Version()))
  for command, description in pairs(commands) do
    print("/mplus " .. command .. " - " .. description)
  end
end

MplusLedger:RegisterChatCommand("mplus", function(args)
  MplusLedger:ProcessChatCommand(args)
end)