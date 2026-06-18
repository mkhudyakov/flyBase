extends Control
## LabDashboard — the central lab screen (spec section 17.2). Manages vials,
## incubators, fly selection, breeding, moving flies, and archiving, all backed
## by the Lab singleton. Analysis tools (genome, phenotype, microscope, cross,
## development) are reachable from the Tools row.

const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"

const TOOL_SCENES := {
	"genotype": "res://scenes/GenotypeDebug.tscn",
	"phenotype": "res://scenes/PhenotypeViewer.tscn",
	"microscope": "res://scenes/MicroscopeViewer.tscn",
	"development": "res://scenes/DevelopmentTimeline.tscn",
	"cross": "res://scenes/CrossSimulator.tscn",
	"statistics": "res://scenes/StatisticsScreen.tscn",
	"notebook": "res://scenes/NotebookScreen.tscn",
	"campaign": "res://scenes/CampaignScreen.tscn",
	"population": "res://scenes/PopulationScreen.tscn",
}

@onready var _stats: Label = %LabStats
@onready var _event: Label = %LastEvent
@onready var _vial_list: ItemList = %VialList
@onready var _vial_name: Label = %VialNameLabel
@onready var _vial_summary: RichTextLabel = %VialSummary
@onready var _incubator_option: OptionButton = %IncubatorOption
@onready var _fly_list: ItemList = %FlyList
@onready var _move_target: OptionButton = %MoveTargetOption
@onready var _inc_list: ItemList = %IncubatorList
@onready var _inc_temp_slider: HSlider = %IncTempSlider
@onready var _inc_temp_label: Label = %IncTempLabel

var _selected_vial_id := ""
var _selected_fly_id := ""
var _selected_inc_id := ""

var _vial_ids: Array[String] = []     # vial-list index → id
var _inc_ids: Array[String] = []      # incubator list / option index → id
var _fly_ids: Array[String] = []      # fly-list index → id
var _move_ids: Array[String] = []     # move-target option index → id

func _ready() -> void:
	_inc_temp_slider.value_changed.connect(_on_inc_temp_changed)
	var actives := Lab.active_vials()
	if not actives.is_empty():
		_selected_vial_id = actives[0].id
	if not Lab.incubators.is_empty():
		_selected_inc_id = Lab.incubators[0].id
	_refresh_all()

# --- Refresh -----------------------------------------------------------------

func _refresh_all() -> void:
	_refresh_vials()
	_refresh_incubators()
	_refresh_detail()
	_refresh_stats()

func _refresh_stats() -> void:
	_stats.text = "Generation %d   •   %d vials   •   %d flies" \
		% [Lab.generation, Lab.active_vials().size(), Lab.total_flies()]
	_event.text = Lab.last_event

func _refresh_vials() -> void:
	_vial_list.clear()
	_vial_ids.clear()
	for v in Lab.active_vials():
		var inc := Lab.get_incubator(v.incubator_id)
		var temp := "%.0f°C" % inc.temperature_c if inc != null else "—"
		_vial_list.add_item("%s   [%s]" % [v.summary_line(), temp])
		_vial_ids.append(v.id)
		if v.id == _selected_vial_id:
			_vial_list.select(_vial_ids.size() - 1)

func _refresh_incubators() -> void:
	_inc_list.clear()
	_inc_ids.clear()
	for inc in Lab.incubators:
		_inc_list.add_item("%s — %.0f°C" % [inc.name, inc.temperature_c])
		_inc_ids.append(inc.id)
		if inc.id == _selected_inc_id:
			_inc_list.select(_inc_ids.size() - 1)
	var inc := Lab.get_incubator(_selected_inc_id)
	if inc != null:
		_inc_temp_slider.set_value_no_signal(inc.temperature_c)
		_inc_temp_label.text = "%s: %.0f °C" % [inc.name, inc.temperature_c]

func _refresh_detail() -> void:
	var v := Lab.get_vial(_selected_vial_id)
	if v == null:
		_vial_name.text = "No vial selected"
		_vial_summary.text = ""
		_fly_list.clear()
		_fly_ids.clear()
		return

	_vial_name.text = v.name
	var c := v.sex_counts()
	_vial_summary.text = "[b]%d flies[/b] — ♀%d ♂%d, %d alive\nGenes segregating shown per fly below." \
		% [v.population(), c["female"], c["male"], v.alive_count()]

	# Incubator assignment dropdown.
	_incubator_option.clear()
	for i in Lab.incubators.size():
		var inc: Incubator = Lab.incubators[i]
		_incubator_option.add_item("%s (%.0f°C)" % [inc.name, inc.temperature_c])
		if inc.id == v.incubator_id:
			_incubator_option.select(i)

	# Fly list.
	_fly_list.clear()
	_fly_ids.clear()
	for f in v.flies:
		_fly_list.add_item(_fly_label(f))
		_fly_ids.append(f.id)
		if f.id == _selected_fly_id:
			_fly_list.select(_fly_ids.size() - 1)

	# Move-target dropdown: other active vials.
	_move_target.clear()
	_move_ids.clear()
	for other in Lab.active_vials():
		if other.id == v.id:
			continue
		_move_target.add_item(other.name)
		_move_ids.append(other.id)

