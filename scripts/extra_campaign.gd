extends Node

const SAVE_PATH := "user://mutant_match_extra_progress.cfg"
const DATA_PATH := "res://data/extra_levels.json"

var game: Control
var levels: Array = []
var unlocked: int = 1
var active := false
var current := 0
var finished := false
var chapter_overlay: Control
var result_overlay: Control
var map_button_added := false
var map_overlay_id: int = 0

func _ready() -> void:
	call_deferred("setup")

func setup() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file != null:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Array:
			levels = parsed
	load_progress()
	for i in range(8):
		await get_tree().process_frame
	game = get_tree().current_scene as Control

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		unlocked = clampi(int(cfg.get_value("progress", "unlocked", 1)), 1, 20)

func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.save(SAVE_PATH)

func _process(_delta: float) -> void:
	if game == null:
		game = get_tree().current_scene as Control
		if game == null:
			return
	update_main_map()
	if not active or finished:
		return
	var crates_left := 0
	var crates = get_node_or_null("/root/Crates")
	if crates != null:
		crates_left = int(crates.remaining)
	if int(game.get("score")) >= int(game.get("target")) and crates_left <= 0:
		finished = true
		game.set("busy", true)
		if current + 1 < 20:
			unlocked = maxi(unlocked, current + 2)
			save_progress()
		var economy = get_node_or_null("/root/Economy")
		if economy != null:
			economy.call("reward_for_level", current + 31)
		show_result(true)
	elif int(game.get("moves")) <= 0:
		finished = true
		game.set("busy", true)
		show_result(false)

func update_main_map() -> void:
	var level_map = get_node_or_null("/root/LevelMap")
	if level_map == null:
		return
	var overlay = level_map.get("overlay")
	if overlay == null or not is_instance_valid(overlay):
		map_button_added = false
		map_overlay_id = 0
		return

	var current_overlay_id := int(overlay.get_instance_id())
	if current_overlay_id != map_overlay_id:
		map_overlay_id = current_overlay_id
		map_button_added = false

	for node in all_children(overlay):
		if node is Label and "30 уровней" in node.text:
			node.text = "50 уровней • монеты • магазин • новая глава"

	var existing = overlay.get_node_or_null("ExtraLevelsButton")
	if existing != null:
		map_button_added = true
		return
	if map_button_added:
		return

	var button := Button.new()
	button.name = "ExtraLevelsButton"
	button.text = "НОВАЯ ГЛАВА 31–50"
	button.position = Vector2(205, 856)
	button.size = Vector2(310, 60)
	button.z_index = 50
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_stylebox_override("normal", make_button_style(Color("d97b32"), Color("ffe07a")))
	button.add_theme_stylebox_override("hover", make_button_style(Color("ee9343"), Color("fff0aa")))
	button.add_theme_stylebox_override("pressed", make_button_style(Color("bf6429"), Color.WHITE))
	button.pressed.connect(show_chapter)
	overlay.add_child(button)
	map_button_added = true

func all_children(node: Node) -> Array:
	var out: Array = []
	for child in node.get_children():
		out.append(child)
		out.append_array(all_children(child))
	return out

func show_chapter() -> void:
	close_chapter()
	chapter_overlay = Control.new()
	chapter_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chapter_overlay.z_index = 310
	game.add_child(chapter_overlay)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/tropical_bg.svg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chapter_overlay.add_child(bg)
	var wash := ColorRect.new()
	wash.color = Color(0.02, 0.12, 0.24, 0.55)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chapter_overlay.add_child(wash)
	var panel := PanelContainer.new()
	panel.position = Vector2(55, 70)
	panel.size = Vector2(610, 820)
	panel.add_theme_stylebox_override("panel", make_card())
	chapter_overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := Label.new()
	title.text = "НОВАЯ ГЛАВА • УРОВНИ 31–50"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("fff2c7"))
	box.add_child(title)
	var sub := Label.new()
	sub.text = "Умеренная сложность • больше монет за победы"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(sub)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	for i in range(20):
		var b := Button.new()
		b.custom_minimum_size = Vector2(125, 92)
		b.add_theme_font_size_override("font_size", 18)
		if i + 1 > unlocked:
			b.text = "%d\nЗАКРЫТ" % (i + 31)
			b.disabled = true
			b.add_theme_stylebox_override("disabled", make_button_style(Color("4b5870"), Color("6e7890")))
		else:
			b.text = "%d\nИГРАТЬ" % (i + 31)
			b.add_theme_stylebox_override("normal", make_button_style(Color("d97b32"), Color("ffe07a")))
			b.add_theme_stylebox_override("hover", make_button_style(Color("ee9343"), Color("fff0aa")))
			b.pressed.connect(start_extra_level.bind(i))
		grid.add_child(b)
	var back := Button.new()
	back.text = "НАЗАД К КАРТЕ"
	back.custom_minimum_size = Vector2(280, 58)
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(close_chapter)
	box.add_child(back)

