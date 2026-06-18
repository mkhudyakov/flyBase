extends Node
## DataLoader (autoload singleton)
##
## Reads the data-driven content files (genes, alleles, rules, scenarios, ...)
## from res://data/ and caches them as parsed dictionaries.
##
## Phase 0 scope: generic JSON loading + caching only. The schema-aware parsing
## into Gene/Allele objects happens in Phase 1. Keeping this generic now means
## later phases can add files without touching the loader.

## Directory that holds all data-driven content.
const DATA_DIR := "res://data/"

## Known data files. Missing files are tolerated (logged, not fatal) so the
## project always opens even before every file exists.
const DATA_FILES := {
	"genes": "genes.json",
	"alleles": "alleles.json",
	"trait_rules": "trait_rules.json",
	"epistasis_rules": "epistasis_rules.json",
	"development_stages": "development_stages.json",
	"scenarios": "scenarios.json",
	"equipment": "equipment.json",
}

## Cache of parsed file contents keyed by the logical name above.
var _cache: Dictionary = {}

func _ready() -> void:
	# Eagerly load everything once at startup. Files are tiny in this game.
	load_all()

## Loads (or reloads) every known data file into the cache. Files that do not
## exist yet are skipped silently (they are authored in later phases); a single
## informational line lists what is still pending so startup stays quiet.
func load_all() -> void:
	_cache.clear()
	var pending: Array = []
	for key in DATA_FILES.keys():
		var path := DATA_DIR + String(DATA_FILES[key])
		if not FileAccess.file_exists(path):
			pending.append(String(DATA_FILES[key]))
			continue
		var data: Variant = load_json(path)
		if data != null:
			_cache[key] = data
	if not pending.is_empty():
		print("DataLoader: %d data file(s) not present yet (added in later phases): %s"
			% [pending.size(), ", ".join(pending)])

## Loads and parses a single JSON file. Returns the parsed Variant (usually a
## Dictionary or Array), or null on any error. Errors are logged, not thrown,
## so a malformed or missing file never blocks the project from opening.
func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("DataLoader: file not found: %s" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DataLoader: could not open %s (err %d)" % [path, FileAccess.get_open_error()])
		return null

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("DataLoader: JSON parse error in %s at line %d: %s"
			% [path, json.get_error_line(), json.get_error_message()])
		return null

	return json.data

## Returns the cached data for a logical key (e.g. "genes"), or `default`
## if it was never loaded.
func get_data(key: String, default: Variant = null) -> Variant:
	return _cache.get(key, default)

## True if a logical data key was loaded successfully.
func has_data(key: String) -> bool:
	return _cache.has(key)

## List of logical keys currently in the cache. Useful for debug panels.
func loaded_keys() -> Array:
	return _cache.keys()
