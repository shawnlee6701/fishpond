extends RefCounted
class_name FishingSimulator

const DataLoaderScript := preload("res://scripts/data_loader.gd")
const BalanceRulesScript := preload("res://scripts/balance_rules.gd")

var rng := RandomNumberGenerator.new()
var fish_types: Array = []
var rules: Dictionary = {}
var fishing_rules: Dictionary = {}

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value

	fish_types = DataLoaderScript.load_json(DataLoaderScript.FISH_TYPES_PATH, [])
	rules = BalanceRulesScript.load_rules()
	fishing_rules = BalanceRulesScript.section(rules, "fishing")

func generate_harvest_result(pond: Dictionary, plan_id: String, work_cost: int) -> Dictionary:
	var main_fish_type := _roll_fish_type(pond, plan_id)
	var catch_details := _generate_catch_details(pond, plan_id, main_fish_type)
	var fish_income := _sum_catch_income(catch_details)
	var plan_name := _get_plan_name(plan_id)
	var is_final := plan_id == "drain" or plan_id == "full"
	var fish_name := str(main_fish_type.get("name", "未知鱼获"))
	var description := _build_fish_description(fish_income, work_cost, fish_name)
	var quality := _get_quality_score(str(main_fish_type.get("id", "normal_fish")), fish_income, work_cost)

	return {
		"plan_id": plan_id,
		"plan_name": plan_name,
		"work_cost": work_cost,
		"fish_income": fish_income,
		"catch_details": catch_details,
		"is_final": is_final,
		"quality": quality,
		"fish_result_id": str(main_fish_type.get("id", "normal_fish")),
		"fish_result_name": fish_name,
		"fish_description": description,
		"text": "%s：%s\n%s\n本次卖鱼回款 %d 元。" % [plan_name, description, _format_catch_details(catch_details), fish_income]
	}

func _roll_fish_type(pond: Dictionary, plan_id: String) -> Dictionary:
	if fish_types.is_empty():
		return {
			"id": "normal_fish",
			"name": "普通鱼",
			"min_value": BalanceRulesScript.integer(fishing_rules, "fallback_fish_min_value", 100),
			"max_value": BalanceRulesScript.integer(fishing_rules, "fallback_fish_max_value", 300),
			"display_text": "普通鱼获，今天不算白忙。"
		}

	var difficulty := maxf(float(pond.get("difficulty", 1.0)), BalanceRulesScript.number(fishing_rules, "min_difficulty", 0.2))
	var plan_power := _get_plan_power(plan_id)
	var power_rules := BalanceRulesScript.dict_value(fishing_rules, "result_power")
	var pond_big_bonus := clampf(float(pond.get("big_fish_chance", 0.12)) - BalanceRulesScript.number(power_rules, "big_chance_baseline", 0.12), BalanceRulesScript.number(power_rules, "big_bonus_min", -0.08), BalanceRulesScript.number(power_rules, "big_bonus_max", 0.28))
	var pond_king_bonus := clampf(float(pond.get("fish_king_chance", 0.02)) - BalanceRulesScript.number(power_rules, "king_chance_baseline", 0.02), BalanceRulesScript.number(power_rules, "king_bonus_min", -0.01), BalanceRulesScript.number(power_rules, "king_bonus_max", 0.08))
	var difficulty_penalty := clampf((difficulty - BalanceRulesScript.number(power_rules, "difficulty_baseline", 1.0)) * BalanceRulesScript.number(power_rules, "difficulty_weight", 0.42), BalanceRulesScript.number(power_rules, "difficulty_penalty_min", -0.12), BalanceRulesScript.number(power_rules, "difficulty_penalty_max", 0.35))
	var result_power := plan_power + pond_big_bonus + pond_king_bonus - difficulty_penalty

	var weights := BalanceRulesScript.dict_value(fishing_rules, "base_weights", {
		"small_fish": 42.0,
		"normal_fish": 43.0,
		"big_fish": 13.0,
		"fish_king": 2.0
	})

	if result_power >= 0.0:
		_apply_positive_weight_adjustments(weights, result_power)
	else:
		_apply_negative_weight_adjustments(weights, absf(result_power))

	return _pick_by_weight(weights)

func _pick_by_weight(weights: Dictionary) -> Dictionary:
	var total_weight := 0.0
	for fish_type in fish_types:
		total_weight += float(weights.get(str(fish_type.get("id", "")), 0.0))

	var roll := rng.randf_range(0.0, total_weight)
	var cursor := 0.0
	for fish_type in fish_types:
		cursor += float(weights.get(str(fish_type.get("id", "")), 0.0))
		if roll <= cursor:
			return fish_type

	return fish_types.back()

