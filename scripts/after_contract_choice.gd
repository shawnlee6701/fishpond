extends Control

const UIKit := preload("res://scripts/ui_kit.gd")

const BUYER_TRANSFER_TEXTURE: Texture2D = preload("res://assets/decorations/buyer_transfer_placeholder.png")
const CATCH_RESULT_TEXTURE: Texture2D = preload("res://assets/effects/catch_result_visual.png")
const NET_METHOD_LOW_TEXTURE: Texture2D = preload("res://assets/effects/net_method_low.png")
const NET_METHOD_STANDARD_TEXTURE: Texture2D = preload("res://assets/effects/net_method_standard.png")
const NET_METHOD_FULL_TEXTURE: Texture2D = preload("res://assets/effects/net_method_full.png")

const _NET_METHOD_TEXTURES: Dictionary[String, Texture2D] = {
	"low": NET_METHOD_LOW_TEXTURE,
	"standard": NET_METHOD_STANDARD_TEXTURE,
	"full": NET_METHOD_FULL_TEXTURE
}

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

const OWNED_POND_CARD_BG_TEXTURE: Texture2D = preload("res://assets/ui/owned_pond_card_bg.png")
const ACTION_CARD_BG_TEXTURE: Texture2D = preload("res://assets/ui/action_card_bg.png")
const NET_OPTION_CARD_BG_TEXTURE: Texture2D = preload("res://assets/ui/net_option_card_bg.png")
const TRANSFER_DIALOG_BG_TEXTURE: Texture2D = preload("res://assets/ui/transfer_dialog_bg.png")
const SPEECH_BUBBLE_TEXTURE: Texture2D = preload("res://assets/ui/speech_bubble.png")
const OWNED_POND_VISUAL_TEXTURE: Texture2D = preload("res://assets/ponds/owned_pond_visual.png")
const OFFER_PRICE_BADGE_TEXTURE: Texture2D = preload("res://assets/ui/offer_price_badge.png")
const BALANCE_HIGHLIGHT_BG_TEXTURE: Texture2D = preload("res://assets/ui/balance_highlight_bg.png")
const STATUS_BOX_BG_TEXTURE: Texture2D = preload("res://assets/ui/status_box_bg.png")
const PROFIT_LOSS_BADGE_TEXTURE: Texture2D = preload("res://assets/ui/profit_loss_badge.png")
const BG_CARD_PAPER_TEXTURE: Texture2D = preload("res://assets/decorations/bg_card_paper.png")
const BG_PARCHMENT_TEXTURE: Texture2D = preload("res://assets/decorations/bg_parchment.png")
const BUTTON_ACCEPT_TEXTURE: Texture2D = preload("res://assets/buttons/button_accept.png")
const BUTTON_DANGER_CONFIRM_TEXTURE: Texture2D = preload("res://assets/buttons/button_danger_confirm.png")
const BUTTON_SECONDARY_TEXTURE: Texture2D = preload("res://assets/buttons/button_secondary.png")

func _get_net_method_texture(method_id: String) -> Texture2D:
	return _NET_METHOD_TEXTURES.get(method_id, NET_METHOD_LOW_TEXTURE)


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
var harvest_catch_visual: TextureRect
var harvest_fish_revenue_value: Label
var harvest_net_cost_value: Label
var harvest_net_profit_value: Label
var harvest_result_label: Label
var harvest_continue_button: Button
var harvest_opportunity_card: PanelContainer
var harvest_opportunity_label: Label
var pending_harvest_result: Dictionary = {}
var pending_harvest_opportunities: Dictionary = {}
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
	_apply_panel_texture(top_status_bar, BALANCE_HIGHLIGHT_BG_TEXTURE, 14, 20)
	UIKit.style_page_title(title_label)
	UIKit.style_label(subtitle_label, "muted")
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_page_frame(owned_pond_card, UIKit.GREEN)
	_apply_panel_texture(owned_pond_card, OWNED_POND_CARD_BG_TEXTURE, 24, 24)
	_apply_label_texture(pond_status_badge, PROFIT_LOSS_BADGE_TEXTURE, 12, 4, 16)
	UIKit.style_label(pond_name_label, "content_title")
	_apply_panel_texture(latest_net_result_card, STATUS_BOX_BG_TEXTURE, 24, 20)
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
	UIKit.apply_texture_button(ledger_toggle_button, BUTTON_SECONDARY_TEXTURE)
	UIKit.style_label(ledger_detail_label, "body_dark")
	_create_ledger_detail_card()
	work_plan_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	work_plan_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIKit.set_scrollbar_auto_hide(content_scroll)
	UIKit.set_scrollbar_auto_hide(work_plan_scroll)
	_show_choice_page()

