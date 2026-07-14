var runner: TestRunner


func run() -> void:
	print("\n--- UIFormatHelperTest ---")

	runner.assert_eq(UIFormatHelper.money_int(110), "$110", "UI money int format")
	runner.assert_eq(UIFormatHelper.money_float(33.0), "$33.00", "UI money float format")
	runner.assert_eq(UIFormatHelper.percent(7.04), "+7.04%", "UI positive percent format")
	runner.assert_eq(UIFormatHelper.percent(-2.51), "-2.51%", "UI negative percent format")
	runner.assert_eq(UIFormatHelper.percent(0.0), "0.00%", "UI zero percent format")
	runner.assert_eq(UIFormatHelper.season_date("spring", 3, 1), "Spring 3, Year 1", "UI season date format")
	runner.assert_eq(UIFormatHelper.display_product_name("potatoe"), "Potato", "UI potato display name")
	runner.assert_eq(UIFormatHelper.display_product_name("tomatoe"), "Tomato", "UI tomato display name")
	runner.assert_eq(UIFormatHelper.display_market_trend("bearish"), "Bearish", "UI bearish trend display")
	runner.assert_eq(UIFormatHelper.display_market_trend("bullish"), "Bullish", "UI bullish trend display")
	runner.assert_eq(UIFormatHelper.display_market_trend("neutral"), "Neutral", "UI neutral trend display")
