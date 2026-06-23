extends Control

const UIKit := preload("res://scripts/ui_kit.gd")

class OwnedPondVisualPlaceholder:
	extends Control

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var center := rect.get_center()
		var water_rect := Rect2(Vector2(30.0, size.y * 0.16), Vector2(maxf(1.0, size.x - 60.0), maxf(1.0, size.y * 0.68)))
		_draw_ellipse(water_rect, Color(0.18, 0.46, 0.58, 1.0))
		draw_arc(center, minf(size.x, size.y) * 0.34, 0.0, TAU, 96, Color(0.06, 0.18, 0.18, 1.0), 6.0, true)
		for index in range(3):
			var wave_y := size.y * (0.36 + float(index) * 0.14)
			var from_x := size.x * 0.22
			var to_x := size.x * 0.78
			var points := PackedVector2Array()
			for step in range(24):
				var t := float(step) / 23.0
				points.append(Vector2(lerpf(from_x, to_x, t), wave_y + sin(t * TAU * 2.0 + float(index)) * 7.0))
			draw_polyline(points, Color(0.78, 0.95, 0.94, 0.75), 3.0, true)
		_draw_ellipse(Rect2(Vector2(size.x * 0.38, size.y * 0.50), Vector2(76.0, 26.0)), Color(0.04, 0.15, 0.13, 0.55))
		_draw_ellipse(Rect2(Vector2(size.x * 0.58, size.y * 0.36), Vector2(54.0, 20.0)), Color(0.04, 0.15, 0.13, 0.45))

	func _draw_ellipse(rect: Rect2, color: Color) -> void:
		var points := PackedVector2Array()
		var center := rect.get_center()
		var radius := rect.size * 0.5
		for index in range(64):
			var angle := float(index) / 64.0 * TAU
			points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
		draw_colored_polygon(points, color)

@onready var safe_area: MarginContainer = $SafeArea
@onready var top_status_bar: PanelContainer = $SafeArea/PageLayout/TopStatusBar
@onready var day_label: Label = $SafeArea/PageLayout/TopStatusBar/StatusRow/DayLabel
@onready var cash_label: Label = $SafeArea/PageLayout/TopStatusBar/StatusRow/MoneyLabel
@onready var title_label: Label = $SafeArea/PageLayout/PageHeader/TitleLabel
@onready var subtitle_label: Label = $SafeArea/PageLayout/PageHeader/SubtitleLabel
@onready var content_scroll: ScrollContainer = $SafeArea/PageLayout/ContentScroll
@onready var owned_pond_card: PanelContainer = $SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard
@onready var pond_status_badge: Label = $SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/PondHeader/PondStatusBadge
@onready var pond_name_label: Label = $SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/PondHeader/PondNameLabel
@onready var pond_visual_host: Control = $SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/PondVisualHost
@onready var contract_price_value: Label = $SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/ContractPriceRow/RowContent/Value
@onready var inspection_spent_value: Label = $SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/InspectionSpentRow/RowContent/Value
@onready var total_invested_value: Label = $SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/TotalInvestedRow/RowContent/Value
@onready var revenue_value: Label = $SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/RevenueRow/RowContent/Value
@onready var profit_loss_value: Label = $SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/ProfitLossRow/RowContent/Value
@onready var profit_loss_row: PanelContainer = $SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/ProfitLossRow
@onready var situation_hint_card: PanelContainer = $SafeArea/PageLayout/ContentScroll/Content/SituationHintCard
@onready var message_label: Label = $SafeArea/PageLayout/ContentScroll/Content/SituationHintCard/HintMargin/MessageLabel
@onready var action_section: VBoxContainer = $SafeArea/PageLayout/ContentScroll/Content/ActionSection
@onready var action_section_title: Label = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/SectionTitleLabel
@onready var transfer_card: PanelContainer = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_TransferOut
@onready var transfer_status_label: Label = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_TransferOut/CardMargin/CardContent/ActionStatusLabel
@onready var transfer_button: Button = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_TransferOut/CardMargin/CardContent/TransferButton
@onready var sell_one_net_card: PanelContainer = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_SellOneNet
@onready var sell_one_net_desc_label: Label = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_SellOneNet/CardMargin/CardContent/ActionDescLabel
@onready var sell_one_net_status_label: Label = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_SellOneNet/CardMargin/CardContent/ActionStatusLabel
@onready var sell_one_net_button: Button = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_SellOneNet/CardMargin/CardContent/SellOneNetButton
@onready var harvest_self_card: PanelContainer = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_SelfNet
@onready var harvest_self_status_label: Label = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_SelfNet/CardMargin/CardContent/ActionStatusLabel
@onready var harvest_self_button: Button = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_SelfNet/CardMargin/CardContent/HarvestSelfButton
@onready var work_plan_back_button: Button = $SafeArea/PageLayout/ContentScroll/Content/WorkPlanBackButton
@onready var work_plan_scroll: ScrollContainer = $SafeArea/PageLayout/ContentScroll/Content/WorkPlanScroll
@onready var work_plan_panel: VBoxContainer = $SafeArea/PageLayout/ContentScroll/Content/WorkPlanScroll/WorkPlanPanel
@onready var low_work_button: Button = $SafeArea/PageLayout/ContentScroll/Content/WorkPlanScroll/WorkPlanPanel/LowWorkCard/CardContent/LowWorkButton
@onready var standard_work_button: Button = $SafeArea/PageLayout/ContentScroll/Content/WorkPlanScroll/WorkPlanPanel/StandardWorkCard/CardContent/StandardWorkButton
@onready var full_work_button: Button = $SafeArea/PageLayout/ContentScroll/Content/WorkPlanScroll/WorkPlanPanel/FullWorkCard/CardContent/FullWorkButton

