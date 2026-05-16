function clampToZero(value) {
    return value > 0 ? value : 0;
}
function createCombatSpellSnapshot(spell, castTimeAdjustment, cooldownAdjustment) {
    const baseCastTime = spell.castTime ?? null;
    const baseCooldown = spell.cooldown ?? null;
    return {
        ...spell,
        baseCastTime,
        baseCooldown,
        energyCost: spell.energyCost,
        castTime: baseCastTime === null ? null : baseCastTime * castTimeAdjustment,
        cooldown: baseCooldown === null ? null : baseCooldown * cooldownAdjustment,
        cooldownRemaining: 0,
    };
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
        warnings: state.warnings.slice(),
    };
}
function getSpell(state, spellId) {
    return state.player.activeSpells.find((spell) => spell.id === spellId);
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
function completeCast(state, casting, at) {
    const spell = getSpell(state, casting.spellId);
    if (!spell) {
        state.player.casting = null;
        return {
            type: "player_cast_rejected",
            at,
            spellId: casting.spellId,
            targetIds: casting.targetIds,
            reason: "unknown_spell",
        };
    }
    spendEnergy(state.player, casting.committedEnergyCost);
    applySpellCooldown(spell);
    state.player.casting = null;
    return {
        type: "player_cast_completed",
        at,
        spellId: casting.spellId,
        targetIds: casting.targetIds,
    };
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
    return next;
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
            castTimeAdjustment,
            cooldownAdjustment,
            activeSpells: snapshot.player.activeSpells.map((spell) => (createCombatSpellSnapshot(spell, castTimeAdjustment, cooldownAdjustment))),
            casting: null,
        },
        allies: snapshot.allies.map((ally) => ({ ...ally })),
        enemies: snapshot.enemies.map((enemy) => ({ ...enemy })),
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
        events: [completeCast(next, {
                spellId: spell.id,
                startedAt: next.time,
                totalCastTime: 0,
                remainingCastTime: 0,
                committedEnergyCost: spell.energyCost,
                targetIds,
            }, next.time)],
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
        const casting = next.player.casting;
        if (!casting || casting.remainingCastTime > remaining) {
            next = advanceClock(next, remaining);
            remaining = 0;
            continue;
        }
        const segment = casting.remainingCastTime;
        next = advanceClock(next, segment);
        remaining -= segment;
        events.push(completeCast(next, casting, next.time));
    }
    return {
        state: next,
        events,
    };
}
//# sourceMappingURL=combat.js.map