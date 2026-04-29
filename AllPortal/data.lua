local addonName, ns = ...

AllPortal = AllPortal or {}
local A = AllPortal
A.data = A.data or {}

-- ============================================================
-- Locale table
-- ============================================================
local locale = GetLocale()

local L = {
  enUS = {
    addon_title        = "AllPortal",
    current_season     = "Mythic+ Current Season",
    mage_portal        = "Portals & Teleports",
    toys               = "Toys",
    items              = "Items",
    misc               = "Other",
    mp_midnight        = "M+ Midnight",
    mp_tww             = "M+ The War Within",
    mp_df              = "M+ Dragonflight",
    mp_sl              = "M+ Shadowlands",
    mp_bfa             = "M+ Battle for Azeroth",
    mp_legion          = "M+ Legion",
    show_owned_only    = "Show owned only",
    close              = "Close",
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
    addon_title        = "올포탈",
    current_season     = "영웅의 길 한밤1 시즌",
    mage_portal        = "포탈",
    toys               = "장난감",
    items              = "아이템",
    misc               = "기타",
    mp_midnight        = "영웅의 길: 한밤",
    mp_tww             = "영웅의 길: 내부 전쟁",
    mp_df              = "영웅의 길: 용군단",
    mp_sl              = "영웅의 길: 어둠땅",
    mp_bfa             = "영웅의 길: 격전의 아제로스",
    mp_legion          = "영웅의 길: 군단",
    show_owned_only    = "사용 가능만 보기",
    close              = "닫기",
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

A.data.SEPARATOR_AFTER_INDEX = 5

-- ============================================================
-- Category items
--   Flat array  = { entry, entry, ... }
--   Grouped     = { {entry,...}, {entry,...}, ... }  (groups get visual separators)
--   Entry shape = { type="spell"|"toy"|"item", id=<number>, race=?, class=? }
--   id=0 entries are skipped at runtime (TBD placeholders)
-- ============================================================
A.data.categoryItems = {

  -- ── Current season M+ teleport spells ─────────────────────
  -- UPDATE THIS TABLE EACH SEASON PATCH.
  -- Confirm spellIDs: /dump GetSpellInfo(<id>) in-game
  current_season = {
    -- TBD: Midnight Season 1 dungeon teleport spellIDs
    -- { type = "spell", id = 0 },  -- 마법 학자의 정원
    -- { type = "spell", id = 0 },  -- 공결탑 제나스
    -- { type = "spell", id = 0 },  -- 샤론의 구덩이
    -- { type = "spell", id = 0 },  -- 삼두정의 권좌
    -- + rotation dungeons (Scholomance, Scarlet Monastery, etc.)
  },

  -- ── Mage portals & teleports ──────────────────────────────
  -- Hidden for non-Mages via classRequired on the category.
  -- Each city has a Portal (party) and Teleport (self) spell.
  mage_portal = {
    -- TBD: fill in Portal: <city> and Teleport: <city> spellIDs
    -- On a Mage: open spellbook, hover each portal/teleport → note spellID
    -- or use: /dump GetSpellInfo(<id>)
  },

  -- ── Toys ──────────────────────────────────────────────────
  toys = {
    {  -- G1: General hearthstones / movement toys
      { type = "toy",  id = 140192 },  -- 달라란 귀환석 (Dalaran Hearthstone)
      { type = "toy",  id = 0 },        -- TBD: 아르칸티나로 통하는 개인 열쇠
      { type = "item", id = 141605 },  -- 비행 조련사의 호루라기 (Flight Master's Whistle)
      { type = "toy",  id = 110560 },  -- 주둔지 귀환석 (Garrison Hearthstone)
    },
    {  -- G2: Undermine (구렁)
      { type = "toy", id = 0 },  -- TBD: 구렁 탐험가의 마나결속 에테르 관문
      { type = "toy", id = 0 },  -- TBD: 구렁로봇 7001
    },
    {  -- G3
      { type = "toy", id = 0 },  -- TBD: 불안정한 차원문 방출기
    },
    {  -- G4: Wormhole Generators (BfA era and later)
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

  -- ── Items (equip-and-use + direct use) ────────────────────
  items = {
    {  -- G1: Equip-and-use gear (tabards, rings, cloaks)
       -- First click equips if not equipped; second click uses the effect.
      { type = "item", id = 0 },  -- TBD: 충전식 리브스 전지
      { type = "item", id = 0 },  -- TBD: 은빛십자군 성전사의 휘장
      { type = "item", id = 0 },  -- TBD: 왕놋쇠 너클
      { type = "item", id = 0 },  -- TBD: 싸움꾼의 강력한 주먹질 반지
      { type = "item", id = 0 },  -- TBD: 사기꾼의 알록달곡 망토
      { type = "item", id = 0 },  -- TBD: 단결의 망토
      { type = "item", id = 0 },  -- TBD: 키린 토 반지
      { type = "item", id = 0 },  -- TBD: 헬스크림 세력단 휘장
    },
    {  -- G2: Trinkets / direct-use items
      { type = "item", id = 0 },  -- TBD: 잃어버린 시간의 유물 (장신구)
      { type = "item", id = 0 },  -- TBD: 칼날첨탑 성물
      { type = "item", id = 0 },  -- TBD: 제이나의 펜던트
      { type = "item", id = 0 },  -- TBD: 제독의 나침반
    },
  },

  -- ── Race-specific (기타) ───────────────────────────────────
  misc = {
    { type = "spell", id = 0, race = "Vulpera" },        -- TBD: 야영지 귀환 (spellID ~345396)
    { type = "spell", id = 0, race = "DarkIronDwarf" },  -- TBD: 굴착기 (spellID ~265225)
  },

  -- ── M+ teleports by expansion ─────────────────────────────
  -- Each entry is a flat list of teleport spellIDs for that expansion's dungeons.
  -- Wowhead: search "Path of the X Hero" achievement → reward spell IDs.
  mp_midnight = {},
  mp_tww      = {},
  mp_df       = {},
  mp_sl       = {},
  mp_bfa      = {},
  mp_legion   = {},
}

-- ============================================================
-- Helper: iterate entries of a category as (entry, groupIndex) pairs
-- ============================================================
function A.data.IterEntries(categoryId)
  local items = A.data.categoryItems[categoryId]
  if not items or #items == 0 then return function() end end

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
  if not entry.id or entry.id == 0 then return false end
  return true
end

-- ============================================================
-- Helper: is the entry "owned/usable" (used by the filter)?
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
-- Helper: cooldown query → start, duration
-- ============================================================
function A.data.GetEntryCooldown(entry)
  if entry.type == "spell" then
    local info = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(entry.id)
    if info then return info.startTime, info.duration end
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
