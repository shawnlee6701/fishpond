extends Control

const UIKit := preload("res://scripts/ui_kit.gd")
const TRANSFER_POPUP_TEXTURE := preload("res://Design/Popup/popup_clean.png")
const TRANSFER_PERSON_TEXTURE := preload("res://Design/Other Person/screen_clean.png")
const FISH_KING_TEXTURE := preload("res://Design/Catch Fish King/screen_clean.png")
const EARN_MORE_TEXTURE := preload("res://Design/Earn More/screen_clean.png")
const EARN_LESS_TEXTURE := preload("res://Design/Earn Less/screen_clean.png")

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $TitleLabel
@onready var pond_name_label: Label = $Panel/Margin/Content/PondNameLabel
@onready var cash_label: Label = $CashLabel
@onready var estimate_label: Label = $Panel/Margin/Content/EstimateLabel
@onready var profit_label: Label = $Panel/Margin/Content/ProfitLabel
@onready var choice_buttons: VBoxContainer = $Panel/Margin/Content/ChoiceButtons
@onready var transfer_button: Button = $Panel/Margin/Content/ChoiceButtons/TransferButton
@onready var sell_one_net_button: Button = $Panel/Margin/Content/ChoiceButtons/SellOneNetButton
@onready var harvest_self_button: Button = $Panel/Margin/Content/ChoiceButtons/HarvestSelfButton
@onready var message_label: Label = $Panel/Margin/Content/MessageLabel
@onready var work_plan_back_button: Button = $Panel/Margin/Content/WorkPlanBackButton
@onready var work_plan_panel: VBoxContainer = $Panel/Margin/Content/WorkPlanPanel
@onready var low_work_button: Button = $Panel/Margin/Content/WorkPlanPanel/LowWorkButton
@onready var standard_work_button: Button = $Panel/Margin/Content/WorkPlanPanel/StandardWorkButton
@onready var full_work_button: Button = $Panel/Margin/Content/WorkPlanPanel/FullWorkButton

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
var harvest_result_illustration: TextureRect
var harvest_result_label: Label

func setup(next_game_state: GameState, next_screen_container: Control) -> void:
	game_state = next_game_state
	screen_container = next_screen_container

func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()

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
	UIKit.apply_root(self)
	UIKit.style_page_frame(panel)
	var margin := panel.get_node_or_null("Margin") as MarginContainer
	if margin != null:
		margin.add_theme_constant_override("margin_left", 54)
		margin.add_theme_constant_override("margin_top", 52)
		margin.add_theme_constant_override("margin_right", 54)
		margin.add_theme_constant_override("margin_bottom", 52)
	UIKit.style_page_title(title_label)
	UIKit.style_label(pond_name_label, "content_title")
	UIKit.style_top_status(cash_label)
	UIKit.style_highlight_label(estimate_label, "price")
	UIKit.style_highlight_label(profit_label, "gold")
	UIKit.style_label(message_label, "body_dark")
	UIKit.style_label(transfer_offer_label, "body_dark")
	UIKit.style_button(transfer_button, "ghost")
	UIKit.style_button(sell_one_net_button, "secondary")
	UIKit.style_button(harvest_self_button, "primary")
	UIKit.style_button(work_plan_back_button, "ghost")
	UIKit.style_button(accept_transfer_button, "primary")
	UIKit.style_button(reject_transfer_button, "ghost")
	UIKit.style_button(low_work_button, "secondary")
	UIKit.style_button(standard_work_button, "secondary")
	UIKit.style_button(full_work_button, "gold")
	transfer_button.custom_minimum_size = Vector2(0, 96)
	sell_one_net_button.custom_minimum_size = Vector2(0, 96)
	harvest_self_button.custom_minimum_size = Vector2(0, 96)
	work_plan_back_button.custom_minimum_size = Vector2(0, 64)
	low_work_button.custom_minimum_size = Vector2(0, 220)
	standard_work_button.custom_minimum_size = Vector2(0, 220)
	full_work_button.custom_minimum_size = Vector2(0, 220)
	low_work_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	standard_work_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	full_work_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	work_plan_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_show_choice_page()

