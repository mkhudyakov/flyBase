extends Control
## NotebookScreen — Phase 7 (spec 17.10). Lists the automatically recorded
## experiment entries and shows the full detail of the selected one, including
## the expected-vs-observed analysis. Can export the notebook to disk.

const LAB_DASHBOARD_SCENE := "res://scenes/LabDashboard.tscn"

@onready var _list: ItemList = %EntryList
@onready var _detail: RichTextLabel = %Detail
@onready var _status: Label = %Status
@onready var _publish_button: Button = %PublishButton

var _selected_index := -1

func _ready() -> void:
	_refresh_list()

func _entry_key(e: Dictionary) -> String:
	return "%s|%s" % [e.get("time", ""), e.get("title", "")]

func _refresh_list() -> void:
	_list.clear()
	# Most recent first.
	for i in range(Lab.notebook.size() - 1, -1, -1):
		var e: Dictionary = Lab.notebook[i]
		var pub := "  📄published" if Economy.is_published(_entry_key(e)) else ""
		_list.add_item("[%s] %s%s" % [e.get("time", ""), e.get("title", "entry"), pub])
		_list.set_item_metadata(_list.item_count - 1, i)
	if Lab.notebook.is_empty():
		_detail.text = "No experiments recorded yet. Breed a vial on the dashboard and the result is logged here automatically."
	else:
		_list.select(0)
		_selected_index = Lab.notebook.size() - 1
		_show_entry(Lab.notebook[_selected_index])

func _on_entry_list_item_selected(idx: int) -> void:
	_selected_index = _list.get_item_metadata(idx)
	if _selected_index >= 0 and _selected_index < Lab.notebook.size():
		_show_entry(Lab.notebook[_selected_index])

func _on_publish_pressed() -> void:
	if _selected_index < 0 or _selected_index >= Lab.notebook.size():
		_status.text = "Select an experiment to publish."
		return
	var key := _entry_key(Lab.notebook[_selected_index])
	var reward := Economy.publish(key)
	if reward.is_empty():
		_status.text = "Already published."
	else:
		_status.text = "Published! +%d publication, +%d RP, +$%d, +%d reputation." \
			% [reward["publication_score"], reward["research_points"], reward["budget"], reward["reputation"]]
		_refresh_list()

func _show_entry(e: Dictionary) -> void:
	var lines: Array[String] = []
	lines.append("[b]%s[/b]" % e.get("title", ""))
	lines.append("Recorded %s" % e.get("time", ""))
	lines.append("Mother: %s    Father: %s" % [e.get("mother", "?"), e.get("father", "?")])
	lines.append("%s → %s" % [e.get("source_vial", "?"), e.get("child_vial", "?")])
	var sex: Dictionary = e.get("sex_counts", {})
	lines.append("%d offspring at %.0f°C (seed %d) — %d survived, ♀%d ♂%d."
		% [int(e.get("count", 0)), float(e.get("temperature", 25.0)), int(e.get("seed", 0)),
			int(e.get("survivors", 0)), int(sex.get("female", 0)), int(sex.get("male", 0))])
	lines.append("")

	# Expected vs observed per gene.
	for entry: Dictionary in e.get("per_gene", []):
		lines.append("[b]%s (%s)[/b] — %s" % [entry.get("gene", ""), entry.get("symbol", ""), entry.get("scope", "")])
		lines.append("  [u]%-26s %9s %9s %9s[/u]" % ["genotype class", "expected", "observed", "survival"])
		for c: Dictionary in entry.get("classes", []):
			lines.append("  %-26s %8.0f%% %8.0f%% %8.0f%%"
				% [c.get("label", ""), float(c.get("expected", 0)) * 100.0,
					float(c.get("observed_frac", 0)) * 100.0, float(c.get("survival", 0)) * 100.0])
		lines.append("")

	lines.append("[b]Explanation[/b]")
	for line in e.get("explanation", []):
		lines.append("  " + String(line))

	_detail.text = "\n".join(lines)

func _on_export_pressed() -> void:
	if Lab.notebook.is_empty():
		_status.text = "Nothing to export yet."
		return
	var path := Lab.export_notebook()
	if path == "":
		_status.text = "Export failed."
	else:
		# Show the OS path so the file is findable.
		_status.text = "Exported to: %s" % ProjectSettings.globalize_path(path)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(LAB_DASHBOARD_SCENE)
