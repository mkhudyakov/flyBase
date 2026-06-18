extends Control
## SettingsScreen — Phase 12 (spec 17). Audio volumes, accessibility options, the
## safety disclaimer, and a "new game" reset. Changes apply and save immediately.

const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"

@onready var _master: HSlider = %MasterSlider
@onready var _sfx: HSlider = %SfxSlider
@onready var _music: HSlider = %MusicSlider
@onready var _scale: HSlider = %ScaleSlider
@onready var _scale_label: Label = %ScaleLabel
@onready var _contrast: CheckBox = %ContrastCheck
@onready var _motion: CheckBox = %MotionCheck
@onready var _language: OptionButton = %LanguageOption
@onready var _status: Label = %Status
@onready var _confirm: ConfirmationDialog = %ConfirmNewGame

const LANG_CODES := ["en", "ru"]

func _ready() -> void:
	_master.value = Settings.master_volume
	_sfx.value = Settings.sfx_volume
	_music.value = Settings.music_volume
	_scale.value = Settings.ui_scale
	_contrast.button_pressed = Settings.high_contrast
	_motion.button_pressed = Settings.reduced_motion
	_language.add_item("English")
	_language.add_item("Русский")
	_language.select(LANG_CODES.find(Settings.language))
	_language.item_selected.connect(_on_language_selected)
	_update_scale_label()

	_master.value_changed.connect(func(v): Settings.set_master_volume(v))
	_sfx.value_changed.connect(func(v): Settings.set_sfx_volume(v))
	_music.value_changed.connect(func(v): Settings.set_music_volume(v))
	_scale.value_changed.connect(func(v):
		Settings.set_ui_scale(v)
		_update_scale_label())
	_contrast.toggled.connect(func(on): Settings.set_high_contrast(on))
	_motion.toggled.connect(func(on): Settings.set_reduced_motion(on))
	_confirm.confirmed.connect(_do_new_game)

func _update_scale_label() -> void:
	_scale_label.text = tr("UI scale: %d%%") % roundi(Settings.ui_scale * 100.0)

func _on_language_selected(idx: int) -> void:
	Loc.set_language(LANG_CODES[idx])
	# Reload the screen so all text re-renders in the chosen language.
	get_tree().reload_current_scene()

func _on_new_game_pressed() -> void:
	_confirm.popup_centered()

func _do_new_game() -> void:
	# Reset all game progress (keeps settings).
	Lab.new_default_lab()
	Campaign.completed.clear()
	Campaign.unlocks.clear()
	Campaign.quiz_correct.clear()
	Campaign.current_id = ""
	Economy.reset()
	SaveLoadService.delete_save("lab")
	SaveLoadService.delete_save("campaign")
	SaveLoadService.delete_save("economy")
	_status.text = "New game started — all progress reset."

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
