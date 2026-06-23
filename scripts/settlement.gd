extends Control

const UIKit := preload("res://scripts/ui_kit.gd")
const SaveSystem := preload("res://scripts/save_system.gd")

const FISH_KING_ID := "fish_king"
const FISH_KING_NAME := "青背老塘王"
const BANKRUPT_CASH_THRESHOLD := 3000

class SettlementVisualPlaceholder:
	extends Control

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var paper := Rect2(Vector2(size.x * 0.18, size.y * 0.14), Vector2(size.x * 0.64, size.y * 0.70))
		draw_rect(paper, Color(1.0, 0.94, 0.74, 1.0), true)
		draw_rect(paper, Color(0.42, 0.29, 0.14, 1.0), false, 5.0)
		for index in range(4):
			var y := paper.position.y + paper.size.y * (0.22 + float(index) * 0.14)
			draw_line(Vector2(paper.position.x + paper.size.x * 0.15, y), Vector2(paper.position.x + paper.size.x * 0.72, y), Color(0.57, 0.42, 0.22, 0.76), 3.0, true)
		var coin_center := Vector2(size.x * 0.68, size.y * 0.66)
		draw_circle(coin_center, minf(size.x, size.y) * 0.10, Color(0.92, 0.62, 0.20, 1.0))
		draw_arc(coin_center, minf(size.x, size.y) * 0.10, 0.0, TAU, 40, Color(0.35, 0.22, 0.09, 1.0), 4.0, true)
		_draw_fish(Vector2(size.x * 0.38, size.y * 0.65), size.x * 0.16, Color(0.10, 0.34, 0.27, 0.86))

	func _draw_fish(center: Vector2, length: float, color: Color) -> void:
		_draw_ellipse(Rect2(center - Vector2(length * 0.30, length * 0.13), Vector2(length * 0.60, length * 0.26)), color)
		var tail := PackedVector2Array([
			center + Vector2(length * 0.32, 0.0),
			center + Vector2(length * 0.52, -length * 0.14),
			center + Vector2(length * 0.52, length * 0.14)
		])
		draw_colored_polygon(tail, color)

	func _draw_ellipse(rect: Rect2, color: Color) -> void:
		var points := PackedVector2Array()
		var center := rect.get_center()
		var radius := rect.size * 0.5
		for index in range(40):
			var angle := float(index) / 40.0 * TAU
			points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		draw_colored_polygon(points, color)

var game_state: GameState
var screen_container: Control
var safe_area: MarginContainer
var day_label: Label
var cash_label: Label
var visual_host: Control
var result_title_label: Label
var profit_highlight_label: Label
var fish_king_panel: PanelContainer
var sections_box: VBoxContainer
var next_day_button: Button

func setup(next_game_state: GameState, next_screen_container: Control) -> void:
	game_state = next_game_state
	screen_container = next_screen_container

func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()
	_build_ui()
	SaveSystem.record_settlement(game_state)
	_render()

