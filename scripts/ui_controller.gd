extends RefCounted
class_name UIController

const POND_LIST_SCENE := preload("res://scenes/PondList.tscn")
const POND_DETAIL_SCENE := preload("res://scenes/PondDetail.tscn")
const AFTER_CONTRACT_CHOICE_SCENE := preload("res://scenes/AfterContractChoice.tscn")
const SETTLEMENT_SCENE := preload("res://scenes/Settlement.tscn")
const SETTLEMENT_HISTORY_SCENE := preload("res://scenes/SettlementHistory.tscn")
const SaveSystem := preload("res://scripts/save_system.gd")
const UIKit := preload("res://scripts/ui_kit.gd")

static func replace_screen(container: Control, next_screen: Control) -> void:
	for child in container.get_children():
		child.queue_free()

	container.add_child(next_screen)
	next_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	UIKit.animate_page_entry(next_screen, 1.0)


static func show_pond_list(container: Control, game_state: GameState, save_checkpoint := false) -> void:
	var screen := POND_LIST_SCENE.instantiate()
	screen.setup(game_state, container)
	replace_screen(container, screen)
	if save_checkpoint:
		SaveSystem.save_checkpoint(game_state)

static func show_pond_detail(container: Control, game_state: GameState, pond: Dictionary) -> void:
	if str(game_state.current_pond.get("id", "")) != str(pond.get("id", "")):
		game_state.reset_round()
		game_state.current_pond = pond
	var screen := POND_DETAIL_SCENE.instantiate()
	screen.setup(game_state, container, pond)
	replace_screen(container, screen)

static func show_after_contract_choice(container: Control, game_state: GameState, play_contract_entry_animation := false) -> void:
	var screen := AFTER_CONTRACT_CHOICE_SCENE.instantiate()
	screen.setup(game_state, container, play_contract_entry_animation)
	replace_screen(container, screen)

static func show_settlement(container: Control, game_state: GameState) -> void:
	var screen := SETTLEMENT_SCENE.instantiate()
	if screen.has_method("setup"):
		screen.setup(game_state, container)
	replace_screen(container, screen)

static func show_settlement_history(container: Control, game_state: GameState) -> void:
	var screen := SETTLEMENT_HISTORY_SCENE.instantiate()
	screen.setup(game_state, container)
	replace_screen(container, screen)
