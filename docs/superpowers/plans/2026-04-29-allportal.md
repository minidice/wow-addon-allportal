# AllPortal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the AllPortal WoW addon — a unified toolbar for Mythic+ teleport spells, Mage portals, toys, use items (incl. equip-and-use gear), and race-specific abilities. Single window with category sidebar + button grid, minimap button, race/class-conditional categories.

**Architecture:** Pure Blizzard API (no external libs). Single-namespace global `AllPortal`, four Lua files (`core`, `data`, `ui`, `minimap`) + `bindings.xml` + TOC. Secure button pool pre-created on `PLAYER_LOGIN` so category switching, filter toggle, and resize all work in combat while cast actions remain secure (combat-safe).

**Tech Stack:** WoW Lua 5.1 (Blizzard embedded). Frame XML/Templates from Blizzard. `SecureActionButtonTemplate` for click-to-cast. ID-based data (locale-independent).

---

## Spec Reference

Design doc: [docs/superpowers/specs/2026-04-29-allportal-design.md](../specs/2026-04-29-allportal-design.md)

---

## Development Workflow

WoW addons have no native automated test framework. Verification = save files → `/reload` in-game → click through. To eliminate copy-paste, use a Windows directory junction so the project folder IS the WoW addon folder (no admin required for `/J` junctions, only for `/D` symlinks):

```cmd
mklink /J "D:\Game\BattleNet\World of Warcraft\_retail_\Interface\AddOns\AllPortal" "D:\Project\wowaddon\allportal\AllPortal"
```

After this, editing files in `D:\Project\wowaddon\allportal\AllPortal\` updates the live WoW addon. `/reload` in-game picks up changes.

This is set up in Task 1.

---

## File Structure

```
D:\Project\wowaddon\allportal\
├── docs\superpowers\
│   ├── specs\2026-04-29-allportal-design.md   (already exists)
│   └── plans\2026-04-29-allportal.md          (this file)
├── .gitignore
└── AllPortal\                                  ← WoW-importable addon folder
    ├── allportal.toc                           ← addon manifest
    ├── core.lua                                ← entry point, events, slash, SavedVariables
    ├── data.lua                                ← categories, items, locale table
    ├── ui.lua                                  ← main frame, button pool, grid
    ├── minimap.lua                             ← minimap button
    └── bindings.xml                            ← keybinding definition
```

Responsibilities:

| File | Responsibility | Public API |
|---|---|---|
| `core.lua` | Event dispatch, SavedVariables init, slash command, combat lockdown queue | `AllPortal` global |
| `data.lua` | Locale table, category metadata, item lists, helper checks (race/class/owned/cooldown) | `AllPortal.data`, `AllPortal.T` |
| `ui.lua` | Main frame, secure button pool, category panel, grid layout, scroll, cooldown ticker | `AllPortal.ui` (with `:Show/:Hide/:Toggle/:Refresh/:ResetPosition`) |
| `minimap.lua` | Minimap button creation, drag-to-border, click handler | `AllPortal.minimap` |

---

## Phase 1 — Setup

### Task 1: Project structure, junction, git

**Files:**
- Create: `D:\Project\wowaddon\allportal\AllPortal\` (directory)
- Create: `D:\Project\wowaddon\allportal\.gitignore`
- Junction: `<WoW>\Interface\AddOns\AllPortal` → project's `AllPortal\`

- [ ] **Step 1: Create the addon source directory**

```bash
mkdir -p "D:/Project/wowaddon/allportal/AllPortal"
```

- [ ] **Step 2: Create the junction so WoW loads from the project folder**

In bash:

```bash
cmd //c mklink //J "D:\Game\BattleNet\World of Warcraft\_retail_\Interface\AddOns\AllPortal" "D:\Project\wowaddon\allportal\AllPortal"
```

Expected output: `Junction created for ... <<===>> ...`

If the junction already exists, delete first: `cmd //c rmdir "D:\Game\BattleNet\World of Warcraft\_retail_\Interface\AddOns\AllPortal"` then re-run.

- [ ] **Step 3: Create `.gitignore`**

File: `D:\Project\wowaddon\allportal\.gitignore`

```gitignore
# WoW SavedVariables (don't commit user state)
*.lua.bak

# Editor
.vscode/
.idea/
*.swp
*~

# OS
.DS_Store
Thumbs.db
```

- [ ] **Step 4: Initialize git and commit the existing design doc**

```bash
cd "D:/Project/wowaddon/allportal" && git init -b main && git add .gitignore docs/ && git commit -m "chore: initial design doc"
```