func _build_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	custom_minimum_size = UIKit.DESIGN_SIZE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.184314, 0.419608, 0.309804, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	safe_area = MarginContainer.new()
	safe_area.name = "SafeArea"
	add_child(safe_area)
	UIKit.set_safe_panel(safe_area, int(UIKit.PAGE_SAFE_X), int(UIKit.PAGE_TOP), -int(UIKit.PAGE_SAFE_X), -int(UIKit.PAGE_BOTTOM))

	var layout := VBoxContainer.new()
	layout.name = "PageLayout"
	layout.add_theme_constant_override("separation", 16)
	safe_area.add_child(layout)

	var top_status := PanelContainer.new()
	top_status.name = "TopStatusBar"
	top_status.custom_minimum_size = Vector2(0, 64)
	UIKit.style_card(top_status, UIKit.GOLD)
	layout.add_child(top_status)

	var status_row := HBoxContainer.new()
	status_row.name = "StatusRow"
	status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_status.add_child(status_row)
	day_label = _make_status_label("第 1 天")
	cash_label = _make_status_label("本钱：0 元")
	status_row.add_child(day_label)
	status_row.add_child(cash_label)

	var scroll := ScrollContainer.new()
	scroll.name = "ContentScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	sections_box = VBoxContainer.new()
	sections_box.name = "Content"
	sections_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sections_box.add_theme_constant_override("separation", 16)
	scroll.add_child(sections_box)

	visual_host = SettlementVisualPlaceholder.new()
	visual_host.name = "SettlementVisualPlaceholder"
	visual_host.custom_minimum_size = Vector2(0, 250)
	visual_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual_host.set_meta("_future_texture_slot", "settlement_visual.png")
	# Future art pass: replace this drawn placeholder with settlement_visual.png.
	sections_box.add_child(visual_host)

	var header := VBoxContainer.new()
	header.name = "FinalResultHeader"
	header.add_theme_constant_override("separation", 10)
	sections_box.add_child(header)
	result_title_label = Label.new()
	result_title_label.name = "FinalResultTitleLabel"
	UIKit.style_page_title(result_title_label)
	header.add_child(result_title_label)
	profit_highlight_label = Label.new()
	profit_highlight_label.name = "FinalProfitLossHighlight"
	profit_highlight_label.custom_minimum_size = Vector2(0, 76)
	header.add_child(profit_highlight_label)

	fish_king_panel = _create_fish_king_panel()
	sections_box.add_child(fish_king_panel)

	next_day_button = Button.new()
	next_day_button.name = "NextButton"
	next_day_button.custom_minimum_size = Vector2(0, UIKit.PAGE_ACTION_HEIGHT)
	next_day_button.set_meta("_future_texture_button", "button_primary.png")
	UIKit.style_button(next_day_button, "primary")
	next_day_button.pressed.connect(_on_next_day_pressed)
	layout.add_child(next_day_button)

func _make_status_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIKit.style_label(label, "top_status")
	return label

func _render() -> void:
	var ledger := _get_pond_run_state()
	var net_profit := int(ledger.get("pond_net_profit", 0))
	day_label.text = "第 %d 天" % game_state.day
	cash_label.text = "本钱：%d 元" % game_state.cash
	if net_profit > 0:
		result_title_label.text = "本塘最终盈利"
		profit_highlight_label.text = "+%d 元" % net_profit
		UIKit.style_highlight_label(profit_highlight_label, "positive")
	elif net_profit < 0:
		result_title_label.text = "本塘最终亏损"
		profit_highlight_label.text = "%d 元" % net_profit
		UIKit.style_highlight_label(profit_highlight_label, "negative")
	else:
		result_title_label.text = "本塘打平"
		profit_highlight_label.text = "0 元"
		UIKit.style_highlight_label(profit_highlight_label, "gold")

	_render_fish_king_panel(_is_fish_king_result() and game_state.cash >= BANKRUPT_CASH_THRESHOLD)
	_render_sections(ledger)
	next_day_button.text = "进入第 %d 天" % (game_state.day + 1)

func _get_pond_run_state() -> Dictionary:
	var contract_cost := int(game_state.current_pond.get("contract_total_cost", game_state.current_pond.get("quote_price", 0)))
	var fish_revenue := game_state.fish_income
	var transfer_revenue := game_state.transfer_income
	var one_net_revenue := game_state.one_net_income
	var other_income := 0
	var total_income := fish_revenue + transfer_revenue + one_net_revenue + other_income
	var inspection_cost := game_state.inspection_cost_total
	var fishing_cost := game_state.work_cost
	var transport_cost := 0
	var labor_cost := 0
	var pump_cost := 0
	var other_cost := 0
	var total_expense := contract_cost + inspection_cost + fishing_cost + transport_cost + labor_cost + pump_cost + other_cost
	var finish_method := _normalize_finish_method(str(game_state.last_result.get("title", "自然结束")))
	return {
		"pond_name": str(game_state.current_pond.get("name", "未知鱼塘")),
		"pond_price": contract_cost,
		"inspection_spent": inspection_cost,
		"fishing_cost_total": fishing_cost,
		"transport_cost_total": transport_cost,
		"labor_cost_total": labor_cost,
		"pump_cost_total": pump_cost,
		"fish_catches": game_state.catch_details.duplicate(true),
		"fish_revenue_total": fish_revenue,
		"transfer_revenue": transfer_revenue,
		"one_net_revenue": one_net_revenue,
		"other_income": other_income,
		"other_cost": other_cost,
		"total_income": total_income,
		"total_expense": total_expense,
		"pond_net_profit": total_income - total_expense,
		"money_after_settlement": game_state.cash,
		"finish_method": finish_method
	}

