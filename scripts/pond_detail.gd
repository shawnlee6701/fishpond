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
var confirm_content: VBoxContainer
var confirm_title_label: Label
var confirm_subtitle_label: Label
var confirm_summary_label: Label
var confirm_message_label: Label
var confirm_bill_rows: VBoxContainer
var confirm_current_money_value: Label
var confirm_inspection_spent_row: Control
var confirm_inspection_spent_value: Label
var confirm_pond_price_value: Label
var confirm_remaining_value: Label
var confirm_min_working_capital_value: Label
var confirm_status_box: PanelContainer
var confirm_status_title_label: Label
var confirm_status_desc_label: Label
var confirm_warning_label: Label
var confirm_cancel_button: Button
var confirm_ok_button: Button
var confirm_dialog_mode := ""
var confirm_dialog_preferred_height := 720
var confirm_dialog_submitting := false


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
	commit_button.disabled = false


func _on_give_up_pressed() -> void:
	if game_state.inspection_cost_total <= 0:
		_return_to_pond_list()
		return

	confirm_dialog_mode = "give_up"
	confirm_dialog_submitting = false
	confirm_title_label.text = "确定放弃这口塘？"
	confirm_subtitle_label.text = "已花的钱不回头，回去重新挑塘。"
	confirm_summary_label.text = "已花验塘费：%d 元" % game_state.inspection_cost_total
	confirm_message_label.text = "已花的验塘费不会退回，确定放弃这口塘吗？"
	_set_contract_bill_visible(false)
	confirm_cancel_button.text = "继续验塘"
	confirm_ok_button.text = "确定放弃"
	confirm_ok_button.disabled = false
	_show_confirm_dialog(470)


func _on_commit_pressed() -> void:
	var preview := game_state.get_contract_preview(pond)
	confirm_dialog_mode = "commit"
	confirm_dialog_submitting = false
	_populate_contract_bill(preview)
	_show_confirm_dialog(680)


