class_name InheritanceEngine
extends RefCounted
## InheritanceEngine — crosses two flies and produces offspring (spec section 12).
##
## Genetics modelled:
##   - Meiosis: each parent makes a gamete carrying one allele per locus, drawn
##     from its two homologous chromosome copies.
##   - Simplified recombination: genes on the same chromosome arm are linked;
##     between adjacent genes (sorted by map position) the gamete switches which
##     homolog it reads from with a probability that grows with map distance
##     (close genes co-inherit, far genes assort more freely).
##   - Sex determination: the mother always contributes an X; the father
##     contributes X (→ daughter, XX) or Y (→ son, XY) with equal chance.
##   - Sex linkage: an X-linked locus in a son comes only from the mother
##     (hemizygous); the Y carries no modelled genes.
##   - Optional spontaneous mutation (off by default; raised by radiation).
##
## Each offspring is then developed (DevelopmentEngine) so survival, sex ratio,
## and adult phenotypes reflect viability/lethality. Reproducible: all rolls come
## from one RNG seeded by `seed` (or the global seed when seed < 0).

const RECOMB_PER_UNIT := 0.04  ## crossover probability per unit of map distance
const MAX_OFFSPRING := 2000    ## performance safeguard (spec section 22)

## Crosses mother × father and returns a fully analysed CrossResult.
static func cross(mother: Fly, father: Fly, count: int,
		env: VialEnvironment = null, seed: int = -1,
		mutation_rate: float = 0.0) -> CrossResult:
	if env == null:
		env = VialEnvironment.standard()
	count = clampi(count, 1, MAX_OFFSPRING)

	var result := CrossResult.new()
	result.requested = count
	result.seed_used = seed if seed >= 0 else RandomService.get_seed()

	var rng := RandomNumberGenerator.new()
	rng.seed = result.seed_used

	# Radiation slightly raises spontaneous mutation (spec section 11).
	var mut_rate: float = clampf(mutation_rate + env.radiation_exposure * 0.01, 0.0, 0.25)
	var gen := maxi(mother.generation, father.generation) + 1

	for i in count:
		var maternal := _make_gamete(mother.genome, rng, mut_rate)
		var paternal := _make_gamete(father.genome, rng, mut_rate)
		var child := _assemble(maternal, paternal)
		child.generation = gen
		child.parent_ids = [mother.id, father.id]
		# Develop under the vial environment; this sets phenotype + alive.
		DevelopmentEngine.simulate(child, env, rng.randi())
		result.offspring.append(child)

	_analyse(result, mother, father)
	return result

# --- Meiosis -----------------------------------------------------------------

## Builds one gamete from a diploid parent genome.
## Returns { autosomes: {arm: {gene_id: allele_id}}, sex_type: "X"/"Y",
##           sex_alleles: {gene_id: allele_id} }.
static func _make_gamete(genome: Genome, rng: RandomNumberGenerator, mut_rate: float) -> Dictionary:
	var gamete := {"autosomes": {}, "sex_type": "X", "sex_alleles": {}}

	for arm in Genome.AUTOSOMES:
		var copies := genome.copies_of(arm)
		gamete["autosomes"][arm] = _recombine(copies, arm, rng)

	if genome.sex == Genome.MALE:
		# Male: gamete carries either the single X or the Y (50/50) → sets sex.
		if rng.randf() < 0.5:
			gamete["sex_type"] = "X"
			var xs := genome.copies_of("X")
			gamete["sex_alleles"] = xs[0].alleles.duplicate() if not xs.is_empty() else {}
		else:
			gamete["sex_type"] = "Y"
			gamete["sex_alleles"] = {}
	else:
		# Female: always an X, recombined between the two X homologs.
		gamete["sex_type"] = "X"
		gamete["sex_alleles"] = _recombine(genome.copies_of("X"), "X", rng)

	if mut_rate > 0.0:
		_maybe_mutate(gamete, rng, mut_rate)
	return gamete

## Produces a recombined allele set for one chromosome arm from its homolog
## copies. With 1 copy (e.g. male X) it just copies it.
static func _recombine(copies: Array, arm: String, rng: RandomNumberGenerator) -> Dictionary:
	var out := {}
	if copies.is_empty():
		return out
	if copies.size() == 1:
		return (copies[0] as Chromosome).alleles.duplicate()

	var a := copies[0] as Chromosome
	var b := copies[1] as Chromosome
	var current := 0 if rng.randf() < 0.5 else 1  # which homolog we start reading
	var prev_pos := INF
	for gene: Gene in Catalog.genes_on_chromosome(arm):
		if prev_pos != INF:
			var dist: float = absf(gene.position - prev_pos)
			var r: float = clampf(dist * RECOMB_PER_UNIT, 0.0, 0.5)
			if rng.randf() < r:
				current = 1 - current
		var src := a if current == 0 else b
		if src.has_gene(gene.id):
			out[gene.id] = src.get_allele_id(gene.id)
		prev_pos = gene.position
	return out

