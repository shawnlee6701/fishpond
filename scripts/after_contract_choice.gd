extends Control

@onready var pond_name_label: Label = $Panel/Margin/Content/PondNameLabel
@onready var cash_label: Label = $Panel/Margin/Content/CashLabel
@onready var transfer_button: Button = $Panel/Margin/Content/ChoiceButtons/TransferButton
@onready var sell_one_net_button: Button = $Panel/Margin/Content/ChoiceButtons/SellOneNetButton
@onready var harvest_self_button: Button = $Panel/Margin/Content/ChoiceButtons/HarvestSelfButton

var game_state: GameState
var screen_container: Control

func setup(next_game_state: GameState, next_screen_container: Control) -> void:
	game_state = next_game_state
	screen_container = next_screen_container

func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()

	_render()

func _render() -> void:
	var pond := game_state.current_pond
	pond_name_label.text = "当前鱼塘：%s" % str(pond.get("name", "未承包鱼塘"))
	cash_label.text = "当前现金：%d 元" % game_state.cash

	transfer_button.text = "转包"
	sell_one_net_button.text = "卖一网"
	harvest_self_button.text = "自己捞"