func _create_owned_pond_visual() -> void:
	if pond_visual_host.get_child_count() > 0:
		return
	var visual := TextureRect.new()
	visual.name = "PondVisual"
	visual.texture = OWNED_POND_VISUAL_TEXTURE
	visual.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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
	_apply_panel_texture(card, ACTION_CARD_BG_TEXTURE, 24, 24)
	for label in card.find_children("*", "Label", true, false):
		var typed_label := label as Label
		typed_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if typed_label.name == "ActionTitleLabel":
			UIKit.style_label(typed_label, "section")
		elif typed_label.name == "ActionStatusLabel":
			UIKit.style_label(typed_label, "muted")
		else:
			UIKit.style_label(typed_label, "body_dark")
	_apply_button_texture(button, BUTTON_ACCEPT_TEXTURE if role == "primary" else BUTTON_DANGER_CONFIRM_TEXTURE)

func _create_ledger_detail_card() -> void:
	if ledger_detail_card != null and is_instance_valid(ledger_detail_card):
		return
	ledger_detail_label.visible = false
	ledger_detail_card = PanelContainer.new()
	ledger_detail_card.name = "LedgerDetailCard"
	ledger_detail_card.visible = false
	ledger_detail_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_panel_texture(ledger_detail_card, BG_CARD_PAPER_TEXTURE, 12, 24)
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
	_apply_panel_texture(transfer_dialog, TRANSFER_DIALOG_BG_TEXTURE, 40, 40)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 16)
	transfer_dialog.add_child(content)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "有人来看塘了"
	UIKit.style_modal_title(title)
	content.add_child(title)

	transfer_offer_highlight_label = Label.new()
	transfer_offer_highlight_label.name = "OfferHighlight"
	transfer_offer_highlight_label.custom_minimum_size = Vector2(0, 70)
	transfer_offer_highlight_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	transfer_offer_highlight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transfer_offer_highlight_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_label_texture(transfer_offer_highlight_label, OFFER_PRICE_BADGE_TEXTURE, 24, 12, 20)
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

	var buyer_placeholder := TextureRect.new()
	buyer_placeholder.name = "BuyerTexture"
	buyer_placeholder.texture = BUYER_TRANSFER_TEXTURE
	buyer_placeholder.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	buyer_placeholder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	buyer_placeholder.custom_minimum_size = Vector2(190, 190)
	buyer_placeholder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	buyer_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buyer_area.add_child(buyer_placeholder)

	var bubble := PanelContainer.new()
	bubble.name = "BuyerSpeechBubble"
	bubble.custom_minimum_size = Vector2(210, 0)
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_apply_panel_texture(bubble, SPEECH_BUBBLE_TEXTURE, 18, 16)
	buyer_area.add_child(bubble)

	var bubble_margin := MarginContainer.new()
	bubble_margin.add_theme_constant_override("margin_left", 18)
	bubble_margin.add_theme_constant_override("margin_top", 16)
	bubble_margin.add_theme_constant_override("margin_right", 18)
	bubble_margin.add_theme_constant_override("margin_bottom", 16)
	bubble.add_child(bubble_margin)

	var bubble_text := Label.new()
	bubble_text.name = "BuyerSpeechText"
	bubble_text.text = "哥，你这塘我盯好久了，给个痛快价呗。"
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

	transfer_total_invested_value = _add_transfer_summary_row(summary_rows, "TotalInvestedRow", "你投进去的")
	transfer_offer_price_value = _add_transfer_summary_row(summary_rows, "OfferPriceRow", "对方报价")
	transfer_profit_loss_value = _add_transfer_summary_row(summary_rows, "TransferProfitLossRow", "这单转手")
	transfer_profit_loss_status_label = Label.new()
	transfer_profit_loss_status_label.name = "TransferProfitLossStatus"
	transfer_profit_loss_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	transfer_profit_loss_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UIKit.style_label(transfer_profit_loss_status_label, "muted")
	summary_rows.add_child(transfer_profit_loss_status_label)
	transfer_money_after_accept_value = _add_transfer_summary_row(summary_rows, "MoneyAfterAcceptRow", "接了你兜里")

	var risk_panel := PanelContainer.new()
	risk_panel.name = "RiskNotePanel"
	risk_panel.add_theme_stylebox_override("panel", UIKit.make_translucent_readability_panel(0.75))
	body.add_child(risk_panel)

	var risk_margin := MarginContainer.new()
	risk_margin.add_theme_constant_override("margin_left", 14)
	risk_margin.add_theme_constant_override("margin_top", 10)
	risk_margin.add_theme_constant_override("margin_right", 14)
	risk_margin.add_theme_constant_override("margin_bottom", 10)
	risk_panel.add_child(risk_margin)

	transfer_risk_note_label = Label.new()
	transfer_risk_note_label.name = "RiskNoteLabel"
	transfer_risk_note_label.text = "来人出价是照行情估的，不一定等于塘里真剩的。"
	transfer_risk_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	transfer_risk_note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(transfer_risk_note_label, "muted")
	risk_margin.add_child(transfer_risk_note_label)

	var buttons := HBoxContainer.new()
	buttons.name = "ButtonRow"
	buttons.add_theme_constant_override("separation", 14)
	content.add_child(buttons)

	accept_transfer_button = Button.new()
	accept_transfer_button.name = "AcceptTransferButton"
	accept_transfer_button.text = "转！接了这个价"
	accept_transfer_button.custom_minimum_size = Vector2(0, 96)
	accept_transfer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_texture(accept_transfer_button, BUTTON_ACCEPT_TEXTURE)
	accept_transfer_button.pressed.connect(_on_accept_transfer_pressed)
	buttons.add_child(accept_transfer_button)

	reject_transfer_button = Button.new()
	reject_transfer_button.name = "ContinueButton"
	reject_transfer_button.text = "不转，自己干"
	reject_transfer_button.custom_minimum_size = Vector2(0, 96)
	reject_transfer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_texture(reject_transfer_button, BUTTON_SECONDARY_TEXTURE)
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

	harvest_catch_visual = TextureRect.new()
	harvest_catch_visual.name = "CatchVisual"
	harvest_catch_visual.texture = CATCH_RESULT_TEXTURE
	harvest_catch_visual.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	harvest_catch_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	harvest_catch_visual.custom_minimum_size = Vector2(0, 280)
	harvest_catch_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(harvest_catch_visual)

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

	# "New opportunities brought by this net" hint (uses existing opportunities data).
	harvest_opportunity_card = PanelContainer.new()
	harvest_opportunity_card.name = "OpportunityHintCard"
	UIKit.style_card(harvest_opportunity_card, UIKit.GOLD)
	body.add_child(harvest_opportunity_card)

	var opportunity_margin := MarginContainer.new()
	opportunity_margin.name = "OpportunityMargin"
	opportunity_margin.add_theme_constant_override("margin_left", 16)
	opportunity_margin.add_theme_constant_override("margin_top", 14)
	opportunity_margin.add_theme_constant_override("margin_right", 16)
	opportunity_margin.add_theme_constant_override("margin_bottom", 14)
	harvest_opportunity_card.add_child(opportunity_margin)

	var opportunity_content := VBoxContainer.new()
	opportunity_content.name = "OpportunityContent"
	opportunity_content.add_theme_constant_override("separation", 8)
	opportunity_margin.add_child(opportunity_content)

	var opportunity_title := Label.new()
	opportunity_title.name = "OpportunityTitle"
	opportunity_title.text = "这一网带来的新机会"
	opportunity_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(opportunity_title, "section")
	opportunity_content.add_child(opportunity_title)

	harvest_opportunity_label = Label.new()
	harvest_opportunity_label.name = "OpportunityBody"
	harvest_opportunity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	harvest_opportunity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIKit.style_label(harvest_opportunity_label, "body_dark")
	opportunity_content.add_child(harvest_opportunity_label)

	harvest_continue_button = Button.new()
	harvest_continue_button.name = "CollectResultButton"
	harvest_continue_button.text = "收工"
	harvest_continue_button.custom_minimum_size = Vector2(0, UIKit.MODAL_ACTION_HEIGHT)
	_apply_button_texture(harvest_continue_button, BUTTON_ACCEPT_TEXTURE)
	harvest_continue_button.pressed.connect(_on_harvest_result_continue_pressed)
	content.add_child(harvest_continue_button)

