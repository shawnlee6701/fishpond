extends RefCounted
class_name UIController

const POND_LIST_SCENE := preload("res://scenes/PondList.tscn")
const POND_DETAIL_SCENE := preload("res://scenes/PondDetail.tscn")
const AFTER_CONTRACT_CHOICE_SCENE := preload("res://scenes/AfterContractChoice.tscn")

static func replace_screen(container: Control, next_screen: Control) -> void:
	for child in container.get_children():
		child.queue_free()

	container.add_child(next_screen)
	next_screen.set_anchors_preset(Control.PRESET_FULL_RECT)

static func show_pond_list(container: Control, game_state: GameState) -> void:
	var screen := POND_LIST_SCENE.instantiate()
	screen.setup(game_state, container)
	replace_screen(container, screen)

static func show_pond_detail(container: Control, game_state: GameState, pond: Dictionary) -> void:
	game_state.reset_round()
	var screen := POND_DETAIL_SCENE.instantiate()
	screen.setup(game_state, container, pond)
	replace_screen(container, screen)

static func show_after_contract_choice(container: Control, game_state: GameState) -> void:
	var screen := AFTER_CONTRACT_CHOICE_SCENE.instantiate()
	screen.setup(game_state, container)
	replace_screen(container, screen)
