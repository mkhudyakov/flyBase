extends Node
## Economy (autoload singleton) — research points, budget, reputation,
## publication score, and equipment unlocks (spec sections 14-15).
##
## This is the progression layer that turns the sandbox into a game with
## constraints: breeding costs budget; completing scenarios and publishing
## experiments earn budget + research points + reputation; research points buy
## equipment that unlocks deeper analysis and bigger experiments. Engine-level
## simulation never depends on the economy — only the UI charges/awards — so the
## science stays pure.

const SAVE_SLOT := "economy"

const START_BUDGET := 100
const BREED_BASE_COST := 8
const VIAL_COST := 4

var research_points: int = 0
var budget: int = START_BUDGET
var reputation: int = 0
var publication_score: int = 0
var unlocked: Array[String] = []
var published: Array[String] = []   ## keys of notebook entries already published

var _equipment: Array = []          ## from equipment.json

func _ready() -> void:
	var data: Variant = DataLoader.get_data("equipment")
	if data is Dictionary and data.has("equipment"):
		_equipment = data["equipment"]
	load_progress()

## Resets to a fresh game (used when starting a new game / by tests).
func reset() -> void:
	research_points = 0
	budget = START_BUDGET
	reputation = 0
	publication_score = 0
	unlocked.clear()
	published.clear()

# --- Currency ----------------------------------------------------------------

## Supply cost of a cross of `count` offspring (bigger = pricier; automation cuts it).
func breed_cost(count: int) -> int:
	var cost := BREED_BASE_COST + int(count / 25)
	if is_unlocked("automation"):
		cost = int(ceil(cost * 0.5))
	return cost

func can_afford(amount: int) -> bool:
	return budget >= amount

## Spends budget if affordable; returns success.
func spend(amount: int) -> bool:
	if budget < amount:
		return false
	budget -= amount
	save_progress()
	return true

# --- Earning -----------------------------------------------------------------

## Awards a scenario's reward dict {research_points, budget, reputation}.
func award_scenario(reward: Dictionary) -> void:
	research_points += int(reward.get("research_points", 0))
	budget += int(reward.get("budget", 0))
	reputation += int(reward.get("reputation", 0))
	save_progress()

## Publishes a notebook experiment (once). Returns the reward granted, or {} if
## it was already published.
func publish(entry_key: String) -> Dictionary:
	if published.has(entry_key):
		return {}
	published.append(entry_key)
	var reward := {"publication_score": 1, "research_points": 8, "reputation": 2, "budget": 25}
	publication_score += int(reward["publication_score"])
	research_points += int(reward["research_points"])
	reputation += int(reward["reputation"])
	budget += int(reward["budget"])
	save_progress()
	return reward

func is_published(entry_key: String) -> bool:
	return published.has(entry_key)

# --- Equipment ---------------------------------------------------------------

func all_equipment() -> Array:
	return _equipment

func get_equipment(id: String) -> Dictionary:
	for e in _equipment:
		if e is Dictionary and String(e.get("id", "")) == id:
			return e
	return {}

func is_unlocked(id: String) -> bool:
	return unlocked.has(id)

## True if every prerequisite of an equipment item is owned.
func requirements_met(id: String) -> bool:
	for req in get_equipment(id).get("requires", []):
		if not is_unlocked(String(req)):
			return false
	return true

## Attempts to buy an equipment item with research points. Returns success.
func unlock(id: String) -> bool:
	var e := get_equipment(id)
	if e.is_empty() or is_unlocked(id) or not requirements_met(id):
		return false
	var cost := int(e.get("cost_rp", 0))
	if research_points < cost:
		return false
	research_points -= cost
	unlocked.append(id)
	save_progress()
	return true

# --- Save / load -------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"research_points": research_points,
		"budget": budget,
		"reputation": reputation,
		"publication_score": publication_score,
		"unlocked": unlocked.duplicate(),
		"published": published.duplicate(),
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
	research_points = int(d.get("research_points", 0))
	budget = int(d.get("budget", START_BUDGET))
	reputation = int(d.get("reputation", 0))
	publication_score = int(d.get("publication_score", 0))
	unlocked.assign(d.get("unlocked", []))
	published.assign(d.get("published", []))
