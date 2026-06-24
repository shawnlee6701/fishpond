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

class TransferBuyerPlaceholder:
	extends Control

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var center := rect.get_center()
		var avatar_center := Vector2(rect.size.x * 0.34, rect.size.y * 0.42)
		var avatar_radius := minf(rect.size.x, rect.size.y) * 0.18
		_draw_circle_shape(avatar_center, avatar_radius, Color(0.94, 0.72, 0.48, 1.0))
		_draw_circle_shape(avatar_center + Vector2(0.0, avatar_radius * 1.75), avatar_radius * 1.35, Color(0.18, 0.36, 0.25, 1.0))
		_draw_circle_shape(avatar_center + Vector2(-avatar_radius * 0.33, -avatar_radius * 0.10), avatar_radius * 0.08, Color(0.12, 0.10, 0.06, 1.0))
		_draw_circle_shape(avatar_center + Vector2(avatar_radius * 0.33, -avatar_radius * 0.10), avatar_radius * 0.08, Color(0.12, 0.10, 0.06, 1.0))
		draw_arc(avatar_center + Vector2(0.0, avatar_radius * 0.12), avatar_radius * 0.36, 0.18, PI - 0.18, 18, Color(0.12, 0.10, 0.06, 1.0), 3.0, true)

		var paper_rect := Rect2(Vector2(rect.size.x * 0.50, rect.size.y * 0.22), Vector2(rect.size.x * 0.34, rect.size.y * 0.52))
		draw_rect(paper_rect, Color(1.0, 0.95, 0.78, 1.0), true)
		draw_rect(paper_rect, Color(0.43, 0.31, 0.16, 1.0), false, 4.0)
		for index in range(3):
			var line_y := paper_rect.position.y + paper_rect.size.y * (0.26 + float(index) * 0.18)
			draw_line(
				Vector2(paper_rect.position.x + paper_rect.size.x * 0.18, line_y),
				Vector2(paper_rect.position.x + paper_rect.size.x * 0.82, line_y),
				Color(0.61, 0.45, 0.25, 0.80),
				3.0,
				true
			)
		draw_circle(paper_rect.position + paper_rect.size * Vector2(0.72, 0.78), paper_rect.size.x * 0.10, Color(0.66, 0.16, 0.11, 0.88))

	func _draw_circle_shape(center: Vector2, radius: float, color: Color) -> void:
		var points := PackedVector2Array()
		for index in range(48):
			var angle := float(index) / 48.0 * TAU
			points.append(center + Vector2(cos(angle) * radius, sin(angle) * radius))
		draw_colored_polygon(points, color)

class NetMethodPlaceholder:
	extends Control

	var method_id := "low"

	func _init(next_method_id := "low") -> void:
		method_id = next_method_id

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var base := Color(0.18, 0.46, 0.58, 1.0)
		var ink := Color(0.07, 0.16, 0.13, 1.0)
		if method_id == "full":
			base = Color(0.64, 0.42, 0.22, 1.0)
			ink = Color(0.22, 0.12, 0.06, 1.0)
		_draw_round_rect(Rect2(Vector2(size.x * 0.08, size.y * 0.20), Vector2(size.x * 0.84, size.y * 0.62)), base, 22.0)
		if method_id == "full":
			var pump := Rect2(Vector2(size.x * 0.20, size.y * 0.32), Vector2(size.x * 0.32, size.y * 0.25))
			draw_rect(pump, Color(0.22, 0.29, 0.25, 1.0), true)
			draw_rect(pump, ink, false, 4.0)
			draw_line(Vector2(size.x * 0.52, size.y * 0.44), Vector2(size.x * 0.78, size.y * 0.34), ink, 5.0, true)
			draw_line(Vector2(size.x * 0.52, size.y * 0.52), Vector2(size.x * 0.80, size.y * 0.68), ink, 5.0, true)
			draw_arc(Vector2(size.x * 0.72, size.y * 0.44), size.x * 0.10, 0.0, TAU, 32, Color(0.94, 0.86, 0.58, 1.0), 4.0, true)
			for index in range(3):
				draw_line(Vector2(size.x * (0.22 + index * 0.18), size.y * 0.74), Vector2(size.x * (0.34 + index * 0.18), size.y * 0.72), Color(0.93, 0.78, 0.48, 1.0), 4.0, true)
			return

		var net_center := Vector2(size.x * (0.46 if method_id == "low" else 0.50), size.y * 0.48)
		var net_radius := minf(size.x, size.y) * (0.22 if method_id == "low" else 0.30)
		draw_arc(net_center, net_radius, 0.0, TAU, 48, Color(0.88, 0.96, 0.90, 1.0), 5.0, true)
		for index in range(-2, 3):
			var x := net_center.x + float(index) * net_radius * 0.34
			draw_line(Vector2(x, net_center.y - net_radius * 0.78), Vector2(x, net_center.y + net_radius * 0.78), Color(0.88, 0.96, 0.90, 0.72), 2.0, true)
			var y := net_center.y + float(index) * net_radius * 0.26
			draw_line(Vector2(net_center.x - net_radius * 0.82, y), Vector2(net_center.x + net_radius * 0.82, y), Color(0.88, 0.96, 0.90, 0.72), 2.0, true)
		draw_line(Vector2(net_center.x + net_radius * 0.68, net_center.y + net_radius * 0.60), Vector2(size.x * 0.86, size.y * 0.78), ink, 7.0, true)

	func _draw_round_rect(rect: Rect2, color: Color, radius: float) -> void:
		draw_rect(rect, color, true)
		draw_rect(rect, Color(0.06, 0.18, 0.14, 0.85), false, 4.0)

