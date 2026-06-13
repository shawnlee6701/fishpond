extends RefCounted
class_name PondGenerator

const DataLoaderScript := preload("res://scripts/data_loader.gd")

const WATER_STATES := ["清亮微绿", "偏浑发黄", "肥水泛绿", "水面起花", "深水偏暗"]
const RUMORS := [
	"老板说去年有人钓到过大货",
	"塘边常有人夜里听见炸水",
	"附近钓友说这里鱼口很滑",
	"上一手承包商急着转出去",
	"村里老师傅说底下有老鱼"
]
const RISK_TAGS := ["低风险", "鱼情不明", "可能偏贵", "大鱼难捞", "高波动"]
const AREA_LABELS := ["小塘", "中塘", "大塘", "宽水面"]

var rng := RandomNumberGenerator.new()
var pond_types: Array = []

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value

	pond_types = DataLoaderScript.load_json(DataLoaderScript.POND_TYPES_PATH, [])

func generate_daily_ponds(day: int) -> Array[Dictionary]:
	var ponds: Array[Dictionary] = []
	for index in range(3):
		ponds.append(_generate_pond(day, index))

	return ponds

func _generate_pond(day: int, index: int) -> Dictionary:
	var pond_type: Dictionary = pond_types[index % pond_types.size()]
	var type_id := str(pond_type.get("id", "unknown"))
	var type_name := str(pond_type.get("name", "未知鱼塘"))
	var age_years := _generate_age_years(type_id)
	var age_label := get_age_label(age_years)
	var age_factor := clampf(float(age_years) / 10.0, 0.0, 1.5)
	var difficulty := _round_to_2(float(pond_type.get("difficulty_modifier", 1.0)) + age_factor * 0.25 + rng.randf_range(-0.08, 0.08))
	var big_fish_chance := _round_to_2(clampf(0.12 + age_factor * 0.16 + float(pond_type.get("big_fish_modifier", 1.0)) * 0.08, 0.05, 0.65))
	var fish_king_chance := _round_to_2(clampf(0.01 + age_factor * 0.025 + float(pond_type.get("fish_king_modifier", 1.0)) * 0.018, 0.01, 0.22))
	var hidden_value := _calculate_hidden_value(type_id, age_years, big_fish_chance, fish_king_chance)
	var quote_price := _calculate_quote_price(hidden_value, difficulty)

	return {
		"id": "day_%d_pond_%d" % [day, index + 1],
		"name": "%s%d号塘" % [type_name, index + 1],
		"pond_type": type_id,
		"pond_type_name": type_name,
		"age_years": age_years,
		"age_label": age_label,
		"quote_price": quote_price,
		"area_label": AREA_LABELS[rng.randi_range(0, AREA_LABELS.size() - 1)],
		"water_state": WATER_STATES[rng.randi_range(0, WATER_STATES.size() - 1)],
		"rumor": RUMORS[rng.randi_range(0, RUMORS.size() - 1)],
		"risk_tag": _pick_risk_tag(type_id, difficulty),
		"hidden_value": hidden_value,
		"big_fish_chance": big_fish_chance,
		"fish_king_chance": fish_king_chance,
		"difficulty": difficulty
	}

static func get_age_label(age_years: int) -> String:
	if age_years < 1:
		return "新塘"
	if age_years <= 3:
		return "熟塘"
	if age_years <= 8:
		return "老塘"
	return "老水塘"

func _generate_age_years(type_id: String) -> int:
	match type_id:
		"artificial_pond":
			return rng.randi_range(0, 5)
		"old_pond":
			return rng.randi_range(3, 12)
		"reservoir_pond":
			return rng.randi_range(2, 15)
		_:
			return rng.randi_range(0, 8)

func _calculate_hidden_value(type_id: String, age_years: int, big_fish_chance: float, fish_king_chance: float) -> int:
	var base_value := rng.randi_range(4500, 9000)
	var type_bonus := 0
	match type_id:
		"artificial_pond":
			type_bonus = rng.randi_range(-600, 700)
		"old_pond":
			type_bonus = rng.randi_range(200, 1700)
		"reservoir_pond":
			type_bonus = rng.randi_range(700, 2600)

	var chance_bonus := int(big_fish_chance * 3500.0 + fish_king_chance * 9000.0)
	var age_bonus := age_years * rng.randi_range(80, 180)
	return maxi(1800, base_value + type_bonus + chance_bonus + age_bonus)

func _calculate_quote_price(hidden_value: int, difficulty: float) -> int:
	var estimate_gap := rng.randf_range(0.75, 1.3)
	var difficulty_discount := 1.0 - clampf((difficulty - 1.0) * 0.08, -0.08, 0.18)
	var quote := int(float(hidden_value) * estimate_gap * difficulty_discount)
	return maxi(1200, int(round(float(quote) / 100.0)) * 100)

func _pick_risk_tag(type_id: String, difficulty: float) -> String:
	if type_id == "reservoir_pond":
		return "高波动"
	if difficulty >= 1.2:
		return "大鱼难捞"
	if difficulty >= 1.0:
		return "鱼情不明"
	return RISK_TAGS[rng.randi_range(0, 2)]

func _round_to_2(value: float) -> float:
	return roundf(value * 100.0) / 100.0
