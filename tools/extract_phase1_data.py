#!/usr/bin/env python3
import argparse
import ast
import difflib
import hashlib
import json
import plistlib
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "web" / "data"

SOURCE_FILES = {
    "encounters": [
        ROOT / "Healer" / "DataObjects" / "Encounter.m",
        ROOT / "Healer" / "DataObjects" / "Encounter.h",
    ],
    "spells": [
        ROOT / "Healer" / "DataObjects" / "Spell.m",
        ROOT / "Healer" / "DataObjects" / "Spell.h",
    ],
    "abilities": [
        ROOT / "Healer" / "Ability.m",
        ROOT / "Healer" / "Ability.h",
        ROOT / "Healer" / "DataObjects" / "Enemy.m",
        ROOT / "Healer" / "DataObjects" / "Enemy.h",
    ],
    "effects": [
        ROOT / "Healer" / "DataObjects" / "Effect.m",
        ROOT / "Healer" / "DataObjects" / "Effect.h",
        ROOT / "Healer" / "DataObjects" / "Spell.m",
        ROOT / "Healer" / "DataObjects" / "Spell.h",
        ROOT / "Healer" / "DataObjects" / "Enemy.m",
        ROOT / "Healer" / "DataObjects" / "Enemy.h",
    ],
    "enemies": [
        ROOT / "Healer" / "DataObjects" / "Enemy.m",
        ROOT / "Healer" / "DataObjects" / "Enemy.h",
    ],
    "allies": [
        ROOT / "Healer" / "DataObjects" / "RaidMember.m",
        ROOT / "Healer" / "DataObjects" / "RaidMember.h",
    ],
    "talents": [
        ROOT / "Healer" / "Talents.m",
        ROOT / "Healer" / "talents.plist",
    ],
    "shop": [
        ROOT / "Healer" / "Shop.m",
        ROOT / "Healer" / "Shop.h",
        ROOT / "Healer" / "ShopItem.m",
        ROOT / "Healer" / "ShopItem.h",
    ],
    "progression-schema": [
        ROOT / "Healer" / "PlayerDataManager.m",
        ROOT / "Healer" / "PlayerDataManager.h",
        ROOT / "Healer" / "EquipmentItem.h",
    ],
    "equipment-schema": [
        ROOT / "Healer" / "EquipmentItem.m",
        ROOT / "Healer" / "EquipmentItem.h",
    ],
    "loot-rules": [
        ROOT / "Healer" / "DataObjects" / "Encounter.m",
        ROOT / "Healer" / "LootTable.m",
        ROOT / "Healer" / "EquipmentItem.m",
        ROOT / "Healer" / "EquipmentItem.h",
    ],
    "tips": [
        ROOT / "Healer" / "tips.plist",
    ],
}

CONSTANTS = {
    "kCostEfficiencyScale": 1.2,
    "kHealingDoneScale": 0.9,
    "SOA_HEALING_AMOUNT": 200,
    "END_FREE_ENCOUNTER_LEVEL": 7,
    "MAXIMUM_ALLY_UPGRADES": 50,
}

SPELL_TARGETING_OVERRIDES = {
    "Respite": {"targetCount": 1, "targeting": "self"},
    "ForkedHeal": {"targetCount": 2, "targeting": "lowest_health_with_required_primary"},
    "LightEternal": {"targetCount": 5, "targeting": "same_position_as_primary"},
    "WardOfAncients": {"targetCount": "all_allies", "targeting": "raid_wide"},
    "TouchOfHope": {"targetCount": 1, "targeting": "selected_ally"},
    "SoaringSpirit": {"targetCount": 1, "targeting": "self"},
    "Sunburst": {"targetCount": 7, "targeting": "lowest_health_with_required_primary"},
    "StarsOfAravon": {"targetCount": 4, "targeting": "2_lowest_health_including_primary_plus_2_random"},
    "Attunement": {"targetCount": "all_allies", "targeting": "raid_wide"},
    "WanderingSpirit": {"targetCount": "all_allies", "targeting": "wanders_between_injured_allies"},
}

SPELL_INTERNAL_CLASSES = {"RaidHeal", "HealBuff", "LightBolt", "HastyBrew"}

ABILITY_FIELDS = {
    "key",
    "title",
    "iconName",
    "info",
    "cooldown",
    "activationTime",
    "abilityValue",
    "executionSound",
    "activationSound",
    "spriteName",
    "timeApplied",
    "stunDuration",
}

EFFECT_FIELDS = {
    "title",
    "spriteName",
    "numOfTicks",
    "valuePerTick",
    "value",
    "effectCooldown",
    "maxStacks",
    "visibilityPriority",
    "damageTakenMultiplierAdjustment",
    "damageDoneMultiplierAdjustment",
    "healingDoneMultiplierAdjustment",
    "healingReceivedMultiplierAdjustment",
    "castTimeAdjustment",
    "cooldownMultiplierAdjustment",
    "energyRegenAdjustment",
    "spellCostAdjustment",
    "criticalChanceAdjustment",
    "ailmentType",
    "isIndependent",
}

ABILITY_STRING_FIELDS = ABILITY_FIELDS | {
    "attackParticleEffectName",
    "breathParticleName",
    "damageAudioName",
    "explosionParticleName",
    "explosionSoundName",
    "pulseSoundTitle",
}

ABILITY_NUMERIC_FIELDS = (ABILITY_FIELDS - {"key", "title", "iconName", "info", "executionSound", "activationSound", "spriteName"}) | {
    "attacksPerTrigger",
    "bonusCriticalChance",
    "cooldownVariance",
    "criticalChance",
    "duration",
    "failureChance",
    "numberOfTargets",
    "numTargets",
    "stunDuration",
}

ABILITY_BOOL_FIELDS = {
    "ignoresBusy",
    "ignoresGuardians",
    "ignoresPlayers",
    "interruptAppliesDot",
    "prefersTargetsWithoutVisibleEffects",
    "removesPositiveEffects",
    "requiresDamageToApplyEffect",
}

EFFECT_STRING_FIELDS = EFFECT_FIELDS | {
    "completionParticleName",
    "particleEffectName",
}

EFFECT_NUMERIC_FIELDS = (EFFECT_FIELDS - {"title", "spriteName", "isIndependent"}) | {
    "amountPerReaction",
    "baseValue",
    "dodgeChanceAdjustment",
    "effectCooldown",
    "effectivePercentage",
    "energyChangePerCast",
    "failureChance",
    "getUpThreshold",
    "maximumAbsorbtionAdjustment",
    "maximumHealthMultiplierAdjustment",
    "numCastsRemaining",
    "percentageHealingReceived",
    "raidWidePulseCooldown",
    "threshold",
    "triggerCooldown",
}

EFFECT_BOOL_FIELDS = {
    "causesBlind",
    "causesConfusion",
    "causesReactiveDodge",
    "causesStun",
    "healthReduced",
    "ignoresDispels",
    "isIndependent",
    "needsDetonation",
}


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def source_metadata(dataset: str):
    files = SOURCE_FILES[dataset]
    return [
        {
            "path": str(path.relative_to(ROOT)),
            "sha256": sha256_text(read(path)),
        }
        for path in files
    ]


