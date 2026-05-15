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


def parse_string_setters(text: str, variable_name: str):
    result = {}
    for field in list(ABILITY_FIELDS | EFFECT_FIELDS) + ["spriteName", "title", "key", "iconName", "info"]:
        matches = re.findall(
            rf"\[{re.escape(variable_name)} set{field[0].upper()}{field[1:]}:@\"((?:\\.|[^\"\\])*)\"\];",
            text,
        )
        if matches:
            result[field] = objc_string(matches[-1])
    for field in list(ABILITY_FIELDS | EFFECT_FIELDS):
        matches = re.findall(
            rf"{re.escape(variable_name)}\.{field}\s*=\s*@\"((?:\\.|[^\"\\])*)\";",
            text,
        )
        if matches:
            result[field] = objc_string(matches[-1])
    return result


def parse_numeric_setters(text: str, variable_name: str, field_names):
    result = {}
    for field in field_names:
        matches = re.findall(
            rf"\[{re.escape(variable_name)} set{field[0].upper()}{field[1:]}:([^\]]+)\];",
            text,
        )
        if matches:
            result[field] = number_or_expression(matches[-1])
        matches = re.findall(
            rf"{re.escape(variable_name)}\.{field}\s*=\s*([^;]+);",
            text,
        )
        if matches:
            result[field] = number_or_expression(matches[-1])
    return result


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
            info.update(parse_string_setters(block, var_name))
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
                "backgroundKey": background_map.get(level),
                "battleTrackTitle": "sounds/battle2.mp3" if level in battle2_levels else "sounds/battle1.mp3",
            }
        )
    return sorted(encounters, key=lambda entry: entry["level"])


def build_effect_summary(default_block: str, spell_context):
    effect_match = re.search(
        r"(\w+)\s*\*(\w+)\s*=\s*\[\[\[?(\w+) alloc\] initWithDuration:(.*?) andEffectType:(\w+)\];",
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
    effect.update(parse_string_setters(default_block, var_name))
    effect.update(parse_numeric_setters(default_block, var_name, EFFECT_FIELDS - {"title", "spriteName", "effectType"}))
    return effect


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
                "appliedEffect": effect_summary,
            }
        )
    return sorted(spells, key=lambda entry: (entry["classification"], entry["title"]))


def extract_enemies():
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
            if factory_method:
                temp_abilities[variable]["factoryMethod"] = factory_method.strip()
        for variable_name, ability in temp_abilities.items():
            ability.update(parse_string_setters(default_block, variable_name))
            ability.update(parse_numeric_setters(default_block, variable_name, ABILITY_FIELDS - {"key", "title", "iconName", "info", "executionSound", "activationSound", "spriteName"}))
        for added_variable in re.findall(r"\[\w+ addAbility:(\w+)\];", default_block):
            if added_variable in temp_abilities:
                abilities.append(temp_abilities[added_variable])
        record["abilities"] = abilities
        enemies.append(record)
    return sorted(enemies, key=lambda entry: entry.get("title", entry["id"]))


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


def extract_tips():
    return plistlib.loads((ROOT / "Healer" / "tips.plist").read_bytes())


def generate_payloads():
    spells = extract_spells()
    return {
        "encounters.json": dataset_wrapper("encounters", extract_encounters()),
        "spells.json": dataset_wrapper("spells", spells),
        "enemies.json": dataset_wrapper("enemies", extract_enemies()),
        "allies.json": dataset_wrapper("allies", extract_allies()),
        "talents.json": dataset_wrapper("talents", extract_talents()),
        "shop.json": dataset_wrapper("shop", extract_shop(spells)),
        "progression-schema.json": dataset_wrapper("progression-schema", extract_progression_schema()),
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