func _generate_catch_details(pond: Dictionary, plan_id: String, main_fish_type: Dictionary) -> Array[Dictionary]:
	var catch_details: Array[Dictionary] = []
	var main_fish_id := str(main_fish_type.get("id", "normal_fish"))
	var difficulty := maxf(float(pond.get("difficulty", 1.0)), BalanceRulesScript.number(fishing_rules, "min_difficulty", 0.2))
	var plan_scale := _get_plan_catch_scale(plan_id)
	var difficulty_rules := BalanceRulesScript.dict_value(fishing_rules, "difficulty_scale")
	var difficulty_scale := clampf(BalanceRulesScript.number(difficulty_rules, "base", 1.12) - (difficulty - BalanceRulesScript.number(difficulty_rules, "difficulty_baseline", 1.0)) * BalanceRulesScript.number(difficulty_rules, "difficulty_weight", 0.2), BalanceRulesScript.number(difficulty_rules, "min", 0.62), BalanceRulesScript.number(difficulty_rules, "max", 1.22))
	var catch_scale := plan_scale * difficulty_scale

	for fish_type in fish_types:
		var fish_id := str(fish_type.get("id", ""))
		var weight := _roll_weight_jin(fish_id, main_fish_id, catch_scale)
		var unit_price := rng.randi_range(int(fish_type.get("min_value", 0)), int(fish_type.get("max_value", 0)))
		var integrity := 0
		var price_note := ""
		if fish_id == "fish_king" and weight > 0:
			var integrity_rules := BalanceRulesScript.dict_value(fishing_rules, "fish_king_integrity")
			integrity = BalanceRulesScript.random_int_range(rng, integrity_rules, "min", "max", 80, 100)
			if integrity < BalanceRulesScript.integer(integrity_rules, "premium_threshold", 90):
				unit_price = _get_random_unit_price_by_id("big_fish")
				price_note = "鱼王受伤严重，估计养不活了，只能按大鱼价格算"
			else:
				price_note = ""
		var income := weight * unit_price
		var catch_item := {
			"id": fish_id,
			"name": str(fish_type.get("name", fish_id)),
			"weight_jin": weight,
			"unit_price": unit_price,
			"income": income
		}
		if integrity > 0:
			catch_item["integrity"] = integrity
			catch_item["price_note"] = price_note
		catch_details.append(catch_item)

	return catch_details

func _roll_weight_jin(fish_id: String, main_fish_id: String, catch_scale: float) -> int:
	var weight := 0.0
	match fish_id:
		"small_fish":
			var small_rules := _get_weight_rules("small_fish")
			weight = BalanceRulesScript.random_float_range(rng, small_rules, "min", "max", 6.0, 22.0) * catch_scale
			if main_fish_id == "small_fish":
				weight *= BalanceRulesScript.random_float_range(rng, small_rules, "main_multiplier_min", "main_multiplier_max", 0.8, 1.25)
		"normal_fish":
			var normal_rules := _get_weight_rules("normal_fish")
			if main_fish_id in ["normal_fish", "big_fish", "fish_king"] or rng.randf() <= BalanceRulesScript.number(normal_rules, "extra_chance", 0.45):
				weight = BalanceRulesScript.random_float_range(rng, normal_rules, "min", "max", 5.0, 18.0) * catch_scale
		"big_fish":
			var big_rules := _get_weight_rules("big_fish")
			if main_fish_id in ["big_fish", "fish_king"]:
				weight = BalanceRulesScript.random_float_range(rng, big_rules, "min", "max", 10.0, 32.0) * catch_scale
			elif rng.randf() <= BalanceRulesScript.number(big_rules, "extra_chance", 0.08):
				weight = BalanceRulesScript.random_float_range(rng, big_rules, "extra_min", "extra_max", 10.0, 16.0) * catch_scale
		"fish_king":
			var king_rules := _get_weight_rules("fish_king")
			if main_fish_id == "fish_king":
				weight = BalanceRulesScript.random_int_range(rng, king_rules, "min", "max", 50, 150)
		_:
			weight = 0.0

	return _snap_weight_to_unit(weight, _get_weight_unit(fish_id))

func _get_weight_unit(fish_id: String) -> int:
	match fish_id:
		"small_fish", "normal_fish", "big_fish", "fish_king":
			return BalanceRulesScript.integer(_get_weight_rules(fish_id), "unit", 1)
		_:
			return 1

func _get_random_unit_price_by_id(fish_id: String) -> int:
	for fish_type in fish_types:
		if str(fish_type.get("id", "")) == fish_id:
			return rng.randi_range(int(fish_type.get("min_value", 0)), int(fish_type.get("max_value", 0)))
	return 0

func _snap_weight_to_unit(weight: float, unit: int) -> int:
	if weight <= 0.0:
		return 0

	return maxi(unit, int(roundf(weight / float(unit))) * unit)

func _sum_catch_income(catch_details: Array[Dictionary]) -> int:
	var total := 0
	for item in catch_details:
		total += int(item.get("income", 0))
	return total

