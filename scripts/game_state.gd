extends RefCounted
class_name GameState

const DataLoaderScript := preload("res://scripts/data_loader.gd")

var cash: int = 0
var day: int = 1
var min_working_capital: int = 0
var daily_ponds_day: int = 0
var daily_ponds: Array[Dictionary] = []
var current_pond: Dictionary = {}
var inspection_cost_total: int = 0
var inspection_results: Array[String] = []
var one_net_income: int = 0
var transfer_income: int = 0
var work_cost: int = 0
var fish_income: int = 0
var last_result: Dictionary = {}

func _init() -> void:
	var balance: Dictionary = DataLoaderScript.load_json(DataLoaderScript.GAME_BALANCE_PATH, {})
	cash = int(balance.get("initial_cash", 10000))
	min_working_capital = int(balance.get("min_working_capital", 1000))
	day = 1

func reset_round() -> void:
	current_pond = {}
	inspection_cost_total = 0
	inspection_results = []
	one_net_income = 0
	transfer_income = 0
	work_cost = 0
	fish_income = 0
	last_result = {}

func can_pay(amount: int) -> bool:
	return amount <= 0 or cash >= amount

func pay_inspection_cost(amount: int) -> bool:
	if not can_pay(amount):
		return false

	if amount > 0:
		cash -= amount
		inspection_cost_total += amount

	return true

func add_inspection_result(result_text: String) -> void:
	inspection_results.append(result_text)

func get_contract_preview(pond: Dictionary) -> Dictionary:
	var quote_price := int(pond.get("quote_price", 0))
	var remaining_cash := cash - quote_price
	return {
		"current_cash": cash,
		"quote_price": quote_price,
		"remaining_cash": remaining_cash,
		"min_working_capital": min_working_capital,
		"can_contract": remaining_cash >= min_working_capital
	}

func can_contract_pond(pond: Dictionary) -> bool:
	return bool(get_contract_preview(pond).get("can_contract", false))

func contract_pond(pond: Dictionary) -> bool:
	if not can_contract_pond(pond):
		return false

	cash -= int(pond.get("quote_price", 0))
	current_pond = pond.duplicate(true)
	return true
