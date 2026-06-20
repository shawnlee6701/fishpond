extends SceneTree

const BalanceRulesScript := preload("res://scripts/balance_rules.gd")
const DataLoaderScript := preload("res://scripts/data_loader.gd")
const GameStateScript := preload("res://scripts/game_state.gd")
const PondGeneratorScript := preload("res://scripts/pond_generator.gd")
const ActionResolverScript := preload("res://scripts/action_resolver.gd")

var rules: Dictionary = {}
var simulation_rules: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rules = BalanceRulesScript.load_rules()
	simulation_rules = BalanceRulesScript.section(rules, "simulation")
	var runs := _get_arg_int("runs", BalanceRulesScript.integer(simulation_rules, "default_runs", 1000))
	var max_days := _get_arg_int("days", BalanceRulesScript.integer(simulation_rules, "max_days", 12))
	var seed := _get_arg_int("seed", BalanceRulesScript.integer(simulation_rules, "seed", 20260619))
	rng.seed = seed

	print("BALANCE_SIMULATION")
	print("runs=%d max_days=%d seed=%d" % [runs, max_days, seed])
	print("strategy,runs,avg_roi,median_roi,p25_final_cash,p50_final_cash,p75_final_cash,bankrupt_rate,avg_days,fish_king_rate")

	var strategy_summaries := {}
	var strategies := BalanceRulesScript.dict_value(simulation_rules, "strategies")
	for strategy_name in strategies.keys():
		var summary := _simulate_strategy(str(strategy_name), BalanceRulesScript.dict_value(strategies, str(strategy_name)), runs, max_days, seed)
		strategy_summaries[str(strategy_name)] = summary
		print("%s,%d,%.3f,%.3f,%d,%d,%d,%.3f,%.2f,%.3f" % [
			strategy_name,
			runs,
			float(summary.get("avg_roi", 0.0)),
			float(summary.get("median_roi", 0.0)),
			int(summary.get("p25_final_cash", 0)),
			int(summary.get("p50_final_cash", 0)),
			int(summary.get("p75_final_cash", 0)),
			float(summary.get("bankrupt_rate", 0.0)),
			float(summary.get("avg_days", 0.0)),
			float(summary.get("fish_king_rate", 0.0))
		])

	print("")
	print("STRATEGY_ECONOMY")
	print("strategy,rounds,avg_contract_cost,avg_work_cost,avg_inspection_cost,avg_fish_income,avg_transfer_income,avg_one_net_income,avg_round_net,median_round_roi,profitable_round_rate,transfer_round_rate,one_net_round_rate")
	for strategy_name in strategies.keys():
		var summary := Dictionary(strategy_summaries.get(str(strategy_name), {}))
		print("%s,%d,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.0f,%.3f,%.3f,%.3f,%.3f" % [
			strategy_name,
			int(summary.get("rounds", 0)),
			float(summary.get("avg_contract_cost", 0.0)),
			float(summary.get("avg_work_cost", 0.0)),
			float(summary.get("avg_inspection_cost", 0.0)),
			float(summary.get("avg_fish_income", 0.0)),
			float(summary.get("avg_transfer_income", 0.0)),
			float(summary.get("avg_one_net_income", 0.0)),
			float(summary.get("avg_round_net", 0.0)),
			float(summary.get("median_round_roi", 0.0)),
			float(summary.get("profitable_round_rate", 0.0)),
			float(summary.get("transfer_round_rate", 0.0)),
			float(summary.get("one_net_round_rate", 0.0))
		])

	print("")
	print("POND_TYPE_GROSS_ROI")
	print("pond_type,samples,min_roi,p25_roi,median_roi,p75_roi,max_roi,target_min,target_max,out_of_range_rate")
	var pond_type_summary := _simulate_pond_type_gross_roi(runs, seed)
	for pond_type in pond_type_summary.keys():
		var summary := Dictionary(pond_type_summary[pond_type])
		print("%s,%d,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f" % [
			pond_type,
			int(summary.get("samples", 0)),
			float(summary.get("min_roi", 0.0)),
			float(summary.get("p25_roi", 0.0)),
			float(summary.get("median_roi", 0.0)),
			float(summary.get("p75_roi", 0.0)),
			float(summary.get("max_roi", 0.0)),
			float(summary.get("target_min", 0.0)),
			float(summary.get("target_max", 0.0)),
			float(summary.get("out_of_range_rate", 0.0))
		])

	quit(0)

