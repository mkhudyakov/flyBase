# Changelog

All notable changes to the Drosophila Genetics Lab Simulator are documented
here, phase by phase (see SPECS.md section 24).

## Phase 1 — Core data model

Implemented the fly/genome/gene/allele/phenotype/environment classes. The
genotype model is data-driven and diploid with correct sex-linkage. No phenotype
computation yet (that is Phase 2).

### Added
- `scripts/sim/Gene.gd`, `Allele.gd` — immutable catalog definitions built from
  JSON via `from_dict`, with safe defaults.
- `scripts/sim/Catalog.gd` (autoload) — parses `genes.json`/`alleles.json` into
  typed objects; lookups by id, by chromosome, and wild-type-allele resolution.
- `scripts/sim/Chromosome.gd` — one physical chromosome copy (gene_id → allele_id).
- `scripts/sim/Genome.gd` — diploid scaffold (two copies per autosome; XX female,
  XY male); `genotype_at`, `is_homozygous`, `is_hemizygous`, allele placement,
  and to/from dict.
- `scripts/sim/Phenotype.gd` — trait/explanation container (computed in Phase 2).
- `scripts/sim/VialEnvironment.gd` — rearing-condition container with standard
  defaults. (Named `VialEnvironment`, not `Environment`, because Godot has a
  built-in `Environment` class that the name would otherwise hide.)
- `scripts/sim/Fly.gd` — ties genome + phenotype + lineage; full save/load dict.
- `scripts/sim/FlyFactory.gd` — `create_wild_type` and `create_mutant`
  (homozygous / heterozygous; hemizygous for male X-linked).
- `data/genes.json` — 12 genes (w, y, e, vg, ey, Antp, wg, N, Ubx, bcd, per, dnc).
- `data/alleles.json` — 24 alleles (a wild-type + a mutant per gene).
- `scenes/GenotypeDebug.tscn` + `scripts/ui/GenotypeDebug.gd` — debug panel to
  build flies and inspect genotype; includes a save/load round-trip test.
- `scenes/Phase1Tests.tscn` + `scripts/tests/Phase1Tests.gd` — 13-check headless
  suite (all passing).
- Registered `Catalog` autoload; added a "Genotype Debug" entry on the dashboard.

### Fixed
- `RandomService.seed_with` forced the RNG `state` to a constant after seeding,
  which made every seed produce the same sequence. Removed; seeding now
  reproduces per-seed sequences correctly (verified by tests 12–13).

### Definition of Done
- Create a wild-type fly ✓ / create a mutant fly ✓
- Inspect genotype in debug panel ✓
- Load gene/allele data from JSON ✓ (12 genes, 24 alleles)
- Save/load one fly ✓ (genome preserved, verified)

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