## Rare spontaneous mutation: swap a gamete allele for another allele of the
## same gene. Off when mut_rate is 0.
static func _maybe_mutate(gamete: Dictionary, rng: RandomNumberGenerator, mut_rate: float) -> void:
	for arm: String in gamete["autosomes"].keys():
		_mutate_set(gamete["autosomes"][arm], rng, mut_rate)
	if gamete["sex_type"] == "X":
		_mutate_set(gamete["sex_alleles"], rng, mut_rate)

static func _mutate_set(alleles: Dictionary, rng: RandomNumberGenerator, mut_rate: float) -> void:
	for gene_id: String in alleles.keys():
		if rng.randf() >= mut_rate:
			continue
		var options := Catalog.alleles_for_gene(gene_id)
		if options.size() <= 1:
			continue
		var pick: Allele = options[rng.randi_range(0, options.size() - 1)]
		alleles[gene_id] = pick.id

# --- Offspring assembly ------------------------------------------------------

static func _assemble(maternal: Dictionary, paternal: Dictionary) -> Fly:
	var child_sex := Genome.MALE if paternal["sex_type"] == "Y" else Genome.FEMALE
	var fly := FlyFactory.new_offspring()
	fly.genome.build_scaffold(child_sex)

	for arm in Genome.AUTOSOMES:
		var copies := fly.genome.copies_of(arm)
		copies[0].alleles = (maternal["autosomes"][arm] as Dictionary).duplicate()
		copies[1].alleles = (paternal["autosomes"][arm] as Dictionary).duplicate()

	if child_sex == Genome.FEMALE:
		var xs := fly.genome.copies_of("X")
		xs[0].alleles = (maternal["sex_alleles"] as Dictionary).duplicate()
		xs[1].alleles = (paternal["sex_alleles"] as Dictionary).duplicate()
	else:
		var x := fly.genome.copies_of("X")
		if not x.is_empty():
			x[0].alleles = (maternal["sex_alleles"] as Dictionary).duplicate()
		# Y copy carries no modelled genes.
	return fly

# --- Analysis ----------------------------------------------------------------

static func _analyse(result: CrossResult, mother: Fly, father: Fly) -> void:
	var seg := _segregating_genes(mother, father)

	# Tallies.
	for child: Fly in result.offspring:
		result.sex_counts[child.sex()] += 1
		if child.alive:
			result.survivors += 1
		_tally(result.genotype_dist, _multilocus_label(child, seg))

	# Phenotype distribution among survivors (only over dimensions that vary).
	_build_phenotype_dist(result)

	# Expected vs observed per segregating gene.
	for gene: Gene in seg:
		result.per_gene.append(_expected_vs_observed(gene, mother, father, result.offspring))

	_build_explanation(result, mother, father, seg)

## Genes where the parents carry more than one distinct allele (informative loci).
static func _segregating_genes(mother: Fly, father: Fly) -> Array:
	var out: Array = []
	for gene: Gene in Catalog.all_genes():
		var alleles := {}
		for a in mother.genome.genotype_at(gene.id):
			alleles[a] = true
		for a in father.genome.genotype_at(gene.id):
			alleles[a] = true
		if alleles.size() > 1:
			out.append(gene)
	return out

static func _multilocus_label(fly: Fly, seg: Array) -> String:
	if seg.is_empty():
		return "all wild-type"
	var parts: Array[String] = []
	for gene: Gene in seg:
		parts.append("%s[%s]" % [gene.symbol, _genotype_label(fly, gene.id)])
	return ", ".join(parts)

static func _genotype_label(fly: Fly, gene_id: String) -> String:
	var g := fly.genome.genotype_at(gene_id)
	var copy := g.duplicate()
	copy.sort()
	return "/".join(copy)

static func _tally(dict: Dictionary, key: String) -> void:
	dict[key] = int(dict.get(key, 0)) + 1

