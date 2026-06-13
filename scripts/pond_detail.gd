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
var pond: Dictionary = {}
var tools: Array = []
var inspection_system := InspectionSystemScript.new()
var contract_dialog: ConfirmationDialog

func setup(next_game_state: GameState, next_screen_container: Control, next_pond: Dictionary = {}) -> void:
	game_state = next_game_state
	screen_container = next_screen_container
	pond = next_pond

func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()
	if pond.is_empty():
		pond = game_state.current_pond

	tools = DataLoaderScript.load_json(DataLoaderScript.TOOLS_PATH, [])
	_create_contract_dialog()
	_render_detail()
	_render_inspection_buttons()
	contract_button.pressed.connect(_on_contract_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _render_detail() -> void:
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
	var cost := int(tool.get("cost", 0))
	if not game_state.pay_inspection_cost(cost):
		_append_system_message("现金不足，不能使用%s（需要 %d 元）。" % [tool.get("name", "该验塘方式"), cost])
		return

	var result_text := inspection_system.generate_result(tool, pond)
	game_state.add_inspection_result(result_text)
	_update_cash_label()
	_render_inspection_results()

func _on_contract_pressed() -> void:
	_show_contract_dialog()

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

func _create_contract_dialog() -> void:
	contract_dialog = ConfirmationDialog.new()
	contract_dialog.title = "确认承包"
	contract_dialog.ok_button_text = "确认承包"
	contract_dialog.cancel_button_text = "取消"
	contract_dialog.dialog_text = ""
	contract_dialog.confirmed.connect(_on_contract_confirmed)
	add_child(contract_dialog)

func _show_contract_dialog() -> void:
	var preview := game_state.get_contract_preview(pond)
	var can_contract := bool(preview.get("can_contract", false))
	var lines := [
		"当前现金：%d 元" % int(preview.get("current_cash", 0)),
		"塘主报价：%d 元" % int(preview.get("quote_price", 0)),
		"承包后剩余资金：%d 元" % int(preview.get("remaining_cash", 0)),
		"最低开工资金：%d 元" % int(preview.get("min_working_capital", 0)),
		"是否可以承包：%s" % ("可以" if can_contract else "不可以")
	]
	if not can_contract:
		lines.append("")
		lines.append("承包后剩余资金不足，无法支付基础作业成本，不能承包。")

	contract_dialog.dialog_text = "\n".join(lines)
	contract_dialog.get_ok_button().disabled = not can_contract
	contract_dialog.popup_centered(Vector2i(760, 430))

func _on_contract_confirmed() -> void:
	if not game_state.contract_pond(pond):
		_append_system_message("承包后剩余资金不足，无法支付基础作业成本，不能承包。")
		return

	UIController.show_after_contract_choice(screen_container, game_state)
