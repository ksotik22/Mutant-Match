extends Node

var game: Control
var board_grid: GridContainer
var goal_value: Label
var moves_value: Label
var chaos_label: Label
var chaos_bar: ProgressBar
var monster: TextureRect
var last_chaos := -1

var colors := [Color("ff5a66"), Color("668cff"), Color("ffd75c"), Color("7ed968"), Color("a66be0"), Color("ff9f4b")]
var piece_textures: Array[Texture2D] = []
var special_textures: Dictionary = {}

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	await get_tree().process_frame
	game = get_tree().current_scene as Control
	if game == null: return
	board_grid = game.get("board_grid")
	load_piece_art()
	make_soft_background()
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
	special_textures = {
		1: load("res://assets/pieces/rocket_h.svg"),
		2: load("res://assets/pieces/rocket_v.svg"),
		3: load("res://assets/pieces/bomb.svg"),
		4: load("res://assets/pieces/core.svg")
	}

func make_soft_background() -> void:
	var bg := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color("24476c"), Color("315f7b"), Color("2d6f73"), Color("21445f")])
	grad.offsets = PackedFloat32Array([0.0, 0.32, 0.70, 1.0])
	bg.gradient = grad
	bg.width = 720
	bg.height = 960
	bg.fill_from = Vector2(0.1, 0.0)
	bg.fill_to = Vector2(0.9, 1.0)
	var rect := TextureRect.new()
	rect.texture = bg
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(rect)
	game.move_child(rect, 1)

	var top_glow := ColorRect.new()
	top_glow.color = Color(0.45, 0.78, 0.95, 0.08)
	top_glow.position = Vector2(0, 0)
	top_glow.size = Vector2(720, 230)
	top_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(top_glow)
	game.move_child(top_glow, 2)