(If the user already preferred a different default branch name or doesn't want git, skip Step 4. The plan does not depend on git.)

---

### Task 2: TOC manifest + empty core.lua → smoke test addon loads

**Files:**
- Create: `AllPortal/allportal.toc`
- Create: `AllPortal/core.lua`

- [ ] **Step 1: Create the TOC manifest**

File: `D:\Project\wowaddon\allportal\AllPortal\allportal.toc`

```
## Interface: 110200
## Title: AllPortal
## Title-koKR: 올포탈
## Notes: Toolbar for portals, toys and use items
## Notes-koKR: 포탈, 장난감, 사용 아이템 통합 툴바
## Author: psmtopsm
## Version: 0.1.0
## SavedVariables: AllPortalDB

data.lua
core.lua
```

(More files are added to the TOC in later tasks. `Interface: 110200` corresponds to patch 11.2.0; bump to current build before release.)

- [ ] **Step 2: Create a placeholder `core.lua`**

File: `D:\Project\wowaddon\allportal\AllPortal\core.lua`

```lua
-- AllPortal: entry point. Wired up in later tasks.
local addonName = ...

AllPortal = AllPortal or {}
AllPortal.addonName = addonName

-- Sanity: confirm load
print("|cff00ff00AllPortal|r v" .. (GetAddOnMetadata(addonName, "Version") or "?") .. " loaded")
```

- [ ] **Step 3: Create a placeholder `data.lua` (so the TOC reference doesn't error)**

File: `D:\Project\wowaddon\allportal\AllPortal\data.lua`

```lua
AllPortal = AllPortal or {}
AllPortal.data = AllPortal.data or {}
```

- [ ] **Step 4: In-game verification**

1. Launch WoW (or `/reload` if running)
2. Open Add-Ons screen at character select → confirm `AllPortal` is listed and **enabled**
3. Log in with any character
4. In chat, look for the green load message: `AllPortal v0.1.0 loaded`
5. Type `/dump AllPortal` → should print a non-nil table

If no load message: check `<WoW>\Logs\FrameXML.log` for errors (TOC syntax issue most likely).

- [ ] **Step 5: Commit**

```bash
git add AllPortal/ && git commit -m "feat: addon loads with placeholder modules"
```

---

## Phase 2 — Data layer

### Task 3: data.lua — locale table and category metadata

**Files:**
- Modify: `AllPortal/data.lua`

- [ ] **Step 1: Replace `data.lua` with the locale table and category list**

```lua
local addonName, ns = ...

AllPortal = AllPortal or {}
local A = AllPortal
A.data = A.data or {}

-- ============================================================
-- Locale table
-- ============================================================
local locale = GetLocale()  -- "koKR", "enUS", "deDE", ...

local L = {
  enUS = {
    addon_title       = "AllPortal",
    current_season    = "Mythic+ Current Season",
    mage_portal       = "Portals & Teleports",
    toys              = "Toys",
    items             = "Items",
    misc              = "Other",
    mp_midnight       = "M+ Midnight",
    mp_tww            = "M+ The War Within",
    mp_df             = "M+ Dragonflight",
    mp_sl             = "M+ Shadowlands",
    mp_bfa            = "M+ Battle for Azeroth",
    mp_legion         = "M+ Legion",
    show_owned_only   = "Show owned only",
    close             = "Close",
    tooltip_left_click = "Left-click: Toggle window",
    minimap_hidden_msg = "Minimap button hidden.",
    minimap_shown_msg  = "Minimap button shown.",
    reset_msg          = "Position and size reset.",
    help_header        = "Commands:",
    help_toggle        = "Toggle main window",
    help_minimap       = "Toggle minimap button",
    help_reset         = "Reset window position and size",
    help_help          = "Show this help",
    unknown_cmd_msg    = "Unknown command. Try",
  },
  koKR = {
    addon_title       = "올포탈",
    current_season    = "영웅의 길 한밤1 시즌",
    mage_portal       = "포탈",
    toys              = "장난감",
    items             = "아이템",
    misc              = "기타",
    mp_midnight       = "영웅의 길: 한밤",
    mp_tww            = "영웅의 길: 내부 전쟁",
    mp_df             = "영웅의 길: 용군단",
    mp_sl             = "영웅의 길: 어둠땅",
    mp_bfa            = "영웅의 길: 격전의 아제로스",
    mp_legion         = "영웅의 길: 군단",
    show_owned_only   = "사용 가능만 보기",
    close             = "닫기",
    tooltip_left_click = "좌클릭: 창 열기/닫기",
    minimap_hidden_msg = "미니맵 버튼을 숨겼습니다.",
    minimap_shown_msg  = "미니맵 버튼을 표시합니다.",
    reset_msg          = "창 위치와 크기를 초기화했습니다.",
    help_header        = "명령어:",
    help_toggle        = "메인 창 열기/닫기",
    help_minimap       = "미니맵 버튼 표시/숨김",
    help_reset         = "창 위치·크기 초기화",
    help_help          = "도움말 표시",
    unknown_cmd_msg    = "알 수 없는 명령어. 시도:",
  },
}

A.T = L[locale] or L.enUS

-- ============================================================
-- Category metadata (left-panel order)
-- ============================================================
A.data.categories = {
  { id = "current_season", labelKey = "current_season", isCurrentSeason = true },
  { id = "mage_portal",    labelKey = "mage_portal",    classRequired = "MAGE" },
  { id = "toys",           labelKey = "toys" },
  { id = "items",          labelKey = "items" },
  { id = "misc",           labelKey = "misc",
    racesRequired = { "Vulpera", "DarkIronDwarf" } },
  -- separator drawn between index 5 and 6 in UI
  { id = "mp_midnight",    labelKey = "mp_midnight" },
  { id = "mp_tww",         labelKey = "mp_tww" },
  { id = "mp_df",          labelKey = "mp_df" },
  { id = "mp_sl",          labelKey = "mp_sl" },
  { id = "mp_bfa",         labelKey = "mp_bfa" },
  { id = "mp_legion",      labelKey = "mp_legion" },
}

A.data.SEPARATOR_AFTER_INDEX = 5  -- draw a thin separator after this category index
```

- [ ] **Step 2: Verify data loads**

In-game: `/reload`, then `/dump AllPortal.T.addon_title` → should print `"올포탈"` on koKR or `"AllPortal"` on enUS. `/dump #AllPortal.data.categories` → `11`.

- [ ] **Step 3: Commit**

```bash
git add AllPortal/data.lua && git commit -m "feat(data): locale table and category metadata"
```

---

### Task 4: data.lua — categoryItems with TBD ID markers

**Files:**
- Modify: `AllPortal/data.lua` (append)

- [ ] **Step 1: Append `categoryItems` to data.lua**

Append at the end of `AllPortal/data.lua`:

```lua
-- ============================================================
-- Category items
--   Each value is either a flat array of entries, or an array of groups
--   where each group is itself an array of entries (groups become visually
--   separated rows in the right grid).
--
--   Entry shape:
--     { type = "spell"|"toy"|"item", id = <number>, race = ?, class = ? }
--
--   IDs marked TBD must be filled in Task 5.
-- ============================================================
A.data.categoryItems = {

  -- Current Mythic+ season teleport spells (update each season patch)
  current_season = {
    -- TBD: Midnight S1 dungeon teleport spellIDs (5 current dungeons + rotation)
    -- Confirm via: /dump GetSpellInfo(<spellID>)
  },

  -- Mage class portals + teleports (city-by-city, alphabetical by city Korean name)
  mage_portal = {
    -- TBD: 마법사 포탈 / 순간이동 spellIDs by city
    -- Each city typically has both: a "Portal" (party) and a "Teleport" (self) spell
  },

  toys = {
    {  -- G1: General hearthstones
      { type = "toy",  id = 140192 },  -- Dalaran Hearthstone (확인됨)
      { type = "toy",  id = 0 },        -- TBD: 아르칸티나로 통하는 개인 열쇠
      { type = "item", id = 141605 },  -- Flight Master's Whistle (item, not toy)
      { type = "toy",  id = 110560 },  -- Garrison Hearthstone (확인됨)
    },
    {  -- G2: Undermine (구렁) related
      { type = "toy", id = 0 },  -- TBD: 구렁 탐험가의 마나결속 에테르 관문
      { type = "toy", id = 0 },  -- TBD: 구렁로봇 7001
    },
    {  -- G3
      { type = "toy", id = 0 },  -- TBD: 불안정한 차원문 방출기
    },
    {  -- G4: Wormhole Generators (BfA and later)
      { type = "toy", id = 0 },  -- TBD: 웜홀 생성기: 카즈 알가르
      { type = "toy", id = 0 },  -- TBD: 웜홀 생성기: 아르거스
      { type = "toy", id = 0 },  -- TBD: 웜홀 생성기: 잔달라
      { type = "toy", id = 0 },  -- TBD: 웜홀 생성기: 판다리아
      { type = "toy", id = 0 },  -- TBD: 웜홀 생성기: 어둠땅
    },
    {  -- G5: Wormhole Generators (older)
      { type = "toy", id = 0 },  -- TBD: 웜홀 생성기: 쿨 티라스
      { type = "toy", id = 0 },  -- TBD: 웜홀 생성기: 노스랜드
    },
    {  -- G6
      { type = "toy", id = 0 },  -- TBD: 웜홀 원심 분리기
    },
    {  -- G7: Engineering ultrasafe transporters
      { type = "toy", id = 0 },  -- TBD: 안전보증 순간이동기: 가젯잔
      { type = "toy", id = 0 },  -- TBD: 안전보증 순간이동기: 토쉴리의 연구기지
    },
  },

  items = {
    {  -- G1: Equip-and-use gear (tabards, rings, cloaks)
      { type = "item", id = 0 },  -- TBD: 충전식 리브스 전지
      { type = "item", id = 0 },  -- TBD: 은빛십자군 성전사의 휘장
      { type = "item", id = 0 },  -- TBD: 왕놋쇠 너클
      { type = "item", id = 0 },  -- TBD: 싸움꾼의 강력한 주먹질 반지
      { type = "item", id = 0 },  -- TBD: 사기꾼의 알록달곡 망토
      { type = "item", id = 0 },  -- TBD: 단결의 망토
      { type = "item", id = 0 },  -- TBD: 키린 토 반지
      { type = "item", id = 0 },  -- TBD: 헬스크림 세력단 휘장
    },
    {  -- G2: Trinkets / consumables
      { type = "item", id = 0 },  -- TBD: 잃어버린 시간의 유물 (장신구)
      { type = "item", id = 0 },  -- TBD: 칼날첨탑 성물
      { type = "item", id = 0 },  -- TBD: 제이나의 펜던트
      { type = "item", id = 0 },  -- TBD: 제독의 나침반
    },
  },

  misc = {
    { type = "spell", id = 0, race = "Vulpera" },        -- TBD: 야영지 귀환
    { type = "spell", id = 0, race = "DarkIronDwarf" },  -- TBD: 굴착기
  },

  -- Mythic+ teleport spells per expansion (all dungeons of that expansion's seasons)
  mp_midnight = { --[[ TBD ]] },
  mp_tww      = { --[[ TBD ]] },
  mp_df       = { --[[ TBD ]] },
  mp_sl       = { --[[ TBD ]] },
  mp_bfa      = { --[[ TBD ]] },
  mp_legion   = { --[[ TBD ]] },
}

-- ============================================================
-- Helper: iterate entries of a category as a flat list
--   For both flat arrays and grouped arrays, returns each entry along with
--   a `groupIndex` (1-based) so the UI can draw separators.
-- ============================================================
function A.data.IterEntries(categoryId)
  local items = A.data.categoryItems[categoryId]
  if not items then return function() end end

  -- Detect: is `items` a flat array (entries) or grouped (arrays of entries)?
  local first = items[1]
  local isGrouped = type(first) == "table" and first[1] ~= nil and first.type == nil

  if not isGrouped then
    local i = 0
    return function()
      i = i + 1
      if items[i] then return items[i], 1 end
    end
  else
    local g, e = 1, 0
    return function()
      while items[g] do
        e = e + 1
        if items[g][e] then return items[g][e], g end
        g, e = g + 1, 0
      end
    end
  end
end

-- ============================================================
-- Helper: should this category be shown for the current player?
-- ============================================================
function A.data.IsCategoryVisible(category)
  local _, classFile = UnitClass("player")
  local _, raceFile  = UnitRace("player")

  if category.classRequired and category.classRequired ~= classFile then
    return false
  end
  if category.racesRequired then
    local match = false
    for _, r in ipairs(category.racesRequired) do
      if r == raceFile then match = true; break end
    end
    if not match then return false end
  end
  return true
end

-- ============================================================
-- Helper: should this individual entry be shown for the current player?
--   (Independent of "owned only" filter — that's a separate check.)
-- ============================================================
function A.data.IsEntryVisible(entry)
  if entry.race then
    local _, raceFile = UnitRace("player")
    if raceFile ~= entry.race then return false end
  end
  if entry.class then
    local _, classFile = UnitClass("player")
    if classFile ~= entry.class then return false end
  end
  -- Skip entries with id == 0 (TBD placeholders) so the addon doesn't crash before IDs are filled
  if not entry.id or entry.id == 0 then return false end
  return true
end

-- ============================================================
-- Helper: is the entry "owned/usable" right now (used by the filter)?
-- ============================================================
function A.data.IsEntryOwned(entry)
  if entry.type == "spell" then
    return IsPlayerSpell(entry.id)
  elseif entry.type == "toy" then
    return PlayerHasToy(entry.id) and C_ToyBox.IsToyUsable(entry.id)
  elseif entry.type == "item" then
    return GetItemCount(entry.id, false) > 0 or IsEquippedItem(entry.id)
  end
  return false
end

-- ============================================================
-- Helper: cooldown query → start, duration (0 if not on cooldown)
-- ============================================================
function A.data.GetEntryCooldown(entry)
  if entry.type == "spell" then
    local info = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(entry.id)
    if info then return info.startTime, info.duration end
    -- Fallback for older API
    local s, d = GetSpellCooldown(entry.id)
    return s or 0, d or 0
  else
    local s, d = GetItemCooldown(entry.id)
    return s or 0, d or 0
  end
end

-- ============================================================
-- Helper: icon texture for an entry
-- ============================================================
function A.data.GetEntryIcon(entry)
  if entry.type == "spell" then
    if C_Spell and C_Spell.GetSpellTexture then
      return C_Spell.GetSpellTexture(entry.id)
    end
    return GetSpellTexture(entry.id)
  else
    return C_Item.GetItemIconByID(entry.id)
  end
end
```

- [ ] **Step 2: Verify**

`/reload` in-game. Should still load with no errors. Helpers won't be called yet, but they should at least parse.

`/dump AllPortal.data.IsCategoryVisible(AllPortal.data.categories[1])` → `true` (the current_season category has no class/race gate).

- [ ] **Step 3: Commit**

```bash
git add AllPortal/data.lua && git commit -m "feat(data): item lists with TBD markers + visibility helpers"
```

---

### Task 5: Resolve all TBD IDs

**Files:**
- Modify: `AllPortal/data.lua` (replace each `id = 0` and TBD comment with real ID)

This is research-heavy. Use Wowhead and in-game macros to resolve every TBD.

- [ ] **Step 1: Resolve toy/item IDs via Wowhead**

For each TBD toy/item, search Wowhead by Korean name. The URL contains the itemID (e.g., `https://www.wowhead.com/item=140192/...` → ID 140192).

Confirmed examples to keep:
- Dalaran Hearthstone: 140192
- Garrison Hearthstone: 110560
- Flight Master's Whistle: 141605

Look up:
- 아르칸티나로 통하는 개인 열쇠
- 구렁 탐험가의 마나결속 에테르 관문 / 구렁로봇 7001
- 불안정한 차원문 방출기
- 웜홀 생성기 8개 (카즈 알가르 / 아르거스 / 잔달라 / 판다리아 / 어둠땅 / 쿨 티라스 / 노스랜드)
- 웜홀 원심 분리기
- 안전보증 순간이동기: 가젯잔 / 토쉴리의 연구기지
- All `items` entries (충전식 리브스 전지, 휘장 2종, 반지 3종, 망토 2종, 장신구 4종)

In-game cross-check: `/dump GetItemInfo(<itemID>)` → returns the Korean name, confirms the ID.

For toys: `/dump C_ToyBox.GetToyInfo(<itemID>)` → returns `(itemID, name, icon, isFavorite, hasFanfare, itemQuality)`. Returns nil if the player has never had that toy *registered with toybox*; itemID alone still identifies it.

- [ ] **Step 2: Resolve spell IDs (Mage portals, racial spells, M+ teleports)**

**Mage portals/teleports** (`mage_portal` category): On a Mage character, open the spellbook → portal/teleport spells. For each: `/dump GetSpellInfo(<spellID>)` or right-click → "Find on Wowhead". Cities to cover (typical Mage repertoire):
- Stormwind (Ally), Ironforge (Ally), Darnassus (Ally), Exodar (Ally)
- Orgrimmar (Horde), Thunder Bluff (Horde), Undercity (Horde), Silvermoon (Horde)
- Dalaran (cross-faction, NW + Broken Isles versions both)
- Shattrath, Theramore (if still in game), Tol Barad, Vale of Eternal Blossoms, Hall of the Guardian, Oribos, Valdrakken

For each, add **two** entries: `Portal: <city>` and `Teleport: <city>` (the party-vs-self pair).

**Race spells**:
- Vulpera 야영지 귀환: spellID `345396` (가능. 인게임 확인 필수)
- Dark Iron Dwarf 굴착기 (Mole Machine): spellID `265225` (확인 필수)

**M+ teleport spells** (`mp_*` categories): Wowhead lists all "Path of the X Hero" and "Path of the X" spells. Quick reference:
- Legion: Court of Stars, Eye of Azshara, Black Rook Hold, Halls of Valor, Maw of Souls, Vault of the Wardens, Lower Karazhan, Upper Karazhan, Cathedral of Eternal Night, Seat of the Triumvirate, Neltharion's Lair, Darkheart Thicket
- BfA: Atal'Dazar, Freehold, King's Rest, Shrine of the Storm, Siege of Boralus, Temple of Sethraliss, The MOTHERLODE!!, The Underrot, Tol Dagor, Waycrest Manor, Mechagon Junkyard, Mechagon Workshop
- SL: De Other Side, Halls of Atonement, Mists of Tirna Scithe, Plaguefall, Sanguine Depths, Spires of Ascension, The Necrotic Wake, Theater of Pain, Tazavesh
- DF: Algeth'ar Academy, The Azure Vault, Halls of Infusion, Neltharus, Ruby Life Pools, The Nokhud Offensive, Brackenhide Hollow, Uldaman: Legacy of Tyr, Dawn of the Infinite (DotI: Murozond's Rise / Galakrond's Fall split), Throne of the Tides
- TWW: Ara-Kara, City of Threads, The Dawnbreaker, The Stonevault, Cinderbrew Meadery, Darkflame Cleft, Priory of the Sacred Flame, The Rookery, Operation: Floodgate
- Midnight: TBD upon release

Authoritative source: each expansion's "Hero/Path of …" achievement on Wowhead — clicking the achievement reveals the reward spell IDs.

- [ ] **Step 3: Replace `id = 0` and TBD with real IDs**

For each entry in `data.lua`, change `id = 0` to the resolved number and remove the `TBD:` prefix from the comment.

Example transformation:

Before:
```lua
{ type = "toy", id = 0 },  -- TBD: 웜홀 생성기: 노스랜드
```

After:
```lua
{ type = "toy", id = 48933 },  -- 웜홀 생성기: 노스랜드
```

(48933 is the actual Wormhole Generator: Northrend item ID — verify before using.)

- [ ] **Step 4: Update `current_season` label if Midnight S1 dungeons differ from spec**

If the current season's actual dungeon names differ from the spec, update `L.koKR.current_season` and `L.enUS.current_season` to reflect the actual season.

- [ ] **Step 5: Verify**

`/reload`. `/dump #AllPortal.data.categoryItems.toys` → should be 7 (groups). `/dump AllPortal.data.IsEntryOwned({type="toy", id=140192})` on a character that has Dalaran Hearthstone → `true`.

Spot-check 5 random entries via the helpers.

- [ ] **Step 6: Commit**

```bash
git add AllPortal/data.lua && git commit -m "data: fill in spell/item/toy IDs"
```

---

## Phase 3 — UI

### Task 6: ui.lua — main frame, header, drag, resize, close

**Files:**
- Create: `AllPortal/ui.lua`
- Modify: `AllPortal/allportal.toc` (add `ui.lua`)

- [ ] **Step 1: Create the ui.lua skeleton**

File: `D:\Project\wowaddon\allportal\AllPortal\ui.lua`

```lua
local addonName, ns = ...
AllPortal = AllPortal or {}
local A = AllPortal
A.ui = A.ui or {}
local UI = A.ui

-- Default values used when SavedVariables is missing
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

-- Title text (BasicFrameTemplate has frame.TitleText)
frame.TitleText:SetText(A.T.addon_title)

-- ESC closes
tinsert(UISpecialFrames, "AllPortalMainFrame")

UI.frame = frame

-- ============================================================
-- Public methods
-- ============================================================
function UI:Show()  frame:Show() end
function UI:Hide() frame:Hide() end
function UI:Toggle() if frame:IsShown() then frame:Hide() else frame:Show() end end

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

-- Stub for relayout, filled in Task 9-12
function UI:RelayoutGrid() end
function UI:Refresh() end
function UI:SelectCategory(id) end
```

- [ ] **Step 2: Add ui.lua to TOC**

Edit `AllPortal/allportal.toc`:

```
data.lua
core.lua
ui.lua
```

- [ ] **Step 3: Add a temporary slash command in core.lua to test the frame**

Replace `core.lua` with:

```lua
local addonName = ...
AllPortal = AllPortal or {}
AllPortal.addonName = addonName

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
  print("|cff00ff00AllPortal|r v" .. (GetAddOnMetadata(addonName, "Version") or "?") .. " loaded")
end)

SLASH_ALLPORTAL1 = "/allportal"
SlashCmdList["ALLPORTAL"] = function(msg)
  AllPortal.ui:Toggle()
end
```

- [ ] **Step 4: In-game verification**

1. `/reload`
2. `/allportal` → main frame opens, with title "올포탈" or "AllPortal"
3. Drag the title bar — frame moves
4. Drag the bottom-right corner — frame resizes (between 400×300 and 1200×900)
5. Press `Esc` while frame is open — frame closes
6. Click the X (top right) — frame closes
7. `/allportal` again — opens at the last position/size (won't be remembered yet — savedvariables wired in Task 14, but movement should at least work in-session)

If anything errors, check `<WoW>\Logs\FrameXML.log`.

- [ ] **Step 5: Commit**

```bash
git add AllPortal/ && git commit -m "feat(ui): main frame with drag, resize, close"
```

---

### Task 7: ui.lua — header (filter checkbox)

**Files:**
- Modify: `AllPortal/ui.lua`

- [ ] **Step 1: Append filter checkbox creation after the resizer block**

Add to `ui.lua` (above the `function UI:Show()` line):

```lua
-- ============================================================
-- Header: filter checkbox (top-left)
-- ============================================================
local filterCB = CreateFrame("CheckButton", "AllPortalFilterCheckbox", frame, "UICheckButtonTemplate")
filterCB:SetSize(20, 20)
filterCB:SetPoint("TOPLEFT", 12, -28)
filterCB.text:SetText(A.T.show_owned_only)
filterCB.text:SetFontObject("GameFontNormal")
-- Enlarge clickable area to include the label
filterCB:SetHitRectInsets(0, -filterCB.text:GetStringWidth() - 4, 0, 0)

filterCB:SetScript("OnClick", function(self)
  local checked = self:GetChecked() and true or false
  if AllPortalDB then AllPortalDB.filterOwnedOnly = checked end
  if UI.Refresh then UI:Refresh() end
end)

UI.filterCheckbox = filterCB

-- Restore checkbox state
function UI:RestoreFilterCheckbox()
  if AllPortalDB and AllPortalDB.filterOwnedOnly then
    filterCB:SetChecked(true)
  else
    filterCB:SetChecked(false)
  end
end
```

- [ ] **Step 2: Verify**

`/reload`, `/allportal`. Confirm:
- A checkbox appears top-left under the title bar with the label "사용 가능만 보기" or "Show owned only"
- Clicking toggles the check
- No errors

(Behavior — actually filtering — happens in Task 12. Right now the checkbox just toggles its own state.)

- [ ] **Step 3: Commit**

```bash
git add AllPortal/ui.lua && git commit -m "feat(ui): filter checkbox in header"
```

---

### Task 8: ui.lua — left category panel

**Files:**
- Modify: `AllPortal/ui.lua`

- [ ] **Step 1: Append left panel creation**

Add to `ui.lua` (before `function UI:Show()`):

```lua
-- ============================================================
-- Left panel: category list
-- ============================================================
local LEFT_W = 180
local CAT_BTN_H = 28
local CAT_PADDING = 4

local leftPanel = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
leftPanel:SetPoint("TOPLEFT", 8, -56)
leftPanel:SetPoint("BOTTOMLEFT", 8, 8)
leftPanel:SetWidth(LEFT_W)
UI.leftPanel = leftPanel

local catButtons = {}    -- index → button
UI.catButtons = catButtons

local separators = {}    -- index → separator line texture

-- Build (or rebuild) the category buttons. Hides categories not visible
-- to the current player (class/race gating).
function UI:BuildCategoryList()
  -- Reuse existing buttons; just re-anchor & re-show as needed
  local visibleIndex = 0
  for catIdx, cat in ipairs(A.data.categories) do
    local visible = A.data.IsCategoryVisible(cat)

    -- Empty-after-filter safety net: if no entries pass IsEntryVisible, hide category
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
        highlight:SetColorTexture(1, 0.5, 0, 0.35)  -- orange
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
      btn.label:SetText(A.T[cat.labelKey] or cat.id)
      btn:ClearAllPoints()
      btn:SetPoint("TOPLEFT", 4, -((visibleIndex - 1) * (CAT_BTN_H + 2)) - CAT_PADDING)
      btn:Show()

      -- Separator after the configured index (in *original* category order)
      if catIdx == A.data.SEPARATOR_AFTER_INDEX then
        local sep = separators[catIdx] or leftPanel:CreateTexture(nil, "ARTWORK")
        sep:SetTexture("Interface\\Common\\UI-TooltipDivider-Transparent")
        sep:SetHeight(8)
        sep:ClearAllPoints()
        sep:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
        sep:SetPoint("RIGHT", btn, "RIGHT")
        sep:Show()
        separators[catIdx] = sep
        -- Bump subsequent buttons down by separator height
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
```

- [ ] **Step 2: Hook BuildCategoryList into Show**

Modify the existing `function UI:Show()`:

```lua
function UI:Show()
  if not self._built then
    self:BuildCategoryList()
    self._built = true
  end
  frame:Show()
end
```

- [ ] **Step 3: Verify**

`/reload`, `/allportal`. Confirm:
- Left panel shows the categories in order
- "포탈" / "Portals & Teleports" is hidden if you're not a Mage; visible on a Mage
- "기타" / "Other" is hidden unless you're Vulpera or Dark Iron Dwarf
- Hover highlights gray, no orange highlight yet (no category selected)
- Clicking a category — nothing happens yet (SelectCategory is still a stub)

- [ ] **Step 4: Commit**

```bash
git add AllPortal/ui.lua && git commit -m "feat(ui): left category panel with class/race gating"
```

---

### Task 9: ui.lua — right scroll panel + grid container

**Files:**
- Modify: `AllPortal/ui.lua`

- [ ] **Step 1: Append right panel creation**

Add to `ui.lua` (before `function UI:Show()`):

```lua
-- ============================================================
-- Right panel: scrollable grid
-- ============================================================
local RIGHT_PADDING_L = 8
local BTN_SIZE = 36
local BTN_SPACING = 6
local GROUP_GAP = 12  -- extra vertical space between groups

local rightPanel = CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 4, 0)
rightPanel:SetPoint("BOTTOMRIGHT", -8, 8)
UI.rightPanel = rightPanel

local scrollFrame = CreateFrame("ScrollFrame", "AllPortalScroll", rightPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 4, -4)
scrollFrame:SetPoint("BOTTOMRIGHT", -28, 4)  -- leave room for scrollbar

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(1, 1)  -- recalculated in RelayoutGrid
scrollFrame:SetScrollChild(scrollChild)
UI.scrollFrame = scrollFrame
UI.scrollChild = scrollChild
```

- [ ] **Step 2: Verify**

`/reload`, `/allportal`. Confirm the right panel shows an empty inset region with a scrollbar on the right edge. No errors.

- [ ] **Step 3: Commit**

```bash
git add AllPortal/ui.lua && git commit -m "feat(ui): right scroll panel + grid container"
```

---

### Task 10: ui.lua — secure button factory

**Files:**
- Modify: `AllPortal/ui.lua`

- [ ] **Step 1: Append the button factory**

Add to `ui.lua` (before `function UI:Show()`):

```lua
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

  -- Set the secure attributes (ID-based, locale-independent)
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

  -- Icon
  btn.icon = btn:CreateTexture(nil, "ARTWORK")
  btn.icon:SetAllPoints(true)
  btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  btn.icon:SetTexture(A.data.GetEntryIcon(entry) or "Interface\\Icons\\INV_Misc_QuestionMark")

  -- Border (standard action button look)
  btn:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
  local n = btn:GetNormalTexture()
  n:SetTexCoord(0, 1, 0, 1)
  n:SetSize(BTN_SIZE * 1.8, BTN_SIZE * 1.8)
  n:ClearAllPoints()
  n:SetPoint("CENTER")

  btn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
  btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")

  -- Cooldown overlay (Blizzard standard)
  btn.cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
  btn.cooldown:SetAllPoints(true)

  -- Cooldown text (we draw seconds remaining ourselves; the spinner is drawn by Cooldown frame)
  btn.cdText = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
  btn.cdText:SetPoint("CENTER")
  btn.cdText:SetTextColor(1, 1, 0)
  btn.cdText:SetText("")

  -- Tooltip
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

UI._CreateActionButton = CreateActionButton  -- exposed for pool building
UI._FormatCooldown = FormatCooldown
```

- [ ] **Step 2: Verify (lua syntax only)**

`/reload` → no errors. Buttons aren't created until the pool task. This is just to confirm the file parses.

- [ ] **Step 3: Commit**

```bash
git add AllPortal/ui.lua && git commit -m "feat(ui): secure action button factory"
```

---

### Task 11: ui.lua — pre-create button pool on PLAYER_LOGIN

**Files:**
- Modify: `AllPortal/ui.lua`

- [ ] **Step 1: Append pool builder**

Add to `ui.lua` (before `function UI:Show()`):

```lua
-- ============================================================
-- Button pool (pre-created at PLAYER_LOGIN; fixed for life of session)
-- ============================================================
-- Map: entry → button. Indexed by reference to entry tables.
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

-- Called from core.lua on PLAYER_LOGIN. Skipped if already built (safety against double-call).
function UI:Initialize()
  if self._initialized then return end
  self:BuildPool()
  self:RestoreFromDB()
  self:RestoreFilterCheckbox()
  self:BuildCategoryList()
  self._initialized = true
end
```

- [ ] **Step 2: Update core.lua to call UI:Initialize on PLAYER_LOGIN**

Replace `core.lua`:

```lua
local addonName = ...
AllPortal = AllPortal or {}
AllPortal.addonName = addonName

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_LOGIN" then
    -- Initialize SavedVariables with defaults
    AllPortalDB = AllPortalDB or {}
    AllPortalDB.minimap = AllPortalDB.minimap or { angle = 215 }
    if AllPortalDB.minimapHidden == nil then AllPortalDB.minimapHidden = false end
    if AllPortalDB.filterOwnedOnly == nil then AllPortalDB.filterOwnedOnly = false end

    AllPortal.ui:Initialize()
    print("|cff00ff00AllPortal|r v" .. (GetAddOnMetadata(addonName, "Version") or "?") .. " loaded")
  end
end)

SLASH_ALLPORTAL1 = "/allportal"
SlashCmdList["ALLPORTAL"] = function(msg)
  AllPortal.ui:Toggle()
end
```

- [ ] **Step 3: Verify**

`/reload`. Confirm:
- No errors
- `/dump #AllPortal.ui.pool` runs without error (count depends on how many TBD IDs you've resolved; entries with id == 0 are skipped)
- `/allportal` opens the frame; right panel still empty (SelectCategory is stub)

- [ ] **Step 4: Commit**

```bash
git add AllPortal/ && git commit -m "feat(ui): button pool created at PLAYER_LOGIN"
```

---

### Task 12: ui.lua — category selection + grid layout + filter behavior

**Files:**
- Modify: `AllPortal/ui.lua`

- [ ] **Step 1: Replace stub `SelectCategory`, `Refresh`, `RelayoutGrid` with real implementations**

Locate the stub block at the end of `ui.lua`:

```lua
-- Stub for relayout, filled in Task 9-12
function UI:RelayoutGrid() end
function UI:Refresh() end
function UI:SelectCategory(id) end
```

Replace with:

```lua
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

  -- Compute columns based on current right-panel width
  local panelW = scrollFrame:GetWidth()
  local available = panelW - RIGHT_PADDING_L * 2
  local cols = math.max(1, math.floor((available + BTN_SPACING) / (BTN_SIZE + BTN_SPACING)))

  -- Lay out buttons. Insert a row break when groupIndex changes.
  local x, y = RIGHT_PADDING_L, -RIGHT_PADDING_L
  local col = 0
  local lastGroup = visible[1].groupIndex
  local maxRow = 0

  for _, item in ipairs(visible) do
    if item.groupIndex ~= lastGroup then
      -- new group → start new row, with extra gap
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
  -- Hide previously visible buttons
  for _, item in ipairs(self._visibleButtons) do
    item.btn:Hide()
  end
  wipe(self._visibleButtons)

  self.currentCategoryId = catId
  self:HighlightCategory(catId)

  -- Persist
  if AllPortalDB then AllPortalDB.lastCategory = catId end

  -- Build new visible list, respecting groups + entry visibility + filter
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

-- Auto-select last category (or first visible) on first show
local origShow = UI.Show
function UI:Show()
  origShow(self)
  if not self.currentCategoryId then
    local target = AllPortalDB and AllPortalDB.lastCategory
    -- Verify target is still visible to current player; otherwise pick first visible
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

-- Cooldown updater (called per-frame via OnUpdate; cheap because most buttons aren't on cooldown)
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

-- Per-frame text update (every 0.1s)
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
```

- [ ] **Step 2: In-game verification**

`/reload`. Verify:
1. `/allportal` opens
2. The first visible category is auto-selected and highlighted orange in the left panel
3. Right grid shows action buttons; mousing over each shows tooltip
4. Clicking the buttons (left-click) executes the spell/toy/item — try Dalaran Hearthstone (`140192`) if you have it
5. Clicking different categories switches the right grid
6. Toggling the filter checkbox hides/shows entries
7. Resize the frame: grid columns reflow, scroll appears when content exceeds height
8. Use a hearthstone first, then click it on the toolbar — should show a cooldown sweep + remaining time

- [ ] **Step 3: Commit**

```bash
git add AllPortal/ui.lua && git commit -m "feat(ui): category selection, grid layout, cooldowns, filter"
```

---

## Phase 4 — Minimap

### Task 13: minimap.lua — minimap button

**Files:**
- Create: `AllPortal/minimap.lua`
- Modify: `AllPortal/allportal.toc` (add `minimap.lua`)
- Modify: `AllPortal/core.lua` (call `AllPortal.minimap:Initialize()`)

- [ ] **Step 1: Create minimap.lua**

File: `D:\Project\wowaddon\allportal\AllPortal\minimap.lua`

```lua
local addonName, ns = ...
AllPortal = AllPortal or {}
local A = AllPortal
A.minimap = A.minimap or {}
local M = A.minimap

local RADIUS = 80  -- distance from minimap center

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

  btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

  btn:SetScript("OnClick", function(self, mouseButton)
    if mouseButton == "LeftButton" then
      AllPortal.ui:Toggle()
    end
  end)

  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText(A.T.addon_title)
    GameTooltip:AddLine(A.T.tooltip_left_click, 1, 1, 1)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", GameTooltip_Hide)

  self.btn = btn

  -- Restore saved position
  UpdatePosition((AllPortalDB and AllPortalDB.minimap and AllPortalDB.minimap.angle) or 215)

  -- Apply hidden state
  if AllPortalDB and AllPortalDB.minimapHidden then btn:Hide() end
end
```

- [ ] **Step 2: Add to TOC**

Edit `AllPortal/allportal.toc`:

```
data.lua
core.lua
ui.lua
minimap.lua
```

- [ ] **Step 3: Initialize from core.lua**

In `core.lua`, inside the `PLAYER_LOGIN` handler, add:

```lua
    AllPortal.ui:Initialize()
    AllPortal.minimap:Initialize()    -- ← add this line
    print("|cff00ff00AllPortal|r v" ..
```

- [ ] **Step 4: Verify**

`/reload`. Confirm:
- A minimap button appears at angle 215° (lower-left of minimap)
- Drag the button along the minimap edge — it follows the border circle, can't be moved off it
- The angle persists across `/reload`
- Left-click toggles the main frame
- Mouse over shows a tooltip
- The button is detected by MinimapButtonButton (if installed) — it shows up in the MBB drawer

- [ ] **Step 5: Commit**

```bash
git add AllPortal/ && git commit -m "feat(minimap): minimap button with drag-to-border"
```

---

## Phase 5 — Slash + keybinding

### Task 14: Full slash command + keybinding

**Files:**
- Modify: `AllPortal/core.lua`
- Create: `AllPortal/bindings.xml`
- Modify: `AllPortal/allportal.toc` (add `bindings.xml`)

- [ ] **Step 1: Replace the slash handler in core.lua with the full version**

Replace the slash block at the bottom of `core.lua`:

```lua
SLASH_ALLPORTAL1 = "/allportal"

SlashCmdList["ALLPORTAL"] = function(msg)
  msg = strtrim((msg or ""):lower())
  local T = AllPortal.T
  local prefix = "|cff00ff00AllPortal:|r "
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
```

- [ ] **Step 2: Create bindings.xml**

File: `D:\Project\wowaddon\allportal\AllPortal\bindings.xml`

```xml
<Bindings>
  <Binding name="ALLPORTAL_TOGGLE" header="ALLPORTAL" category="ADDONS">
    AllPortal.ui:Toggle()
  </Binding>
</Bindings>
```

- [ ] **Step 3: Add to TOC**

Edit `AllPortal/allportal.toc`:

```
data.lua
core.lua
ui.lua
minimap.lua
bindings.xml
```

- [ ] **Step 4: Verify**

`/reload`. Confirm:
- `/allportal` toggles
- `/allportal show` opens, `/allportal hide` closes
- `/allportal minimap` toggles minimap button visibility, prints message
- `/allportal reset` resets frame position/size and minimap angle
- `/allportal help` prints command list
- `/allportal foo` prints unknown-command error

In Game Menu → Key Bindings → AddOns: a new "ALLPORTAL" section with "ALLPORTAL_TOGGLE" — bind it to a key, then press the key in-game → toggles the frame.

- [ ] **Step 5: Commit**

```bash
git add AllPortal/ && git commit -m "feat: full slash commands and keybinding"
```

---

## Phase 6 — Persistence + events

### Task 15: SavedVariables — full persistence wiring

**Files:**
- Modify: `AllPortal/core.lua` (verify defaults)
- Modify: `AllPortal/ui.lua` (verify Save points)
- Modify: `AllPortal/minimap.lua` (verify save points)

This task is mostly verification — the prior tasks should already write to `AllPortalDB`. This step ensures every state in section 9 of the spec persists correctly.

- [ ] **Step 1: Verify SavedVariables shape after a session**

`/reload`. Open frame, drag, resize, switch category, toggle filter, drag minimap button. `/reload`.

Then run:

```
/dump AllPortalDB
```

Expected fields populated:
- `framePoint` — array {point, parent, relPoint, x, y}
- `frameSize` — array {w, h}
- `lastCategory` — string ID
- `filterOwnedOnly` — boolean
- `minimap.angle` — number
- `minimapHidden` — boolean

If any field is missing, find the corresponding write site (Tasks 6, 7, 12, 13) and confirm it actually writes.

- [ ] **Step 2: Verify restore on next `/reload`**

`/reload` again. The frame should:
- Reopen at the same position
- Be the same size
- Start with the previously selected category (if frame is shown — note: by default frame is hidden after reload)
- Filter checkbox state matches
- Minimap button at the saved angle

- [ ] **Step 3: Commit (if any tweaks were needed)**

```bash
git add AllPortal/ && git commit -m "fix: SavedVariables persistence corrections" --allow-empty
```

(Use `--allow-empty` only if no tweaks were needed — this records that the verification step ran.)

---

### Task 16: Event wiring (data refresh + cooldowns + combat lockdown)

**Files:**
- Modify: `AllPortal/core.lua`

- [ ] **Step 1: Replace core.lua event frame block**

Replace the `local frame = CreateFrame("Frame")` block in `core.lua` with the full version:

```lua
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
  local UI = AllPortal.ui
  local data = AllPortal.data

  if event == "PLAYER_LOGIN" then
    AllPortalDB = AllPortalDB or {}
    AllPortalDB.minimap = AllPortalDB.minimap or { angle = 215 }
    if AllPortalDB.minimapHidden == nil then AllPortalDB.minimapHidden = false end
    if AllPortalDB.filterOwnedOnly == nil then AllPortalDB.filterOwnedOnly = false end
    UI:Initialize()
    AllPortal.minimap:Initialize()
    print("|cff00ff00AllPortal|r v" .. (GetAddOnMetadata(addonName, "Version") or "?") .. " loaded")

  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Cache-warm: call GetItemInfo on every entry's itemID once. Replies arrive via GET_ITEM_INFO_RECEIVED.
    for _, cat in ipairs(data.categories) do
      for entry in data.IterEntries(cat.id) do
        if entry.type ~= "spell" and entry.id and entry.id > 0 then
          GetItemInfo(entry.id)
        end
      end
    end

  elseif event == "GET_ITEM_INFO_RECEIVED" then
    -- An item's metadata arrived. If it's one of ours and currently visible, refresh icons/tooltips.
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
    -- Owned-state may have changed → refresh visible category if filter is on or visibility may differ
    if UI.frame and UI.frame:IsShown() then
      QueueOrRun(function() UI:Refresh() end)
    end

  elseif event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" then
    if UI.frame and UI.frame:IsShown() then
      UI:UpdateCooldowns()
    end

  elseif event == "PLAYER_REGEN_DISABLED" then
    -- combat enter; queue is already in effect
  elseif event == "PLAYER_REGEN_ENABLED" then
    FlushQueue()
  end
end)
```

- [ ] **Step 2: Verify**

`/reload`. Confirm:
- Toy collection: open Collections → Toys, mark Dalaran Hearthstone as not learned (just a check; don't actually delete) — actually, this is hard to test. Easier: while frame is open showing toys, change zone via flight master to trigger map updates → frame should remain stable
- Cooldown: cast Hearthstone, look at the AllPortal frame — the corresponding button shows a cooldown sweep + ticking text
- Bag changes: while frame open showing items category, swap a weapon → no errors, the items list updates ownership state
- Combat: enter combat (attack a training dummy), try to switch category — works (Show/Hide is unrestricted). Try `/allportal reset` mid-combat — should defer or work without issue.

- [ ] **Step 3: Commit**

```bash
git add AllPortal/core.lua && git commit -m "feat(core): full event wiring with combat lockdown queue"
```

---

## Phase 7 — Final integration

### Task 17: End-to-end verification on multiple characters

**Files:** none (verification only)

Test on at least 4 characters covering different conditions. Use whatever characters are available.

- [ ] **Step 1: Mage character (any race)**

Verify:
- "포탈" / "Portals & Teleports" category appears in the left panel (it doesn't on non-mages)
- Mage portal/teleport spells display correctly with names in client locale
- Click a teleport — character casts it

- [ ] **Step 2: Vulpera character**

Verify:
- "기타" / "Other" category appears, with the Camp Hearth (야영지 귀환) entry only

- [ ] **Step 3: Dark Iron Dwarf character**

Verify:
- "기타" / "Other" category appears, with Mole Machine (굴착기) entry only

- [ ] **Step 4: Non-mage, non-Vulpera, non-DarkIron character**

Verify:
- "포탈" and "기타" categories are both **hidden** in the left panel

- [ ] **Step 5: Pre-Mythic+ alt (no M+ teleports learned)**

Verify:
- With "사용 가능만 보기" off: M+ categories show all entries, grayed/unowned
- With "사용 가능만 보기" on: M+ categories show no entries (or category hidden by safety net if zero owned)

- [ ] **Step 6: Combat regression test**

Engage a training dummy. While in combat:
- `/allportal` toggle works
- Switching categories works
- Toggling filter works
- Resizing main frame works
- Clicking a portal button casts (post-combat for actually-restricted teleports)

- [ ] **Step 7: Commit final test pass**

```bash
git add -A && git commit -m "chore: end-to-end test pass" --allow-empty
```

- [ ] **Step 8: Tag v1.0.0**

```bash
git tag -a v1.0.0 -m "AllPortal v1.0.0"
```

---

## Out of scope (for future versions)

- Right-click to hide/show individual entries
- GUI options panel (`/allportal config`)
- Custom user-added entries
- Favorites category
- Search box

These are explicitly v2 items per the design spec.

---

## Self-Review (filled in by author)

**Spec coverage** — every section of the spec maps to one or more tasks above:

- §2 file structure → Task 1, 2 (TOC + initial files)
- §3 data model + locale + visibility helpers → Task 3, 4, 5
- §4 main frame UI → Task 6, 7
- §4.3-4.4 panels (left + grid) → Task 8, 9
- §5 click behavior → Task 10, 11, 12 (factory + pool + selection)
- §6 events + cooldowns + combat lockdown → Task 16
- §7 minimap → Task 13
- §8 slash + keybinding → Task 14
- §9 SavedVariables → Task 15 (verify; writes happen earlier)
- §10 season-patch update procedure → addressed in Task 5 commentary
- §11 v2 items → "Out of scope" section above

**Placeholder check:** All `TBD: …` markers in the plan are inside Task 5, which is explicitly the "go look these up" task. No other TBDs in implementation steps.

**Type/method consistency:**
- `UI:Initialize`, `UI:Show`, `UI:Hide`, `UI:Toggle`, `UI:Refresh`, `UI:SelectCategory`, `UI:ResetPosition`, `UI:RestoreFromDB`, `UI:RestoreFilterCheckbox`, `UI:BuildCategoryList`, `UI:HighlightCategory`, `UI:BuildPool`, `UI:RelayoutGrid`, `UI:UpdateCooldowns` — all defined and called consistently
- `A.data.IterEntries`, `IsCategoryVisible`, `IsEntryVisible`, `IsEntryOwned`, `GetEntryCooldown`, `GetEntryIcon` — all defined and called consistently
- `A.minimap:Initialize`, `A.minimap.UpdatePosition` — defined and called consistently
- `AllPortalDB` keys: `framePoint`, `frameSize`, `lastCategory`, `filterOwnedOnly`, `minimap.angle`, `minimapHidden` — used consistently