func _rebuild_work_plan_cards() -> void:
	for child in work_plan_panel.get_children():
		child.queue_free()
	net_option_empty_state = null
	low_work_button = _create_net_option_card("low", "小捞一网", "成本低，鱼获看天。捞完还能接着来。", "捞完还能继续。", false)
	standard_work_button = _create_net_option_card("standard", "稳捞一网", "功夫花到，鱼获更稳。捞完还能接着来。", "捞完还能继续。", false)
	full_work_button = _create_net_option_card("full", "抽干收尾", "水抽干、网收净，这口塘不再折腾。直接结算。", "本塘直接结算。", true)
	_ensure_net_option_list_layout()

func _create_net_option_card(plan_id: String, title_text: String, desc_text: String, consequence_text: String, is_final: bool) -> Button:
	var card := PanelContainer.new()
	card.name = "NetOptionCard_%s" % ("Final" if is_final else "Small" if plan_id == "low" else "Normal")
	card.custom_minimum_size = Vector2(0, 250 if is_final else 220)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	work_plan_panel.add_child(card)
	_apply_panel_texture(card, NET_OPTION_CARD_BG_TEXTURE, 24, 24)

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

	var visual := TextureRect.new()
	visual.name = "NetMethodTexture"
	visual.texture = _get_net_method_texture(plan_id)
	visual.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.custom_minimum_size = Vector2(150, 150)
	visual.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		warning.text = "选了就不能回头了"
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
	_apply_button_texture(button, BUTTON_DANGER_CONFIRM_TEXTURE if is_final else BUTTON_ACCEPT_TEXTURE)
	button.pressed.connect(_on_work_plan_pressed.bind(plan_id))
	info.add_child(button)
	return button

