# Coding conventions

Conventions for the Drosophila Genetics Lab Simulator. They exist to keep the
project extensible (data-driven) and the simulation testable (deterministic).

## Architecture

1. **Keep simulation code separate from UI code.** Simulation/engine logic must
   not reach into `Control` nodes. UI scripts (`scripts/ui/`) read from and call
   into engines; engines never depend on UI.
2. **Prefer data over code.** New genes, alleles, traits, rules, and scenarios
   go in `res://data/*.json`, not in `if/else` blocks. Avoid large hardcoded
   switch statements over gene/allele IDs.
3. **All randomness goes through `RandomService`.** Never call the global
   `randf()`/`randi()` from simulation code. Reproducibility (same seed → same
   result) is a hard requirement.
4. **Every simulation result must be explainable.** Engines record
   human-readable reasons (the ExplanationEngine, Phase 2+). No black-box
   phenotypes.
5. **Autoload singletons** (`DataLoader`, `RandomService`, `SaveLoadService`) are
   registered in `project.godot` and reachable globally by name.

## GDScript style

- One class per file; file name matches the class (PascalCase): `Fly.gd`.
- Indent with **tabs** (Godot default).
- `snake_case` for variables, functions, and signals; `PascalCase` for classes
  and nodes; `CONSTANT_CASE` for constants.
- Prefix intentionally-private members with `_` (`_cache`, `_refresh()`).
- Use **static typing** everywhere it is reasonable (`var x: int`,
  `func f(a: String) -> bool`). It catches errors and documents intent.
- Use `##` doc comments on classes and public functions; `#` for inline notes.
- **Comment non-obvious biological abstractions** — explain what a number or
  rule models and that it is simplified, not literal biology.

## Scenes

- UI scenes live in `scenes/`; their controller scripts live in `scripts/ui/`.
- Reference important nodes via unique names (`%NodeName`) rather than long
  paths, so layout can be rearranged without breaking scripts.
- Connect signals in the scene file (Inspector) where practical; name handlers
  `_on_<node>_<signal>`.

## Safety (non-negotiable)

- Never add real wet-lab protocols or real gene-editing instructions.
- All genetics is an abstract computational model. Label fictional/simplified
  modules as abstractions in data and UI.

## Process

- Build phase by phase (SPECS.md §24). Keep the project runnable after each.
- Update `README.md` and add a `CHANGELOG.md` entry per phase.
- Add debug/test screens for simulation verification as systems land.
