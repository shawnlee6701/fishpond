extends Control

const UIKit := preload("res://scripts/ui_kit.gd")
const PondGeneratorScript := preload("res://scripts/pond_generator.gd")

const THUMB_TEXTURES := {
	"artificial_pond": preload("res://assets/ponds/pond_thumb_artificial.png"),
	"old_pond": preload("res://assets/ponds/pond_thumb_old.png"),
	"reservoir_pond": preload("res://assets/ponds/pond_thumb_reservoir.png"),
}

const CARD_BG_TEXTURES := {
	"artificial_pond": preload("res://assets/ponds/pond_card_bg_artificial.png"),
	"old_pond": preload("res://assets/ponds/pond_card_bg_old.png"),
	"reservoir_pond": preload("res://assets/ponds/pond_card_bg_reservoir.png"),
}

const PRICE_BADGE_TEXTURE: Texture2D = preload("res://assets/ui/price_badge.png")
const POND_ACTION_BUTTON_TEXTURE: Texture2D = preload("res://assets/buttons/pond_action_button.png")
const BALANCE_HIGHLIGHT_BG_TEXTURE: Texture2D = preload("res://assets/ui/balance_highlight_bg.png")
const BUTTON_SECONDARY_TEXTURE: Texture2D = preload("res://assets/buttons/button_secondary.png")

@onready var top_status_bar: PanelContainer = $SafeArea/PageLayout/TopStatusBar
@onready var day_label: Label = $SafeArea/PageLayout/TopStatusBar/StatusRow/DayLabel
@onready var money_label: Label = $SafeArea/PageLayout/TopStatusBar/StatusRow/MoneyLabel
@onready var record_button: Button = $SafeArea/PageLayout/TopStatusBar/StatusRow/RecordButton
@onready var hint_label: Label = $SafeArea/PageLayout/PageHeader/HintLabel
@onready var pond_list_scroll: ScrollContainer = $SafeArea/PageLayout/PondListScroll
@onready var pond_list_container: VBoxContainer = $SafeArea/PageLayout/PondListScroll/PondListContainer

var game_state: GameState
var screen_container: Control


func _apply_panel_texture(panel: PanelContainer, texture: Texture2D, margin: int = 24, texture_margin: int = 0) -> void:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	if texture_margin > 0:
		style.texture_margin_left = texture_margin
		style.texture_margin_top = texture_margin
		style.texture_margin_right = texture_margin
		style.texture_margin_bottom = texture_margin
	panel.add_theme_stylebox_override("panel", style)


func _apply_label_texture(label: Label, texture: Texture2D, margin_h: int = 14, margin_v: int = 4, texture_margin: int = 0) -> void:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.content_margin_left = margin_h
	style.content_margin_top = margin_v
	style.content_margin_right = margin_h
	style.content_margin_bottom = margin_v
	if texture_margin > 0:
		style.texture_margin_left = texture_margin
		style.texture_margin_top = texture_margin
		style.texture_margin_right = texture_margin
		style.texture_margin_bottom = texture_margin
	label.add_theme_stylebox_override("normal", style)


func _apply_button_texture(button: Button, texture: Texture2D) -> void:
	var patch := 20
	var normal := _make_nine_patch_style(texture, patch, Color(1.0, 1.0, 1.0, 1.0))
	var hover := _make_nine_patch_style(texture, patch, Color(1.12, 1.12, 1.12, 1.0))
	var pressed := _make_nine_patch_style(texture, patch, Color(0.88, 0.88, 0.88, 1.0))
	var disabled := _make_nine_patch_style(texture, patch, Color(0.65, 0.65, 0.65, 0.85))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)


