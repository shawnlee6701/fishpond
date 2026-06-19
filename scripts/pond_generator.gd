extends RefCounted
class_name PondGenerator

const DataLoaderScript := preload("res://scripts/data_loader.gd")
const BalanceRulesScript := preload("res://scripts/balance_rules.gd")

const WATER_STATES := ["清亮微绿", "偏浑发黄", "肥水泛绿", "水面起花", "深水偏暗"]
const RUMORS := [
	"老板说去年有人钓到过大货",
	"塘边常有人夜里听见炸水",
	"附近钓友说这里鱼口很滑",
	"上一手承包商急着转出去",
	"村里老师傅说底下有老鱼",
	"早上水面有鱼追小虾，像是鱼群靠边",
	"塘主急着今天收钱，报价可能有水分",
	"看塘的人说前两天刚有人空手走",
	"进水口附近常翻花，但深水区不太见动静",
	"老钓位旁边鱼腥味重，像是刚起过一批鱼",
	"邻塘老板说这口塘被压价转过两手",
	"有人说夜里听到大鱼炸水，也有人说是风浪",
	"塘底淤泥厚，网下去可能拖不动",
	"水草边小鱼很多，大货要看运气"
]
const RISK_TAGS := ["低风险", "鱼情不明", "可能偏贵", "大鱼难捞", "高波动"]
const AREA_LABELS := ["小塘", "中塘", "大塘", "宽水面"]
const POND_NAMES := ["东湾塘", "南埂塘", "西桥塘", "北坡塘", "柳树塘", "三岔塘", "月牙塘", "瓦窑塘", "竹林塘", "渡口塘", "石坝塘", "老井塘"]
const VALUE_PROFILES := ["surplus", "break_even", "loss"]
const QUOTE_TIERS := ["quarter", "half", "high"]

var rng := RandomNumberGenerator.new()
var pond_types: Array = []
var rules: Dictionary = {}
var generation_rules: Dictionary = {}

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value

	pond_types = DataLoaderScript.load_json(DataLoaderScript.POND_TYPES_PATH, [])
	rules = BalanceRulesScript.load_rules()
	generation_rules = BalanceRulesScript.section(rules, "pond_generation")

func generate_daily_ponds(day: int, current_cash: int = 10000) -> Array[Dictionary]:
	var game_balance: Dictionary = DataLoaderScript.load_json(DataLoaderScript.GAME_BALANCE_PATH, {})
	var ponds_per_day := maxi(1, int(game_balance.get("ponds_per_day", 3)))
	var ponds: Array[Dictionary] = []
	var profiles := VALUE_PROFILES.duplicate()
	profiles.shuffle()
	var rumor_pool := RUMORS.duplicate()
	rumor_pool.shuffle()
	var name_pool := POND_NAMES.duplicate()
	name_pool.shuffle()

	for index in range(ponds_per_day):
		var profile := str(profiles[index % profiles.size()])
		var quote_tier := str(QUOTE_TIERS[mini(index, QUOTE_TIERS.size() - 1)])
		var rumor := str(rumor_pool[index % rumor_pool.size()])
		var pond_name := str(name_pool[index % name_pool.size()])
		ponds.append(_generate_pond(day, index, profile, quote_tier, rumor, pond_name, current_cash))

	return ponds

