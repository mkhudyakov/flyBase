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

## Current status: Phase 11 — Game economy & progression

Constraints and a progression loop turn the sandbox into a game. What works:

- Everything from Phases 0–10 (full simulation, lab, campaign, population sim).
- **Economy** singleton (`scripts/game/Economy.gd`): research points, budget,
  reputation, and publication score, with JSON persistence.
- **Meaningful constraints**: breeding and new vials cost budget; run out and you
  must earn more before continuing.
- **Earning loop**: completing campaign scenarios grants RP/budget/reputation
  (data-driven `reward` per scenario), and **publishing** a notebook experiment
  (Notebook → *Publish selected*) pays out RP + budget + reputation.
- **Equipment unlock tree** (`data/equipment.json`, *Equipment* screen): spend RP
  on upgrades with prerequisite gating, each with a real effect — *carrier
  scanner* reveals hidden genotypes in the vial list (otherwise you only see the
  visible phenotype), *high-throughput crosser* enables 1000-offspring crosses,
  *long-term culture* enables 20-generation runs, *automation* cuts breeding cost.
- The dashboard shows live `$ / RP / Rep / Pubs`. `Phase11Tests.tscn` (18 checks).

> Final phase (12) is polish & productization: settings, audio, accessibility,
> macOS export, balancing.

### Earlier phases recap

- **Phase 10 — population**: `PopulationEngine` runs 10–20 generations with
  truncation selection, bottlenecks, and drift; tracks allele frequencies and a
  line-stability score (*Population* screen).
- **Phase 9 — advanced genetics**: epistasis (gene masking), suppressor/enhancer
  modifiers, polygenic body size, temperature-sensitive alleles, + 3 advanced
  challenges. Per-individual variation via `Fly.roll_seed`.
- **Phase 8 — campaign**: `Campaign` engine + 8 scenarios with prerequisite
  gating, data-driven objectives, quizzes, and tutorial popups (*Campaign* screen).
- **Phase 7 — statistics & notebook**: `StatisticsEngine` distributions +
  histograms (*Statistics* screen); every breed auto-logged to the *Notebook*
  with expected-vs-observed tables, exportable to `user://exports/`.
- **Phase 6 — lab**: `Lab` singleton owns vials + incubators; the dashboard lets
  you breed, move/inspect flies, archive lines, set incubator temperature, and
  Save/Load the lab.
- **Phase 5 — inheritance**: `InheritanceEngine` crosses two flies (autosomal +
  sex-linked, recombination, sex determination) into 10/100/1000 offspring with
  expected-vs-observed ratio tables. Verified 3:1, X-linked criss-cross, lethal
  deviation. See *Cross Simulator*.
- **Phase 4 — development**: `DevelopmentEngine` walks 10 egg→adult stages;
  severe developmental mutants can fail (named outcomes), and temperature /
  nutrition / crowding change duration, size, fertility, and survival. See
  *Development Timeline*.
- **Phase 3 — renderer**: `FlyRenderer` draws a top-down fly from vector shapes
  (no art assets), every feature phenotype-driven. See *Microscope Viewer*.
