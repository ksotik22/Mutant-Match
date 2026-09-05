extends Control

const COLS := 8
const ROWS := 8
const TYPES := 6
const CELL := 68.0
const GAP := 6.0
const NORMAL := 0
const ROCKET_H := 1
const ROCKET_V := 2
const BOMB := 3
const CORE := 4

var board: Array = []
var specials: Array = []
var cells: Array = []
var selected := Vector2i(-1, -1)
var moves: int = 28
var score: int = 0
var target: int = 1500
var busy := false
var last_swap_b := Vector2i(-1, -1)
var rng := RandomNumberGenerator.new()

var board_grid: GridContainer
var moves_label: Label
var score_label: Label
var goal_label: Label
var status_label: Label

var colors := [Color("ff5b70"), Color("4da6ff"), Color("ffd447"), Color("63d66b"), Color("a96cff"), Color("ff914d")]
var symbols := ["◆", "●", "★", "■", "✦", "⬟"]

func _ready() -> void:
	rng.randomize()
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
	subtitle.text = "Цепные реакции • ракеты • бомбы • ядра"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color("b9d5ff"))
	root.add_child(subtitle)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	moves_label = make_stat(top, "ХОДЫ\n28")
	score_label = make_stat(top, "СЧЁТ\n0")
	goal_label = make_stat(top, "ЦЕЛЬ\n1500")
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color("263b72")
	ps.corner_radius_top_left = 24
	ps.corner_radius_top_right = 24
	ps.corner_radius_bottom_left = 24
	ps.corner_radius_bottom_right = 24
	ps.content_margin_left = 14
	ps.content_margin_right = 14
	ps.content_margin_top = 14
	ps.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", ps)
	root.add_child(panel)
	board_grid = GridContainer.new()
	board_grid.columns = COLS
	board_grid.add_theme_constant_override("h_separation", int(GAP))
	board_grid.add_theme_constant_override("v_separation", int(GAP))
	panel.add_child(board_grid)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 19)
	status_label.add_theme_color_override("font_color", Color.WHITE)
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
	style.set_border_width_all(2)
	style.border_color = Color("5476b8")
	label.add_theme_stylebox_override("normal", style)
	parent.add_child(label)
	return label

func new_game() -> void:
	busy = false
	selected = Vector2i(-1, -1)
	moves = 28
	score = 0
	board.clear()
	specials.clear()
	for y in ROWS:
		var row: Array = []
		var srow: Array = []
		for x in COLS:
			var t: int = rng.randi_range(0, TYPES - 1)
			while (x >= 2 and row[x - 1] == t and row[x - 2] == t) or (y >= 2 and board[y - 1][x] == t and board[y - 2][x] == t):
				t = rng.randi_range(0, TYPES - 1)
			row.append(t)
			srow.append(NORMAL)
		board.append(row)
		specials.append(srow)
	build_cells()
	update_hud()
	status_label.text = "4 = ракета • 5 = ядро • Т/L = бомба"

func build_cells() -> void:
	for child in board_grid.get_children(): child.queue_free()
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

func piece_text(x: int, y: int) -> String:
	match int(specials[y][x]):
		ROCKET_H: return "↔"
		ROCKET_V: return "↕"
		BOMB: return "✹"
		CORE: return "◎"
	return symbols[int(board[y][x])]

func refresh_board() -> void:
	for y in ROWS:
		for x in COLS:
			var b: Button = cells[y][x]
			var t: int = int(board[y][x])
			b.text = piece_text(x, y)
			b.add_theme_font_size_override("font_size", 36 if int(specials[y][x]) != NORMAL else 34)
			var style := StyleBoxFlat.new()
			style.bg_color = colors[t]
			if int(specials[y][x]) != NORMAL: style.bg_color = colors[t].lightened(0.18)
			style.corner_radius_top_left = 16
			style.corner_radius_top_right = 16
			style.corner_radius_bottom_left = 16
			style.corner_radius_bottom_right = 16
			style.set_border_width_all(5 if selected == Vector2i(x,y) or int(specials[y][x]) != NORMAL else 2)
			style.border_color = Color.WHITE if selected == Vector2i(x,y) or int(specials[y][x]) != NORMAL else colors[t].lightened(0.25)
			b.add_theme_stylebox_override("normal", style)
			var hover: StyleBoxFlat = style.duplicate()
			hover.bg_color = style.bg_color.lightened(0.12)
			b.add_theme_stylebox_override("hover", hover)

