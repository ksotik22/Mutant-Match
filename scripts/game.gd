extends Control

const COLS := 8
const ROWS := 8
const TYPES := 6
const CELL := 68.0
const GAP := 6.0

var board: Array = []
var cells: Array = []
var selected := Vector2i(-1, -1)
var moves := 25
var score := 0
var target := 1200
var busy := false

var board_grid: GridContainer
var moves_label: Label
var score_label: Label
var goal_label: Label
var status_label: Label

var colors := [
	Color("ff5b70"), Color("4da6ff"), Color("ffd447"),
	Color("63d66b"), Color("a96cff"), Color("ff914d")
]
var symbols := ["◆", "●", "★", "■", "✦", "⬟"]

func _ready() -> void:
	build_ui()
	new_game()

func build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("152449")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.position = Vector2(-305, -430)
	root.custom_minimum_size = Vector2(610, 860)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	var title := Label.new()
	title.text = "MUTANT MATCH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("fff4d6"))
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Собирай энерго-ядра и запускай цепные реакции"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color("b9d5ff"))
	root.add_child(subtitle)

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	moves_label = make_stat(top, "ХОДЫ\n25")
	score_label = make_stat(top, "СЧЁТ\n0")
	goal_label = make_stat(top, "ЦЕЛЬ\n1200")

	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("263b72")
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_left = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.content_margin_left = 14
	panel_style.content_margin_right = 14
	panel_style.content_margin_top = 14
	panel_style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(panel)

	board_grid = GridContainer.new()
	board_grid.columns = COLS
	board_grid.add_theme_constant_override("h_separation", int(GAP))
	board_grid.add_theme_constant_override("v_separation", int(GAP))
	panel.add_child(board_grid)

	status_label = Label.new()
	status_label.text = "Поменяй соседние фишки местами"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 19)
	status_label.add_theme_color_override("font_color", Color("ffffff"))
	root.add_child(status_label)

	var restart := Button.new()
	restart.text = "НОВАЯ ИГРА"
	restart.custom_minimum_size = Vector2(220, 52)
	restart.add_theme_font_size_override("font_size", 18)
	restart.pressed.connect(new_game)
	root.add_child(restart)

