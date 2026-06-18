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

## Current status: Phase 1 — Core data model

The fly/genome/gene/allele/phenotype/environment classes now exist and are
data-driven. What works:

- Everything from Phase 0 (menu, dashboard, services).
- **Core simulation classes** (`scripts/sim/`): `Gene`, `Allele`, `Chromosome`,
  `Genome`, `Phenotype`, `Environment`, `Fly`, plus a `FlyFactory` and a
  `Catalog` singleton.
- **Data-driven catalog**: 12 genes (`data/genes.json`) and 24 alleles
  (`data/alleles.json`), loaded and parsed at startup.
- **Diploid genome model** with homologous chromosome copies and correct
  sex-linkage: females are XX, males XY, and a male X-linked gene is hemizygous.
- **Genotype Debug** screen: build wild-type / mutant / carrier flies and read
  their genotype gene-by-gene. (Dashboard → *Genotype Debug*.)
- **Save/load one fly** round-trips a genome through JSON without loss.
- Headless test scene `res://scenes/Phase1Tests.tscn` (13 checks, all passing).

> Phenotype is **not computed yet** — that's Phase 2. The `Phenotype` class is a
> container today; the genome carries alleles, but their visible effects are not
> yet expressed.

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
│   └── alleles.json           # 24 alleles
├── scenes/                    # Godot scenes (.tscn)
│   ├── MainMenu.tscn
│   ├── LabDashboard.tscn
│   ├── GenotypeDebug.tscn
│   └── Phase1Tests.tscn       # headless test scene
└── scripts/
    ├── autoload/              # Singletons (registered in project.godot)
    │   ├── DataLoader.gd
    │   ├── RandomService.gd
    │   └── SaveLoadService.gd
    ├── sim/                   # Simulation classes (no UI dependencies)
    │   ├── Catalog.gd         # autoload: parses JSON into Gene/Allele objects
    │   ├── Gene.gd
    │   ├── Allele.gd
    │   ├── Chromosome.gd
    │   ├── Genome.gd
    │   ├── Phenotype.gd
    │   ├── VialEnvironment.gd  # "Environment" collides with a Godot built-in
    │   ├── Fly.gd
    │   └── FlyFactory.gd
    ├── tests/
    │   └── Phase1Tests.gd
    └── ui/                    # UI controllers (kept separate from sim code)
        ├── MainMenu.gd
        ├── LabDashboard.gd
        └── GenotypeDebug.gd
```

Simulation code lives in `scripts/sim/` separately from UI code, per the
conventions.

---

## Safety boundary

This game never provides real-world biological modification instructions. It does
not implement or describe CRISPR/guide-RNA design, primers, injection or
transformation protocols, reagent lists, gene drives, or any real organism
engineering workflow. All genetics here is an abstract computational model.
