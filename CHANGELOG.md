# Changelog

All notable changes to the Drosophila Genetics Lab Simulator are documented
here, phase by phase (see SPECS.md section 24).

## Phase 0 — Project foundation

The Godot 4 project skeleton and core architecture. No simulation yet.

### Added
- `project.godot` — Godot 4.x project config, 1280×720 window, autoload
  registration for the three core services, main scene set to the main menu.
- Folder structure: `scenes/`, `scripts/autoload/`, `scripts/ui/`, `data/`.
- `scenes/MainMenu.tscn` + `scripts/ui/MainMenu.gd` — main menu (Continue, New
  Campaign, Sandbox, Challenges, Tutorial Library, Settings, Quit) with the
  required educational disclaimer. Sandbox/Continue open the dashboard;
  unbuilt flows show a "later phase" notice.
- `scenes/LabDashboard.tscn` + `scripts/ui/LabDashboard.gd` — lab dashboard
  placeholder that reports core-service status and exercises save/load.
- `scripts/autoload/DataLoader.gd` — generic, fault-tolerant JSON loader +
  cache for `res://data/`.
- `scripts/autoload/RandomService.gd` — seedable, reproducible RNG with named
  sub-streams.
- `scripts/autoload/SaveLoadService.gd` — JSON save/load shell with versioned
  envelopes, autosave, slot listing/deletion.
- `data/genes.json` — placeholder so the loader can demonstrate reading JSON
  (full catalog comes in Phase 1); `data/README.md`.
- `icon.svg` — abstract fly app icon.
- `README.md` with macOS run instructions; `CONVENTIONS.md` coding conventions.

### Definition of Done
- Project opens in Godot ✓
- Main menu runs ✓
- Dashboard opens ✓
- Data loader can read JSON ✓
- No simulation yet ✓
- README explains how to run on macOS ✓
