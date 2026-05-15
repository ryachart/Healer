# Web Port Extraction Matrix

This workbook maps the native Objective-C sources to the canonical web-facing JSON produced by `tools/extract_phase1_data.py`.

| Status | Web output | Native source of truth | Notes |
| --- | --- | --- | --- |
| Implemented | `web/data/encounters.json` | `Healer/DataObjects/Encounter.m`, `Healer/DataObjects/Encounter.h` | Exports level metadata, recommended spells, ally composition, battle background, battle track, and reward gold. |
| Implemented | `web/data/spells.json` | `Healer/DataObjects/Spell.m`, `Healer/DataObjects/Spell.h` | Exports player spell definitions, stable ids, targeting metadata, cast/cooldown costs, and embedded applied-effect summaries. |
| Implemented | `web/data/enemies.json` | `Healer/DataObjects/Enemy.m`, `Healer/DataObjects/Enemy.h` | Exports boss classes, base combat stats, sprite/title metadata, and directly-authored ability summaries from default boss definitions. |
| Implemented | `web/data/allies.json` | `Healer/DataObjects/RaidMember.m`, `Healer/DataObjects/RaidMember.h` | Exports raid ally archetype stats used by encounter assembly. |
| Implemented | `web/data/talents.json` | `Healer/Talents.m`, `Healer/talents.plist` | Exports tier ordering, required rating thresholds, talent descriptions, sprite ids, and direct stat adjustments defined in `Talents.m`. |
| Implemented | `web/data/shop.json` | `Healer/Shop.m`, `Healer/Shop.h`, `Healer/ShopItem.m`, `Healer/ShopItem.h` | Exports shop categories, unlock thresholds, spell inventory, and gold prices. |
| Implemented | `web/data/progression-schema.json` | `Healer/PlayerDataManager.m`, `Healer/PlayerDataManager.h`, `Healer/EquipmentItem.h` | Exports progression/persistence keys, FTUE states, content gating, inventory slots, and upgrade formulas. |
| Implemented | `web/data/tips.json` | `Healer/tips.plist` | Exports loading-screen tips verbatim for the browser shell. |
| Deferred | `web/data/abilities.json` | `Healer/Ability.m`, `Healer/Ability.h` | Next phase-1 pass should split reusable ability definitions out of enemy authoring. |
| Deferred | `web/data/effects.json` | `Healer/DataObjects/Effect.m`, `Healer/DataObjects/Effect.h` | Next phase-1 pass should normalize effect records shared by spells, talents, and enemies. |
| Deferred | `web/data/equipment-schema.json` | `Healer/EquipmentItem.m`, `Healer/EquipmentItem.h` | Next phase-1 pass should export item schema and special item spell hooks. |
| Deferred | `web/data/loot-rules.json` | `Healer/DataObjects/Encounter.m`, `Healer/EquipmentItem.m`, `Healer/LootTable.m` | Next phase-1 pass should separate boss loot tables from progression rules. |

## Validation workflow

- Regenerate data: `python3 tools/extract_phase1_data.py`
- Verify committed outputs: `python3 tools/extract_phase1_data.py --check`

Each generated dataset includes source-file provenance and SHA-256 hashes so future web-port work can diff extracted data against the native source of truth.
