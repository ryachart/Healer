# Healer Web Port Migration Plan

## Objective

Port the native Objective-C / cocos2d-iphone game in this repository to a browser-playable website that:

1. serves an HTML entry page,
2. runs the game in the browser,
3. is backed by a local Python server for development and future API expansion, and
4. preserves the authored game content, combat logic, progression, and presentation patterns from the current iOS game.

This document is based on repository research across the native app entry flow, content declarations, battle systems, persistence, asset pipeline, and backend hooks.

---

## 1. Current Game Structure

### 1.1 Player flow and scenes

The current native flow is assembled from cocos2d scenes and supporting layers:

- **Launch / splash** → `LaunchScene` transitions into the start menu.  
  Source: `/home/runner/work/Healer/Healer/Healer/Scenes/LaunchScene.m`
- **Start menu / landing page** → `HealerStartScene` exposes **Play**, **Academy** (shop/spells), **Armory** (inventory/items), **Talents**, and **Settings**.  
  Source: `/home/runner/work/Healer/Healer/Healer/Scenes/HealerStartScene.m`
- **World map** → `LevelSelectMapScene` + `LevelSelectMapNode` provide the horizontally scrolling map and level selection flow.  
  Sources: `/home/runner/work/Healer/Healer/Healer/LevelSelectMapScene.m`, `/home/runner/work/Healer/Healer/Healer/LevelSelectMapNode.m`
- **Pre-fight** → `PreBattleScene` shows the encounter, raid composition, and selected spells, and supports spell swapping before combat.  
  Source: `/home/runner/work/Healer/Healer/Healer/Scenes/PreBattleScene.h`
- **Battle** → `GamePlayScene` owns the combat screen, battle UI, encounter simulation orchestration, and multiplayer hooks.  
  Source: `/home/runner/work/Healer/Healer/Healer/Scenes/GamePlayScene.h`
- **Post-fight** → `PostBattleScene` handles victory/defeat follow-up.  
  Source: `/home/runner/work/Healer/Healer/Healer/Scenes/PostBattleScene.h`
- **Talents** → `TalentScene` + `Talents` provide 5 talent tiers with 3 choices each.  
  Sources: `/home/runner/work/Healer/Healer/Healer/Scenes/TalentScene.h`, `/home/runner/work/Healer/Healer/Healer/Talents.m`
- **Inventory / equipment** → `InventoryScene` + `EquipmentItem`.  
  Sources: `/home/runner/work/Healer/Healer/Healer/InventoryScene.h`, `/home/runner/work/Healer/Healer/Healer/EquipmentItem.h`
- **Shop / spells** → `ShopScene` + `Shop`.  
  Sources: `/home/runner/work/Healer/Healer/Healer/ShopScene.h`, `/home/runner/work/Healer/Healer/Healer/Shop.m`
- **Settings** → audio toggles, feedback, rename, restore purchases, erase data.  
  Source: `/home/runner/work/Healer/Healer/Healer/SettingsScene.m`
- **Multiplayer setup / queue** → Game Center matchmaking scenes already exist, though they are not central to the current single-player loop.  
  Sources: `/home/runner/work/Healer/Healer/Healer/MultiplayerSetupScene.h`, `/home/runner/work/Healer/Healer/Healer/MultiplayerQueueScene.h`

### 1.2 Main simulation model

The game logic is not purely scene-driven; it is organized around reusable model classes:

- **Combat entities**: `Agent`, `HealableTarget`, `RaidMember`, `Player`, `Enemy`  
  Sources: `/home/runner/work/Healer/Healer/Healer/Agent.h`, `/home/runner/work/Healer/Healer/Healer/DataObjects/HealableTarget.h`, `/home/runner/work/Healer/Healer/Healer/DataObjects/RaidMember.h`, `/home/runner/work/Healer/Healer/Healer/DataObjects/Player.h`, `/home/runner/work/Healer/Healer/Healer/DataObjects/Enemy.h`
- **Encounter assembly**: `Encounter`, `Raid`  
  Sources: `/home/runner/work/Healer/Healer/Healer/DataObjects/Encounter.h`, `/home/runner/work/Healer/Healer/Healer/DataObjects/Raid.h`
- **Player actions**: `Spell` and concrete spell classes  
  Source: `/home/runner/work/Healer/Healer/Healer/DataObjects/Spell.h`
