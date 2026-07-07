extends Control

const UIKit := preload("res://scripts/ui_kit.gd")
const SaveSystem := preload("res://scripts/save_system.gd")

const FISH_KING_ID := "fish_king"
const FISH_KING_NAME := "青背老塘王"
const BANKRUPT_CASH_THRESHOLD := 3000

const _INCOME_KEYS: Array[String] = ["fish_revenue_total", "transfer_revenue", "one_net_revenue", "other_income"]
const _INCOME_LABELS: Dictionary[String, String] = {
	"fish_revenue_total": "鱼获厚",
	"transfer_revenue": "转包巧",
	"one_net_revenue": "一网快",
	"other_income": "杂项有"
}
const _COST_KEYS: Array[String] = ["pond_price", "inspection_spent", "fishing_cost_total", "transport_cost_total", "labor_cost_total", "pump_cost_total", "other_cost"]
const _COST_LABELS: Dictionary[String, String] = {
	"pond_price": "包价高",
	"inspection_spent": "验塘贵",
	"fishing_cost_total": "下网贵",
	"transport_cost_total": "运费高",
	"labor_cost_total": "人工贵",
	"pump_cost_total": "抽水贵",
	"other_cost": "杂项支"
}

const SETTLEMENT_VISUAL_TEXTURE: Texture2D = preload("res://assets/effects/settlement_visual.png")
const SETTLEMENT_CARD_BG_TEXTURE: Texture2D = preload("res://assets/ui/settlement_card_bg.png")
const PROFIT_LOSS_BADGE_TEXTURE: Texture2D = preload("res://assets/ui/profit_loss_badge.png")
const BALANCE_HIGHLIGHT_BG_TEXTURE: Texture2D = preload("res://assets/ui/balance_highlight_bg.png")
const BUTTON_ACCEPT_TEXTURE: Texture2D = preload("res://assets/buttons/button_accept.png")

const FISH_TEXTURES: Dictionary[String, Texture2D] = {
	"small_fish": preload("res://assets/fish/fish_small.png"),
	"normal_fish": preload("res://assets/fish/fish_normal.png"),
	"big_fish": preload("res://assets/fish/fish_big.png"),
	"fish_king": preload("res://assets/fish/fish_king.png")
}

const FISH_ICON_HEIGHTS: Dictionary[String, int] = {
	"small_fish": 24,
	"normal_fish": 32,
	"big_fish": 40,
	"fish_king": 56
}

func _apply_panel_texture(panel: PanelContainer, texture: Texture2D, margin: int = 24, texture_margin: int = 0) -> void:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	if texture_margin > 0:
		style.texture_margin_left = texture_margin
		style.texture_margin_top = texture_margin
		style.texture_margin_right = texture_margin
		style.texture_margin_bottom = texture_margin
	panel.add_theme_stylebox_override("panel", style)


func _apply_label_texture(label: Label, texture: Texture2D, margin_h: int = 14, margin_v: int = 4, texture_margin: int = 0) -> void:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.content_margin_left = margin_h
	style.content_margin_top = margin_v
	style.content_margin_right = margin_h
	style.content_margin_bottom = margin_v
	if texture_margin > 0:
		style.texture_margin_left = texture_margin
		style.texture_margin_top = texture_margin
		style.texture_margin_right = texture_margin
		style.texture_margin_bottom = texture_margin
	label.add_theme_stylebox_override("normal", style)


func _apply_button_texture(button: Button, texture: Texture2D) -> void:
	var patch := 20
	var normal := _make_nine_patch_style(texture, patch, Color(1.0, 1.0, 1.0, 1.0))
	var hover := _make_nine_patch_style(texture, patch, Color(1.12, 1.12, 1.12, 1.0))
	var pressed := _make_nine_patch_style(texture, patch, Color(0.88, 0.88, 0.88, 1.0))
	var disabled := _make_nine_patch_style(texture, patch, Color(0.65, 0.65, 0.65, 0.85))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)


