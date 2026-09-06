extends Node

var current_language := "ru"
var button: Button
var game: Control
var refresh_timer := 0.0
var language_layer: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("setup")

func setup() -> void:
	for i in range(12):
		await get_tree().process_frame
	game = get_tree().current_scene as Control
	if game == null:
		return
	add_toggle_button()
	apply_language()

func add_toggle_button() -> void:
	if game == null:
		return
	if language_layer != null and is_instance_valid(language_layer):
		language_layer.queue_free()
	language_layer = CanvasLayer.new()
	language_layer.name = "LanguageLayer"
	language_layer.layer = 100
	game.add_child(language_layer)

	button = Button.new()
	button.name = "LanguageToggle"
	button.text = "EN"
	button.position = Vector2(620, 18)
	button.size = Vector2(78, 48)
	button.focus_mode = Control.FOCUS_NONE
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", make_style(Color("175f9f"), Color("f2c76b")))
	button.add_theme_stylebox_override("hover", make_style(Color("2076bc"), Color("fff0a0")))
	button.add_theme_stylebox_override("pressed", make_style(Color("0f4d85"), Color.WHITE))
	button.pressed.connect(toggle_language)
	language_layer.add_child(button)

func toggle_language() -> void:
	current_language = "en" if current_language == "ru" else "ru"
	apply_language()

func _process(delta: float) -> void:
	refresh_timer += delta
	if refresh_timer < 0.15:
		return
	refresh_timer = 0.0
	if game == null:
		game = get_tree().current_scene as Control
	if game != null:
		apply_language()

func apply_language() -> void:
	if game == null:
		return
	for node in all_children(game):
		if node == button:
			continue
		if node is Label or node is Button:
			translate_node(node)
	if button != null:
		button.text = "RU" if current_language == "en" else "EN"

func translate_node(node: Control) -> void:
	var text := String(node.text)
	if current_language == "en":
		node.text = to_english(text)
	else:
		node.text = to_russian(text)

func to_english(text: String) -> String:
	var exact := {
		"МУТАНТЫ • КОМБО • ВЗРЫВЫ": "MUTANTS • COMBOS • BLASTS",
		"Собирай фишки, ломай коробки\nи создавай мощные бустеры!": "Match pieces, break crates\nand create powerful boosters!",
		"50 УРОВНЕЙ  •  КОРОБКИ  •  КОМБО": "50 LEVELS  •  CRATES  •  COMBOS",
		"ИГРАТЬ": "PLAY",
		"КАРТА УРОВНЕЙ": "LEVEL MAP",
		"МАГАЗИН": "SHOP",
		"50 уровней • монеты • магазин • новая глава": "50 levels • coins • shop • new chapter",
		"1–10 ТРОПИКИ   •   11–19 ХАОС   •   20–30 НОВЫЙ ОСТРОВ": "1–10 TROPICS   •   11–19 CHAOS   •   20–30 NEW ISLAND",
		"НОВАЯ ГЛАВА 31–50": "NEW CHAPTER 31–50",
		"МАГАЗИН УЛУЧШЕНИЙ": "BOOSTER SHOP",
		"За каждую победу ты получаешь монеты.\nПокупай бустеры и используй их на сложных уровнях.": "Earn coins for every victory.\nBuy boosters and use them on difficult levels.",
		"НАЗАД К КАРТЕ": "BACK TO MAP",
		"НАЗАД К КАРТЕ УРОВНЕЙ": "BACK TO LEVEL MAP",
		"Цели уровня": "Level goals",
		"ПАУЗА": "PAUSE",
		"Можно продолжить в любой момент": "You can continue at any time",
		"ПРОДОЛЖИТЬ": "CONTINUE",
		"К КАРТЕ УРОВНЕЙ": "LEVEL MAP",
		"Продолжаем!": "Let's continue!",
		"Прогресс уровня": "Level progress",
		"УРОВЕНЬ ПРОЙДЕН!": "LEVEL COMPLETE!",
		"ХОДЫ ЗАКОНЧИЛИСЬ": "OUT OF MOVES",
		"СЛЕДУЮЩИЙ УРОВЕНЬ": "NEXT LEVEL",
		"ПОВТОРИТЬ": "RETRY",
		"ИГРАТЬ ЕЩЁ РАЗ": "PLAY AGAIN",
		"УРОВНИ 31–50": "LEVELS 31–50",
		"К НОВОЙ ГЛАВЕ": "NEW CHAPTER",
		"НОВАЯ ГЛАВА • УРОВНИ 31–50": "NEW CHAPTER • LEVELS 31–50",
		"Умеренная сложность • больше монет за победы": "Moderate difficulty • more coins for victories",
		"КУПИТЬ": "BUY",
		"Бомба": "Bomb",
		"Ракета": "Rocket",
		"Энерго-ядро": "Energy Core",
		"Взрыв 3×3": "Blast 3×3",
		"+3 ХОДА": "+3 MOVES"
	}
	if exact.has(text):
		return exact[text]
	if text.begins_with("МОНЕТЫ: "):
		return "COINS: " + text.trim_prefix("МОНЕТЫ: ")
	if text.begins_with("Монеты: "):
		return "Coins: " + text.trim_prefix("Монеты: ")
	if text.begins_with("Открыто: "):
		return "Unlocked: " + text.trim_prefix("Открыто: ")
	if text.begins_with("Разбей коробки: "):
		return "Break crates: " + text.trim_prefix("Разбей коробки: ")
	if text.begins_with("УРОВЕНЬ "):
		return text.replace("УРОВЕНЬ ", "LEVEL ").replace(" ОЧКОВ", " POINTS").replace("КОРОБКИ", "CRATES")
	if text.begins_with("Очки: "):
		return text.replace("Очки: ", "Score: ").replace("Коробки: ", "Crates: ")
	if "В запасе:" in text:
		return text.replace("В запасе:", "In stock:")
	if text.begins_with("КУПИТЬ\n"):
		return text.replace("КУПИТЬ", "BUY")
	if text.ends_with("\nЗАКРЫТ"):
		return text.replace("ЗАКРЫТ", "LOCKED")
	if text.ends_with("\nИГРАТЬ"):
		return text.replace("ИГРАТЬ", "PLAY")
	return text

