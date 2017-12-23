local MplusLedger = MplusLedger
local ColorText = LibStub("MplusLedgerColorText-1.0")

MplusLedger:RegisterEvent(MplusLedger.Wow.Events.ChallengeModeStarted, function(_, dungeonId)
  -- it is possible for this even to fire while the mythic+ is ongoing if the player 
  -- logs out and back... silently handle this scenario and do not replay init
  if not MplusLedger:IsRunningMythicPlus() then
    MplusLedger:StartMythicPlus(C_ChallengeMode.GetActiveChallengeMapID())
  end
end)

MplusLedger:RegisterEvent(MplusLedger.Wow.Events.ChallengeModeCompleted, function()
  MplusLedger:EndMythicPlusAsCompleted()
  MplusLedger:StoreKeystoneFromBags()
end)

MplusLedger:RegisterEvent(MplusLedger.Wow.Events.PlayerEnteringWorld, function()
  MplusLedger:StoreKeystoneFromBags()
end)

MplusLedger:RegisterEvent(MplusLedger.Wow.Events.GroupRosterUpdate, function()
  print('calling this correctly')
  MplusLedger:SendPartyYourKeystone()
end)

MplusLedger:RegisterMessage(MplusLedger.Events.TrackingStopped, function(_, dungeon)
  local stateMsg
  if dungeon.state == "failed" then
    stateMsg = "failed"
  else
    stateMsg = "successful"
  end
  print(ColorText:Yellow(MplusLedger:Title()) .. ": Stored your " .. stateMsg .. " M+!")
end)

MplusLedger:RegisterMessage(MplusLedger.Events.TrackingStarted, function(_, dungeon)
  local name = C_ChallengeMode.GetMapInfo(dungeon.challengeMapId)
  print(ColorText:Yellow(MplusLedger:Title()) .. ": Tracking your " .. name .. " +" .. dungeon.mythicLevel)
end)

MplusLedger:RegisterComm("MplusLedger", function(_, message)
  print(message)
end)