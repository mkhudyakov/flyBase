class_name Genome
extends RefCounted
## Genome — a fly's complete diploid genetic state.
##
## Holds homologous chromosome copies:
##   - autosomes 2L, 2R, 3L, 3R, 4: two copies each
##   - female: two X copies
##   - male:   one X copy + one Y copy
##
## The genotype at a gene is read by gathering the alleles from every copy of
## the chromosome that gene lives on. For an X-linked gene in a male there is
## only one X copy, so the genotype is hemizygous (a single allele) — this is
## how the simplified sex-linkage model produces male expression of recessive
## X-linked alleles.

const FEMALE := "female"
const MALE := "male"

## The five autosome arms in this simplified model. Each is present in two copies.
const AUTOSOMES := ["2L", "2R", "3L", "3R", "4"]

var sex: String = FEMALE
var chromosomes: Array[Chromosome] = []   ## All copies (homologous pairs flattened).

## Builds the empty diploid scaffold of chromosome copies for a given sex.
## No alleles are placed yet — see Catalog-driven construction in FlyFactory.
func build_scaffold(for_sex: String) -> void:
	sex = for_sex
	chromosomes.clear()
	for autosome in AUTOSOMES:
		chromosomes.append(Chromosome.new(autosome))
		chromosomes.append(Chromosome.new(autosome))
	if sex == MALE:
		chromosomes.append(Chromosome.new("X"))
		chromosomes.append(Chromosome.new("Y"))
	else:
		chromosomes.append(Chromosome.new("X"))
		chromosomes.append(Chromosome.new("X"))

## Returns every chromosome copy of a given type (e.g. two for "2L", one "X"
## in a male).
func copies_of(chromosome_type: String) -> Array[Chromosome]:
	var result: Array[Chromosome] = []
	for c in chromosomes:
		if c.type == chromosome_type:
			result.append(c)
	return result

## The genotype at a gene: the list of allele_ids carried across all relevant
## chromosome copies. Length 2 for diploid loci, 1 for male X-linked (hemizygous).
## Empty if the gene is unknown or unplaced.
func genotype_at(gene_id: String) -> Array[String]:
	var result: Array[String] = []
	var gene: Gene = Catalog.get_gene(gene_id)
	if gene == null:
		return result
	for c in copies_of(gene.chromosome):
		if c.has_gene(gene_id):
			result.append(c.get_allele_id(gene_id))
	return result

## True if every allele at the gene is identical (or the locus is hemizygous,
## which is trivially "homozygous-like" for expression purposes).
func is_homozygous(gene_id: String) -> bool:
	var g := genotype_at(gene_id)
	if g.size() <= 1:
		return true
	for i in range(1, g.size()):
		if g[i] != g[0]:
			return false
	return true

## True if the gene sits on a single chromosome copy (male X / Y genes).
func is_hemizygous(gene_id: String) -> bool:
	return genotype_at(gene_id).size() == 1

## Places an allele on the Nth copy (0-based) of the gene's chromosome.
## Used to construct heterozygotes (one copy) or homozygotes (both copies).
func set_allele_on_copy(gene_id: String, allele_id: String, copy_index: int) -> void:
	var gene: Gene = Catalog.get_gene(gene_id)
	if gene == null:
		push_error("Genome: unknown gene '%s'." % gene_id)
		return
	var copies := copies_of(gene.chromosome)
	if copy_index < 0 or copy_index >= copies.size():
		push_warning("Genome: copy index %d out of range for %s on %s."
			% [copy_index, gene_id, gene.chromosome])
		return
	copies[copy_index].set_allele(gene_id, allele_id)

## Places the same allele on all copies of the gene's chromosome (homozygous,
## or hemizygous for male X-linked genes).
func set_allele_all_copies(gene_id: String, allele_id: String) -> void:
	var gene: Gene = Catalog.get_gene(gene_id)
	if gene == null:
		push_error("Genome: unknown gene '%s'." % gene_id)
		return
	for c in copies_of(gene.chromosome):
		c.set_allele(gene_id, allele_id)

## Every gene id that has at least one allele placed somewhere in this genome.
func placed_gene_ids() -> Array[String]:
	var ids: Array[String] = []
	for c in chromosomes:
		for gene_id in c.alleles.keys():
			if not ids.has(gene_id):
				ids.append(gene_id)
	return ids

func to_dict() -> Dictionary:
	var chrom_dicts: Array = []
	for c in chromosomes:
		chrom_dicts.append(c.to_dict())
	return {"sex": sex, "chromosomes": chrom_dicts}

static func from_dict(d: Dictionary) -> Genome:
	var genome := Genome.new()
	genome.sex = String(d.get("sex", FEMALE))
	genome.chromosomes.clear()
	for cd in d.get("chromosomes", []):
		if cd is Dictionary:
			genome.chromosomes.append(Chromosome.from_dict(cd))
	return genome