var game_state: GameState
var screen_container: Control
var resolver := ActionResolver.new()
var current_transfer_offer: Dictionary = {}
var current_one_net_offer: Dictionary = {}
var transfer_overlay: Control
var transfer_dialog: PanelContainer
var transfer_offer_summary_label: Label
var transfer_offer_label: Label
var accept_transfer_button: Button
var reject_transfer_button: Button
var harvest_result_overlay: Control
var harvest_result_dialog: PanelContainer
var harvest_result_title: Label
var harvest_catch_label: Label
var harvest_result_label: Label

func setup(next_game_state: GameState, next_screen_container: Control) -> void:
	game_state = next_game_state
	screen_container = next_screen_container

func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()

	_create_owned_pond_visual()
	_create_transfer_dialog()
	_create_harvest_result_dialog()
	transfer_button.pressed.connect(_on_transfer_pressed)
	sell_one_net_button.pressed.connect(_on_sell_one_net_pressed)
	harvest_self_button.pressed.connect(_on_harvest_self_pressed)
	work_plan_back_button.pressed.connect(_on_work_plan_back_pressed)
	low_work_button.pressed.connect(_on_work_plan_pressed.bind("low"))
	standard_work_button.pressed.connect(_on_work_plan_pressed.bind("standard"))
	full_work_button.pressed.connect(_on_work_plan_pressed.bind("full"))
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_apply_ui_frame()
	_refresh_transfer_offer()
	_render()

func _apply_ui_frame() -> void:
	UIKit.set_safe_panel(safe_area, int(UIKit.PAGE_SAFE_X), int(UIKit.PAGE_TOP), -int(UIKit.PAGE_SAFE_X), -int(UIKit.PAGE_BOTTOM))
	UIKit.style_card(top_status_bar, UIKit.GOLD)
	UIKit.style_page_title(title_label)
	UIKit.style_label(subtitle_label, "muted")
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_page_frame(owned_pond_card, UIKit.GREEN)
	owned_pond_card.set_meta("_future_texture_slot", "owned_pond_card_bg.png")
	pond_visual_host.set_meta("_future_texture_slot", "owned_pond_visual.png")
	UIKit.style_chip(pond_status_badge, UIKit.GREEN)
	UIKit.style_label(pond_name_label, "content_title")
	UIKit.style_message_panel(situation_hint_card)
	UIKit.style_label(message_label, "body")
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(action_section_title, "section")
	_style_ledger_rows()
	_style_action_card(transfer_card, transfer_button, "secondary")
	_style_action_card(sell_one_net_card, sell_one_net_button, "ghost")
	_style_action_card(harvest_self_card, harvest_self_button, "primary")
	work_plan_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	work_plan_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_show_choice_page()