func _render() -> void:
	var pond := game_state.current_pond
	pond_name_label.text = "已拿下：%s" % str(pond.get("name", "未承包鱼塘"))
	day_label.text = "第 %d 天" % game_state.day
	cash_label.text = "兜里：%d 元" % game_state.cash
	_render_ledger()
	_render_latest_net_result()
	_render_ledger_accordion()

	var has_net_result := not latest_net_result.is_empty() or game_state.self_net_count > 0 or game_state.fish_income > 0
	harvest_self_title_label.text = "再下一网" if has_net_result else "下网开工"
	harvest_self_desc_label.text = "看看塘里还有多少货。" if has_net_result else "花点开工钱，看看这口塘到底有没有货。"
	harvest_self_button.text = "再下一网" if has_net_result else "下网开工"
	transfer_button.text = "去转包"
	transfer_button.disabled = current_transfer_offer.is_empty() or game_state.drained
	harvest_self_button.disabled = not game_state.can_pay(game_state.get_work_cost("low"))
	transfer_status_label.text = "有人出价" if not transfer_button.disabled else "暂无报价"
	harvest_self_status_label.text = "主操作" if not harvest_self_button.disabled else "钱不够"
	if current_transfer_offer.is_empty():
		transfer_button.text = "暂无报价"

	# ---- 卖一网状态机渲染 ----
	var current_state := _get_sell_one_net_state()
	match current_state:
		SellOneNetState.LOCKED_NO_CATCH:
			sell_one_net_card.visible = true
			sell_one_net_status_label.text = "还没下过网"
			sell_one_net_desc_label.text = "先下一网，让外面的人看到货才会有人出价。"
			sell_one_net_button.text = "没人出价"
			sell_one_net_button.disabled = true
			_set_banner_visible(false)
		SellOneNetState.AVAILABLE:
			sell_one_net_card.visible = true
			sell_one_net_status_label.text = "有人出价"
			sell_one_net_desc_label.text = "有人要你这网鱼，接了就入账，鱼归人家。"
			sell_one_net_button.text = "看看出多少"
			sell_one_net_button.disabled = false
			_set_banner_visible(false)
		SellOneNetState.NO_BUYER:
			sell_one_net_card.visible = true
			sell_one_net_status_label.text = "没人出价"
			sell_one_net_desc_label.text = "暂时没人要。再下一网，可能就有人开口了。"
			sell_one_net_button.text = "没人出价"
			sell_one_net_button.disabled = true
			_set_banner_visible(false)
		SellOneNetState.SOLD:
			sell_one_net_card.visible = false
			sell_one_net_button.disabled = true
			_set_banner_visible(true)
			var sold_income := _last_sell_one_net_income if _last_sell_one_net_income > 0 else game_state.one_net_income
			if sold_income > 0:
				_set_banner_text("这网出手了：+%d 元到兜里" % sold_income, "这一网的货已经是人家的了")
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

	if current_profit_loss > 0:
		pond_status_badge.text = "赚了"
		pond_status_badge.add_theme_color_override("font_color", UIKit.GREEN)
	elif current_profit_loss < 0:
		pond_status_badge.text = "亏了"
		pond_status_badge.add_theme_color_override("font_color", UIKit.RED)
	else:
		pond_status_badge.text = "持平"
		pond_status_badge.add_theme_color_override("font_color", UIKit.INK)

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
	latest_revenue_label.text = "鱼获：%d 元" % fish_revenue
	latest_cost_label.text = "成本：%d 元" % net_cost
	if latest_net_profit > 0:
		latest_profit_label.text = "这网净赚：+%d 元" % latest_net_profit
	elif latest_net_profit < 0:
		latest_profit_label.text = "这网净亏：%d 元" % latest_net_profit
	else:
		latest_profit_label.text = "这网打平：0 元"
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

	transfer_offer_highlight_label.text = "来人出价：%d 元" % offer_price
	transfer_total_invested_value.text = "%d 元" % total_invested
	transfer_offer_price_value.text = "%d 元" % offer_price
	transfer_profit_loss_value.text = "%+d 元" % transfer_profit_loss if transfer_profit_loss != 0 else "0 元"
	transfer_money_after_accept_value.text = "%d 元" % money_after_accept

	var outcome_text := "不赚不亏"
	var outcome_tone := "gold"
	if transfer_profit_loss < 0:
		outcome_text = "亏了"
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
		accept_transfer_button.text = "转！接了这个价（亏%d元）" % abs(transfer_profit_loss)
		UIKit.style_button(accept_transfer_button, "gold")
	elif transfer_profit_loss > 0:
		accept_transfer_button.text = "转！接了这个价（赚%d元）" % transfer_profit_loss
		UIKit.style_button(accept_transfer_button, "primary")
	else:
		accept_transfer_button.text = "转！接了这个价（不赚不亏）"
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
	title_label.text = "这塘归你了"
	subtitle_label.text = "塘在你名下，下一步怎么走？"
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
	title_label.text = "下网开工"
	subtitle_label.text = "花多少钱，就看到多少真东西。"
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
	_apply_panel_texture(_sell_one_net_dialog, TRANSFER_DIALOG_BG_TEXTURE, 40, 40)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 14)
	_sell_one_net_dialog.add_child(content)

	# -- Title --
	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "有人要你这网鱼"
	UIKit.style_modal_title(title)
	content.add_child(title)

	# -- Offer price highlight --
	_sell_one_net_highlight_label = Label.new()
	_sell_one_net_highlight_label.name = "SellOneNetOfferHighlight"
	_sell_one_net_highlight_label.custom_minimum_size = Vector2(0, 70)
	_sell_one_net_highlight_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sell_one_net_highlight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sell_one_net_highlight_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_label_texture(_sell_one_net_highlight_label, OFFER_PRICE_BADGE_TEXTURE, 24, 12, 20)
	content.add_child(_sell_one_net_highlight_label)

	# -- Deal body (summary rows + explanation on translucent panel) --
	var body_panel := PanelContainer.new()
	body_panel.name = "DealBodyPanel"
	body_panel.add_theme_stylebox_override("panel", UIKit.make_translucent_readability_panel(0.82))
	content.add_child(body_panel)

	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 18)
	body_margin.add_theme_constant_override("margin_top", 14)
	body_margin.add_theme_constant_override("margin_right", 18)
	body_margin.add_theme_constant_override("margin_bottom", 14)
	body_panel.add_child(body_margin)

	var body := VBoxContainer.new()
	body.name = "DealBody"
	body.add_theme_constant_override("separation", 10)
	body_margin.add_child(body)

	# -- Deal summary rows --
	var summary := VBoxContainer.new()
	summary.name = "DealSummaryRows"
	summary.add_theme_constant_override("separation", 6)
	body.add_child(summary)

	_sell_one_net_offer_price_label = Label.new()
	_sell_one_net_offer_price_label.name = "ImmediateIncomeRow"
	_sell_one_net_offer_price_label.text = "接了到手：+0 元"
	_sell_one_net_offer_price_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(_sell_one_net_offer_price_label, "body_dark")
	summary.add_child(_sell_one_net_offer_price_label)

	_sell_one_net_current_money_label = Label.new()
	_sell_one_net_current_money_label.name = "CurrentMoneyRow"
	_sell_one_net_current_money_label.text = "兜里有：0 元"
	_sell_one_net_current_money_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(_sell_one_net_current_money_label, "body_dark")
	summary.add_child(_sell_one_net_current_money_label)

	_sell_one_net_after_money_label = Label.new()
	_sell_one_net_after_money_label.name = "MoneyAfterSellOneNetRow"
	_sell_one_net_after_money_label.text = "接了兜里变：0 元"
	_sell_one_net_after_money_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(_sell_one_net_after_money_label, "body_dark")
	summary.add_child(_sell_one_net_after_money_label)

	var sold_state_row := Label.new()
	sold_state_row.name = "SoldStateRow"
	sold_state_row.text = "卖出后：这网就是人家的了"
	sold_state_row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(sold_state_row, "body_dark")
	summary.add_child(sold_state_row)

	# -- Explain text --
	var explain := Label.new()
	explain.name = "ExplainText"
	explain.text = "来人只买这一网，不买塘。接了这一网的货就归人家了。"
	explain.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(explain, "muted")
	body.add_child(explain)

	# -- Buttons --
	var buttons := HBoxContainer.new()
	buttons.name = "ButtonRow"
	buttons.add_theme_constant_override("separation", 14)
	content.add_child(buttons)

	_sell_one_net_reject_button = Button.new()
	_sell_one_net_reject_button.name = "RejectSellOneNetButton"
	_sell_one_net_reject_button.text = "再等等看"
	_sell_one_net_reject_button.custom_minimum_size = Vector2(0, 78)
	_sell_one_net_reject_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_texture(_sell_one_net_reject_button, BUTTON_SECONDARY_TEXTURE)
	_sell_one_net_reject_button.pressed.connect(_on_sell_one_net_reject_pressed)
	buttons.add_child(_sell_one_net_reject_button)

	_sell_one_net_accept_button = Button.new()
	_sell_one_net_accept_button.name = "AcceptSellOneNetButton"
	_sell_one_net_accept_button.text = "接！卖给他"
	_sell_one_net_accept_button.custom_minimum_size = Vector2(0, 78)
	_sell_one_net_accept_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_texture(_sell_one_net_accept_button, BUTTON_ACCEPT_TEXTURE)
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
		if flag and UIKit.animations_enabled:
			UIKit.animate_pop_in(_sell_one_net_result_banner)
			UIKit.animate_shine(_sell_one_net_banner_title)

