local addonName, ns = ...
AllPortal = AllPortal or {}
local A = AllPortal
A.ui = A.ui or {}
local UI = A.ui

local DEFAULT_W, DEFAULT_H = 476, 400
local MIN_W, MIN_H, MAX_W, MAX_H = 456, 300, 1200, 900
local HEARTH_MIN_W = 700
local HEARTH_MIN_H = 460
local OPEN_UI_ICON = 135743
local RANDOM_HEARTH_ICON = 3193420
local RANDOM_HEARTH_ACTION_BUTTON_NAME = "AllPortalRandomHearthActionButton"
local RANDOM_HEARTH_MACRO_NAME = "Random Hearth AP"
local RANDOM_HEARTH_LEGACY_MACRO_NAME = "Random Hearth"
local RANDOM_HEARTH_CLICK_BODY = "/click " .. RANDOM_HEARTH_ACTION_BUTTON_NAME

local function GetRandomHearthMacroBody(entry)
  if entry and entry.id then
    return "#showtooltip item:" .. entry.id .. "\n" .. RANDOM_HEARTH_CLICK_BODY
  end
  return "#showtooltip\n" .. RANDOM_HEARTH_CLICK_BODY
end

local function ApplyIconButtonFeedback(btn, target)
  local parent = target:GetParent() or btn

  local hover = parent:CreateTexture(nil, "OVERLAY", nil, 6)
  hover:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
  hover:SetBlendMode("ADD")
  hover:SetAllPoints(target)
  hover:Hide()

  local pushed = parent:CreateTexture(nil, "OVERLAY", nil, 7)
  pushed:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
  pushed:SetAllPoints(target)
  pushed:SetAlpha(0.85)
  pushed:Hide()

  btn:HookScript("OnEnter", function()
    hover:Show()
  end)
  btn:HookScript("OnLeave", function()
    hover:Hide()
    pushed:Hide()
  end)
  btn:HookScript("OnMouseDown", function()
    pushed:Show()
  end)
  btn:HookScript("OnMouseUp", function()
    pushed:Hide()
  end)
  btn:HookScript("OnHide", function()
    hover:Hide()
    pushed:Hide()
  end)
end

-- ============================================================
-- Main frame
-- ============================================================
local frame = CreateFrame("Frame", "AllPortalMainFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(DEFAULT_W, DEFAULT_H)
frame:SetPoint("CENTER")
frame:SetFrameStrata("HIGH")
frame:SetClampedToScreen(true)
frame:Hide()

-- Movable
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  if AllPortalDB then
    local p, _, rp, x, y = self:GetPoint()
    AllPortalDB.framePoint = { p, "UIParent", rp, x, y }
  end
end)

-- Resizable
frame:SetResizable(true)
if frame.SetResizeBounds then
  frame:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)
else
  frame:SetMinResize(MIN_W, MIN_H)
  frame:SetMaxResize(MAX_W, MAX_H)
end

local resizer = CreateFrame("Button", nil, frame)
resizer:SetSize(16, 16)
resizer:SetPoint("BOTTOMRIGHT", -4, 4)
resizer:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizer:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizer:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizer:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
resizer:SetScript("OnMouseUp", function()
  frame:StopMovingOrSizing()
  if AllPortalDB then
    AllPortalDB.frameSize = { frame:GetWidth(), frame:GetHeight() }
  end
  if UI.RelayoutGrid then UI:RelayoutGrid() end
end)

-- TitleText location changed in Dragonflight (10.x)+: now nested under TitleContainer
local _titleText = frame.TitleText
    or (frame.TitleContainer and frame.TitleContainer.TitleText)
if _titleText then _titleText:SetText(A.T and A.T.addon_title or "AllPortal") end

tinsert(UISpecialFrames, "AllPortalMainFrame")

UI.frame = frame

-- ============================================================
-- Header: filter checkbox (top-left)
-- ============================================================
local filterCB = CreateFrame("CheckButton", "AllPortalFilterCheckbox", frame, "UICheckButtonTemplate")
filterCB:SetSize(20, 20)
filterCB:SetPoint("TOPLEFT", 12, -28)

-- Template text child name varies by WoW version; create our own label to be safe
local filterLabel = filterCB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
filterLabel:SetPoint("LEFT", filterCB, "RIGHT", 4, 0)
filterLabel:SetText(A.T and A.T.show_unavailable or "Show unavailable too")
UI.filterLabel = filterLabel

filterCB:SetScript("OnClick", function(self)
  local checked = self:GetChecked() and true or false
  if AllPortalDB then AllPortalDB.showUnavailable = checked end
  if UI.Refresh then UI:Refresh() end
end)

UI.filterCheckbox = filterCB

local factionCB = CreateFrame("CheckButton", "AllPortalOtherFactionCheckbox", frame, "UICheckButtonTemplate")
factionCB:SetSize(20, 20)
factionCB:SetPoint("LEFT", filterLabel, "RIGHT", 18, 0)

local factionLabel = factionCB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
factionLabel:SetPoint("LEFT", factionCB, "RIGHT", 4, 0)
factionLabel:SetText(A.T and A.T.show_other_faction or "Show other faction")
UI.factionLabel = factionLabel

factionCB:SetScript("OnClick", function(self)
  local checked = self:GetChecked() and true or false
  if AllPortalDB then AllPortalDB.showOtherFaction = checked end
  if UI.BuildCategoryList then UI:BuildCategoryList() end
  if UI.Refresh then UI:Refresh() end
end)

UI.factionCheckbox = factionCB

local function PickupMacroButton(name, icon, body)
  if InCombatLockdown() then return end
  local index = GetMacroIndexByName and GetMacroIndexByName(name) or 0
  if index and index > 0 then
    EditMacro(index, name, icon, body, 1)
    PickupMacro(index)
    return
  end

  local ok, macroIndex = pcall(CreateMacro, name, icon, body, 1)
  if ok and macroIndex then
    PickupMacro(macroIndex)
  else
    print("|cffff0000AllPortal:|r Could not create action bar macro.")
  end
end

local function NormalizeRandomHearthMacro()
  if InCombatLockdown() or not GetMacroIndexByName or not GetMacroInfo or not EditMacro then return end

  local currentIndex = GetMacroIndexByName(RANDOM_HEARTH_MACRO_NAME)
  if currentIndex and currentIndex > 0 then
    EditMacro(currentIndex, RANDOM_HEARTH_MACRO_NAME, RANDOM_HEARTH_ICON, GetRandomHearthMacroBody(UI.randomHearthButton and UI.randomHearthButton._cooldownEntry), 1)
    return
  end

  local legacyIndex = GetMacroIndexByName(RANDOM_HEARTH_LEGACY_MACRO_NAME)
  if not legacyIndex or legacyIndex <= 0 then return end

  local _, _, legacyBody = GetMacroInfo(legacyIndex)
  if legacyBody and string.find(legacyBody, "AllPortalRandomHearthActionButton", 1, true) then
    EditMacro(legacyIndex, RANDOM_HEARTH_MACRO_NAME, RANDOM_HEARTH_ICON, GetRandomHearthMacroBody(UI.randomHearthButton and UI.randomHearthButton._cooldownEntry), 1)
  end
end