func _render_sections(ledger: Dictionary) -> void:
	for child in sections_box.get_children():
		if child not in [visual_host, result_title_label.get_parent(), fish_king_panel]:
			sections_box.remove_child(child)
			child.queue_free()
	sections_box.add_child(_create_summary_card(ledger))
	sections_box.add_child(_create_income_section(ledger))
	sections_box.add_child(_create_expense_section(ledger))
	sections_box.add_child(_create_final_ledger_section(ledger))

func _create_summary_card(ledger: Dictionary) -> PanelContainer:
	var card := _make_section_card("SettlementSummaryCard", UIKit.GREEN)
	card.set_meta("_future_texture_slot", "settlement_card_bg.png")
	var box := _section_box(card)
	box.add_child(_make_money_row("塘口", str(ledger.get("pond_name", "未知鱼塘"))))
	box.add_child(_make_money_row("收尾方式", str(ledger.get("finish_method", "自然结束"))))
	box.add_child(_make_money_row("结算后本钱", "%d 元" % int(ledger.get("money_after_settlement", 0))))
	return card

func _create_income_section(ledger: Dictionary) -> PanelContainer:
	var card := _make_section_card("IncomeSection", UIKit.GREEN)
	var box := _section_box(card)
	box.add_child(_section_title("收入明细"))
	box.add_child(_section_title("鱼获收入"))
	var catches := Array(ledger.get("fish_catches", []))
	if catches.is_empty():
		box.add_child(_make_money_row("鱼获", "0 元"))
	else:
		for item_variant in catches:
			var item := Dictionary(item_variant)
			box.add_child(_make_money_row(str(item.get("name", "未知鱼获")), "%d 斤 × %d 元/斤 = %d 元" % [int(item.get("weight_jin", 0)), int(item.get("unit_price", 0)), int(item.get("income", 0))]))
	box.add_child(_section_title("其他收入"))
	_add_nonzero_or_zero_row(box, "卖一网回款", int(ledger.get("one_net_revenue", 0)))
	_add_nonzero_or_zero_row(box, "转包回款", int(ledger.get("transfer_revenue", 0)))
	_add_nonzero_or_zero_row(box, "其他收入", int(ledger.get("other_income", 0)))
	box.add_child(_make_money_row("总收入", "+%d 元" % int(ledger.get("total_income", 0)), true, int(ledger.get("total_income", 0))))
	return card

func _create_expense_section(ledger: Dictionary) -> PanelContainer:
	var card := _make_section_card("ExpenseSection", UIKit.RED)
	var box := _section_box(card)
	box.add_child(_section_title("支出明细"))
	_add_nonzero_or_zero_row(box, "承包费", int(ledger.get("pond_price", 0)), true)
	_add_nonzero_or_zero_row(box, "验塘费", int(ledger.get("inspection_spent", 0)), true)
	_add_nonzero_or_zero_row(box, "下网作业费", int(ledger.get("fishing_cost_total", 0)), true)
	_add_nonzero_or_zero_row(box, "运输费", int(ledger.get("transport_cost_total", 0)), true)
	_add_nonzero_or_zero_row(box, "人工费", int(ledger.get("labor_cost_total", 0)), true)
	_add_nonzero_or_zero_row(box, "抽水费", int(ledger.get("pump_cost_total", 0)), true)
	_add_nonzero_or_zero_row(box, "其他支出", int(ledger.get("other_cost", 0)), true)
	box.add_child(_make_money_row("总支出", "-%d 元" % int(ledger.get("total_expense", 0)), true, -int(ledger.get("total_expense", 0))))
	return card

func _create_final_ledger_section(ledger: Dictionary) -> PanelContainer:
	var card := _make_section_card("FinalLedgerSection", UIKit.GOLD)
	var box := _section_box(card)
	box.add_child(_section_title("最终公式"))
	box.add_child(_make_money_row("总收入", "+%d 元" % int(ledger.get("total_income", 0)), false, int(ledger.get("total_income", 0))))
	box.add_child(_make_money_row("总支出", "-%d 元" % int(ledger.get("total_expense", 0)), false, -int(ledger.get("total_expense", 0))))
	box.add_child(_make_money_row("本塘净赚亏", _format_signed(int(ledger.get("pond_net_profit", 0))), true, int(ledger.get("pond_net_profit", 0))))
	box.add_child(_make_money_row("结算后本钱", "%d 元" % int(ledger.get("money_after_settlement", 0))))
	return card

