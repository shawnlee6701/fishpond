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
var current_pond_estimated_value: int = 0
var last_result: Dictionary = {}
var sold_one_net: bool = false
var self_net_count: int = 0
var drained: bool = false
var settlement_recorded: bool = false
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
	current_pond_estimated_value = 0
	last_result = {}
	sold_one_net = false
	self_net_count = 0
	drained = false
	settlement_recorded = false

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
	inspection_results.append(result_text)

func set_inspection_feedback(tool_id: String, feedback_text: String) -> void:
	inspection_feedback_by_tool[tool_id] = feedback_text

func get_inspection_feedback(tool_id: String) -> String:
	return str(inspection_feedback_by_tool.get(tool_id, ""))

func get_contract_preview(pond: Dictionary) -> Dictionary:
	var quote_price := int(pond.get("quote_price", 0))
	var contract_extra_cost := get_contract_extra_cost(pond)
	var contract_total_cost := quote_price + contract_extra_cost
	var remaining_cash := cash - contract_total_cost
	var recommended_working_capital := get_recommended_working_capital(pond)
	return {
		"current_cash": cash,
		"quote_price": quote_price,
		"pond_price": quote_price,
		"contract_extra_cost": contract_extra_cost,
		"contract_total_cost": contract_total_cost,
		"remaining_cash": remaining_cash,
		"remaining_after_contract": remaining_cash,
		"min_working_capital": min_working_capital,
		"recommended_working_capital": recommended_working_capital,
		"can_contract": remaining_cash >= min_working_capital
	}

func get_contract_extra_cost(pond: Dictionary) -> int:
	return maxi(0, int(pond.get("contract_extra_cost", game_balance.get("contract_extra_cost", 0))))

func get_recommended_working_capital(pond: Dictionary) -> int:
	var configured := int(game_balance.get("recommended_working_capital", 0))
	if configured > 0:
		return maxi(min_working_capital, configured)

	var standard_cost := int(game_balance.get("standard_work_cost", 1200))
	var quote_price := int(pond.get("quote_price", 0))
	var full_work_min_cost := int(game_balance.get("full_work_min_cost", 2000))
	var full_work_quote_ratio := float(game_balance.get("full_work_quote_ratio", 0.2))
	var likely_big_work_cost := maxi(full_work_min_cost, int(round(float(quote_price) * full_work_quote_ratio)))
	return maxi(min_working_capital, standard_cost + likely_big_work_cost)

func can_contract_pond(pond: Dictionary) -> bool:
	return bool(get_contract_preview(pond).get("can_contract", false))

func contract_pond(pond: Dictionary) -> bool:
	var preview := get_contract_preview(pond)
	if not bool(preview.get("can_contract", false)):
		return false

	cash -= int(preview.get("contract_total_cost", 0))
	current_pond = pond.duplicate(true)
	current_pond["contract_extra_cost"] = int(preview.get("contract_extra_cost", 0))
	current_pond["contract_total_cost"] = int(preview.get("contract_total_cost", current_pond.get("quote_price", 0)))
	current_pond_estimated_value = int(current_pond.get("quote_price", 0))
	current_pond["estimated_transfer_value"] = current_pond_estimated_value
	return true

func get_current_pond_estimated_value() -> int:
	if current_pond_estimated_value > 0:
		return current_pond_estimated_value
	return int(current_pond.get("estimated_transfer_value", current_pond.get("quote_price", 0)))

func get_mark_to_market_profit() -> int:
	if current_pond.is_empty():
		return get_net_profit()

	return get_current_pond_estimated_value() + one_net_income + fish_income - _current_contract_cost() - inspection_cost_total - work_cost

func get_work_cost(plan_id: String) -> int:
	match plan_id:
		"low":
			return int(game_balance.get("low_work_cost", 500))
		"full", "drain":
			return get_full_work_cost()
		_:
			return int(game_balance.get("standard_work_cost", 1200))

func get_full_work_cost() -> int:
	var min_cost := int(game_balance.get("full_work_min_cost", 2000))
	var quote_ratio := float(game_balance.get("full_work_quote_ratio", 0.2))
	var quote_price := int(current_pond.get("quote_price", 0))
	return maxi(min_cost, int(round(float(quote_price) * quote_ratio)))

func apply_transfer(income: int, transfer_profit_loss: int = 0) -> void:
	transfer_income = income
	cash += income
	current_pond["status"] = "transferred"
	current_pond["settlement_status"] = "已转包"
	current_pond["transfer_profit_loss"] = transfer_profit_loss
	last_result = {
		"type": "transfer",
		"title": "转包结算",
		"message": "你以 %d 元把这口塘转了出去，后面的鱼情和风险都不归你了。" % income,
		"transfer_profit_loss": transfer_profit_loss
	}

