extends Node

var game: Control
var board_grid: GridContainer
var colors := [Color("ff354f"), Color("1788ff"), Color("ffbf19"), Color("50df3d"), Color("a93cff"), Color("ff7a22")]

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	await get_tree().process_frame
	game = get_tree().current_scene as Control
	if game == null: return
	board_grid = game.get("board_grid")
	make_lab_background()
	upgrade_board_panel()
	upgrade_hud()
	await get_tree().process_frame
	upgrade_tiles()

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
		glow.size = Vector2(18 + (i%3)*8, 18 + (i%3)*8)
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
	s.shadow_color = Color(0.0,0.0,0.0,0.62)
	s.shadow_size = 18
	s.shadow_offset = Vector2(0,8)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", s)

func upgrade_hud() -> void:
	var title: Label = find_label("MUTANT MATCH")
	if title != null:
		title.add_theme_font_size_override("font_size", 46)
		title.add_theme_color_override("font_color", Color("9cff32"))
		title.add_theme_color_override("font_shadow_color", Color("061322"))
		title.add_theme_constant_override("shadow_offset_x", 4)
		title.add_theme_constant_override("shadow_offset_y", 5)
	for prop in ["moves_label", "score_label", "goal_label"]:
		var label: Label = game.get(prop)
		if label != null:
			var s := StyleBoxFlat.new()
			s.bg_color = Color("172b52")
			s.corner_radius_top_left = 20
			s.corner_radius_top_right = 20
			s.corner_radius_bottom_left = 20
			s.corner_radius_bottom_right = 20
			s.set_border_width_all(3)
			s.border_color = Color("5d8bd4")
			s.shadow_color = Color(0,0,0,0.45)
			s.shadow_size = 8
			s.shadow_offset = Vector2(0,4)
			label.add_theme_stylebox_override("normal", s)
			label.add_theme_color_override("font_color", Color.WHITE)

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
			s.bg_color = colors[t]
			s.corner_radius_top_left = 24
			s.corner_radius_top_right = 24
			s.corner_radius_bottom_left = 24
			s.corner_radius_bottom_right = 24
			s.set_border_width_all(3)
			s.border_color = colors[t].lightened(0.48)
			s.shadow_color = Color(0,0,0,0.48)
			s.shadow_size = 7
			s.shadow_offset = Vector2(0,5)
			if special != 0:
				s.bg_color = colors[t].lightened(0.14)
				s.set_border_width_all(5)
				s.border_color = Color("fff2a6")
				s.shadow_color = Color(1.0,0.65,0.12,0.55)
				s.shadow_size = 11
			b.add_theme_stylebox_override("normal", s)
			var hover: StyleBoxFlat = s.duplicate()
			hover.bg_color = s.bg_color.lightened(0.12)
			b.add_theme_stylebox_override("hover", hover)
			var pressed: StyleBoxFlat = s.duplicate()
			pressed.bg_color = s.bg_color.darkened(0.10)
			b.add_theme_stylebox_override("pressed", pressed)
			b.add_theme_color_override("font_color", Color.WHITE)
			b.add_theme_color_override("font_shadow_color", Color(0,0,0,0.45))
			b.add_theme_constant_override("shadow_offset_x", 2)
			b.add_theme_constant_override("shadow_offset_y", 3)
			b.add_theme_font_size_override("font_size", 39 if special != 0 else 35)