func to_russian(text: String) -> String:
	var exact := {
		"MUTANTS • COMBOS • BLASTS": "МУТАНТЫ • КОМБО • ВЗРЫВЫ",
		"Match pieces, break crates\nand create powerful boosters!": "Собирай фишки, ломай коробки\nи создавай мощные бустеры!",
		"50 LEVELS  •  CRATES  •  COMBOS": "50 УРОВНЕЙ  •  КОРОБКИ  •  КОМБО",
		"PLAY": "ИГРАТЬ",
		"LEVEL MAP": "КАРТА УРОВНЕЙ",
		"SHOP": "МАГАЗИН",
		"50 levels • coins • shop • new chapter": "50 уровней • монеты • магазин • новая глава",
		"1–10 TROPICS   •   11–19 CHAOS   •   20–30 NEW ISLAND": "1–10 ТРОПИКИ   •   11–19 ХАОС   •   20–30 НОВЫЙ ОСТРОВ",
		"NEW CHAPTER 31–50": "НОВАЯ ГЛАВА 31–50",
		"BOOSTER SHOP": "МАГАЗИН УЛУЧШЕНИЙ",
		"Earn coins for every victory.\nBuy boosters and use them on difficult levels.": "За каждую победу ты получаешь монеты.\nПокупай бустеры и используй их на сложных уровнях.",
		"BACK TO MAP": "НАЗАД К КАРТЕ",
		"BACK TO LEVEL MAP": "НАЗАД К КАРТЕ УРОВНЕЙ",
		"Level goals": "Цели уровня",
		"PAUSE": "ПАУЗА",
		"You can continue at any time": "Можно продолжить в любой момент",
		"CONTINUE": "ПРОДОЛЖИТЬ",
		"Let's continue!": "Продолжаем!",
		"Level progress": "Прогресс уровня",
		"LEVEL COMPLETE!": "УРОВЕНЬ ПРОЙДЕН!",
		"OUT OF MOVES": "ХОДЫ ЗАКОНЧИЛИСЬ",
		"NEXT LEVEL": "СЛЕДУЮЩИЙ УРОВЕНЬ",
		"RETRY": "ПОВТОРИТЬ",
		"PLAY AGAIN": "ИГРАТЬ ЕЩЁ РАЗ",
		"LEVELS 31–50": "УРОВНИ 31–50",
		"NEW CHAPTER": "К НОВОЙ ГЛАВЕ",
		"NEW CHAPTER • LEVELS 31–50": "НОВАЯ ГЛАВА • УРОВНИ 31–50",
		"Moderate difficulty • more coins for victories": "Умеренная сложность • больше монет за победы",
		"Bomb": "Бомба",
		"Rocket": "Ракета",
		"Energy Core": "Энерго-ядро",
		"Blast 3×3": "Взрыв 3×3",
		"+3 MOVES": "+3 ХОДА"
	}
	if exact.has(text):
		return exact[text]
	if text.begins_with("COINS: "):
		return "МОНЕТЫ: " + text.trim_prefix("COINS: ")
	if text.begins_with("Coins: "):
		return "Монеты: " + text.trim_prefix("Coins: ")
	if text.begins_with("Unlocked: "):
		return "Открыто: " + text.trim_prefix("Unlocked: ")
	if text.begins_with("Break crates: "):
		return "Разбей коробки: " + text.trim_prefix("Break crates: ")
	if text.begins_with("LEVEL "):
		return text.replace("LEVEL ", "УРОВЕНЬ ").replace(" POINTS", " ОЧКОВ").replace("CRATES", "КОРОБКИ")
	if text.begins_with("Score: "):
		return text.replace("Score: ", "Очки: ").replace("Crates: ", "Коробки: ")
	if "In stock:" in text:
		return text.replace("In stock:", "В запасе:")
	if text.begins_with("BUY\n"):
		return text.replace("BUY", "КУПИТЬ")
	if text.ends_with("\nLOCKED"):
		return text.replace("LOCKED", "ЗАКРЫТ")
	if text.ends_with("\nPLAY"):
		return text.replace("PLAY", "ИГРАТЬ")
	return text

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