func _make_nine_patch_style(texture: Texture2D, patch: int, modulate: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = modulate
	style.texture_margin_left = patch
	style.texture_margin_top = patch
	style.texture_margin_right = patch
	style.texture_margin_bottom = patch
	return style


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
	_play_sfx("settlement_stamp")
	_render()

func _build_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	custom_minimum_size = UIKit.DESIGN_SIZE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.184314, 0.419608, 0.309804, 0.0)
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
	_apply_panel_texture(top_status, BALANCE_HIGHLIGHT_BG_TEXTURE, 14, 20)
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
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	layout.add_child(scroll)

	sections_box = VBoxContainer.new()
	sections_box.name = "Content"
	sections_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sections_box.add_theme_constant_override("separation", 16)
	scroll.add_child(sections_box)

	visual_host = TextureRect.new()
	visual_host.name = "SettlementVisual"
	visual_host.texture = SETTLEMENT_VISUAL_TEXTURE
	visual_host.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	visual_host.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual_host.custom_minimum_size = Vector2(0, 250)
	visual_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	profit_highlight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	profit_highlight_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(profit_highlight_label)

	fish_king_panel = _create_fish_king_panel()
	sections_box.add_child(fish_king_panel)

	next_day_button = Button.new()
	next_day_button.name = "NextButton"
	next_day_button.custom_minimum_size = Vector2(0, UIKit.PAGE_ACTION_HEIGHT)
	_apply_button_texture(next_day_button, BUTTON_ACCEPT_TEXTURE)
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
	cash_label.text = "兜里：%d 元" % game_state.cash
	if net_profit > 0:
		result_title_label.text = "这口塘，你赚了"
		profit_highlight_label.text = "净赚 %d 元" % net_profit
		UIKit.style_highlight_label(profit_highlight_label, "positive")
		_apply_label_texture(profit_highlight_label, PROFIT_LOSS_BADGE_TEXTURE, 20, 6, 16)
	elif net_profit < 0:
		result_title_label.text = "这口塘，栽了"
		profit_highlight_label.text = "亏了 %d 元" % net_profit
		UIKit.style_highlight_label(profit_highlight_label, "negative")
		_apply_label_texture(profit_highlight_label, PROFIT_LOSS_BADGE_TEXTURE, 20, 6, 16)
	else:
		result_title_label.text = "这口塘，白忙一场"
		profit_highlight_label.text = "不赚不赔，交个学费"
		UIKit.style_highlight_label(profit_highlight_label, "gold")
		_apply_label_texture(profit_highlight_label, PROFIT_LOSS_BADGE_TEXTURE, 20, 6, 16)

	_render_fish_king_panel(_is_fish_king_result() and game_state.cash >= BANKRUPT_CASH_THRESHOLD)
	_render_sections(ledger)
	next_day_button.text = "走，第 %d 天" % (game_state.day + 1)

	if UIKit.animations_enabled:
		var tone := "positive" if net_profit > 0 else "negative" if net_profit < 0 else "gold"
		UIKit.animate_emphasis(profit_highlight_label, tone)
		_spawn_settlement_sparkles.call_deferred(tone)

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
	sections_box.add_child(_create_boss_review_section(ledger))
	sections_box.add_child(_create_final_ledger_section(ledger))

func _create_summary_card(ledger: Dictionary) -> PanelContainer:
	var card := _make_section_card("SettlementSummaryCard", UIKit.GREEN)
	card.set_meta("_future_texture_slot", "settlement_card_bg.png")
	var box := _section_box(card)
	box.add_child(_make_money_row("哪口塘", str(ledger.get("pond_name", "未知鱼塘"))))
	box.add_child(_make_money_row("怎么收的", str(ledger.get("finish_method", "自然结束"))))
	box.add_child(_make_money_row("现在兜里", "%d 元" % int(ledger.get("money_after_settlement", 0))))
	return card

