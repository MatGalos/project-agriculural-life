extends RefCounted

var runner: TestRunner

const NEWS_PANEL_SCENE := preload("res://Scenes/UIs/PlayerHUD/Phone/NewsApp/news_panel.tscn")
const NEWS_ROW_SCENE := preload("res://Scenes/UIs/PlayerHUD/Phone/NewsApp/news_item_row.tscn")


func run() -> void:
	print("\n--- NewsAppLayoutTest ---")

	var panel := NEWS_PANEL_SCENE.instantiate() as Control
	runner.assert_true(panel != null, "News app scene instantiates")

	if panel:
		_assert_news_panel_layout(panel)
		panel.free()

	var row := NEWS_ROW_SCENE.instantiate() as PanelContainer
	runner.assert_true(row != null, "News item row scene instantiates as card")

	if row:
		_assert_news_card_layout(row)
		row.free()


func _assert_news_panel_layout(panel: Control) -> void:
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/ContentStack/TitleLabel") is Label, "News app has header")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/ContentStack/EmptyStateCard") is PanelContainer, "News app has empty state card")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/ContentStack/NewsScroll") is ScrollContainer, "News app uses scroll container")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/ContentStack/NewsScroll/ListMargin") is MarginContainer, "News app reserves gutter before scrollbar")
	runner.assert_true(panel.get_node_or_null("PanelContainer/MarginContainer/ContentStack/NewsScroll/ListMargin/NewsContainer") is VBoxContainer, "News app has card list container")

	var margin := panel.get_node_or_null("PanelContainer/MarginContainer") as MarginContainer
	runner.assert_true(margin != null, "News app has outer content margin")

	if margin:
		runner.assert_eq(margin.get_theme_constant("margin_left"), 12, "News app keeps adjusted left inset inside FarmPhone screen")
		runner.assert_eq(margin.get_theme_constant("margin_right"), 12, "News app keeps safe right inset inside FarmPhone screen")

	var list_margin := panel.get_node_or_null("PanelContainer/MarginContainer/ContentStack/NewsScroll/ListMargin") as MarginContainer
	if list_margin:
		runner.assert_eq(list_margin.get_theme_constant("margin_right"), 8, "News card list leaves room for the vertical scrollbar")

	var empty_title := panel.get_node_or_null("PanelContainer/MarginContainer/ContentStack/EmptyStateCard/EmptyMargin/EmptyStack/EmptyTitleLabel") as Label
	runner.assert_true(empty_title != null and empty_title.text == "No news yet.", "News app empty state title is user-facing")


func _assert_news_card_layout(row: PanelContainer) -> void:
	runner.assert_true(row.get_node_or_null("CardMargin/CardRow/CategoryIcon") is Label, "News card has category icon")
	runner.assert_true(row.get_node_or_null("CardMargin/CardRow/TextStack/TitleLabel") is Label, "News card has title label")
	runner.assert_true(row.get_node_or_null("CardMargin/CardRow/TextStack/MetaRow/DateLabel") is Label, "News card has date label")
	runner.assert_true(row.get_node_or_null("CardMargin/CardRow/TextStack/MetaRow/CategoryLabel") is Label, "News card has category label")
	runner.assert_true(row.get_node_or_null("CardMargin/CardRow/TextStack/BodyLabel") is Label, "News card has body label")

	var title := row.get_node_or_null("CardMargin/CardRow/TextStack/TitleLabel") as Label
	var date := row.get_node_or_null("CardMargin/CardRow/TextStack/MetaRow/DateLabel") as Label
	var body := row.get_node_or_null("CardMargin/CardRow/TextStack/BodyLabel") as Label
	runner.assert_true(row.custom_minimum_size.y >= 150.0, "News card reserves enough height for wrapped title and body")
	runner.assert_true(title != null and title.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "News card title wraps cleanly")
	runner.assert_true(title != null and title.max_lines_visible == 2, "News card title is capped at two lines")
	runner.assert_true(date != null and date.max_lines_visible == 2, "News card date is capped at two lines")
	runner.assert_true(body != null and body.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "News card body wraps cleanly")
	runner.assert_true(body != null and body.max_lines_visible == 4, "News card body is capped at four lines")