func on_cell_pressed(pos: Vector2i) -> void:
	if busy or moves <= 0: return
	if selected.x < 0:
		selected = pos
		refresh_board()
		return
	if selected == pos:
		selected = Vector2i(-1, -1)
		refresh_board()
		return
	var dist: int = absi(selected.x - pos.x) + absi(selected.y - pos.y)
	if dist != 1:
		selected = pos
		refresh_board()
		return
	busy = true
	var a: Vector2i = selected
	selected = Vector2i(-1, -1)
	last_swap_b = pos
	swap_cells(a, pos)
	refresh_board()
	await get_tree().create_timer(0.10).timeout
	if int(specials[a.y][a.x]) != NORMAL or int(specials[pos.y][pos.x]) != NORMAL:
		moves -= 1
		var blast: Dictionary = {}
		activate_special(a, blast)
		activate_special(pos, blast)
		await resolve_blast(blast, 1)
		finish_move()
		return
	var matches: Array = find_matches()
	if matches.is_empty():
		swap_cells(a, pos)
		status_label.text = "Почти! Попробуй другой ход"
		refresh_board()
		busy = false
		return
	moves -= 1
	await resolve_cascades(matches, pos)
	finish_move()

func finish_move() -> void:
	update_hud()
	if score >= target: status_label.text = "ПОБЕДА! Мощная цепная реакция!"
	elif moves <= 0: status_label.text = "Ходы закончились — ещё попытка?"
	elif not status_label.text.begins_with("КАСКАД"): status_label.text = "Отлично! Собери ещё спецфишки"
	busy = false

func swap_cells(a: Vector2i, b: Vector2i) -> void:
	var temp: int = int(board[a.y][a.x])
	board[a.y][a.x] = board[b.y][b.x]
	board[b.y][b.x] = temp
	var st: int = int(specials[a.y][a.x])
	specials[a.y][a.x] = specials[b.y][b.x]
	specials[b.y][b.x] = st

func find_matches() -> Array:
	var found: Dictionary = {}
	for y in ROWS:
		var start: int = 0
		for x in range(1, COLS + 1):
			if x == COLS or board[y][x] != board[y][start]:
				if x - start >= 3:
					for mx in range(start, x): found[Vector2i(mx,y)] = true
				start = x
	for x in COLS:
		var start: int = 0
		for y in range(1, ROWS + 1):
			if y == ROWS or board[y][x] != board[start][x]:
				if y - start >= 3:
					for my in range(start, y): found[Vector2i(x,my)] = true
				start = y
	return found.keys()

func run_length(pos: Vector2i, horizontal: bool) -> int:
	var t: int = int(board[pos.y][pos.x])
	var count: int = 1
	var dx: int = 1 if horizontal else 0
	var dy: int = 0 if horizontal else 1
	var x: int = pos.x - dx
	var y: int = pos.y - dy
	while x >= 0 and y >= 0 and x < COLS and y < ROWS and int(board[y][x]) == t:
		count += 1; x -= dx; y -= dy
	x = pos.x + dx; y = pos.y + dy
	while x >= 0 and y >= 0 and x < COLS and y < ROWS and int(board[y][x]) == t:
		count += 1; x += dx; y += dy
	return count

func choose_special(matches: Array, preferred: Vector2i) -> Dictionary:
	var result: Dictionary = {"pos": Vector2i(-1,-1), "kind": NORMAL}
	for p in matches:
		var h: int = run_length(p, true)
		var v: int = run_length(p, false)
		if h >= 3 and v >= 3: return {"pos": p, "kind": BOMB}
	for p in matches:
		if run_length(p, true) >= 5 or run_length(p, false) >= 5:
			return {"pos": preferred if matches.has(preferred) else p, "kind": CORE}
	for p in matches:
		if run_length(p, true) >= 4:
			return {"pos": preferred if matches.has(preferred) else p, "kind": ROCKET_V}
		if run_length(p, false) >= 4:
			return {"pos": preferred if matches.has(preferred) else p, "kind": ROCKET_H}
	return result

func resolve_cascades(matches: Array, preferred: Vector2i = Vector2i(-1,-1)) -> void:
	var chain: int = 1
	var current: Array = matches
	while not current.is_empty():
		var create: Dictionary = choose_special(current, preferred if chain == 1 else Vector2i(-1,-1))
		var blast: Dictionary = {}
		for p in current:
			if p != create["pos"]: blast[p] = true
		for p in current:
			if int(specials[p.y][p.x]) != NORMAL and p != create["pos"]: activate_special(p, blast)
		if int(create["kind"]) != NORMAL:
			var cp: Vector2i = create["pos"]
			specials[cp.y][cp.x] = int(create["kind"])
			status_label.text = special_message(int(create["kind"]))
		score += blast.size() * 30 * chain
		for p in blast.keys(): clear_piece(p)
		refresh_removed()
		await get_tree().create_timer(0.14).timeout
		collapse_board(chain)
		refresh_board()
		update_hud()
		await get_tree().create_timer(0.14).timeout
		current = find_matches()
		if not current.is_empty(): status_label.text = "КАСКАД x%d  +%d" % [chain + 1, current.size() * 30 * (chain + 1)]
		chain += 1