func _create_owned_pond_visual() -> void:
	if pond_visual_host.get_child_count() > 0:
		return
	# Future art pass: replace this drawn placeholder with owned_pond_visual.png.
	var visual := OwnedPondVisualPlaceholder.new()
	visual.name = "PondVisualPlaceholder"
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pond_visual_host.add_child(visual)

func _style_ledger_rows() -> void:
	var ledger_rows := [
		$SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/ContractPriceRow,
		$SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/InspectionSpentRow,
		$SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/TotalInvestedRow,
		$SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/RevenueRow,
		$SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/ProfitLossRow
	]
	for row in ledger_rows:
		var row_panel := row as PanelContainer
		row_panel.add_theme_stylebox_override("panel", UIKit.make_style(Color(1.0, 0.96, 0.84, 0.92), Color(0.61, 0.45, 0.25, 0.55), 8, 2, false))
		row_panel.custom_minimum_size = Vector2(0, 54)
		var name_label := row_panel.get_node("RowContent/Label") as Label
		var value_label := row_panel.get_node("RowContent/Value") as Label
		UIKit.style_label(name_label, "body_dark")
		UIKit.style_label(value_label, "body_dark")
		value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _style_action_card(card: PanelContainer, button: Button, role: String) -> void:
	card.set_meta("_future_texture_slot", "action_card_bg.png")
	UIKit.style_card(card, UIKit.RED if role == "primary" else UIKit.GREEN)
	for label in card.find_children("*", "Label", true, false):
		var typed_label := label as Label
		typed_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if typed_label.name == "ActionTitleLabel":
			UIKit.style_label(typed_label, "section")
		elif typed_label.name == "ActionStatusLabel":
			UIKit.style_label(typed_label, "muted")
		else:
			UIKit.style_label(typed_label, "body_dark")
	UIKit.style_button(button, role)
	button.set_meta("_future_texture_button", "button_primary.png" if role == "primary" else "button_secondary.png")

func _create_transfer_dialog() -> void:
	var modal := UIKit.create_modal_layer(self, "TransferModal")
	transfer_overlay = modal["overlay"] as Control
	transfer_dialog = modal["card"] as PanelContainer

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	transfer_dialog.add_child(content)

	var title := Label.new()
	title.text = "有人愿意接手"
	UIKit.style_modal_title(title)
	content.add_child(title)

	transfer_offer_summary_label = Label.new()
	transfer_offer_summary_label.custom_minimum_size = Vector2(0, 64)
	UIKit.style_highlight_label(transfer_offer_summary_label, "price")
	content.add_child(transfer_offer_summary_label)

	var body_scroll := ScrollContainer.new()
	body_scroll.name = "BodyScroll"
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(body_scroll)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	body_scroll.add_child(body)

	transfer_offer_label = Label.new()
	transfer_offer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	transfer_offer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transfer_offer_label.add_theme_font_size_override("font_size", UIKit.FONT_BODY)
	transfer_offer_label.add_theme_color_override("font_color", UIKit.INK)
	body.add_child(transfer_offer_label)

	body.add_child(UIKit.make_image_placeholder(Vector2(280, 300)))

	var bubble := PanelContainer.new()
	bubble.custom_minimum_size = Vector2(250, 0)
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bubble.add_theme_stylebox_override("panel", UIKit.make_style(Color("fff8df"), Color("6d241f"), 24, 3, true))
	body.add_child(bubble)

	var bubble_margin := MarginContainer.new()
	bubble_margin.add_theme_constant_override("margin_left", 24)
	bubble_margin.add_theme_constant_override("margin_top", 20)
	bubble_margin.add_theme_constant_override("margin_right", 24)
	bubble_margin.add_theme_constant_override("margin_bottom", 20)
	bubble.add_child(bubble_margin)

	var bubble_text := Label.new()
	bubble_text.text = "兄弟一场，把这塘包给我"
	bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble_text.add_theme_font_size_override("font_size", 28)
	bubble_text.add_theme_color_override("font_color", UIKit.INK)
	bubble_margin.add_child(bubble_text)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	content.add_child(buttons)

	accept_transfer_button = Button.new()
	accept_transfer_button.text = "接受转包"
	accept_transfer_button.custom_minimum_size = Vector2(0, UIKit.MODAL_ACTION_HEIGHT)
	accept_transfer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIKit.style_button(accept_transfer_button, "primary")
	accept_transfer_button.pressed.connect(_on_accept_transfer_pressed)
	buttons.add_child(accept_transfer_button)

	reject_transfer_button = Button.new()
	reject_transfer_button.text = "继续自己扛"
	reject_transfer_button.custom_minimum_size = Vector2(0, UIKit.MODAL_ACTION_HEIGHT)
	reject_transfer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIKit.style_button(reject_transfer_button, "ghost")
	reject_transfer_button.pressed.connect(_on_reject_transfer_pressed)
	buttons.add_child(reject_transfer_button)