local function CreateHeaderActionButton(name, icon, macroText, tooltipText, dragName, dragMacroText, dragIcon, tooltipLines)
  local btn = CreateFrame("Button", name, frame, "SecureActionButtonTemplate")
  btn:SetSize(34, 34)
  btn:RegisterForClicks("AnyUp")
  btn:RegisterForDrag("LeftButton")
  btn:SetAttribute("type", "macro")
  btn:SetAttribute("macrotext", macroText)

  btn.icon = btn:CreateTexture(nil, "ARTWORK")
  btn.icon:SetSize(30, 30)
  btn.icon:SetPoint("CENTER")
  btn.icon:SetTexture(icon)
  btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  ApplyIconButtonFeedback(btn, btn.icon)

  btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
  btn.cooldown:SetAllPoints(btn.icon)
  if btn.cooldown.SetDrawEdge then btn.cooldown:SetDrawEdge(false) end

  btn.cdText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  btn.cdText:SetPoint("CENTER", btn.icon, "CENTER")
  btn.cdText:SetTextColor(1, 1, 0)
  btn.cdText:SetText("")

  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(tooltipText)
    for _, line in ipairs(tooltipLines or {}) do
      GameTooltip:AddLine(line, 0.85, 0.85, 0.85, true)
    end
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", GameTooltip_Hide)
  btn:SetScript("OnDragStart", function()
    PickupMacroButton(dragName, dragIcon or icon, dragMacroText or macroText)
  end)

  return btn
end

local openButton = CreateHeaderActionButton(
  "AllPortalOpenActionButton",
  OPEN_UI_ICON,
  "/run AllPortal.ToggleUI()",
  A.T and A.T.open_ui or "Open UI",
  "AllPortal",
  "/allportal",
  OPEN_UI_ICON,
  {
    A.T and A.T.open_ui_tip or "Click to open or close the AllPortal window.",
    A.T and A.T.actionbar_drag_tip or "Drag to an action bar to use it there.",
  }
)
openButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -30)
openButton:SetAttribute("type", nil)
openButton:SetAttribute("macrotext", nil)
openButton:SetScript("OnClick", function()
  AllPortal.ToggleUI()
end)
UI.openButton = openButton

local randomHearthButton = CreateHeaderActionButton(
  "AllPortalRandomHearthLauncherButton",
  RANDOM_HEARTH_ICON,
  GetRandomHearthMacroBody(),
  A.T and A.T.hearth_random or "Random Hearth",
  RANDOM_HEARTH_MACRO_NAME,
  GetRandomHearthMacroBody(),
  RANDOM_HEARTH_ICON,
  {
    A.T and A.T.hearth_random_tip or "Uses one of your favorite hearthstones at random.",
    A.T and A.T.actionbar_drag_tip or "Drag to an action bar to use it there.",
  }
)
randomHearthButton:SetPoint("RIGHT", openButton, "LEFT", -2, 0)
UI.randomHearthButton = randomHearthButton

local randomHearthExecuteButton = CreateFrame("Button", RANDOM_HEARTH_ACTION_BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
randomHearthExecuteButton:SetSize(1, 1)
randomHearthExecuteButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -100, -100)
randomHearthExecuteButton:SetAlpha(0)
randomHearthExecuteButton:Show()
randomHearthExecuteButton.displayButton = randomHearthButton
UI.randomHearthExecuteButton = randomHearthExecuteButton

local function ClearRandomHearthButton(btn)
  local display = btn.displayButton or btn
  btn:SetAttribute("type", nil)
  btn:SetAttribute("typerelease", nil)
  btn:SetAttribute("toy", nil)
  btn:SetAttribute("item", nil)
  btn._cooldownEntry = nil
  display._cooldownEntry = nil
  if display.cooldown then display.cooldown:Clear() end
  if display.cdText then display.cdText:SetText("") end
end

