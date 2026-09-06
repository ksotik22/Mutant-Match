extends Node

const SAVE_PATH := "user://mutant_match_progress.cfg"
const TOTAL_LEVELS := 30
const SHOP_PRICES := [120, 100, 180, 150]
const SHOP_NAMES := ["Бомба", "Ракета", "Энерго-ядро", "Взрыв 3×3"]
const SHOP_ICONS := [
	"res://assets/pieces/bomb.svg",
	"res://assets/pieces/rocket_h.svg",
	"res://assets/pieces/core.svg",
	"res://assets/pieces/rocket_v.svg"
]

var game: Control
var overlay: Control
var shop_overlay: Control
var highest_unlocked: int = 1
var completed_levels: Dictionary = {}
var last_reward: int = 0

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
		highest_unlocked = clampi(int(cfg.get_value("progress", "highest_unlocked", 1)), 1, TOTAL_LEVELS)
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
	highest_unlocked = maxi(highest_unlocked, mini(TOTAL_LEVELS, level_number + 1))
	var economy = get_node_or_null("/root/Economy")
	if economy != null:
		last_reward = int(economy.call("reward_for_level", level_number))
	save_progress()

func get_coins() -> int:
	var economy = get_node_or_null("/root/Economy")
	if economy == null:
		return 0
	return int(economy.get("coins"))

func get_booster_count(index: int) -> int:
	var economy = get_node_or_null("/root/Economy")
	if economy == null:
		return 0
	return int(economy.call("get_booster_count", index))

func show_map() -> void:
	if game == null:
		game = get_tree().current_scene as Control
	if game == null:
		return
	close_shop()
	close_map()

	overlay = Control.new()
	overlay.name = "LevelMap"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 200
	game.add_child(overlay)

	var bg := TextureRect.new()
	bg.texture = load("res://assets/ui/tropical_bg.svg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)

	var wash := ColorRect.new()
	wash.color = Color(0.02, 0.19, 0.30, 0.34)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(wash)

	for data in [
		[Vector2(40, 120), Vector2(180, 180), Color(0.20, 0.86, 0.92, 0.18)],
		[Vector2(535, 185), Vector2(155, 155), Color(1.00, 0.84, 0.32, 0.14)],
		[Vector2(25, 705), Vector2(210, 210), Color(0.44, 0.88, 0.42, 0.15)],
		[Vector2(555, 735), Vector2(150, 150), Color(0.82, 0.48, 0.95, 0.13)]
	]:
		var deco := Panel.new()
		deco.position = data[0]
		deco.size = data[1]
		deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
		deco.add_theme_stylebox_override("panel", make_blob_style(data[2]))
		overlay.add_child(deco)

	var card := PanelContainer.new()
	card.position = Vector2(35, 35)
	card.size = Vector2(650, 890)
	card.add_theme_stylebox_override("panel", make_panel())
	overlay.add_child(card)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 9)
	card.add_child(box)

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 14)
	box.add_child(top)

	var title := Label.new()
	title.text = "КАРТА УРОВНЕЙ"
	title.custom_minimum_size = Vector2(330, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("fff1bd"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0.12, 0.20, 0.75))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	top.add_child(title)

	var coins := Label.new()
	coins.text = "МОНЕТЫ: %d" % get_coins()
	coins.custom_minimum_size = Vector2(150, 48)
	coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coins.add_theme_font_size_override("font_size", 18)
	coins.add_theme_color_override("font_color", Color("ffe05d"))
	top.add_child(coins)

	var shop_button := Button.new()
	shop_button.text = "МАГАЗИН"
	shop_button.custom_minimum_size = Vector2(130, 48)
	shop_button.focus_mode = Control.FOCUS_NONE
	shop_button.add_theme_font_size_override("font_size", 17)
	shop_button.add_theme_stylebox_override("normal", make_level_style(Color("d98527"), Color("ffe07a")))
	shop_button.pressed.connect(show_shop)
	top.add_child(shop_button)

	var subtitle := Label.new()
	subtitle.text = "30 уровней • за победы получай монеты • покупай бустеры"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("d9efff"))
	box.add_child(subtitle)

	var progress := Label.new()
	progress.text = "Открыто: %d / %d" % [highest_unlocked, TOTAL_LEVELS]
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.add_theme_font_size_override("font_size", 16)
	progress.add_theme_color_override("font_color", Color("ffe28a"))
	box.add_child(progress)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 9)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)

	for i in range(TOTAL_LEVELS):
		var number := i + 1
		var button := Button.new()
		button.custom_minimum_size = Vector2(108, 88)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 18)
		if number > highest_unlocked:
			button.text = "%d\n🔒" % number
			button.disabled = true
			button.add_theme_stylebox_override("disabled", make_level_style(Color("46576a"), Color("728197")))
		elif completed_levels.has(number):
			button.text = "%d\n✓" % number
			button.add_theme_stylebox_override("normal", make_level_style(chapter_color(number, true), Color("ffe07a")))
		else:
			button.text = "%d\nИГРАТЬ" % number
			button.add_theme_stylebox_override("normal", make_level_style(chapter_color(number, false), Color("f6c96e")))
		button.add_theme_stylebox_override("hover", make_level_style(chapter_color(number, false).lightened(0.12), Color("fff0aa")))
		button.add_theme_stylebox_override("pressed", make_level_style(chapter_color(number, false).darkened(0.08), Color.WHITE))
		if not button.disabled:
			button.pressed.connect(select_level.bind(i))
		grid.add_child(button)

	var legend := Label.new()
	legend.text = "1–10 ТРОПИКИ   •   11–19 ХАОС   •   20–30 НОВЫЙ ОСТРОВ"
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.add_theme_font_size_override("font_size", 14)
	legend.add_theme_color_override("font_color", Color("c9eaff"))
	box.add_child(legend)