func _create_harvest_result_dialog() -> void:
	var modal := UIKit.create_modal_layer(self, "HarvestResultModal")
	harvest_result_overlay = modal["overlay"] as Control
	harvest_result_dialog = modal["card"] as PanelContainer

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	harvest_result_dialog.add_child(content)

	harvest_result_title = Label.new()
	UIKit.style_modal_title(harvest_result_title)
	content.add_child(harvest_result_title)

	var body_scroll := ScrollContainer.new()
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(body_scroll)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	body_scroll.add_child(body)

	body.add_child(UIKit.make_image_placeholder(Vector2(0, 360)))

	harvest_catch_label = Label.new()
	harvest_catch_label.name = "HarvestCatchLabel"
	harvest_catch_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	harvest_catch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UIKit.style_label(harvest_catch_label, "body_dark")
	body.add_child(harvest_catch_label)

	harvest_result_label = Label.new()
	harvest_result_label.name = "HarvestProfitLabel"
	harvest_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	harvest_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(harvest_result_label, "body_dark")
	body.add_child(harvest_result_label)

	var continue_button := Button.new()
	continue_button.text = "收下结果"
	continue_button.custom_minimum_size = Vector2(0, UIKit.MODAL_ACTION_HEIGHT)
	UIKit.style_button(continue_button, "primary")
	continue_button.pressed.connect(_on_harvest_result_continue_pressed)
	content.add_child(continue_button)

func _render() -> void:
	var pond := game_state.current_pond
	pond_name_label.text = str(pond.get("name", "未承包鱼塘"))
	day_label.text = "第 %d 天" % game_state.day
	cash_label.text = "本钱：%d 元" % game_state.cash
	_render_ledger()

	transfer_button.text = "去转包"
	sell_one_net_button.text = "卖一网"
	harvest_self_button.text = "开始下网"
	transfer_button.disabled = current_transfer_offer.is_empty() or game_state.drained
	sell_one_net_button.disabled = current_one_net_offer.is_empty() or game_state.sold_one_net
	harvest_self_button.disabled = not game_state.can_pay(game_state.get_work_cost("low"))
	transfer_status_label.text = "有接手价" if not transfer_button.disabled else "暂无报价"
	harvest_self_status_label.text = "主行动" if not harvest_self_button.disabled else "本钱不够"
	if current_transfer_offer.is_empty():
		transfer_button.text = "暂无报价"
	if game_state.sold_one_net:
		sell_one_net_status_label.text = "已卖出"
		sell_one_net_desc_label.text = "这一局已经卖过一网，不能再拆着卖。"
		sell_one_net_button.text = "已卖出"
	elif current_one_net_offer.is_empty():
		sell_one_net_status_label.text = "暂无买家"
		sell_one_net_desc_label.text = "先下一网见到鱼，才有人出价。"
		sell_one_net_button.text = "暂不可用"
	else:
		sell_one_net_status_label.text = "已有买家"
		sell_one_net_desc_label.text = "有人愿意买一网，收钱快，但这一网里的好货归买家。"
		sell_one_net_button.text = "卖一网"
	if game_state.self_net_count > 0 or game_state.sold_one_net:
		message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		message_label.text = _build_pond_ledger()
	elif not game_state.can_pay(game_state.get_work_cost("low")):
		message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		message_label.text = "钱不够下一网了。可以转包脱手，留本钱去下一地方。"
	else:
		message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		message_label.text = "先自己下一网，见到鱼，外面才有人信。"

	_update_work_buttons()

