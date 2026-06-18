class_name CrossResult
extends RefCounted
## CrossResult — the outcome of crossing two flies (spec section 12).
##
## Holds the offspring plus the distributions and the expected-vs-observed
## analysis the cross simulator displays. Plain data so it can be rendered or
## saved.

var seed_used: int = 0
var requested: int = 0
var offspring: Array[Fly] = []

var survivors: int = 0
var sex_counts: Dictionary = {"female": 0, "male": 0}

## Multilocus genotype distribution over segregating genes (all offspring).
var genotype_dist: Dictionary = {}
## Visible phenotype distribution among survivors.
var phenotype_dist: Dictionary = {}

## Per segregating gene: expected (Mendelian) vs observed class fractions.
## Each entry: {gene, symbol, scope, classes: [{label, expected, observed, observed_frac, survival}]}
var per_gene: Array = []

var explanation: Array[String] = []

func survival_rate() -> float:
	return float(survivors) / float(max(requested, 1))
