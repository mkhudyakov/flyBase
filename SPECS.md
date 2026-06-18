# Product Specification: Drosophila Genetics Lab Simulator

## 0. Product vision

Build a full Godot 4 game called **Drosophila Genetics Lab Simulator**.

This is a deep, science-inspired simulation game about fruit fly genetics, development, inheritance, mutation, environmental stress, phenotype expression, and multi-generation experiments.

The player runs a virtual genetics lab. They do not perform real gene editing. Instead, they work with an abstract computational model of Drosophila genes, alleles, developmental modules, environmental conditions, and inheritance patterns.

The game should feel like:

* Kerbal Space Program, but for genetics: complex systems, failure, learning through experiments.
* Plague Inc. style systemic simulation, but educational and laboratory-based.
* A scientific “creature breeder” where outcomes are explainable, not random magic.
* A dry-lab genetics sandbox, not a wet-lab protocol simulator.

The end product should be a serious, replayable simulation game, not a weak prototype.

## 1. Critical safety and scientific boundary

This game must never provide real-world biological modification instructions.

Do not implement or describe:

* CRISPR guide RNA design
* primers
* injection protocols
* transformation methods
* real wet-lab steps
* reagent lists
* gene drive implementation
* real organism engineering workflow
* instructions for physically modifying flies or any organism

All editing in the game is abstract and virtual.

Use terms like:

* abstract allele editor
* simulated genotype
* virtual mutation
* developmental module
* dry-lab experiment
* computational phenotype model

Avoid terms like:

* real CRISPR editor
* wet lab protocol
* guide RNA
* embryo injection
* transformation protocol

Add a visible in-game disclaimer:

> This is a simplified educational dry-lab simulation inspired by Drosophila genetics. It does not simulate the full genome, does not provide real gene-editing instructions, and must not be used for real biological or medical decisions.

## 2. Target platform

Use:

* Godot 4.x
* GDScript
* 2D UI
* macOS-compatible project
* no paid assets
* no runtime web APIs
* no C#
* no real downloadable genome database dependency

The game should run from the Godot editor and also be exportable later.

The project must include:

* project.godot
* all scenes
* all scripts
* data files
* README.md
* example experiments
* test/debug scenes
* save/load support

## 3. Core fantasy

The player is not a warrior. The player is a scientist managing a fly lab.

They create fly lines, cross flies, observe offspring, investigate mutations, and try to solve research objectives.

The fun comes from:

* predicting inheritance
* being surprised by epistasis
* discovering hidden genotype effects
* managing fragile fly lines
* rescuing traits across generations
* building stable mutant lines
* balancing viability vs desired phenotype
* comparing expected vs observed ratios
* publishing virtual findings
* unlocking better models and instruments
* solving campaign scenarios

## 4. Game modes

### 4.1 Campaign mode

A structured sequence of research scenarios.

Example chapters:

1. Foundations of inheritance
2. Eye color mystery
3. Why did the wings disappear?
4. Hidden carriers
5. Lethal recessives
6. Temperature-sensitive mutants
7. Developmental catastrophe
8. Rescue cross
9. Polygenic body size
10. Selection over ten generations
11. Environmental stress experiment
12. Build a stable flightless line
13. Recover fertility
14. Explain unexpected F2 ratios
15. Final thesis project

### 4.2 Sandbox mode

The player can freely:

* create flies
* edit abstract alleles
* set environment
* run crosses
* simulate generations
* inspect phenotype
* export data
* create custom experiments

### 4.3 Challenge mode

Prebuilt puzzles with success conditions.

Examples:

* Produce 25% white-eyed offspring.
* Identify whether a trait is dominant or recessive.
* Determine if a lethal allele is present.
* Maintain a lethal allele in a line without losing it.
* Create a viable line with reduced wings and high fertility.
* Explain why expected Mendelian ratios failed.
* Find the environmental trigger for a temperature-sensitive phenotype.

### 4.4 Free observation mode

A non-game educational mode:

* select gene
* select allele
* observe predicted effects
* compare genotype and phenotype
* view inheritance explanation