func start_extra_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		return
	close_chapter()
	var level_map = get_node_or_null("/root/LevelMap")
	if level_map != null:
		level_map.call("close_map")
	var base_levels = get_node_or_null("/root/Levels")
	if base_levels != null:
		base_levels.set("finished", true)
	current = index
	active = true
	finished = false
	game.call("new_game")
	await get_tree().process_frame
	var data: Dictionary = levels[current]
	game.set("moves", int(data["moves"]))
	game.set("target", int(data["target"]))
	game.set("score", 0)
	game.set("busy", false)
	game.call("update_hud")
	var crates = get_node_or_null("/root/Crates")
	if crates != null:
		await crates.reset_for_level(int(data["crates"]))
	var info = base_levels.get("info_label") if base_levels != null else null
	if info != null:
		info.text = "УРОВЕНЬ %d  •  %d ОЧКОВ  •  КОРОБКИ %d" % [current + 31, int(data["target"]), int(data["crates"])]

func get_coins() -> int:
	var economy = get_node_or_null("/root/Economy")
	if economy == null:
		return 0
	return int(economy.get("coins"))

func show_result(win: bool) -> void:
	close_result()
	result_overlay = Control.new()
	result_overlay.name = "ExtraLevelResult"
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.z_index = 330
	game.add_child(result_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.08, 0.16, 0.74)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.add_child(dim)

	var card := PanelContainer.new()
	card.position = Vector2(95, 205)
	card.size = Vector2(530, 535)
	card.add_theme_stylebox_override("panel", make_card())
	result_overlay.add_child(card)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 11)
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
	score_label.add_theme_font_size_override("font_size", 21)
	score_label.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(score_label)

	var coins_label := Label.new()
	coins_label.text = "МОНЕТЫ: %d" % get_coins()
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins_label.add_theme_font_size_override("font_size", 22)
	coins_label.add_theme_color_override("font_color", Color("ffe05d"))
	box.add_child(coins_label)

	var next := Button.new()
	next.text = "СЛЕДУЮЩИЙ УРОВЕНЬ" if win and current < 19 else ("К НОВОЙ ГЛАВЕ" if win else "ПОВТОРИТЬ")
	next.custom_minimum_size = Vector2(330, 58)
	next.add_theme_font_size_override("font_size", 22)
	next.pressed.connect(next_extra if win else retry_extra)
	box.add_child(next)

	var chapter := Button.new()
	chapter.text = "УРОВНИ 31–50"
	chapter.custom_minimum_size = Vector2(330, 56)
	chapter.add_theme_font_size_override("font_size", 21)
	chapter.pressed.connect(back_to_chapter)
	box.add_child(chapter)

	var shop := Button.new()
	shop.text = "МАГАЗИН"
	shop.custom_minimum_size = Vector2(330, 56)
	shop.add_theme_font_size_override("font_size", 21)
	shop.pressed.connect(open_shop)
	box.add_child(shop)

	var main_map := Button.new()
	main_map.text = "К КАРТЕ УРОВНЕЙ"
	main_map.custom_minimum_size = Vector2(330, 56)
	main_map.add_theme_font_size_override("font_size", 20)
	main_map.pressed.connect(open_main_map)
	box.add_child(main_map)

	if win:
		var stars := Label.new()
		stars.text = "★ ★ ★"
		stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars.add_theme_font_size_override("font_size", 35)
		stars.add_theme_color_override("font_color", Color("ffd84f"))
		box.add_child(stars)

func next_extra() -> void:
	close_result()
	if current < 19:
		start_extra_level(current + 1)
	else:
		show_chapter()

func retry_extra() -> void:
	close_result()
	start_extra_level(current)

func back_to_chapter() -> void:
	close_result()
	active = false
	show_chapter()

func open_shop() -> void:
	close_result()
	active = false
	var base_levels = get_node_or_null("/root/Levels")
	if base_levels != null:
		base_levels.set("finished", true)
	var level_map = get_node_or_null("/root/LevelMap")
	if level_map != null:
		level_map.show_map()
		level_map.show_shop()

func open_main_map() -> void:
	close_result()
	active = false
	var level_map = get_node_or_null("/root/LevelMap")
	if level_map != null:
		level_map.show_map()

func close_chapter() -> void:
	if chapter_overlay != null and is_instance_valid(chapter_overlay):
		chapter_overlay.queue_free()
	chapter_overlay = null

func close_result() -> void:
	if result_overlay != null and is_instance_valid(result_overlay):
		result_overlay.queue_free()
	result_overlay = null

func make_card() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("175f9f")
	s.corner_radius_top_left = 34
	s.corner_radius_top_right = 34
	s.corner_radius_bottom_left = 34
	s.corner_radius_bottom_right = 34
	s.set_border_width_all(5)
	s.border_color = Color("f2c76b")
	s.shadow_color = Color(0, 0, 0, 0.50)
	s.shadow_size = 20
	s.shadow_offset = Vector2(0, 10)
	s.content_margin_left = 30
	s.content_margin_right = 30
	s.content_margin_top = 24
	s.content_margin_bottom = 24
	return s

func make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 20
	s.corner_radius_top_right = 20
	s.corner_radius_bottom_left = 20
	s.corner_radius_bottom_right = 20
	s.set_border_width_all(3)
	s.border_color = border
	s.shadow_color = Color(0, 0, 0, 0.30)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 3)
	return s