class CatchVisualPlaceholder:
	extends Control

	func _draw() -> void:
		var bag_center := Vector2(size.x * 0.50, size.y * 0.48)
		var bag_radius := minf(size.x, size.y) * 0.30
		draw_arc(bag_center, bag_radius, 0.0, TAU, 64, Color(0.08, 0.18, 0.15, 1.0), 5.0, true)
		for index in range(-3, 4):
			var x := bag_center.x + float(index) * bag_radius * 0.22
			draw_line(Vector2(x, bag_center.y - bag_radius * 0.82), Vector2(x, bag_center.y + bag_radius * 0.82), Color(0.82, 0.94, 0.88, 0.70), 2.0, true)
		for index in range(4):
			var fish_center := Vector2(size.x * (0.35 + index * 0.10), size.y * (0.42 + (index % 2) * 0.12))
			_draw_fish(fish_center, 38.0 + float(index % 2) * 10.0, Color(0.08, 0.30, 0.24, 0.70))
		for index in range(5):
			draw_circle(Vector2(size.x * (0.18 + index * 0.14), size.y * (0.24 + (index % 3) * 0.10)), 7.0 + index % 2 * 3.0, Color(0.80, 0.95, 0.94, 0.72))

	func _draw_fish(center: Vector2, length: float, color: Color) -> void:
		_draw_ellipse(Rect2(center - Vector2(length * 0.32, length * 0.16), Vector2(length * 0.64, length * 0.32)), color)
		var tail := PackedVector2Array([
			center + Vector2(length * 0.34, 0.0),
			center + Vector2(length * 0.55, -length * 0.16),
			center + Vector2(length * 0.55, length * 0.16)
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
@onready var latest_net_result_card: PanelContainer = $SafeArea/PageLayout/ContentScroll/Content/LatestNetResultCard
@onready var content_container: VBoxContainer = $SafeArea/PageLayout/ContentScroll/Content
@onready var latest_title_label: Label = $SafeArea/PageLayout/ContentScroll/Content/LatestNetResultCard/HintMargin/LatestContent/LatestTitleLabel
@onready var latest_method_label: Label = $SafeArea/PageLayout/ContentScroll/Content/LatestNetResultCard/HintMargin/LatestContent/LatestMethodLabel
@onready var latest_revenue_label: Label = $SafeArea/PageLayout/ContentScroll/Content/LatestNetResultCard/HintMargin/LatestContent/LatestRevenueLabel
@onready var latest_cost_label: Label = $SafeArea/PageLayout/ContentScroll/Content/LatestNetResultCard/HintMargin/LatestContent/LatestCostLabel
@onready var latest_profit_label: Label = $SafeArea/PageLayout/ContentScroll/Content/LatestNetResultCard/HintMargin/LatestContent/LatestProfitLabel
@onready var message_label: Label = $SafeArea/PageLayout/ContentScroll/Content/LatestNetResultCard/HintMargin/LatestContent/LatestProfitLabel
@onready var action_section: VBoxContainer = $SafeArea/PageLayout/ContentScroll/Content/ActionSection
@onready var action_section_title: Label = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/SectionTitleLabel
@onready var transfer_card: PanelContainer = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_TransferOut
@onready var transfer_status_label: Label = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_TransferOut/CardMargin/CardContent/ActionStatusLabel
@onready var transfer_button: Button = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_TransferOut/CardMargin/CardContent/TransferButton
@onready var sell_one_net_card: PanelContainer = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_SellOneNet
@onready var sell_one_net_desc_label: Label = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_SellOneNet/CardMargin/CardContent/ActionDescLabel
@onready var sell_one_net_status_label: Label = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_SellOneNet/CardMargin/CardContent/ActionStatusLabel
@onready var sell_one_net_button: Button = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_SellOneNet/CardMargin/CardContent/SellOneNetButton
@onready var harvest_self_card: PanelContainer = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_ContinueNet
@onready var harvest_self_title_label: Label = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_ContinueNet/CardMargin/CardContent/ActionTitleLabel
@onready var harvest_self_desc_label: Label = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_ContinueNet/CardMargin/CardContent/ActionDescLabel
@onready var harvest_self_status_label: Label = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_ContinueNet/CardMargin/CardContent/ActionStatusLabel
@onready var harvest_self_button: Button = $SafeArea/PageLayout/ContentScroll/Content/ActionSection/ActionCard_ContinueNet/CardMargin/CardContent/HarvestSelfButton
@onready var ledger_accordion: PanelContainer = $SafeArea/PageLayout/ContentScroll/Content/LedgerAccordion
@onready var ledger_toggle_button: Button = $SafeArea/PageLayout/ContentScroll/Content/LedgerAccordion/AccordionMargin/AccordionContent/LedgerToggleButton
@onready var ledger_detail_label: Label = $SafeArea/PageLayout/ContentScroll/Content/LedgerAccordion/AccordionMargin/AccordionContent/LedgerDetailLabel
@onready var ledger_accordion_content: VBoxContainer = $SafeArea/PageLayout/ContentScroll/Content/LedgerAccordion/AccordionMargin/AccordionContent
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
var transfer_offer_highlight_label: Label
var transfer_total_invested_value: Label
var transfer_offer_price_value: Label
var transfer_profit_loss_value: Label
var transfer_profit_loss_status_label: Label
var transfer_money_after_accept_value: Label
var transfer_risk_note_label: Label
var accept_transfer_button: Button
var reject_transfer_button: Button
var harvest_result_overlay: Control
var harvest_result_dialog: PanelContainer
var harvest_result_title: Label
var harvest_catch_list: VBoxContainer
var harvest_fish_revenue_value: Label
var harvest_net_cost_value: Label
var harvest_net_profit_value: Label
var harvest_result_label: Label
var harvest_continue_button: Button
var pending_harvest_result: Dictionary = {}
var harvest_collect_locked := false
var net_option_empty_state: Label
var latest_net_result: Dictionary = {}
var ledger_expanded := false
var ledger_detail_card: PanelContainer
var ledger_detail_content: VBoxContainer

# ---- 卖一网状态机 ----
enum SellOneNetState {
	LOCKED_NO_CATCH,  # 还没下过网，无鱼获
	AVAILABLE,        # 有鱼获且有报价，可卖
	NO_BUYER,         # 有鱼获但暂无买家
	SOLD              # 已经卖过了
}

var _sell_one_net_overlay: Control
var _sell_one_net_dialog: PanelContainer
var _sell_one_net_offer_price_label: Label
var _sell_one_net_current_money_label: Label
var _sell_one_net_after_money_label: Label
var _sell_one_net_highlight_label: Label
var _sell_one_net_accept_button: Button
var _sell_one_net_reject_button: Button
var _sell_one_net_result_banner: PanelContainer
var _sell_one_net_banner_title: Label
var _sell_one_net_banner_detail: Label
var _revenue_breakdown_label: Label
var _last_sell_one_net_income: int = 0

func setup(next_game_state: GameState, next_screen_container: Control) -> void:
	game_state = next_game_state
	screen_container = next_screen_container

func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()

	_create_owned_pond_visual()
	_create_revenue_breakdown_label()
	_rebuild_work_plan_cards()
	_create_transfer_dialog()
	_create_harvest_result_dialog()
	_create_sell_one_net_dialog()
	transfer_button.pressed.connect(_on_transfer_pressed)
	sell_one_net_button.pressed.connect(_on_sell_one_net_pressed)
	harvest_self_button.pressed.connect(_on_harvest_self_pressed)
	work_plan_back_button.pressed.connect(_on_work_plan_back_pressed)
	ledger_toggle_button.pressed.connect(_on_ledger_toggle_pressed)
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
	UIKit.style_card(latest_net_result_card, UIKit.GOLD)
	UIKit.style_label(latest_title_label, "section")
	UIKit.style_label(latest_method_label, "body_dark")
	UIKit.style_label(latest_revenue_label, "body_dark")
	UIKit.style_label(latest_cost_label, "body_dark")
	UIKit.style_label(latest_profit_label, "body_dark")
	UIKit.style_label(_revenue_breakdown_label, "muted")
	UIKit.style_label(action_section_title, "section")
	_style_ledger_rows()
	_style_action_card(transfer_card, transfer_button, "secondary")
	_style_action_card(sell_one_net_card, sell_one_net_button, "ghost")
	_style_action_card(harvest_self_card, harvest_self_button, "primary")
	UIKit.style_card(ledger_accordion, UIKit.GOLD)
	UIKit.style_button(ledger_toggle_button, "ghost")
	UIKit.style_label(ledger_detail_label, "body_dark")
	_create_ledger_detail_card()
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

func _create_revenue_breakdown_label() -> void:
	if is_instance_valid(_revenue_breakdown_label):
		return
	var ledger_summary := $SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary as VBoxContainer
	var revenue_row := $SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/RevenueRow as PanelContainer
	_revenue_breakdown_label = Label.new()
	_revenue_breakdown_label.name = "RevenueBreakdownLabel"
	_revenue_breakdown_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_revenue_breakdown_label.text = ""
	_revenue_breakdown_label.visible = false
	ledger_summary.add_child(_revenue_breakdown_label)
	ledger_summary.move_child(_revenue_breakdown_label, revenue_row.get_index() + 1)

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

func _create_ledger_detail_card() -> void:
	if ledger_detail_card != null and is_instance_valid(ledger_detail_card):
		return
	ledger_detail_label.visible = false
	ledger_detail_card = PanelContainer.new()
	ledger_detail_card.name = "LedgerDetailCard"
	ledger_detail_card.visible = false
	ledger_detail_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ledger_detail_card.add_theme_stylebox_override("panel", UIKit.make_style(Color(1.0, 0.96, 0.84, 0.96), Color(0.61, 0.45, 0.25, 0.65), 8, 2, false))
	ledger_accordion_content.add_child(ledger_detail_card)

	var margin := MarginContainer.new()
	margin.name = "LedgerDetailMargin"
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	ledger_detail_card.add_child(margin)

	ledger_detail_content = VBoxContainer.new()
	ledger_detail_content.name = "LedgerDetailContent"
	ledger_detail_content.add_theme_constant_override("separation", 10)
	ledger_detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(ledger_detail_content)

func _create_transfer_dialog() -> void:
	var modal := UIKit.create_modal_layer(self, "TransferModal")
	transfer_overlay = modal["overlay"] as Control
	transfer_dialog = modal["card"] as PanelContainer
	var dim_overlay := modal["mask"] as Control
	dim_overlay.name = "DimOverlay"
	transfer_overlay.set_meta("_structure_name", "TransferOfferDialog")
	transfer_dialog.name = "DialogCard"
	# Future art pass: replace this native card with transfer_dialog_bg.png.
	transfer_dialog.set_meta("_future_texture_slot", "transfer_dialog_bg.png")
	transfer_dialog.add_theme_stylebox_override("panel", UIKit.make_style(Color(0.98, 0.90, 0.72, 0.99), UIKit.RED, 16, 4, true))

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 16)
	transfer_dialog.add_child(content)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "有人愿意接手"
	UIKit.style_modal_title(title)
	content.add_child(title)

	transfer_offer_highlight_label = Label.new()
	transfer_offer_highlight_label.name = "OfferHighlight"
	transfer_offer_highlight_label.custom_minimum_size = Vector2(0, 70)
	transfer_offer_highlight_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Future art pass: replace this native badge with offer_price_badge.png.
	transfer_offer_highlight_label.set_meta("_future_texture_slot", "offer_price_badge.png")
	UIKit.style_highlight_label(transfer_offer_highlight_label, "price")
	content.add_child(transfer_offer_highlight_label)

	var body_scroll := ScrollContainer.new()
	body_scroll.name = "BodyScroll"
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(body_scroll)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	body_scroll.add_child(body)

	var buyer_area := HBoxContainer.new()
	buyer_area.name = "BuyerArea"
	buyer_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buyer_area.add_theme_constant_override("separation", 14)
	body.add_child(buyer_area)

	# Future art pass: replace this drawn placeholder with buyer_transfer_placeholder.png.
	var buyer_placeholder := TransferBuyerPlaceholder.new()
	buyer_placeholder.name = "BuyerPlaceholder"
	buyer_placeholder.custom_minimum_size = Vector2(190, 190)
	buyer_placeholder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buyer_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buyer_placeholder.set_meta("_future_texture_slot", "buyer_transfer_placeholder.png")
	buyer_area.add_child(buyer_placeholder)

	var bubble := PanelContainer.new()
	bubble.name = "BuyerSpeechBubble"
	bubble.custom_minimum_size = Vector2(210, 0)
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bubble.add_theme_stylebox_override("panel", UIKit.make_style(Color("fff8df"), Color("6d241f"), 24, 3, true))
	# Future art pass: replace this native bubble with speech_bubble.png.
	bubble.set_meta("_future_texture_slot", "speech_bubble.png")
	buyer_area.add_child(bubble)

	var bubble_margin := MarginContainer.new()
	bubble_margin.add_theme_constant_override("margin_left", 18)
	bubble_margin.add_theme_constant_override("margin_top", 16)
	bubble_margin.add_theme_constant_override("margin_right", 18)
	bubble_margin.add_theme_constant_override("margin_bottom", 16)
	bubble.add_child(bubble_margin)

	var bubble_text := Label.new()
	bubble_text.name = "BuyerSpeechText"
	bubble_text.text = "兄弟一场，把这塘包给我"
	bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble_text.add_theme_font_size_override("font_size", UIKit.FONT_BODY)
	bubble_text.add_theme_color_override("font_color", UIKit.INK)
	bubble_margin.add_child(bubble_text)

	var summary_card := PanelContainer.new()
	summary_card.name = "OfferSummaryCard"
	summary_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_card.add_theme_stylebox_override("panel", UIKit.make_style(Color(1.0, 0.96, 0.84, 0.96), Color(0.61, 0.45, 0.25, 0.85), 10, 3, false))
	body.add_child(summary_card)

	var summary_margin := MarginContainer.new()
	summary_margin.add_theme_constant_override("margin_left", 14)
	summary_margin.add_theme_constant_override("margin_top", 12)
	summary_margin.add_theme_constant_override("margin_right", 14)
	summary_margin.add_theme_constant_override("margin_bottom", 12)
	summary_card.add_child(summary_margin)

	var summary_rows := VBoxContainer.new()
	summary_rows.name = "SummaryRows"
	summary_rows.add_theme_constant_override("separation", 6)
	summary_margin.add_child(summary_rows)

	transfer_total_invested_value = _add_transfer_summary_row(summary_rows, "TotalInvestedRow", "当前总投入")
	transfer_offer_price_value = _add_transfer_summary_row(summary_rows, "OfferPriceRow", "对方接手价")
	transfer_profit_loss_value = _add_transfer_summary_row(summary_rows, "TransferProfitLossRow", "转包盈亏")
	transfer_profit_loss_status_label = Label.new()
	transfer_profit_loss_status_label.name = "TransferProfitLossStatus"
	transfer_profit_loss_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	transfer_profit_loss_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UIKit.style_label(transfer_profit_loss_status_label, "muted")
	summary_rows.add_child(transfer_profit_loss_status_label)
	transfer_money_after_accept_value = _add_transfer_summary_row(summary_rows, "MoneyAfterAcceptRow", "接受后本钱")

	transfer_risk_note_label = Label.new()
	transfer_risk_note_label.name = "RiskNoteLabel"
	transfer_risk_note_label.text = "对方报价只是外面人根据鱼情估出来的价，不等于塘里的真实剩货。"
	transfer_risk_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	transfer_risk_note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(transfer_risk_note_label, "muted")
	body.add_child(transfer_risk_note_label)

	var buttons := HBoxContainer.new()
	buttons.name = "ButtonRow"
	buttons.add_theme_constant_override("separation", 14)
	content.add_child(buttons)

	accept_transfer_button = Button.new()
	accept_transfer_button.name = "AcceptTransferButton"
	accept_transfer_button.text = "接受转包"
	accept_transfer_button.custom_minimum_size = Vector2(0, 96)
	accept_transfer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Future art pass: replace this native button with button_accept.png.
	accept_transfer_button.set_meta("_future_texture_button", "button_accept.png")
	UIKit.style_button(accept_transfer_button, "primary")
	accept_transfer_button.pressed.connect(_on_accept_transfer_pressed)
	buttons.add_child(accept_transfer_button)

	reject_transfer_button = Button.new()
	reject_transfer_button.name = "ContinueButton"
	reject_transfer_button.text = "继续自己扛"
	reject_transfer_button.custom_minimum_size = Vector2(0, 96)
	reject_transfer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Future art pass: replace this native button with button_secondary.png.
	reject_transfer_button.set_meta("_future_texture_button", "button_secondary.png")
	UIKit.style_button(reject_transfer_button, "secondary")
	reject_transfer_button.pressed.connect(_on_reject_transfer_pressed)
	buttons.add_child(reject_transfer_button)

func _add_transfer_summary_row(parent: VBoxContainer, row_name: String, label_text: String) -> Label:
	var row := PanelContainer.new()
	row.name = row_name
	row.custom_minimum_size = Vector2(0, 46)
	row.add_theme_stylebox_override("panel", UIKit.make_style(Color(0.94, 0.86, 0.68, 0.55), Color(0.61, 0.45, 0.25, 0.32), 8, 1, false))
	parent.add_child(row)

	var row_content := HBoxContainer.new()
	row_content.name = "RowContent"
	row_content.add_theme_constant_override("separation", 12)
	row.add_child(row_content)

	var name_label := Label.new()
	name_label.name = "Label"
	name_label.text = "%s：" % label_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIKit.style_label(name_label, "body_dark")
	row_content.add_child(name_label)

	var value_label := Label.new()
	value_label.name = "Value"
	value_label.custom_minimum_size = Vector2(190, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	UIKit.style_label(value_label, "body_dark")
	row_content.add_child(value_label)
	return value_label

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

	# Future art pass: replace this drawn placeholder with catch_result_visual.png.
	var catch_visual := CatchVisualPlaceholder.new()
	catch_visual.name = "CatchVisualPlaceholder"
	catch_visual.custom_minimum_size = Vector2(0, 280)
	catch_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	catch_visual.set_meta("_future_texture_slot", "catch_result_visual.png")
	body.add_child(catch_visual)

	var catch_card := PanelContainer.new()
	catch_card.name = "CatchListCard"
	UIKit.style_card(catch_card, UIKit.GREEN)
	body.add_child(catch_card)

	var catch_margin := MarginContainer.new()
	catch_margin.add_theme_constant_override("margin_left", 16)
	catch_margin.add_theme_constant_override("margin_top", 14)
	catch_margin.add_theme_constant_override("margin_right", 16)
	catch_margin.add_theme_constant_override("margin_bottom", 14)
	catch_card.add_child(catch_margin)

	harvest_catch_list = VBoxContainer.new()
	harvest_catch_list.name = "CatchRows"
	harvest_catch_list.add_theme_constant_override("separation", 8)
	catch_margin.add_child(harvest_catch_list)

	var summary_card := PanelContainer.new()
	summary_card.name = "NetSummaryCard"
	UIKit.style_card(summary_card, UIKit.GOLD)
	body.add_child(summary_card)

	var summary_margin := MarginContainer.new()
	summary_margin.add_theme_constant_override("margin_left", 16)
	summary_margin.add_theme_constant_override("margin_top", 14)
	summary_margin.add_theme_constant_override("margin_right", 16)
	summary_margin.add_theme_constant_override("margin_bottom", 14)
	summary_card.add_child(summary_margin)

	var summary_rows := VBoxContainer.new()
	summary_rows.name = "SummaryRows"
	summary_rows.add_theme_constant_override("separation", 8)
	summary_margin.add_child(summary_rows)
	harvest_fish_revenue_value = _add_transfer_summary_row(summary_rows, "FishRevenueRow", "本次鱼获收入")
	harvest_net_cost_value = _add_transfer_summary_row(summary_rows, "NetCostRow", "本次下网成本")
	harvest_net_profit_value = _add_transfer_summary_row(summary_rows, "NetProfitRow", "本次净收益")

	harvest_result_label = Label.new()
	harvest_result_label.name = "HarvestProfitLabel"
	harvest_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	harvest_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(harvest_result_label, "body_dark")
	body.add_child(harvest_result_label)

	harvest_continue_button = Button.new()
	harvest_continue_button.name = "CollectResultButton"
	harvest_continue_button.text = "收下结果"
	harvest_continue_button.custom_minimum_size = Vector2(0, UIKit.MODAL_ACTION_HEIGHT)
	# Future art pass: replace this native button with TextureButton.
	harvest_continue_button.set_meta("_future_texture_button", "button_primary.png")
	UIKit.style_button(harvest_continue_button, "primary")
	harvest_continue_button.pressed.connect(_on_harvest_result_continue_pressed)
	content.add_child(harvest_continue_button)

func _rebuild_work_plan_cards() -> void:
	for child in work_plan_panel.get_children():
		child.queue_free()
	net_option_empty_state = null
	low_work_button = _create_net_option_card("low", "小捞一网", "低成本试一网，鱼获不稳定。", "捞完还能继续。", false)
	standard_work_button = _create_net_option_card("standard", "稳捞一网", "多下点功夫，鱼获更稳定。", "捞完还能继续。", false)
	full_work_button = _create_net_option_card("full", "抽干收尾", "直接抽干收尾，看清这口塘最后有多少货。", "本塘直接结算。", true)
	_ensure_net_option_list_layout()

func _create_net_option_card(plan_id: String, title_text: String, desc_text: String, consequence_text: String, is_final: bool) -> Button:
	var card := PanelContainer.new()
	card.name = "NetOptionCard_%s" % ("Final" if is_final else "Small" if plan_id == "low" else "Normal")
	card.custom_minimum_size = Vector2(0, 250 if is_final else 220)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.set_meta("_future_texture_slot", "net_option_card_bg.png")
	work_plan_panel.add_child(card)
	UIKit.style_card(card, UIKit.RED if is_final else UIKit.GREEN)

	var margin := MarginContainer.new()
	margin.name = "CardMargin"
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "CardContent"
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)

	# Future art pass: replace this drawn placeholder with net_method_xxx.png.
	var visual := NetMethodPlaceholder.new(plan_id)
	visual.name = "NetMethodPlaceholder"
	visual.custom_minimum_size = Vector2(150, 150)
	visual.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.set_meta("_future_texture_slot", "net_method_%s.png" % plan_id)
	row.add_child(visual)

	var info := VBoxContainer.new()
	info.name = "Info"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 8)
	row.add_child(info)

	var title_row := HBoxContainer.new()
	title_row.name = "TitleRow"
	title_row.add_theme_constant_override("separation", 10)
	info.add_child(title_row)

	var title := Label.new()
	title.name = "MethodTitleLabel"
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIKit.style_label(title, "section")
	title_row.add_child(title)

	if is_final:
		var final_badge := Label.new()
		final_badge.name = "FinalBadge"
		final_badge.text = "收尾"
		final_badge.custom_minimum_size = Vector2(92, 44)
		final_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		final_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UIKit.style_chip(final_badge, UIKit.RED)
		title_row.add_child(final_badge)

	var cost_badge := Label.new()
	cost_badge.name = "CostBadge"
	cost_badge.text = "费用：0 元"
	cost_badge.custom_minimum_size = Vector2(0, 44)
	cost_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIKit.style_highlight_label(cost_badge, "price")
	info.add_child(cost_badge)

	var desc := Label.new()
	desc.name = "MethodDescLabel"
	desc.text = desc_text
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(desc, "body_dark")
	info.add_child(desc)

	var consequence := Label.new()
	consequence.name = "ConsequenceLabel"
	consequence.text = consequence_text
	consequence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(consequence, "muted")
	consequence.add_theme_color_override("font_color", UIKit.RED if is_final else UIKit.MUTED)
	info.add_child(consequence)

	if is_final:
		var warning := Label.new()
		warning.name = "FinalWarningLabel"
		warning.text = "选择后本塘将进入最终结算"
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UIKit.style_label(warning, "muted")
		warning.add_theme_color_override("font_color", UIKit.RED)
		info.add_child(warning)

	var button := Button.new()
	button.name = "%sWorkButton" % ("Low" if plan_id == "low" else "Standard" if plan_id == "standard" else "Full")
	button.custom_minimum_size = Vector2(0, 74)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = title_text
	button.set_meta("_future_texture_button", "button_primary.png" if is_final else "button_secondary.png")
	UIKit.style_button(button, "primary" if is_final else "secondary")
	button.pressed.connect(_on_work_plan_pressed.bind(plan_id))
	info.add_child(button)
	return button

