extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- MoneyManagerTest ---")

	MoneyManager.set_money(100)
	runner.assert_eq(MoneyManager.get_money(), 100, "Money starts at 100")

	MoneyManager.add_money(50)
	runner.assert_eq(MoneyManager.get_money(), 150, "Money add works")

	var spent := MoneyManager.spend_money(40)
	runner.assert_true(spent, "Can spend when enough money")
	runner.assert_eq(MoneyManager.get_money(), 110, "Money spend subtracts amount")

	var failed_spend := MoneyManager.spend_money(999)
	runner.assert_true(not failed_spend, "Cannot spend more than available")
	runner.assert_eq(MoneyManager.get_money(), 110, "Failed spend does not change money")
