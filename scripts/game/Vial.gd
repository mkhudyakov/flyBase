class_name Vial
extends RefCounted
## Vial — a container holding a group of flies plus its rearing environment
## (spec section 14). Flies belong to vials; a vial sits in an incubator that
## supplies its temperature.

var id: String
var name: String
var flies: Array[Fly] = []
var environment: VialEnvironment
var incubator_id: String = ""
var archived: bool = false

func _init() -> void:
	environment = VialEnvironment.standard()

func population() -> int:
	return flies.size()

func alive_count() -> int:
	var n := 0
	for f in flies:
		if f.alive:
			n += 1
	return n

func sex_counts() -> Dictionary:
	var c := {"female": 0, "male": 0}
	for f in flies:
		c[f.sex()] += 1
	return c

func alive_of_sex(sex: String) -> Array[Fly]:
	var out: Array[Fly] = []
	for f in flies:
		if f.alive and f.sex() == sex:
			out.append(f)
	return out

func find_fly(fly_id: String) -> Fly:
	for f in flies:
		if f.id == fly_id:
			return f
	return null

func remove_fly(fly_id: String) -> Fly:
	for i in flies.size():
		if flies[i].id == fly_id:
			return flies.pop_at(i)
	return null

func add_fly(fly: Fly) -> void:
	flies.append(fly)

## One-line summary for the vial list.
func summary_line() -> String:
	var c := sex_counts()
	return "%s — ♀%d ♂%d (%d alive)" % [name, c["female"], c["male"], alive_count()]

func to_dict() -> Dictionary:
	var fly_dicts: Array = []
	for f in flies:
		fly_dicts.append(f.to_dict())
	return {
		"id": id,
		"name": name,
		"incubator_id": incubator_id,
		"archived": archived,
		"environment": environment.to_dict(),
		"flies": fly_dicts,
	}

static func from_dict(d: Dictionary) -> Vial:
	var v := Vial.new()
	v.id = String(d.get("id", ""))
	v.name = String(d.get("name", v.id))
	v.incubator_id = String(d.get("incubator_id", ""))
	v.archived = bool(d.get("archived", false))
	if d.has("environment") and d["environment"] is Dictionary:
		v.environment = VialEnvironment.from_dict(d["environment"])
	v.flies.clear()
	for fd in d.get("flies", []):
		if fd is Dictionary:
			v.flies.append(Fly.from_dict(fd))
	return v
