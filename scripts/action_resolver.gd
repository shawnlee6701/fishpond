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
	var hidden_value := int(pond.get("hidden_value", quote_price))
	var value_factor := clampf(float(hidden_value) / maxf(float(quote_price), 1.0), BalanceRulesScript.number(transfer_rules, "value_factor_min", 0.55), BalanceRulesScript.number(transfer_rules, "value_factor_max", 1.65))
	var result_quality := float(harvest_result.get("quality", value_factor + BalanceRulesScript.number(transfer_rules, "default_quality_offset", -1.0)))
	var result_factor := clampf(1.0 + result_quality * BalanceRulesScript.number(transfer_rules, "quality_weight", 0.42), BalanceRulesScript.number(transfer_rules, "result_factor_min", 0.58), BalanceRulesScript.number(transfer_rules, "result_factor_max", 1.35))
	var random_factor := BalanceRulesScript.random_float_range(rng, transfer_rules, "random_min", "random_max", 0.78, 1.22)
	var rounding := BalanceRulesScript.integer(transfer_rules, "rounding", 100)
	var offer := int(round(float(quote_price) * lerpf(BalanceRulesScript.number(transfer_rules, "value_lerp_min", 0.82), BalanceRulesScript.number(transfer_rules, "value_lerp_max", 1.16), value_factor / BalanceRulesScript.number(transfer_rules, "value_factor_max", 1.65)) * result_factor * random_factor / float(rounding))) * rounding
	var min_income := BalanceRulesScript.integer(transfer_rules, "min_income", 300)

	return {
		"income": maxi(min_income, offer),
		"text": "有人开价 %d 元接手这口塘。\n现在转包，后面的鱼和风险都归他；留下来，可能翻本，也可能越捞越重。要不要脱手？" % maxi(min_income, offer)
	}

func generate_one_net_offer(pond: Dictionary, harvest_result: Dictionary = {}) -> Dictionary:
	var one_net_rules := BalanceRulesScript.dict_value(market_rules, "one_net")
	var quote_price := int(pond.get("quote_price", 0))
	var hidden_value := int(pond.get("hidden_value", quote_price))
	var result_quality := float(harvest_result.get("quality", 0.0))
	var heat_factor := clampf(1.0 + result_quality * BalanceRulesScript.number(one_net_rules, "quality_weight", 0.3), BalanceRulesScript.number(one_net_rules, "heat_factor_min", 0.75), BalanceRulesScript.number(one_net_rules, "heat_factor_max", 1.35))
	var rounding := BalanceRulesScript.integer(one_net_rules, "rounding", 100)
	var income := int(round((float(quote_price) * BalanceRulesScript.random_float_range(rng, one_net_rules, "quote_ratio_min", "quote_ratio_max", 0.16, 0.28) + float(hidden_value) * BalanceRulesScript.random_float_range(rng, one_net_rules, "hidden_ratio_min", "hidden_ratio_max", 0.04, 0.09)) * heat_factor / float(rounding))) * rounding
	var result_roll := rng.randf()
	var fish_king_chance := float(pond.get("fish_king_chance", 0.01))
	var big_fish_chance := float(pond.get("big_fish_chance", 0.1))
	var result_text := ""

	if result_roll <= fish_king_chance * BalanceRulesScript.number(one_net_rules, "fish_king_text_weight", 0.18):
		result_text = "小概率让人家碰到鱼王，这笔会很扎心。"
	elif result_roll <= fish_king_chance * BalanceRulesScript.number(one_net_rules, "fish_king_text_weight", 0.18) + big_fish_chance * BalanceRulesScript.number(one_net_rules, "big_fish_text_weight", 0.45):
		result_text = "要是人家这一网起大鱼，你多半会后悔。"
	elif result_roll <= BalanceRulesScript.number(one_net_rules, "normal_text_threshold", 0.62):
		result_text = "大概率就是普通鱼，赚亏看这一口价。"
	else:
		result_text = "也可能只起小鱼，那这钱就收得舒服。"
	var min_income := BalanceRulesScript.integer(one_net_rules, "min_income", 500)

	return {
		"income": maxi(min_income, income),
		"text": "有人出 %d 元买下一网，只买这一网，不接整口塘。\n%s" % [maxi(min_income, income), result_text],
		"result_text": result_text
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

	if rng.randf() <= transfer_chance:
		opportunities["transfer_offer"] = generate_transfer_offer(pond, harvest_result)
	if rng.randf() <= one_net_chance:
		opportunities["one_net_offer"] = generate_one_net_offer(pond, harvest_result)

	var messages: Array[String] = []
	if not Dictionary(opportunities["transfer_offer"]).is_empty():
		if quality < bad_quality_threshold:
			messages.append("这一网不亮眼，有人趁机压价想接手。")
		else:
			messages.append("这一网有动静，塘边有人开始问整塘转包价。")
	if not Dictionary(opportunities["one_net_offer"]).is_empty():
		messages.append("旁边有人想买一网试试水，给你先回点现金。")
	if messages.is_empty():
		messages.append("这一网还没让买家动心。你可以继续下网，也可以抽干收尾。")
	opportunities["message"] = "\n".join(messages)
	return opportunities
