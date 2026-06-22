extends Control

const UIKit := preload("res://scripts/ui_kit.gd")
const SaveSystem := preload("res://scripts/save_system.gd")

@onready var home_screen: Control = $HomeScreen
@onready var screen_container: Control = $ScreenContainer
@onready var title_sign_shadow: Panel = $HomeScreen/SafeArea/PageLayout/TopArea/TitleSignCenter/TitleSign/TitleSignShadow
@onready var title_sign_bg: Panel = $HomeScreen/SafeArea/PageLayout/TopArea/TitleSignCenter/TitleSign/TitleSignBg
@onready var title_label: Label = $HomeScreen/SafeArea/PageLayout/TopArea/TitleSignCenter/TitleSign/TitleLabel
@onready var subtitle_label: Label = $HomeScreen/SafeArea/PageLayout/TopArea/SubtitleLabel
@onready var hint_label: Label = $HomeScreen/SafeArea/PageLayout/MainVisualArea/HintLabel
@onready var continue_button: Button = $HomeScreen/SafeArea/PageLayout/BottomActionCenter/BottomActionArea/ContinueButton
@onready var restart_button: Button = $HomeScreen/SafeArea/PageLayout/BottomActionCenter/BottomActionArea/RestartButton

var game_state: GameState = GameState.new()


func _ready() -> void:
	continue_button.text = "继续包塘" if SaveSystem.has_checkpoint() else "开始包塘"
	UIKit.apply_root(self)
	# UIRoot applies the shared theme after child _ready() calls, so apply homepage-only
	# graybox styles deferred. These are replaceable presentation slots, not gameplay logic.
	_apply_home_styles.call_deferred()
	continue_button.pressed.connect(_on_continue_pressed)
	restart_button.pressed.connect(_on_restart_pressed)


func _apply_home_styles() -> void:
	# Future art replacement: swap TitleSignBg for title_sign.png.
	title_sign_shadow.add_theme_stylebox_override(
		"panel", UIKit.make_style(Color(0.08, 0.07, 0.04, 0.46), Color(0.08, 0.07, 0.04, 0.0), 24, 0)
	)
	title_sign_bg.add_theme_stylebox_override(
		"panel", UIKit.make_style(Color("D5A94D"), Color("4A321C"), 24, 6, true)
	)
	title_label.add_theme_color_override("font_color", Color("38240F"))
	title_label.add_theme_color_override("font_outline_color", Color("F5D98B"))
	title_label.add_theme_constant_override("outline_size", 4)
	subtitle_label.add_theme_color_override("font_color", Color("F7EAC5"))
	subtitle_label.add_theme_color_override("font_outline_color", Color(0.08, 0.16, 0.11, 0.9))
	subtitle_label.add_theme_constant_override("outline_size", 4)
	hint_label.add_theme_color_override("font_color", Color("E9E1C1"))
	hint_label.add_theme_color_override("font_outline_color", Color(0.08, 0.16, 0.11, 0.9))
	hint_label.add_theme_constant_override("outline_size", 3)

	# Future art replacement: use button_primary.png for ContinueButton.
	_style_home_button(continue_button, true)
	# Future art replacement: use button_secondary.png for RestartButton.
	_style_home_button(restart_button, false)


func _style_home_button(button: Button, primary: bool) -> void:
	var normal := Color("E4B940") if primary else Color(0.12, 0.27, 0.20, 0.92)
	var hover := Color("F1CD5B") if primary else Color(0.16, 0.34, 0.25, 0.96)
	var pressed := Color("C79627") if primary else Color(0.08, 0.22, 0.16, 1.0)
	var border := Color("4A321C") if primary else Color("B7C9A8")
	var font := Color("2E200E") if primary else Color("E8E2C8")
	var border_width := 5 if primary else 3
	var radius := 20 if primary else 16

	button.add_theme_stylebox_override("normal", UIKit.make_style(normal, border, radius, border_width, primary))
	button.add_theme_stylebox_override("hover", UIKit.make_style(hover, border, radius, border_width, primary))
	button.add_theme_stylebox_override("pressed", UIKit.make_style(pressed, border, radius, border_width, false))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.16) if primary else Color(0, 0, 0, 0.55))
	button.add_theme_constant_override("outline_size", 2)


func _on_continue_pressed() -> void:
	_open_game(true)


func _on_restart_pressed() -> void:
	_open_game(false)


func _open_game(continue_existing: bool) -> void:
	game_state = GameState.new()
	if continue_existing:
		SaveSystem.load_checkpoint(game_state)
	else:
		SaveSystem.clear_checkpoint()

	home_screen.visible = false
	screen_container.visible = true
	UIController.show_pond_list(screen_container, game_state, true)
