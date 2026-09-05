extends Node

var game: Control
var board_grid: GridContainer
var goal_value: Label
var moves_value: Label
var chaos_label: Label
var chaos_bar: ProgressBar
var monster: TextureRect
var last_chaos := -1

var colors := [Color("ff354f"), Color("1788ff"), Color("ffbf19"), Color("50df3d"), Color("a93cff"), Color("ff7a22")]
var piece_textures: Array[Texture2D] = []

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	await get_tree().process_frame
	game = get_tree().current_scene as Control
	if game == null: return
	board_grid = game.get("board_grid")
	load_piece_art()
	make_lab_background()
	upgrade_board_panel()
	hide_old_header()
	build_reference_hud()
	await get_tree().process_frame
	upgrade_tiles()
	update_reference_hud()

func load_piece_art() -> void:
	piece_textures = [
		load("res://assets/pieces/red.svg"),
		load("res://assets/pieces/blue.svg"),
		load("res://assets/pieces/yellow.svg"),
		load("res://assets/pieces/green.svg"),
		load("res://assets/pieces/purple.svg"),
		load("res://assets/pieces/orange.svg")
	]

func make_lab_background() -> void:
	var bg := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color("071225"), Color("10284a"), Color("143735"), Color("071322")])
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.72, 1.0])
	bg.gradient = grad
	bg.width = 720
	bg.height = 960
	bg.fill_from = Vector2(0.15, 0.0)
	bg.fill_to = Vector2(0.85, 1.0)
	var rect := TextureRect.new()
	rect.texture = bg
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(rect)
	game.move_child(rect, 1)
	for i in 8:
		var pipe := ColorRect.new()
		pipe.color = Color(0.08, 0.16, 0.22, 0.7)
		pipe.position = Vector2(25 + (i % 4) * 205, 40 + (i / 4) * 760)
		pipe.size = Vector2(22, 180)
		pipe.rotation = -0.18 if i % 2 == 0 else 0.16
		pipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		game.add_child(pipe)
		game.move_child(pipe, 2)
	for i in 12:
		var glow := ColorRect.new()
		glow.color = Color(0.28, 1.0, 0.18, 0.10)
		glow.position = Vector2(20 + (i * 83) % 680, 100 + (i * 137) % 800)
		glow.size = Vector2(18 + (i % 3) * 8, 18 + (i % 3) * 8)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		game.add_child(glow)
		game.move_child(glow, 3)

func upgrade_board_panel() -> void:
	if board_grid == null: return
	var panel := board_grid.get_parent() as PanelContainer
	if panel == null: return
	var s := StyleBoxFlat.new()
	s.bg_color = Color("101c32")
	s.corner_radius_top_left = 28
	s.corner_radius_top_right = 28
	s.corner_radius_bottom_left = 28
	s.corner_radius_bottom_right = 28
	s.set_border_width_all(5)
	s.border_color = Color("6aa7ff")
	s.shadow_color = Color(0.0, 0.0, 0.0, 0.62)
	s.shadow_size = 18
	s.shadow_offset = Vector2(0, 8)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", s)

func hide_old_header() -> void:
	var title := find_label("MUTANT MATCH")
	if title != null: title.visible = false
	for node in get_all_children(game):
		if node is Label and "Цепные реакции" in node.text:
			node.visible = false
	for prop in ["moves_label", "score_label", "goal_label"]:
		var label: Label = game.get(prop)
		if label != null: label.visible = false

func build_reference_hud() -> void:
	var layer := Control.new()
	layer.name = "ReferenceHUD"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.z_index = 30
	game.add_child(layer)

	var goal_panel := PanelContainer.new()
	goal_panel.position = Vector2(24, 24)
	goal_panel.size = Vector2(224, 118)
	goal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_panel.add_theme_stylebox_override("panel", make_panel(Color("19325e"), Color("72aaff"), 24, 10))
	layer.add_child(goal_panel)

	var goal_box := VBoxContainer.new()
	goal_box.alignment = BoxContainer.ALIGNMENT_CENTER
	goal_box.add_theme_constant_override("separation", 2)
	goal_panel.add_child(goal_box)
	var goal_title := Label.new()
	goal_title.text = "ЦЕЛЬ"
	goal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_title.add_theme_font_size_override("font_size", 22)
	goal_title.add_theme_color_override("font_color", Color("d8ebff"))
	goal_box.add_child(goal_title)
	var goal_line := HBoxContainer.new()
	goal_line.alignment = BoxContainer.ALIGNMENT_CENTER
	goal_line.add_theme_constant_override("separation", 10)
	goal_box.add_child(goal_line)
	var goal_icon := TextureRect.new()
	goal_icon.texture = piece_textures[3]
	goal_icon.custom_minimum_size = Vector2(54, 54)
	goal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	goal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	goal_line.add_child(goal_icon)
	goal_value = Label.new()
	goal_value.text = "0 / 1500"
	goal_value.add_theme_font_size_override("font_size", 22)
	goal_value.add_theme_color_override("font_color", Color.WHITE)
	goal_line.add_child(goal_value)

	var moves_panel := PanelContainer.new()
	moves_panel.position = Vector2(292, 34)
	moves_panel.size = Vector2(136, 86)
	moves_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moves_panel.add_theme_stylebox_override("panel", make_panel(Color("213f72"), Color("89bdff"), 22, 8))
	layer.add_child(moves_panel)
	var moves_box := VBoxContainer.new()
	moves_box.alignment = BoxContainer.ALIGNMENT_CENTER
	moves_panel.add_child(moves_box)
	var moves_title := Label.new()
	moves_title.text = "ХОДЫ"
	moves_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_title.add_theme_font_size_override("font_size", 18)
	moves_title.add_theme_color_override("font_color", Color("cce3ff"))
	moves_box.add_child(moves_title)
	moves_value = Label.new()
	moves_value.text = "28"
	moves_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_value.add_theme_font_size_override("font_size", 30)
	moves_value.add_theme_color_override("font_color", Color.WHITE)
	moves_box.add_child(moves_value)

	monster = TextureRect.new()
	monster.texture = load("res://assets/ui/monster_red.svg")
	monster.position = Vector2(552, -2)
	monster.size = Vector2(154, 154)
	monster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	monster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	monster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(monster)

	chaos_label = Label.new()
	chaos_label.position = Vector2(456, 119)
	chaos_label.size = Vector2(230, 24)
	chaos_label.text = "ХАОС  0%"
	chaos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chaos_label.add_theme_font_size_override("font_size", 16)
	chaos_label.add_theme_color_override("font_color", Color("ffd6dd"))
	layer.add_child(chaos_label)

	chaos_bar = ProgressBar.new()
	chaos_bar.position = Vector2(464, 143)
	chaos_bar.size = Vector2(218, 25)
	chaos_bar.min_value = 0
	chaos_bar.max_value = 100
	chaos_bar.value = 0
	chaos_bar.show_percentage = false
	chaos_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chaos_bar.add_theme_stylebox_override("background", make_bar(Color("301c31"), Color("71364b")))
	chaos_bar.add_theme_stylebox_override("fill", make_bar(Color("ff3551"), Color("ff92a1")))
	layer.add_child(chaos_bar)

