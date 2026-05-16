import { createGameRegistry } from "./engine/registry.js";
import type { RegistryInput } from "./engine/types.js";
import {
  createDefaultBrowserShellProfile,
  createPrebattleViewModel,
  createWorldMapViewModel,
  highestUnlockedEncounterLevel,
  type BrowserShellProfile,
} from "./browser-shell.js";

type Screen = "splash" | "menu" | "map" | "prebattle";

interface AppState {
  registry: ReturnType<typeof createGameRegistry>;
  profile: BrowserShellProfile;
  screen: Screen;
  selectedLevel: number | null;
  notice: string | null;
}

const SHELL_STORAGE_KEY = "healer.web.browser-shell.v1";

async function loadPayload<T>(path: string): Promise<T> {
  const response = await fetch(path);
  if (!response.ok) {
    throw new Error(`Failed to load '${path}' (${response.status}).`);
  }
  const body = await response.json() as { payload: T };
  return body.payload;
}

async function loadRegistry() {
  const input: RegistryInput = {
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

function loadProfile(): BrowserShellProfile {
  const fallback = createDefaultBrowserShellProfile();
  const raw = window.localStorage.getItem(SHELL_STORAGE_KEY);
  if (!raw) {
    return fallback;
  }

  try {
    const parsed = JSON.parse(raw) as Partial<BrowserShellProfile>;
    return {
      ...fallback,
      ...parsed,
      selectedSpellIds: Array.isArray(parsed.selectedSpellIds) ? parsed.selectedSpellIds.slice() : fallback.selectedSpellIds,
      lastUsedSpellIds: Array.isArray(parsed.lastUsedSpellIds) ? parsed.lastUsedSpellIds.slice() : fallback.lastUsedSpellIds,
      ownedSpellIds: Array.isArray(parsed.ownedSpellIds) ? parsed.ownedSpellIds.slice() : fallback.ownedSpellIds,
      equippedItems: Array.isArray(parsed.equippedItems) ? parsed.equippedItems.map((item) => ({ ...item })) : fallback.equippedItems,
      difficultyByLevel: typeof parsed.difficultyByLevel === "object" && parsed.difficultyByLevel !== null
        ? Object.fromEntries(Object.entries(parsed.difficultyByLevel).map(([key, value]) => [Number(key), Number(value)]))
        : fallback.difficultyByLevel,
    };
  } catch {
    return fallback;
  }
}

function saveProfile(profile: BrowserShellProfile): void {
  window.localStorage.setItem(SHELL_STORAGE_KEY, JSON.stringify(profile));
}

function element<K extends keyof HTMLElementTagNameMap>(
  tagName: K,
  className?: string,
  text?: string,
): HTMLElementTagNameMap[K] {
  const node = document.createElement(tagName);
  if (className) {
    node.className = className;
  }
  if (typeof text === "string") {
    node.textContent = text;
  }
  return node;
}

function actionButton(label: string, onClick: () => void, options?: { disabled?: boolean; accent?: boolean }): HTMLButtonElement {
  const button = element("button", options?.accent ? "button button--accent" : "button", label);
  button.type = "button";
  button.disabled = options?.disabled ?? false;
  button.addEventListener("click", onClick);
  return button;
}

function createMetric(label: string, value: string): HTMLElement {
  const wrapper = element("div", "metric");
  wrapper.append(element("dt", "metric__label", label));
  wrapper.append(element("dd", "metric__value", value));
  return wrapper;
}

function render(appRoot: HTMLElement, state: AppState): void {
  appRoot.replaceChildren();

  const shell = element("div", "shell");
  const header = element("header", "shell__header");
  header.append(element("p", "shell__eyebrow", "Healer web migration"));
  header.append(element("h1", "shell__title", "Phase 3 browser shell"));
  header.append(element("p", "shell__subtitle", "A DOM-based scaffold that reuses the extracted data and deterministic bootstrap engine."));
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
  }

  shell.append(content);
  appRoot.append(shell);
}

function renderSplash(content: HTMLElement, state: AppState, appRoot: HTMLElement): void {
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

function renderMenu(content: HTMLElement, state: AppState, appRoot: HTMLElement): void {
  const menu = element("section", "panel");
  menu.append(element("p", "panel__eyebrow", "Main menu"));
  menu.append(element("h2", "panel__title", `Welcome, ${state.profile.name}`));
  menu.append(element("p", "panel__text", "The browser shell mirrors the native entry points while only the Play path is wired into the extracted campaign data."));

  const metrics = element("dl", "metrics");
  metrics.append(createMetric("Highest cleared", `Level ${state.profile.highestLevelCompleted}`));
  metrics.append(createMetric("Unlocked now", `Up to level ${highestUnlockedEncounterLevel(state.profile)}`));
  metrics.append(createMetric("Selected spells", `${state.profile.selectedSpellIds.length}`));
  menu.append(metrics);

  const actions = element("div", "actions");
  actions.append(actionButton("Play", () => {
    state.screen = "map";
    state.notice = null;
    render(appRoot, state);
  }, { accent: true }));

  for (const label of ["Academy", "Armory", "Talents", "Settings"]) {
    actions.append(actionButton(label, () => {
      state.notice = `${label} is still pending later Phase 3 browser-flow work.`;
      render(appRoot, state);
    }));
  }

  menu.append(actions);
  content.append(menu);
}

function renderWorldMap(content: HTMLElement, state: AppState, appRoot: HTMLElement): void {
  const mapSection = element("section", "panel");
  mapSection.append(element("p", "panel__eyebrow", "World map"));
  mapSection.append(element("h2", "panel__title", "Campaign route"));
  mapSection.append(element("p", "panel__text", "The native map unlocks levels linearly and scrolls horizontally. This scaffold keeps the same unlock rule with a scrollable encounter rail."));

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
    card.append(actionButton(
      encounter.unlocked ? "Open prebattle" : "Locked",
      () => {
        state.selectedLevel = encounter.level;
        state.screen = "prebattle";
        state.notice = null;
        render(appRoot, state);
      },
      { disabled: !encounter.unlocked, accent: encounter.unlocked },
    ));
    rail.append(card);
  }
  mapSection.append(rail);
  content.append(mapSection);
}

function renderPrebattle(content: HTMLElement, state: AppState, appRoot: HTMLElement): void {
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
    state.notice = "The deterministic combat engine is ready, but the Phase 3 battle HUD and interactive browser combat screen are still the next slice.";
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
  const spellList = element("ul", "detail-card__list");
  for (const spell of preview.selectedSpells) {
    spellList.append(element("li", "", spell.spellType ? `${spell.title} (${spell.spellType})` : spell.title));
  }
  spellsPanel.append(spellList);
  spellsPanel.append(element(
    "p",
    "detail-card__text",
    `Recommended: ${preview.bootstrap.encounter.recommendedSpellIds.join(", ") || "None"}`,
  ));
  if (preview.bootstrap.encounter.requiredSpellIds.length > 0) {
    spellsPanel.append(element(
      "p",
      "detail-card__text",
      `Required: ${preview.bootstrap.encounter.requiredSpellIds.join(", ")}`,
    ));
  }
  grid.append(spellsPanel);

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

async function main(): Promise<void> {
  const appRoot = document.getElementById("app");
  if (!appRoot) {
    throw new Error("Could not find #app mount point.");
  }

  appRoot.replaceChildren(element("p", "loading", "Loading extracted campaign data..."));

  try {
    const registry = await loadRegistry();
    const state: AppState = {
      registry,
      profile: loadProfile(),
      screen: "splash",
      selectedLevel: null,
      notice: null,
    };

    saveProfile(state.profile);
    render(appRoot, state);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    appRoot.replaceChildren(element("p", "notice notice--error", `Failed to start browser shell: ${message}`));
  }
}

void main();