func _format_catch_details(catch_details: Array[Dictionary]) -> String:
	var lines: Array[String] = []
	for item in catch_details:
		var line := "%s：%d 斤，%d 元/斤，合计 %d 元" % [
			str(item.get("name", "")),
			int(item.get("weight_jin", 0)),
			int(item.get("unit_price", 0)),
			int(item.get("income", 0))
		]
		if str(item.get("id", "")) == "fish_king" and item.has("integrity"):
			line = "%s，完整度 %d%%" % [line, int(item.get("integrity", 0))]
			if not str(item.get("price_note", "")).is_empty():
				line = "%s（%s）" % [line, str(item.get("price_note", ""))]
		lines.append(line)
	return "\n".join(lines)

func _get_plan_power(plan_id: String) -> float:
	var plan_rules := BalanceRulesScript.dict_value(fishing_rules, "plan_power")
	return float(plan_rules.get(plan_id, plan_rules.get("default", 0.08)))

func _get_plan_catch_scale(plan_id: String) -> float:
	var plan_rules := BalanceRulesScript.dict_value(fishing_rules, "plan_catch_scale")
	return float(plan_rules.get(plan_id, plan_rules.get("default", 1.0)))

func _get_plan_name(plan_id: String) -> String:
	match plan_id:
		"low":
			return "省着下网"
		"standard":
			return "正常作业"
		"full", "drain":
			return "抽干收尾"
		_:
			return "正常作业"

func _build_fish_description(fish_income: int, work_cost: int, fish_name: String) -> String:
	var harvest_profit := fish_income - work_cost
	var description_rules := BalanceRulesScript.dict_value(fishing_rules, "description_thresholds")
	if fish_income <= 0:
		return "这一网几乎空了，作业费基本压在身上。"
	if harvest_profit < int(float(work_cost) * BalanceRulesScript.number(description_rules, "severe_loss_ratio", -0.55)):
		return "鱼获明显不够，卖鱼钱离作业成本差得远。"
	if harvest_profit < 0:
		return "%s上岸，但卖鱼钱还没盖住这次作业成本。" % fish_name
	if harvest_profit < int(float(work_cost) * BalanceRulesScript.number(description_rules, "thin_profit_ratio", 0.35)):
		return "%s上岸，刚刚盖住作业成本，利润不厚。" % fish_name
	return "%s上岸，这一网卖鱼钱明显跑赢作业成本。" % fish_name

func _get_quality_score(fish_result_id: String, income: int, work_cost: int) -> float:
	var profit_ratio := float(income - work_cost) / maxf(float(work_cost), 1.0)
	var quality_rules := BalanceRulesScript.dict_value(BalanceRulesScript.dict_value(fishing_rules, "quality_scores"), fish_result_id, BalanceRulesScript.dict_value(BalanceRulesScript.dict_value(fishing_rules, "quality_scores"), "default"))
	return clampf(BalanceRulesScript.number(quality_rules, "base", 0.0) + profit_ratio * BalanceRulesScript.number(quality_rules, "profit_weight", 0.0), BalanceRulesScript.number(quality_rules, "min", 0.0), BalanceRulesScript.number(quality_rules, "max", 0.0))

func _apply_positive_weight_adjustments(weights: Dictionary, result_power: float) -> void:
	var adjustments := BalanceRulesScript.dict_value(fishing_rules, "positive_weight_adjustments")
	for fish_id in adjustments.keys():
		var rule := BalanceRulesScript.dict_value(adjustments, str(fish_id))
		var next_weight := float(weights.get(fish_id, 0.0)) + result_power * BalanceRulesScript.number(rule, "delta", 0.0)
		if rule.has("min"):
			next_weight = maxf(BalanceRulesScript.number(rule, "min", next_weight), next_weight)
		if rule.has("max"):
			next_weight = minf(BalanceRulesScript.number(rule, "max", next_weight), next_weight)
		weights[fish_id] = next_weight

func _apply_negative_weight_adjustments(weights: Dictionary, bad_power: float) -> void:
	var adjustments := BalanceRulesScript.dict_value(fishing_rules, "negative_weight_adjustments")
	for fish_id in adjustments.keys():
		var rule := BalanceRulesScript.dict_value(adjustments, str(fish_id))
		var next_weight := float(weights.get(fish_id, 0.0)) + bad_power * BalanceRulesScript.number(rule, "delta", 0.0)
		if rule.has("min"):
			next_weight = maxf(BalanceRulesScript.number(rule, "min", next_weight), next_weight)
		if rule.has("max"):
			next_weight = minf(BalanceRulesScript.number(rule, "max", next_weight), next_weight)
		weights[fish_id] = next_weight

func _get_weight_rules(fish_id: String) -> Dictionary:
	return BalanceRulesScript.dict_value(BalanceRulesScript.dict_value(fishing_rules, "weights"), fish_id)
