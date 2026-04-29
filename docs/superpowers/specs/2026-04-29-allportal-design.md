# AllPortal — 와우 애드온 설계 문서

- **상태**: 설계 확정
- **작성일**: 2026-04-29
- **대상 클라이언트**: World of Warcraft Retail (현재 시즌: 한밤 시즌 1)
- **지원 로케일**: koKR (1차), enUS (2차, 폴백)
- **외부 라이브러리**: 없음 (순수 Blizzard API)

## 1. 개요

블리자드의 "Mythic Dungeon Portals" 창과 비슷한 형태의 통합 포탈 툴바. 신화+ 텔레포트뿐 아니라 **마법사 포탈/순간이동 주문, 장난감, 사용 아이템, 종족 한정 항목**까지 한 창에서 좌클릭으로 시전·사용한다.

### 1.1 핵심 요구사항

- 메인 창: 좌측 카테고리 패널 + 우측 항목 그리드
- 좌클릭으로 즉시 시전/사용 (보안 버튼)
- "사용 가능만 보기" 필터 체크박스 (좌상단)
- 쿨타임 중인 항목은 시계 오버레이 + 남은 시간 텍스트 표시
- 미니맵 버튼으로 창 토글 (테두리 위만 따라 드래그)
- 슬래시 명령어 `/allportal`
- 직업/종족 조건에 맞는 카테고리·항목만 노출
- 메인 창 크기 조절 가능, 그리드는 폭에 맞춰 컬럼 자동 재계산

### 1.2 비포함 사항 (v1 범위 밖)

- 항목별 사용자 숨김/순서 조정 (고정 리스트)
- 우클릭 동작 (좌클릭 시전만)
- 별도 GUI 옵션창 (모든 토글은 슬래시 명령어로)
- 즐겨찾기, 검색, 카테고리 추가

## 2. 파일 구조

```
D:\Project\wowaddon\allportal\
└── AllPortal\                    # 와우 애드온 폴더 (그대로 _retail_/Interface/AddOns에 복사)
    ├── allportal.toc             # 매니페스트
    ├── core.lua                  # 진입점, 이벤트, SavedVariables, 슬래시
    ├── data.lua                  # 카테고리/항목 정의, 로케일 라벨 테이블
    ├── ui.lua                    # 메인 프레임, 카테고리 패널, 그리드, 보안 버튼 풀
    ├── minimap.lua               # 미니맵 버튼
    └── bindings.xml              # 키바인딩 등록
```

### 2.1 모듈 책임

| 파일 | 책임 | 노출 |
|---|---|---|
| `core.lua` | 이벤트 등록, 디스패치. SavedVariables 로드/저장. 슬래시. 전투 lockdown 큐. | `AllPortal` 글로벌 (단일 네임스페이스 테이블) |
| `data.lua` | `AllPortal.data.categories`, `AllPortal.data.categoryItems`, 로케일 테이블 `T` | `AllPortal.data`, `AllPortal.T` |
| `ui.lua` | `AllPortal.ui:Show/Hide/Toggle()`, 보안 버튼 풀, 카테고리 전환, 그리드 재배치 | `AllPortal.ui` |
| `minimap.lua` | 미니맵 버튼 생성, 각도 기반 테두리 드래그, 표시/숨김 | `AllPortal.minimap` |

### 2.2 TOC 파일

```toc
## Interface: 110200
## Title: AllPortal
## Title-koKR: 올포탈
## Notes: Toolbar for portals, toys and use items
## Notes-koKR: 포탈, 장난감, 사용 아이템 통합 툴바
## Author: psmtopsm
## Version: 1.0.0
## SavedVariables: AllPortalDB

data.lua
core.lua
minimap.lua
ui.lua
bindings.xml
```

(Interface 번호는 구현 시점의 와우 빌드에 맞춰 갱신)

## 3. 데이터 모델

### 3.1 항목(Item Entry) 스키마

```lua
{
  type   = "spell" | "toy" | "item",   -- 사용/검사 메서드 결정
  id     = 123456,                     -- spellID(spell) 또는 itemID(toy/item)
  race   = "Vulpera",                  -- 선택. 이 종족일 때만 노출
  class  = "MAGE",                     -- 선택. 이 직업일 때만 노출
}
```

### 3.2 카테고리 스키마 및 목록

