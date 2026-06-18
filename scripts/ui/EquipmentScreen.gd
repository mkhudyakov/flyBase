extends Control
## EquipmentScreen — Phase 11 (spec section 15). Spend research points to unlock
## equipment that enables deeper analysis and bigger experiments.

const LAB_DASHBOARD_SCENE := "res://scenes/LabDashboard.tscn"

@onready var _stats: Label = %Stats
@onready var _list: VBoxContainer = %EquipmentList
@onready var _status: Label = %Status

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	_stats.text = "Research points: %d    Budget: $%d    Reputation: %d    Publications: %d" \
		% [Economy.research_points, Economy.budget, Economy.reputation, Economy.publication_score]

	for child in _list.get_children():
		child.queue_free()

	for e: Dictionary in Economy.all_equipment():
		var id := String(e["id"])
		var owned := Economy.is_unlocked(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var info := Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.text = "%s — %s  (%d RP)" % [e.get("name", id), e.get("description", ""), int(e.get("cost_rp", 0))]
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(info)

		if owned:
			var owned_lbl := Label.new()
			owned_lbl.text = "OWNED ✓"
			owned_lbl.add_theme_color_override("font_color", Color(0.56, 0.84, 0.63))
			row.add_child(owned_lbl)
		else:
			var btn := Button.new()
			var affordable := Economy.research_points >= int(e.get("cost_rp", 0)) and Economy.requirements_met(id)
			btn.text = "Unlock"
			btn.disabled = not affordable
			if not Economy.requirements_met(id):
				btn.text = "Requires: " + ", ".join(e.get("requires", []))
				btn.disabled = true
			var captured := id
			btn.pressed.connect(func(): _buy(captured))
			row.add_child(btn)

		_list.add_child(row)

func _buy(id: String) -> void:
	if Economy.unlock(id):
		_status.text = "Unlocked %s." % Economy.get_equipment(id).get("name", id)
	else:
		_status.text = "Cannot unlock — not enough research points (or prerequisites missing)."
	_refresh()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(LAB_DASHBOARD_SCENE)
