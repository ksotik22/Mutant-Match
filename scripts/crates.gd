extends Node

var game: Control
var remaining: int = 0
var total: int = 0
var crate_nodes: Dictionary = {}
var rng := RandomNumberGenerator.new()
var crate_texture: Texture2D

func _ready() -> void:
	rng.randomize()
	crate_texture = load("res://assets/ui/goal_crate.svg")
	call_deferred("setup")

func setup() -> void:
	for i in range(4):
		await get_tree().process_frame
	game = get_tree().current_scene as Control

func reset_for_level(count: int) -> void:
	for node in crate_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	crate_nodes.clear()
	total = maxi(0, count)
	remaining = total
	if game == null:
		game = get_tree().current_scene as Control
	if game == null or total <= 0:
		return
	await get_tree().process_frame
	var cells = game.get("cells")
	if cells == null or cells.size() < 8:
		return
	var spots: Array[Vector2i] = []
	for y in range(8):
		for x in range(8):
			spots.append(Vector2i(x, y))
	spots.shuffle()
	for i in range(mini(total, spots.size())):
		add_crate(spots[i])

func add_crate(pos: Vector2i) -> void:
	var cells = game.get("cells")
	if cells == null or pos.y >= cells.size() or pos.x >= cells[pos.y].size():
		return
	var button: Button = cells[pos.y][pos.x]
	if button == null:
		return
	var icon := TextureRect.new()
	icon.name = "Crate_%d_%d" % [pos.x, pos.y]
	icon.texture = crate_texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.z_index = 12
	icon.modulate = Color(1, 1, 1, 0.95)
	icon.pivot_offset = button.size * 0.5
	button.add_child(icon)
	crate_nodes[pos] = icon
	var tw := create_tween()
	icon.scale = Vector2(0.25, 0.25)
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(icon, "scale", Vector2.ONE, 0.22)

func _process(_delta: float) -> void:
	if game == null or remaining <= 0 or crate_nodes.is_empty():
		return
	var board = game.get("board")
	if board == null or board.size() < 8:
		return

	# A crate breaks when its own tile is destroyed OR when a matched/destroyed
	# tile is directly next to it. This makes normal 3-in-a-row matches useful
	# for clearing crates, not only bombs and rockets.
	var destroyed: Array[Vector2i] = []
	for y in range(8):
		for x in range(8):
			if int(board[y][x]) == -1:
				destroyed.append(Vector2i(x, y))

	if destroyed.is_empty():
		return

	var broken: Dictionary = {}
	var dirs := [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for hit in destroyed:
		for dir in dirs:
			var p: Vector2i = hit + dir
			if crate_nodes.has(p):
				broken[p] = true

	for pos in broken.keys():
		break_crate(pos)

func break_crate(pos: Vector2i) -> void:
	if not crate_nodes.has(pos):
		return
	var icon: TextureRect = crate_nodes[pos]
	crate_nodes.erase(pos)
	remaining = maxi(0, remaining - 1)
	if game != null and game.get("status_label") != null:
		game.status_label.text = "КОРОБКА РАЗБИТА! Осталось %d" % remaining
	if is_instance_valid(icon):
		icon.pivot_offset = icon.size * 0.5
		var tw := create_tween()
		tw.set_parallel(true)
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_property(icon, "scale", Vector2(1.45, 0.35), 0.14)
		tw.tween_property(icon, "rotation", randf_range(-0.35, 0.35), 0.14)
		tw.tween_property(icon, "modulate:a", 0.0, 0.18)
		tw.chain().tween_callback(icon.queue_free)
	spawn_crate_pop(pos)

func spawn_crate_pop(pos: Vector2i) -> void:
	if game == null:
		return
	var cells = game.get("cells")
	if cells == null or pos.y >= cells.size() or pos.x >= cells[pos.y].size():
		return
	var button: Button = cells[pos.y][pos.x]
	var label := Label.new()
	label.text = "+ КОРОБКА!"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 120
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color("ffd84f"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.position = button.global_position + Vector2(-18, -10)
	game.add_child(label)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 70.0, 0.55)
	tw.tween_property(label, "modulate:a", 0.0, 0.55)
	tw.chain().tween_callback(label.queue_free)
