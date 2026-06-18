extends Node
## Phase7Tests — headless verification of statistics + notebook.
##
## Run with:
##   Godot --headless --path . res://scenes/Phase7Tests.tscn --quit-after 5

var _passed := 0
var _failed := 0

func _ready() -> void:
	print("\n==== Phase 7 tests ====")
	Lab.new_default_lab()

	# --- Notebook auto-logs a cross ---
	var before := Lab.notebook.size()
	var stock := Lab.active_vials()[0]
	var child := Lab.breed(stock, 100, 4242)
	_check("Breeding records a notebook entry", Lab.notebook.size() == before + 1)

	var entry: Dictionary = Lab.notebook.back()
	_check("Entry records offspring count", int(entry["count"]) == 100)
	_check("Entry has an explanation", entry.get("explanation", []).size() > 0)
	_check("Entry has phenotype distribution", not entry.get("phenotype_dist", {}).is_empty())

	# --- StatisticsEngine over the offspring vial ---
	var flies := child.flies
	var s := StatisticsEngine.summarize(flies)
	_check("summarize counts add up", s["female"] + s["male"] == s["count"])
	_check("summarize alive <= count", s["alive"] <= s["count"])

	var dist := StatisticsEngine.phenotype_distribution(flies, true)
	var dist_total := 0
	for k in dist:
		dist_total += int(dist[k])
	_check("phenotype distribution covers all survivors", dist_total == s["alive"])

	var hist := StatisticsEngine.trait_histogram(flies, "body_size", 10, true)
	var hist_total := 0
	for b: Dictionary in hist["bins"]:
		hist_total += int(b["count"])
	_check("histogram has 10 bins", hist["bins"].size() == 10)
	_check("histogram bins sum to n", hist_total == int(hist["n"]))
	_check("histogram mean within range",
		hist["mean"] >= hist["min"] - 0.001 and hist["mean"] <= hist["max"] + 0.001)

	# --- Expected vs observed available for comparison ---
	var has_eo := false
	for pg: Dictionary in entry.get("per_gene", []):
		for c: Dictionary in pg.get("classes", []):
			if c.has("expected") and c.has("observed_frac"):
				has_eo = true
	# vg/+ stock is wild-type only in the default lab → no segregation; breed a
	# segregating cross to confirm expected-vs-observed is captured.
	var carriers := Lab.active_vials()[1]  # vestigial line (vg/+)
	var f1 := Lab.breed(carriers, 200, 4242)
	var seg_entry: Dictionary = Lab.notebook.back()
	for pg: Dictionary in seg_entry.get("per_gene", []):
		for c: Dictionary in pg.get("classes", []):
			if c.has("expected") and c.has("observed_frac"):
				has_eo = true
	_check("Notebook captures expected-vs-observed for a segregating cross", has_eo)

	# --- Export ---
	var path := Lab.export_notebook()
	_check("export_notebook returns a path", path != "")
	_check("Exported file exists", path != "" and FileAccess.file_exists(path))

	# --- Notebook survives save/load ---
	var n := Lab.notebook.size()
	var snap := Lab.to_dict()
	Lab.new_default_lab()
	Lab.load_from_dict(snap)
	_check("Notebook persists through save/load", Lab.notebook.size() == n)

	print("==== %d passed, %d failed ====\n" % [_passed, _failed])

func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % label)
	else:
		_failed += 1
		print("  FAIL  %s" % label)
