extends Node

const SAVE_PATH := "user://mutant_match_progress.cfg"

var game: Control
var overlay: Control
var highest_unlocked: int = 1
var completed_levels: Dictionary = {}

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	for i in range(8):
		await get_tree().process_frame
	game = get_tree().current_scene as Control
	load_progress()
	show_map()

func load_progress() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err == OK:
		highest_unlocked = clampi(int(cfg.get_value("progress", "highest_unlocked", 1)), 1, 20)
		var saved_completed: Array = cfg.get_value("progress", "completed", [])
		for value in saved_completed:
			completed_levels[int(value)] = true

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "highest_unlocked", highest_unlocked)
	var completed: Array = completed_levels.keys()
	completed.sort()
	cfg.set_value("progress", "completed", completed)
	cfg.save(SAVE_PATH)

func complete_level(level_index: int) -> void:
	var level_number := level_index + 1
	completed_levels[level_number] = true
	highest_unlocked = maxi(highest_unlocked, mini(20, level_number + 1))
	save_progress()

func show_map() -> void:
	if game == null:
		game = get_tree().current_scene as Control
	if game == null:
		return
	close_map()

	overlay = Control.new()
	overlay.name = "LevelMap"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	game.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.10, 0.18, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var card := PanelContainer.new()
	card.position = Vector2(45, 55)
	card.size = Vector2(630, 850)
	card.add_theme_stylebox_override("panel", make_panel())
	overlay.add_child(card)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	card.add_child(box)

	var title := Label.new()
	title.text = "КАРТА УРОВНЕЙ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("fff1bd"))
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Пройди все 20 уровней"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color("d9efff"))
	box.add_child(subtitle)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)

	for i in range(20):
		var number := i + 1
		var button := Button.new()
		button.custom_minimum_size = Vector2(132, 104)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 21)
		if number > highest_unlocked:
			button.text = "%d\nЗАКРЫТ" % number
			button.disabled = true
			button.add_theme_stylebox_override("disabled", make_level_style(Color("4b5870"), Color("6e7890")))
		elif completed_levels.has(number):
			button.text = "%d\nПРОЙДЕН" % number
			button.add_theme_stylebox_override("normal", make_level_style(Color("2c9b67"), Color("ffe07a")))
		else:
			button.text = "%d\nИГРАТЬ" % number
			button.add_theme_stylebox_override("normal", make_level_style(Color("1687dc"), Color("f6c96e")))
		if not button.disabled:
			button.pressed.connect(select_level.bind(i))
		grid.add_child(button)

	var hint := Label.new()
	hint.text = "Новые уровни открываются после победы"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 17)
	hint.add_theme_color_override("font_color", Color("b9d5ff"))
	box.add_child(hint)

func select_level(index: int) -> void:
	var levels = get_node_or_null("/root/Levels")
	if levels == null:
		return
	close_map()
	levels.start_level(index)

func close_map() -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null

func make_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("174f7d")
	s.corner_radius_top_left = 36
	s.corner_radius_top_right = 36
	s.corner_radius_bottom_left = 36
	s.corner_radius_bottom_right = 36
	s.set_border_width_all(5)
	s.border_color = Color("f0c76e")
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 18
	s.shadow_offset = Vector2(0, 8)
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 24
	s.content_margin_bottom = 24
	return s

func make_level_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 22
	s.corner_radius_top_right = 22
	s.corner_radius_bottom_left = 22
	s.corner_radius_bottom_right = 22
	s.set_border_width_all(3)
	s.border_color = border
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 7
	s.shadow_offset = Vector2(0, 4)
	return s