## 5. Full simulation pillars

The game has six major simulation pillars:

1. Genetics engine
2. Development engine
3. Phenotype engine
4. Environment engine
5. Population/inheritance engine
6. Lab/game progression engine

Each pillar must be implemented as a separate subsystem.

## 6. Biological abstraction model

Do not model the full DNA sequence letter by letter.

Instead, model:

* chromosomes
* genes
* alleles
* dominance
* penetrance
* expressivity
* pleiotropy
* epistasis
* sex linkage
* recombination
* developmental stages
* environment effects
* stochastic biological noise

Use Drosophila melanogaster as the base organism.

Simplified chromosomes:

* X
* 2L
* 2R
* 3L
* 3R
* 4

Simplified sex model:

* Female: XX
* Male: XY

For the first implementation, the Y chromosome can be mostly ignored except for male sex and optional male fertility modifiers.

## 7. Gene catalog design

The gene catalog must be data-driven.

Use files like:

```text
res://data/genes.json
res://data/alleles.json
res://data/trait_rules.json
res://data/epistasis_rules.json
res://data/development_stages.json
res://data/scenarios.json
```

Each gene should have:

* id
* display_name
* symbol
* chromosome
* position
* biological_category
* description
* affected_modules
* essentiality
* risk_level
* educational_note
* is_real_gene_name
* is_simulator_abstraction

Initial real-gene-inspired set:

1. white / w
2. yellow / y
3. ebony / e
4. vestigial / vg
5. eyeless / ey
6. Antennapedia / Antp
7. wingless / wg
8. Notch / N
9. Ultrabithorax / Ubx
10. nanos / nos
11. bicoid / bcd
12. hedgehog / hh
13. decapentaplegic / dpp
14. doublesex / dsx
15. period / per
16. dunce / dnc

Simulator abstraction genes/modules:

17. metabolism_core
18. stress_response
19. starvation_tolerance
20. immune_resilience
21. bristle_pattern_module
22. wing_vein_module
23. larval_growth_rate
24. pupal_remodeling_stability
25. fertility_balance
26. courtship_behavior
27. vision_processing
28. locomotion_control
29. thermal_tolerance
30. developmental_buffering

The game must clearly label fictional/simplified modules as abstractions.

## 8. Allele system

Each gene can have multiple alleles.

Allele types:

* wild_type
* loss_of_function
* null
* hypomorphic
* hypermorphic
* gain_of_function
* dominant_negative
* regulatory_variant
* temperature_sensitive
* conditional_lethal
* recessive_lethal
* semi_dominant
* modifier
* suppressor
* enhancer

Each allele should define:

* id
* gene_id
* display_name
* mutation_type
* dominance_model
* severity
* penetrance
* expressivity_min
* expressivity_max
* affected_traits
* affected_development_modules
* stage_sensitivity
* environment_sensitivity
* viability_impact
* fertility_impact
* behavior_impact
* educational_note
* risk_warning

Example:

```json
{
  "gene_id": "vg",
  "allele_id": "vg_strong_loss",
  "display_name": "vestigial strong loss-of-function",
  "mutation_type": "loss_of_function",
  "dominance_model": "recessive",
  "severity": 0.8,
  "penetrance": 0.95,
  "expressivity_min": 0.65,
  "expressivity_max": 1.0,
  "affected_traits": {
    "wing_size": -0.75,
    "flight_ability": -0.9,
    "mating_success": -0.25
  },
  "affected_development_modules": {
    "wing_disc_development": -0.6
  },
  "stage_sensitivity": ["larva_3", "pupa"],
  "environment_sensitivity": {
    "temperature_high": 0.1,
    "nutrition_low": 0.15
  },
  "viability_impact": -0.05,
  "fertility_impact": -0.15,
  "educational_note": "A simplified model inspired by vestigial wing phenotypes.",
  "risk_warning": "Functional phenotype, usually viable but flight-impaired."
}
```

## 9. Trait system

Separate genotype from phenotype.

