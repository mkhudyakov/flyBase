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

## Current status: Phase 3 — Procedural fly renderer

The phenotype is now drawn as a 2D fly from generated vector shapes. What works:

- Everything from Phases 0–2 (menu, dashboard, services, data model, phenotype
  engine, Genotype/Phenotype viewers).
- **FlyRenderer** (`scripts/ui/FlyRenderer.gd`) draws a top-down fly — head,
  thorax, striped abdomen, wings, legs, antennae, eyes, bristles — entirely from
  vector shapes. **No art assets.**
- Every visual is **phenotype-driven**: eye color (red↔white), eye size, wing
  size + shape (notching), body color (yellow↔ebony), body size, bristle count,
  antenna shape (leg-like as it drops), and `deformity_score` asymmetry.
- **Microscope Viewer** screen (Dashboard → *Microscope Viewer*): pick a fly and
  see it drawn; *Recompute* re-rolls expressivity/penetrance on the same genome.
- Verified visually: white-eyed, vestigial-winged, and light/dark-bodied flies
  each look clearly different.

> Phase 3 added two renderer-facing traits (`body_size`, `bristle_count`),
> bringing the total to 17; the phenotype engine itself is unchanged from
> Phase 2 and still reproducible. Environment effects on development arrive in
> Phase 4.

### Phenotype engine recap (Phase 2)

`PhenotypeEngine` converts a genome into traits using dominance + dose,
**penetrance**, and **expressivity**, recording a human-readable **explanation
log**. Data-driven traits live in `data/trait_rules.json`. Same seed + same
genotype → identical phenotype. Hidden carriers, pleiotropy, and X-linked male
expression all work and are covered by `Phase2Tests.tscn`.

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
│   └── trait_rules.json       # 17 traits (baselines + normal ranges)
├── scenes/                    # Godot scenes (.tscn)
│   ├── MainMenu.tscn
│   ├── LabDashboard.tscn
│   ├── GenotypeDebug.tscn
│   ├── PhenotypeViewer.tscn
│   ├── MicroscopeViewer.tscn
│   ├── Phase1Tests.tscn       # headless test scenes
│   └── Phase2Tests.tscn
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
    │   ├── VialEnvironment.gd  # "Environment" collides with a Godot built-in
    │   ├── Fly.gd
    │   └── FlyFactory.gd
    ├── tests/
    │   ├── Phase1Tests.gd
    │   └── Phase2Tests.gd
    └── ui/                    # UI controllers (kept separate from sim code)
        ├── MainMenu.gd
        ├── LabDashboard.gd
        ├── GenotypeDebug.gd
        ├── PhenotypeViewer.gd
        ├── MicroscopeViewer.gd
        └── FlyRenderer.gd     # procedural 2D fly (vector shapes, no assets)
```

Simulation code lives in `scripts/sim/` separately from UI code, per the
conventions.

---

## Safety boundary

This game never provides real-world biological modification instructions. It does
not implement or describe CRISPR/guide-RNA design, primers, injection or
transformation protocols, reagent lists, gene drives, or any real organism
engineering workflow. All genetics here is an abstract computational model.
