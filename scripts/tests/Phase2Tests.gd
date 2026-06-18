extends Node
## Phase2Tests — headless verification of the PhenotypeEngine.
##
## Run with:
##   Godot --headless --path . res://scenes/Phase2Tests.tscn --quit-after 5
##
## Uses fixed roll_seed values so penetrance/expressivity rolls are deterministic
## (so the checks don't flake). Reproducibility itself is checked separately.

const SEED := 4242  # an arbitrary fixed seed where the penetrant alleles express

var _passed := 0
var _failed := 0

func _ready() -> void:
	print("\n==== Phase 2 tests ====")

	# Wild-type fly: every trait sits within its normal band.
	var wt := FlyFactory.create_wild_type(Genome.FEMALE)
	PhenotypeEngine.compute(wt, null, SEED)
	_check("Wild-type fly: all traits within normal range", _all_normal(wt))
	_check("Wild-type explanation generated", wt.phenotype.explanation.size() > 0)
	_check("Wild-type eye_color is full (red)", is_equal_approx(wt.phenotype.get_trait("eye_color"), 1.0))

	# white (X-linked) in a male → white eyes (eye_color drops to ~0).
	var white_male := FlyFactory.create_mutant("w", "w_null", FlyFactory.Zygosity.HOMOZYGOUS, Genome.MALE)
	PhenotypeEngine.compute(white_male, null, SEED)
	_check("white male: eye_color reduced to ~0",
		white_male.phenotype.get_trait("eye_color") < 0.05)
	_check("white male: explanation mentions X chromosome",
		_explanation_contains(white_male, "X"))

	# vestigial homozygous → wing_size reduced below normal.
	var vg := FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE)
	PhenotypeEngine.compute(vg, null, SEED)
	_check("vestigial homozygous: wing_size reduced",
		vg.phenotype.get_trait("wing_size") < 0.85)
	_check("vestigial homozygous: flight_ability reduced",
		vg.phenotype.get_trait("flight_ability") < 0.8)

	# vestigial heterozygous carrier → wing_size normal (recessive masked).
	var vg_carrier := FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HETEROZYGOUS, Genome.FEMALE)
	PhenotypeEngine.compute(vg_carrier, null, SEED)
	_check("vestigial carrier (het): wing_size stays normal (recessive masked)",
		vg_carrier.phenotype.get_trait("wing_size") >= 0.85)
	_check("vestigial carrier: explanation flags a hidden carrier",
		_explanation_contains(vg_carrier, "hidden carrier"))

	# yellow / ebony move body_color in opposite directions from wild-type 0.5.
	var yellow := FlyFactory.create_mutant("y", "y_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE)
	PhenotypeEngine.compute(yellow, null, SEED)
	_check("yellow homozygous: body_color lighter (< 0.5)",
		yellow.phenotype.get_trait("body_color") < 0.5)

	var ebony := FlyFactory.create_mutant("e", "e_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE)
	PhenotypeEngine.compute(ebony, null, SEED)
	_check("ebony homozygous: body_color darker (> 0.5)",
		ebony.phenotype.get_trait("body_color") > 0.5)

	# Antennapedia dominant heterozygote expresses (dominant: one copy is enough).
	var antp := FlyFactory.create_mutant("Antp", "Antp_dom_gof", FlyFactory.Zygosity.HETEROZYGOUS, Genome.FEMALE)
	PhenotypeEngine.compute(antp, null, SEED)
	_check("Antp dominant het: antenna_shape altered",
		antp.phenotype.get_trait("antenna_shape") < 1.0)

	# Reproducibility: same seed + same genotype → identical traits.
	var a := FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE)
	var b := FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE)
	PhenotypeEngine.compute(a, null, 9001)
	PhenotypeEngine.compute(b, null, 9001)
	_check("Same seed gives same phenotype", a.phenotype.traits == b.phenotype.traits)

	# Different seeds can give different expressivity for a variable allele.
	var c1 := FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE)
	var c2 := FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE)
	PhenotypeEngine.compute(c1, null, 100)
	PhenotypeEngine.compute(c2, null, 200)
	_check("Different seeds can vary expressivity",
		c1.phenotype.get_trait("wing_size") != c2.phenotype.get_trait("wing_size"))

	print("==== %d passed, %d failed ====\n" % [_passed, _failed])

func _all_normal(fly: Fly) -> bool:
	for tr: TraitRule in Catalog.all_traits():
		if not tr.is_within_normal(fly.phenotype.get_trait(tr.id)):
			return false
	return true

func _explanation_contains(fly: Fly, needle: String) -> bool:
	for line in fly.phenotype.explanation:
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