- **Enemy actions**: `Ability` and concrete ability classes  
  Source: `/home/runner/work/Healer/Healer/Healer/Ability.h`
- **Status systems**: `Effect` and concrete effect classes  
  Source: `/home/runner/work/Healer/Healer/Healer/DataObjects/Effect.h`
- **Progression/economy**: `PlayerDataManager`, `Shop`, `EquipmentItem`, `LootTable`  
  Sources: `/home/runner/work/Healer/Healer/Healer/PlayerDataManager.h`, `/home/runner/work/Healer/Healer/Healer/Shop.h`, `/home/runner/work/Healer/Healer/Healer/EquipmentItem.h`, `/home/runner/work/Healer/Healer/Healer/LootTable.h`

### 1.3 Battle UI systems to preserve

The browser port needs to preserve the native battle HUD patterns, especially the raid-frame-style health UI described in the problem statement. The native equivalents are:

- `RaidView` for ally health frame layout  
  Source: `/home/runner/work/Healer/Healer/Healer/Sprites/RaidView.h`
- `RaidMemberHealthView` for animated health bars, floating numbers, selection state, and status presentation  
  Source: `/home/runner/work/Healer/Healer/Healer/Sprites/RaidMemberHealthView.h`
- `BossHealthView` for boss portrait/name/health/ability display  
  Source: `/home/runner/work/Healer/Healer/Healer/Sprites/BossHealthView.h`
- `PlayerStatusView` for player energy/channeling status  
  Source: `/home/runner/work/Healer/Healer/Healer/Sprites/PlayerStatusView.h`
- `PlayerSpellButton`, `PlayerMoveButton`, `PlayerCastBar`, `EnemyAbilityDescriptionsView`, `IconDescriptionModalLayer`, and related controls/layers for interaction and overlays  
  Sources: `/home/runner/work/Healer/Healer/Healer/Controls/PlayerSpellButton.m`, `/home/runner/work/Healer/Healer/Healer/Controls/PlayerMoveButton.m`, `/home/runner/work/Healer/Healer/Healer/Sprites/PlayerCastBar.h`, `/home/runner/work/Healer/Healer/Healer/EnemyAbilityDescriptionsView.h`, `/home/runner/work/Healer/Healer/Healer/IconDescriptionModalLayer.h`

---

## 2. Authored Content Inventory

## 2.1 Encounters and campaign progression

The normal campaign is hardcoded in `Encounter.m` and contains **21 authored encounters** on a horizontally scrolling world map. `LevelSelectMapNode` defines `NUM_ENCOUNTERS 21`, and `Encounter` defines the encounter composition, story text, recommended spells, and boss keys.

Sources:
- `/home/runner/work/Healer/Healer/Healer/LevelSelectMapNode.m`
- `/home/runner/work/Healer/Healer/Healer/DataObjects/Encounter.m`

### Encounter list

| Level | Boss Key | Encounter Title |
|---|---|---|
| 1 | ghoul | The Ghoul |
| 2 | troll | Corrupted Troll |
| 3 | drake | Tainted Drake |
| 4 | imps | Mischievious Imps |
| 5 | treant | Befouled Akarus |
| 6 | fungalravagers | Fungal Ravagers |
| 7 | plaguebringer | Plaguebringer Colossus |
| 8 | trulzar | Trulzar the Maleficar |
| 9 | council | Council of Dark Summoners |
| 10 | twinchampions | Twin Champions of Baraghast |
| 11 | baraghast | Baraghast, Warlord of the Damned |
| 12 | tyonath | Crazed Seer Tyonath |
| 13 | gatekeeper | Gatekeeper of Delsarn |
| 14 | skeletaldragon | Skeletal Dragon |
| 15 | colossusbone | Colossus of Bone |
| 16 | overseer | Overseer of Delsarn |
| 17 | unspeakable | The Unspeakable |
| 18 | baraghastreborn | Baraghast Reborn |
| 19 | avataroftorment | The Avatar of Torment |
| 20 | avataroftorment | The Avatar of Torment II |
| 21 | souloftorment | The Soul of Torment |

### Map progression and difficulty

- The map is a 3-panel horizontally scrolling background (`map-level-1`, `map-level-2`, `map-level-3`).  
  Source: `/home/runner/work/Healer/Healer/Healer/LevelSelectMapNode.m`
