extends Control
## CrossSimulator — Phase 5 screen (spec 17.5). Choose two parents, an offspring
## count and a seed, run the cross, and read genotype/phenotype distributions and
## expected-vs-observed ratios.

const LAB_DASHBOARD_SCENE := "res://scenes/LabDashboard.tscn"
const COUNTS := [10, 100, 1000]

# Parent presets. g="" means wild-type; hom=false makes a heterozygous carrier.
const MOTHERS := [
	{"label": "Wild-type ♀", "g": "", "a": "", "hom": true},
	{"label": "vg/+ carrier ♀", "g": "vg", "a": "vg_strong_loss", "hom": false},
	{"label": "vg/vg vestigial ♀", "g": "vg", "a": "vg_strong_loss", "hom": true},
	{"label": "w/+ carrier ♀", "g": "w", "a": "w_null", "hom": false},
	{"label": "w/w white ♀", "g": "w", "a": "w_null", "hom": true},
	{"label": "bcd/+ carrier ♀", "g": "bcd", "a": "bcd_loss", "hom": false},
	{"label": "e/e ebony ♀", "g": "e", "a": "e_loss", "hom": true},
]
const FATHERS := [
	{"label": "Wild-type ♂", "g": "", "a": "", "hom": true},
	{"label": "vg/+ carrier ♂", "g": "vg", "a": "vg_strong_loss", "hom": false},
	{"label": "vg/vg vestigial ♂", "g": "vg", "a": "vg_strong_loss", "hom": true},
	{"label": "w white ♂ (hemizygous)", "g": "w", "a": "w_null", "hom": true},
	{"label": "bcd/+ carrier ♂", "g": "bcd", "a": "bcd_loss", "hom": false},
	{"label": "e/e ebony ♂", "g": "e", "a": "e_loss", "hom": true},
]

@onready var _mother_opt: OptionButton = %MotherOption
@onready var _father_opt: OptionButton = %FatherOption
@onready var _count_opt: OptionButton = %CountOption
@onready var _seed_spin: SpinBox = %SeedSpin
@onready var _out: RichTextLabel = %Output
@onready var _chart: ChartView = %CrossChart
@onready var _gallery: HBoxContainer = %FlyGallery

func _ready() -> void:
	if not Catalog.is_ready():
		_out.text = "Catalog not loaded — check data/*.json."
		return
	for m in MOTHERS:
		_mother_opt.add_item(m["label"])
	for f in FATHERS:
		_father_opt.add_item(f["label"])
	# The 1000-offspring option requires the high-throughput crosser upgrade.
	for c in COUNTS:
		if c >= 1000 and not Economy.is_unlocked("large_cross"):
			continue
		_count_opt.add_item("%d offspring" % c)
	# Default to the classic monohybrid cross (vg/+ × vg/+, 100 offspring).
	_mother_opt.select(1)
	_father_opt.select(1)
	_count_opt.select(1)
	_seed_spin.value = 12345
	_run()

func _on_randomize_pressed() -> void:
	_seed_spin.value = randi() % 1000000
	_run()

func _on_run_pressed() -> void:
	_run()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(LAB_DASHBOARD_SCENE)

func _build(recipe: Dictionary, sex: String) -> Fly:
	if recipe["g"] == "":
		return FlyFactory.create_wild_type(sex)
	var z := FlyFactory.Zygosity.HOMOZYGOUS if recipe["hom"] else FlyFactory.Zygosity.HETEROZYGOUS
	return FlyFactory.create_mutant(recipe["g"], recipe["a"], z, sex)

func _run() -> void:
	var mother := _build(MOTHERS[_mother_opt.get_selected()], Genome.FEMALE)
	var father := _build(FATHERS[_father_opt.get_selected()], Genome.MALE)
	var count: int = COUNTS[_count_opt.get_selected()]
	var seed := int(_seed_spin.value)

	var result := InheritanceEngine.cross(mother, father, count, VialEnvironment.standard(), seed)
	_render(result)