func _render() -> void:
	var pond := game_state.current_pond
	pond_name_label.text = "已包下：%s" % str(pond.get("name", "未承包鱼塘"))
	day_label.text = "第 %d 天" % game_state.day
	cash_label.text = "本钱：%d 元" % game_state.cash
	_render_ledger()
	_render_latest_net_result()
	_render_ledger_accordion()

	var has_net_result := not latest_net_result.is_empty() or game_state.self_net_count > 0 or game_state.fish_income > 0
	harvest_self_title_label.text = "继续下网" if has_net_result else "自己下网"
	harvest_self_desc_label.text = "再下一网，看看塘里还有多少货。" if has_net_result else "继续投入开工成本，看看这口塘到底有没有货。"
	harvest_self_button.text = "继续下网" if has_net_result else "开始下网"
	transfer_button.text = "去转包"
	transfer_button.disabled = current_transfer_offer.is_empty() or game_state.drained
	harvest_self_button.disabled = not game_state.can_pay(game_state.get_work_cost("low"))
	transfer_status_label.text = "有接手价" if not transfer_button.disabled else "暂无报价"
	harvest_self_status_label.text = "主操作" if not harvest_self_button.disabled else "本钱不够"
	if current_transfer_offer.is_empty():
		transfer_button.text = "暂无报价"

	# ---- 卖一网状态机渲染 ----
	var current_state := _get_sell_one_net_state()
	match current_state:
		SellOneNetState.LOCKED_NO_CATCH:
			sell_one_net_card.visible = true
			sell_one_net_status_label.text = "未解锁"
			sell_one_net_desc_label.text = "先下一网，有鱼情才有人报价。"
			sell_one_net_button.text = "暂无买家"
			sell_one_net_button.disabled = true
			_set_banner_visible(false)
		SellOneNetState.AVAILABLE:
			sell_one_net_card.visible = true
			sell_one_net_status_label.text = "有报价"
			sell_one_net_desc_label.text = "有人愿意出钱买这一网，接受后立刻入账。"
			sell_one_net_button.text = "查看报价"
			sell_one_net_button.disabled = false
			_set_banner_visible(false)
		SellOneNetState.NO_BUYER:
			sell_one_net_card.visible = true
			sell_one_net_status_label.text = "暂无买家"
			sell_one_net_desc_label.text = "现在没人出价，可以继续下网看看。"
			sell_one_net_button.text = "暂无买家"
			sell_one_net_button.disabled = true
			_set_banner_visible(false)
		SellOneNetState.SOLD:
			sell_one_net_card.visible = false
			sell_one_net_button.disabled = true
			_set_banner_visible(true)
			var sold_income := _last_sell_one_net_income if _last_sell_one_net_income > 0 else game_state.one_net_income
			if sold_income > 0:
				_set_banner_text("卖一网成功：+%d 元已入账" % sold_income, "这一网已卖出，不能重复卖")
			else:
				_set_banner_text("这一网已经卖过", "不能重复卖")

	_update_work_buttons()

