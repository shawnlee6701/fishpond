extends RefCounted
class_name ActionResolver

const FishingSimulatorScript := preload("res://scripts/fishing_simulator.gd")

var rng := RandomNumberGenerator.new()
var fishing_simulator

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
		fishing_simulator = FishingSimulatorScript.new()
	else:
		rng.seed = seed_value
		fishing_simulator = FishingSimulatorScript.new(seed_value + 137)

func generate_transfer_offer(pond: Dictionary, harvest_result: Dictionary = {}) -> Dictionary:
	var quote_price := int(pond.get("quote_price", 0))
	var hidden_value := int(pond.get("hidden_value", quote_price))
	var value_factor := clampf(float(hidden_value) / maxf(float(quote_price), 1.0), 0.55, 1.65)
	var result_quality := float(harvest_result.get("quality", value_factor - 1.0))
	var result_factor := clampf(1.0 + result_quality * 0.42, 0.58, 1.35)
	var random_factor := rng.randf_range(0.78, 1.22)
	var offer := int(round(float(quote_price) * lerpf(0.82, 1.16, value_factor / 1.65) * result_factor * random_factor / 100.0)) * 100

	return {
		"income": maxi(300, offer),
		"text": "有人愿意出 %d 元接手这口塘，是否转包？" % maxi(300, offer)
	}

func generate_one_net_offer(pond: Dictionary, harvest_result: Dictionary = {}) -> Dictionary:
	var quote_price := int(pond.get("quote_price", 0))
	var hidden_value := int(pond.get("hidden_value", quote_price))
	var result_quality := float(harvest_result.get("quality", 0.0))
	var heat_factor := clampf(1.0 + result_quality * 0.3, 0.75, 1.35)
	var income := int(round((float(quote_price) * rng.randf_range(0.16, 0.28) + float(hidden_value) * rng.randf_range(0.04, 0.09)) * heat_factor / 100.0)) * 100
	var result_roll := rng.randf()
	var fish_king_chance := float(pond.get("fish_king_chance", 0.01))
	var big_fish_chance := float(pond.get("big_fish_chance", 0.1))
	var result_text := ""

	if result_roll <= fish_king_chance * 0.18:
		result_text = "极低概率对方捞到鱼王，你亏麻了"
	elif result_roll <= fish_king_chance * 0.18 + big_fish_chance * 0.45:
		result_text = "对方捞到大鱼，你有点后悔"
	elif result_roll <= 0.62:
		result_text = "对方捞到普通鱼"
	else:
		result_text = "对方只捞到小鱼，你赚了"

	return {
		"income": maxi(500, income),
		"text": "有人想花 %d 元买下一网。\n%s" % [maxi(500, income), result_text],
		"result_text": result_text
	}

func generate_harvest_result(pond: Dictionary, plan_id: String, work_cost: int) -> Dictionary:
	return fishing_simulator.generate_harvest_result(pond, plan_id, work_cost)

func generate_disposal_opportunities(pond: Dictionary, harvest_result: Dictionary) -> Dictionary:
	var quality := float(harvest_result.get("quality", 0.0))
	var opportunities := {
		"transfer_offer": {},
		"one_net_offer": {},
		"message": ""
	}

	var transfer_chance := clampf(0.28 + quality * 0.2, 0.12, 0.68)
	var one_net_chance := clampf(0.2 + quality * 0.35, 0.02, 0.72)
	if quality < -0.25:
		transfer_chance = clampf(transfer_chance + 0.24, 0.22, 0.78)
		one_net_chance *= 0.35

	if rng.randf() <= transfer_chance:
		opportunities["transfer_offer"] = generate_transfer_offer(pond, harvest_result)
	if rng.randf() <= one_net_chance:
		opportunities["one_net_offer"] = generate_one_net_offer(pond, harvest_result)

	var messages: Array[String] = []
	if not Dictionary(opportunities["transfer_offer"]).is_empty():
		if quality < -0.25:
			messages.append("鱼获不太好，有人压价想接手。")
		else:
			messages.append("这网动静不小，有人开始问转包价。")
	if not Dictionary(opportunities["one_net_offer"]).is_empty():
		messages.append("旁边有人想买一网试试水。")
	if messages.is_empty():
		messages.append("这一网还没激起买家的兴趣，你可以继续捞或选择全部抽干。")
	opportunities["message"] = "\n".join(messages)
	return opportunities
