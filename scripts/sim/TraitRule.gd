class_name TraitRule
extends RefCounted
## TraitRule — a catalog definition of one phenotype trait, from
## res://data/trait_rules.json.
##
## Keeps the *set* of traits and their baselines/ranges data-driven: the
## PhenotypeEngine starts every fly at each trait's baseline and clamps the
## final value to [min_value, max_value]. The "normal" band is used only to flag
## a trait as visibly abnormal in explanations and the viewer.
##
## Values are abstract simulator quantities, not real biological measurements.

var id: String
var label: String
var category: String          ## "visible" | "functional" | "behavioral".
var baseline: float           ## Wild-type starting value.
var min_value: float          ## Hard clamp lower bound.
var max_value: float          ## Hard clamp upper bound.
var normal_min: float         ## Lower edge of the "looks normal" band.
var normal_max: float         ## Upper edge of the "looks normal" band.
var higher_is_better: bool    ## Direction hint for summaries (false for e.g. deformity).
var explanation: String       ## What the number means.

static func from_dict(d: Dictionary) -> TraitRule:
	var t := TraitRule.new()
	t.id = String(d.get("id", ""))
	t.label = String(d.get("label", t.id))
	t.category = String(d.get("category", "visible"))
	t.baseline = float(d.get("baseline", 1.0))
	t.min_value = float(d.get("min", 0.0))
	t.max_value = float(d.get("max", 1.0))
	t.normal_min = float(d.get("normal_min", t.baseline))
	t.normal_max = float(d.get("normal_max", t.baseline))
	t.higher_is_better = bool(d.get("higher_is_better", true))
	t.explanation = String(d.get("explanation", ""))
	return t

## True if a value sits inside the "looks normal" band.
func is_within_normal(value: float) -> bool:
	return value >= normal_min - 0.0001 and value <= normal_max + 0.0001