func _fly_label(f: Fly) -> String:
	var status := "" if f.alive else "  ✗dead"
	var marks: Array[String] = []
	# Note any non-wild-type locus so carriers/mutants are visible at a glance.
	for gene: Gene in Catalog.all_genes():
		for aid in f.genome.genotype_at(gene.id):
			var a: Allele = Catalog.get_allele(aid)
			if a != null and not a.is_wild_type():
				marks.append(gene.symbol)
				break
	var geno := (" {" + ",".join(marks) + "}") if not marks.is_empty() else " wild-type"
	return "%s  %s%s%s" % [f.id, f.sex(), geno, status]

# --- Vial actions ------------------------------------------------------------

func _on_vial_list_item_selected(idx: int) -> void:
	_selected_vial_id = _vial_ids[idx]
	_selected_fly_id = ""
	_refresh_detail()

func _on_fly_list_item_selected(idx: int) -> void:
	_selected_fly_id = _fly_ids[idx]

func _on_new_vial_pressed() -> void:
	var inc_id: String = _selected_inc_id if _selected_inc_id != "" else ""
	var v := Lab.create_vial("New vial", inc_id)
	_selected_vial_id = v.id
	Lab.last_event = "Created vial '%s'." % v.name
	_refresh_all()

func _on_archive_pressed() -> void:
	if _selected_vial_id == "":
		return
	Lab.archive_vial(_selected_vial_id)
	var actives := Lab.active_vials()
	_selected_vial_id = actives[0].id if not actives.is_empty() else ""
	_refresh_all()

func _on_incubator_option_item_selected(idx: int) -> void:
	var v := Lab.get_vial(_selected_vial_id)
	if v != null and idx < Lab.incubators.size():
		v.incubator_id = Lab.incubators[idx].id
		Lab.last_event = "Moved '%s' to %s." % [v.name, Lab.incubators[idx].name]
		_refresh_all()

func _on_breed_pressed() -> void:
	var v := Lab.get_vial(_selected_vial_id)
	if v == null:
		return
	var child := Lab.breed(v, 50)
	if child != null:
		_selected_vial_id = child.id
		_selected_fly_id = ""
	_refresh_all()

func _on_move_pressed() -> void:
	if _selected_fly_id == "" or _move_target.item_count == 0:
		return
	var target_id: String = _move_ids[_move_target.get_selected()]
	if Lab.move_fly(_selected_fly_id, _selected_vial_id, target_id):
		_selected_fly_id = ""
		_refresh_all()

func _on_inspect_pressed() -> void:
	var v := Lab.get_vial(_selected_vial_id)
	if v == null or _selected_fly_id == "":
		return
	var fly := v.find_fly(_selected_fly_id)
	if fly != null:
		Lab.pending_inspect = fly
		get_tree().change_scene_to_file(TOOL_SCENES["microscope"])

# --- Incubator actions -------------------------------------------------------

func _on_incubator_list_item_selected(idx: int) -> void:
	_selected_inc_id = _inc_ids[idx]
	_refresh_incubators()

func _on_inc_temp_changed(value: float) -> void:
	var inc := Lab.get_incubator(_selected_inc_id)
	if inc != null:
		inc.temperature_c = value
		_inc_temp_label.text = "%s: %.0f °C" % [inc.name, value]
		_refresh_vials()
		_refresh_detail()

# --- Save / load / tools / nav ----------------------------------------------

func _on_save_pressed() -> void:
	Lab.save_lab()
	_refresh_stats()

func _on_load_pressed() -> void:
	if Lab.load_lab():
		var actives := Lab.active_vials()
		_selected_vial_id = actives[0].id if not actives.is_empty() else ""
		_selected_fly_id = ""
		_refresh_all()

func _on_tool_genotype_pressed() -> void: _open("genotype")
func _on_tool_phenotype_pressed() -> void: _open("phenotype")
func _on_tool_microscope_pressed() -> void: _open("microscope")
func _on_tool_development_pressed() -> void: _open("development")
func _on_tool_cross_pressed() -> void: _open("cross")
func _on_tool_statistics_pressed() -> void: _open("statistics")
func _on_tool_notebook_pressed() -> void: _open("notebook")
func _on_tool_campaign_pressed() -> void: _open("campaign")
func _on_tool_population_pressed() -> void: _open("population")

func _open(key: String) -> void:
	get_tree().change_scene_to_file(TOOL_SCENES[key])

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
