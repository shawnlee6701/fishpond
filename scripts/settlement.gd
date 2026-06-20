extends Control

const UIKit := preload("res://scripts/ui_kit.gd")

@onready var title_label: Label = $Panel/Margin/Content/TitleLabel
@onready var detail_label: Label = $Panel/Margin/Content/Scroll/DetailLabel
@onready var cash_label: Label = $CashLabel
@onready var panel: PanelContainer = $Panel
@onready var result_illustration: TextureRect = $Panel/Margin/Content/ResultIllustration
@onready var fish_king_panel: PanelContainer = $Panel/Margin/Content/FishKingPanel
@onready var fish_king_scene_label: Label = $Panel/Margin/Content/FishKingPanel/Margin/Content/SceneLabel
@onready var fish_king_name_label: Label = $Panel/Margin/Content/FishKingPanel/Margin/Content/NameLabel
@onready var fish_king_stats_label: Label = $Panel/Margin/Content/FishKingPanel/Margin/Content/StatsLabel
@onready var fish_king_tagline_label: Label = $Panel/Margin/Content/FishKingPanel/Margin/Content/TaglineLabel
@onready var next_day_button: Button = $Panel/Margin/Content/NextDayButton

const FISH_KING_ID := "fish_king"
const FISH_KING_NAME := "青背老塘王"
const BANKRUPT_CASH_THRESHOLD := 3000
const FISH_KING_TEXTURE := preload("res://Design/Catch Fish King/screen_clean.png")
const WIN_MORE_TEXTURE := preload("res://Design/Win More/screen_clean.png")
const WIN_LESS_TEXTURE := preload("res://Design/Win Less/screen_clean.png")
const BANKRUPT_TEXTURE := preload("res://Design/Bankrupt/screen_clean.png")

var game_state: GameState
var screen_container: Control

func setup(next_game_state: GameState, next_screen_container: Control) -> void:
	game_state = next_game_state
	screen_container = next_screen_container

func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()

	next_day_button.pressed.connect(_on_next_day_pressed)
	_apply_ui_frame()
	_render()

func _apply_ui_frame() -> void:
	UIKit.apply_root(self)
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	UIKit.style_page_title(title_label)
	UIKit.style_top_status(cash_label)
	UIKit.style_label(detail_label, "body_dark")
	UIKit.style_button(next_day_button, "gold")
	UIKit.style_card(fish_king_panel, UIKit.GOLD)
	next_day_button.custom_minimum_size = Vector2(0, 88)
	detail_label.add_theme_font_size_override("font_size", 25)

func _render() -> void:
	var result := game_state.last_result
	var is_fish_king := _is_fish_king_result()
	var is_bankrupt := game_state.cash < BANKRUPT_CASH_THRESHOLD
	if is_bankrupt:
		title_label.text = "本钱见底"
	elif is_fish_king:
		title_label.text = "鱼王出现！"
	else:
		title_label.text = str(result.get("title", "本局结算"))
	_render_result_illustration(is_bankrupt, is_fish_king)
	_render_fish_king_panel(is_fish_king and not is_bankrupt)

	var lines: Array[String] = []
	lines.append("这口塘：%s" % str(game_state.current_pond.get("name", "未知鱼塘")))
	lines.append("本局结果：%s" % _get_fish_result_text())
	lines.append("原因说明：%s" % _get_fish_description_text())
	if not game_state.catch_details.is_empty():
		lines.append("鱼获明细：")
		for item in game_state.catch_details:
			lines.append(_format_catch_detail_line(item))
	lines.append("")
	lines.append("账本（承包后经营）：")
	lines.append("承包费：%d 元（已扣，不重复算净利）" % int(game_state.current_pond.get("quote_price", 0)))
	lines.append("验塘费：-%d 元" % game_state.inspection_cost_total)
	lines.append("作业成本：-%d 元" % game_state.work_cost)
	lines.append("卖一网回款：+%d 元" % game_state.one_net_income)
	lines.append("转包回款：+%d 元" % game_state.transfer_income)
	lines.append("卖鱼回款：+%d 元" % game_state.fish_income)
	lines.append("承包后经营账：%s" % _format_profit_line(game_state.get_net_profit()))

	detail_label.text = "\n".join(lines)
	cash_label.text = UIKit.format_run_status(game_state.day, game_state.cash)

