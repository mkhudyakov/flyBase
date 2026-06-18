class_name Fly
extends RefCounted
## Fly — one individual organism in the simulation.
##
## A Fly ties together its Genome (what it carries) and its Phenotype (what it
## expresses, computed later in Phase 2), plus bookkeeping for lineage. The
## environment a fly experiences belongs to its vial (Phase 6), not the fly, so
## it is not stored here.

var id: String                          ## Unique within a run, e.g. "fly_0001".
var genome: Genome
var phenotype: Phenotype
var generation: int = 0                 ## 0 = founder.
var parent_ids: Array[String] = []      ## Ids of the two parents, if bred.
var label: String = ""                  ## Optional player-facing name.
var alive: bool = true                  ## False if development failed (set by DevelopmentEngine).

func _init() -> void:
	genome = Genome.new()
	phenotype = Phenotype.new()

## Convenience: a fly's sex is determined by its genome's sex chromosomes.
func sex() -> String:
	return genome.sex

func is_female() -> bool:
	return genome.sex == Genome.FEMALE

func to_dict() -> Dictionary:
	return {
		"id": id,
		"label": label,
		"generation": generation,
		"alive": alive,
		"parent_ids": parent_ids.duplicate(),
		"genome": genome.to_dict(),
		"phenotype": phenotype.to_dict(),
	}

static func from_dict(d: Dictionary) -> Fly:
	var f := Fly.new()
	f.id = String(d.get("id", ""))
	f.label = String(d.get("label", ""))
	f.generation = int(d.get("generation", 0))
	f.alive = bool(d.get("alive", true))
	f.parent_ids.assign(d.get("parent_ids", []))
	if d.has("genome") and d["genome"] is Dictionary:
		f.genome = Genome.from_dict(d["genome"])
	if d.has("phenotype") and d["phenotype"] is Dictionary:
		f.phenotype = Phenotype.from_dict(d["phenotype"])
	return f