Phenotype traits must include visible, functional, developmental, and behavioral traits.

Visible traits:

* eye_color
* eye_size
* eye_shape
* wing_size
* wing_shape
* wing_vein_quality
* body_color
* body_size
* bristle_count
* bristle_pattern
* antenna_shape
* leg_shape
* abdomen_shape
* segment_identity
* deformity_score

Functional traits:

* viability_score
* fertility_score
* flight_ability
* locomotion_score
* vision_score
* mating_success
* lifespan_days
* starvation_tolerance
* thermal_tolerance
* immune_resilience
* developmental_stability
* metabolic_efficiency

Behavioral traits:

* light_preference
* activity_level
* courtship_score
* escape_response
* sleep_cycle_stability
* feeding_behavior

Each trait should store:

* numeric value
* normal range
* visible label
* explanation
* contributing factors
* confidence/uncertainty

Phenotype output must never be a black box.

Every major phenotype must include an explanation log.

Example:

```text
Wing size is severely reduced because the fly is homozygous for a strong vestigial loss-of-function allele. Low larval nutrition further reduced wing-disc growth. Flight ability is near zero, but overall viability remains moderate.
```

## 10. Development engine

Simulate stages:

1. egg
2. embryo_early
3. embryo_late
4. larva_1
5. larva_2
6. larva_3
7. pupa_early
8. pupa_late
9. adult_eclosion
10. adult

Each stage has:

* expected duration
* temperature scaling
* required energy
* sensitive genes/modules
* failure thresholds
* phenotype module updates
* log events

Development modules:

* axis_patterning
* segment_identity
* nervous_system
* eye_imaginal_disc
* wing_imaginal_disc
* leg_imaginal_disc
* antenna_identity
* gut_development
* muscle_development
* cuticle_pigmentation
* bristle_development
* gonad_development
* metabolic_maturation
* pupal_remodeling
* adult_eclosion_readiness

Failure outcomes:

* embryonic arrest
* axis pattern failure
* larval arrest
* metabolic collapse
* pupal lethality
* failed metamorphosis
* adult eclosion failure
* sterile adult
* viable but impaired adult
* short-lived adult

Failure must be explained.

Example:

```text
Development stopped during pupa_late. Wing imaginal disc development was below the minimum threshold, and pupal remodeling stability collapsed due to combined wg disruption and high temperature stress.
```

## 11. Environment engine

Environment is not cosmetic. It should modify development and phenotype.

Environment variables:

* temperature_c
* food_quality
* food_quantity
* crowding
* humidity
* infection_pressure
* toxin_exposure
* radiation_exposure
* light_cycle
* stress_level
* vial_cleanliness

Effects:

* low food reduces body size, fertility, survival
* high crowding reduces larval growth
* high temperature speeds development but increases stress
* low temperature slows development
* extreme temperature causes lethality
* infection pressure tests immune resilience
* toxin exposure increases developmental instability
* radiation exposure increases mutation chance and developmental damage
* light cycle affects behavior and activity rhythm

Environment should be configurable per vial/incubator.

## 12. Inheritance engine

Implement:

* Mendelian inheritance
* sex-linked inheritance
* simplified recombination
* chromosome linkage
* spontaneous mutation chance
* lethal allele survival filtering
* random seed reproducibility
* offspring sex ratio
* genotype and phenotype distributions
* expected vs observed ratios

Cross types:

* simple cross
* test cross
* backcross
* sibling cross
* selected cross
* line maintenance cross
* multi-generation batch cross

The player should be able to generate:

* 10 offspring
* 50 offspring
* 100 offspring
* 1000 offspring
* custom count, with performance safeguards

The output should include:

* genotype distribution
* phenotype distribution
* survival rate
* sex ratio
* fertility rate
* interesting outliers
* expected ratio
* observed ratio
* explanation of deviation

## 13. Advanced genetics systems

Add these after the foundation works:

### 13.1 Penetrance

A genotype does not always produce a phenotype.

Example:

```text
This allele has 70% penetrance. 30% of flies with this genotype may appear normal.
```