func _simulate_strategy(strategy_name: String, strategy: Dictionary, runs: int, max_days: int, seed: int) -> Dictionary:
	var game_balance: Dictionary = DataLoaderScript.load_json(DataLoaderScript.GAME_BALANCE_PATH, {})
	var initial_cash := int(game_balance.get("initial_cash", 10000))
	var rois: Array[float] = []
	var final_cash_values: Array[int] = []
	var survived_days_values: Array[int] = []
	var bankrupt_count := 0
	var fish_king_runs := 0
	var round_count := 0
	var profitable_round_count := 0
	var transfer_round_count := 0
	var one_net_round_count := 0
	var contract_cost_total := 0
	var work_cost_total := 0
	var inspection_cost_total := 0
	var fish_income_total := 0
	var transfer_income_total := 0
	var one_net_income_total := 0
	var round_net_total := 0
	var round_rois: Array[float] = []

	for run_index in range(runs):
		var result := _simulate_run(strategy_name, strategy, max_days, seed + run_index * 7919)
		var final_cash := int(result.get("final_cash", initial_cash))
		var survived_days := int(result.get("survived_days", 0))
		final_cash_values.append(final_cash)
		survived_days_values.append(survived_days)
		rois.append((float(final_cash) - float(initial_cash)) / maxf(float(initial_cash), 1.0))
		if survived_days < max_days:
			bankrupt_count += 1
		if bool(result.get("had_fish_king", false)):
			fish_king_runs += 1
		round_count += int(result.get("round_count", 0))
		profitable_round_count += int(result.get("profitable_round_count", 0))
		transfer_round_count += int(result.get("transfer_round_count", 0))
		one_net_round_count += int(result.get("one_net_round_count", 0))
		contract_cost_total += int(result.get("contract_cost_total", 0))
		work_cost_total += int(result.get("work_cost_total", 0))
		inspection_cost_total += int(result.get("inspection_cost_total", 0))
		fish_income_total += int(result.get("fish_income_total", 0))
		transfer_income_total += int(result.get("transfer_income_total", 0))
		one_net_income_total += int(result.get("one_net_income_total", 0))
		round_net_total += int(result.get("round_net_total", 0))
		for round_roi in Array(result.get("round_rois", [])):
			round_rois.append(float(round_roi))

	rois.sort()
	final_cash_values.sort()
	round_rois.sort()
	var safe_round_count := maxf(float(round_count), 1.0)
	return {
		"avg_roi": _average_float(rois),
		"median_roi": _percentile_float(rois, 0.5),
		"p25_final_cash": _percentile_int(final_cash_values, 0.25),
		"p50_final_cash": _percentile_int(final_cash_values, 0.5),
		"p75_final_cash": _percentile_int(final_cash_values, 0.75),
		"bankrupt_rate": float(bankrupt_count) / maxf(float(runs), 1.0),
		"avg_days": _average_int(survived_days_values),
		"fish_king_rate": float(fish_king_runs) / maxf(float(runs), 1.0),
		"rounds": round_count,
		"avg_contract_cost": float(contract_cost_total) / safe_round_count,
		"avg_work_cost": float(work_cost_total) / safe_round_count,
		"avg_inspection_cost": float(inspection_cost_total) / safe_round_count,
		"avg_fish_income": float(fish_income_total) / safe_round_count,
		"avg_transfer_income": float(transfer_income_total) / safe_round_count,
		"avg_one_net_income": float(one_net_income_total) / safe_round_count,
		"avg_round_net": float(round_net_total) / safe_round_count,
		"median_round_roi": _percentile_float(round_rois, 0.5),
		"profitable_round_rate": float(profitable_round_count) / safe_round_count,
		"transfer_round_rate": float(transfer_round_count) / safe_round_count,
		"one_net_round_rate": float(one_net_round_count) / safe_round_count
	}