func _render_result_illustration(is_bankrupt: bool, is_fish_king: bool) -> void:
	if is_bankrupt:
		result_illustration.texture = BANKRUPT_TEXTURE
	elif is_fish_king:
		result_illustration.texture = FISH_KING_TEXTURE
	elif game_state.get_net_profit() > 0:
		result_illustration.texture = WIN_MORE_TEXTURE
	else:
		result_illustration.texture = WIN_LESS_TEXTURE

func _is_fish_king_result() -> bool:
	if game_state.fish_result_id == FISH_KING_ID:
		return true
	for item in game_state.catch_details:
		if str(item.get("id", "")) == FISH_KING_ID:
			return true
	return str(game_state.last_result.get("fish_result_id", "")) == FISH_KING_ID

func _render_fish_king_panel(is_fish_king: bool) -> void:
	fish_king_panel.visible = is_fish_king
	if not is_fish_king:
		return

	var fish_king_detail := _get_fish_king_catch_detail()
	var weight_jin := int(fish_king_detail.get("weight_jin", 0))
	var integrity := int(fish_king_detail.get("integrity", 0))
	var estimated_value := int(fish_king_detail.get("income", 0))

	fish_king_scene_label.text = "水面猛地一翻，一条大青鱼被拖出水面。"
	fish_king_name_label.text = "%s出现！" % FISH_KING_NAME
	fish_king_stats_label.text = "重量：%d 斤\n完整度：%d%%\n估值：%d 元" % [
		weight_jin,
		integrity,
		estimated_value
	]
	fish_king_tagline_label.text = "这口塘，算是捞出名堂了。"
	_apply_fish_king_style()
	_play_fish_king_animation()

func _get_fish_king_catch_detail() -> Dictionary:
	for item in game_state.catch_details:
		if str(item.get("id", "")) == FISH_KING_ID:
			return item
	return {}

func _format_catch_detail_line(item: Dictionary) -> String:
	var line := "%s：%d 斤，%d 元" % [
		str(item.get("name", "")),
		int(item.get("weight_jin", 0)),
		int(item.get("income", 0))
	]
	if str(item.get("id", "")) == FISH_KING_ID and item.has("integrity"):
		line = "%s，完整度 %d%%" % [line, int(item.get("integrity", 0))]
		if not str(item.get("price_note", "")).is_empty():
			line = "%s（%s）" % [line, str(item.get("price_note", ""))]
	return line

func _apply_fish_king_style() -> void:
	title_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2))
	fish_king_scene_label.add_theme_color_override("font_color", Color(0.35, 0.18, 0.02))
	fish_king_name_label.add_theme_color_override("font_color", Color(0.24, 0.08, 0.0))
	fish_king_stats_label.add_theme_color_override("font_color", Color(0.28, 0.12, 0.0))
	fish_king_tagline_label.add_theme_color_override("font_color", Color(0.55, 0.16, 0.02))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.76, 0.18)
	style.border_color = Color(0.98, 0.92, 0.42)
	style.set_border_width_all(6)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.36, 0.18, 0.0, 0.35)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 6)
	fish_king_panel.add_theme_stylebox_override("panel", style)

func _play_fish_king_animation() -> void:
	fish_king_panel.scale = Vector2.ONE
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fish_king_panel, "scale", Vector2(1.035, 1.035), 0.16)
	tween.tween_property(fish_king_panel, "scale", Vector2.ONE, 0.12)

func _get_fish_result_text() -> String:
	if not game_state.fish_result_name.is_empty():
		return game_state.fish_result_name
	if str(game_state.last_result.get("type", "")) == "abandon":
		return "认亏收手"
	if game_state.transfer_income > 0:
		return "未继续捕捞"
	return "暂无鱼获"

func _get_fish_description_text() -> String:
	if not game_state.fish_description.is_empty():
		return game_state.fish_description
	if str(game_state.last_result.get("type", "")) == "abandon":
		return "你没有继续下网，止住了后续作业成本，也放弃了可能的鱼获。"
	if game_state.transfer_income > 0:
		return "你选择转包，拿固定回款离场，后面涨跌都不再参与。"
	return "本局没有卖鱼回款，亏损主要来自验塘费和作业成本。"

func _format_profit_line(net_profit: int) -> String:
	if net_profit > 0:
		return "+%d 元，赚在回款盖过验塘费和作业成本。" % net_profit
	if net_profit < 0:
		return "%d 元，亏在回款没盖住验塘费和作业成本。" % net_profit
	return "0 元，刚好打平。"

func _on_next_day_pressed() -> void:
	game_state.advance_to_next_day()
	UIController.show_pond_list(screen_container, game_state, true)