local function PrepareRandomHearthButton(btn)
  local display = btn.displayButton or btn
  local T = A.T or {}
  local candidates = A.data.GetUsableFavoriteHearthstones and A.data.GetUsableFavoriteHearthstones() or {}
  local hasFavorites = A.data.HasHearthFavorites and A.data.HasHearthFavorites()
  if #candidates == 0 and not hasFavorites and A.data.GetUsableHearthstoneToys then
    candidates = A.data.GetUsableHearthstoneToys()
  end

  local entry = nil
  if #candidates > 0 then
    entry = candidates[math.random(#candidates)]
  elseif not hasFavorites then
    local base = A.data.GetBaseHearthstone and A.data.GetBaseHearthstone()
    if base and A.data.IsEntryOwned(base) then
      entry = base
    end
  end

  if not entry then
    ClearRandomHearthButton(btn)
    print("|cff00ff00AllPortal:|r " .. (T.hearth_no_fav or "No usable hearthstone items."))
    return
  end

  if entry.type == "toy" then
    btn:SetAttribute("type", "toy")
    btn:SetAttribute("typerelease", "toy")
    btn:SetAttribute("toy", A.data.GetEntryActionName and A.data.GetEntryActionName(entry) or A.data.GetEntryName(entry))
    btn:SetAttribute("item", nil)
  elseif entry.type == "item" then
    btn:SetAttribute("type", "item")
    btn:SetAttribute("typerelease", "item")
    btn:SetAttribute("item", "item:" .. entry.id)
    btn:SetAttribute("toy", nil)
  else
    btn:SetAttribute("type", nil)
    btn:SetAttribute("typerelease", nil)
    btn:SetAttribute("toy", nil)
    btn:SetAttribute("item", nil)
  end

  local icon = A.data.GetEntryIcon and A.data.GetEntryIcon(entry)
  if icon and display.icon then display.icon:SetTexture(icon) end
  btn._cooldownEntry = entry
  display._cooldownEntry = entry
  if not InCombatLockdown() and GetMacroIndexByName and EditMacro then
    local macroIndex = GetMacroIndexByName(RANDOM_HEARTH_MACRO_NAME)
    if macroIndex and macroIndex > 0 then
      EditMacro(macroIndex, RANDOM_HEARTH_MACRO_NAME, RANDOM_HEARTH_ICON, GetRandomHearthMacroBody(entry), 1)
    end
  end
  if not InCombatLockdown() then
    randomHearthButton:SetAttribute("macrotext", GetRandomHearthMacroBody(entry))
  end
  if UI.UpdateRandomHearthCooldown then UI:UpdateRandomHearthCooldown() end
end

randomHearthExecuteButton:SetAttribute("type", nil)
randomHearthExecuteButton:SetAttribute("macrotext", nil)
randomHearthExecuteButton:RegisterForClicks("AnyDown")
randomHearthExecuteButton:SetAttribute("pressAndHoldAction", true)
randomHearthExecuteButton:SetScript("PreClick", function(self)
  PrepareRandomHearthButton(self)
end)
randomHearthExecuteButton:SetScript("PostClick", function()
  if UI.UpdateRandomHearthCooldown then UI:UpdateRandomHearthCooldown() end
end)
randomHearthButton:SetScript("OnDragStart", function()
  PickupMacroButton(RANDOM_HEARTH_MACRO_NAME, RANDOM_HEARTH_ICON, GetRandomHearthMacroBody(randomHearthButton._cooldownEntry))
end)

function UI:RestoreFilterCheckbox()
  if AllPortalDB and AllPortalDB.showUnavailable then
    filterCB:SetChecked(true)
  else
    filterCB:SetChecked(false)
  end
  if AllPortalDB and AllPortalDB.showOtherFaction then
    factionCB:SetChecked(true)
  else
    factionCB:SetChecked(false)
  end
end

-- ============================================================
-- Left panel: category list
-- ============================================================
local LEFT_W = 220
local CAT_BTN_H = 28

local leftPanel = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
leftPanel:SetPoint("TOPLEFT", 8, -72)
leftPanel:SetPoint("BOTTOMLEFT", 8, 8)
leftPanel:SetWidth(LEFT_W)
UI.leftPanel = leftPanel

local leftScrollFrame = CreateFrame("ScrollFrame", "AllPortalCategoryScroll", leftPanel, "UIPanelScrollFrameTemplate")
leftScrollFrame:SetPoint("TOPLEFT", 4, -4)
leftScrollFrame:SetPoint("BOTTOMRIGHT", -26, 4)

local leftChild = CreateFrame("Frame", nil, leftScrollFrame)
leftChild:SetSize(LEFT_W - 34, 1)
leftScrollFrame:SetScrollChild(leftChild)
UI.leftScrollFrame = leftScrollFrame
UI.leftChild = leftChild

local catButtons = {}
UI.catButtons = catButtons

local separators = {}

function UI:BuildCategoryList()
  local visibleIndex = 0
  for catIdx, cat in ipairs(A.data.categories) do
    local visible = A.data.IsCategoryVisible(cat)

    local btn = catButtons[catIdx]
    if visible then
      visibleIndex = visibleIndex + 1
      if not btn then
        btn = CreateFrame("Button", nil, leftChild)
        btn:SetSize(LEFT_W - 42, CAT_BTN_H)
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", 8, 0)
        label:SetPoint("RIGHT", -8, 0)
        label:SetJustifyH("LEFT")
        btn.label = label

        local highlight = btn:CreateTexture(nil, "BACKGROUND")
        highlight:SetAllPoints(true)
        highlight:SetColorTexture(1, 0.5, 0, 0.35)
        highlight:Hide()
        btn.highlight = highlight

        btn:SetScript("OnEnter", function(self)
          if not self.selected then self.highlight:SetColorTexture(1, 1, 1, 0.1); self.highlight:Show() end
        end)
        btn:SetScript("OnLeave", function(self)
          if not self.selected then self.highlight:Hide() end
        end)
        btn:SetScript("OnClick", function(self)
          UI:SelectCategory(self.catId)
        end)

        catButtons[catIdx] = btn
      end

      btn.catId = cat.id
      btn.label:SetText(A.T and A.T[cat.labelKey] or cat.id)
      btn:ClearAllPoints()
      btn:SetPoint("TOPLEFT", 4, -((visibleIndex - 1) * (CAT_BTN_H + 2)) - 4)
      btn:Show()

      if catIdx == A.data.SEPARATOR_AFTER_INDEX then
        local sep = separators[catIdx] or leftChild:CreateTexture(nil, "ARTWORK")
        sep:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
        sep:SetHeight(8)
        sep:ClearAllPoints()
        sep:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
        sep:SetPoint("RIGHT", btn, "RIGHT")
        sep:Show()
        separators[catIdx] = sep
        visibleIndex = visibleIndex + 0.4
      end
    else
      if btn then btn:Hide() end
      if separators[catIdx] then separators[catIdx]:Hide() end
    end
  end
  leftChild:SetHeight(math.max(1, visibleIndex * (CAT_BTN_H + 2) + 8))
end

function UI:HighlightCategory(catId)
  for _, btn in pairs(catButtons) do
    if btn.catId == catId then
      btn.selected = true
      btn.highlight:SetColorTexture(1, 0.5, 0, 0.35)
      btn.highlight:Show()
    else
      btn.selected = false
      btn.highlight:Hide()
    end
  end
end

-- ============================================================
-- Right panel: scrollable grid
-- ============================================================
local RIGHT_PADDING_L = 8
local BTN_W = 160
local BTN_H = 36
local ICON_SIZE = 32
local BTN_SPACING = 6
local GROUP_GAP = 0
local NAME_BG = { 0.08, 0.10, 0.12, 0.94 }
local NAME_BG_HOVER = { 0.12, 0.15, 0.17, 0.96 }
local NAME_BG_OTHER_FACTION = { 0.18, 0.08, 0.08, 0.94 }
local NAME_BG_OTHER_FACTION_HOVER = { 0.24, 0.10, 0.10, 0.96 }
local NAME_TEXT = { 0.88, 0.84, 0.72 }
local NAME_TEXT_DISABLED = { 0.48, 0.48, 0.48 }
local NAME_TEXT_OTHER_FACTION = { 0.82, 0.64, 0.58 }

local rightPanel = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 4, 0)
rightPanel:SetPoint("BOTTOMRIGHT", -8, 8)
UI.rightPanel = rightPanel

local RefreshHearthPanel
local ApplyHearthFavoriteSelection
local hearthRows = {}
local hearthEntries = {}
local hearthOffset = 0
local hearthSearchText = ""
local hearthVisibleCols = 1
local UpdateHearthBulkLabels

local scrollFrame = CreateFrame("ScrollFrame", "AllPortalScroll", rightPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 4, -4)
scrollFrame:SetPoint("BOTTOMRIGHT", -28, 4)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(1, 1)
scrollFrame:SetScrollChild(scrollChild)
UI.scrollFrame = scrollFrame
UI.scrollChild = scrollChild

local emptyLabel = rightPanel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
emptyLabel:SetPoint("CENTER", rightPanel, "CENTER", -10, 0)
emptyLabel:SetJustifyH("CENTER")
emptyLabel:SetText("")
emptyLabel:Hide()
UI.emptyLabel = emptyLabel

local hearthPanel = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
hearthPanel:SetPoint("TOPLEFT", 4, -4)
hearthPanel:SetPoint("BOTTOMRIGHT", -8, 4)
hearthPanel:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
hearthPanel:SetBackdropColor(0.02, 0.02, 0.02, 0.82)
hearthPanel:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.85)
hearthPanel:SetFrameLevel(rightPanel:GetFrameLevel() + 8)
hearthPanel:Hide()
UI.hearthPanel = hearthPanel

local hearthTitle = hearthPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hearthTitle:SetPoint("TOPLEFT", 10, -10)
hearthTitle:SetPoint("RIGHT", -10, 0)
hearthTitle:SetJustifyH("LEFT")
hearthTitle:SetText(A.T and A.T.hearthstones or "Hearthstones")

local hearthText = hearthPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
hearthText:SetPoint("TOPLEFT", hearthTitle, "BOTTOMLEFT", 0, -8)
hearthText:SetPoint("RIGHT", -10, 0)
hearthText:SetJustifyH("LEFT")
hearthText:SetText(A.T and A.T.hearth_hint or "")
hearthText:SetHeight(34)

local hearthSearchSlot = CreateFrame("Frame", nil, hearthPanel, "BackdropTemplate")
hearthSearchSlot:SetPoint("TOPLEFT", hearthText, "BOTTOMLEFT", 0, -8)
hearthSearchSlot:SetPoint("RIGHT", -10, 0)
hearthSearchSlot:SetHeight(24)
hearthSearchSlot:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 },
})
hearthSearchSlot:SetBackdropColor(0.02, 0.06, 0.08, 0.65)
hearthSearchSlot:SetBackdropBorderColor(0.32, 0.52, 0.58, 0.7)

local hearthSearchBox = CreateFrame("EditBox", nil, hearthSearchSlot, "InputBoxTemplate")
hearthSearchBox:SetAutoFocus(false)
hearthSearchBox:SetPoint("LEFT", 24, 0)
hearthSearchBox:SetPoint("RIGHT", -112, 0)
hearthSearchBox:SetHeight(20)
hearthSearchBox:SetFontObject("GameFontHighlightSmall")
hearthSearchBox:SetTextColor(1, 1, 1, 1)
hearthSearchBox:SetScript("OnEscapePressed", function(self)
  self:ClearFocus()
end)
hearthSearchBox:SetScript("OnEnterPressed", function(self)
  hearthSearchText = strtrim(self:GetText() or "")
  hearthOffset = 0
  if UpdateHearthBulkLabels then UpdateHearthBulkLabels() end
  if RefreshHearthPanel then RefreshHearthPanel() end
  self:ClearFocus()
end)
hearthSearchBox:SetScript("OnTextChanged", function(self, userInput)
  if not userInput then return end
  hearthSearchText = strtrim(self:GetText() or "")
  hearthOffset = 0
  if UpdateHearthBulkLabels then UpdateHearthBulkLabels() end
  if RefreshHearthPanel then RefreshHearthPanel() end
end)
UI.hearthSearchBox = hearthSearchBox

