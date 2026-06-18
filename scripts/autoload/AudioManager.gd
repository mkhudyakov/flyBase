extends Node
## AudioManager (autoload singleton) — procedurally generated audio, no asset
## files (spec §2: no paid assets). Synthesizes a short UI click and a low
## ambient lab drone as 16-bit PCM streams at startup, auto-connects the click to
## every button in the scene tree, and loops the ambient bed. Volumes follow the
## Settings singleton.

const RATE := 22050

var _music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _click: AudioStreamWAV

func _ready() -> void:
	_click = _make_tone([880.0, 1320.0], 0.06, 40.0, 0.28, false)
	var ambient := _make_tone([110.0, 165.0, 220.0], 6.0, 0.0, 0.10, true)

	_music = AudioStreamPlayer.new()
	_music.stream = ambient
	add_child(_music)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_pool.append(p)

	# Auto-play a click on every button, current and future.
	get_tree().node_added.connect(_on_node_added)
	_connect_existing(get_tree().root)

	apply_settings()
	if Settings.music_volume > 0.001:
		_music.play()

func _connect_existing(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node)
	for child in node.get_children():
		_connect_existing(child)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node)

func _connect_button(b: BaseButton) -> void:
	if not b.pressed.is_connected(play_click):
		b.pressed.connect(play_click)

## Plays the UI click on a free pooled player.
func play_click() -> void:
	if Settings.sfx_volume <= 0.001:
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = _click
			p.play()
			return
	_sfx_pool[0].stream = _click
	_sfx_pool[0].play()

## Re-reads the Settings volumes and applies them.
func apply_settings() -> void:
	if _music == null:
		return
	_music.volume_db = _vol_db(Settings.music_volume)
	for p in _sfx_pool:
		p.volume_db = _vol_db(Settings.sfx_volume)
	if Settings.music_volume <= 0.001 and _music.playing:
		_music.stop()
	elif Settings.music_volume > 0.001 and not _music.playing:
		_music.play()

func _vol_db(v: float) -> float:
	return -80.0 if v <= 0.001 else linear_to_db(v)

## Builds a tone stream by summing sine partials. `decay` > 0 gives a plucked
## blip; `loop` adds a gentle fade and forward looping for an ambient bed.
func _make_tone(freqs: Array, secs: float, decay: float, amp: float, loop: bool) -> AudioStreamWAV:
	var n := int(secs * RATE)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var fade := float(RATE) * 0.25  # samples for fade in/out (ambient)
	for i in n:
		var t := float(i) / RATE
		var env := 1.0
		if decay > 0.0:
			env = exp(-decay * t)
		elif loop:
			env = clampf(minf(float(i), float(n - i)) / fade, 0.0, 1.0)
		var s := 0.0
		for f in freqs:
			s += sin(TAU * float(f) * t)
		s = s / float(freqs.size()) * env * amp
		bytes.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))

	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = n
	return w