func _set_banner_text(title: String, detail := "这一网已卖出，不能重复卖") -> void:
	if is_instance_valid(_sell_one_net_banner_title):
		_sell_one_net_banner_title.text = title
	if is_instance_valid(_sell_one_net_banner_detail):
		_sell_one_net_banner_detail.text = detail

func _show_sell_one_net_dialog() -> void:
	var income := int(current_one_net_offer.get("income", 0))
	var current_money := game_state.cash
	var money_after_sell_one_net := current_money + income
	_sell_one_net_highlight_label.text = "来人出到 %d 元" % income
	_sell_one_net_offer_price_label.text = "接了到手：+%d 元" % income
	_sell_one_net_current_money_label.text = "兜里有：%d 元" % current_money
	_sell_one_net_after_money_label.text = "接了兜里变：%d 元" % money_after_sell_one_net
	_sell_one_net_accept_button.text = "接！卖给他（+%d）" % income
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
		message_label.text = "没人出价。先下一网，让外面的人看到货，自然有人开口。"
		return

	_open_transfer_offer_dialog()

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
			"title": "真要亏钱转出去？",
			"body": "接了这个价，这口塘你亏 %d 元，但至少不用再往里贴钱了。" % abs(transfer_profit_loss),
			"cancel_text": "再掂量掂量",
			"confirm_text": "转出去，认亏",
			"on_confirm": Callable(self, "_confirm_accept_transfer"),
			"on_cancel": Callable(self, "_on_cancel_loss_transfer_confirm")
		})
		return
	_confirm_accept_transfer()

