extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var shared_theme := load("res://themes/UI_Theme.tres") as Theme
	_check(shared_theme.default_font != null, "全局主题已绑定默认字体")
	_check(shared_theme.default_font_size == 28, "全局默认字号为 28")
	var panel_style := shared_theme.get_stylebox("panel", "PanelContainer") as StyleBoxFlat
	_check(panel_style != null, "PanelContainer 已绑定全局 Panel 样式")
	if panel_style != null:
		_check(panel_style.bg_color.is_equal_approx(Color("#FDF8EF")), "Panel 背景色为 #FDF8EF")
		_check(panel_style.border_color.is_equal_approx(Color("#D4AF37")), "Panel 边框色为 #D4AF37")
		_check(panel_style.border_width_left == 3 and panel_style.border_width_top == 3 and panel_style.border_width_right == 3 and panel_style.border_width_bottom == 3, "Panel 四边边框为 3")
		_check(panel_style.corner_radius_top_left == 20 and panel_style.corner_radius_top_right == 20 and panel_style.corner_radius_bottom_left == 20 and panel_style.corner_radius_bottom_right == 20, "Panel 四角圆角为 20")
		_check(is_equal_approx(panel_style.content_margin_left, 24.0) and is_equal_approx(panel_style.content_margin_top, 24.0) and is_equal_approx(panel_style.content_margin_right, 24.0) and is_equal_approx(panel_style.content_margin_bottom, 24.0), "Panel 四边内容边距为 24")
		_check(panel_style.shadow_size == 12 and panel_style.shadow_offset == Vector2(0, 6), "Panel 阴影尺寸与偏移正确")
		_check(panel_style.shadow_color.is_equal_approx(Color("#00000028")), "Panel 阴影颜色为 #00000028")

	var main_scene: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame
	await process_frame

	var game_root: Control = main_scene.get_node("UIRoot/GameRoot") as Control
	var screen_container := game_root.get_node("ScreenContainer") as Control
	var start_button := game_root.get_node("HomeScreen/SafeArea/PageLayout/BottomActionCenter/BottomActionArea/ContinueButton") as Button
	start_button.pressed.emit()
	await _settle_frames()
	_check_screen(screen_container, "PondList", "开始按钮进入鱼塘列表")

	var pond_list := _current_screen(screen_container)
	var pond_thumb := pond_list.find_child("PondThumbPlaceholder", true, false) as PanelContainer
	_check(pond_thumb != null and pond_thumb.find_child("PlaceholderMarker", true, false) == null, "鱼塘卡片使用无叉号的自绘缩略图占位")
	var quote_label := pond_list.find_child("PriceBadge", true, false) as Label
	var stat_grid := pond_list.find_child("StatGrid", true, false) as GridContainer
	var tag_row := pond_list.find_child("TagRow", true, false) as HBoxContainer
	_check(quote_label != null and stat_grid != null and quote_label.get_parent().get_index() < stat_grid.get_index(), "要价位于卡片首要信息区")
	_check(quote_label != null and quote_label.theme_type_variation == &"PondPriceLabel" and quote_label.get_theme_stylebox("normal") is StyleBoxFlat, "要价使用稳定的价格牌样式")
	_check(tag_row != null and tag_row.get_child_count() == 3 and tag_row.get_child(0) is PanelContainer and tag_row.get_child(1) is PanelContainer and tag_row.get_child(2) is PanelContainer, "鱼塘名称下三个标签均使用面板")
	if tag_row != null and tag_row.get_child_count() == 3:
		var depth_tag_labels := tag_row.get_child(2).find_children("*", "Label", true, false)
		var depth_tag_label := depth_tag_labels[0] as Label if not depth_tag_labels.is_empty() else null
		_check(depth_tag_label != null and not depth_tag_label.text.ends_with("水水"), "深浅标签不重复水字")
	var age_label := pond_list.find_child("AgeLabel", true, false) as Label
	var depth_label := pond_list.find_child("DepthLabel", true, false) as Label
	var water_label := pond_list.find_child("WaterLabel", true, false) as Label
	_check(age_label != null and depth_label != null and water_label != null and age_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and depth_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER and water_label.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "鱼塘属性使用三列居中信息块")
	var view_button := pond_list.find_child("ViewButton", true, false) as Button
	_check(view_button != null, "鱼塘卡片存在进塘验货按钮")
	if view_button == null:
		_finish()
		return
	view_button.pressed.emit()
	await _settle_frames()
	_check_screen(screen_container, "PondDetail", "进塘验货按钮进入鱼塘详情")

	var pond_detail := _current_screen(screen_container)
	var inspection_cards := pond_detail.get_node("SafeArea/PageLayout/ContentScroll/Content/InspectionSection/InspectionCards") as VBoxContainer
	_check(inspection_cards.get_child_count() == 3, "验塘页面显示三张买线索卡片")
	_check(pond_detail.find_child("CostBadge", true, false) != null, "未验线索卡显示费用牌")
	var inspection_button := _first_enabled_button_in(inspection_cards)
	_check(inspection_button != null, "验塘页面存在可用检查按钮")
	if inspection_button != null:
		inspection_button.pressed.emit()
		await _settle_frames()
	_check(pond_detail.find_child("UsedBadge", true, false) != null, "验塘后卡片显示已验状态")
	_check(pond_detail.find_child("ResultHeadlineLabel", true, false) != null and pond_detail.find_child("ResultDetailLabel", true, false) != null, "验塘结果拆分为结论和详情")
	var inspection_state := pond_detail.get("game_state") as GameState
	var money_label := pond_detail.get_node("SafeArea/PageLayout/TopStatusBar/StatusRow/MoneyLabel") as Label
	var cost_label := pond_detail.get_node("SafeArea/PageLayout/TopStatusBar/StatusRow/InspectionCostLabel") as Label
	_check(money_label.text.contains(str(inspection_state.cash)) and cost_label.text.contains("0 元"), "免费验塘后顶部本钱和验塘费保持同步")

	var bottom_bar := pond_detail.get_node("SafeArea/PageLayout/BottomDecisionBar") as PanelContainer
	var content_scroll := pond_detail.get_node("SafeArea/PageLayout/ContentScroll") as ScrollContainer
	_check(bottom_bar.get_index() > content_scroll.get_index(), "验塘决策栏固定在滚动内容下方")
	var back_button := pond_detail.get_node("SafeArea/PageLayout/BottomDecisionBar/DecisionButtons/GiveUpButton") as Button
	_check(back_button.text == "放弃此塘", "返回操作明确为放弃此塘")
	back_button.pressed.emit()
	await _settle_frames()
	_check_screen(screen_container, "PondList", "未花验塘费时放弃直接回到同日鱼塘列表")

	pond_list = _current_screen(screen_container)
	view_button = pond_list.find_child("ViewButton", true, false) as Button
	view_button.pressed.emit()
	await _settle_frames()
	pond_detail = _current_screen(screen_container)

	var fish_finder_card := pond_detail.find_child("InspectionOptionCard_TanYu", true, false) as PanelContainer
	var paid_button := fish_finder_card.find_child("ActionButton", true, false) as Button
	var cash_before_paid := (pond_detail.get("game_state") as GameState).cash
	paid_button.pressed.emit()
	await _settle_frames()
	inspection_state = pond_detail.get("game_state") as GameState
	money_label = pond_detail.get_node("SafeArea/PageLayout/TopStatusBar/StatusRow/MoneyLabel") as Label
	cost_label = pond_detail.get_node("SafeArea/PageLayout/TopStatusBar/StatusRow/InspectionCostLabel") as Label
	_check(inspection_state.cash == cash_before_paid - 300 and inspection_state.inspection_cost_total == 300, "付费验塘只扣除对应费用")
	_check(money_label.text.contains(str(inspection_state.cash)) and cost_label.text.contains("300 元"), "付费验塘后顶部金额和累计费用同步更新")
	var master_card := pond_detail.find_child("InspectionOptionCard_LaoShiFu", true, false) as PanelContainer
	var master_button := master_card.find_child("ActionButton", true, false) as Button
	master_button.pressed.emit()
	await _settle_frames()
	inspection_state = pond_detail.get("game_state") as GameState
	money_label = pond_detail.get_node("SafeArea/PageLayout/TopStatusBar/StatusRow/MoneyLabel") as Label
	cost_label = pond_detail.get_node("SafeArea/PageLayout/TopStatusBar/StatusRow/InspectionCostLabel") as Label
	_check(inspection_state.cash == cash_before_paid - 1300 and inspection_state.inspection_cost_total == 1300, "连续使用 300 元和 1000 元验塘后累计费用为 1300 元")
	_check(money_label.text.contains(str(inspection_state.cash)) and cost_label.text.contains("1300 元"), "多次付费验塘后顶部金额和累计费用继续同步")

	back_button = pond_detail.get_node("SafeArea/PageLayout/BottomDecisionBar/DecisionButtons/GiveUpButton") as Button
	back_button.pressed.emit()
	await _settle_frames()
	var confirm_dialog := pond_detail.get_node("ConfirmContractDialog") as Control
	_check(confirm_dialog.visible and _find_button_by_text(confirm_dialog, "继续验塘") != null and _find_button_by_text(confirm_dialog, "确定放弃") != null, "已花验塘费后放弃会提示费用不退")
	var continue_inspection := _find_button_by_text(confirm_dialog, "继续验塘")
	continue_inspection.pressed.emit()
	await process_frame

	var contract_button := pond_detail.get_node("SafeArea/PageLayout/BottomDecisionBar/DecisionButtons/CommitButton") as Button
	_check(contract_button.text.begins_with("承包 "), "承包按钮直接显示承包价格")
	contract_button.pressed.emit()
	await _settle_frames()
	var contract_modal := pond_detail.get_node("ConfirmContractDialog") as Control
	_check(contract_modal.visible, "承包按钮显示最终确认弹窗")
	var contract_state := pond_detail.get("game_state") as GameState
	var pond := pond_detail.get("pond") as Dictionary
	var pond_price := int(pond.get("quote_price", 0))
	var preview := contract_state.get_contract_preview(pond)
	var contract_extra_cost := int(preview.get("contract_extra_cost", 0))
	var contract_total_cost := int(preview.get("contract_total_cost", pond_price + contract_extra_cost))
	var remaining_after_contract := int(preview.get("remaining_after_contract", contract_state.cash - contract_total_cost))
	var balance_highlight := contract_modal.get_node("DialogCard/DialogContent/ContentStack/BalanceHighlight") as Label
	var inspection_spent_value := contract_modal.get_node("DialogCard/DialogContent/ContentStack/DialogBody/BillRows/InspectionSpentRow/RowContent/Value") as Label
	var pond_price_value := contract_modal.get_node("DialogCard/DialogContent/ContentStack/DialogBody/BillRows/PondPriceRow/RowContent/Value") as Label
	var extra_cost_row := contract_modal.get_node("DialogCard/DialogContent/ContentStack/DialogBody/BillRows/ExtraCostRow") as PanelContainer
	var total_contract_cost_value := contract_modal.get_node("DialogCard/DialogContent/ContentStack/DialogBody/BillRows/TotalContractCostRow/RowContent/Value") as Label
	var remaining_value := contract_modal.get_node("DialogCard/DialogContent/ContentStack/DialogBody/BillRows/RemainingAfterContractRow/RowContent/Value") as Label
	var status_title := contract_modal.get_node("DialogCard/DialogContent/ContentStack/DialogBody/StatusBox/StatusContent/StatusTitleLabel") as Label
	var dialog_body_scroll := contract_modal.get_node_or_null("DialogCard/DialogContent/ContentStack/DialogBodyScroll") as ScrollContainer
	var bill_rows := contract_modal.get_node("DialogCard/DialogContent/ContentStack/DialogBody/BillRows") as VBoxContainer
	_check(balance_highlight.text.contains("%d 元" % remaining_after_contract), "承包账单高亮显示包下后剩余且来自当前现金减承包价")
	_check(inspection_spent_value.text.contains("1300 元") and inspection_spent_value.text.contains("不退"), "承包账单显示已花验塘费且标明不退")
	_check(pond_price_value.text == "-%d 元" % pond_price, "承包账单将塘主要价显示为负数扣款")
	_check(not extra_cost_row.visible and contract_extra_cost == 0, "承包账单无杂费时隐藏包塘杂费行")
	_check(total_contract_cost_value.text == "-%d 元" % contract_total_cost, "承包账单显示合计扣款")
	_check(remaining_value.text == "%d 元" % remaining_after_contract, "承包账单行显示正确包下后剩余")
	_check(pond_price_value.autowrap_mode == TextServer.AUTOWRAP_OFF and pond_price_value.custom_minimum_size.x >= 240.0 and pond_price_value.size.y <= 60.0, "承包账单右侧金额横排显示且不会逐字换行")
	_check(bill_rows.get_child(0).size.y <= 60.0 and bill_rows.get_child(1).size.y <= 60.0 and bill_rows.get_child(2).size.y <= 60.0, "承包账单行高度不会被金额撑大")
	_check(dialog_body_scroll == null, "承包账单内容未超出时不创建内部滚动条")
	var expected_status := "资金状态：够开工"
	if remaining_after_contract < int(preview.get("recommended_working_capital", contract_state.min_working_capital)):
		expected_status = "资金状态：余额偏紧"
	_check(status_title.text == expected_status, "承包账单显示系统资金状态")
	var contract_card := contract_modal.get_node("DialogCard") as PanelContainer
	var contract_button_row := contract_modal.get_node("DialogCard/DialogContent/ContentStack/ButtonRow") as HBoxContainer
	_check(contract_button_row.position.y + contract_button_row.size.y <= contract_card.size.y, "承包账单底部按钮保持在弹窗卡片内")
	_check(contract_card.size.y <= 1920.0 * 0.8 and contract_card.size.y < 760.0, "承包账单高度按内容收紧且不超过屏幕 80%")
	for viewport_size in [Vector2i(540, 960), Vector2i(720, 1280), Vector2i(1080, 1920)]:
		pond_detail.size = Vector2(1080, 1920)
		pond_detail.call("_on_viewport_size_changed")
		await _settle_frames()
		var width_ratio: float = contract_card.size.x / 1080.0
		var card_in_bounds: bool = contract_card.position.x >= 0.0 and contract_card.position.y >= 0.0 and contract_card.position.x + contract_card.size.x <= 1080.0 and contract_card.position.y + contract_card.size.y <= 1920.0
		var scaled_button_height: float = contract_button_row.size.y * float(viewport_size.y) / 1920.0
		_check(width_ratio >= 0.85 and width_ratio <= 0.92 and card_in_bounds and scaled_button_height >= 44.0, "%dx%d 下承包账单宽度、边界和按钮高度稳定" % [viewport_size.x, viewport_size.y])
	pond_detail.size = Vector2(1080, 1920)
	pond_detail.call("_on_viewport_size_changed")
	await _settle_frames()

	var cancel_button := _find_button_by_text(contract_modal, "再想想")
	_check(cancel_button != null, "承包弹窗存在取消按钮")
	if cancel_button != null:
		cancel_button.pressed.emit()
		await process_frame
		_check(not contract_modal.visible, "承包弹窗取消按钮可关闭弹窗")

	pond["contract_extra_cost"] = 400
	contract_button.pressed.emit()
	await _settle_frames()
	preview = contract_state.get_contract_preview(pond)
	contract_total_cost = int(preview.get("contract_total_cost", 0))
	remaining_after_contract = int(preview.get("remaining_after_contract", 0))
	_check(extra_cost_row.visible, "承包账单有杂费时显示包塘杂费行")
	_check(pond_price_value.text == "-%d 元" % pond_price, "承包账单有杂费时塘主要价仍与顶部鱼塘价格一致")
	_check(total_contract_cost_value.text == "-%d 元" % contract_total_cost and remaining_value.text == "%d 元" % remaining_after_contract, "承包账单有杂费时合计扣款和剩余金额一致")
	cancel_button = _find_button_by_text(contract_modal, "再想想")
	if cancel_button != null:
		cancel_button.pressed.emit()
		await process_frame
	pond.erase("contract_extra_cost")
	contract_button.pressed.emit()
	await _settle_frames()
	preview = contract_state.get_contract_preview(pond)
	contract_total_cost = int(preview.get("contract_total_cost", pond_price))
	remaining_after_contract = int(preview.get("remaining_after_contract", contract_state.cash - contract_total_cost))

	var cash_before_shortage_check := contract_state.cash
	contract_state.cash = contract_total_cost + contract_state.min_working_capital - 1
	pond_detail.call("_render_page")
	await _settle_frames()
	contract_button.pressed.emit()
	await _settle_frames()
	var shortage_status_title := contract_modal.get_node("DialogCard/DialogContent/ContentStack/DialogBody/StatusBox/StatusContent/StatusTitleLabel") as Label
	var shortage_confirm := _find_button_by_text(contract_modal, "钱不够")
	_check(shortage_status_title.text == "资金状态：资金不足", "承包账单在最低开工资金不足时显示资金不足")
	_check(shortage_confirm != null and shortage_confirm.disabled, "承包账单在资金不足时禁用确认按钮")
	cancel_button = _find_button_by_text(contract_modal, "再想想")
	if cancel_button != null:
		cancel_button.pressed.emit()
		await process_frame
	contract_state.cash = cash_before_shortage_check
	pond_detail.call("_render_page")
	await _settle_frames()

	contract_button.pressed.emit()
	await _settle_frames()
	var confirm_button := _find_button_by_text(contract_modal, "就包这塘")
	if confirm_button == null:
		confirm_button = _find_button_by_text(contract_modal, "就包这塘（-%d）" % contract_total_cost)
	_check(confirm_button != null and not confirm_button.disabled, "承包弹窗确认按钮可用")
	_check(confirm_button != null and confirm_button.text == "就包这塘（-%d）" % contract_total_cost, "承包弹窗确认按钮显示实际扣款金额")
	if confirm_button == null or confirm_button.disabled:
		_finish()
		return
	var cash_before_contract := contract_state.cash
	confirm_button.pressed.emit()
	await _settle_frames()
	_check_screen(screen_container, "AfterContractChoice", "确认承包进入承包后选择页")
	_check(contract_state.cash == cash_before_contract - contract_total_cost, "确认承包只扣除合计扣款一次")

	var choice_screen := _current_screen(screen_container)
	var transfer_button := choice_screen.get_node("PageLayout/Panel/Margin/Content/ChoiceButtons/TransferButton") as Button
	_check(not transfer_button.disabled, "转包脱手按钮可用")
	transfer_button.pressed.emit()
	await _settle_frames()
	var transfer_modal := choice_screen.get_node("TransferModal") as Control
	_check(transfer_modal.visible, "转包脱手按钮显示报价弹窗")
	_check(transfer_modal.find_child("ImagePlaceholder", true, false) != null, "转包人物图片位显示叉号占位")
	var reject_transfer := _find_button_by_text(transfer_modal, "继续自己扛")
	_check(reject_transfer != null, "转包弹窗存在拒绝按钮")
	if reject_transfer != null:
		reject_transfer.pressed.emit()
		await process_frame
		_check(not transfer_modal.visible, "拒绝转包关闭弹窗并留在当前页")

	var sell_button := choice_screen.get_node("PageLayout/Panel/Margin/Content/ChoiceButtons/SellOneNetButton") as Button
	_check(sell_button.disabled, "未打出鱼情时卖一网按钮正确禁用")

	var self_button := choice_screen.get_node("PageLayout/Panel/Margin/Content/ChoiceButtons/HarvestSelfButton") as Button
	self_button.pressed.emit()
	await process_frame
	var work_scroll := choice_screen.get_node("PageLayout/Panel/Margin/Content/WorkPlanScroll") as ScrollContainer
	var work_panel := choice_screen.get_node("PageLayout/Panel/Margin/Content/WorkPlanScroll/WorkPlanPanel") as VBoxContainer
	_check(work_scroll.visible, "自己下网按钮打开作业方案列表")
	_check(work_panel.find_children("ImagePlaceholder", "PanelContainer", true, false).size() == 3, "三个作业方案均显示叉号图片位")

	var work_back := choice_screen.get_node("PageLayout/Panel/Margin/Content/WorkPlanBackButton") as Button
	_check(work_back.get_index() > work_scroll.get_index(), "返回处置选择固定在方案列表底端")
	work_back.pressed.emit()
	await process_frame
	_check(not work_scroll.visible, "作业方案返回按钮回到处置选择")

	self_button.pressed.emit()
	await process_frame
	var low_button := choice_screen.get_node("PageLayout/Panel/Margin/Content/WorkPlanScroll/WorkPlanPanel/LowWorkCard/CardContent/LowWorkButton") as Button
	_check(not low_button.disabled, "小捞一网按钮可用")
	if not low_button.disabled:
		low_button.pressed.emit()
		await _settle_frames()
		var harvest_modal := choice_screen.get_node("HarvestResultModal") as Control
		_check(harvest_modal.visible, "非最终捕捞显示结果弹窗")
		_check(harvest_modal.find_child("ImagePlaceholder", true, false) != null, "捕捞结果图片位显示叉号占位")
		var continue_button := _find_button_by_text(harvest_modal, "收下结果")
		_check(continue_button != null, "捕捞结果弹窗存在继续按钮")
		if continue_button != null:
			continue_button.pressed.emit()
			await process_frame
			_check(not harvest_modal.visible, "捕捞结果继续按钮关闭弹窗")

	var choice_state := choice_screen.get("game_state") as GameState
	choice_screen.set("current_one_net_offer", ActionResolver.new(42).generate_one_net_offer(choice_state.current_pond))
	choice_screen.call("_render")
	await process_frame
	_check(not sell_button.disabled, "打出鱼情后卖一网按钮可用")
	sell_button.pressed.emit()
	await _settle_frames()
	_check(choice_state.sold_one_net, "卖一网按钮执行交易并更新状态")

	self_button.pressed.emit()
	await process_frame
	var standard_button := choice_screen.get_node("PageLayout/Panel/Margin/Content/WorkPlanScroll/WorkPlanPanel/StandardWorkCard/CardContent/StandardWorkButton") as Button
	_check(not standard_button.disabled, "稳捞一网按钮可用")
	if not standard_button.disabled:
		standard_button.pressed.emit()
		await _settle_frames()
		var standard_modal := choice_screen.get_node("HarvestResultModal") as Control
		_check(standard_modal.visible, "稳捞一网显示结果弹窗")
		var standard_continue := _find_button_by_text(standard_modal, "收下结果")
		if standard_continue != null:
			standard_continue.pressed.emit()
			await process_frame

	self_button.pressed.emit()
	await process_frame
	var full_button := choice_screen.get_node("PageLayout/Panel/Margin/Content/WorkPlanScroll/WorkPlanPanel/FullWorkCard/CardContent/FullWorkButton") as Button
	_check(not full_button.disabled, "抽干收尾按钮可用")
	if full_button.disabled:
		_finish()
		return
	full_button.pressed.emit()
	await _settle_frames()
	_check_screen(screen_container, "Settlement", "抽干收尾进入结算页")

	var settlement := _current_screen(screen_container)
	_check(settlement.get_node_or_null("Panel/Margin/Content/ResultImagePlaceholder") != null, "结算图片位显示叉号占位")
	var next_button := settlement.get_node("Panel/Margin/Content/NextDayButton") as Button
	next_button.pressed.emit()
	await _settle_frames()
	_check_screen(screen_container, "PondList", "下一地方按钮进入新一天鱼塘列表")

	var restart_scene: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(restart_scene)
	await _settle_frames()
	var restart_root := restart_scene.get_node("UIRoot/GameRoot") as Control
	var restart_container := restart_root.get_node("ScreenContainer") as Control
	var restart_button := restart_root.get_node("HomeScreen/SafeArea/PageLayout/BottomActionCenter/BottomActionArea/RestartButton") as Button
	restart_button.pressed.emit()
	await _settle_frames()
	_check_screen(restart_container, "PondList", "重新开始按钮清档并进入鱼塘列表")

	var restart_list := _current_screen(restart_container)
	var restart_view := restart_list.find_child("ViewButton", true, false) as Button
	restart_view.pressed.emit()
	await _settle_frames()
	var restart_detail := _current_screen(restart_container)
	var restart_contract := restart_detail.get_node("SafeArea/PageLayout/BottomDecisionBar/DecisionButtons/CommitButton") as Button
	restart_contract.pressed.emit()
	await _settle_frames()
	var restart_contract_modal := restart_detail.get_node("ConfirmContractDialog") as Control
	var restart_state := restart_detail.get("game_state") as GameState
	var restart_pond := restart_detail.get("pond") as Dictionary
	var restart_preview := restart_state.get_contract_preview(restart_pond)
	var restart_confirm := _find_button_by_text(restart_contract_modal, "就包这塘（-%d）" % int(restart_preview.get("contract_total_cost", 0)))
	restart_confirm.pressed.emit()
	await _settle_frames()
	var restart_choice := _current_screen(restart_container)
	var restart_transfer := restart_choice.get_node("PageLayout/Panel/Margin/Content/ChoiceButtons/TransferButton") as Button
	restart_transfer.pressed.emit()
	await _settle_frames()
	var restart_transfer_modal := restart_choice.get_node("TransferModal") as Control
	var accept_transfer := _find_button_by_text(restart_transfer_modal, "接受转包")
	_check(accept_transfer != null, "转包弹窗存在接受按钮")
	if accept_transfer != null:
		accept_transfer.pressed.emit()
		await _settle_frames()
		_check_screen(restart_container, "Settlement", "接受转包进入结算页")

	_finish()


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


func _first_enabled_button_in(node: Node) -> Button:
	for child in node.find_children("*", "Button", true, false):
		var button := child as Button
		if not button.disabled:
			return button
	return null


func _find_button_by_text(node: Node, target_text: String) -> Button:
	for child in node.find_children("*", "Button", true, false):
		var button := child as Button
		if button.text == target_text:
			return button
	return null


func _check(condition: bool, description: String) -> void:
	if condition:
		print("UI_FLOW_OK: %s" % description)
	else:
		failures.append(description)
		push_error("UI_FLOW_FAIL: %s" % description)


func _finish() -> void:
	if failures.is_empty():
		print("UI_FLOW_TEST_OK")
		quit(0)
	else:
		print("UI_FLOW_TEST_FAILED: %s" % ", ".join(failures))
		quit(1)
