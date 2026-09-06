extends Node

var game: Control
var score_value: Label
var target_value: Label
var booster_counts := [3, 3, 3, 3]
var booster_buttons: Array[Button] = []
var paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("setup")

func setup() -> void:
	for i in range(6):
		await get_tree().process_frame
	game = get_tree().current_scene as Control
	if game == null:
		return
	build_real_goal_panel()
	build_working_boosters()

func build_real_goal_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "RealGoalPanel"
	panel.position = Vector2(16, 18)
	panel.size = Vector2(254, 142)
	panel.z_index = 60
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", make_panel(Color("f9e7be"), Color("b7773d"), 26, 9))
	game.add_child(panel)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Цель уровня"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color("663419"))
	box.add_child(title)

	score_value = Label.new()
	score_value.text = "0"
	score_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_value.add_theme_font_size_override("font_size", 32)
	score_value.add_theme_color_override("font_color", Color("1687dc"))
	box.add_child(score_value)

	target_value = Label.new()
	target_value.text = "из 0 очков"
	target_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_value.add_theme_font_size_override("font_size", 17)
	target_value.add_theme_color_override("font_color", Color("683619"))
	box.add_child(target_value)

func build_working_boosters() -> void:
	var bar := PanelContainer.new()
	bar.name = "WorkingBoosters"
	bar.position = Vector2(72, 850)
	bar.size = Vector2(576, 92)
	bar.z_index = 70
	bar.add_theme_stylebox_override("panel", make_panel(Color("906039"), Color("dcb376"), 34, 11))
	game.add_child(bar)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)

	add_booster_button(row, "💣", 0, "Бомба")
	add_booster_button(row, "↔", 1, "Ракета")
	add_booster_button(row, "◎", 2, "Ядро")
	add_booster_button(row, "✹", 3, "Взрыв")

	var pause := Button.new()
	pause.text = "Ⅱ"
	pause.tooltip_text = "Пауза"
	pause.custom_minimum_size = Vector2(72, 72)
	pause.focus_mode = Control.FOCUS_NONE
	pause.add_theme_font_size_override("font_size", 30)
	pause.add_theme_color_override("font_color", Color.WHITE)
	pause.add_theme_stylebox_override("normal", make_panel(Color("1687dc"), Color("f6c96e"), 32, 4))
	pause.pressed.connect(toggle_pause.bind(pause))
	row.add_child(pause)

func add_booster_button(parent: HBoxContainer, icon: String, index: int, tip: String) -> void:
	var b := Button.new()
	b.text = "%s\n%d" % [icon, booster_counts[index]]
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(84, 72)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", make_panel(Color("1687dc"), Color("f6c96e"), 28, 4))
	b.pressed.connect(use_booster.bind(index))
	parent.add_child(b)
	booster_buttons.append(b)

func use_booster(index: int) -> void:
	if game == null or paused:
		return
	if index < 0 or index >= booster_counts.size() or booster_counts[index] <= 0:
		return
	if bool(game.get("busy")):
		return
	booster_counts[index] -= 1
	update_booster_text(index)

	var x := randi_range(0, int(game.get("COLS")) - 1) if game.get("COLS") != null else randi_range(0, 7)
	var y := randi_range(0, int(game.get("ROWS")) - 1) if game.get("ROWS") != null else randi_range(0, 7)
	var pos := Vector2i(x, y)

	if index == 0:
		game.specials[y][x] = 3
		game.status_label.text = "Бустер: бомба готова!"
		game.call("refresh_board")
	elif index == 1:
		game.specials[y][x] = 1 if randi() % 2 == 0 else 2
		game.status_label.text = "Бустер: ракета готова!"
		game.call("refresh_board")
	elif index == 2:
		game.specials[y][x] = 4
		game.status_label.text = "Бустер: энерго-ядро готово!"
		game.call("refresh_board")
	else:
		await instant_blast(pos)

func instant_blast(center: Vector2i) -> void:
	game.set("busy", true)
	var blast: Dictionary = {}
	for yy in range(maxi(0, center.y - 1), mini(8, center.y + 2)):
		for xx in range(maxi(0, center.x - 1), mini(8, center.x + 2)):
			blast[Vector2i(xx, yy)] = true
	await game.call("resolve_blast", blast, 1)
	game.call("update_hud")
	game.status_label.text = "Бустер: мгновенный взрыв!"
	game.set("busy", false)

func update_booster_text(index: int) -> void:
	var icons := ["💣", "↔", "◎", "✹"]
	if index < booster_buttons.size():
		booster_buttons[index].text = "%s\n%d" % [icons[index], booster_counts[index]]
		booster_buttons[index].disabled = booster_counts[index] <= 0

func toggle_pause(button: Button) -> void:
	paused = not paused
	get_tree().paused = paused
	button.text = "▶" if paused else "Ⅱ"

func _process(_delta: float) -> void:
	if game == null or score_value == null or target_value == null:
		return
	var score := int(game.get("score"))
	var target := int(game.get("target"))
	score_value.text = "%d / %d" % [score, target]
	target_value.text = "Набери нужные очки"

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
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s
