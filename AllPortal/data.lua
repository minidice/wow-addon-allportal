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
    current_season     = "Hero's Path: Midnight Season 1",
    mage_portal        = "Portals & Teleports",
    hearthstones       = "Hearthstones",
    toys               = "Toys",
    items              = "Items",
    use_items          = "Use Items",
    equip_items        = "Equipped Items",
    misc               = "Special",
    raids              = "Raids",
    mp_wrath           = "Hero's Path: Wrath of the Lich King",
    mp_cata            = "Hero's Path: Cataclysm",
    mp_mop             = "Hero's Path: Mists of Pandaria",
    mp_wod             = "Hero's Path: Warlords of Draenor",
    mp_legion          = "Hero's Path: Legion",
    mp_bfa             = "Hero's Path: Battle for Azeroth",
    mp_sl              = "Hero's Path: Shadowlands",
    mp_df              = "Hero's Path: Dragonflight",
    mp_tww             = "Hero's Path: The War Within",
    mp_midnight        = "Hero's Path: Midnight",
    show_unavailable  = "Show unavailable too",
    show_other_faction = "Show other faction",
    hearth_hint        = "Use the checkbox to add or remove an owned hearthstone from random hearth favorites.",
    hearth_fav_added   = "Added to random hearth favorites.",
    hearth_fav_removed = "Removed from random hearth favorites.",
    hearth_no_fav      = "No usable hearthstone items.",
    hearth_random      = "Random Hearth",
    hearth_random_tip  = "Uses one of your favorite hearthstones at random.",
    open_ui_tip        = "Click to open or close the AllPortal window.",
    actionbar_drag_tip = "Drag to an action bar to use it there.",
    search             = "Search",
    search_placeholder = "Search",
    select_all         = "Select All",
    select_results     = "Select Results",
    clear_all          = "Clear All",
    clear_search       = "Clear Search",
    open_ui            = "Open UI",
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
    empty_category     = "No entries yet.",
  },
  koKR = {
    addon_title        = "올포탈",
    current_season     = "영웅의 길: 한밤 1 시즌",
    mage_portal        = "포탈",
    hearthstones       = "귀환",
    toys               = "장난감",
    items              = "아이템",
    use_items          = "사용 아이템",
    equip_items        = "장비 아이템",
    misc               = "특수",
    raids              = "공격대",
    mp_wrath           = "영웅의 길: 리치 왕의 분노",
    mp_cata            = "영웅의 길: 대격변",
    mp_mop             = "영웅의 길: 판다리아의 안개",
    mp_wod             = "영웅의 길: 드레노어의 전쟁군주",
    mp_legion          = "영웅의 길: 군단",
    mp_bfa             = "영웅의 길: 격전의 아제로스",
    mp_sl              = "영웅의 길: 어둠땅",
    mp_df              = "영웅의 길: 용군단",
    mp_tww             = "영웅의 길: 내부 전쟁",
    mp_midnight        = "영웅의 길: 한밤",
    show_unavailable  = "사용 불가능도 보기",
    show_other_faction = "타진영도 보기",
    hearth_hint        = "습득한 귀환석의 체크박스로 무작위 귀환 즐겨찾기에 추가하거나 뺄 수 있습니다.",
    hearth_fav_added   = "무작위 귀환 즐겨찾기에 추가했습니다.",
    hearth_fav_removed = "무작위 귀환 즐겨찾기에서 제거했습니다.",
    hearth_no_fav      = "귀환 가능한 아이템이 없습니다.",
    hearth_random      = "무작위 귀환",
    hearth_random_tip  = "즐겨찾기한 귀환석 중 하나를 무작위로 사용합니다.",
    open_ui_tip        = "클릭하면 올포탈 창을 열거나 닫을 수 있습니다.",
    actionbar_drag_tip = "액션바에 드래그한 뒤에도 사용할 수 있습니다.",
    search             = "검색",
    search_placeholder = "검색",
    select_all         = "전체 선택",
    select_results     = "결과 선택",
    clear_all          = "전체 해제",
    clear_search       = "검색 지우기",
    open_ui            = "UI 열기",
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
    empty_category     = "아직 등록된 항목이 없습니다.",
  },
}

A.T = L[locale] or L.enUS