local hearthSearchPlaceholder = hearthSearchSlot:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
hearthSearchPlaceholder:SetPoint("LEFT", hearthSearchBox, "LEFT", 2, 0)
hearthSearchPlaceholder:SetText(A.T and A.T.search_placeholder or "Search")
hearthSearchPlaceholder:SetJustifyH("LEFT")
hearthSearchBox:SetScript("OnEditFocusGained", function()
  hearthSearchPlaceholder:Hide()
end)
hearthSearchBox:SetScript("OnEditFocusLost", function(self)
  if (self:GetText() or "") == "" then hearthSearchPlaceholder:Show() end
end)
hearthSearchBox:HookScript("OnTextChanged", function(self)
  if (self:GetText() or "") == "" and not self:HasFocus() then
    hearthSearchPlaceholder:Show()
  else
    hearthSearchPlaceholder:Hide()
  end
end)

local hearthSearchIcon = hearthSearchSlot:CreateTexture(nil, "ARTWORK")
hearthSearchIcon:SetSize(14, 14)
hearthSearchIcon:SetPoint("LEFT", 7, 0)
hearthSearchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
hearthSearchIcon:SetVertexColor(0.8, 0.8, 0.8, 0.9)

local hearthClearSearchButton = CreateFrame("Button", nil, hearthSearchSlot, "UIPanelButtonTemplate")
hearthClearSearchButton:SetPoint("RIGHT", -2, 0)
hearthClearSearchButton:SetSize(24, 20)
hearthClearSearchButton:SetText("X")
hearthClearSearchButton:SetScript("OnClick", function()
  hearthSearchBox:SetText("")
  hearthSearchText = ""
  hearthOffset = 0
  if UpdateHearthBulkLabels then UpdateHearthBulkLabels() end
  if RefreshHearthPanel then RefreshHearthPanel() end
  hearthSearchBox:ClearFocus()
end)
hearthClearSearchButton:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(A.T and A.T.clear_search or "Clear Search")
  GameTooltip:Show()
end)
hearthClearSearchButton:SetScript("OnLeave", GameTooltip_Hide)

local hearthSearchButton = CreateFrame("Button", nil, hearthSearchSlot, "UIPanelButtonTemplate")
hearthSearchButton:SetPoint("RIGHT", hearthClearSearchButton, "LEFT", -4, 0)
hearthSearchButton:SetSize(74, 20)
hearthSearchButton:SetText(A.T and A.T.search or "Search")
hearthSearchButton:SetScript("OnClick", function()
  hearthSearchText = strtrim(hearthSearchBox:GetText() or "")
  hearthOffset = 0
  if UpdateHearthBulkLabels then UpdateHearthBulkLabels() end
  if RefreshHearthPanel then RefreshHearthPanel() end
  hearthSearchBox:ClearFocus()
end)

local hearthBulkFrame = CreateFrame("Frame", nil, hearthPanel)
hearthBulkFrame:SetPoint("TOPLEFT", hearthSearchSlot, "BOTTOMLEFT", 0, -6)
hearthBulkFrame:SetPoint("RIGHT", -10, 0)
hearthBulkFrame:SetHeight(22)

local hearthSelectAllButton = CreateFrame("Button", nil, hearthBulkFrame, "UIPanelButtonTemplate")
hearthSelectAllButton:SetPoint("LEFT", 0, 0)
hearthSelectAllButton:SetSize(96, 20)
hearthSelectAllButton:SetText(A.T and A.T.select_all or "Select All")
hearthSelectAllButton:SetScript("OnClick", function()
  if ApplyHearthFavoriteSelection then ApplyHearthFavoriteSelection(true) end
end)

UpdateHearthBulkLabels = function()
  local hasSearch = strtrim(hearthSearchText or "") ~= ""
  hearthSelectAllButton:SetText(hasSearch and (A.T and A.T.select_results or "Select Results") or (A.T and A.T.select_all or "Select All"))
end
UpdateHearthBulkLabels()

local hearthClearAllButton = CreateFrame("Button", nil, hearthBulkFrame, "UIPanelButtonTemplate")
hearthClearAllButton:SetPoint("LEFT", hearthSelectAllButton, "RIGHT", 6, 0)
hearthClearAllButton:SetSize(96, 20)
hearthClearAllButton:SetText(A.T and A.T.clear_all or "Clear All")
hearthClearAllButton:SetScript("OnClick", function()
  if ApplyHearthFavoriteSelection then ApplyHearthFavoriteSelection(false) end
end)

local hearthListFrame = CreateFrame("Frame", nil, hearthPanel)
hearthListFrame:SetPoint("TOPLEFT", hearthBulkFrame, "BOTTOMLEFT", 0, -8)
hearthListFrame:SetPoint("BOTTOMRIGHT", hearthPanel, "BOTTOMRIGHT", -10, 8)
hearthListFrame:EnableMouseWheel(true)
UI.hearthListFrame = hearthListFrame

local hearthEmptyLabel = hearthListFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
hearthEmptyLabel:SetPoint("CENTER", hearthListFrame, "CENTER", 0, 0)
hearthEmptyLabel:SetJustifyH("CENTER")
hearthEmptyLabel:Hide()

-- ============================================================
-- Secure action button factory
-- ============================================================
local function FormatCooldown(remain)
  if remain >= 3600 then
    return string.format("%dh", math.floor(remain / 3600))
  elseif remain >= 60 then
    return string.format("%dm", math.floor(remain / 60))
  elseif remain >= 1 then
    return string.format("%ds", math.floor(remain))
  else
    return ""
  end
end

local function ApplySpellAttributes(btn, spell)
  btn:SetAttribute("type", "spell")
  btn:SetAttribute("spell", spell.id)
end

local function ApplyHouseAttributes(btn, entry)
  local house = A.data.housesByZone and A.data.housesByZone[entry.zoneId]
  if house then
    btn:SetAttribute("type", "teleporthome")
    btn:SetAttribute("house-neighborhood-guid", house.neighborhoodGUID)
    btn:SetAttribute("house-guid", house.houseGUID)
    btn:SetAttribute("house-plot-id", house.plotID)
    btn:SetAttribute("macrotext", nil)
  else
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macrotext", "/script print(\"AllPortal: House is not available.\")")
    btn:SetAttribute("house-neighborhood-guid", nil)
    btn:SetAttribute("house-guid", nil)
    btn:SetAttribute("house-plot-id", nil)
  end
end

local function CreateIconFrame(parent, x)
  local iconFrame = CreateFrame("Frame", nil, parent)
  iconFrame:SetSize(ICON_SIZE, ICON_SIZE)
  iconFrame:SetPoint("LEFT", x, 0)

  iconFrame.icon = iconFrame:CreateTexture(nil, "ARTWORK")
  iconFrame.icon:SetSize(ICON_SIZE, ICON_SIZE)
  iconFrame.icon:SetPoint("CENTER")
  iconFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  return iconFrame
end

