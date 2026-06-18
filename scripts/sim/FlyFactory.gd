class_name FlyFactory
extends RefCounted
## FlyFactory — constructs flies from the Catalog.
##
## Centralises fly creation so genotype construction stays data-driven: a
## wild-type fly is built by placing each gene's wild-type allele on its
## chromosome copies, and a mutant is a wild-type fly with one locus overridden.
## Phase 1 covers founder flies; offspring construction (meiosis/recombination)
## arrives with the InheritanceEngine in Phase 5.

enum Zygosity { HOMOZYGOUS, HETEROZYGOUS }

## Monotonic counter for unique founder ids within a run.
static var _counter: int = 0

static func _next_id() -> String:
	_counter += 1
	return "fly_%04d" % _counter

## A blank fly with a fresh unique id and an empty genome. The caller (e.g. the
## InheritanceEngine) builds the genome from inherited gametes.
static func new_offspring() -> Fly:
	var fly := Fly.new()
	fly.id = _next_id()
	return fly

## Builds a fully wild-type fly of the given sex: every catalog gene receives
## its wild-type allele on all relevant chromosome copies.
static func create_wild_type(for_sex: String = Genome.FEMALE) -> Fly:
	var fly := Fly.new()
	fly.id = _next_id()
	fly.genome.build_scaffold(for_sex)
	for gene in Catalog.all_genes():
		var wt: Allele = Catalog.wild_type_allele_for(gene.id)
		if wt == null:
			push_warning("FlyFactory: gene '%s' has no wild-type allele; skipped." % gene.id)
			continue
		fly.genome.set_allele_all_copies(gene.id, wt.id)
	return fly

## Builds a mutant fly: a wild-type background with one gene overridden by the
## given allele. HOMOZYGOUS sets all copies; HETEROZYGOUS sets one copy and
## leaves the other wild-type. For a male X-linked gene there is a single copy,
## so the result is hemizygous regardless of the requested zygosity.
static func create_mutant(
		gene_id: String,
		allele_id: String,
		zygosity: Zygosity = Zygosity.HOMOZYGOUS,
		for_sex: String = Genome.FEMALE) -> Fly:

	var fly := create_wild_type(for_sex)

	if not Catalog.has_gene(gene_id):
		push_error("FlyFactory: unknown gene '%s'." % gene_id)
		return fly
	if not Catalog.has_allele(allele_id):
		push_error("FlyFactory: unknown allele '%s'." % allele_id)
		return fly

	if zygosity == Zygosity.HOMOZYGOUS:
		fly.genome.set_allele_all_copies(gene_id, allele_id)
	else:
		# Override only the first copy; the second keeps its wild-type allele.
		fly.genome.set_allele_on_copy(gene_id, allele_id, 0)
	return fly