func make_stat(parent: Node, text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size = Vector2(170, 72)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("203460")
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("5476b8")
	label.add_theme_stylebox_override("normal", style)
	parent.add_child(label)
	return label

func new_game() -> void:
	busy = false
	selected = Vector2i(-1, -1)
	moves = 25
	score = 0
	board.clear()
	for y in ROWS:
		var row: Array = []
		for x in COLS:
			var t := randi_range(0, TYPES - 1)
			while (x >= 2 and row[x - 1] == t and row[x - 2] == t) or (y >= 2 and board[y - 1][x] == t and board[y - 2][x] == t):
				t = randi_range(0, TYPES - 1)
			row.append(t)
		board.append(row)
	build_cells()
	update_hud()
	status_label.text = "Собери 3 или больше одинаковых"

func build_cells() -> void:
	for child in board_grid.get_children():
		child.queue_free()
	cells.clear()
	for y in ROWS:
		var cell_row: Array = []
		for x in COLS:
			var b := Button.new()
			b.custom_minimum_size = Vector2(CELL, CELL)
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(on_cell_pressed.bind(Vector2i(x, y)))
			board_grid.add_child(b)
			cell_row.append(b)
		cells.append(cell_row)
	refresh_board()

func refresh_board() -> void:
	for y in ROWS:
		for x in COLS:
			var b: Button = cells[y][x]
			var t: int = board[y][x]
			b.text = symbols[t]
			b.add_theme_font_size_override("font_size", 34)
			var style := StyleBoxFlat.new()
			style.bg_color = colors[t]
			style.corner_radius_top_left = 16
			style.corner_radius_top_right = 16
			style.corner_radius_bottom_left = 16
			style.corner_radius_bottom_right = 16
			style.border_width_left = 4 if selected == Vector2i(x,y) else 2
			style.border_width_top = 4 if selected == Vector2i(x,y) else 2
			style.border_width_right = 4 if selected == Vector2i(x,y) else 2
			style.border_width_bottom = 4 if selected == Vector2i(x,y) else 2
			style.border_color = Color.WHITE if selected == Vector2i(x,y) else colors[t].lightened(0.25)
			b.add_theme_stylebox_override("normal", style)
			var hover := style.duplicate()
			hover.bg_color = colors[t].lightened(0.12)
			b.add_theme_stylebox_override("hover", hover)

func on_cell_pressed(pos: Vector2i) -> void:
	if busy or moves <= 0:
		return
	if selected.x < 0:
		selected = pos
		refresh_board()
		return
	if selected == pos:
		selected = Vector2i(-1, -1)
		refresh_board()
		return
	var dist := abs(selected.x - pos.x) + abs(selected.y - pos.y)
	if dist != 1:
		selected = pos
		refresh_board()
		return
	busy = true
	var a := selected
	selected = Vector2i(-1, -1)
	swap_cells(a, pos)
	refresh_board()
	await get_tree().create_timer(0.12).timeout
	var matches := find_matches()
	if matches.is_empty():
		swap_cells(a, pos)
		status_label.text = "Нет комбинации — ход не потрачен"
		refresh_board()
		busy = false
		return
	moves -= 1
	await resolve_cascades(matches)
	update_hud()
	if score >= target:
		status_label.text = "ПОБЕДА! Цель выполнена ✦"
	elif moves <= 0:
		status_label.text = "Ходы закончились. Попробуй ещё раз"
	else:
		status_label.text = "Отлично! Ищи следующую цепочку"
	busy = false

func swap_cells(a: Vector2i, b: Vector2i) -> void:
	var temp = board[a.y][a.x]
	board[a.y][a.x] = board[b.y][b.x]
	board[b.y][b.x] = temp

func find_matches() -> Array:
	var found := {}
	for y in ROWS:
		var run_start := 0
		for x in range(1, COLS + 1):
			if x == COLS or board[y][x] != board[y][run_start]:
				if x - run_start >= 3:
					for mx in range(run_start, x): found[Vector2i(mx,y)] = true
				run_start = x
	for x in COLS:
		var run_start := 0
		for y in range(1, ROWS + 1):
			if y == ROWS or board[y][x] != board[run_start][x]:
				if y - run_start >= 3:
					for my in range(run_start, y): found[Vector2i(x,my)] = true
				run_start = y
	return found.keys()

func resolve_cascades(matches: Array) -> void:
	var chain := 1
	var current := matches
	while not current.is_empty():
		score += current.size() * 25 * chain
		status_label.text = "КАСКАД x%d   +%d" % [chain, current.size() * 25 * chain]
		for p in current:
			board[p.y][p.x] = -1
		refresh_removed()
		await get_tree().create_timer(0.18).timeout
		collapse_board()
		refresh_board()
		update_hud()
		await get_tree().create_timer(0.18).timeout
		current = find_matches()
		chain += 1

func refresh_removed() -> void:
	for y in ROWS:
		for x in COLS:
			var b: Button = cells[y][x]
			if board[y][x] == -1:
				b.text = ""
				var empty := StyleBoxFlat.new()
				empty.bg_color = Color("182a55")
				empty.corner_radius_top_left = 16
				empty.corner_radius_top_right = 16
				empty.corner_radius_bottom_left = 16
				empty.corner_radius_bottom_right = 16
				b.add_theme_stylebox_override("normal", empty)

func collapse_board() -> void:
	for x in COLS:
		var values: Array = []
		for y in range(ROWS - 1, -1, -1):
			if board[y][x] != -1:
				values.append(board[y][x])
		var index := 0
		for y in range(ROWS - 1, -1, -1):
			if index < values.size():
				board[y][x] = values[index]
				index += 1
			else:
				board[y][x] = randi_range(0, TYPES - 1)

func update_hud() -> void:
	moves_label.text = "ХОДЫ\n%d" % moves
	score_label.text = "СЧЁТ\n%d" % score
	goal_label.text = "ЦЕЛЬ\n%d" % target
