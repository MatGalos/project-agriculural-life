extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- MarketSaveTest ---")

	var commodity := CommodityMarketManager.commodities[0]

	commodity.current_price = 22.5
	commodity.volatility = 0.12
	commodity.trend = CommodityData.MarketTrend.BULLISH
	commodity.trend_strength = 0.03
	commodity.price_history = [15.0, 18.0, 22.5]
	commodity.price_history_labels = ["Day 1 09:00", "Day 1 10:00", "Day 1 11:00"]

	var save_data := SaveManager._create_market_save_data()

	commodity.current_price = 1.0
	commodity.volatility = 0.01
	commodity.trend = CommodityData.MarketTrend.NEUTRAL
	commodity.trend_strength = 0.01
	commodity.price_history.clear()
	commodity.price_history_labels.clear()

	SaveManager._apply_market_save_data(save_data)

	runner.assert_eq(commodity.current_price, 22.5, "Market price restored")
	runner.assert_eq(commodity.volatility, 0.12, "Market volatility restored")
	runner.assert_eq(int(commodity.trend), int(CommodityData.MarketTrend.BULLISH), "Market trend restored")
	runner.assert_eq(commodity.trend_strength, 0.03, "Market trend strength restored")
	runner.assert_eq(commodity.price_history.size(), 3, "Market history restored")
	runner.assert_eq(commodity.price_history_labels.size(), 3, "Market history labels restored")
