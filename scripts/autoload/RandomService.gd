extends Node
## RandomService (autoload singleton)
##
## Centralised, seedable randomness. Every stochastic part of the simulation
## (penetrance rolls, expressivity, recombination, mutation, sex assignment...)
## MUST draw from here rather than calling randf()/randi() directly. That makes
## experiments reproducible: the same seed always yields the same result, which
## the spec requires (section 12 and test cases 9-10).
##
## Phase 0 scope: the service exists and works. Later engines will request
## named sub-streams so unrelated systems don't perturb each other's sequences.

## The master seed currently in use. 0 means "not yet seeded".
var _seed: int = 0

## The primary RNG. Sub-streams are derived from the same seed plus a salt.
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	# Start with a time-based seed so a fresh run is non-deterministic until the
	# player or a scenario explicitly sets one.
	seed_with(_generate_time_seed())

## Generates a fresh seed from the system clock.
func _generate_time_seed() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0) ^ (randi() & 0xFFFFFF)

## Sets the master seed and resets the primary stream. All reproducible
## experiments should call this with a known value first.
func seed_with(new_seed: int) -> void:
	_seed = new_seed
	# Assigning `seed` deterministically resets the generator's internal state,
	# so the same seed always reproduces the same sequence. (Do NOT also poke
	# `state` here — forcing it to a constant would make every seed identical.)
	_rng.seed = new_seed

## Returns the master seed (e.g. to record it in a save file or notebook).
func get_seed() -> int:
	return _seed

## Returns a fresh RNG derived deterministically from the master seed and a
## string label. Two systems using different labels get independent, repeatable
## sequences. Same seed + same label always reproduces.
func make_stream(label: String) -> RandomNumberGenerator:
	var stream := RandomNumberGenerator.new()
	stream.seed = _seed ^ int(hash(label))
	return stream

## Float in [0, 1) from the primary stream.
func randf() -> float:
	return _rng.randf()

## Float in [from, to] from the primary stream.
func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)

## Integer in [from, to] inclusive from the primary stream.
func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)

## True with the given probability (0..1). Convenience for penetrance-style rolls.
func chance(probability: float) -> bool:
	return _rng.randf() < probability
