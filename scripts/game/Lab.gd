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
## Automatically recorded experiment log (spec section 17.10). Entries are
## plain dictionaries so they serialise with the save file.
var notebook: Array = []

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
	notebook.clear()
	generation = 0
	_vial_counter = 0
	_inc_counter = 0

	_create_default_incubators()
	var standard := incubators[1]  # the 25°C incubator

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

## Clears the lab and creates the standard incubators but no vials — used when a
## campaign scenario seeds its own starting vials.
func new_scenario_lab() -> void:
	vials.clear()
	incubators.clear()
	notebook.clear()
	generation = 0
	_vial_counter = 0
	_inc_counter = 0
	_create_default_incubators()

func _create_default_incubators() -> void:
	_add_incubator("Incubator (18°C)", 18.0)
	_add_incubator("Incubator (25°C)", 25.0)
	_add_incubator("Incubator (29°C)", 29.0)

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

## Strips leading "F<n> of " prefixes so an offspring vial is named after the
## original stock, e.g. "F3 of F2 of vestigial line" -> "vestigial line".
func _base_stock_name(name: String) -> String:
	var re := RegEx.new()
	re.compile("^(F\\d+ of )+")
	return re.sub(name, "")

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

	# Name the offspring vial "F<gen> of <base stock>" — strip any existing
	# "F<n> of " prefixes so the name doesn't grow without bound across breedings.
	var child_gen := females[0].generation + 1
	var base_name := _base_stock_name(vial.name)
	var child_vial := create_vial("F%d of %s" % [child_gen, base_name], vial.incubator_id)
	var survivors := 0
	for child in result.offspring:
		if child.alive:
			child_vial.add_fly(child)
			survivors += 1
	generation = maxi(generation, females[0].generation + 1)
	last_event = "Bred '%s' at %.0f°C: %d of %d offspring survived to adult." \
		% [vial.name, env.temperature_c, survivors, result.requested]

	# Automatically record the experiment in the notebook.
	notebook.append(_make_cross_entry(result, females[0], males[0], env, vial, child_vial))
	return child_vial

## Builds a notebook entry from a cross result (all JSON-serialisable).
func _make_cross_entry(result: CrossResult, mother: Fly, father: Fly,
		env: VialEnvironment, source: Vial, child: Vial) -> Dictionary:
	return {
		"kind": "cross",
		"time": Time.get_datetime_string_from_system(),
		"title": "F%d  %s  ×  %s" % [child.flies[0].generation if not child.flies.is_empty() else generation,
			_genotype_desc(mother), _genotype_desc(father)],
		"source_vial": source.name,
		"child_vial": child.name,
		"mother": "%s (%s)" % [mother.id, _genotype_desc(mother)],
		"father": "%s (%s)" % [father.id, _genotype_desc(father)],
		"count": result.requested,
		"survivors": result.survivors,
		"sex_counts": result.sex_counts.duplicate(),
		"temperature": env.temperature_c,
		"seed": result.seed_used,
		"per_gene": result.per_gene.duplicate(true),
		"phenotype_dist": result.phenotype_dist.duplicate(),
		"genotype_dist": result.genotype_dist.duplicate(),
		"explanation": result.explanation.duplicate(),
	}

## Short genotype label listing non-wild-type loci (e.g. "vg+/vg-", "wild-type").
func _genotype_desc(fly: Fly) -> String:
	var parts: Array[String] = []
	for gene: Gene in Catalog.all_genes():
		var has_mut := false
		for aid in fly.genome.genotype_at(gene.id):
			var a: Allele = Catalog.get_allele(aid)
			if a != null and not a.is_wild_type():
				has_mut = true
				break
		if has_mut:
			parts.append(gene.symbol)
	return "+".join(parts) if not parts.is_empty() else "wild-type"

## Writes the notebook to user://exports/ as both .txt and .json.
## Returns the .txt path, or "" on failure.
func export_notebook() -> String:
	var dir := "user://exports/"
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var txt_path := dir + "notebook_%s.txt" % stamp
	var json_path := dir + "notebook_%s.json" % stamp

	var jf := FileAccess.open(json_path, FileAccess.WRITE)
	if jf == null:
		return ""
	jf.store_string(JSON.stringify(notebook, "\t"))
	jf.close()

	var tf := FileAccess.open(txt_path, FileAccess.WRITE)
	if tf == null:
		return ""
	tf.store_string(_notebook_as_text())
	tf.close()
	last_event = "Exported notebook (%d entries)." % notebook.size()
	return txt_path

func _notebook_as_text() -> String:
	var lines: Array[String] = ["Drosophila Genetics Lab — notebook export", ""]
	for entry: Dictionary in notebook:
		lines.append("[%s] %s" % [entry.get("time", ""), entry.get("title", "")])
		lines.append("  %s → %s, %d offspring at %.0f°C (seed %d), %d survived."
			% [entry.get("source_vial", ""), entry.get("child_vial", ""),
				int(entry.get("count", 0)), float(entry.get("temperature", 25.0)),
				int(entry.get("seed", 0)), int(entry.get("survivors", 0))])
		for line in entry.get("explanation", []):
			lines.append("    " + String(line))
		lines.append("")
	return "\n".join(lines)

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
		"notebook": notebook.duplicate(true),
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
	notebook = d.get("notebook", []).duplicate(true)

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