### 13.2 Expressivity

The same genotype can produce different severity.

Example:

```text
Wing reduction varies from mild to severe.
```

### 13.3 Epistasis

One gene can mask or modify another.

Examples:

* eye development failure masks eye pigment color
* severe wg disruption overrides wing-shape genes
* Antp appendage identity defects override normal antenna/leg traits
* metabolism defects reduce body size and indirectly reduce fertility

### 13.4 Pleiotropy

One gene affects multiple traits.

Examples:

* wing gene affects wing size, flight, mating success
* pigment gene affects body color and behavior slightly
* metabolism gene affects size, survival, fertility, lifespan

### 13.5 Genetic modifiers

Add enhancer and suppressor alleles.

Example:

```text
Suppressor allele reduces severity of wing defect by 30%.
```

### 13.6 Polygenic traits

Traits like body size, thermal tolerance, and starvation tolerance should depend on multiple genes.

### 13.7 Hidden carriers

Some flies look normal but carry recessive alleles.

This is important for gameplay puzzles.

### 13.8 Lethal alleles

Some genotypes do not survive to adult stage.

The game should model:

* embryonic lethal
* larval lethal
* pupal lethal
* adult sterile
* adult short-lived

### 13.9 Line stability

Some lines are hard to maintain because desired traits reduce fertility or viability.

## 14. Lab management layer

The game should not be only a calculator.

Add a virtual lab with:

* fly vials
* incubators
* microscope
* freezer/archive
* notebook
* experiment planner
* lineage board
* statistics station
* grant/project board

Resources:

* lab budget
* reputation
* research points
* publication score
* incubator capacity
* vial capacity
* staff time
* data quality

Do not include real wet-lab protocols. Treat all equipment as abstract game systems.

Example lab actions:

* create vial
* move flies to vial
* select breeding pair
* set incubator temperature
* inspect under microscope
* archive fly line
* publish virtual report
* compare expected vs observed result
* request virtual peer review

## 15. Research progression

The player unlocks better abstractions, not real lab methods.

Unlocks:

* better microscope visualization
* improved phenotype scoring
* larger population simulations
* more genes
* more allele models
* better statistics
* lineage tracking
* hidden-carrier detection
* epistasis analysis
* environmental chamber
* automated batch crosses
* advanced charting
* custom scenario builder

Do not unlock real biological protocols.

## 16. Game progression structure

The full product should be built around research arcs.

### Arc 1: Basic inheritance

Player learns:

* dominant/recessive
* homozygous/heterozygous
* carriers
* simple crosses

### Arc 2: Development matters

Player learns:

* not all genes are cosmetic
* some mutations break development
* stage-specific effects
* lethality

### Arc 3: Environment matters

Player learns:

* temperature changes timing and phenotype
* nutrition changes body size and survival
* crowding changes outcomes

### Arc 4: Complex traits

Player learns:

* polygenic inheritance
* modifiers
* penetrance
* expressivity
* epistasis

### Arc 5: Population and selection

Player learns:

* trait frequency
* selection pressure
* drift
* bottlenecks
* maintaining lines

### Arc 6: Research mastery

Player must solve multi-factor puzzles:

* unexpected F2 ratios
* hidden lethal allele
* rescue fertility
* stabilize fragile phenotype
* distinguish environment effect from genotype effect

## 17. User interface

### 17.1 Main menu

* Continue
* New Campaign
* Sandbox
* Challenges
* Tutorial Library
* Settings
* Quit

### 17.2 Lab dashboard

The central screen.

Shows:

* current lab
* active research objective
* vials
* incubators
* selected fly
* generation
* budget/reputation/research points
* warnings
* recent events

Actions:

* open genome browser
* open allele editor
* open microscope
* open cross planner
* open incubator
* open notebook
* open statistics
* open lineage tree

### 17.3 Genome browser

Shows:

* chromosomes
* gene cards
* allele pairs
* inheritance type
* gene function
* risk level
* known phenotype effects
* discovered/undiscovered information

Early in the campaign, some effects can be unknown until discovered.