local function CreateSpellPairButton(parent, entry)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(BTN_W, BTN_H)
  row.entry = entry
  row.actionButtons = {}

  local labelLeft = ICON_SIZE * 2 + 16

  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetColorTexture(NAME_BG[1], NAME_BG[2], NAME_BG[3], NAME_BG[4])
  row.bg:SetPoint("TOPLEFT", labelLeft - 4, 0)
  row.bg:SetPoint("BOTTOMRIGHT", 0, 0)

  row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.label:SetPoint("LEFT", row, "LEFT", labelLeft, 0)
  row.label:SetPoint("RIGHT", -8, 0)
  row.label:SetJustifyH("LEFT")
  row.label:SetTextColor(NAME_TEXT[1], NAME_TEXT[2], NAME_TEXT[3])
  row.label:SetText(A.data.GetEntryDisplayName(entry))

  for i, spell in ipairs(entry.spells or {}) do
    if i > 2 then break end
    local iconFrame = CreateIconFrame(row, 2 + (i - 1) * (ICON_SIZE + 4))
    iconFrame.icon:SetTexture(A.data.GetEntryIcon(spell) or "Interface\\Icons\\INV_Misc_QuestionMark")

    local btn = CreateFrame("Button", nil, iconFrame, "SecureActionButtonTemplate")
    btn:SetAllPoints(iconFrame)
    btn:RegisterForClicks("AnyDown", "AnyUp")
    btn.entry = spell
    btn.icon = iconFrame.icon
    ApplySpellAttributes(btn, spell)

    ApplyIconButtonFeedback(btn, iconFrame.icon)

    btn.cooldown = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
    btn.cooldown:SetAllPoints(iconFrame)
    if btn.cooldown.SetDrawEdge then btn.cooldown:SetDrawEdge(false) end

    btn.cdText = iconFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    btn.cdText:SetPoint("CENTER")
    btn.cdText:SetTextColor(1, 1, 0)
    btn.cdText:SetText("")

    btn:SetScript("OnEnter", function(self)
      local hover = row._bgHoverColor or NAME_BG_HOVER
      row.bg:SetColorTexture(hover[1], hover[2], hover[3], hover[4])
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetSpellByID(spell.id)
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
      local bg = row._bgColor or NAME_BG
      row.bg:SetColorTexture(bg[1], bg[2], bg[3], bg[4])
      GameTooltip_Hide()
    end)

    tinsert(row.actionButtons, btn)
  end

  return row
end

local function SetIconUsable(icon, usable)
  if icon.SetDesaturated then icon:SetDesaturated(not usable) end
  if usable then
    icon:SetVertexColor(1, 1, 1, 1)
  else
    icon:SetVertexColor(0.45, 0.45, 0.45, 1)
  end
end

local function UpdateEntryVisualState(btn)
  local otherFaction = A.data.IsOtherFactionEntry and A.data.IsOtherFactionEntry(btn.entry)

  if btn.bg then
    if otherFaction then
      btn.bg:SetColorTexture(NAME_BG_OTHER_FACTION[1], NAME_BG_OTHER_FACTION[2], NAME_BG_OTHER_FACTION[3], NAME_BG_OTHER_FACTION[4])
      btn._bgColor = NAME_BG_OTHER_FACTION
      btn._bgHoverColor = NAME_BG_OTHER_FACTION_HOVER
    else
      btn.bg:SetColorTexture(NAME_BG[1], NAME_BG[2], NAME_BG[3], NAME_BG[4])
      btn._bgColor = NAME_BG
      btn._bgHoverColor = NAME_BG_HOVER
    end
  end

  if btn.actionButtons then
    local anyUsable = false
    for _, actionBtn in ipairs(btn.actionButtons) do
      local usable = A.data.IsEntryOwned(actionBtn.entry)
      anyUsable = anyUsable or usable
      SetIconUsable(actionBtn.icon, usable)
    end
    if anyUsable then
      if otherFaction then
        btn.label:SetTextColor(NAME_TEXT_OTHER_FACTION[1], NAME_TEXT_OTHER_FACTION[2], NAME_TEXT_OTHER_FACTION[3])
      else
        btn.label:SetTextColor(NAME_TEXT[1], NAME_TEXT[2], NAME_TEXT[3])
      end
    else
      btn.label:SetTextColor(NAME_TEXT_DISABLED[1], NAME_TEXT_DISABLED[2], NAME_TEXT_DISABLED[3])
    end
    return
  end

  local usable = A.data.IsEntryOwned(btn.entry)
  if btn.entry and btn.entry.type == "house" and not InCombatLockdown() then
    ApplyHouseAttributes(btn, btn.entry)
  end
  SetIconUsable(btn.icon, usable)
  if usable then
    if otherFaction then
      btn.label:SetTextColor(NAME_TEXT_OTHER_FACTION[1], NAME_TEXT_OTHER_FACTION[2], NAME_TEXT_OTHER_FACTION[3])
    else
      btn.label:SetTextColor(NAME_TEXT[1], NAME_TEXT[2], NAME_TEXT[3])
    end
  else
    btn.label:SetTextColor(NAME_TEXT_DISABLED[1], NAME_TEXT_DISABLED[2], NAME_TEXT_DISABLED[3])
  end
end
UI._UpdateEntryVisualState = UpdateEntryVisualState

local function CreateActionButton(parent, entry)
  if entry.type == "spellPair" then
    return CreateSpellPairButton(parent, entry)
  end

  local btn = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
  btn:SetSize(BTN_W, BTN_H)
  btn:RegisterForClicks("AnyDown", "AnyUp")
  btn.entry = entry

  if entry.type == "spell" then
    ApplySpellAttributes(btn, entry)
  elseif entry.type == "toy" then
    btn:SetAttribute("type", "toy")
    btn:SetAttribute("toy", entry.id)
  elseif entry.type == "item" then
    btn:SetAttribute("type", "item")
    btn:SetAttribute("item", "item:" .. entry.id)
  elseif entry.type == "house" then
    ApplyHouseAttributes(btn, entry)
  end

  btn.bg = btn:CreateTexture(nil, "BACKGROUND")
  btn.bg:SetColorTexture(NAME_BG[1], NAME_BG[2], NAME_BG[3], NAME_BG[4])
  btn.bg:SetPoint("TOPLEFT", ICON_SIZE + 8, 0)
  btn.bg:SetPoint("BOTTOMRIGHT", 0, 0)

  btn.iconFrame = CreateFrame("Frame", nil, btn)
  btn.iconFrame:SetSize(ICON_SIZE, ICON_SIZE)
  btn.iconFrame:SetPoint("LEFT", 2, 0)

  btn.icon = btn.iconFrame:CreateTexture(nil, "ARTWORK")
  btn.icon:SetSize(ICON_SIZE, ICON_SIZE)
  btn.icon:SetPoint("CENTER")
  btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  btn.icon:SetTexture(A.data.GetEntryIcon(entry) or "Interface\\Icons\\INV_Misc_QuestionMark")

  ApplyIconButtonFeedback(btn, btn.icon)

  btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  btn.label:SetPoint("LEFT", btn.iconFrame, "RIGHT", 10, 0)
  btn.label:SetPoint("RIGHT", -8, 0)
  btn.label:SetJustifyH("LEFT")
  btn.label:SetTextColor(NAME_TEXT[1], NAME_TEXT[2], NAME_TEXT[3])
  btn.label:SetText(A.data.GetEntryDisplayName(entry))

  btn.cooldown = CreateFrame("Cooldown", nil, btn.iconFrame, "CooldownFrameTemplate")
  btn.cooldown:SetAllPoints(btn.iconFrame)
  if btn.cooldown.SetDrawEdge then btn.cooldown:SetDrawEdge(false) end

  btn.cdText = btn.iconFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  btn.cdText:SetPoint("CENTER")
  btn.cdText:SetTextColor(1, 1, 0)
  btn.cdText:SetText("")

  btn:SetScript("OnEnter", function(self)
    local hover = self._bgHoverColor or NAME_BG_HOVER
    self.bg:SetColorTexture(hover[1], hover[2], hover[3], hover[4])
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if entry.type == "spell" or entry.type == "house" then
      GameTooltip:SetSpellByID(entry.id)
    elseif entry.type == "toy" then
      GameTooltip:SetToyByItemID(entry.id)
    elseif entry.type == "item" then
      GameTooltip:SetItemByID(entry.id)
    end
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function(self)
    local bg = self._bgColor or NAME_BG
    self.bg:SetColorTexture(bg[1], bg[2], bg[3], bg[4])
    GameTooltip_Hide()
  end)

  return btn
