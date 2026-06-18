class_name StatisticsEngine
extends RefCounted
## StatisticsEngine — summarises a collection of flies (spec section 17.8).
##
## Pure analysis over an Array[Fly]: counts, sex/survival, visible-phenotype
## distribution, and trait histograms. Used by the Statistics screen and the
## notebook. No state, no UI.

## Basic counts for a set of flies.
static func summarize(flies: Array) -> Dictionary:
	var s := {"count": 0, "alive": 0, "female": 0, "male": 0, "female_alive": 0, "male_alive": 0}
	for f: Fly in flies:
		s["count"] += 1
		s[f.sex()] += 1
		if f.alive:
			s["alive"] += 1
			s[f.sex() + "_alive"] += 1
	return s

## Visible phenotype distribution over only the dimensions that vary (so the
## table stays readable). Returns class_label -> count.
static func phenotype_distribution(flies: Array, alive_only: bool = true) -> Dictionary:
	var subjects: Array = []
	for f: Fly in flies:
		if not alive_only or f.alive:
			subjects.append(f)
	var dist := {}
	if subjects.is_empty():
		return dist

	var dims := ["eye", "wing", "body"]
	var per := {}
	var distinct := {"eye": {}, "wing": {}, "body": {}}
	for f: Fly in subjects:
		var d := visible_dims(f)
		per[f] = d
		for dim in dims:
			distinct[dim][d[dim]] = true

	var varying: Array[String] = []
	for dim in dims:
		if distinct[dim].size() > 1:
			varying.append(dim)

	for f: Fly in subjects:
		var d: Dictionary = per[f]
		var parts: Array[String] = [f.sex()]
		for dim in varying:
			parts.append(d[dim])
		if varying.is_empty():
			parts.append("wild-type")
		var key := ", ".join(parts)
		dist[key] = int(dist.get(key, 0)) + 1
	return dist

## Coarse visible categories for a fly (shared with the cross simulator's view).
static func visible_dims(fly: Fly) -> Dictionary:
	var p := fly.phenotype
	var eye_color := p.get_trait("eye_color", 1.0)
	var wing := p.get_trait("wing_size", 1.0)
	var body := p.get_trait("body_color", 0.5)
	return {
		"eye": "white-eye" if eye_color < 0.3 else "red-eye",
		"wing": "vestigial-wing" if wing < 0.4 else ("reduced-wing" if wing < 0.8 else "normal-wing"),
		"body": "pale-body" if body < 0.35 else ("dark-body" if body > 0.65 else "tan-body"),
	}

## Histogram of one trait across flies. Uses the trait's min/max as the range.
## Returns {trait_id, label, min, max, mean, n, bins:[{lo, hi, count}]}.
static func trait_histogram(flies: Array, trait_id: String, bin_count: int = 10, alive_only: bool = true) -> Dictionary:
	var tr: TraitRule = Catalog.get_trait_rule(trait_id)
	if tr == null:
		return {"trait_id": trait_id, "label": trait_id, "min": 0.0, "max": 1.0, "mean": 0.0, "n": 0, "bins": []}

	bin_count = maxi(bin_count, 1)
	var span: float = maxf(tr.max_value - tr.min_value, 0.0001)
	var counts := PackedInt32Array()
	counts.resize(bin_count)
	var sum := 0.0
	var n := 0
	for f: Fly in flies:
		if alive_only and not f.alive:
			continue
		var v: float = clampf(f.phenotype.get_trait(trait_id, tr.baseline), tr.min_value, tr.max_value)
		sum += v
		n += 1
		var idx: int = clampi(int((v - tr.min_value) / span * bin_count), 0, bin_count - 1)
		counts[idx] += 1

	var bins: Array = []
	for i in bin_count:
		bins.append({
			"lo": tr.min_value + span * float(i) / float(bin_count),
			"hi": tr.min_value + span * float(i + 1) / float(bin_count),
			"count": counts[i],
		})
	return {
		"trait_id": trait_id,
		"label": tr.label,
		"min": tr.min_value,
		"max": tr.max_value,
		"mean": (sum / float(n)) if n > 0 else 0.0,
		"n": n,
		"bins": bins,
	}
