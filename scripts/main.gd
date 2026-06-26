extends Control

const UIKit := preload("res://scripts/ui_kit.gd")
const SaveSystem := preload("res://scripts/save_system.gd")

@onready var home_screen: Control = $HomeScreen
@onready var screen_container: Control = $ScreenContainer
@onready var title_label: Label = $HomeScreen/SafeArea/PageLayout/TopArea/TitleSignCenter/TitleSign/TitleLabel
@onready var subtitle_strip: PanelContainer = $HomeScreen/SafeArea/PageLayout/TopArea/SubtitleStrip
@onready var subtitle_label: Label = $HomeScreen/SafeArea/PageLayout/TopArea/SubtitleStrip/SubtitleLabel
@onready var hint_strip: PanelContainer = $HomeScreen/SafeArea/PageLayout/MainVisualArea/HintStrip
@onready var hint_label: Label = $HomeScreen/SafeArea/PageLayout/MainVisualArea/HintStrip/HintLabel
@onready var continue_button: Button = $HomeScreen/SafeArea/PageLayout/BottomActionCenter/BottomActionArea/ContinueButton
@onready var restart_button: Button = $HomeScreen/SafeArea/PageLayout/BottomActionCenter/BottomActionArea/RestartButton

const BUTTON_PRIMARY_TEXTURE := preload("res://assets/buttons/button_primary.png")

var game_state: GameState = GameState.new()


func _ready() -> void:
	continue_button.text = "接着干" if SaveSystem.has_checkpoint() else "出门看塘"
	UIKit.apply_root(self)
	_apply_home_styles.call_deferred()
	continue_button.pressed.connect(_on_continue_pressed)
	restart_button.pressed.connect(_on_restart_pressed)


func _apply_home_styles() -> void:
	title_label.add_theme_color_override("font_color", Color("2E200E"))
	title_label.add_theme_color_override("font_outline_color", Color("F5D98B"))
	title_label.add_theme_constant_override("outline_size", 4)

	subtitle_strip.add_theme_stylebox_override("panel", _make_rough_paper_style(false))
	subtitle_label.add_theme_color_override("font_color", Color("2E200E"))
	subtitle_label.add_theme_color_override("font_outline_color", Color("000000"))
	subtitle_label.add_theme_constant_override("outline_size", 2)

	hint_strip.add_theme_stylebox_override("panel", _make_rough_paper_style(true))
	hint_label.add_theme_color_override("font_color", Color("2E200E"))
	hint_label.add_theme_color_override("font_outline_color", Color("000000"))
	hint_label.add_theme_constant_override("outline_size", 2)

	_style_home_button(continue_button, BUTTON_PRIMARY_TEXTURE, Color("2E200E"), true)
	_style_secondary_button(restart_button)


func _style_home_button(button: Button, texture: Texture2D, font_color: Color, is_primary: bool) -> void:
	button.add_theme_stylebox_override("normal", _make_texture_style(texture))
	button.add_theme_stylebox_override("hover", _make_texture_style(texture))
	button.add_theme_stylebox_override("pressed", _make_texture_style(texture))
	button.add_theme_stylebox_override("disabled", _make_texture_style(texture))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color(0.74, 0.74, 0.66, 1.0))
	button.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.03, 0.85))
	button.add_theme_constant_override("outline_size", 4 if is_primary else 2)


func _style_secondary_button(button: Button) -> void:
	var normal := _make_rough_paper_style(false)
	normal.bg_color = Color("3A6E54")
	normal.border_color = Color("2F6B4F")
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(6)
	var hover := _make_rough_paper_style(false)
	hover.bg_color = Color("438064")
	hover.border_color = Color("348C6A")
	hover.set_border_width_all(3)
	hover.set_corner_radius_all(6)
	var pressed := _make_rough_paper_style(false)
	pressed.bg_color = Color("2E5A46")
	pressed.border_color = Color("2F6B4F")
	pressed.set_border_width_all(3)
	pressed.set_corner_radius_all(6)
	var disabled := _make_rough_paper_style(false)
	disabled.bg_color = Color("4A8264")
	disabled.border_color = Color("3E7056")
	disabled.set_border_width_all(2)
	disabled.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var font_color := Color("E8D59E")
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_disabled_color", Color(0.74, 0.74, 0.66, 1.0))
	button.add_theme_color_override("font_outline_color", Color("000000"))
	button.add_theme_constant_override("outline_size", 3)


func _make_rough_paper_style(wide: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("E8D59E", 0.86)
	style.border_color = Color("2E200E")
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	style.content_margin_left = 26.0 if wide else 24.0
	style.content_margin_top = 12.0
	style.content_margin_right = 26.0 if wide else 24.0
	style.content_margin_bottom = 14.0
	style.anti_aliasing = false
	return style


func _make_texture_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	var patch := 20
	style.texture_margin_left = patch
	style.texture_margin_top = patch
	style.texture_margin_right = patch
	style.texture_margin_bottom = patch
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return style


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