func _render_ledger() -> void:
	var ledger := _get_current_ledger()
	contract_price_value.text = "%d 元" % int(ledger.get("pond_price", 0))
	inspection_spent_value.text = "%d 元" % int(ledger.get("inspection_spent", 0))
	total_invested_value.text = "%d 元" % int(ledger.get("total_invested", 0))
	revenue_value.text = "%d 元" % int(ledger.get("revenue", 0))
	var current_profit_loss := int(ledger.get("current_profit_loss", 0))
	profit_loss_value.text = "%+d 元" % current_profit_loss if current_profit_loss != 0 else "0 元"
	UIKit.style_label(profit_loss_value, "body_dark")
	profit_loss_value.add_theme_color_override("font_color", UIKit.GREEN if current_profit_loss > 0 else UIKit.RED if current_profit_loss < 0 else UIKit.INK)
	profit_loss_row.add_theme_stylebox_override("panel", UIKit.make_style(Color(1.0, 0.92, 0.70, 0.95), UIKit.GREEN_LIGHT if current_profit_loss > 0 else UIKit.RED if current_profit_loss < 0 else UIKit.GOLD, 8, 3, false))

func _get_current_ledger() -> Dictionary:
	var current_money := game_state.cash
	var pond_price := int(game_state.current_pond.get("contract_total_cost", game_state.current_pond.get("quote_price", 0)))
	var inspection_spent := game_state.inspection_cost_total
	var fishing_cost := game_state.work_cost
	var transport_cost := 0
	var revenue := game_state.fish_income + game_state.one_net_income + game_state.transfer_income
	var total_invested := pond_price + inspection_spent + fishing_cost + transport_cost
	var current_profit_loss := revenue - total_invested
	return {
		"current_money": current_money,
		"pond_price": pond_price,
		"inspection_spent": inspection_spent,
		"fishing_cost": fishing_cost,
		"transport_cost": transport_cost,
		"revenue": revenue,
		"total_invested": total_invested,
		"current_profit_loss": current_profit_loss
	}

func _hide_detail_panels() -> void:
	_close_transfer_dialog()
	_show_choice_page()

func _show_choice_page() -> void:
	title_label.text = "塘已经包下"
	subtitle_label.text = "本钱已经下去了，接下来要决定怎么处理这口塘"
	owned_pond_card.visible = true
	situation_hint_card.visible = true
	action_section.visible = true
	work_plan_back_button.visible = false
	work_plan_scroll.visible = false

func _show_work_plan_page() -> void:
	title_label.text = "自己下网"
	subtitle_label.text = "选一种作业方式，钱不够的方案不能开工"
	owned_pond_card.visible = false
	situation_hint_card.visible = true
	action_section.visible = false
	work_plan_back_button.visible = true
	work_plan_scroll.visible = true

func _close_transfer_dialog() -> void:
	UIKit.hide_modal(transfer_overlay)

func _refresh_transfer_offer() -> void:
	game_state.current_pond["estimated_transfer_value"] = game_state.get_current_pond_estimated_value()
	current_transfer_offer = resolver.generate_transfer_offer(game_state.current_pond)

func _on_transfer_pressed() -> void:
	if current_transfer_offer.is_empty():
		message_label.text = "现在没人肯接手。先自己下一网，让外面的人看到这塘到底有没有货。"
		return

	_show_global_confirm({
		"title": "确定要转包？",
		"body": "转包可能亏钱，但可以提前止损。",
		"cancel_text": "再想想",
		"confirm_text": "去转包",
		"on_confirm": Callable(self, "_open_transfer_offer_dialog")
	})

func _open_transfer_offer_dialog() -> void:
	_hide_detail_panels()
	transfer_offer_summary_label.text = "接手价：%d 元" % int(current_transfer_offer.get("income", 0))
	transfer_offer_label.text = str(current_transfer_offer.get("text", ""))
	UIKit.show_modal(self, transfer_overlay, transfer_dialog, 0.86, 980, Vector2i(340, 560), Vector2i(860, 1040))
	message_label.text = ""

