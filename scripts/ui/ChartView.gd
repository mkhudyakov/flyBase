extends Control
class_name ChartView
## ChartView — a small reusable chart widget drawn with _draw() (no libraries).
## Supports grouped bar charts and multi-line charts with axes, gridlines, value
## ticks, x labels, and a legend. Feed it data via set_bars()/set_lines().

enum Kind { BARS, LINES }

const PALETTE := [
	Color(0.45, 0.70, 0.95),  # blue
	Color(0.95, 0.72, 0.36),  # orange
	Color(0.56, 0.84, 0.63),  # green
	Color(0.86, 0.45, 0.45),  # red
	Color(0.75, 0.60, 0.90),  # purple
]

var _kind: int = Kind.BARS
var _title: String = ""
var _categories: Array = []      ## x-axis labels (bars) / x ticks (lines)
var _series: Array = []          ## [{name, color, values:Array[float]}]
var _y_max: float = 0.0          ## 0 = auto
var _y_suffix: String = ""       ## e.g. "%" on tick labels

func set_bars(categories: Array, series: Array, title: String = "", y_max: float = 0.0, y_suffix: String = "") -> void:
	_kind = Kind.BARS
	_categories = categories
	_series = _with_colors(series)
	_title = title
	_y_max = y_max
	_y_suffix = y_suffix
	queue_redraw()

func set_lines(x_labels: Array, series: Array, title: String = "", y_max: float = 0.0, y_suffix: String = "") -> void:
	_kind = Kind.LINES
	_categories = x_labels
	_series = _with_colors(series)
	_title = title
	_y_max = y_max
	_y_suffix = y_suffix
	queue_redraw()

func _with_colors(series: Array) -> Array:
	var out: Array = []
	for i in series.size():
		var s: Dictionary = (series[i] as Dictionary).duplicate()
		if not s.has("color"):
			s["color"] = PALETTE[i % PALETTE.size()]
		out.append(s)
	return out

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var fs := 11
	var axis := Color(0.45, 0.5, 0.55)
	var grid := Color(1, 1, 1, 0.08)
	var text := Color(0.82, 0.85, 0.88)

	var left := 46.0
	var right := 14.0
	var top := 26.0 if _title != "" else 12.0
	var bottom := 54.0
	var plot := Rect2(left, top, size.x - left - right, size.y - top - bottom)
	if plot.size.x <= 10 or plot.size.y <= 10:
		return

	if _title != "":
		draw_string(font, Vector2(left, 16), _title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, text)

	var ymax := _resolve_y_max()
	# Gridlines + y tick labels at 0, ½, 1.
	for f: float in [0.0, 0.5, 1.0]:
		var y: float = plot.position.y + plot.size.y * (1.0 - f)
		draw_line(Vector2(plot.position.x, y), Vector2(plot.position.x + plot.size.x, y), grid, 1.0)
		var tick := "%.0f%s" % [ymax * f, _y_suffix]
		draw_string(font, Vector2(4, y + 4), tick, HORIZONTAL_ALIGNMENT_LEFT, left - 6, fs, text)
	# Axes.
	draw_line(plot.position, plot.position + Vector2(0, plot.size.y), axis, 1.5)
	draw_line(plot.position + Vector2(0, plot.size.y), plot.position + plot.size, axis, 1.5)

	if _categories.is_empty() or _series.is_empty():
		return

	if _kind == Kind.BARS:
		_draw_bars(font, fs, plot, ymax, text)
	else:
		_draw_lines(font, fs, plot, ymax, text)

	_draw_legend(font, plot, text)

func _resolve_y_max() -> float:
	if _y_max > 0.0:
		return _y_max
	var m := 0.0
	for s in _series:
		for v in s["values"]:
			m = maxf(m, float(v))
	return maxf(m * 1.15, 1.0)

func _draw_bars(font: Font, fs: int, plot: Rect2, ymax: float, text: Color) -> void:
	var n := _categories.size()
	var groups := _series.size()
	var group_w := plot.size.x / float(n)
	var bar_w := group_w * 0.8 / float(maxi(groups, 1))
	for ci in n:
		for si in groups:
			var vals: Array = _series[si]["values"]
			if ci >= vals.size():
				continue
			var v := float(vals[ci])
			var h := (v / ymax) * plot.size.y
			var x := plot.position.x + ci * group_w + group_w * 0.1 + si * bar_w
			var r := Rect2(x, plot.position.y + plot.size.y - h, bar_w * 0.92, h)
			draw_rect(r, _series[si]["color"])
		# x label, centered under the group, truncated to the group width.
		var label := str(_categories[ci])
		draw_string(font, Vector2(plot.position.x + ci * group_w, plot.position.y + plot.size.y + 16),
			label, HORIZONTAL_ALIGNMENT_CENTER, group_w, fs, text)

func _draw_lines(font: Font, fs: int, plot: Rect2, ymax: float, text: Color) -> void:
	var n := _categories.size()
	if n < 2:
		return
	for s in _series:
		var pts := PackedVector2Array()
		var vals: Array = s["values"]
		for xi in mini(n, vals.size()):
			var x := plot.position.x + (float(xi) / float(n - 1)) * plot.size.x
			var y := plot.position.y + plot.size.y * (1.0 - clampf(float(vals[xi]) / ymax, 0.0, 1.0))
			pts.append(Vector2(x, y))
		if pts.size() >= 2:
			draw_polyline(pts, s["color"], 2.0, true)
	# x labels: a handful, evenly spaced.
	var step := maxi(1, int(ceil(n / 8.0)))
	for xi in range(0, n, step):
		var x := plot.position.x + (float(xi) / float(n - 1)) * plot.size.x
		draw_string(font, Vector2(x - 10, plot.position.y + plot.size.y + 16),
			str(_categories[xi]), HORIZONTAL_ALIGNMENT_LEFT, 40, fs, text)

func _draw_legend(font: Font, plot: Rect2, text: Color) -> void:
	if _series.size() <= 1 and _series[0].get("name", "") == "":
		return
	var y := plot.position.y + 2
	for s in _series:
		var name: String = s.get("name", "")
		if name == "":
			continue
		var w := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		var x := plot.position.x + plot.size.x - w - 18
		draw_rect(Rect2(x, y + 2, 12, 12), s["color"])
		draw_string(font, Vector2(x + 16, y + 12), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, text)
		y += 18
