class_name PopulationEngine
extends RefCounted
## PopulationEngine — simulates a population over many generations (spec §10, §16
## Arc 5). Each generation: the current adults breed (brood size scales with the
## number of females), offspring develop (viability filters them), truncation
## **selection** optionally keeps only flies matching a phenotype, and a carrying
## capacity / **bottleneck** randomly samples survivors (the source of **drift**).
##
## It produces per-generation allele frequencies and trait means so the player can
## watch **trait frequencies change** under selection or drift, see a line collapse
## when viability is too low, and read a **line-stability** score.
##
## Reproducible via the `seed` config. Performance: capped per-generation size.

const BROOD := 8                     ## offspring attempts per breeding female
const DEFAULT_CAPACITY := 120

## config keys: generations, capacity, env, seed, selection {predicate, mode},
## track_genes (Array[String]), bottleneck {at_gen, size}.
static func simulate(founders: Array, config: Dictionary) -> PopulationResult:
	var res := PopulationResult.new()
	var generations := int(config.get("generations", 10))
	var capacity := int(config.get("capacity", DEFAULT_CAPACITY))
	var env: VialEnvironment = config.get("env", VialEnvironment.standard())
	var selection: Variant = config.get("selection", null)
	var track: Array = config.get("track_genes", [])
	var bottleneck: Dictionary = config.get("bottleneck", {})

	res.requested_generations = generations
	res.track_genes = track

	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.get("seed", -1)) if int(config.get("seed", -1)) >= 0 else RandomService.get_seed()

	var pop: Array = _alive(founders)
	res.generations.append(_gen_stats(0, pop, 1.0, pop.size(), track))

	var survival_rates: Array[float] = []
	for g in range(1, generations + 1):
		var females := _of_sex(pop, Genome.FEMALE)
		var males := _of_sex(pop, Genome.MALE)
		if females.is_empty() or males.is_empty():
			res.extinct = true
			res.explanation.append("Generation %d: the line went extinct — no breeding pair remained." % g)
			break

		var attempts: int = clampi(females.size() * BROOD, 1, capacity * 2)
		var offspring: Array = []
		for i in attempts:
			var mom: Fly = females[rng.randi_range(0, females.size() - 1)]
			var dad: Fly = males[rng.randi_range(0, males.size() - 1)]
			var child := InheritanceEngine.make_child(mom, dad, env, rng, 0.0, g)
			if child.alive:
				offspring.append(child)

		var survival_rate := float(offspring.size()) / float(attempts)
		survival_rates.append(survival_rate)

		# Truncation selection on the survivors (keep or cull by phenotype).
		var selected := _select(offspring, selection)

		# Carrying capacity + drift: shuffle and trim. A bottleneck overrides cap.
		var cap := capacity
		if not bottleneck.is_empty() and int(bottleneck.get("at_gen", -1)) == g:
			cap = int(bottleneck.get("size", capacity))
		_shuffle(selected, rng)
		if selected.size() > cap:
			selected.resize(cap)

		pop = selected
		res.completed_generations = g
		res.generations.append(_gen_stats(g, pop, survival_rate, attempts, track))

		if pop.is_empty():
			res.extinct = true
			var why := " (selection removed every survivor)" if selection != null else " (no offspring survived development)"
			res.explanation.append("Generation %d: the line collapsed%s." % [g, why])
			break

	res.line_stability = _stability(res, survival_rates)
	_summarize(res, selection, track)
	return res

# --- Per-generation statistics ----------------------------------------------

