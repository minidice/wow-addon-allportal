local addonName = ...

AllPortal = AllPortal or {}
AllPortal.addonName = addonName

print("|cff00ff00AllPortal|r v" .. (GetAddOnMetadata(addonName, "Version") or "?") .. " loaded")
