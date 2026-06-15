extends Control

@onready var title_label: Label = $Panel/Margin/Content/TitleLabel
@onready var detail_label: Label = $Panel/Margin/Content/DetailLabel
@onready var cash_label: Label = $Panel/Margin/Content/CashLabel
@onready var fish_king_panel: PanelContainer = $Panel/Margin/Content/FishKingPanel
@onready var fish_king_scene_label: Label = $Panel/Margin/Content/FishKingPanel/Margin/Content/SceneLabel
@onready var fish_king_name_label: Label = $Panel/Margin/Content/FishKingPanel/Margin/Content/NameLabel
@onready var fish_king_stats_label: Label = $Panel/Margin/Content/FishKingPanel/Margin/Content/StatsLabel
@onready var fish_king_tagline_label: Label = $Panel/Margin/Content/FishKingPanel/Margin/Content/TaglineLabel
@onready var next_day_button: Button = $Panel/Margin/Content/NextDayButton

const FISH_KING_ID := "fish_king"
const FISH_KING_NAME := "青背老塘王"

var game_state: GameState
var screen_container: Control
var rng := RandomNumberGenerator.new()

func setup(next_game_state: GameState, next_screen_container: Control) -> void:
	game_state = next_game_state
	screen_container = next_screen_container

func _ready() -> void:
	if game_state == null:
		game_state = GameState.new()

	next_day_button.pressed.connect(_on_next_day_pressed)
	_render()

func _render() -> void:
	var result := game_state.last_result
	var is_fish_king := _is_fish_king_result()
	title_label.text = "鱼王出现！" if is_fish_king else str(result.get("title", "本局结算"))
	_render_fish_king_panel(is_fish_king)

	var lines: Array[String] = []
	lines.append("鱼塘名称：%s" % str(game_state.current_pond.get("name", "未知鱼塘")))
	lines.append("鱼获结果：%s" % _get_fish_result_text())
	lines.append("鱼获描述：%s" % _get_fish_description_text())
	if not game_state.catch_details.is_empty():
		lines.append("鱼获明细：")
		for item in game_state.catch_details:
			lines.append("%s：%d 斤，%d 元" % [
				str(item.get("name", "")),
				int(item.get("weight_jin", 0)),
				int(item.get("income", 0))
			])
	lines.append("")
	lines.append("承包费：%d 元（已在承包时扣除）" % int(game_state.current_pond.get("quote_price", 0)))
	lines.append("验塘费：-%d 元" % game_state.inspection_cost_total)
	lines.append("作业成本：-%d 元" % game_state.work_cost)
	lines.append("卖一网收入：+%d 元" % game_state.one_net_income)
	lines.append("转包收入：+%d 元" % game_state.transfer_income)
	lines.append("卖鱼收入：+%d 元" % game_state.fish_income)
	lines.append("本局净利润：%+d 元" % game_state.get_net_profit())

	detail_label.text = "\n".join(lines)
	cash_label.text = "当前现金：%d 元" % game_state.cash

func _is_fish_king_result() -> bool:
	if game_state.fish_result_id == FISH_KING_ID:
		return true
	return str(game_state.last_result.get("fish_result_id", "")) == FISH_KING_ID

func _render_fish_king_panel(is_fish_king: bool) -> void:
	fish_king_panel.visible = is_fish_king
	if not is_fish_king:
		return

	rng.randomize()
	var weight_jin := rng.randi_range(50, 150)
	var integrity := rng.randi_range(80, 100)
	var estimated_value := _round_to_hundred(int(float(weight_jin) * lerpf(180.0, 280.0, float(integrity - 80) / 20.0)))

	fish_king_scene_label.text = "水面炸开，一条巨大的青鱼被拖出水面！"
	fish_king_name_label.text = "%s出现！" % FISH_KING_NAME
	fish_king_stats_label.text = "重量：%d 斤\n完整度：%d%%\n估值：%d 元" % [
		weight_jin,
		integrity,
		estimated_value
	]
	fish_king_tagline_label.text = "这一网，翻身了。"
	_apply_fish_king_style()
	_play_fish_king_animation()

func _round_to_hundred(value: int) -> int:
	return int(roundf(float(value) / 100.0)) * 100

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
		return "放弃作业"
	if game_state.transfer_income > 0:
		return "未继续捕捞"
	return "暂无鱼获"

func _get_fish_description_text() -> String:
	if not game_state.fish_description.is_empty():
		return game_state.fish_description
	if str(game_state.last_result.get("type", "")) == "abandon":
		return "本局放弃继续捕捞，没有产生作业成本和卖鱼收入。"
	if game_state.transfer_income > 0:
		return "本局已转包结算。"
	return "本局没有产生卖鱼收入。"

func _on_next_day_pressed() -> void:
	game_state.advance_to_next_day()
	UIController.show_pond_list(screen_container, game_state)
