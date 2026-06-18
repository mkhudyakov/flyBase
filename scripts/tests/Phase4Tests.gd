extends Node
## Phase4Tests — headless verification of the DevelopmentEngine.
##
## Run with:
##   Godot --headless --path . res://scenes/Phase4Tests.tscn --quit-after 5
##
## Fixed roll_seed keeps the probabilistic stages deterministic.

const SEED := 4242

var _passed := 0
var _failed := 0

func _ready() -> void:
	print("\n==== Phase 4 tests ====")

	var std := VialEnvironment.standard()

	# Wild-type reaches adulthood healthily.
	var wt := FlyFactory.create_wild_type(Genome.FEMALE)
	var wt_r := DevelopmentEngine.simulate(wt, std, SEED)
	_check("Wild-type reaches adult", wt_r.reached_adult)
	_check("Wild-type outcome is healthy adult", wt_r.outcome == "healthy adult")
	_check("Wild-type viability high (>0.8)", wt_r.viability_score > 0.8)
	_check("Wild-type went through all 10 stages", wt_r.stage_logs.size() == 10)
	_check("Wild-type explanation generated", wt_r.explanation.size() > 0)

	# Severe developmental mutant (bicoid, axis patterning) fails early.
	var bcd := FlyFactory.create_mutant("bcd", "bcd_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE)
	var bcd_r := DevelopmentEngine.simulate(bcd, std, SEED)
	_check("bicoid homozygous fails to reach adult", not bcd_r.reached_adult)
	_check("bicoid failure has a named outcome", bcd_r.outcome != "" and bcd_r.outcome != "healthy adult")
	_check("bicoid failure explained (mentions axis or bcd)",
		_explanation_contains(bcd_r, "axis") or _explanation_contains(bcd_r, "bcd"))
	_check("bicoid dies early (before pupa)", bcd_r.stage_logs.size() <= 4)

	# Temperature changes stage duration: cold is slower than hot.
	var cold_env := VialEnvironment.standard(); cold_env.temperature_c = 18.0
	var hot_env := VialEnvironment.standard(); hot_env.temperature_c = 29.0
	var cold_r := DevelopmentEngine.simulate(FlyFactory.create_wild_type(Genome.FEMALE), cold_env, SEED)
	var hot_r := DevelopmentEngine.simulate(FlyFactory.create_wild_type(Genome.FEMALE), hot_env, SEED)
	_check("Low temperature slows development (more days than high temp)",
		cold_r.total_days > hot_r.total_days)

	# Extreme temperature is lethal.
	var extreme_env := VialEnvironment.standard(); extreme_env.temperature_c = 36.0
	var extreme_r := DevelopmentEngine.simulate(FlyFactory.create_wild_type(Genome.FEMALE), extreme_env, SEED)
	_check("Extreme temperature is lethal", not extreme_r.reached_adult)
	_check("Extreme temperature outcome is temperature lethality",
		extreme_r.outcome == "temperature lethality")

	# Nutrition: moderate low food yields a smaller, less fertile (but surviving) adult.
	var lowfood_env := VialEnvironment.standard(); lowfood_env.food_quantity = 0.5
	var low := FlyFactory.create_wild_type(Genome.FEMALE)
	var low_r := DevelopmentEngine.simulate(low, lowfood_env, SEED)
	var ref := FlyFactory.create_wild_type(Genome.FEMALE)
	DevelopmentEngine.simulate(ref, std, SEED)
	_check("Low food reduces body size",
		low.phenotype.get_trait("body_size") < ref.phenotype.get_trait("body_size"))
	_check("Low food reduces fertility",
		low_r.fertility_score < ref.phenotype.get_trait("fertility_score"))

	# Severe starvation collapses development.
	var starve_env := VialEnvironment.standard(); starve_env.food_quantity = 0.15
	var starve_r := DevelopmentEngine.simulate(FlyFactory.create_wild_type(Genome.FEMALE), starve_env, SEED)
	_check("Severe starvation causes metabolic collapse",
		not starve_r.reached_adult and starve_r.outcome == "metabolic collapse")

	# Reproducibility: same seed + genome + env → same result.
	var a := FlyFactory.create_wild_type(Genome.FEMALE)
	var b := FlyFactory.create_wild_type(Genome.FEMALE)
	var ra := DevelopmentEngine.simulate(a, std, 555)
	var rb := DevelopmentEngine.simulate(b, std, 555)
	_check("Same seed reproduces development",
		ra.total_days == rb.total_days and ra.outcome == rb.outcome
		and is_equal_approx(ra.viability_score, rb.viability_score))

	print("==== %d passed, %d failed ====\n" % [_passed, _failed])

func _explanation_contains(r: DevelopmentResult, needle: String) -> bool:
	for line in r.explanation:
		if needle.to_lower() in String(line).to_lower():
			return true
	return false

func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % label)
	else:
		_failed += 1
		print("  FAIL  %s" % label)