-- ============================================================
-- Category metadata (left-panel order)
-- ============================================================
A.data.categories = {
  { id = "current_season", labelKey = "current_season", isCurrentSeason = true },
  { id = "mage_portal",    labelKey = "mage_portal",    classRequired = "MAGE" },
  { id = "hearthstones",   labelKey = "hearthstones",   hasHearthHint = true },
  { id = "misc",           labelKey = "misc" },
  { id = "raids",          labelKey = "raids" },
  { id = "toys",           labelKey = "toys" },
  { id = "use_items",      labelKey = "use_items" },
  { id = "equip_items",    labelKey = "equip_items" },
  -- separator drawn between index 8 and 9 in UI
  { id = "mp_midnight",    labelKey = "mp_midnight" },
  { id = "mp_tww",         labelKey = "mp_tww" },
  { id = "mp_df",          labelKey = "mp_df" },
  { id = "mp_sl",          labelKey = "mp_sl" },
  { id = "mp_bfa",         labelKey = "mp_bfa" },
  { id = "mp_legion",      labelKey = "mp_legion" },
  { id = "mp_wod",         labelKey = "mp_wod" },
  { id = "mp_mop",         labelKey = "mp_mop" },
  { id = "mp_cata",        labelKey = "mp_cata" },
  { id = "mp_wrath",       labelKey = "mp_wrath" },
}