func _generate_pond(day: int, index: int, value_profile: String, quote_tier: String, rumor: String, pond_name: String, current_cash: int) -> Dictionary:
	var pond_type: Dictionary = pond_types[rng.randi_range(0, pond_types.size() - 1)]
	var type_id := str(pond_type.get("id", "unknown"))
	var type_name := str(pond_type.get("name", "未知鱼塘"))
	var physical_profile := _generate_physical_profile(type_id, quote_tier)
	var age_years := int(physical_profile.get("age_years", 0))
	var age_label := get_age_label(age_years)
	var age_factor := _get_age_factor(age_years)
	var physical_factor := float(physical_profile.get("value_factor", 1.0))
	var profile := _get_value_profile(value_profile)
	var depth_factor := float(physical_profile.get("depth_factor", 1.0))
	var difficulty_rules := BalanceRulesScript.dict_value(generation_rules, "difficulty")
	var big_rules := BalanceRulesScript.dict_value(generation_rules, "big_fish_chance")
	var king_rules := BalanceRulesScript.dict_value(generation_rules, "fish_king_chance")
	var difficulty := _round_to_2((float(pond_type.get("difficulty_modifier", 1.0)) + age_factor * BalanceRulesScript.number(difficulty_rules, "age_weight", 0.25) + depth_factor * BalanceRulesScript.number(difficulty_rules, "depth_weight", 0.12) + BalanceRulesScript.random_float_range(rng, difficulty_rules, "random_min", "random_max", -0.08, 0.08)) * float(profile.get("difficulty_factor", 1.0)))
	var big_fish_chance := _round_to_2(clampf((BalanceRulesScript.number(big_rules, "base", 0.12) + age_factor * BalanceRulesScript.number(big_rules, "age_weight", 0.16) + physical_factor * BalanceRulesScript.number(big_rules, "physical_weight", 0.05) + float(pond_type.get("big_fish_modifier", 1.0)) * BalanceRulesScript.number(big_rules, "type_weight", 0.08)) * float(profile.get("big_fish_factor", 1.0)), BalanceRulesScript.number(big_rules, "min", 0.05), BalanceRulesScript.number(big_rules, "max", 0.65)))
	var fish_king_chance := _round_to_2(clampf((BalanceRulesScript.number(king_rules, "base", 0.01) + age_factor * BalanceRulesScript.number(king_rules, "age_weight", 0.025) + depth_factor * BalanceRulesScript.number(king_rules, "depth_weight", 0.012) + float(pond_type.get("fish_king_modifier", 1.0)) * BalanceRulesScript.number(king_rules, "type_weight", 0.018)) * float(profile.get("fish_king_factor", 1.0)), BalanceRulesScript.number(king_rules, "min", 0.01), BalanceRulesScript.number(king_rules, "max", 0.22)))
	var hidden_value := _calculate_hidden_value(type_id, age_years, big_fish_chance, fish_king_chance, float(profile.get("hidden_value_factor", 1.0)) * physical_factor)
	var quote_price := _calculate_quote_price(current_cash, quote_tier, physical_factor)

	return {
		"id": "day_%d_pond_%d" % [day, index + 1],
		"name": pond_name,
		"pond_type": type_id,
		"pond_type_name": type_name,
		"value_profile": value_profile,
		"quote_tier": quote_tier,
		"age_years": age_years,
		"age_label": age_label,
		"quote_price": quote_price,
		"area_label": str(physical_profile.get("area_label", "中塘")),
		"depth_label": str(physical_profile.get("depth_label", "中水")),
		"depth_meters": float(physical_profile.get("depth_meters", 1.8)),
		"water_state": WATER_STATES[rng.randi_range(0, WATER_STATES.size() - 1)],
		"rumor": rumor,
		"risk_tag": _pick_risk_tag(type_id, difficulty),
		"hidden_value": hidden_value,
		"big_fish_chance": big_fish_chance,
		"fish_king_chance": fish_king_chance,
		"difficulty": difficulty
	}

static func get_age_label(age_years: int) -> String:
	if age_years <= 2:
		return "新塘"
	if age_years <= 5:
		return "熟塘"
	if age_years <= 10:
		return "老塘"
	return "老水塘"

func _generate_age_years(type_id: String) -> int:
	var ranges := BalanceRulesScript.dict_value(generation_rules, "age_ranges_by_type")
	var pair := Array(ranges.get(type_id, ranges.get("default", [0, 8])))
	if pair.size() < 2:
		return rng.randi_range(0, 8)
	return rng.randi_range(int(pair[0]), int(pair[1]))

func _generate_physical_profile(type_id: String, quote_tier: String) -> Dictionary:
	var quote_rules := BalanceRulesScript.dict_value(BalanceRulesScript.dict_value(generation_rules, "quote_tiers"), quote_tier, BalanceRulesScript.dict_value(BalanceRulesScript.dict_value(generation_rules, "quote_tiers"), "default"))
	var area_options := BalanceRulesScript.string_array(quote_rules, "area_labels", AREA_LABELS)
	var area_label := _pick_from(area_options)
	var depth_meters := BalanceRulesScript.random_float_range(rng, quote_rules, "depth_min", "depth_max", 1.0, 3.0)
	var age_years := _generate_tier_age(type_id, BalanceRulesScript.integer(quote_rules, "age_min", 0), BalanceRulesScript.integer(quote_rules, "age_max", 8))

	var area_factor := _get_area_factor(area_label)
	var depth_rules := BalanceRulesScript.dict_value(generation_rules, "depth_factor")
	var physical_rules := BalanceRulesScript.dict_value(generation_rules, "physical_value_factor")
	var depth_factor := clampf((depth_meters - BalanceRulesScript.number(depth_rules, "offset", 1.0)) / BalanceRulesScript.number(depth_rules, "divisor", 2.2), BalanceRulesScript.number(depth_rules, "min", 0.0), BalanceRulesScript.number(depth_rules, "max", 1.5))
	var age_factor := _get_age_factor(age_years)
	var value_factor := clampf(BalanceRulesScript.number(physical_rules, "base", 0.72) + area_factor * BalanceRulesScript.number(physical_rules, "area_weight", 0.28) + depth_factor * BalanceRulesScript.number(physical_rules, "depth_weight", 0.18) + age_factor * BalanceRulesScript.number(physical_rules, "age_weight", 0.12), BalanceRulesScript.number(physical_rules, "min", 0.65), BalanceRulesScript.number(physical_rules, "max", 1.55))

	return {
		"area_label": area_label,
		"depth_meters": _round_to_2(depth_meters),
		"depth_label": _get_depth_label(depth_meters),
		"age_years": age_years,
		"depth_factor": depth_factor,
		"value_factor": value_factor
	}

func _generate_tier_age(type_id: String, min_age: int, max_age: int) -> int:
	var generated_age := _generate_age_years(type_id)
	return clampi(generated_age, min_age, max_age)

