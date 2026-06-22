extends Control

const UIKit := preload("res://scripts/ui_kit.gd")
const SaveSystem := preload("res://scripts/save_system.gd")

@onready var day_label: Label = $SafeArea/PageLayout/TopStatusBar/StatusRow/DayLabel
@onready var money_label: Label = $SafeArea/PageLayout/TopStatusBar/StatusRow/MoneyLabel
@onready var summary_bar: PanelContainer = $SafeArea/PageLayout/RecordSummaryBar
@onready var pond_count_stat: Label = $SafeArea/PageLayout/RecordSummaryBar/StatsRow/TotalPondCountStat
@onready var profit_loss_stat: Label = $SafeArea/PageLayout/RecordSummaryBar/StatsRow/TotalProfitLossStat
@onready var current_money_stat: Label = $SafeArea/PageLayout/RecordSummaryBar/StatsRow/CurrentMoneyStat
@onready var empty_state: PanelContainer = $SafeArea/PageLayout/ContentArea/EmptyState
@onready var go_pond_list_button: Button = $SafeArea/PageLayout/ContentArea/EmptyState/EmptyContent/GoPondListButton
@onready var record_scroll: ScrollContainer = $SafeArea/PageLayout/ContentArea/RecordListScroll
@onready var record_list: VBoxContainer = $SafeArea/PageLayout/ContentArea/RecordListScroll/RecordListContainer
@onready var bottom_button: Button = $SafeArea/PageLayout/BottomButton

var game_state: GameState
var screen_container: Control

func setup(next_game_state: GameState, next_screen_container: Control) -> void:
	game_state = next_game_state
	screen_container = next_screen_container

func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()
	go_pond_list_button.pressed.connect(_on_bottom_pressed)
	bottom_button.pressed.connect(_on_bottom_pressed)
	_render_page()

func _render_page() -> void:
	day_label.text = "第 %d 天" % game_state.day
	money_label.text = "本钱：%d 元" % game_state.cash
	bottom_button.text = "进入下一天" if _is_day_finished() else "返回今日鱼塘"

	for child in record_list.get_children():
		child.queue_free()

	var records := SaveSystem.load_settlement_records()
	_render_summary(records)
	summary_bar.visible = not records.is_empty()
	empty_state.visible = records.is_empty()
	record_scroll.visible = not records.is_empty()
	for index in range(records.size() - 1, -1, -1):
		record_list.add_child(_create_record_card(records[index]))

func _render_summary(records: Array[Dictionary]) -> void:
	var total_profit_loss := 0
	for record in records:
		total_profit_loss += int(record.get("net_profit", 0))

	pond_count_stat.text = "已包塘\n%d 口" % records.size()
	if total_profit_loss > 0:
		profit_loss_stat.text = "累计盈利\n+%d 元" % total_profit_loss
	elif total_profit_loss < 0:
		profit_loss_stat.text = "累计亏损\n%d 元" % total_profit_loss
	else:
		profit_loss_stat.text = "累计打平\n0 元"
	current_money_stat.text = "当前本钱\n%d 元" % game_state.cash

func _create_record_card(record: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "PondRecordCard"
	card.theme_type_variation = &"PondRecordCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.set_meta("future_texture", "record_card_bg.png")

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 0)
	card.add_child(content)

	var header := _create_record_header(record)
	content.add_child(header)

	var detail := _create_record_detail(record)
	content.add_child(detail)
	header.pressed.connect(_toggle_record.bind(header, detail))
	return card

