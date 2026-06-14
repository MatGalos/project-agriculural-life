extends Node

signal money_changed(new_amount: int)

var money: int = 100


func get_money() -> int:
	return money


func set_money(new_amount: int) -> void:
	money = max(new_amount, 0)
	money_changed.emit(money)


func add_money(amount: int) -> void:
	if amount <= 0:
		return

	set_money(money + amount)


func can_afford(amount: int) -> bool:
	return money >= amount


func spend_money(amount: int) -> bool:
	if amount <= 0:
		return false

	if not can_afford(amount):
		return false

	set_money(money - amount)
	return true
