extends Control
## MainMenu
##
## Phase 0 main menu. Buttons that map to systems not yet built are present but
## disabled (or show a "not implemented yet" notice) so the menu reflects the
## final shape (spec 17.1) while staying runnable.

const LAB_DASHBOARD_SCENE := "res://scenes/LabDashboard.tscn"

@onready var _continue_button: Button = %ContinueButton
@onready var _status_label: Label = %StatusLabel

func _ready() -> void:
	# "Continue" is only meaningful once a save exists.
	_continue_button.disabled = not SaveLoadService.has_save(SaveLoadService.AUTOSAVE_NAME)
	_status_label.text = "Phase 0 skeleton — simulation not yet implemented."

## Sandbox is the only flow that currently leads anywhere: it opens the lab
## dashboard placeholder. Everything else is wired up in later phases.
func _on_sandbox_pressed() -> void:
	get_tree().change_scene_to_file(LAB_DASHBOARD_SCENE)

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file(LAB_DASHBOARD_SCENE)

func _on_new_campaign_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CampaignScreen.tscn")

func _on_challenges_pressed() -> void:
	_notify("Challenge mode arrives in a later phase.")

func _on_tutorial_pressed() -> void:
	_notify("Tutorial library arrives in a later phase.")

func _on_settings_pressed() -> void:
	_notify("Settings menu arrives in Phase 12.")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _notify(message: String) -> void:
	_status_label.text = message
