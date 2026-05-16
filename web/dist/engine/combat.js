const EPSILON = 1e-9;
function clampToZero(value) {
    return value > 0 ? value : 0;
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
function copyPlayer(player) {
    return {
        ...player,
        activeSpells: player.activeSpells.map((spell) => ({ ...spell })),
        casting: copyCasting(player.casting),
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
        enemies: state.enemies.map((enemy) => ({ ...enemy })),
        effects: state.effects.map((effect) => ({ ...effect })),
        warnings: state.warnings.slice(),
    };
}
function getSpell(state, spellId) {
    return state.player.activeSpells.find((spell) => spell.id === spellId);
}
function getHealableTarget(state, targetId) {
    if (targetId === state.player.id) {
        return state.player;
    }
    return state.allies.find((ally) => ally.id === targetId);
}
function isLivingTarget(target) {
    return Boolean(target && target.health > 0);
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
        const target = getHealableTarget(state, targetId);
        if (target && target.id !== state.player.id && target.health > 0) {
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
function adjustedEffectMagnitude(value, healingDoneMultiplier) {
    if (value === null) {
        return null;
    }
    return Math.round(value * (value > 0 ? healingDoneMultiplier : 1));
}
function createCombatEffectSnapshot(effect, targetId, sourceSpellId, healingDoneMultiplier) {
    const effectId = effect.id ?? effect.title;
    if (!effectId) {
        return null;
    }
    const totalDuration = numericValue(effect.duration) ?? 0;
    const totalTicksValue = numericValue(effect.numOfTicks);
    const totalTicks = totalTicksValue === null ? null : Math.max(1, Math.round(totalTicksValue));
    const tickInterval = totalTicks && totalDuration > 0 ? totalDuration / totalTicks : null;
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
function applySpellResolution(state, spell, requestedTargetIds, at) {
    const events = [];
    const resolvedTargetIds = resolveSpellTargets(state, spell, requestedTargetIds);
    if (resolvedTargetIds.length === 0) {
        return events;
    }
    if (spell.healingAmount !== null) {
        const resolvedHealing = Math.round(spell.healingAmount * state.player.healingDoneMultiplier);
        for (const targetId of resolvedTargetIds) {
            const target = getHealableTarget(state, targetId);
            if (!target) {
                continue;
            }
            const appliedAmount = applyHealthDelta(target, resolvedHealing);
            if (appliedAmount !== 0) {
                events.push({
                    type: "health_changed",
                    at,
                    spellId: spell.id,
                    targetId,
                    amount: appliedAmount,
                });
            }
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
function advanceClock(state, elapsedSeconds) {
    const next = copyState(state);
    if (!(elapsedSeconds > 0)) {
        return next;
    }
    next.time += elapsedSeconds;
    next.player.energy = Math.min(next.player.maximumEnergy, next.player.energy + (next.player.energyRegenPerSecond * elapsedSeconds));
    for (const spell of next.player.activeSpells) {
        spell.cooldownRemaining = clampToZero(spell.cooldownRemaining - elapsedSeconds);
    }
    if (next.player.casting) {
        next.player.casting.remainingCastTime = clampToZero(next.player.casting.remainingCastTime - elapsedSeconds);
    }
    next.effects = next.effects.map((effect) => ({
        ...effect,
        remainingDuration: clampToZero(effect.remainingDuration - elapsedSeconds),
        remainingUntilNextTick: effect.remainingUntilNextTick === null
            ? null
            : clampToZero(effect.remainingUntilNextTick - elapsedSeconds),
    }));
    return next;
}
function nextTimelineStep(state, remaining) {
    let step = remaining;
    if (state.player.casting) {
        step = Math.min(step, state.player.casting.remainingCastTime);
    }
    for (const effect of state.effects) {
        step = Math.min(step, effect.remainingDuration);
        if (effect.remainingUntilNextTick !== null) {
            step = Math.min(step, effect.remainingUntilNextTick);
        }
    }
    return step;
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
            const target = getHealableTarget(state, next.targetId);
            if (target && next.currentValuePerTick !== null) {
                const appliedAmount = applyHealthDelta(target, next.currentValuePerTick);
                if (appliedAmount !== 0) {
                    events.push({
                        type: "health_changed",
                        at,
                        spellId: next.sourceSpellId,
                        targetId: next.targetId,
                        effectId: next.effectId,
                        amount: appliedAmount,
                    });
                }
            }
            next.ticksApplied += 1;
            next.currentValuePerTick = next.currentValuePerTick === null
                ? null
                : Math.round(next.currentValuePerTick * (1 + next.increasePerTick));
            next.remainingUntilNextTick = next.totalTicks !== null && next.ticksApplied >= next.totalTicks
                ? null
                : next.tickInterval;
        }
        if (next.remainingDuration <= EPSILON) {
            if (next.className === "DelayedHealthEffect" && next.value !== null) {
                const target = getHealableTarget(state, next.targetId);
                if (target) {
                    const appliedAmount = applyHealthDelta(target, next.value);
                    if (appliedAmount !== 0) {
                        events.push({
                            type: "health_changed",
                            at,
                            spellId: next.sourceSpellId,
                            targetId: next.targetId,
                            effectId: next.effectId,
                            amount: appliedAmount,
                        });
                    }
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
        allies: snapshot.allies.map((ally) => ({ ...ally })),
        enemies: snapshot.enemies.map((enemy) => ({ ...enemy })),
        effects: [],
        warnings: snapshot.warnings.slice(),
    };
}
export function beginPlayerCast(state, request) {
    const next = copyState(state);
    const targetIds = request.targetIds?.slice() ?? [];
    const spell = getSpell(next, request.spellId);
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
    if (!(elapsedSeconds > 0)) {
        return {
            state: copyState(state),
            events: [],
        };
    }
    const events = [];
    let remaining = elapsedSeconds;
    let next = copyState(state);
    while (remaining > 0) {
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
        const effectEvents = processDueEffects(next, next.time);
        if (effectEvents.length > 0) {
            events.push(...effectEvents);
            emitted = true;
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