### 17.4 Abstract allele editor

Sandbox-only or unlocked mode.

Allows:

* set wild type
* set known mutant allele
* randomize allele
* create virtual variant
* revert allele
* compare allele effect

Must show warnings:

* cosmetic
* functional
* developmental
* high lethality
* unknown interaction

### 17.5 Cross planner

Allows:

* choose female parent
* choose male parent
* choose offspring count
* choose environment
* choose simulation seed
* preview expected simple ratios where possible
* run cross

### 17.6 Development timeline

Shows:

* stage progression
* viability
* developmental stability
* energy balance
* stress level
* stage-specific gene warnings
* event log

### 17.7 Microscope viewer

Shows a rendered 2D fly.

Fly drawing must reflect:

* eye color
* eye size
* wing size
* wing shape
* wing veins
* body color
* body size
* bristles
* antenna defects
* leg defects
* severe morphology defects
* adult/failure status

Use generated vector-like shapes if no art assets exist.

### 17.8 Statistics screen

Charts/tables:

* phenotype distribution
* genotype distribution
* survival by genotype
* fertility by phenotype
* trait over generations
* observed vs expected ratio
* histogram of body size
* histogram of flight ability

### 17.9 Lineage tree

Shows:

* parents
* offspring
* generations
* selected trait markers
* carrier status where known
* dead/sterile/viable status
* archived lines

### 17.10 Lab notebook

Automatically records:

* crosses
* environment
* genotype assumptions
* offspring outcomes
* observations
* explanations
* charts
* campaign objective progress

Player can export a summary later.

## 18. Fly visualization

Use a procedural 2D fly renderer.

Do not depend on art assets.

Base fly:

* body ellipse
* abdomen ellipse
* head circle
* eyes as colored circles
* wings as translucent polygons
* legs as simple lines
* antennae as curves/lines
* bristles as tiny lines

Phenotype-driven rendering:

* eye_color changes eye fill color
* eye_size scales eye circles
* wing_size scales wing polygons
* wing_shape deforms wing outline
* body_color changes body fill
* bristle_count changes number of lines
* body_size scales body
* leg_shape changes leg length/angle
* antenna_shape changes antenna lines
* deformity_score adds asymmetry

Keep visuals clean, symbolic, and non-graphic.

## 19. Explanation engine

Every simulation result must explain itself.

Create an ExplanationEngine that records:

* allele effects
* dominance interpretation
* penetrance roll
* expressivity value
* environmental modifiers
* epistasis rules
* development failures
* inherited allele origin
* why a trait changed
* why a fly died or became sterile

The explanation should be human-readable.

Example:

```text
Eye color: white.
Reason: This male fly inherited a mutant white allele on its single X chromosome. Because males have only one X chromosome in this simplified model, the recessive allele is expressed.
```

Example:

```text
Observed F2 ratio differs from simple 3:1 because homozygous mutants have reduced viability. Many expected mutant offspring died during pupal development.
```

## 20. Save/load system

Use JSON save files.

Save:

* lab state
* campaign progress
* flies
* vials
* genotypes
* phenotypes
* lineages
* environments
* experiments
* random seeds
* notebook entries
* unlocks
* settings

Add autosave.

## 21. Data-driven content

Make it easy to add:

* genes
* alleles
* traits
* scenarios
* campaign objectives
* tutorial steps
* environment presets
* epistasis rules

Avoid huge hardcoded if/else blocks.

Use rule files.

Example epistasis rule:

```json
{
  "id": "eye_development_masks_eye_pigment",
  "condition": {
    "trait_below": {
      "eye_size": 0.25
    }
  },
  "effect": {
    "mask_traits": ["eye_color"]
  },
  "explanation": "Eye pigment is not visible because eye development failed."
}
```

## 22. Performance requirements

The simulator should handle:

* individual fly inspection
* 1000 offspring simulation in batch
* at least 20 generations of summarized population simulation
* save/load of large experiments
* UI remains responsive

Use batch mode for large crosses.