def dataset_wrapper(dataset: str, payload):
    return {
        "dataset": dataset,
        "generatedBy": "tools/extract_phase1_data.py",
        "sourceFiles": source_metadata(dataset),
        "payload": payload,
    }


def objc_string(value: str) -> str:
    return value.replace(r"\"", '"').replace(r"\n", "\n")


def slugify(value: str) -> str:
    return value.lower().replace(" ", "-")


def between(text: str, start: str, end: str) -> str:
    start_index = text.index(start)
    end_index = text.index(end, start_index)
    return text[start_index:end_index]


def split_implementations(text: str):
    matches = list(re.finditer(r"@implementation\s+(\w+)", text))
    blocks = {}
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        blocks[match.group(1)] = text[match.start():end]
    return blocks


def extract_method_block(block: str, method_pattern: str):
    match = re.search(method_pattern, block)
    if not match:
        return ""
    start = match.start()
    cursor = match.end()
    brace_depth = 0
    opened = False
    while cursor < len(block):
        char = block[cursor]
        if char == "{":
            brace_depth += 1
            opened = True
        elif char == "}":
            brace_depth -= 1
            if opened and brace_depth == 0:
                cursor += 1
                break
        cursor += 1
    return block[start:cursor]


def safe_eval(expression: str, context=None):
    if expression is None:
        return None
    expr = expression.strip().rstrip(";")
    if not expr:
        return None
    ctx = dict(CONSTANTS)
    if context:
        ctx.update(context)
    expr = re.sub(r"\((?:int|float|NSInteger|NSTimeInterval)\)", "", expr)
    expr = expr.replace("YES", "True").replace("NO", "False")
    for name, value in sorted(ctx.items(), key=lambda item: len(item[0]), reverse=True):
        expr = re.sub(rf"\b{re.escape(name)}\b", repr(value), expr)
    try:
        node = ast.parse(expr, mode="eval")
    except SyntaxError:
        return None

    allowed_nodes = (
        ast.Expression,
        ast.BinOp,
        ast.UnaryOp,
        ast.Add,
        ast.Sub,
        ast.Mult,
        ast.Div,
        ast.FloorDiv,
        ast.Mod,
        ast.Pow,
        ast.USub,
        ast.UAdd,
        ast.Constant,
        ast.Call,
        ast.Name,
        ast.Load,
    )
    for subnode in ast.walk(node):
        if not isinstance(subnode, allowed_nodes):
            return None
        if isinstance(subnode, ast.Call):
            if not isinstance(subnode.func, ast.Name) or subnode.func.id not in {"min", "max", "round"}:
                return None
    try:
        return eval(compile(node, "<expr>", "eval"), {"__builtins__": {}}, {"min": min, "max": max, "round": round})
    except Exception:
        return None


def number_or_expression(expression: str, context=None):
    value = safe_eval(expression, context=context)
    if isinstance(value, float):
        value = round(value, 4)
    return {
        "expression": expression.strip() if expression else None,
        "value": value,
    }


def parse_string_setters(text: str, variable_name: str, field_names):
    result = {}
    for field in field_names:
        matches = re.findall(
            rf"\[{re.escape(variable_name)} set{field[0].upper()}{field[1:]}:@\"((?:\\.|[^\"\\])*)\"\];",
            text,
        )
        if matches:
            result[field] = objc_string(matches[-1])
    for field in field_names:
        matches = re.findall(
            rf"{re.escape(variable_name)}\.{field}\s*=\s*@\"((?:\\.|[^\"\\])*)\";",
            text,
        )
        if matches:
            result[field] = objc_string(matches[-1])
    return result


def parse_numeric_setters(text: str, variable_name: str, field_names, context=None):
    result = {}
    for field in field_names:
        matches = re.findall(
            rf"\[{re.escape(variable_name)} set{field[0].upper()}{field[1:]}:([^\]]+)\];",
            text,
        )
        if matches:
            result[field] = number_or_expression(matches[-1], context=context)
        matches = re.findall(
            rf"{re.escape(variable_name)}\.{field}\s*=\s*([^;]+);",
            text,
        )
        if matches:
            result[field] = number_or_expression(matches[-1], context=context)
    return result


def parse_bool_setters(text: str, variable_name: str, field_names):
    result = {}
    for field in field_names:
        matches = re.findall(
            rf"\[{re.escape(variable_name)} set{field[0].upper()}{field[1:]}:(YES|NO)\];",
            text,
        )
        if matches:
            result[field] = matches[-1] == "YES"
        matches = re.findall(
            rf"{re.escape(variable_name)}\.{field}\s*=\s*(YES|NO);",
            text,
        )
        if matches:
            result[field] = matches[-1] == "YES"
    return result


def merge_missing_fields(primary, secondary):
    for key, value in secondary.items():
        if key not in primary or primary[key] in (None, "", {}, []):
            primary[key] = value
    return primary


def effect_identifier(effect):
    if not effect:
        return None
    return effect.get("title") or effect.get("key") or effect.get("className")


def ability_identifier(ability):
    if not ability:
        return None
    return (
        ability.get("key")
        or (slugify(ability["title"]) if ability.get("title") else None)
        or (
            f"{ability.get('className')}::{ability.get('factoryMethod')}"
            if ability.get("className") and ability.get("factoryMethod")
            else None
        )
        or ability.get("className")
    )


def render_nsstring_formats(text: str, context=None):
    rendered = {}
    for match in re.finditer(
        r'NSString\s+\*(\w+)\s*=\s*\[NSString stringWithFormat:@\"((?:\\.|[^\"\\])*)\",(.*?)\];',
        text,
        re.DOTALL,
    ):
        name, fmt, args = match.groups()
        arg_parts = [part.strip() for part in args.split(",") if part.strip()]
        values = []
        for part in arg_parts:
            value = safe_eval(part, context=context)
            if value is None:
                break
            values.append(value)
        else:
            python_fmt = objc_string(fmt).replace("%i", "%d")
            try:
                rendered[name] = python_fmt % tuple(values)
            except TypeError:
                pass
    return rendered


def parse_case_value_map(text: str, return_type: str):
    body = extract_method_block(text, return_type)
    mapping = {}
    current_cases = []
    current_assignment = None
    for raw_line in body.splitlines():
        line = raw_line.strip()
        case_match = re.match(r"case\s+(\d+):", line)
        if case_match:
            current_cases.append(int(case_match.group(1)))
            continue
        if line.startswith("default:"):
            current_cases = []
            current_assignment = None
            continue
        return_match = re.match(r'return\s+(@?"?[^;]+);', line)
        if return_match and current_cases:
            raw_value = return_match.group(1).strip()
            value = objc_string(raw_value[2:-1]) if raw_value.startswith('@"') else safe_eval(raw_value)
            for case in current_cases:
                mapping[case] = value
            current_cases = []
            current_assignment = None
            continue
        assign_match = re.match(r'(\w+)\s*=\s*(@?"?[^;]+);', line)
        if assign_match:
            current_assignment = assign_match.group(2).strip()
            continue
        if line == "break;" and current_cases and current_assignment is not None:
            raw_value = current_assignment
            value = objc_string(raw_value[2:-1]) if raw_value.startswith('@"') else safe_eval(raw_value)
            for case in current_cases:
                mapping[case] = value
            current_cases = []
            current_assignment = None
    return mapping