func apply_one_net(income: int, result_text: String) -> bool:
	if sold_one_net:
		return false

	sold_one_net = true
	one_net_income = income
	cash += income
	var one_net_catch := _remove_sold_one_net_stock()
	_update_estimated_value_after_one_net(income, one_net_catch)
	var reveal_text := _format_one_net_reveal(one_net_catch)
	last_result = {
		"type": "one_net",
		"title": "卖一网",
		"message": "%s\n你先收下一网钱 %d 元，但这网里真有好鱼也归买家。\n%s" % [result_text, income, reveal_text]
	}
	return true

func _remove_sold_one_net_stock() -> Array[Dictionary]:
	var removed_details: Array[Dictionary] = []
	var stock := Array(current_pond.get("fish_stock", []))
	if stock.is_empty():
		return removed_details

	for index in range(stock.size()):
		var item := Dictionary(stock[index])
		var fish_id := str(item.get("id", ""))
		var remaining_weight := int(item.get("remaining_weight_jin", item.get("weight_jin", 0)))
		var unit_price := int(item.get("unit_price", 0))
		var weight_unit := int(item.get("weight_unit", _get_default_weight_unit(fish_id)))
		var remove_ratio := _get_one_net_remove_ratio(fish_id)
		var removed_weight := _snap_weight_down(float(remaining_weight) * remove_ratio, weight_unit)
		removed_weight = mini(removed_weight, remaining_weight)
		if removed_weight > 0:
			removed_details.append({
				"id": fish_id,
				"name": str(item.get("name", fish_id)),
				"weight_jin": removed_weight,
				"unit_price": unit_price,
				"income": removed_weight * unit_price
			})
		item["remaining_weight_jin"] = remaining_weight - removed_weight
		item["remaining_income"] = int(item.get("remaining_weight_jin", 0)) * unit_price
		stock[index] = item

	current_pond["fish_stock"] = stock
	current_pond["remaining_fish_value"] = _sum_remaining_stock_income(stock)
	return removed_details

func _update_estimated_value_after_one_net(income: int, one_net_catch: Array[Dictionary]) -> void:
	var previous := get_current_pond_estimated_value()
	var remaining_value := int(current_pond.get("remaining_fish_value", current_pond.get("hidden_value", previous)))
	var reveal_signal := _get_one_net_reveal_signal(one_net_catch)
	var signal_factor := clampf(1.0 + reveal_signal * 0.32, 0.72, 1.35)
	var market_anchor := (float(previous) * 0.5 + float(remaining_value) * 0.5) * signal_factor - float(income) * 0.12
	var quote_price := int(current_pond.get("quote_price", previous))
	var min_value := int(float(quote_price) * 0.12)
	var max_value := int(maxf(float(quote_price) * 2.2, float(remaining_value) * 1.35))
	var next_value := int(round(market_anchor / 100.0)) * 100
	current_pond_estimated_value = clampi(next_value, min_value, max_value)
	current_pond["estimated_transfer_value"] = current_pond_estimated_value

func _get_one_net_reveal_signal(one_net_catch: Array[Dictionary]) -> float:
	if one_net_catch.is_empty():
		return -0.8

	var total_income := 0
	var best_rank := 0
	for item in one_net_catch:
		total_income += int(item.get("income", 0))
		best_rank = maxi(best_rank, _fish_rank(str(item.get("id", ""))))

	var paid_income := maxi(1, one_net_income)
	var value_signal := clampf((float(total_income) - float(paid_income)) / float(paid_income), -1.0, 1.4)
	var species_signal := 0.0
	match best_rank:
		4:
			species_signal = 1.5
		3:
			species_signal = 0.85
		2:
			species_signal = 0.15
		1:
			species_signal = -0.25
		_:
			species_signal = -0.8
	return clampf(value_signal * 0.65 + species_signal * 0.35, -1.0, 1.5)

func _format_one_net_reveal(one_net_catch: Array[Dictionary]) -> String:
	if one_net_catch.is_empty():
		return "买家这一网几乎没起货，外面会觉得这塘不太行。"

	var lines: Array[String] = ["买家这一网开出来："]
	for item in one_net_catch:
		lines.append("%s：%d 斤，估 %d 元" % [
			str(item.get("name", "")),
			int(item.get("weight_jin", 0)),
			int(item.get("income", 0))
		])
	lines.append("开窗后塘口估值变为 %d 元。" % current_pond_estimated_value)
	return "\n".join(lines)

