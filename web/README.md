# Healer web rules engine

This workspace contains the Phase 2 browser-port rules-engine slices plus a flow-complete Phase 3 browser shell: deterministic encounter bootstrap state, combat-runtime spell timing/cooldown, player-healing resolution, ally/enemy combat progression, encounter result transitions, postbattle reward/progression resolution, positive spell-effect lifecycle state, and browser pages for splash, main menu, world map, prebattle, gameplay, postbattle, academy, armory, talents, and settings assembled from canonical `web/data/*.json` payloads.

## Commands

- `npm run build`
- `npm test`

To preview the browser shell locally, serve the `web/` directory with any static file server and open `index.html`.
