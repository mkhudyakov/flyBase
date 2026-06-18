extends Node
## SaveLoadService (autoload singleton)
##
## JSON-based save/load. Phase 0 is a working *shell*: it can write and read a
## save-game dictionary to disk, list slots, and autosave. It does not yet know
## about flies, vials, lineages, etc. Later phases register their state into the
## save dictionary via gather/apply hooks instead of this file growing forever.

## Where saves live. user:// maps to a per-user app directory on macOS:
##   ~/Library/Application Support/Godot/app_userdata/<project name>/
const SAVE_DIR := "user://saves/"
const SAVE_EXT := ".save.json"
const AUTOSAVE_NAME := "autosave"

## Bumped when the on-disk format changes so loaders can migrate old saves.
const SAVE_VERSION := 1

func _ready() -> void:
	_ensure_save_dir()

## Creates the save directory if it does not exist.
func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		var err := DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		if err != OK:
			push_error("SaveLoadService: could not create %s (err %d)" % [SAVE_DIR, err])

## Full path for a named slot.
func _path_for(slot_name: String) -> String:
	return SAVE_DIR + slot_name + SAVE_EXT

## Writes a save dictionary to a named slot. Wraps the payload with metadata
## (version, timestamp, seed) so loaders can validate it. Returns true on success.
func save_game(slot_name: String, payload: Dictionary) -> bool:
	_ensure_save_dir()
	var envelope := {
		"version": SAVE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"seed": RandomService.get_seed(),
		"data": payload,
	}

	var file := FileAccess.open(_path_for(slot_name), FileAccess.WRITE)
	if file == null:
		push_error("SaveLoadService: cannot write slot '%s' (err %d)"
			% [slot_name, FileAccess.get_open_error()])
		return false

	file.store_string(JSON.stringify(envelope, "\t"))
	file.close()
	return true

## Loads a named slot. Returns the full envelope dictionary, or an empty
## dictionary if the slot is missing or corrupt. Use get("data") for the payload.
func load_game(slot_name: String) -> Dictionary:
	var path := _path_for(slot_name)
	if not FileAccess.file_exists(path):
		push_warning("SaveLoadService: slot '%s' does not exist." % slot_name)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveLoadService: cannot read slot '%s' (err %d)"
			% [slot_name, FileAccess.get_open_error()])
		return {}

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("SaveLoadService: corrupt save in slot '%s': %s"
			% [slot_name, json.get_error_message()])
		return {}

	var result: Variant = json.data
	if typeof(result) != TYPE_DICTIONARY:
		push_error("SaveLoadService: slot '%s' is not a valid save envelope." % slot_name)
		return {}

	return result

## Convenience: writes to the autosave slot.
func autosave(payload: Dictionary) -> bool:
	return save_game(AUTOSAVE_NAME, payload)

## True if a named slot exists on disk.
func has_save(slot_name: String) -> bool:
	return FileAccess.file_exists(_path_for(slot_name))

## Returns the list of save slot names (without extension) currently on disk.
func list_saves() -> Array[String]:
	var names: Array[String] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return names
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and f.ends_with(SAVE_EXT):
			names.append(f.substr(0, f.length() - SAVE_EXT.length()))
		f = dir.get_next()
	dir.list_dir_end()
	return names

## Deletes a named slot. Returns true if it was removed.
func delete_save(slot_name: String) -> bool:
	var path := _path_for(slot_name)
	if not FileAccess.file_exists(path):
		return false
	return DirAccess.remove_absolute(path) == OK
