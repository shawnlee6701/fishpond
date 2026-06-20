extends RefCounted
class_name FishPoolSaveSystem

const SAVE_PATH := "user://save_game.json"
const SAVE_VERSION := 1

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
