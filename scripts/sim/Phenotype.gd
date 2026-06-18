class_name Phenotype
extends RefCounted
## Phenotype — the observable traits of a fly.
##
## Phase 1 scope: this is a data *container* only. It is deliberately not
## computed yet — the PhenotypeEngine (Phase 2) reads a Genome + Environment and
## fills `traits` and `explanation`. Defining the container now lets the Fly
## class, save/load, and the debug panel be written against a stable shape.
##
## Genotype and phenotype are kept strictly separate (spec section 9): the
## genome is what the fly carries; the phenotype is what it expresses.

## trait_name -> numeric value (e.g. "eye_color_index", "wing_size").
var traits: Dictionary = {}

## Human-readable lines explaining how each trait came about. Every major
## phenotype must be explainable (spec section 19); populated in Phase 2.
var explanation: Array[String] = []

## False until the PhenotypeEngine has run on this fly.
var computed: bool = false

func get_trait(name: String, default: float = 0.0) -> float:
	return float(traits.get(name, default))

func set_trait(name: String, value: float) -> void:
	traits[name] = value

func add_explanation(line: String) -> void:
	explanation.append(line)

func to_dict() -> Dictionary:
	return {
		"traits": traits.duplicate(),
		"explanation": explanation.duplicate(),
		"computed": computed,
	}

static func from_dict(d: Dictionary) -> Phenotype:
	var p := Phenotype.new()
	var t: Variant = d.get("traits", {})
	if t is Dictionary:
		p.traits = (t as Dictionary).duplicate()
	p.explanation.assign(d.get("explanation", []))
	p.computed = bool(d.get("computed", false))
	return p
