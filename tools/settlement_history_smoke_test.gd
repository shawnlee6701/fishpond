extends SceneTree

const SaveSystem := preload("res://scripts/save_system.gd")

var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	_clear_history()
	var game_state := GameState.new()
	game_state.day = 2
	game_state.cash = 28700
	var container := Control.new()
	root.add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	UIController.show_pond_list(container, game_state)
	await _settle_frames()
	var pond_list := _current_screen(container)
	var history_button := pond_list.get_node("SafeArea/PageLayout/TopStatusBar/StatusRow/RecordButton") as Button
	_check(history_button != null, "今日鱼塘右上角存在包塘记录入口")
	history_button.pressed.emit()
	await _settle_frames()
	_check_screen(container, "PondRecordScreen", "包塘记录入口进入记录页")
	var empty_history := _current_screen(container)
	_check(empty_history.get_node("SafeArea/PageLayout/ContentArea/EmptyState").visible, "没有结算时显示空账本状态")
	_check(not empty_history.get_node("SafeArea/PageLayout/RecordSummaryBar").visible, "空账本不显示无意义的统计条")
	_check(empty_history.get_node("SafeArea/PageLayout/ContentArea/EmptyState/EmptyContent/GoPondListButton").text == "去看今日鱼塘", "空状态提供去看今日鱼塘按钮")

	_seed_settlement(game_state, "东湾老塘", 1680, "转包脱手")
	var expected_profit := game_state.get_net_profit()
	_check(SaveSystem.record_settlement(game_state), "最终结算成功写入记录")
	_check(not SaveSystem.record_settlement(game_state), "同一轮结算不会重复写入")
	var records := SaveSystem.load_settlement_records()
	_check(records.size() == 1, "包塘记录保存为一条账目")
	if records.size() == 1:
		_check_record_schema(records[0], expected_profit)

	var cached_records := SaveSystem.load_settlement_records()
	_check(cached_records.size() == 1, "缓存命中时仍返回相同数量的记录")
	if cached_records.size() == 1:
		_check(cached_records[0].record_id == records[0].record_id, "缓存返回的记录内容与首次读取一致")
		cached_records[0].pond_name = "被篡改的塘口"
		var still_intact := SaveSystem.load_settlement_records()
		if still_intact.size() == 1:
			_check(still_intact[0].pond_name == records[0].pond_name, "外部修改缓存副本不会破坏底层记录")

	SaveSystem.clear_checkpoint()
	_check(SaveSystem.load_settlement_records().size() == 1, "重新开始清档不会删除包塘记录")
	UIController.show_settlement_history(container, game_state)
	await _settle_frames()
	var history_screen := _current_screen(container)
	_check(history_screen.get_node("SafeArea/PageLayout/TopStatusBar/StatusRow/DayLabel").text == "第 2 天", "顶部天数来自当前游戏状态")
	_check(history_screen.get_node("SafeArea/PageLayout/TopStatusBar/StatusRow/MoneyLabel").text == "本钱：28700 元", "顶部本钱来自当前游戏状态")
	_check(history_screen.get_node("SafeArea/PageLayout/RecordSummaryBar/StatsRow/TotalPondCountStat").text == "已包塘\n1 口", "总览显示已包塘数量")
	_check("+1680 元" in history_screen.get_node("SafeArea/PageLayout/RecordSummaryBar/StatsRow/TotalProfitLossStat").text, "总览显示累计盈利")
	_check("28700 元" in history_screen.get_node("SafeArea/PageLayout/RecordSummaryBar/StatsRow/CurrentMoneyStat").text, "总览显示当前本钱")

	var header := history_screen.find_child("RecordHeader", true, false) as Button
	var detail := history_screen.find_child("RecordDetail", true, false) as VBoxContainer
	var badge := history_screen.find_child("ProfitLossBadge", true, false) as Label
	var meta := history_screen.find_child("DayAndMethodLabel", true, false) as Label
	_check(header != null and detail != null, "记录页显示可展开账本卡片")
	_check(badge != null and badge.text == "赚 1680 元", "折叠卡片使用醒目的盈利 Badge")
	_check(meta != null and meta.text.begins_with("第 2 天 · 转包脱手 · "), "Header 先显示天数和结算方式，时间只保留时分")
	if header != null and detail != null:
		header.pressed.emit()
		await process_frame
		_check(detail.visible, "点击 RecordHeader 展开详情")
		_check(header.get_node("RecordHeaderRow/ExpandArrow").text == "▼", "展开状态箭头向下")
		_check(detail.get_node_or_null("ResultSummarySection") != null, "展开详情包含本塘结果分区")
		_check(detail.get_node_or_null("IncomeSection") != null, "展开详情包含收入分区")
		_check(detail.get_node_or_null("ExpenseSection") != null, "展开详情包含支出分区")
		_check(detail.get_node_or_null("FinalLedgerSection") != null, "展开详情包含最终账本分区")
		_check(_tree_has_text(detail, "总收入") and _tree_has_text(detail, "总支出") and _tree_has_text(detail, "本塘净赚亏"), "最终账本显示统一合计")
		header.pressed.emit()
		await process_frame
		_check(not detail.visible and header.get_node("RecordHeaderRow/ExpandArrow").text == "▶", "再次点击折叠并恢复箭头")

	for viewport_size in [Vector2i(540, 960), Vector2i(720, 1280), Vector2i(1080, 1920)]:
		root.size = viewport_size
		await _settle_frames()
		var scroll := history_screen.get_node("SafeArea/PageLayout/ContentArea/RecordListScroll") as ScrollContainer
		var bottom := history_screen.get_node("SafeArea/PageLayout/BottomButton") as Button
		_check(scroll.size.y > 0 and bottom.size.y > 0, "%dx%d 下列表可滚动且底部按钮可见" % [viewport_size.x, viewport_size.y])

	var inconsistent := SaveSystem.normalize_settlement_record({
		"day": 3,
		"fish_revenue": 1000,
		"transfer_revenue": 200,
		"total_income": 99999,
		"contract_cost": 700,
		"total_expense": 1,
		"net_profit": 99998
	})
	_check(int(inconsistent.total_income) == 1200, "收入总计始终由收入明细重算")
	_check(int(inconsistent.total_expense) == 700, "支出总计始终由支出明细重算")
	_check(int(inconsistent.net_profit) == 500, "净赚亏始终由收入减支出重算")

	var next_state := GameState.new()
	_seed_settlement(next_state, "南埂新塘", -420, "抽干结算")
	_check(SaveSystem.record_settlement(next_state), "下一次结算继续追加记录")
	_check(SaveSystem.load_settlement_records().size() == 2, "记录列表不写死数量")

	SaveSystem.clear_settlement_history_cache()
	_check(SaveSystem.load_settlement_records().size() == 2, "手动清除缓存后重新读取仍保持两条记录")
	UIController.show_settlement_history(container, next_state)
	await _settle_frames()
	var two_record_screen := _current_screen(container)
	var newest_badge := two_record_screen.find_child("ProfitLossBadge", true, false) as Label
	_check(newest_badge != null and newest_badge.text == "亏 420 元", "亏损记录使用亏损 Badge 且不显示负号重复")
	_check("+1260 元" in two_record_screen.get_node("SafeArea/PageLayout/RecordSummaryBar/StatsRow/TotalProfitLossStat").text, "多条记录累计盈亏按净赚亏合计")
	_clear_history()
	_finish()