- **Phase 2 — phenotype**: `PhenotypeEngine` converts a genome into traits via
  dominance + dose, **penetrance**, and **expressivity**, with an **explanation
  log**. 21 data-driven traits. Hidden carriers, pleiotropy, and X-linked male
  expression all work.

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
4. Click **Sandbox** to open the **Lab Dashboard**: manage vials and incubators,
   breed flies, move/inspect them, and open the analysis tools from the Tools
   row (Genome, Phenotype, Microscope, Development, Cross). **Save/Load Lab**
   persists the whole lab.

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
"$GODOT" --headless --path . res://scenes/Phase5Tests.tscn --quit-after 15
"$GODOT" --headless --path . res://scenes/Phase6Tests.tscn --quit-after 15
"$GODOT" --headless --path . res://scenes/Phase7Tests.tscn --quit-after 15
"$GODOT" --headless --path . res://scenes/Phase8Tests.tscn --quit-after 15
"$GODOT" --headless --path . res://scenes/Phase9Tests.tscn --quit-after 15
"$GODOT" --headless --path . res://scenes/Phase10Tests.tscn --quit-after 30
"$GODOT" --headless --path . res://scenes/Phase11Tests.tscn --quit-after 15
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
│   ├── genes.json             # 16 genes
│   ├── alleles.json           # 37 alleles
│   ├── trait_rules.json       # 21 traits (baselines + normal ranges)
│   ├── development_stages.json # 10 egg→adult stages
│   ├── epistasis_rules.json   # gene-masking rules
│   ├── scenarios.json         # 8 campaign scenarios
│   └── equipment.json         # purchasable upgrades
├── scenes/                    # Godot scenes (.tscn)
│   ├── MainMenu.tscn
│   ├── LabDashboard.tscn
│   ├── GenotypeDebug.tscn
│   ├── PhenotypeViewer.tscn
│   ├── MicroscopeViewer.tscn
│   ├── DevelopmentTimeline.tscn
│   ├── CrossSimulator.tscn
│   ├── StatisticsScreen.tscn
│   ├── NotebookScreen.tscn
│   ├── CampaignScreen.tscn
│   ├── PopulationScreen.tscn
│   ├── EquipmentScreen.tscn
│   ├── Phase1Tests.tscn       # headless test scenes
│   ├── Phase2Tests.tscn
│   ├── Phase4Tests.tscn
│   ├── Phase5Tests.tscn
│   ├── Phase6Tests.tscn
│   ├── Phase7Tests.tscn
│   ├── Phase8Tests.tscn
│   ├── Phase9Tests.tscn
│   ├── Phase10Tests.tscn
│   └── Phase11Tests.tscn
└── scripts/
    ├── autoload/              # Singletons (registered in project.godot)
    │   ├── DataLoader.gd
    │   ├── RandomService.gd
    │   └── SaveLoadService.gd
    ├── game/                  # Game-layer state (vials, incubators, lab)
    │   ├── Lab.gd             # autoload: central lab state + operations
    │   ├── Campaign.gd        # autoload: scenarios, objectives, unlocks
    │   ├── Economy.gd         # autoload: budget, RP, reputation, equipment
    │   ├── Vial.gd
    │   └── Incubator.gd
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
    │   ├── InheritanceEngine.gd
    │   ├── CrossResult.gd
    │   ├── StatisticsEngine.gd
    │   ├── PopulationEngine.gd
    │   ├── PopulationResult.gd
    │   ├── VialEnvironment.gd  # "Environment" collides with a Godot built-in
    │   ├── Fly.gd
    │   └── FlyFactory.gd
    ├── tests/
    │   ├── Phase1Tests.gd
    │   ├── Phase2Tests.gd
    │   ├── Phase4Tests.gd
    │   ├── Phase5Tests.gd
    │   ├── Phase6Tests.gd
    │   ├── Phase7Tests.gd
    │   ├── Phase8Tests.gd
    │   ├── Phase9Tests.gd
    │   ├── Phase10Tests.gd
    │   └── Phase11Tests.gd
    └── ui/                    # UI controllers (kept separate from sim code)
        ├── MainMenu.gd
        ├── LabDashboard.gd
        ├── GenotypeDebug.gd
        ├── PhenotypeViewer.gd
        ├── MicroscopeViewer.gd
        ├── FlyRenderer.gd     # procedural 2D fly (vector shapes, no assets)
        ├── DevelopmentTimeline.gd
        ├── CrossSimulator.gd
        ├── StatisticsScreen.gd
        ├── NotebookScreen.gd
        ├── CampaignScreen.gd
        ├── PopulationScreen.gd
        └── EquipmentScreen.gd
```

Simulation code lives in `scripts/sim/` separately from UI code, per the
conventions.

---

## Safety boundary

This game never provides real-world biological modification instructions. It does
not implement or describe CRISPR/guide-RNA design, primers, injection or
transformation protocols, reagent lists, gene drives, or any real organism
engineering workflow. All genetics here is an abstract computational model.
