extends Node

var last_coins := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var economy = get_node_or_null("/root/Economy")
	if economy == null:
		return
	var coins := int(economy.get("coins"))
	if coins == last_coins:
		return
	last_coins = coins
	var scene := get_tree().current_scene
	if scene == null:
		return
	update_coin_labels(scene, coins)

func update_coin_labels(node: Node, coins: int) -> void:
	for child in node.get_children():
		if child is Label:
			var text := str(child.text)
			if text.begins_with("МОНЕТЫ:"):
				child.text = "МОНЕТЫ: %d" % coins
			elif text.begins_with("Монеты:"):
				child.text = "Монеты: %d" % coins
		update_coin_labels(child, coins)
