extends RefCounted
class_name InspectionSystem

const BalanceRulesScript := preload("res://scripts/balance_rules.gd")

var rng := RandomNumberGenerator.new()
var rules: Dictionary = {}
var inspection_rules: Dictionary = {}

func _init() -> void:
	rng.randomize()
	rules = BalanceRulesScript.load_rules()
	inspection_rules = BalanceRulesScript.section(rules, "inspection")

func generate_result(tool: Dictionary, pond: Dictionary) -> String:
	var result := generate_result_data(tool, pond)
	return "%s\n%s" % [result.get("headline", "验塘结果"), result.get("detail", "暂时看不准。")]

func generate_result_data(tool: Dictionary, pond: Dictionary) -> Dictionary:
	var tool_id := str(tool.get("id", "observe"))
	var profile := _build_signal_profile(pond)
	var lines: Array[String] = []

	match tool_id:
		"fish_finder":
			lines.append_array(_build_fish_finder_lines(profile))
		"master":
			lines.append_array(_build_master_lines(pond, profile))
		_:
			lines.append_array(_build_observe_lines(profile))

	var detail := " ".join(lines)
	if not detail.is_empty():
		detail += " "
	detail += _uncertainty_note(tool_id)
	return {
		"headline": _build_result_headline(tool_id, profile),
		"detail": detail
	}

func _build_result_headline(tool_id: String, profile: Dictionary) -> String:
	match tool_id:
		"fish_finder":
			match str(profile.get("big", "low")):
				"high":
					return "鱼群信号较强，有大鱼机会"
				"medium":
					return "扫到一些鱼影，密度还不算稳"
				_:
					return "鱼群信号偏散，需要谨慎"
		"master":
			var price_level := str(profile.get("price", "fair"))
			var difficulty_level := str(profile.get("difficulty", "normal"))
			if price_level == "expensive" or difficulty_level == "hard":
				return "老师傅建议谨慎承包"
			if price_level == "cheap" and difficulty_level != "hard":
				return "报价有机会，但不能算稳赚"
			return "这塘能谈，后续成本要留足"
		_:
			match str(profile.get("big", "low")):
				"high":
					return "水面动静明显，像是有大鱼"
				"medium":
					return "水面有些动静，鱼活动一般"
				_:
					return "水面较平静，暂时看不出大货"

func _build_signal_profile(pond: Dictionary) -> Dictionary:
	var big_chance := float(pond.get("big_fish_chance", 0.0))
	var king_chance := float(pond.get("fish_king_chance", 0.0))
	var difficulty := float(pond.get("difficulty", 1.0))
	var hidden_value := float(pond.get("hidden_value", 0))
	var quote_price := float(pond.get("quote_price", 0))
	var quote_ratio := quote_price / maxf(hidden_value, 1.0)

	return {
		"big": _big_level(big_chance),
		"king": _king_level(king_chance),
		"difficulty": _difficulty_level(difficulty),
		"price": _price_level(quote_ratio)
	}

func _big_level(value: float) -> String:
	var thresholds := BalanceRulesScript.dict_value(inspection_rules, "big_thresholds")
	if value >= BalanceRulesScript.number(thresholds, "high", 0.42):
		return "high"
	if value >= BalanceRulesScript.number(thresholds, "medium", 0.24):
		return "medium"
	return "low"

func _king_level(value: float) -> String:
	var thresholds := BalanceRulesScript.dict_value(inspection_rules, "king_thresholds")
	if value >= BalanceRulesScript.number(thresholds, "strong", 0.14):
		return "strong"
	if value >= BalanceRulesScript.number(thresholds, "possible", 0.07):
		return "possible"
	return "quiet"

func _difficulty_level(value: float) -> String:
	var thresholds := BalanceRulesScript.dict_value(inspection_rules, "difficulty_thresholds")
	if value >= BalanceRulesScript.number(thresholds, "hard", 1.18):
		return "hard"
	if value >= BalanceRulesScript.number(thresholds, "normal", 0.95):
		return "normal"
	return "easy"

func _price_level(quote_ratio: float) -> String:
	var thresholds := BalanceRulesScript.dict_value(inspection_rules, "price_thresholds")
	if quote_ratio <= BalanceRulesScript.number(thresholds, "cheap", 0.9):
		return "cheap"
	if quote_ratio >= BalanceRulesScript.number(thresholds, "expensive", 1.12):
		return "expensive"
	return "fair"

