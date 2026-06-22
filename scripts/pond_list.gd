extends Control

const PondGeneratorScript := preload("res://scripts/pond_generator.gd")
const PondThumbPlaceholderScript := preload("res://scripts/pond_thumb_placeholder.gd")

@onready var day_label: Label = $SafeArea/PageLayout/TopStatusBar/StatusRow/DayLabel
@onready var money_label: Label = $SafeArea/PageLayout/TopStatusBar/StatusRow/MoneyLabel
@onready var record_button: Button = $SafeArea/PageLayout/TopStatusBar/StatusRow/RecordButton
@onready var hint_label: Label = $SafeArea/PageLayout/PageHeader/HintLabel
@onready var pond_list_container: VBoxContainer = $SafeArea/PageLayout/PondListScroll/PondListContainer

var game_state: GameState
var screen_container: Control


func setup(next_game_state: GameState, next_screen_container: Control) -> void:
	game_state = next_game_state
	screen_container = next_screen_container


func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()

	hint_label.modulate = Color(1.0, 1.0, 1.0, 0.68)
	record_button.pressed.connect(_on_history_pressed)
	_render_ponds()


func _render_ponds() -> void:
	if game_state.daily_ponds_day != game_state.day or game_state.daily_ponds.is_empty():
		var generator := PondGeneratorScript.new()
		game_state.daily_ponds = generator.generate_daily_ponds(game_state.day, game_state.cash)
		game_state.daily_ponds_day = game_state.day

	day_label.text = "第 %d 天" % game_state.day
	money_label.text = "本钱：%d 元" % game_state.cash

	for child in pond_list_container.get_children():
		child.queue_free()

	var card_models := _build_card_models(game_state.daily_ponds)
	for model in card_models:
		pond_list_container.add_child(_create_pond_card(model))

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
			"source_pond": pond,
		})
	return models


func _create_pond_card(model: Dictionary) -> Control:
	var pond_card := MarginContainer.new()
	pond_card.name = "PondCard"
	pond_card.set_meta("component", "PondCard")
	pond_card.custom_minimum_size = Vector2(0, 500)
	pond_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Future art slot: CardBg can be replaced by the pond card background texture.
	var card_bg := PanelContainer.new()
	card_bg.name = "CardBg"
	card_bg.theme_type_variation = &"PondCardPanel"
	card_bg.set_meta("future_texture", "pond_card_bg_xxx.png")
	pond_card.add_child(card_bg)

	var content_row := HBoxContainer.new()
	content_row.name = "ContentRow"
	content_row.add_theme_constant_override("separation", 26)
	card_bg.add_child(content_row)

	content_row.add_child(_create_pond_thumb())

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

	# Future art slot: PriceBadge can be replaced by a price-board texture.
	var price_badge := Label.new()
	price_badge.name = "PriceBadge"
	price_badge.text = "要价 %d 元" % int(model["price"])
	price_badge.custom_minimum_size = Vector2(230, 66)
	price_badge.theme_type_variation = &"PondPriceWarningLabel" if not bool(model["can_afford"]) else &"PondPriceLabel"
	price_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_badge.set_meta("future_texture", "price_badge_xxx.png")
	header_row.add_child(price_badge)

	var tag_row := HBoxContainer.new()
	tag_row.name = "TagRow"
	tag_row.add_theme_constant_override("separation", 10)
	info_area.add_child(tag_row)
	for index in Array(model["tags"]).size():
		var chip := _create_chip(str(Array(model["tags"])[index]))
		chip.name = "Tag%d" % (index + 1)
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
	rumor.text = "江湖传闻  “%s”" % str(model["rumor"])
	rumor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rumor.theme_type_variation = &"PondRumorLabel"
	rumor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rumor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rumor.modulate = Color(1.0, 1.0, 1.0, 0.76)
	info_area.add_child(rumor)

	# Future art slot: ActionButton can be replaced by a TextureButton.
	var action_button := Button.new()
	action_button.name = "ViewButton"
	action_button.text = "进塘验货" if bool(model["can_afford"]) else "钱不够"
	action_button.custom_minimum_size = Vector2(0, 82)
	action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_button.theme_type_variation = &"PondActionButton"
	action_button.disabled = not bool(model["can_afford"])
	action_button.set_meta("future_texture", "pond_action_button_xxx.png")
	if not action_button.disabled:
		action_button.pressed.connect(_on_view_pressed.bind(Dictionary(model["source_pond"])))
	info_area.add_child(action_button)

	return pond_card


func _create_pond_thumb() -> PanelContainer:
	# Future art slot: replace this native placeholder with pond_thumb_xxx.png.
	var thumb_slot := PanelContainer.new()
	thumb_slot.name = "PondThumbPlaceholder"
	thumb_slot.custom_minimum_size = Vector2(224, 0)
	thumb_slot.theme_type_variation = &"PondThumbPanel"
	thumb_slot.set_meta("future_texture", "pond_thumb_xxx.png")
	thumb_slot.tooltip_text = "鱼塘缩略图预留位"

	var drawing := PondThumbPlaceholderScript.new()
	# Compatibility name for smoke checks; this is a drawn pond, never an X marker.
	drawing.name = "ImagePlaceholder"
	drawing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drawing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb_slot.add_child(drawing)
	return thumb_slot


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
