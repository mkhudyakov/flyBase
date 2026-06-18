extends Node
## Phase10Tests — headless verification of the PopulationEngine.
##
## Run with:
##   Godot --headless --path . res://scenes/Phase10Tests.tscn --quit-after 5

const SEED := 777

var _passed := 0
var _failed := 0

func _ready() -> void:
	print("\n==== Phase 10 tests ====")
	var std := VialEnvironment.standard()

	# --- 10 generations, no selection: line persists, frequencies tracked ---
	var run := PopulationEngine.simulate(_carrier_founders(std), {
		"generations": 10, "seed": SEED, "track_genes": ["vg"], "env": std})
	_check("Runs the requested 10 generations", run.completed_generations == 10 and not run.extinct)
	_check("Records founders + 10 generations", run.generations.size() == 11)
	_check("Founder vg frequency ~0.5", absf(run.allele_freq_at(0, "vg", "vg_strong_loss") - 0.5) < 0.12)

	# --- Selection increases the desired allele ---
	var sel := PopulationEngine.simulate(_carrier_founders(std), {
		"generations": 8, "seed": SEED, "track_genes": ["vg"], "env": std,
		"selection": {"predicate": {"trait": "wing_size", "op": "lt", "value": 0.4}, "mode": "keep"}})
	var vg0 := sel.allele_freq_at(0, "vg", "vg_strong_loss")
	var vg_final := sel.allele_freq_at(sel.generations.size() - 1, "vg", "vg_strong_loss")
	_check("Selection increases the vestigial allele frequency", vg_final > vg0 + 0.2)
	_check("Selection drives the allele toward fixation (>0.85)", vg_final > 0.85)
	_check("Trait frequency changed under selection", absf(vg_final - vg0) > 0.05)

	# --- Low viability collapses the line ---
	var hot := VialEnvironment.standard(); hot.temperature_c = 35.0
	var collapse := PopulationEngine.simulate(_carrier_founders(std), {
		"generations": 10, "seed": SEED, "track_genes": ["vg"], "env": hot})
	_check("Lethal environment collapses the line", collapse.extinct)
	_check("Collapse ends before the full run", collapse.completed_generations < 10)

	# --- Line stability reflects outcome ---
	_check("Stability is in [0,1]", run.line_stability >= 0.0 and run.line_stability <= 1.0)
	_check("Stable line scores higher than a collapsed one", run.line_stability > collapse.line_stability)

	# --- Reproducibility ---
	var a := PopulationEngine.simulate(_carrier_founders(std), {"generations": 6, "seed": 4242, "track_genes": ["vg"], "env": std})
	var b := PopulationEngine.simulate(_carrier_founders(std), {"generations": 6, "seed": 4242, "track_genes": ["vg"], "env": std})
	_check("Same seed reproduces final population size",
		int(a.final()["population"]) == int(b.final()["population"]))
	_check("Same seed reproduces final allele frequency",
		is_equal_approx(a.allele_freq_at(a.generations.size() - 1, "vg", "vg_strong_loss"),
			b.allele_freq_at(b.generations.size() - 1, "vg", "vg_strong_loss")))

	# --- Bottleneck shrinks the population at the chosen generation ---
	var bn := PopulationEngine.simulate(_carrier_founders(std), {
		"generations": 8, "seed": SEED, "track_genes": ["vg"], "env": std,
		"bottleneck": {"at_gen": 3, "size": 6}})
	_check("Bottleneck caps the population at the chosen generation",
		int(bn.generations[3]["population"]) <= 6)

	print("==== %d passed, %d failed ====\n" % [_passed, _failed])

## 30 heterozygous vestigial carriers (vg/+), developed — vg allele freq 0.5.
func _carrier_founders(env: VialEnvironment) -> Array:
	var founders: Array = []
	for i in 30:
		var sex := Genome.FEMALE if i % 2 == 0 else Genome.MALE
		var fly := FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HETEROZYGOUS, sex)
		DevelopmentEngine.simulate(fly, env)
		founders.append(fly)
	return founders

func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % label)
	else:
		_failed += 1
		print("  FAIL  %s" % label)
