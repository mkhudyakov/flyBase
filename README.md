# Drosophila Genetics Lab Simulator

A deep, science-inspired **dry-lab** simulation game about fruit fly genetics —
inheritance, development, mutation, environment, and multi-generation
experiments. You run a virtual genetics lab and work with an abstract,
computational model of *Drosophila melanogaster* genes, alleles, and
developmental modules.

> **Disclaimer.** This is a simplified educational dry-lab simulation inspired by
> Drosophila genetics. It does not simulate the full genome, does not provide
> real gene-editing instructions, and must not be used for real biological or
> medical decisions. All "editing" in the game is abstract and virtual.

Built with **Godot 4.x** and **GDScript**. No C#, no paid assets, no runtime web
APIs, no real genome database.

---

## Current status: Phase 4 — Development engine

Flies now develop egg→adult, and the **environment changes outcomes**. What works:

- Everything from Phases 0–3 (menu, dashboard, services, data model, phenotype
  engine, fly renderer, viewers).
- **DevelopmentEngine** (`scripts/sim/DevelopmentEngine.gd`) walks the 10 stages
  (egg → adult), derives development-module health from the genome, and checks
  each stage's sensitive modules, energy needs, and temperature-scaled duration.
  It produces viability / developmental-stability / fertility / lifespan scores
  plus a full per-stage log and explanation.
- **Named failure outcomes** (embryonic arrest, metabolic collapse, pupal
  lethality, temperature lethality, …): a severe developmental mutant (e.g.
  `bicoid`, `wingless`) can die before adulthood, with the reason explained
  ("axis_patterning critically low … lowered by bcd").
- **Environment effects**: temperature scales stage duration (hot = faster,
  cold = slower) and adds stress; extreme temperature is lethal; low food /
  crowding reduce energy → smaller, less-fertile adults, or collapse if severe.
- **Development Timeline** screen (Dashboard → *Development Timeline*): pick a
  subject, set temperature / food / crowding, and watch the stage-by-stage run.
- Reproducible (same seed + genome + environment → same result); verified by
  `Phase4Tests.tscn` (16 checks).

> Inheritance / crossing two flies arrives in Phase 5.

### Earlier phases recap

- **Phase 3 — renderer**: `FlyRenderer` draws a top-down fly from vector shapes
  (no art assets), every feature phenotype-driven (eye color/size, wing
  size/shape, body color/size, bristles, antennae, asymmetry). See *Microscope
  Viewer*.
- **Phase 2 — phenotype**: `PhenotypeEngine` converts a genome into traits via
  dominance + dose, **penetrance**, and **expressivity**, with a human-readable
  **explanation log**. 21 data-driven traits in `data/trait_rules.json`. Hidden
  carriers, pleiotropy, and X-linked male expression all work.

See [CHANGELOG.md](CHANGELOG.md) for per-phase history and
[CONVENTIONS.md](CONVENTIONS.md) for coding conventions. The full plan lives in
[SPECS.md](SPECS.md) (section 24 is the phase roadmap).

---

## Running on macOS

1. **Install Godot 4.x** (standard build, *not* the .NET/C# build — this project
   uses GDScript only).
   - Download from <https://godotengine.org/download/macos/>, or
   - `brew install --cask godot`
2. **Open the project.**
   - Launch Godot, click **Import**, and select the `project.godot` file in this
     folder. (Or from a terminal: `godot --editor --path /path/to/flyBase`.)
3. **Run it.** Press the ▶ **Run Project** button (or `Cmd+B`). The main menu
   appears.
4. Click **Sandbox** to open the lab dashboard. From there open **Genotype
   Debug** to build flies and inspect genotypes, or use **Test Save / Test
   Load** to exercise the save/load shell.

Save files are written to the per-user Godot data directory:
`~/Library/Application Support/Godot/app_userdata/Drosophila Genetics Lab Simulator/saves/`

### Running the test scene

Phase checks live in headless test scenes. To run the Phase 1 suite from a
terminal:

```
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
# First run after pulling new code registers class_name globals:
"$GODOT" --headless --path . --editor --quit
"$GODOT" --headless --path . res://scenes/Phase1Tests.tscn --quit-after 10
"$GODOT" --headless --path . res://scenes/Phase2Tests.tscn --quit-after 10
"$GODOT" --headless --path . res://scenes/Phase4Tests.tscn --quit-after 10
```

The first command is only needed once after new `class_name` scripts are added
(the editor normally does this for you on open). It prints `PASS`/`FAIL` per
check.

---

## Project structure

```
flyBase/
├── project.godot              # Godot 4 project config + autoload registration
├── icon.svg                   # App icon (abstract fly)
├── README.md
├── CHANGELOG.md
├── CONVENTIONS.md             # Coding conventions
├── SPECS.md                   # Full product specification
├── data/                      # Data-driven content (JSON). See data/README.md
│   ├── genes.json             # 12 genes
│   ├── alleles.json           # 24 alleles
│   ├── trait_rules.json       # 21 traits (baselines + normal ranges)
│   └── development_stages.json # 10 egg→adult stages
├── scenes/                    # Godot scenes (.tscn)
│   ├── MainMenu.tscn
│   ├── LabDashboard.tscn
│   ├── GenotypeDebug.tscn
│   ├── PhenotypeViewer.tscn
│   ├── MicroscopeViewer.tscn
│   ├── DevelopmentTimeline.tscn
│   ├── Phase1Tests.tscn       # headless test scenes
│   ├── Phase2Tests.tscn
│   └── Phase4Tests.tscn
└── scripts/
    ├── autoload/              # Singletons (registered in project.godot)
    │   ├── DataLoader.gd
    │   ├── RandomService.gd
    │   └── SaveLoadService.gd
    ├── sim/                   # Simulation classes (no UI dependencies)
    │   ├── Catalog.gd         # autoload: parses JSON into Gene/Allele/TraitRule
    │   ├── Gene.gd
    │   ├── Allele.gd
    │   ├── TraitRule.gd
    │   ├── Chromosome.gd
    │   ├── Genome.gd
    │   ├── Phenotype.gd
    │   ├── PhenotypeEngine.gd
    │   ├── DevelopmentEngine.gd
    │   ├── DevelopmentResult.gd
    │   ├── VialEnvironment.gd  # "Environment" collides with a Godot built-in
    │   ├── Fly.gd
    │   └── FlyFactory.gd
    ├── tests/
    │   ├── Phase1Tests.gd
    │   ├── Phase2Tests.gd
    │   └── Phase4Tests.gd
    └── ui/                    # UI controllers (kept separate from sim code)
        ├── MainMenu.gd
        ├── LabDashboard.gd
        ├── GenotypeDebug.gd
        ├── PhenotypeViewer.gd
        ├── MicroscopeViewer.gd
        ├── FlyRenderer.gd     # procedural 2D fly (vector shapes, no assets)
        └── DevelopmentTimeline.gd
```

Simulation code lives in `scripts/sim/` separately from UI code, per the
conventions.

---

## Safety boundary

This game never provides real-world biological modification instructions. It does
not implement or describe CRISPR/guide-RNA design, primers, injection or
transformation protocols, reagent lists, gene drives, or any real organism
engineering workflow. All genetics here is an abstract computational model.