```lua
{
  id = "<category_id>",
  labelKey = "<L_table_key>",       -- 로케일 테이블 키
  classRequired = "MAGE",           -- 선택. 카테고리 자체 노출 가드
  racesRequired = {"Vulpera",...},  -- 선택. 카테고리 자체 노출 가드 (목록에 포함되어야 함)
  isCurrentSeason = true,           -- 선택. 시즌 패치 때 갱신 대상 표식
}
```

```lua
AllPortal.data.categories = {
  { id = "current_season", labelKey = "current_season", isCurrentSeason = true },
  { id = "mage_portal",    labelKey = "mage_portal",    classRequired = "MAGE" },
  { id = "toys",           labelKey = "toys" },
  { id = "items",          labelKey = "items" },
  { id = "misc",           labelKey = "misc",
    racesRequired = { "Vulpera", "DarkIronDwarf" } },
  -- 좌측 패널에서 위 5개 ↔ 아래 6개 사이에 가는 구분선
  { id = "mp_midnight",    labelKey = "mp_midnight" },
  { id = "mp_tww",         labelKey = "mp_tww" },
  { id = "mp_df",          labelKey = "mp_df" },
  { id = "mp_sl",          labelKey = "mp_sl" },
  { id = "mp_bfa",         labelKey = "mp_bfa" },
  { id = "mp_legion",      labelKey = "mp_legion" },
}
```

### 3.3 카테고리 노출 규칙

좌측 리스트에 카테고리가 노출되는 조건 (모두 만족해야 함):

1. `classRequired` 없음 OR 플레이어 직업과 일치
2. `racesRequired` 없음 OR 플레이어 종족이 목록에 포함
3. (안전망) 카테고리 안에 항목별 `class`/`race` 조건까지 적용 후 1개 이상 남음

판정은 `PLAYER_LOGIN` 시 1회. (캐릭터 종족·직업은 런타임에 변하지 않음)

### 3.4 항목 노출 / 사용 가능 / 쿨타임 판정

| 판정 | spell | toy | item |
|---|---|---|---|
| 노출 (race/class 조건) | 항목의 `race`/`class` 매치 | 동일 | 동일 |
| 사용 가능 (필터용) | `IsPlayerSpell(spellID)` | `PlayerHasToy(itemID) and C_ToyBox.IsToyUsable(itemID)` | `GetItemCount(itemID) > 0 or IsEquippedItem(itemID)` |
| 쿨타임 (오버레이용) | `GetSpellCooldown(spellID)` | `GetItemCooldown(itemID)` | `GetItemCooldown(itemID)` |
| 아이콘 텍스처 | `C_Spell.GetSpellTexture(spellID)` | `C_Item.GetItemIconByID(itemID)` | `C_Item.GetItemIconByID(itemID)` |
| 툴팁 | `GameTooltip:SetSpellByID(id)` | `:SetToyByItemID(id)` | `:SetItemByID(id)` |

### 3.5 카테고리별 항목 (시각적 그룹 포함)

`categoryItems`는 카테고리 ID를 키로 하고, 값은 항목 배열 또는 그룹 배열.

- **단일 배열 형태**: `{ {type=...}, {type=...}, ... }` — 그룹 구분 없음
- **그룹 배열 형태**: `{ { {type=...}, ... }, { {type=...}, ... } }` — 우측 그리드에서 그룹 사이에 가로 구분선

