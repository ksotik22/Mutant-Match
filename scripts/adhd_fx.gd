extends Node

var game: Control
var last_score := 0
var last_status := ""
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	call_deferred("setup")

func setup() -> void:
	for i in range(6):
		await get_tree().process_frame
	game = get_tree().current_scene as Control
	if game == null:
		return
	last_score = int(game.get("score"))
	if game.get("status_label") != null:
		last_status = str(game.status_label.text)

func _process(_delta: float) -> void:
	if game == null:
		return
	var score := int(game.get("score"))
	if score > last_score:
		var delta_score := score - last_score
		spawn_score_pop(delta_score)
		bounce_random_tiles(mini(5, 1 + delta_score / 120))
	last_score = score
	var status = game.get("status_label")
	if status != null and str(status.text) != last_status:
		last_status = str(status.text)
		if "КАСКАД" in last_status or "ЦЕПНАЯ" in last_status:
			combo_burst()
		elif "КОРОБКА" in last_status:
			mini_burst(Color("ffd166"))
		elif "ПОБЕДА" in last_status:
			victory_confetti()

func spawn_score_pop(amount: int) -> void:
	var label := Label.new()
	label.text = "+%d" % amount
	label.position = Vector2(292 + rng.randf_range(-45, 45), 360 + rng.randf_range(-20, 35))
	label.size = Vector2(150, 60)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 140
	label.add_theme_font_size_override("font_size", 38 if amount < 300 else 48)
	label.add_theme_color_override("font_color", Color("fff176") if amount < 300 else Color("ffb347"))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	game.add_child(label)
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2(0.35, 0.35)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "scale", Vector2(1.18, 1.18), 0.10)
	tw.tween_property(label, "scale", Vector2.ONE, 0.08)
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 95.0, 0.58)
	tw.tween_property(label, "modulate:a", 0.0, 0.58).set_delay(0.18)
	tw.chain().tween_callback(label.queue_free)

func bounce_random_tiles(count: int) -> void:
	var cells = game.get("cells")
	if cells == null or cells.is_empty():
		return
	for i in range(count):
		var y := rng.randi_range(0, 7)
		var x := rng.randi_range(0, 7)
		if y >= cells.size() or x >= cells[y].size():
			continue
		var b: Button = cells[y][x]
		if b == null:
			continue
		b.pivot_offset = b.size * 0.5
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "scale", Vector2(1.16, 0.88), 0.06)
		tw.tween_property(b, "scale", Vector2(0.94, 1.10), 0.06)
		tw.tween_property(b, "scale", Vector2.ONE, 0.08)

func combo_burst() -> void:
	mini_burst(Color("fff7a8"))
	var banner := Label.new()
	banner.text = ["КОМБО!", "ВАУ!", "БУМ!", "СУПЕР!"][rng.randi_range(0, 3)]
	banner.position = Vector2(210, 250)
	banner.size = Vector2(300, 80)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 145
	banner.add_theme_font_size_override("font_size", 52)
	banner.add_theme_color_override("font_color", Color("ffffff"))
	banner.add_theme_color_override("font_shadow_color", Color(0.1, 0.1, 0.2, 0.9))
	banner.add_theme_constant_override("shadow_offset_x", 4)
	banner.add_theme_constant_override("shadow_offset_y", 4)
	game.add_child(banner)
	banner.pivot_offset = banner.size * 0.5
	banner.rotation = rng.randf_range(-0.08, 0.08)
	banner.scale = Vector2(0.25, 0.25)
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(banner, "scale", Vector2(1.18, 1.18), 0.12)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.08)
	tw.tween_interval(0.18)
	tw.tween_property(banner, "scale", Vector2(1.35, 0.2), 0.10)
	tw.parallel().tween_property(banner, "modulate:a", 0.0, 0.10)
	tw.tween_callback(banner.queue_free)

func mini_burst(color: Color) -> void:
	for i in range(10):
		var dot := ColorRect.new()
		dot.color = color.lightened(rng.randf_range(0.0, 0.25))
		dot.size = Vector2(rng.randf_range(5, 11), rng.randf_range(5, 11))
		dot.position = Vector2(360, 430)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.z_index = 130
		game.add_child(dot)
		var angle := rng.randf_range(0, TAU)
		var dist := rng.randf_range(55, 150)
		var target := dot.position + Vector2(cos(angle), sin(angle)) * dist
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(dot, "position", target, rng.randf_range(0.28, 0.45))
		tw.tween_property(dot, "rotation", rng.randf_range(-4.0, 4.0), 0.38)
		tw.tween_property(dot, "modulate:a", 0.0, 0.40)
		tw.chain().tween_callback(dot.queue_free)

func victory_confetti() -> void:
	for i in range(34):
		var bit := ColorRect.new()
		bit.color = [Color("ff5b70"), Color("4da6ff"), Color("ffd447"), Color("63d66b"), Color("a96cff"), Color("ff914d")][rng.randi_range(0, 5)]
		bit.size = Vector2(rng.randf_range(6, 12), rng.randf_range(10, 18))
		bit.position = Vector2(rng.randf_range(40, 680), rng.randf_range(170, 270))
		bit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bit.z_index = 150
		game.add_child(bit)
		var end_pos := bit.position + Vector2(rng.randf_range(-80, 80), rng.randf_range(260, 520))
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(bit, "position", end_pos, rng.randf_range(0.8, 1.4))
		tw.tween_property(bit, "rotation", rng.randf_range(-10, 10), 1.1)
		tw.tween_property(bit, "modulate:a", 0.0, 1.2).set_delay(0.35)
		tw.chain().tween_callback(bit.queue_free)
