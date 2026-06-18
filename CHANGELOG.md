# Changelog

All notable changes to the Drosophila Genetics Lab Simulator are documented
here, phase by phase (see SPECS.md section 24).

## Phase 9 — Advanced genetics

Added depth so Mendelian ratios can fail for explainable reasons.

### Added
- **Epistasis**: `data/epistasis_rules.json` + `PhenotypeEngine._apply_epistasis`
  — rules mask traits (e.g. eye color when the eye fails to develop) or override
  them; `Phenotype.masked` tracks hidden traits and the classifier shows "no-eye".
- **Modifier alleles**: `Allele.target_gene` / `modifier_factor`; the phenotype
  engine applies a pre-pass so suppressor/enhancer alleles scale a target gene's
  effect. New `wing_mod` gene with suppressor (rescues vestigial) and enhancer.
- **Polygenic body size**: three additive `size_a/b/c` loci with large/small
  variants; body size is the sum of small contributions across loci.
- **Temperature-sensitive alleles**: `Allele.is_temperature_sensitive` +
  `ts_active()`; the engine uses the environment temperature so a hidden allele
  (`vg_ts`) only expresses when reared warm.
- **Per-individual variation**: `Fly.roll_seed` (assigned by FlyFactory, saved)
  is the stochastic fallback, so genetically identical siblings differ in
  expressivity/penetrance while staying reproducible.
- 3 advanced challenge scenarios (epistasis, temperature-sensitive, polygenic),
  gated after the intro chain; `FlyFactory.create_multi` for multi-locus founders.
- `data/genes.json` → 16 genes, `data/alleles.json` → 37 alleles.
- `scenes/Phase9Tests.tscn` + `scripts/tests/Phase9Tests.gd` — 13-check suite.

### Definition of Done
- Simple Mendelian ratios can fail for explainable reasons ✓ (epistasis masking,
  lethals, modifiers)
- Environment can reveal hidden effects ✓ (temperature-sensitive allele)
- Complex traits depend on multiple genes ✓ (polygenic body size)
- Player can solve at least 3 advanced challenges ✓

## Phase 8 — Campaign framework

Added structured, goal-driven gameplay.

### Added
- `data/scenarios.json` — 5 scenarios with briefings, tutorials, starting vials,
  prerequisite gating, unlocks, and data-driven objectives.
- `scripts/game/Campaign.gd` (autoload `Campaign`) — loads scenarios, seeds the
  lab (`Lab.new_scenario_lab()`), evaluates objectives against live lab/notebook
  state, tracks completion + unlocks, handles quiz answers, and persists progress.
  Objective types: `phenotype_count`, `vial_uniform_phenotype`,
  `cross_survival_below`, and `quiz`.
- `scenes/CampaignScreen.tscn` + `scripts/ui/CampaignScreen.gd` — scenario list
  with lock/complete markers, briefing, live objective progress, dynamic quiz
  buttons, tutorial popup on start, and Start/Check/Complete actions.
- Wired *New Campaign* (main menu) and a *Campaign* tool (dashboard) to the screen.
- `scenes/Phase8Tests.tscn` + `scripts/tests/Phase8Tests.gd` — 13-check suite.

### Definition of Done
- At least 5 playable scenarios ✓ (chained by unlocks)
- Objectives can be completed ✓ (evaluated live against lab + notebook)
- Unlocks work ✓ (prerequisite gating; later scenarios locked until earlier done)
- Tutorial teaches core mechanics ✓ (per-scenario tutorial popups)

## Phase 7 — Statistics & lab notebook

Made experiments understandable: analysis tools + an automatic experiment log.

### Added
- `scripts/sim/StatisticsEngine.gd` — `summarize`, `phenotype_distribution`
  (varying-dimension classes), and `trait_histogram` over any Array[Fly].
- `scenes/StatisticsScreen.tscn` + `scripts/ui/StatisticsScreen.gd` — per-vial
  population/survival, phenotype distribution (bar table), and a trait histogram
  with a trait selector.
- Notebook on `Lab`: `notebook` array auto-populated on every `breed` with the
  parents, environment, counts, per-gene expected-vs-observed tables, phenotype/
  genotype distributions, and explanation; serialised in the save file.
  `Lab.export_notebook()` writes `.txt` + `.json` to `user://exports/`.
- `scenes/NotebookScreen.tscn` + `scripts/ui/NotebookScreen.gd` — browse entries,
  read full detail (incl. expected-vs-observed), and export.
- Dashboard Tools row: added "Statistics" and "Notebook".
- `scenes/Phase7Tests.tscn` + `scripts/tests/Phase7Tests.gd` — 14-check suite.

