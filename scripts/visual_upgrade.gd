extends Node

var game: Control
var board_grid: GridContainer
var goal_value: Label
var moves_value: Label
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
	hide_old_ui()
	position_gameplay_area()
	upgrade_board_panel()
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
	if game.get_child_count() > 0:
		var old_bg := game.get_child(0)
		if old_bg is ColorRect: old_bg.visible = false
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
	veil.color = Color(0.02, 0.12, 0.22, 0.04)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(veil)
	game.move_child(veil, 1)

func hide_old_ui() -> void:
	for node in get_all_children(game):
		if node is Label:
			if node.text == "MUTANT MATCH" or "Цепные реакции" in node.text or "4 = ракета" in node.text:
				node.visible = false
		if node is Button and node.text == "НОВАЯ ИГРА":
			node.visible = false
	for prop in ["moves_label", "score_label", "goal_label"]:
		var label: Label = game.get(prop)
		if label != null: label.visible = false

func position_gameplay_area() -> void:
	if board_grid == null: return
	var panel := board_grid.get_parent()
	if panel == null: return
	var root := panel.get_parent()
	if root is VBoxContainer:
		root.position = Vector2(-305, -215)
		root.custom_minimum_size = Vector2(610, 610)
		root.alignment = BoxContainer.ALIGNMENT_BEGIN

func upgrade_board_panel() -> void:
	if board_grid == null: return
	var panel := board_grid.get_parent() as PanelContainer
	if panel == null: return
	var outer := StyleBoxFlat.new()
	outer.bg_color = Color("173f6d")
	outer.corner_radius_top_left = 28
	outer.corner_radius_top_right = 28
	outer.corner_radius_bottom_left = 28
	outer.corner_radius_bottom_right = 28
	outer.set_border_width_all(5)
	outer.border_color = Color("4f86ba")
	outer.shadow_color = Color(0.01, 0.08, 0.16, 0.62)
	outer.shadow_size = 18
	outer.shadow_offset = Vector2(0, 9)
	outer.content_margin_left = 10
	outer.content_margin_right = 10
	outer.content_margin_top = 10
	outer.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", outer)
	board_grid.add_theme_constant_override("h_separation", 3)
	board_grid.add_theme_constant_override("v_separation", 3)

func build_reference_hud() -> void:
	var layer := Control.new()
	layer.name = "ReferenceHUD"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.z_index = 30
	game.add_child(layer)

	# LEFT: goals card, matching the warm cream card from the reference.
	var goal_panel := PanelContainer.new()
	goal_panel.position = Vector2(16, 18)
	goal_panel.size = Vector2(254, 142)
	goal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_panel.add_theme_stylebox_override("panel", make_panel(Color("f9e7be"), Color("b7773d"), 26, 9))
	layer.add_child(goal_panel)
	var goal_box := VBoxContainer.new()
	goal_box.alignment = BoxContainer.ALIGNMENT_CENTER
	goal_box.add_theme_constant_override("separation", 4)
	goal_panel.add_child(goal_box)
	var goal_title := Label.new()
	goal_title.text = "Цели:"
	goal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	goal_title.add_theme_font_size_override("font_size", 22)
	goal_title.add_theme_color_override("font_color", Color("663419"))
	goal_box.add_child(goal_title)
	var targets := HBoxContainer.new()
	targets.alignment = BoxContainer.ALIGNMENT_CENTER
	targets.add_theme_constant_override("separation", 15)
	goal_box.add_child(targets)
	add_goal_item(targets, piece_textures[3], "24")
	add_goal_item(targets, load("res://assets/ui/goal_ice.svg"), "12")
	add_goal_item(targets, load("res://assets/ui/goal_crate.svg"), "8")
	goal_value = Label.new()
	goal_value.visible = false
	goal_box.add_child(goal_value)

	# CENTER: moves card.
	var moves_panel := PanelContainer.new()
	moves_panel.position = Vector2(282, 18)
	moves_panel.size = Vector2(156, 142)
	moves_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moves_panel.add_theme_stylebox_override("panel", make_panel(Color("1476c9"), Color("0b4c92"), 26, 9))
	layer.add_child(moves_panel)
	var moves_box := VBoxContainer.new()
	moves_box.alignment = BoxContainer.ALIGNMENT_CENTER
	moves_panel.add_child(moves_box)
	var moves_title := Label.new()
	moves_title.text = "Ходы"
	moves_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_title.add_theme_font_size_override("font_size", 23)
	moves_title.add_theme_color_override("font_color", Color.WHITE)
	moves_box.add_child(moves_title)
	moves_value = Label.new()
	moves_value.text = "28"
	moves_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_value.add_theme_font_size_override("font_size", 48)
	moves_value.add_theme_color_override("font_color", Color.WHITE)
	moves_value.add_theme_color_override("font_shadow_color", Color("063d78"))
	moves_value.add_theme_constant_override("shadow_offset_x", 2)
	moves_value.add_theme_constant_override("shadow_offset_y", 3)
	moves_box.add_child(moves_value)

	# RIGHT: monster card and chaos meter.
	var chaos_panel := PanelContainer.new()
	chaos_panel.position = Vector2(450, 18)
	chaos_panel.size = Vector2(254, 142)
	chaos_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chaos_panel.add_theme_stylebox_override("panel", make_panel(Color("f9e7be"), Color("b7773d"), 26, 9))
	layer.add_child(chaos_panel)
	monster = TextureRect.new()
	monster.texture = load("res://assets/ui/monster_red.svg")
	monster.position = Vector2(505, 22)
	monster.size = Vector2(144, 86)
	monster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	monster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	monster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(monster)
	chaos_bar = ProgressBar.new()
	chaos_bar.position = Vector2(470, 103)
	chaos_bar.size = Vector2(214, 22)
	chaos_bar.min_value = 0
	chaos_bar.max_value = 100
	chaos_bar.value = 0
	chaos_bar.show_percentage = false
	chaos_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chaos_bar.add_theme_stylebox_override("background", make_bar(Color("59496e"), Color("3f3453")))
	chaos_bar.add_theme_stylebox_override("fill", make_bar(Color("d932d5"), Color("ff83ef")))
	layer.add_child(chaos_bar)
	var chaos_text := Label.new()
	chaos_text.position = Vector2(468, 124)
	chaos_text.size = Vector2(218, 26)
	chaos_text.text = "Шкала хаоса"
	chaos_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chaos_text.add_theme_font_size_override("font_size", 17)
	chaos_text.add_theme_color_override("font_color", Color("663419"))
	layer.add_child(chaos_text)