func _simulate_run(strategy_name: String, strategy: Dictionary, max_days: int, seed: int) -> Dictionary:
	var state := GameStateScript.new()
	var had_fish_king := false
	var survived_days := 0
	var round_count := 0
	var profitable_round_count := 0
	var transfer_round_count := 0
	var one_net_round_count := 0
	var contract_cost_total := 0
	var work_cost_total := 0
	var inspection_cost_total := 0
	var fish_income_total := 0
	var transfer_income_total := 0
	var one_net_income_total := 0
	var round_net_total := 0
	var round_rois: Array[float] = []

	for day in range(1, max_days + 1):
		var generator := PondGeneratorScript.new(seed + day * 101)
		var resolver := ActionResolverScript.new(seed + day * 313)
		var ponds := generator.generate_daily_ponds(day, state.cash)
		var cash_before_round := state.cash
		var inspection_cost := BalanceRulesScript.integer(strategy, "inspection_cost", 0)
		if inspection_cost > 0 and not state.pay_inspection_cost(inspection_cost):
			break

		var pond := _select_pond(strategy, ponds, state, seed + day * 577)
		if pond.is_empty() or not state.contract_pond(pond):
			break

		_play_round(strategy, state, resolver)
		had_fish_king = had_fish_king or _state_has_fish_king(state)
		var quote_price := int(pond.get("quote_price", 0))
		var round_net := state.cash - cash_before_round
		round_count += 1
		contract_cost_total += quote_price
		work_cost_total += state.work_cost
		inspection_cost_total += state.inspection_cost_total
		fish_income_total += state.fish_income
		transfer_income_total += state.transfer_income
		one_net_income_total += state.one_net_income
		round_net_total += round_net
		if round_net > 0:
			profitable_round_count += 1
		if state.transfer_income > 0:
			transfer_round_count += 1
		if state.one_net_income > 0:
			one_net_round_count += 1
		round_rois.append(float(round_net) / maxf(float(quote_price), 1.0))
		survived_days = day
		state.reset_round()

	return {
		"strategy": strategy_name,
		"final_cash": state.cash,
		"survived_days": survived_days,
		"had_fish_king": had_fish_king,
		"round_count": round_count,
		"profitable_round_count": profitable_round_count,
		"transfer_round_count": transfer_round_count,
		"one_net_round_count": one_net_round_count,
		"contract_cost_total": contract_cost_total,
		"work_cost_total": work_cost_total,
		"inspection_cost_total": inspection_cost_total,
		"fish_income_total": fish_income_total,
		"transfer_income_total": transfer_income_total,
		"one_net_income_total": one_net_income_total,
		"round_net_total": round_net_total,
		"round_rois": round_rois
	}

func _select_pond(strategy: Dictionary, ponds: Array, state, seed: int) -> Dictionary:
	var contractable: Array[Dictionary] = []
	for pond in ponds:
		if state.can_contract_pond(pond):
			contractable.append(pond)
	if contractable.is_empty():
		return {}

	var selection := str(strategy.get("selection", "random"))
	match selection:
		"lowest_quote":
			contractable.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("quote_price", 0)) < int(b.get("quote_price", 0)))
			return contractable.front()
		"best_hidden_value_ratio_with_noise":
			var local_rng := RandomNumberGenerator.new()
			local_rng.seed = seed
			var best_pond: Dictionary = contractable.front()
			var best_score := -INF
			for pond in contractable:
				var noise := BalanceRulesScript.random_float_range(local_rng, strategy, "selection_noise_min", "selection_noise_max", 0.82, 1.18)
				var score := float(pond.get("hidden_value", 0)) * noise / maxf(float(pond.get("quote_price", 1)), 1.0)
				if score > best_score:
					best_score = score
					best_pond = pond
			return best_pond
		_:
			var local_rng := RandomNumberGenerator.new()
			local_rng.seed = seed
			return contractable[local_rng.randi_range(0, contractable.size() - 1)]