func _confirm_accept_transfer() -> void:
	if accept_transfer_button != null:
		accept_transfer_button.disabled = true
	UIKit.animate_shine(transfer_offer_highlight_label)
	_close_transfer_dialog()
	var ledger := _get_transfer_decision_ledger()
	game_state.apply_transfer(int(ledger.get("offer_price", 0)), int(ledger.get("transfer_profit_loss", 0)))
	UIController.show_settlement(screen_container, game_state)

func _on_cancel_loss_transfer_confirm() -> void:
	if accept_transfer_button != null and transfer_overlay != null and transfer_overlay.visible:
		accept_transfer_button.disabled = false

func _on_reject_transfer_pressed() -> void:
	_close_transfer_dialog()
	message_label.text = "没接。这口塘的账，你自己算到底。"
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
		message_label.text = "现在不能卖一网。"
		_render()
		return

	_hide_detail_panels()
	_show_sell_one_net_dialog()

func _on_sell_one_net_accept_pressed() -> void:
	if _sell_one_net_accept_button.disabled:
		return

	_sell_one_net_accept_button.disabled = true
	if current_one_net_offer.is_empty():
		message_label.text = "卖一网报价已过期，没法交易了。"
		_close_sell_one_net_dialog()
		_render()
		return
	if game_state.sold_one_net:
		message_label.text = "这一网已经卖过了，不能重复卖。"
		_close_sell_one_net_dialog()
		_render()
		return

	var income := int(current_one_net_offer.get("income", 0))
	if game_state.apply_one_net(income, str(current_one_net_offer.get("text", ""))):
		_last_sell_one_net_income = income
		_set_banner_text("这网出手了：+%d 元到兜里" % income, "这一网的货已经是人家的了")
		_set_banner_visible(true)
		message_label.text = "成了，%d 元到手。这网的货归买家了。" % income
		current_one_net_offer = {}
		_refresh_transfer_offer()
	_close_sell_one_net_dialog()
	_render()