For very large simulations, show summary tables instead of rendering every fly.

## 23. Testing and validation

Add test/debug scripts.

Test cases:

1. Recessive allele inheritance
2. Dominant allele inheritance
3. X-linked inheritance
4. Lethal homozygous allele
5. Penetrance variation
6. Expressivity range
7. Epistasis masking
8. Temperature-sensitive allele
9. Same random seed gives same result
10. Different random seed gives different stochastic variation
11. Cross output count is correct
12. Phenotype explanation is generated
13. Save/load preserves genotype and phenotype

Add a Debug Test Runner scene.

## 24. Development roadmap

Build the full product in phases. Do not skip phases. Each phase must leave the game runnable.

### Phase 0: Project foundation

Goal:
Create the Godot project skeleton and architecture.

Deliverables:

* project.godot
* folder structure
* main menu scene
* lab dashboard placeholder
* data loader
* seedable random service
* basic save/load shell
* README.md
* coding conventions

Definition of Done:

* project opens in Godot
* main menu runs
* dashboard opens
* data loader can read JSON
* no simulation yet
* README explains how to run on macOS

### Phase 1: Core data model

Goal:
Implement fly/genome/gene/allele/phenotype/environment classes.

Deliverables:

* Fly.gd
* Genome.gd
* Chromosome.gd
* Gene.gd
* Allele.gd
* Phenotype.gd
* Environment.gd
* genes.json
* alleles.json with at least 10 genes and 20 alleles

Definition of Done:

* create a wild-type fly
* create a mutant fly
* inspect genotype in debug panel
* load gene/allele data from JSON
* save/load one fly

### Phase 2: Phenotype engine

Goal:
Convert genotype into phenotype.

Deliverables:

* PhenotypeEngine.gd
* dominance handling
* penetrance
* expressivity
* trait deltas
* explanation log
* simple phenotype viewer panel

Definition of Done:

* wild-type fly has normal phenotype
* white mutation affects eye color
* vestigial mutation affects wing size
* yellow/ebony affects body color
* explanations are generated
* same seed gives same phenotype

### Phase 3: Procedural fly renderer

Goal:
Show phenotype visually.

Deliverables:

* MicroscopeViewer.tscn
* FlyRenderer.gd
* eye rendering
* wing rendering
* body color rendering
* bristle rendering
* body size rendering

Definition of Done:

* phenotype changes are visible
* white-eyed fly looks different
* vestigial-wing fly looks different
* dark/light body flies look different
* no external art required

### Phase 4: Development engine

Goal:
Simulate egg-to-adult development.

Deliverables:

* DevelopmentEngine.gd
* development stages
* viability score
* developmental stability
* stage logs
* failure outcomes
* timeline UI

Definition of Done:

* fly can develop from egg to adult
* severe developmental mutation can fail
* failure has explanation
* temperature changes stage duration/stress
* nutrition affects size/survival

### Phase 5: Inheritance and cross simulator

Goal:
Generate offspring from parents.

Deliverables:

* InheritanceEngine.gd
* CrossSimulator.tscn
* sex-linked inheritance
* autosomal inheritance
* simplified recombination
* offspring tables
* expected vs observed ratios

Definition of Done:

* cross two flies
* generate 10/100/1000 offspring
* output genotype distribution
* output phenotype distribution
* offspring inherit alleles correctly
* random seed is reproducible

### Phase 6: Lab dashboard and vial system

Goal:
Turn the simulator into a game space.

Deliverables:

* lab dashboard
* vial model
* incubator model
* fly selection
* move flies between vials
* archive line
* inspect vial summary

Definition of Done:

* player can manage multiple vials
* each vial has environment settings
* flies belong to vials
* incubator temperature affects development
* dashboard feels like a lab

### Phase 7: Statistics and notebook

Goal:
Make experiments understandable.

Deliverables:

* StatisticsEngine.gd
* charts/tables
* lab notebook
* automatic experiment logs
* observed vs expected ratio analysis
* export summary text/JSON

Definition of Done:

