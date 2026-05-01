local addonName = ...
AllPortal = AllPortal or {}
AllPortal.addonName = addonName

local eventFrame = CreateFrame("Frame")

local function GetAddonMetadata(field)
  if C_AddOns and C_AddOns.GetAddOnMetadata then
    return C_AddOns.GetAddOnMetadata(addonName, field)
  end
  if GetAddOnMetadata then
    return GetAddOnMetadata(addonName, field)
  end
end

-- GET_ITEM_INFO_RECEIVED was removed in Dragonflight (10.0); registering a
-- removed event throws a Lua error that stops the entire file from executing.
-- BAG_UPDATE_COOLDOWN was also removed in 10.0; use SPELL_UPDATE_COOLDOWN instead.
-- PLAYER_REGEN_DISABLED: we queue on lockdown; no need to listen for it explicitly.
local EVENTS = {
  "PLAYER_LOGIN",
  "PLAYER_ENTERING_WORLD",
  "BAG_UPDATE_DELAYED",
  "PLAYER_EQUIPMENT_CHANGED",
  "TOY_UPDATED",
  "TOYS_UPDATED",
  "SPELLS_CHANGED",
  "SPELL_UPDATE_COOLDOWN",
  "PLAYER_HOUSE_LIST_UPDATED",
  "PLAYER_REGEN_ENABLED",
}

for _, ev in ipairs(EVENTS) do
  local ok, err = pcall(eventFrame.RegisterEvent, eventFrame, ev)
  if not ok then
    print("|cffff0000AllPortal event error:|r " .. ev .. " - " .. tostring(err))
  end
end

local lockdownQueue = {}

local function FlushQueue()
  while #lockdownQueue > 0 do
    local fn = table.remove(lockdownQueue, 1)
    pcall(fn)
  end
end

local function QueueOrRun(fn)
  if InCombatLockdown() then
    tinsert(lockdownQueue, fn)
  else
    fn()
  end
end

function AllPortal.ToggleUI()
  if AllPortal.ui then AllPortal.ui:Toggle() end
end

function AllPortal.UseRandomHearth()
  local T = AllPortal.T or {}
  local favorites = AllPortal.data.GetUsableFavoriteHearthstones and AllPortal.data.GetUsableFavoriteHearthstones() or {}
  if #favorites == 0 then
    print("|cff00ff00AllPortal:|r " .. (T.hearth_no_fav or "No usable favorite hearthstones."))
    return
  end

  local entry = favorites[math.random(#favorites)]
  if entry.type == "toy" then
    C_ToyBox.UseToy(entry.id)
  elseif entry.type == "item" then
    if C_Item and C_Item.UseItemByName then
      C_Item.UseItemByName("item:" .. entry.id)
    elseif UseItemByName then
      UseItemByName("item:" .. entry.id)
    end
  end
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
  local UI   = AllPortal.ui
  local data = AllPortal.data

  if event == "PLAYER_LOGIN" then
    AllPortalDB = AllPortalDB or {}
    AllPortalDB.minimap = AllPortalDB.minimap or { angle = 215 }
    if AllPortalDB.minimapHidden  == nil then AllPortalDB.minimapHidden  = false end
    if AllPortalDB.showUnavailable == nil then AllPortalDB.showUnavailable = false end
    if AllPortalDB.showOtherFaction == nil then AllPortalDB.showOtherFaction = false end
    AllPortalDB.hearthFavorites = AllPortalDB.hearthFavorites or {}

    local okUI, errUI = pcall(function() UI:Initialize() end)
    if not okUI then
      print("|cffff0000AllPortal UI error:|r " .. tostring(errUI))
    end

    local okMM, errMM = pcall(function() AllPortal.minimap:Initialize() end)
    if not okMM then
      print("|cffff0000AllPortal minimap error:|r " .. tostring(errMM))
    end

    if data and data.RequestHouses then data.RequestHouses() end

    print("|cff00ff00AllPortal|r v" .. (GetAddonMetadata("Version") or "?") .. " loaded")

  elseif event == "PLAYER_ENTERING_WORLD" then
    if data and data.RequestHouses then data.RequestHouses() end

    if data and data.RequestEntryNames then data.RequestEntryNames() end
    if UI and UI.ScheduleNameRefresh and UI.frame and UI.frame:IsShown() then
      UI:ScheduleNameRefresh()
    end

  elseif event == "BAG_UPDATE_DELAYED"
      or event == "PLAYER_EQUIPMENT_CHANGED"
      or event == "TOY_UPDATED"
      or event == "TOYS_UPDATED"
      or event == "SPELLS_CHANGED" then
    if UI.frame and UI.frame:IsShown() then
      QueueOrRun(function() UI:Refresh() end)
    end

  elseif event == "PLAYER_HOUSE_LIST_UPDATED" then
    local houses = ...
    if data and data.UpdateHouses then data.UpdateHouses(houses) end
    if UI.frame and UI.frame:IsShown() then
      QueueOrRun(function() UI:Refresh() end)
    end

  elseif event == "SPELL_UPDATE_COOLDOWN" then
    if UI.frame and UI.frame:IsShown() then
      UI:UpdateCooldowns()
    end

  elseif event == "PLAYER_REGEN_ENABLED" then
    FlushQueue()
  end
end)

-- ============================================================
-- Slash command
-- ============================================================
SLASH_ALLPORTAL1 = "/allportal"

SlashCmdList["ALLPORTAL"] = function(msg)
  msg = strtrim((msg or ""):lower())
  local T = AllPortal.T
  local prefix    = "|cff00ff00AllPortal:|r "
  local errPrefix = "|cffff0000AllPortal:|r "

  if msg == "" then
    AllPortal.ToggleUI()

  elseif msg == "hearth" then
    AllPortal.UseRandomHearth()

  elseif msg == "show" then
    AllPortal.ui:Show()

  elseif msg == "hide" then
    AllPortal.ui:Hide()

  elseif msg == "minimap" then
    AllPortalDB.minimapHidden = not AllPortalDB.minimapHidden
    if AllPortalDB.minimapHidden then
      if AllPortal.minimap.btn then AllPortal.minimap.btn:Hide() end
      print(prefix .. T.minimap_hidden_msg)
    else
      if not AllPortal.minimap.btn then AllPortal.minimap:Initialize() end
      if AllPortal.minimap.btn then AllPortal.minimap.btn:Show() end
      print(prefix .. T.minimap_shown_msg)
    end

  elseif msg == "reset" then
    AllPortalDB.framePoint = nil
    AllPortalDB.frameSize  = nil
    AllPortalDB.minimap    = { angle = 215 }
    AllPortal.ui:ResetPosition()
    if AllPortal.minimap.btn then AllPortal.minimap.UpdatePosition(215) end
    print(prefix .. T.reset_msg)

  elseif msg == "help" or msg == "?" then
    print(prefix .. T.help_header)
    print("  /allportal           — " .. T.help_toggle)
    print("  /allportal hearth    — " .. (T.hearth_random or "Random Hearth"))
    print("  /allportal minimap   — " .. T.help_minimap)
    print("  /allportal reset     — " .. T.help_reset)
    print("  /allportal help      — " .. T.help_help)

  else
    print(errPrefix .. T.unknown_cmd_msg .. " '/allportal help'")
  end
end
