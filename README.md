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

## Current status: Phase 5 — Inheritance & cross simulator

Two flies can now be crossed to produce offspring. What works:

- Everything from Phases 0–4 (menu, dashboard, services, data model, phenotype
  engine, fly renderer, development engine, viewers).
- **InheritanceEngine** (`scripts/sim/InheritanceEngine.gd`) runs meiosis →
  gametes → offspring with **autosomal** and **sex-linked** inheritance,
  **simplified recombination** (map-distance linkage), sex determination
  (mother gives X; father gives X→daughter / Y→son), and optional spontaneous
  mutation. Each offspring is developed under the vial environment.
- **Cross Simulator** screen (Dashboard → *Cross Simulator*): choose two parents,
  10 / 100 / 1000 offspring, and a seed; see genotype and phenotype
  distributions, sex/survival ratios, and **expected-vs-observed** ratio tables
  per segregating gene, with deviation explanations.
- Correct, verified genetics: monohybrid **3:1 / 1:2:1**, X-linked **criss-cross**
  (white ♀ × wild ♂ → carrier daughters, white sons), and **lethal deviation**
  (bcd/+ × bcd/+ → homozygotes conceived at ~25% but absent among adults, with
  the deviation explained). Reproducible by seed. `Phase5Tests.tscn` (15 checks).

> Vials / lab management arrive in Phase 6.

### Earlier phases recap

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
"$GODOT" --headless --path . res://scenes/Phase5Tests.tscn --quit-after 15
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
│   ├── CrossSimulator.tscn
│   ├── Phase1Tests.tscn       # headless test scenes
│   ├── Phase2Tests.tscn
│   ├── Phase4Tests.tscn
│   └── Phase5Tests.tscn
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
    │   ├── InheritanceEngine.gd
    │   ├── CrossResult.gd
    │   ├── VialEnvironment.gd  # "Environment" collides with a Godot built-in
    │   ├── Fly.gd
    │   └── FlyFactory.gd
    ├── tests/
    │   ├── Phase1Tests.gd
    │   ├── Phase2Tests.gd
    │   ├── Phase4Tests.gd
    │   └── Phase5Tests.gd
    └── ui/                    # UI controllers (kept separate from sim code)
        ├── MainMenu.gd
        ├── LabDashboard.gd
        ├── GenotypeDebug.gd
        ├── PhenotypeViewer.gd
        ├── MicroscopeViewer.gd
        ├── FlyRenderer.gd     # procedural 2D fly (vector shapes, no assets)
        ├── DevelopmentTimeline.gd
        └── CrossSimulator.gd
```

Simulation code lives in `scripts/sim/` separately from UI code, per the
conventions.

---

## Safety boundary

This game never provides real-world biological modification instructions. It does
not implement or describe CRISPR/guide-RNA design, primers, injection or
transformation protocols, reagent lists, gene drives, or any real organism
engineering workflow. All genetics here is an abstract computational model.
