local addonName, ns = ...
AllPortal = AllPortal or {}
local A = AllPortal
A.minimap = A.minimap or {}
local M = A.minimap

local RADIUS = 80

local function UpdatePosition(angle)
  local rad = math.rad(angle)
  local x = RADIUS * math.cos(rad)
  local y = RADIUS * math.sin(rad)
  M.btn:ClearAllPoints()
  M.btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

M.UpdatePosition = UpdatePosition

function M:Initialize()
  if self.btn then return end

  local btn = CreateFrame("Button", "AllPortalMinimapButton", Minimap)
  btn:SetSize(31, 31)
  btn:SetFrameStrata("MEDIUM")
  btn:SetFrameLevel(8)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  btn:RegisterForDrag("LeftButton")
  btn:SetMovable(true)

  btn.icon = btn:CreateTexture(nil, "ARTWORK")
  btn.icon:SetTexture("Interface\\Icons\\Spell_Arcane_PortalDalaran")
  btn.icon:SetSize(20, 20)
  btn.icon:SetPoint("CENTER")
  btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  btn.border = btn:CreateTexture(nil, "OVERLAY")
  btn.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  btn.border:SetSize(54, 54)
  btn.border:SetPoint("TOPLEFT")

  btn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      cx, cy = cx / scale, cy / scale
      local angle = math.deg(math.atan2(cy - my, cx - mx))
      AllPortalDB.minimap.angle = angle
      UpdatePosition(angle)
    end)
  end)

  btn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
  end)

  btn:SetScript("OnClick", function(self, mouseButton)
    if mouseButton == "LeftButton" then
      AllPortal.ui:Toggle()
    end
  end)

  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(A.T and A.T.addon_title or "AllPortal")
    GameTooltip:AddLine(A.T and A.T.tooltip_left_click or "Left-click: Toggle window", 1, 1, 1)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", GameTooltip_Hide)

  self.btn = btn

  UpdatePosition((AllPortalDB and AllPortalDB.minimap and AllPortalDB.minimap.angle) or 215)

  if AllPortalDB and AllPortalDB.minimapHidden then btn:Hide() end
end
