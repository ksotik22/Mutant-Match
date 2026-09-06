extends Node

const LEVELS := [
	{"moves": 27, "target": 1800, "crates": 2},
	{"moves": 27, "target": 2200, "crates": 3},
	{"moves": 26, "target": 2600, "crates": 4},
	{"moves": 26, "target": 3000, "crates": 5},
	{"moves": 25, "target": 3400, "crates": 6},
	{"moves": 25, "target": 3900, "crates": 7},
	{"moves": 24, "target": 4400, "crates": 8},
	{"moves": 23, "target": 4900, "crates": 9},
	{"moves": 22, "target": 5500, "crates": 10},
	{"moves": 21, "target": 6200, "crates": 12},

	# 11-17: difficulty reset so the next chapter feels fresh and fair.
	{"moves": 28, "target": 2600, "crates": 4},
	{"moves": 28, "target": 2900, "crates": 5},
	{"moves": 27, "target": 3200, "crates": 5},
	{"moves": 27, "target": 3500, "crates": 6},
	{"moves": 26, "target": 3900, "crates": 7},
	{"moves": 26, "target": 4300, "crates": 8},
	{"moves": 25, "target": 4700, "crates": 9},

	# 18-20: final ramp-up.
	{"moves": 24, "target": 5600, "crates": 11},
	{"moves": 23, "target": 6500, "crates": 13},
	{"moves": 22, "target": 7600, "crates": 15}
]

var game: Control
var current_level := 0
var finished := false
var info_label: Label
var result_layer: Control

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	for i in range(4):
		await get_tree().process_frame
	game = get_tree().current_scene as Control
	if game == null:
		return
	build_level_label()
	start_level(current_level)

func build_level_label() -> void:
	info_label = Label.new()
	info_label.name = "LevelInfo"
	info_label.position = Vector2(165, 158)
	info_label.size = Vector2(390, 34)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 19)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	info_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.15, 0.25, 0.8))
	info_label.add_theme_constant_override("shadow_offset_x", 2)
	info_label.add_theme_constant_override("shadow_offset_y", 2)
	info_label.z_index = 45
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(info_label)

func start_level(index: int) -> void:
	if game == null:
		return
	current_level = clampi(index, 0, LEVELS.size() - 1)
	finished = false
	close_result()

	game.call("new_game")
	await get_tree().process_frame

	var data: Dictionary = LEVELS[current_level]
	game.set("moves", int(data["moves"]))
	game.set("target", int(data["target"]))
	game.set("score", 0)
	game.set("busy", false)
	game.call("update_hud")

	var crates = get_node_or_null("/root/Crates")
	if crates != null:
		await crates.reset_for_level(int(data["crates"]))

	info_label.text = "УРОВЕНЬ %d  •  %d ОЧКОВ  •  КОРОБКИ %d" % [current_level + 1, int(data["target"]), int(data["crates"])]

func _process(_delta: float) -> void:
	if game == null or finished:
		return
	var score := int(game.get("score"))
	var target := int(game.get("target"))
	var moves := int(game.get("moves"))
	var crates_left := 0
	var crates = get_node_or_null("/root/Crates")
	if crates != null:
		crates_left = int(crates.remaining)
	if score >= target and crates_left <= 0:
		finished = true
		game.set("busy", true)
		show_result(true)
	elif moves <= 0:
		finished = true
		game.set("busy", true)
		show_result(false)

func show_result(win: bool) -> void:
	close_result()
	result_layer = Control.new()
	result_layer.name = "LevelResult"
	result_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_layer.z_index = 100
	game.add_child(result_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.08, 0.16, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_layer.add_child(dim)

	var card := PanelContainer.new()
	card.position = Vector2(95, 285)
	card.size = Vector2(530, 350)
	card.add_theme_stylebox_override("panel", make_card())
	result_layer.add_child(card)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	card.add_child(box)

	var title := Label.new()
	title.text = "УРОВЕНЬ ПРОЙДЕН!" if win else "ХОДЫ ЗАКОНЧИЛИСЬ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("fff2c7"))
	box.add_child(title)

	var crates_left := 0
	var crates = get_node_or_null("/root/Crates")
	if crates != null:
		crates_left = int(crates.remaining)
	var score_label := Label.new()
	score_label.text = "Очки: %d / %d   •   Коробки: %d" % [int(game.get("score")), int(game.get("target")), crates_left]
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(score_label)

	var button := Button.new()
	button.custom_minimum_size = Vector2(310, 70)
	button.add_theme_font_size_override("font_size", 25)
	if win and current_level < LEVELS.size() - 1:
		button.text = "СЛЕДУЮЩИЙ УРОВЕНЬ"
		button.pressed.connect(next_level)
	elif win:
		button.text = "ИГРАТЬ ЕЩЁ РАЗ"
		button.pressed.connect(restart_level)
	else:
		button.text = "ПОВТОРИТЬ"
		button.pressed.connect(restart_level)
	box.add_child(button)

	if win:
		var stars := Label.new()
		stars.text = "★ ★ ★"
		stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars.add_theme_font_size_override("font_size", 42)
		stars.add_theme_color_override("font_color", Color("ffd84f"))
		box.add_child(stars)

func next_level() -> void:
	if current_level < LEVELS.size() - 1:
		start_level(current_level + 1)
	else:
		start_level(0)

func restart_level() -> void:
	start_level(current_level)

func close_result() -> void:
	if result_layer != null and is_instance_valid(result_layer):
		result_layer.queue_free()
	result_layer = null

func make_card() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("175f9f")
	s.corner_radius_top_left = 34
	s.corner_radius_top_right = 34
	s.corner_radius_bottom_left = 34
	s.corner_radius_bottom_right = 34
	s.set_border_width_all(5)
	s.border_color = Color("f2c76b")
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 20
	s.shadow_offset = Vector2(0, 10)
	s.content_margin_left = 30
	s.content_margin_right = 30
	s.content_margin_top = 28
	s.content_margin_bottom = 28
	return s
