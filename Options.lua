local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local optionsTable = {
  type = "group",
  args = {
    enable_minimap = {
      type = "toggle",
      width = "full",
      name = "Show Minimap Button",
      desc = "Show or hide the minimap button. Requires you to reload your UI",
      descStyle = "inline",
      confirm = true,
      confirmText = "Changing this setting requires you to reload your UI. Are you sure?",
      set = function(info, val) 
        MplusLedger:SetConfig(info[1], val)
        ReloadUI()
      end,
      get = function(info)
        return MplusLedger:GetConfig(info[1])
      end
    },

    display_no_key_characters = {
      type = "toggle",
      width = "full",
      name = "Show your characters with no keys",
      desc = "Show or hide other characters without keys in the minimap button tooltip and the 'Your Keys' tab. This will not impact your currently logged in character.",
      descStyle = "inline",
      set = function(info, val)
        MplusLedger:SetConfig(info[1], val)
      end,
      get = function(info)
        return MplusLedger:GetConfig(info[1])
      end
    },

    display_party_in_minimap = {
      type = "toggle",
      width = "full",
      name = "Show party member's keys in minimap button",
      desc = "Show or hide party member's keys in the minimap button. This will only show up if you're in a group",
      descStyle = "inline",
      set = function(info, val)
        MplusLedger:SetConfig(info[1], val)
      end,
      get = function(info)
        return MplusLedger:GetConfig(info[1])
      end
    }
  }
}

AceConfigDialog:AddToBlizOptions("M+ Ledger")
AceConfig:RegisterOptionsTable("M+ Ledger", optionsTable)