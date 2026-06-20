extends Control

const PondGeneratorScript := preload("res://scripts/pond_generator.gd")
const UIKit := preload("res://scripts/ui_kit.gd")

@onready var title_label: Label = $Panel/Margin/Content/Title
@onready var status_label: Label = $Panel/Margin/Content/StatusLabel
@onready var panel: PanelContainer = $Panel
@onready var card_list: VBoxContainer = $Panel/Margin/Content/Scroll/CardList

var game_state: GameState
var screen_container: Control

func setup(next_game_state: GameState, next_screen_container: Control) -> void:
	game_state = next_game_state
	screen_container = next_screen_container

func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()

	_apply_ui_frame()
	_render_ponds()

func _apply_ui_frame() -> void:
	UIKit.apply_root(self)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	UIKit.style_page_title(title_label)
	UIKit.style_top_status(status_label)
	card_list.add_theme_constant_override("separation", 18)

func _render_ponds() -> void:
	if game_state.daily_ponds_day != game_state.day or game_state.daily_ponds.is_empty():
		var generator := PondGeneratorScript.new()
		game_state.daily_ponds = generator.generate_daily_ponds(game_state.day, game_state.cash)
		game_state.daily_ponds_day = game_state.day

	var ponds := game_state.daily_ponds
	status_label.text = UIKit.format_run_status(game_state.day, game_state.cash)

	for child in card_list.get_children():
		child.queue_free()

	for pond in ponds:
		card_list.add_child(_create_pond_card(pond))

func _create_pond_card(pond: Dictionary) -> Control:
	var card := Control.new()
	card.custom_minimum_size = Vector2(0, 540)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var background := PanelContainer.new()
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_theme_stylebox_override("panel", _make_pond_card_style(pond))
	card.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	card.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 54
	margin.offset_top = 44
	margin.offset_right = -54
	margin.offset_bottom = -32

	var content := VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 8)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(content)

	var title := UIKit.make_label(str(pond["name"]), 38, UIKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.custom_minimum_size = Vector2(0, 48)
	content.add_child(title)

	var tag_row := HBoxContainer.new()
	tag_row.add_theme_constant_override("separation", 12)
	tag_row.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(tag_row)
	tag_row.add_child(_make_card_tag(str(pond["pond_type_name"]), Color(0.58, 0.34, 0.12, 1.0)))
	tag_row.add_child(_make_card_tag(str(pond["area_label"]), Color(0.66, 0.40, 0.17, 1.0)))
	tag_row.add_child(_make_card_tag("%s水" % str(pond["depth_label"]), Color(0.76, 0.56, 0.25, 1.0)))

	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 20)
	content.add_child(info_row)

	var info := Label.new()
	info.text = "塘龄：%s（%d 年）" % [pond["age_label"], pond["age_years"]]
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", UIKit.FONT_BODY)
	info.add_theme_color_override("font_color", UIKit.INK)
	info_row.add_child(info)

	var depth := Label.new()
	depth.text = "水深：%.1f 米" % float(pond["depth_meters"])
	depth.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	depth.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	depth.add_theme_font_size_override("font_size", UIKit.FONT_BODY)
	depth.add_theme_color_override("font_color", UIKit.INK)
	info_row.add_child(depth)

	var water := Label.new()
	water.text = "水色：%s" % pond["water_state"]
	water.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	water.add_theme_font_size_override("font_size", UIKit.FONT_BODY)
	water.add_theme_color_override("font_color", UIKit.INK)
	content.add_child(water)

	var rumor := Label.new()
	rumor.text = "“%s”" % pond["rumor"]
	rumor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rumor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rumor.add_theme_font_size_override("font_size", UIKit.FONT_SECONDARY)
	rumor.add_theme_color_override("font_color", UIKit.MUTED)
	content.add_child(rumor)

	var view_button := Button.new()
	view_button.name = "ViewButton"
	view_button.text = "进塘验货"
	view_button.custom_minimum_size = Vector2(540, 76)
	UIKit.style_button(view_button, "primary")
	view_button.pressed.connect(_on_view_pressed.bind(pond))
	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_child(view_button)
	content.add_child(button_row)

	var quote_badge := _make_quote_badge(int(pond["quote_price"]))
	card.add_child(quote_badge)
	quote_badge.anchor_left = 1.0
	quote_badge.anchor_right = 1.0
	quote_badge.offset_left = -270
	quote_badge.offset_top = 30
	quote_badge.offset_right = -38
	quote_badge.offset_bottom = 92

	return card

func _make_card_tag(text: String, color: Color) -> PanelContainer:
	var tag := PanelContainer.new()
	tag.custom_minimum_size = Vector2(0, 44)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag.add_theme_stylebox_override("panel", UIKit.make_style(color, Color(0.48, 0.29, 0.11, 0.55), 18, 1, false))
	var label := UIKit.make_label(text, 24, UIKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.add_child(label)
	return tag

func _make_quote_badge(quote_price: int) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override(
		"panel",
		UIKit.make_style(Color(0.70, 0.10, 0.065, 1.0), Color(0.96, 0.62, 0.18, 1.0), 12, 3, true)
	)
	var label := UIKit.make_label("要价 %d 元" % quote_price, 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(label)
	return badge

func _make_pond_card_style(pond: Dictionary) -> StyleBoxFlat:
	return UIKit.make_style(
		Color(0.98, 0.92, 0.76, 0.96),
		_get_pond_accent(pond),
		22,
		3,
		true
	)

func _get_pond_accent(pond: Dictionary) -> Color:
	match str(pond.get("pond_type", pond.get("pond_type_id", ""))):
		"artificial_pond":
			return UIKit.GREEN_LIGHT
		"old_pond":
			return UIKit.GOLD
		"reservoir_pond":
			return Color(0.16, 0.44, 0.56, 1.0)
		_:
			return UIKit.GREEN

func _on_view_pressed(pond: Dictionary) -> void:
	UIController.show_pond_detail(screen_container, game_state, pond)
