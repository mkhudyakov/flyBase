extends Control
## PhenotypeViewer — Phase 2 panel: builds a fly, runs the PhenotypeEngine, and
## shows the resulting traits plus the explanation log.
##
## Re-clicking a build recomputes with a fresh roll, which is a deliberate way to
## see penetrance/expressivity variation (e.g. a 95%-penetrant allele occasionally
## not showing). The genome never changes — only how it is expressed.

const LAB_DASHBOARD_SCENE := "res://scenes/LabDashboard.tscn"

@onready var _traits_out: RichTextLabel = %TraitsOut
@onready var _explain_out: RichTextLabel = %ExplainOut
@onready var _title: Label = %FlyTitle

var _current_fly: Fly

func _ready() -> void:
	if not Catalog.is_ready() or Catalog.trait_count() == 0:
		_title.text = "Catalog/traits not loaded — check data/*.json."
		return
	_show(FlyFactory.create_wild_type(Genome.FEMALE), "Wild-type female")

func _on_wild_female_pressed() -> void:
	_show(FlyFactory.create_wild_type(Genome.FEMALE), "Wild-type female")

func _on_white_male_pressed() -> void:
	_show(FlyFactory.create_mutant("w", "w_null", FlyFactory.Zygosity.HOMOZYGOUS, Genome.MALE),
		"white-eyed male (X-linked)")

func _on_vestigial_pressed() -> void:
	_show(FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE),
		"vestigial homozygous female")

func _on_yellow_pressed() -> void:
	_show(FlyFactory.create_mutant("y", "y_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE),
		"yellow homozygous female")

func _on_ebony_pressed() -> void:
	_show(FlyFactory.create_mutant("e", "e_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE),
		"ebony homozygous female")

func _on_antp_pressed() -> void:
	_show(FlyFactory.create_mutant("Antp", "Antp_dom_gof", FlyFactory.Zygosity.HETEROZYGOUS, Genome.FEMALE),
		"Antennapedia dominant (het) female")

func _on_recompute_pressed() -> void:
	if _current_fly != null:
		_render(_current_fly)  # fresh rolls on the same genome

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(LAB_DASHBOARD_SCENE)

func _show(fly: Fly, title: String) -> void:
	_current_fly = fly
	_title.text = "%s   (id %s, %s)" % [title, fly.id, fly.sex()]
	_render(fly)

func _render(fly: Fly) -> void:
	PhenotypeEngine.compute(fly)

	var current_category := ""
	var lines: Array[String] = []
	for tr: TraitRule in Catalog.all_traits():
		if tr.category != current_category:
			current_category = tr.category
			lines.append("[b]%s traits[/b]" % current_category.capitalize())
		var value: float = fly.phenotype.get_trait(tr.id)
		var normal := tr.is_within_normal(value)
		var bar := _bar(value, tr.min_value, tr.max_value)
		var text := "  %-22s %s %5.2f" % [tr.label, bar, value]
		if not normal:
			text = "[color=#e6b85c]%s  ◀ abnormal (normal %.2f–%.2f)[/color]" \
				% [text, tr.normal_min, tr.normal_max]
		lines.append(text)
	_traits_out.text = "\n".join(lines)

	_explain_out.text = "\n".join(fly.phenotype.explanation)

## A tiny text gauge so trait magnitudes are readable at a glance.
func _bar(value: float, lo: float, hi: float) -> String:
	var span := maxf(hi - lo, 0.0001)
	var filled := clampi(roundi((value - lo) / span * 10.0), 0, 10)
	return "[" + "█".repeat(filled) + "·".repeat(10 - filled) + "]"
