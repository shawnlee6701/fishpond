extends Control

const PondGeneratorScript := preload("res://scripts/pond_generator.gd")

@onready var day_label: Label = $Panel/Margin/Content/Header/DayLabel
@onready var cash_label: Label = $Panel/Margin/Content/Header/CashLabel
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
	if game_state.daily_ponds_day != game_state.day or game_state.daily_ponds.is_empty():
		var generator := PondGeneratorScript.new()
		game_state.daily_ponds = generator.generate_daily_ponds(game_state.day, game_state.cash)
		game_state.daily_ponds_day = game_state.day

	var ponds := game_state.daily_ponds
	day_label.text = "第 %d 天：今天有 3 口塘可谈，先看牌面再决定。" % game_state.day
	cash_label.text = "手上本钱：%d 元" % game_state.cash

	for child in card_list.get_children():
		child.queue_free()

	for pond in ponds:
		card_list.add_child(_create_pond_card(pond))

func _create_pond_card(pond: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 350)

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
	title.text = "%s  ｜  塘主要价：%d 元" % [pond["name"], pond["quote_price"]]
	title.add_theme_font_size_override("font_size", 38)
	content.add_child(title)

	var info := Label.new()
	info.text = "塘型：%s    水面：%s    水深：%s（%.1f 米）" % [pond["pond_type_name"], pond["area_label"], pond["depth_label"], float(pond["depth_meters"])]
	info.add_theme_font_size_override("font_size", 30)
	content.add_child(info)

	var age := Label.new()
	age.text = "塘龄：%s（%d 年）" % [pond["age_label"], pond["age_years"]]
	age.add_theme_font_size_override("font_size", 30)
	content.add_child(age)

	var water := Label.new()
	water.text = "水色看着：%s" % pond["water_state"]
	water.add_theme_font_size_override("font_size", 30)
	content.add_child(water)

	var rumor := Label.new()
	rumor.text = "塘边说法：%s" % pond["rumor"]
	rumor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rumor.add_theme_font_size_override("font_size", 30)
	content.add_child(rumor)

	var view_button := Button.new()
	view_button.name = "ViewButton"
	view_button.text = "进塘看看"
	view_button.custom_minimum_size = Vector2(0, 72)
	view_button.add_theme_font_size_override("font_size", 32)
	view_button.pressed.connect(_on_view_pressed.bind(pond))
	content.add_child(view_button)

	return card

func _on_view_pressed(pond: Dictionary) -> void:
	UIController.show_pond_detail(screen_container, game_state, pond)
