extends Control
## CampaignScreen — Phase 8 (spec 4.1, 17). Lists scenarios, shows the selected
## scenario's briefing/objectives, starts it (seeding the lab + tutorial popup),
## evaluates objectives, handles quiz answers, and completes scenarios.

const LAB_DASHBOARD_SCENE := "res://scenes/LabDashboard.tscn"
const MAIN_MENU_SCENE := "res://scenes/MainMenu.tscn"

@onready var _list: ItemList = %ScenarioList
@onready var _briefing: RichTextLabel = %Briefing
@onready var _objectives_box: VBoxContainer = %ObjectivesBox
@onready var _start_button: Button = %StartButton
@onready var _check_button: Button = %CheckButton
@onready var _complete_button: Button = %CompleteButton
@onready var _status: Label = %Status
@onready var _tutorial: AcceptDialog = %TutorialDialog

var _scenario_ids: Array[String] = []
var _viewing_id := ""

func _ready() -> void:
	if Campaign.scenarios.is_empty():
		_briefing.text = "No scenarios loaded — check data/scenarios.json."
		return
	_refresh_list()
	# Default to the current scenario if one is in progress, else the first.
	var initial: String = Campaign.current_id if Campaign.current_id != "" else _scenario_ids[0]
	_select(initial)

func _refresh_list() -> void:
	_list.clear()
	_scenario_ids.clear()
	for s: Dictionary in Campaign.all_scenarios():
		var id := String(s["id"])
		var tag := ""
		if Campaign.is_completed(id):
			tag = "  ✓"
		elif not Campaign.is_unlocked(id):
			tag = "  🔒"
		_list.add_item(Loc.scenario_text(s, "title") + tag)
		_scenario_ids.append(id)
		if id == _viewing_id:
			_list.select(_scenario_ids.size() - 1)

func _on_scenario_list_item_selected(idx: int) -> void:
	_select(_scenario_ids[idx])

func _select(id: String) -> void:
	_viewing_id = id
	# keep list highlight in sync
	var idx := _scenario_ids.find(id)
	if idx >= 0:
		_list.select(idx)
	_render()

func _render() -> void:
	var s := Campaign.get_scenario(_viewing_id)
	if s.is_empty():
		return
	var unlocked := Campaign.is_unlocked(_viewing_id)
	var is_current := Campaign.current_id == _viewing_id
	var done := Campaign.is_completed(_viewing_id)

	var b: Array[String] = []
	b.append("[b]%s[/b]" % Loc.scenario_text(s, "title"))
	if done:
		b.append("[color=#8fd6a0]%s[/color]" % tr("Completed ✓"))
	elif not unlocked:
		b.append("[color=#d9a06c]%s[/color]" % tr("Locked — complete the prerequisite scenario first."))
	b.append("")
	b.append(Loc.scenario_text(s, "briefing"))
	_briefing.text = "\n".join(b)

	_build_objectives(s, is_current)

	_start_button.disabled = not unlocked
	_start_button.text = tr("Restart scenario") if is_current else tr("Start scenario")
	_check_button.disabled = not is_current
	_complete_button.disabled = not (is_current and Campaign.is_scenario_complete(_viewing_id) and not done)

	if done:
		_status.text = tr("Scenario complete.")
	elif not unlocked:
		_status.text = tr("Locked.")
	elif is_current:
		_status.text = tr("Scenario in progress — breed in the lab, then Check objectives.")
	else:
		_status.text = tr("Press Start to begin this scenario.")

## Rebuilds the objective list (and quiz controls) for the scenario.
func _build_objectives(s: Dictionary, is_current: bool) -> void:
	for child in _objectives_box.get_children():
		child.queue_free()

	var statuses: Array = Campaign.evaluate(String(s["id"])) if is_current else []
	var objectives: Array = s.get("objectives", [])
	for i in objectives.size():
		var obj: Dictionary = objectives[i]
		var complete := false
		var progress := ""
		if is_current and i < statuses.size():
			complete = statuses[i]["complete"]
			progress = statuses[i]["progress"]

		var row := Label.new()
		var mark := "✓" if complete else "○"
		row.text = "%s  %s" % [mark, Loc.objective_text(s, i, "desc")]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_color_override("font_color",
			Color(0.56, 0.84, 0.63) if complete else Color(0.85, 0.85, 0.85))
		_objectives_box.add_child(row)

		if is_current and progress != "":
			var prog := Label.new()
			prog.text = "      %s" % progress
			prog.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			prog.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
			prog.add_theme_font_size_override("font_size", 12)
			_objectives_box.add_child(prog)

		# Quiz: render question + answer buttons (only when playing this scenario).
		if String(obj.get("type", "")) == "quiz" and is_current and not complete:
			var q := Label.new()
			q.text = "      %s" % Loc.objective_text(s, i, "question")
			q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_objectives_box.add_child(q)
			var hb := HBoxContainer.new()
			_objectives_box.add_child(hb)
			var options: Array = Loc.objective_options(s, i)
			for opt_idx in options.size():
				var btn := Button.new()
				btn.text = String(options[opt_idx])
				var captured_i := i
				var captured_opt := opt_idx
				btn.pressed.connect(func(): _on_quiz_answer(captured_i, captured_opt))
				hb.add_child(btn)

func _on_quiz_answer(obj_index: int, choice: int) -> void:
	var correct := Campaign.answer_quiz(_viewing_id, obj_index, choice)
	_status.text = "Correct!" if correct else "Not quite — try again."
	_render()

# --- Actions -----------------------------------------------------------------

func _on_start_pressed() -> void:
	Campaign.start_scenario(_viewing_id)
	_show_tutorial(Campaign.get_scenario(_viewing_id))
	_refresh_list()
	_render()

func _show_tutorial(s: Dictionary) -> void:
	var steps: Array = Loc.scenario_tutorial(s)
	if steps.is_empty():
		return
	var text := ""
	for i in steps.size():
		text += "%d. %s\n\n" % [i + 1, steps[i]]
	_tutorial.dialog_autowrap = true
	_tutorial.title = "%s — %s" % [tr("Tutorial"), Loc.scenario_text(s, "title")]
	_tutorial.dialog_text = text
	_tutorial.popup_centered(Vector2i(640, 360))

func _on_check_pressed() -> void:
	_render()
	if Campaign.is_scenario_complete(_viewing_id) and not Campaign.is_completed(_viewing_id):
		_status.text = "All objectives met! Press Complete scenario."

func _on_complete_pressed() -> void:
	Campaign.complete_current()
	_refresh_list()
	_render()
	_status.text = "Scenario completed — new content unlocked."

func _on_open_lab_pressed() -> void:
	get_tree().change_scene_to_file(LAB_DASHBOARD_SCENE)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