func _create_record_header(record: Dictionary) -> Button:
	var header := Button.new()
	header.name = "RecordHeader"
	header.theme_type_variation = &"RecordHeaderButton"
	header.custom_minimum_size = Vector2(0, 118)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.set_meta("future_texture", "record_header_bg.png")

	var row := HBoxContainer.new()
	row.name = "RecordHeaderRow"
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	header.add_child(row)

	var arrow := Label.new()
	arrow.name = "ExpandArrow"
	arrow.text = "▶"
	arrow.custom_minimum_size = Vector2(42, 0)
	arrow.theme_type_variation = &"RecordHeaderMetaLabel"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(arrow)

	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	titles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(titles)

	var pond_name := Label.new()
	pond_name.name = "PondNameLabel"
	pond_name.text = str(record.get("pond_name", "未知鱼塘"))
	pond_name.theme_type_variation = &"RecordPondNameLabel"
	pond_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	pond_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.add_child(pond_name)

	var meta := Label.new()
	meta.name = "DayAndMethodLabel"
	meta.text = "第 %d 天 · %s · %s" % [
		int(record.get("day", 1)),
		str(record.get("finish_method", "本局结算")),
		_format_short_time(str(record.get("timestamp", "")))
	]
	meta.theme_type_variation = &"RecordHeaderMetaLabel"
	meta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titles.add_child(meta)

	var badge := Label.new()
	badge.name = "ProfitLossBadge"
	badge.custom_minimum_size = Vector2(164, 62)
	badge.text = _format_badge(int(record.get("net_profit", 0)))
	badge.theme_type_variation = _badge_theme(int(record.get("net_profit", 0)))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_meta("future_texture", "profit_loss_badge.png")
	row.add_child(badge)
	return header

func _create_record_detail(record: Dictionary) -> VBoxContainer:
	var detail := VBoxContainer.new()
	detail.name = "RecordDetail"
	detail.visible = false
	detail.add_theme_constant_override("separation", 14)
	detail.add_theme_constant_override("margin_top", 12)
	detail.add_theme_constant_override("margin_bottom", 16)

	detail.add_child(_create_result_summary_section(record))
	detail.add_child(_create_money_section("IncomeSection", "收入明细", [
		["卖鱼回款", int(record.get("fish_revenue", 0))],
		["转包回款", int(record.get("transfer_revenue", 0))],
		["卖一网回款", int(record.get("one_net_revenue", 0))],
		["其他收入", int(record.get("other_income", 0))],
		["收入合计", int(record.get("total_income", 0))]
	], true, record.get("catch_details", [])))
	detail.add_child(_create_money_section("ExpenseSection", "支出明细", [
		["承包费", int(record.get("contract_cost", 0))],
		["验塘费", int(record.get("inspection_cost", 0))],
		["下网作业费", int(record.get("fishing_cost", 0))],
		["运输费", int(record.get("transport_cost", 0))],
		["人工费", int(record.get("labor_cost", 0))],
		["抽水费", int(record.get("pump_cost", 0))],
		["其他支出", int(record.get("other_cost", 0))],
		["支出合计", int(record.get("total_expense", 0))]
	], false))
	detail.add_child(_create_final_ledger_section(record))
	return detail

func _create_result_summary_section(record: Dictionary) -> PanelContainer:
	var section := _create_section("ResultSummarySection", "本塘结果")
	var body := section.get_node("SectionMargin/SectionContent") as VBoxContainer
	body.add_child(_create_text_row("塘口", str(record.get("pond_name", "未知鱼塘"))))
	body.add_child(_create_text_row("结算方式", str(record.get("finish_method", "本局结算"))))
	body.add_child(_create_text_row("结算时间", _format_full_time(str(record.get("timestamp", "")))))
	body.add_child(_create_money_row("结算后本钱", int(record.get("money_after_settlement", 0)), false, true))
	return section

func _create_money_section(
	section_name: String,
	title: String,
	items: Array,
	is_income: bool,
	catch_details: Variant = []
) -> PanelContainer:
	var section := _create_section(section_name, title)
	var body := section.get_node("SectionMargin/SectionContent") as VBoxContainer
	if is_income and catch_details is Array and not catch_details.is_empty():
		body.add_child(_create_catch_summary(catch_details))
	for index in range(items.size()):
		var item: Array = items[index]
		body.add_child(_create_money_row(str(item[0]), int(item[1]), is_income, index == items.size() - 1))
	return section