func show_shop() -> void:
	if game == null:
		return
	close_shop()
	shop_overlay = Control.new()
	shop_overlay.name = "ShopOverlay"
	shop_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_overlay.z_index = 260
	game.add_child(shop_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.08, 0.14, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_overlay.add_child(dim)

	var card := PanelContainer.new()
	card.position = Vector2(70, 120)
	card.size = Vector2(580, 720)
	card.add_theme_stylebox_override("panel", make_shop_panel())
	shop_overlay.add_child(card)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	card.add_child(box)

	var title := Label.new()
	title.text = "МАГАЗИН УЛУЧШЕНИЙ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 31)
	title.add_theme_color_override("font_color", Color("fff1bd"))
	box.add_child(title)

	var money := Label.new()
	money.text = "Монеты: %d" % get_coins()
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	money.add_theme_font_size_override("font_size", 24)
	money.add_theme_color_override("font_color", Color("ffe05d"))
	box.add_child(money)

	var info := Label.new()
	info.text = "За каждую победу ты получаешь монеты.\nПокупай бустеры и используй их на сложных уровнях."
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 17)
	info.add_theme_color_override("font_color", Color.WHITE)
	box.add_child(info)

	for i in range(4):
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 12)
		box.add_child(row)

		var icon := TextureRect.new()
		icon.texture = load(SHOP_ICONS[i])
		icon.custom_minimum_size = Vector2(70, 70)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)

		var name := Label.new()
		name.text = "%s\nВ запасе: %d" % [SHOP_NAMES[i], get_booster_count(i)]
		name.custom_minimum_size = Vector2(220, 70)
		name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name.add_theme_font_size_override("font_size", 18)
		name.add_theme_color_override("font_color", Color.WHITE)
		row.add_child(name)

		var buy := Button.new()
		buy.text = "КУПИТЬ\n%d" % SHOP_PRICES[i]
		buy.custom_minimum_size = Vector2(150, 70)
		buy.focus_mode = Control.FOCUS_NONE
		buy.add_theme_font_size_override("font_size", 17)
		buy.add_theme_stylebox_override("normal", make_level_style(Color("2d9c67"), Color("ffe07a")))
		buy.disabled = get_coins() < SHOP_PRICES[i]
		buy.pressed.connect(buy_booster.bind(i))
		row.add_child(buy)

	var close := Button.new()
	close.text = "НАЗАД К КАРТЕ"
	close.custom_minimum_size = Vector2(300, 62)
	close.focus_mode = Control.FOCUS_NONE
	close.add_theme_font_size_override("font_size", 21)
	close.pressed.connect(close_shop)
	box.add_child(close)

func buy_booster(index: int) -> void:
	var economy = get_node_or_null("/root/Economy")
	if economy == null:
		return
	if bool(economy.call("buy_booster", index, SHOP_PRICES[index], 1)):
		var ui = get_node_or_null("/root/GameplayUIFix")
		if ui != null:
			ui.call("refresh_all_boosters")
		show_shop()

func chapter_color(number: int, completed: bool) -> Color:
	if completed:
		if number <= 10:
			return Color("2c9b67")
		if number <= 19:
			return Color("7b63c6")
		return Color("d27a39")
	if number <= 10:
		return Color("1687dc")
	if number <= 19:
		return Color("8558c9")
	return Color("e18b37")

func select_level(index: int) -> void:
	var levels = get_node_or_null("/root/Levels")
	if levels == null:
		return
	close_shop()
	close_map()
	levels.start_level(index)

func close_map() -> void:
	if overlay != null and is_instance_valid(overlay):
		overlay.queue_free()
	overlay = null

func close_shop() -> void:
	if shop_overlay != null and is_instance_valid(shop_overlay):
		shop_overlay.queue_free()
	shop_overlay = null

func make_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.055, 0.28, 0.43, 0.93)
	s.corner_radius_top_left = 38
	s.corner_radius_top_right = 38
	s.corner_radius_bottom_left = 38
	s.corner_radius_bottom_right = 38
	s.set_border_width_all(5)
	s.border_color = Color("f0c76e")
	s.shadow_color = Color(0, 0, 0, 0.48)
	s.shadow_size = 20
	s.shadow_offset = Vector2(0, 9)
	s.content_margin_left = 26
	s.content_margin_right = 26
	s.content_margin_top = 20
	s.content_margin_bottom = 18
	return s

func make_shop_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.07, 0.31, 0.43, 0.98)
	s.corner_radius_top_left = 40
	s.corner_radius_top_right = 40
	s.corner_radius_bottom_left = 40
	s.corner_radius_bottom_right = 40
	s.set_border_width_all(5)
	s.border_color = Color("f6c96e")
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_size = 24
	s.shadow_offset = Vector2(0, 10)
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 26
	s.content_margin_bottom = 26
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
	s.shadow_color = Color(0, 0, 0, 0.34)
	s.shadow_size = 7
	s.shadow_offset = Vector2(0, 4)
	return s

func make_blob_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 90
	s.corner_radius_top_right = 90
	s.corner_radius_bottom_left = 90
	s.corner_radius_bottom_right = 90
	return s
