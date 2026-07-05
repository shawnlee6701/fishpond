extends Control

const UIKit := preload("res://scripts/ui_kit.gd")
const DataLoaderScript := preload("res://scripts/data_loader.gd")
const InspectionSystemScript := preload("res://scripts/inspection_system.gd")

const CARD_NAMES := {
	"observe": "InspectionOptionCard_MianCe",
	"fish_finder": "InspectionOptionCard_TanYu",
	"master": "InspectionOptionCard_LaoShiFu"
}

const INSPECTION_CARD_TEXTURES: Dictionary[String, Texture2D] = {
	"observe": preload("res://assets/ui/inspection_method_card_observe.png"),
	"fish_finder": preload("res://assets/ui/inspection_method_card_fish_finder.png"),
	"master": preload("res://assets/ui/inspection_method_card_master.png")
}

const INSPECTION_COST_BADGE_TEXTURE: Texture2D = preload("res://assets/ui/inspection_cost_badge.png")
const INSPECTION_USED_BADGE_TEXTURE: Texture2D = preload("res://assets/ui/inspection_used_badge.png")
const BALANCE_HIGHLIGHT_BG_TEXTURE: Texture2D = preload("res://assets/ui/balance_highlight_bg.png")
const STATUS_BOX_BG_TEXTURE: Texture2D = preload("res://assets/ui/status_box_bg.png")
const PRICE_BADGE_TEXTURE: Texture2D = preload("res://assets/ui/price_badge.png")
const BUTTON_SECONDARY_TEXTURE: Texture2D = preload("res://assets/buttons/button_secondary.png")
const POND_ACTION_BUTTON_TEXTURE: Texture2D = preload("res://assets/buttons/pond_action_button.png")
const OWNED_POND_CARD_BG_TEXTURE: Texture2D = preload("res://assets/ui/owned_pond_card_bg.png")

@onready var top_status_bar: PanelContainer = $SafeArea/PageLayout/TopStatusBar
@onready var day_label: Label = $SafeArea/PageLayout/TopStatusBar/StatusRow/DayLabel
@onready var money_label: Label = $SafeArea/PageLayout/TopStatusBar/StatusRow/MoneyLabel
@onready var inspection_cost_label: Label = $SafeArea/PageLayout/TopStatusBar/StatusRow/InspectionCostLabel
@onready var pond_name_label: Label = $SafeArea/PageLayout/ContentScroll/Content/PondSummaryCard/SummaryContent/HeaderRow/PondNameLabel
@onready var price_badge: Label = $SafeArea/PageLayout/ContentScroll/Content/PondSummaryCard/SummaryContent/HeaderRow/PriceBadge
@onready var tag_row: HBoxContainer = $SafeArea/PageLayout/ContentScroll/Content/PondSummaryCard/SummaryContent/TagRow
@onready var known_info_grid: GridContainer = $SafeArea/PageLayout/ContentScroll/Content/PondSummaryCard/SummaryContent/KnownInfoGrid
@onready var risk_hint_label: Label = $SafeArea/PageLayout/ContentScroll/Content/PondSummaryCard/SummaryContent/RiskHintLabel
@onready var content_scroll: ScrollContainer = $SafeArea/PageLayout/ContentScroll
@onready var pond_summary_card: PanelContainer = $SafeArea/PageLayout/ContentScroll/Content/PondSummaryCard
@onready var inspection_cards: VBoxContainer = $SafeArea/PageLayout/ContentScroll/Content/InspectionSection/InspectionCards
@onready var decision_summary_card: PanelContainer = $SafeArea/PageLayout/ContentScroll/Content/DecisionSummaryCard
@onready var summary_numbers_label: Label = $SafeArea/PageLayout/ContentScroll/Content/DecisionSummaryCard/Summary/SummaryNumbersLabel
@onready var reserve_hint_label: Label = $SafeArea/PageLayout/ContentScroll/Content/DecisionSummaryCard/Summary/ReserveHintLabel
@onready var bottom_decision_bar: PanelContainer = $SafeArea/PageLayout/BottomDecisionBar
@onready var give_up_button: Button = $SafeArea/PageLayout/BottomDecisionBar/DecisionButtons/GiveUpButton
@onready var commit_button: Button = $SafeArea/PageLayout/BottomDecisionBar/DecisionButtons/CommitButton