```lua
AllPortal.data.categoryItems = {

  -- 한밤 시즌1 던전 텔레포트 주문 (시즌 패치 때 갱신)
  current_season = {
    { type = "spell", id = TBD },  -- 마법 학자의 정원
    { type = "spell", id = TBD },  -- 공결탑 제나스
    { type = "spell", id = TBD },  -- 샤론의 구덩이
    { type = "spell", id = TBD },  -- 삼두정의 권좌
    -- + 시즌1 회전풀의 과거 던전들 (Scholomance, Scarlet Monastery 등)
    -- TBD: 시즌 확정 시 spellID들 채움
  },

  -- 마법사 포탈 + 순간이동 (직업 가드: MAGE)
  mage_portal = {
    -- 도시별 정렬 — 구현 시 주문 ID 채움
    -- 스톰윈드/오그리마/아이언포지/썬더 블러프/엑소다/언더시티/실버문/달라란/샤트라스/샤도라
    -- 각 도시 포탈(파티 이동) + 순간이동(자기 자신) 두 줄로
  },

  toys = {
    {  -- G1: 일반 귀환/이동
      { type = "toy",  id = 140192 },  -- 달라란 귀환석
      { type = "toy",  id = TBD },      -- 아르칸티나로 통하는 개인 열쇠
      { type = "item", id = 141605 },  -- 비행 조련사의 호루라기 (item, toy 아님)
      { type = "toy",  id = 110560 },  -- 주둔지 귀환석
    },
    {  -- G2: 구렁(언더마인)
      { type = "toy", id = TBD },  -- 구렁 탐험가의 마나결속 에테르 관문
      { type = "toy", id = TBD },  -- 구렁로봇 7001
    },
    {  -- G3
      { type = "toy", id = TBD },  -- 불안정한 차원문 방출기
    },
    {  -- G4: 웜홀 생성기 (BfA 이후)
      { type = "toy", id = TBD },  -- 웜홀 생성기: 카즈 알가르
      { type = "toy", id = TBD },  -- 웜홀 생성기: 아르거스
      { type = "toy", id = TBD },  -- 웜홀 생성기: 잔달라
      { type = "toy", id = TBD },  -- 웜홀 생성기: 판다리아
      { type = "toy", id = TBD },  -- 웜홀 생성기: 어둠땅
    },
    {  -- G5: 웜홀 생성기 (구버전)
      { type = "toy", id = TBD },  -- 웜홀 생성기: 쿨 티라스
      { type = "toy", id = TBD },  -- 웜홀 생성기: 노스랜드
    },
    {  -- G6
      { type = "toy", id = TBD },  -- 웜홀 원심 분리기
    },
    {  -- G7: 안전보증 순간이동기 (엔지니어링)
      { type = "toy", id = TBD },  -- 안전보증 순간이동기: 가젯잔
      { type = "toy", id = TBD },  -- 안전보증 순간이동기: 토쉴리의 연구기지
    },
  },

  items = {
    {  -- G1: 휘장/반지/망토 (장착 후 사용)
      { type = "item", id = TBD },  -- 충전식 리브스 전지
      { type = "item", id = TBD },  -- 은빛십자군 성전사의 휘장 (겉옷)
      { type = "item", id = TBD },  -- 왕놋쇠 너클 (손가락)
      { type = "item", id = TBD },  -- 싸움꾼의 강력한 주먹질 반지 (손가락)
      { type = "item", id = TBD },  -- 사기꾼의 알록달곡 망토 (등)
      { type = "item", id = TBD },  -- 단결의 망토 (등)
      { type = "item", id = TBD },  -- 키린 토 반지 (손가락)
      { type = "item", id = TBD },  -- 헬스크림 세력단 휘장 (겉옷)
    },
    {  -- G2: 장신구/소비형
      { type = "item", id = TBD },  -- 잃어버린 시간의 유물 (장신구)
      { type = "item", id = TBD },  -- 칼날첨탑 성물
      { type = "item", id = TBD },  -- 제이나의 펜던트
      { type = "item", id = TBD },  -- 제독의 나침반
    },
  },

  misc = {
    { type = "spell", id = TBD, race = "Vulpera" },        -- 야영지 귀환
    { type = "spell", id = TBD, race = "DarkIronDwarf" },  -- 굴착기
  },

  -- 영웅의 길: 확장팩별 신화+ 텔레포트 (해당 확장팩의 모든 시즌)
  mp_midnight = { --[[ TBD ]] },
  mp_tww      = { --[[ TBD ]] },
  mp_df       = { --[[ TBD ]] },
  mp_sl       = { --[[ TBD ]] },
  mp_bfa      = { --[[ TBD ]] },
  mp_legion   = { --[[ TBD ]] },
}
```

> **TBD 마커**: 구현 단계에서 Wowhead 또는 인게임 매크로 툴팁으로 spellID/itemID를 조회해 채워 넣는다. 한 번 박으면 거의 안 변한다. 시즌 패치 때 `current_season`만 갱신.

### 3.6 로케일 테이블 (`data.lua` 상단)

```lua
local locale = GetLocale()  -- "koKR", "enUS", ...

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

AllPortal.T = L[locale] or L.enUS  -- 폴백: enUS
```

## 4. UI 레이아웃 (`ui.lua`)

### 4.1 메인 프레임

