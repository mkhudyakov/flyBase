extends Node
## Catalog (autoload singleton)
##
## Parses the raw JSON from DataLoader into typed Gene and Allele objects and
## provides lookups the rest of the simulation needs (wild-type allele for a
## gene, all genes on a chromosome, etc.). This is the single source of truth
## for "what genes and alleles exist", keeping content fully data-driven.
##
## Depends on DataLoader, which is listed first in project.godot so it is ready
## before this autoload builds.

var _genes_by_id: Dictionary = {}        ## gene_id -> Gene
var _alleles_by_id: Dictionary = {}      ## allele_id -> Allele
var _alleles_by_gene: Dictionary = {}    ## gene_id -> Array[Allele]
var _traits_by_id: Dictionary = {}       ## trait_id -> TraitRule
var _trait_order: Array[String] = []     ## trait_ids in file order (stable display)

func _ready() -> void:
	build()

## (Re)builds the catalog from DataLoader's cached JSON. Safe to call again
## after reloading data files.
func build() -> void:
	_genes_by_id.clear()
	_alleles_by_id.clear()
	_alleles_by_gene.clear()
	_traits_by_id.clear()
	_trait_order.clear()

	var genes_data: Variant = DataLoader.get_data("genes")
	if genes_data is Dictionary and genes_data.has("genes"):
		for raw in genes_data["genes"]:
			if raw is Dictionary:
				var g := Gene.from_dict(raw)
				if g.id != "":
					_genes_by_id[g.id] = g

	var alleles_data: Variant = DataLoader.get_data("alleles")
	if alleles_data is Dictionary and alleles_data.has("alleles"):
		for raw in alleles_data["alleles"]:
			if raw is Dictionary:
				var a := Allele.from_dict(raw)
				if a.id != "":
					_alleles_by_id[a.id] = a
					if not _alleles_by_gene.has(a.gene_id):
						_alleles_by_gene[a.gene_id] = []
					_alleles_by_gene[a.gene_id].append(a)

	var traits_data: Variant = DataLoader.get_data("trait_rules")
	if traits_data is Dictionary and traits_data.has("traits"):
		for raw in traits_data["traits"]:
			if raw is Dictionary:
				var t := TraitRule.from_dict(raw)
				if t.id != "":
					_traits_by_id[t.id] = t
					_trait_order.append(t.id)

	print("Catalog: loaded %d genes, %d alleles, %d traits."
		% [_genes_by_id.size(), _alleles_by_id.size(), _traits_by_id.size()])

## True once at least one gene loaded (i.e. data files exist).
func is_ready() -> bool:
	return not _genes_by_id.is_empty()

func gene_count() -> int:
	return _genes_by_id.size()

func allele_count() -> int:
	return _alleles_by_id.size()

func trait_count() -> int:
	return _traits_by_id.size()

## TraitRule objects in file order (stable display order).
func all_traits() -> Array:
	var result: Array = []
	for tid in _trait_order:
		result.append(_traits_by_id[tid])
	return result

func get_trait_rule(trait_id: String) -> TraitRule:
	return _traits_by_id.get(trait_id, null)

func has_trait(trait_id: String) -> bool:
	return _traits_by_id.has(trait_id)

func get_gene(gene_id: String) -> Gene:
	return _genes_by_id.get(gene_id, null)

func get_allele(allele_id: String) -> Allele:
	return _alleles_by_id.get(allele_id, null)

func has_gene(gene_id: String) -> bool:
	return _genes_by_id.has(gene_id)

func has_allele(allele_id: String) -> bool:
	return _alleles_by_id.has(allele_id)

## All Gene objects, sorted by chromosome then map position (stable display order).
func all_genes() -> Array:
	var genes: Array = _genes_by_id.values()
	genes.sort_custom(func(a: Gene, b: Gene) -> bool:
		if a.chromosome == b.chromosome:
			return a.position < b.position
		return Gene.CHROMOSOMES.find(a.chromosome) < Gene.CHROMOSOMES.find(b.chromosome))
	return genes

## All genes located on a given chromosome (e.g. "X").
func genes_on_chromosome(chromosome: String) -> Array:
	var result: Array = []
	for g in all_genes():
		if g.chromosome == chromosome:
			result.append(g)
	return result

## All alleles defined for a gene.
func alleles_for_gene(gene_id: String) -> Array:
	return _alleles_by_gene.get(gene_id, [])

## The wild-type (reference) allele for a gene, or null if none is defined.
## Wild-type construction relies on every gene having exactly one of these.
func wild_type_allele_for(gene_id: String) -> Allele:
	for a in alleles_for_gene(gene_id):
		if a.is_wild_type():
			return a
	return null
