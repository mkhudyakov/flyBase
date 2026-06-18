class_name DevelopmentEngine
extends RefCounted
## DevelopmentEngine — simulates a fly developing from egg to adult under an
## environment (spec sections 10-11). This is the first system where the
## environment actually changes outcomes.
##
## How it works, kept explainable:
##   - Development module health (axis_patterning, wing_imaginal_disc, ...) is
##     derived from the genome: each expressed mutant allele lowers the modules
##     it disrupts, gated by dominance + dose (shared with the PhenotypeEngine).
##   - Walk the stages in order. Each stage has sensitive modules, an energy
##     need, and a temperature-scaled duration. Per-stage stress accumulates and
##     erodes developmental stability.
##   - A stage FAILS (the fly dies) when a sensitive module is critically low,
##     the temperature is lethal, larval energy collapses, or accumulated stress
##     wins a probabilistic roll. Failure carries the stage's named outcome.
##   - Survivors get viability / fertility / lifespan scores and a body-size
##     adjustment from nutrition, all written onto the phenotype.
##
## Environment effects modelled: temperature scales stage duration (hot = faster,
## cold = slower) and adds stress; extreme temperature is lethal; low food /
## high crowding reduce energy (smaller body, lower fertility, possible collapse);
## toxin/infection/radiation add developmental instability.
##
## Reproducible: rolls come from a local RNG seeded from the global seed plus the
## genome+environment signature, or from an explicit roll_seed.

const COLD_LETHAL := 10.0
const HEAT_LETHAL := 33.0
const HARD_MODULE := 0.20   ## below this, a sensitive stage fails outright.
const SOFT_MODULE := 0.45   ## below this, failure becomes probabilistic.