- 기본 크기 600 × 400, 사용자 드래그 리사이즈 가능
- `SetResizable(true)`, `SetResizeBounds(400, 300, 1200, 900)`
- 우하단 리사이즈 그립
- 헤더 드래그로 이동
- 우상단 닫기(X) 버튼, Esc 키로도 닫힘 (`UISpecialFrames` 등록)
- 위치/크기는 `AllPortalDB.framePoint`, `AllPortalDB.frameSize`에 저장

### 4.2 헤더

- 좌상단: "사용 가능만 보기" 체크박스 (`AllPortalDB.filterOwnedOnly`와 양방향 바인딩)
- 중앙: `T.addon_title`
- 우상단: 닫기 버튼

### 4.3 좌측 카테고리 패널

- 폭: 180 px
- 항목: 카테고리 라벨 텍스트 버튼
- 선택된 카테고리: 주황색 하이라이트
- "일반 5개" ↔ "영웅의 길 6개" 사이에 가는 가로 구분선

### 4.4 우측 그리드 패널

- 항목 버튼 36 × 36 px
- 그리드 컬럼 수: `floor((panelWidth - paddingLR) / (buttonSize + spacing))` — 리사이즈 시 재계산
- 그룹 사이에 1줄 가로 구분선 (data가 그룹 배열인 경우)
- 콘텐츠 높이가 패널을 넘으면 우측에 자동 스크롤바 (Blizzard `ScrollFrame`)

### 4.5 버튼 시각 상태

| 상태 | 표시 |
|---|---|
| 사용 가능 + 쿨타임 없음 | 풀컬러 아이콘 |
| 사용 가능 + 쿨타임 중 | 풀컬러 아이콘 + Cooldown 시계 오버레이 + 남은 시간 텍스트 |
| 보유/학습 안 됨 | 어두운 회색 아이콘 (필터 켜져 있으면 숨김) |

쿨타임 시계 오버레이는 표준 `Cooldown` 프레임 + `SetCooldown(start, duration)`. 남은 시간 텍스트(`mm:ss` 또는 `Ns`)는 OnUpdate 핸들러로 별도 갱신.

### 4.6 첫 진입 동작

- 메인 프레임 처음 열 때 `AllPortalDB.lastCategory`의 카테고리 자동 선택
- 저장값이 없거나 그 카테고리가 현재 캐릭터에 노출 불가면 → 첫 노출 가능 카테고리 자동 선택
- 카테고리 선택 변경 시 `AllPortalDB.lastCategory` 갱신

## 5. 클릭 동작 (보안 버튼)

### 5.1 버튼 생성 (ID 기반, 로케일 무관)

```lua
local btn = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate")
btn:RegisterForClicks("AnyDown", "AnyUp")

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
```

### 5.2 장착 후 사용 (자동 2-클릭)

`type="item"` + `"item:ITEMID"`는 우클릭과 동일 효과:
- 장비형(휘장/반지/망토/장신구)이 미장착이면 첫 클릭에 **장착됨**
- 이미 장착돼 있고 사용 효과가 있으면 발동
- 별도의 `equipped:` 매크로 분기 불필요

### 5.3 보안 버튼 풀

전투 중 보안 attribute 변경 불가 문제는 풀로 해결한다:

```
[PLAYER_LOGIN]
  └→ 모든 카테고리의 모든 노출 후보 항목에 대해 보안 버튼 생성 (총 100개 미만)
  └→ type/spell/toy/item attribute 각각 세팅
  └→ 모두 Hide() 상태로 부모 프레임에 부착

[카테고리 클릭 / 필터 토글 시]
  └→ 이전에 보이던 버튼들 Hide()
  └→ 현재 카테고리 + 노출 조건 + 필터 통과 버튼만 Show()
  └→ 보이는 버튼들 SetPoint으로 그리드 재배치 (attribute 변경 X)
```

`Show/Hide`와 `SetPoint`는 보안 제한 없음. 카테고리 전환·필터 토글·창 리사이즈 모두 전투 중에도 작동.

### 5.4 마우스 오버 툴팁

- spell: `GameTooltip:SetSpellByID(id)`
- toy: `GameTooltip:SetToyByItemID(id)`
- item: `GameTooltip:SetItemByID(id)`

## 6. 동작·이벤트·엣지 케이스 (`core.lua`)

### 6.1 등록 이벤트