A.data.SEPARATOR_AFTER_INDEX = 8

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
    { type = "spell", id = 1254572, name = "마법 학자의 정원", enName = "Magisters' Terrace" },
    { type = "spell", id = 1254563, name = "공결탑 제나스", enName = "Nexus-Point Xenas" },
    { type = "spell", id = 159898, name = "하늘탑", enName = "Skyreach" },
    { type = "spell", id = 1254400, name = "윈드러너 첨탑", enName = "Windrunner Spire" },
    { type = "spell", id = 393273, name = "알게타르 대학", enName = "Algeth'ar Academy" },
    { type = "spell", id = 1254559, name = "마이사라 동굴", enName = "Maisara Caverns" },
    { type = "spell", id = 1254555, name = "사론의 구덩이", enName = "Pit of Saron" },
    { type = "spell", id = 1254551, name = "삼두정의 권좌", enName = "Seat of the Triumvirate" },
  },

  -- ── Raid teleports ────────────────────────────────────────
  raids = {
    { type = "spell", id = 1239155, name = "마나괴철로 종극점", enName = "Manaforge Omega" },
    { type = "spell", id = 1226482, name = "언더마인 해방전선", enName = "Liberation of Undermine" },
    { type = "spell", id = 432258, name = "꿈의 희망 아미드랏실", enName = "Amirdrassil, the Dream's Hope" },
    { type = "spell", id = 432257, name = "어둠의 도가니 아베루스", enName = "Aberrus, the Shadowed Crucible" },
    { type = "spell", id = 432254, name = "헌신의 금고", enName = "Vault of the Incarnates" },
    { type = "spell", id = 373192, name = "태초의 존재의 매장터", enName = "Sepulcher of the First Ones" },
    { type = "spell", id = 373191, name = "지배의 성소", enName = "Sanctum of Domination" },
    { type = "spell", id = 373190, name = "나스리아 성채", enName = "Castle Nathria" },
  },

  -- ── Mage portals & teleports ──────────────────────────────
  -- Hidden for non-Mages via classRequired on the category.
  -- Each city has a Portal (party) and Teleport (self) spell.
  mage_portal = {
    { type = "spellPair", faction = "Alliance", name = "스톰윈드",
      spells = { { type = "spell", id = 3561 }, { type = "spell", id = 10059 } } },
    { type = "spellPair", faction = "Alliance", name = "아이언포지",
      spells = { { type = "spell", id = 3562 }, { type = "spell", id = 11416 } } },
    { type = "spellPair", faction = "Alliance", name = "다르나서스",
      spells = { { type = "spell", id = 3565 }, { type = "spell", id = 11419 } } },
    { type = "spellPair", faction = "Alliance", name = "엑소다르",
      spells = { { type = "spell", id = 32271 }, { type = "spell", id = 32266 } } },
    { type = "spellPair", faction = "Alliance", name = "테라모어",
      spells = { { type = "spell", id = 49359 }, { type = "spell", id = 49360 } } },
    { type = "spellPair", faction = "Alliance", name = "샤트라스",
      spells = { { type = "spell", id = 33690 }, { type = "spell", id = 33691 } } },
    { type = "spellPair", faction = "Alliance", name = "톨 바라드",
      spells = { { type = "spell", id = 88342 }, { type = "spell", id = 88345 } } },
    { type = "spellPair", faction = "Alliance", name = "일곱 별의 제단",
      spells = { { type = "spell", id = 132621 }, { type = "spell", id = 132620 } } },
    { type = "spellPair", faction = "Alliance", name = "폭풍방패",
      spells = { { type = "spell", id = 176248 }, { type = "spell", id = 176246 } } },
    { type = "spellPair", faction = "Alliance", name = "보랄러스",
      spells = { { type = "spell", id = 281403 }, { type = "spell", id = 281400 } } },

    { type = "spellPair", faction = "Horde", name = "오그리마",
      spells = { { type = "spell", id = 3567 }, { type = "spell", id = 11417 } } },
    { type = "spellPair", faction = "Horde", name = "언더시티",
      spells = { { type = "spell", id = 3563 }, { type = "spell", id = 11418 } } },
    { type = "spellPair", faction = "Horde", name = "썬더 블러프",
      spells = { { type = "spell", id = 3566 }, { type = "spell", id = 11420 } } },
    { type = "spellPair", faction = "Horde", name = "실버문 (불타는 성전)",
      spells = { { type = "spell", id = 32272 }, { type = "spell", id = 32267 } } },
    { type = "spellPair", faction = "Horde", name = "샤트라스",
      spells = { { type = "spell", id = 35715 }, { type = "spell", id = 35717 } } },
    { type = "spellPair", faction = "Horde", name = "스토나드",
      spells = { { type = "spell", id = 49358 }, { type = "spell", id = 49361 } } },
    { type = "spellPair", faction = "Horde", name = "톨 바라드",
      spells = { { type = "spell", id = 88344 }, { type = "spell", id = 88346 } } },
    { type = "spellPair", faction = "Horde", name = "두 달의 제단",
      spells = { { type = "spell", id = 132627 }, { type = "spell", id = 132626 } } },
    { type = "spellPair", faction = "Horde", name = "전쟁의 창",
      spells = { { type = "spell", id = 176242 }, { type = "spell", id = 176244 } } },
    { type = "spellPair", faction = "Horde", name = "다자알로",
      spells = { { type = "spell", id = 281404 }, { type = "spell", id = 281402 } } },

    { type = "spellPair", name = "달라란 (노스렌드)",
      spells = { { type = "spell", id = 53140 }, { type = "spell", id = 53142 } } },
    { type = "spellPair", name = "달라란 분화구",
      spells = { { type = "spell", id = 120145 }, { type = "spell", id = 120146 } } },
    { type = "spellPair", name = "수호자의 전당",
      spells = { { type = "spell", id = 193759 } } },
    { type = "spellPair", name = "달라란 (부서진 섬)",
      spells = { { type = "spell", id = 224869 }, { type = "spell", id = 224871 } } },
    { type = "spellPair", name = "오리보스",
      spells = { { type = "spell", id = 344587 }, { type = "spell", id = 344597 } } },
    { type = "spellPair", name = "발드라켄",
      spells = { { type = "spell", id = 395277 }, { type = "spell", id = 395289 } } },
    { type = "spellPair", name = "도르노갈",
      spells = { { type = "spell", id = 446540 }, { type = "spell", id = 446534 } } },
    { type = "spellPair", name = "실버문",
      spells = { { type = "spell", id = 1259190 }, { type = "spell", id = 1259194 } } },
  },

  hearthstones = {},

  -- ── Toys ──────────────────────────────────────────────────
  toys = {
    {  --  General hearthstones / movement toys
	  { type = "toy", id = 266370, name = "둔둔의 풍요로운 이동 수단" },
      { type = "toy", id = 253629, name = "아르칸티나로 통하는 개인 열쇠" },
	  { type = "toy", id = 243056, name = "구렁 탐험가의 마나결속 에테르 관문" },  
	  { type = "toy", id = 141605, name = "비행 조련사의 호루라기" },
      { type = "toy", id = 230850, name = "구렁로봇 7001" },
	  { type = "toy", id = 153004, name = "불안정한 차원문 방출기" },
	  { type = "toy", id = 140192, name = "달라란 귀환석" },
      { type = "toy", id = 110560, name = "주둔지 귀환석" },
	  { type = "toy", id = 151016, name = "균열난 강령술사의 해골"},
      { type = "toy", id = 129929, name = "끊임없이 변화하는 거울"},
	  { type = "toy", id = 64457, name = "마지막 아르거스 유물"},
	  { type = "toy", id = 205255, name = "니펜 굴착 반장갑" },		  
	  { type = "toy", id = 140324, name = "이동식 이동술 신호 장치" },	  
	  { type = "toy", id = 169297, faction = "Alliance", name = "스톰파이크 휘장" },	  
	  { type = "toy", id = 169298, faction = "Horde", name = "서리늑대 휘장" },	  
	  { type = "toy", id = 136849, name = "자연의 손짓" },  
	  
    },
    {  -- Wormhole Generators (newer)
      { type = "toy", id = 248485, name = "웜홀 생성기: 쿠엘탈라스" },
      { type = "toy", id = 221966, name = "웜홀 생성기: 카즈 알가르" },	
      { type = "toy", id = 198156, name = "지룡 구멍 생성기: 용의 섬" },		
      { type = "toy", id = 172924, name = "웜홀 생성기: 어둠땅" },	
      { type = "toy", id = 168808, name = "웜홀 생성기: 잔달라" },	  
      { type = "toy", id = 168807, name = "웜홀 생성기: 쿨 티라스" },	  
      { type = "toy", id = 151652, name = "웜홀 생성기: 아르거스" },
      { type = "toy", id = 112059, name = "웜홀 원심 분리기" },
      { type = "toy", id = 87215, name = "웜홀 생성기: 판다리아" },
      { type = "toy", id = 48933, name = "웜홀 생성기: 노스랜드" }, 
	  { type = "toy", id = 30542, name = "차원 분할기: 52번 구역" },
	  { type = "toy", id = 30544, name = "안전보증 순간이동기: 토쉴리의 연구기지" },
	  { type = "toy", id = 18986, name = "안전보증 순간이동기: 가젯잔" },
	  { type = "toy", id = 18984, name = "안전보증 순간이동기: 눈망루 마을" },
    },

  },

  -- ── Direct-use items ──────────────────────────────────────
  use_items = {
    { type = "item", id = 144341, name = "충전식 리브스 전지", useKind = "use" },
    { type = "item", id = 128353, name = "제독의 나침반", useKind = "use" },
    { type = "item", id = 118662, faction = "Horde", name = "카라보르 성물", useKind = "use" },
    { type = "item", id = 118663, faction = "Alliance", name = "칼날첨탑 성물", useKind = "use" },
	{ type = "item", id = 52251, name = "제이나의 펜던트", useKind = "use" },
	{ type = "item", id = 37863, name = "다이어브루의 원격 조정기", useKind = "use" },	
  },

  -- ── Equip-and-use items ───────────────────────────────────
  equip_items = {
    {  -- Common gear
      { type = "item", id = 46874, name = "은빛십자군 성전사의 휘장", useKind = "equip" },
	  { type = "item", id = 63379, faction = "Alliance", name = "바라딘 감시대 휘장", useKind = "equip" },
      { type = "item", id = 63378, faction = "Horde", name = "헬스크림 세력단 휘장", useKind = "equip" },
    },
	
    {  -- 싸움꾼
      { type = "item", id = 95051, faction = "Alliance", name = "왕놋쇠 너클", useKind = "equip" },
      { type = "item", id = 95050, faction = "Horde", name = "왕놋쇠 너클", useKind = "equip" },
      { type = "item", id = 144391, faction = "Alliance", name = "싸움꾼의 강력한 주먹질 반지", useKind = "equip" },
      { type = "item", id = 144392, faction = "Horde", name = "싸움꾼의 강력한 주먹질 반지", useKind = "equip" },
    },		
	
    {  -- 격전의 아제로스
	  { type = "item", id = 166560, faction = "Alliance", name = "선장의 지휘 인장", useKind = "equip" },
      { type = "item", id = 166559, faction = "Horde", name = "사령관의 전투 인장", useKind = "equip" },
	},
	
    {  -- 군단
	   { type = "item", id = 139599, name = "키린 토의 힘이 깃든 반지", useKind = "equip" },		
	   { type = "item", id = 142469, name = "대마법사의 보랏빛 인장", useKind = "equip" },	
	},

    {  -- 판다리아
	   { type = "item", id = 103678, name = "잃어버린 시간의 유물", useKind = "equip" },
	},
		
    {  -- 리치왕의 분노
	  -- 힘
      { type = "item", id = 51559, name = "룬이 새겨진 키린 토 반지", useKind = "equip" },
      { type = "item", id = 48956, name = "글이 새겨진 키린 토 반지", useKind = "equip" },
      { type = "item", id = 45690, name = "문자가 새겨진 키린 토 반지", useKind = "equip" },
      { type = "item", id = 44935, name = "키린 토 반지", useKind = "equip" },

	  -- 민첩
      { type = "item", id = 51560, name = "룬이 새겨진 키린 토 고리", useKind = "equip" },
      { type = "item", id = 48954, name = "글이 새겨진 키린 토 고리", useKind = "equip" },
      { type = "item", id = 45688, name = "문자가 새겨진 키린 토 고리", useKind = "equip" },
      { type = "item", id = 40586, name = "키린 토 고리", useKind = "equip" },

	  -- 지능
      { type = "item", id = 51557, name = "룬이 새겨진 키린 토의 인장", useKind = "equip" },
      { type = "item", id = 48955, name = "글이 새겨진 키린 토의 인장", useKind = "equip" },
	  { type = "item", id = 45691, name = "문자가 새겨진 키린 토의 인장", useKind = "equip" },	  
      { type = "item", id = 40585, name = "키린 토의 인장", useKind = "equip" },
		
	  -- 지능
      { type = "item", id = 51558, name = "룬이 새겨진 키린 토 실반지", useKind = "equip" },
      { type = "item", id = 48957, name = "글이 새겨진 키린 토 실반지", useKind = "equip" },
      { type = "item", id = 45689, name = "문자가 새겨진 키린 토 실반지", useKind = "equip" },  
      { type = "item", id = 44934, name = "키린 토 실반지 ", useKind = "equip" },
    },	
	
	{  -- 길드
      { type = "item", id = 65360, faction = "Alliance", name = "단결의 망토", useKind = "equip" },
      { type = "item", id = 65274, faction = "Horde", name = "단결의 망토", useKind = "equip" },
      { type = "item", id = 63206, faction = "Alliance", name = "합일의 등싸개", useKind = "equip" },
      { type = "item", id = 63207, faction = "Horde", name = "합일의 등싸개", useKind = "equip" },
      { type = "item", id = 63352, faction = "Alliance", name = "협동의 쓰개", useKind = "equip" },
      { type = "item", id = 63353, faction = "Horde", name = "협동의 쓰개", useKind = "equip" },
    },
	
  },

  -- ── Special class/race utilities ──────────────────────────
  misc = {
    { type = "house", id = 1233637, icon = 7726459, zoneId = 2351, name = "하우스 (호드)", enName = "Teleport Home: Horde" },
    { type = "house", id = 1233637, icon = 7726459, zoneId = 2352, name = "하우스 (얼라이언스)", enName = "Teleport Home: Alliance" },
    { type = "spell", id = 193753, class = "DRUID", name = "꿈길걸음" },
    { type = "spell", id = 50977, class = "DEATHKNIGHT", name = "죽음의 관문" },
    { type = "spell", id = 126892, class = "MONK", name = "순례" },
    { type = "spell", id = 698, class = "WARLOCK", name = "소환 의식", enName = "Ritual of Summoning" },
    { type = "spell", id = 556, class = "SHAMAN", name = "영혼의 귀환", enName = "Astral Recall" },
	
    { type = "spell", id = 312370, race = "Vulpera", name = "야영지 만들기" },
    { type = "spell", id = 312372, race = "Vulpera", name = "야영지 귀환" },
    { type = "spell", id = 265225, race = "DarkIronDwarf", name = "굴착기" },
  },

  -- ── Hero's Path teleports by expansion ────────────────────
  mp_wrath = {
    { type = "spell", id = 1254555, name = "사론의 구덩이", enName = "Pit of Saron" },
  },
  mp_cata = {
    { type = "spell", id = 410080, name = "소용돌이 누각", enName = "The Vortex Pinnacle" },
    { type = "spell", id = 424142, name = "파도의 왕좌", enName = "Throne of the Tides" },
    { type = "spell", id = 445424, name = "그림 바툴", enName = "Grim Batol" },
  },
  mp_mop = {
    { type = "spell", id = 131204, name = "옥룡사", enName = "Temple of the Jade Serpent" },
    { type = "spell", id = 131205, name = "스톰스타우트 양조장", enName = "Stormstout Brewery" },
    { type = "spell", id = 131206, name = "음영파 수도원", enName = "Shado-Pan Monastery" },
    { type = "spell", id = 131222, name = "모구샨 궁전", enName = "Mogu'shan Palace" },
    { type = "spell", id = 131225, name = "석양의 문", enName = "Gate of the Setting Sun" },
    { type = "spell", id = 131229, name = "붉은십자군 수도원", enName = "Scarlet Monastery" },
    { type = "spell", id = 131231, name = "붉은십자군 전당", enName = "Scarlet Halls" },
    { type = "spell", id = 131232, name = "스칼로맨스", enName = "Scholomance" },
    { type = "spell", id = 131228, name = "나우짜오 사원 공성전투", enName = "Siege of Niuzao Temple" },
  },
  mp_wod = {
    { type = "spell", id = 159896, name = "강철 선착장", enName = "Iron Docks" },
    { type = "spell", id = 159900, name = "파멸철로 정비소", enName = "Grimrail Depot" },
    { type = "spell", id = 159899, name = "어둠달 지하묘지", enName = "Shadowmoon Burial Grounds" },
    { type = "spell", id = 159898, name = "하늘탑", enName = "Skyreach" },
    { type = "spell", id = 159901, name = "상록숲", enName = "Everbloom" },
  },
  mp_legion = {
    { type = "spell", id = 373262, name = "카라잔", enName = "Karazhan" },
    { type = "spell", id = 393764, name = "용맹의 전당", enName = "Halls of Valor" },
    { type = "spell", id = 393766, name = "별의 궁정", enName = "Court of Stars" },
    { type = "spell", id = 410078, name = "넬타리온의 둥지", enName = "Neltharion's Lair" },
    { type = "spell", id = 424153, name = "검은 떼까마귀 요새", enName = "Black Rook Hold" },
    { type = "spell", id = 424163, name = "어둠심장 숲", enName = "Darkheart Thicket" },
    { type = "spell", id = 1254551, name = "삼두정의 권좌", enName = "Seat of the Triumvirate" },
  },
  mp_bfa = {
    { type = "spell", id = 373274, name = "작전명: 메카곤", enName = "Operation: Mechagon - Workshop" },
    { type = "spell", id = 410071, name = "자유지대", enName = "Freehold" },
    { type = "spell", id = 410074, name = "썩은굴", enName = "The Underrot" },
    { type = "spell", id = 424167, name = "웨이크레스트 저택", enName = "Waycrest Manor" },
    { type = "spell", id = 424187, name = "아탈다자르", enName = "Atal'Dazar" },
    { type = "spell", id = 445418, faction = "Horde", name = "보랄러스 공성전", enName = "Siege of Boralus" },
    { type = "spell", id = 464256, faction = "Alliance", name = "보랄러스 공성전", enName = "Siege of Boralus" },
    { type = "spell", id = 467555, faction = "Horde", name = "왕노다지 광산!!", enName = "The MOTHERLODE!!" },
    { type = "spell", id = 467553, faction = "Alliance", name = "왕노다지 광산!!", enName = "The MOTHERLODE!!" },
  },
  mp_sl = {
    { type = "spell", id = 354465, name = "속죄의 전당", enName = "Halls of Atonement" },
    { type = "spell", id = 354464, name = "티르너 사이드의 안개", enName = "Mists of Tirna Scithe" },
    { type = "spell", id = 354463, name = "역병 몰락지", enName = "Plaguefall" },
    { type = "spell", id = 354467, name = "고통의 투기장", enName = "Theater of Pain" },
    { type = "spell", id = 354468, name = "저편", enName = "De Other Side" },
    { type = "spell", id = 354469, name = "핏빛 심연", enName = "Sanguine Depths" },
    { type = "spell", id = 0, name = "승천의 첨탑", enName = "Spires of Ascension" },
    { type = "spell", id = 354462, name = "죽음의 상흔", enName = "The Necrotic Wake" },
    { type = "spell", id = 367416, name = "미지의 시장 타자베쉬", enName = "Tazavesh" },
  },
  mp_df = {
    { type = "spell", id = 393273, name = "알게타르 대학", enName = "Algeth'ar Academy" },
    { type = "spell", id = 393256, name = "루비 생명의 웅덩이", enName = "Ruby Life Pools" },
    { type = "spell", id = 393279, name = "하늘빛 보관소", enName = "The Azure Vault" },
    { type = "spell", id = 393262, name = "노쿠드 공격대", enName = "The Nokhud Offensive" },
    { type = "spell", id = 393276, name = "넬타루스", enName = "Neltharus" },
    { type = "spell", id = 393283, name = "주입의 전당", enName = "Halls of Infusion" },
    { type = "spell", id = 393267, name = "담쟁이가죽 골짜기", enName = "Brackenhide Hollow" },
    { type = "spell", id = 393222, name = "울다만: 티르의 유산", enName = "Uldaman: Legacy of Tyr" },
    { type = "spell", id = 424197, name = "무한의 여명", enName = "Dawn of the Infinite" },
  },
  mp_tww = {
    { type = "spell", id = 445417, name = "메아리의 도시 아라카라", enName = "Ara-Kara, City of Echoes" },
    { type = "spell", id = 445440, name = "잿불맥주 양조장", enName = "Cinderbrew Meadery" },
    { type = "spell", id = 1237215, name = "생태지구 알다니", enName = "Eco-Dome Al'dani" },
    { type = "spell", id = 445416, name = "실타래의 도시", enName = "City of Threads" },
    { type = "spell", id = 445414, name = "새벽인도자호", enName = "The Dawnbreaker" },
    { type = "spell", id = 445269, name = "바위금고", enName = "The Stonevault" },
    { type = "spell", id = 445444, name = "신성한 불꽃의 수도원", enName = "Priory of the Sacred Flame" },
    { type = "spell", id = 445441, name = "어둠불꽃 동굴", enName = "Darkflame Cleft" },
    { type = "spell", id = 1216786, name = "수문", enName = "Operation: Floodgate" },
    { type = "spell", id = 445443, name = "부화장", enName = "The Rookery" },
  },
  mp_midnight = {
    { type = "spell", id = 1254572, name = "마법 학자의 정원", enName = "Magisters' Terrace" },
    { type = "spell", id = 1254563, name = "공결탑 제나스", enName = "Nexus-Point Xenas" },
    { type = "spell", id = 1254400, name = "윈드러너 첨탑", enName = "Windrunner Spire" },
    { type = "spell", id = 1254559, name = "마이사라 동굴", enName = "Maisara Caverns" },
  },
}

