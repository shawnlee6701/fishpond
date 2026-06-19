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

	var strategies := BalanceRulesScript.dict_value(simulation_rules, "strategies")
	for strategy_name in strategies.keys():
		var summary := _simulate_strategy(str(strategy_name), BalanceRulesScript.dict_value(strategies, str(strategy_name)), runs, max_days, seed)
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

	quit(0)

func _simulate_strategy(strategy_name: String, strategy: Dictionary, runs: int, max_days: int, seed: int) -> Dictionary:
	var game_balance: Dictionary = DataLoaderScript.load_json(DataLoaderScript.GAME_BALANCE_PATH, {})
	var initial_cash := int(game_balance.get("initial_cash", 10000))
	var rois: Array[float] = []
	var final_cash_values: Array[int] = []
	var survived_days_values: Array[int] = []
	var bankrupt_count := 0
	var fish_king_runs := 0

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

	rois.sort()
	final_cash_values.sort()
	return {
		"avg_roi": _average_float(rois),
		"median_roi": _percentile_float(rois, 0.5),
		"p25_final_cash": _percentile_int(final_cash_values, 0.25),
		"p50_final_cash": _percentile_int(final_cash_values, 0.5),
		"p75_final_cash": _percentile_int(final_cash_values, 0.75),
		"bankrupt_rate": float(bankrupt_count) / maxf(float(runs), 1.0),
		"avg_days": _average_int(survived_days_values),
		"fish_king_rate": float(fish_king_runs) / maxf(float(runs), 1.0)
	}

func _simulate_run(strategy_name: String, strategy: Dictionary, max_days: int, seed: int) -> Dictionary:
	var state := GameStateScript.new()
	var had_fish_king := false
	var survived_days := 0

	for day in range(1, max_days + 1):
		var generator := PondGeneratorScript.new(seed + day * 101)
		var resolver := ActionResolverScript.new(seed + day * 313)
		var ponds := generator.generate_daily_ponds(day, state.cash)
		var inspection_cost := BalanceRulesScript.integer(strategy, "inspection_cost", 0)
		if inspection_cost > 0 and not state.pay_inspection_cost(inspection_cost):
			break

		var pond := _select_pond(strategy, ponds, state, seed + day * 577)
		if pond.is_empty() or not state.contract_pond(pond):
			break

		_play_round(strategy, state, resolver)
		had_fish_king = had_fish_king or _state_has_fish_king(state)
		survived_days = day
		state.reset_round()

	return {
		"strategy": strategy_name,
		"final_cash": state.cash,
		"survived_days": survived_days,
		"had_fish_king": had_fish_king
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

func _get_arg_int(name: String, fallback: int) -> int:
	var prefix := "--%s=" % name
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with(prefix):
			return int(str(arg).trim_prefix(prefix))
	return fallback
