extends Node

var game: Control
var overlay: Control
var started := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("setup")

func setup() -> void:
	for i in range(9):
		await get_tree().process_frame
	game = get_tree().current_scene as Control
	if game == null:
		return
	show_start()

func show_start() -> void:
	if started:
		return
	if game == null:
		game = get_tree().current_scene as Control
	if game == null:
		return
	close_start()

	overlay = Control.new()
	overlay.name = "StartScreen"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 400
	game.add_child(overlay)

	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/tropical_bg.svg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)

	var tint := ColorRect.new()
	tint.color = Color(0.02, 0.18, 0.30, 0.24)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(tint)

	var glow := PanelContainer.new()
	glow.position = Vector2(70, 85)
	glow.size = Vector2(580, 690)
	glow.add_theme_stylebox_override("panel", make_card())
	overlay.add_child(glow)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	glow.add_child(box)

	var badge := Label.new()
	badge.text = "МУТАНТЫ • КОМБО • ВЗРЫВЫ"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 18)
	badge.add_theme_color_override("font_color", Color("dff5ff"))
	box.add_child(badge)

	var title := Label.new()
	title.text = "MUTANT\nMATCH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 62)
	title.add_theme_color_override("font_color", Color("fff1a8"))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.12, 0.20, 0.85))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 5)
	box.add_child(title)

	var monster := TextureRect.new()
	monster.texture = load("res://assets/ui/monster_red.svg")
	monster.custom_minimum_size = Vector2(260, 210)
	monster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	monster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	monster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(monster)

	var subtitle := Label.new()
	subtitle.text = "Собирай фишки, ломай коробки\nи создавай мощные бустеры!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(subtitle)

	var play := Button.new()
	play.text = "ИГРАТЬ"
	play.custom_minimum_size = Vector2(360, 92)
	play.focus_mode = Control.FOCUS_NONE
	play.add_theme_font_size_override("font_size", 36)
	play.add_theme_color_override("font_color", Color.WHITE)
	play.add_theme_stylebox_override("normal", make_button(Color("23a95f"), Color("ffe06b")))
	play.add_theme_stylebox_override("hover", make_button(Color("2dcf73"), Color("fff3a0")))
	play.add_theme_stylebox_override("pressed", make_button(Color("17894a"), Color("ffd24a")))
	play.pressed.connect(start_game.bind(play))
	box.add_child(play)

	var footer := Label.new()
	footer.text = "30 УРОВНЕЙ  •  КОРОБКИ  •  КОМБО"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 17)
	footer.add_theme_color_override("font_color", Color("d7efff"))
	box.add_child(footer)

	animate_intro(glow, monster, play)

func start_game(button: Button) -> void:
	if started:
		return
	started = true
	button.disabled = true
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(overlay, "modulate:a", 0.0, 0.22)
	tw.tween_property(overlay, "scale", Vector2(1.04, 1.04), 0.22)
	await tw.finished
	close_start()
	var level_map = get_node_or_null("/root/LevelMap")
	if level_map != null:
		level_map.show_map()

func close_start() -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null

func animate_intro(card: Control, monster: Control, play: Control) -> void:
	card.modulate.a = 0.0
	card.scale = Vector2(0.92, 0.92)
	card.pivot_offset = card.size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.32)
	tw.tween_property(card, "scale", Vector2.ONE, 0.38)

	monster.pivot_offset = monster.size * 0.5
	var bob := create_tween().set_loops()
	bob.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(monster, "rotation", 0.035, 0.75)
	bob.tween_property(monster, "rotation", -0.035, 0.75)

	play.pivot_offset = play.size * 0.5
	var pulse := create_tween().set_loops()
	pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(play, "scale", Vector2(1.045, 1.045), 0.62)
	pulse.tween_property(play, "scale", Vector2.ONE, 0.62)

func make_card() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.34, 0.57, 0.94)
	s.corner_radius_top_left = 42
	s.corner_radius_top_right = 42
	s.corner_radius_bottom_left = 42
	s.corner_radius_bottom_right = 42
	s.set_border_width_all(5)
	s.border_color = Color("f1c86f")
	s.shadow_color = Color(0, 0, 0, 0.48)
	s.shadow_size = 22
	s.shadow_offset = Vector2(0, 10)
	s.content_margin_left = 26
	s.content_margin_right = 26
	s.content_margin_top = 28
	s.content_margin_bottom = 24
	return s

func make_button(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 30
	s.corner_radius_top_right = 30
	s.corner_radius_bottom_left = 30
	s.corner_radius_bottom_right = 30
	s.set_border_width_all(5)
	s.border_color = border
	s.shadow_color = Color(0, 0, 0, 0.38)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 5)
	return s
