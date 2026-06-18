class_name PhenotypeEngine
extends RefCounted
## PhenotypeEngine — converts a fly's genotype into its phenotype (spec sections
## 9, 13.1-13.2, 19).
##
## Model, kept deliberately transparent (no black boxes):
##   1. Every trait starts at its baseline (from TraitRule).
##   2. For each gene, the mutant allele's effect is gated by dominance + dose:
##        - dominant      : one copy expresses fully
##        - recessive     : only homozygous (or hemizygous male X) expresses
##        - semi_dominant / additive : dose-proportional (½ heterozygous, full homozygous)
##   3. Penetrance: a roll decides whether an expressed genotype actually shows
##      (spec 13.1). If it fails, the fly looks normal at that locus.
##   4. Expressivity: a roll in [expressivity_min, expressivity_max] scales how
##      strong the effect is (spec 13.2).
##   5. Trait deltas (× dose × expressivity) are added, then clamped.
##   6. Every step is recorded in the phenotype's explanation log.
##
## Reproducibility: the rolls come from a local RNG seeded from the global seed
## plus the fly's genotype signature, so the same seed + same genotype always
## yields the same phenotype (spec test case 9). Pass `roll_seed` to force a
## specific stream.
##
## Advanced genetics (Phase 9): modifier alleles (suppressor/enhancer) scale a
## target gene's effect; temperature-sensitive alleles only express in a
## temperature window (so the environment can reveal a hidden genotype); and
## epistasis rules can mask/override traits after the fact. Body size and similar
## traits are polygenic via additive small-effect alleles across several loci.