func _on_sell_one_net_reject_pressed() -> void:
	_close_sell_one_net_dialog()
	message_label.text = "不卖了。再看看行情，说不定后面更高。"
	_render()

func _on_harvest_self_pressed() -> void:
	_close_transfer_dialog()
	_open_work_plan_page()

func _open_work_plan_page() -> void:
	_show_work_plan_page()
	message_label.text = "选个方案。抽干就是终局了，钱不够的干不了。"
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
		message_label.text = "钱不够，干不了这个方案。"
		_update_work_buttons()
		return

	if plan_id == "full":
		_show_global_confirm({
			"title": "确定要抽干收尾？",
			"body": "抽干了就不能再下了，这口塘的账到此为止。",
			"cancel_text": "再想想",
			"confirm_text": "抽干收尾",
			"on_confirm": Callable(self, "_execute_work_plan").bind(plan_id)
		})
		return
	_execute_work_plan(plan_id)

func _execute_work_plan(plan_id: String) -> void:
	var cost := game_state.get_work_cost(plan_id)
	if not game_state.can_pay(cost):
		message_label.text = "钱不够，干不了这个方案。"
		_update_work_buttons()
		return

	var result := resolver.generate_harvest_result(game_state.current_pond, plan_id, cost)
	pending_harvest_result = result
	pending_harvest_opportunities = resolver.generate_disposal_opportunities(game_state.current_pond, result)
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
		harvest_result_title.text = "鱼王出水！"
	elif round_profit > 0:
		harvest_result_title.text = "这一网赚了"
	elif round_profit == 0:
		harvest_result_title.text = "这一网平了"
	else:
		harvest_result_title.text = "这一网亏了"

	_render_harvest_catch_rows(result)
	harvest_fish_revenue_value.text = "%d 元" % fish_revenue
	harvest_net_cost_value.text = "%d 元" % net_cost
	harvest_net_profit_value.text = "%+d 元" % round_profit if round_profit != 0 else "0 元"
	harvest_net_profit_value.add_theme_color_override("font_color", UIKit.GREEN if round_profit > 0 else UIKit.RED if round_profit < 0 else UIKit.INK)
	harvest_result_label.text = "本次赚亏 %+d 元" % round_profit
	UIKit.style_highlight_label(harvest_result_label, "positive" if round_profit > 0 else "negative" if round_profit < 0 else "gold")
	_update_harvest_opportunity_hint()
	harvest_continue_button.disabled = false
	UIKit.show_modal(self, harvest_result_overlay, harvest_result_dialog, 0.86, 1060, Vector2i(340, 700), Vector2i(860, 1160))

	if UIKit.animations_enabled:
		var result_tone := "positive" if round_profit > 0 else "negative" if round_profit < 0 else "gold"
		UIKit.animate_emphasis(harvest_result_title, "gold" if caught_fish_king else result_tone)
		var sparkle_target: Control = harvest_catch_visual if caught_fish_king else harvest_result_label
		_spawn_harvest_sparkles.call_deferred("gold" if caught_fish_king else result_tone)