### Definition of Done
- After a cross, notebook records the result ✓ (automatic)
- Statistics screen shows distributions ✓ (phenotype + histograms)
- Player can compare expected vs observed ✓ (notebook tables)
- Explanations are readable ✓

## Phase 6 — Lab dashboard & vial system

Turned the simulator into a lab game space.

### Added
- `scripts/game/Vial.gd` — a container of flies with its own environment and an
  incubator assignment; population/sex/alive helpers; to/from dict.
- `scripts/game/Incubator.gd` — a temperature-controlled box vials sit in.
- `scripts/game/Lab.gd` (autoload `Lab`) — central game state: vials, incubators,
  generation, and operations (`create_vial`, `move_fly`, `archive_vial`,
  `effective_environment`, `breed`) plus JSON save/load. A fresh lab seeds three
  incubators and stock vials of developed founders. Breeding delegates to the
  InheritanceEngine and develops offspring under the vial's incubator temperature.
- Rebuilt `scenes/LabDashboard.tscn` + `scripts/ui/LabDashboard.gd` — vials list,
  selected-vial detail (summary, incubator dropdown, fly list), incubators panel
  with a temperature slider, actions (new/archive/breed/move/inspect), a Tools row
  to the analysis screens, and Save/Load Lab. *Inspect fly* hands the selected fly
  to the Microscope viewer via `Lab.pending_inspect`.
- `VialEnvironment.clone()`. `scenes/Phase6Tests.tscn` +
  `scripts/tests/Phase6Tests.gd` — 17-check headless suite (all passing).

### Definition of Done
- Player can manage multiple vials ✓
- Each vial has environment settings ✓ (vial env + incubator temperature)
- Flies belong to vials ✓ (move between vials)
- Incubator temperature affects development ✓ (25 °C survives, 36 °C lethal)
- Dashboard feels like a lab ✓

## Phase 5 — Inheritance & cross simulator

Crossing two flies to generate offspring, with expected-vs-observed analysis.

### Added
- `scripts/sim/InheritanceEngine.gd` — `cross(mother, father, count, env, seed)`:
  meiosis with per-arm **recombination** (crossover probability from map
  distance), **autosomal** + **sex-linked** inheritance, sex determination
  (mother→X, father→X/Y), optional spontaneous mutation (raised by radiation),
  and per-offspring development. Analyses results into genotype/phenotype
  distributions and per-gene expected-vs-observed ratio tables (autosomal, and
  X-linked split by sex), with per-class survival and deviation explanations.
  Performance safeguard caps offspring at 2000.
- `scripts/sim/CrossResult.gd` — result container (offspring, distributions,
  per-gene analysis, sex/survival counts, explanation).
- `scenes/CrossSimulator.tscn` + `scripts/ui/CrossSimulator.gd` — pick two parent
  presets, 10/100/1000 offspring, and a seed; renders the tables and explanation.
- `FlyFactory.new_offspring()`; `Fly.alive` (set by development, saved/loaded).
- `scenes/Phase5Tests.tscn` + `scripts/tests/Phase5Tests.gd` — 15-check headless
  suite (all passing). Dashboard: added a "Cross Simulator" entry.

### Verified genetics
- Monohybrid 3:1 / genotype 1:2:1 (vg/+ × vg/+); X-linked criss-cross
  (white ♀ × wild ♂ → carrier daughters, white sons); lethal deviation
  (bcd/+ × bcd/+ → ~25% homozygotes conceived, ~0% among adults).

### Definition of Done
- Cross two flies ✓ / generate 10/100/1000 offspring ✓
- Output genotype distribution ✓ / phenotype distribution ✓
- Offspring inherit alleles correctly ✓ (autosomal + sex-linked, verified)
- Random seed is reproducible ✓

## Phase 4 — Development engine

Simulated egg→adult development; the environment now changes outcomes.

### Added
- `scripts/sim/DevelopmentEngine.gd` — `simulate(fly, env, roll_seed)` walks the
  10 stages, derives development-module health from the genome (gated by the same
  dominance + dose logic as the phenotype engine), and at each stage checks
  sensitive modules, temperature-scaled duration, and energy needs. Computes
  viability / developmental-stability / fertility / lifespan, writes them (plus a
  nutrition-based body-size adjustment) onto the phenotype, and records a
  per-stage log + explanation.
- `scripts/sim/DevelopmentResult.gd` — result container (stage logs, outcome,
  scores, explanation; `to_dict`).
