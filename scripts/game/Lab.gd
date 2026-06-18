extends Node
## Lab (autoload singleton) — the central game state (spec section 14): the
## player's vials, incubators, and lab-wide bookkeeping, plus the operations the
## dashboard performs (create/move/archive/breed) and save/load.
##
## This is the game layer sitting on top of the simulation engines. It owns no
## genetics logic itself — breeding delegates to the InheritanceEngine and
## development to the DevelopmentEngine.

const SAVE_SLOT := "lab"

var vials: Array[Vial] = []
var incubators: Array[Incubator] = []
var generation: int = 0
var last_event: String = ""
## Set by the dashboard to hand a specific fly to the Microscope viewer.
var pending_inspect: Fly = null

var _vial_counter: int = 0
var _inc_counter: int = 0

func _ready() -> void:
	if vials.is_empty():
		new_default_lab()

## Builds a fresh starter lab: three incubators and a couple of stock vials with
## developed founder flies, so the dashboard looks like a working lab on open.
func new_default_lab() -> void:
	vials.clear()
	incubators.clear()
	generation = 0
	_vial_counter = 0
	_inc_counter = 0

	var cold := _add_incubator("Incubator (18°C)", 18.0)
	var standard := _add_incubator("Incubator (25°C)", 25.0)
	_add_incubator("Incubator (29°C)", 29.0)

	var stock := create_vial("Wild-type stock", standard.id)
	for i in 2:
		stock.add_fly(_founder(FlyFactory.create_wild_type(Genome.FEMALE), standard))
		stock.add_fly(_founder(FlyFactory.create_wild_type(Genome.MALE), standard))

	var carriers := create_vial("vestigial line (vg/+)", standard.id)
	carriers.add_fly(_founder(
		FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HETEROZYGOUS, Genome.FEMALE), standard))
	carriers.add_fly(_founder(
		FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HETEROZYGOUS, Genome.MALE), standard))

	last_event = "New lab created."

## Develops a founder fly in an incubator so it has a phenotype and alive state.
func _founder(fly: Fly, inc: Incubator) -> Fly:
	var env := VialEnvironment.standard()
	env.temperature_c = inc.temperature_c
	DevelopmentEngine.simulate(fly, env)
	return fly

# --- Lookups -----------------------------------------------------------------

func get_vial(vial_id: String) -> Vial:
	for v in vials:
		if v.id == vial_id:
			return v
	return null

func get_incubator(inc_id: String) -> Incubator:
	for inc in incubators:
		if inc.id == inc_id:
			return inc
	return null

func active_vials() -> Array[Vial]:
	var out: Array[Vial] = []
	for v in vials:
		if not v.archived:
			out.append(v)
	return out

func archived_vials() -> Array[Vial]:
	var out: Array[Vial] = []
	for v in vials:
		if v.archived:
			out.append(v)
	return out

func total_flies() -> int:
	var n := 0
	for v in active_vials():
		n += v.population()
	return n

# --- Operations --------------------------------------------------------------

func _add_incubator(name: String, temp: float) -> Incubator:
	_inc_counter += 1
	var inc := Incubator.new()
	inc.id = "inc_%02d" % _inc_counter
	inc.name = name
	inc.temperature_c = temp
	incubators.append(inc)
	return inc

func create_vial(name: String, incubator_id: String = "") -> Vial:
	_vial_counter += 1
	var v := Vial.new()
	v.id = "vial_%03d" % _vial_counter
	v.name = name
	if incubator_id == "" and not incubators.is_empty():
		incubator_id = incubators[0].id
	v.incubator_id = incubator_id
	vials.append(v)
	return v

func archive_vial(vial_id: String) -> bool:
	var v := get_vial(vial_id)
	if v == null:
		return false
	v.archived = true
	last_event = "Archived line '%s'." % v.name
	return true

## Moves a fly from one vial to another. Returns true on success.
func move_fly(fly_id: String, from_vial_id: String, to_vial_id: String) -> bool:
	var from_v := get_vial(from_vial_id)
	var to_v := get_vial(to_vial_id)
	if from_v == null or to_v == null or from_v == to_v:
		return false
	var fly := from_v.remove_fly(fly_id)
	if fly == null:
		return false
	to_v.add_fly(fly)
	last_event = "Moved %s from '%s' to '%s'." % [fly_id, from_v.name, to_v.name]
	return true

## The environment a vial's flies actually experience: the vial's settings with
## temperature supplied by its incubator.
func effective_environment(vial: Vial) -> VialEnvironment:
	var env := vial.environment.clone()
	var inc := get_incubator(vial.incubator_id)
	if inc != null:
		env.temperature_c = inc.temperature_c
	return env

## Breeds the first alive female × first alive male in `vial`, develops the
## offspring under the vial's effective environment (so incubator temperature
## matters), and places the survivors in a new vial. Returns the new vial, or
## null if the vial lacks a breeding pair.
func breed(vial: Vial, count: int = 50, seed: int = -1) -> Vial:
	var females := vial.alive_of_sex(Genome.FEMALE)
	var males := vial.alive_of_sex(Genome.MALE)
	if females.is_empty() or males.is_empty():
		last_event = "Cannot breed '%s': need at least one living female and male." % vial.name
		return null

	var env := effective_environment(vial)
	var result := InheritanceEngine.cross(females[0], males[0], count, env, seed)

	var child_vial := create_vial("F%d of %s" % [generation + 1, vial.name], vial.incubator_id)
	var survivors := 0
	for child in result.offspring:
		if child.alive:
			child_vial.add_fly(child)
			survivors += 1
	generation = maxi(generation, females[0].generation + 1)
	last_event = "Bred '%s' at %.0f°C: %d of %d offspring survived to adult." \
		% [vial.name, env.temperature_c, survivors, result.requested]
	return child_vial

# --- Save / load -------------------------------------------------------------

func to_dict() -> Dictionary:
	var vial_dicts: Array = []
	for v in vials:
		vial_dicts.append(v.to_dict())
	var inc_dicts: Array = []
	for inc in incubators:
		inc_dicts.append(inc.to_dict())
	return {
		"generation": generation,
		"vial_counter": _vial_counter,
		"inc_counter": _inc_counter,
		"incubators": inc_dicts,
		"vials": vial_dicts,
	}

func load_from_dict(d: Dictionary) -> void:
	generation = int(d.get("generation", 0))
	_vial_counter = int(d.get("vial_counter", 0))
	_inc_counter = int(d.get("inc_counter", 0))
	incubators.clear()
	for id in d.get("incubators", []):
		if id is Dictionary:
			incubators.append(Incubator.from_dict(id))
	vials.clear()
	for vd in d.get("vials", []):
		if vd is Dictionary:
			vials.append(Vial.from_dict(vd))

func save_lab() -> bool:
	var ok := SaveLoadService.save_game(SAVE_SLOT, to_dict())
	if ok:
		last_event = "Lab saved."
	return ok

func load_lab() -> bool:
	if not SaveLoadService.has_save(SAVE_SLOT):
		return false
	var env := SaveLoadService.load_game(SAVE_SLOT)
	if env.is_empty() or not env.has("data"):
		return false
	load_from_dict(env["data"])
	last_event = "Lab loaded."
	return true