def parse_enum_block(text: str, enum_name: str):
    match = next(
        (candidate for candidate in re.finditer(r"typedef enum\s*\{([\s\S]*?)\}\s*(\w+)\s*;", text) if candidate.group(2) == enum_name),
        None,
    )
    if not match:
        return []
    token_pattern = re.compile(r"(\w+)(?:\s*=\s*(-?\d+))?")
    entries = []
    for raw_line in match.group(1).splitlines():
        line = raw_line.split("//", 1)[0].strip().rstrip(",")
        if not line or line.startswith("//"):
            continue
        token_match = token_pattern.match(line)
        if not token_match:
            continue
        token, explicit_value = token_match.groups()
        if explicit_value is not None:
            value = int(explicit_value)
        elif entries:
            value = entries[-1]["value"] + 1
        else:
            value = 0
        entries.append({"token": token, "value": value})
    return entries


def parse_equipment_item_initializers(block: str):
    records = []
    pattern = re.compile(
        r'EquipmentItem\s*\*\w+\s*=\s*\[\[\[EquipmentItem alloc\] initWithName:@\"((?:\\.|[^\"\\])*)\"\s+'
        r'health:(.*?)\s+regen:(.*?)\s+speed:(.*?)\s+crit:(.*?)\s+healing:(.*?)\s+slot:(\w+)\s+'
        r'rarity:(\w+)\s+specialKey:(nil|@\"((?:\\.|[^\"\\])*)\")\s+quality:(.*?)\s+uniqueId:(.*?)\] autorelease\];',
        re.DOTALL,
    )
    for match in pattern.finditer(block):
        (
            name,
            health,
            regen,
            speed,
            crit,
            healing,
            slot,
            rarity,
            _special_raw,
            special_key,
            quality,
            unique_id,
        ) = match.groups()
        canonical_item_id_prefix = re.sub(r"[^a-z0-9]+", "-", slugify(objc_string(name))).strip("-")
        records.append(
            {
                "id": f"{canonical_item_id_prefix}-{safe_eval(unique_id)}",
                "name": objc_string(name),
                "health": safe_eval(health),
                "regen": safe_eval(regen),
                "speed": safe_eval(speed),
                "crit": safe_eval(crit),
                "healing": safe_eval(healing),
                "slot": slot,
                "rarity": rarity,
                "specialKey": objc_string(special_key) if special_key else None,
                "quality": safe_eval(quality),
            }
        )
    return records


def extract_encounters():
    text = read(ROOT / "Healer" / "DataObjects" / "Encounter.m")
    body = between(text, "+ (Encounter*)normalEncounterForLevel", "+(NSInteger)goldForLevelNumber")
    gold_map = parse_case_value_map(text, r"\+\(NSInteger\)goldForLevelNumber:\(NSInteger\)levelNumber")
    background_map = parse_case_value_map(text, r"\+ \(NSString \*\)backgroundPathForEncounter:\(NSInteger\)encounter")
    battle_track_body = extract_method_block(text, r"- \(NSString \*\)battleTrackTitle")
    battle2_levels = {int(level) for level in re.findall(r"case\s+(\d+):", battle_track_body)}

    encounters = []
    for match in re.finditer(r"if \(level == (\d+)\)\{([\s\S]*?)\n    \}", body):
        level = int(match.group(1))
        block = match.group(2)
        temp_enemies = {}
        for init_match in re.finditer(
            r"(\w+)\s*\*(\w+)\s*=\s*\[\[\[(\w+) alloc\] initWithHealth:(.*?) damage:(.*?) targets:(.*?) frequency:(.*?) choosesMT:(YES|NO)\] autorelease\];",
            block,
        ):
            declared_type, var_name, class_name, health, damage, targets, frequency, chooses = init_match.groups()
            temp_enemies[var_name] = {
                "declaredType": declared_type,
                "className": class_name,
                "health": number_or_expression(health),
                "damage": number_or_expression(damage),
                "targets": number_or_expression(targets),
                "frequency": number_or_expression(frequency),
                "choosesMainTarget": chooses == "YES",
            }

        for default_boss_match in re.finditer(r"(\w+)\s*\*(\w+)\s*=\s*\[(\w+) defaultBoss\];", block):
            declared_type, var_name, class_name = default_boss_match.groups()
            temp_enemies[var_name] = {
                "declaredType": declared_type,
                "className": class_name,
                "source": "defaultBoss",
            }

        for var_name, info in temp_enemies.items():
            info.update(parse_string_setters(block, var_name, {"spriteName", "title", "key", "iconName", "info"}))
            info.update(parse_numeric_setters(block, var_name, {"threatPriority"}))

        enemy_roster = []
        for default_boss in re.findall(r"\[enemies addObject:\[(\w+) defaultBoss\]\];", block):
            enemy_roster.append({"className": default_boss, "source": "defaultBoss"})
        for var_name in re.findall(r"\[enemies addObject:(\w+)\];", block):
            if var_name in temp_enemies:
                enemy_roster.append(temp_enemies[var_name])

        spell_array_match = re.search(r"spells = \[NSArray arrayWithObjects:(.*?), nil\];", block, re.DOTALL)
        recommended_spells = re.findall(r"\[(\w+) defaultSpell\]", spell_array_match.group(1) if spell_array_match else "")

        ally_composition = {}
        for ally_key in ["Archer", "Guardian", "Champion", "Warlock", "Wizard", "Berserker"]:
            count_match = re.search(rf"num{ally_key}\s*=\s*(\d+);", block)
            if count_match:
                ally_composition[ally_key.lower()] = int(count_match.group(1))

        boss_key = re.search(r'bossKey = @\"((?:\\.|[^\"\\])*)\";', block)
        title = re.search(r'title = @\"((?:\\.|[^\"\\])*)\";', block)
        info = re.search(r'info = @\"((?:\\.|[^\"\\])*)\";', block)
        encounters.append(
            {
                "level": level,
                "title": objc_string(title.group(1)) if title else None,
                "info": objc_string(info.group(1)) if info else None,
                "bossKey": objc_string(boss_key.group(1)) if boss_key else None,
                "recommendedSpellIds": recommended_spells,
                "allyComposition": ally_composition,
                "multiplayerAdjustments": {"warlock": -1},
                "enemyRoster": enemy_roster,
                "baseRewardGold": gold_map.get(level),
                "lootRuleId": f"level-{level}",
                "backgroundKey": background_map.get(level),
                "battleTrackTitle": "sounds/battle2.mp3" if level in battle2_levels else "sounds/battle1.mp3",
            }
        )
    return sorted(encounters, key=lambda entry: entry["level"])


def build_effect_summary(default_block: str, spell_context):
    effect_match = re.search(
        r"(\w+)\s*\*(\w+)\s*=\s*\[\[\[?(\w+) alloc\] initWithDuration:(.*?) andEffectType:(\w+)\](?: autorelease\])?;",
        default_block,
    )
    if not effect_match:
        return None
    declared_type, var_name, class_name, duration, effect_type = effect_match.groups()
    effect = {
        "declaredType": declared_type,
        "className": class_name,
        "duration": number_or_expression(duration, context=spell_context),
        "effectType": effect_type,
    }
    effect.update(parse_string_setters(default_block, var_name, EFFECT_STRING_FIELDS))
    effect.update(parse_numeric_setters(default_block, var_name, EFFECT_NUMERIC_FIELDS, context=spell_context))
    effect.update(parse_bool_setters(default_block, var_name, EFFECT_BOOL_FIELDS))
    effect["id"] = effect_identifier(effect)
    return effect


