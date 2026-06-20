extends Control

const UIKit := preload("res://scripts/ui_kit.gd")
const SaveSystem := preload("res://scripts/save_system.gd")
const BUTTON_BOARD := preload("res://assets/ui/button_board.png")

@onready var main_menu: Control = $MainMenu
@onready var screen_container: Control = $ScreenContainer
@onready var homepage_background: TextureRect = $HomepageBackground
@onready var start_button: Button = $MainMenu/BottomActions/StartButton
@onready var restart_button: Button = $MainMenu/BottomActions/RestartButton

var game_state: GameState = GameState.new()

func _ready() -> void:
	start_button.text = "继续包塘" if SaveSystem.has_checkpoint() else "开始包塘"
	_apply_ui_frame()
	start_button.pressed.connect(_on_start_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

func _apply_ui_frame() -> void:
	UIKit.apply_root(self)
	_style_wood_button(start_button, false)
	_style_wood_button(restart_button, true)

func _style_wood_button(button: Button, secondary: bool) -> void:
	var normal_tint := Color(0.78, 0.73, 0.62, 1.0) if secondary else Color.WHITE
	var hover_tint := Color(0.88, 0.82, 0.68, 1.0) if secondary else Color(1.0, 0.94, 0.80, 1.0)
	button.add_theme_stylebox_override("normal", _make_wood_style(normal_tint))
	button.add_theme_stylebox_override("hover", _make_wood_style(hover_tint))
	button.add_theme_stylebox_override("pressed", _make_wood_style(Color(0.68, 0.63, 0.53, 1.0)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", UIKit.INK)
	button.add_theme_color_override("font_hover_color", UIKit.INK)
	button.add_theme_color_override("font_pressed_color", UIKit.INK)
	button.add_theme_color_override("font_outline_color", Color(0.98, 0.86, 0.61, 0.9))
	button.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.28))
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_constant_override("shadow_offset_x", 1)
	button.add_theme_constant_override("shadow_offset_y", 2)
	button.add_theme_constant_override("h_separation", 18)
	button.add_theme_font_size_override("font_size", 48)

func _make_wood_style(modulate: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = BUTTON_BOARD
	style.texture_margin_left = 150.0
	style.texture_margin_top = 60.0
	style.texture_margin_right = 150.0
	style.texture_margin_bottom = 60.0
	style.modulate_color = modulate
	return style

func _on_start_pressed() -> void:
	_open_game(true)

func _on_restart_pressed() -> void:
	_open_game(false)

func _open_game(continue_existing: bool) -> void:
	game_state = GameState.new()
	if continue_existing:
		SaveSystem.load_checkpoint(game_state)
	else:
		SaveSystem.clear_checkpoint()

	main_menu.visible = false
	homepage_background.visible = false
	screen_container.visible = true
	UIController.show_pond_list(screen_container, game_state, true)