func _check_record_schema(record: Dictionary, expected_profit: int) -> void:
	var required_fields := [
		"record_id", "day", "timestamp", "pond_name", "finish_method",
		"contract_cost", "inspection_cost", "fishing_cost", "transport_cost",
		"labor_cost", "pump_cost", "other_cost", "fish_revenue",
		"transfer_revenue", "one_net_revenue", "other_income", "total_income",
		"total_expense", "net_profit", "money_after_settlement"
	]
	for field in required_fields:
		_check(record.has(field), "记录包含字段 %s" % field)
	var income_sum := int(record.fish_revenue) + int(record.transfer_revenue) + int(record.one_net_revenue) + int(record.other_income)
	var expense_sum := int(record.contract_cost) + int(record.inspection_cost) + int(record.fishing_cost) + int(record.transport_cost) + int(record.labor_cost) + int(record.pump_cost) + int(record.other_cost)
	_check(income_sum == int(record.total_income), "收入明细与收入合计一致")
	_check(expense_sum == int(record.total_expense), "支出明细与支出合计一致")
	_check(int(record.net_profit) == income_sum - expense_sum, "净赚亏等于总收入减总支出")
	_check(int(record.net_profit) == expected_profit, "记录净赚亏与最终结算一致")

func _seed_settlement(game_state: GameState, pond_name: String, net_profit: int, finish_method: String) -> void:
	game_state.current_pond = {"name": pond_name, "quote_price": 5000}
	game_state.inspection_cost_total = 300
	game_state.work_cost = 1200
	game_state.fish_income = 6500 + net_profit
	game_state.fish_result_name = "大鱼起网"
	game_state.fish_description = "这塘鱼情比塘主说的实在。"
	game_state.catch_details = [{
		"id": "big_fish",
		"name": "大鱼",
		"weight_jin": 60,
		"income": 6500 + net_profit
	}]
	game_state.last_result = {"title": finish_method}

func _tree_has_text(node: Node, expected: String) -> bool:
	if node is Label and expected in (node as Label).text:
		return true
	for child in node.get_children():
		if _tree_has_text(child, expected):
			return true
	return false

func _clear_history() -> void:
	if FileAccess.file_exists(SaveSystem.SETTLEMENT_HISTORY_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveSystem.SETTLEMENT_HISTORY_PATH))
	SaveSystem.clear_settlement_history_cache()

func _settle_frames() -> void:
	await process_frame
	await process_frame

func _current_screen(container: Control) -> Control:
	for child in container.get_children():
		if not child.is_queued_for_deletion():
			return child as Control
	return null

func _check_screen(container: Control, expected_name: String, description: String) -> void:
	var screen := _current_screen(container)
	_check(screen != null and screen.name == expected_name, description)

func _check(condition: bool, description: String) -> void:
	if condition:
		print("SETTLEMENT_HISTORY_OK: %s" % description)
	else:
		failures.append(description)
		push_error("SETTLEMENT_HISTORY_FAIL: %s" % description)

func _finish() -> void:
	if failures.is_empty():
		print("SETTLEMENT_HISTORY_TEST_OK")
		quit(0)
	else:
		print("SETTLEMENT_HISTORY_TEST_FAILED: %s" % ", ".join(failures))
		quit(1)