- Levels unlock linearly based on highest completed level.  
  Source: `/home/runner/work/Healer/Healer/Healer/LevelSelectMapNode.m`
- Encounter difficulty is clamped to **1..5** and is stored in player progression data.  
  Source: `/home/runner/work/Healer/Healer/Healer/DataObjects/Encounter.m`
- The main paid-content gate currently unlocks levels beyond `END_FREE_ENCOUNTER_LEVEL 7`.  
  Source: `/home/runner/work/Healer/Healer/Healer/PlayerDataManager.h`

## 2.2 Player spells

`Spell.h` declares **24 concrete spell classes**:

- Heal
- GreaterHeal
- ForkedHeal
- Regrow
- Barrier
- HealingBurst
- Purify
- OrbsOfLight
- SwirlingLight
- LightEternal
- WanderingSpirit
- Respite
- WardOfAncients
- TouchOfHope
- SoaringSpirit
- FadingLight
- Sunburst
- StarsOfAravon
- BlessedArmor
- Attunement
- RaidHeal
- HealBuff
- LightBolt
- HastyBrew

Source: `/home/runner/work/Healer/Healer/Healer/DataObjects/Spell.h`

The shop currently sells a curated subset of those spells across four categories:

- **Essentials**
- **Advanced**
- **Archives**
- **Vault**

Source: `/home/runner/work/Healer/Healer/Healer/Shop.m`

## 2.3 Enemy/boss content

`Enemy.h` declares **28 enemy classes**, including shipped bosses, multi-phase variants, event/test content, and encounter-specific variants:

- Ghoul
- CorruptedTroll
- Drake
- Trulzar
- Teritha
- Grimgon
- Galcyon
- DarkCouncil
- PlaguebringerColossus
- FinalRavager
- MischievousImps
- BefouledTreant
- Sarroth
- Vorroth
- Baraghast
- CrazedSeer
- GatekeeperDelsarn
- SkeletalDragon
- ColossusOfBone
- OverseerOfDelsarn
- TheUnspeakable
- BaraghastReborn
- AvatarOfTorment1
- AvatarOfTorment2
- SoulOfTorment
- TheEndlessVoid
- FungalRavager
- TestBoss

Source: `/home/runner/work/Healer/Healer/Healer/DataObjects/Enemy.h`

For the browser port, treat the encounter-facing shipped boss set as the canonical dataset, and keep non-shipping/test variants as explicitly flagged content during extraction.

## 2.4 Ally archetypes

`RaidMember.h` declares **6 ally archetypes**:

- Guardian
- Berserker
- Archer
- Wizard
- Champion
- Warlock

Source: `/home/runner/work/Healer/Healer/Healer/DataObjects/RaidMember.h`

These are assembled per encounter in `Encounter.m` through counts such as `numGuardian`, `numWizard`, `numArcher`, `numChampion`, `numWarlock`, and `numBerserker`.

Source: `/home/runner/work/Healer/Healer/Healer/DataObjects/Encounter.m`

## 2.5 Enemy abilities

`Ability.h` declares **71 concrete ability or specialized ability classes** (57 direct subclasses of `Ability`, plus derived specializations). This file is one of the most important extraction targets for the combat port.

Representative authored abilities include:

- Attack / FocusedAttack / SustainedAttack
- BoneThrow
- ProjectileAttack / ChannelledRaidProjectileAttack
- RaidDamagePulse / RaidDamage / RaidDamageSweep
- Crush / BloodCrush
- Debilitate
- InvertedHealing
- SoulBurn
- Impale
- AlternatingFlame
- BoneQuake
- GroundSmash
- SoulPrison
- DisruptionCloud
- Confusion
- DisorientingBoulder
- Cleave
- WaveOfTorment
- Earthquake
- DarkCloud
- ShatterArmor
- BrokenWill
- Soulshatter
- BlindingSmokeAttack
- DisableSpell
- OrbsOfFury
- BoneStorm
- SlimeOrbs
- SoulSwap
- AvatarOfTormentSubmerge
- RainOfFire
- ManaDrain

Source: `/home/runner/work/Healer/Healer/Healer/Ability.h`

## 2.6 Effects and status systems

