extends Control

const DataLoaderScript := preload("res://scripts/data_loader.gd")
const InspectionSystemScript := preload("res://scripts/inspection_system.gd")
const UIKit := preload("res://scripts/ui_kit.gd")

const CARD_NAMES := {
	"observe": "InspectionOptionCard_MianCe",
	"fish_finder": "InspectionOptionCard_TanYu",
	"master": "InspectionOptionCard_LaoShiFu"
}

@onready var day_label: Label = $SafeArea/PageLayout/TopStatusBar/StatusRow/DayLabel
@onready var money_label: Label = $SafeArea/PageLayout/TopStatusBar/StatusRow/MoneyLabel
@onready var inspection_cost_label: Label = $SafeArea/PageLayout/TopStatusBar/StatusRow/InspectionCostLabel
@onready var pond_name_label: Label = $SafeArea/PageLayout/ContentScroll/Content/PondSummaryCard/SummaryContent/HeaderRow/PondNameLabel
@onready var price_badge: Label = $SafeArea/PageLayout/ContentScroll/Content/PondSummaryCard/SummaryContent/HeaderRow/PriceBadge
@onready var tag_row: HBoxContainer = $SafeArea/PageLayout/ContentScroll/Content/PondSummaryCard/SummaryContent/TagRow
@onready var known_info_grid: GridContainer = $SafeArea/PageLayout/ContentScroll/Content/PondSummaryCard/SummaryContent/KnownInfoGrid
@onready var risk_hint_label: Label = $SafeArea/PageLayout/ContentScroll/Content/PondSummaryCard/SummaryContent/RiskHintLabel
@onready var content_scroll: ScrollContainer = $SafeArea/PageLayout/ContentScroll
@onready var inspection_cards: VBoxContainer = $SafeArea/PageLayout/ContentScroll/Content/InspectionSection/InspectionCards
@onready var summary_numbers_label: Label = $SafeArea/PageLayout/ContentScroll/Content/DecisionSummaryCard/Summary/SummaryNumbersLabel
@onready var reserve_hint_label: Label = $SafeArea/PageLayout/ContentScroll/Content/DecisionSummaryCard/Summary/ReserveHintLabel
@onready var give_up_button: Button = $SafeArea/PageLayout/BottomDecisionBar/DecisionButtons/GiveUpButton
@onready var commit_button: Button = $SafeArea/PageLayout/BottomDecisionBar/DecisionButtons/CommitButton

