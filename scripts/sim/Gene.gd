class_name Gene
extends RefCounted
## Gene — an immutable catalog definition loaded from res://data/genes.json.
##
## A Gene is *not* a fly's genetic state; it is the static description of a locus
## (where it sits, what it does, how risky its mutations are). A fly's actual
## alleles live in its Genome. This separation keeps genotype data-driven: adding
## a gene means adding a JSON entry, not code.
##
## All values here are abstract simulator data inspired by Drosophila biology.
## They are not real biological sequences or instructions.

## Valid simplified chromosomes in this model (spec section 6).
const CHROMOSOMES := ["X", "Y", "2L", "2R", "3L", "3R", "4"]

var id: String                       ## Stable key, e.g. "vg".
var display_name: String             ## Human name, e.g. "vestigial".
var symbol: String                   ## Short symbol, e.g. "vg".
var chromosome: String               ## One of CHROMOSOMES.
var position: float                  ## Abstract map position (ordering/linkage).
var biological_category: String      ## e.g. "wing_development".
var description: String
var affected_modules: Array          ## Development module ids this gene touches.
var essentiality: String             ## "non_essential" | "conditional" | "essential".
var risk_level: String               ## "cosmetic" | "functional" | "developmental" | "lethal".
var educational_note: String
var is_real_gene_name: bool          ## True if inspired by a real gene name.
var is_simulator_abstraction: bool   ## True if this is a simplified abstraction.

## Builds a Gene from a parsed JSON dictionary. Unknown keys are ignored and
## missing keys fall back to safe defaults so partial data never crashes load.
static func from_dict(d: Dictionary) -> Gene:
	var g := Gene.new()
	g.id = String(d.get("id", ""))
	g.display_name = String(d.get("display_name", g.id))
	g.symbol = String(d.get("symbol", g.id))
	g.chromosome = String(d.get("chromosome", "2L"))
	g.position = float(d.get("position", 0.0))
	g.biological_category = String(d.get("biological_category", "unspecified"))
	g.description = String(d.get("description", ""))
	g.affected_modules = d.get("affected_modules", [])
	g.essentiality = String(d.get("essentiality", "non_essential"))
	g.risk_level = String(d.get("risk_level", "cosmetic"))
	g.educational_note = String(d.get("educational_note", ""))
	g.is_real_gene_name = bool(d.get("is_real_gene_name", false))
	g.is_simulator_abstraction = bool(d.get("is_simulator_abstraction", true))
	return g

## True if this gene sits on a sex chromosome (relevant for sex-linked
## inheritance and male hemizygosity in this simplified model).
func is_sex_linked() -> bool:
	return chromosome == "X" or chromosome == "Y"
