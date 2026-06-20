extends Control

const DataLoaderScript := preload("res://scripts/data_loader.gd")
const InspectionSystemScript := preload("res://scripts/inspection_system.gd")
const UIKit := preload("res://scripts/ui_kit.gd")
const CONTRACT_POPUP_TEXTURE := preload("res://Design/Popup/popup_clean.png")

@onready var title_label: Label = $Panel/Content/TitleLabel
@onready var cash_label: Label = $CashLabel
@onready var info_label: Label = $Panel/Content/InfoLabel
@onready var quote_label: Label = $Panel/Content/QuoteLabel
@onready var inspection_scroll: ScrollContainer = $Panel/Content/InspectionScroll
@onready var inspection_buttons: VBoxContainer = $Panel/Content/InspectionScroll/InspectionButtons
@onready var contract_button: Button = $ActionRow/ContractButton
@onready var back_button: Button = $ActionRow/BackButton
@onready var panel: PanelContainer = $Panel

var game_state: GameState
var screen_container: Control
var pond: Dictionary = {}
var tools: Array = []
var inspection_system := InspectionSystemScript.new()
var contract_overlay: Control
var contract_dialog: PanelContainer
var contract_dialog_message: Label
var contract_dialog_ok_button: Button
var contract_dialog_preferred_height := 500
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
	_apply_ui_frame()
	_render_detail()
	_render_inspection_buttons()
	contract_button.pressed.connect(_on_contract_pressed)
	back_button.pressed.connect(_on_back_pressed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _apply_ui_frame() -> void:
	UIKit.apply_root(self)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	UIKit.style_page_title(title_label)
	UIKit.style_top_status(cash_label)
	UIKit.style_label(info_label, "body_dark")
	UIKit.style_label(quote_label, "body_dark")
	UIKit.style_button(back_button, "ghost")
	UIKit.style_button(contract_button, "primary")
	title_label.add_theme_font_size_override("font_size", 48)
	quote_label.add_theme_font_size_override("font_size", 24)

func _render_detail() -> void:
	title_label.text = str(pond.get("name", "未选择鱼塘"))
	quote_label.text = "%d 元" % int(pond.get("quote_price", 0))
	_update_cash_label()
	info_label.text = "\n".join([
		"要价 %d 元 | %s | %s" % [int(pond.get("quote_price", 0)), pond.get("pond_type_name", "-"), pond.get("area_label", "-")],
		"水深 %s（%.1f 米） | 塘龄 %d 年" % [pond.get("depth_label", "-"), float(pond.get("depth_meters", 0.0)), int(pond.get("age_years", 0))],
		"水色：%s" % pond.get("water_state", "-"),
		"塘边：%s" % pond.get("rumor", "-"),
		"风险：%s" % pond.get("risk_tag", "-")
	])

func _render_inspection_buttons() -> void:
	var previous_scroll := inspection_scroll.scroll_vertical
	for child in inspection_buttons.get_children():
		child.queue_free()
	inspection_feedback_labels = {}

	for tool in tools:
		var tool_id := str(tool.get("id", ""))
		var section := VBoxContainer.new()
		section.add_theme_constant_override("separation", 6)
		inspection_buttons.add_child(section)

		var button := Button.new()
		button.text = "%s  |  %d 元" % [tool["name"], int(tool["cost"])]
		button.custom_minimum_size = Vector2(0, 78)
		UIKit.style_button(button, "secondary")
		button.disabled = game_state.has_inspection_result(tool_id)
		if button.disabled:
			button.text = "%s（已验）" % tool["name"]
		button.pressed.connect(_on_inspection_pressed.bind(tool))
		section.add_child(button)

		var feedback := Label.new()
		feedback.text = game_state.get_inspection_feedback(tool_id)
		feedback.visible = not feedback.text.is_empty()
		feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		feedback.add_theme_font_size_override("font_size", 19)
		feedback.add_theme_color_override("font_color", UIKit.MUTED)
		section.add_child(feedback)
		inspection_feedback_labels[tool_id] = feedback

	_restore_inspection_scroll.call_deferred(previous_scroll)

func _restore_inspection_scroll(scroll_value: int) -> void:
	await get_tree().process_frame
	inspection_scroll.scroll_vertical = scroll_value

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

func _on_contract_pressed() -> void:
	_show_contract_dialog()

func _on_back_pressed() -> void:
	UIController.show_pond_list(screen_container, game_state)

func _update_cash_label() -> void:
	cash_label.text = UIKit.format_run_status(game_state.day, game_state.cash, "验塘费 %d" % game_state.inspection_cost_total)

func _append_system_message(message: String) -> void:
	game_state.add_inspection_result(message)
	contract_dialog_message.text = message
	contract_dialog_ok_button.disabled = true
	_show_contract_popup(360)

func _update_inspection_feedback(tool_id: String) -> void:
	if not inspection_feedback_labels.has(tool_id):
		return

	var feedback := inspection_feedback_labels[tool_id] as Label
	if feedback == null:
		return

	feedback.text = game_state.get_inspection_feedback(tool_id)
	feedback.visible = not feedback.text.is_empty()

func _create_contract_dialog() -> void:
	var modal := UIKit.create_modal_layer(self, "ContractModal", CONTRACT_POPUP_TEXTURE)
	contract_overlay = modal["overlay"] as Control
	contract_dialog = modal["card"] as PanelContainer

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	contract_dialog.add_child(content)

	var dialog_title := Label.new()
	dialog_title.text = "盘一盘再承包"
	UIKit.style_modal_title(dialog_title)
	content.add_child(dialog_title)

	contract_dialog_message = Label.new()
	contract_dialog_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contract_dialog_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	contract_dialog_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contract_dialog_message.add_theme_font_size_override("font_size", 22)
	contract_dialog_message.add_theme_color_override("font_color", Color("392d24"))
	var message_scroll := ScrollContainer.new()
	message_scroll.name = "MessageScroll"
	message_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	message_scroll.add_child(contract_dialog_message)
	content.add_child(message_scroll)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 18)
	content.add_child(action_row)

	var cancel_button := Button.new()
	cancel_button.text = "再想想"
	cancel_button.custom_minimum_size = Vector2(0, 76)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIKit.style_button(cancel_button, "ghost")
	cancel_button.pressed.connect(_close_contract_dialog)
	action_row.add_child(cancel_button)

	contract_dialog_ok_button = Button.new()
	contract_dialog_ok_button.text = "就包这塘"
	contract_dialog_ok_button.custom_minimum_size = Vector2(0, 76)
	contract_dialog_ok_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIKit.style_button(contract_dialog_ok_button, "primary")
	contract_dialog_ok_button.pressed.connect(_on_contract_dialog_confirmed)
	action_row.add_child(contract_dialog_ok_button)

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

	contract_dialog_message.text = "\n".join(lines)
	contract_dialog_ok_button.disabled = not can_contract
	_show_contract_popup(500)

func _show_contract_popup(preferred_height: int) -> void:
	contract_dialog_preferred_height = preferred_height
	UIKit.show_modal(self, contract_overlay, contract_dialog, 0.82, preferred_height, Vector2i(320, 320), Vector2i(820, 760))

func _close_contract_dialog() -> void:
	UIKit.hide_modal(contract_overlay)

func _on_viewport_size_changed() -> void:
	if contract_overlay == null or not contract_overlay.visible:
		return
	UIKit.layout_modal(self, contract_dialog, 0.82, contract_dialog_preferred_height, Vector2i(320, 320), Vector2i(820, 760))

func _on_contract_dialog_confirmed() -> void:
	_close_contract_dialog()
	_on_contract_confirmed()

func _on_contract_confirmed() -> void:
	if not game_state.contract_pond(pond):
		_append_system_message("包下后不够最低开工资金，这塘先不能接。")
		return

	UIController.show_after_contract_choice(screen_container, game_state)
