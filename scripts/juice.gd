extends Node

var game: Control
var last_status := ""
var last_score := 0
var audio_players: Array[AudioStreamPlayer] = []
var audio_index: int = 0
var sample_rate := 44100.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	call_deferred("setup")

func setup() -> void:
	await get_tree().process_frame
	game = get_tree().current_scene as Control
	if game == null: return
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.volume_db = -5.0
		game.add_child(p)
		audio_players.append(p)
	await get_tree().process_frame
	connect_buttons()
	if game.get("status_label") != null: last_status = str(game.status_label.text)
	last_score = int(game.get("score"))

func connect_buttons() -> void:
	var grid = game.get("board_grid")
	if grid == null: return
	for child in grid.get_children():
		if child is Button:
			child.button_down.connect(piece_press.bind(child))
			child.button_up.connect(piece_release.bind(child))

func piece_press(button: Button) -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(button, "scale", Vector2(0.90, 0.90), 0.05)
	play_soft_click()

func piece_release(button: Button) -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(button, "scale", Vector2(1.06, 1.06), 0.05)
	tw.tween_property(button, "scale", Vector2.ONE, 0.08)

func _process(_delta: float) -> void:
	if game == null: return
	var status = game.get("status_label")
	if status != null and str(status.text) != last_status:
		last_status = str(status.text)
		on_status(last_status)
	var current_score := int(game.get("score"))
	if current_score > last_score: pulse_score()
	last_score = current_score

func on_status(text: String) -> void:
	if "КАСКАД" in text:
		cascade_fx(cascade_number(text))
	elif "ЦЕПНАЯ" in text:
		blast_fx(Color("fff08a"), 0.18)
		play_combo_burst()
	elif "РАКЕТА" in text:
		blast_fx(Color("7ee8ff"), 0.12)
		play_rocket()
	elif "БОМБА" in text:
		blast_fx(Color("ff8a65"), 0.20)
		play_bomb()
	elif "ЯДРО" in text:
		blast_fx(Color("d79cff"), 0.22)
		play_core()
	elif "ПОБЕДА" in text:
		win_fx()

func cascade_number(text: String) -> int:
	var marker := text.find("x")
	if marker < 0: return 2
	var rest := text.substr(marker + 1)
	var number := ""
	for c in rest:
		if c >= "0" and c <= "9": number += c
		else: break
	return maxi(2, int(number))

func cascade_fx(chain: int) -> void:
	play_match_pop(chain)
	pop_status(1.0 + minf(float(chain) * 0.07, 0.36))
	if chain >= 3: blast_fx(Color("ffffff"), 0.045 + float(chain) * 0.01)
	if chain >= 5: play_reward_sparkle(chain)

func play_soft_click() -> void:
	# A tiny muted tactile tick instead of a synth beep.
	play_percussive(0.032, 0.055, 0.72, 1700.0, 0.0)

func play_match_pop(chain: int) -> void:
	# Casual match-3 pop: soft impact + airy bubble + subtle pitched sparkle.
	var step: float = minf(float(chain), 7.0)
	var pitch: float = 510.0 * pow(1.05946, step * 1.6)
	play_percussive(0.075, 0.12, 0.32, 950.0 + step * 90.0, 0.18)
	play_bubble(pitch, 0.085, 0.095)
	if chain >= 2: play_chime(pitch * 1.48, 0.105, 0.038)

func play_combo_burst() -> void:
	play_percussive(0.11, 0.14, 0.42, 1250.0, 0.16)
	play_bubble(720.0, 0.12, 0.10)
	play_chime(1080.0, 0.16, 0.055)

func play_rocket() -> void:
	# Airy launch + paper-like snap, not an electronic laser.
	play_whoosh(0.22, 0.13, true)
	play_percussive(0.055, 0.12, 0.55, 2200.0, 0.05)
	play_chime(1180.0, 0.11, 0.035)

func play_bomb() -> void:
	# Rounded cartoon thump with a short debris puff.
	play_thump(0.26, 0.22)
	play_percussive(0.18, 0.16, 0.20, 520.0, 0.0)
	play_whoosh(0.16, 0.07, false)

func play_core() -> void:
	# Magical reward-like shimmer rather than a sci-fi oscillator.
	play_whoosh(0.24, 0.08, true)
	play_chime(659.25, 0.28, 0.06)
	play_chime(987.77, 0.24, 0.05)
	play_chime(1318.5, 0.20, 0.04)

func play_reward_sparkle(chain: int) -> void:
	var lift: float = minf(float(chain - 5) * 30.0, 120.0)
	play_chime(1046.5 + lift, 0.18, 0.045)
	play_chime(1318.5 + lift, 0.22, 0.038)
	play_chime(1568.0 + lift, 0.25, 0.030)

func pop_status(amount: float) -> void:
	var label = game.get("status_label")
	if label == null: return
	label.pivot_offset = label.size * 0.5
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "scale", Vector2(amount, amount), 0.08)
	tw.tween_property(label, "scale", Vector2.ONE, 0.15)

