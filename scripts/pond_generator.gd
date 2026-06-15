extends RefCounted
class_name PondGenerator

const DataLoaderScript := preload("res://scripts/data_loader.gd")

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

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value

	pond_types = DataLoaderScript.load_json(DataLoaderScript.POND_TYPES_PATH, [])

func generate_daily_ponds(day: int, current_cash: int = 10000) -> Array[Dictionary]:
	var ponds: Array[Dictionary] = []
	var profiles := VALUE_PROFILES.duplicate()
	profiles.shuffle()
	var rumor_pool := RUMORS.duplicate()
	rumor_pool.shuffle()
	var name_pool := POND_NAMES.duplicate()
	name_pool.shuffle()

	for index in range(3):
		ponds.append(_generate_pond(day, index, str(profiles[index]), str(QUOTE_TIERS[index]), str(rumor_pool[index]), str(name_pool[index]), current_cash))

	return ponds

func _generate_pond(day: int, index: int, value_profile: String, quote_tier: String, rumor: String, pond_name: String, current_cash: int) -> Dictionary:
	var pond_type: Dictionary = pond_types[rng.randi_range(0, pond_types.size() - 1)]
	var type_id := str(pond_type.get("id", "unknown"))
	var type_name := str(pond_type.get("name", "未知鱼塘"))
	var physical_profile := _generate_physical_profile(type_id, quote_tier)
	var age_years := int(physical_profile.get("age_years", 0))
	var age_label := get_age_label(age_years)
	var age_factor := clampf(float(age_years) / 10.0, 0.0, 1.5)
	var physical_factor := float(physical_profile.get("value_factor", 1.0))
	var profile := _get_value_profile(value_profile)
	var depth_factor := float(physical_profile.get("depth_factor", 1.0))
	var difficulty := _round_to_2((float(pond_type.get("difficulty_modifier", 1.0)) + age_factor * 0.25 + depth_factor * 0.12 + rng.randf_range(-0.08, 0.08)) * float(profile.get("difficulty_factor", 1.0)))
	var big_fish_chance := _round_to_2(clampf((0.12 + age_factor * 0.16 + physical_factor * 0.05 + float(pond_type.get("big_fish_modifier", 1.0)) * 0.08) * float(profile.get("big_fish_factor", 1.0)), 0.05, 0.65))
	var fish_king_chance := _round_to_2(clampf((0.01 + age_factor * 0.025 + depth_factor * 0.012 + float(pond_type.get("fish_king_modifier", 1.0)) * 0.018) * float(profile.get("fish_king_factor", 1.0)), 0.01, 0.22))
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
	match type_id:
		"artificial_pond":
			return rng.randi_range(0, 5)
		"old_pond":
			return rng.randi_range(3, 12)
		"reservoir_pond":
			return rng.randi_range(2, 15)
		_:
			return rng.randi_range(0, 8)

func _generate_physical_profile(type_id: String, quote_tier: String) -> Dictionary:
	var area_label := "中塘"
	var depth_meters := 1.8
	var age_years := 2
	match quote_tier:
		"quarter":
			area_label = _pick_from(["小塘", "中塘"])
			depth_meters = rng.randf_range(0.8, 1.5)
			age_years = _generate_tier_age(type_id, 0, 4)
		"half":
			area_label = _pick_from(["中塘", "大塘"])
			depth_meters = rng.randf_range(1.5, 2.4)
			age_years = _generate_tier_age(type_id, 2, 8)
		"high":
			area_label = _pick_from(["大塘", "宽水面"])
			depth_meters = rng.randf_range(2.4, 4.0)
			age_years = _generate_tier_age(type_id, 5, 15)
		_:
			area_label = AREA_LABELS[rng.randi_range(0, AREA_LABELS.size() - 1)]
			depth_meters = rng.randf_range(1.0, 3.0)
			age_years = _generate_age_years(type_id)

	var area_factor := _get_area_factor(area_label)
	var depth_factor := clampf((depth_meters - 1.0) / 2.2, 0.0, 1.5)
	var age_factor := clampf(float(age_years) / 10.0, 0.0, 1.5)
	var value_factor := clampf(0.72 + area_factor * 0.28 + depth_factor * 0.18 + age_factor * 0.12, 0.65, 1.55)

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
	match area_label:
		"小塘":
			return 0.25
		"中塘":
			return 0.65
		"大塘":
			return 1.0
		"宽水面":
			return 1.28
		_:
			return 0.65

func _get_depth_label(depth_meters: float) -> String:
	if depth_meters < 1.5:
		return "浅水"
	if depth_meters < 2.4:
		return "中水"
	return "深水"

func _calculate_hidden_value(type_id: String, age_years: int, big_fish_chance: float, fish_king_chance: float, profile_factor: float) -> int:
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
	return maxi(1800, int(float(base_value + type_bonus + chance_bonus + age_bonus) * profile_factor))

func _calculate_quote_price(current_cash: int, quote_tier: String, physical_factor: float) -> int:
	var cash := maxi(0, current_cash)
	var ratio := 0.25
	match quote_tier:
		"quarter":
			ratio = rng.randf_range(0.23, 0.27)
		"half":
			ratio = rng.randf_range(0.48, 0.52)
		"high":
			ratio = rng.randf_range(0.8, 0.9)

	var adjusted_ratio := ratio * clampf(physical_factor, 0.86, 1.12)
	match quote_tier:
		"quarter":
			adjusted_ratio = clampf(adjusted_ratio, 0.22, 0.3)
		"half":
			adjusted_ratio = clampf(adjusted_ratio, 0.44, 0.58)
		"high":
			adjusted_ratio = clampf(adjusted_ratio, 0.78, 0.92)

	var quote := int(round(float(cash) * adjusted_ratio / 100.0)) * 100
	if cash < 100:
		return cash
	return clampi(maxi(100, quote), 100, cash)

func _get_value_profile(value_profile: String) -> Dictionary:
	match value_profile:
		"surplus":
			return {
				"hidden_value_factor": rng.randf_range(1.18, 1.42),
				"difficulty_factor": rng.randf_range(0.78, 0.95),
				"big_fish_factor": rng.randf_range(1.25, 1.55),
				"fish_king_factor": rng.randf_range(1.15, 1.45)
			}
		"break_even":
			return {
				"hidden_value_factor": rng.randf_range(0.92, 1.08),
				"difficulty_factor": rng.randf_range(0.96, 1.08),
				"big_fish_factor": rng.randf_range(0.9, 1.1),
				"fish_king_factor": rng.randf_range(0.85, 1.1)
			}
		"loss":
			return {
				"hidden_value_factor": rng.randf_range(0.68, 0.88),
				"difficulty_factor": rng.randf_range(1.12, 1.35),
				"big_fish_factor": rng.randf_range(0.55, 0.82),
				"fish_king_factor": rng.randf_range(0.45, 0.75)
			}
		_:
			return {
				"hidden_value_factor": 1.0,
				"difficulty_factor": 1.0,
				"big_fish_factor": 1.0,
				"fish_king_factor": 1.0
			}

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
