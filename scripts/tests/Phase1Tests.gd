extends Node
## Phase1Tests — headless verification of the Phase 1 data model.
##
## Run with:
##   Godot --headless --path . res://scenes/Phase1Tests.tscn --quit-after 5
##
## Prints PASS/FAIL for each Definition-of-Done item. This is the seed of the
## fuller Debug Test Runner described in spec section 23 (expanded in later phases).

var _passed := 0
var _failed := 0

func _ready() -> void:
	print("\n==== Phase 1 tests ====")

	_check("Catalog: >= 10 genes loaded from JSON", Catalog.gene_count() >= 10)
	_check("Catalog: >= 20 alleles loaded from JSON", Catalog.allele_count() >= 20)
	_check("Every gene has a wild-type allele", _every_gene_has_wild_type())

	# Create a wild-type fly: all loci homozygous wild-type.
	var wt := FlyFactory.create_wild_type(Genome.FEMALE)
	_check("Wild-type fly built", wt != null and wt.genome.placed_gene_ids().size() == Catalog.gene_count())
	_check("Wild-type 'w' is homozygous wild-type", _is_all_wild_type(wt, "w"))

	# Create a mutant (homozygous vestigial).
	var vg := FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE)
	var vg_geno := vg.genome.genotype_at("vg")
	_check("Mutant vestigial homozygous (both copies mutant)",
		vg_geno == ["vg_strong_loss", "vg_strong_loss"] and vg.genome.is_homozygous("vg"))

	# Heterozygous carrier: one mutant copy, one wild-type copy.
	var carrier := FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HETEROZYGOUS, Genome.FEMALE)
	var c_geno := carrier.genome.genotype_at("vg")
	_check("Carrier is heterozygous (one mutant, one wild-type)",
		c_geno.size() == 2 and c_geno.has("vg_strong_loss") and c_geno.has("vg_plus")
		and not carrier.genome.is_homozygous("vg"))

	# X-linked male: single X copy -> hemizygous.
	var male := FlyFactory.create_mutant("w", "w_null", FlyFactory.Zygosity.HOMOZYGOUS, Genome.MALE)
	_check("Male X-linked 'w' is hemizygous (single allele)",
		male.genome.is_hemizygous("w") and male.genome.genotype_at("w") == ["w_null"])
	_check("Male has one X and one Y copy",
		male.genome.copies_of("X").size() == 1 and male.genome.copies_of("Y").size() == 1)
	_check("Female has two X copies",
		wt.genome.copies_of("X").size() == 2)

	# Save/load one fly preserves the genome.
	var before := vg.to_dict()
	SaveLoadService.save_game("phase1_test_fly", {"fly": before})
	var env := SaveLoadService.load_game("phase1_test_fly")
	var reloaded_ok := false
	if not env.is_empty() and env.get("data", {}).has("fly"):
		var reloaded := Fly.from_dict(env["data"]["fly"])
		reloaded_ok = JSON.stringify(reloaded.to_dict()) == JSON.stringify(before)
	_check("Save/load preserves genotype", reloaded_ok)
	SaveLoadService.delete_save("phase1_test_fly")

	# Reproducibility: same seed -> same sequence.
	RandomService.seed_with(12345)
	var seq_a := [RandomService.randf(), RandomService.randf(), RandomService.randf()]
	RandomService.seed_with(12345)
	var seq_b := [RandomService.randf(), RandomService.randf(), RandomService.randf()]
	_check("Same seed reproduces the same random sequence", seq_a == seq_b)

	RandomService.seed_with(99999)
	var seq_c := [RandomService.randf(), RandomService.randf(), RandomService.randf()]
	_check("Different seed yields a different sequence", seq_a != seq_c)

	print("==== %d passed, %d failed ====\n" % [_passed, _failed])

func _check(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  PASS  %s" % label)
	else:
		_failed += 1
		print("  FAIL  %s" % label)

func _every_gene_has_wild_type() -> bool:
	for g in Catalog.all_genes():
		if Catalog.wild_type_allele_for(g.id) == null:
			return false
	return true

func _is_all_wild_type(fly: Fly, gene_id: String) -> bool:
	for allele_id in fly.genome.genotype_at(gene_id):
		var a: Allele = Catalog.get_allele(allele_id)
		if a == null or not a.is_wild_type():
			return false
	return true