def parse_effect_initializer(effect_match, block: str, context=None):
    declared_type, var_name, class_name, duration, effect_type = effect_match.groups()
    effect = {
        "declaredType": declared_type,
        "className": class_name,
        "duration": number_or_expression(duration, context=context),
        "effectType": effect_type,
    }
    effect.update(parse_string_setters(block, var_name, EFFECT_STRING_FIELDS))
    effect.update(parse_numeric_setters(block, var_name, EFFECT_NUMERIC_FIELDS, context=context))
    effect.update(parse_bool_setters(block, var_name, EFFECT_BOOL_FIELDS))
    effect["id"] = effect_identifier(effect)
    return var_name, effect


def extract_declared_effects(block: str, context=None):
    effects = {}
    for effect_match in re.finditer(
        r"(\w+)\s*\*(\w+)\s*=\s*\[\[\[?(\w+) alloc\] initWithDuration:(.*?) andEffectType:(\w+)\](?: autorelease\])?;",
        block,
        re.DOTALL,
    ):
        var_name, effect = parse_effect_initializer(effect_match, block, context=context)
        effects[var_name] = effect
    return effects


def extract_default_effects():
    text = read(ROOT / "Healer" / "DataObjects" / "Effect.m")
    implementations = split_implementations(text)
    effects = {}
    for class_name, block in implementations.items():
        default_block = extract_method_block(block, r"\+\s*\([^)]*\)defaultEffect")
        if not default_block:
            continue
        effect_match = re.search(
            r"(\w+)\s*\*(\w+)\s*=\s*\[\[\[?(\w+) alloc\] initWithDuration:(.*?) andEffectType:(\w+)\](?: autorelease\])?;",
            default_block,
            re.DOTALL,
        )
        if not effect_match:
            continue
        _, effect = parse_effect_initializer(effect_match, default_block)
        effect["factoryMethod"] = "defaultEffect"
        effects[class_name] = effect
    return effects


def extract_ability_factories():
    text = read(ROOT / "Healer" / "Ability.m")
    implementations = split_implementations(text)
    factories = {}
    cleave_block = extract_method_block(implementations.get("Cleave", ""), r"\+\s*\(Cleave \*\)normalCleave")
    if cleave_block:
        init_match = re.search(
            r"(\w+)\s*\*(\w+)\s*=\s*\[\[\[?(\w+) alloc\] init[^\]]*\](?: autorelease)?\];",
            cleave_block,
            re.DOTALL,
        )
        if init_match:
            declared_type, variable_name, class_name = init_match.groups()
            ability = {
                "declaredType": declared_type,
                "className": class_name,
                "factoryMethod": "normalCleave",
            }
            ability.update(parse_string_setters(cleave_block, variable_name, ABILITY_STRING_FIELDS))
            ability.update(parse_numeric_setters(cleave_block, variable_name, ABILITY_NUMERIC_FIELDS))
            ability.update(parse_bool_setters(cleave_block, variable_name, ABILITY_BOOL_FIELDS))
            ability["id"] = ability_identifier(ability)
            factories[(class_name, "normalCleave")] = ability
    return factories


def extract_spells():
    text = read(ROOT / "Healer" / "DataObjects" / "Spell.m")
    shipping_text = text.split("#pragma mark Test Spells")[0]
    implementations = split_implementations(shipping_text)

    spells = []
    for class_name, block in implementations.items():
        if class_name == "Spell":
            continue
        default_block = extract_method_block(block, r"\+\s*\(id\)defaultSpell")
        if not default_block:
            continue
        init_match = re.search(
            r"(\w+)\s*\*(\w+)\s*=\s*\[\[?\[?%s alloc\] initWithTitle:@\"((?:\\.|[^\"\\])*)\" healAmnt:(.*?) energyCost:(.*?) castTime:(.*?) andCooldown:(.*?)\]" % re.escape(class_name),
            default_block,
            re.DOTALL,
        )
        if not init_match:
            continue
        _, variable_name, title, healing_expr, energy_expr, cast_expr, cooldown_expr = init_match.groups()
        spell_type_match = re.search(r"self\.spellType = (SpellType\w+);", block)
        spell_context = {}
        healing = number_or_expression(healing_expr)
        energy = number_or_expression(energy_expr)
        cast_time = number_or_expression(cast_expr)
        cooldown = number_or_expression(cooldown_expr)
        spell_context[f"{variable_name}.energyCost"] = energy["value"]
        spell_context[f"{variable_name}.cooldown"] = cooldown["value"]

        descriptions = render_nsstring_formats(default_block, context=spell_context)
        direct_description = re.search(rf"\[{re.escape(variable_name)} setSpellDescription:@\"((?:\\.|[^\"\\])*)\"\];", default_block)
        indirect_description = re.search(rf"\[{re.escape(variable_name)} setSpellDescription:(\w+)\];", default_block)
        if direct_description:
            description = objc_string(direct_description.group(1))
        elif indirect_description and indirect_description.group(1) in descriptions:
            description = descriptions[indirect_description.group(1)]
        else:
            description = None

        item_sprite = re.search(rf"\[{re.escape(variable_name)} setItemSpriteName:@\"((?:\\.|[^\"\\])*)\"\];", default_block)
        item_sprite_name = objc_string(item_sprite.group(1)) if item_sprite else None

        end_audio_match = re.search(r'self\.endCastingAudioTitle = @\"((?:\\.|[^\"\\])*)\";', block)
        begin_audio_match = re.search(r'self\.beginCastingAudioTitle = @\"((?:\\.|[^\"\\])*)\";', block)
        interrupted_audio_match = re.search(r'self\.interruptedAudioTitle = @\"((?:\\.|[^\"\\])*)\";', block)

        effect_summary = build_effect_summary(default_block, spell_context)
        targeting = SPELL_TARGETING_OVERRIDES.get(class_name, {"targetCount": 1, "targeting": "selected_ally"})
        if class_name in {"Respite", "SoaringSpirit"}:
            targeting = SPELL_TARGETING_OVERRIDES[class_name]

        spells.append(
            {
                "id": class_name,
                "title": objc_string(title),
                "classification": "internal" if class_name in SPELL_INTERNAL_CLASSES else "player",
                "spellType": spell_type_match.group(1).replace("SpellType", "").lower() if spell_type_match else None,
                "healingAmount": healing,
                "energyCost": energy,
                "castTime": cast_time,
                "cooldown": cooldown,
                "descriptionTemplate": description,
                "iconFrameName": item_sprite_name or f"{slugify(objc_string(title))}-icon.png",
                "itemSpriteName": item_sprite_name,
                "beginCastingAudioTitle": objc_string(begin_audio_match.group(1)) if begin_audio_match else "heal_begin.mp3",
                "endCastingAudioTitle": objc_string(end_audio_match.group(1)) if end_audio_match else "heal_finish.mp3",
                "interruptedAudioTitle": objc_string(interrupted_audio_match.group(1)) if interrupted_audio_match else "interrupted.mp3",
                "isExclusiveEffectTarget": "[%s setIsExclusiveEffectTarget:YES];" % variable_name in default_block,
                "targetCount": targeting["targetCount"],
                "targeting": targeting["targeting"],
                "appliedEffectId": effect_identifier(effect_summary),
                "appliedEffect": effect_summary,
            }
        )
    return sorted(spells, key=lambda entry: (entry["classification"], entry["title"]))


