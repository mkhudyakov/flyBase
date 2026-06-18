extends Node
## Phase5Tests — headless verification of the InheritanceEngine.
##
## Run with:
##   Godot --headless --path . res://scenes/Phase5Tests.tscn --quit-after 5

const SEED := 20240

var _passed := 0
var _failed := 0

func _ready() -> void:
	print("\n==== Phase 5 tests ====")
	var std := VialEnvironment.standard()

	# --- Counts ---
	for n in [10, 100, 1000]:
		var r := InheritanceEngine.cross(_wt(Genome.FEMALE), _wt(Genome.MALE), n, std, SEED)
		_check("Cross produces exactly %d offspring" % n, r.offspring.size() == n)

	# --- Wild × wild: all wild-type, both sexes appear ---
	var wr := InheritanceEngine.cross(_wt(Genome.FEMALE), _wt(Genome.MALE), 200, std, SEED)
	_check("Wild × wild offspring are all wild-type", wr.genotype_dist.size() == 1 and wr.genotype_dist.has("all wild-type"))
	_check("Both sexes are produced", wr.sex_counts["female"] > 0 and wr.sex_counts["male"] > 0)
	_check("Wild × wild survival is high (>0.9)", wr.survival_rate() > 0.9)

	# --- True-breeding: vg/vg × vg/vg → all vg/vg ---
	var vv := InheritanceEngine.cross(
		_mut("vg", "vg_strong_loss", true, Genome.FEMALE),
		_mut("vg", "vg_strong_loss", true, Genome.MALE), 100, std, SEED)
	_check("vg/vg × vg/vg → all offspring vg/vg",
		_all_have_genotype(vv, "vg", ["vg_strong_loss", "vg_strong_loss"]))

	# --- X-linked criss-cross: white ♀ × wild ♂ ---
	# Daughters become carriers (w_null/w_plus); sons are white (hemizygous w_null).
	var cc := InheritanceEngine.cross(
		_mut("w", "w_null", true, Genome.FEMALE), _wt(Genome.MALE), 300, std, SEED)
	_check("X-linked: all daughters are w carriers",
		_all_sex_genotype(cc, Genome.FEMALE, "w", ["w_null", "w_plus"]))
	_check("X-linked: all sons are hemizygous white",
		_all_sex_genotype(cc, Genome.MALE, "w", ["w_null"]))

	# --- Monohybrid 3:1 (genotype 1:2:1) ---
	var f2 := InheritanceEngine.cross(
		_mut("vg", "vg_strong_loss", false, Genome.FEMALE),
		_mut("vg", "vg_strong_loss", false, Genome.MALE), 1000, std, SEED)
	var vg_hom := _fraction_genotype(f2, "vg", ["vg_strong_loss", "vg_strong_loss"])
	_check("vg/+ × vg/+ : ~25%% homozygous mutant (got %.2f)" % vg_hom, absf(vg_hom - 0.25) < 0.06)

	# --- Reproducibility ---
	var a := InheritanceEngine.cross(_mut("vg", "vg_strong_loss", false, Genome.FEMALE),
		_mut("vg", "vg_strong_loss", false, Genome.MALE), 200, std, 777)
	var b := InheritanceEngine.cross(_mut("vg", "vg_strong_loss", false, Genome.FEMALE),
		_mut("vg", "vg_strong_loss", false, Genome.MALE), 200, std, 777)
	_check("Same seed reproduces identical genotype distribution", a.genotype_dist == b.genotype_dist)

	# --- Lethal deviation: bcd/+ × bcd/+ ---
	var bcd := InheritanceEngine.cross(
		_mut("bcd", "bcd_loss", false, Genome.FEMALE),
		_mut("bcd", "bcd_loss", false, Genome.MALE), 1000, std, SEED)
	var bcd_conceived := _fraction_genotype(bcd, "bcd", ["bcd_loss", "bcd_loss"])
	var bcd_survivors := _fraction_survivor_genotype(bcd, "bcd", ["bcd_loss", "bcd_loss"])
	_check("bcd/+ × bcd/+ : ~25%% conceived homozygous (got %.2f)" % bcd_conceived, absf(bcd_conceived - 0.25) < 0.07)
	_check("bcd/bcd homozygotes mostly die (survivor fraction < 0.05, got %.2f)" % bcd_survivors, bcd_survivors < 0.05)
	_check("Lethal cross lowers overall survival (<0.85)", bcd.survival_rate() < 0.85)
	_check("Deviation is explained", _explanation_contains(bcd, "deviate"))

	print("==== %d passed, %d failed ====\n" % [_passed, _failed])

# --- builders ---
func _wt(sex: String) -> Fly:
	return FlyFactory.create_wild_type(sex)

func _mut(g: String, a: String, hom: bool, sex: String) -> Fly:
	var z := FlyFactory.Zygosity.HOMOZYGOUS if hom else FlyFactory.Zygosity.HETEROZYGOUS
	return FlyFactory.create_mutant(g, a, z, sex)

# --- assertions ---
func _all_have_genotype(r: CrossResult, gene: String, expected: Array) -> bool:
	for c: Fly in r.offspring:
		if _sorted_geno(c, gene) != expected:
			return false
	return true

func _all_sex_genotype(r: CrossResult, sex: String, gene: String, expected: Array) -> bool:
	var any := false
	for c: Fly in r.offspring:
		if c.sex() != sex:
			continue
		any = true
		if _sorted_geno(c, gene) != expected:
			return false
	return any

func _fraction_genotype(r: CrossResult, gene: String, expected: Array) -> float:
	var n := 0
	for c: Fly in r.offspring:
		if _sorted_geno(c, gene) == expected:
			n += 1
	return float(n) / float(max(r.offspring.size(), 1))

func _fraction_survivor_genotype(r: CrossResult, gene: String, expected: Array) -> float:
	var n := 0
	for c: Fly in r.offspring:
		if c.alive and _sorted_geno(c, gene) == expected:
			n += 1
	return float(n) / float(max(r.survivors, 1))

func _sorted_geno(fly: Fly, gene: String) -> Array:
	var g := fly.genome.genotype_at(gene)
	var copy := g.duplicate()
	copy.sort()
	return copy

func _explanation_contains(r: CrossResult, needle: String) -> bool:
	for line in r.explanation:
		if needle.to_lower() in String(line).to_lower():
			return true
	return false

func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % label)
	else:
		_failed += 1
		print("  FAIL  %s" % label)
