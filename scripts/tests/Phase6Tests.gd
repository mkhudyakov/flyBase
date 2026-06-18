extends Node
## Phase6Tests — headless verification of the Lab / vial system.
##
## Run with:
##   Godot --headless --path . res://scenes/Phase6Tests.tscn --quit-after 5

var _passed := 0
var _failed := 0

func _ready() -> void:
	print("\n==== Phase 6 tests ====")
	Lab.new_default_lab()

	# Default lab content.
	_check("Default lab has >= 2 active vials", Lab.active_vials().size() >= 2)
	_check("Default lab has >= 3 incubators", Lab.incubators.size() >= 3)
	_check("Default lab has flies", Lab.total_flies() > 0)

	# Create a vial.
	var before := Lab.active_vials().size()
	var fresh := Lab.create_vial("Test vial")
	_check("create_vial adds an active vial", Lab.active_vials().size() == before + 1)
	_check("New vial starts empty", fresh.population() == 0)

	# Move a fly between vials.
	var stock := Lab.active_vials()[0]
	var src_n := stock.population()
	var fly_id: String = stock.flies[0].id
	var moved := Lab.move_fly(fly_id, stock.id, fresh.id)
	_check("move_fly succeeds", moved)
	_check("Source vial lost a fly", stock.population() == src_n - 1)
	_check("Target vial gained the fly", fresh.find_fly(fly_id) != null)

	# Archive a vial.
	var active_before := Lab.active_vials().size()
	Lab.archive_vial(fresh.id)
	_check("Archiving removes vial from active list", Lab.active_vials().size() == active_before - 1)
	_check("Archived vial is listed as archived", Lab.archived_vials().size() >= 1)

	# Effective environment takes temperature from the incubator.
	var cold := Lab.incubators[0]  # 18°C in the default lab
	var v := Lab.create_vial("Cold vial", cold.id)
	_check("effective_environment uses incubator temperature",
		is_equal_approx(Lab.effective_environment(v).temperature_c, cold.temperature_c))

	# Breed: produces an offspring vial of the next generation.
	var stock2 := Lab.active_vials()[0]
	var warm := _incubator_at(25.0)
	stock2.incubator_id = warm.id
	var child := Lab.breed(stock2, 50, 4242)
	_check("Breeding a vial with a pair produces an offspring vial", child != null)
	if child != null:
		_check("Offspring survive at 25°C", child.population() > 0)
		_check("Offspring are the next generation", child.flies[0].generation == stock2.flies[0].generation + 1)

	# Incubator temperature affects development: breeding hot is lethal.
	var hot := Lab.incubators[2]  # 29°C slot — push it to a lethal 36°C
	hot.temperature_c = 36.0
	stock2.incubator_id = hot.id
	var child_hot := Lab.breed(stock2, 50, 4242)
	_check("Breeding at 36°C kills the offspring (incubator temperature matters)",
		child_hot != null and child_hot.population() == 0)

	# Save / load round trip.
	Lab.new_default_lab()
	var snapshot := Lab.to_dict()
	var n_vials := Lab.active_vials().size()
	var n_flies := Lab.total_flies()
	Lab.create_vial("scratch")  # mutate state
	Lab.load_from_dict(snapshot)
	_check("Save/load restores vial count", Lab.active_vials().size() == n_vials)
	_check("Save/load restores fly count", Lab.total_flies() == n_flies)

	print("==== %d passed, %d failed ====\n" % [_passed, _failed])

func _incubator_at(temp: float) -> Incubator:
	for inc in Lab.incubators:
		if is_equal_approx(inc.temperature_c, temp):
			return inc
	return Lab.incubators[0]

func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % label)
	else:
		_failed += 1
		print("  FAIL  %s" % label)
