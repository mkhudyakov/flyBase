extends Control
class_name FlyRenderer
## FlyRenderer — draws a fly from its phenotype using only generated vector
## shapes (spec sections 17.7 and 18). No art assets are required.
##
## This is a top-down symbolic fly: head + thorax + abdomen along a vertical
## axis, a pair of wings, legs, antennae, eyes, and bristles. Every visual is
## driven by a phenotype trait, so a white-eyed / vestigial / dark fly looks
## visibly different. The renderer reads sim data (Phenotype) but never writes
## it — drawing is a pure function of the traits.

# Palette anchors for trait→color mapping.
const COL_OUTLINE := Color(0.08, 0.08, 0.10)
const COL_EYE_RED := Color(0.72, 0.06, 0.05)   ## wild-type red (eye_color = 1)
const COL_EYE_WHITE := Color(0.95, 0.93, 0.90) ## white mutant (eye_color = 0)
const COL_BODY_PALE := Color(0.88, 0.78, 0.42) ## yellow (body_color = 0)
const COL_BODY_WILD := Color(0.52, 0.40, 0.23) ## wild-type (body_color = 0.5)
const COL_BODY_DARK := Color(0.15, 0.12, 0.10) ## ebony (body_color = 1)
const COL_WING := Color(0.82, 0.87, 0.96)      ## translucent wing membrane

var _phenotype: Phenotype

func _ready() -> void:
	# Containers settle their children's size a frame after _ready, so repaint
	# whenever our rect changes to stay centered on the final size.
	resized.connect(queue_redraw)

## Sets the fly to draw (reads its already-computed phenotype) and repaints.
func set_fly(fly: Fly) -> void:
	_phenotype = fly.phenotype if fly != null else null
	queue_redraw()

func set_phenotype(p: Phenotype) -> void:
	_phenotype = p
	queue_redraw()

func _t(name: String, default: float) -> float:
	return _phenotype.get_trait(name, default) if _phenotype != null else default

func _draw() -> void:
	# Microscope field backdrop.
	var center := size * 0.5
	var field_r := minf(size.x, size.y) * 0.48
	draw_circle(center, field_r, Color(0.06, 0.08, 0.09))
	draw_arc(center, field_r, 0.0, TAU, 64, Color(0.2, 0.25, 0.28), 2.0)

	if _phenotype == null:
		return

	# --- Read traits --------------------------------------------------------
	var body_size := _t("body_size", 1.0)
	var body_color_t := _t("body_color", 0.5)
	var eye_color_t := _t("eye_color", 1.0)
	var eye_size := _t("eye_size", 1.0)
	var wing_size := _t("wing_size", 1.0)
	var wing_shape := _t("wing_shape", 1.0)
	var wing_vein := _t("wing_vein_quality", 1.0)
	var antenna_shape := _t("antenna_shape", 1.0)
	var bristle_count := int(round(_t("bristle_count", 12.0)))
	var deformity := _t("deformity_score", 0.0)

	var body_col := _body_color(body_color_t)
	var thorax_col := body_col.darkened(0.15)
	var head_col := body_col.darkened(0.25)

	# Base scale in pixels; everything derives from this so body_size scales all.
	var s := minf(size.x, size.y) * 0.30 * body_size
	var head_c := center + Vector2(0, -s * 0.95)
	var head_r := s * 0.34
	var thorax_c := center + Vector2(0, -s * 0.10)
	var abdomen_c := center + Vector2(0, s * 0.80)

	# deformity introduces left/right asymmetry: the right side is scaled down.
	var right_scale := 1.0 - deformity * 0.45

	# --- Wings (behind the body) -------------------------------------------
	_draw_wing(thorax_c, -1, wing_size, wing_shape, wing_vein, 1.0)
	_draw_wing(thorax_c, 1, wing_size, wing_shape, wing_vein, right_scale)

	# --- Legs ---------------------------------------------------------------
	_draw_legs(thorax_c, s, right_scale)

	# --- Body segments (back to front: abdomen, thorax, head) --------------
	_fill_ellipse(abdomen_c, s * 0.50, s * 0.88, body_col)
	_draw_abdomen_stripes(abdomen_c, s, body_col)
	_fill_ellipse(thorax_c, s * 0.42, s * 0.52, thorax_col)
	draw_circle(head_c, head_r, head_col)
	draw_arc(head_c, head_r, 0.0, TAU, 32, COL_OUTLINE, 1.5)

	# --- Eyes ---------------------------------------------------------------
	var eye_col := _eye_color(eye_color_t)
	var eye_r := head_r * 0.62 * eye_size
	_draw_eye(head_c + Vector2(-head_r * 0.62, -head_r * 0.05), eye_r, eye_col)
	_draw_eye(head_c + Vector2(head_r * 0.62, -head_r * 0.05), eye_r * right_scale, eye_col)

	# --- Antennae (lengthen / thicken toward leg-like as antenna_shape drops)
	_draw_antennae(head_c, head_r, antenna_shape)

	# --- Bristles -----------------------------------------------------------
	_draw_bristles(thorax_c, abdomen_c, s, bristle_count)

# --- Trait → color mapping ---------------------------------------------------

## eye_color: 1.0 = wild-type red, 0.0 = white.
func _eye_color(t: float) -> Color:
	return COL_EYE_WHITE.lerp(COL_EYE_RED, clampf(t, 0.0, 1.0))

## body_color: 0 = pale/yellow, 0.5 = wild-type, 1 = dark/ebony (piecewise).
func _body_color(t: float) -> Color:
	t = clampf(t, 0.0, 1.0)
	if t < 0.5:
		return COL_BODY_PALE.lerp(COL_BODY_WILD, t / 0.5)
	return COL_BODY_WILD.lerp(COL_BODY_DARK, (t - 0.5) / 0.5)

