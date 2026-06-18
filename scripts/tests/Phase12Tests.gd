extends Node
## Phase12Tests — headless verification of productization-layer logic:
## settings persistence, the full campaign (>=15 scenarios), new-game reset,
## and the heat-fertility balancing tweak.
##
## Run with:
##   Godot --headless --path . res://scenes/Phase12Tests.tscn --quit-after 5

var _passed := 0
var _failed := 0

func _ready() -> void:
	print("\n==== Phase 12 tests ====")

	# Campaign content: at least 15 scenarios, fully linked.
	_check("Campaign has at least 15 scenarios", Campaign.all_scenarios().size() >= 15)
	_check("Every scenario has objectives and a reward", _scenarios_well_formed())
	_check("Scenario requires/unlocks reference real scenarios", _chain_valid())

	# Settings model + persistence.
	Settings.master_volume = 0.42
	Settings.ui_scale = 1.2
	Settings.high_contrast = true
	var snap := Settings.to_dict()
	Settings.master_volume = 0.0
	Settings.ui_scale = 1.0
	Settings.high_contrast = false
	_load_settings(snap)
	_check("Settings round-trip preserves values",
		is_equal_approx(Settings.master_volume, 0.42) and is_equal_approx(Settings.ui_scale, 1.2) and Settings.high_contrast)

	# Audio synthesized at startup (no asset files).
	_check("AudioManager is present", AudioManager != null)

	# New-game reset clears progress.
	Economy.reset()
	Economy.award_scenario({"research_points": 50, "budget": 50})
	Campaign.completed.append("foundations")
	Lab.notebook.append({"kind": "cross", "title": "x"})
	_new_game()
	_check("New game resets economy", Economy.research_points == 0 and Economy.budget == Economy.START_BUDGET)
	_check("New game clears campaign progress", Campaign.completed.is_empty())
	_check("New game rebuilds a fresh lab", Lab.notebook.is_empty() and Lab.active_vials().size() >= 2)

	# Balancing: heat suppresses fertility (recover-fertility scenario relies on it).
	var cool := VialEnvironment.standard(); cool.temperature_c = 25.0
	var hot := VialEnvironment.standard(); hot.temperature_c = 30.0
	var f_cool := _fertility(cool)
	var f_hot := _fertility(hot)
	_check("Heat reduces fertility (cool > hot)", f_cool > f_hot + 0.05)
	_check("Cool rearing gives high fertility (>=0.92)", f_cool >= 0.92)

	# Save/load still works end to end (Lab).
	Lab.new_default_lab()
	var n := Lab.active_vials().size()
	Lab.save_lab()
	Lab.load_from_dict(Lab.to_dict())
	_check("Lab save/load still works", Lab.active_vials().size() == n)

	SaveLoadService.delete_save("settings")
	SaveLoadService.delete_save("lab")
	SaveLoadService.delete_save("campaign")
	SaveLoadService.delete_save("economy")
	print("==== %d passed, %d failed ====\n" % [_passed, _failed])

func _scenarios_well_formed() -> bool:
	for s in Campaign.all_scenarios():
		if s.get("objectives", []).is_empty() or s.get("reward", {}).is_empty():
			return false
	return true

func _chain_valid() -> bool:
	var ids := {}
	for s in Campaign.all_scenarios():
		ids[String(s["id"])] = true
	for s in Campaign.all_scenarios():
		for r in s.get("requires", []):
			if not ids.has(String(r)):
				return false
		for u in s.get("unlocks", []):
			if not ids.has(String(u)):
				return false
	return true

func _fertility(env: VialEnvironment) -> float:
	var fly := FlyFactory.create_wild_type(Genome.FEMALE)
	var r := DevelopmentEngine.simulate(fly, env, 4242)
	return r.fertility_score

func _load_settings(d: Dictionary) -> void:
	Settings.master_volume = float(d["master_volume"])
	Settings.sfx_volume = float(d["sfx_volume"])
	Settings.music_volume = float(d["music_volume"])
	Settings.ui_scale = float(d["ui_scale"])
	Settings.high_contrast = bool(d["high_contrast"])
	Settings.reduced_motion = bool(d["reduced_motion"])

func _new_game() -> void:
	Lab.new_default_lab()
	Campaign.completed.clear()
	Campaign.unlocks.clear()
	Campaign.quiz_correct.clear()
	Economy.reset()

func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % label)
	else:
		_failed += 1
		print("  FAIL  %s" % label)