end

UI._CreateActionButton = CreateActionButton
UI._FormatCooldown = FormatCooldown

local pool

local function RefreshButtonLabel(btn)
  if not btn or not btn.entry then return end
  if btn.label then
    btn.label:SetText(A.data.GetEntryDisplayName(btn.entry))
  end
  if btn.icon then
    local tex = A.data.GetEntryIcon(btn.entry)
    if tex then btn.icon:SetTexture(tex) end
  end
  if btn.actionButtons and btn.label then
    btn.label:SetText(A.data.GetEntryDisplayName(btn.entry))
    for _, actionBtn in ipairs(btn.actionButtons) do
      if actionBtn.icon then
        local tex = A.data.GetEntryIcon(actionBtn.entry)
        if tex then actionBtn.icon:SetTexture(tex) end
      end
    end
  end
end

function UI:RefreshLabels()
  if A.data.RequestEntryNames then
    A.data.RequestEntryNames()
  end

  for _, btn in pairs(pool or {}) do
    RefreshButtonLabel(btn)
  end

  for _, item in ipairs(self._visibleButtons or {}) do
    RefreshButtonLabel(item.btn)
    if self._UpdateEntryVisualState then
      self._UpdateEntryVisualState(item.btn)
    end
  end

  for _, row in pairs(hearthRows or {}) do
    if row.actionButton then
      RefreshButtonLabel(row.actionButton)
      if self._UpdateEntryVisualState then
        self._UpdateEntryVisualState(row.actionButton)
      end
    end
  end

  if self.currentCategoryId == "hearthstones" and RefreshHearthPanel then
    RefreshHearthPanel()
  end
end

function UI:ScheduleNameRefresh()
  self:RefreshLabels()
  if C_Timer and C_Timer.After then
    C_Timer.After(0.5, function()
      if UI.frame and UI.frame:IsShown() then UI:RefreshLabels() end
    end)
    C_Timer.After(2, function()
      if UI.frame and UI.frame:IsShown() then UI:RefreshLabels() end
    end)
  end
end

local HEARTH_ROW_H = 42
local HEARTH_ROW_GAP = 2

local function CreateHearthActionEntry(entry)
  local actionEntry = {}
  for k, v in pairs(entry) do
    if k ~= "hearthstone" then
      actionEntry[k] = v
    end
  end
  return actionEntry
end

local function CreateHearthRow(parent, entry)
  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(HEARTH_ROW_H)
  row:EnableMouse(true)
  row:SetFrameLevel(parent:GetFrameLevel() + 5)
  row.entry = entry

  row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
  row.check:SetSize(30, 30)
  row.check:SetPoint("LEFT", row, "LEFT", 6, 0)
  row.check:SetFrameLevel(row:GetFrameLevel() + 8)
  row.check:RegisterForClicks("LeftButtonUp")
  row.check.owner = row

  row.actionButton = CreateActionButton(row, CreateHearthActionEntry(entry))
  if A.data.IsBaseHearthstone and A.data.IsBaseHearthstone(entry) then
    row.check:Hide()
    row.actionButton:SetPoint("LEFT", row, "LEFT", 44, 0)
  else
    row.actionButton:SetPoint("LEFT", row.check, "RIGHT", 8, 0)
  end
  row.actionButton:SetFrameLevel(row:GetFrameLevel() + 2)

  row.check:SetScript("OnEnter", function(self)
    local actionButton = self.owner.actionButton
    if actionButton and actionButton.bg then
      actionButton.bg:SetColorTexture(NAME_BG_HOVER[1], NAME_BG_HOVER[2], NAME_BG_HOVER[3], NAME_BG_HOVER[4])
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(A.T and A.T.hearth_hint or "Click to favorite.")
    GameTooltip:Show()
  end)
  row.check:SetScript("OnLeave", function(self)
    local actionButton = self.owner.actionButton
    if actionButton and actionButton.bg then
      actionButton.bg:SetColorTexture(NAME_BG[1], NAME_BG[2], NAME_BG[3], NAME_BG[4])
    end
    GameTooltip_Hide()
  end)
  row.check:SetScript("OnClick", function(self)
    local result = A.data.ToggleHearthFavorite and A.data.ToggleHearthFavorite(self.owner.entry)
    if result == nil then return end
    self:SetChecked(result)
    RefreshHearthPanel()
    if result then
      print("|cff00ff00AllPortal:|r " .. (A.T and A.T.hearth_fav_added or "Added to random hearth favorites."))
    else
      print("|cff00ff00AllPortal:|r " .. (A.T and A.T.hearth_fav_removed or "Removed from random hearth favorites."))
    end
    if UI.randomHearthExecuteButton then
      PrepareRandomHearthButton(UI.randomHearthExecuteButton)
    end
  end)

  return row
end

local function HearthEntryMatchesSearch(entry)
  local query = strtrim(hearthSearchText or "")
  if query == "" then return true end

  local name = A.data.GetEntryActionName and A.data.GetEntryActionName(entry) or A.data.GetEntryName(entry)
  if not name then return false end

  return string.find(string.lower(name), string.lower(query), 1, true) ~= nil
end

ApplyHearthFavoriteSelection = function(checked)
  AllPortalDB = AllPortalDB or {}
  AllPortalDB.hearthFavorites = AllPortalDB.hearthFavorites or {}

  for entry in A.data.IterEntries("hearthstones") do
    if A.data.IsEntryVisible(entry)
        and HearthEntryMatchesSearch(entry)
        and not (A.data.IsBaseHearthstone and A.data.IsBaseHearthstone(entry))
        and A.data.IsEntryOwned(entry) then
      local key = A.data.GetEntryKey(entry)
      if key then
        if checked then
          AllPortalDB.hearthFavorites[key] = true
        else
          AllPortalDB.hearthFavorites[key] = nil
        end
      end
    end
  end

  hearthOffset = 0
  RefreshHearthPanel()
  if UI.randomHearthExecuteButton then
    PrepareRandomHearthButton(UI.randomHearthExecuteButton)
  end
end

