extends Node

var game: Control
var board_grid: GridContainer

func _ready() -> void:
	call_deferred("apply_layout")

func apply_layout() -> void:
	# Wait until game.gd and VisualUpgrade finish building the UI.
	for i in range(3):
		await get_tree().process_frame

	game = get_tree().current_scene as Control
	if game == null:
		return

	board_grid = game.get("board_grid") as GridContainer
	if board_grid == null:
		return

	_fix_board_position()

	var viewport := game.get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_fix_board_position):
		viewport.size_changed.connect(_fix_board_position)

func _fix_board_position() -> void:
	if game == null or board_grid == null:
		return

	var panel := board_grid.get_parent() as Control
	if panel == null:
		return

	var root := panel.get_parent() as Control
	if root == null:
		return

	# Use absolute top-left anchoring so the board does not drift when the
	# window/stretched viewport changes. Keep it centered between HUD and boosters.
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.position = Vector2(55, 190)
	root.size = Vector2(610, 620)
	root.custom_minimum_size = Vector2(610, 620)

	# Ensure the board itself keeps the intended 8x8 compact spacing.
	board_grid.add_theme_constant_override("h_separation", 3)
	board_grid.add_theme_constant_override("v_separation", 3)
