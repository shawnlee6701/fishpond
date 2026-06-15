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
var inspection_feedback_labels: Dictionary = {}

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
		"塘主要价：%d 元" % int(pond.get("quote_price", 0)),
		"塘型：%s" % pond.get("pond_type_name", "-"),
		"塘龄：%s（%d 年）" % [pond.get("age_label", "-"), int(pond.get("age_years", 0))],
		"水面：%s" % pond.get("area_label", "-"),
		"水深：%s（%.1f 米）" % [pond.get("depth_label", "-"), float(pond.get("depth_meters", 0.0))],
		"水色看着：%s" % pond.get("water_state", "-"),
		"塘边说法：%s" % pond.get("rumor", "-"),
		"心里先记一笔：%s" % pond.get("risk_tag", "-")
	])

func _render_inspection_buttons() -> void:
	for child in inspection_buttons.get_children():
		child.queue_free()
	inspection_feedback_labels = {}

	for tool in tools:
		var tool_id := str(tool.get("id", ""))
		var section := VBoxContainer.new()
		section.add_theme_constant_override("separation", 8)
		inspection_buttons.add_child(section)

		var button := Button.new()
		button.text = "%s（%d 元）" % [tool["name"], int(tool["cost"])]
		button.custom_minimum_size = Vector2(0, 76)
		button.add_theme_font_size_override("font_size", 30)
		button.disabled = game_state.has_inspection_result(tool_id)
		if button.disabled:
			button.text = "%s（已验）" % tool["name"]
		button.pressed.connect(_on_inspection_pressed.bind(tool))
		section.add_child(button)

		var feedback := Label.new()
		feedback.text = game_state.get_inspection_feedback(tool_id)
		feedback.visible = not feedback.text.is_empty()
		feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		feedback.add_theme_font_size_override("font_size", 26)
		section.add_child(feedback)
		inspection_feedback_labels[tool_id] = feedback

func _on_inspection_pressed(tool: Dictionary) -> void:
	var tool_id := str(tool.get("id", ""))
	if game_state.has_inspection_result(tool_id):
		return

	var cost := int(tool.get("cost", 0))
	if not game_state.pay_inspection_cost(cost):
		game_state.set_inspection_feedback(tool_id, "本钱不够，先别请%s了（需要 %d 元）。" % [tool.get("name", "这个验塘方式"), cost])
		_update_inspection_feedback(tool_id)
		return

	var result_text := inspection_system.generate_result(tool, pond)
	game_state.set_inspection_result(tool_id, result_text)
	_update_cash_label()
	_render_inspection_buttons()
	_render_inspection_results()

func _on_contract_pressed() -> void:
	_show_contract_dialog()

func _on_back_pressed() -> void:
	UIController.show_pond_list(screen_container, game_state)

func _update_cash_label() -> void:
	cash_label.text = "手上本钱：%d 元    已花验塘费：%d 元" % [game_state.cash, game_state.inspection_cost_total]

func _render_inspection_results() -> void:
	if game_state.inspection_results.is_empty():
		result_label.text = "验塘只能帮你缩小判断，不会直接告诉你赚还是亏。每种方式本局用一次。"
	else:
		result_label.text = "\n\n".join(game_state.inspection_results)

func _append_system_message(message: String) -> void:
	game_state.add_inspection_result(message)
	_render_inspection_results()

func _update_inspection_feedback(tool_id: String) -> void:
	if not inspection_feedback_labels.has(tool_id):
		return

	var feedback := inspection_feedback_labels[tool_id] as Label
	if feedback == null:
		return

	feedback.text = game_state.get_inspection_feedback(tool_id)
	feedback.visible = not feedback.text.is_empty()

func _create_contract_dialog() -> void:
	contract_dialog = ConfirmationDialog.new()
	contract_dialog.title = "盘一盘再承包"
	contract_dialog.ok_button_text = "就包这塘"
	contract_dialog.cancel_button_text = "再想想"
	contract_dialog.dialog_text = ""
	contract_dialog.confirmed.connect(_on_contract_confirmed)
	add_child(contract_dialog)

func _show_contract_dialog() -> void:
	var preview := game_state.get_contract_preview(pond)
	var can_contract := bool(preview.get("can_contract", false))
	var lines := [
		"手上本钱：%d 元" % int(preview.get("current_cash", 0)),
		"塘主要价：%d 元（确认后立刻扣）" % int(preview.get("quote_price", 0)),
		"包下后剩余：%d 元" % int(preview.get("remaining_cash", 0)),
		"最低开工资金：%d 元（留给下网、请工、周转）" % int(preview.get("min_working_capital", 0)),
		"能不能包：%s" % ("能包，后面还够开工。" if can_contract else "不能包，包完就没钱开工。")
	]
	if not can_contract:
		lines.append("")
		lines.append("做水产生意不能把本钱一次压光，先换一口塘看看。")

	contract_dialog.dialog_text = "\n".join(lines)
	contract_dialog.get_ok_button().disabled = not can_contract
	contract_dialog.popup_centered(Vector2i(760, 430))

func _on_contract_confirmed() -> void:
	if not game_state.contract_pond(pond):
		_append_system_message("包下后不够最低开工资金，这塘先不能接。")
		return

	UIController.show_after_contract_choice(screen_container, game_state)
