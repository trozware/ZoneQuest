-- ZoneQuest: An addon to track quests by zone, relevance and distance.

-- Always show tracked quest at the top of the list, then complete, important, meta, then the rest sorted by distance.
-- Don't track newest quest if it is auto-accepted.
-- If you do track it, make sure to track the quest that was selected before accepting the new quest,
--   so that the selected quest doesn't get lost when accepting a new quest.
-- add option to reset list without any selected or newest quests so order is based purely on zone and distance

ZoneQuest = {}

local ZoneQuest_EventFrame = CreateFrame("Frame")
ZoneQuest_EventFrame:RegisterEvent("VARIABLES_LOADED")
ZoneQuest_EventFrame:RegisterEvent("PLAYER_LOGIN")
ZoneQuest_EventFrame:RegisterEvent("ZONE_CHANGED")
ZoneQuest_EventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ZoneQuest_EventFrame:RegisterEvent("QUEST_ACCEPTED") -- Fires when a quest is accepted, including auto-accepted quests.
ZoneQuest_EventFrame:RegisterEvent("QUEST_COMPLETE")
ZoneQuest_EventFrame:RegisterEvent("QUEST_AUTOCOMPLETE")
ZoneQuest_EventFrame:RegisterEvent("QUEST_TURNED_IN")
ZoneQuest_EventFrame:RegisterEvent("QUEST_REMOVED")
ZoneQuest_EventFrame:RegisterEvent("QUEST_ACCEPT_CONFIRM") -- Fires when agreeing to join a group quest that a party member has started
ZoneQuest_EventFrame:RegisterEvent("QUEST_FINISHED")
ZoneQuest_EventFrame:RegisterEvent("QUEST_WATCH_UPDATE")

ZoneQuest_SelectedQuestID = nil
ZoneQuest_NewestQuestID = nil
ZoneQuest_DebugMode = false

ZoneQuest_EventFrame:SetScript(
  "OnEvent",
  function(self, event, questID, ...)
    -- print(event, questID)
    if event == "VARIABLES_LOADED" then
      ZoneQuest:Initialize()
    elseif event == "PLAYER_LOGIN" then
      ZoneQuest_ShowWelcome()
      ZoneQuest_DelayedUpdate(1)
    elseif event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
      ZoneQuest_DelayedUpdate(1)
    elseif event == "QUEST_ACCEPTED" or event == "QUEST_ACCEPT_CONFIRM" then
      if questID and questID > 0 then
        ZoneQuest_HandleNewQuest(questID)
      end
    elseif event == "QUEST_WATCH_UPDATE" then
      if questID and questID > 0 then
        ZoneQuest_SelectedQuestID = questID
        C_SuperTrack.SetSuperTrackedQuestID(ZoneQuest_SelectedQuestID)
      end
    elseif
      event == "QUEST_COMPLETE" or event == "QUEST_TURNED_IN" or event == "QUEST_REMOVED" or
        event == "QUEST_AUTOCOMPLETE" or
        event == "QUEST_FINISHED"
     then
      ZoneQuest_DelayedUpdate(1)
    end
  end
)

function ZoneQuest:Initialize()
  SLASH_ZoneQuest1, SLASH_ZoneQuest2 = "/ZoneQuest", "/zq"
  SlashCmdList["ZoneQuest"] = ZoneQuestCommandHandler
  if not zoneQuestSettings then
    zoneQuestSettings = {}
    ZoneQuest_ApplyDefaultSettings(false)
  end

  ZoneQuest_addInterfaceOptions()
end

function ZoneQuest_ApplyDefaultSettings(withMessage)
  if withMessage then
    ZoneQuest_DisplayMessage("ZoneQuest settings have been reset to the defaults.", true)
  end

  zoneQuestSettings = {
    showCompletes = true,
    alwaysShowMeta = true,
    alwaysShowImportant = true,
    maxTrackedQuests = 10
  }
end

function ZoneQuestCommandHandler(msg)
  if msg == "reset" then
    ZoneQuest_Reset()
  else
    ZoneQuest_DisplayHelp()
  end