RefreshHearthPanel = function()
  for _, row in pairs(hearthRows) do row:Hide() end
  wipe(hearthEntries)

  local orderByKey = {}
  local order = 0
  for entry in A.data.IterEntries("hearthstones") do
    order = order + 1
    if A.data.IsEntryVisible(entry) and HearthEntryMatchesSearch(entry) then
      local key = A.data.GetEntryKey(entry)
      if key then orderByKey[key] = order end
      tinsert(hearthEntries, entry)
    end
  end

  table.sort(hearthEntries, function(a, b)
    local aBase = (A.data.IsBaseHearthstone and A.data.IsBaseHearthstone(a)) and true or false
    local bBase = (A.data.IsBaseHearthstone and A.data.IsBaseHearthstone(b)) and true or false
    if aBase ~= bBase then return aBase end

    local aOwned = A.data.IsEntryOwned(a) and true or false
    local bOwned = A.data.IsEntryOwned(b) and true or false
    if aOwned ~= bOwned then return aOwned end

    local aKey = A.data.GetEntryKey(a)
    local bKey = A.data.GetEntryKey(b)
    return (orderByKey[aKey] or 0) < (orderByKey[bKey] or 0)
  end)

  local panelW = math.max(260, (hearthPanel:GetWidth() or 0) - 24)
  local colGap = 8
  local minRowW = 210
  local cols = math.max(1, math.min(4, math.floor((panelW + colGap) / (minRowW + colGap))))
  hearthVisibleCols = cols
  local rowW = math.max(190, math.floor((panelW - (cols - 1) * colGap) / cols))
  local rowH = HEARTH_ROW_H
  local listH = math.max(rowH * 6, (hearthPanel:GetHeight() or 0) - 128)
  local visibleRows = math.max(1, math.floor((listH + HEARTH_ROW_GAP) / (rowH + HEARTH_ROW_GAP)))
  local visibleSlots = visibleRows * cols
  local maxOffset = math.max(0, #hearthEntries - visibleSlots)
  local listX = 10
  local listY = -124

  if hearthOffset > maxOffset then hearthOffset = maxOffset end
  if hearthOffset < 0 then hearthOffset = 0 end

  for displayIndex = 1, math.min(visibleSlots, #hearthEntries - hearthOffset) do
      local entryIndex = hearthOffset + displayIndex
      local entry = hearthEntries[entryIndex]
      local rowKey = A.data.GetEntryKey(entry)
      local row = hearthRows[rowKey]
      if not row then
        row = CreateHearthRow(hearthPanel, entry)
        hearthRows[rowKey] = row
      end

      local fav = A.data.IsHearthFavorite and A.data.IsHearthFavorite(entry)
      local isBase = A.data.IsBaseHearthstone and A.data.IsBaseHearthstone(entry)

      row:SetWidth(rowW)
      row.actionButton:SetWidth(math.max(146, rowW - 44))
      row:ClearAllPoints()
      local col = (displayIndex - 1) % cols
      local rowIndex = math.floor((displayIndex - 1) / cols)
      row:SetPoint("TOPLEFT", hearthPanel, "TOPLEFT", listX + col * (rowW + colGap), listY - rowIndex * (HEARTH_ROW_H + HEARTH_ROW_GAP))
      if isBase then
        row.check:Hide()
      else
        row.check:Show()
        row.check:SetChecked(fav and true or false)
      end
      UpdateEntryVisualState(row.actionButton)
      row:Show()
  end

  if #hearthEntries == 0 then
    hearthEmptyLabel:SetText((A.T and A.T.hearthstones or "Hearthstones") .. "\n" .. (A.T and A.T.empty_category or "No entries yet."))
    hearthEmptyLabel:Show()
  else
    hearthEmptyLabel:Hide()
  end
end

hearthPanel:EnableMouseWheel(true)
hearthPanel:SetScript("OnMouseWheel", function(_, delta)
  if delta > 0 then
    hearthOffset = hearthOffset - hearthVisibleCols
  else
    hearthOffset = hearthOffset + hearthVisibleCols
  end
  RefreshHearthPanel()
end)

frame:HookScript("OnSizeChanged", function()
  if UI.currentCategoryId == "hearthstones" then
    RefreshHearthPanel()
  elseif UI.RelayoutGrid then
    UI:RelayoutGrid()
  end
end)

-- ============================================================
-- Button pool (pre-created at PLAYER_LOGIN; fixed for life of session)
-- ============================================================
pool = {}
UI.pool = pool

local function ShouldCreateButton(entry)
  if entry.hearthstone then return false end
  if A.data.IsEntryVisible(entry) then return true end

  if entry.faction then
    local saved = AllPortalDB and AllPortalDB.showOtherFaction
    if AllPortalDB then AllPortalDB.showOtherFaction = true end
    local visibleWithOtherFaction = A.data.IsEntryVisible(entry)
    if AllPortalDB then AllPortalDB.showOtherFaction = saved end
    return visibleWithOtherFaction
  end

  return false
end

function UI:BuildPool()
  for _, cat in ipairs(A.data.categories) do
    for entry in A.data.IterEntries(cat.id) do
      if ShouldCreateButton(entry) then
        local btn = CreateActionButton(scrollChild, entry)
        btn:Hide()
        pool[entry] = btn
      end
    end
  end
end

function UI:Initialize()
  if self._initialized then return end
  NormalizeRandomHearthMacro()
  self:BuildPool()
  self:RestoreFromDB()
  self:RestoreFilterCheckbox()
  self:BuildCategoryList()
  if self.randomHearthExecuteButton then
    PrepareRandomHearthButton(self.randomHearthExecuteButton)
  end
  self._initialized = true
end

-- ============================================================
-- Category selection + grid layout
-- ============================================================
UI.currentCategoryId = nil
UI._visibleButtons = {}

local function ShouldShowEntry(entry)
  if not A.data.IsEntryVisible(entry) then return false end
  if AllPortalDB and AllPortalDB.showUnavailable then
    return true
  end
  return A.data.IsEntryOwned(entry)
end

local function IsHeroPathCategory(catId)
  return catId == "current_season" or (type(catId) == "string" and catId:match("^mp_"))
end

local function ApplyCategoryLayout(catId)
  local hearthMode = catId == "hearthstones"

  scrollFrame:ClearAllPoints()
  if hearthMode then
    if frame.SetResizeBounds then
      frame:SetResizeBounds(HEARTH_MIN_W, HEARTH_MIN_H, MAX_W, MAX_H)
    else
      frame:SetMinResize(HEARTH_MIN_W, HEARTH_MIN_H)
    end
    if not UI._preHearthWidth and frame:GetWidth() < HEARTH_MIN_W then
      UI._preHearthWidth = frame:GetWidth()
    end
    if not UI._preHearthHeight and frame:GetHeight() < HEARTH_MIN_H then
      UI._preHearthHeight = frame:GetHeight()
    end
    frame:SetSize(math.max(frame:GetWidth(), HEARTH_MIN_W), math.max(frame:GetHeight(), HEARTH_MIN_H))

    scrollFrame:Hide()
    hearthPanel:Show()
    RefreshHearthPanel()
    if C_Timer and C_Timer.After then
      C_Timer.After(0, RefreshHearthPanel)
    end
  else
    if frame.SetResizeBounds then
      frame:SetResizeBounds(MIN_W, MIN_H, MAX_W, MAX_H)
    else
      frame:SetMinResize(MIN_W, MIN_H)
    end
    if UI._preHearthWidth then
      frame:SetSize(UI._preHearthWidth, frame:GetHeight())
      UI._preHearthWidth = nil
    end
    if UI._preHearthHeight then
      frame:SetSize(frame:GetWidth(), UI._preHearthHeight)
      UI._preHearthHeight = nil
    end

    hearthPanel:Hide()
    scrollFrame:Show()
    scrollFrame:SetPoint("TOPLEFT", rightPanel, "TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", rightPanel, "BOTTOMRIGHT", -28, 4)
  end
end

function UI:RelayoutGrid()
  local visible = self._visibleButtons
  if #visible == 0 then
    scrollChild:SetSize(1, 1)
    return
  end

  local panelW = scrollFrame:GetWidth()
  local available = panelW - RIGHT_PADDING_L * 2
  local itemW = BTN_W
  local cols = math.max(1, math.min(5, math.floor((available + BTN_SPACING) / (itemW + BTN_SPACING))))

  local x, y = RIGHT_PADDING_L, -RIGHT_PADDING_L
  local col = 0
  local lastGroup = visible[1].groupIndex
  local maxRow = 0

  for _, item in ipairs(visible) do
    if item.groupIndex ~= lastGroup then
      if col > 0 then
        y = y - (BTN_H + BTN_SPACING)
        col = 0
      end
      y = y - GROUP_GAP
      lastGroup = item.groupIndex
    end
    if col >= cols then
      y = y - (BTN_H + BTN_SPACING)
      col = 0
    end
    item.btn:ClearAllPoints()
    item.btn:SetWidth(itemW)
    item.btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", RIGHT_PADDING_L + col * (itemW + BTN_SPACING), y)
    item.btn:Show()
    col = col + 1
    if y < maxRow then maxRow = y end
  end

  scrollChild:SetSize(panelW, math.abs(maxRow) + BTN_H + RIGHT_PADDING_L)
end

function UI:SelectCategory(catId)
  for _, item in ipairs(self._visibleButtons) do
    item.btn:Hide()
  end
  wipe(self._visibleButtons)

  self.currentCategoryId = catId
  self:HighlightCategory(catId)
  emptyLabel:Hide()
  ApplyCategoryLayout(catId)

  if AllPortalDB then AllPortalDB.lastCategory = catId end

  if catId == "hearthstones" then
    self:RelayoutGrid()
    self:UpdateCooldowns()
    self:ScheduleNameRefresh()
    return
  end

  local order = 0
  for entry, groupIdx in A.data.IterEntries(catId) do
    if ShouldShowEntry(entry) then
      order = order + 1
      local btn = pool[entry]
      if not btn and ShouldCreateButton(entry) then
        btn = CreateActionButton(scrollChild, entry)
        btn:Hide()
        pool[entry] = btn
      end
      if btn then
        UpdateEntryVisualState(btn)
        tinsert(self._visibleButtons, { btn = btn, groupIndex = groupIdx, order = order })
      end
    end
  end

  if IsHeroPathCategory(catId) and AllPortalDB and AllPortalDB.showUnavailable then
    table.sort(self._visibleButtons, function(a, b)
      local aOwned = A.data.IsEntryOwned(a.btn.entry)
      local bOwned = A.data.IsEntryOwned(b.btn.entry)
      if aOwned ~= bOwned then return aOwned end
      return (a.order or 0) < (b.order or 0)
    end)
  end

  if #self._visibleButtons == 0 then
    local label = catId
    for _, cat in ipairs(A.data.categories) do
      if cat.id == catId then
        label = A.T and A.T[cat.labelKey] or cat.id
        break
      end
    end
    emptyLabel:SetText(label .. "\n" .. (A.T and A.T.empty_category or "No entries yet."))
    emptyLabel:Show()
  end

  self:RelayoutGrid()
  self:UpdateCooldowns()
  self:RefreshLabels()
end

function UI:Refresh()
  if self.currentCategoryId then
    self:SelectCategory(self.currentCategoryId)
    self:ScheduleNameRefresh()
  end
end

-- ============================================================
-- Public show/hide/toggle/reset
-- ============================================================
function UI:Show()
  frame:Show()
  if not self.currentCategoryId then
    local target = AllPortalDB and AllPortalDB.lastCategory
    if target == "items" then target = "use_items" end
    local pick = nil
    for _, cat in ipairs(A.data.categories) do
      if A.data.IsCategoryVisible(cat) then
        if target == cat.id then pick = cat.id; break end
        if not pick then pick = cat.id end
      end
    end
    if pick then self:SelectCategory(pick) end
  else
    self:SelectCategory(self.currentCategoryId)
  end
  self:ScheduleNameRefresh()
end

function UI:Hide() frame:Hide() end

function UI:Toggle()
  if frame:IsShown() then frame:Hide() else self:Show() end
end

function UI:ResetPosition()
  frame:ClearAllPoints()
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  frame:SetSize(DEFAULT_W, DEFAULT_H)
end

function UI:RestoreFromDB()
  if AllPortalDB and AllPortalDB.framePoint then
    local p, parentName, rp, x, y = unpack(AllPortalDB.framePoint)
    frame:ClearAllPoints()
    frame:SetPoint(p, _G[parentName] or UIParent, rp, x, y)
  end
  if AllPortalDB and AllPortalDB.frameSize then
    frame:SetSize(AllPortalDB.frameSize[1], AllPortalDB.frameSize[2])
  end
end

-- ============================================================
-- Cooldown updater
-- ============================================================
function UI:UpdateCooldowns()
  for _, item in ipairs(self._visibleButtons) do
    local buttons = item.btn.actionButtons or { item.btn }
    for _, btn in ipairs(buttons) do
      local entry = btn.entry
      local start, dur = A.data.GetEntryCooldown(entry)
      if start and dur and dur > 0 then
        btn.cooldown:SetCooldown(start, dur)
        btn.cooldownActive = true
        btn.cooldownEnd = start + dur
      else
        btn.cooldown:Clear()
        btn.cooldownActive = false
        btn.cdText:SetText("")
      end
    end
  end
  if self.UpdateRandomHearthCooldown then
    self:UpdateRandomHearthCooldown()
  end
end

function UI:UpdateRandomHearthCooldown()
  local btn = self.randomHearthButton
  if not btn then return end

  local entry = btn._cooldownEntry
  if not entry then
    local favorites = A.data.GetUsableFavoriteHearthstones and A.data.GetUsableFavoriteHearthstones() or {}
    local hasFavorites = A.data.HasHearthFavorites and A.data.HasHearthFavorites()
    if #favorites > 0 then
      entry = favorites[1]
    elseif not hasFavorites then
      local toys = A.data.GetUsableHearthstoneToys and A.data.GetUsableHearthstoneToys() or {}
      entry = toys[1] or (A.data.GetBaseHearthstone and A.data.GetBaseHearthstone())
    end
  end

  if not entry then
    if btn.cooldown then btn.cooldown:Clear() end
    if btn.cdText then btn.cdText:SetText("") end
    btn.cooldownActive = false
    return
  end

  local start, dur = A.data.GetEntryCooldown(entry)
  if start and dur and dur > 0 then
    btn.cooldown:SetCooldown(start, dur)
    btn.cooldownActive = true
    btn.cooldownEnd = start + dur
  else
    btn.cooldown:Clear()
    btn.cooldownActive = false
    btn.cdText:SetText("")
  end
end

local function UpdateCooldownText(btn)
  if btn.cooldownActive then
    local remain = btn.cooldownEnd - GetTime()
    if remain <= 0 then
      btn.cdText:SetText("")
      btn.cooldownActive = false
    else
      btn.cdText:SetText(FormatCooldown(remain))
    end
  end
end

local accumulator = 0
frame:HookScript("OnUpdate", function(self, elapsed)
  accumulator = accumulator + elapsed
  if accumulator < 0.1 then return end
  accumulator = 0
  for _, item in ipairs(UI._visibleButtons) do
    if item.btn.actionButtons then
      for _, btn in ipairs(item.btn.actionButtons) do
        UpdateCooldownText(btn)
      end
    else
      UpdateCooldownText(item.btn)
    end
  end
  UI:UpdateRandomHearthCooldown()
  UpdateCooldownText(UI.randomHearthButton)
end)
