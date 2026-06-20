extends RefCounted
class_name ActionResolver

const FishingSimulatorScript := preload("res://scripts/fishing_simulator.gd")
const BalanceRulesScript := preload("res://scripts/balance_rules.gd")

var rng := RandomNumberGenerator.new()
var fishing_simulator
var rules: Dictionary = {}
var market_rules: Dictionary = {}

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
		fishing_simulator = FishingSimulatorScript.new()
	else:
		rng.seed = seed_value
		fishing_simulator = FishingSimulatorScript.new(seed_value + 137)
	rules = BalanceRulesScript.load_rules()
	market_rules = BalanceRulesScript.section(rules, "market")

func generate_transfer_offer(pond: Dictionary, harvest_result: Dictionary = {}) -> Dictionary:
	var transfer_rules := BalanceRulesScript.dict_value(market_rules, "transfer")
	var quote_price := int(pond.get("quote_price", 0))
	var estimated_value := int(pond.get("estimated_transfer_value", quote_price))
	var hidden_value := int(pond.get("hidden_value", quote_price))
	var value_factor := clampf(float(hidden_value) / maxf(float(quote_price), 1.0), BalanceRulesScript.number(transfer_rules, "value_factor_min", 0.55), BalanceRulesScript.number(transfer_rules, "value_factor_max", 1.65))
	var rounding := BalanceRulesScript.integer(transfer_rules, "rounding", 100)
	var market_noise := BalanceRulesScript.random_float_range(rng, transfer_rules, "estimate_noise_min", "estimate_noise_max", 0.96, 1.04)
	var offer := int(round(float(estimated_value) * market_noise / float(rounding))) * rounding
	var min_income := BalanceRulesScript.integer(transfer_rules, "min_income", 300)
	var work_cost := int(harvest_result.get("work_cost", 0))
	var recovery_floor := int(round((float(quote_price) * BalanceRulesScript.number(transfer_rules, "min_quote_ratio", 0.0) + float(work_cost) * BalanceRulesScript.number(transfer_rules, "work_cost_recovery", 0.0)) / float(rounding))) * rounding
	var final_offer := maxi(min_income, maxi(recovery_floor, offer))

	return {
		"income": final_offer,
		"text": "现在塘口估值约 %d 元，有人愿意按 %d 元接手。\n这个价只看外面人根据鱼情估出来的行情，不等于塘里的真实剩货。要不要脱手？" % [estimated_value, final_offer],
		"estimated_value": estimated_value,
		"value_factor": value_factor
	}

func generate_one_net_offer(pond: Dictionary, harvest_result: Dictionary = {}) -> Dictionary:
	var one_net_rules := BalanceRulesScript.dict_value(market_rules, "one_net")
	var quote_price := int(pond.get("quote_price", 0))
	var estimated_value := int(pond.get("estimated_transfer_value", quote_price))
	var rounding := BalanceRulesScript.integer(one_net_rules, "rounding", 100)
	var ratio := BalanceRulesScript.number(one_net_rules, "estimated_value_ratio", 0.25)
	var income := int(round(float(estimated_value) * ratio / float(rounding))) * rounding
	var result_text := "买家按当前塘口估值的四分之一买一网。等这一网开出来，塘口估值会跟着涨跌。"
	var min_income := BalanceRulesScript.integer(one_net_rules, "min_income", 500)

	return {
		"income": maxi(min_income, income),
		"text": "有人出 %d 元买下一网，只买这一网，不接整口塘。\n%s" % [maxi(min_income, income), result_text],
		"result_text": result_text,
		"estimated_value": estimated_value
	}

func generate_harvest_result(pond: Dictionary, plan_id: String, work_cost: int) -> Dictionary:
	return fishing_simulator.generate_harvest_result(pond, plan_id, work_cost)

func generate_disposal_opportunities(pond: Dictionary, harvest_result: Dictionary) -> Dictionary:
	var quality := float(harvest_result.get("quality", 0.0))
	var opportunity_rules := BalanceRulesScript.dict_value(market_rules, "opportunities")
	var opportunities := {
		"transfer_offer": {},
		"one_net_offer": {},
		"message": ""
	}

	var transfer_chance := clampf(BalanceRulesScript.number(opportunity_rules, "transfer_base", 0.28) + quality * BalanceRulesScript.number(opportunity_rules, "transfer_quality_weight", 0.2), BalanceRulesScript.number(opportunity_rules, "transfer_min", 0.12), BalanceRulesScript.number(opportunity_rules, "transfer_max", 0.68))
	var one_net_chance := clampf(BalanceRulesScript.number(opportunity_rules, "one_net_base", 0.2) + quality * BalanceRulesScript.number(opportunity_rules, "one_net_quality_weight", 0.35), BalanceRulesScript.number(opportunity_rules, "one_net_min", 0.02), BalanceRulesScript.number(opportunity_rules, "one_net_max", 0.72))
	var bad_quality_threshold := BalanceRulesScript.number(opportunity_rules, "bad_quality_threshold", -0.25)
	if quality < bad_quality_threshold:
		transfer_chance = clampf(transfer_chance + BalanceRulesScript.number(opportunity_rules, "bad_transfer_bonus", 0.24), BalanceRulesScript.number(opportunity_rules, "bad_transfer_min", 0.22), BalanceRulesScript.number(opportunity_rules, "bad_transfer_max", 0.78))
		one_net_chance *= BalanceRulesScript.number(opportunity_rules, "bad_one_net_multiplier", 0.35)

	opportunities["transfer_offer"] = generate_transfer_offer(pond, harvest_result)
	if rng.randf() <= one_net_chance:
		opportunities["one_net_offer"] = generate_one_net_offer(pond, harvest_result)

	var messages: Array[String] = []
	if quality < bad_quality_threshold:
		messages.append("这一网不亮眼，塘口估值被压下来了；你仍然可以按当前价转包。")
	else:
		messages.append("这一网打出鱼情，塘口估值已经更新；你可以继续捞，也可以按当前价转包。")
	if not Dictionary(opportunities["one_net_offer"]).is_empty():
		messages.append("旁边有人想买一网试试水，给你先回点现金。")
	if messages.is_empty():
		messages.append("这一网还没让买家动心。你可以继续下网，也可以抽干收尾。")
	opportunities["message"] = "\n".join(messages)
	return opportunities
