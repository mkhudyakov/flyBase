extends Node
## Campaign (autoload singleton) — structured gameplay (spec sections 4.1, 16).
##
## Loads scenarios from data/scenarios.json, seeds the lab for a chosen scenario,
## evaluates its objectives against the live Lab state + notebook, and tracks
## completion / unlocks. Scenarios are gated by `requires`, so completing one
## unlocks the next. Objective evaluation is data-driven — no per-scenario code.

const SAVE_SLOT := "campaign"

var scenarios: Array = []                 ## ordered scenario dicts
var current_id: String = ""               ## scenario currently being played
var completed: Array[String] = []
var unlocks: Array[String] = []
var quiz_correct: Dictionary = {}         ## obj_id -> true

func _ready() -> void:
	var data: Variant = DataLoader.get_data("scenarios")
	if data is Dictionary and data.has("scenarios"):
		scenarios = data["scenarios"]
	load_progress()

# --- Lookups -----------------------------------------------------------------

func get_scenario(id: String) -> Dictionary:
	for s in scenarios:
		if s is Dictionary and String(s.get("id", "")) == id:
			return s
	return {}

func all_scenarios() -> Array:
	return scenarios

func is_completed(id: String) -> bool:
	return completed.has(id)

## A scenario is unlocked once all its prerequisites are completed.
func is_unlocked(id: String) -> bool:
	var s := get_scenario(id)
	for req in s.get("requires", []):
		if not is_completed(String(req)):
			return false
	return true

# --- Flow --------------------------------------------------------------------

## Begins a scenario: seeds the lab with its starting vials and clears its quiz
## answers so it can be played fresh.
func start_scenario(id: String) -> void:
	var s := get_scenario(id)
	if s.is_empty():
		return
	current_id = id
	_seed_lab(s)
	# Reset quiz answers for this scenario.
	for i in s.get("objectives", []).size():
		quiz_correct.erase(_obj_id(id, i))

func _seed_lab(scenario: Dictionary) -> void:
	Lab.new_scenario_lab()
	for vspec: Dictionary in scenario.get("starting_vials", []):
		var inc_idx: int = clampi(int(vspec.get("incubator", 1)), 0, maxi(Lab.incubators.size() - 1, 0))
		var inc_id: String = Lab.incubators[inc_idx].id if not Lab.incubators.is_empty() else ""
		var vial := Lab.create_vial(String(vspec.get("name", "vial")), inc_id)
		for fspec: Dictionary in vspec.get("flies", []):
			for i in maxi(int(fspec.get("count", 1)), 1):
				vial.add_fly(_build_and_develop(fspec, vial))
	Lab.last_event = "Started scenario: %s" % scenario.get("title", current_id)

func _build_and_develop(fspec: Dictionary, vial: Vial) -> Fly:
	var sex: String = Genome.MALE if String(fspec.get("sex", "female")) == "male" else Genome.FEMALE
	var fly: Fly
	if bool(fspec.get("wild", false)) or fspec.get("gene", "") == "":
		fly = FlyFactory.create_wild_type(sex)
	else:
		var z := FlyFactory.Zygosity.HOMOZYGOUS if String(fspec.get("zyg", "hom")) == "hom" else FlyFactory.Zygosity.HETEROZYGOUS
		fly = FlyFactory.create_mutant(String(fspec["gene"]), String(fspec["allele"]), z, sex)
	DevelopmentEngine.simulate(fly, Lab.effective_environment(vial))
	return fly

## Marks the current scenario complete and records its unlocks.
func complete_current() -> void:
	if current_id == "" or is_completed(current_id):
		return
	completed.append(current_id)
	var s := get_scenario(current_id)
	for u in s.get("unlocks", []):
		if not unlocks.has(String(u)):
			unlocks.append(String(u))
	save_progress()

# --- Objective evaluation ----------------------------------------------------

func _obj_id(scenario_id: String, index: int) -> String:
	return "%s#%d" % [scenario_id, index]

## Returns per-objective status for a scenario:
## [{obj_id, type, desc, complete, progress, raw}]
func evaluate(scenario_id: String) -> Array:
	var s := get_scenario(scenario_id)
	var out: Array = []
	var objectives: Array = s.get("objectives", [])
	for i in objectives.size():
		var obj: Dictionary = objectives[i]
		var oid := _obj_id(scenario_id, i)
		var status := _eval_objective(obj, oid)
		out.append({
			"obj_id": oid,
			"type": String(obj.get("type", "")),
			"desc": String(obj.get("desc", "")),
			"complete": status["complete"],
			"progress": status["progress"],
			"raw": obj,
		})
	return out

