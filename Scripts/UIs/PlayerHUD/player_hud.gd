extends CanvasLayer

const CROSSHAIR_SIZE := 40.0

@onready var prompt_label: Label = $Root/CenterContainer/PromptLabel


func _ready() -> void:
	get_viewport().size_changed.connect(_update_prompt_layout)
	_update_prompt_layout()


func _update_prompt_layout() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var min_axis: float = minf(viewport_size.x, viewport_size.y)
	var prompt_width: float = clampf(viewport_size.x * 0.42, 280.0, 640.0)
	var prompt_gap: float = clampf(min_axis * 0.045, 28.0, 64.0)
	var prompt_font_size: int = roundi(clampf(min_axis * 0.026, 18.0, 28.0))
	var prompt_height: float = maxf(float(prompt_font_size) * 1.7, 40.0)
	var prompt_top: float = (CROSSHAIR_SIZE * 0.5) + prompt_gap

	prompt_label.offset_left = -prompt_width * 0.5
	prompt_label.offset_top = prompt_top
	prompt_label.offset_right = prompt_width * 0.5
	prompt_label.offset_bottom = prompt_top + prompt_height
	prompt_label.add_theme_font_size_override("font_size", prompt_font_size)