func _build_observe_lines(profile: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	match str(profile.get("big", "low")):
		"high":
			lines.append(_pick([
				"水面偶尔有重翻花，疑似有大鱼活动。",
				"塘边痕迹偏重，看起来不像只有小鱼。"
			]))
		"medium":
			lines.append(_pick([
				"水面有些碎花，鱼情看着不算死。",
				"浅边有零星动静，但鱼的个头还看不准。"
			]))
		_:
			lines.append(_pick([
				"水面比较安静，暂时看不出明显大鱼迹象。",
				"表层动静偏少，可能鱼在深处，也可能密度一般。"
			]))

	match str(profile.get("king", "quiet")):
		"strong":
			lines.append(_pick([
				"深水区偶尔有浑泡和暗涌，像是藏着大东西。",
				"远水位有沉重动静，深处值得留意。"
			]))
		"possible":
			lines.append(_pick([
				"深水区看不太透，不能排除藏着老鱼。",
				"靠目测看不到底，深处先打个问号。"
			]))

	if str(profile.get("difficulty", "normal")) == "hard":
		lines.append(_pick([
			"岸边泥底和水色都不太省心，这塘不好捞。",
			"下网位置不太舒服，操作难度可能偏高。"
		]))

	return lines

func _build_fish_finder_lines(profile: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	match str(profile.get("big", "low")):
		"high":
			lines.append(_pick([
				"设备扫到几段中大型回波，和目测的大鱼迹象对得上。",
				"中下层有偏强鱼群信号，大鱼概率看着不低。"
			]))
		"medium":
			lines.append(_pick([
				"有鱼群回波，但大小分布不算特别亮眼。",
				"中层信号断断续续，像是有货，但还谈不上稳。"
			]))
		_:
			lines.append(_pick([
				"鱼群信号偏散，没扫到很漂亮的密集大回波。",
				"设备反馈一般，更像是鱼少或鱼口比较滑。"
			]))

	match str(profile.get("king", "quiet")):
		"strong":
			lines.append(_pick([
				"深水区有异常大型信号，不过设备仍不能确认是不是鱼王。",
				"底层出现过一段很重的回波，值得谨慎加分。"
			]))
		"possible":
			lines.append(_pick([
				"底层偶有大回波，可能是大鱼，也可能是障碍物。",
				"深处信号不干净，有点机会但别太上头。"
			]))
		_:
			lines.append(_pick([
				"底层没有明显异常大信号，鱼王线索暂时偏弱。",
				"深水回波比较平，暂时看不到特别突出的大家伙。"
			]))

	match str(profile.get("difficulty", "normal")):
		"hard":
			lines.append(_pick([
				"水下结构比较乱，真下网可能会费工。",
				"底况不算清爽，捞鱼难度可能偏高。"
			]))
		"easy":
			lines.append(_pick([
				"底况回波还算顺，施工阻力看着不大。",
				"下层结构不算复杂，操作风险暂时可控。"
			]))
		_:
			lines.append(_pick([
				"底况中规中矩，作业难度大概正常。",
				"水下结构有些起伏，但还没到特别难搞。"
			]))

	return lines

func _build_master_lines(pond: Dictionary, profile: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var value_range := _estimate_value_range(float(pond.get("hidden_value", 0)))
	lines.append("老师傅估摸：这塘底子大概在 %d 到 %d 元这一带。" % [value_range.x, value_range.y])

	match str(profile.get("price", "fair")):
		"cheap":
			lines.append(_pick([
				"这报价不算硬，顺利的话有赚头。",
				"塘主报价看着有机会，但得防鱼不好起。"
			]))
		"expensive":
			lines.append(_pick([
				"老板要价偏满，回旋余地可能不多。",
				"报价不算便宜，除非真出大货，不然压力不小。"
			]))
		_:
			lines.append(_pick([
				"价格大致在合理区间，赚亏主要看操作和运气。",
				"报价谈不上捡漏，也还没到离谱。"
			]))

	match str(profile.get("difficulty", "normal")):
		"hard":
			lines.append(_pick([
				"风险判断：这塘不好捞，人工和时间都要多留。",
				"风险判断：水底情况可能拖后腿，别只看鱼价。"
			]))
		"easy":
			lines.append(_pick([
				"风险判断：操作风险偏低，主要看报价和出鱼节奏。",
				"风险判断：底况不算难，失手点更多在鱼情判断。"
			]))
		_:
			lines.append(_pick([
				"风险判断：整体偏常规，胜负手在报价和起鱼效率。",
				"风险判断：没有特别吓人的信号，但也看不出稳赚。"
			]))

	match str(profile.get("big", "low")):
		"high":
			lines.append("综合看，大鱼想象空间是有的，但别按必出大鱼去算账。")
		"medium":
			lines.append("综合看，鱼情有一定空间，但收益别估得太满。")
		_:
			lines.append("综合看，稳妥起见别把大货收益算得太重。")

	return lines

func _estimate_value_range(hidden_value: float) -> Vector2i:
	var estimate_rules := BalanceRulesScript.dict_value(inspection_rules, "master_value_estimate")
	var rounding := BalanceRulesScript.integer(estimate_rules, "rounding", 500)
	var center := hidden_value * BalanceRulesScript.random_float_range(rng, estimate_rules, "center_min", "center_max", 0.88, 1.12)
	var lower := _round_to_nearest(maxf(BalanceRulesScript.number(estimate_rules, "min_lower", 1000.0), center * BalanceRulesScript.random_float_range(rng, estimate_rules, "lower_min", "lower_max", 0.86, 0.94)), rounding)
	var upper := _round_to_nearest(maxf(float(lower + BalanceRulesScript.integer(estimate_rules, "min_width", 500)), center * BalanceRulesScript.random_float_range(rng, estimate_rules, "upper_min", "upper_max", 1.06, 1.16)), rounding)
	return Vector2i(lower, upper)

func _uncertainty_note(tool_id: String) -> String:
	match tool_id:
		"fish_finder":
			return "信号比目测清楚，但水下障碍和鱼口状态还是会干扰判断。"
		"master":
			return "老师傅说得更透，但仍是估值区间，不是保底收益。"
		_:
			return "目测只能看个大概，换个法子验塘能把判断收窄。"

func _round_to_nearest(value: float, step: int) -> int:
	return int(round(value / float(step)) * float(step))

func _pick(options: Array) -> String:
	return str(options[rng.randi_range(0, options.size() - 1)])
