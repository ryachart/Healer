# Healer web rules engine

This workspace contains the Phase 2 browser-port rules-engine slices plus an initial Phase 3 browser-shell scaffold: deterministic encounter bootstrap state, combat-runtime spell timing/cooldown, player-healing resolution, ally/enemy combat progression, encounter result transitions, postbattle reward/progression resolution, positive spell-effect lifecycle state, and a browser flow for splash, main menu, world map, and prebattle preview assembled from the canonical `web/data/*.json` payloads.

## Commands

- `npm run build`
- `npm test`

To preview the browser shell locally, serve the `web/` directory with any static file server and open `index.html`.
