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

## Current status: Phase 9 — Advanced genetics

Simple Mendelian ratios can now fail for rich, explainable reasons. What works:

- Everything from Phases 0–8 (simulation core, lab, statistics, notebook, campaign).
- **Epistasis** (data-driven `data/epistasis_rules.json`): one gene can mask
  another — eyeless flies hide their eye-color genotype; severe wing loss
  overrides wing-shape genes. Masked traits show as e.g. "no-eye".
- **Modifier alleles**: a suppressor reduces another gene's effect (rescuing
  vestigial wings) and an enhancer worsens it — neither shows a phenotype alone.
- **Polygenic traits**: body size is set additively by three body-size loci; you
  stack "large" variants through breeding to grow an unusually large fly.
- **Temperature-sensitive alleles**: a hidden allele only expresses when reared
  warm, so the **environment reveals the genotype**.
- **3 advanced challenge scenarios** (gated after the intro chain): epistasis
  (hidden eye color), the temperature-sensitive mutant, and polygenic body size.
- 16 genes / 37 alleles. `Phase9Tests.tscn` (13 checks). Each fly also carries a
  per-individual `roll_seed`, so genetically identical siblings vary in
  expressivity/penetrance (and stay reproducible).

> Population-scale simulation (selection, drift, line stability) is Phase 10.

### Earlier phases recap

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
│   └── scenarios.json         # 8 campaign scenarios
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
│   ├── Phase1Tests.tscn       # headless test scenes
│   ├── Phase2Tests.tscn
│   ├── Phase4Tests.tscn
│   ├── Phase5Tests.tscn
│   ├── Phase6Tests.tscn
│   ├── Phase7Tests.tscn
│   ├── Phase8Tests.tscn
│   └── Phase9Tests.tscn
└── scripts/
    ├── autoload/              # Singletons (registered in project.godot)
    │   ├── DataLoader.gd
    │   ├── RandomService.gd
    │   └── SaveLoadService.gd
    ├── game/                  # Game-layer state (vials, incubators, lab)
    │   ├── Lab.gd             # autoload: central lab state + operations
    │   ├── Campaign.gd        # autoload: scenarios, objectives, unlocks
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
    │   └── Phase9Tests.gd
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
        └── CampaignScreen.gd
```

Simulation code lives in `scripts/sim/` separately from UI code, per the
conventions.

---

## Safety boundary

This game never provides real-world biological modification instructions. It does
not implement or describe CRISPR/guide-RNA design, primers, injection or
transformation protocols, reagent lists, gene drives, or any real organism
engineering workflow. All genetics here is an abstract computational model.
