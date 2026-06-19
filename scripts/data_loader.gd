extends RefCounted
class_name DataLoader

const POND_TYPES_PATH := "res://data/pond_types.json"
const FISH_TYPES_PATH := "res://data/fish_types.json"
const TOOLS_PATH := "res://data/tools.json"
const GAME_BALANCE_PATH := "res://data/game_balance.json"
const BALANCE_RULES_PATH := "res://data/balance_rules.json"

static func load_all() -> Dictionary:
	return {
		"pond_types": load_json(POND_TYPES_PATH, []),
		"fish_types": load_json(FISH_TYPES_PATH, []),
		"tools": load_json(TOOLS_PATH, []),
		"game_balance": load_json(GAME_BALANCE_PATH, {}),
		"balance_rules": load_json(BALANCE_RULES_PATH, {})
	}

static func load_json(path: String, fallback: Variant) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("数据文件不存在：%s" % path)
		return fallback

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("数据文件读取失败：%s" % path)
		return fallback

	var text := file.get_as_text()
	var data: Variant = JSON.parse_string(text)
	if data == null:
		push_error("JSON 格式错误：%s" % path)
		return fallback

	return data

static func print_test() -> void:
	var data := load_all()
	print("鱼塘类型数量：", data["pond_types"].size())
	print("鱼获类型数量：", data["fish_types"].size())
	print("验塘方式数量：", data["tools"].size())
	print("初始现金：", data["game_balance"].get("initial_cash", 0))
