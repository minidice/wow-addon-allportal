local addonName, ns = ...
AllPortal = AllPortal or {}
local A = AllPortal
A.ui = A.ui or {}
local UI = A.ui

local DEFAULT_W, DEFAULT_H = 600, 400
local MIN_W, MIN_H, MAX_W, MAX_H = 400, 300, 1200, 900

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

frame.TitleText:SetText(A.T and A.T.addon_title or "AllPortal")

tinsert(UISpecialFrames, "AllPortalMainFrame")

UI.frame = frame

-- ============================================================
-- Header: filter checkbox (top-left)
-- ============================================================
local filterCB = CreateFrame("CheckButton", "AllPortalFilterCheckbox", frame, "UICheckButtonTemplate")
filterCB:SetSize(20, 20)
filterCB:SetPoint("TOPLEFT", 12, -28)
filterCB.text:SetText(A.T and A.T.show_owned_only or "Show owned only")
filterCB.text:SetFontObject("GameFontNormal")
filterCB:SetHitRectInsets(0, -filterCB.text:GetStringWidth() - 4, 0, 0)

filterCB:SetScript("OnClick", function(self)
  local checked = self:GetChecked() and true or false
  if AllPortalDB then AllPortalDB.filterOwnedOnly = checked end
  if UI.Refresh then UI:Refresh() end
end)

UI.filterCheckbox = filterCB

function UI:RestoreFilterCheckbox()
  if AllPortalDB and AllPortalDB.filterOwnedOnly then
    filterCB:SetChecked(true)
  else
    filterCB:SetChecked(false)
  end
end

-- ============================================================
-- Left panel: category list
-- ============================================================
local LEFT_W = 180
local CAT_BTN_H = 28

local leftPanel = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
leftPanel:SetPoint("TOPLEFT", 8, -56)
leftPanel:SetPoint("BOTTOMLEFT", 8, 8)
leftPanel:SetWidth(LEFT_W)
UI.leftPanel = leftPanel

local catButtons = {}
UI.catButtons = catButtons

local separators = {}

function UI:BuildCategoryList()
  local visibleIndex = 0
  for catIdx, cat in ipairs(A.data.categories) do
    local visible = A.data.IsCategoryVisible(cat)

    if visible then
      local hasAny = false
      for entry in A.data.IterEntries(cat.id) do
        if A.data.IsEntryVisible(entry) then hasAny = true; break end
      end
      if not hasAny then visible = false end
    end

    local btn = catButtons[catIdx]
    if visible then
      visibleIndex = visibleIndex + 1
      if not btn then
        btn = CreateFrame("Button", nil, leftPanel)
        btn:SetSize(LEFT_W - 16, CAT_BTN_H)
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
        local sep = separators[catIdx] or leftPanel:CreateTexture(nil, "ARTWORK")
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
local BTN_SIZE = 36
local BTN_SPACING = 6
local GROUP_GAP = 12

local rightPanel = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 4, 0)
rightPanel:SetPoint("BOTTOMRIGHT", -8, 8)
UI.rightPanel = rightPanel

local scrollFrame = CreateFrame("ScrollFrame", "AllPortalScroll", rightPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 4, -4)
scrollFrame:SetPoint("BOTTOMRIGHT", -28, 4)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(1, 1)
scrollFrame:SetScrollChild(scrollChild)
UI.scrollFrame = scrollFrame
UI.scrollChild = scrollChild

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

local function CreateActionButton(parent, entry)
  local btn = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
  btn:SetSize(BTN_SIZE, BTN_SIZE)
  btn:RegisterForClicks("AnyDown", "AnyUp")
  btn.entry = entry

  if entry.type == "spell" then
    btn:SetAttribute("type", "spell")
    btn:SetAttribute("spell", entry.id)
  elseif entry.type == "toy" then
    btn:SetAttribute("type", "toy")
    btn:SetAttribute("toy", entry.id)
  elseif entry.type == "item" then
    btn:SetAttribute("type", "item")
    btn:SetAttribute("item", "item:" .. entry.id)
  end

  btn.icon = btn:CreateTexture(nil, "ARTWORK")
  btn.icon:SetAllPoints(true)
  btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  btn.icon:SetTexture(A.data.GetEntryIcon(entry) or "Interface\\Icons\\INV_Misc_QuestionMark")

  btn:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
  local n = btn:GetNormalTexture()
  n:SetTexCoord(0, 1, 0, 1)
  n:SetSize(BTN_SIZE * 1.8, BTN_SIZE * 1.8)
  n:ClearAllPoints()
  n:SetPoint("CENTER")

  btn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
  btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

  btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
  btn.cooldown:SetAllPoints(true)

  btn.cdText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  btn.cdText:SetPoint("CENTER")
  btn.cdText:SetTextColor(1, 1, 0)
  btn.cdText:SetText("")

  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if entry.type == "spell" then
      GameTooltip:SetSpellByID(entry.id)
    elseif entry.type == "toy" then
      GameTooltip:SetToyByItemID(entry.id)
    elseif entry.type == "item" then
      GameTooltip:SetItemByID(entry.id)
    end
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", GameTooltip_Hide)

  return btn