func _create_confirm_dialog() -> void:
	var modal := UIKit.create_modal_layer(self, "ConfirmContractDialog")
	confirm_overlay = modal["overlay"] as Control
	confirm_dialog = modal["card"] as PanelContainer
	var dim_overlay := modal["mask"] as Control
	if dim_overlay != null:
		dim_overlay.name = "DimOverlay"
	confirm_dialog.name = "DialogCard"
	confirm_dialog.theme_type_variation = &"ContractDialogCard"
	confirm_dialog.set_meta("_future_texture_slot", "contract_dialog_bg.png")

	confirm_content = VBoxContainer.new()
	confirm_content.name = "DialogContent"
	confirm_content.add_theme_constant_override("separation", 10)
	confirm_dialog.add_child(confirm_content)

	confirm_title_label = Label.new()
	confirm_title_label.name = "TitleLabel"
	confirm_title_label.theme_type_variation = &"InspectDialogTitleLabel"
	confirm_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm_content.add_child(confirm_title_label)

	confirm_subtitle_label = Label.new()
	confirm_subtitle_label.name = "SubtitleLabel"
	confirm_subtitle_label.theme_type_variation = &"ContractDialogSubtitleLabel"
	confirm_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm_content.add_child(confirm_subtitle_label)

	confirm_summary_label = Label.new()
	confirm_summary_label.name = "BalanceHighlight"
	confirm_summary_label.theme_type_variation = &"InspectDialogSummaryLabel"
	confirm_summary_label.custom_minimum_size = Vector2(0, 66)
	confirm_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	confirm_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm_summary_label.set_meta("_future_texture_slot", "balance_highlight_badge")
	confirm_content.add_child(confirm_summary_label)

	var body_scroll := ScrollContainer.new()
	body_scroll.name = "DialogBodyScroll"
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.follow_focus = true
	confirm_content.add_child(body_scroll)

	var body_content := VBoxContainer.new()
	body_content.name = "DialogBody"
	body_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_content.add_theme_constant_override("separation", 8)
	body_scroll.add_child(body_content)

	confirm_bill_rows = VBoxContainer.new()
	confirm_bill_rows.name = "BillRows"
	confirm_bill_rows.add_theme_constant_override("separation", 6)
	body_content.add_child(confirm_bill_rows)

	confirm_current_money_value = _add_contract_bill_row("CurrentMoneyRow", "手上钱")
	confirm_inspection_spent_value = _add_contract_bill_row("InspectionSpentRow", "已花验塘费")
	confirm_inspection_spent_row = confirm_inspection_spent_value.get_parent().get_parent() as Control
	confirm_pond_price_value = _add_contract_bill_row("PondPriceRow", "塘主要价", true)
	confirm_remaining_value = _add_contract_bill_row("RemainingAfterContractRow", "包下后剩余")
	confirm_min_working_capital_value = _add_contract_bill_row("MinWorkingCapitalRow", "最低开工资金")

	confirm_status_box = PanelContainer.new()
	confirm_status_box.name = "StatusBox"
	confirm_status_box.theme_type_variation = &"ContractStatusOkPanel"
	body_content.add_child(confirm_status_box)

	var status_content := VBoxContainer.new()
	status_content.name = "StatusContent"
	status_content.add_theme_constant_override("separation", 4)
	confirm_status_box.add_child(status_content)

	confirm_status_title_label = Label.new()
	confirm_status_title_label.name = "StatusTitleLabel"
	confirm_status_title_label.theme_type_variation = &"ContractStatusTitleLabel"
	confirm_status_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_content.add_child(confirm_status_title_label)

	confirm_status_desc_label = Label.new()
	confirm_status_desc_label.name = "StatusDescLabel"
	confirm_status_desc_label.theme_type_variation = &"ContractStatusDescLabel"
	confirm_status_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_content.add_child(confirm_status_desc_label)

	confirm_warning_label = Label.new()
	confirm_warning_label.name = "WarningLabel"
	confirm_warning_label.theme_type_variation = &"InspectWarningLabel"
	confirm_warning_label.text = "承包后还要支付下网、人工、抽水、鱼车等成本。"
	confirm_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_content.add_child(confirm_warning_label)

	confirm_message_label = Label.new()
	confirm_message_label.name = "MessageLabel"
	confirm_message_label.theme_type_variation = &"InspectDialogBodyLabel"
	confirm_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	confirm_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_content.add_child(confirm_message_label)

	var action_row := HBoxContainer.new()
	action_row.name = "ButtonRow"
	action_row.add_theme_constant_override("separation", 18)
	confirm_content.add_child(action_row)

	confirm_cancel_button = Button.new()
	confirm_cancel_button.name = "CancelButton"
	confirm_cancel_button.custom_minimum_size = Vector2(0, 96)
	confirm_cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_cancel_button.theme_type_variation = &"ContractSecondaryButton"
	confirm_cancel_button.set_meta("_future_texture_button", "button_secondary.png")
	confirm_cancel_button.pressed.connect(_close_confirm_dialog)
	action_row.add_child(confirm_cancel_button)

	confirm_ok_button = Button.new()
	confirm_ok_button.name = "ConfirmButton"
	confirm_ok_button.custom_minimum_size = Vector2(0, 96)
	confirm_ok_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_ok_button.theme_type_variation = &"PondActionButton"
	confirm_ok_button.set_meta("_future_texture_button", "button_confirm.png")
	confirm_ok_button.pressed.connect(_on_confirm_dialog_accepted)
	action_row.add_child(confirm_ok_button)


func _add_contract_bill_row(row_name: String, label_text: String, is_negative := false) -> Label:
	var row := PanelContainer.new()
	row.name = row_name
	row.theme_type_variation = &"ContractBillRowPanel"
	row.custom_minimum_size = Vector2(0, 46)
	confirm_bill_rows.add_child(row)

	var row_content := HBoxContainer.new()
	row_content.name = "RowContent"
	row_content.add_theme_constant_override("separation", 12)
	row.add_child(row_content)

	var name_label := Label.new()
	name_label.name = "Label"
	name_label.theme_type_variation = &"ContractBillNameLabel"
	name_label.text = label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row_content.add_child(name_label)

	var value_label := Label.new()
	value_label.name = "Value"
	value_label.theme_type_variation = &"ContractBillNegativeValueLabel" if is_negative else &"ContractBillValueLabel"
	value_label.custom_minimum_size = Vector2(260, 0)
	value_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row_content.add_child(value_label)
	return value_label