static func _gen_stats(gen: int, pop: Array, survival_rate: float, attempts: int, track: Array) -> Dictionary:
	var allele_freq := {}
	for gene_id in track:
		allele_freq[gene_id] = _allele_frequency(pop, String(gene_id))
	var sum_body := 0.0
	var sum_wing := 0.0
	var sum_flight := 0.0
	var vestigial := 0
	for f: Fly in pop:
		sum_body += f.phenotype.get_trait("body_size", 1.0)
		sum_wing += f.phenotype.get_trait("wing_size", 1.0)
		sum_flight += f.phenotype.get_trait("flight_ability", 1.0)
		if f.phenotype.get_trait("wing_size", 1.0) < 0.4:
			vestigial += 1
	var n: int = maxi(pop.size(), 1)
	return {
		"gen": gen,
		"population": pop.size(),
		"attempts": attempts,
		"survival_rate": survival_rate,
		"allele_freq": allele_freq,
		"means": {
			"body_size": sum_body / n,
			"wing_size": sum_wing / n,
			"flight_ability": sum_flight / n,
		},
		"vestigial_frac": float(vestigial) / n,
	}

## Allele frequencies at one gene across a population: allele_id -> fraction.
static func _allele_frequency(pop: Array, gene_id: String) -> Dictionary:
	var counts := {}
	var total := 0
	for f: Fly in pop:
		for aid in f.genome.genotype_at(gene_id):
			counts[aid] = int(counts.get(aid, 0)) + 1
			total += 1
	var freq := {}
	for aid: String in counts.keys():
		freq[aid] = float(counts[aid]) / float(maxi(total, 1))
	return freq

# --- Helpers -----------------------------------------------------------------

static func _alive(pop: Array) -> Array:
	var out: Array = []
	for f: Fly in pop:
		if f.alive:
			out.append(f)
	return out

static func _of_sex(pop: Array, sex: String) -> Array:
	var out: Array = []
	for f: Fly in pop:
		if f.sex() == sex:
			out.append(f)
	return out

## Applies a selection filter {predicate, mode:"keep"|"cull"}; null keeps all.
static func _select(pop: Array, selection: Variant) -> Array:
	if selection == null:
		return pop
	var sel: Dictionary = selection
	var predicate: Dictionary = sel.get("predicate", {})
	var keep := String(sel.get("mode", "keep")) == "keep"
	var out: Array = []
	for f: Fly in pop:
		var matches := _match(f, predicate)
		if matches == keep:
			out.append(f)
	return out

static func _match(fly: Fly, predicate: Dictionary) -> bool:
	if predicate.is_empty():
		return true
	var v := fly.phenotype.get_trait(String(predicate.get("trait", "")), 0.0)
	var target := float(predicate.get("value", 0.0))
	match String(predicate.get("op", "lt")):
		"lt": return v < target
		"le": return v <= target
		"gt": return v > target
		"ge": return v >= target
	return false

static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

## Line stability: how much of the run survived, weighted by mean survival rate.
static func _stability(res: PopulationResult, survival_rates: Array) -> float:
	var base := float(res.completed_generations) / float(maxi(res.requested_generations, 1))
	var mean_sr := 0.0
	if not survival_rates.is_empty():
		for s in survival_rates:
			mean_sr += s
		mean_sr /= survival_rates.size()
	return clampf(base * (0.5 + 0.5 * mean_sr), 0.0, 1.0)

static func _summarize(res: PopulationResult, selection: Variant, track: Array) -> void:
	if not res.extinct:
		res.explanation.append("The line persisted for all %d generations." % res.completed_generations)
	# Report how a tracked allele's frequency moved.
	for gene_id in track:
		var first: Dictionary = res.generations[0].get("allele_freq", {}).get(gene_id, {})
		var last: Dictionary = res.final().get("allele_freq", {}).get(gene_id, {})
		var keys := {}
		for k in first: keys[k] = true
		for k in last: keys[k] = true
		for aid: String in keys.keys():
			var f0 := float(first.get(aid, 0.0))
			var f1 := float(last.get(aid, 0.0))
			if absf(f1 - f0) >= 0.05:
				var dir := "rose" if f1 > f0 else "fell"
				res.explanation.append("Allele %s frequency %s from %.0f%% to %.0f%%." % [aid, dir, f0 * 100.0, f1 * 100.0])
	if selection != null:
		res.explanation.append("Selection acted each generation, shifting the population toward the chosen phenotype.")
	res.explanation.append("Line-stability score: %.2f." % res.line_stability)