local housesByZone = {}
A.data.housesByZone = housesByZone

function A.data.UpdateHouses(houses)
  wipe(housesByZone)
  if not houses or not C_Housing or not C_Housing.GetUIMapIDForNeighborhood then return end

  for _, house in ipairs(houses) do
    local zone = C_Housing.GetUIMapIDForNeighborhood(house.neighborhoodGUID)
    if zone then housesByZone[zone] = house end
  end
end

function A.data.RequestHouses()
  if C_Housing and C_Housing.GetPlayerOwnedHouses then
    pcall(C_Housing.GetPlayerOwnedHouses)
  end
end

function A.data.GetEntryKey(entry)
  if not entry then return nil end
  return (entry.type or "entry") .. ":" .. tostring(entry.id or 0)
end

function A.data.IsHearthFavorite(entry)
  local key = A.data.GetEntryKey(entry)
  return key and AllPortalDB and AllPortalDB.hearthFavorites and AllPortalDB.hearthFavorites[key]
end

function A.data.IsBaseHearthstone(entry)
  return entry and entry.type == "item" and entry.id == 6948
end

function A.data.ToggleHearthFavorite(entry)
  if not entry or not entry.hearthstone or A.data.IsBaseHearthstone(entry) or not A.data.IsEntryOwned(entry) then return nil end
  AllPortalDB = AllPortalDB or {}
  AllPortalDB.hearthFavorites = AllPortalDB.hearthFavorites or {}
  local key = A.data.GetEntryKey(entry)
  if AllPortalDB.hearthFavorites[key] then
    AllPortalDB.hearthFavorites[key] = nil
    return false
  end
  AllPortalDB.hearthFavorites[key] = true
  return true
