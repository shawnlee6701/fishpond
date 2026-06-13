extends Control

const POND_LIST_SCENE := preload("res://scenes/PondList.tscn")

@onready var main_menu: Control = $MainMenu
@onready var screen_container: Control = $ScreenContainer
@onready var cash_label: Label = $MainMenu/Content/Stats/CashLabel
@onready var day_label: Label = $MainMenu/Content/Stats/DayLabel
@onready var go_pond_button: Button = $MainMenu/Content/GoPondButton

var game_state := GameState.new()

func _ready() -> void:
	_update_stats()
	go_pond_button.pressed.connect(_on_go_pond_pressed)

func _update_stats() -> void:
	cash_label.text = "当前现金：%d 元" % game_state.cash
	day_label.text = "当前天数：第 %d 天" % game_state.day

func _on_go_pond_pressed() -> void:
	main_menu.visible = false
	screen_container.visible = true
	UIController.replace_screen(screen_container, POND_LIST_SCENE.instantiate())