func special_message(kind: int) -> String:
	if kind == CORE: return "ЭНЕРГО-ЯДРО! 5 в ряд"
	if kind == BOMB: return "МУТАНТ-БОМБА! Т/L комбинация"
	return "РАКЕТА! 4 в ряд"

func activate_special(pos: Vector2i, blast: Dictionary) -> void:
	if pos.x < 0 or pos.y < 0 or pos.x >= COLS or pos.y >= ROWS: return
	if blast.has(pos): return
	blast[pos] = true
	var kind: int = int(specials[pos.y][pos.x])
	if kind == ROCKET_H:
		for x in COLS: add_blast(Vector2i(x,pos.y), blast)
	elif kind == ROCKET_V:
		for y in ROWS: add_blast(Vector2i(pos.x,y), blast)
	elif kind == BOMB:
		for yy in range(maxi(0,pos.y-2), mini(ROWS,pos.y+3)):
			for xx in range(maxi(0,pos.x-2), mini(COLS,pos.x+3)): add_blast(Vector2i(xx,yy), blast)
	elif kind == CORE:
		var target_type: int = rng.randi_range(0, TYPES - 1)
		for y in ROWS:
			for x in COLS:
				if int(board[y][x]) == target_type: add_blast(Vector2i(x,y), blast)

func add_blast(pos: Vector2i, blast: Dictionary) -> void:
	if blast.has(pos): return
	blast[pos] = true
	if int(specials[pos.y][pos.x]) != NORMAL: activate_special(pos, blast)

func resolve_blast(blast: Dictionary, chain: int) -> void:
	score += blast.size() * 35 * chain
	status_label.text = "ЦЕПНАЯ РЕАКЦИЯ!  +%d" % (blast.size() * 35 * chain)
	for p in blast.keys(): clear_piece(p)
	refresh_removed()
	await get_tree().create_timer(0.15).timeout
	collapse_board(chain)
	refresh_board()
	await get_tree().create_timer(0.15).timeout
	var matches: Array = find_matches()
	if not matches.is_empty(): await resolve_cascades(matches)

func clear_piece(pos: Vector2i) -> void:
	board[pos.y][pos.x] = -1
	specials[pos.y][pos.x] = NORMAL

func refresh_removed() -> void:
	for y in ROWS:
		for x in COLS:
			var b: Button = cells[y][x]
			if int(board[y][x]) == -1:
				b.text = ""
				var empty := StyleBoxFlat.new()
				empty.bg_color = Color("182a55")
				empty.corner_radius_top_left = 16
				empty.corner_radius_top_right = 16
				empty.corner_radius_bottom_left = 16
				empty.corner_radius_bottom_right = 16
				b.add_theme_stylebox_override("normal", empty)

func collapse_board(chain: int = 1) -> void:
	for x in COLS:
		var vals: Array = []
		var specs: Array = []
		for y in range(ROWS - 1, -1, -1):
			if int(board[y][x]) != -1:
				vals.append(board[y][x]); specs.append(specials[y][x])
		var index: int = 0
		for y in range(ROWS - 1, -1, -1):
			if index < vals.size():
				board[y][x] = vals[index]; specials[y][x] = specs[index]; index += 1
			else:
				board[y][x] = generous_piece(x, y, chain)
				specials[y][x] = NORMAL

func generous_piece(x: int, y: int, chain: int) -> int:
	# Slightly favor colors that can continue a chain. It keeps the game lively without guaranteeing every drop.
	var candidates: Array[int] = []
	if y + 2 < ROWS and int(board[y+1][x]) == int(board[y+2][x]) and int(board[y+1][x]) >= 0:
		for i in range(3 + mini(chain, 3)): candidates.append(int(board[y+1][x]))
	if x >= 2 and int(board[y][x-1]) == int(board[y][x-2]) and int(board[y][x-1]) >= 0:
		for i in range(2 + mini(chain, 2)): candidates.append(int(board[y][x-1]))
	if x + 2 < COLS and int(board[y][x+1]) == int(board[y][x+2]) and int(board[y][x+1]) >= 0:
		for i in range(2 + mini(chain, 2)): candidates.append(int(board[y][x+1]))
	if not candidates.is_empty() and rng.randf() < 0.58:
		return candidates[rng.randi_range(0, candidates.size()-1)]
	return rng.randi_range(0, TYPES - 1)

func update_hud() -> void:
	moves_label.text = "ХОДЫ\n%d" % moves
	score_label.text = "СЧЁТ\n%d" % score
	goal_label.text = "ЦЕЛЬ\n%d" % target
