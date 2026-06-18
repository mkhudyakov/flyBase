# Data directory

Data-driven content for the simulator. Everything here is **abstract, virtual
simulator data** — not real biological data, and never real wet-lab or
gene-editing instructions.

Files (loaded by `scripts/autoload/DataLoader.gd`):

| File                      | Status   | Introduced |
|---------------------------|----------|------------|
| `genes.json`              | placeholder | Phase 0 (full catalog in Phase 1) |
| `alleles.json`            | not yet  | Phase 1 |
| `trait_rules.json`        | not yet  | Phase 2 |
| `development_stages.json` | not yet  | Phase 4 |
| `epistasis_rules.json`    | not yet  | Phase 9 |
| `scenarios.json`          | not yet  | Phase 8 |

Missing files are tolerated by the loader (logged as warnings, never fatal), so
the project always opens even before every file exists.
