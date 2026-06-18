# Data directory

Data-driven content for the simulator. Everything here is **abstract, virtual
simulator data** — not real biological data, and never real wet-lab or
gene-editing instructions.

Files (loaded by `scripts/autoload/DataLoader.gd`):

| File                      | Status   | Introduced |
|---------------------------|----------|------------|
| `genes.json`              | active (16 genes) | Phase 1 |
| `alleles.json`            | active (37 alleles) | Phase 1 |
| `trait_rules.json`        | active (21 traits) | Phase 2 |
| `development_stages.json` | active (10 stages) | Phase 4 |
| `epistasis_rules.json`    | active (2 rules) | Phase 9 |
| `scenarios.json`          | active (15 scenarios) | Phase 8 |
| `equipment.json`          | active (5 upgrades) | Phase 11 |
| `lang_ru.json`            | active (RU campaign text) | localization |

`genes.json` and `alleles.json` are parsed by `scripts/sim/Catalog.gd` into
`Gene`/`Allele` objects. Each gene defines exactly one `wild_type` allele plus
one or more mutant alleles. `affected_traits` values are signed deltas the
Phase 2 phenotype engine will consume.

Missing files are tolerated by the loader (logged as warnings, never fatal), so
the project always opens even before every file exists.