func _create_income_section(ledger: Dictionary) -> PanelContainer:
	var card := _make_section_card("IncomeSection", UIKit.GREEN)
	var box := _section_box(card)
	box.add_child(_section_title("进账"))
	box.add_child(_section_title("卖鱼"))
	var catches := Array(ledger.get("fish_catches", []))
	if catches.is_empty():
		box.add_child(_make_money_row("鱼获", "0 元"))
	else:
		for item_variant in catches:
			var item := Dictionary(item_variant)
			box.add_child(_create_fish_catch_row(item))
	box.add_child(_make_money_row("卖鱼合计", "+%d 元" % int(ledger.get("fish_revenue_total", 0)), true, int(ledger.get("fish_revenue_total", 0))))
	box.add_child(_section_title("其他进账"))
	var one_net_revenue := int(ledger.get("one_net_revenue", 0))
	var transfer_revenue := int(ledger.get("transfer_revenue", 0))
	var other_income := int(ledger.get("other_income", 0))
	var has_other_income := one_net_revenue > 0 or transfer_revenue > 0 or other_income > 0
	if has_other_income:
		_add_positive_income_row(box, "卖一网入账", one_net_revenue)
		_add_positive_income_row(box, "转手入账", transfer_revenue)
		_add_positive_income_row(box, "其他入账", other_income)
		box.add_child(_make_money_row("进账合计", "+%d 元" % int(ledger.get("total_income", 0)), true, int(ledger.get("total_income", 0))))
	else:
		box.add_child(_make_money_row("其他进账", "无"))
	return card

