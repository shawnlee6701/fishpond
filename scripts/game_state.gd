extends RefCounted
class_name GameState

const DataLoaderScript := preload("res://scripts/data_loader.gd")
const PondGeneratorScript := preload("res://scripts/pond_generator.gd")

var cash: int = 0
var day: int = 1
var min_working_capital: int = 0
var daily_ponds_day: int = 0
var daily_ponds: Array[Dictionary] = []
var current_pond: Dictionary = {}
var inspection_cost_total: int = 0
var inspection_results: Array[String] = []
var inspection_results_by_tool: Dictionary = {}
var inspection_feedback_by_tool: Dictionary = {}
var one_net_income: int = 0
var transfer_income: int = 0
var work_cost: int = 0
var fish_income: int = 0
var fish_result_id: String = ""
var fish_result_name: String = ""
var fish_description: String = ""
var catch_details: Array[Dictionary] = []
var last_result: Dictionary = {}
var sold_one_net: bool = false
var self_net_count: int = 0
var drained: bool = false
var game_balance: Dictionary = {}

func _init() -> void:
	game_balance = DataLoaderScript.load_json(DataLoaderScript.GAME_BALANCE_PATH, {})
	cash = int(game_balance.get("initial_cash", 10000))
	min_working_capital = int(game_balance.get("min_working_capital", 1000))
	day = 1

func reset_round() -> void:
	current_pond = {}
	inspection_cost_total = 0
	inspection_results = []
	inspection_results_by_tool = {}
	inspection_feedback_by_tool = {}
	one_net_income = 0
	transfer_income = 0
	work_cost = 0
	fish_income = 0
	fish_result_id = ""
	fish_result_name = ""
	fish_description = ""
	catch_details = []
	last_result = {}
	sold_one_net = false
	self_net_count = 0
	drained = false

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

func has_inspection_result(tool_id: String) -> bool:
	return inspection_results_by_tool.has(tool_id)

func set_inspection_result(tool_id: String, result_text: String) -> void:
	inspection_results_by_tool[tool_id] = result_text
	inspection_feedback_by_tool[tool_id] = result_text

func set_inspection_feedback(tool_id: String, feedback_text: String) -> void:
	inspection_feedback_by_tool[tool_id] = feedback_text

func get_inspection_feedback(tool_id: String) -> String:
	return str(inspection_feedback_by_tool.get(tool_id, ""))

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

func get_work_cost(plan_id: String) -> int:
	match plan_id:
		"low":
			return int(game_balance.get("low_work_cost", 500))
		"full":
			return int(game_balance.get("full_work_cost", 2500))
		_:
			return int(game_balance.get("standard_work_cost", 1200))

func apply_transfer(income: int) -> void:
	transfer_income = income
	cash += income
	last_result = {
		"type": "transfer",
		"title": "转包结算",
		"message": "你以 %d 元转包了这口塘。" % income
	}

func apply_one_net(income: int, result_text: String) -> bool:
	if sold_one_net:
		return false

	sold_one_net = true
	one_net_income = income
	cash += income
	last_result = {
		"type": "one_net",
		"title": "卖一网",
		"message": "%s\n获得一网收入 %d 元。" % [result_text, income]
	}
	return true

func apply_abandon() -> void:
	last_result = {
		"type": "abandon",
		"title": "放弃结算",
		"message": "你放弃继续作业，本局不再产生作业成本和卖鱼收入。"
	}

func apply_harvest(result: Dictionary) -> bool:
	var cost := int(result.get("work_cost", 0))
	if not can_pay(cost):
		return false

	work_cost += cost
	fish_income += int(result.get("fish_income", 0))
	fish_result_id = str(result.get("fish_result_id", fish_result_id))
	fish_result_name = str(result.get("fish_result_name", fish_result_name))
	fish_description = str(result.get("fish_description", fish_description))
	_merge_catch_details(result.get("catch_details", []))
	cash -= cost
	cash += int(result.get("fish_income", 0))
	if bool(result.get("is_final", false)):
		drained = true
	else:
		self_net_count += 1
	last_result = {
		"type": "harvest",
		"title": "全部抽干结算" if bool(result.get("is_final", false)) else "捞一网结果",
		"message": str(result.get("text", "")),
		"plan_name": str(result.get("plan_name", "")),
		"work_cost": work_cost,
		"fish_income": fish_income,
		"fish_result_id": fish_result_id,
		"fish_result_name": fish_result_name,
		"fish_description": fish_description,
		"catch_details": catch_details,
		"is_final": bool(result.get("is_final", false))
	}
	return true

func _merge_catch_details(next_catch_details: Array) -> void:
	for next_item in next_catch_details:
		var fish_id := str(next_item.get("id", ""))
		var existing := _find_catch_detail(fish_id)
		if existing.is_empty():
			catch_details.append({
				"id": fish_id,
				"name": str(next_item.get("name", fish_id)),
				"weight_jin": int(next_item.get("weight_jin", 0)),
				"income": int(next_item.get("income", 0))
			})
		else:
			existing["weight_jin"] = int(existing.get("weight_jin", 0)) + int(next_item.get("weight_jin", 0))
			existing["income"] = int(existing.get("income", 0)) + int(next_item.get("income", 0))

func _find_catch_detail(fish_id: String) -> Dictionary:
	for item in catch_details:
		if str(item.get("id", "")) == fish_id:
			return item
	return {}

func get_net_profit() -> int:
	return transfer_income + one_net_income + fish_income - inspection_cost_total - work_cost

func advance_to_next_day() -> void:
	day += 1
	reset_round()
	var generator := PondGeneratorScript.new()
	daily_ponds = generator.generate_daily_ponds(day, cash)
	daily_ponds_day = day