## Simulates development, returns a DevelopmentResult, and writes the resulting
## functional scores + nutrition-adjusted body size onto fly.phenotype.
static func simulate(fly: Fly, env: VialEnvironment = null, roll_seed: int = -1) -> DevelopmentResult:
	if env == null:
		env = VialEnvironment.standard()

	var result := DevelopmentResult.new()
	var stages := _stages()
	if stages.is_empty():
		result.outcome = "no stage data"
		result.explanation.append("development_stages.json is missing or empty.")
		return result

	var rng := RandomNumberGenerator.new()
	rng.seed = roll_seed if roll_seed >= 0 else _derive_seed(fly, env)

	# --- Derive inputs from genome + environment ---------------------------
	var effects := _expressed_effects(fly)
	var module_health := _module_health(effects)
	var viability_impact := 0.0
	var fertility_impact := 0.0
	for e in effects:
		viability_impact += e.allele.viability_impact * e.scale
		fertility_impact += e.allele.fertility_impact * e.scale

	var opt: float = _optimal_temp()
	var temp := env.temperature_c
	var temp_rate: float = clampf(pow(2.0, (opt - temp) / 10.0), 0.4, 2.5)  # <1 = faster
	var temp_stress: float = clampf(absf(temp - opt) / 10.0, 0.0, 1.5)
	var extreme := temp <= COLD_LETHAL or temp >= HEAT_LETHAL

	var nutrition: float = clampf(env.food_quality * env.food_quantity, 0.0, 1.0)
	var nutrition_eff: float = clampf(nutrition * (1.0 - env.crowding * 0.4), 0.0, 1.0)

	# --- Walk the stages ----------------------------------------------------
	var stability := 1.0
	var alive := true
	for stage: Dictionary in stages:
		var duration: float = float(stage.get("base_duration_days", 1.0)) * temp_rate
		result.total_days += duration
		result.final_stage = String(stage.get("id", ""))

		var worst := 1.0
		var worst_mod := ""
		for mod in stage.get("sensitive_modules", []):
			var h: float = float(module_health.get(mod, 1.0))
			if h < worst:
				worst = h
				worst_mod = String(mod)

		var energy_need: float = float(stage.get("required_energy", 0.0)) * (1.0 + env.crowding * 0.5)
		var energy_gap: float = maxf(0.0, energy_need - nutrition_eff)

		var stress: float = clampf(
			temp_stress * 0.4
			+ (1.0 - worst) * 0.9
			+ energy_gap * 0.6
			+ env.toxin_exposure * 0.4
			+ env.infection_pressure * 0.3
			+ env.radiation_exposure * 0.3,
			0.0, 2.0)
		stability = clampf(stability - stress * 0.12, 0.0, 1.0)

		var status := "ok"
		var note := ""
		var stage_id := String(stage.get("id", ""))
		var outcome := String(stage.get("failure_outcome", "developmental failure"))

		if worst < HARD_MODULE:
			alive = false
			status = "fail"
			note = "%s critically low (%.2f)" % [worst_mod, worst]
			result.outcome = outcome
		elif extreme:
			alive = false
			status = "fail"
			note = "temperature %.0f°C is outside the survivable range" % temp
			result.outcome = "temperature lethality"
		elif energy_gap > 0.4 and (stage_id == "larva_2" or stage_id == "larva_3"):
			alive = false
			status = "fail"
			note = "insufficient energy for larval growth (need %.2f, have %.2f)" % [energy_need, nutrition_eff]
			result.outcome = "metabolic collapse"
		else:
			var p_fail := 0.0
			if worst < SOFT_MODULE:
				p_fail = (SOFT_MODULE - worst) / (SOFT_MODULE - HARD_MODULE) * 0.6
			p_fail += clampf((stress - 0.9) * 0.25, 0.0, 0.5)
			if rng.randf() < p_fail:
				alive = false
				status = "fail"
				note = "accumulated stress (%.2f) exceeded tolerance" % stress
				result.outcome = outcome

		result.stage_logs.append({
			"id": stage_id,
			"display_name": String(stage.get("display_name", stage_id)),
			"duration": duration,
			"stress": stress,
			"status": status,
			"note": note,
		})
		if not alive:
			break

	result.reached_adult = alive
	result.developmental_stability = stability

	# --- Scores -------------------------------------------------------------
	if alive:
		result.viability_score = clampf(0.5 + 0.5 * stability + viability_impact, 0.0, 1.0)
		result.fertility_score = clampf(
			0.6 + 0.4 * stability + fertility_impact + (nutrition_eff - 0.7) * 0.5, 0.0, 1.0)
		var temp_life: float = clampf(1.0 - (temp - opt) / 40.0, 0.4, 1.2)
		result.lifespan_days = clampf(55.0 * stability * temp_life, 0.0, 90.0)
		result.outcome = _adult_outcome(result)
	else:
		result.viability_score = 0.0
		result.fertility_score = 0.0
		result.lifespan_days = 0.0

	fly.alive = result.reached_adult
	_write_phenotype(fly, env, roll_seed, result, nutrition_eff)
	_build_explanation(fly, env, result, effects, module_health, temp_rate)
	return result

# --- Helpers -----------------------------------------------------------------

static func _stages() -> Array:
	var data: Variant = DataLoader.get_data("development_stages")
	if data is Dictionary and data.has("stages"):
		return data["stages"]
	return []

static func _optimal_temp() -> float:
	var data: Variant = DataLoader.get_data("development_stages")
	if data is Dictionary:
		return float(data.get("optimal_temperature_c", 25.0))
	return 25.0

static func _derive_seed(fly: Fly, env: VialEnvironment) -> int:
	var base := fly.roll_seed if fly.roll_seed != 0 else int(hash(JSON.stringify(fly.genome.to_dict())))
	return RandomService.get_seed() ^ base ^ int(hash(JSON.stringify(env.to_dict())))