func _create_fish_catch_row(item: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "FishCatchRow_%s" % str(item.get("id", "unknown"))
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	var fish_id := str(item.get("id", "normal_fish"))
	var texture: Texture2D = FISH_TEXTURES.get(fish_id, FISH_TEXTURES["normal_fish"])
	var icon := TextureRect.new()
	icon.name = "FishIcon"
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(0, int(FISH_ICON_HEIGHTS.get(fish_id, 32)))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var label := UIKit.make_label(
		"%s：%d 斤 × %d 元/斤 = %d 元" % [
			str(item.get("name", "未知鱼获")),
			int(item.get("weight_jin", 0)),
			int(item.get("unit_price", 0)),
			int(item.get("income", 0))
		],
		UIKit.FONT_BODY,
		UIKit.INK,
		HORIZONTAL_ALIGNMENT_LEFT
	)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if fish_id == "fish_king" and item.has("integrity"):
		label.text += "，完整度 %d%%" % int(item.get("integrity", 0))
	row.add_child(label)
	return row

func _create_expense_section(ledger: Dictionary) -> PanelContainer:
	var card := _make_section_card("ExpenseSection", UIKit.RED)
	var box := _section_box(card)
	box.add_child(_section_title("花销"))
	_add_nonzero_or_zero_row(box, "包塘钱", int(ledger.get("pond_price", 0)), true)
	_add_nonzero_or_zero_row(box, "看塘费", int(ledger.get("inspection_spent", 0)), true)
	_add_nonzero_or_zero_row(box, "下网钱", int(ledger.get("fishing_cost_total", 0)), true)
	_add_nonzero_or_zero_row(box, "拉鱼钱", int(ledger.get("transport_cost_total", 0)), true)
	_add_nonzero_or_zero_row(box, "工钱", int(ledger.get("labor_cost_total", 0)), true)
	_add_nonzero_or_zero_row(box, "抽水钱", int(ledger.get("pump_cost_total", 0)), true)
	_add_nonzero_or_zero_row(box, "杂项", int(ledger.get("other_cost", 0)), true)
	box.add_child(_make_money_row("总共花出去的", "-%d 元" % int(ledger.get("total_expense", 0)), true, -int(ledger.get("total_expense", 0))))
	return card

func _create_final_ledger_section(ledger: Dictionary) -> PanelContainer:
	var card := _make_section_card("FinalLedgerSection", UIKit.GOLD)
	var box := _section_box(card)
	box.add_child(_section_title("算总账"))
	box.add_child(_make_money_row("总共进账的", "+%d 元" % int(ledger.get("total_income", 0)), false, int(ledger.get("total_income", 0))))
	box.add_child(_make_money_row("总共花出去的", "-%d 元" % int(ledger.get("total_expense", 0)), false, -int(ledger.get("total_expense", 0))))
	box.add_child(_make_money_row("这口塘，到头来", _format_signed(int(ledger.get("pond_net_profit", 0))), true, int(ledger.get("pond_net_profit", 0))))
	box.add_child(_make_money_row("结算后本钱", "%d 元" % int(ledger.get("money_after_settlement", 0))))
	return card

func _create_boss_review_section(ledger: Dictionary) -> PanelContainer:
	var card := _make_section_card("BossReviewSection", UIKit.GOLD)
	var box := _section_box(card)
	var title_label := UIKit.make_label("老板复盘", UIKit.FONT_SECTION, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(title_label)
	var phrase := _generate_boss_review_phrase(ledger)
	var tone := _review_tone(ledger)
	var phrase_color := UIKit.GOLD
	if tone == "positive":
		phrase_color = UIKit.GREEN
	elif tone == "negative":
		phrase_color = UIKit.RED
	var phrase_label := UIKit.make_label(phrase, UIKit.FONT_IMPORTANT, phrase_color, HORIZONTAL_ALIGNMENT_CENTER)
	phrase_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	phrase_label.custom_minimum_size = Vector2(0, 76)
	box.add_child(phrase_label)
	return card

func _generate_boss_review_phrase(ledger: Dictionary) -> String:
	var net_profit := int(ledger.get("pond_net_profit", 0))
	if net_profit == 0:
		return "本塘打平"
	if net_profit > 0:
		var key := _find_largest_key(ledger, _INCOME_KEYS)
		var label: String = _INCOME_LABELS.get(key, "进项")
		return "赚在" + label
	var cost_key := _find_largest_key(ledger, _COST_KEYS)
	var cost_label: String = _COST_LABELS.get(cost_key, "支出")
	return "亏在" + cost_label

func _find_largest_key(ledger: Dictionary, keys: Array[String]) -> String:
	var best_key := ""
	var best_value := -1
	for key: String in keys:
		var value := int(ledger.get(key, 0))
		if value > best_value:
			best_value = value
			best_key = key
	return best_key

func _review_tone(ledger: Dictionary) -> String:
	var net_profit := int(ledger.get("pond_net_profit", 0))
	if net_profit > 0:
		return "positive"
	if net_profit < 0:
		return "negative"
	return "neutral"

func _make_section_card(card_name: String, accent: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = card_name
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_panel_texture(card, SETTLEMENT_CARD_BG_TEXTURE, 18, 24)
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

func _add_positive_income_row(box: VBoxContainer, name_text: String, amount: int) -> void:
	if amount > 0:
		box.add_child(_make_money_row(name_text, "+%d 元" % amount, false, amount))

func _make_money_row(name_text: String, value_text: String, important := false, signed_amount := 0, value_min_width := 300, single_line_value := false) -> PanelContainer:
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
	value_label.custom_minimum_size = Vector2(value_min_width, 0)
	if single_line_value:
		value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
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
		return "转手出去了"
	if method == "抽干结算":
		return "抽干收尾"
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
	box.add_child(UIKit.make_label("塘边看热闹的人都炸了——“出鱼王了！”", UIKit.FONT_SECONDARY, Color(0.35, 0.18, 0.02), HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIKit.make_label("%s现身！" % FISH_KING_NAME, 42, Color(0.24, 0.08, 0.0), HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(UIKit.make_label("重量：%d 斤  完整度：%d%%  估值：%d 元" % [int(detail.get("weight_jin", 0)), int(detail.get("integrity", 0)), int(detail.get("income", 0))], UIKit.FONT_BODY, Color(0.28, 0.12, 0.0), HORIZONTAL_ALIGNMENT_CENTER))
	fish_king_panel.add_theme_stylebox_override("panel", UIKit.make_style(Color(1.0, 0.76, 0.18), Color(0.98, 0.92, 0.42), 18, 6, true))

func _get_fish_king_catch_detail() -> Dictionary:
	for item in game_state.catch_details:
		if str(item.get("id", "")) == FISH_KING_ID:
			return item
	return {}

func _spawn_settlement_sparkles(tone: String) -> void:
	if fish_king_panel.visible:
		UIKit.spawn_sparkles(sections_box, fish_king_panel.get_rect(), "gold")
	else:
		UIKit.spawn_sparkles(sections_box, profit_highlight_label.get_parent().get_rect(), tone)


func _play_sfx(effect_id: String) -> void:
	var sfx := get_tree().root.get_node_or_null("SfxManager")
	if sfx != null and sfx.has_method("play"):
		sfx.call("play", effect_id)


func _on_next_day_pressed() -> void:
	_play_sfx("card_select")
	game_state.advance_to_next_day()
	UIController.show_pond_list(screen_container, game_state, true)
