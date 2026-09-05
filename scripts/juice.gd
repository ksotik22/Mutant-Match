extends Node

var game: Control
var last_status := ""
var last_score := 0
var audio: AudioStreamPlayer
var sample_rate := 22050.0

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	await get_tree().process_frame
	game = get_tree().current_scene as Control
	if game == null: return
	audio = AudioStreamPlayer.new()
	game.add_child(audio)
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
	tw.tween_property(button, "scale", Vector2(0.88, 0.88), 0.07)
	play_tone(520.0, 0.035, 0.11)

func piece_release(button: Button) -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(button, "scale", Vector2(1.08, 1.08), 0.06)
	tw.tween_property(button, "scale", Vector2.ONE, 0.09)

func _process(_delta: float) -> void:
	if game == null: return
	var status = game.get("status_label")
	if status != null and str(status.text) != last_status:
		last_status = str(status.text)
		on_status(last_status)
	var current_score := int(game.get("score"))
	if current_score > last_score:
		pulse_score()
	last_score = current_score

func on_status(text: String) -> void:
	if "КАСКАД" in text:
		var chain := cascade_number(text)
		cascade_fx(chain)
	elif "ЦЕПНАЯ" in text:
		blast_fx(Color("fff08a"), 0.20)
		play_chord([330.0, 495.0, 660.0], 0.11)
	elif "РАКЕТА" in text:
		blast_fx(Color("7ee8ff"), 0.13)
		play_sweep(420.0, 900.0, 0.13)
	elif "БОМБА" in text:
		blast_fx(Color("ff8a65"), 0.22)
		play_tone(105.0, 0.16, 0.25)
	elif "ЯДРО" in text:
		blast_fx(Color("d79cff"), 0.25)
		play_chord([440.0, 660.0, 880.0], 0.15)
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
	var pitch := 520.0 + float(chain) * 95.0
	play_tone(pitch, 0.09, 0.16)
	pop_status(1.0 + minf(float(chain) * 0.08, 0.38))
	if chain >= 3: blast_fx(Color("ffffff"), 0.07 + float(chain) * 0.015)

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
	play_chord([523.25, 659.25, 783.99, 1046.5], 0.22)
	var label = game.get("status_label")
	if label != null:
		label.add_theme_font_size_override("font_size", 28)
		pop_status(1.35)

func play_chord(freqs: Array, duration: float) -> void:
	if audio == null: return
	var frames := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / sample_rate
		var envelope := 1.0 - float(i) / float(frames)
		var v := 0.0
		for f in freqs: v += sin(TAU * float(f) * t)
		v = v / float(freqs.size()) * envelope * 0.18
		var s := int(clampf(v, -1.0, 1.0) * 32767.0)
		data[i*2] = s & 255
		data[i*2+1] = (s >> 8) & 255
	play_pcm(data)

func play_tone(freq: float, duration: float, volume: float) -> void:
	if audio == null: return
	var frames := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / sample_rate
		var envelope := 1.0 - float(i) / float(frames)
		var v := sin(TAU * freq * t) * envelope * volume
		var s := int(clampf(v, -1.0, 1.0) * 32767.0)
		data[i*2] = s & 255
		data[i*2+1] = (s >> 8) & 255
	play_pcm(data)

func play_sweep(from_freq: float, to_freq: float, duration: float) -> void:
	if audio == null: return
	var frames := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var phase := 0.0
	for i in frames:
		var k := float(i) / float(frames)
		var freq := lerpf(from_freq, to_freq, k)
		phase += TAU * freq / sample_rate
		var v := sin(phase) * (1.0-k) * 0.20
		var s := int(clampf(v,-1.0,1.0)*32767.0)
		data[i*2] = s & 255
		data[i*2+1] = (s >> 8) & 255
	play_pcm(data)

func play_pcm(data: PackedByteArray) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false
	stream.data = data
	audio.stream = stream
	audio.play()