func _fish_rank(fish_id: String) -> int:
	match fish_id:
		"fish_king":
			return 4
		"big_fish":
			return 3
		"normal_fish":
			return 2
		"small_fish":
			return 1
		_:
			return 0

func _get_one_net_remove_ratio(fish_id: String) -> float:
	match fish_id:
		"small_fish":
			return 0.24
		"normal_fish":
			return 0.2
		"big_fish":
			return 0.16
		"fish_king":
			return 0.0
		_:
			return 0.15

func _get_default_weight_unit(fish_id: String) -> int:
	match fish_id:
		"small_fish":
			return 1
		"normal_fish":
			return 5
		"big_fish":
			return 10
		"fish_king":
			return 50
		_:
			return 1

func _snap_weight_down(weight: float, unit: int) -> int:
	if weight <= 0.0:
		return 0
	var safe_unit := maxi(1, unit)
	return int(floor(weight / float(safe_unit))) * safe_unit

func _sum_remaining_stock_income(stock: Array) -> int:
	var total := 0
	for item_variant in stock:
		var item := Dictionary(item_variant)
		total += int(item.get("remaining_income", int(item.get("remaining_weight_jin", 0)) * int(item.get("unit_price", 0))))
	return total

func apply_abandon() -> void:
	last_result = {
		"type": "abandon",
		"title": "放弃结算",
		"message": "你决定认亏收手，本局不再花作业钱，也不会再有卖鱼收入。"
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
		_update_estimated_value_after_harvest(result)
	last_result = {
		"type": "harvest",
		"title": "抽干结算" if bool(result.get("is_final", false)) else "一网结果",
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

func _update_estimated_value_after_harvest(result: Dictionary) -> void:
	var quote_price := int(current_pond.get("quote_price", 0))
	var previous := get_current_pond_estimated_value()
	var remaining_value := int(current_pond.get("remaining_fish_value", current_pond.get("hidden_value", quote_price)))
	var quality := float(result.get("quality", 0.0))
	var signal_factor := clampf(1.0 + quality * 0.35, 0.68, 1.38)
	var market_anchor := (float(previous) * 0.45 + float(remaining_value) * 0.55) * signal_factor
	var min_value := int(float(quote_price) * 0.12)
	var max_value := int(maxf(float(quote_price) * 2.2, float(remaining_value) * 1.35))
	var next_value := int(round(market_anchor / 100.0)) * 100
	current_pond_estimated_value = clampi(next_value, min_value, max_value)
	current_pond["estimated_transfer_value"] = current_pond_estimated_value

func _merge_catch_details(next_catch_details: Array) -> void:
	for next_item in next_catch_details:
		var fish_id := str(next_item.get("id", ""))
		var existing := _find_catch_detail(fish_id)
		if existing.is_empty():
			var catch_item := {
				"id": fish_id,
				"name": str(next_item.get("name", fish_id)),
				"weight_jin": int(next_item.get("weight_jin", 0)),
				"income": int(next_item.get("income", 0))
			}
			if next_item.has("unit_price"):
				catch_item["unit_price"] = int(next_item.get("unit_price", 0))
			if next_item.has("integrity"):
				catch_item["integrity"] = int(next_item.get("integrity", 0))
			if next_item.has("price_note"):
				catch_item["price_note"] = str(next_item.get("price_note", ""))
			catch_details.append(catch_item)
		else:
			existing["weight_jin"] = int(existing.get("weight_jin", 0)) + int(next_item.get("weight_jin", 0))
			existing["income"] = int(existing.get("income", 0)) + int(next_item.get("income", 0))
			if next_item.has("unit_price"):
				existing["unit_price"] = int(next_item.get("unit_price", 0))
			if next_item.has("integrity"):
				existing["integrity"] = int(next_item.get("integrity", 0))
			if next_item.has("price_note"):
				existing["price_note"] = str(next_item.get("price_note", ""))

func _find_catch_detail(fish_id: String) -> Dictionary:
	for item in catch_details:
		if str(item.get("id", "")) == fish_id:
			return item
	return {}

func get_net_profit() -> int:
	var contract_cost := _current_contract_cost()
	return transfer_income + one_net_income + fish_income - contract_cost - inspection_cost_total - work_cost

func _current_contract_cost() -> int:
	return int(current_pond.get("contract_total_cost", current_pond.get("quote_price", 0)))

func advance_to_next_day() -> void:
	day += 1
	reset_round()
	var generator := PondGeneratorScript.new()
	daily_ponds = generator.generate_daily_ponds(day, cash)
	daily_ponds_day = day
