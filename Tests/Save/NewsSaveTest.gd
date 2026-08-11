extends RefCounted

var runner: TestRunner


func run() -> void:
	print("\n--- NewsSaveTest ---")

	NewsManager.clear_news()

	var news := NewsItem.new()
	news.title = "Test News"
	news.body = "Test Body"
	news.day = 3
	news.month = 1
	news.year = 1
	news.category = "Test"

	NewsManager.add_news(news)

	var save_data := SaveManager._create_news_save_data()

	NewsManager.clear_news()
	runner.assert_eq(NewsManager.news_items.size(), 0, "News cleared before load")

	SaveManager._apply_news_save_data(save_data)

	runner.assert_eq(NewsManager.news_items.size(), 1, "News restored")
	runner.assert_eq(NewsManager.news_items[0].title, "Test News", "News title restored")
	runner.assert_eq(NewsManager.news_items[0].body, "Test Body", "News body restored")