end

UI._CreateActionButton = CreateActionButton
UI._FormatCooldown = FormatCooldown

-- ============================================================
-- Button pool (pre-created at PLAYER_LOGIN; fixed for life of session)
-- ============================================================
local pool = {}
UI.pool = pool

function UI:BuildPool()
  for _, cat in ipairs(A.data.categories) do
    for entry in A.data.IterEntries(cat.id) do
      if A.data.IsEntryVisible(entry) then
        local btn = CreateActionButton(scrollChild, entry)
        btn:Hide()
        pool[entry] = btn
      end
    end
  end
end

function UI:Initialize()
  if self._initialized then return end
  self:BuildPool()
  self:RestoreFromDB()
  self:RestoreFilterCheckbox()
  self:BuildCategoryList()
  self._initialized = true
end

-- ============================================================
-- Category selection + grid layout
-- ============================================================
UI.currentCategoryId = nil
UI._visibleButtons = {}

local function ShouldShowEntry(entry)
  if not A.data.IsEntryVisible(entry) then return false end
  if AllPortalDB and AllPortalDB.filterOwnedOnly then
    return A.data.IsEntryOwned(entry)
  end
  return true
end

function UI:RelayoutGrid()
  local visible = self._visibleButtons
  if #visible == 0 then
    scrollChild:SetSize(1, 1)
    return
  end

  local panelW = scrollFrame:GetWidth()
  local available = panelW - RIGHT_PADDING_L * 2
  local cols = math.max(1, math.floor((available + BTN_SPACING) / (BTN_SIZE + BTN_SPACING)))

  local x, y = RIGHT_PADDING_L, -RIGHT_PADDING_L
  local col = 0
  local lastGroup = visible[1].groupIndex
  local maxRow = 0

  for _, item in ipairs(visible) do
    if item.groupIndex ~= lastGroup then
      if col > 0 then
        y = y - (BTN_SIZE + BTN_SPACING)
        col = 0
      end
      y = y - GROUP_GAP
      lastGroup = item.groupIndex
    end
    if col >= cols then
      y = y - (BTN_SIZE + BTN_SPACING)
      col = 0
    end
    item.btn:ClearAllPoints()
    item.btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", RIGHT_PADDING_L + col * (BTN_SIZE + BTN_SPACING), y)
    item.btn:Show()
    col = col + 1
    if y < maxRow then maxRow = y end
  end

  scrollChild:SetSize(panelW, math.abs(maxRow) + BTN_SIZE + RIGHT_PADDING_L)
end

function UI:SelectCategory(catId)
  for _, item in ipairs(self._visibleButtons) do
    item.btn:Hide()
  end
  wipe(self._visibleButtons)

  self.currentCategoryId = catId
  self:HighlightCategory(catId)

  if AllPortalDB then AllPortalDB.lastCategory = catId end

  for entry, groupIdx in A.data.IterEntries(catId) do
    if ShouldShowEntry(entry) then
      local btn = pool[entry]
      if btn then
        tinsert(self._visibleButtons, { btn = btn, groupIndex = groupIdx })
      end
    end
  end

  self:RelayoutGrid()
  self:UpdateCooldowns()
end

function UI:Refresh()
  if self.currentCategoryId then
    self:SelectCategory(self.currentCategoryId)
  end
end

-- ============================================================
-- Public show/hide/toggle/reset
-- ============================================================
function UI:Show()
  frame:Show()
  if not self.currentCategoryId then
    local target = AllPortalDB and AllPortalDB.lastCategory
    local pick = nil
    for _, cat in ipairs(A.data.categories) do
      if A.data.IsCategoryVisible(cat) then
        local hasAny = false
        for entry in A.data.IterEntries(cat.id) do
          if A.data.IsEntryVisible(entry) then hasAny = true; break end
        end
        if hasAny then
          if target == cat.id then pick = cat.id; break end
          if not pick then pick = cat.id end
        end
      end
    end
    if pick then self:SelectCategory(pick) end
  end
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
    local entry = item.btn.entry
    local start, dur = A.data.GetEntryCooldown(entry)
    if start and dur and dur > 0 then
      item.btn.cooldown:SetCooldown(start, dur)
      item.btn.cooldownActive = true
      item.btn.cooldownEnd = start + dur
    else
      item.btn.cooldown:Clear()
      item.btn.cooldownActive = false
      item.btn.cdText:SetText("")
    end
  end
end

local accumulator = 0
frame:HookScript("OnUpdate", function(self, elapsed)
  accumulator = accumulator + elapsed
  if accumulator < 0.1 then return end
  accumulator = 0
  for _, item in ipairs(UI._visibleButtons) do
    local btn = item.btn
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
end)