func _make_section_card(card_name: String, accent: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = card_name
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIKit.style_card(card, accent)
	return card

func _section_box(card: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.name = "Rows"
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	return box

func _section_title(text: String) -> Label:
	return UIKit.make_label(text, UIKit.FONT_SECTION, UIKit.GREEN, HORIZONTAL_ALIGNMENT_LEFT)

func _add_nonzero_or_zero_row(box: VBoxContainer, name_text: String, amount: int, expense := false) -> void:
	if amount == 0:
		box.add_child(_make_money_row(name_text, "0 元"))
	else:
		box.add_child(_make_money_row(name_text, ("-%d 元" if expense else "+%d 元") % amount, false, -amount if expense else amount))

func _make_money_row(name_text: String, value_text: String, important := false, signed_amount := 0) -> PanelContainer:
	var row := PanelContainer.new()
	row.name = name_text.replace(" ", "") + "Row"
	row.custom_minimum_size = Vector2(0, 52 if not important else 62)
	row.add_theme_stylebox_override("panel", UIKit.make_style(Color(1.0, 0.96, 0.84, 0.90), Color(0.61, 0.45, 0.25, 0.36), 8, 1, false))
	var content := HBoxContainer.new()
	content.name = "RowContent"
	content.add_theme_constant_override("separation", 12)
	row.add_child(content)
	var name_label := UIKit.make_label("%s：" % name_text, UIKit.FONT_BODY, UIKit.INK, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(name_label)
	var value_label := UIKit.make_label(value_text, UIKit.FONT_BODY if not important else UIKit.FONT_IMPORTANT, _money_color(signed_amount), HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.name = "Value"
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.custom_minimum_size = Vector2(300, 0)
	content.add_child(value_label)
	return row

func _money_color(signed_amount: int) -> Color:
	if signed_amount > 0:
		return UIKit.GREEN
	if signed_amount < 0:
		return UIKit.RED
	return UIKit.INK

func _format_signed(amount: int) -> String:
	if amount > 0:
		return "+%d 元" % amount
	if amount < 0:
		return "%d 元" % amount
	return "0 元"

func _normalize_finish_method(method: String) -> String:
	if method == "转包结算":
		return "转包"
	if method == "抽干结算":
		return "抽干结算"
	if method == "一网结果":
		return "自然结束"
	return method

func _create_fish_king_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "FishKingPanel"
	panel.visible = false
	panel.custom_minimum_size = Vector2(0, 220)
	return panel

func _is_fish_king_result() -> bool:
	if game_state.fish_result_id == FISH_KING_ID:
		return true
	for item in game_state.catch_details:
		if str(item.get("id", "")) == FISH_KING_ID:
			return true
	return str(game_state.last_result.get("fish_result_id", "")) == FISH_KING_ID

func _render_fish_king_panel(is_fish_king: bool) -> void:
	fish_king_panel.visible = is_fish_king
	for child in fish_king_panel.get_children():
		child.queue_free()
	if not is_fish_king:
		return
	var detail := _get_fish_king_catch_detail()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	fish_king_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	box.add_child(UIKit.make_label("水面猛地一翻，一条大青鱼被拖出水面。", UIKit.FONT_SECONDARY, Color(0.35, 0.18, 0.02), HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIKit.make_label("%s出现！" % FISH_KING_NAME, 42, Color(0.24, 0.08, 0.0), HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIKit.make_label("重量：%d 斤  完整度：%d%%  估值：%d 元" % [int(detail.get("weight_jin", 0)), int(detail.get("integrity", 0)), int(detail.get("income", 0))], UIKit.FONT_BODY, Color(0.28, 0.12, 0.0), HORIZONTAL_ALIGNMENT_CENTER))
	fish_king_panel.add_theme_stylebox_override("panel", UIKit.make_style(Color(1.0, 0.76, 0.18), Color(0.98, 0.92, 0.42), 18, 6, true))

func _get_fish_king_catch_detail() -> Dictionary:
	for item in game_state.catch_details:
		if str(item.get("id", "")) == FISH_KING_ID:
			return item
	return {}

func _on_next_day_pressed() -> void:
	game_state.advance_to_next_day()
	UIController.show_pond_list(screen_container, game_state, true)