func _populate_contract_bill(preview: Dictionary) -> void:
	var current_money := int(preview.get("current_cash", game_state.cash))
	var pond_price := int(preview.get("quote_price", pond.get("quote_price", 0)))
	var inspection_spent := game_state.inspection_cost_total
	var min_working_capital := int(preview.get("min_working_capital", game_state.min_working_capital))
	var remaining_after_contract := current_money - pond_price
	var can_contract := remaining_after_contract >= min_working_capital

	_set_contract_bill_visible(true)
	confirm_title_label.text = "盘一盘再承包"
	confirm_subtitle_label.text = "承包后还要留钱开工，别一把梭哈。"
	confirm_summary_label.text = "包下后剩余：%d 元" % remaining_after_contract
	confirm_current_money_value.text = "%d 元" % current_money
	confirm_inspection_spent_value.text = "%d 元（不退）" % inspection_spent if inspection_spent > 0 else "0 元"
	confirm_inspection_spent_row.visible = inspection_spent > 0
	confirm_pond_price_value.text = "-%d 元" % pond_price
	confirm_remaining_value.text = "%d 元" % remaining_after_contract
	confirm_min_working_capital_value.text = "%d 元" % min_working_capital
	confirm_status_box.theme_type_variation = &"ContractStatusOkPanel" if can_contract else &"ContractStatusBadPanel"
	confirm_status_title_label.text = "资金状态：够开工" if can_contract else "资金状态：余额不足"
	confirm_status_desc_label.text = "能包，但后面还要支付下网、人工、抽水和鱼车成本。" if can_contract else "包下后连基本开工资金都不够，建议先别包。"
	confirm_warning_label.text = "承包后还要支付下网、人工、抽水、鱼车等成本。"
	confirm_message_label.text = ""
	confirm_cancel_button.text = "再想想"
	confirm_ok_button.text = "就包这塘" if can_contract else "钱不够"
	confirm_ok_button.disabled = not can_contract


func _set_contract_bill_visible(is_visible: bool) -> void:
	if confirm_bill_rows != null:
		confirm_bill_rows.visible = is_visible
	if confirm_status_box != null:
		confirm_status_box.visible = is_visible
	if confirm_warning_label != null:
		confirm_warning_label.visible = is_visible
	if confirm_message_label != null:
		confirm_message_label.visible = not is_visible


func _show_confirm_dialog(preferred_height: int) -> void:
	confirm_dialog_preferred_height = preferred_height
	confirm_overlay.modulate.a = 0.0
	UIKit.show_modal(self, confirm_overlay, confirm_dialog, 0.9, preferred_height, Vector2i(360, 360), Vector2i(980, 820))
	var tween := create_tween()
	tween.tween_property(confirm_overlay, "modulate:a", 1.0, 0.12)


func _close_confirm_dialog() -> void:
	confirm_dialog_submitting = false
	UIKit.hide_modal(confirm_overlay)


func _on_confirm_dialog_accepted() -> void:
	if confirm_dialog_submitting:
		return
	var accepted_mode := confirm_dialog_mode
	if accepted_mode == "give_up":
		confirm_dialog_submitting = true
		_close_confirm_dialog()
		_return_to_pond_list()
	elif accepted_mode == "commit":
		var preview := game_state.get_contract_preview(pond)
		if not bool(preview.get("can_contract", false)):
			_populate_contract_bill(preview)
			return
		confirm_dialog_submitting = true
		confirm_ok_button.disabled = true
		confirm_ok_button.text = "承包中"
		_close_confirm_dialog()
		if game_state.contract_pond(pond):
			UIController.show_after_contract_choice(screen_container, game_state)


func _return_to_pond_list() -> void:
	UIController.show_pond_list(screen_container, game_state)


func _on_viewport_size_changed() -> void:
	if confirm_overlay == null or not confirm_overlay.visible:
		return
	UIKit.layout_modal(self, confirm_dialog, 0.9, confirm_dialog_preferred_height, Vector2i(360, 360), Vector2i(980, 820))


func _restore_content_scroll(scroll_value: int) -> void:
	await get_tree().process_frame
	content_scroll.scroll_vertical = scroll_value


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