def parse_ability_initializer_fields(initializer_tail: str):
    result = {}
    init_match = re.search(r"initWithDamage:(.*?) andCooldown:(.*?)(?:\]|$)", initializer_tail, re.DOTALL)
    if init_match:
        ability_value, cooldown = init_match.groups()
        result["abilityValue"] = number_or_expression(ability_value)
        result["cooldown"] = number_or_expression(cooldown)
    return result


def extract_enemies(default_effects=None, ability_factories=None):
    default_effects = default_effects or {}
    ability_factories = ability_factories or {}
    text = read(ROOT / "Healer" / "DataObjects" / "Enemy.m")
    implementations = split_implementations(text)
    enemies = []
    for class_name, block in implementations.items():
        if class_name == "Enemy":
            continue
        default_block = extract_method_block(block, r"\+\(id\)defaultBoss|\+ \(id\)defaultBoss")
        if not default_block:
            continue
        init_match = re.search(
            r"%s\s*\*(\w+)\s*=\s*\[\[%s alloc\] initWithHealth:(.*?) damage:(.*?) targets:(.*?) frequency:(.*?) choosesMT:(YES|NO)\s*\]" % (re.escape(class_name), re.escape(class_name)),
            default_block,
            re.DOTALL,
        )
        if not init_match:
            continue
        variable_name, health, damage, targets, frequency, chooses_main_target = init_match.groups()
        record = {
            "id": class_name,
            "className": class_name,
            "health": number_or_expression(health),
            "damage": number_or_expression(damage),
            "targets": number_or_expression(targets),
            "attackFrequency": number_or_expression(frequency),
            "choosesMainTarget": chooses_main_target == "YES",
        }
        title_match = re.search(rf"\[{re.escape(variable_name)} setTitle:@\"((?:\\.|[^\"\\])*)\"\];", default_block)
        sprite_match = re.search(rf"\[{re.escape(variable_name)} setSpriteName:@\"((?:\\.|[^\"\\])*)\"\];", default_block)
        if title_match:
            record["title"] = objc_string(title_match.group(1))
        if sprite_match:
            record["spriteName"] = objc_string(sprite_match.group(1))

        auto_attack_fields = {}
        for field in ["failureChance", "dodgeChanceAdjustment"]:
            match = re.search(rf"{re.escape(variable_name)}\.autoAttack\.{field}\s*=\s*([^;]+);", default_block)
            if match:
                auto_attack_fields[field] = number_or_expression(match.group(1))
        if auto_attack_fields:
            record["autoAttackAdjustments"] = auto_attack_fields

        abilities = []
        temp_effects = extract_declared_effects(default_block)
        temp_abilities = {}
        for ability_match in re.finditer(
            r"(\w+)\s*\*(\w+)\s*=\s*(?:\[\[\[(\w+) alloc\](.*?)\] autorelease\]|\[(\w+) ([^\]]+)\]);",
            default_block,
            re.DOTALL,
        ):
            declared_type, variable, alloc_class, alloc_tail, class_factory, factory_method = ability_match.groups()
            class_value = alloc_class or class_factory
            temp_abilities[variable] = {
                "declaredType": declared_type,
                "className": class_value,
            }
            if alloc_tail:
                temp_abilities[variable].update(parse_ability_initializer_fields(alloc_tail))
            if factory_method:
                temp_abilities[variable]["factoryMethod"] = factory_method.strip()
        for variable_name, ability in temp_abilities.items():
            ability.update(parse_string_setters(default_block, variable_name, ABILITY_STRING_FIELDS))
            ability.update(parse_numeric_setters(default_block, variable_name, ABILITY_NUMERIC_FIELDS))
            ability.update(parse_bool_setters(default_block, variable_name, ABILITY_BOOL_FIELDS))
            effect_match = re.search(
                rf"\[(?:\(\w+\*\))?{re.escape(variable_name)} setAppliedEffect:(\w+)\];",
                default_block,
            )
            default_effect_match = re.search(
                rf"\[(?:\(\w+\*\))?{re.escape(variable_name)} setAppliedEffect:\[(\w+) defaultEffect\]\];",
                default_block,
            )
            if effect_match and effect_match.group(1) in temp_effects:
                ability["appliedEffect"] = temp_effects[effect_match.group(1)]
            elif default_effect_match and default_effect_match.group(1) in default_effects:
                ability["appliedEffect"] = default_effects[default_effect_match.group(1)]
            if ability.get("factoryMethod") and (ability.get("className"), ability.get("factoryMethod")) in ability_factories:
                merge_missing_fields(ability, ability_factories[(ability.get("className"), ability.get("factoryMethod"))])
            ability["id"] = ability_identifier(ability)
            ability["appliedEffectId"] = effect_identifier(ability.get("appliedEffect"))
        for added_variable in re.findall(r"\[\w+ addAbility:(\w+)\];", default_block):
            if added_variable in temp_abilities:
                abilities.append(temp_abilities[added_variable])
        record["abilities"] = abilities
        enemies.append(record)
    return sorted(enemies, key=lambda entry: entry.get("title", entry["id"]))


def extract_abilities(enemies):
    abilities_by_id = {}
    for enemy in enemies:
        for ability in enemy.get("abilities", []):
            ability_id = ability_identifier(ability)
            if ability_id not in abilities_by_id:
                canonical = dict(ability)
                canonical["id"] = ability_id
                canonical["usedByEnemyIds"] = [enemy["id"]]
                abilities_by_id[ability_id] = canonical
            else:
                merge_missing_fields(abilities_by_id[ability_id], ability)
                if enemy["id"] not in abilities_by_id[ability_id]["usedByEnemyIds"]:
                    abilities_by_id[ability_id]["usedByEnemyIds"].append(enemy["id"])
    return sorted(abilities_by_id.values(), key=lambda entry: entry["id"])


def extract_effects(spells, enemies, default_effects):
    effects_by_id = {}

    def register(effect, *, source_type, source_id):
        if not effect:
            return
        effect_id = effect_identifier(effect)
        if not effect_id:
            return
        if effect_id not in effects_by_id:
            canonical = dict(effect)
            canonical["id"] = effect_id
            canonical["usedBySpells"] = []
            canonical["usedByAbilities"] = []
            canonical["factorySources"] = []
            effects_by_id[effect_id] = canonical
        else:
            merge_missing_fields(effects_by_id[effect_id], effect)
        if source_type == "spell" and source_id not in effects_by_id[effect_id]["usedBySpells"]:
            effects_by_id[effect_id]["usedBySpells"].append(source_id)
        elif source_type == "ability" and source_id not in effects_by_id[effect_id]["usedByAbilities"]:
            effects_by_id[effect_id]["usedByAbilities"].append(source_id)
        elif source_type == "factory" and source_id not in effects_by_id[effect_id]["factorySources"]:
            effects_by_id[effect_id]["factorySources"].append(source_id)

    for spell in spells:
        register(spell.get("appliedEffect"), source_type="spell", source_id=spell["id"])
    for enemy in enemies:
        for ability in enemy.get("abilities", []):
            register(ability.get("appliedEffect"), source_type="ability", source_id=ability["id"])
    for class_name, effect in default_effects.items():
        register(effect, source_type="factory", source_id=class_name)

    return sorted(effects_by_id.values(), key=lambda entry: entry["id"])