## Computes and stores the phenotype on `fly.phenotype` (in place).
static func compute(fly: Fly, env: VialEnvironment = null, roll_seed: int = -1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = roll_seed if roll_seed >= 0 else _derive_seed(fly)
	var temperature: float = env.temperature_c if env != null else 25.0

	var p := fly.phenotype
	p.traits.clear()
	p.explanation.clear()
	p.masked.clear()

	# 1. Baselines.
	for tr: TraitRule in Catalog.all_traits():
		p.traits[tr.id] = tr.baseline

	# Modifier pre-pass: how suppressor/enhancer alleles scale each target gene.
	var modifiers := _modifier_factors(fly, rng)

	# 2-5. Per-gene allele effects.
	var reasoning: Array[String] = []
	for gene: Gene in Catalog.all_genes():
		_apply_gene(fly, gene, p, rng, reasoning, temperature, modifiers)

	# 5 (clamp).
	for tr: TraitRule in Catalog.all_traits():
		p.traits[tr.id] = clampf(p.traits[tr.id], tr.min_value, tr.max_value)

	# Epistasis: one gene's outcome can mask/override another's (spec 13.3).
	var epistasis: Array[String] = _apply_epistasis(p)

	# 6. Assemble explanation: summary first, then genetic reasoning.
	p.explanation.assign(_build_summary(p))
	p.add_explanation("")
	p.add_explanation("Genetic reasoning:")
	if reasoning.is_empty():
		p.add_explanation("  All loci carry wild-type alleles; nothing modifies the baseline.")
	else:
		for line in reasoning:
			p.add_explanation("  " + line)
	if not epistasis.is_empty():
		p.add_explanation("")
		p.add_explanation("Epistasis:")
		for line in epistasis:
			p.add_explanation("  " + line)

	p.computed = true

## Computes a per-target-gene scaling factor from expressed modifier alleles
## (suppressor < 1, enhancer > 1). target_gene -> factor (product of modifiers).
static func _modifier_factors(fly: Fly, _rng: RandomNumberGenerator) -> Dictionary:
	var factors := {}
	for gene: Gene in Catalog.all_genes():
		var genotype := fly.genome.genotype_at(gene.id)
		var counts := {}
		for aid in genotype:
			counts[aid] = int(counts.get(aid, 0)) + 1
		for aid: String in counts.keys():
			var allele: Allele = Catalog.get_allele(aid)
			if allele == null or not allele.is_modifier():
				continue
			if dose_factor(allele.dominance_model, int(counts[aid]), genotype.size()) <= 0.0:
				continue
			factors[allele.target_gene] = float(factors.get(allele.target_gene, 1.0)) * allele.modifier_factor
	return factors

## Stochastic seed when none is supplied: the fly's own per-individual roll_seed
## (so genetically identical flies still vary), falling back to a genotype hash.
static func _derive_seed(fly: Fly) -> int:
	var base := fly.roll_seed if fly.roll_seed != 0 else int(hash(JSON.stringify(fly.genome.to_dict())))
	return RandomService.get_seed() ^ base

## Applies one gene's mutant allele(s) to the phenotype, appending reasoning.
static func _apply_gene(fly: Fly, gene: Gene, p: Phenotype, rng: RandomNumberGenerator,
		reasoning: Array[String], temperature: float, modifiers: Dictionary) -> void:
	var genotype := fly.genome.genotype_at(gene.id)
	if genotype.is_empty():
		return

	# Count copies of each distinct allele present at this locus.
	var counts := {}
	for allele_id in genotype:
		counts[allele_id] = int(counts.get(allele_id, 0)) + 1

	for allele_id: String in counts.keys():
		var allele: Allele = Catalog.get_allele(allele_id)
		if allele == null or allele.is_wild_type() or allele.is_modifier():
			continue  # wild-type and pure-modifier alleles add no direct effect.

		var copies := int(counts[allele_id])
		var total := genotype.size()
		var hemizygous := total == 1
		var dose := dose_factor(allele.dominance_model, copies, total)

		# Recessive carrier: a single masked copy (hidden carrier, spec 13.7).
		if dose <= 0.0:
			reasoning.append("%s (%s): carries one %s, masked by the wild-type allele (recessive). No visible effect, but it can be inherited — a hidden carrier."
				% [gene.display_name, gene.symbol, allele.display_name])
			continue

		# Temperature-sensitive gate (spec 13.x / 4.3): only expresses in-window.
		if not allele.ts_active(temperature):
			reasoning.append("%s (%s): %s is temperature-sensitive and inactive at %.0f°C (needs %s %.0f°C); the fly appears normal here."
				% [gene.display_name, gene.symbol, allele.display_name, temperature,
					allele.ts_direction, allele.ts_threshold])
			continue

		# Penetrance gate (spec 13.1).
		if rng.randf() > allele.penetrance:
			reasoning.append("%s (%s): %s did not manifest this time (penetrance %d%%); the fly appears normal at this locus."
				% [gene.display_name, gene.symbol, allele.display_name, roundi(allele.penetrance * 100.0)])
			continue

		# Expressivity scaling (spec 13.2), then any suppressor/enhancer modifier.
		var expressivity := rng.randf_range(allele.expressivity_min, allele.expressivity_max)
		var mod_factor := float(modifiers.get(gene.id, 1.0))
		var scale := dose * expressivity * mod_factor

		var effects: Array[String] = []
		for trait_name: String in allele.affected_traits.keys():
			if not p.traits.has(trait_name):
				push_warning("PhenotypeEngine: allele '%s' targets unknown trait '%s'." % [allele.id, trait_name])
				continue
			var delta := float(allele.affected_traits[trait_name]) * scale
			p.traits[trait_name] += delta
			effects.append("%s %+.2f" % [trait_name, delta])

		var mod_note := ""
		if not is_equal_approx(mod_factor, 1.0):
			var kind := "suppressor reduced" if mod_factor < 1.0 else "enhancer raised"
			mod_note = " A %s this effect to %d%%." % [kind, roundi(mod_factor * 100.0)]
		reasoning.append("%s (%s): %s expressed %s. %s%s%s"
			% [
				gene.display_name, gene.symbol, allele.display_name,
				_zygosity_phrase(hemizygous, dose, copies, total),
				_dominance_reason(gene, allele, hemizygous, copies, total),
				(" Effect: " + ", ".join(effects) + ".") if not effects.is_empty() else "",
				mod_note,
			])

## Applies epistasis rules after traits are computed. A rule whose condition
## holds can mask traits (hide them) or override them to a fixed value. Returns
## the explanation lines produced. Data-driven via Catalog.epistasis_rules().
static func _apply_epistasis(p: Phenotype) -> Array[String]:
	var lines: Array[String] = []
	for rule: Dictionary in Catalog.epistasis_rules():
		if not _condition_holds(p, rule.get("condition", {})):
			continue
		var effect: Dictionary = rule.get("effect", {})
		for t in effect.get("mask_traits", []):
			if not p.masked.has(String(t)):
				p.masked.append(String(t))
		for key: String in effect.get("override", {}).keys():
			if p.traits.has(key):
				p.traits[key] = float(effect["override"][key])
		lines.append(String(rule.get("explanation", rule.get("id", "epistasis rule"))))
	return lines

static func _condition_holds(p: Phenotype, condition: Dictionary) -> bool:
	if condition.is_empty():
		return false
	var v := p.get_trait(String(condition.get("trait", "")), 0.0)
	var target := float(condition.get("value", 0.0))
	match String(condition.get("op", "lt")):
		"lt": return v < target
		"le": return v <= target
		"gt": return v > target
		"ge": return v >= target
	return false

## Maps dominance model + dose to an expression factor in [0,1].
## Public so the DevelopmentEngine can gate allele effects the same way.
static func dose_factor(dominance_model: String, copies: int, total: int) -> float:
	match dominance_model:
		"dominant":
			return 1.0  # one copy is sufficient
		"recessive":
			if total == 1:
				return 1.0  # hemizygous (e.g. male X) — single copy expresses
			return 1.0 if copies == total else 0.0  # needs to be homozygous
		"semi_dominant", "additive":
			return float(copies) / float(total)  # ½ heterozygous, full homozygous
		_:
			return 1.0

static func _zygosity_phrase(hemizygous: bool, dose: float, _copies: int, total: int) -> String:
	if hemizygous:
		return "(hemizygous)"
	if total == 2 and dose < 1.0:
		return "(heterozygous, partial dose)"
	return "(homozygous)" if dose >= 1.0 and total == 2 else "(heterozygous)"

## A short clause explaining *why* the allele is expressed, tailored to the case.
static func _dominance_reason(gene: Gene, allele: Allele, hemizygous: bool, copies: int, total: int) -> String:
	if hemizygous and gene.is_sex_linked():
		return "Males carry a single X in this simplified model, so this X-linked allele is expressed even though it is recessive."
	match allele.dominance_model:
		"dominant":
			return "A single copy is enough because the allele is dominant."
		"semi_dominant", "additive":
			if copies < total:
				return "The allele is semi-dominant, so even one copy produces a partial effect."
			return "Both copies carry the allele, giving the full semi-dominant effect."
		"recessive":
			return "Both copies carry the mutant allele, so the recessive phenotype appears."
		_:
			return ""

## Human-readable summary of traits that fall outside their normal band.
static func _build_summary(p: Phenotype) -> Array[String]:
	var lines: Array[String] = ["Phenotype summary:"]
	var any_abnormal := false
	for tr: TraitRule in Catalog.all_traits():
		var value: float = p.traits[tr.id]
		if tr.is_within_normal(value):
			continue
		any_abnormal = true
		var direction := _describe_direction(tr, value)
		lines.append("  %s is %s (%.2f; normal %.2f–%.2f)."
			% [tr.label, direction, value, tr.normal_min, tr.normal_max])
	if not any_abnormal:
		lines.append("  All traits within normal range (wild-type appearance).")
	return lines

static func _describe_direction(tr: TraitRule, value: float) -> String:
	if value < tr.normal_min:
		return "elevated" if not tr.higher_is_better else "reduced"
	return "increased" if not tr.higher_is_better else "elevated"
