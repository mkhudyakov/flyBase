extends Control
## LabDashboard (placeholder)
##
## Phase 0 placeholder for the central lab screen (spec 17.2). It does not yet
## show vials, incubators, or a selected fly. Instead it doubles as a quick
## self-check that the core services are alive: it reports loaded data files,
## the current RNG seed, and exercises the save/load shell.

const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"
const GENOTYPE_DEBUG_SCENE := "res://scenes/GenotypeDebug.tscn"
const PHENOTYPE_VIEWER_SCENE := "res://scenes/PhenotypeViewer.tscn"
const MICROSCOPE_SCENE := "res://scenes/MicroscopeViewer.tscn"
const DEVELOPMENT_SCENE := "res://scenes/DevelopmentTimeline.tscn"

@onready var _info_label: RichTextLabel = %InfoLabel

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	var loaded: Array = DataLoader.loaded_keys()
	var loaded_text := "none yet (data files are added in Phase 1)" \
		if loaded.is_empty() else ", ".join(loaded)

	var lines := [
		"[b]Lab Dashboard[/b] (Phase 0 placeholder)",
		"",
		"This screen becomes the real lab in Phase 6. For now it verifies the",
		"core services from Phase 0 are running:",
		"",
		"[b]DataLoader[/b] — loaded data: %s" % loaded_text,
		"[b]Catalog[/b] — %d genes, %d alleles, %d traits parsed" % [Catalog.gene_count(), Catalog.allele_count(), Catalog.trait_count()],
		"[b]RandomService[/b] — current seed: %d" % RandomService.get_seed(),
		"[b]SaveLoadService[/b] — autosave present: %s" % str(SaveLoadService.has_save(SaveLoadService.AUTOSAVE_NAME)),
		"",
		"Use [b]Genotype Debug[/b] to build wild-type/mutant flies and test save/load.",
	]
	_info_label.text = "\n".join(lines)

## Demonstrates the save/load shell end-to-end without any real game state.
func _on_test_save_pressed() -> void:
	var ok := SaveLoadService.autosave({"phase": 0, "note": "placeholder autosave"})
	_refresh()
	_info_label.text += "\n\nSaved autosave: %s" % str(ok)

func _on_test_load_pressed() -> void:
	var envelope := SaveLoadService.load_game(SaveLoadService.AUTOSAVE_NAME)
	_refresh()
	if envelope.is_empty():
		_info_label.text += "\n\nLoad returned nothing (no save yet)."
	else:
		_info_label.text += "\n\nLoaded autosave envelope: %s" % JSON.stringify(envelope)

func _on_genotype_debug_pressed() -> void:
	get_tree().change_scene_to_file(GENOTYPE_DEBUG_SCENE)

func _on_phenotype_viewer_pressed() -> void:
	get_tree().change_scene_to_file(PHENOTYPE_VIEWER_SCENE)

func _on_microscope_pressed() -> void:
	get_tree().change_scene_to_file(MICROSCOPE_SCENE)

func _on_development_pressed() -> void:
	get_tree().change_scene_to_file(DEVELOPMENT_SCENE)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
