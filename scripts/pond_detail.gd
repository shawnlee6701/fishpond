extends Control

const DataLoaderScript := preload("res://scripts/data_loader.gd")
const InspectionSystemScript := preload("res://scripts/inspection_system.gd")

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
var inspection_system := InspectionSystemScript.new()

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
	_update_cash_label()
	_render_inspection_results()
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
	var cost := int(tool.get("cost", 0))
	if not game_state.pay_inspection_cost(cost):
		_append_system_message("现金不足，不能使用%s（需要 %d 元）。" % [tool.get("name", "该验塘方式"), cost])
		return

	var result_text := inspection_system.generate_result(tool, pond)
	game_state.add_inspection_result(result_text)
	_update_cash_label()
	_render_inspection_results()

func _on_contract_pressed() -> void:
	result_label.text = "承包功能将在下一步实现。"

func _on_back_pressed() -> void:
	UIController.show_pond_list(screen_container, game_state)

func _update_cash_label() -> void:
	cash_label.text = "当前现金：%d 元    验塘成本：%d 元" % [game_state.cash, game_state.inspection_cost_total]

func _render_inspection_results() -> void:
	if game_state.inspection_results.is_empty():
		result_label.text = "请选择一种验塘方式。"
	else:
		result_label.text = "\n\n".join(game_state.inspection_results)

func _append_system_message(message: String) -> void:
	game_state.add_inspection_result(message)
	_render_inspection_results()