var game_state: GameState
var screen_container: Control
var pond: Dictionary = {}
var tools: Array = []
var inspection_system := InspectionSystemScript.new()


func setup(next_game_state: GameState, next_screen_container: Control, next_pond: Dictionary = {}) -> void:
	game_state = next_game_state
	screen_container = next_screen_container
	pond = next_pond


func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()
	if pond.is_empty():
		pond = game_state.current_pond

	tools = DataLoaderScript.load_json(DataLoaderScript.TOOLS_PATH, [])
	_apply_texture_panel_bg(top_status_bar, BALANCE_HIGHLIGHT_BG_TEXTURE, 14, 20)
	_apply_texture_panel_bg(pond_summary_card, OWNED_POND_CARD_BG_TEXTURE, 24, 24)
	_apply_texture_label_bg(price_badge, PRICE_BADGE_TEXTURE, 14, 4, 16)
	decision_summary_card.add_theme_stylebox_override("panel", UIKit.make_translucent_readability_panel(0.82))
	_apply_texture_panel_bg(bottom_decision_bar, STATUS_BOX_BG_TEXTURE, 16, 20)
	UIKit.apply_texture_button(give_up_button, BUTTON_SECONDARY_TEXTURE)
	UIKit.apply_texture_button(commit_button, POND_ACTION_BUTTON_TEXTURE)
	UIKit.set_scrollbar_auto_hide(content_scroll)
	_render_page()
	give_up_button.pressed.connect(_on_give_up_pressed)
	commit_button.pressed.connect(_on_commit_pressed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _render_page() -> void:
	_render_status()
	_render_pond_summary()
	_render_inspection_cards()
	_render_decision_summary()


func _render_status() -> void:
	day_label.text = "第 %d 天" % game_state.day
	money_label.text = "兜里：%d 元" % game_state.cash
	inspection_cost_label.text = "验塘已花：%d 元" % game_state.inspection_cost_total


func _render_pond_summary() -> void:
	pond_name_label.text = str(pond.get("name", "未选择鱼塘"))
	price_badge.text = "%d 元" % int(pond.get("quote_price", 0))

	_clear_children(tag_row)
	_add_tag(str(pond.get("pond_type_name", "未知塘型")))
	_add_tag(str(pond.get("area_label", "未知大小")))

	_clear_children(known_info_grid)
	_add_info_block("水深", "%s  %.1f 米" % [pond.get("depth_label", "-"), float(pond.get("depth_meters", 0.0))])
	_add_info_block("塘龄", "%d 年" % int(pond.get("age_years", 0)))
	_add_info_block("水色", str(pond.get("water_state", "-")))

	risk_hint_label.text = "镇上有人说：%s\n老手看下来：%s" % [pond.get("rumor", "暂无消息"), pond.get("risk_tag", "暂时看不太透")]


func _add_tag(text: String) -> void:
	var chip := PanelContainer.new()
	chip.theme_type_variation = &"PondTagPanel"
	var label := Label.new()
	label.theme_type_variation = &"PondChipLabel"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(label)
	tag_row.add_child(chip)


func _add_info_block(key_text: String, value_text: String) -> void:
	var block := PanelContainer.new()
	block.name = "%sInfoBlock" % key_text
	block.custom_minimum_size = Vector2(0, 92)
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.theme_type_variation = &"InspectInfoBlockPanel"

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	block.add_child(content)

	var key_label := Label.new()
	key_label.theme_type_variation = &"PondStatKeyLabel"
	key_label.text = key_text
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(key_label)

	var value_label := Label.new()
	value_label.theme_type_variation = &"PondStatValueLabel"
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(value_label)
	known_info_grid.add_child(block)


func _render_inspection_cards() -> void:
	var previous_scroll := content_scroll.scroll_vertical
	_clear_children(inspection_cards)

	for tool_variant in tools:
		var tool := tool_variant as Dictionary
		inspection_cards.add_child(_build_inspection_card(_inspection_option_data(tool)))

	_restore_content_scroll.call_deferred(previous_scroll)


func _inspection_option_data(tool: Dictionary) -> Dictionary:
	var tool_id := str(tool.get("id", ""))
	var is_used := game_state.has_inspection_result(tool_id)
	var result := _decode_inspection_result(game_state.get_inspection_feedback(tool_id)) if is_used else {}
	return {
		"id": tool_id,
		"name": str(tool.get("name", "验塘")),
		"cost": int(tool.get("cost", 0)),
		"short_desc": str(tool.get("short_desc", tool.get("description", "多看一眼塘口情况。"))),
		"is_used": is_used,
		"result_headline": str(result.get("headline", "线索已经记下")),
		"result_detail": str(result.get("detail", "验塘结果已记录。")),
		"can_afford": game_state.can_pay(int(tool.get("cost", 0)))
	}


func _build_inspection_card(option: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var tool_id := str(option.get("id", ""))
	card.name = str(CARD_NAMES.get(tool_id, "InspectionOptionCard_%s" % tool_id))
	card.custom_minimum_size = Vector2(0, 190 if bool(option.get("is_used", false)) else 178)
	card.theme_type_variation = &"InspectionUsedCard" if bool(option.get("is_used", false)) else &"InspectionOptionCard"
	var card_texture: Texture2D = INSPECTION_CARD_TEXTURES.get(tool_id, INSPECTION_CARD_TEXTURES["observe"])
	_apply_texture_panel_bg(card, card_texture, 24, 24)

	var content := VBoxContainer.new()
	content.name = "CardContent"
	content.add_theme_constant_override("separation", 10)
	card.add_child(content)

	var header := HBoxContainer.new()
	header.name = "HeaderRow"
	header.add_theme_constant_override("separation", 14)
	content.add_child(header)

	var method_label := Label.new()
	method_label.name = "MethodNameLabel"
	method_label.theme_type_variation = &"InspectMethodNameLabel"
	method_label.text = str(option.get("name", "验塘"))
	method_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(method_label)

	if bool(option.get("is_used", false)):
		var used_badge := Label.new()
		used_badge.name = "UsedBadge"
		used_badge.theme_type_variation = &"InspectUsedBadge"
		_apply_texture_label_bg(used_badge, INSPECTION_USED_BADGE_TEXTURE, 8, 2, 12)
		used_badge.text = "已验"
		used_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		used_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_child(used_badge)

		var headline := Label.new()
		headline.name = "ResultHeadlineLabel"
		headline.theme_type_variation = &"InspectResultHeadlineLabel"
		headline.text = str(option.get("result_headline", "线索已经记下"))
		headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(headline)

		var detail := Label.new()
		detail.name = "ResultDetailLabel"
		detail.theme_type_variation = &"InspectResultDetailLabel"
		detail.text = str(option.get("result_detail", "验塘结果已记录。"))
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(detail)
	else:
		var cost_badge := Label.new()
		cost_badge.name = "CostBadge"
		cost_badge.theme_type_variation = &"InspectFreeBadge" if int(option.get("cost", 0)) == 0 else &"InspectCostBadge"
		cost_badge.text = "免费" if int(option.get("cost", 0)) == 0 else "%d 元" % int(option.get("cost", 0))
		cost_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_texture_label_bg(cost_badge, INSPECTION_COST_BADGE_TEXTURE, 14, 4, 12)
		header.add_child(cost_badge)

		var desc := Label.new()
		desc.name = "ShortDescLabel"
		desc.theme_type_variation = &"InspectOptionDescLabel"
		desc.text = str(option.get("short_desc", "多看一眼塘口情况。"))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(desc)

		var action := Button.new()
		action.name = "ActionButton"
		action.custom_minimum_size = Vector2(0, 68)
		action.disabled = not bool(option.get("can_afford", true))
		var tool_id_for_label := str(option.get("id", ""))
		if action.disabled:
			action.text = "钱不够"
		elif int(option.get("cost", 0)) == 0:
			action.text = "瞄一眼（免费）"
		elif tool_id_for_label == "fish_finder":
			action.text = "花 %d 元扫一梭子" % int(option.get("cost", 0))
		elif tool_id_for_label == "master":
			action.text = "花 %d 元请老师傅" % int(option.get("cost", 0))
		else:
			action.text = "花 %d 元买线索" % int(option.get("cost", 0))
		UIKit.apply_texture_button(action, POND_ACTION_BUTTON_TEXTURE)
		action.pressed.connect(_on_inspection_pressed.bind(option))
		content.add_child(action)

	return card


func _apply_texture_panel_bg(panel: PanelContainer, texture: Texture2D, margin: int = 24, texture_margin: int = 0) -> void:
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


func _apply_texture_label_bg(label: Label, texture: Texture2D, margin_h: int = 14, margin_v: int = 4, texture_margin: int = 0) -> void:
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


func _on_inspection_pressed(option: Dictionary) -> void:
	var tool_id := str(option.get("id", ""))
	if game_state.has_inspection_result(tool_id):
		return

	var cost := int(option.get("cost", 0))
	if not game_state.pay_inspection_cost(cost):
		_render_page()
		return

	var tool := _find_tool(tool_id)
	var result_data := inspection_system.generate_result_data(tool, pond)
	game_state.set_inspection_result(tool_id, JSON.stringify(result_data))
	_render_page()


func _find_tool(tool_id: String) -> Dictionary:
	for tool_variant in tools:
		var tool := tool_variant as Dictionary
		if str(tool.get("id", "")) == tool_id:
			return tool
	return {"id": tool_id, "name": "验塘", "cost": 0}


func _decode_inspection_result(stored_text: String) -> Dictionary:
	var parsed = JSON.parse_string(stored_text)
	if parsed is Dictionary and parsed.has("headline"):
		return parsed

	var lines := stored_text.split("\n", false)
	if lines.is_empty():
		return {"headline": "线索已经记下", "detail": "验塘结果已记录。"}
	var headline := str(lines[0]).trim_suffix("结果：").strip_edges()
	var details: Array[String] = []
	for index in range(1, lines.size()):
		details.append(str(lines[index]))
	return {
		"headline": headline if not headline.is_empty() else "线索已经记下",
		"detail": " ".join(details) if not details.is_empty() else stored_text
	}


func _render_decision_summary() -> void:
	var preview := game_state.get_contract_preview(pond)
	var quote_price := int(preview.get("quote_price", 0))
	var remaining_cash := int(preview.get("remaining_after_contract", preview.get("remaining_cash", 0)))
	var can_contract := bool(preview.get("can_contract", false))

	summary_numbers_label.text = "验塘已花：%d 元\n塘主开价：%d 元\n包完还剩：%d 元" % [game_state.inspection_cost_total, quote_price, remaining_cash]
	reserve_hint_label.text = "留够开工钱，别让一口塘拖死你。" if can_contract else "包了也没钱开工，这塘先放一放吧。"
	reserve_hint_label.theme_type_variation = &"InspectReserveHintLabel" if can_contract else &"InspectWarningLabel"
	commit_button.text = "包了！给塘主 %d 元" % quote_price
	commit_button.disabled = false


func _on_give_up_pressed() -> void:
	if game_state.inspection_cost_total <= 0:
		_return_to_pond_list()
		return

	_show_global_confirm({
		"title": "这塘不看了？",
		"subtitle": "已花的验塘钱就当交学费了，咱们回去再看别的。",
		"balance_text": "已花验塘费：%d 元" % game_state.inspection_cost_total,
		"body": "已花的验塘费不会退回，确定放弃这口塘吗？",
		"cancel_text": "再看看",
		"confirm_text": "不包了，走",
		"on_confirm": Callable(self, "_return_to_pond_list")
	})


func _on_commit_pressed() -> void:
	var preview := game_state.get_contract_preview(pond)
	_show_global_confirm(_contract_confirm_config(preview))


func _contract_confirm_config(preview: Dictionary) -> Dictionary:
	var current_money := int(preview.get("current_cash", game_state.cash))
	var pond_price := int(preview.get("pond_price", preview.get("quote_price", pond.get("quote_price", 0))))
	var contract_extra_cost := int(preview.get("contract_extra_cost", 0))
	var contract_total_cost := int(preview.get("contract_total_cost", pond_price + contract_extra_cost))
	var inspection_spent := game_state.inspection_cost_total
	var min_working_capital := int(preview.get("min_working_capital", game_state.min_working_capital))
	var recommended_working_capital := int(preview.get("recommended_working_capital", min_working_capital))
	var remaining_after_contract := current_money - contract_total_cost
	var can_contract := remaining_after_contract >= min_working_capital
	var status_type := "ok"
	var status_title := "钱够开工"
	var status_desc := "包是能包，但后面下网、人工、抽水、拉鱼——哪样都要钱。"
	if not can_contract:
		status_type = "bad"
		status_title = "钱不够开工"
		status_desc = "包了也没钱开工，这塘先放一放吧。"
	elif remaining_after_contract < recommended_working_capital:
		status_type = "tight"
		status_title = "稍微有点紧"
		status_desc = "包了也能开工，但账要算紧，后面一步都不能错。"

	return {
		"title": "包塘前再算一卦",
		"subtitle": "留够开工钱，别让一口塘拖死你。",
		"balance_text": "包完还剩：%d 元" % remaining_after_contract,
		"bill_rows": [
			{"name": "CurrentMoneyRow", "label": "兜里", "value": "%d 元" % current_money},
			{"name": "InspectionSpentRow", "label": "已花看塘费", "value": "%d 元（不退）" % inspection_spent, "visible": inspection_spent > 0},
			{"name": "PondPriceRow", "label": "塘主开价", "value": "-%d 元" % pond_price, "negative": true},
			{"name": "ExtraCostRow", "label": "杂费（盖章跑腿）", "value": "-%d 元" % contract_extra_cost, "negative": true, "visible": contract_extra_cost > 0},
			{"name": "TotalContractCostRow", "label": "合计从兜里扣", "value": "-%d 元" % contract_total_cost, "negative": true},
			{"name": "RemainingAfterContractRow", "label": "包完还剩", "value": "%d 元" % remaining_after_contract},
			{"name": "MinWorkingCapitalRow", "label": "开工底线", "value": "%d 元" % min_working_capital}
		],
		"status_type": status_type,
		"status_title": status_title,
		"status_desc": status_desc,
		"warning_text": "承包后还要支付下网、人工、抽水、鱼车等成本。",
		"cancel_text": "再掂量掂量",
		"confirm_text": "干！包了（-%d）" % contract_total_cost if can_contract else "包不了",
		"confirm_disabled": not can_contract,
		"on_confirm": Callable(self, "_on_contract_confirmed")
	}


func _on_contract_confirmed() -> void:
	var preview := game_state.get_contract_preview(pond)
	if not bool(preview.get("can_contract", false)):
		_show_global_confirm(_contract_confirm_config(preview))
		return
	if game_state.contract_pond(pond):
		UIController.show_after_contract_choice(screen_container, game_state, true)


func _show_global_confirm(config: Dictionary) -> void:
	var popup_manager := get_tree().root.get_node_or_null("PopupManager")
	if popup_manager == null or not popup_manager.has_method("show_confirm"):
		push_error("PopupManager autoload is missing; cannot show confirmation dialog.")
		return
	popup_manager.call("show_confirm", config)


func _return_to_pond_list() -> void:
	UIController.show_pond_list(screen_container, game_state)


func _on_viewport_size_changed() -> void:
	pass


func _restore_content_scroll(scroll_value: int) -> void:
	await get_tree().process_frame
	content_scroll.scroll_vertical = scroll_value


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
