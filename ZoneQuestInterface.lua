function ZoneQuest_addInterfaceOptions()
  local y = -16
  ZoneQuest.panel = CreateFrame("Frame", "ZoneQuestPanel", UIParent)
  ZoneQuest.panel.name = "ZoneQuest"

  local category, layout =
    Settings.RegisterCanvasLayoutCategory(ZoneQuest.panel, ZoneQuest.panel.name, ZoneQuest.panel.name)
  category.ID = ZoneQuest.panel.name
  Settings.RegisterAddOnCategory(category)

  local Title = ZoneQuest.panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  Title:SetJustifyV("TOP")
  Title:SetJustifyH("LEFT")
  Title:SetPoint("TOPLEFT", 16, y)
  local v = C_AddOns.GetAddOnMetadata("ZoneQuest", "Version")
  Title:SetText("ZoneQuest v" .. v)
  y = y - 44

  local btnCompletes = CreateFrame("CheckButton", nil, ZoneQuest.panel, "UICheckButtonTemplate")
  btnCompletes:SetSize(26, 26)
  btnCompletes:SetHitRectInsets(-2, -160, -2, -2)
  btnCompletes.text:SetText("  Show Completed Quests")
  btnCompletes.text:SetFontObject("GameFontNormal")
  btnCompletes:SetPoint("TOPLEFT", 40, y)
  btnCompletes:SetChecked(zoneQuestSettings.showCompletes == true)
  btnCompletes:SetScript(
    "OnClick",
    function()
      local isChecked = btnCompletes:GetChecked()
      if isChecked then
        zoneQuestSettings.showCompletes = true
      else
        zoneQuestSettings.showCompletes = false
      end
      ZoneQuest_DelayedUpdate(1)
    end
  )
  y = y - 25

  local completedInfo = ZoneQuest.panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
  completedInfo:SetJustifyV("TOP")
  completedInfo:SetJustifyH("LEFT")
  completedInfo:SetPoint("TOPLEFT", 100, y)
  completedInfo:SetText("If this is checked, completed quests will still be shown if they are nearby.")
  y = y - 40

  local btnMeta = CreateFrame("CheckButton", nil, ZoneQuest.panel, "UICheckButtonTemplate")
  btnMeta:SetSize(26, 26)
  btnMeta:SetHitRectInsets(-2, -160, -2, -2)
  btnMeta.text:SetText("  Always Show Meta Quests")
  btnMeta.text:SetFontObject("GameFontNormal")
  btnMeta:SetPoint("TOPLEFT", 40, y)
  btnMeta:SetChecked(zoneQuestSettings.alwaysShowMeta == true)
  btnMeta:SetScript(
    "OnClick",
    function()
      local isChecked = btnMeta:GetChecked()
      if isChecked then
        zoneQuestSettings.alwaysShowMeta = true
      else
        zoneQuestSettings.alwaysShowMeta = false
      end
      ZoneQuest_DelayedUpdate(1)
    end
  )
  y = y - 25

  local metaInfo = ZoneQuest.panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
  metaInfo:SetJustifyV("TOP")
  metaInfo:SetJustifyH("LEFT")
  metaInfo:SetPoint("TOPLEFT", 100, y)
  metaInfo:SetText("If this is checked, all meta quests will be shown,\neven if they are not in the current zone.")
  y = y - 40

  local btnImportant = CreateFrame("CheckButton", nil, ZoneQuest.panel, "UICheckButtonTemplate")
  btnImportant:SetSize(26, 26)
  btnImportant:SetHitRectInsets(-2, -160, -2, -2)
  btnImportant.text:SetText("  Always Show Important Quests")
  btnImportant.text:SetFontObject("GameFontNormal")
  btnImportant:SetPoint("TOPLEFT", 40, y)
  btnImportant:SetChecked(zoneQuestSettings.alwaysShowImportant == true)
  btnImportant:SetScript(
    "OnClick",
    function()
      local isChecked = btnImportant:GetChecked()
      if isChecked then
        zoneQuestSettings.alwaysShowImportant = true
      else
        zoneQuestSettings.alwaysShowImportant = false
      end
      ZoneQuest_DelayedUpdate(1)
    end
  )
  y = y - 25

  local importantInfo = ZoneQuest.panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
  importantInfo:SetJustifyV("TOP")
  importantInfo:SetJustifyH("LEFT")
  importantInfo:SetPoint("TOPLEFT", 100, y)
  importantInfo:SetText(
    "If this is checked, all important quests will be shown,\neven if they are not in the current zone."
  )
  y = y - 40

  -- add a slider to choose max tracked quests from 3 to 20
  local slider = CreateFrame("Slider", nil, ZoneQuest.panel, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", 40, y)
  slider:SetMinMaxValues(3, 20)
  slider:SetValueStep(1)
  slider:SetObeyStepOnDrag(true)
  slider:SetValue(zoneQuestSettings.maxTrackedQuests or 10)
  slider.Text:ClearAllPoints()
  slider.Text:SetPoint("LEFT", slider, "RIGHT", 10, 0)
  slider.Text:SetFontObject("GameFontNormal")
  slider.Text:SetText("Max Tracked Quests: " .. (zoneQuestSettings.maxTrackedQuests or 10))
  slider:SetScript(
    "OnValueChanged",
    function(self, value)
      zoneQuestSettings.maxTrackedQuests = value
      slider.Text:SetText("Max Tracked Quests: " .. value)
      ZoneQuest_DelayedUpdate(1)
    end
  )
  y = y - 35

  local maxTrackedInfo = ZoneQuest.panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
  maxTrackedInfo:SetJustifyV("TOP")
  maxTrackedInfo:SetJustifyH("LEFT")
  maxTrackedInfo:SetPoint("TOPLEFT", 100, y)
  maxTrackedInfo:SetText(
    "Set the maximum number of quests to track at once.\nDepending on quest availability and other settings, you may see a different number."
  )
  y = y - 60

  local resetBtn = CreateFrame("Button", nil, ZoneQuest.panel, "UIPanelButtonTemplate")
  resetBtn:SetSize(160, 26)
  resetBtn:SetText("Reset to Default Settings")
  resetBtn:SetPoint("TOPLEFT", 40, y)
  resetBtn:SetScript(
    "OnClick",
    function()
      ZoneQuest_ResetSettings()
    end
  )
  y = y - 60

  local resetInfo = ZoneQuest.panel:CreateFontString(nil, "ARTWORK", "GameFontWhite")
  resetInfo:SetJustifyV("TOP")
  resetInfo:SetJustifyH("LEFT")
  resetInfo:SetPoint("TOPLEFT", 40, y)
  resetInfo:SetText("If the order of quests in the list looks wrong, type '/zq reset' in the chat to reset.")
end

function ZoneQuest_ResetSettings()
  ZoneQuest_ApplyDefaultSettings(true)
  ZoneQuest_DelayedUpdate(1)
  ZoneQuest_UpdateInterfaceOptions()
end

function ZoneQuest_UpdateInterfaceOptions()
  if not ZoneQuest.panel then
    return
  end

  for _, child in ipairs({ZoneQuest.panel:GetChildren()}) do
    if child.Text and child.Text:GetText() and string.find(child.Text:GetText(), "Max Tracked Quests:") then
      child.Text:SetText("Max Tracked Quests: " .. (zoneQuestSettings.maxTrackedQuests or 10))
    elseif child.text and child.text:GetText() == "  Show Completed Quests" then
      child:SetChecked(zoneQuestSettings.showCompletes == true)
    elseif child.text and child.text:GetText() == "  Always Show Meta Quests" then
      child:SetChecked(zoneQuestSettings.alwaysShowMeta == true)
    elseif child.text and child.text:GetText() == "  Always Show Important Quests" then
      child:SetChecked(zoneQuestSettings.alwaysShowImportant == true)
    end
  end
end