end

function ZoneQuest_ShowWelcome()
  local v = C_AddOns.GetAddOnMetadata("ZoneQuest", "Version")
  local msg = "|c0000FF00Welcome to ZoneQuest v" .. v .. ": " .. "|c0000FFFFType |c00FFD100/zq |c0000FFFFfor help."
  ZoneQuest_DisplayMessage(msg, false)
end

function ZoneQuest_DisplayMessage(msg, format)
  if format == true then
    local formatted_msg = "|c0000FF00ZoneQuest: |c0000FFFF" .. msg
    ChatFrame1:AddMessage(formatted_msg)
  else
    ChatFrame1:AddMessage(msg)
  end
end

function ZoneQuest_DisplayHelp()
  local msg
  msg = "|c0000FF00ZoneQuest " .. "|c0000FFFFattempts to track quests by zone, relevance and distance."
  ChatFrame1:AddMessage(msg)
  msg = "|c0000FF00ZoneQuest: " .. "|c0000FFFFType |cFFFFFFFF/zq reset|c0000FFFF to reset the quest list order."
  ChatFrame1:AddMessage(msg)
  msg = "|c0000FFFFUse Game Menu > Options > AddOns > ZoneQuest to configure the options."
  ChatFrame1:AddMessage(msg)
end

function ZoneQuest_ListQuests()
  local maxNumQuests = C_QuestLog.GetMaxNumQuests()
  for i = 1, maxNumQuests do
    local questID = C_QuestLog.GetQuestIDForLogIndex(i)
    if questID > 0 then
      local isOnQuest = C_QuestLog.IsOnQuest(questID)
      if isOnQuest then
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHidden then
          local isComplete = C_QuestLog.IsComplete(questID)
          local isImportant = C_QuestLog.IsImportantQuest(questID)
          local isMeta = C_QuestLog.IsMetaQuest(questID)

          local title = info.title
          local isOnMap = info.isOnMap
          local distanceSq, onContinent = C_QuestLog.GetDistanceSqToQuest(questID)

          print(
            "Quest ID: " ..
              questID ..
                ", Title: " ..
                  title ..
                    ", Complete: " ..
                      tostring(isComplete) ..
                        ", Important: " ..
                          tostring(isImportant) ..
                            ", Meta: " ..
                              tostring(isMeta) ..
                                ", OnMap: " ..
                                  tostring(isOnMap) ..
                                    ", DistanceSq: " ..
                                      (distanceSq or "N/A") .. ", OnContinent: " .. tostring(onContinent)
          )
        end
      end
    end
  end
end

-- /run ZoneQuest_ListQuests()

function ZoneQuest_UntrackAllQuests()
  local maxNumQuests = C_QuestLog.GetNumQuestWatches()
  ZoneQuest_SelectedQuestID = C_SuperTrack.GetSuperTrackedQuestID()
  local index = 1
  for i = 1, maxNumQuests do
    local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(index)
    if questID and questID > 0 then
      local info = C_QuestLog.GetInfo(questID)
      C_QuestLog.RemoveQuestWatch(questID)
    end
  end
end

-- /run ZoneQuest_UntrackAllQuests()