func _pick_from(options: Array) -> String:
	return str(options[rng.randi_range(0, options.size() - 1)])

func _get_area_factor(area_label: String) -> float:
	var area_factors := BalanceRulesScript.dict_value(generation_rules, "area_factors")
	return float(area_factors.get(area_label, area_factors.get("中塘", 0.65)))

func _get_depth_label(depth_meters: float) -> String:
	if depth_meters < 1.5:
		return "浅水"
	if depth_meters < 2.4:
		return "中水"
	return "深水"

func _calculate_hidden_value(type_id: String, age_years: int, big_fish_chance: float, fish_king_chance: float, profile_factor: float) -> int:
	var hidden_rules := BalanceRulesScript.dict_value(generation_rules, "hidden_value")
	var base_value := BalanceRulesScript.random_int_range(rng, hidden_rules, "base_min", "base_max", 4500, 9000)
	var type_bonus := BalanceRulesScript.random_pair_int(rng, BalanceRulesScript.dict_value(hidden_rules, "type_bonus"), type_id, 0, 0)
	var chance_bonus := int(big_fish_chance * BalanceRulesScript.number(hidden_rules, "big_fish_weight", 3500.0) + fish_king_chance * BalanceRulesScript.number(hidden_rules, "fish_king_weight", 9000.0))
	var age_bonus := age_years * BalanceRulesScript.random_int_range(rng, hidden_rules, "age_bonus_min", "age_bonus_max", 80, 180)
	return maxi(BalanceRulesScript.integer(hidden_rules, "min", 1800), int(float(base_value + type_bonus + chance_bonus + age_bonus) * profile_factor))

func _calculate_quote_price(current_cash: int, quote_tier: String, physical_factor: float) -> int:
	var cash := maxi(0, current_cash)
	var quote_rules := BalanceRulesScript.dict_value(BalanceRulesScript.dict_value(generation_rules, "quote_tiers"), quote_tier, BalanceRulesScript.dict_value(BalanceRulesScript.dict_value(generation_rules, "quote_tiers"), "default"))
	var ratio := BalanceRulesScript.random_float_range(rng, quote_rules, "ratio_min", "ratio_max", 0.25, 0.25)
	var adjusted_ratio := ratio * clampf(physical_factor, BalanceRulesScript.number(generation_rules, "quote_physical_factor_min", 0.86), BalanceRulesScript.number(generation_rules, "quote_physical_factor_max", 1.12))
	adjusted_ratio = clampf(adjusted_ratio, BalanceRulesScript.number(quote_rules, "adjusted_min", 0.22), BalanceRulesScript.number(quote_rules, "adjusted_max", 0.92))

	var rounding := BalanceRulesScript.integer(generation_rules, "quote_rounding", 100)
	var min_quote := BalanceRulesScript.integer(generation_rules, "min_quote", 100)
	var quote := int(round(float(cash) * adjusted_ratio / float(rounding))) * rounding
	if cash < min_quote:
		return cash
	return clampi(maxi(min_quote, quote), min_quote, cash)

func _get_value_profile(value_profile: String) -> Dictionary:
	var profile_rules := BalanceRulesScript.dict_value(BalanceRulesScript.dict_value(generation_rules, "value_profiles"), value_profile)
	if profile_rules.is_empty():
		return {
			"hidden_value_factor": 1.0,
			"difficulty_factor": 1.0,
			"big_fish_factor": 1.0,
			"fish_king_factor": 1.0
		}
	return {
		"hidden_value_factor": BalanceRulesScript.random_pair_float(rng, profile_rules, "hidden_value_factor", 1.0, 1.0),
		"difficulty_factor": BalanceRulesScript.random_pair_float(rng, profile_rules, "difficulty_factor", 1.0, 1.0),
		"big_fish_factor": BalanceRulesScript.random_pair_float(rng, profile_rules, "big_fish_factor", 1.0, 1.0),
		"fish_king_factor": BalanceRulesScript.random_pair_float(rng, profile_rules, "fish_king_factor", 1.0, 1.0)
	}

func _pick_risk_tag(type_id: String, difficulty: float) -> String:
	var risk_rules := BalanceRulesScript.dict_value(generation_rules, "risk_thresholds")
	if type_id == "reservoir_pond":
		return "高波动"
	if difficulty >= BalanceRulesScript.number(risk_rules, "hard", 1.2):
		return "大鱼难捞"
	if difficulty >= BalanceRulesScript.number(risk_rules, "unclear", 1.0):
		return "鱼情不明"
	return RISK_TAGS[rng.randi_range(0, 2)]

func _get_age_factor(age_years: int) -> float:
	var divisor := BalanceRulesScript.number(generation_rules, "age_factor_divisor", 10.0)
	return clampf(float(age_years) / divisor, BalanceRulesScript.number(generation_rules, "factor_min", 0.0), BalanceRulesScript.number(generation_rules, "factor_max", 1.5))

func _round_to_2(value: float) -> float:
	return roundf(value * 100.0) / 100.0
