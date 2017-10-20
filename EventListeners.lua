local MplusLedger = MplusLedger
local ColorText = LibStub("MplusLedgerColorText-1.0")

MplusLedger:RegisterEvent("CHALLENGE_MODE_START", function(_, dungeonId)
  -- it is possible for this even to fire while the mythic+ is ongoing if the player 
  -- logs out and back... silently handle this scenario and do not replay init
  if not MplusLedger:IsRunningMythicPlus() then
    MplusLedger:StartMythicPlus(C_ChallengeMode.GetActiveChallengeMapID())
  end
end)

-- Marks the currently running dungeon as having completed successfully, successfully here 
-- means that a chest was received at dungeon completion... regardless of timer.
--
-- Please note that there is a CHALLENGE_MODE_COMPLETED event that is fired immediately before 
-- this that we are ignoring because this event includes more details about the run, namely the 
-- amount of time it took.
MplusLedger:RegisterEvent("CHALLENGE_MODE_NEW_RECORD", function(_, _, recordTime)
  MplusLedger:EndMythicPlusAsCompleted(recordTime)
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