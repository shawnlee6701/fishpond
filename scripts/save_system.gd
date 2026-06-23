extends RefCounted
class_name FishPoolSaveSystem

const SAVE_PATH := "user://save_game.json"
const SETTLEMENT_HISTORY_PATH := "user://settlement_history.json"
const SAVE_VERSION := 1
const SETTLEMENT_HISTORY_VERSION := 2

static func has_checkpoint() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func save_checkpoint(game_state: GameState) -> bool:
	var payload := {
		"version": SAVE_VERSION,
		"cash": game_state.cash,
		"day": game_state.day,
		"daily_ponds_day": game_state.daily_ponds_day,
		"daily_ponds": game_state.daily_ponds
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("无法写入游戏存档：%s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(payload))
	return true

static func load_checkpoint(game_state: GameState) -> bool:
	if not has_checkpoint():
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false

	var payload := parsed as Dictionary
	if int(payload.get("version", 0)) != SAVE_VERSION:
		return false

	var ponds: Array[Dictionary] = []
	var saved_ponds: Variant = payload.get("daily_ponds", [])
	if saved_ponds is Array:
		for pond_variant in saved_ponds:
			if pond_variant is Dictionary:
				ponds.append(Dictionary(pond_variant).duplicate(true))

	game_state.cash = int(payload.get("cash", game_state.cash))
	game_state.day = maxi(1, int(payload.get("day", game_state.day)))
	game_state.daily_ponds_day = int(payload.get("daily_ponds_day", 0))
	game_state.daily_ponds = ponds
	if game_state.daily_ponds_day != game_state.day:
		game_state.daily_ponds = []
		game_state.daily_ponds_day = 0
	game_state.reset_round()
	return true

static func clear_checkpoint() -> bool:
	if not has_checkpoint():
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH)) == OK

static func record_settlement(game_state: GameState) -> bool:
	if game_state.settlement_recorded or game_state.current_pond.is_empty():
		return false

	var records := load_settlement_records()
	var settled_at_unix := int(Time.get_unix_time_from_system())
	var timestamp := Time.get_datetime_string_from_system(false, true)
	records.append(normalize_settlement_record({
		"record_id": "%d-%d-%d" % [game_state.day, settled_at_unix, records.size() + 1],
		"day": game_state.day,
		"timestamp": timestamp,
		"timestamp_unix": settled_at_unix,
		"settled_at": timestamp,
		"settled_at_unix": settled_at_unix,
		"pond_name": str(game_state.current_pond.get("name", "未知鱼塘")),
		"finish_method": _normalize_finish_method(str(game_state.last_result.get("title", "本局结算"))),
		"settlement_title": str(game_state.last_result.get("title", "本局结算")),
		"result_name": game_state.fish_result_name,
		"result_description": game_state.fish_description,
		"contract_cost": int(game_state.current_pond.get("contract_total_cost", game_state.current_pond.get("quote_price", 0))),
		"inspection_cost": game_state.inspection_cost_total,
		"fishing_cost": game_state.work_cost,
		"transport_cost": 0,
		"labor_cost": 0,
		"pump_cost": 0,
		"other_cost": 0,
		"fish_revenue": game_state.fish_income,
		"transfer_revenue": game_state.transfer_income,
		"one_net_revenue": game_state.one_net_income,
		"other_income": 0,
		"money_after_settlement": game_state.cash,
		"catch_details": game_state.catch_details.duplicate(true)
	}))

	var payload := {
		"version": SETTLEMENT_HISTORY_VERSION,
		"records": records
	}
	var file := FileAccess.open(SETTLEMENT_HISTORY_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("无法写入包塘记录：%s" % SETTLEMENT_HISTORY_PATH)
		return false
	file.store_string(JSON.stringify(payload))
	file.close()
	game_state.settlement_recorded = true
	return true

static func load_settlement_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	if not FileAccess.file_exists(SETTLEMENT_HISTORY_PATH):
		return records

	var file := FileAccess.open(SETTLEMENT_HISTORY_PATH, FileAccess.READ)
	if file == null:
		return records
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return records

	var payload := parsed as Dictionary
	var version := int(payload.get("version", 0))
	if version < 1 or version > SETTLEMENT_HISTORY_VERSION:
		return records
	var saved_records: Variant = payload.get("records", [])
	if saved_records is Array:
		for record_variant in saved_records:
			if record_variant is Dictionary:
				records.append(normalize_settlement_record(Dictionary(record_variant)))
	return records

static func normalize_settlement_record(source: Dictionary) -> Dictionary:
	# Version 1 used shorter field names. Normalize every record before the UI sees it,
	# then calculate all totals from the canonical line items below.
	var record := source.duplicate(true)
	var timestamp := str(record.get("timestamp", record.get("settled_at", "")))
	var timestamp_unix := int(record.get("timestamp_unix", record.get("settled_at_unix", 0)))
	var day := maxi(1, int(record.get("day", 1)))
	var record_id := str(record.get("record_id", ""))
	if record_id.is_empty():
		record_id = "%d-%d" % [day, timestamp_unix]

	var catch_details: Array = []
	var saved_catch_details: Variant = record.get("catch_details", [])
	if saved_catch_details is Array:
		catch_details = saved_catch_details.duplicate(true)

	var normalized := {
		"record_id": record_id,
		"day": day,
		"timestamp": timestamp,
		"timestamp_unix": timestamp_unix,
		"pond_name": str(record.get("pond_name", "未知鱼塘")),
		"finish_method": _normalize_finish_method(str(record.get("finish_method", record.get("settlement_title", "本局结算")))),
		"contract_cost": int(record.get("contract_cost", record.get("quote_price", 0))),
		"inspection_cost": int(record.get("inspection_cost", 0)),
		"fishing_cost": int(record.get("fishing_cost", record.get("work_cost", 0))),
		"transport_cost": int(record.get("transport_cost", 0)),
		"labor_cost": int(record.get("labor_cost", 0)),
		"pump_cost": int(record.get("pump_cost", 0)),
		"other_cost": int(record.get("other_cost", 0)),
		"fish_revenue": int(record.get("fish_revenue", record.get("fish_income", 0))),
		"transfer_revenue": int(record.get("transfer_revenue", record.get("transfer_income", 0))),
		"one_net_revenue": int(record.get("one_net_revenue", record.get("one_net_income", 0))),
		"other_income": int(record.get("other_income", 0)),
		"money_after_settlement": int(record.get("money_after_settlement", record.get("cash_after", 0))),
		"result_name": str(record.get("result_name", "")),
		"result_description": str(record.get("result_description", "")),
		"catch_details": catch_details
	}

	var total_income := (
		int(normalized["fish_revenue"])
		+ int(normalized["transfer_revenue"])
		+ int(normalized["one_net_revenue"])
		+ int(normalized["other_income"])
	)
	var total_expense := (
		int(normalized["contract_cost"])
		+ int(normalized["inspection_cost"])
		+ int(normalized["fishing_cost"])
		+ int(normalized["transport_cost"])
		+ int(normalized["labor_cost"])
		+ int(normalized["pump_cost"])
		+ int(normalized["other_cost"])
	)
	normalized["total_income"] = total_income
	normalized["total_expense"] = total_expense
	normalized["net_profit"] = total_income - total_expense
	return normalized

static func _normalize_finish_method(method: String) -> String:
	if method == "转包结算":
		return "转包脱手"
	return method