func _on_accept_transfer_pressed() -> void:
	_close_transfer_dialog()
	game_state.apply_transfer(int(current_transfer_offer.get("income", 0)))
	UIController.show_settlement(screen_container, game_state)

func _on_reject_transfer_pressed() -> void:
	_close_transfer_dialog()
	message_label.text = "你没接这个转包价。后面是赚是亏，继续自己扛。"
	_render()

func _on_viewport_size_changed() -> void:
	if transfer_overlay != null and transfer_overlay.visible:
		UIKit.layout_modal(self, transfer_dialog, 0.86, 980, Vector2i(340, 560), Vector2i(860, 1040))
	if harvest_result_overlay != null and harvest_result_overlay.visible:
		UIKit.layout_modal(self, harvest_result_dialog, 0.86, 1060, Vector2i(340, 700), Vector2i(860, 1160))

func _on_sell_one_net_pressed() -> void:
	_hide_detail_panels()
	if game_state.sold_one_net:
		message_label.text = "这一局已经卖过一网了，不能再把机会拆着卖。"
		_render()
		return
	if current_one_net_offer.is_empty():
		message_label.text = "暂时没人愿意买一网。先自己下一网，把鱼情打出来。"
		_render()
		return

	if game_state.apply_one_net(int(current_one_net_offer.get("income", 0)), str(current_one_net_offer.get("text", ""))):
		message_label.text = str(game_state.last_result.get("message", "买家这一网已经开出来，塘口估值已更新。"))
		current_one_net_offer = {}
		_refresh_transfer_offer()
	_render()

func _on_harvest_self_pressed() -> void:
	_close_transfer_dialog()
	_show_global_confirm({
		"title": "准备自己下网？",
		"body": "下网会产生人工、网具、抽水或鱼车等成本，确定继续吗？",
		"cancel_text": "再想想",
		"confirm_text": "开始下网",
		"on_confirm": Callable(self, "_open_work_plan_page")
	})

func _open_work_plan_page() -> void:
	_show_work_plan_page()
	message_label.text = "选一种下网方式。抽干会直接结算，钱不够的方案不能选。"
	_update_work_buttons()

func _show_global_confirm(config: Dictionary) -> void:
	var popup_manager := get_tree().root.get_node_or_null("PopupManager")
	if popup_manager == null or not popup_manager.has_method("show_confirm"):
		push_error("PopupManager autoload is missing; cannot show confirmation dialog.")
		return
	popup_manager.call("show_confirm", config)

func _on_work_plan_back_pressed() -> void:
	message_label.text = ""
	_show_choice_page()
	_render()

func _on_work_plan_pressed(plan_id: String) -> void:
	var cost := game_state.get_work_cost(plan_id)
	if not game_state.can_pay(cost):
		message_label.text = "本钱不够，干不了这个作业方案。"
		_update_work_buttons()
		return

	var result := resolver.generate_harvest_result(game_state.current_pond, plan_id, cost)
	if game_state.apply_harvest(result):
		if bool(result.get("is_final", false)):
			UIController.show_settlement(screen_container, game_state)
			return

		var opportunities := resolver.generate_disposal_opportunities(game_state.current_pond, result)
		current_transfer_offer = opportunities.get("transfer_offer", {})
		if current_transfer_offer.is_empty():
			_refresh_transfer_offer()
		if not game_state.sold_one_net:
			current_one_net_offer = opportunities.get("one_net_offer", {})
		message_label.text = "%s\n%s" % [str(result.get("text", "")), str(opportunities.get("message", ""))]
		_show_choice_page()
		_render()
		_show_harvest_result(result)
	else:
		message_label.text = "本钱不够，干不了这个作业方案。"
		_update_work_buttons()