## Expressed (non-masked) mutant allele effects, gated by dominance + dose, with
## a mid-expressivity magnitude. Shared basis for module health and impacts.
static func _expressed_effects(fly: Fly) -> Array:
	var out: Array = []
	for gene: Gene in Catalog.all_genes():
		var genotype := fly.genome.genotype_at(gene.id)
		if genotype.is_empty():
			continue
		var counts := {}
		for aid in genotype:
			counts[aid] = int(counts.get(aid, 0)) + 1
		for aid: String in counts.keys():
			var allele: Allele = Catalog.get_allele(aid)
			if allele == null or allele.is_wild_type():
				continue
			var dose := PhenotypeEngine.dose_factor(allele.dominance_model, int(counts[aid]), genotype.size())
			if dose <= 0.0:
				continue
			var expr_mid := (allele.expressivity_min + allele.expressivity_max) * 0.5
			out.append({"gene": gene, "allele": allele, "scale": dose * expr_mid})
	return out

static func _module_health(effects: Array) -> Dictionary:
	var mh := {}
	for e in effects:
		for mod: String in e.allele.affected_development_modules.keys():
			var cur: float = float(mh.get(mod, 1.0))
			mh[mod] = clampf(cur + float(e.allele.affected_development_modules[mod]) * e.scale, 0.0, 1.0)
	return mh

static func _adult_outcome(result: DevelopmentResult) -> String:
	if result.fertility_score < 0.15:
		return "sterile adult"
	if result.developmental_stability < 0.4:
		return "viable but impaired adult"
	if result.lifespan_days < 25.0:
		return "short-lived adult"
	return "healthy adult"

## Computes the visible phenotype and overlays development-derived functional
## traits and a nutrition-based body-size adjustment.
static func _write_phenotype(fly: Fly, env: VialEnvironment, roll_seed: int,
		result: DevelopmentResult, nutrition_eff: float) -> void:
	PhenotypeEngine.compute(fly, env, roll_seed)
	var p := fly.phenotype
	# Low food / crowding yield a smaller adult.
	var size_factor: float = clampf(0.65 + 0.35 * nutrition_eff, 0.4, 1.05)
	if p.traits.has("body_size"):
		var tr: TraitRule = Catalog.get_trait_rule("body_size")
		p.set_trait("body_size", clampf(p.get_trait("body_size") * size_factor, tr.min_value, tr.max_value))
	p.set_trait("viability_score", result.viability_score)
	p.set_trait("developmental_stability", result.developmental_stability)
	p.set_trait("fertility_score", result.fertility_score)
	p.set_trait("lifespan_days", result.lifespan_days)

static func _build_explanation(fly: Fly, env: VialEnvironment, result: DevelopmentResult,
		effects: Array, module_health: Dictionary, temp_rate: float) -> void:
	var lines: Array[String] = []
	if result.reached_adult:
		lines.append("Reached adulthood as a %s after %.1f simulated days." % [result.outcome, result.total_days])
	else:
		var last: Dictionary = result.stage_logs[-1] if not result.stage_logs.is_empty() else {}
		lines.append("Development stopped during %s (%s) after %.1f days."
			% [String(last.get("display_name", result.final_stage)), result.outcome, result.total_days])
		if String(last.get("note", "")) != "":
			lines.append("Cause: %s." % last["note"])

	# Environment narrative.
	var temp_note := "sped up" if temp_rate < 0.95 else ("slowed" if temp_rate > 1.05 else "kept normal")
	lines.append("Environment: %.0f°C (development %s), food %.0f%%, crowding %.0f%%."
		% [env.temperature_c, temp_note, env.food_quality * env.food_quantity * 100.0, env.crowding * 100.0])

	# Which genes disrupted which modules.
	var disruptors: Array[String] = []
	for e in effects:
		for mod: String in e.allele.affected_development_modules.keys():
			if float(module_health.get(mod, 1.0)) < 0.6:
				disruptors.append("%s lowered %s to %.2f" % [e.gene.symbol, mod, float(module_health[mod])])
	if not disruptors.is_empty():
		lines.append("Module disruption: " + "; ".join(disruptors) + ".")

	if result.reached_adult:
		lines.append("Scores — viability %.2f, stability %.2f, fertility %.2f, lifespan %.0f days."
			% [result.viability_score, result.developmental_stability, result.fertility_score, result.lifespan_days])

	result.explanation = lines