end

function A.data.GetUsableFavoriteHearthstones()
  local result = {}
  if not AllPortalDB or not AllPortalDB.hearthFavorites then return result end
  for entry in A.data.IterEntries("hearthstones") do
    local key = A.data.GetEntryKey(entry)
    if key and AllPortalDB.hearthFavorites[key] and not A.data.IsBaseHearthstone(entry) and A.data.IsEntryOwned(entry) then
      tinsert(result, entry)
    end
  end
  return result
end

function A.data.GetUsableHearthstoneToys()
  local result = {}
  for entry in A.data.IterEntries("hearthstones") do
    if entry.type == "toy" and not A.data.IsBaseHearthstone(entry) and A.data.IsEntryVisible(entry) and A.data.IsEntryOwned(entry) then
      tinsert(result, entry)
    end
  end
  return result
end

function A.data.GetBaseHearthstone()
  for entry in A.data.IterEntries("hearthstones") do
    if A.data.IsBaseHearthstone(entry) then return entry end
  end
  return nil
end

do
  local portals = A.data.categoryItems.mage_portal
  if portals then
    for i = 1, math.floor(#portals / 2) do
      local j = #portals - i + 1
      portals[i], portals[j] = portals[j], portals[i]
    end
  end
end

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
  if entry.type == "spellPair" then
    if entry.faction then
      local faction = UnitFactionGroup("player")
      if faction ~= entry.faction and not (AllPortalDB and AllPortalDB.showOtherFaction) then return false end
    end
    if entry.class then
      local _, classFile = UnitClass("player")
      if classFile ~= entry.class then return false end
    end
    if not entry.spells or #entry.spells == 0 then return false end
    for _, spell in ipairs(entry.spells) do
      if spell.id and spell.id > 0 then return true end
    end
    return false
  end

  if entry.race then
    local _, raceFile = UnitRace("player")
    if raceFile ~= entry.race then return false end
  end
  if entry.faction then
    local faction = UnitFactionGroup("player")
    if faction ~= entry.faction and not (AllPortalDB and AllPortalDB.showOtherFaction) then return false end
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
  if entry.type == "spellPair" then
    for _, spell in ipairs(entry.spells or {}) do
      if spell.id and IsPlayerSpell(spell.id) then return true end
    end
    return false
  elseif entry.type == "spell" then
    return IsPlayerSpell(entry.id)
  elseif entry.type == "toy" then
    return PlayerHasToy(entry.id) and C_ToyBox.IsToyUsable(entry.id)
  elseif entry.type == "item" then
    return GetItemCount(entry.id, false) > 0 or IsEquippedItem(entry.id)
  elseif entry.type == "house" then
    return housesByZone[entry.zoneId] ~= nil
  end
  return false
end

-- ============================================================
-- Helper: cooldown query → start, duration
-- ============================================================
function A.data.GetEntryCooldown(entry)
  if entry.type == "spellPair" then
    return 0, 0
  elseif entry.type == "spell" then
    local info = C_Spell and C_Spell.GetSpellCooldown and C_Spell.GetSpellCooldown(entry.id)
    if info then return info.startTime, info.duration end
    local s, d = GetSpellCooldown(entry.id)
    return s or 0, d or 0
  elseif entry.type == "house" then
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
  if entry.icon then return entry.icon end

  if entry.type == "spellPair" then
    local first = entry.spells and entry.spells[1]
    if first then return A.data.GetEntryIcon(first) end
    return nil
  end

  if entry.type == "spell" or entry.type == "house" then
    if C_Spell and C_Spell.GetSpellTexture then
      return C_Spell.GetSpellTexture(entry.id)
    end
    return GetSpellTexture(entry.id)
  else
    return C_Item.GetItemIconByID(entry.id)
  end
end

-- ============================================================
-- Helper: display name for an entry
-- ============================================================
local function GetDefaultEntryName(entry)
  if entry.type == "spellPair" then
    local first = entry.spells and entry.spells[1]
    if first then return GetDefaultEntryName(first) end
    return nil
  end
  if entry.type == "spell" or entry.type == "house" then
    if C_Spell and C_Spell.GetSpellInfo then
      local info = C_Spell.GetSpellInfo(entry.id)
      if info and info.name then return info.name end
    end
    local name = GetSpellInfo and GetSpellInfo(entry.id)
    if name then return name end
  elseif entry.type == "toy" then
    if C_ToyBox and C_ToyBox.GetToyInfo then
      local _, toyName = C_ToyBox.GetToyInfo(entry.id)
      if toyName then return toyName end
    end
  end

  if C_Item and C_Item.GetItemInfo then
    local item = C_Item.GetItemInfo(entry.id)
    if item then return item end
  end
  local itemName = GetItemInfo and GetItemInfo(entry.id)
  return itemName
end

function A.data.RequestEntryNames()
  local requestItem = C_Item and C_Item.RequestLoadItemDataByID

  for _, cat in ipairs(A.data.categories or {}) do
    for entry in A.data.IterEntries(cat.id) do
      if entry.type == "spellPair" then
        for _, spell in ipairs(entry.spells or {}) do
          if spell.id and C_Spell and C_Spell.GetSpellInfo then
            C_Spell.GetSpellInfo(spell.id)
          elseif spell.id and GetSpellInfo then
            GetSpellInfo(spell.id)
          end
        end
      elseif entry.type == "spell" or entry.type == "house" then
        if entry.id and C_Spell and C_Spell.GetSpellInfo then
          C_Spell.GetSpellInfo(entry.id)
        elseif entry.id and GetSpellInfo then
          GetSpellInfo(entry.id)
        end
      elseif (entry.type == "toy" or entry.type == "item") and entry.id and entry.id > 0 then
        if requestItem then requestItem(entry.id) end
        if GetItemInfo then GetItemInfo(entry.id) end
        if entry.type == "toy" and C_ToyBox and C_ToyBox.GetToyInfo then
          C_ToyBox.GetToyInfo(entry.id)
        end
      end
    end
  end
end

function A.data.GetEntryName(entry)
  if locale == "koKR" then
    if entry.name then return entry.name end
    local defaultName = GetDefaultEntryName(entry)
    return defaultName or tostring(entry.id)
  end

  if entry.enName then return entry.enName end
  local defaultName = GetDefaultEntryName(entry)
  if defaultName then return defaultName end
  if entry.type == "toy" or entry.type == "item" then
    return tostring(entry.id)
  end
  return entry.name or tostring(entry.id)
end

function A.data.GetEntryActionName(entry)
  return GetDefaultEntryName(entry) or A.data.GetEntryName(entry)
end

function A.data.GetEntryDisplayName(entry)
  local name = A.data.GetEntryName(entry)
  if entry.type == "item" and entry.useKind == "equip" then
    if locale == "koKR" then
      return name .. " · 장착"
    end
    return name .. " · Equip"
  end
  return name
end

function A.data.IsOtherFactionEntry(entry)
  if entry.faction then
    local faction = UnitFactionGroup("player")
    return faction ~= entry.faction
  end
  return false
end