func _build_pond_ledger() -> String:
	var lines: Array[String] = ["塘口累计账"]
	lines.append("鱼获收入")
	if game_state.catch_details.is_empty():
		lines.append("暂无鱼获")
	else:
		for item in game_state.catch_details:
			lines.append("%s：%d 斤，收入 %d 元" % [
				str(item.get("name", "未知鱼获")),
				int(item.get("weight_jin", 0)),
				int(item.get("income", 0))
			])
	lines.append("鱼获收入合计：%d 元" % game_state.fish_income)

	lines.append("其他收入")
	if game_state.one_net_income <= 0 and game_state.transfer_income <= 0:
		lines.append("暂无其他收入")
	else:
		if game_state.one_net_income > 0:
			lines.append("卖一网收入：%d 元" % game_state.one_net_income)
		if game_state.transfer_income > 0:
			lines.append("转包收入：%d 元" % game_state.transfer_income)

	var contract_cost := int(game_state.current_pond.get("quote_price", 0))
	var total_cost := contract_cost + game_state.inspection_cost_total + game_state.work_cost
	lines.append("各项支出")
	lines.append("承包费：%d 元" % contract_cost)
	lines.append("验塘费：%d 元" % game_state.inspection_cost_total)
	lines.append("下网作业费：%d 元" % game_state.work_cost)
	lines.append("支出合计：%d 元" % total_cost)

	var received_income := game_state.fish_income + game_state.one_net_income + game_state.transfer_income
	var realized_net := received_income - total_cost
	lines.append("截至目前")
	lines.append("已回款净额：%+d 元" % realized_net)
	lines.append("塘内剩余估值：%d 元" % game_state.get_current_pond_estimated_value())
	lines.append("当前账面盈亏：%+d 元" % game_state.get_mark_to_market_profit())
	return "\n".join(lines)

func _show_harvest_result(result: Dictionary) -> void:
	var caught_fish_king := false
	for item in Array(result.get("catch_details", [])):
		if str(Dictionary(item).get("id", "")) == "fish_king":
			caught_fish_king = true
			break

	var round_profit := int(result.get("fish_income", 0)) - int(result.get("work_cost", 0))
	if caught_fish_king:
		harvest_result_title.text = "鱼王出现！"
	elif round_profit > 0:
		harvest_result_title.text = "这一网赚到了"
	else:
		harvest_result_title.text = "这一网没回本"

	harvest_catch_label.text = _format_harvest_catch(result)
	harvest_result_label.text = "本次赚亏 %+d 元" % round_profit
	UIKit.style_highlight_label(harvest_result_label, "positive" if round_profit > 0 else "negative")
	UIKit.show_modal(self, harvest_result_overlay, harvest_result_dialog, 0.86, 1060, Vector2i(340, 700), Vector2i(860, 1160))

func _format_harvest_catch(result: Dictionary) -> String:
	var lines: Array[String] = ["鱼获明细"]
	var catch_details := Array(result.get("catch_details", []))
	if catch_details.is_empty():
		lines.append("这一网没有起货。")
	else:
		lines.append("这网主货：%s" % str(result.get("fish_result_name", "暂无鱼获")))
		for item_variant in catch_details:
			var item := Dictionary(item_variant)
			var line := "%s：%d 斤 × %d 元/斤 = %d 元" % [
				str(item.get("name", "未知鱼获")),
				int(item.get("weight_jin", 0)),
				int(item.get("unit_price", 0)),
				int(item.get("income", 0))
			]
			if str(item.get("id", "")) == "fish_king" and item.has("integrity"):
				line += "，完整度 %d%%" % int(item.get("integrity", 0))
			lines.append(line)
			var price_note := str(item.get("price_note", ""))
			if not price_note.is_empty():
				lines.append(price_note)
	lines.append("卖鱼回款：%d 元" % int(result.get("fish_income", 0)))
	return "\n".join(lines)

func _on_harvest_result_continue_pressed() -> void:
	UIKit.hide_modal(harvest_result_overlay)

func _update_work_buttons() -> void:
	var low_cost := game_state.get_work_cost("low")
	var standard_cost := game_state.get_work_cost("standard")
	var full_cost := game_state.get_work_cost("full")

	low_work_button.text = "小捞一网\n%d 元 · 捞完还能继续" % low_cost
	standard_work_button.text = "稳捞一网\n%d 元 · 捞完还能继续" % standard_cost
	full_work_button.text = "抽干收尾\n%d 元 · 本轮直接结算" % full_cost
	low_work_button.disabled = not game_state.can_pay(low_cost)
	standard_work_button.disabled = not game_state.can_pay(standard_cost)
	full_work_button.disabled = game_state.drained or not game_state.can_pay(full_cost)
