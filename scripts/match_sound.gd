extends Node

var game: Control
var last_score: int = 0
var players: Array[AudioStreamPlayer] = []
var player_index: int = 0
var sample_rate := 44100.0

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	for i in range(4):
		await get_tree().process_frame
	game = get_tree().current_scene as Control
	if game == null:
		return
	last_score = int(game.get("score"))
	for i in range(4):
		var p := AudioStreamPlayer.new()
		p.volume_db = -2.0
		add_child(p)
		players.append(p)

func _process(_delta: float) -> void:
	if game == null:
		return
	var score := int(game.get("score"))
	if score > last_score:
		play_match_pop(score - last_score)
	last_score = score

func play_match_pop(delta_score: int) -> void:
	if players.is_empty():
		return
	var strength := clampf(float(delta_score) / 240.0, 0.0, 1.0)
	var duration := 0.11
	var frames := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var base_freq := 610.0 + strength * 130.0
	for i in range(frames):
		var t := float(i) / sample_rate
		var k := float(i) / float(frames)
		var env := pow(1.0 - k, 2.4)
		var pitch := base_freq * (1.18 - 0.18 * k)
		var v := sin(TAU * pitch * t) * 0.18
		v += sin(TAU * pitch * 1.50 * t) * 0.08
		v += sin(TAU * pitch * 2.05 * t) * 0.035
		var sample := int(clampf(v * env, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 255
		data[i * 2 + 1] = (sample >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(sample_rate)
	stream.stereo = false
	stream.data = data
	var p: AudioStreamPlayer = players[player_index]
	player_index = (player_index + 1) % players.size()
	p.stream = stream
	p.pitch_scale = randf_range(0.97, 1.05)
	p.play()