* after a cross, notebook records result
* statistics screen shows distributions
* player can compare expected vs observed
* explanations are readable

### Phase 8: Campaign framework

Goal:
Add structured gameplay.

Deliverables:

* scenario system
* objective system
* campaign progression
* tutorial popups
* success/failure conditions
* unlocks

Definition of Done:

* at least 5 playable campaign scenarios
* objectives can be completed
* unlocks work
* tutorial teaches core mechanics

### Phase 9: Advanced genetics

Goal:
Add depth.

Deliverables:

* epistasis rules
* pleiotropy rules
* modifier genes
* suppressor/enhancer alleles
* polygenic traits
* lethal carriers
* temperature-sensitive alleles
* hidden carrier mechanics

Definition of Done:

* simple Mendelian ratios can fail for explainable reasons
* environment can reveal hidden effects
* complex traits depend on multiple genes
* player can solve at least 3 advanced challenges

### Phase 10: Population simulation

Goal:
Support long-term selection and evolution-like experiments.

Deliverables:

* PopulationEngine.gd
* generation simulation
* selection filters
* population bottlenecks
* drift
* trait frequency tracking
* line stability score

Definition of Done:

* player can run 10+ generations
* trait frequencies change
* selection can increase desired trait
* low viability can collapse a line
* charts show generational trends

### Phase 11: Game economy and progression

Goal:
Make the product replayable.

Deliverables:

* research points
* budget
* lab reputation
* project board
* publication score
* equipment unlocks
* scenario rewards

Definition of Done:

* completing scenarios rewards progress
* better tools unlock deeper analysis
* player has meaningful constraints
* game has progression beyond sandbox

### Phase 12: Polish and productization

Goal:
Prepare for public playable release.

Deliverables:

* settings menu
* UI polish
* sound effects
* ambient lab music
* accessibility options
* export presets
* improved README
* packaged macOS export
* bug fixes
* balancing pass

Definition of Done:

* game is playable by a new user
* campaign has at least 15 scenarios
* sandbox is stable
* save/load works
* no obvious crashes
* macOS export works

## 25. Claude Code working rules

When implementing, follow these rules:

1. Do not implement all phases at once.
2. Always keep the project runnable.
3. After each phase, update README.md.
4. After each phase, add a short CHANGELOG.md entry.
5. Prefer data-driven rules over hardcoded logic.
6. Keep simulation code separate from UI code.
7. Add debug screens for simulation verification.
8. Add comments explaining non-obvious biological abstractions.
9. Never add real wet-lab protocols.
10. Never add real gene-editing instructions.

## 26. Initial implementation request to Claude Code

Start with Phase 0 only.

Create the Godot 4 project skeleton for Drosophila Genetics Lab Simulator.

Implement:

* project.godot
* main menu
* lab dashboard placeholder
* folder structure
* DataLoader.gd
* RandomService.gd
* SaveLoadService.gd shell
* README.md with macOS run instructions
* CHANGELOG.md
* placeholder data directory

Do not implement the full simulation yet.

After Phase 0 works, stop and summarize what was created.

## 27. Phase-by-phase prompt template

For each next phase, use this format:

```text
Continue the Drosophila Genetics Lab Simulator project.

Implement Phase N from the product specification.

Do not rewrite the whole project.
Do not skip ahead.
Keep the project runnable.
Use existing architecture.
Update README.md and CHANGELOG.md.
Add debug/test screens where useful.
Do not include any real wet-lab or gene-editing instructions.

Phase N goal:
[paste phase goal]

Phase N deliverables:
[paste deliverables]

Phase N Definition of Done:
[paste definition of done]
```

## 28. Final success criteria

The final game should be successful if:

* a player can learn real genetics concepts through play
* every result is explainable
* the simulation feels complex but not arbitrary
* the player can run meaningful multi-generation experiments
* visual phenotype changes are clear
* hidden genetic complexity creates interesting puzzles
* campaign mode teaches the system gradually
* sandbox mode allows deep experimentation
* the product avoids unsafe real-world gene editing details
* the project remains extensible through data files