func _spawn_harvest_sparkles(tone: String) -> void:
	if not is_instance_valid(harvest_result_dialog):
		return
	var target: Control = harvest_catch_visual if _is_fish_king_harvest() else harvest_result_label
	if is_instance_valid(target):
		UIKit.spawn_sparkles(harvest_result_dialog, target.get_rect(), tone)


func _is_fish_king_harvest() -> bool:
	for item in Array(pending_harvest_result.get("catch_details", [])):
		if str(Dictionary(item).get("id", "")) == "fish_king":
			return true
	return false


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
		harvest_catch_list.add_child(_create_fish_catch_row(item))
		var price_note := str(item.get("price_note", ""))
		if not price_note.is_empty():
			harvest_catch_list.add_child(UIKit.make_label(price_note, UIKit.FONT_SECONDARY, UIKit.MUTED, HORIZONTAL_ALIGNMENT_LEFT))

func _create_fish_catch_row(item: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "FishCatchRow_%s" % str(item.get("id", "unknown"))
	row.add_theme_constant_override("separation", 10)
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

	var row_text := "%s：%d 斤 × %d 元/斤 = %d 元" % [
		str(item.get("name", "未知鱼获")),
		int(item.get("weight_jin", 0)),
		int(item.get("unit_price", 0)),
		int(item.get("income", 0))
	]
	if fish_id == "fish_king" and item.has("integrity"):
		row_text += "，完整度 %d%%" % int(item.get("integrity", 0))
	var label := _make_plain_card_label(row_text)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return row

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
		message_label.text = "钱不够，干不了这个方案。"
		_update_work_buttons()
		return
	if bool(result.get("is_final", false)):
		UIController.show_settlement(screen_container, game_state)
		return

	latest_net_result = result.duplicate(true)
	var opportunities := pending_harvest_opportunities
	if opportunities.is_empty():
		opportunities = resolver.generate_disposal_opportunities(game_state.current_pond, result)
	pending_harvest_opportunities = {}
	current_transfer_offer = opportunities.get("transfer_offer", {})
	if current_transfer_offer.is_empty():
		_refresh_transfer_offer()
	if not game_state.sold_one_net:
		current_one_net_offer = opportunities.get("one_net_offer", {})
	message_label.text = "%s\n%s" % [str(result.get("text", "")), str(opportunities.get("message", ""))]
	_show_choice_page()
	_render()


func _update_harvest_opportunity_hint() -> void:
	if harvest_opportunity_label == null:
		return
	var transfer_offer := Dictionary(pending_harvest_opportunities.get("transfer_offer", {}))
	var one_net_offer := Dictionary(pending_harvest_opportunities.get("one_net_offer", {}))
	var lines: Array[String] = []
	if not transfer_offer.is_empty():
		var transfer_price := int(transfer_offer.get("income", 0))
		lines.append("有人愿意转包这口塘：%d 元" % transfer_price)
	if not one_net_offer.is_empty():
		var one_net_price := int(one_net_offer.get("income", 0))
		lines.append("有买家想买一网试试：%d 元" % one_net_price)
	if lines.is_empty():
		lines.append("暂无新机会，可以继续下网或抽干收尾。")
	harvest_opportunity_label.text = "\n".join(lines)
	if is_instance_valid(harvest_opportunity_card):
		harvest_opportunity_card.visible = not pending_harvest_opportunities.is_empty()

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
	net_option_empty_state.text = "暂无可用下网方式，请返回看看其他选择。"
	net_option_empty_state.custom_minimum_size = Vector2(0, 140)
	net_option_empty_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	net_option_empty_state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	net_option_empty_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.style_label(net_option_empty_state, "body_dark")
	work_plan_panel.add_child(net_option_empty_state)