func add_goal_item(parent: HBoxContainer, texture: Texture2D, count_text: String) -> void:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", -2)
	parent.add_child(box)
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(44, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon)
	var count := Label.new()
	count.text = count_text
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.add_theme_font_size_override("font_size", 17)
	count.add_theme_color_override("font_color", Color("683619"))
	box.add_child(count)

func build_booster_bar() -> void:
	var bar := PanelContainer.new()
	bar.position = Vector2(72, 850)
	bar.size = Vector2(576, 92)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.z_index = 40
	bar.add_theme_stylebox_override("panel", make_panel(Color("906039"), Color("dcb376"), 34, 11))
	game.add_child(bar)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 17)
	bar.add_child(row)
	add_booster(row, special_textures[3], "3")
	add_booster(row, special_textures[1], "3")
	add_booster(row, special_textures[4], "3")
	add_booster(row, special_textures[2], "3")
	var pause := Label.new()
	pause.text = "Ⅱ"
	pause.custom_minimum_size = Vector2(78, 78)
	pause.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause.add_theme_font_size_override("font_size", 38)
	pause.add_theme_color_override("font_color", Color.WHITE)
	pause.add_theme_stylebox_override("normal", make_panel(Color("1687dc"), Color("f6c96e"), 39, 5))
	row.add_child(pause)

func add_booster(parent: HBoxContainer, texture: Texture2D, count_text: String) -> void:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(86, 78)
	parent.add_child(holder)
	var circle := PanelContainer.new()
	circle.position = Vector2(0, 0)
	circle.size = Vector2(74, 74)
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_theme_stylebox_override("panel", make_panel(Color("1687dc"), Color("f6c96e"), 37, 5))
	holder.add_child(circle)
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_child(icon)
	var badge := Label.new()
	badge.position = Vector2(56, 49)
	badge.size = Vector2(30, 30)
	badge.text = count_text
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 18)
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.add_theme_stylebox_override("normal", make_panel(Color("e53b32"), Color("a91f1a"), 15, 2))
	holder.add_child(badge)

func make_panel(bg: Color, border: Color, radius: int, shadow: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.set_border_width_all(3)
	s.border_color = border
	s.shadow_color = Color(0.03, 0.08, 0.14, 0.42)
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
	if moves_value == null or chaos_bar == null: return
	moves_value.text = str(int(game.get("moves")))
	var current_score: int = int(game.get("score"))
	var target_score: int = int(game.get("target"))
	var chaos: int = 0
	if target_score > 0:
		chaos = clampi(int(round(float(current_score) / float(target_score) * 100.0)), 0, 100)
	chaos_bar.value = chaos
	if chaos != last_chaos and chaos > 0 and monster != null:
		last_chaos = chaos
		monster.pivot_offset = monster.size * 0.5
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(monster, "scale", Vector2(1.07, 1.07), 0.07)
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
			b.custom_minimum_size = Vector2(68, 68)
			var s := StyleBoxFlat.new()
			s.bg_color = Color("244b78")
			s.corner_radius_top_left = 11
			s.corner_radius_top_right = 11
			s.corner_radius_bottom_left = 11
			s.corner_radius_bottom_right = 11
			s.set_border_width_all(1)
			s.border_color = Color("315d8a")
			s.shadow_color = Color(0.01, 0.06, 0.12, 0.26)
			s.shadow_size = 2
			s.shadow_offset = Vector2(0, 2)
			if special != 0:
				s.bg_color = Color("28517d")
				s.set_border_width_all(3)
				s.border_color = Color("ffd76f")
				s.shadow_color = Color(1.0, 0.68, 0.16, 0.38)
				s.shadow_size = 7
			b.add_theme_stylebox_override("normal", s)
			var hover: StyleBoxFlat = s.duplicate()
			hover.bg_color = s.bg_color.lightened(0.05)
			b.add_theme_stylebox_override("hover", hover)
			var pressed: StyleBoxFlat = s.duplicate()
			pressed.bg_color = s.bg_color.darkened(0.08)
			b.add_theme_stylebox_override("pressed", pressed)
			b.expand_icon = true
			b.icon = piece_textures[t] if special == 0 else special_textures.get(special, piece_textures[t])
			b.text = ""