func _create_final_ledger_section(record: Dictionary) -> PanelContainer:
	var section := _create_section("FinalLedgerSection", "最终账本", true)
	var body := section.get_node("SectionMargin/SectionContent") as VBoxContainer
	body.add_child(_create_money_row("总收入", int(record.get("total_income", 0)), true))
	body.add_child(_create_money_row("总支出", int(record.get("total_expense", 0)), false))
	body.add_child(_create_signed_money_row("本塘净赚亏", int(record.get("net_profit", 0)), true))
	body.add_child(_create_money_row("结算后本钱", int(record.get("money_after_settlement", 0)), false, true))
	return section

func _create_section(section_name: String, title: String, is_final := false) -> PanelContainer:
	var section := PanelContainer.new()
	section.name = section_name
	section.theme_type_variation = &"RecordFinalSectionPanel" if is_final else &"RecordDetailSectionPanel"
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.name = "SectionMargin"
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	section.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "SectionContent"
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var title_label := Label.new()
	title_label.text = title
	title_label.theme_type_variation = &"RecordSectionTitleLabel"
	content.add_child(title_label)
	return section

func _create_text_row(key: String, value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var key_label := _make_row_label(key, HORIZONTAL_ALIGNMENT_LEFT)
	key_label.custom_minimum_size = Vector2(190, 0)
	row.add_child(key_label)
	var value_label := _make_row_label(value, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(value_label)
	return row

func _create_money_row(key: String, amount: int, is_income: bool, emphasized := false) -> HBoxContainer:
	var value := "+%d 元" % amount if is_income else "%d 元" % amount
	return _create_ledger_row(key, value, emphasized)

func _create_signed_money_row(key: String, amount: int, emphasized := false) -> HBoxContainer:
	var value := "%+d 元" % amount if amount != 0 else "0 元"
	return _create_ledger_row(key, value, emphasized)

func _create_ledger_row(key: String, value: String, emphasized: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	var key_label := _make_row_label(key, HORIZONTAL_ALIGNMENT_LEFT)
	if emphasized:
		key_label.theme_type_variation = &"RecordLedgerTotalLabel"
	row.add_child(key_label)
	var value_label := _make_row_label(value, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if emphasized:
		value_label.theme_type_variation = &"RecordLedgerTotalLabel"
	row.add_child(value_label)
	return row

func _make_row_label(text: String, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"RecordBodyLabel"
	label.horizontal_alignment = alignment
	return label

func _create_catch_summary(catch_details: Array) -> Label:
	var parts: Array[String] = []
	for item_variant in catch_details:
		if item_variant is Dictionary:
			var item := item_variant as Dictionary
			parts.append("%s %d 斤 / %d 元" % [
				str(item.get("name", "鱼获")),
				int(item.get("weight_jin", 0)),
				int(item.get("income", 0))
			])
	var label := _make_row_label("鱼获：%s" % "；".join(parts), HORIZONTAL_ALIGNMENT_LEFT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _toggle_record(header: Button, detail: VBoxContainer) -> void:
	detail.visible = not detail.visible
	var arrow := header.get_node("RecordHeaderRow/ExpandArrow") as Label
	arrow.text = "▼" if detail.visible else "▶"

func _format_badge(net_profit: int) -> String:
	if net_profit > 0:
		return "赚 %d 元" % net_profit
	if net_profit < 0:
		return "亏 %d 元" % absi(net_profit)
	return "打平"

func _badge_theme(net_profit: int) -> StringName:
	if net_profit > 0:
		return &"ProfitBadgePositive"
	if net_profit < 0:
		return &"ProfitBadgeNegative"
	return &"ProfitBadgeNeutral"

func _format_short_time(timestamp: String) -> String:
	var parts := timestamp.split(" ", false)
	if parts.size() >= 2:
		return str(parts[1]).substr(0, 5)
	return "时间不详"

func _format_full_time(timestamp: String) -> String:
	return timestamp if not timestamp.is_empty() else "时间不详"

func _is_day_finished() -> bool:
	return game_state.settlement_recorded and not game_state.current_pond.is_empty()

func _on_bottom_pressed() -> void:
	if _is_day_finished():
		game_state.advance_to_next_day()
		UIController.show_pond_list(screen_container, game_state, true)
	else:
		UIController.show_pond_list(screen_container, game_state)