`Effect.h` declares **55 concrete effect classes** and captures much of the combat ruleset for buffs, debuffs, DoTs, shields, dispels, visibility priority, healing modifiers, damage modifiers, confusion, stun, blind, stacking, and triggered behavior.

Important effect families include:

- repeated heal/damage-over-time effects,
- shield effects,
- talent effects,
- dispel-sensitive effects,
- execution / delayed effects,
- contagious / stacking effects,
- healing absorption effects,
- special boss mechanic effects.

Source: `/home/runner/work/Healer/Healer/Healer/DataObjects/Effect.h`

## 2.7 Talents

`Talents.m` defines **5 tiers** with **3 choices per tier**:

- Tier 1: Healing Hands, Blessed Power, Insight
- Tier 2: Surging Glory, Shining Aegis, After Light
- Tier 3: Repel The Darkness, Ancient Knowledge, Purity of Soul
- Tier 4: Searing Power, Sunlight, Arcane Blessing
- Tier 5: Godstouch, Redemption, Avatar

Sources:
- `/home/runner/work/Healer/Healer/Healer/Talents.m`
- `/home/runner/work/Healer/Healer/Healer/talents.plist`

## 2.8 Items and equipment

`EquipmentItem.h` defines a generated loot system with:

- **6 slots**: Head, Weapon, Chest, Legs, Boots, Neck
- **5 stat types**: Health, Healing, Regen, Crit, Speed
- **4 rarity tiers**: Uncommon, Rare, Epic, Legendary

Source: `/home/runner/work/Healer/Healer/Healer/EquipmentItem.h`

`EquipmentItem.m` additionally defines:

- stat atom weights for procedural generation,
- randomized naming by slot prefix + suffix,
- sprite naming conventions for inventory and avatar art,
- special weapon keys that grant item spells or triggered effects.

Source: `/home/runner/work/Healer/Healer/Healer/EquipmentItem.m`

## 2.9 Persistence and progression content

`PlayerDataManager` owns the portable player profile state and is the canonical source for what must become browser-save data:

- level progress,
- ratings and scores,
- owned spells,
- selected spells,
- talent configuration,
- content unlocks,
- settings,
- inventory/equipped items,
- ally upgrades,
- player name,
- FTUE state,
- stamina.

Sources:
- `/home/runner/work/Healer/Healer/Healer/PlayerDataManager.h`
- `/home/runner/work/Healer/Healer/Healer/PlayerDataManager.m`

---

## 3. Asset Inventory

Repository counts from the working tree currently show:

- **396 PNG files**
- **38 JPG files**
- **79 MP3 files**
- **35 particle `.plist` files** in `emitters/`

Relevant asset roots include:

- `/home/runner/work/Healer/Healer/Sprites`
- `/home/runner/work/Healer/Healer/backgrounds`
- `/home/runner/work/Healer/Healer/battle-sprites`
- `/home/runner/work/Healer/Healer/bosses`
- `/home/runner/work/Healer/Healer/divinity-sprites`
- `/home/runner/work/Healer/Healer/effect-sprites`
- `/home/runner/work/Healer/Healer/emitters`
- `/home/runner/work/Healer/Healer/inventory`
- `/home/runner/work/Healer/Healer/items`
- `/home/runner/work/Healer/Healer/map-icons`
- `/home/runner/work/Healer/Healer/postbattle`
- `/home/runner/work/Healer/Healer/shop-sprites`
- `/home/runner/work/Healer/Healer/sounds`
- `/home/runner/work/Healer/Healer/spell-sprites`
- `/home/runner/work/Healer/Healer/avatar`

### Existing asset-pipeline clues

The native project already batches many art folders into atlases with TexturePacker:

- `scripts/build-spritesheet.sh`
- `scripts/build-boss-assets.sh`

These scripts are useful because they already define the logical sprite groupings that the web asset pipeline should preserve.

---

## 4. Backend / Platform Dependencies To Replace

The current native implementation depends on iOS-only or legacy platform services that must be replaced or wrapped:

- **cocos2d-iphone** scene graph, animation, input, texture loading  
  Source: `/home/runner/work/Healer/Healer/.gitmodules`
- **Game Center / GameKit** for multiplayer hooks  
  Sources: `/home/runner/work/Healer/Healer/Healer/Scenes/GamePlayScene.h`, `/home/runner/work/Healer/Healer/Healer/MultiplayerQueueScene.h`