var game_state: GameState
var screen_container: Control
var pond: Dictionary = {}
var tools: Array = []
var inspection_system := InspectionSystemScript.new()
var confirm_overlay: Control
var confirm_dialog: PanelContainer
var confirm_title_label: Label
var confirm_summary_label: Label
var confirm_message_label: Label
var confirm_cancel_button: Button
var confirm_ok_button: Button
var confirm_dialog_mode := ""
var confirm_dialog_preferred_height := 560


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
	_create_confirm_dialog()
	_render_page()
	give_up_button.pressed.connect(_on_give_up_pressed)
	commit_button.pressed.connect(_on_commit_pressed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _render_page() -> void:
	_render_status()
	_render_pond_summary()
	_render_inspection_cards()
	_render_decision_summary()


func _render_status() -> void:
	day_label.text = "第 %d 天" % game_state.day
	money_label.text = "本钱：%d 元" % game_state.cash
	inspection_cost_label.text = "已花验塘费：%d 元" % game_state.inspection_cost_total


func _render_pond_summary() -> void:
	pond_name_label.text = str(pond.get("name", "未选择鱼塘"))
	price_badge.text = "%d 元" % int(pond.get("quote_price", 0))

	_clear_children(tag_row)
	_add_tag(str(pond.get("pond_type_name", "未知塘型")))
	_add_tag(str(pond.get("area_label", "未知大小")))

	_clear_children(known_info_grid)
	_add_info_block("水深", "%s  %.1f 米" % [pond.get("depth_label", "-"), float(pond.get("depth_meters", 0.0))])
	_add_info_block("塘龄", "%d 年" % int(pond.get("age_years", 0)))
	_add_info_block("水色", str(pond.get("water_state", "-")))

	risk_hint_label.text = "塘边消息：%s\n原始风险：%s" % [pond.get("rumor", "暂无消息"), pond.get("risk_tag", "暂时看不准")]


func _add_tag(text: String) -> void:
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"PondTagPanel"
	var label := Label.new()
	label.theme_type_variation = &"PondChipLabel"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(label)
	tag_row.add_child(chip)


func _add_info_block(key_text: String, value_text: String) -> void:
	var block := PanelContainer.new()
	block.name = "%sInfoBlock" % key_text
	block.custom_minimum_size = Vector2(0, 92)
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.theme_type_variation = &"InspectInfoBlockPanel"

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	block.add_child(content)

	var key_label := Label.new()
	key_label.theme_type_variation = &"PondStatKeyLabel"
	key_label.text = key_text
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(key_label)

	var value_label := Label.new()
	value_label.theme_type_variation = &"PondStatValueLabel"
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(value_label)
	known_info_grid.add_child(block)


func _render_inspection_cards() -> void:
	var previous_scroll := content_scroll.scroll_vertical
	_clear_children(inspection_cards)

	for tool_variant in tools:
		var tool := tool_variant as Dictionary
		inspection_cards.add_child(_build_inspection_card(_inspection_option_data(tool)))

	_restore_content_scroll.call_deferred(previous_scroll)


func _inspection_option_data(tool: Dictionary) -> Dictionary:
	var tool_id := str(tool.get("id", ""))
	var is_used := game_state.has_inspection_result(tool_id)
	var result := _decode_inspection_result(game_state.get_inspection_feedback(tool_id)) if is_used else {}
	return {
		"id": tool_id,
		"name": str(tool.get("name", "验塘")),
		"cost": int(tool.get("cost", 0)),
		"short_desc": str(tool.get("short_desc", tool.get("description", "多看一眼塘口情况。"))),
		"is_used": is_used,
		"result_headline": str(result.get("headline", "线索已经记下")),
		"result_detail": str(result.get("detail", "验塘结果已记录。")),
		"can_afford": game_state.can_pay(int(tool.get("cost", 0)))
	}


func _build_inspection_card(option: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var tool_id := str(option.get("id", ""))
	card.name = str(CARD_NAMES.get(tool_id, "InspectionOptionCard_%s" % tool_id))
	card.custom_minimum_size = Vector2(0, 190 if bool(option.get("is_used", false)) else 178)
	card.theme_type_variation = &"InspectionUsedCard" if bool(option.get("is_used", false)) else &"InspectionOptionCard"
	card.set_meta("_future_texture_slot", "inspection_method_card_%s" % tool_id)

	var content := VBoxContainer.new()
	content.name = "CardContent"
	content.add_theme_constant_override("separation", 10)
	card.add_child(content)

	var header := HBoxContainer.new()
	header.name = "HeaderRow"
	header.add_theme_constant_override("separation", 14)
	content.add_child(header)

	var method_label := Label.new()
	method_label.name = "MethodNameLabel"
	method_label.theme_type_variation = &"InspectMethodNameLabel"
	method_label.text = str(option.get("name", "验塘"))
	method_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(method_label)

	if bool(option.get("is_used", false)):
		var used_badge := Label.new()
		used_badge.name = "UsedBadge"
		used_badge.theme_type_variation = &"InspectUsedBadge"
		used_badge.text = "已验"
		used_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		used_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_child(used_badge)

		var headline := Label.new()
		headline.name = "ResultHeadlineLabel"
		headline.theme_type_variation = &"InspectResultHeadlineLabel"
		headline.text = str(option.get("result_headline", "线索已经记下"))
		headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(headline)

		var detail := Label.new()
		detail.name = "ResultDetailLabel"
		detail.theme_type_variation = &"InspectResultDetailLabel"
		detail.text = str(option.get("result_detail", "验塘结果已记录。"))
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(detail)
	else:
		var cost_badge := Label.new()
		cost_badge.name = "CostBadge"
		cost_badge.theme_type_variation = &"InspectFreeBadge" if int(option.get("cost", 0)) == 0 else &"InspectCostBadge"
		cost_badge.text = "免费" if int(option.get("cost", 0)) == 0 else "%d 元" % int(option.get("cost", 0))
		cost_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cost_badge.set_meta("_future_texture_slot", "inspection_cost_badge")
		header.add_child(cost_badge)

		var desc := Label.new()
		desc.name = "ShortDescLabel"
		desc.theme_type_variation = &"InspectOptionDescLabel"
		desc.text = str(option.get("short_desc", "多看一眼塘口情况。"))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(desc)

		var action := Button.new()
		action.name = "ActionButton"
		action.custom_minimum_size = Vector2(0, 68)
		action.theme_type_variation = &"InspectClueButton"
		action.disabled = not bool(option.get("can_afford", true))
		action.text = "钱不够" if action.disabled else ("免费查看" if int(option.get("cost", 0)) == 0 else "花 %d 元买线索" % int(option.get("cost", 0)))
		action.pressed.connect(_on_inspection_pressed.bind(option))
		content.add_child(action)

	return card


func _on_inspection_pressed(option: Dictionary) -> void:
	var tool_id := str(option.get("id", ""))
	if game_state.has_inspection_result(tool_id):
		return

	var cost := int(option.get("cost", 0))
	if not game_state.pay_inspection_cost(cost):
		_render_page()
		return

	var tool := _find_tool(tool_id)
	var result_data := inspection_system.generate_result_data(tool, pond)
	game_state.set_inspection_result(tool_id, JSON.stringify(result_data))
	_render_page()


func _find_tool(tool_id: String) -> Dictionary:
	for tool_variant in tools:
		var tool := tool_variant as Dictionary
		if str(tool.get("id", "")) == tool_id:
			return tool
	return {"id": tool_id, "name": "验塘", "cost": 0}


func _decode_inspection_result(stored_text: String) -> Dictionary:
	var parsed = JSON.parse_string(stored_text)
	if parsed is Dictionary and parsed.has("headline"):
		return parsed

	var lines := stored_text.split("\n", false)
	if lines.is_empty():
		return {"headline": "线索已经记下", "detail": "验塘结果已记录。"}
	var headline := str(lines[0]).trim_suffix("结果：").strip_edges()
	var details: Array[String] = []
	for index in range(1, lines.size()):
		details.append(str(lines[index]))
	return {
		"headline": headline if not headline.is_empty() else "线索已经记下",
		"detail": " ".join(details) if not details.is_empty() else stored_text
	}


func _render_decision_summary() -> void:
	var preview := game_state.get_contract_preview(pond)
	var quote_price := int(preview.get("quote_price", 0))
	var remaining_cash := int(preview.get("remaining_cash", 0))
	var can_contract := bool(preview.get("can_contract", false))

	summary_numbers_label.text = "已花验塘费：%d 元\n承包价：%d 元\n承包后剩余：%d 元" % [game_state.inspection_cost_total, quote_price, remaining_cash]
	reserve_hint_label.text = "提醒：承包后还要预留捞鱼、抽水、鱼车和运输成本" if can_contract else "钱不够承包：包下后留不出最低开工资金"
	reserve_hint_label.theme_type_variation = &"InspectReserveHintLabel" if can_contract else &"InspectWarningLabel"
	commit_button.text = "承包 %d 元" % quote_price
	commit_button.disabled = not can_contract


func _on_give_up_pressed() -> void:
	if game_state.inspection_cost_total <= 0:
		_return_to_pond_list()
		return

	confirm_dialog_mode = "give_up"
	confirm_title_label.text = "确定放弃这口塘？"
	confirm_summary_label.text = "已花验塘费：%d 元" % game_state.inspection_cost_total
	confirm_message_label.text = "已花的验塘费不会退回，确定放弃这口塘吗？"
	confirm_cancel_button.text = "继续验塘"
	confirm_ok_button.text = "确定放弃"
	_show_confirm_dialog(470)


func _on_commit_pressed() -> void:
	var preview := game_state.get_contract_preview(pond)
	if not bool(preview.get("can_contract", false)):
		return

	confirm_dialog_mode = "commit"
	confirm_title_label.text = "确定承包%s？" % str(pond.get("name", "这口塘"))
	confirm_summary_label.text = "承包后剩余：%d 元" % int(preview.get("remaining_cash", 0))
	confirm_message_label.text = "承包价：%d 元\n已花验塘费：%d 元\n承包后剩余：%d 元\n\n后续还需要支付捞鱼、抽水、鱼车和运输等成本。" % [int(preview.get("quote_price", 0)), game_state.inspection_cost_total, int(preview.get("remaining_cash", 0))]
	confirm_cancel_button.text = "再想想"
	confirm_ok_button.text = "确定承包"
	_show_confirm_dialog(610)


func _create_confirm_dialog() -> void:
	var modal := UIKit.create_modal_layer(self, "ConfirmDialog")
	confirm_overlay = modal["overlay"] as Control
	confirm_dialog = modal["card"] as PanelContainer

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	confirm_dialog.add_child(content)

	confirm_title_label = Label.new()
	confirm_title_label.theme_type_variation = &"InspectDialogTitleLabel"
	confirm_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(confirm_title_label)

	confirm_summary_label = Label.new()
	confirm_summary_label.theme_type_variation = &"InspectDialogSummaryLabel"
	confirm_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(confirm_summary_label)

	confirm_message_label = Label.new()
	confirm_message_label.theme_type_variation = &"InspectDialogBodyLabel"
	confirm_message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	confirm_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	confirm_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(confirm_message_label)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 18)
	content.add_child(action_row)

	confirm_cancel_button = Button.new()
	confirm_cancel_button.custom_minimum_size = Vector2(0, UIKit.MODAL_ACTION_HEIGHT)
	confirm_cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_cancel_button.theme_type_variation = &"InspectGiveUpButton"
	confirm_cancel_button.pressed.connect(_close_confirm_dialog)
	action_row.add_child(confirm_cancel_button)

	confirm_ok_button = Button.new()
	confirm_ok_button.custom_minimum_size = Vector2(0, UIKit.MODAL_ACTION_HEIGHT)
	confirm_ok_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_ok_button.theme_type_variation = &"PondActionButton"
	confirm_ok_button.pressed.connect(_on_confirm_dialog_accepted)
	action_row.add_child(confirm_ok_button)


func _show_confirm_dialog(preferred_height: int) -> void:
	confirm_dialog_preferred_height = preferred_height
	UIKit.show_modal(self, confirm_overlay, confirm_dialog, 0.86, preferred_height, Vector2i(360, 360), Vector2i(860, 760))


func _close_confirm_dialog() -> void:
	UIKit.hide_modal(confirm_overlay)


func _on_confirm_dialog_accepted() -> void:
	var accepted_mode := confirm_dialog_mode
	_close_confirm_dialog()
	if accepted_mode == "give_up":
		_return_to_pond_list()
	elif accepted_mode == "commit":
		if game_state.contract_pond(pond):
			UIController.show_after_contract_choice(screen_container, game_state)


func _return_to_pond_list() -> void:
	UIController.show_pond_list(screen_container, game_state)


func _on_viewport_size_changed() -> void:
	if confirm_overlay == null or not confirm_overlay.visible:
		return
	UIKit.layout_modal(self, confirm_dialog, 0.86, confirm_dialog_preferred_height, Vector2i(360, 360), Vector2i(860, 760))


func _restore_content_scroll(scroll_value: int) -> void:
	await get_tree().process_frame
	content_scroll.scroll_vertical = scroll_value


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
