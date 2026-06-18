class_name Incubator
extends RefCounted
## Incubator — a temperature-controlled box that vials sit in (spec section 14).
##
## The incubator supplies the temperature used when a vial's flies develop, so
## moving a vial to a hotter/colder incubator changes developmental outcomes.
## Other environment factors (food, crowding, …) belong to the vial itself.

var id: String
var name: String
var temperature_c: float = 25.0
var capacity: int = 8   ## max vials it can hold (advisory; UI-enforced).

func to_dict() -> Dictionary:
	return {"id": id, "name": name, "temperature_c": temperature_c, "capacity": capacity}

static func from_dict(d: Dictionary) -> Incubator:
	var inc := Incubator.new()
	inc.id = String(d.get("id", ""))
	inc.name = String(d.get("name", inc.id))
	inc.temperature_c = float(d.get("temperature_c", 25.0))
	inc.capacity = int(d.get("capacity", 8))
	return inc