- **Parse** for remote player objects, analytics, and stamina cloud functions  
  Sources: `/home/runner/work/Healer/Healer/Healer/AppDelegate.m`, `/home/runner/work/Healer/Healer/HealerCloudCode/cloud/main.js`
- **StoreKit-style purchase flow** for content unlocks and restore purchases  
  Sources: `/home/runner/work/Healer/Healer/Healer/PurchaseManager.h`, `/home/runner/work/Healer/Healer/Healer/SettingsScene.m`
- **UIKit / local notifications / mail compose** for native integrations  
  Sources: `/home/runner/work/Healer/Healer/Healer/AppDelegate.m`, `/home/runner/work/Healer/Healer/Healer/SettingsScene.m`

For security, do **not** reuse the checked-in legacy Parse secrets in a web deployment. Treat legacy backend config only as migration input.

---

## 5. Recommended Target Web Architecture

## 5.1 Frontend

Use a browser-first frontend organized around:

- a single `index.html` entry page,
- a game client written in TypeScript,
- a 2D rendering layer for battle/map/UI,
- DOM-driven overlays for menus and forms where appropriate,
- a data-driven asset manifest and content registry.

### Recommended frontend split

- **Canvas/WebGL game layer** for map, battle, spell effects, raid frames, and boss UI
- **DOM/UI layer** for menus, settings, rename dialogs, and future account/multiplayer controls
- **Pure simulation layer** for combat rules, AI, progression, loot, and encounter assembly

The most important rule is: **combat/game rules must be framework-agnostic** so they can later run on the server for multiplayer or authoritative verification.

## 5.2 Local Python server

Back the website with a local Python service from the start, even if the first milestone only serves static files.

### Recommended responsibilities

Phase 1 responsibilities:
- serve `index.html`
- serve compiled frontend assets
- serve extracted JSON game data
- serve image/audio/particle assets
- expose dev-only API stubs for save/load and encounter bootstrapping

Phase 2+ responsibilities:
- save/load player state
- issue encounter seeds / content payloads
- track progression submissions
- host stamina/account logic
- evolve toward multiplayer orchestration and eventually authoritative combat validation

### Suggested server shape

- `server/app.py` – Python application entry
- `server/routes/static.py` – static/html delivery
- `server/routes/player.py` – save/load/profile endpoints
- `server/routes/encounters.py` – encounter bootstrap endpoints
- `server/routes/multiplayer.py` – future matchmaking/session APIs
- `web/index.html` – browser entry page
- `web/assets/` – optimized art/audio/particles
- `web/data/` – extracted content JSON

---

## 6. Migration Strategy

## Phase 0 – Preserve and inventory the source of truth

1. Freeze the Objective-C codebase as the current gameplay authority.
2. Create a migration workbook that maps each web data file back to its source Objective-C file.
3. Explicitly label content as:
   - shipped single-player content,
   - multiplayer-only hooks,
   - event/test/debug content,
   - platform service dependencies.

## Phase 1 – Extract canonical game data

Create a repeatable extractor that converts authored content into JSON without hand-copying game balance by eye.

### Data sets to extract first

- `encounters.json` from `Encounter.m`
- `enemies.json` from `Enemy.h/.m`
- `abilities.json` from `Ability.h/.m`
- `effects.json` from `Effect.h/.m`
- `spells.json` from `Spell.h/.m`
- `allies.json` from `RaidMember.h/.m`
- `talents.json` from `Talents.m` and `talents.plist`
- `shop.json` from `Shop.m`
- `equipment-schema.json` from `EquipmentItem.h/.m`
- `loot-rules.json` from `Encounter.m`, `EquipmentItem.m`, and `LootTable.m`
- `progression-schema.json` from `PlayerDataManager.h/.m`
- `tips.json` from `Healer/tips.plist`

### Extraction rules

- Preserve stable ids (`bossKey`, spell keys, talent keys, item special keys).
- Separate **content data** from **procedural rules**.
- Store enough metadata to recreate prebattle, battle, postbattle, and progression screens without referring back to Objective-C at runtime.
- Record source-file provenance for every exported dataset.

## Phase 2 – Port the core rules engine

Port the simulation into a pure TypeScript engine that does not depend on the renderer.

### Subsystems to port