func _make_nine_patch_style(texture: Texture2D, patch: int, modulate: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = modulate
	style.texture_margin_left = patch
	style.texture_margin_top = patch
	style.texture_margin_right = patch
	style.texture_margin_bottom = patch
	return style


func setup(next_game_state: GameState, next_screen_container: Control) -> void:
	game_state = next_game_state
	screen_container = next_screen_container


func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()

	hint_label.modulate = Color(1.0, 1.0, 1.0, 0.68)
	record_button.pressed.connect(_on_history_pressed)
	_apply_panel_texture(top_status_bar, BALANCE_HIGHLIGHT_BG_TEXTURE, 14, 20)
	_apply_button_texture(record_button, BUTTON_SECONDARY_TEXTURE)
	UIKit.set_scrollbar_auto_hide(pond_list_scroll)
	_render_ponds()


func _render_ponds() -> void:
	if game_state.daily_ponds_day != game_state.day or game_state.daily_ponds.is_empty():
		var generator := PondGeneratorScript.new()
		game_state.daily_ponds = generator.generate_daily_ponds(game_state.day, game_state.cash)
		game_state.daily_ponds_day = game_state.day

	day_label.text = "第 %d 天" % game_state.day
	money_label.text = "兜里：%d 元" % game_state.cash

	for child in pond_list_container.get_children():
		child.queue_free()

	var card_models := _build_card_models(game_state.daily_ponds)
	for card_index in range(card_models.size()):
		pond_list_container.add_child(_create_pond_card(card_models[card_index], card_index))

	var bottom_space := Control.new()
	bottom_space.name = "ScrollBottomSpace"
	bottom_space.custom_minimum_size = Vector2(0, 20)
	bottom_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pond_list_container.add_child(bottom_space)


func _build_card_models(pond_list: Array) -> Array[Dictionary]:
	var models: Array[Dictionary] = []
	for raw_pond in pond_list:
		var pond := Dictionary(raw_pond)
		var price := int(pond.get("quote_price", 0))
		models.append({
			"pond_name": str(pond.get("name", "无名塘")),
			"price": price,
			"tags": [
				str(pond.get("pond_type_name", "鱼塘")),
				str(pond.get("area_label", "中塘")),
				str(pond.get("risk_tag", "鱼情不明")),
			],
			"age": "%s · %d 年" % [pond.get("age_label", "新塘"), int(pond.get("age_years", 0))],
			"depth": "%.1f 米" % float(pond.get("depth_meters", 0.0)),
			"water_color": str(pond.get("water_state", "暂未看清")),
			"rumor": str(pond.get("rumor", "附近还没人摸清这塘的底")),
			"can_afford": price <= game_state.cash,
			"pond_type": str(pond.get("pond_type", "artificial_pond")),
			"source_pond": pond,
		})
	return models


func _create_pond_card(model: Dictionary, card_index: int) -> Control:
	var pond_type := str(model.get("pond_type", "artificial_pond"))

	var pond_card := MarginContainer.new()
	pond_card.name = "PondCard_%d" % card_index
	pond_card.set_meta("component", "PondCard")
	pond_card.custom_minimum_size = Vector2(0, 500)
	pond_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var card_bg := PanelContainer.new()
	card_bg.name = "CardBg"
	card_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pond_card.add_child(card_bg)

	var bg_style := StyleBoxTexture.new()
	var bg_texture: Texture2D = CARD_BG_TEXTURES.get(pond_type, CARD_BG_TEXTURES["artificial_pond"])
	bg_style.texture = bg_texture
	var patch := 24
	bg_style.texture_margin_left = patch
	bg_style.texture_margin_top = patch
	bg_style.texture_margin_right = patch
	bg_style.texture_margin_bottom = patch
	card_bg.add_theme_stylebox_override("panel", bg_style)

	var content_margin := MarginContainer.new()
	content_margin.name = "ContentMargin"
	content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_margin.add_theme_constant_override("margin_left", 24)
	content_margin.add_theme_constant_override("margin_top", 22)
	content_margin.add_theme_constant_override("margin_right", 24)
	content_margin.add_theme_constant_override("margin_bottom", 22)
	card_bg.add_child(content_margin)

	var content_row := HBoxContainer.new()
	content_row.name = "ContentRow"
	content_row.add_theme_constant_override("separation", 26)
	content_margin.add_child(content_row)

	content_row.add_child(_create_pond_thumb(pond_type))

	var info_area := VBoxContainer.new()
	info_area.name = "PondInfoArea"
	info_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_area.add_theme_constant_override("separation", 14)
	content_row.add_child(info_area)

	var header_row := HBoxContainer.new()
	header_row.name = "HeaderRow"
	header_row.add_theme_constant_override("separation", 16)
	info_area.add_child(header_row)

	var pond_name := Label.new()
	pond_name.name = "PondNameLabel"
	pond_name.text = str(model["pond_name"])
	pond_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pond_name.theme_type_variation = &"PondNameLabel"
	pond_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pond_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_row.add_child(pond_name)

	var price_badge := Label.new()
	price_badge.name = "PriceBadge"
	price_badge.text = "塘主开价 %d 元" % int(model["price"])
	price_badge.custom_minimum_size = Vector2(230, 66)
	price_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_label_texture(price_badge, PRICE_BADGE_TEXTURE, 10, 4, 16)
	header_row.add_child(price_badge)

	var tag_row := HBoxContainer.new()
	tag_row.name = "TagRow"
	tag_row.add_theme_constant_override("separation", 10)
	info_area.add_child(tag_row)
	for tag_index in Array(model["tags"]).size():
		var chip := _create_chip(str(Array(model["tags"])[tag_index]))
		chip.name = "Tag%d" % (tag_index + 1)
		tag_row.add_child(chip)

	var stat_grid := GridContainer.new()
	stat_grid.name = "StatGrid"
	stat_grid.columns = 3
	stat_grid.add_theme_constant_override("h_separation", 10)
	stat_grid.add_theme_constant_override("v_separation", 8)
	info_area.add_child(stat_grid)
	stat_grid.add_child(_create_stat_block("塘龄", str(model["age"]), "AgeLabel"))
	stat_grid.add_child(_create_stat_block("水深", str(model["depth"]), "DepthLabel"))
	stat_grid.add_child(_create_stat_block("水色", str(model["water_color"]), "WaterLabel"))

	var rumor := Label.new()
	rumor.name = "RumorLabel"
	rumor.text = "镇上有人说  “%s”" % str(model["rumor"])
	rumor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rumor.theme_type_variation = &"PondRumorLabel"
	rumor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rumor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rumor.modulate = Color(1.0, 1.0, 1.0, 0.76)
	info_area.add_child(rumor)

	var action_button := Button.new()
	action_button.name = "ViewButton"
	action_button.text = "进塘看看" if bool(model["can_afford"]) else "钱不够"
	action_button.custom_minimum_size = Vector2(0, 82)
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_button.theme_type_variation = &"PondActionButton"
	_apply_button_texture(action_button, POND_ACTION_BUTTON_TEXTURE)
	action_button.disabled = not bool(model["can_afford"])
	if not action_button.disabled:
		action_button.pressed.connect(_on_view_pressed.bind(Dictionary(model["source_pond"])))
	info_area.add_child(action_button)

	return pond_card


func _create_pond_thumb(pond_type: String) -> TextureRect:
	var thumb := TextureRect.new()
	thumb.name = "PondThumb"
	thumb.custom_minimum_size = Vector2(224, 224)
	thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.texture = THUMB_TEXTURES.get(pond_type, THUMB_TEXTURES["artificial_pond"])
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return thumb


func _create_chip(text: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"PondTagPanel"
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"PondChipLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	chip.add_child(label)
	return chip


func _create_stat_block(title: String, value: String, node_name: String) -> PanelContainer:
	var block := PanelContainer.new()
	block.name = "%sBlock" % node_name
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.theme_type_variation = &"PondStatPanel"

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	block.add_child(stack)

	var key_label := Label.new()
	key_label.text = title
	key_label.theme_type_variation = &"PondStatKeyLabel"
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(key_label)

	var value_label := Label.new()
	value_label.name = node_name
	value_label.text = value
	value_label.theme_type_variation = &"PondStatValueLabel"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(value_label)
	return block


func _on_view_pressed(pond: Dictionary) -> void:
	UIController.show_pond_detail(screen_container, game_state, pond)


func _on_history_pressed() -> void:
	UIController.show_settlement_history(screen_container, game_state)
