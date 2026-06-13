extends Control

const PondGeneratorScript := preload("res://scripts/pond_generator.gd")

@onready var day_label: Label = $Panel/Margin/Content/Header/DayLabel
@onready var card_list: VBoxContainer = $Panel/Margin/Content/Scroll/CardList

var game_state: GameState
var screen_container: Control

func setup(next_game_state: GameState, next_screen_container: Control) -> void:
	game_state = next_game_state
	screen_container = next_screen_container

func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()

	_render_ponds()

func _render_ponds() -> void:
	var generator := PondGeneratorScript.new()
	var ponds := generator.generate_daily_ponds(game_state.day)
	day_label.text = "第 %d 天：今日可看 3 口塘" % game_state.day

	for child in card_list.get_children():
		child.queue_free()

	for pond in ponds:
		card_list.add_child(_create_pond_card(pond))

func _create_pond_card(pond: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 330)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var title := Label.new()
	title.text = "%s  ｜  报价：%d 元" % [pond["name"], pond["quote_price"]]
	title.add_theme_font_size_override("font_size", 38)
	content.add_child(title)

	var info := Label.new()
	info.text = "类型：%s    塘龄：%s（%d 年）" % [pond["pond_type_name"], pond["age_label"], pond["age_years"]]
	info.add_theme_font_size_override("font_size", 30)
	content.add_child(info)

	var water := Label.new()
	water.text = "水色：%s" % pond["water_state"]
	water.add_theme_font_size_override("font_size", 30)
	content.add_child(water)

	var rumor := Label.new()
	rumor.text = "传闻：%s" % pond["rumor"]
	rumor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rumor.add_theme_font_size_override("font_size", 30)
	content.add_child(rumor)

	var risk := Label.new()
	risk.text = "风险：%s" % pond["risk_tag"]
	risk.add_theme_font_size_override("font_size", 30)
	content.add_child(risk)

	var view_button := Button.new()
	view_button.name = "ViewButton"
	view_button.text = "查看"
	view_button.custom_minimum_size = Vector2(0, 72)
	view_button.add_theme_font_size_override("font_size", 32)
	view_button.pressed.connect(_on_view_pressed.bind(pond))
	content.add_child(view_button)

	return card

func _on_view_pressed(pond: Dictionary) -> void:
	UIController.show_pond_detail(screen_container, game_state, pond)
