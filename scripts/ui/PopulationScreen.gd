extends Control
## PopulationScreen — Phase 10 (spec §10, §17.8). Configure and run a
## multi-generation population experiment, then read generational trends,
## allele-frequency change, and the line-stability score.

const LAB_DASHBOARD_SCENE := "res://scenes/LabDashboard.tscn"

# Founder presets: how to build the starting population + which genes to track.
const FOUNDERS := [
	{"label": "Vestigial carriers (vg/+)", "kind": "vg_carrier", "track": ["vg"]},
	{"label": "Polygenic size (large variants)", "kind": "size", "track": ["size_a", "size_b", "size_c"]},
	{"label": "Wild-type stock", "kind": "wild", "track": []},
]
const SELECTIONS := [
	{"label": "No selection", "sel": null},
	{"label": "Select vestigial wings", "sel": {"predicate": {"trait": "wing_size", "op": "lt", "value": 0.4}, "mode": "keep"}},
	{"label": "Select large body", "sel": {"predicate": {"trait": "body_size", "op": "ge", "value": 1.1}, "mode": "keep"}},
	{"label": "Cull vestigial (purge)", "sel": {"predicate": {"trait": "wing_size", "op": "lt", "value": 0.4}, "mode": "cull"}},
]
const GENERATION_OPTS := [10, 15, 20]

@onready var _founder_opt: OptionButton = %FounderOption
@onready var _selection_opt: OptionButton = %SelectionOption
@onready var _gen_opt: OptionButton = %GenOption
@onready var _temp_slider: HSlider = %TempSlider
@onready var _temp_label: Label = %TempLabel
@onready var _bottleneck: CheckBox = %Bottleneck
@onready var _out: RichTextLabel = %Output

func _ready() -> void:
	for f in FOUNDERS:
		_founder_opt.add_item(f["label"])
	for s in SELECTIONS:
		_selection_opt.add_item(s["label"])
	# 20-generation runs require the long-term culture chamber upgrade.
	for g in GENERATION_OPTS:
		if g >= 20 and not Economy.is_unlocked("long_term_culture"):
			continue
		_gen_opt.add_item("%d generations" % g)
	_temp_slider.value_changed.connect(func(v): _temp_label.text = tr("Temperature: %.0f °C") % v)
	_founder_opt.select(0)
	_selection_opt.select(1)
	_gen_opt.select(0)
	_temp_slider.value = 25.0
	_temp_label.text = tr("Temperature: %.0f °C") % 25.0
	_out.text = "Configure a population experiment and press Run."

func _on_run_pressed() -> void:
	_run()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(LAB_DASHBOARD_SCENE)

func _build_founders(kind: String) -> Array:
	var founders: Array = []
	var build := VialEnvironment.standard()  # founders are reared benignly
	for i in 30:
		var sex := Genome.FEMALE if i % 2 == 0 else Genome.MALE
		var fly: Fly
		match kind:
			"vg_carrier":
				fly = FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HETEROZYGOUS, sex)
			"size":
				fly = FlyFactory.create_multi([
					{"gene": "size_a", "allele": "size_a_large", "zyg": "het"},
					{"gene": "size_b", "allele": "size_b_large", "zyg": "het"},
					{"gene": "size_c", "allele": "size_c_large", "zyg": "het"}], sex)
			_:
				fly = FlyFactory.create_wild_type(sex)
		DevelopmentEngine.simulate(fly, build)
		founders.append(fly)
	return founders

func _run() -> void:
	var founder_spec: Dictionary = FOUNDERS[_founder_opt.get_selected()]
	var env := VialEnvironment.standard()
	env.temperature_c = _temp_slider.value
	var config := {
		"generations": GENERATION_OPTS[_gen_opt.get_selected()],
		"seed": 12345,
		"env": env,
		"track_genes": founder_spec["track"],
		"selection": SELECTIONS[_selection_opt.get_selected()]["sel"],
	}
	if _bottleneck.button_pressed:
		config["bottleneck"] = {"at_gen": 4, "size": 8}

	var res := PopulationEngine.simulate(_build_founders(founder_spec["kind"]), config)
	_render(res, founder_spec["track"])

func _render(res: PopulationResult, track: Array) -> void:
	var lines: Array[String] = []
	var track_gene := String(track[0]) if not track.is_empty() else ""

	lines.append("[b]Generational trend[/b]")
	var header := "  gen   pop  surv%%  meanBody  meanFlight  %%vestigial"
	if track_gene != "":
		header += "  %s-freq" % track_gene
	lines.append("[u]%s[/u]" % header)

	var pop_series: Array[float] = []
	for gd: Dictionary in res.generations:
		pop_series.append(float(gd["population"]))
		var means: Dictionary = gd["means"]
		var line := "  %3d  %4d  %4.0f  %7.2f  %9.2f  %9.0f%%" % [
			int(gd["gen"]), int(gd["population"]), float(gd["survival_rate"]) * 100.0,
			float(means["body_size"]), float(means["flight_ability"]), float(gd["vestigial_frac"]) * 100.0]
		if track_gene != "":
			line += "  %7s" % _freq_text(gd, track_gene)
		lines.append(line)

	lines.append("")
	lines.append("Population: %s" % _sparkline(pop_series))
	if track_gene != "":
		lines.append("%s allele freq: %s" % [track_gene, _freq_sparkline(res, track_gene)])
	lines.append("")

	var head_col := "#e06c6c" if res.extinct else "#8fd6a0"
	lines.append("[color=%s][b]%s[/b][/color]" % [head_col,
		"Line went EXTINCT at generation %d." % res.completed_generations if res.extinct
		else "Line survived all %d generations." % res.completed_generations])
	lines.append("[b]Line stability:[/b] %.2f" % res.line_stability)
	lines.append("")
	lines.append("[b]Explanation[/b]")
	for line in res.explanation:
		lines.append("  " + line)

	_out.text = "\n".join(lines)

## Frequency of the most common non-wild allele at a tracked gene, as text.
func _freq_text(gd: Dictionary, gene_id: String) -> String:
	var af: Dictionary = gd.get("allele_freq", {}).get(gene_id, {})
	var best := 0.0
	for aid: String in af.keys():
		var a: Allele = Catalog.get_allele(aid)
		if a != null and not a.is_wild_type():
			best = maxf(best, float(af[aid]))
	return "%.0f%%" % (best * 100.0)

func _freq_sparkline(res: PopulationResult, gene_id: String) -> String:
	var series: Array[float] = []
	for gd: Dictionary in res.generations:
		var af: Dictionary = gd.get("allele_freq", {}).get(gene_id, {})
		var best := 0.0
		for aid: String in af.keys():
			var a: Allele = Catalog.get_allele(aid)
			if a != null and not a.is_wild_type():
				best = maxf(best, float(af[aid]))
		series.append(best)
	return _sparkline_fixed(series, 0.0, 1.0)

func _sparkline(series: Array) -> String:
	var hi := 0.0
	for v in series:
		hi = maxf(hi, v)
	return _sparkline_fixed(series, 0.0, maxf(hi, 1.0))

func _sparkline_fixed(series: Array, lo: float, hi: float) -> String:
	const BARS := "▁▂▃▄▅▆▇█"
	var span := maxf(hi - lo, 0.0001)
	var s := ""
	for v in series:
		var idx := clampi(int((float(v) - lo) / span * 7.0), 0, 7)
		s += BARS[idx]
	return s