func make_panel(bg: Color, border: Color, radius: int, shadow: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.set_border_width_all(3)
	s.border_color = border
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = shadow
	s.shadow_offset = Vector2(0, 5)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func make_bar(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 12
	s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.set_border_width_all(2)
	s.border_color = border
	return s

func find_label(value: String) -> Label:
	for node in get_all_children(game):
		if node is Label and node.text == value: return node
	return null

func get_all_children(node: Node) -> Array:
	var out: Array = []
	for child in node.get_children():
		out.append(child)
		out.append_array(get_all_children(child))
	return out

func _process(_delta: float) -> void:
	if game == null or board_grid == null: return
	upgrade_tiles()
	update_reference_hud()

func update_reference_hud() -> void:
	if goal_value == null: return
	var current_score: int = int(game.get("score"))
	var target_score: int = int(game.get("target"))
	var current_moves: int = int(game.get("moves"))
	goal_value.text = "%d / %d" % [current_score, target_score]
	moves_value.text = str(current_moves)
	var chaos: int = 0
	if target_score > 0:
		chaos = clampi(int(round(float(current_score) / float(target_score) * 100.0)), 0, 100)
	chaos_bar.value = chaos
	chaos_label.text = "ХАОС  %d%%" % chaos
	if chaos != last_chaos and chaos > 0 and monster != null:
		last_chaos = chaos
		monster.pivot_offset = monster.size * 0.5
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(monster, "scale", Vector2(1.08, 1.08), 0.07)
		tw.tween_property(monster, "scale", Vector2.ONE, 0.11)

func upgrade_tiles() -> void:
	var cells = game.get("cells")
	var board = game.get("board")
	var specials = game.get("specials")
	if cells == null or board == null or specials == null: return
	for y in range(mini(8, cells.size())):
		for x in range(mini(8, cells[y].size())):
			var b: Button = cells[y][x]
			var t: int = int(board[y][x])
			if t < 0 or t >= colors.size(): continue
			var special: int = int(specials[y][x])
			var s := StyleBoxFlat.new()
			s.bg_color = colors[t].darkened(0.13)
			s.corner_radius_top_left = 22
			s.corner_radius_top_right = 22
			s.corner_radius_bottom_left = 22
			s.corner_radius_bottom_right = 22
			s.set_border_width_all(2)
			s.border_color = colors[t].lightened(0.32)
			s.shadow_color = Color(0, 0, 0, 0.50)
			s.shadow_size = 6
			s.shadow_offset = Vector2(0, 5)
			if special != 0:
				s.bg_color = colors[t].lightened(0.02)
				s.set_border_width_all(5)
				s.border_color = Color("fff0a0")
				s.shadow_color = Color(1.0, 0.65, 0.12, 0.55)
				s.shadow_size = 10
			b.add_theme_stylebox_override("normal", s)
			var hover: StyleBoxFlat = s.duplicate()
			hover.bg_color = s.bg_color.lightened(0.10)
			b.add_theme_stylebox_override("hover", hover)
			var pressed: StyleBoxFlat = s.duplicate()
			pressed.bg_color = s.bg_color.darkened(0.12)
			b.add_theme_stylebox_override("pressed", pressed)
			b.icon = piece_textures[t]
			b.expand_icon = true
			if special == 0:
				b.text = ""
			else:
				match special:
					1: b.text = "↔"
					2: b.text = "↕"
					3: b.text = "✹"
					4: b.text = "◎"
			b.add_theme_color_override("font_color", Color.WHITE)
			b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
			b.add_theme_constant_override("shadow_offset_x", 2)
			b.add_theme_constant_override("shadow_offset_y", 3)
			b.add_theme_font_size_override("font_size", 26)
