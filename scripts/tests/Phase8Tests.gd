extends Node
## Phase8Tests — headless verification of the campaign framework.
##
## Run with:
##   Godot --headless --path . res://scenes/Phase8Tests.tscn --quit-after 5

const SEED := 4242

var _passed := 0
var _failed := 0

func _ready() -> void:
	print("\n==== Phase 8 tests ====")
	_reset_campaign()

	_check("At least 5 scenarios loaded", Campaign.all_scenarios().size() >= 5)

	# --- Start seeds the lab ---
	Campaign.start_scenario("foundations")
	var vials := Lab.active_vials()
	_check("Starting a scenario seeds its vials", vials.size() == 1 and vials[0].population() == 2)
	_check("foundations objective starts incomplete", not Campaign.is_scenario_complete("foundations"))

	# --- Objective completes after breeding ---
	Lab.breed(Lab.active_vials()[0], 100, SEED)
	_check("foundations objective completes after producing vestigial offspring",
		Campaign.is_scenario_complete("foundations"))

	# --- Unlock gating ---
	_check("eye_color_mystery locked before foundations done", not Campaign.is_unlocked("eye_color_mystery"))
	Campaign.complete_current()
	_check("foundations recorded as completed", Campaign.is_completed("foundations"))
	_check("eye_color_mystery unlocked after completion", Campaign.is_unlocked("eye_color_mystery"))

	# --- Quiz objective ---
	Campaign.start_scenario("eye_color_mystery")
	var wrong := Campaign.answer_quiz("eye_color_mystery", 1, 0)  # "Dominant" — wrong
	_check("Wrong quiz answer is rejected", not wrong)
	var right := Campaign.answer_quiz("eye_color_mystery", 1, 1)  # "Recessive" — correct
	_check("Correct quiz answer is accepted", right)
	# Quiz objective (index 1) should now read complete.
	var eo := Campaign.evaluate("eye_color_mystery")
	_check("Quiz objective marked complete", eo[1]["complete"])

	# --- cross_survival_below ---
	Campaign.start_scenario("lethal_recessive")
	Lab.breed(Lab.active_vials()[0], 200, SEED)
	var lr := Campaign.evaluate("lethal_recessive")
	_check("Lethal cross objective completes (survival < 85%)", lr[0]["complete"])

	# --- vial_uniform_phenotype ---
	Campaign.start_scenario("build_flightless")
	var inc := Lab.incubators[1]
	var line := Lab.create_vial("vestigial line", inc.id)
	for i in 30:
		var sex := Genome.FEMALE if i % 2 == 0 else Genome.MALE
		var fly := FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HOMOZYGOUS, sex)
		# Explicit per-fly seed → deterministic (no dependence on the time-based global seed).
		DevelopmentEngine.simulate(fly, Lab.effective_environment(line), 9000 + i)
		line.add_fly(fly)
	_check("True-breeding vestigial line satisfies the objective",
		Campaign.is_scenario_complete("build_flightless"))

	# --- Progress persists through save/load ---
	Campaign.save_progress()
	var done_before := Campaign.completed.size()
	Campaign.completed.clear()
	Campaign.unlocks.clear()
	Campaign.load_progress()
	_check("Campaign progress persists through save/load", Campaign.completed.size() == done_before)

	SaveLoadService.delete_save("campaign")
	print("==== %d passed, %d failed ====\n" % [_passed, _failed])

func _reset_campaign() -> void:
	Campaign.completed.clear()
	Campaign.unlocks.clear()
	Campaign.quiz_correct.clear()
	Campaign.current_id = ""

func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % label)
	else:
		_failed += 1
		print("  FAIL  %s" % label)