func _render_ledger() -> void:
	var ledger := _get_current_ledger()
	contract_price_value.text = "%d 元" % int(ledger.get("pond_price", 0))
	inspection_spent_value.text = "%d 元" % int(ledger.get("inspection_spent", 0))
	total_invested_value.text = "%d 元" % int(ledger.get("total_invested", 0))
	revenue_value.text = "%d 元" % int(ledger.get("revenue", 0))
	_render_revenue_breakdown()
	var current_profit_loss := int(ledger.get("current_profit_loss", 0))
	profit_loss_value.text = "%+d 元" % current_profit_loss if current_profit_loss != 0 else "0 元"
	UIKit.style_label(profit_loss_value, "body_dark")
	profit_loss_value.add_theme_color_override("font_color", UIKit.GREEN if current_profit_loss > 0 else UIKit.RED if current_profit_loss < 0 else UIKit.INK)
	profit_loss_row.add_theme_stylebox_override("panel", UIKit.make_style(Color(1.0, 0.92, 0.70, 0.95), UIKit.GREEN_LIGHT if current_profit_loss > 0 else UIKit.RED if current_profit_loss < 0 else UIKit.GOLD, 8, 3, false))

func _render_revenue_breakdown() -> void:
	if not is_instance_valid(_revenue_breakdown_label):
		return
	var fish_revenue := game_state.fish_income
	var one_net_revenue := game_state.one_net_income
	var transfer_revenue := game_state.transfer_income
	var parts := PackedStringArray()
	if fish_revenue > 0:
		parts.append("鱼获收入 %d 元" % fish_revenue)
	if one_net_revenue > 0:
		parts.append("卖一网入账 +%d 元" % one_net_revenue)
	if transfer_revenue > 0:
		parts.append("转包入账 %d 元" % transfer_revenue)
	_revenue_breakdown_label.visible = parts.size() > 1 or one_net_revenue > 0
	_revenue_breakdown_label.text = " + ".join(parts) if _revenue_breakdown_label.visible else ""

