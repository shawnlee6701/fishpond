extends RefCounted
class_name InspectionSystem

var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func generate_result(tool: Dictionary, pond: Dictionary) -> String:
	var tool_id := str(tool.get("id", "observe"))
	var tool_name := str(tool.get("name", "验塘"))
	var accuracy := float(tool.get("accuracy", 0.35))
	var lines: Array[String] = ["%s结果：" % tool_name]

	match tool_id:
		"fish_finder":
			lines.append_array(_build_fish_finder_lines(pond, accuracy))
		"master":
			lines.append_array(_build_master_lines(pond, accuracy))
		_:
			lines.append_array(_build_observe_lines(pond, accuracy))

	lines.append("仅供参考，鱼在水里，谁也不敢说死。")
	return "\n".join(lines)

func _build_observe_lines(pond: Dictionary, accuracy: float) -> Array[String]:
	var lines: Array[String] = []
	var big_signal := _fuzzy_score(float(pond.get("big_fish_chance", 0.0)), accuracy, 0.34)
	var king_signal := _fuzzy_score(float(pond.get("fish_king_chance", 0.0)), accuracy, 0.12)
	var difficulty_signal := _fuzzy_score(float(pond.get("difficulty", 1.0)), accuracy, 1.18)

	if big_signal >= 0.75:
		lines.append(_pick([
			"水面偶尔有大翻花，疑似有大鱼活动。",
			"塘边能看见几处重口痕迹，像是有大货游过。"
		]))
	elif big_signal >= 0.45:
		lines.append(_pick([
			"水面有些碎花，鱼情看着不算死。",
			"浅边有零星动静，但看不出鱼有多大。"
		]))
	else:
		lines.append(_pick([
			"水面比较安静，暂时看不出明显大鱼迹象。",
			"表层动静偏少，可能鱼在深处，也可能密度一般。"
		]))

	if king_signal >= 0.65:
		lines.append(_pick([
			"深水区偶尔冒浑泡，像有异常大的东西压底。",
			"远水位有一两次沉重暗涌，值得留意。"
		]))
	elif rng.randf() < 0.35:
		lines.append(_pick([
			"深水区看不太透，不能排除藏鱼。",
			"靠目测看不到底，鱼王这种事只能先打个问号。"
		]))

	if difficulty_signal >= 0.7:
		lines.append(_pick([
			"岸边泥底和水色都不太省心，这塘不好捞。",
			"下网位置不太舒服，操作难度可能偏高。"
		]))

	return lines

func _build_fish_finder_lines(pond: Dictionary, accuracy: float) -> Array[String]:
	var lines: Array[String] = []
	var big_signal := _fuzzy_score(float(pond.get("big_fish_chance", 0.0)), accuracy, 0.34)
	var king_signal := _fuzzy_score(float(pond.get("fish_king_chance", 0.0)), accuracy, 0.12)
	var difficulty_signal := _fuzzy_score(float(pond.get("difficulty", 1.0)), accuracy, 1.18)

	if big_signal >= 0.75:
		lines.append(_pick([
			"设备扫到几段中大型回波，像有大鱼带队活动。",
			"中下层有偏强鱼群信号，大鱼概率看着不低。"
		]))
	elif big_signal >= 0.45:
		lines.append(_pick([
			"有鱼群信号，但大小分布不算特别亮眼。",
			"中层回波断断续续，可能有货，但不算稳。"
		]))
	else:
		lines.append(_pick([
			"鱼群信号偏散，暂时没扫到很漂亮的密集回波。",
			"设备反馈一般，像是鱼少或鱼口比较滑。"
		]))

	if king_signal >= 0.65:
		lines.append(_pick([
			"深水区有异常大型信号，不过设备没法确认是不是鱼王。",
			"底层出现过一段很重的回波，值得谨慎加分。"
		]))
	elif king_signal >= 0.35:
		lines.append(_pick([
			"底层偶有大回波，可能是大鱼，也可能是障碍物。",
			"深处信号不干净，有点机会但别太上头。"
		]))

	if difficulty_signal >= 0.7:
		lines.append(_pick([
			"水下结构比较乱，真下网可能会费工。",
			"底况不算清爽，捞鱼难度可能偏高。"
		]))
	else:
		lines.append(_pick([
			"底况回波还算顺，施工阻力看着不大。",
			"下层结构不算复杂，操作风险暂时可控。"
		]))

	return lines

func _build_master_lines(pond: Dictionary, accuracy: float) -> Array[String]:
	var lines: Array[String] = []
	var hidden_value := float(pond.get("hidden_value", 0))
	var quote_price := float(pond.get("quote_price", 0))
	var difficulty_signal := _fuzzy_score(float(pond.get("difficulty", 1.0)), accuracy, 1.18)
	var big_signal := _fuzzy_score(float(pond.get("big_fish_chance", 0.0)), accuracy, 0.34)
	var value_range := _estimate_value_range(hidden_value, accuracy)

	lines.append("老师傅估摸：这塘底子大概在 %d 到 %d 元这一带。" % [value_range.x, value_range.y])

	if quote_price <= hidden_value * rng.randf_range(0.78, 0.95):
		lines.append(_pick([
			"塘主报价看着有机会，但得防鱼不好起。",
			"这报价不算硬，顺利的话有赚头。"
		]))
	elif quote_price >= hidden_value * rng.randf_range(1.08, 1.28):
		lines.append(_pick([
			"报价不算便宜，除非真出大货，不然压力不小。",
			"老板要价偏满，回旋余地可能不多。"
		]))
	else:
		lines.append(_pick([
			"价格大致在合理区间，赚亏主要看操作和运气。",
			"报价谈不上捡漏，也还没到离谱。"
		]))

	if difficulty_signal >= 0.7:
		lines.append(_pick([
			"风险判断：这塘不好捞，人工和时间都要多留。",
			"风险判断：水底情况可能拖后腿，别只看鱼价。"
		]))
	elif big_signal >= 0.7:
		lines.append(_pick([
			"风险判断：有大鱼想象空间，但波动也会更大。",
			"风险判断：值得一搏，不过别把大鱼当成必出。"
		]))
	else:
		lines.append(_pick([
			"风险判断：整体偏常规，胜负手在报价和起鱼效率。",
			"风险判断：没有特别吓人的信号，但也看不出稳赚。"
		]))

	return lines

func _fuzzy_score(value: float, accuracy: float, high_value: float) -> float:
	var noise := lerpf(0.38, 0.12, clampf(accuracy, 0.0, 1.0))
	var normalized := clampf(value / high_value, 0.0, 1.0)
	return clampf(normalized + rng.randf_range(-noise, noise), 0.0, 1.0)

func _estimate_value_range(hidden_value: float, accuracy: float) -> Vector2i:
	var noise := lerpf(0.5, 0.2, clampf(accuracy, 0.0, 1.0))
	var center := hidden_value * rng.randf_range(1.0 - noise, 1.0 + noise)
	var lower := _round_to_nearest(maxf(1000.0, center * rng.randf_range(0.8, 0.92)), 500)
	var upper := _round_to_nearest(maxf(float(lower + 500), center * rng.randf_range(1.08, 1.24)), 500)
	return Vector2i(lower, upper)

func _round_to_nearest(value: float, step: int) -> int:
	return int(round(value / float(step)) * float(step))

func _pick(options: Array) -> String:
	return str(options[rng.randi_range(0, options.size() - 1)])