| 이벤트 | 처리 |
|---|---|
| `PLAYER_LOGIN` | SavedVariables 로드, 보안 버튼 풀 생성, 미니맵 버튼 생성 |
| `PLAYER_ENTERING_WORLD` | `GetItemInfo` 캐시 워밍 (모든 itemID 1회 호출) |
| `GET_ITEM_INFO_RECEIVED` | 캐시 미스였던 항목의 아이콘/툴팁 갱신 |
| `BAG_UPDATE_DELAYED` | `items` 카테고리 보이는 중이면 보유 여부 재계산 |
| `PLAYER_EQUIPMENT_CHANGED` | `items` 카테고리 보이는 중이면 장착 슬롯 재평가 |
| `TOY_UPDATED` | `toys` 카테고리 보이는 중이면 컬렉션 재계산 |
| `SPELLS_CHANGED` | spell 포함 카테고리 재계산 (`LEARNED_SPELL_IN_TAB`은 retail에서 deprecated) |
| `SPELL_UPDATE_COOLDOWN` | 보이는 spell 버튼 쿨타임 갱신 |
| `BAG_UPDATE_COOLDOWN` | 보이는 item/toy 버튼 쿨타임 갱신 |
| `PLAYER_REGEN_DISABLED` | 전투 진입 → 보안 attribute 변경 큐 잠금 |
| `PLAYER_REGEN_ENABLED` | 전투 종료 → 큐에 쌓인 변경 적용 |

**효율성 원칙**: "보이는 카테고리"가 영향받지 않는 이벤트는 무시. 보안 풀은 한 번만 생성.

### 6.2 OnUpdate 쿨타임 텍스트 갱신

```lua
local accumulator = 0
mainFrame:HookScript("OnUpdate", function(self, elapsed)
  accumulator = accumulator + elapsed
  if accumulator < 0.1 then return end
  accumulator = 0
  for _, btn in ipairs(visibleButtons) do
    if btn.cooldownActive then
      local remain = btn.cooldownEnd - GetTime()
      if remain <= 0 then
        btn.cdText:SetText("")
        btn.cooldownActive = false
      else
        btn.cdText:SetText(formatCooldown(remain))
      end
    end
  end
end)
```

메인 프레임이 `Hide()` 상태면 OnUpdate 호출 안 됨 → 닫혀있을 때 비용 0.

`formatCooldown`:
- 1시간 이상: `1h`, `2h`, …
- 1분 이상: `12m`, `5m`, …
- 1분 미만: `45s`, `9s`, …

### 6.3 전투 중 동작 정리

| 동작 | 전투 중 가능? |
|---|---|
| 좌클릭 시전/사용 | ✅ (보안 버튼 attribute 미리 세팅돼 있음) |
| 카테고리 전환 (Show/Hide) | ✅ |
| "사용 가능만 보기" 토글 | ✅ |
| 메인 창 크기 조절 | ✅ (보안과 무관한 Region 작업) |
| 메인 창 오픈/닫기 | ✅ (보안 풀은 PLAYER_LOGIN에 미리 생성, 오픈은 Show만 호출) |

**lockdown 큐의 용도**: 일반적으로는 비어있다. 향후 v2에서 동적으로 항목을 추가하거나 attribute를 갱신할 때만 사용. v1에선 PLAYER_LOGIN 시 1회 풀 생성 후 attribute 변경 없음 → 큐는 등록만 해두고 실제 작업은 없음.

## 7. 미니맵 버튼 (`minimap.lua`)

### 7.1 생성

```lua
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

btn.border = btn:CreateTexture(nil, "OVERLAY")
btn.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
btn.border:SetSize(54, 54)
btn.border:SetPoint("TOPLEFT")
```

### 7.2 테두리 따라 드래그

```lua
local function UpdatePosition(angle)
  local rad = math.rad(angle)
  local radius = 80  -- 미니맵 반지름 + 여유
  local x = radius * math.cos(rad)
  local y = radius * math.sin(rad)
  btn:ClearAllPoints()
  btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

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
```

### 7.3 클릭 / 툴팁

```lua
btn:SetScript("OnClick", function(self, mouseButton)
  if mouseButton == "LeftButton" then
    AllPortal.ui:Toggle()
  end
end)

btn:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:SetText(AllPortal.T.addon_title)
  GameTooltip:AddLine(AllPortal.T.tooltip_left_click, 1, 1, 1)
  GameTooltip:Show()
end)
btn:SetScript("OnLeave", GameTooltip_Hide)
```