func _render_latest_net_result() -> void:
	latest_net_result_card.visible = not latest_net_result.is_empty()
	if latest_net_result.is_empty():
		return
	var method_name := _plan_display_name(str(latest_net_result.get("plan_id", "")))
	var fish_revenue := int(latest_net_result.get("fish_income", 0))
	var net_cost := int(latest_net_result.get("work_cost", 0))
	var latest_net_profit := fish_revenue - net_cost
	latest_method_label.text = "最新一网：%s" % method_name
	latest_revenue_label.text = "鱼获收入：%d 元" % fish_revenue
	latest_cost_label.text = "本次成本：%d 元" % net_cost
	if latest_net_profit > 0:
		latest_profit_label.text = "本次净赚：+%d 元" % latest_net_profit
	elif latest_net_profit < 0:
		latest_profit_label.text = "本次净亏：%d 元" % latest_net_profit
	else:
		latest_profit_label.text = "本次打平：0 元"
	latest_profit_label.add_theme_color_override("font_color", UIKit.GREEN if latest_net_profit > 0 else UIKit.RED if latest_net_profit < 0 else UIKit.INK)

func _render_ledger_accordion() -> void:
	var ledger := _get_ledger_display_totals()
	var realized_profit_loss := int(ledger.get("realized_profit_loss", 0))
	var estimated_profit_loss := int(ledger.get("estimated_profit_loss", 0))
	ledger_toggle_button.text = "收起账本明细" if ledger_expanded else "账本明细：已实现 %s｜含估值 %s" % [
		_format_signed_amount(realized_profit_loss),
		_format_signed_amount(estimated_profit_loss)
	]
	ledger_detail_label.visible = false
	if ledger_detail_card == null or not is_instance_valid(ledger_detail_card):
		_create_ledger_detail_card()
	ledger_detail_card.visible = ledger_expanded
	if ledger_expanded:
		_render_ledger_detail_card(ledger)

func _get_ledger_display_totals() -> Dictionary:
	var ledger := _get_current_ledger()
	var fish_revenue := game_state.fish_income
	var sell_one_net_revenue := game_state.one_net_income
	var transfer_revenue := game_state.transfer_income
	var other_income := 0
	var income_total := fish_revenue + sell_one_net_revenue + transfer_revenue + other_income

	var contract_cost := int(ledger.get("pond_price", 0))
	var inspection_cost := int(ledger.get("inspection_spent", 0))
	var net_cost_total := int(ledger.get("fishing_cost", 0))
	var labor_cost := 0
	var pump_cost := 0
	var transport_cost := int(ledger.get("transport_cost", 0))
	var other_cost := 0
	var expense_total := contract_cost + inspection_cost + net_cost_total + labor_cost + pump_cost + transport_cost + other_cost

	var realized_profit_loss := income_total - expense_total
	var pond_remaining_estimated_value := game_state.get_current_pond_estimated_value()
	var estimated_profit_loss := realized_profit_loss + pond_remaining_estimated_value
	return {
		"fish_revenue": fish_revenue,
		"sell_one_net_revenue": sell_one_net_revenue,
		"transfer_revenue": transfer_revenue,
		"other_income": other_income,
		"income_total": income_total,
		"contract_cost": contract_cost,
		"inspection_cost": inspection_cost,
		"net_cost_total": net_cost_total,
		"labor_cost": labor_cost,
		"pump_cost": pump_cost,
		"transport_cost": transport_cost,
		"other_cost": other_cost,
		"expense_total": expense_total,
		"realized_profit_loss": realized_profit_loss,
		"pond_remaining_estimated_value": pond_remaining_estimated_value,
		"estimated_profit_loss": estimated_profit_loss
	}

func _render_ledger_detail_card(ledger: Dictionary) -> void:
	for child in ledger_detail_content.get_children():
		child.queue_free()

	ledger_detail_content.add_child(_make_ledger_section("收入", [
		{"label": "鱼获收入", "value": int(ledger.get("fish_revenue", 0))},
		{"label": "卖一网收入", "value": int(ledger.get("sell_one_net_revenue", 0))},
		{"label": "转包收入", "value": int(ledger.get("transfer_revenue", 0))},
		{"label": "其他收入", "value": int(ledger.get("other_income", 0))},
		{"label": "收入合计", "value": int(ledger.get("income_total", 0)), "always": true, "total": true}
	]))
	ledger_detail_content.add_child(_make_ledger_section("支出", [
		{"label": "承包费", "value": int(ledger.get("contract_cost", 0))},
		{"label": "验塘费", "value": int(ledger.get("inspection_cost", 0))},
		{"label": "下网作业费", "value": int(ledger.get("net_cost_total", 0))},
		{"label": "人工费", "value": int(ledger.get("labor_cost", 0))},
		{"label": "抽水费", "value": int(ledger.get("pump_cost", 0))},
		{"label": "鱼车 / 运输费", "value": int(ledger.get("transport_cost", 0))},
		{"label": "其他支出", "value": int(ledger.get("other_cost", 0))},
		{"label": "支出合计", "value": int(ledger.get("expense_total", 0)), "always": true, "total": true}
	]))
	ledger_detail_content.add_child(_make_ledger_section("塘口估值", [
		{"label": "塘内剩余估值", "value": int(ledger.get("pond_remaining_estimated_value", 0)), "always": true}
	], "估值不是已入账现金，只是当前判断。"))
	ledger_detail_content.add_child(_make_ledger_section("账本结果", [
		{"label": "已实现盈亏", "value": int(ledger.get("realized_profit_loss", 0)), "always": true, "signed": true, "total": true},
		{"label": "含估值盈亏", "value": int(ledger.get("estimated_profit_loss", 0)), "always": true, "signed": true, "total": true}
	]))

