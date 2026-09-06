extends Node

const SAVE_PATH := "user://mutant_match_economy.cfg"

var coins: int = 0
var boosters: Array[int] = [3, 3, 3, 3]

func _ready() -> void:
	load_data()

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	coins = maxi(0, int(cfg.get_value("economy", "coins", 0)))
	var saved: Array = cfg.get_value("economy", "boosters", [3, 3, 3, 3])
	for i in range(mini(4, saved.size())):
		boosters[i] = maxi(0, int(saved[i]))

func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("economy", "coins", coins)
	cfg.set_value("economy", "boosters", boosters)
	cfg.save(SAVE_PATH)

func reward_for_level(level_number: int) -> int:
	var reward := 40 + level_number * 8
	coins += reward
	save_data()
	return reward

func can_afford(price: int) -> bool:
	return coins >= price

func buy_booster(index: int, price: int, amount: int = 1) -> bool:
	if index < 0 or index >= boosters.size():
		return false
	if price < 0 or amount <= 0 or coins < price:
		return false
	coins -= price
	boosters[index] += amount
	save_data()
	return true

func use_booster(index: int) -> bool:
	if index < 0 or index >= boosters.size() or boosters[index] <= 0:
		return false
	boosters[index] -= 1
	save_data()
	return true

func get_booster_count(index: int) -> int:
	if index < 0 or index >= boosters.size():
		return 0
	return boosters[index]
