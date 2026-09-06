extends Node

var current_language := "ru"
var button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("setup")

func setup() -> void:
	for i in range(12):
		await get_tree().process_frame
	add_toggle_button()
	apply_language()

func add_toggle_button() -> void:
	var game := get_tree().current_scene as Control
	if game == null:
		return
	var start_screen = game.get_node_or_null("StartScreen")
	if start_screen == null:
		return
	button = Button.new()
	button.name = "LanguageToggle"
	button.text = "EN"
	button.position = Vector2(610, 22)
	button.size = Vector2(88, 50)
	button.z_index = 500
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", make_style(Color("175f9f"), Color("f2c76b")))
	button.add_theme_stylebox_override("hover", make_style(Color("2076bc"), Color("fff0a0")))
	button.pressed.connect(toggle_language)
	start_screen.add_child(button)

func toggle_language() -> void:
	current_language = "en" if current_language == "ru" else "ru"
	apply_language()

func apply_language() -> void:
	var game := get_tree().current_scene as Control
	if game == null:
		return
	var start_screen = game.get_node_or_null("StartScreen")
	if start_screen == null:
		return
	for node in all_children(start_screen):
		if node is Label:
			if current_language == "en":
				if node.text == "МУТАНТЫ • КОМБО • ВЗРЫВЫ":
					node.text = "MUTANTS • COMBOS • BLASTS"
				elif node.text.begins_with("Собирай фишки"):
					node.text = "Match pieces, break crates\nand create powerful boosters!"
				elif node.text == "50 УРОВНЕЙ  •  КОРОБКИ  •  КОМБО":
					node.text = "50 LEVELS  •  CRATES  •  COMBOS"
			else:
				if node.text == "MUTANTS • COMBOS • BLASTS":
					node.text = "МУТАНТЫ • КОМБО • ВЗРЫВЫ"
				elif node.text.begins_with("Match pieces"):
					node.text = "Собирай фишки, ломай коробки\nи создавай мощные бустеры!"
				elif node.text == "50 LEVELS  •  CRATES  •  COMBOS":
					node.text = "50 УРОВНЕЙ  •  КОРОБКИ  •  КОМБО"
		elif node is Button and node.name != "LanguageToggle":
			if current_language == "en" and node.text == "ИГРАТЬ":
				node.text = "PLAY"
			elif current_language == "ru" and node.text == "PLAY":
				node.text = "ИГРАТЬ"
	if button != null:
		button.text = "RU" if current_language == "en" else "EN"

func all_children(node: Node) -> Array:
	var out: Array = []
	for child in node.get_children():
		out.append(child)
		out.append_array(all_children(child))
	return out

func make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = 18
	s.corner_radius_top_right = 18
	s.corner_radius_bottom_left = 18
	s.corner_radius_bottom_right = 18
	s.set_border_width_all(3)
	s.border_color = border
	s.shadow_color = Color(0, 0, 0, 0.28)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 3)
	return s