func _make_ledger_section(title_text: String, rows: Array, note := "") -> PanelContainer:
	var section := PanelContainer.new()
	section.name = "%sSection" % title_text
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_stylebox_override("panel", UIKit.make_style(Color(0.98, 0.91, 0.74, 0.80), Color(0.61, 0.45, 0.25, 0.42), 8, 1, false))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	section.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(stack)

	var title := UIKit.make_label(title_text, UIKit.FONT_SECTION, UIKit.GREEN, HORIZONTAL_ALIGNMENT_LEFT)
	title.name = "SectionTitleLabel"
	stack.add_child(title)

	for row_variant in rows:
		var row := row_variant as Dictionary
		var value := int(row.get("value", 0))
		if value == 0 and not bool(row.get("always", false)):
			continue
		stack.add_child(_make_ledger_row(
			str(row.get("label", "")),
			value,
			bool(row.get("signed", false)),
			bool(row.get("total", false))
		))

	if not note.is_empty():
		var note_label := UIKit.make_label(note, UIKit.FONT_SECONDARY, UIKit.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		note_label.name = "SectionNoteLabel"
		stack.add_child(note_label)
	return section

func _make_ledger_row(label_text: String, amount: int, signed := false, total := false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "LedgerRow"
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, 34 if not total else 42)

	var name_label := UIKit.make_label(label_text, UIKit.FONT_BODY if not total else UIKit.FONT_SECTION, UIKit.INK, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_label)

	var value_label := UIKit.make_label(_format_signed_amount(amount) if signed else "%d 元" % amount, UIKit.FONT_BODY if not total else UIKit.FONT_SECTION, _amount_color(amount) if signed else UIKit.INK, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.name = "Value"
	value_label.custom_minimum_size = Vector2(220, 0)
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(value_label)
	return row

func _format_signed_amount(amount: int) -> String:
	if amount > 0:
		return "+%d 元" % amount
	if amount < 0:
		return "%d 元" % amount
	return "0 元"

func _amount_color(amount: int) -> Color:
	if amount > 0:
		return UIKit.GREEN
	if amount < 0:
		return UIKit.RED
	return UIKit.INK

func _plan_display_name(plan_id: String) -> String:
	match plan_id:
		"low":
			return "小捞一网"
		"standard":
			return "稳捞一网"
		"full", "drain":
			return "抽干收尾"
		_:
			return "这一网"

func _on_ledger_toggle_pressed() -> void:
	ledger_expanded = not ledger_expanded
	_render_ledger_accordion()

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

func _get_transfer_decision_ledger() -> Dictionary:
	var ledger := _get_current_ledger()
	var current_money := int(ledger.get("current_money", 0))
	var pond_price := int(ledger.get("pond_price", 0))
	var inspection_spent := int(ledger.get("inspection_spent", 0))
	var fishing_cost := int(ledger.get("fishing_cost", 0))
	var transport_cost := int(ledger.get("transport_cost", 0))
	var revenue := int(ledger.get("revenue", 0))
	var offer_price := int(current_transfer_offer.get("income", 0))
	var total_invested := pond_price + inspection_spent + fishing_cost + transport_cost
	var transfer_profit_loss := offer_price - total_invested
	var money_after_accept := current_money + offer_price
	return {
		"current_money": current_money,
		"pond_price": pond_price,
		"inspection_spent": inspection_spent,
		"fishing_cost": fishing_cost,
		"transport_cost": transport_cost,
		"revenue": revenue,
		"offer_price": offer_price,
		"total_invested": total_invested,
		"transfer_profit_loss": transfer_profit_loss,
		"money_after_accept": money_after_accept
	}

func _render_transfer_decision_dialog() -> Dictionary:
	var ledger := _get_transfer_decision_ledger()
	var offer_price := int(ledger.get("offer_price", 0))
	var total_invested := int(ledger.get("total_invested", 0))
	var transfer_profit_loss := int(ledger.get("transfer_profit_loss", 0))
	var money_after_accept := int(ledger.get("money_after_accept", 0))

	transfer_offer_highlight_label.text = "对方报价：%d 元" % offer_price
	transfer_total_invested_value.text = "%d 元" % total_invested
	transfer_offer_price_value.text = "%d 元" % offer_price
	transfer_profit_loss_value.text = "%+d 元" % transfer_profit_loss if transfer_profit_loss != 0 else "0 元"
	transfer_money_after_accept_value.text = "%d 元" % money_after_accept

	var outcome_text := "不赚不亏"
	var outcome_tone := "gold"
	if transfer_profit_loss < 0:
		outcome_text = "亏钱止损"
		outcome_tone = "negative"
	elif transfer_profit_loss > 0:
		outcome_text = "转手赚了"
		outcome_tone = "positive"

	transfer_profit_loss_status_label.text = outcome_text
	UIKit.style_label(transfer_profit_loss_value, "body_dark")
	transfer_profit_loss_value.add_theme_color_override("font_color", UIKit.RED if transfer_profit_loss < 0 else UIKit.GREEN if transfer_profit_loss > 0 else UIKit.INK)
	UIKit.style_label(transfer_profit_loss_status_label, "muted")
	transfer_profit_loss_status_label.add_theme_color_override("font_color", UIKit.RED if transfer_profit_loss < 0 else UIKit.GREEN if transfer_profit_loss > 0 else UIKit.MUTED)

	if transfer_profit_loss < 0:
		accept_transfer_button.text = "接受转包（亏%d元）" % abs(transfer_profit_loss)
		UIKit.style_button(accept_transfer_button, "gold")
	elif transfer_profit_loss > 0:
		accept_transfer_button.text = "接受转包（赚%d元）" % transfer_profit_loss
		UIKit.style_button(accept_transfer_button, "primary")
	else:
		accept_transfer_button.text = "接受转包（不赚不亏）"
		UIKit.style_button(accept_transfer_button, "gold")
	accept_transfer_button.add_theme_font_size_override("font_size", 26)
	reject_transfer_button.add_theme_font_size_override("font_size", 26)
	accept_transfer_button.disabled = false
	accept_transfer_button.set_meta("_future_texture_button", "button_accept.png")
	UIKit.style_highlight_label(transfer_offer_highlight_label, outcome_tone)
	return ledger

func _hide_detail_panels() -> void:
	_close_transfer_dialog()
	_close_sell_one_net_dialog()
	_show_choice_page()

func _show_choice_page() -> void:
	title_label.text = "塘已经包下"
	subtitle_label.text = "看清现在亏多少，再决定下一步。"
	owned_pond_card.custom_minimum_size = Vector2(0, 360)
	owned_pond_card.visible = true
	pond_visual_host.visible = true
	pond_visual_host.custom_minimum_size = Vector2(0, 112)
	_set_ledger_row_visibility(false)
	latest_net_result_card.visible = not latest_net_result.is_empty()
	action_section.visible = true
	ledger_accordion.visible = true
	work_plan_back_button.visible = false
	work_plan_scroll.visible = false

func _show_work_plan_page() -> void:
	title_label.text = "自己下网"
	subtitle_label.text = "选一种下网方式，成本越高，越可能看到真东西。"
	owned_pond_card.custom_minimum_size = Vector2(0, 238)
	owned_pond_card.visible = true
	pond_visual_host.visible = false
	_set_ledger_row_visibility(false)
	latest_net_result_card.visible = false
	action_section.visible = false
	ledger_accordion.visible = false
	work_plan_back_button.visible = true
	work_plan_scroll.visible = true
	_ensure_net_option_list_layout()

func _set_ledger_row_visibility(show_full: bool) -> void:
	$SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/ContractPriceRow.visible = show_full
	$SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/InspectionSpentRow.visible = show_full
	$SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/RevenueRow.visible = true

func _close_transfer_dialog() -> void:
	UIKit.hide_modal(transfer_overlay)

func _get_sell_one_net_state() -> int:
	if game_state.sold_one_net:
		return SellOneNetState.SOLD

	# LOCKED_NO_CATCH: no net result and no fish income yet
	var has_any_catch := not latest_net_result.is_empty() or game_state.self_net_count > 0 or game_state.fish_income > 0
	if not has_any_catch:
		return SellOneNetState.LOCKED_NO_CATCH

	# NO_BUYER: has catch but no one_net_offer
	if current_one_net_offer.is_empty():
		return SellOneNetState.NO_BUYER

	# AVAILABLE: has catch and has offer
	return SellOneNetState.AVAILABLE

func _create_sell_one_net_dialog() -> void:
	var modal := UIKit.create_modal_layer(self, "SellOneNetModal")
	_sell_one_net_overlay = modal["overlay"] as Control
	_sell_one_net_dialog = modal["card"] as PanelContainer
	var dim_overlay := modal["mask"] as Control
	dim_overlay.name = "SellOneNetDimOverlay"
	_sell_one_net_overlay.set_meta("_structure_name", "SellOneNetDialog")
	_sell_one_net_dialog.name = "SellOneNetDialogCard"
	_sell_one_net_dialog.add_theme_stylebox_override("panel", UIKit.make_style(Color(0.98, 0.90, 0.72, 0.99), UIKit.GREEN, 16, 4, true))

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 14)
	_sell_one_net_dialog.add_child(content)

	# -- Title --
	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "有人要买这一网"
	UIKit.style_modal_title(title)
	content.add_child(title)

	# -- Offer price highlight --
	_sell_one_net_highlight_label = Label.new()
	_sell_one_net_highlight_label.name = "SellOneNetOfferHighlight"
	_sell_one_net_highlight_label.custom_minimum_size = Vector2(0, 64)
	_sell_one_net_highlight_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_highlight_label(_sell_one_net_highlight_label, "price")
	content.add_child(_sell_one_net_highlight_label)

	# -- Deal summary rows --
	var summary := VBoxContainer.new()
	summary.name = "DealSummaryRows"
	summary.add_theme_constant_override("separation", 6)
	summary.custom_minimum_size = Vector2(0, 8)
	content.add_child(summary)

	_sell_one_net_offer_price_label = Label.new()
	_sell_one_net_offer_price_label.name = "ImmediateIncomeRow"
	_sell_one_net_offer_price_label.text = "接受后入账：+0 元"
	_sell_one_net_offer_price_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(_sell_one_net_offer_price_label, "body_dark")
	summary.add_child(_sell_one_net_offer_price_label)

	_sell_one_net_current_money_label = Label.new()
	_sell_one_net_current_money_label.name = "CurrentMoneyRow"
	_sell_one_net_current_money_label.text = "当前本钱：0 元"
	_sell_one_net_current_money_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(_sell_one_net_current_money_label, "body_dark")
	summary.add_child(_sell_one_net_current_money_label)

	_sell_one_net_after_money_label = Label.new()
	_sell_one_net_after_money_label.name = "MoneyAfterSellOneNetRow"
	_sell_one_net_after_money_label.text = "接受后本钱：0 元"
	_sell_one_net_after_money_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(_sell_one_net_after_money_label, "body_dark")
	summary.add_child(_sell_one_net_after_money_label)

	var sold_state_row := Label.new()
	sold_state_row.name = "SoldStateRow"
	sold_state_row.text = "卖出后：这一网不能重复卖"
	sold_state_row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(sold_state_row, "body_dark")
	summary.add_child(sold_state_row)

	# -- Explain text --
	var explain := Label.new()
	explain.name = "ExplainText"
	explain.text = "买家只买这一网，不买整口塘。接受后，这一网会标记为已卖出。"
	explain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(explain, "muted")
	content.add_child(explain)

	# -- Buttons --
	var buttons := HBoxContainer.new()
	buttons.name = "ButtonRow"
	buttons.add_theme_constant_override("separation", 14)
	content.add_child(buttons)

	_sell_one_net_reject_button = Button.new()
	_sell_one_net_reject_button.name = "RejectSellOneNetButton"
	_sell_one_net_reject_button.text = "再等等"
	_sell_one_net_reject_button.custom_minimum_size = Vector2(0, 78)
	_sell_one_net_reject_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIKit.style_button(_sell_one_net_reject_button, "ghost")
	_sell_one_net_reject_button.pressed.connect(_on_sell_one_net_reject_pressed)
	buttons.add_child(_sell_one_net_reject_button)

	_sell_one_net_accept_button = Button.new()
	_sell_one_net_accept_button.name = "AcceptSellOneNetButton"
	_sell_one_net_accept_button.text = "接受卖出"
	_sell_one_net_accept_button.custom_minimum_size = Vector2(0, 78)
	_sell_one_net_accept_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIKit.style_button(_sell_one_net_accept_button, "primary")
	_sell_one_net_accept_button.pressed.connect(_on_sell_one_net_accept_pressed)
	buttons.add_child(_sell_one_net_accept_button)

	# -- Create result banner (placed in page content, shown after sold) --
	_sell_one_net_result_banner = PanelContainer.new()
	_sell_one_net_result_banner.name = "SellOneNetResultBanner"
	_sell_one_net_result_banner.custom_minimum_size = Vector2(0, 112)
	_sell_one_net_result_banner.add_theme_stylebox_override("panel", UIKit.make_style(Color(0.88, 0.96, 0.82, 0.96), UIKit.GREEN, 10, 3, false))
	_sell_one_net_result_banner.visible = false

	var banner_margin := MarginContainer.new()
	banner_margin.add_theme_constant_override("margin_left", 20)
	banner_margin.add_theme_constant_override("margin_top", 14)
	banner_margin.add_theme_constant_override("margin_right", 20)
	banner_margin.add_theme_constant_override("margin_bottom", 14)
	_sell_one_net_result_banner.add_child(banner_margin)

	var banner_content := VBoxContainer.new()
	banner_content.name = "BannerContent"
	banner_content.add_theme_constant_override("separation", 6)
	banner_margin.add_child(banner_content)

	_sell_one_net_banner_title = Label.new()
	_sell_one_net_banner_title.name = "BannerTitle"
	_sell_one_net_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sell_one_net_banner_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(_sell_one_net_banner_title, "section")
	_sell_one_net_banner_title.add_theme_color_override("font_color", UIKit.GREEN)
	banner_content.add_child(_sell_one_net_banner_title)

	_sell_one_net_banner_detail = Label.new()
	_sell_one_net_banner_detail.name = "BannerDetail"
	_sell_one_net_banner_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sell_one_net_banner_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(_sell_one_net_banner_detail, "body_dark")
	banner_content.add_child(_sell_one_net_banner_detail)
	# Insert after LatestNetResultCard in the page content
	if is_instance_valid(content_container) and is_instance_valid(latest_net_result_card):
		var latest_index: int = latest_net_result_card.get_index()
		content_container.add_child(_sell_one_net_result_banner)
		content_container.move_child(_sell_one_net_result_banner, maxi(0, latest_index + 1))
	else:
		push_warning("SellOneNetDialog: content_container or latest_net_result_card not available; banner not placed.")

func _close_sell_one_net_dialog() -> void:
	UIKit.hide_modal(_sell_one_net_overlay)

func _set_banner_visible(flag: bool) -> void:
	if is_instance_valid(_sell_one_net_result_banner):
		_sell_one_net_result_banner.visible = flag

func _set_banner_text(title: String, detail := "这一网已卖出，不能重复卖") -> void:
	if is_instance_valid(_sell_one_net_banner_title):
		_sell_one_net_banner_title.text = title
	if is_instance_valid(_sell_one_net_banner_detail):
		_sell_one_net_banner_detail.text = detail

func _show_sell_one_net_dialog() -> void:
	var income := int(current_one_net_offer.get("income", 0))
	var current_money := game_state.cash
	var money_after_sell_one_net := current_money + income
	_sell_one_net_highlight_label.text = "买家出价：%d 元" % income
	_sell_one_net_offer_price_label.text = "接受后入账：+%d 元" % income
	_sell_one_net_current_money_label.text = "当前本钱：%d 元" % current_money
	_sell_one_net_after_money_label.text = "接受后本钱：%d 元" % money_after_sell_one_net
	_sell_one_net_accept_button.text = "接受卖出（+%d）" % income
	_sell_one_net_accept_button.disabled = false
	_show_auto_sell_one_net_modal()

func _show_auto_sell_one_net_modal() -> void:
	_layout_sell_one_net_modal()
	_sell_one_net_overlay.visible = true
	move_child(_sell_one_net_overlay, get_child_count() - 1)

func _layout_sell_one_net_modal() -> void:
	var viewport_size := Vector2i(size)
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		viewport_size = Vector2i(get_viewport_rect().size)
	var safe_width := maxi(1, viewport_size.x - 48)
	var safe_height := maxi(1, viewport_size.y - 48)
	var target_width := clampi(int(viewport_size.x * 0.90), mini(340, safe_width), mini(920, safe_width))
	var max_height := mini(int(viewport_size.y * 0.80), safe_height)
	var content_height := _get_sell_one_net_dialog_content_height()
	var target_height := mini(maxi(content_height, 1), max_height)
	_sell_one_net_dialog.size = Vector2(target_width, target_height)
	_sell_one_net_dialog.position = Vector2((viewport_size.x - target_width) * 0.5, (viewport_size.y - target_height) * 0.5)

func _get_sell_one_net_dialog_content_height() -> int:
	# Avoid Godot autowrap minimum-size overestimation, which can stretch this compact dialog to the 80% cap.
	return 430

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
	_render_transfer_decision_dialog()
	UIKit.show_modal(self, transfer_overlay, transfer_dialog, 0.90, 1100, Vector2i(340, 640), Vector2i(920, 1180))
	message_label.text = ""

func _on_accept_transfer_pressed() -> void:
	if accept_transfer_button.disabled:
		return
	var ledger := _get_transfer_decision_ledger()
	var transfer_profit_loss := int(ledger.get("transfer_profit_loss", 0))
	if transfer_profit_loss < 0:
		accept_transfer_button.disabled = true
		_show_global_confirm({
			"title": "确定亏钱转包？",
			"body": "接受后本塘亏损 %d 元，但可以提前止损。" % abs(transfer_profit_loss),
			"cancel_text": "再想想",
			"confirm_text": "确定转包",
			"on_confirm": Callable(self, "_confirm_accept_transfer"),
			"on_cancel": Callable(self, "_on_cancel_loss_transfer_confirm")
		})
		return
	_confirm_accept_transfer()

func _confirm_accept_transfer() -> void:
	if accept_transfer_button != null:
		accept_transfer_button.disabled = true
	_close_transfer_dialog()
	var ledger := _get_transfer_decision_ledger()
	game_state.apply_transfer(int(ledger.get("offer_price", 0)), int(ledger.get("transfer_profit_loss", 0)))
	UIController.show_settlement(screen_container, game_state)

func _on_cancel_loss_transfer_confirm() -> void:
	if accept_transfer_button != null and transfer_overlay != null and transfer_overlay.visible:
		accept_transfer_button.disabled = false

func _on_reject_transfer_pressed() -> void:
	_close_transfer_dialog()
	message_label.text = "你没接这个转包价。后面是赚是亏，继续自己扛。"
	_render()

func _on_viewport_size_changed() -> void:
	if transfer_overlay != null and transfer_overlay.visible:
		UIKit.layout_modal(self, transfer_dialog, 0.90, 1100, Vector2i(340, 640), Vector2i(920, 1180))
	if harvest_result_overlay != null and harvest_result_overlay.visible:
		UIKit.layout_modal(self, harvest_result_dialog, 0.86, 1060, Vector2i(340, 700), Vector2i(860, 1160))
	if _sell_one_net_overlay != null and _sell_one_net_overlay.visible:
		_layout_sell_one_net_modal()

func _on_sell_one_net_pressed() -> void:
	var current_state := _get_sell_one_net_state()

	if current_state != SellOneNetState.AVAILABLE:
		message_label.text = "当前不能卖一网。"
		_render()
		return

	_hide_detail_panels()
	_show_sell_one_net_dialog()

func _on_sell_one_net_accept_pressed() -> void:
	if _sell_one_net_accept_button.disabled:
		return

	_sell_one_net_accept_button.disabled = true
	if current_one_net_offer.is_empty():
		message_label.text = "卖一网报价已过期，无法完成交易。"
		_close_sell_one_net_dialog()
		_render()
		return
	if game_state.sold_one_net:
		message_label.text = "这一网已经卖过，不能重复交易。"
		_close_sell_one_net_dialog()
		_render()
		return

	var income := int(current_one_net_offer.get("income", 0))
	if game_state.apply_one_net(income, str(current_one_net_offer.get("text", ""))):
		_last_sell_one_net_income = income
		_set_banner_text("卖一网成功：+%d 元已入账" % income, "这一网已卖出，不能重复卖")
		_set_banner_visible(true)
		message_label.text = "卖一网成功，+%d 元已入账。" % income
		current_one_net_offer = {}
		_refresh_transfer_offer()
	_close_sell_one_net_dialog()
	_render()

func _on_sell_one_net_reject_pressed() -> void:
	_close_sell_one_net_dialog()
	message_label.text = "你决定先不出售这一网，继续看看行情。"
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

	if plan_id == "full":
		_show_global_confirm({
			"title": "确定抽干收尾？",
			"body": "抽干后这口塘会直接结算，不能再继续下网。",
			"cancel_text": "再想想",
			"confirm_text": "抽干收尾",
			"on_confirm": Callable(self, "_execute_work_plan").bind(plan_id)
		})
		return
	_execute_work_plan(plan_id)

func _execute_work_plan(plan_id: String) -> void:
	var cost := game_state.get_work_cost(plan_id)
	if not game_state.can_pay(cost):
		message_label.text = "本钱不够，干不了这个作业方案。"
		_update_work_buttons()
		return

	var result := resolver.generate_harvest_result(game_state.current_pond, plan_id, cost)
	pending_harvest_result = result
	harvest_collect_locked = false
	_show_harvest_result(result)

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

	var fish_revenue := int(result.get("fish_income", 0))
	var net_cost := int(result.get("work_cost", 0))
	var round_profit := fish_revenue - net_cost
	if caught_fish_king:
		harvest_result_title.text = "鱼王出现！"
	elif round_profit > 0:
		harvest_result_title.text = "这一网赚到了"
	elif round_profit == 0:
		harvest_result_title.text = "这一网打平"
	else:
		harvest_result_title.text = "这一网亏了"

	_render_harvest_catch_rows(result)
	harvest_fish_revenue_value.text = "%d 元" % fish_revenue
	harvest_net_cost_value.text = "%d 元" % net_cost
	harvest_net_profit_value.text = "%+d 元" % round_profit if round_profit != 0 else "0 元"
	harvest_net_profit_value.add_theme_color_override("font_color", UIKit.GREEN if round_profit > 0 else UIKit.RED if round_profit < 0 else UIKit.INK)
	harvest_result_label.text = "本次赚亏 %+d 元" % round_profit
	UIKit.style_highlight_label(harvest_result_label, "positive" if round_profit > 0 else "negative" if round_profit < 0 else "gold")
	harvest_continue_button.disabled = false
	UIKit.show_modal(self, harvest_result_overlay, harvest_result_dialog, 0.86, 1060, Vector2i(340, 700), Vector2i(860, 1160))

func _render_harvest_catch_rows(result: Dictionary) -> void:
	for child in harvest_catch_list.get_children():
		child.queue_free()
	var catch_details := Array(result.get("catch_details", []))
	if catch_details.is_empty():
		var empty_label := UIKit.make_label("这一网没有起货。", UIKit.FONT_BODY, UIKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
		harvest_catch_list.add_child(empty_label)
		return

	var title := UIKit.make_label("鱼获明细", UIKit.FONT_SECTION, UIKit.GREEN, HORIZONTAL_ALIGNMENT_LEFT)
	harvest_catch_list.add_child(title)
	for item_variant in catch_details:
		var item := Dictionary(item_variant)
		var row_text := "%s：%d 斤 × %d 元/斤 = %d 元" % [
			str(item.get("name", "未知鱼获")),
			int(item.get("weight_jin", 0)),
			int(item.get("unit_price", 0)),
			int(item.get("income", 0))
		]
		if str(item.get("id", "")) == "fish_king" and item.has("integrity"):
			row_text += "，完整度 %d%%" % int(item.get("integrity", 0))
		harvest_catch_list.add_child(_make_plain_card_label(row_text))
		var price_note := str(item.get("price_note", ""))
		if not price_note.is_empty():
			harvest_catch_list.add_child(UIKit.make_label(price_note, UIKit.FONT_SECONDARY, UIKit.MUTED, HORIZONTAL_ALIGNMENT_LEFT))

func _make_plain_card_label(text: String) -> Label:
	var label := UIKit.make_label(text, UIKit.FONT_BODY, UIKit.INK, HORIZONTAL_ALIGNMENT_LEFT)
	label.custom_minimum_size = Vector2(0, 42)
	return label

func _on_harvest_result_continue_pressed() -> void:
	if harvest_collect_locked:
		return
	harvest_collect_locked = true
	harvest_continue_button.disabled = true
	UIKit.hide_modal(harvest_result_overlay)
	if pending_harvest_result.is_empty():
		return
	var result := pending_harvest_result
	pending_harvest_result = {}
	if not game_state.apply_harvest(result):
		message_label.text = "本钱不够，干不了这个作业方案。"
		_update_work_buttons()
		return
	if bool(result.get("is_final", false)):
		UIController.show_settlement(screen_container, game_state)
		return

	latest_net_result = result.duplicate(true)
	var opportunities := resolver.generate_disposal_opportunities(game_state.current_pond, result)
	current_transfer_offer = opportunities.get("transfer_offer", {})
	if current_transfer_offer.is_empty():
		_refresh_transfer_offer()
	if not game_state.sold_one_net:
		current_one_net_offer = opportunities.get("one_net_offer", {})
	message_label.text = "%s\n%s" % [str(result.get("text", "")), str(opportunities.get("message", ""))]
	_show_choice_page()
	_render()

func _update_work_buttons() -> void:
	var low_cost := game_state.get_work_cost("low")
	var standard_cost := game_state.get_work_cost("standard")
	var full_cost := game_state.get_work_cost("full")

	_update_net_option_card(low_work_button, low_cost, "小捞一网")
	_update_net_option_card(standard_work_button, standard_cost, "稳捞一网")
	_update_net_option_card(full_work_button, full_cost, "抽干收尾")
	low_work_button.disabled = not game_state.can_pay(low_cost)
	standard_work_button.disabled = not game_state.can_pay(standard_cost)
	full_work_button.disabled = game_state.drained or not game_state.can_pay(full_cost)
	_ensure_net_option_list_layout()

func _update_net_option_card(button: Button, cost: int, title_text: String) -> void:
	var card := button.get_parent().get_parent().get_parent().get_parent() as PanelContainer
	var cost_badge := card.find_child("CostBadge", true, false) as Label
	if cost_badge != null:
		cost_badge.text = "费用：%d 元" % cost
	button.text = title_text if game_state.can_pay(cost) else "钱不够"

func _ensure_net_option_list_layout() -> void:
	# Keep the net-option list visible inside the outer page scroll. Without a
	# stable height, the nested ScrollContainer can collapse to 0 and only leave
	# the back button visible.
	work_plan_scroll.set_meta("_structure_name", "NetOptionList")
	work_plan_scroll.modulate.a = 1.0
	work_plan_scroll.custom_minimum_size = Vector2(0, 800)
	work_plan_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	work_plan_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	work_plan_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	work_plan_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	work_plan_panel.set_meta("_structure_name", "NetOptionPanel")
	work_plan_panel.custom_minimum_size = Vector2(0, 760)
	work_plan_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	work_plan_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if work_plan_panel.get_child_count() <= 0:
		_show_net_option_empty_state()

func _show_net_option_empty_state() -> void:
	if net_option_empty_state != null and is_instance_valid(net_option_empty_state):
		return
	net_option_empty_state = Label.new()
	net_option_empty_state.name = "NetOptionEmptyState"
	net_option_empty_state.text = "暂无可用下网方式，请返回处理选择。"
	net_option_empty_state.custom_minimum_size = Vector2(0, 140)
	net_option_empty_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	net_option_empty_state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	net_option_empty_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(net_option_empty_state, "body_dark")
	work_plan_panel.add_child(net_option_empty_state)
