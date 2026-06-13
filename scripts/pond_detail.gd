extends Control

const DataLoaderScript := preload("res://scripts/data_loader.gd")

@onready var title_label: Label = $Panel/Margin/Content/TitleLabel
@onready var cash_label: Label = $Panel/Margin/Content/CashLabel
@onready var info_label: Label = $Panel/Margin/Content/InfoLabel
@onready var inspection_buttons: VBoxContainer = $Panel/Margin/Content/InspectionButtons
@onready var result_label: Label = $Panel/Margin/Content/ResultPanel/Margin/ResultLabel
@onready var contract_button: Button = $Panel/Margin/Content/ActionRow/ContractButton
@onready var back_button: Button = $Panel/Margin/Content/ActionRow/BackButton

var game_state: GameState
var screen_container: Control
var tools: Array = []

func setup(next_game_state: GameState, next_screen_container: Control) -> void:
	game_state = next_game_state
	screen_container = next_screen_container

func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()

	tools = DataLoaderScript.load_json(DataLoaderScript.TOOLS_PATH, [])
	_render_detail()
	_render_inspection_buttons()
	contract_button.pressed.connect(_on_contract_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _render_detail() -> void:
	var pond := game_state.current_pond
	title_label.text = str(pond.get("name", "未选择鱼塘"))
	cash_label.text = "当前现金：%d 元" % game_state.cash
	info_label.text = "\n".join([
		"塘主报价：%d 元" % int(pond.get("quote_price", 0)),
		"鱼塘类型：%s" % pond.get("pond_type_name", "-"),
		"塘龄：%s（%d 年）" % [pond.get("age_label", "-"), int(pond.get("age_years", 0))],
		"面积：%s" % pond.get("area_label", "-"),
		"水色：%s" % pond.get("water_state", "-"),
		"传闻：%s" % pond.get("rumor", "-"),
		"风险标签：%s" % pond.get("risk_tag", "-")
	])

func _render_inspection_buttons() -> void:
	for child in inspection_buttons.get_children():
		child.queue_free()

	for tool in tools:
		var button := Button.new()
		button.text = "%s（%d 元）" % [tool["name"], int(tool["cost"])]
		button.custom_minimum_size = Vector2(0, 76)
		button.add_theme_font_size_override("font_size", 30)
		button.pressed.connect(_on_inspection_pressed.bind(tool))
		inspection_buttons.add_child(button)

func _on_inspection_pressed(tool: Dictionary) -> void:
	var pond := game_state.current_pond
	result_label.text = "%s：%s\n准确度：%d%%\n初步判断：%s，%s。" % [
		tool["name"],
		tool["description"],
		int(float(tool["accuracy"]) * 100.0),
		pond.get("water_state", "水色不明"),
		pond.get("risk_tag", "风险未知")
	]

func _on_contract_pressed() -> void:
	result_label.text = "承包功能将在下一步实现。"

func _on_back_pressed() -> void:
	UIController.show_pond_list(screen_container, game_state)