1. **Encounter assembly**
   - raid composition
   - enemy roster assembly
   - recommended/required spells
   - difficulty application

2. **Combatants**
   - player
   - raid members
   - enemies
   - stat aggregation
   - targeting and threat

3. **Spells / abilities / effects**
   - cast timing
   - cooldowns
   - energy management
   - healing/damage/shielding
   - periodic effects
   - dispels
   - interrupts
   - visibility priority for status display

4. **Scoring / rewards / progression**
   - score tally
   - gold rewards
   - loot rolls
   - unlock progression
   - talent unlocks
   - ally upgrades

### Porting rule

Do not port scene code directly into browser scene code. First port the rules into a deterministic, serializable combat engine with tests and replay support.

## Phase 3 – Build the browser shell and page flow

Recreate the native flow on the web in the same order users experience it:

1. splash / landing page
2. main menu
3. world map
4. prebattle
5. gameplay
6. postbattle
7. talents
8. spells/shop
9. inventory/armory
10. settings

### UX parity goals

- The map must scroll horizontally and honor unlock state.
- Prebattle must show boss, allies, and currently selected spells.
- The battle HUD must retain raid-frame readability and status-icon priority behavior.
- Menu navigation should work with mouse and touch.

## Phase 4 – Convert and package assets

1. Convert the current atlas-oriented art pipeline into a web manifest.
2. Group assets by scene and load lazily.
3. Preserve logical atlas groupings already implied by the TexturePacker scripts.
4. Convert particles into a web-friendly format and define fallback behavior when parity is expensive.
5. Normalize audio into browser-friendly formats and explicit manifests.

### Deliverables

- `assets-manifest.json`
- `audio-manifest.json`
- `particles-manifest.json`
- sprite atlas metadata or individual-frame metadata

## Phase 5 – Browser persistence and Python APIs

### Local/offline first

Implement local save compatibility first with a browser save shape equivalent to the native `PlayerDataManager` state.

### Python-backed next

Add Python endpoints for:

- player save/load
- progression submission
- stamina state
- encounter bootstrap
- session creation for future multiplayer

This lets the first web build run locally while also setting up the service boundary needed for multiplayer.

## Phase 6 – Multiplayer-ready architecture

Do not port current Game Center specifics. Replace them with neutral concepts:

- player profile id
- session id
- party/raid state
- combat snapshot
- authoritative event stream
- reconnect/resync path

Make the Python service the orchestration point for:

- matchmaking/session creation
- encounter state ownership
- message routing
- validation of spell casts and combat outcomes

---

## 7. Content-by-Content Extraction Plan

## 7.1 Encounters

Extract per-encounter records containing:

- level number
- encounter type
- title
- info text
- boss key
- enemy class list
- ally composition
- recommended spells
- required spells
- background key
- battle music key
- reward rules
- loot table references

Primary source: `/home/runner/work/Healer/Healer/Healer/DataObjects/Encounter.m`

## 7.2 Enemies

Extract per-enemy records containing:

- class id
- display name
- portrait/sprite names
- base stats
- threat priority behavior
- phase thresholds
- ability loadout
- difficulty modifiers
- special encounter hooks

Primary sources:
- `/home/runner/work/Healer/Healer/Healer/DataObjects/Enemy.h`
- `/home/runner/work/Healer/Healer/Healer/DataObjects/Enemy.m`

## 7.3 Spells

Extract per-spell records containing:

- id
- title
- spell type
- cast time
- cooldown
- energy cost
- target count / targeting rules
- heal amount or special payload
- audio ids
- icon frame names
- applied effect references
- talent interactions

Primary sources:
- `/home/runner/work/Healer/Healer/Healer/DataObjects/Spell.h`
- `/home/runner/work/Healer/Healer/Healer/DataObjects/Spell.m`

## 7.4 Abilities and effects

These should be exported together because many abilities instantiate or mutate effects directly.

Per-ability records:
- id
- owner rules
- activation timing
- cooldown
- value fields
- target filters
- particle/audio/icon metadata
- effect references
- interrupt/failure behavior

Per-effect records:
- id
- effect type
- ailment type
- duration
- stacking rules
- visibility priority
- stat adjustments
- expiry conditions
- tick behavior
- dispel rules

