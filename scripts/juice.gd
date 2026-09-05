extends Node

var game: Control
var last_status := ""
var last_score := 0
var audio_players: Array[AudioStreamPlayer] = []
var audio_index: int = 0
var sample_rate := 22050.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	call_deferred("setup")

func setup() -> void:
	await get_tree().process_frame
	game = get_tree().current_scene as Control
	if game == null: return
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -3.0
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
	tw.tween_property(button, "scale", Vector2(0.88, 0.88), 0.055)
	play_pop(0)

func piece_release(button: Button) -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(button, "scale", Vector2(1.08, 1.08), 0.055)
	tw.tween_property(button, "scale", Vector2.ONE, 0.085)

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
		blast_fx(Color("fff08a"), 0.20)
		play_chain_burst()
	elif "РАКЕТА" in text:
		blast_fx(Color("7ee8ff"), 0.13)
		play_rocket()
	elif "БОМБА" in text:
		blast_fx(Color("ff8a65"), 0.22)
		play_bomb()
	elif "ЯДРО" in text:
		blast_fx(Color("d79cff"), 0.25)
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
	play_pop(chain)
	pop_status(1.0 + minf(float(chain) * 0.075, 0.40))
	if chain >= 3: blast_fx(Color("ffffff"), 0.055 + float(chain) * 0.012)
	if chain >= 5: play_jackpot(chain)

func play_pop(chain: int) -> void:
	# Bright, soft original match sound. Each cascade climbs a musical step.
	var notes := [392.0, 440.0, 493.88, 587.33, 659.25, 783.99, 880.0, 987.77]
	var idx: int = mini(chain, notes.size() - 1)
	var base: float = notes[idx]
	play_layered_tone(base, 0.070, 0.15, 0.55)
	play_layered_tone(base * 2.0, 0.038, 0.055, 0.25)

func play_chain_burst() -> void:
	play_layered_tone(523.25, 0.10, 0.14, 0.45)
	play_layered_tone(783.99, 0.12, 0.10, 0.25)
	play_noise_burst(0.075, 0.055, 0.80)

func play_rocket() -> void:
	play_sweep(300.0, 1250.0, 0.18, 0.16)
	play_noise_burst(0.13, 0.075, 0.55)
	play_layered_tone(880.0, 0.055, 0.08, 0.25)

func play_bomb() -> void:
	play_sweep(145.0, 58.0, 0.24, 0.27)
	play_noise_burst(0.16, 0.13, 0.30)
	play_layered_tone(82.4, 0.25, 0.16, 0.65)

func play_core() -> void:
	play_sweep(360.0, 1350.0, 0.25, 0.12)
	play_layered_tone(659.25, 0.20, 0.12, 0.35)
	play_layered_tone(987.77, 0.16, 0.08, 0.25)
	play_layered_tone(1318.5, 0.12, 0.055, 0.20)

func play_jackpot(chain: int) -> void:
	var boost: float = minf(float(chain - 5) * 25.0, 100.0)
	play_layered_tone(1046.5 + boost, 0.16, 0.10, 0.25)
	play_layered_tone(1318.5 + boost, 0.18, 0.08, 0.20)
	play_layered_tone(1568.0 + boost, 0.20, 0.065, 0.18)

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
	blast_fx(Color("fff0a8"), 0.32)
	play_layered_tone(523.25, 0.30, 0.11, 0.20)
	play_layered_tone(659.25, 0.32, 0.09, 0.20)
	play_layered_tone(783.99, 0.34, 0.08, 0.20)
	play_layered_tone(1046.5, 0.36, 0.065, 0.20)
	var label = game.get("status_label")
	if label != null:
		label.add_theme_font_size_override("font_size", 28)
		pop_status(1.35)

func next_player() -> AudioStreamPlayer:
	var p: AudioStreamPlayer = audio_players[audio_index]
	audio_index = (audio_index + 1) % audio_players.size()
	return p

func play_layered_tone(freq: float, duration: float, volume: float, softness: float) -> void:
	if audio_players.is_empty(): return
	var frames: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t: float = float(i) / sample_rate
		var k: float = float(i) / float(frames)
		var attack: float = minf(1.0, float(i) / maxf(1.0, sample_rate * 0.006))
		var env: float = attack * pow(1.0 - k, 1.4)
		var fundamental: float = sin(TAU * freq * t)
		var harmonic: float = sin(TAU * freq * 2.01 * t) * softness
		var shimmer: float = sin(TAU * freq * 3.0 * t) * softness * 0.16
		var v: float = (fundamental + harmonic + shimmer) / (1.0 + softness) * env * volume
		write_sample(data, i, v)
	play_pcm(data)

func play_sweep(from_freq: float, to_freq: float, duration: float, volume: float) -> void:
	if audio_players.is_empty(): return
	var frames: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var phase: float = 0.0
	for i in frames:
		var k: float = float(i) / float(frames)
		var freq: float = lerpf(from_freq, to_freq, smoothstep(0.0, 1.0, k))
		phase += TAU * freq / sample_rate
		var env: float = sin(PI * clampf(k * 1.15, 0.0, 1.0)) * pow(1.0-k, 0.35)
		var v: float = (sin(phase) + sin(phase*2.0)*0.22) * env * volume
		write_sample(data, i, v)
	play_pcm(data)

func play_noise_burst(duration: float, volume: float, brightness: float) -> void:
	if audio_players.is_empty(): return
	var frames: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var previous: float = 0.0
	for i in frames:
		var k: float = float(i) / float(frames)
		var raw: float = rng.randf_range(-1.0, 1.0)
		var filtered: float = lerpf(previous, raw, brightness)
		previous = filtered
		var env: float = pow(1.0-k, 2.2)
		write_sample(data, i, filtered * env * volume)
	play_pcm(data)

func write_sample(data: PackedByteArray, i: int, value: float) -> void:
	var s: int = int(clampf(value, -1.0, 1.0) * 32767.0)
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
