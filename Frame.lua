local MplusLedger = MplusLedger
local AceGUI = LibStub("AceGUI-3.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")
local frame
local tabs
local selectedTab
local font, fontSize, flags = GameFontNormal:GetFont()

local OneIndent = "     "
local TwoIndent = OneIndent .. OneIndent

local HideFrame = function(widget)
	AceGUI:Release(widget) 
	MplusLedger.ShowingMainFrame = false
	selectedTab = nil
end

local function ClassColorText(text, classToken)
  local color = RAID_CLASS_COLORS[classToken]
  return string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, text)
end

local function AddPartyMemberLabelsToContainer(container, partyMember) 
  local nameLabel = AceGUI:Create("Label")
  local name = ClassColorText(partyMember.name, partyMember.classToken)
  if partyMember.realm then
    name = name .. " - " .. partyMember.realm
  end
  nameLabel:SetText(OneIndent .. name)
  nameLabel:SetRelativeWidth(1.0)
  nameLabel:SetFont(font, fontSize * 1.25, flags)
  
  container:AddChild(nameLabel)
  
  local raceClassLabel = AceGUI:Create("Label")
  raceClassLabel:SetText(TwoIndent .. partyMember.race .. " " .. partyMember.class)
  raceClassLabel:SetRelativeWidth(1.0)
  raceClassLabel:SetFont(font, fontSize * 1.1, flags)
  
  container:AddChild(raceClassLabel)
  
  local deathCountLabel = AceGUI:Create("Label")
  deathCountLabel:SetText(TwoIndent .. "Died " .. partyMember.deathCount .. " times")
  deathCountLabel:SetRelativeWidth(1.0)
  deathCountLabel:SetFont(font, fontSize * 0.8, flags)
  
  container:AddChild(deathCountLabel)
end

local function AddDungeonLabelsToContainer(container, dungeon)
	local name = C_ChallengeMode.GetMapInfo(dungeon.challengeMapId)
  local nameLabel = AceGUI:Create("Label")
  nameLabel:SetText(name)
  nameLabel:SetFont(font, fontSize * 2.25, flags)
  nameLabel:SetRelativeWidth(0.8)
  
  container:AddChild(nameLabel)

  local levelLabel = AceGUI:Create("Label")
  levelLabel:SetText("Level " .. dungeon.mythicLevel)
  levelLabel:SetFont(font, fontSize * 2.25, flags)
  levelLabel:SetRelativeWidth(0.2)
  
  container:AddChild(levelLabel)
  
  local dateLabel = AceGUI:Create("Label")
  dateLabel:SetText("Ran on " .. date("%c", dungeon.startedAt))
  dateLabel:SetFont(font, fontSize * 1.1, flags)
  dateLabel:SetRelativeWidth(0.8)
  
  container:AddChild(dateLabel)

	local affixInfo
	for _, affixId in ipairs(dungeon.affixes) do
		local name, description = C_ChallengeMode.GetAffixInfo(affixId)
		if not affixInfo then
			affixInfo = name
		else
			affixInfo = affixInfo .. ", " .. name
		end
	end

	if not affixInfo then
		affixInfo = "No affixes"
	end

	local affixesLabel = AceGUI:Create("Label")
	affixesLabel:SetText(affixInfo)
  affixesLabel:SetFont(font, fontSize * 0.8, flags)
  affixesLabel:SetRelativeWidth(0.2)
	container:AddChild(affixesLabel)

	for _, partyMember in ipairs(dungeon.party) do
		AddPartyMemberLabelsToContainer(container, partyMember)
	end
end

local function DrawCurrentDungeonTab(container)
	if MplusLedger:IsRunningMythicPlus() then
		local currentDungeon = MplusLedger:CurrentDungeon()		
		local scrollFrame = AceGUI:Create("ScrollFrame")
		scrollFrame:SetLayout("Flow")
		container:AddChild(scrollFrame)
		AddDungeonLabelsToContainer(scrollFrame, currentDungeon)
	else
		local label = AceGUI:Create("Label")
		label:SetText("No Mythic+ is currently being ran. Please check again after you've started a M+")
		label:SetFullWidth(true)
		container:AddChild(label)
	end
end

local function DrawHistoryTab(container)
	local scrollFrame = AceGUI:Create("ScrollFrame")
	scrollFrame:SetLayout("Flow")
	container:AddChild(scrollFrame)
	for _, dungeon in ipairs(MplusLedger:FinishedDungeons()) do
    local partyGroup = AceGUI:Create("InlineGroup")
    partyGroup:SetLayout("Flow")
    partyGroup:SetRelativeWidth(1.0)
    scrollFrame:AddChild(partyGroup)
		AddDungeonLabelsToContainer(partyGroup, dungeon)
	end
end

local function SelectedTab(container, event, tab)
	container:ReleaseChildren()
	selectedTab = tab
	if tab == "current_dungeon" then
		DrawCurrentDungeonTab(container)
	elseif tab == "history" then
		DrawHistoryTab(container)
	end
end

MplusLedger:RegisterMessage(MplusLedger.Events.HideMainFrame, function()
	HideFrame(frame)
end)

MplusLedger:RegisterMessage(MplusLedger.Events.ShowMainFrame, function(_, tabToShow)
  if not tabToShow then
    tabToShow = "current_dungeon"
  elseif tabToShow ~= "current_dungeon" and tabToShow ~= "history" then
    error("A tab that does not exist, " .. tabToShow .. ", was asked to be shown. If you have not modified this addon's source code please submit an issue describing your problem")
  end
  
	MplusLedger.ShowingMainFrame = true
	frame = AceGUI:Create("Frame")
	frame:SetTitle(MplusLedger.Title)
	frame:SetStatus("v" .. MplusLedger.Version)
	frame:SetCallback("OnClose", function(widget) 
		HideFrame(widget)	
	end)
	frame:SetLayout("Fill")

	tabs = AceGUI:Create("TabGroup")
	tabs:SetLayout("Fill")

	tabs:SetTabs({
		{
			text = "Current Dungeon",
			value = "current_dungeon"
		},
		{
			text = "History",
			value = "history"
		}
	})

	tabs:SetCallback("OnGroupSelected", SelectedTab)
	tabs:SelectTab(tabToShow)

	frame:AddChild(tabs)
end)