func _render(r: CrossResult) -> void:
	_render_chart(r)
	_render_gallery(r)
	var lines: Array[String] = []
	lines.append("[b]%s  ×  %s[/b]" % [MOTHERS[_mother_opt.get_selected()]["label"], FATHERS[_father_opt.get_selected()]["label"]])
	lines.append("Offspring: %d   Survivors: %d (%.0f%%)   Sex ♀%d : ♂%d   Seed: %d"
		% [r.requested, r.survivors, r.survival_rate() * 100.0,
			r.sex_counts["female"], r.sex_counts["male"], r.seed_used])
	lines.append("")

	# Expected vs observed per segregating gene.
	if r.per_gene.is_empty():
		lines.append("[i]No genes segregate between these parents — every offspring matches the parents.[/i]")
	for entry: Dictionary in r.per_gene:
		lines.append("[b]%s (%s)[/b] — %s" % [entry["gene"], entry["symbol"], entry["scope"]])
		lines.append("  [u]%-26s %9s %9s %9s[/u]" % ["genotype class", "expected", "observed", "survival"])
		for c: Dictionary in entry["classes"]:
			lines.append("  %-26s %8.0f%% %8.0f%% %8.0f%%"
				% [c["label"], c["expected"] * 100.0, c["observed_frac"] * 100.0, c["survival"] * 100.0])
		lines.append("")

	# Phenotype distribution among survivors.
	lines.append("[b]Adult phenotype distribution[/b] (survivors)")
	if r.phenotype_dist.is_empty():
		lines.append("  (no survivors)")
	else:
		for key in _sorted_by_count(r.phenotype_dist):
			lines.append("  %-40s %4d  (%.0f%%)"
				% [key, r.phenotype_dist[key], float(r.phenotype_dist[key]) / float(max(r.survivors, 1)) * 100.0])
	lines.append("")

	# Multilocus genotype distribution.
	lines.append("[b]Genotype distribution[/b] (all offspring)")
	for key in _sorted_by_count(r.genotype_dist):
		lines.append("  %-40s %4d  (%.0f%%)"
			% [key, r.genotype_dist[key], float(r.genotype_dist[key]) / float(max(r.requested, 1)) * 100.0])
	lines.append("")

	lines.append("[b]Explanation[/b]")
	for line in r.explanation:
		lines.append("  " + line)

	_out.text = "\n".join(lines)

## Draws one representative surviving fly per visible phenotype class, so the
## player sees the actual flies the cross produced (not just numbers).
func _render_gallery(r: CrossResult) -> void:
	for child in _gallery.get_children():
		child.queue_free()

	# Group survivors by their visible phenotype class; keep a representative + count.
	var reps := {}      # class label -> Fly
	var counts := {}    # class label -> int
	for child: Fly in r.offspring:
		if not child.alive:
			continue
		var dims := StatisticsEngine.visible_dims(child)
		var key := "%s, %s, %s, %s" % [child.sex(), dims["eye"], dims["wing"], dims["body"]]
		counts[key] = int(counts.get(key, 0)) + 1
		if not reps.has(key):
			reps[key] = child

	# Most common classes first, cap to keep the strip tidy.
	var keys: Array = reps.keys()
	keys.sort_custom(func(a, b): return int(counts[a]) > int(counts[b]))
	for i in mini(keys.size(), 8):
		var key: String = keys[i]
		_gallery.add_child(_fly_card(reps[key], "%d×  %s" % [counts[key], key]))

	if keys.is_empty():
		var none := Label.new()
		none.text = "  (no surviving offspring to show)"
		_gallery.add_child(none)

## A small card: a drawn fly above a caption.
func _fly_card(fly: Fly, caption: String) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(150, 0)
	var renderer := FlyRenderer.new()
	renderer.custom_minimum_size = Vector2(150, 150)
	renderer.set_fly(fly)
	box.add_child(renderer)
	var label := Label.new()
	label.text = caption
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(150, 0)
	label.add_theme_font_size_override("font_size", 11)
	box.add_child(label)
	return box

## Expected-vs-observed grouped bars for the first segregating gene.
func _render_chart(r: CrossResult) -> void:
	if r.per_gene.is_empty():
		_chart.set_bars([], [], tr("No segregating genes"))
		return
	var entry: Dictionary = r.per_gene[0]
	var cats: Array = []
	var expected: Array = []
	var observed: Array = []
	for c: Dictionary in entry["classes"]:
		var label := String(c["label"])
		var sep := label.find(": ")
		if sep >= 0:
			label = label.substr(sep + 2)
		cats.append(label)
		expected.append(float(c["expected"]) * 100.0)
		observed.append(float(c["observed_frac"]) * 100.0)
	_chart.set_bars(cats, [
		{"name": "expected", "values": expected},
		{"name": "observed", "values": observed},
	], "%s — %% expected vs observed" % entry["symbol"], 0.0, "%")

func _sorted_by_count(dict: Dictionary) -> Array:
	var keys: Array = dict.keys()
	keys.sort_custom(func(a, b): return int(dict[a]) > int(dict[b]))
	return keys