func _play_round(strategy: Dictionary, state, resolver) -> void:
	var plans := Array(strategy.get("plans", ["standard", "full"]))
	var accept_transfer_quality_below := float(strategy.get("accept_transfer_quality_below", -999.0))
	var accept_one_net := bool(strategy.get("accept_one_net", false))

	for plan_variant in plans:
		var plan_id := str(plan_variant)
		var cost: int = state.get_work_cost(plan_id)
		if not state.can_pay(cost):
			state.apply_abandon()
			return
		var result: Dictionary = resolver.generate_harvest_result(state.current_pond, plan_id, cost)
		if not state.apply_harvest(result):
			state.apply_abandon()
			return
		if bool(result.get("is_final", false)):
			return

		var opportunities: Dictionary = resolver.generate_disposal_opportunities(state.current_pond, result)
		var quality := float(result.get("quality", 0.0))
		var transfer_offer := Dictionary(opportunities.get("transfer_offer", {}))
		if not transfer_offer.is_empty() and quality <= accept_transfer_quality_below:
			state.apply_transfer(int(transfer_offer.get("income", 0)))
			return

		var one_net_offer := Dictionary(opportunities.get("one_net_offer", {}))
		if accept_one_net and not one_net_offer.is_empty():
			state.apply_one_net(int(one_net_offer.get("income", 0)), str(one_net_offer.get("text", "")))

	if not state.drained and state.transfer_income <= 0:
		state.apply_abandon()

func _state_has_fish_king(state) -> bool:
	for item in state.catch_details:
		if str(item.get("id", "")) == "fish_king" and int(item.get("weight_jin", 0)) > 0:
			return true
	return false

func _simulate_pond_type_gross_roi(runs: int, seed: int) -> Dictionary:
	var game_balance: Dictionary = DataLoaderScript.load_json(DataLoaderScript.GAME_BALANCE_PATH, {})
	var initial_cash := int(game_balance.get("initial_cash", 10000))
	var by_type := {}
	var target_rules := BalanceRulesScript.dict_value(BalanceRulesScript.section(rules, "pond_generation"), "pond_type_roi_targets")

	for run_index in range(runs):
		var generator := PondGeneratorScript.new(seed + run_index * 1543)
		var ponds := generator.generate_daily_ponds(1, initial_cash)
		for pond in ponds:
			var pond_type := str(pond.get("pond_type", "unknown"))
			if not by_type.has(pond_type):
				by_type[pond_type] = []
			var quote_price := int(pond.get("quote_price", 0))
			var fish_value := int(pond.get("total_fish_value", pond.get("hidden_value", 0)))
			if quote_price > 0:
				by_type[pond_type].append((float(fish_value) - float(quote_price)) / float(quote_price))

	var summaries := {}
	for pond_type in by_type.keys():
		var values: Array = Array(by_type[pond_type])
		values.sort()
		var type_targets := BalanceRulesScript.dict_value(target_rules, str(pond_type))
		var target_min := BalanceRulesScript.number(type_targets, "min_roi", -1.0)
		var target_max := BalanceRulesScript.number(type_targets, "max_roi", 1.0)
		var out_of_range_count := 0
		for value in values:
			var roi := float(value)
			if roi < target_min or roi > target_max:
				out_of_range_count += 1
		summaries[pond_type] = {
			"samples": values.size(),
			"min_roi": _first_float(values),
			"p25_roi": _percentile_untyped_float(values, 0.25),
			"median_roi": _percentile_untyped_float(values, 0.5),
			"p75_roi": _percentile_untyped_float(values, 0.75),
			"max_roi": _last_float(values),
			"target_min": target_min,
			"target_max": target_max,
			"out_of_range_rate": float(out_of_range_count) / maxf(float(values.size()), 1.0)
		}
	return summaries

func _average_float(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += value
	return total / float(values.size())

func _average_int(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0
	for value in values:
		total += value
	return float(total) / float(values.size())

func _percentile_float(values: Array[float], percentile: float) -> float:
	if values.is_empty():
		return 0.0
	var index := clampi(int(round(float(values.size() - 1) * percentile)), 0, values.size() - 1)
	return values[index]

func _percentile_int(values: Array[int], percentile: float) -> int:
	if values.is_empty():
		return 0
	var index := clampi(int(round(float(values.size() - 1) * percentile)), 0, values.size() - 1)
	return values[index]

func _percentile_untyped_float(values: Array, percentile: float) -> float:
	if values.is_empty():
		return 0.0
	var index := clampi(int(round(float(values.size() - 1) * percentile)), 0, values.size() - 1)
	return float(values[index])

func _first_float(values: Array) -> float:
	if values.is_empty():
		return 0.0
	return float(values.front())

func _last_float(values: Array) -> float:
	if values.is_empty():
		return 0.0
	return float(values.back())

func _get_arg_int(name: String, fallback: int) -> int:
	var prefix := "--%s=" % name
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with(prefix):
			return int(str(arg).trim_prefix(prefix))
	return fallback