- `data/development_stages.json` — 10 stages with durations, energy needs,
  sensitive modules, and named failure outcomes.
- `data/trait_rules.json`: added functional traits `viability_score`,
  `developmental_stability`, `fertility_score`, `lifespan_days` (now 21 traits).
- `scenes/DevelopmentTimeline.tscn` + `scripts/ui/DevelopmentTimeline.gd` — pick
  a subject, adjust temperature / food / crowding, and view the stage-by-stage
  run with failure highlighting and explanation.
- `scenes/Phase4Tests.tscn` + `scripts/tests/Phase4Tests.gd` — 16-check headless
  suite (all passing).
- Made `PhenotypeEngine.dose_factor` public so development reuses the same
  allele-expression gating. Dashboard: added a "Development Timeline" entry.

### Definition of Done
- Fly develops egg→adult ✓
- Severe developmental mutation can fail ✓ (e.g. bicoid → embryonic arrest)
- Failure has explanation ✓ (names the stage, module, and gene)
- Temperature changes stage duration/stress ✓ (hot faster, cold slower, extreme lethal)
- Nutrition affects size/survival ✓ (smaller/less-fertile, or collapse if severe)

## Phase 3 — Procedural fly renderer

Drew the phenotype as a 2D fly using only generated vector shapes (no art assets).

### Added
- `scripts/ui/FlyRenderer.gd` — a `Control` that paints a top-down fly in
  `_draw()`: head, thorax, striped abdomen, two wings, six legs, antennae, eyes,
  bristles, on a microscope-field backdrop. Every feature is driven by a
  phenotype trait, with trait→color mapping for eyes (red↔white) and body
  (yellow↔wild↔ebony), trailing-edge notching from `wing_shape`, leg-like
  antennae as `antenna_shape` drops, and left/right asymmetry from
  `deformity_score`. Repaints on resize.
- `scenes/MicroscopeViewer.tscn` + `scripts/ui/MicroscopeViewer.gd` — pick a fly,
  draw it, and *Recompute* to re-roll expressivity/penetrance on the same genome.
- `data/trait_rules.json`: added `body_size` and `bristle_count` (now 17 traits)
  so body scaling and bristles are phenotype-driven.
- Dashboard: added a "Microscope Viewer" entry.

### Verification
- Rendered each variant to PNG and visually confirmed the Definition of Done:
  white-eyed (white eyes), vestigial (shrunken wings), and yellow vs ebony
  (pale vs near-black body) all look clearly different; no external art used.
  (Verification harness was temporary and removed.)

### Definition of Done
- Phenotype changes are visible ✓
- white-eyed fly looks different ✓ / vestigial-wing fly looks different ✓
- dark/light body flies look different ✓
- No external art required ✓

## Phase 2 — Phenotype engine

Converted genotype into phenotype with dominance, penetrance, expressivity,
trait deltas, and a human-readable explanation log.

### Added
- `scripts/sim/PhenotypeEngine.gd` — static `compute(fly, env, roll_seed)` that:
  starts every trait at its baseline; gates each mutant allele by dominance +
  dose (dominant = 1 copy; recessive = homozygous/hemizygous; semi-dominant /
  additive = dose-proportional); rolls penetrance; scales by expressivity;
  applies and clamps trait deltas; and records a full explanation (summary +
  per-locus genetic reasoning, including hidden-carrier and penetrance-miss cases).
- `scripts/sim/TraitRule.gd` + `data/trait_rules.json` — 15 data-driven traits
  with baselines, hard clamps, and "normal" bands (visible/functional/behavioral).
- `Catalog` now also parses trait rules (`all_traits`, `get_trait_rule`,
  `trait_count`).
- `scenes/PhenotypeViewer.tscn` + `scripts/ui/PhenotypeViewer.gd` — trait readout
  (with abnormal-range flags and text gauges) and explanation log; a *Recompute*
  button re-rolls penetrance/expressivity on the same genome.
- `scenes/Phase2Tests.tscn` + `scripts/tests/Phase2Tests.gd` — 14-check headless
  suite (all passing).
- Dashboard: added a "Phenotype Viewer" entry; status line now shows trait count.

### Reproducibility
- Phenotype rolls use a local RNG seeded from the global seed XOR the genotype
  signature, so the same seed + genotype always reproduces the same phenotype.

### Definition of Done
- Wild-type fly has normal phenotype ✓
- white mutation affects eye color ✓ / vestigial affects wing size ✓
- yellow/ebony affect body color (opposite directions) ✓
- Explanations are generated ✓ (verified to match the spec's example style)
- Same seed gives same phenotype ✓

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
