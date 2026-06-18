extends Node
## Settings (autoload singleton) — user preferences: audio volumes and
## accessibility options (UI scale, high contrast, reduced motion). Applied
## globally and persisted to a JSON save slot.

const SAVE_SLOT := "settings"

var master_volume: float = 0.8
var sfx_volume: float = 0.7
var music_volume: float = 0.5
var ui_scale: float = 1.0          ## window content scale (accessibility)
var high_contrast: bool = false
var reduced_motion: bool = false
var language: String = "en"        ## "en" | "ru"

func _ready() -> void:
	load_settings()
	apply()

## Applies all settings to the running game.
func apply() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), _vol_db(master_volume))
	AudioManager.apply_settings()
	var w := get_window()
	if w != null:
		w.content_scale_factor = ui_scale
		w.theme = _high_contrast_theme() if high_contrast else null

func _vol_db(v: float) -> float:
	return -80.0 if v <= 0.001 else linear_to_db(v)

## A minimal high-contrast theme (pure-white text on common controls).
func _high_contrast_theme() -> Theme:
	var t := Theme.new()
	var white := Color(1, 1, 1)
	t.set_color("font_color", "Label", white)
	t.set_color("font_color", "Button", white)
	t.set_color("default_color", "RichTextLabel", white)
	return t

# --- Setters (apply + save immediately) -------------------------------------

func set_master_volume(v: float) -> void: master_volume = v; apply(); save_settings()
func set_sfx_volume(v: float) -> void: sfx_volume = v; apply(); save_settings()
func set_music_volume(v: float) -> void: music_volume = v; apply(); save_settings()
func set_ui_scale(v: float) -> void: ui_scale = v; apply(); save_settings()
func set_high_contrast(v: bool) -> void: high_contrast = v; apply(); save_settings()
func set_reduced_motion(v: bool) -> void: reduced_motion = v; save_settings()

# --- Save / load -------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"master_volume": master_volume, "sfx_volume": sfx_volume, "music_volume": music_volume,
		"ui_scale": ui_scale, "high_contrast": high_contrast, "reduced_motion": reduced_motion,
		"language": language,
	}

func save_settings() -> void:
	SaveLoadService.save_game(SAVE_SLOT, to_dict())

func load_settings() -> void:
	if not SaveLoadService.has_save(SAVE_SLOT):
		return
	var env := SaveLoadService.load_game(SAVE_SLOT)
	if env.is_empty() or not env.has("data"):
		return
	var d: Dictionary = env["data"]
	master_volume = float(d.get("master_volume", master_volume))
	sfx_volume = float(d.get("sfx_volume", sfx_volume))
	music_volume = float(d.get("music_volume", music_volume))
	ui_scale = float(d.get("ui_scale", ui_scale))
	high_contrast = bool(d.get("high_contrast", high_contrast))
	reduced_motion = bool(d.get("reduced_motion", reduced_motion))
	language = String(d.get("language", language))
