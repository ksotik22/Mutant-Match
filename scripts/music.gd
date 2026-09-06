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
	# Louder than before, but still leaves headroom for match/explosion SFX.
	player.volume_db = -11.0
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
		var t: float = phase_time
		var bar: float = fmod(t, 16.0)
		var root: float = 220.0
		if bar >= 4.0 and bar < 8.0: root = 174.61
		elif bar >= 8.0 and bar < 12.0: root = 196.0
		elif bar >= 12.0: root = 164.81

		# Warm pad.
		var pad: float = sin(TAU * root * t) * 0.050
		pad += sin(TAU * root * 1.5 * t) * 0.030
		pad += sin(TAU * root * 2.0 * t) * 0.018

		# More audible casual-game pluck rhythm.
		var pulse_phase: float = fmod(t, 1.0)
		var pluck_env: float = exp(-pulse_phase * 4.2)
		var step: int = int(t) % 4
		var ratios: Array[float] = [2.0, 2.25, 2.5, 2.25]
		var ratio: float = ratios[step]
		var pluck_note: float = root * ratio
		var pluck: float = sin(TAU * pluck_note * t) * 0.045 * pluck_env
		pluck += sin(TAU * pluck_note * 2.0 * t) * 0.012 * pluck_env

		# Light shimmer so the loop feels more energetic without becoming harsh.
		var shimmer: float = sin(TAU * (root * 3.0) * t) * 0.009 * (0.5 + 0.5 * sin(TAU * 0.125 * t))
		var bass_pulse: float = sin(TAU * (root * 0.5) * t) * 0.022 * exp(-fmod(t, 2.0) * 2.7)

		var sample: float = clampf(pad + pluck + shimmer + bass_pulse, -0.30, 0.30)
		playback.push_frame(Vector2(sample, sample))
		phase_time += 1.0 / mix_rate