### 7.4 표시/숨김

`AllPortalDB.minimapHidden = true`이면 버튼 자체를 `:Hide()`. 슬래시로만 토글 (v1).

### 7.5 MinimapButtonButton(MBB) 호환

`Minimap`을 부모로, 31×31 표준 모양으로 만들면 자동 호환. 별도 작업 없음.

## 8. 슬래시 명령어 / 키바인딩 (`core.lua`, `bindings.xml`)

### 8.1 `/allportal`

```lua
SLASH_ALLPORTAL1 = "/allportal"

SlashCmdList["ALLPORTAL"] = function(msg)
  msg = strtrim((msg or ""):lower())
  local T = AllPortal.T

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
      print("|cff00ff00AllPortal:|r " .. T.minimap_hidden_msg)
    else
      AllPortal.minimap.btn:Show()
      print("|cff00ff00AllPortal:|r " .. T.minimap_shown_msg)
    end

  elseif msg == "reset" then
    AllPortalDB.framePoint = nil
    AllPortalDB.frameSize  = nil
    AllPortalDB.minimap    = { angle = 215 }
    AllPortal.ui:ResetPosition()
    AllPortal.minimap:UpdatePosition(215)
    print("|cff00ff00AllPortal:|r " .. T.reset_msg)

  elseif msg == "help" or msg == "?" then
    print("|cff00ff00AllPortal:|r " .. T.help_header)
    print("  /allportal              — " .. T.help_toggle)
    print("  /allportal minimap      — " .. T.help_minimap)
    print("  /allportal reset        — " .. T.help_reset)
    print("  /allportal help         — " .. T.help_help)

  else
    print("|cffff0000AllPortal:|r " .. T.unknown_cmd_msg .. " '/allportal help'")
  end
end
```

### 8.2 키바인딩 (`bindings.xml`)

```xml
<Bindings>
  <Binding name="ALLPORTAL_TOGGLE" header="ALLPORTAL" category="ADDONS">
    AllPortal.ui:Toggle()
  </Binding>
</Bindings>
```

게임 내 "키 설정 → 애드온" 탭에서 사용자가 단축키 할당.

## 9. SavedVariables (`AllPortalDB`, 계정 공유)

```lua
{
  framePoint      = {"CENTER", "UIParent", "CENTER", 0, 0},  -- 메인 창 위치
  frameSize       = { 600, 400 },                            -- 메인 창 크기
  lastCategory    = "current_season",                        -- 마지막 선택 카테고리 ID
  filterOwnedOnly = false,                                   -- "사용 가능만 보기" 체크박스
  minimap         = { angle = 215 },                         -- 미니맵 버튼 각도(도)
  minimapHidden   = false,                                   -- 미니맵 버튼 숨김 여부
}
```

**저장 시점:**
- 창 이동/리사이즈: `OnDragStop`, `OnSizeChanged` 종료 시
- 카테고리 전환: 즉시
- 필터 토글: 즉시
- 미니맵 드래그: `OnUpdate` 매 프레임 (저장은 메모리상, 디스크 동기화는 로그아웃 시 자동)

**기본값 채움:** `PLAYER_LOGIN`에서 `AllPortalDB`가 없거나 키가 누락되면 디폴트로 채움.

## 10. 운영: 시즌 패치 시 갱신 절차

새 신화+ 시즌 출시 시:

1. `data.lua`의 `current_season` 항목 리스트를 새 던전들의 텔레포트 spellID로 교체
2. 로케일 테이블 `L.koKR.current_season`, `L.enUS.current_season` 라벨 갱신 (`"한밤1 시즌"` → `"한밤2 시즌"` 등)
3. (선택) 직전 시즌 spellID들은 해당 확장팩 `mp_*` 카테고리에 누적

(spellID 변동 없는 한 다른 카테고리는 손댈 필요 없음)

## 11. 미해결 / 후속 작업

- 모든 **TBD** ID는 구현 단계에서 채워야 함. 가장 큰 데이터 작업.
- v2 후보: 우클릭으로 항목 숨김 토글, GUI 옵션창, 커스텀 항목 추가, 자주 쓰는 즐겨찾기 카테고리, 검색