# --- Drawing helpers ---------------------------------------------------------

func _fill_ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := _ellipse_points(c, rx, ry, 40)
	draw_colored_polygon(pts, col)
	draw_polyline(_close(pts), COL_OUTLINE, 1.5, true)

func _ellipse_points(c: Vector2, rx: float, ry: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

func _close(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	if out.size() > 0:
		out.append(out[0])
	return out

func _draw_wing(root: Vector2, side: int, wing_size: float, wing_shape: float,
		vein_quality: float, extra_scale: float) -> void:
	var length := minf(size.x, size.y) * 0.30 * wing_size * extra_scale
	var width := length * 0.42
	var origin := root + Vector2(side * length * 0.12, -length * 0.18)

	# Leaf-shaped outline pointing down-and-outward. x is mirrored by `side`.
	var rel := [
		Vector2(0.0, 0.0),
		Vector2(0.55, -0.10),
		Vector2(1.05, 0.18),
		Vector2(1.10, 0.55),   # trailing-edge control (notched by wing_shape)
		Vector2(0.70, 0.95),
		Vector2(0.20, 1.05),
		Vector2(-0.05, 0.55),
	]
	# A low wing_shape pulls the trailing edge inward, producing a notched wing.
	rel[3] = rel[3].lerp(Vector2(0.45, 0.45), clampf(1.0 - wing_shape, 0.0, 1.0))

	var pts := PackedVector2Array()
	for r: Vector2 in rel:
		pts.append(origin + Vector2(side * r.x * width, r.y * length))

	var membrane := COL_WING
	membrane.a = 0.34
	draw_colored_polygon(pts, membrane)
	draw_polyline(_close(pts), Color(0.6, 0.66, 0.74, 0.7), 1.5, true)

	# Veins fade with wing_vein_quality.
	if vein_quality > 0.05:
		var vein := Color(0.45, 0.5, 0.58, clampf(vein_quality * 0.7, 0.0, 0.7))
		draw_line(pts[0], pts[3], vein, 1.0)
		draw_line(pts[0], pts[4], vein, 1.0)

func _draw_legs(thorax_c: Vector2, s: float, right_scale: float) -> void:
	var leg_col := Color(0.12, 0.10, 0.10)
	for i in 3:
		var y := thorax_c.y - s * 0.25 + i * s * 0.28
		var len_l := s * (0.7 + i * 0.12)
		var len_r := len_l * right_scale
		var down := s * (0.18 + i * 0.16)
		# left
		draw_polyline([thorax_c + Vector2(-s * 0.3, y - thorax_c.y),
			Vector2(thorax_c.x - s * 0.3 - len_l * 0.6, y + down * 0.4),
			Vector2(thorax_c.x - s * 0.3 - len_l, y + down)], leg_col, 2.0)
		# right
		draw_polyline([thorax_c + Vector2(s * 0.3, y - thorax_c.y),
			Vector2(thorax_c.x + s * 0.3 + len_r * 0.6, y + down * 0.4),
			Vector2(thorax_c.x + s * 0.3 + len_r, y + down)], leg_col, 2.0)

func _draw_abdomen_stripes(c: Vector2, s: float, body_col: Color) -> void:
	var stripe := body_col.darkened(0.35)
	stripe.a = 0.6
	for i in range(1, 4):
		var y := c.y - s * 0.5 + i * s * 0.42
		var half := sqrt(maxf(1.0 - pow((y - c.y) / (s * 0.88), 2.0), 0.0)) * s * 0.50
		if half > 1.0:
			draw_line(Vector2(c.x - half, y), Vector2(c.x + half, y), stripe, 2.0)

func _draw_eye(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c, r, col)
	draw_arc(c, r, 0.0, TAU, 24, COL_OUTLINE, 1.0)
	# small specular highlight
	draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.22, Color(1, 1, 1, 0.5))

func _draw_antennae(head_c: Vector2, head_r: float, antenna_shape: float) -> void:
	var col := Color(0.1, 0.08, 0.08)
	# As antenna_shape drops toward 0, antennae grow longer/leg-like.
	var extra := (1.0 - clampf(antenna_shape, 0.0, 1.0))
	var length := head_r * (0.7 + extra * 1.4)
	var width := 2.0 + extra * 2.0
	for side in [-1, 1]:
		var base := head_c + Vector2(side * head_r * 0.3, -head_r * 0.85)
		var mid := base + Vector2(side * length * 0.3, -length * 0.5)
		var tip := mid + Vector2(side * length * 0.5, -length * 0.3 + extra * length * 0.6)
		draw_polyline([base, mid, tip], col, width)

func _draw_bristles(thorax_c: Vector2, abdomen_c: Vector2, s: float, count: int) -> void:
	var col := Color(0.05, 0.05, 0.06)
	for i in maxi(count, 0):
		# Deterministic placement: alternate thorax/abdomen, spread by index.
		var on_thorax := i % 3 == 0
		var origin := thorax_c if on_thorax else abdomen_c
		var rx := (s * 0.38) if on_thorax else (s * 0.48)
		var ry := (s * 0.48) if on_thorax else (s * 0.84)
		var a := float(i) * 2.39996  # golden angle for even spread
		var p := origin + Vector2(cos(a) * rx * 0.85, sin(a) * ry * 0.85)
		var dir := Vector2(cos(a), sin(a)) * (s * 0.12)
		draw_line(p, p + dir, col, 1.5)