function ZoneQuest_WatchQuests(doReset)
  ZoneQuest_UntrackAllQuests()

  local validQuests = ZoneQuest_GetValidQuests()

  local inInstance, instanceType = IsInInstance()
  if inInstance then
    ZoneQuest_WatchInstanceQuests(validQuests)
    return
  end

  -- add tracked quest to list first
  -- add complete quests next, then important and meta quests
  -- next add the closest quests until we reach the max number of quests to track, then sort by distance and track those on the map.

  local questsToShow = {}

  if doReset then
    ZoneQuest_SelectedQuestID = nil
    ZoneQuest_NewestQuestID = nil
  else
    questsToShow.selected = ZoneQuest_SelectedQuestID
    questsToShow.newest = ZoneQuest_NewestQuestID
  end

  questsToShow.complete = ZoneQuest_GetCompletedQuests(validQuests)
  questsToShow.important = ZoneQuest_GetImportantQuests(validQuests)
  questsToShow.meta = ZoneQuest_GetMetaQuests(validQuests)

  -- print("===============")
  -- print("Selected Quest ID: " .. (ZoneQuest_SelectedQuestID or "None"))
  -- print("Newest Quest ID: " .. (ZoneQuest_NewestQuestID or "None"))
  -- print("Complete Quests: " .. #questsToShow.complete)
  -- print("Important Quests: " .. #questsToShow.important)
  -- print("Meta Quests: " .. #questsToShow.meta)

  local totalQuestsToTrack = #questsToShow.complete + #questsToShow.important + #questsToShow.meta
  if questsToShow.selected then
    totalQuestsToTrack = totalQuestsToTrack + 1
  end
  if questsToShow.newest then
    totalQuestsToTrack = totalQuestsToTrack + 1
  end

  local completedQuestIDs = {}
  for _, quest in ipairs(questsToShow.complete) do
    completedQuestIDs[quest.questID] = true
  end

  local maxTrackedQuests = zoneQuestSettings and zoneQuestSettings.maxTrackedQuests or 10
  local remainingSlots = maxTrackedQuests - totalQuestsToTrack
  questsToShow.closest = ZoneQuest_ClosestQuestIDs(remainingSlots, validQuests, completedQuestIDs)
  totalQuestsToTrack = totalQuestsToTrack + #questsToShow.closest

  if totalQuestsToTrack == 0 then
    questsToShow.closest = ZoneQuest_AnyQuestIDs(validQuests)
  end
  -- print("Closest Quests: " .. #questsToShow.closest)

  ZoneQuest_SelectedQuestID = nil
  ZoneQuest_NewestQuestID = nil

  local alreadyWatched = {}
  local numWatches = C_QuestLog.GetNumQuestWatches()
  for i = 1, numWatches do
    local watchInfo = C_QuestLog.GetQuestWatchInfo(i)
    if watchInfo then
      alreadyWatched[watchInfo.questID] = true
    end
  end

  local function addWatch(questID)
    if not alreadyWatched[questID] then
      C_QuestLog.AddQuestWatch(questID)
      alreadyWatched[questID] = true
    end
  end

  local closeQuestIDs = {}
  for _, quest in ipairs(questsToShow.closest) do
    closeQuestIDs[quest.questID] = true
  end

  for _, quest in ipairs(questsToShow.complete) do
    if not closeQuestIDs[quest.questID] then
      addWatch(quest.questID)
      ZoneQuest_DebugPrint(
        "Complete Quest: " .. quest.title .. " (ID: " .. quest.questID .. ", DistanceSq: " .. quest.distanceSq .. ")"
      )
    else
      ZoneQuest_DebugPrint(
        "Skipping Complete Quest (already shown as close): " ..
          quest.title .. " (ID: " .. quest.questID .. ", DistanceSq: " .. quest.distanceSq .. ")"
      )
    end
  end
  for _, quest in ipairs(questsToShow.meta) do
    addWatch(quest.questID)
    ZoneQuest_DebugPrint(
      "Meta Quest: " .. quest.title .. " (ID: " .. quest.questID .. ", DistanceSq: " .. quest.distanceSq .. ")"
    )
  end
  for _, quest in ipairs(questsToShow.important) do
    addWatch(quest.questID)
    ZoneQuest_DebugPrint(
      "Important Quest: " .. quest.title .. " (ID: " .. quest.questID .. ", DistanceSq: " .. quest.distanceSq .. ")"
    )
    -- )
  end
  for _, quest in ipairs(questsToShow.closest) do
    addWatch(quest.questID)
    ZoneQuest_DebugPrint(
      "Closest Quest: " .. quest.title .. " (ID: " .. quest.questID .. ", DistanceSq: " .. quest.distanceSq .. ")"
    )
  end

  ZoneQuest_DebugPrint("New Quests Available: " .. (questsToShow.newest and questsToShow.newest or "None"))
  ZoneQuest_DebugPrint("Selected Quest: " .. (questsToShow.selected and questsToShow.selected or "None"))

  if questsToShow.selected then
    ZoneQuest_DebugPrint("Selected Quest: ID: " .. questsToShow.selected)
    addWatch(questsToShow.selected)
    ZoneQuest_SelectedQuestID = questsToShow.selected
  end

  if questsToShow.newest then
    ZoneQuest_DebugPrint("Newest Quest: ID: " .. questsToShow.newest)
    addWatch(questsToShow.newest)
    -- local top3Closest = ZoneQuest_ClosestQuestIDs(3, validQuests, {})
    -- for _, quest in ipairs(top3Closest) do
    --   if quest.questID == questsToShow.newest then
    ZoneQuest_SelectedQuestID = questsToShow.newest
  --     break
  --   end
  -- end
  -- if not ZoneQuest_SelectedQuestID then
  --   ZoneQuest_DebugPrint("Newest quest not in top 3 closest on-map quests, skipping auto-select")
  --   -- ZoneQuest_NewestQuestID = questsToShow.newest
  -- end
  end

  if ZoneQuest_SelectedQuestID then
    ZoneQuest_DebugPrint("Tracked Quest: " .. (ZoneQuest_SelectedQuestID and ZoneQuest_SelectedQuestID or "None"))
    C_SuperTrack.SetSuperTrackedQuestID(ZoneQuest_SelectedQuestID)
  elseif #alreadyWatched == 0 then
    local closestQuests = ZoneQuest_ClosestQuestIDs(1, validQuests, {})
    local firstWatchedQuestID = closestQuests and closestQuests[1] and closestQuests[1].questID
    if firstWatchedQuestID then
      ZoneQuest_SelectedQuestID = firstWatchedQuestID
      C_SuperTrack.SetSuperTrackedQuestID(ZoneQuest_SelectedQuestID)
      ZoneQuest_DebugPrint(
        "No selected or newest quest to track, defaulting to closest quest: ID: " .. ZoneQuest_SelectedQuestID
      )
    end
  end
end

-- /run ZoneQuest_WatchQuests()

function ZoneQuest_GetValidQuests()
  local quests = {}
  local maxNumQuests = C_QuestLog.GetMaxNumQuests()

  for i = 1, maxNumQuests do
    local info = C_QuestLog.GetInfo(i)
    if info and not info.isHidden then
      local questID = info.questID
      if questID and questID > 0 then
        local distanceSq, onContinent = C_QuestLog.GetDistanceSqToQuest(questID)
        local onMap, hasLocalPOI = C_QuestLog.IsOnMap(questID)
        table.insert(
          quests,
          {
            questID = questID,
            title = info.title,
            isOnMap = info.isOnMap,
            questClassification = info.questClassification,
            isOnQuest = C_QuestLog.IsOnQuest(questID),
            isComplete = C_QuestLog.IsComplete(questID),
            isImportant = C_QuestLog.IsImportantQuest(questID),
            isMeta = C_QuestLog.IsMetaQuest(questID),
            distanceSq = distanceSq,
            onContinent = onContinent,
            onMap = onMap,
            hasLocalPOI = hasLocalPOI
          }
        )
      end
    end
  end

  return quests
end

function ZoneQuest_GetCompletedQuests(validQuests)
  local completed = {}
  if not zoneQuestSettings or not zoneQuestSettings.showCompletes then
    return completed
  end

  for _, quest in ipairs(validQuests) do
    if quest.isOnQuest and quest.isOnMap and quest.isComplete and quest.distanceSq and quest.onContinent then
      table.insert(completed, {questID = quest.questID, distanceSq = quest.distanceSq, title = quest.title})
    end
  end

  return completed
end

function ZoneQuest_GetImportantQuests(validQuests)
  local important = {}

  for _, quest in ipairs(validQuests) do
    if quest.isOnQuest and quest.isImportant then
      local distanceSq = quest.distanceSq or 0
      if zoneQuestSettings.alwaysShowImportant or (quest.onContinent and distanceSq > 0) then
        table.insert(important, {questID = quest.questID, distanceSq = distanceSq, title = quest.title})
      end
    end
  end

  return important
end

function ZoneQuest_GetMetaQuests(validQuests)
  local meta = {}

  for _, quest in ipairs(validQuests) do
    if quest.isOnQuest and quest.isMeta then
      local distanceSq = quest.distanceSq or 0
      if zoneQuestSettings.alwaysShowMeta or (quest.onContinent and distanceSq > 0) then
        table.insert(meta, {questID = quest.questID, distanceSq = distanceSq, title = quest.title})
      end
    end
  end

  return meta
end

function ZoneQuest_ClosestQuestIDs(maxCount, validQuests, completeQuestIDs)
  local closest = {}
  local revisedMaxCount = maxCount

  for _, quest in ipairs(validQuests) do
    if quest.title and quest.isOnQuest and quest.isOnMap and quest.onContinent and quest.distanceSq then
      table.insert(closest, {questID = quest.questID, distanceSq = quest.distanceSq, title = quest.title})
    end
  end

  table.sort(
    closest,
    function(a, b)
      return a.distanceSq < b.distanceSq
    end
  )

  -- print out the title and distance of the closest quests for debugging
  for i, quest in ipairs(closest) do
    ZoneQuest_DebugPrint("Quest: " .. quest.title .. ", DistanceSq: " .. (quest.distanceSq or "N/A"))
  end

  for i, quest in ipairs(closest) do
    if quest.questID and completeQuestIDs[quest.questID] then
      revisedMaxCount = revisedMaxCount + 1
    end
  end

  local closestQuestIDs = {}
  for i = 1, math.min(revisedMaxCount or 5, #closest) do
    table.insert(
      closestQuestIDs,
      {questID = closest[i].questID, title = closest[i].title, distanceSq = closest[i].distanceSq}
    )
  end

  table.sort(
    closestQuestIDs,
    function(a, b)
      return a.distanceSq > b.distanceSq
    end
  )

  return closestQuestIDs
end

function ZoneQuest_AnyQuestIDs(validQuests)
  local closest = {}

  for _, quest in ipairs(validQuests) do
    if quest.title and quest.isOnQuest and quest.questClassification and quest.questClassification > 5 then
      table.insert(closest, {questID = quest.questID, distanceSq = 0, title = quest.title})
    end
  end

  table.sort(
    closest,
    function(a, b)
      return a.distanceSq < b.distanceSq
    end
  )

  return closest
end

function ZoneQuest_HandleNewQuest(questID)
  if questID and questID > 0 then
    local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
    if questLogIndex and questLogIndex > 0 then
      local info = C_QuestLog.GetInfo(questLogIndex)
      if info and not info.isHidden and info.questClassification and info.questClassification <= 7 then
        ZoneQuest_NewestQuestID = questID
      end
    end
  end
  ZoneQuest_DelayedUpdate(1) -- Update after a 1-second delay to ensure all quest data is loaded
end

function ZoneQuest_WatchInstanceQuests(validQuests)
  for _, quest in ipairs(validQuests) do
    if quest.onMap or quest.hasLocalPOI then
      C_QuestLog.AddQuestWatch(quest.questID)
    end
  end
end

local _delayedUpdateTimer
function ZoneQuest_DelayedUpdate(delay)
  if _delayedUpdateTimer then
    _delayedUpdateTimer:Cancel()
  end
  _delayedUpdateTimer =
    C_Timer.After(
    delay,
    function()
      _delayedUpdateTimer = nil
      ZoneQuest_WatchQuests(false)
    end
  )
end

function ZoneQuest_Reset()
  ZoneQuest_SelectedQuestID = nil
  ZoneQuest_NewestQuestID = nil
  ZoneQuest_WatchQuests(true)
  ZoneQuest_DisplayMessage("ZoneQuest list has been reset to show closest quests.", true)
end

function ZoneQuest_DebugPrint(msg)
  if ZoneQuest_DebugMode then
    print(msg)
  end
end
