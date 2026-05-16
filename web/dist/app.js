/// <reference lib="dom" />
/// <reference lib="dom.iterable" />
import { createGameRegistry } from "./engine/registry.js";
import { advanceCombatState, beginPlayerCast, createCombatState } from "./engine/combat.js";
import { resolveEncounterOutcome } from "./engine/resolution.js";
import { applySelectedSpellIds, applyEncounterResolutionToProfile, createDefaultBrowserShellProfile, createEncounterProgressionInput, createPrebattleViewModel, sanitizeBrowserShellProfile, createWorldMapViewModel, highestUnlockedEncounterLevel, maximumStandardSpellSlots, normalizeSelectedSpellIds, } from "./browser-shell.js";
const SHELL_STORAGE_KEY = "healer.web.browser-shell.v1";
const AUTOPLAY_STEP_SECONDS = 0.25;
const AUTOPLAY_MAX_STEPS = 2400;
const EVENT_LOG_LIMIT = 24;
const EVENT_LOG_STORAGE_LIMIT = 256;
const NUMBER_FORMATTER = new Intl.NumberFormat("en-US");
async function loadPayload(path) {
    const response = await fetch(path);
    if (!response.ok) {
        throw new Error(`Failed to load '${path}' (${response.status}).`);
    }
    const body = await response.json();
    return body.payload;
}
async function loadRegistry() {
    const input = {
        encounters: await loadPayload("./data/encounters.json"),
        allies: await loadPayload("./data/allies.json"),
        enemies: await loadPayload("./data/enemies.json"),
        spells: await loadPayload("./data/spells.json"),
        shop: await loadPayload("./data/shop.json"),
        lootRules: await loadPayload("./data/loot-rules.json"),
        equipmentSchema: await loadPayload("./data/equipment-schema.json"),
        progression: await loadPayload("./data/progression-schema.json"),
    };
    return createGameRegistry(input);
}
function loadProfile() {
    const fallback = createDefaultBrowserShellProfile();
    const raw = window.localStorage.getItem(SHELL_STORAGE_KEY);
    if (!raw) {
        return fallback;
    }
    try {
        return sanitizeBrowserShellProfile(JSON.parse(raw), fallback);
    }
    catch {
        return fallback;
    }
}
function saveProfile(profile) {
    window.localStorage.setItem(SHELL_STORAGE_KEY, JSON.stringify(profile));
}
function resetProfile(state) {
    state.profile = createDefaultBrowserShellProfile();
    state.selectedLevel = null;
    state.gameplay = null;
    state.notice = "Profile reset to default browser-shell values.";
    saveProfile(state.profile);
}
function element(tagName, className, text) {
    const node = document.createElement(tagName);
    if (className) {
        node.className = className;
    }
    if (typeof text === "string") {
        node.textContent = text;
    }
    return node;
}
function actionButton(label, onClick, options) {
    const button = element("button", options?.accent ? "button button--accent" : "button", label);
    button.type = "button";
    button.disabled = options?.disabled ?? false;
    button.addEventListener("click", onClick);
    return button;
}
function createMetric(label, value) {
    const wrapper = element("div", "metric");
    wrapper.append(element("dt", "metric__label", label));
    wrapper.append(element("dd", "metric__value", value));
    return wrapper;
}
function formatNumber(value) {
    return NUMBER_FORMATTER.format(value);
}
function appendRecentEvents(eventLog, events) {
    if (events.length === 0) {
        return;
    }
    eventLog.push(...events);
    if (eventLog.length > EVENT_LOG_STORAGE_LIMIT) {
        eventLog.splice(0, eventLog.length - EVENT_LOG_STORAGE_LIMIT);
    }
}
function lowestHealthAllyId(state) {
    const candidates = state.allies
        .filter((ally) => ally.health > 0 && ally.maximumHealth > 0)
        .sort((left, right) => (left.health / left.maximumHealth) - (right.health / right.maximumHealth));
    return candidates[0]?.id ?? null;
}
function healthPercent(health, maximumHealth) {
    if (maximumHealth <= 0) {
        return 0;
    }
    return Math.max(0, Math.min(100, (health / maximumHealth) * 100));
}
function priorityForEffect(event) {
    let priority = 0;
    if (event.tickInterval !== null) {
        priority += 100;
    }
    if (event.currentValuePerTick !== null) {
        priority += 50;
    }
    if (event.effectType === "negative") {
        priority += 40;
    }
    if (event.effectType === "positive") {
        priority += 20;
    }
    priority += Math.max(0, Math.round((event.totalDuration - event.remainingDuration) * 10));
    return priority;
}
function setSelectedSpells(state, appRoot, spellIds) {
    const nextProfile = applySelectedSpellIds(state.registry, state.profile, spellIds);
    state.profile = nextProfile;
    saveProfile(nextProfile);
    state.notice = `Updated prebattle loadout (${nextProfile.selectedSpellIds.length}/${maximumStandardSpellSlots(state.registry, nextProfile)} slots).`;
    render(appRoot, state);
}
function runAutoplayEncounter(state, level) {
    const preview = createPrebattleViewModel(state.registry, state.profile, level);
    let combatState = createCombatState(preview.bootstrap);
    const eventLog = [];
    for (let step = 0; step < AUTOPLAY_MAX_STEPS && combatState.result.status === "in_progress"; step += 1) {
        if (!combatState.player.casting) {
            const targetId = lowestHealthAllyId(combatState);
            for (const spell of combatState.player.activeSpells) {
                if (spell.cooldownRemaining > 0) {
                    continue;
                }
                if (spell.energyCost !== null && combatState.player.energy < spell.energyCost) {
                    continue;
                }
                const castUpdate = beginPlayerCast(combatState, {
                    spellId: spell.id,
                    targetIds: targetId ? [targetId] : [],
                });
                combatState = castUpdate.state;
                appendRecentEvents(eventLog, castUpdate.events);
                if (castUpdate.events.some((event) => event.type !== "player_cast_rejected")) {
                    break;
                }
            }
        }
        const update = advanceCombatState(combatState, AUTOPLAY_STEP_SECONDS);
        combatState = update.state;
        appendRecentEvents(eventLog, update.events);
    }
    if (combatState.result.status === "in_progress") {
        throw new Error("Autoplay did not resolve the encounter within the simulation limit.");
    }
    const resolution = resolveEncounterOutcome(state.registry, combatState, createEncounterProgressionInput(state.profile));
    return {
        preview,
        finalState: combatState,
        eventLog,
        resolution,
    };
}
function render(appRoot, state) {
    appRoot.replaceChildren();
    const shell = element("div", "shell");
    const header = element("header", "shell__header");
    header.append(element("p", "shell__eyebrow", "Healer web migration"));
    header.append(element("h1", "shell__title", "Phase 3 browser shell"));
    header.append(element("p", "shell__subtitle", "A DOM-based scaffold that reuses extracted data, deterministic combat simulation, and progression resolution."));
    shell.append(header);
    if (state.notice) {
        shell.append(element("p", "notice", state.notice));
    }
    const content = element("main", "shell__content");
    switch (state.screen) {
        case "splash":
            renderSplash(content, state, appRoot);
            break;
        case "menu":
            renderMenu(content, state, appRoot);
            break;
        case "map":
            renderWorldMap(content, state, appRoot);
            break;
        case "prebattle":
            renderPrebattle(content, state, appRoot);
            break;
        case "gameplay":
            renderGameplay(content, state, appRoot);
            break;
        case "postbattle":
            renderPostbattle(content, state, appRoot);
            break;
        case "academy":
            renderAcademy(content, state, appRoot);
            break;
        case "armory":
            renderArmory(content, state, appRoot);
            break;
        case "talents":
            renderTalents(content, state, appRoot);
            break;
        case "settings":
            renderSettings(content, state, appRoot);
            break;
    }
    shell.append(content);
    appRoot.append(shell);
}
function renderSplash(content, state, appRoot) {
    const hero = element("section", "hero");
    hero.append(element("p", "hero__kicker", "Splash / landing page"));
    hero.append(element("h2", "hero__title", "Healer"));
    hero.append(element("p", "hero__text", "The native launch scene fades into the start menu. This web slice keeps that flow lightweight and deterministic."));
    hero.append(actionButton("Enter", () => {
        state.screen = "menu";
        state.notice = null;
        render(appRoot, state);
    }, { accent: true }));
    content.append(hero);
}
function renderMenu(content, state, appRoot) {
    const menu = element("section", "panel");
    menu.append(element("p", "panel__eyebrow", "Main menu"));
    menu.append(element("h2", "panel__title", `Welcome, ${state.profile.name}`));
    menu.append(element("p", "panel__text", "All native top-level destinations now route to browser pages while Play uses deterministic encounter simulation."));
    const metrics = element("dl", "metrics");
    metrics.append(createMetric("Highest cleared", `Level ${state.profile.highestLevelCompleted}`));
    metrics.append(createMetric("Unlocked now", `Up to level ${highestUnlockedEncounterLevel(state.profile)}`));
    metrics.append(createMetric("Gold", formatNumber(state.profile.gold)));
    metrics.append(createMetric("Selected spells", `${state.profile.selectedSpellIds.length}`));
    menu.append(metrics);
    const actions = element("div", "actions");
    actions.append(actionButton("Play", () => {
        state.screen = "map";
        state.notice = null;
        render(appRoot, state);
    }, { accent: true }));
    actions.append(actionButton("Academy", () => {
        state.screen = "academy";
        state.notice = null;
        render(appRoot, state);
    }));
    actions.append(actionButton("Armory", () => {
        state.screen = "armory";
        state.notice = null;
        render(appRoot, state);
    }));
    actions.append(actionButton("Talents", () => {
        state.screen = "talents";
        state.notice = null;
        render(appRoot, state);
    }));
    actions.append(actionButton("Settings", () => {
        state.screen = "settings";
        state.notice = null;
        render(appRoot, state);
    }));
    menu.append(actions);
    content.append(menu);
}
function renderWorldMap(content, state, appRoot) {
    const mapSection = element("section", "panel");
    mapSection.append(element("p", "panel__eyebrow", "World map"));
    mapSection.append(element("h2", "panel__title", "Campaign route"));
    mapSection.append(element("p", "panel__text", "The native map unlocks levels linearly and scrolls horizontally. This shell keeps that unlock rule with a scrollable encounter rail."));
    const toolbar = element("div", "toolbar");
    toolbar.append(actionButton("Back to menu", () => {
        state.screen = "menu";
        state.notice = null;
        render(appRoot, state);
    }));
    toolbar.append(element("span", "toolbar__hint", `Expansion gate ends after level ${state.registry.progression.contentGate.endFreeEncounterLevel}.`));
    mapSection.append(toolbar);
    const rail = element("div", "map-rail");
    for (const encounter of createWorldMapViewModel(state.registry, state.profile)) {
        const card = element("article", encounter.unlocked ? "encounter-card" : "encounter-card encounter-card--locked");
        card.append(element("p", "encounter-card__level", `Level ${encounter.level}`));
        card.append(element("h3", "encounter-card__title", encounter.title));
        card.append(element("p", "encounter-card__meta", `Boss key: ${encounter.bossKey}`));
        card.append(element("p", "encounter-card__meta", `Background: ${encounter.backgroundKey}`));
        card.append(element("p", "encounter-card__meta", `Reward: ${encounter.rewardGold} gold`));
        card.append(element("p", "encounter-card__meta", `Recommended: ${encounter.recommendedSpellIds.join(", ") || "None"}`));
        card.append(actionButton(encounter.unlocked ? "Open prebattle" : "Locked", () => {
            state.selectedLevel = encounter.level;
            state.screen = "prebattle";
            state.notice = null;
            render(appRoot, state);
        }, { disabled: !encounter.unlocked, accent: encounter.unlocked }));
        rail.append(card);
    }
    mapSection.append(rail);
    content.append(mapSection);
}
function renderPrebattle(content, state, appRoot) {
    const level = state.selectedLevel ?? 1;
    const preview = createPrebattleViewModel(state.registry, state.profile, level);
    const section = element("section", "panel");
    section.append(element("p", "panel__eyebrow", "Prebattle"));
    section.append(element("h2", "panel__title", preview.bootstrap.encounter.title));
    section.append(element("p", "panel__text", preview.bootstrap.encounter.info));
    const toolbar = element("div", "toolbar");
    toolbar.append(actionButton("Back to map", () => {
        state.screen = "map";
        state.notice = null;
        render(appRoot, state);
    }));
    toolbar.append(actionButton("Start battle", () => {
        try {
            const gameplay = runAutoplayEncounter(state, level);
            state.gameplay = gameplay;
            state.profile = applyEncounterResolutionToProfile(state.profile, gameplay.resolution);
            saveProfile(state.profile);
            state.notice = gameplay.resolution.result.status === "victory"
                ? `Victory at level ${level}. Rewards and progression have been applied.`
                : `Defeat at level ${level}. Failure count has been recorded.`;
            state.screen = "gameplay";
        }
        catch (error) {
            state.notice = `Could not simulate encounter: ${error instanceof Error ? error.message : String(error)}`;
        }
        render(appRoot, state);
    }, { accent: true }));
    section.append(toolbar);
    const grid = element("div", "detail-grid");
    const encounterPanel = element("article", "detail-card");
    encounterPanel.append(element("h3", "detail-card__title", "Encounter"));
    encounterPanel.append(element("p", "detail-card__text", `Difficulty ${preview.bootstrap.encounter.difficulty} • Replay seed ${preview.bootstrap.replay.seed}`));
    encounterPanel.append(element("p", "detail-card__text", `Boss key: ${preview.bootstrap.encounter.bossKey}`));
    encounterPanel.append(element("p", "detail-card__text", `Battle track: ${preview.bootstrap.encounter.battleTrackTitle}`));
    encounterPanel.append(element("p", "detail-card__text", `Reward preview: ${preview.bootstrap.rewards.gold} gold`));
    grid.append(encounterPanel);
    const alliesPanel = element("article", "detail-card");
    alliesPanel.append(element("h3", "detail-card__title", "Allies"));
    const allyList = element("ul", "detail-card__list");
    for (const ally of preview.allySummary) {
        allyList.append(element("li", "", `${ally.count}× ${ally.title}`));
    }
    alliesPanel.append(allyList);
    grid.append(alliesPanel);
    const spellsPanel = element("article", "detail-card");
    spellsPanel.append(element("h3", "detail-card__title", "Selected spells"));
    const maxSpellSlots = maximumStandardSpellSlots(state.registry, state.profile);
    const normalizedSelectedSpellIds = normalizeSelectedSpellIds(state.registry, state.profile, state.profile.selectedSpellIds);
    const selectedSpellIdSet = new Set(normalizedSelectedSpellIds);
    spellsPanel.append(element("p", "detail-card__text", `Loadout slots: ${normalizedSelectedSpellIds.length}/${maxSpellSlots}`));
    const spellList = element("ul", "detail-card__list");
    for (const spell of preview.selectedSpells) {
        spellList.append(element("li", "", spell.spellType ? `${spell.title} (${spell.spellType})` : spell.title));
    }
    if (preview.selectedSpells.length === 0) {
        spellList.append(element("li", "", "No selected spells. The bootstrap falls back to recommended/owned spells."));
    }
    spellsPanel.append(spellList);
    spellsPanel.append(element("p", "detail-card__text", `Recommended: ${preview.bootstrap.encounter.recommendedSpellIds.join(", ") || "None"}`));
    if (preview.bootstrap.encounter.requiredSpellIds.length > 0) {
        spellsPanel.append(element("p", "detail-card__text", `Required: ${preview.bootstrap.encounter.requiredSpellIds.join(", ")}`));
    }
    grid.append(spellsPanel);
    const loadoutPanel = element("article", "detail-card");
    loadoutPanel.append(element("h3", "detail-card__title", "Loadout editor"));
    loadoutPanel.append(element("p", "detail-card__text", "Toggle owned spells before battle. Selection is persisted to browser profile state."));
    const loadoutActions = element("div", "actions");
    loadoutActions.append(actionButton("Use recommended", () => {
        const recommendedFirst = [
            ...preview.bootstrap.encounter.requiredSpellIds,
            ...preview.bootstrap.encounter.recommendedSpellIds,
            ...normalizedSelectedSpellIds,
        ];
        setSelectedSpells(state, appRoot, recommendedFirst);
    }));
    loadoutActions.append(actionButton("Clear loadout", () => {
        setSelectedSpells(state, appRoot, []);
    }));
    loadoutPanel.append(loadoutActions);
    const loadoutList = element("ul", "loadout-list");
    for (const spellId of state.profile.ownedSpellIds) {
        const spell = state.registry.spellsById.get(spellId);
        if (!spell) {
            continue;
        }
        const row = element("li", "loadout-row");
        const text = element("div", "loadout-row__text");
        text.append(element("p", "loadout-row__title", spell.title));
        const tags = [
            preview.bootstrap.encounter.requiredSpellIds.includes(spellId) ? "required" : null,
            preview.bootstrap.encounter.recommendedSpellIds.includes(spellId) ? "recommended" : null,
            selectedSpellIdSet.has(spellId) ? "selected" : null,
        ].filter((entry) => entry !== null);
        text.append(element("p", "loadout-row__meta", tags.join(" • ") || "owned"));
        row.append(text);
        row.append(actionButton(selectedSpellIdSet.has(spellId) ? "Remove" : "Add", () => {
            const nextSelection = selectedSpellIdSet.has(spellId)
                ? normalizedSelectedSpellIds.filter((id) => id !== spellId)
                : [...normalizedSelectedSpellIds, spellId];
            setSelectedSpells(state, appRoot, nextSelection);
        }, { accent: !selectedSpellIdSet.has(spellId) }));
        loadoutList.append(row);
    }
    if (loadoutList.childElementCount === 0) {
        loadoutList.append(element("li", "loadout-row", "No owned spells are available in this profile."));
    }
    loadoutPanel.append(loadoutList);
    grid.append(loadoutPanel);
    const enemiesPanel = element("article", "detail-card");
    enemiesPanel.append(element("h3", "detail-card__title", "Enemy roster"));
    const enemyList = element("ul", "detail-card__list");
    for (const enemy of preview.bootstrap.enemies) {
        const health = enemy.maximumHealth === null ? "unknown health" : `${enemy.maximumHealth} hp`;
        enemyList.append(element("li", "", `${enemy.title} — ${health}`));
    }
    enemiesPanel.append(enemyList);
    grid.append(enemiesPanel);
    section.append(grid);
    content.append(section);
}
function renderGameplay(content, state, appRoot) {
    const gameplay = state.gameplay;
    if (!gameplay) {
        state.screen = "map";
        state.notice = "No gameplay summary found. Pick an encounter first.";
        render(appRoot, state);
        return;
    }
    const section = element("section", "panel");
    section.append(element("p", "panel__eyebrow", "Gameplay"));
    section.append(element("h2", "panel__title", `${gameplay.preview.bootstrap.encounter.title} simulation`));
    section.append(element("p", "panel__text", "Combat runs through the deterministic runtime and auto-casts available player spells against the lowest-health ally."));
    const toolbar = element("div", "toolbar");
    toolbar.append(actionButton("Back to map", () => {
        state.screen = "map";
        state.notice = null;
        render(appRoot, state);
    }));
    toolbar.append(actionButton("Continue to postbattle", () => {
        state.screen = "postbattle";
        state.notice = null;
        render(appRoot, state);
    }, { accent: true }));
    section.append(toolbar);
    const metrics = element("dl", "metrics");
    metrics.append(createMetric("Outcome", gameplay.resolution.result.status));
    metrics.append(createMetric("Duration", `${gameplay.resolution.metrics.duration.toFixed(2)}s`));
    metrics.append(createMetric("Score", formatNumber(gameplay.resolution.metrics.score)));
    metrics.append(createMetric("Healing", formatNumber(Math.trunc(gameplay.resolution.metrics.healingDone))));
    metrics.append(createMetric("Damage taken", formatNumber(Math.trunc(gameplay.resolution.metrics.damageTaken))));
    section.append(metrics);
    const hudGrid = element("div", "detail-grid");
    const raidCard = element("article", "detail-card");
    raidCard.append(element("h3", "detail-card__title", "Raid frames"));
    const raidList = element("ul", "raid-frames");
    for (const ally of gameplay.finalState.allies) {
        const allyRow = element("li", "raid-frame");
        allyRow.append(element("p", "raid-frame__name", ally.title));
        allyRow.append(element("p", "raid-frame__value", `${formatNumber(ally.health)} / ${formatNumber(ally.maximumHealth)} HP`));
        const bar = element("div", "raid-frame__bar");
        const fill = element("div", "raid-frame__fill");
        fill.style.width = `${healthPercent(ally.health, ally.maximumHealth).toFixed(2)}%`;
        bar.append(fill);
        allyRow.append(bar);
        const topEffects = gameplay.finalState.effects
            .filter((effect) => effect.targetId === ally.id)
            .sort((left, right) => priorityForEffect(right) - priorityForEffect(left))
            .slice(0, 2);
        const effectText = topEffects.length > 0
            ? topEffects.map((effect) => effect.title).join(", ")
            : "No active effects";
        allyRow.append(element("p", "raid-frame__effects", effectText));
        raidList.append(allyRow);
    }
    raidCard.append(raidList);
    hudGrid.append(raidCard);
    const playerCard = element("article", "detail-card");
    playerCard.append(element("h3", "detail-card__title", "Player status"));
    playerCard.append(element("p", "detail-card__text", `${formatNumber(Math.trunc(gameplay.finalState.player.health))}/${formatNumber(Math.trunc(gameplay.finalState.player.maximumHealth))} HP`));
    playerCard.append(element("p", "detail-card__text", `${formatNumber(Math.trunc(gameplay.finalState.player.energy))}/${formatNumber(Math.trunc(gameplay.finalState.player.maximumEnergy))} Energy`));
    playerCard.append(element("p", "detail-card__text", gameplay.finalState.player.casting
        ? `Casting ${gameplay.finalState.player.casting.spellId} (${gameplay.finalState.player.casting.remainingCastTime.toFixed(2)}s left)`
        : "Not casting"));
    hudGrid.append(playerCard);
    section.append(hudGrid);
    const logCard = element("article", "detail-card");
    logCard.append(element("h3", "detail-card__title", "Recent combat events"));
    const logList = element("ul", "detail-card__list");
    for (const event of gameplay.eventLog.slice(-EVENT_LOG_LIMIT)) {
        const parts = [
            `[${event.at.toFixed(2)}s]`,
            event.type,
            event.spellId ?? event.abilityId ?? event.actorId ?? event.targetId ?? "",
            event.reason ?? event.result ?? "",
        ].filter((part) => part.length > 0);
        logList.append(element("li", "", parts.join(" • ")));
    }
    if (gameplay.eventLog.length === 0) {
        logList.append(element("li", "", "No combat events were emitted."));
    }
    logCard.append(logList);
    section.append(logCard);
    content.append(section);
}
function renderPostbattle(content, state, appRoot) {
    const gameplay = state.gameplay;
    if (!gameplay) {
        state.screen = "map";
        state.notice = "No postbattle data found. Run an encounter first.";
        render(appRoot, state);
        return;
    }
    const { resolution } = gameplay;
    const section = element("section", "panel");
    section.append(element("p", "panel__eyebrow", "Postbattle"));
    section.append(element("h2", "panel__title", `${resolution.encounter.title} results`));
    section.append(element("p", "panel__text", "Rewards and progression are resolved through the deterministic Phase 2 resolution layer."));
    const toolbar = element("div", "toolbar");
    toolbar.append(actionButton("Back to map", () => {
        state.screen = "map";
        state.notice = null;
        render(appRoot, state);
    }));
    toolbar.append(actionButton("Main menu", () => {
        state.screen = "menu";
        state.notice = null;
        render(appRoot, state);
    }, { accent: true }));
    section.append(toolbar);
    const metrics = element("dl", "metrics");
    metrics.append(createMetric("Result", resolution.result.status));
    metrics.append(createMetric("Gold awarded", formatNumber(resolution.rewards.goldAwarded)));
    metrics.append(createMetric("Total gold", formatNumber(resolution.progression.gold)));
    metrics.append(createMetric("Highest cleared", `Level ${resolution.progression.highestLevelCompleted}`));
    metrics.append(createMetric("Inventory", `${resolution.progression.inventoryCount}/${state.registry.progression.progressionRules.maximumInventorySize}`));
    metrics.append(createMetric("Talent rating", formatNumber(resolution.progression.totalRating)));
    section.append(metrics);
    const rewardGrid = element("div", "detail-grid");
    const scoreCard = element("article", "detail-card");
    scoreCard.append(element("h3", "detail-card__title", "Score and rating"));
    scoreCard.append(element("p", "detail-card__text", `Score: ${formatNumber(resolution.metrics.score)} (${resolution.rewards.newBestScore ? "new best" : "not improved"})`));
    scoreCard.append(element("p", "detail-card__text", `Rating: ${resolution.rewards.previousRating} → ${resolution.rewards.updatedRating}`));
    rewardGrid.append(scoreCard);
    const lootCard = element("article", "detail-card");
    lootCard.append(element("h3", "detail-card__title", "Loot"));
    if (resolution.rewards.loot) {
        lootCard.append(element("p", "detail-card__text", `${resolution.rewards.loot.name} (${resolution.rewards.loot.rarity})`));
        lootCard.append(element("p", "detail-card__text", `Quality ${resolution.rewards.loot.quality} • Sale ${resolution.rewards.loot.salePrice}g`));
    }
    else {
        const reason = resolution.rewards.lootBlockedReason ?? "no_drop";
        lootCard.append(element("p", "detail-card__text", `No loot drop (${reason}).`));
    }
    rewardGrid.append(lootCard);
    const unlockCard = element("article", "detail-card");
    unlockCard.append(element("h3", "detail-card__title", "Unlocks"));
    unlockCard.append(element("p", "detail-card__text", `Talents unlocked: ${resolution.progression.talentsUnlocked ? "yes" : "no"}`));
    unlockCard.append(element("p", "detail-card__text", `Unlocked talent tiers: ${resolution.progression.unlockedTalentTiers.join(", ") || "none"}`));
    unlockCard.append(element("p", "detail-card__text", `Multiplayer unlocked: ${resolution.progression.multiplayerUnlocked ? "yes" : "no"}`));
    rewardGrid.append(unlockCard);
    section.append(rewardGrid);
    content.append(section);
}
function renderAcademy(content, state, appRoot) {
    const section = element("section", "panel");
    section.append(element("p", "panel__eyebrow", "Academy / spells"));
    section.append(element("h2", "panel__title", "Known spellbook"));
    section.append(element("p", "panel__text", "This screen summarizes owned spells and current active loadout from the extracted registry."));
    const toolbar = element("div", "toolbar");
    toolbar.append(actionButton("Back to menu", () => {
        state.screen = "menu";
        state.notice = null;
        render(appRoot, state);
    }));
    section.append(toolbar);
    const spellGrid = element("div", "detail-grid");
    const selected = element("article", "detail-card");
    selected.append(element("h3", "detail-card__title", "Selected loadout"));
    const selectedList = element("ul", "detail-card__list");
    for (const spellId of state.profile.selectedSpellIds) {
        const title = state.registry.spellsById.get(spellId)?.title ?? spellId;
        selectedList.append(element("li", "", title));
    }
    selected.append(selectedList);
    spellGrid.append(selected);
    const owned = element("article", "detail-card");
    owned.append(element("h3", "detail-card__title", "Owned spells"));
    const ownedList = element("ul", "detail-card__list");
    for (const spellId of state.profile.ownedSpellIds) {
        const spell = state.registry.spellsById.get(spellId);
        const label = spell?.spellType ? `${spell.title} (${spell.spellType})` : (spell?.title ?? spellId);
        ownedList.append(element("li", "", label));
    }
    owned.append(ownedList);
    spellGrid.append(owned);
    section.append(spellGrid);
    content.append(section);
}
function renderArmory(content, state, appRoot) {
    const section = element("section", "panel");
    section.append(element("p", "panel__eyebrow", "Armory / inventory"));
    section.append(element("h2", "panel__title", "Equipment overview"));
    section.append(element("p", "panel__text", "Inventory and equipped item summaries are sourced from persisted browser profile state."));
    const toolbar = element("div", "toolbar");
    toolbar.append(actionButton("Back to menu", () => {
        state.screen = "menu";
        state.notice = null;
        render(appRoot, state);
    }));
    section.append(toolbar);
    const metrics = element("dl", "metrics");
    metrics.append(createMetric("Inventory items", String(state.profile.inventoryCount)));
    metrics.append(createMetric("Total drops", String(state.profile.totalItemsEarned)));
    metrics.append(createMetric("Equipped items", String(state.profile.equippedItems.length)));
    section.append(metrics);
    const card = element("article", "detail-card");
    card.append(element("h3", "detail-card__title", "Equipped item stats"));
    const list = element("ul", "detail-card__list");
    if (state.profile.equippedItems.length === 0) {
        list.append(element("li", "", "No equipment is currently equipped."));
    }
    for (const [index, item] of state.profile.equippedItems.entries()) {
        const parts = [
            item.id ?? `item-${index + 1}`,
            item.health ? `+${item.health} health` : null,
            item.healing ? `+${item.healing} healing` : null,
            item.regen ? `+${item.regen} regen` : null,
            item.crit ? `+${item.crit} crit` : null,
            item.speed ? `+${item.speed} speed` : null,
            item.spellId ? `spell: ${item.spellId}` : null,
        ].filter((value) => Boolean(value));
        list.append(element("li", "", parts.join(" • ")));
    }
    card.append(list);
    section.append(card);
    content.append(section);
}
function renderTalents(content, state, appRoot) {
    const section = element("section", "panel");
    section.append(element("p", "panel__eyebrow", "Talents"));
    section.append(element("h2", "panel__title", "Tier unlock progress"));
    section.append(element("p", "panel__text", "Talent unlock state is driven from postbattle progression resolution."));
    const toolbar = element("div", "toolbar");
    toolbar.append(actionButton("Back to menu", () => {
        state.screen = "menu";
        state.notice = null;
        render(appRoot, state);
    }));
    section.append(toolbar);
    const metrics = element("dl", "metrics");
    metrics.append(createMetric("Unlocked tiers", state.profile.unlockedTalentTiers.join(", ") || "none"));
    metrics.append(createMetric("Highest cleared", `Level ${state.profile.highestLevelCompleted}`));
    section.append(metrics);
    const listCard = element("article", "detail-card");
    listCard.append(element("h3", "detail-card__title", "Current unlocked tiers"));
    const list = element("ul", "detail-card__list");
    if (state.profile.unlockedTalentTiers.length === 0) {
        list.append(element("li", "", "No talent tiers unlocked yet."));
    }
    for (const tier of state.profile.unlockedTalentTiers) {
        list.append(element("li", "", `Tier ${tier}`));
    }
    listCard.append(list);
    section.append(listCard);
    content.append(section);
}
function renderSettings(content, state, appRoot) {
    const section = element("section", "panel");
    section.append(element("p", "panel__eyebrow", "Settings"));
    section.append(element("h2", "panel__title", "Browser profile controls"));
    section.append(element("p", "panel__text", "Profile values are persisted in localStorage for shell-flow testing."));
    const toolbar = element("div", "toolbar");
    toolbar.append(actionButton("Back to menu", () => {
        state.screen = "menu";
        state.notice = null;
        render(appRoot, state);
    }));
    toolbar.append(actionButton("Reset profile", () => {
        resetProfile(state);
        render(appRoot, state);
    }, { accent: true }));
    section.append(toolbar);
    const nameCard = element("article", "detail-card");
    nameCard.append(element("h3", "detail-card__title", "Display name"));
    nameCard.append(element("p", "detail-card__text", `Current display name: ${state.profile.name}`));
    const renameForm = element("div", "actions");
    const label = element("label", "input-label", "Display name");
    const input = element("input", "input");
    input.value = state.profile.name;
    input.maxLength = 24;
    label.append(input);
    renameForm.append(label);
    renameForm.append(actionButton("Save display name", () => {
        const nextName = input.value.trim();
        if (nextName.length === 0) {
            state.notice = "Name cannot be empty.";
            render(appRoot, state);
            return;
        }
        state.profile = {
            ...state.profile,
            name: nextName,
        };
        saveProfile(state.profile);
        state.notice = `Saved display name as ${nextName}.`;
        render(appRoot, state);
    }));
    nameCard.append(renameForm);
    section.append(nameCard);
    content.append(section);
}
async function main() {
    const appRoot = document.getElementById("app");
    if (!appRoot) {
        throw new Error("Could not find #app mount point.");
    }
    appRoot.replaceChildren(element("p", "loading", "Loading extracted campaign data..."));
    try {
        const registry = await loadRegistry();
        const state = {
            registry,
            profile: loadProfile(),
            screen: "splash",
            selectedLevel: null,
            notice: null,
            gameplay: null,
        };
        saveProfile(state.profile);
        render(appRoot, state);
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        appRoot.replaceChildren(element("p", "notice notice--error", `Failed to start browser shell: ${message}`));
    }
}
void main();
//# sourceMappingURL=app.js.map