func pulse_score() -> void:
	var label = game.get("score_label")
	if label == null: return
	label.pivot_offset = label.size * 0.5
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "scale", Vector2(1.12, 1.12), 0.07)
	tw.tween_property(label, "scale", Vector2.ONE, 0.12)

func blast_fx(color: Color, alpha: float) -> void:
	var flash := ColorRect.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(color.r, color.g, color.b, alpha)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.add_child(flash)
	flash.z_index = 100
	var tw := create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.18)
	tw.tween_callback(flash.queue_free)
	shake_board()

func shake_board() -> void:
	var grid = game.get("board_grid")
	if grid == null: return
	var original: Vector2 = grid.position
	var tw := create_tween()
	for i in 6:
		var strength := 5.0 - float(i) * 0.65
		tw.tween_property(grid, "position", original + Vector2(randf_range(-strength,strength), randf_range(-strength,strength)), 0.025)
	tw.tween_property(grid, "position", original, 0.035)

func win_fx() -> void:
	blast_fx(Color("fff0a8"), 0.30)
	play_whoosh(0.28, 0.08, true)
	play_chime(523.25, 0.34, 0.055)
	play_chime(659.25, 0.36, 0.050)
	play_chime(783.99, 0.40, 0.045)
	play_chime(1046.5, 0.44, 0.038)
	var label = game.get("status_label")
	if label != null:
		label.add_theme_font_size_override("font_size", 28)
		pop_status(1.35)

func next_player() -> AudioStreamPlayer:
	var p: AudioStreamPlayer = audio_players[audio_index]
	audio_index = (audio_index + 1) % audio_players.size()
	return p

func play_percussive(duration: float, volume: float, brightness: float, body_freq: float, tonal: float) -> void:
	if audio_players.is_empty(): return
	var frames := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var low: float = 0.0
	for i in frames:
		var k := float(i) / float(frames)
		var raw := rng.randf_range(-1.0, 1.0)
		low = lerpf(low, raw, clampf(brightness, 0.05, 0.95))
		var env := pow(1.0 - k, 4.0)
		var body := sin(TAU * body_freq * float(i) / sample_rate) * tonal
		write_sample(data, i, (low * (1.0-tonal) + body) * env * volume)
	play_pcm(data)

func play_bubble(freq: float, duration: float, volume: float) -> void:
	if audio_players.is_empty(): return
	var frames := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var phase := 0.0
	for i in frames:
		var k := float(i) / float(frames)
		var f := freq * (1.0 + 0.42 * pow(1.0-k, 2.0))
		phase += TAU * f / sample_rate
		var env := sin(PI * minf(k * 2.8, 1.0)) * pow(1.0-k, 2.4)
		var rounded := sin(phase) + sin(phase * 0.5) * 0.18
		write_sample(data, i, rounded * env * volume)
	play_pcm(data)

func play_chime(freq: float, duration: float, volume: float) -> void:
	if audio_players.is_empty(): return
	var frames := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / sample_rate
		var k := float(i) / float(frames)
		var attack := minf(1.0, float(i) / (sample_rate * 0.004))
		var env := attack * pow(1.0-k, 2.2)
		var v := sin(TAU*freq*t) * 0.72 + sin(TAU*freq*2.71*t) * 0.18 + sin(TAU*freq*4.05*t) * 0.10
		write_sample(data, i, v * env * volume)
	play_pcm(data)

func play_thump(duration: float, volume: float) -> void:
	if audio_players.is_empty(): return
	var frames := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var phase := 0.0
	for i in frames:
		var k := float(i) / float(frames)
		var freq := lerpf(145.0, 48.0, sqrt(k))
		phase += TAU * freq / sample_rate
		var env := pow(1.0-k, 2.5)
		var v := (sin(phase) + sin(phase*0.5)*0.28) * env * volume
		write_sample(data, i, v)
	play_pcm(data)

func play_whoosh(duration: float, volume: float, rising: bool) -> void:
	if audio_players.is_empty(): return
	var frames := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var smooth_noise: float = 0.0
	for i in frames:
		var k := float(i) / float(frames)
		var raw := rng.randf_range(-1.0, 1.0)
		var response := lerpf(0.08, 0.72, k if rising else 1.0-k)
		smooth_noise = lerpf(smooth_noise, raw, response)
		var env := sin(PI * k) * (1.0-k*0.25)
		write_sample(data, i, smooth_noise * env * volume)
	play_pcm(data)

func write_sample(data: PackedByteArray, i: int, value: float) -> void:
	var s := int(clampf(value, -1.0, 1.0) * 32767.0)
	data[i*2] = s & 255
	data[i*2+1] = (s >> 8) & 255

func play_pcm(data: PackedByteArray) -> void:
	if audio_players.is_empty(): return
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false
	stream.data = data
	var p := next_player()
	p.stream = stream
	p.play()