## Builds expected (Mendelian) vs observed class fractions for one gene.
static func _expected_vs_observed(gene: Gene, mother: Fly, father: Fly, offspring: Array) -> Dictionary:
	var entry := {"gene": gene.display_name, "symbol": gene.symbol, "scope": "", "classes": []}
	var m := mother.genome.genotype_at(gene.id)
	var f := father.genome.genotype_at(gene.id)

	if gene.is_sex_linked():
		# Daughters: maternal X (½ each) + paternal X. Sons: maternal X only.
		var father_x: String = f[0] if not f.is_empty() else ""
		var daughters := {}
		var sons := {}
		for ma in m:
			_add_frac(daughters, _pair_label([ma, father_x]), 0.5)
			_add_frac(sons, ma, 0.5)
		entry["scope"] = "X-linked (split by sex)"
		entry["classes"] = _merge_expected_observed(
			[{"scope": "daughters (XX)", "exp": daughters, "sex": Genome.FEMALE},
			 {"scope": "sons (XY)", "exp": sons, "sex": Genome.MALE}],
			gene, offspring)
	else:
		var exp := {}
		for ma in m:
			for fa in f:
				_add_frac(exp, _pair_label([ma, fa]), 0.25)
		entry["scope"] = "autosomal"
		entry["classes"] = _merge_expected_observed(
			[{"scope": "all", "exp": exp, "sex": ""}], gene, offspring)
	return entry

## Merges expected fractions with observed counts (and per-class survival).
static func _merge_expected_observed(scopes: Array, gene: Gene, offspring: Array) -> Array:
	var classes: Array = []
	for s in scopes:
		var exp: Dictionary = s["exp"]
		var sex_filter: String = s["sex"]
		# Observed counts within this scope.
		var obs := {}
		var obs_alive := {}
		var scope_total := 0
		for child: Fly in offspring:
			if sex_filter != "" and child.sex() != sex_filter:
				continue
			scope_total += 1
			var label := _genotype_label(child, gene.id)
			_tally(obs, label)
			if child.alive:
				_tally(obs_alive, label)
		for label: String in exp.keys():
			var observed := int(obs.get(label, 0))
			var alive := int(obs_alive.get(label, 0))
			classes.append({
				"label": "%s: %s" % [s["scope"], label],
				"expected": float(exp[label]),
				"observed": observed,
				"observed_frac": float(observed) / float(max(scope_total, 1)),
				"survival": float(alive) / float(max(observed, 1)),
			})
	return classes

static func _add_frac(dict: Dictionary, key: String, frac: float) -> void:
	dict[key] = float(dict.get(key, 0.0)) + frac

static func _pair_label(alleles: Array) -> String:
	var copy := alleles.duplicate()
	copy.sort()
	return "/".join(copy)

## Phenotype distribution among survivors, over only the visible dimensions that
## actually vary (keeps the table readable).
static func _build_phenotype_dist(result: CrossResult) -> void:
	var survivors: Array = []
	for child: Fly in result.offspring:
		if child.alive:
			survivors.append(child)
	if survivors.is_empty():
		return

	var dims := ["eye", "wing", "body"]
	var per_child := {}
	var distinct := {"eye": {}, "wing": {}, "body": {}}
	for child: Fly in survivors:
		var d := _visible_dims(child)
		per_child[child] = d
		for dim in dims:
			distinct[dim][d[dim]] = true

	var varying: Array[String] = []
	for dim in dims:
		if distinct[dim].size() > 1:
			varying.append(dim)

	for child: Fly in survivors:
		var d: Dictionary = per_child[child]
		var parts: Array[String] = [child.sex()]
		for dim in varying:
			parts.append(d[dim])
		if varying.is_empty():
			parts.append("wild-type")
		_tally(result.phenotype_dist, ", ".join(parts))

static func _visible_dims(fly: Fly) -> Dictionary:
	# Delegate to the shared classifier (handles epistasis-masked traits too).
	return StatisticsEngine.visible_dims(fly)

static func _build_explanation(result: CrossResult, mother: Fly, father: Fly, seg: Array) -> void:
	var lines: Array[String] = []
	lines.append("Crossed %s (♀) × %s (♂); %d offspring, seed %d."
		% [mother.id, father.id, result.requested, result.seed_used])
	lines.append("Survivors: %d / %d (%.0f%%). Sex ratio ♀%d : ♂%d."
		% [result.survivors, result.requested, result.survival_rate() * 100.0,
			result.sex_counts["female"], result.sex_counts["male"]])

	if seg.is_empty():
		lines.append("No genes segregate between these parents; all offspring share the parental genotype.")
	# Flag any genotype class with heavy lethality → explains ratio deviation.
	for entry: Dictionary in result.per_gene:
		for c: Dictionary in entry["classes"]:
			if c["observed"] >= 5 and c["survival"] < 0.5:
				lines.append("Observed ratios deviate from the simple Mendelian expectation: %s %s offspring had only %.0f%% survival, so this class is under-represented among adults (a lethal/low-viability genotype)."
					% [entry["symbol"], c["label"], c["survival"] * 100.0])
	result.explanation = lines
