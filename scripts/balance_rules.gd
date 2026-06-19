extends RefCounted
class_name BalanceRules

const DataLoaderScript := preload("res://scripts/data_loader.gd")

static func load_rules() -> Dictionary:
	return DataLoaderScript.load_json(DataLoaderScript.BALANCE_RULES_PATH, {})

static func section(rules: Dictionary, key: String) -> Dictionary:
	return Dictionary(rules.get(key, {}))

static func dict_value(source: Dictionary, key: String, fallback: Dictionary = {}) -> Dictionary:
	return Dictionary(source.get(key, fallback))

static func number(source: Dictionary, key: String, fallback: float) -> float:
	return float(source.get(key, fallback))

static func integer(source: Dictionary, key: String, fallback: int) -> int:
	return int(source.get(key, fallback))

static func string_array(source: Dictionary, key: String, fallback: Array) -> Array:
	var value: Variant = source.get(key, fallback)
	if value is Array:
		return Array(value)
	return fallback

static func random_float_range(rng: RandomNumberGenerator, source: Dictionary, min_key: String, max_key: String, fallback_min: float, fallback_max: float) -> float:
	return rng.randf_range(number(source, min_key, fallback_min), number(source, max_key, fallback_max))

static func random_int_range(rng: RandomNumberGenerator, source: Dictionary, min_key: String, max_key: String, fallback_min: int, fallback_max: int) -> int:
	return rng.randi_range(integer(source, min_key, fallback_min), integer(source, max_key, fallback_max))

static func random_pair_float(rng: RandomNumberGenerator, source: Dictionary, key: String, fallback_min: float, fallback_max: float) -> float:
	var pair: Array = Array(source.get(key, [fallback_min, fallback_max]))
	if pair.size() < 2:
		return rng.randf_range(fallback_min, fallback_max)
	return rng.randf_range(float(pair[0]), float(pair[1]))

static func random_pair_int(rng: RandomNumberGenerator, source: Dictionary, key: String, fallback_min: int, fallback_max: int) -> int:
	var pair: Array = Array(source.get(key, [fallback_min, fallback_max]))
	if pair.size() < 2:
		return rng.randi_range(fallback_min, fallback_max)
	return rng.randi_range(int(pair[0]), int(pair[1]))