func is_scenario_complete(scenario_id: String) -> bool:
	for o in evaluate(scenario_id):
		if not o["complete"]:
			return false
	return not get_scenario(scenario_id).get("objectives", []).is_empty()

func _eval_objective(obj: Dictionary, obj_id: String) -> Dictionary:
	match String(obj.get("type", "")):
		"phenotype_count":
			var c := 0
			for v in Lab.active_vials():
				for f: Fly in v.flies:
					if f.alive and _match(f, obj.get("predicate", {})):
						c += 1
			var need := int(obj.get("count", 1))
			return {"complete": c >= need, "progress": "%d / %d so far" % [c, need]}

		"vial_uniform_phenotype":
			var need_n := int(obj.get("count", 20))
			var min_frac := float(obj.get("min_fraction", 0.85))
			var best := ""
			var done := false
			for v in Lab.active_vials():
				var alive := v.alive_count()
				if alive == 0:
					continue
				var matched := 0
				for f: Fly in v.flies:
					if f.alive and _match(f, obj.get("predicate", {})):
						matched += 1
				var frac := float(matched) / float(alive)
				if alive >= need_n and frac >= min_frac:
					done = true
				if alive >= need_n:
					best = "%s: %d/%d matching (%.0f%%)" % [v.name, matched, alive, frac * 100.0]
			return {"complete": done, "progress": best if best != "" else "no vial has >=%d living flies yet" % need_n}

		"cross_survival_below":
			var thr := float(obj.get("threshold", 0.85))
			var min_n := int(obj.get("min_n", 100))
			var best := 1.0
			var done := false
			for e: Dictionary in Lab.notebook:
				if String(e.get("kind", "")) != "cross":
					continue
				var n := int(e.get("count", 0))
				if n < min_n:
					continue
				var sr := float(e.get("survivors", 0)) / float(maxi(n, 1))
				best = minf(best, sr)
				if sr < thr:
					done = true
			return {"complete": done, "progress": "lowest survival in a %d+ cross: %.0f%%" % [min_n, best * 100.0]}

		"quiz":
			var ok: bool = quiz_correct.get(obj_id, false)
			return {"complete": ok, "progress": "answered correctly" if ok else "not yet answered"}

		_:
			return {"complete": false, "progress": "unknown objective"}

## Evaluates a single-trait predicate {trait, op, value} against a fly.
func _match(fly: Fly, predicate: Dictionary) -> bool:
	if predicate.is_empty():
		return false
	var v := fly.phenotype.get_trait(String(predicate.get("trait", "")), 0.0)
	var target := float(predicate.get("value", 0.0))
	match String(predicate.get("op", "lt")):
		"lt": return v < target
		"le": return v <= target
		"gt": return v > target
		"ge": return v >= target
		"eq": return is_equal_approx(v, target)
	return false

## Records a quiz answer for an objective; returns whether it was correct.
func answer_quiz(scenario_id: String, index: int, choice: int) -> bool:
	var s := get_scenario(scenario_id)
	var objectives: Array = s.get("objectives", [])
	if index < 0 or index >= objectives.size():
		return false
	var obj: Dictionary = objectives[index]
	var correct := choice == int(obj.get("answer", -1))
	if correct:
		quiz_correct[_obj_id(scenario_id, index)] = true
		save_progress()
	return correct

# --- Save / load -------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"current_id": current_id,
		"completed": completed.duplicate(),
		"unlocks": unlocks.duplicate(),
		"quiz_correct": quiz_correct.duplicate(),
	}

func save_progress() -> void:
	SaveLoadService.save_game(SAVE_SLOT, to_dict())

func load_progress() -> void:
	if not SaveLoadService.has_save(SAVE_SLOT):
		return
	var env := SaveLoadService.load_game(SAVE_SLOT)
	if env.is_empty() or not env.has("data"):
		return
	var d: Dictionary = env["data"]
	current_id = String(d.get("current_id", ""))
	completed.assign(d.get("completed", []))
	unlocks.assign(d.get("unlocks", []))
	quiz_correct = d.get("quiz_correct", {}).duplicate()
