extends Node

var game: Control
var board_grid: GridContainer
var goal_value: Label
var moves_value: Label
var chaos_label: Label
var chaos_bar: ProgressBar
var monster: TextureRect
var last_chaos := -1

var colors := [Color("ff4b57"), Color("2f8dff"), Color("ffd84f"), Color("67d75b"), Color("a75be7"), Color("ff9847")]
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
	make_reference_background()
	upgrade_board_panel()
	hide_old_header()
	build_reference_hud()
	build_booster_bar()
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

func make_reference_background() -> void:
	var old_bg := game.get_child(0)
	if old_bg is ColorRect:
		old_bg.visible = false
	var rect := TextureRect.new()
	rect.name = "TropicalBackground"
	rect.texture = load("res://assets/ui/tropical_bg.svg")
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(rect)
	game.move_child(rect, 0)
	var veil := ColorRect.new()
	veil.color = Color(0.04, 0.18, 0.30, 0.10)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(veil)
	game.move_child(veil, 1)

func upgrade_board_panel() -> void:
	if board_grid == null: return
	var panel := board_grid.get_parent() as PanelContainer
	if panel == null: return
	var s := StyleBoxFlat.new()
	s.bg_color = Color("204b7a")
	s.corner_radius_top_left = 24
	s.corner_radius_top_right = 24
	s.corner_radius_bottom_left = 24
	s.corner_radius_bottom_right = 24
	s.set_border_width_all(5)
	s.border_color = Color("7bb9df")
	s.shadow_color = Color(0.02, 0.10, 0.18, 0.55)
	s.shadow_size = 16
	s.shadow_offset = Vector2(0, 8)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", s)
	board_grid.add_theme_constant_override("h_separation", 4)
	board_grid.add_theme_constant_override("v_separation", 4)

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
	goal_panel.position = Vector2(22, 18)
	goal_panel.size = Vector2(232, 126)
	goal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_panel.add_theme_stylebox_override("panel", make_panel(Color("f7e4b9"), Color("b57b42"), 24, 8))
	layer.add_child(goal_panel)
	var goal_box := VBoxContainer.new()
	goal_box.alignment = BoxContainer.ALIGNMENT_CENTER
	goal_box.add_theme_constant_override("separation", 2)
	goal_panel.add_child(goal_box)
	var goal_title := Label.new()
	goal_title.text = "Цели:"
	goal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_title.add_theme_font_size_override("font_size", 22)
	goal_title.add_theme_color_override("font_color", Color("5f3019"))
	goal_box.add_child(goal_title)
	var goal_line := HBoxContainer.new()
	goal_line.alignment = BoxContainer.ALIGNMENT_CENTER
	goal_line.add_theme_constant_override("separation", 10)
	goal_box.add_child(goal_line)
	var goal_icon := TextureRect.new()
	goal_icon.texture = piece_textures[3]
	goal_icon.custom_minimum_size = Vector2(48, 48)
	goal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	goal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	goal_line.add_child(goal_icon)
	goal_value = Label.new()
	goal_value.text = "0 / 1500"
	goal_value.add_theme_font_size_override("font_size", 20)
	goal_value.add_theme_color_override("font_color", Color("6a351b"))
	goal_line.add_child(goal_value)

	var moves_panel := PanelContainer.new()
	moves_panel.position = Vector2(276, 18)
	moves_panel.size = Vector2(168, 126)
	moves_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moves_panel.add_theme_stylebox_override("panel", make_panel(Color("1f78c9"), Color("0f4d91"), 24, 8))
	layer.add_child(moves_panel)
	var moves_box := VBoxContainer.new()
	moves_box.alignment = BoxContainer.ALIGNMENT_CENTER
	moves_panel.add_child(moves_box)
	var moves_title := Label.new()
	moves_title.text = "Ходы"
	moves_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_title.add_theme_font_size_override("font_size", 24)
	moves_title.add_theme_color_override("font_color", Color.WHITE)
	moves_box.add_child(moves_title)
	moves_value = Label.new()
	moves_value.text = "28"
	moves_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_value.add_theme_font_size_override("font_size", 44)
	moves_value.add_theme_color_override("font_color", Color.WHITE)
	moves_value.add_theme_color_override("font_shadow_color", Color("0a3b72"))
	moves_value.add_theme_constant_override("shadow_offset_x", 2)
	moves_value.add_theme_constant_override("shadow_offset_y", 3)
	moves_box.add_child(moves_value)

	var chaos_panel := PanelContainer.new()
	chaos_panel.position = Vector2(466, 18)
	chaos_panel.size = Vector2(232, 126)
	chaos_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chaos_panel.add_theme_stylebox_override("panel", make_panel(Color("f7e4b9"), Color("b57b42"), 24, 8))
	layer.add_child(chaos_panel)

	monster = TextureRect.new()
	monster.texture = load("res://assets/ui/monster_red.svg")
	monster.position = Vector2(505, 5)
	monster.size = Vector2(150, 102)
	monster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	monster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	monster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(monster)

	chaos_bar = ProgressBar.new()
	chaos_bar.position = Vector2(486, 91)
	chaos_bar.size = Vector2(192, 18)
	chaos_bar.min_value = 0
	chaos_bar.max_value = 100
	chaos_bar.value = 0
	chaos_bar.show_percentage = false
	chaos_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chaos_bar.add_theme_stylebox_override("background", make_bar(Color("4c3a64"), Color("6e557d")))
	chaos_bar.add_theme_stylebox_override("fill", make_bar(Color("d82bd9"), Color("ff7df0")))
	layer.add_child(chaos_bar)
	chaos_label = Label.new()
	chaos_label.position = Vector2(480, 109)
	chaos_label.size = Vector2(204, 24)
	chaos_label.text = "Шкала хаоса"
	chaos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chaos_label.add_theme_font_size_override("font_size", 16)
	chaos_label.add_theme_color_override("font_color", Color("5f3019"))
	layer.add_child(chaos_label)