def extract_allies():
    text = read(ROOT / "Healer" / "DataObjects" / "RaidMember.m")
    implementations = split_implementations(text)
    ally_classes = ["Guardian", "Berserker", "Archer", "Champion", "Wizard", "Warlock"]
    allies = []
    for class_name in ally_classes:
        block = implementations[class_name]
        init_block = extract_method_block(block, r"- \(id\)init")
        init_match = re.search(
            r"\[super initWithHealth:(.*?) damageDealt:(.*?) andDmgFrequency:(.*?) andPositioning:(\w+)\]",
            init_block,
            re.DOTALL,
        )
        if not init_match:
            continue
        health, damage, frequency, positioning = init_match.groups()
        title_match = re.search(r'self\.title = @\"((?:\\.|[^\"\\])*)\";', init_block)
        info_match = re.search(r'self\.info = @\"((?:\\.|[^\"\\])*)\";', init_block)
        dodge_match = re.search(r"self\.dodgeChance = ([^;]+);", init_block)
        crit_match = re.search(r"self\.criticalChance = ([^;]+);", init_block)
        allies.append(
            {
                "id": class_name,
                "title": objc_string(title_match.group(1)) if title_match else class_name,
                "info": objc_string(info_match.group(1)) if info_match else None,
                "health": number_or_expression(health),
                "damageDealt": number_or_expression(damage),
                "damageFrequency": number_or_expression(frequency),
                "positioning": positioning.lower(),
                "dodgeChance": number_or_expression(dodge_match.group(1)) if dodge_match else None,
                "criticalChance": number_or_expression(crit_match.group(1)) if crit_match else {"expression": "0.05", "value": 0.05},
            }
        )
    return allies


def extract_talents():
    talent_text = read(ROOT / "Healer" / "Talents.m")
    descriptions = plistlib.loads((ROOT / "Healer" / "talents.plist").read_bytes())
    tiers = {}
    tier_switch = extract_method_block(talent_text, r"\+ \(NSArray\*\)talentChoicesForTier:\(NSInteger\)tier")
    for case_match in re.finditer(r"case\s+(\d+):([\s\S]*?)break;", tier_switch):
        tier = int(case_match.group(1))
        titles = [objc_string(value) for value in re.findall(r'addObject:@\"((?:\\.|[^\"\\])*)\"', case_match.group(2))]
        tiers[tier] = titles
    required_ratings = {}
    rating_switch = extract_method_block(talent_text, r"\+ \(NSInteger\)requiredRatingForTier:\(NSInteger\)tier")
    for case_match in re.finditer(r"case\s+(\d+):\s*return\s+(\d+);", rating_switch):
        required_ratings[int(case_match.group(1))] = int(case_match.group(2))

    adjustments = {}
    for effect_match in re.finditer(
        r'if \(\[tierChoiceKey isEqualToString:@\"((?:\\.|[^\"\\])*)\"\]\)\s*\{([\s\S]*?)\n\s*\}',
        talent_text,
    ):
        key = objc_string(effect_match.group(1))
        block = effect_match.group(2)
        mods = {}
        for setter, expression in re.findall(r"\[divEff set(\w+):([^\]]+)\];", block):
            field = setter[0].lower() + setter[1:]
            mods[field] = number_or_expression(expression)
        adjustments[key] = mods

    talents = []
    for tier, titles in sorted(tiers.items()):
        for index, title in enumerate(titles):
            key = slugify(title)
            talents.append(
                {
                    "tier": tier,
                    "choiceIndex": index,
                    "title": title,
                    "key": key,
                    "spriteFrameName": f"{key}-icon.png",
                    "requiredRating": required_ratings.get(tier),
                    "description": descriptions.get(key),
                    "staticAdjustments": adjustments.get(key, {}),
                }
            )
    return talents


def extract_shop(spells):
    shop_text = read(ROOT / "Healer" / "Shop.m")
    shop_item_text = read(ROOT / "Healer" / "ShopItem.m")
    spell_titles = {spell["id"]: spell["title"] for spell in spells}
    thresholds = {
        category.lower().replace("shopcategory", ""): int(value)
        for category, value in re.findall(r"case\s+(ShopCategory\w+):\s*return\s+(\d+);", extract_method_block(shop_text, r"\+ \(NSInteger\)purchasesForCategory:\(ShopCategory\)category"))
    }
    category_blocks = {
        "essentials": extract_method_block(shop_text, r"\+ \(NSArray\*\)essentialsShopItems"),
        "advanced": extract_method_block(shop_text, r"\+ \(NSArray\*\)advancedShopItems"),
        "archives": extract_method_block(shop_text, r"\+ \(NSArray\*\)archivesShopItems"),
        "vault": extract_method_block(shop_text, r"\+ \(NSArray\*\)vaultShopItems"),
    }
    cost_map = {}
    for title, cost in re.findall(r'if \(\[spell isEqualToString:@\"((?:\\.|[^\"\\])*)\"\]\)\s*\{\s*return\s+(\d+);', shop_item_text):
        cost_map[objc_string(title)] = int(cost)

    items = []
    for category_name, block in category_blocks.items():
        spell_ids = re.findall(r"\[(\w+) defaultSpell\]", block)
        for spell_id in spell_ids:
            title = spell_titles.get(spell_id, spell_id)
            items.append(
                {
                    "category": category_name,
                    "spellId": spell_id,
                    "title": title,
                    "goldCost": cost_map.get(title),
                }
            )
    return {
        "unlockThresholdsByCategory": {
            "essentials": thresholds.get("essentials"),
            "advanced": thresholds.get("advanced"),
            "archives": thresholds.get("archives"),
            "vault": thresholds.get("vault"),
        },
        "items": sorted(items, key=lambda item: (item["goldCost"], item["title"])),
    }


