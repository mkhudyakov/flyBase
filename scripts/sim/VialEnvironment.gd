class_name VialEnvironment
extends RefCounted
## VialEnvironment — rearing conditions for a fly/vial (spec section 11).
##
## (Named VialEnvironment rather than "Environment" because Godot already has a
## built-in Environment class; reusing that name hides the engine type. The
## conditions here apply per vial/incubator.)
##
## Environment is not cosmetic: later phases let it modify development and
## phenotype (temperature changes timing and stress, low food reduces size and
## survival, etc.). Phase 1 only defines the data container with sensible
## standard-rearing defaults. Each value is an abstract simulator quantity.

var temperature_c: float = 25.0       ## Standard Drosophila rearing temperature.
var food_quality: float = 1.0         ## 0..1, nutrient richness.
var food_quantity: float = 1.0        ## 0..1, amount available.
var crowding: float = 0.2             ## 0..1, larval density.
var humidity: float = 0.6             ## 0..1.
var infection_pressure: float = 0.0   ## 0..1, pathogen load.
var toxin_exposure: float = 0.0       ## 0..1.
var radiation_exposure: float = 0.0   ## 0..1, raises mutation/damage later.
var light_cycle: float = 0.5          ## 0..1, fraction of day that is light.
var stress_level: float = 0.0         ## 0..1, derived/ambient stress.
var vial_cleanliness: float = 1.0     ## 0..1, 1 = clean.

## A copy with standard rearing conditions (the defaults above).
static func standard() -> VialEnvironment:
	return VialEnvironment.new()

## A deep copy of this environment.
func clone() -> VialEnvironment:
	return VialEnvironment.from_dict(to_dict())

func to_dict() -> Dictionary:
	return {
		"temperature_c": temperature_c,
		"food_quality": food_quality,
		"food_quantity": food_quantity,
		"crowding": crowding,
		"humidity": humidity,
		"infection_pressure": infection_pressure,
		"toxin_exposure": toxin_exposure,
		"radiation_exposure": radiation_exposure,
		"light_cycle": light_cycle,
		"stress_level": stress_level,
		"vial_cleanliness": vial_cleanliness,
	}

static func from_dict(d: Dictionary) -> VialEnvironment:
	var e := VialEnvironment.new()
	e.temperature_c = float(d.get("temperature_c", e.temperature_c))
	e.food_quality = float(d.get("food_quality", e.food_quality))
	e.food_quantity = float(d.get("food_quantity", e.food_quantity))
	e.crowding = float(d.get("crowding", e.crowding))
	e.humidity = float(d.get("humidity", e.humidity))
	e.infection_pressure = float(d.get("infection_pressure", e.infection_pressure))
	e.toxin_exposure = float(d.get("toxin_exposure", e.toxin_exposure))
	e.radiation_exposure = float(d.get("radiation_exposure", e.radiation_exposure))
	e.light_cycle = float(d.get("light_cycle", e.light_cycle))
	e.stress_level = float(d.get("stress_level", e.stress_level))
	e.vial_cleanliness = float(d.get("vial_cleanliness", e.vial_cleanliness))
	return e
