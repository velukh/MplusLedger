local MplusLedger = MplusLedger
local AceGUI = LibStub("AceGUI-3.0")
local frame;
local selectedTab;

local HideFrame = function(widget)
	AceGUI:Release(widget) 
	MplusLedger.ShowingMainFrame = false
	selectedTab = nil
end

MplusLedger:RegisterMessage(MplusLedger.Events.HideMainFrame, function()
	HideFrame(frame)
end)

local function AddDungeonLabelsToContainer(container, dungeon)
	local name = C_ChallengeMode.GetMapInfo(dungeon.challengeMapId)

	local dungeonLabel = AceGUI:Create("Label")
	dungeonLabel:SetText(name .. " Level " .. dungeon.mythicLevel)
	container:AddChild(dungeonLabel)

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
	affixesLabel:SetText("Affixes: " .. affixInfo)
	container:AddChild(affixesLabel)

	local totalDeathCountLabel = AceGUI:Create("Label")
	totalDeathCountLabel:SetText("Total Death Count: " .. MplusLedger:DungeonTotalDeathCount(dungeon))
	container:AddChild(totalDeathCountLabel)

	local partyLabel = AceGUI:Create("Label")
	partyLabel:SetText("Party Members:")
	container:AddChild(partyLabel)

	for _, partyMember in ipairs(dungeon.party) do
		for k, v in pairs(partyMember) do
			local partyMemberLabel = AceGUI:Create("Label")
			partyMemberLabel:SetText("    " .. k .. " = " .. v)
			container:AddChild(partyMemberLabel)
		end
		local newLineLabel = AceGUI:Create("Label")
		newLineLabel:SetText("")
		container:AddChild(newLineLabel)
	end
end

local function DrawCurrentDungeonTab(container)
	if MplusLedger:IsRunningMythicPlus() then
		local currentDungeon = MplusLedger:CurrentDungeon()		
		AddDungeonLabelsToContainer(container, currentDungeon)
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
	for _, dungeon in pairs(MplusLedger:FinishedDungeons()) do
		AddDungeonLabelsToContainer(scrollFrame, dungeon)
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

MplusLedger:RegisterMessage(MplusLedger.Events.ShowMainFrame, function()
	MplusLedger.ShowingMainFrame = true
	frame = AceGUI:Create("Frame")
	frame:SetTitle(MplusLedger.Title .. " v" .. MplusLedger.Version)
	frame:SetCallback("OnClose", function(widget) 
		HideFrame(widget)	
	end)
	frame:SetLayout("Fill")

	local tabs = AceGUI:Create("TabGroup")
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
	tabs:SelectTab("current_dungeon")

	frame:AddChild(tabs)
end)
