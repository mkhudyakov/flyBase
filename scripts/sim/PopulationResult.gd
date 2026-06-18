class_name PopulationResult
extends RefCounted
## PopulationResult — the per-generation record of a population simulation
## (spec section 10 / phase 10). Plain data for charts and the explanation.

var requested_generations: int = 0
var completed_generations: int = 0
var extinct: bool = false
var track_genes: Array = []
var line_stability: float = 0.0

## One dict per generation (index 0 = founders):
## {gen, population, attempts, survived, survival_rate,
##  allele_freq: {gene: {allele: freq}}, means: {trait: value}, vestigial_frac}
var generations: Array = []
var explanation: Array[String] = []

## Allele frequency of a specific allele at a given generation index.
func allele_freq_at(gen_index: int, gene_id: String, allele_id: String) -> float:
	if gen_index < 0 or gen_index >= generations.size():
		return 0.0
	var af: Dictionary = generations[gen_index].get("allele_freq", {})
	return float(af.get(gene_id, {}).get(allele_id, 0.0))

func final() -> Dictionary:
	return generations[-1] if not generations.is_empty() else {}
