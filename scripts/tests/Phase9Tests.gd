extends Node
## Phase9Tests — headless verification of advanced genetics.
##
## Run with:
##   Godot --headless --path . res://scenes/Phase9Tests.tscn --quit-after 5

const SEED := 4242

var _passed := 0
var _failed := 0

func _ready() -> void:
	print("\n==== Phase 9 tests ====")

	# --- Epistasis: eyeless masks eye color ---
	var ey := FlyFactory.create_mutant("ey", "ey_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE)
	PhenotypeEngine.compute(ey, null, SEED)
	_check("Eyeless fly has near-zero eye size", ey.phenotype.get_trait("eye_size") < 0.25)
	_check("Epistasis masks eye_color", ey.phenotype.is_masked("eye_color"))
	_check("Masked eye shows as 'no-eye'", StatisticsEngine.visible_dims(ey)["eye"] == "no-eye")

	# --- Modifier: suppressor rescues, enhancer worsens (vs plain vestigial) ---
	var plain := FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE)
	var suppressed := FlyFactory.create_multi([
		{"gene": "vg", "allele": "vg_strong_loss", "zyg": "hom"},
		{"gene": "wing_mod", "allele": "wm_suppressor", "zyg": "het"}], Genome.FEMALE)
	var enhanced := FlyFactory.create_multi([
		{"gene": "vg", "allele": "vg_strong_loss", "zyg": "hom"},
		{"gene": "wing_mod", "allele": "wm_enhancer", "zyg": "het"}], Genome.FEMALE)
	PhenotypeEngine.compute(plain, null, SEED)
	PhenotypeEngine.compute(suppressed, null, SEED)
	PhenotypeEngine.compute(enhanced, null, SEED)
	_check("Suppressor rescues wing size (larger than unmodified)",
		suppressed.phenotype.get_trait("wing_size") > plain.phenotype.get_trait("wing_size"))
	_check("Enhancer worsens wing size (smaller than unmodified)",
		enhanced.phenotype.get_trait("wing_size") < plain.phenotype.get_trait("wing_size") + 0.0001)

	# --- Polygenic body size: additive across loci ---
	var neutral := FlyFactory.create_wild_type(Genome.FEMALE)
	var het_all := FlyFactory.create_multi([
		{"gene": "size_a", "allele": "size_a_large", "zyg": "het"},
		{"gene": "size_b", "allele": "size_b_large", "zyg": "het"},
		{"gene": "size_c", "allele": "size_c_large", "zyg": "het"}], Genome.FEMALE)
	var hom_all := FlyFactory.create_multi([
		{"gene": "size_a", "allele": "size_a_large", "zyg": "hom"},
		{"gene": "size_b", "allele": "size_b_large", "zyg": "hom"},
		{"gene": "size_c", "allele": "size_c_large", "zyg": "hom"}], Genome.FEMALE)
	PhenotypeEngine.compute(neutral, null, SEED)
	PhenotypeEngine.compute(het_all, null, SEED)
	PhenotypeEngine.compute(hom_all, null, SEED)
	var bn := neutral.phenotype.get_trait("body_size")
	var bh := het_all.phenotype.get_trait("body_size")
	var bhom := hom_all.phenotype.get_trait("body_size")
	_check("Body size is polygenic: heterozygous large > neutral", bh > bn + 0.05)
	_check("Body size is polygenic: homozygous large > heterozygous", bhom > bh + 0.05)
	_check("Stacking three loci yields a large fly (>=1.3)", bhom >= 1.3)

	# --- Temperature-sensitive allele: environment reveals the phenotype ---
	var ts := FlyFactory.create_mutant("vg", "vg_ts", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE)
	var cool := VialEnvironment.standard(); cool.temperature_c = 18.0
	var warm := VialEnvironment.standard(); warm.temperature_c = 30.0
	PhenotypeEngine.compute(ts, cool, SEED)
	var flight_cool := ts.phenotype.get_trait("flight_ability")
	PhenotypeEngine.compute(ts, warm, SEED)
	var flight_warm := ts.phenotype.get_trait("flight_ability")
	_check("TS allele inactive when cool (flight normal)", flight_cool > 0.8)
	_check("TS allele active when warm (flight reduced)", flight_warm < 0.5)
	_check("Environment reveals the hidden genotype", flight_cool - flight_warm > 0.3)

	# --- Challenge scenarios present and gated ---
	var advanced := ["epistasis_eye", "temperature_challenge", "polygenic_size"]
	var all_present := true
	for id in advanced:
		if Campaign.get_scenario(id).is_empty():
			all_present = false
	_check("At least 3 advanced challenge scenarios exist", all_present)
	_check("Advanced challenge is locked until prerequisites done",
		not _fresh_campaign_unlocked("epistasis_eye"))

	print("==== %d passed, %d failed ====\n" % [_passed, _failed])

func _fresh_campaign_unlocked(id: String) -> bool:
	var was := Campaign.completed.duplicate()
	Campaign.completed.clear()
	var u := Campaign.is_unlocked(id)
	Campaign.completed.assign(was)
	return u

func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % label)
	else:
		_failed += 1
		print("  FAIL  %s" % label)