def extract_progression_schema():
    header_text = read(ROOT / "Healer" / "PlayerDataManager.h")
    impl_text = read(ROOT / "Healer" / "PlayerDataManager.m")
    equipment_header = read(ROOT / "Healer" / "EquipmentItem.h")

    persistence_keys = {
        name: value
        for name, value in re.findall(r'NSString\* const (\w+) = @\"((?:\\.|[^\"\\])*)\";', impl_text)
    }
    ftue_states = []
    ftue_enum = re.search(r"typedef enum \{([\s\S]*?)\} FTUEState;", header_text)
    if ftue_enum:
        for line in ftue_enum.group(1).splitlines():
            match = re.search(r"(FTUEState\w+)", line)
            if match:
                ftue_states.append(match.group(1))

    slot_types = re.findall(r"SlotType(\w+),", equipment_header)
    difficulty_default_size = re.search(r"for \(int i = 0; i < (\d+); i\+\+\)\{\s*\[difficultyLevels addObject:@(\d+)\];", impl_text)
    talent_ratings = []
    for tier in range(5):
        match = re.search(rf"case {tier}:\s*return (\d+);", read(ROOT / "Healer" / "Talents.m"))
        talent_ratings.append({"tier": tier, "requiredRating": int(match.group(1)) if match else None})

    return {
        "contentGate": {
            "mainGameContentKey": persistence_keys.get("MainGameContentKey"),
            "endFreeEncounterLevel": CONSTANTS["END_FREE_ENCOUNTER_LEVEL"],
            "endFreeUpsellText": re.search(r'#define END_FREE_STRING @\"((?:\\.|[^\"\\])*)\"', header_text).group(1),
        },
        "ftueStates": ftue_states,
        "progressionRules": {
            "difficultyDefaultValue": int(difficulty_default_size.group(2)) if difficulty_default_size else 2,
            "difficultyTrackedLevelSlots": int(difficulty_default_size.group(1)) if difficulty_default_size else 25,
            "multiplayerUnlockAtHighestLevelCompleted": 6,
            "tutorialLevelHasNoRating": True,
            "totalRatingStartsAtLevel": 2,
            "maximumStandardSpellSlots": {"base": 3, "mainGameExpansionBonus": 1},
            "maximumInventorySize": 15,
            "allyUpgradeCost": {"base": 200, "step": 50, "maximumHealthUpgrades": CONSTANTS["MAXIMUM_ALLY_UPGRADES"]},
            "talentTierUnlocks": talent_ratings,
        },
        "inventorySlots": [slot.lower() for slot in slot_types if slot != "Maximum"],
        "persistenceKeys": persistence_keys,
        "staminaSource": {
            "provider": "Parse Cloud",
            "readFunction": "getStamina",
            "spendFunction": "useStamina",
        },
    }


def extract_equipment_schema():
    header_text = read(ROOT / "Healer" / "EquipmentItem.h")
    impl_text = read(ROOT / "Healer" / "EquipmentItem.m")

    slot_enum = parse_enum_block(header_text, "SlotType")
    stat_enum = parse_enum_block(header_text, "StatType")
    rarity_enum = parse_enum_block(header_text, "ItemRarity")

    slot_tokens = [entry["token"] for entry in slot_enum if entry["token"] != "SlotTypeMaximum"]
    stat_tokens = [entry["token"] for entry in stat_enum if entry["token"] != "StatTypeMaximum"]

    stat_atoms_match = re.search(r"static float stat_atoms\[StatTypeMaximum\]\s*=\s*\{([\s\S]*?)\};", impl_text)
    stat_atoms = [float(value) for value in re.findall(r"(-?\d+(?:\.\d+)?)", stat_atoms_match.group(1))] if stat_atoms_match else []
    stat_atoms_by_type = {
        stat_tokens[index].replace("StatType", "").lower(): stat_atoms[index]
        for index in range(min(len(stat_tokens), len(stat_atoms)))
    }

    slot_modifier_match = re.search(r"slotModifiers\[SlotTypeMaximum\]\s*=\s*\{([\s\S]*?)\};", impl_text)
    slot_modifiers = [float(value) for value in re.findall(r"(-?\d+(?:\.\d+)?)", slot_modifier_match.group(1))] if slot_modifier_match else []
    slot_modifier_by_type = {
        slot_tokens[index].replace("SlotType", "").lower(): slot_modifiers[index]
        for index in range(min(len(slot_tokens), len(slot_modifiers)))
    }

    slot_prefixes_match = re.search(r"\+ \(NSArray \*\)slotPrefixes\{([\s\S]*?)return slotPrefix;", impl_text)
    slot_prefixes = []
    if slot_prefixes_match:
        for raw_line in slot_prefixes_match.group(1).splitlines():
            if "//" not in raw_line:
                continue
            values = [objc_string(value) for value in re.findall(r'@\"((?:\\.|[^\"\\])*)\"', raw_line)]
            if values:
                slot_prefixes.append(values)
    slot_prefixes_by_type = {
        slot_tokens[index].replace("SlotType", "").lower(): values
        for index, values in enumerate(slot_prefixes or [])
        if index < len(slot_tokens)
    }

    suffixes_match = re.search(r"\+ \(NSArray \*\)suffixes \{([\s\S]*?)return suffix;", impl_text)
    suffixes = [objc_string(value) for value in re.findall(r'@\"((?:\\.|[^\"\\])*)\"', suffixes_match.group(1))] if suffixes_match else []

    special_keys_match = re.search(r"\+ \(NSArray \*\)specialKeys\s*\{([\s\S]*?)\}", impl_text)
    special_keys = [objc_string(value) for value in re.findall(r'@\"((?:\\.|[^\"\\])*)\"', special_keys_match.group(1))] if special_keys_match else []

    description_method = extract_method_block(impl_text, r"\+ \(NSString \*\)descriptionForSpecialKey:\(NSString \*\)specialKey")
    descriptions = {
        objc_string(key): objc_string(value)
        for key, value in re.findall(r'@\"((?:\\.|[^\"\\])*)\"\s*:\s*@\"((?:\\.|[^\"\\])*)\"', description_method)
    }

    spell_from_item = extract_method_block(impl_text, r"- \(Spell\*\)spellFromItem")
    special_spell_rules = []
    for key_match in re.finditer(r'if \(\[self\.specialKey isEqualToString:@\"((?:\\.|[^\"\\])*)\"\]\)\s*\{([\s\S]*?)\n\s*\}', spell_from_item):
        special_key = objc_string(key_match.group(1))
        block = key_match.group(2)
        spell_init = re.search(
            r"\[\[\[(\w+) alloc\] initWithTitle:@\"((?:\\.|[^\"\\])*)\" healAmnt:(.*?) energyCost:(.*?) castTime:(.*?) andCooldown:(.*?)\]",
            block,
        )
        rule = {"specialKey": special_key}
        if spell_init:
            class_name, title, heal_amount, energy_cost, cast_time, cooldown = spell_init.groups()
            rule["spell"] = {
                "className": class_name,
                "title": objc_string(title),
                "healAmount": number_or_expression(heal_amount),
                "energyCost": number_or_expression(energy_cost),
                "castTime": number_or_expression(cast_time),
                "cooldown": number_or_expression(cooldown),
            }

        effect_match = re.search(
            r"(\w+)\s+\*(\w+)\s*=\s*\[\[\[(\w+) alloc\] initWithDuration:(.*?) andEffectType:(\w+)\] autorelease\];",
            block,
        )
        if effect_match:
            _name, effect = parse_effect_initializer(effect_match, block)
            rule["appliedEffect"] = effect
        special_spell_rules.append(rule)

    sale_price_method = extract_method_block(impl_text, r"- \(NSInteger\)salePrice")
    sale_expression_match = re.search(r"return\s+([^;]+);", sale_price_method)
    sale_expression = sale_expression_match.group(1).replace("self.", "") if sale_expression_match else None

    return {
        "slotTypes": [
            {"id": entry["token"].replace("SlotType", "").lower(), "enum": entry["token"], "value": entry["value"]}
            for entry in slot_enum
            if entry["token"] != "SlotTypeMaximum"
        ],
        "statTypes": [
            {
                "id": entry["token"].replace("StatType", "").lower(),
                "enum": entry["token"],
                "value": entry["value"],
                "atom": stat_atoms_by_type.get(entry["token"].replace("StatType", "").lower()),
            }
            for entry in stat_enum
            if entry["token"] != "StatTypeMaximum"
        ],
        "rarities": [
            {"id": entry["token"].replace("ItemRarity", "").lower(), "enum": entry["token"], "value": entry["value"]}
            for entry in rarity_enum
        ],
        "proceduralGenerationRules": {
            "slotModifiers": slot_modifier_by_type,
            "namePools": {
                "prefixesBySlot": slot_prefixes_by_type,
                "suffixes": suffixes,
            },
            "weaponSpecials": {
                "minimumQualityForSpecialKey": 4,
                "candidateSpecialKeys": special_keys,
            },
            "salePrice": {
                "expression": sale_expression,
            },
        },
        "specialKeyDetails": [
            {
                "specialKey": key,
                "description": descriptions.get(key),
                "spellRule": next((rule for rule in special_spell_rules if rule["specialKey"] == key), None),
            }
            for key in sorted(set(list(descriptions.keys()) + list(special_keys)))
        ],
    }


