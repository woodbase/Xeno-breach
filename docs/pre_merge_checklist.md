# Pre-merge checklist

- [ ] Use Godot 4.2+; run smoke tests headless if available: `godot4 --headless --path . --run-tests` (or open the project and run `tests/*.gd` scripts on a dummy root).
- [ ] Launch `scenes/ui/main_menu.tscn`, start a run, and verify wave banners, between-wave summaries, and game-over buttons respond.
- [ ] Enable `debug_telemetry_enabled` on the level scene when tuning; confirm run id/seed are printed with wave metrics.
- [ ] Spot-check spawn safety by kiting enemies during a wave; ensure spawns respect the distance buffer from the player.
