class_name Chromosome
extends RefCounted
## Chromosome — one physical chromosome copy carried by a fly.
##
## Drosophila is diploid, so a Genome holds homologous *pairs* of chromosomes
## (two copies of each autosome; females XX, males XY). A single Chromosome
## object is one of those copies and records which allele it carries at each
## gene located on it: gene_id -> allele_id.
##
## Storing alleles per physical copy (rather than as a flat genotype) is what
## lets later phases model recombination and sex linkage naturally.

var type: String                ## Chromosome type: "X", "Y", "2L", "2R", "3L", "3R", "4".
var alleles: Dictionary = {}    ## gene_id -> allele_id present on this copy.

func _init(chromosome_type: String = "") -> void:
	type = chromosome_type

## Sets the allele carried at a gene on this copy.
func set_allele(gene_id: String, allele_id: String) -> void:
	alleles[gene_id] = allele_id

## Returns the allele_id at a gene, or "" if this copy carries nothing there.
func get_allele_id(gene_id: String) -> String:
	return alleles.get(gene_id, "")

func has_gene(gene_id: String) -> bool:
	return alleles.has(gene_id)

func to_dict() -> Dictionary:
	return {"type": type, "alleles": alleles.duplicate()}

static func from_dict(d: Dictionary) -> Chromosome:
	var c := Chromosome.new(String(d.get("type", "")))
	var a: Variant = d.get("alleles", {})
	if a is Dictionary:
		c.alleles = (a as Dictionary).duplicate()
	return c

## Deep copy (used when building offspring from a parent copy later).
func duplicate_copy() -> Chromosome:
	var c := Chromosome.new(type)
	c.alleles = alleles.duplicate()
	return c
