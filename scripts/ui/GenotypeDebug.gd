extends Control
## GenotypeDebug — Phase 1 debug panel (spec DoD: "inspect genotype in debug panel").
##
## Builds wild-type and mutant flies from the Catalog, dumps their genotype in a
## human-readable form, and round-trips one fly through SaveLoadService to prove
## save/load preserves the genome. This is a verification screen, not gameplay.

const LAB_DASHBOARD_SCENE := "res://scenes/LabDashboard.tscn"

@onready var _output: RichTextLabel = %Output
@onready var _status: Label = %Status

var _current_fly: Fly

func _ready() -> void:
	if not Catalog.is_ready():
		_output.text = "[color=#d97]Catalog not loaded — check data/genes.json and data/alleles.json.[/color]"
		return
	_show_wild_type_female()

# --- Build buttons -----------------------------------------------------------

func _on_wild_female_pressed() -> void:
	_show_wild_type_female()

func _show_wild_type_female() -> void:
	_set_fly(FlyFactory.create_wild_type(Genome.FEMALE), "Wild-type female")

func _on_wild_male_pressed() -> void:
	_set_fly(FlyFactory.create_wild_type(Genome.MALE), "Wild-type male")

func _on_white_male_pressed() -> void:
	# X-linked recessive shown in a male with a single X (hemizygous).
	_set_fly(
		FlyFactory.create_mutant("w", "w_null", FlyFactory.Zygosity.HOMOZYGOUS, Genome.MALE),
		"white-eyed male (X-linked, hemizygous)")

func _on_vg_homozygous_pressed() -> void:
	_set_fly(
		FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HOMOZYGOUS, Genome.FEMALE),
		"vestigial homozygous female")

func _on_vg_carrier_pressed() -> void:
	# Heterozygous carrier: looks wild-type but carries one recessive copy.
	_set_fly(
		FlyFactory.create_mutant("vg", "vg_strong_loss", FlyFactory.Zygosity.HETEROZYGOUS, Genome.FEMALE),
		"vestigial heterozygous carrier female")

func _on_antp_het_pressed() -> void:
	# Dominant allele: one copy is enough to express.
	_set_fly(
		FlyFactory.create_mutant("Antp", "Antp_dom_gof", FlyFactory.Zygosity.HETEROZYGOUS, Genome.FEMALE),
		"Antennapedia dominant heterozygote female")

# --- Save/load round trip ----------------------------------------------------

func _on_save_reload_pressed() -> void:
	if _current_fly == null:
		return
	var before := _current_fly.to_dict()
	SaveLoadService.save_game("debug_fly", {"fly": before})

	var envelope := SaveLoadService.load_game("debug_fly")
	if envelope.is_empty() or not envelope.get("data", {}).has("fly"):
		_status.text = "Save/load FAILED: nothing read back."
		return

	var reloaded := Fly.from_dict(envelope["data"]["fly"])
	var after := reloaded.to_dict()
	var identical := JSON.stringify(before) == JSON.stringify(after)
	_status.text = "Save/load round trip: %s (slot 'debug_fly')" % \
		("genome preserved ✓" if identical else "MISMATCH ✗")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(LAB_DASHBOARD_SCENE)

# --- Rendering ---------------------------------------------------------------

func _set_fly(fly: Fly, title: String) -> void:
	_current_fly = fly
	_output.text = _describe(fly, title)
	_status.text = ""

## Produces a bbcode genotype dump. Formatting lives here (UI), not in the sim
## classes, to keep simulation code free of presentation concerns.
func _describe(fly: Fly, title: String) -> String:
	var lines: Array[String] = []
	lines.append("[b]%s[/b]   id: %s   sex: %s   generation: %d"
		% [title, fly.id, fly.sex(), fly.generation])
	lines.append("")
	lines.append("[b]Genotype by gene[/b] (genome carries alleles; phenotype is computed in Phase 2):")

	for gene: Gene in Catalog.all_genes():
		var genotype := fly.genome.genotype_at(gene.id)
		var names: Array[String] = []
		var is_mutant := false
		for allele_id in genotype:
			var allele: Allele = Catalog.get_allele(allele_id)
			names.append(allele.display_name if allele else allele_id)
			if allele and not allele.is_wild_type():
				is_mutant = true

		var zyg := _zygosity_label(fly.genome, gene.id)
		var allele_text := " / ".join(names) if not names.is_empty() else "(unplaced)"
		var line := "  %s (%s) [%s]: %s — %s" \
			% [gene.display_name, gene.symbol, gene.chromosome, allele_text, zyg]
		if is_mutant:
			line = "[color=#e6b85c]%s[/color]" % line  # highlight mutant loci
		lines.append(line)

	lines.append("")
	lines.append("[i]Mutant loci are highlighted. Wild-type loci carry the reference allele.[/i]")
	return "\n".join(lines)

func _zygosity_label(genome: Genome, gene_id: String) -> String:
	if genome.is_hemizygous(gene_id):
		return "hemizygous"
	return "homozygous" if genome.is_homozygous(gene_id) else "heterozygous"
