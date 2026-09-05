extends Node

var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var phase_time := 0.0
var mix_rate := 44100.0

func _ready() -> void:
	call_deferred("setup_music")

func setup_music() -> void:
	await get_tree().process_frame
	player = AudioStreamPlayer.new()
	player.name = "BackgroundMusic"
	player.volume_db = -24.0
	add_child(player)
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = mix_rate
	stream.buffer_length = 0.7
	player.stream = stream
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback

func _process(_delta: float) -> void:
	if playback == null: return
	var frames := playback.get_frames_available()
	for i in frames:
		var t := phase_time
		var bar := fmod(t, 16.0)
		var root := 220.0
		if bar >= 4.0 and bar < 8.0: root = 174.61
		elif bar >= 8.0 and bar < 12.0: root = 196.0
		elif bar >= 12.0: root = 164.81
		var pad := sin(TAU * root * t) * 0.030
		pad += sin(TAU * root * 1.5 * t) * 0.020
		pad += sin(TAU * root * 2.0 * t) * 0.012
		var pulse_phase := fmod(t, 2.0)
		var pluck_env := exp(-pulse_phase * 3.2)
		var pluck_note := root * (2.0 if int(t / 2.0) % 2 == 0 else 2.25)
		var pluck := sin(TAU * pluck_note * t) * 0.025 * pluck_env
		var shimmer := sin(TAU * (root * 3.0) * t) * 0.005 * (0.5 + 0.5 * sin(TAU * 0.125 * t))
		var sample := clampf(pad + pluck + shimmer, -0.18, 0.18)
		playback.push_frame(Vector2(sample, sample))
		phase_time += 1.0 / mix_rate
