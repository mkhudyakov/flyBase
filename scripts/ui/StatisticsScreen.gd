extends Control
## StatisticsScreen — Phase 7 (spec 17.8). Shows distributions and trait
## histograms for a chosen vial's flies, using the StatisticsEngine.

const LAB_DASHBOARD_SCENE := "res://scenes/LabDashboard.tscn"
const HIST_TRAITS := ["body_size", "flight_ability", "lifespan_days", "wing_size", "viability_score"]

@onready var _vial_opt: OptionButton = %VialOption
@onready var _trait_opt: OptionButton = %TraitOption
@onready var _out: RichTextLabel = %Output

var _vial_ids: Array[String] = []

func _ready() -> void:
	for v in Lab.active_vials():
		_vial_opt.add_item("%s (%d)" % [v.name, v.population()])
		_vial_ids.append(v.id)
	for t in HIST_TRAITS:
		var tr: TraitRule = Catalog.get_trait_rule(t)
		_trait_opt.add_item(tr.label if tr != null else t)
	if _vial_ids.is_empty():
		_out.text = "No vials. Breed some flies first."
		return
	_vial_opt.select(0)
	_trait_opt.select(0)
	_render()

func _on_vial_option_item_selected(_i: int) -> void: _render()
func _on_trait_option_item_selected(_i: int) -> void: _render()
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(LAB_DASHBOARD_SCENE)

func _render() -> void:
	if _vial_ids.is_empty():
		return
	var vial := Lab.get_vial(_vial_ids[_vial_opt.get_selected()])
	if vial == null:
		return
	var flies := vial.flies

	var lines: Array[String] = []
	lines.append("[b]%s[/b]" % vial.name)

	var s := StatisticsEngine.summarize(flies)
	lines.append("Population %d — ♀%d ♂%d.  Survivors %d (♀%d ♂%d)."
		% [s["count"], s["female"], s["male"], s["alive"], s["female_alive"], s["male_alive"]])
	lines.append("")

	# Phenotype distribution (survivors).
	lines.append("[b]Phenotype distribution[/b] (survivors)")
	var dist := StatisticsEngine.phenotype_distribution(flies, true)
	if dist.is_empty():
		lines.append("  (no survivors)")
	else:
		var keys: Array = dist.keys()
		keys.sort_custom(func(a, b): return int(dist[a]) > int(dist[b]))
		for k in keys:
			lines.append("  %-40s %s %4d (%.0f%%)"
				% [k, _bar(float(dist[k]) / float(maxi(s["alive"], 1)), 16), dist[k],
					float(dist[k]) / float(maxi(s["alive"], 1)) * 100.0])
	lines.append("")

	# Trait histogram.
	var trait_id: String = HIST_TRAITS[_trait_opt.get_selected()]
	var hist := StatisticsEngine.trait_histogram(flies, trait_id, 10, true)
	lines.append("[b]Histogram: %s[/b]  (n=%d, mean %.2f, range %.0f–%.0f)"
		% [hist["label"], hist["n"], hist["mean"], hist["min"], hist["max"]])
	var maxc := 1
	for b: Dictionary in hist["bins"]:
		maxc = maxi(maxc, b["count"])
	for b: Dictionary in hist["bins"]:
		var frac := float(b["count"]) / float(maxc)
		lines.append("  %5.1f–%5.1f %s %3d" % [b["lo"], b["hi"], _bar(frac, 24), b["count"]])

	_out.text = "\n".join(lines)

func _bar(frac: float, width: int) -> String:
	var filled := clampi(roundi(frac * width), 0, width)
	return "[" + "█".repeat(filled) + "·".repeat(width - filled) + "]"
