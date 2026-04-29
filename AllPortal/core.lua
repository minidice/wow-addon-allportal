local addonName = ...
AllPortal = AllPortal or {}
AllPortal.addonName = addonName

local eventFrame = CreateFrame("Frame")

local EVENTS = {
  "PLAYER_LOGIN",
  "PLAYER_ENTERING_WORLD",
  "GET_ITEM_INFO_RECEIVED",
  "BAG_UPDATE_DELAYED",
  "PLAYER_EQUIPMENT_CHANGED",
  "TOY_UPDATED",
  "SPELLS_CHANGED",
  "SPELL_UPDATE_COOLDOWN",
  "BAG_UPDATE_COOLDOWN",
  "PLAYER_REGEN_DISABLED",
  "PLAYER_REGEN_ENABLED",
}

for _, ev in ipairs(EVENTS) do eventFrame:RegisterEvent(ev) end

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

eventFrame:SetScript("OnEvent", function(self, event, ...)
  local UI   = AllPortal.ui
  local data = AllPortal.data

  if event == "PLAYER_LOGIN" then
    AllPortalDB = AllPortalDB or {}
    AllPortalDB.minimap = AllPortalDB.minimap or { angle = 215 }
    if AllPortalDB.minimapHidden  == nil then AllPortalDB.minimapHidden  = false end
    if AllPortalDB.filterOwnedOnly == nil then AllPortalDB.filterOwnedOnly = false end

    UI:Initialize()
    AllPortal.minimap:Initialize()
    print("|cff00ff00AllPortal|r v" .. (GetAddOnMetadata(addonName, "Version") or "?") .. " loaded")

  elseif event == "PLAYER_ENTERING_WORLD" then
    for _, cat in ipairs(data.categories) do
      for entry in data.IterEntries(cat.id) do
        if entry.type ~= "spell" and entry.id and entry.id > 0 then
          GetItemInfo(entry.id)
        end
      end
    end

  elseif event == "GET_ITEM_INFO_RECEIVED" then
    local itemID = ...
    for _, item in ipairs(UI._visibleButtons or {}) do
      if item.btn.entry.id == itemID and item.btn.entry.type ~= "spell" then
        item.btn.icon:SetTexture(data.GetEntryIcon(item.btn.entry))
      end
    end

  elseif event == "BAG_UPDATE_DELAYED"
      or event == "PLAYER_EQUIPMENT_CHANGED"
      or event == "TOY_UPDATED"
      or event == "SPELLS_CHANGED" then
    if UI.frame and UI.frame:IsShown() then
      QueueOrRun(function() UI:Refresh() end)
    end

  elseif event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" then
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
    AllPortal.ui:Toggle()

  elseif msg == "show" then
    AllPortal.ui:Show()

  elseif msg == "hide" then
    AllPortal.ui:Hide()

  elseif msg == "minimap" then
    AllPortalDB.minimapHidden = not AllPortalDB.minimapHidden
    if AllPortalDB.minimapHidden then
      AllPortal.minimap.btn:Hide()
      print(prefix .. T.minimap_hidden_msg)
    else
      AllPortal.minimap.btn:Show()
      print(prefix .. T.minimap_shown_msg)
    end

  elseif msg == "reset" then
    AllPortalDB.framePoint = nil
    AllPortalDB.frameSize  = nil
    AllPortalDB.minimap    = { angle = 215 }
    AllPortal.ui:ResetPosition()
    AllPortal.minimap.UpdatePosition(215)
    print(prefix .. T.reset_msg)

  elseif msg == "help" or msg == "?" then
    print(prefix .. T.help_header)
    print("  /allportal           — " .. T.help_toggle)
    print("  /allportal minimap   — " .. T.help_minimap)
    print("  /allportal reset     — " .. T.help_reset)
    print("  /allportal help      — " .. T.help_help)

  else
    print(errPrefix .. T.unknown_cmd_msg .. " '/allportal help'")
  end
end
