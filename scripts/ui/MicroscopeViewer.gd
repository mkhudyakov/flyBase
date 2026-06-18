extends Control
## MicroscopeViewer — Phase 3 screen (spec 17.7). Builds a fly, computes its
## phenotype, and draws it with the FlyRenderer so trait changes are visible.
##
## Mirrors the Phenotype Viewer's fly set so the same genotypes can be compared
## visually here and numerically there.

const LAB_DASHBOARD_SCENE := "res://scenes/LabDashboard.tscn"

@onready var _renderer: FlyRenderer = %FlyRenderer
@onready var _title: Label = %FlyTitle
@onready var _caption: RichTextLabel = %Caption

var _current_fly: Fly

func _ready() -> void:
	if not Catalog.is_ready() or Catalog.trait_count() == 0:
		_title.text = "Catalog/traits not loaded — check data/*.json."
		return
	# If the dashboard handed us a specific fly to inspect, show that instead.
	if Lab.pending_inspect != null:
		var fly := Lab.pending_inspect
		Lab.pending_inspect = null
		_current_fly = fly
		_title.text = "Inspecting %s (%s)" % [fly.id, fly.sex()]
		_renderer.set_fly(fly)
		_update_caption(fly)
		return
	_show(FlyFactory.create_wild_type(Genome.FEMALE), "Wild-type female")

func _on_wild_female_pressed() -> void:
	_show(FlyFactory.create_wild_type(Genome.FEMALE), "Wild-type female")

func _on_white_male_pressed() -> void:
	_show(FlyFactory.create_mutant("w", "w_null", FlyFactory.Zygosity.HOMOZYGOUS, Genome.MALE),
		"white-eyed male")

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
		PhenotypeEngine.compute(_current_fly)
		_renderer.set_fly(_current_fly)
		_update_caption(_current_fly)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(LAB_DASHBOARD_SCENE)

func _show(fly: Fly, title: String) -> void:
	_current_fly = fly
	PhenotypeEngine.compute(fly)
	_title.text = "%s   (id %s, %s)" % [title, fly.id, fly.sex()]
	_renderer.set_fly(fly)
	_update_caption(fly)

## A compact caption of the visible traits that drive the drawing.
func _update_caption(fly: Fly) -> void:
	var p := fly.phenotype
	var parts := [
		"eye_color %.2f" % p.get_trait("eye_color", 1.0),
		"eye_size %.2f" % p.get_trait("eye_size", 1.0),
		"wing_size %.2f" % p.get_trait("wing_size", 1.0),
		"wing_shape %.2f" % p.get_trait("wing_shape", 1.0),
		"body_color %.2f" % p.get_trait("body_color", 0.5),
		"body_size %.2f" % p.get_trait("body_size", 1.0),
	]
	_caption.text = "[i]Drawn from phenotype:[/i] " + "   ".join(parts)
