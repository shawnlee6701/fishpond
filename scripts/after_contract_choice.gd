extends Control

@onready var pond_name_label: Label = $Panel/Margin/Content/PondNameLabel
@onready var cash_label: Label = $Panel/Margin/Content/CashLabel
@onready var transfer_button: Button = $Panel/Margin/Content/ChoiceButtons/TransferButton
@onready var sell_one_net_button: Button = $Panel/Margin/Content/ChoiceButtons/SellOneNetButton
@onready var harvest_self_button: Button = $Panel/Margin/Content/ChoiceButtons/HarvestSelfButton
@onready var abandon_button: Button = $Panel/Margin/Content/ChoiceButtons/AbandonButton
@onready var message_label: Label = $Panel/Margin/Content/MessageLabel
@onready var transfer_confirm_panel: VBoxContainer = $Panel/Margin/Content/TransferConfirmPanel
@onready var transfer_offer_label: Label = $Panel/Margin/Content/TransferConfirmPanel/TransferOfferLabel
@onready var accept_transfer_button: Button = $Panel/Margin/Content/TransferConfirmPanel/Buttons/AcceptTransferButton
@onready var reject_transfer_button: Button = $Panel/Margin/Content/TransferConfirmPanel/Buttons/RejectTransferButton
@onready var work_plan_panel: VBoxContainer = $Panel/Margin/Content/WorkPlanPanel
@onready var low_work_button: Button = $Panel/Margin/Content/WorkPlanPanel/LowWorkButton
@onready var standard_work_button: Button = $Panel/Margin/Content/WorkPlanPanel/StandardWorkButton
@onready var full_work_button: Button = $Panel/Margin/Content/WorkPlanPanel/FullWorkButton

var game_state: GameState
var screen_container: Control
var resolver := ActionResolver.new()
var current_transfer_offer: Dictionary = {}
var current_one_net_offer: Dictionary = {}

func setup(next_game_state: GameState, next_screen_container: Control) -> void:
	game_state = next_game_state
	screen_container = next_screen_container

func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()

	transfer_button.pressed.connect(_on_transfer_pressed)
	sell_one_net_button.pressed.connect(_on_sell_one_net_pressed)
	harvest_self_button.pressed.connect(_on_harvest_self_pressed)
	abandon_button.pressed.connect(_on_abandon_pressed)
	accept_transfer_button.pressed.connect(_on_accept_transfer_pressed)
	reject_transfer_button.pressed.connect(_on_reject_transfer_pressed)
	low_work_button.pressed.connect(_on_work_plan_pressed.bind("low"))
	standard_work_button.pressed.connect(_on_work_plan_pressed.bind("standard"))
	full_work_button.pressed.connect(_on_work_plan_pressed.bind("full"))
	_render()

func _render() -> void:
	var pond := game_state.current_pond
	pond_name_label.text = "当前鱼塘：%s" % str(pond.get("name", "未承包鱼塘"))
	cash_label.text = "当前现金：%d 元" % game_state.cash

	transfer_button.text = "转包"
	sell_one_net_button.text = "卖给别人一网"
	harvest_self_button.text = "自己捞"
	abandon_button.text = "放弃"
	transfer_button.disabled = current_transfer_offer.is_empty()
	sell_one_net_button.disabled = current_one_net_offer.is_empty() or game_state.sold_one_net
	if current_transfer_offer.is_empty():
		transfer_button.text = "转包（暂无报价）"
	if game_state.sold_one_net:
		sell_one_net_button.text = "卖一网（已卖出）"
	elif current_one_net_offer.is_empty():
		sell_one_net_button.text = "卖给别人一网（暂无买家）"
	if not game_state.can_pay(game_state.get_work_cost("low")):
		message_label.text = "当前现金不足以支付最低作业成本，可以选择放弃，直接进入本局结算。"
	elif game_state.self_net_count <= 0:
		message_label.text = "先自己捞一网，市场才会根据鱼情给出转包或买一网的机会。"

	_update_work_buttons()

func _hide_detail_panels() -> void:
	transfer_confirm_panel.visible = false
	work_plan_panel.visible = false

func _on_transfer_pressed() -> void:
	if current_transfer_offer.is_empty():
		message_label.text = "还没人愿意接手。先自己捞一网，让外面的人看到鱼情。"
		return

	_hide_detail_panels()
	transfer_offer_label.text = str(current_transfer_offer.get("text", ""))
	transfer_confirm_panel.visible = true
	message_label.text = ""

func _on_accept_transfer_pressed() -> void:
	game_state.apply_transfer(int(current_transfer_offer.get("income", 0)))
	UIController.show_settlement(screen_container, game_state)

func _on_reject_transfer_pressed() -> void:
	current_transfer_offer = {}
	transfer_confirm_panel.visible = false
	message_label.text = "你拒绝了转包报价，继续自己拿主意。"
	_render()

func _on_sell_one_net_pressed() -> void:
	_hide_detail_panels()
	if game_state.sold_one_net:
		message_label.text = "这一局已经卖过一网了，不能重复卖。"
		_render()
		return
	if current_one_net_offer.is_empty():
		message_label.text = "暂时没人愿意买一网。先自己捞一网，把鱼情打出来。"
		_render()
		return

	if game_state.apply_one_net(int(current_one_net_offer.get("income", 0)), str(current_one_net_offer.get("text", ""))):
		message_label.text = "%s\n买家支付 %d 元，你获得一网收入。" % [str(current_one_net_offer.get("text", "")), int(current_one_net_offer.get("income", 0))]
		current_one_net_offer = {}
	_render()

func _on_abandon_pressed() -> void:
	_hide_detail_panels()
	game_state.apply_abandon()
	UIController.show_settlement(screen_container, game_state)

func _on_harvest_self_pressed() -> void:
	_hide_detail_panels()
	work_plan_panel.visible = true
	message_label.text = "捞一网可以多次做；全部抽干只能做一次，做完直接结算。现金不足的方案不能选择。"
	_update_work_buttons()

func _on_work_plan_pressed(plan_id: String) -> void:
	var cost := game_state.get_work_cost(plan_id)
	if not game_state.can_pay(cost):
		message_label.text = "现金不足，无法选择这个作业方案。"
		_update_work_buttons()
		return

	var result := resolver.generate_harvest_result(game_state.current_pond, plan_id, cost)
	if game_state.apply_harvest(result):
		if bool(result.get("is_final", false)):
			UIController.show_settlement(screen_container, game_state)
			return

		var opportunities := resolver.generate_disposal_opportunities(game_state.current_pond, result)
		current_transfer_offer = opportunities.get("transfer_offer", {})
		if not game_state.sold_one_net:
			current_one_net_offer = opportunities.get("one_net_offer", {})
		message_label.text = "%s\n%s" % [str(result.get("text", "")), str(opportunities.get("message", ""))]
		work_plan_panel.visible = false
		_render()
	else:
		message_label.text = "现金不足，无法选择这个作业方案。"
		_update_work_buttons()

func _update_work_buttons() -> void:
	var low_cost := game_state.get_work_cost("low")
	var standard_cost := game_state.get_work_cost("standard")
	var full_cost := game_state.get_work_cost("full")

	low_work_button.text = "低成本捞一网（%d 元）" % low_cost
	standard_work_button.text = "标准捞一网（%d 元）" % standard_cost
	full_work_button.text = "全部抽干（%d 元）" % full_cost
	low_work_button.disabled = not game_state.can_pay(low_cost)
	standard_work_button.disabled = not game_state.can_pay(standard_cost)
	full_work_button.disabled = game_state.drained or not game_state.can_pay(full_cost)
