class_name Allele
extends RefCounted
## Allele — an immutable catalog definition loaded from res://data/alleles.json.
##
## An Allele describes one variant of a gene: how it behaves (dominance,
## penetrance, expressivity) and what it does to traits and development. The
## phenotype engine (Phase 2) consumes these numbers; Phase 1 only stores them.
##
## All values are abstract simulator data inspired by Drosophila biology — not
## real sequences, edits, or lab instructions.

var id: String                          ## Stable key, e.g. "vg_strong_loss".
var gene_id: String                     ## The Gene this allele belongs to.
var display_name: String
var mutation_type: String               ## "wild_type", "loss_of_function", ... (spec §8).
var dominance_model: String             ## "dominant" | "recessive" | "semi_dominant" | "additive".
var severity: float                     ## 0..1 overall strength of effect.
var penetrance: float                   ## 0..1 chance the genotype shows the phenotype.
var expressivity_min: float             ## 0..1 lower bound of phenotype severity when shown.
var expressivity_max: float             ## 0..1 upper bound.
var affected_traits: Dictionary         ## trait_name -> signed delta.
var affected_development_modules: Dictionary  ## module_id -> signed delta.
var stage_sensitivity: Array            ## development stages where this allele matters most.
var environment_sensitivity: Dictionary ## env factor -> modifier weight.
var viability_impact: float             ## signed; negative reduces survival.
var fertility_impact: float             ## signed; negative reduces fertility.
var behavior_impact: float              ## signed; general behavior shift.
var educational_note: String
var risk_warning: String

# --- Advanced genetics (Phase 9) ---
## Modifier alleles (suppressor/enhancer) scale another gene's trait effects.
var target_gene: String = ""            ## the gene whose effect this allele modifies.
var modifier_factor: float = 1.0        ## <1 suppresses, >1 enhances the target's effect.
## Temperature-sensitive alleles only express within a temperature window.
var is_temperature_sensitive: bool = false
var ts_direction: String = "above"      ## "above" = active when temp >= threshold; "below" = active when <=.
var ts_threshold: float = 28.0

## Builds an Allele from a parsed JSON dictionary, with safe defaults for any
## missing key. Wild-type alleles typically leave most numeric fields at 0.
static func from_dict(d: Dictionary) -> Allele:
	var a := Allele.new()
	a.id = String(d.get("id", ""))
	a.gene_id = String(d.get("gene_id", ""))
	a.display_name = String(d.get("display_name", a.id))
	a.mutation_type = String(d.get("mutation_type", "wild_type"))
	a.dominance_model = String(d.get("dominance_model", "recessive"))
	a.severity = float(d.get("severity", 0.0))
	a.penetrance = float(d.get("penetrance", 1.0))
	a.expressivity_min = float(d.get("expressivity_min", 1.0))
	a.expressivity_max = float(d.get("expressivity_max", 1.0))
	a.affected_traits = d.get("affected_traits", {})
	a.affected_development_modules = d.get("affected_development_modules", {})
	a.stage_sensitivity = d.get("stage_sensitivity", [])
	a.environment_sensitivity = d.get("environment_sensitivity", {})
	a.viability_impact = float(d.get("viability_impact", 0.0))
	a.fertility_impact = float(d.get("fertility_impact", 0.0))
	a.behavior_impact = float(d.get("behavior_impact", 0.0))
	a.educational_note = String(d.get("educational_note", ""))
	a.risk_warning = String(d.get("risk_warning", ""))
	a.target_gene = String(d.get("target_gene", ""))
	a.modifier_factor = float(d.get("modifier_factor", 1.0))
	a.is_temperature_sensitive = bool(d.get("temperature_sensitive", false))
	a.ts_direction = String(d.get("ts_direction", "above"))
	a.ts_threshold = float(d.get("ts_threshold", 28.0))
	return a

## True if this allele only scales another gene's effect rather than acting itself.
func is_modifier() -> bool:
	return target_gene != "" and not is_equal_approx(modifier_factor, 1.0)

## Whether a temperature-sensitive allele is active at the given temperature.
## Non-TS alleles are always active.
func ts_active(temperature_c: float) -> bool:
	if not is_temperature_sensitive:
		return true
	return temperature_c >= ts_threshold if ts_direction == "above" else temperature_c <= ts_threshold

## True if this allele is the unmutated reference variant.
func is_wild_type() -> bool:
	return mutation_type == "wild_type"