func _create_transfer_dialog() -> void:
	var modal := UIKit.create_modal_layer(self, "TransferModal", TRANSFER_POPUP_TEXTURE)
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

	var character_row := HBoxContainer.new()
	character_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	character_row.add_theme_constant_override("separation", 12)
	body.add_child(character_row)

	var person := TextureRect.new()
	person.custom_minimum_size = Vector2(280, 300)
	person.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	person.size_flags_vertical = Control.SIZE_EXPAND_FILL
	person.texture = TRANSFER_PERSON_TEXTURE
	person.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	person.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	person.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_row.add_child(person)

	var bubble := PanelContainer.new()
	bubble.custom_minimum_size = Vector2(250, 0)
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bubble.add_theme_stylebox_override("panel", UIKit.make_style(Color("fff8df"), Color("6d241f"), 24, 3, true))
	character_row.add_child(bubble)

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
	var modal := UIKit.create_modal_layer(self, "HarvestResultModal", TRANSFER_POPUP_TEXTURE)
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

	harvest_result_illustration = TextureRect.new()
	harvest_result_illustration.custom_minimum_size = Vector2(0, 520)
	harvest_result_illustration.size_flags_vertical = Control.SIZE_EXPAND_FILL
	harvest_result_illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	harvest_result_illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	harvest_result_illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(harvest_result_illustration)

	harvest_result_label = Label.new()
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
	pond_name_label.text = "已包下：%s" % str(pond.get("name", "未承包鱼塘"))
	cash_label.text = UIKit.format_run_status(game_state.day, game_state.cash)
	estimate_label.text = "塘口估值：%d 元" % game_state.get_current_pond_estimated_value()
	var mark_to_market := game_state.get_mark_to_market_profit()
	profit_label.text = "塘口账面：%+d 元" % mark_to_market
	UIKit.style_highlight_label(profit_label, "positive" if mark_to_market >= 0 else "negative")

	transfer_button.text = "转包脱手"
	sell_one_net_button.text = "卖一网给别人"
	harvest_self_button.text = "自己下网"
	transfer_button.disabled = current_transfer_offer.is_empty() or game_state.drained
	sell_one_net_button.disabled = current_one_net_offer.is_empty() or game_state.sold_one_net
	if current_transfer_offer.is_empty():
		transfer_button.text = "转包脱手（暂无报价）"
	if game_state.sold_one_net:
		sell_one_net_button.text = "卖一网（已卖出）"
	elif current_one_net_offer.is_empty():
		sell_one_net_button.text = "卖一网（暂无买家）"
	if not game_state.can_pay(game_state.get_work_cost("low")):
		message_label.text = "钱不够下一网了。可以转包脱手，留本钱去下一地方。"
	elif game_state.self_net_count <= 0:
		message_label.text = "先自己下一网。没见到鱼，外面不给真价。"

	_update_work_buttons()

func _hide_detail_panels() -> void:
	_close_transfer_dialog()
	_show_choice_page()

func _show_choice_page() -> void:
	title_label.text = "塘已经包下"
	estimate_label.visible = true
	profit_label.visible = true
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choice_buttons.visible = true
	work_plan_back_button.visible = false
	work_plan_panel.visible = false

func _show_work_plan_page() -> void:
	title_label.text = "自己下网"
	estimate_label.visible = false
	profit_label.visible = false
	message_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	choice_buttons.visible = false
	work_plan_back_button.visible = true
	work_plan_panel.visible = true

func _close_transfer_dialog() -> void:
	UIKit.hide_modal(transfer_overlay)

func _refresh_transfer_offer() -> void:
	game_state.current_pond["estimated_transfer_value"] = game_state.get_current_pond_estimated_value()
	current_transfer_offer = resolver.generate_transfer_offer(game_state.current_pond)

func _on_transfer_pressed() -> void:
	if current_transfer_offer.is_empty():
		message_label.text = "现在没人肯接手。先自己下一网，让外面的人看到这塘到底有没有货。"
		return

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
	_show_work_plan_page()
	message_label.text = "选一种下网方式。抽干会直接结算，钱不够的方案不能选。"
	_update_work_buttons()

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

func _show_harvest_result(result: Dictionary) -> void:
	var caught_fish_king := false
	for item in Array(result.get("catch_details", [])):
		if str(Dictionary(item).get("id", "")) == "fish_king":
			caught_fish_king = true
			break

	var round_profit := int(result.get("fish_income", 0)) - int(result.get("work_cost", 0))
	if caught_fish_king:
		harvest_result_title.text = "鱼王出现！"
		harvest_result_illustration.texture = FISH_KING_TEXTURE
	elif round_profit > 0:
		harvest_result_title.text = "这一网赚到了"
		harvest_result_illustration.texture = EARN_MORE_TEXTURE
	else:
		harvest_result_title.text = "这一网没回本"
		harvest_result_illustration.texture = EARN_LESS_TEXTURE

	harvest_result_label.text = "%s\n本次赚亏 %+d 元" % [
		str(result.get("fish_result_name", "下网结果")),
		round_profit
	]
	UIKit.style_highlight_label(harvest_result_label, "positive" if round_profit > 0 else "negative")
	UIKit.show_modal(self, harvest_result_overlay, harvest_result_dialog, 0.86, 1060, Vector2i(340, 700), Vector2i(860, 1160))

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
