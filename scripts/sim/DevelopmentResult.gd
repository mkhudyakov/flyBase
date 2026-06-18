class_name DevelopmentResult
extends RefCounted
## DevelopmentResult — the outcome of simulating one fly's development
## (egg → adult) under a given environment.
##
## Produced by DevelopmentEngine.simulate(). Holds the per-stage log, the final
## status/outcome, and the functional scores the engine writes back onto the
## fly's phenotype. Plain data, so it can be shown in the timeline UI or saved.

var reached_adult: bool = false
var outcome: String = ""               ## e.g. "healthy adult", "pupal lethality".
var final_stage: String = ""           ## stage id where development ended.
var viability_score: float = 0.0
var developmental_stability: float = 1.0
var fertility_score: float = 0.0
var lifespan_days: float = 0.0
var total_days: float = 0.0            ## cumulative development time.
var stage_logs: Array = []             ## [{id, display_name, duration, stress, status, note}]
var explanation: Array[String] = []

func to_dict() -> Dictionary:
	return {
		"reached_adult": reached_adult,
		"outcome": outcome,
		"final_stage": final_stage,
		"viability_score": viability_score,
		"developmental_stability": developmental_stability,
		"fertility_score": fertility_score,
		"lifespan_days": lifespan_days,
		"total_days": total_days,
		"stage_logs": stage_logs.duplicate(true),
		"explanation": explanation.duplicate(),
	}