func upgrade_board_panel() -> void:
	if board_grid == null: return
	var panel := board_grid.get_parent() as PanelContainer
	if panel == null: return
	var s := StyleBoxFlat.new()
	s.bg_color = Color("294b6a")
	s.corner_radius_top_left = 30
	s.corner_radius_top_right = 30
	s.corner_radius_bottom_left = 30
	s.corner_radius_bottom_right = 30
	s.set_border_width_all(5)
	s.border_color = Color("78a8c8")
	s.shadow_color = Color(0.05, 0.12, 0.20, 0.48)
	s.shadow_size = 14
	s.shadow_offset = Vector2(0, 8)
	s.content_margin_left = 13
	s.content_margin_right = 13
	s.content_margin_top = 13
	s.content_margin_bottom = 13
	panel.add_theme_stylebox_override("panel", s)
	board_grid.add_theme_constant_override("h_separation", 5)
	board_grid.add_theme_constant_override("v_separation", 5)

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
	goal_panel.size = Vector2(224, 112)
	goal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_panel.add_theme_stylebox_override("panel", make_panel(Color("365f86"), Color("86b8dc"), 24, 8))
	layer.add_child(goal_panel)

	var goal_box := VBoxContainer.new()
	goal_box.alignment = BoxContainer.ALIGNMENT_CENTER
	goal_box.add_theme_constant_override("separation", 0)
	goal_panel.add_child(goal_box)
	var goal_title := Label.new()
	goal_title.text = "ЦЕЛЬ"
	goal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_title.add_theme_font_size_override("font_size", 20)
	goal_title.add_theme_color_override("font_color", Color("e6f4ff"))
	goal_box.add_child(goal_title)
	var goal_line := HBoxContainer.new()
	goal_line.alignment = BoxContainer.ALIGNMENT_CENTER
	goal_line.add_theme_constant_override("separation", 8)
	goal_box.add_child(goal_line)
	var goal_icon := TextureRect.new()
	goal_icon.texture = piece_textures[3]
	goal_icon.custom_minimum_size = Vector2(46, 46)
	goal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	goal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	goal_line.add_child(goal_icon)
	goal_value = Label.new()
	goal_value.text = "0 / 1500"
	goal_value.add_theme_font_size_override("font_size", 21)
	goal_value.add_theme_color_override("font_color", Color.WHITE)
	goal_line.add_child(goal_value)

	var moves_panel := PanelContainer.new()
	moves_panel.position = Vector2(290, 34)
	moves_panel.size = Vector2(136, 82)
	moves_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moves_panel.add_theme_stylebox_override("panel", make_panel(Color("3b648b"), Color("8fc2e5"), 22, 7))
	layer.add_child(moves_panel)
	var moves_box := VBoxContainer.new()
	moves_box.alignment = BoxContainer.ALIGNMENT_CENTER
	moves_panel.add_child(moves_box)
	var moves_title := Label.new()
	moves_title.text = "ХОДЫ"
	moves_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_title.add_theme_font_size_override("font_size", 17)
	moves_title.add_theme_color_override("font_color", Color("dcefff"))
	moves_box.add_child(moves_title)
	moves_value = Label.new()
	moves_value.text = "28"
	moves_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_value.add_theme_font_size_override("font_size", 28)
	moves_value.add_theme_color_override("font_color", Color.WHITE)
	moves_box.add_child(moves_value)

	monster = TextureRect.new()
	monster.texture = load("res://assets/ui/monster_red.svg")
	monster.position = Vector2(550, 0)
	monster.size = Vector2(150, 150)
	monster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	monster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	monster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(monster)

	chaos_label = Label.new()
	chaos_label.position = Vector2(456, 116)
	chaos_label.size = Vector2(226, 24)
	chaos_label.text = "ХАОС  0%"
	chaos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chaos_label.add_theme_font_size_override("font_size", 15)
	chaos_label.add_theme_color_override("font_color", Color("ffe8eb"))
	layer.add_child(chaos_label)

	chaos_bar = ProgressBar.new()
	chaos_bar.position = Vector2(464, 140)
	chaos_bar.size = Vector2(218, 23)
	chaos_bar.min_value = 0
	chaos_bar.max_value = 100
	chaos_bar.value = 0
	chaos_bar.show_percentage = false
	chaos_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chaos_bar.add_theme_stylebox_override("background", make_bar(Color("4b3b4b"), Color("866275")))
	chaos_bar.add_theme_stylebox_override("fill", make_bar(Color("e95365"), Color("ff9bab")))
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
	s.shadow_color = Color(0.05, 0.12, 0.20, 0.38)
	s.shadow_size = shadow
	s.shadow_offset = Vector2(0, 4)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	return s

func make_bar(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 11
	s.corner_radius_top_right = 11
	s.corner_radius_bottom_left = 11
	s.corner_radius_bottom_right = 11
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
		tw.tween_property(monster, "scale", Vector2(1.06, 1.06), 0.07)
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
			s.bg_color = Color("315776")
			s.corner_radius_top_left = 16
			s.corner_radius_top_right = 16
			s.corner_radius_bottom_left = 16
			s.corner_radius_bottom_right = 16
			s.set_border_width_all(2)
			s.border_color = Color("527b99")
			s.shadow_color = Color(0.05, 0.12, 0.20, 0.38)
			s.shadow_size = 4
			s.shadow_offset = Vector2(0, 3)
			if special != 0:
				s.bg_color = Color("365c79")
				s.set_border_width_all(4)
				s.border_color = Color("ffe5a0")
				s.shadow_color = Color(1.0, 0.72, 0.25, 0.42)
				s.shadow_size = 8
			b.add_theme_stylebox_override("normal", s)
			var hover: StyleBoxFlat = s.duplicate()
			hover.bg_color = s.bg_color.lightened(0.07)
			b.add_theme_stylebox_override("hover", hover)
			var pressed: StyleBoxFlat = s.duplicate()
			pressed.bg_color = s.bg_color.darkened(0.09)
			b.add_theme_stylebox_override("pressed", pressed)
			b.expand_icon = true
			b.icon_max_width = 50
			if special == 0:
				b.icon = piece_textures[t]
			else:
				b.icon = special_textures.get(special, piece_textures[t])
			b.text = ""