Primary sources:
- `/home/runner/work/Healer/Healer/Healer/Ability.h`
- `/home/runner/work/Healer/Healer/Healer/Ability.m`
- `/home/runner/work/Healer/Healer/Healer/DataObjects/Effect.h`
- `/home/runner/work/Healer/Healer/Healer/DataObjects/Effect.m`

## 7.5 Talents, shop, and progression

Extract:

- tier/choice metadata
- talent descriptions and sprite names
- talent rule effects
- shop categories and unlock thresholds
- shop item ordering/costs
- progression gates and unlock conditions

Primary sources:
- `/home/runner/work/Healer/Healer/Healer/Talents.m`
- `/home/runner/work/Healer/Healer/Healer/talents.plist`
- `/home/runner/work/Healer/Healer/Healer/Shop.m`
- `/home/runner/work/Healer/Healer/Healer/PlayerDataManager.h`
- `/home/runner/work/Healer/Healer/Healer/PlayerDataManager.m`

## 7.6 Items and loot

Extract:

- slot metadata
- rarity metadata
- stat types
- procedural generation rules
- naming pools
- special weapon effects/spells
- sale-price rules
- encounter-specific epic/legendary drops

Primary sources:
- `/home/runner/work/Healer/Healer/Healer/EquipmentItem.h`
- `/home/runner/work/Healer/Healer/Healer/EquipmentItem.m`
- `/home/runner/work/Healer/Healer/Healer/DataObjects/Encounter.m`
- `/home/runner/work/Healer/Healer/Healer/LootTable.m`

---

## 8. Recommended Implementation Order

### Milestone 1 – Content-extraction foundation

- inventory every data source
- export encounters, spells, enemies, talents, shop, and progression schemas
- build a content diff process so extractor output can be verified against source files

### Milestone 2 – Single-page local web shell

- Python server serves `index.html`
- main menu and world map render in browser
- extracted JSON loads successfully
- level selection and prebattle screens work without combat yet

### Milestone 3 – Playable single-player battle vertical slice

- one encounter fully playable in browser
- battle HUD reaches parity for raid frames, boss panel, spell buttons, and status icons
- save/load works locally and through Python endpoints

### Milestone 4 – Full single-player campaign parity

- all 21 encounters available
- difficulties, rewards, loot, talents, equipment, and unlocks working
- postbattle and progression fully restored

### Milestone 5 – Service-oriented multiplayer preparation

- simulation snapshots are serializable
- Python service owns encounter/session lifecycle
- browser client can join session channels and sync combat state

---

## 9. Risks and Watch Items

1. **Hardcoded authored content is spread across constructors and switch/if blocks.**  
   Extraction must be scripted and provenance-aware.
2. **Rules are distributed across `Spell`, `Ability`, `Effect`, `Enemy`, `RaidMember`, `Player`, and `Encounter`.**  
   Porting one class family in isolation will produce incorrect combat behavior.
3. **UI behavior is encoded partly in code and partly in art naming conventions.**  
   Asset manifests need to preserve sprite naming and atlas grouping.
4. **Legacy backend and native service dependencies should not be copied forward directly.**  
   Replace them with new service boundaries behind Python APIs.
5. **Multiplayer hooks exist, but the authoritative model is not currently server-centric.**  
   The web port should be designed for future authority on the Python side.

---

## 10. Recommended Deliverables To Create Next

1. `docs/extraction-matrix.md` – content type → native source files → target JSON outputs
2. `tools/` extraction utilities for encounters, spells, abilities, effects, and talents
3. `web/` browser client scaffold
4. `server/` Python local server scaffold
5. `web/data/` canonical extracted JSON payloads
6. `web/assets/manifests/` generated asset manifests
7. combat-engine test fixtures using selected encounters from the current game

---

## 11. Bottom Line

This repository already contains the authored game needed for a browser port, but the content is embedded inside Objective-C gameplay classes rather than external data files. The most effective migration path is:

1. extract canonical content into JSON,
2. rewrite the combat/progression rules as a renderer-agnostic browser/server-friendly simulation layer,
3. rebuild the scene flow as a web experience served from `index.html`, and
4. stand up a Python server early so save/load, encounter bootstrapping, and future multiplayer orchestration are designed in from the beginning.

If executed in that order, the project can reach a playable local single-player website first, then evolve into a service-backed multiplayer-capable web game without having to re-architect the combat rules a second time.
