extends Node
## Phase11Tests — headless verification of the economy & progression layer.
##
## Run with:
##   Godot --headless --path . res://scenes/Phase11Tests.tscn --quit-after 5

var _passed := 0
var _failed := 0

func _ready() -> void:
	print("\n==== Phase 11 tests ====")
	Economy.reset()

	# Starting state + spending.
	_check("Starts with budget 100, 0 RP", Economy.budget == 100 and Economy.research_points == 0)
	_check("breed_cost scales with offspring count", Economy.breed_cost(50) == 10)
	_check("Can spend within budget", Economy.spend(50) and Economy.budget == 50)
	_check("Cannot overspend", not Economy.spend(100) and Economy.budget == 50)

	# Scenario reward.
	Economy.award_scenario({"research_points": 30, "budget": 40, "reputation": 2})
	_check("Scenario reward grants RP/budget/reputation",
		Economy.research_points == 30 and Economy.budget == 90 and Economy.reputation == 2)

	# Publishing.
	var reward := Economy.publish("exp_1")
	_check("Publishing grants a reward", not reward.is_empty() and Economy.publication_score == 1)
	_check("Cannot publish the same experiment twice", Economy.publish("exp_1").is_empty())

	# Equipment loaded.
	_check("Equipment catalog loaded (>=3)", Economy.all_equipment().size() >= 3)

	# Unlocking with research points.
	Economy.reset()
	_check("Cannot unlock without enough RP", not Economy.unlock("large_cross"))
	Economy.award_scenario({"research_points": 100})
	var rp_before := Economy.research_points
	_check("Unlock succeeds with enough RP", Economy.unlock("large_cross"))
	_check("Unlock is recorded", Economy.is_unlocked("large_cross"))
	_check("Unlock spends research points", Economy.research_points < rp_before)

	# Prerequisite gating.
	Economy.reset()
	Economy.award_scenario({"research_points": 100})
	_check("Equipment with unmet prerequisite cannot be unlocked", not Economy.unlock("automation"))
	Economy.unlock("large_cross")
	_check("Equipment unlocks once prerequisite is met", Economy.unlock("automation"))

	# Automation lowers breeding cost (a meaningful upgrade effect).
	_check("Automation reduces breed cost", Economy.breed_cost(50) < 10)

	# Completing a scenario rewards the economy (integration with Campaign).
	Economy.reset()
	Campaign.completed.clear()
	Campaign.unlocks.clear()
	Campaign.current_id = "foundations"
	var rp0 := Economy.research_points
	var budget0 := Economy.budget
	Campaign.complete_current()
	_check("Completing a scenario rewards the economy",
		Economy.research_points > rp0 and Economy.budget > budget0)

	# Save / load.
	Economy.reset()
	Economy.award_scenario({"research_points": 20, "budget": 12})
	_check("stats_suite unlock used for persistence test", Economy.unlock("stats_suite"))
	var snapshot := Economy.to_dict()
	Economy.reset()
	_apply(snapshot)
	_check("Economy persists through save/load",
		Economy.research_points == int(snapshot["research_points"]) and Economy.is_unlocked("stats_suite"))

	SaveLoadService.delete_save("economy")
	SaveLoadService.delete_save("campaign")
	print("==== %d passed, %d failed ====\n" % [_passed, _failed])

func _apply(d: Dictionary) -> void:
	Economy.research_points = int(d["research_points"])
	Economy.budget = int(d["budget"])
	Economy.reputation = int(d["reputation"])
	Economy.publication_score = int(d["publication_score"])
	Economy.unlocked.assign(d["unlocked"])
	Economy.published.assign(d["published"])

func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % label)
	else:
		_failed += 1
		print("  FAIL  %s" % label)