func build_booster_bar() -> void:
	var bar := PanelContainer.new()
	bar.position = Vector2(108, 858)
	bar.size = Vector2(504, 82)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.z_index = 40
	bar.add_theme_stylebox_override("panel", make_panel(Color("8a5a34"), Color("d8a46a"), 30, 10))
	game.add_child(bar)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	bar.add_child(row)
	for tex in [special_textures[3], special_textures[1], special_textures[4], special_textures[2]]:
		var p := PanelContainer.new()
		p.custom_minimum_size = Vector2(70, 70)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_theme_stylebox_override("panel", make_panel(Color("1685db"), Color("f5c26e"), 35, 5))
		row.add_child(p)
		var icon := TextureRect.new()
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(icon)
	var pause := Label.new()
	pause.text = "Ⅱ"
	pause.custom_minimum_size = Vector2(70, 70)
	pause.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause.add_theme_font_size_override("font_size", 36)
	pause.add_theme_color_override("font_color", Color.WHITE)
	pause.add_theme_stylebox_override("normal", make_panel(Color("1685db"), Color("f5c26e"), 35, 5))
	row.add_child(pause)

func make_panel(bg: Color, border: Color, radius: int, shadow: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.set_border_width_all(3)
	s.border_color = border
	s.shadow_color = Color(0.04, 0.10, 0.16, 0.40)
	s.shadow_size = shadow
	s.shadow_offset = Vector2(0, 4)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func make_bar(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 9
	s.corner_radius_top_right = 9
	s.corner_radius_bottom_left = 9
	s.corner_radius_bottom_right = 9
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
			s.bg_color = Color("2b5684")
			s.corner_radius_top_left = 14
			s.corner_radius_top_right = 14
			s.corner_radius_bottom_left = 14
			s.corner_radius_bottom_right = 14
			s.set_border_width_all(2)
			s.border_color = Color("3d6d9a")
			s.shadow_color = Color(0.02, 0.08, 0.14, 0.35)
			s.shadow_size = 3
			s.shadow_offset = Vector2(0, 2)
			if special != 0:
				s.bg_color = Color("315d88")
				s.set_border_width_all(4)
				s.border_color = Color("ffe08a")
				s.shadow_color = Color(1.0, 0.68, 0.15, 0.45)
				s.shadow_size = 8
			b.add_theme_stylebox_override("normal", s)
			var hover: StyleBoxFlat = s.duplicate()
			hover.bg_color = s.bg_color.lightened(0.06)
			b.add_theme_stylebox_override("hover", hover)
			var pressed: StyleBoxFlat = s.duplicate()
			pressed.bg_color = s.bg_color.darkened(0.08)
			b.add_theme_stylebox_override("pressed", pressed)
			b.expand_icon = true
			if special == 0:
				b.icon = piece_textures[t]
			else:
				b.icon = special_textures.get(special, piece_textures[t])
			b.text = ""