def extract_loot_rules():
    encounter_text = read(ROOT / "Healer" / "DataObjects" / "Encounter.m")
    loot_table_text = read(ROOT / "Healer" / "LootTable.m")
    random_item_method = extract_method_block(encounter_text, r"\+ \(EquipmentItem\*\)randomItemForLevelNumber:\(NSInteger\)levelNum difficulty:\(NSInteger\)difficulty rarity:\(ItemRarity\)rarity")
    weights_method = extract_method_block(encounter_text, r"\+ \(NSArray \*\)weightsForDifficulty:\(NSInteger\)difficulty")

    difficulty_weights = {}
    return_arrays = re.findall(r"return\s+@\[(.*?)\];", weights_method)
    fallback_weights = [int(value) for value in re.findall(r"@?(-?\d+)", return_arrays[-1])] if return_arrays else []
    for difficulty in range(1, 6):
        weights = None
        for condition, raw_array in re.findall(r"(?:if|else if)\s*\((.*?)\)\s*\{\s*return\s+@\[(.*?)\];", weights_method, re.DOTALL):
            if safe_eval(condition.replace("difficulty", str(difficulty))):
                weights = [int(value) for value in re.findall(r"@?(-?\d+)", raw_array)]
                break
        difficulty_weights[str(difficulty)] = weights or fallback_weights

    quality_rules = []
    for condition, expression in re.findall(r"(?:if|else if)\s*\((.*?)\)\s*\{\s*ql\s*=\s*([^;]+);", random_item_method, re.DOTALL):
        quality_rules.append(
            {
                "condition": condition.strip(),
                "expression": expression.strip(),
            }
        )

    quality_table = []
    for level in range(1, 22):
        by_difficulty = {}
        for difficulty in range(1, 6):
            quality = None
            for rule in quality_rules:
                condition = rule["condition"].replace("levelNum", str(level)).replace("difficulty", str(difficulty))
                if safe_eval(condition):
                    quality = safe_eval(rule["expression"].replace("difficulty", str(difficulty)))
                    break
            by_difficulty[str(difficulty)] = quality
        quality_table.append({"level": level, "qualityByDifficulty": by_difficulty})

    def parse_boss_drop_method(method_pattern: str):
        method_block = extract_method_block(encounter_text, method_pattern)
        drops = []
        for condition, block in re.findall(r"if \(levelNumber\s*(.*?)\)\s*\{([\s\S]*?)\n\s*\}", method_block):
            levels = [int(value) for value in re.findall(r"(?:^|\|\|)\s*(?:levelNumber\s*)?==\s*(\d+)", condition)]
            for item in parse_equipment_item_initializers(block):
                item["dropLevels"] = sorted(set(levels))
                drops.append(item)
        return drops

    return {
        "rarityRollWeightsByDifficulty": difficulty_weights,
        "rarityOrder": ["uncommon", "rare", "epic", "legendary"],
        "qualityRules": {
            "expressionRules": quality_rules,
            "evaluatedLevelTable": quality_table,
        },
        "selectionBehavior": {
            "lootTableImplementation": "weighted_random_subtraction",
            "selectionSource": "LootTable.randomObject",
            "zeroWeightEntriesNeverDrop": "totalWeights includes only positive sums",
            "fallbackRules": {
                "epic": "if no encounter-specific epic pool, roll random rare-quality item",
                "legendary": "if no encounter-specific legendary pool, fallback to epic pool, else random rare-quality item",
            },
        },
        "encounterSpecificDrops": {
            "epic": parse_boss_drop_method(r"\+ \(NSArray \*\)epicItemsForLevelNumber:\(NSInteger\)levelNumber"),
            "legendary": parse_boss_drop_method(r"\+ \(NSArray \*\)legendaryItemsForLevelNumber:\(NSInteger\)levelNumber"),
        },
        "lootTableSource": {
            "itemsField": bool(re.search(r"@property \(nonatomic, readwrite, retain\) NSArray \*items;", loot_table_text)),
            "weightsField": bool(re.search(r"@property \(nonatomic, readwrite, retain\) NSArray \*weights;", loot_table_text)),
        },
    }


def extract_tips():
    return plistlib.loads((ROOT / "Healer" / "tips.plist").read_bytes())


def generate_payloads():
    default_effects = extract_default_effects()
    ability_factories = extract_ability_factories()
    spells = extract_spells()
    enemies = extract_enemies(default_effects=default_effects, ability_factories=ability_factories)
    abilities = extract_abilities(enemies)
    effects = extract_effects(spells, enemies, default_effects)
    return {
        "encounters.json": dataset_wrapper("encounters", extract_encounters()),
        "spells.json": dataset_wrapper("spells", spells),
        "abilities.json": dataset_wrapper("abilities", abilities),
        "effects.json": dataset_wrapper("effects", effects),
        "enemies.json": dataset_wrapper("enemies", enemies),
        "allies.json": dataset_wrapper("allies", extract_allies()),
        "talents.json": dataset_wrapper("talents", extract_talents()),
        "shop.json": dataset_wrapper("shop", extract_shop(spells)),
        "progression-schema.json": dataset_wrapper("progression-schema", extract_progression_schema()),
        "equipment-schema.json": dataset_wrapper("equipment-schema", extract_equipment_schema()),
        "loot-rules.json": dataset_wrapper("loot-rules", extract_loot_rules()),
        "tips.json": dataset_wrapper("tips", extract_tips()),
    }


def write_payloads(payloads):
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    for file_name, payload in payloads.items():
        (DATA_DIR / file_name).write_text(json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")


def check_payloads(payloads):
    success = True
    for file_name, payload in payloads.items():
        expected = json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
        target = DATA_DIR / file_name
        current = target.read_text(encoding="utf-8") if target.exists() else ""
        if current != expected:
            success = False
            sys.stderr.write(f"Mismatch for {file_name}\n")
            diff = difflib.unified_diff(
                current.splitlines(True),
                expected.splitlines(True),
                fromfile=str(target),
                tofile=f"{target} (expected)",
            )
            sys.stderr.writelines(diff)
    return success


def main():
    parser = argparse.ArgumentParser(description="Extract phase-1 web port data from the Objective-C source.")
    parser.add_argument("--check", action="store_true", help="Validate committed JSON instead of rewriting it.")
    args = parser.parse_args()

    payloads = generate_payloads()
    if args.check:
        if not check_payloads(payloads):
            return 1
        return 0
    write_payloads(payloads)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
