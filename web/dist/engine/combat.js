const EPSILON = 1e-9;
function clampToZero(value) {
    return value > 0 ? value : 0;
}
function normalizeTimelineValue(value) {
    return Math.round(value * 1_000_000) / 1_000_000;
}
function advanceTimer(value, elapsedSeconds) {
    if (!Number.isFinite(value)) {
        return value;
    }
    return normalizeTimelineValue(clampToZero(value - elapsedSeconds));
}
function recurringTimer(value) {
    return value !== null && value > EPSILON ? normalizeTimelineValue(value) : Number.POSITIVE_INFINITY;
}
function numericValue(value) {
    if (typeof value === "number") {
        return value;
    }
    if (!value) {
        return null;
    }
    return value.value;
}
function copyCasting(casting) {
    if (!casting) {
        return null;
    }
    return {
        ...casting,
        targetIds: casting.targetIds.slice(),
    };
}
function copyEnemyCasting(casting) {
    if (!casting) {
        return null;
    }
    return {
        ...casting,
        targetIds: casting.targetIds.slice(),
    };
}
function copyPlayer(player) {
    return {
        ...player,
        activeSpells: player.activeSpells.map((spell) => ({ ...spell })),
        casting: copyCasting(player.casting),
    };
}
function copyEnemy(enemy) {
    return {
        ...enemy,
        abilities: enemy.abilities.map((ability) => ({ ...ability })),
        casting: copyEnemyCasting(enemy.casting),
    };
}
function copyState(state) {
    return {
        ...state,
        replay: { ...state.replay },
        encounter: {
            ...state.encounter,
            recommendedSpellIds: state.encounter.recommendedSpellIds.slice(),
            requiredSpellIds: state.encounter.requiredSpellIds.slice(),
        },
        player: copyPlayer(state.player),
        allies: state.allies.map((ally) => ({ ...ally })),
        enemies: state.enemies.map(copyEnemy),
        effects: state.effects.map((effect) => ({ ...effect })),
        result: { ...state.result },
        warnings: state.warnings.slice(),
    };
}
function getSpell(state, spellId) {
    return state.player.activeSpells.find((spell) => spell.id === spellId);
}
function getEnemyAbility(enemy, abilityId) {
    return enemy.abilities.find((ability) => ability.id === abilityId);
}
function getFriendlyTarget(state, targetId) {
    if (targetId === state.player.id) {
        return state.player;
    }
    return state.allies.find((ally) => ally.id === targetId);
}
function getEnemyTarget(state, targetId) {
    return state.enemies.find((enemy) => enemy.id === targetId);
}
function isCombatAlly(target) {
    return "attackTimer" in target;
}
function healthRatio(target) {
    if (!(target.maximumHealth > 0)) {
        return 0;
    }
    return target.health / target.maximumHealth;
}
function sortTargetsByHealth(targets) {
    return targets.slice().sort((left, right) => {
        const ratioDelta = healthRatio(left) - healthRatio(right);
        if (Math.abs(ratioDelta) > EPSILON) {
            return ratioDelta;
        }
        return left.id.localeCompare(right.id);
    });
}
function uniqueTargetIds(targetIds) {
    return Array.from(new Set(targetIds));
}
function livingAllies(state) {
    return state.allies.filter((ally) => ally.health > 0);
}
function livingEnemies(state) {
    return state.enemies.filter((enemy) => (enemy.health ?? 0) > 0);
}
function requiresPrimaryTarget(targeting) {
    return [
        "selected_ally",
        "same_position_as_primary",
        "lowest_health_with_required_primary",
        "2_lowest_health_including_primary_plus_2_random",
        "wanders_between_injured_allies",
    ].includes(targeting ?? "");
}
function resolvePrimaryTarget(state, targetIds) {
    for (const targetId of targetIds) {
        const target = getFriendlyTarget(state, targetId);
        if (target && isCombatAlly(target) && target.health > 0) {
            return target;
        }
    }
    return undefined;
}
function resolveSpellTargets(state, spell, requestedTargetIds) {
    const primaryTarget = resolvePrimaryTarget(state, requestedTargetIds);
    const alliesByHealth = sortTargetsByHealth(livingAllies(state));
    const numericTargetCount = typeof spell.targetCount === "number" ? spell.targetCount : null;
    switch (spell.targeting) {
        case "self":
            return [state.player.id];
        case "raid_wide":
            return alliesByHealth.map((ally) => ally.id);
        case "same_position_as_primary": {
            if (!primaryTarget) {
                return [];
            }
            const samePosition = alliesByHealth.filter((ally) => ally.positioning === primaryTarget.positioning && ally.id !== primaryTarget.id);
            const limit = numericTargetCount ?? samePosition.length + 1;
            return uniqueTargetIds([primaryTarget.id, ...samePosition.map((ally) => ally.id)]).slice(0, limit);
        }
        case "lowest_health_with_required_primary": {
            if (!primaryTarget) {
                return [];
            }
            const limit = Math.max(1, numericTargetCount ?? 1);
            const additionalTargets = alliesByHealth
                .filter((ally) => ally.id !== primaryTarget.id)
                .slice(0, Math.max(0, limit - 1))
                .map((ally) => ally.id);
            return uniqueTargetIds([...additionalTargets, primaryTarget.id]);
        }
        case "2_lowest_health_including_primary_plus_2_random": {
            if (!primaryTarget) {
                return [];
            }
            const limit = Math.max(1, numericTargetCount ?? 4);
            const additionalTargets = alliesByHealth
                .filter((ally) => ally.id !== primaryTarget.id)
                .slice(0, Math.max(0, limit - 1))
                .map((ally) => ally.id);
            return uniqueTargetIds([primaryTarget.id, ...additionalTargets]).slice(0, limit);
        }
        case "wanders_between_injured_allies":
            return primaryTarget ? [primaryTarget.id] : [];
        case "selected_ally":
        default:
            return primaryTarget ? [primaryTarget.id] : [];
    }
}
function spendEnergy(player, amount) {
    if (amount === null) {
        return;
    }
    player.energy = Math.max(0, player.energy - amount);
}
function applySpellCooldown(spell) {
    spell.cooldownRemaining = spell.cooldown ?? 0;
}
function applyHealthDelta(target, amount) {
    const nextHealth = Math.max(0, Math.min(target.maximumHealth, target.health + amount));
    const delta = nextHealth - target.health;
    target.health = nextHealth;
    return delta;
}
function applyEnemyHealthDelta(target, amount) {
    if (target.health === null || target.maximumHealth === null) {
        return 0;
    }
    const nextHealth = Math.max(0, Math.min(target.maximumHealth, target.health + amount));
    const delta = nextHealth - target.health;
    target.health = nextHealth;
    return delta;
}
function adjustedEffectMagnitude(value, healingDoneMultiplier) {
    if (value === null) {
        return null;
    }
    return value * (value > 0 ? healingDoneMultiplier : 1);
}
function createCombatEffectSnapshot(effect, targetId, sourceSpellId, healingDoneMultiplier) {
    const effectId = effect.id ?? effect.title;
    if (!effectId) {
        return null;
    }
    const totalDuration = normalizeTimelineValue(numericValue(effect.duration) ?? 0);
    const totalTicksValue = numericValue(effect.numOfTicks);
    const totalTicks = totalTicksValue === null ? null : Math.max(1, Math.round(totalTicksValue));
    const tickInterval = totalTicks && totalDuration > 0 ? normalizeTimelineValue(totalDuration / totalTicks) : null;
    return {
        effectId,
        title: effect.title ?? effectId,
        className: effect.className,
        effectType: effect.effectType ?? null,
        targetId,
        sourceSpellId,
        totalDuration,
        remainingDuration: totalDuration,
        tickInterval,
        remainingUntilNextTick: tickInterval,
        totalTicks,
        ticksApplied: 0,
        value: adjustedEffectMagnitude(numericValue(effect.value), healingDoneMultiplier),
        currentValuePerTick: adjustedEffectMagnitude(numericValue(effect.valuePerTick), healingDoneMultiplier),
        increasePerTick: numericValue(effect.increasePerTick) ?? 0,
    };
}
function disableEnemy(enemy) {
    enemy.attackTimer = Number.POSITIVE_INFINITY;
    enemy.casting = null;
    for (const ability of enemy.abilities) {
        ability.remainingCooldown = Number.POSITIVE_INFINITY;
    }
}
function disableFriendlyTarget(target) {
    if (isCombatAlly(target)) {
        target.attackTimer = Number.POSITIVE_INFINITY;
        return;
    }
    target.casting = null;
}
function recordFriendlyHealthChange(events, target, amount, at, metadata) {
    if (amount === 0) {
        return;
    }
    events.push({
        type: "health_changed",
        at,
        targetId: target.id,
        amount,
        ...metadata,
    });
    if (target.health <= 0) {
        disableFriendlyTarget(target);
        events.push({
            type: "combatant_defeated",
            at,
            targetId: target.id,
            actorId: metadata.actorId,
            spellId: metadata.spellId,
            abilityId: metadata.abilityId,
        });
    }
}
function recordEnemyHealthChange(events, target, amount, at, actorId) {
    if (amount === 0) {
        return;
    }
    events.push({
        type: "health_changed",
        at,
        actorId,
        targetId: target.id,
        amount,
    });
    if ((target.health ?? 0) <= 0) {
        disableEnemy(target);
        events.push({
            type: "combatant_defeated",
            at,
            actorId,
            targetId: target.id,
        });
    }
}
function applySpellResolution(state, spell, requestedTargetIds, at) {
    const events = [];
    const resolvedTargetIds = resolveSpellTargets(state, spell, requestedTargetIds);
    if (resolvedTargetIds.length === 0) {
        return events;
    }
    if (spell.healingAmount !== null) {
        const resolvedHealing = Math.round(spell.healingAmount * state.player.healingDoneMultiplier);
        for (const targetId of resolvedTargetIds) {
            const target = getFriendlyTarget(state, targetId);
            if (!target) {
                continue;
            }
            const appliedAmount = applyHealthDelta(target, resolvedHealing);
            recordFriendlyHealthChange(events, target, appliedAmount, at, {
                spellId: spell.id,
            });
        }
    }
    if (spell.appliedEffect) {
        for (const targetId of resolvedTargetIds) {
            const effectSnapshot = createCombatEffectSnapshot(spell.appliedEffect, targetId, spell.id, state.player.healingDoneMultiplier);
            if (!effectSnapshot) {
                continue;
            }
            state.effects.push(effectSnapshot);
            events.push({
                type: "effect_applied",
                at,
                spellId: spell.id,
                targetId,
                effectId: effectSnapshot.effectId,
            });
        }
    }
    return events;
}
function completeCast(state, casting, at) {
    const spell = getSpell(state, casting.spellId);
    if (!spell) {
        state.player.casting = null;
        return [{
                type: "player_cast_rejected",
                at,
                spellId: casting.spellId,
                targetIds: casting.targetIds,
                reason: "unknown_spell",
            }];
    }
    spendEnergy(state.player, casting.committedEnergyCost);
    applySpellCooldown(spell);
    state.player.casting = null;
    return [
        {
            type: "player_cast_completed",
            at,
            spellId: casting.spellId,
            targetIds: casting.targetIds,
        },
        ...applySpellResolution(state, spell, casting.targetIds, at),
    ];
}
function isRaidWideAbility(ability) {
    return ["BaraghastRoar", "Breath", "Earthquake", "RaidDamage", "RaidDamagePulse"].includes(ability.className);
}
function resolveEnemyTargetIds(state, enemy, ability) {
    const availableTargets = livingAllies(state);
    if (availableTargets.length === 0) {
        return [];
    }
    if (ability && isRaidWideAbility(ability)) {
        return availableTargets.map((target) => target.id);
    }
    const maxTargets = Math.max(1, Math.round(ability?.targetCount ?? enemy.targets ?? 1));
    return availableTargets.slice(0, maxTargets).map((target) => target.id);
}
function applyEnemyDamageToTargets(state, events, sourceEnemy, targetIds, amount, at, abilityId) {
    if (!(amount > 0)) {
        return;
    }
    for (const targetId of targetIds) {
        const target = getFriendlyTarget(state, targetId);
        if (!target) {
            continue;
        }
        const appliedAmount = applyHealthDelta(target, -amount);
        recordFriendlyHealthChange(events, target, appliedAmount, at, {
            abilityId,
            actorId: sourceEnemy.id,
        });
    }
}
function processDueAllyAttacks(state, at) {
    const events = [];
    for (const ally of state.allies) {
        if (ally.health <= 0 || ally.attackTimer > EPSILON) {
            continue;
        }
        ally.attackTimer = recurringTimer(ally.damageFrequency);
        const target = livingEnemies(state)[0];
        if (!target) {
            continue;
        }
        const damage = Math.max(0, Math.round(ally.damageDealt * healthRatio(ally)));
        events.push({
            type: "ally_attack",
            at,
            actorId: ally.id,
            targetId: target.id,
            amount: -damage,
        });
        const appliedAmount = applyEnemyHealthDelta(target, -damage);
        recordEnemyHealthChange(events, target, appliedAmount, at, ally.id);
    }
    return events;
}
function processDueEnemyAutoAttacks(state, at) {
    const events = [];
    for (const enemy of state.enemies) {
        if ((enemy.health ?? 0) <= 0 || enemy.attackTimer > EPSILON) {
            continue;
        }
        enemy.attackTimer = recurringTimer(enemy.attackFrequency);
        const targetIds = resolveEnemyTargetIds(state, enemy);
        if (targetIds.length === 0) {
            continue;
        }
        const damage = Math.max(0, Math.round(enemy.damagePerAttack ?? 0));
        events.push({
            type: "enemy_auto_attack",
            at,
            actorId: enemy.id,
            targetIds,
            amount: -damage,
        });
        applyEnemyDamageToTargets(state, events, enemy, targetIds, damage, at);
    }
    return events;
}
function completeEnemyAbility(state, enemy, casting, at) {
    const ability = getEnemyAbility(enemy, casting.abilityId);
    enemy.casting = null;
    if (!ability) {
        return [];
    }
    ability.remainingCooldown = recurringTimer(ability.cooldown);
    const events = [{
            type: "enemy_ability_completed",
            at,
            actorId: enemy.id,
            abilityId: ability.id,
            targetIds: casting.targetIds,
        }];
    applyEnemyDamageToTargets(state, events, enemy, casting.targetIds, Math.max(0, Math.round(ability.abilityValue ?? 0)), at, ability.id);
    if (ability.appliedEffect) {
        for (const targetId of casting.targetIds) {
            const effectSnapshot = createCombatEffectSnapshot(ability.appliedEffect, targetId, ability.id, 1);
            if (!effectSnapshot) {
                continue;
            }
            state.effects.push(effectSnapshot);
            events.push({
                type: "effect_applied",
                at,
                actorId: enemy.id,
                abilityId: ability.id,
                targetId,
                effectId: effectSnapshot.effectId,
            });
        }
    }
    return events;
}
function processDueEnemyAbilityCompletions(state, at) {
    const events = [];
    for (const enemy of state.enemies) {
        if ((enemy.health ?? 0) <= 0 || !enemy.casting || enemy.casting.remainingCastTime > EPSILON) {
            continue;
        }
        events.push(...completeEnemyAbility(state, enemy, enemy.casting, at));
    }
    return events;
}
function processDueEnemyAbilityStarts(state, at) {
    const events = [];
    for (const enemy of state.enemies) {
        if ((enemy.health ?? 0) <= 0 || enemy.casting) {
            continue;
        }
        const ability = enemy.abilities.find((candidate) => candidate.remainingCooldown <= EPSILON);
        if (!ability) {
            continue;
        }
        const targetIds = resolveEnemyTargetIds(state, enemy, ability);
        ability.remainingCooldown = recurringTimer(ability.cooldown);
        if (targetIds.length === 0) {
            continue;
        }
        if (ability.activationTime > EPSILON) {
            enemy.casting = {
                abilityId: ability.id,
                startedAt: at,
                totalCastTime: ability.activationTime,
                remainingCastTime: ability.activationTime,
                targetIds,
            };
            events.push({
                type: "enemy_ability_started",
                at,
                actorId: enemy.id,
                abilityId: ability.id,
                targetIds,
            });
            continue;
        }
        events.push(...completeEnemyAbility(state, enemy, {
            abilityId: ability.id,
            startedAt: at,
            totalCastTime: 0,
            remainingCastTime: 0,
            targetIds,
        }, at));
    }
    return events;
}
function processDueEffects(state, at) {
    const events = [];
    const activeEffects = [];
    for (const effect of state.effects) {
        const next = { ...effect };
        const dueTick = next.remainingUntilNextTick !== null
            && next.remainingUntilNextTick <= EPSILON
            && (next.totalTicks === null || next.ticksApplied < next.totalTicks);
        if (dueTick) {
            const target = getFriendlyTarget(state, next.targetId);
            if (target && next.currentValuePerTick !== null) {
                const appliedAmount = applyHealthDelta(target, Math.round(next.currentValuePerTick));
                recordFriendlyHealthChange(events, target, appliedAmount, at, {
                    spellId: next.sourceSpellId,
                    effectId: next.effectId,
                });
            }
            next.ticksApplied += 1;
            next.currentValuePerTick = next.currentValuePerTick === null
                ? null
                : next.currentValuePerTick * (1 + next.increasePerTick);
            next.remainingUntilNextTick = next.totalTicks !== null && next.ticksApplied >= next.totalTicks
                ? null
                : next.tickInterval;
        }
        if (next.remainingDuration <= EPSILON) {
            if (next.className === "DelayedHealthEffect" && next.value !== null) {
                const target = getFriendlyTarget(state, next.targetId);
                if (target) {
                    const appliedAmount = applyHealthDelta(target, Math.round(next.value));
                    recordFriendlyHealthChange(events, target, appliedAmount, at, {
                        spellId: next.sourceSpellId,
                        effectId: next.effectId,
                    });
                }
            }
            events.push({
                type: "effect_expired",
                at,
                spellId: next.sourceSpellId,
                targetId: next.targetId,
                effectId: next.effectId,
            });
            continue;
        }
        activeEffects.push(next);
    }
    state.effects = activeEffects;
    return events;
}
function updateCombatResult(state, at) {
    if (state.result.status !== "in_progress") {
        return [];
    }
    let result = null;
    if (livingEnemies(state).length === 0) {
        result = { status: "victory", reason: "all_enemies_defeated", finishedAt: at };
    }
    else if (state.player.health <= 0) {
        result = { status: "defeat", reason: "player_defeated", finishedAt: at };
    }
    else if (livingAllies(state).length === 0) {
        result = { status: "defeat", reason: "all_allies_defeated", finishedAt: at };
    }
    if (!result) {
        return [];
    }
    state.result = result;
    return [{
            type: "encounter_completed",
            at,
            result: result.status,
            resultReason: result.reason,
        }];
}
function advanceClock(state, elapsedSeconds) {
    const next = copyState(state);
    if (!(elapsedSeconds > 0)) {
        return next;
    }
    next.time = normalizeTimelineValue(next.time + elapsedSeconds);
    next.player.energy = Math.min(next.player.maximumEnergy, next.player.energy + (next.player.energyRegenPerSecond * elapsedSeconds));
    for (const spell of next.player.activeSpells) {
        spell.cooldownRemaining = clampToZero(spell.cooldownRemaining - elapsedSeconds);
    }
    if (next.player.casting) {
        next.player.casting.remainingCastTime = clampToZero(next.player.casting.remainingCastTime - elapsedSeconds);
    }
    for (const ally of next.allies) {
        ally.attackTimer = advanceTimer(ally.attackTimer, elapsedSeconds);
    }
    for (const enemy of next.enemies) {
        enemy.attackTimer = advanceTimer(enemy.attackTimer, elapsedSeconds);
        for (const ability of enemy.abilities) {
            ability.remainingCooldown = advanceTimer(ability.remainingCooldown, elapsedSeconds);
        }
        if (enemy.casting) {
            enemy.casting.remainingCastTime = clampToZero(enemy.casting.remainingCastTime - elapsedSeconds);
        }
    }
    next.effects = next.effects.map((effect) => ({
        ...effect,
        remainingDuration: normalizeTimelineValue(clampToZero(effect.remainingDuration - elapsedSeconds)),
        remainingUntilNextTick: effect.remainingUntilNextTick === null
            ? null
            : normalizeTimelineValue(clampToZero(effect.remainingUntilNextTick - elapsedSeconds)),
    }));
    return next;
}
function nextTimelineStep(state, remaining) {
    let step = remaining;
    if (state.player.casting) {
        step = Math.min(step, state.player.casting.remainingCastTime);
    }
    for (const ally of state.allies) {
        if (Number.isFinite(ally.attackTimer)) {
            step = Math.min(step, ally.attackTimer);
        }
    }
    for (const enemy of state.enemies) {
        if (Number.isFinite(enemy.attackTimer)) {
            step = Math.min(step, enemy.attackTimer);
        }
        if (enemy.casting) {
            step = Math.min(step, enemy.casting.remainingCastTime);
        }
        for (const ability of enemy.abilities) {
            if (Number.isFinite(ability.remainingCooldown)) {
                step = Math.min(step, ability.remainingCooldown);
            }
        }
    }
    for (const effect of state.effects) {
        step = Math.min(step, effect.remainingDuration);
        if (effect.remainingUntilNextTick !== null) {
            step = Math.min(step, effect.remainingUntilNextTick);
        }
    }
    return step;
}
export function createCombatState(snapshot) {
    const castTimeAdjustment = snapshot.player.castTimeAdjustment;
    const cooldownAdjustment = snapshot.player.cooldownAdjustment;
    return {
        schemaVersion: 1,
        replay: { ...snapshot.replay },
        encounter: {
            ...snapshot.encounter,
            recommendedSpellIds: snapshot.encounter.recommendedSpellIds.slice(),
            requiredSpellIds: snapshot.encounter.requiredSpellIds.slice(),
        },
        time: 0,
        player: {
            id: snapshot.player.id,
            title: snapshot.player.title,
            name: snapshot.player.name,
            health: snapshot.player.health,
            maximumHealth: snapshot.player.maximumHealth,
            energy: snapshot.player.energy,
            maximumEnergy: snapshot.player.maximumEnergy,
            energyRegenPerSecond: snapshot.player.energyRegenPerSecond,
            healingDoneMultiplier: snapshot.player.healingDoneMultiplier,
            castTimeAdjustment,
            cooldownAdjustment,
            activeSpells: snapshot.player.activeSpells.map((spell) => ({
                ...spell,
                baseCastTime: spell.castTime ?? null,
                baseCooldown: spell.cooldown ?? null,
                castTime: spell.castTime === null ? null : spell.castTime * castTimeAdjustment,
                cooldown: spell.cooldown === null ? null : spell.cooldown * cooldownAdjustment,
                cooldownRemaining: 0,
            })),
            casting: null,
        },
        allies: snapshot.allies.map((ally) => ({
            ...ally,
            attackTimer: recurringTimer(ally.damageFrequency),
        })),
        enemies: snapshot.enemies.map((enemy) => ({
            ...enemy,
            attackTimer: recurringTimer(enemy.attackFrequency),
            abilities: enemy.abilities.map((ability) => ({
                ...ability,
                remainingCooldown: recurringTimer(ability.cooldown),
            })),
            casting: null,
        })),
        effects: [],
        result: {
            status: "in_progress",
            reason: null,
            finishedAt: null,
        },
        warnings: snapshot.warnings.slice(),
    };
}
export function beginPlayerCast(state, request) {
    const next = copyState(state);
    const targetIds = request.targetIds?.slice() ?? [];
    const spell = getSpell(next, request.spellId);
    if (next.result.status !== "in_progress") {
        return {
            state: next,
            events: [{
                    type: "player_cast_rejected",
                    at: next.time,
                    spellId: request.spellId,
                    targetIds,
                    reason: "encounter_resolved",
                }],
        };
    }
    if (!spell) {
        return {
            state: next,
            events: [{
                    type: "player_cast_rejected",
                    at: next.time,
                    spellId: request.spellId,
                    targetIds,
                    reason: "unknown_spell",
                }],
        };
    }
    if (next.player.casting) {
        return {
            state: next,
            events: [{
                    type: "player_cast_rejected",
                    at: next.time,
                    spellId: request.spellId,
                    targetIds,
                    reason: "already_casting",
                }],
        };
    }
    if (spell.cooldownRemaining > 0) {
        return {
            state: next,
            events: [{
                    type: "player_cast_rejected",
                    at: next.time,
                    spellId: request.spellId,
                    targetIds,
                    reason: "spell_on_cooldown",
                }],
        };
    }
    if (spell.energyCost !== null && next.player.energy < spell.energyCost) {
        return {
            state: next,
            events: [{
                    type: "player_cast_rejected",
                    at: next.time,
                    spellId: request.spellId,
                    targetIds,
                    reason: "not_enough_energy",
                }],
        };
    }
    if (requiresPrimaryTarget(spell.targeting) && !resolvePrimaryTarget(next, targetIds)) {
        return {
            state: next,
            events: [{
                    type: "player_cast_rejected",
                    at: next.time,
                    spellId: request.spellId,
                    targetIds,
                    reason: "invalid_target",
                }],
        };
    }
    if ((spell.castTime ?? 0) > 0) {
        next.player.casting = {
            spellId: spell.id,
            startedAt: next.time,
            totalCastTime: spell.castTime ?? 0,
            remainingCastTime: spell.castTime ?? 0,
            committedEnergyCost: spell.energyCost,
            targetIds,
        };
        return {
            state: next,
            events: [{
                    type: "player_cast_started",
                    at: next.time,
                    spellId: spell.id,
                    targetIds,
                }],
        };
    }
    return {
        state: next,
        events: completeCast(next, {
            spellId: spell.id,
            startedAt: next.time,
            totalCastTime: 0,
            remainingCastTime: 0,
            committedEnergyCost: spell.energyCost,
            targetIds,
        }, next.time),
    };
}
export function advanceCombatState(state, elapsedSeconds) {
    if (!(elapsedSeconds > 0) || state.result.status !== "in_progress") {
        return {
            state: copyState(state),
            events: [],
        };
    }
    const events = [];
    let remaining = elapsedSeconds;
    let next = copyState(state);
    while (remaining > 0 && next.result.status === "in_progress") {
        const segment = nextTimelineStep(next, remaining);
        if (segment > 0) {
            next = advanceClock(next, segment);
            remaining -= segment;
        }
        let emitted = false;
        if (next.player.casting && next.player.casting.remainingCastTime <= EPSILON) {
            const casting = next.player.casting;
            events.push(...completeCast(next, casting, next.time));
            emitted = true;
        }
        const enemyAbilityCompletionEvents = processDueEnemyAbilityCompletions(next, next.time);
        if (enemyAbilityCompletionEvents.length > 0) {
            events.push(...enemyAbilityCompletionEvents);
            emitted = true;
        }
        let resultEvents = updateCombatResult(next, next.time);
        if (resultEvents.length > 0) {
            events.push(...resultEvents);
            break;
        }
        const allyAttackEvents = processDueAllyAttacks(next, next.time);
        if (allyAttackEvents.length > 0) {
            events.push(...allyAttackEvents);
            emitted = true;
        }
        resultEvents = updateCombatResult(next, next.time);
        if (resultEvents.length > 0) {
            events.push(...resultEvents);
            break;
        }
        const enemyAutoAttackEvents = processDueEnemyAutoAttacks(next, next.time);
        if (enemyAutoAttackEvents.length > 0) {
            events.push(...enemyAutoAttackEvents);
            emitted = true;
        }
        resultEvents = updateCombatResult(next, next.time);
        if (resultEvents.length > 0) {
            events.push(...resultEvents);
            break;
        }
        const enemyAbilityStartEvents = processDueEnemyAbilityStarts(next, next.time);
        if (enemyAbilityStartEvents.length > 0) {
            events.push(...enemyAbilityStartEvents);
            emitted = true;
        }
        const effectEvents = processDueEffects(next, next.time);
        if (effectEvents.length > 0) {
            events.push(...effectEvents);
            emitted = true;
        }
        resultEvents = updateCombatResult(next, next.time);
        if (resultEvents.length > 0) {
            events.push(...resultEvents);
            break;
        }
        if (segment <= EPSILON && !emitted) {
            break;
        }
    }
    return {
        state: next,
        events,
    };
}
//# sourceMappingURL=combat.js.map