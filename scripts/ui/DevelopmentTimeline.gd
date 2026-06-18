extends Control
## DevelopmentTimeline — Phase 4 screen (spec 17.6). Runs the DevelopmentEngine
## on a chosen fly under adjustable environment settings and shows the stage-by-
## stage progression, failure outcomes, and explanation.

const LAB_DASHBOARD_SCENE := "res://scenes/LabDashboard.tscn"

@onready var _out: RichTextLabel = %Output
@onready var _temp_slider: HSlider = %TempSlider
@onready var _temp_label: Label = %TempLabel
@onready var _low_food: CheckBox = %LowFood
@onready var _crowded: CheckBox = %Crowded

# Currently selected fly recipe: [gene, allele, zygosity, sex]. Empty gene = wild.
var _recipe := ["", "", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE]
var _title := "Wild-type female"

func _ready() -> void:
	if not Catalog.is_ready():
		_out.text = "Catalog not loaded — check data/*.json."
		return
	_temp_slider.value_changed.connect(_on_temp_changed)
	_on_temp_changed(_temp_slider.value)
	_run()

# --- Fly selection -----------------------------------------------------------

func _on_wild_pressed() -> void:
	_recipe = ["", "", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE]
	_title = "Wild-type female"
	_run()

func _on_vestigial_pressed() -> void:
	_recipe = ["vg", "vg_strong_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE]
	_title = "vestigial homozygous (wing development)"
	_run()

func _on_wingless_pressed() -> void:
	_recipe = ["wg", "wg_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE]
	_title = "wingless homozygous (severe developmental)"
	_run()

func _on_bicoid_pressed() -> void:
	_recipe = ["bcd", "bcd_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE]
	_title = "bicoid homozygous (axis patterning)"
	_run()

func _on_temp_changed(value: float) -> void:
	_temp_label.text = "Temperature: %.0f °C" % value

func _on_run_pressed() -> void:
	_run()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(LAB_DASHBOARD_SCENE)

# --- Run + render ------------------------------------------------------------

func _build_fly() -> Fly:
	if _recipe[0] == "":
		return FlyFactory.create_wild_type(_recipe[3])
	return FlyFactory.create_mutant(_recipe[0], _recipe[1], _recipe[2], _recipe[3])

func _build_env() -> VialEnvironment:
	var env := VialEnvironment.standard()
	env.temperature_c = _temp_slider.value
	if _low_food.button_pressed:
		env.food_quantity = 0.5
	if _crowded.button_pressed:
		env.crowding = 0.7
	return env

func _run() -> void:
	var fly := _build_fly()
	var env := _build_env()
	var result := DevelopmentEngine.simulate(fly, env)

	var lines: Array[String] = []
	lines.append("[b]%s[/b]" % _title)
	lines.append("")
	lines.append("[b]Stage timeline[/b]  (cumulative %.1f days)" % result.total_days)
	for log: Dictionary in result.stage_logs:
		var ok: bool = log["status"] == "ok"
		var marker := "ok" if ok else "FAILED"
		var bar := _stress_bar(float(log["stress"]))
		var line := "  %-16s  %4.1fd  stress %s  %s" \
			% [log["display_name"], float(log["duration"]), bar, marker]
		if not ok:
			line += "  [%s]" % log["note"]
			line = "[color=#e06c6c]%s[/color]" % line
		else:
			line = "[color=#8fd6a0]%s[/color]" % line
		lines.append(line)

	lines.append("")
	var head_col := "#8fd6a0" if result.reached_adult else "#e06c6c"
	lines.append("[color=%s][b]Outcome: %s[/b][/color]" % [head_col, result.outcome])
	lines.append("")
	lines.append("[b]Explanation[/b]")
	for line in result.explanation:
		lines.append("  " + line)

	_out.text = "\n".join(lines)

func _stress_bar(stress: float) -> String:
	var filled := clampi(roundi(stress / 2.0 * 8.0), 0, 8)
	return "[" + "█".repeat(filled) + "·".repeat(8 - filled) + "]"
