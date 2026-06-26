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
	var pond_thumb := pond_list.find_child("PondThumb", true, false) as TextureRect
	_check(pond_thumb != null and pond_thumb.texture != null, "鱼塘卡片使用 pond_thumb 纹理缩略图")
	var quote_label := pond_list.find_child("PriceBadge", true, false) as Label
	var stat_grid := pond_list.find_child("StatGrid", true, false) as GridContainer
	var tag_row := pond_list.find_child("TagRow", true, false) as HBoxContainer
	_check(quote_label != null and stat_grid != null and quote_label.get_parent().get_index() < stat_grid.get_index(), "要价位于卡片首要信息区")
	_check(quote_label != null and quote_label.get_theme_stylebox("normal") is StyleBoxTexture, "要价使用价格牌贴图样式")
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
	var confirm_dialog := root.get_node("PopupManager") as CanvasLayer
	_check(confirm_dialog.visible and _find_button_by_text(confirm_dialog, "再看看") != null and _find_button_by_text(confirm_dialog, "不包了，走") != null, "已花验塘费后放弃会提示费用不退")
	var continue_inspection := _find_button_by_text(confirm_dialog, "再看看")
	continue_inspection.pressed.emit()
	await process_frame

	var contract_button := pond_detail.get_node("SafeArea/PageLayout/BottomDecisionBar/DecisionButtons/CommitButton") as Button
	_check(contract_button.text.begins_with("包了！给塘主 "), "承包按钮直接显示承包价格")
	contract_button.pressed.emit()
	await _settle_frames()
	var contract_modal := root.get_node("PopupManager") as CanvasLayer
	_check(contract_modal.visible, "承包按钮显示最终确认弹窗")
	var contract_state := pond_detail.get("game_state") as GameState
	var pond := pond_detail.get("pond") as Dictionary
	var pond_price := int(pond.get("quote_price", 0))
	var preview := contract_state.get_contract_preview(pond)
	var contract_extra_cost := int(preview.get("contract_extra_cost", 0))
	var contract_total_cost := int(preview.get("contract_total_cost", pond_price + contract_extra_cost))
	var remaining_after_contract := int(preview.get("remaining_after_contract", contract_state.cash - contract_total_cost))
	var popup_content_path := "DimOverlay/ModalCenter/ConfirmContractDialog/MarginContainer/ContentStack"
	var dim_overlay := contract_modal.get_node("DimOverlay") as Panel
	var modal_center := contract_modal.get_node("DimOverlay/ModalCenter") as CenterContainer
	var balance_highlight := contract_modal.get_node("%s/BalanceHighlight" % popup_content_path) as Label
	var inspection_spent_value := contract_modal.get_node("%s/DialogBody/BillRows/InspectionSpentRow/RowContent/Value" % popup_content_path) as Label
	var pond_price_value := contract_modal.get_node("%s/DialogBody/BillRows/PondPriceRow/RowContent/Value" % popup_content_path) as Label
	var extra_cost_row := contract_modal.get_node_or_null("%s/DialogBody/BillRows/ExtraCostRow" % popup_content_path) as PanelContainer
	var total_contract_cost_value := contract_modal.get_node("%s/DialogBody/BillRows/TotalContractCostRow/RowContent/Value" % popup_content_path) as Label
	var remaining_value := contract_modal.get_node("%s/DialogBody/BillRows/RemainingAfterContractRow/RowContent/Value" % popup_content_path) as Label
	var status_title := contract_modal.get_node("%s/DialogBody/StatusBox/StatusContent/StatusTitleLabel" % popup_content_path) as Label
	var dialog_body_scroll := contract_modal.get_node_or_null("%s/DialogBodyScroll" % popup_content_path) as ScrollContainer
	var bill_rows := contract_modal.get_node("%s/DialogBody/BillRows" % popup_content_path) as VBoxContainer
	_check(balance_highlight.text.contains("%d 元" % remaining_after_contract), "承包账单高亮显示包下后剩余且来自当前现金减承包价")
	_check(inspection_spent_value.text.contains("1300 元") and inspection_spent_value.text.contains("不退"), "承包账单显示已花验塘费且标明不退")
	_check(pond_price_value.text == "-%d 元" % pond_price, "承包账单将塘主要价显示为负数扣款")
	_check(extra_cost_row == null and contract_extra_cost == 0, "承包账单无杂费时隐藏包塘杂费行")
	_check(total_contract_cost_value.text == "-%d 元" % contract_total_cost, "承包账单显示合计扣款")
	_check(remaining_value.text == "%d 元" % remaining_after_contract, "承包账单行显示正确包下后剩余")
	_check(pond_price_value.autowrap_mode == TextServer.AUTOWRAP_OFF and pond_price_value.custom_minimum_size.x >= 240.0 and pond_price_value.size.y <= 60.0, "承包账单右侧金额横排显示且不会逐字换行")
	_check(bill_rows.get_child(0).size.y <= 60.0 and bill_rows.get_child(1).size.y <= 60.0 and bill_rows.get_child(2).size.y <= 60.0, "承包账单行高度不会被金额撑大")
	_check(dialog_body_scroll == null, "承包账单内容未超出时不创建内部滚动条")
	_check(contract_modal.layer >= 100 and dim_overlay.mouse_filter == Control.MOUSE_FILTER_STOP, "承包弹窗位于高层 CanvasLayer 且遮罩阻止底层点击")
	_check(dim_overlay.anchor_left == 0.0 and dim_overlay.anchor_top == 0.0 and dim_overlay.anchor_right == 1.0 and dim_overlay.anchor_bottom == 1.0, "承包弹窗遮罩覆盖全屏")
	_check(modal_center.anchor_left == 0.0 and modal_center.anchor_top == 0.0 and modal_center.anchor_right == 1.0 and modal_center.anchor_bottom == 1.0, "承包弹窗居中容器覆盖全屏")
	var expected_status := "钱够开工"
	if remaining_after_contract < int(preview.get("recommended_working_capital", contract_state.min_working_capital)):
		expected_status = "稍微有点紧"
	_check(status_title.text == expected_status, "承包账单显示系统资金状态")
	var contract_card := contract_modal.get_node("DimOverlay/ModalCenter/ConfirmContractDialog") as PanelContainer
	var contract_button_row := contract_modal.get_node("%s/ButtonRow" % popup_content_path) as HBoxContainer
	_check(contract_button_row.position.y + contract_button_row.size.y <= contract_card.size.y, "承包账单底部按钮保持在弹窗卡片内")
	_check(contract_card.size.y <= 1920.0 * 0.8 and contract_card.size.y < 900.0, "承包账单高度按内容收紧且不超过屏幕 80%")
	for viewport_size in [Vector2i(540, 960), Vector2i(720, 1280), Vector2i(1080, 1920)]:
		pond_detail.size = Vector2(1080, 1920)
		pond_detail.call("_on_viewport_size_changed")
		await _settle_frames()
		var center_size := modal_center.size
		var safe_width := maxf(1.0, center_size.x - 48.0)
		var expected_dialog_width := clampf(center_size.x * 0.9, minf(360.0, safe_width), minf(980.0, safe_width))
		var width_matches: bool = absf(contract_card.size.x - expected_dialog_width) <= 2.0
		var card_in_bounds: bool = contract_card.position.x >= 0.0 and contract_card.position.y >= 0.0 and contract_card.position.x + contract_card.size.x <= center_size.x and contract_card.position.y + contract_card.size.y <= center_size.y
		var horizontally_centered: bool = absf(contract_card.position.x + contract_card.size.x * 0.5 - center_size.x * 0.5) <= 2.0
		var vertically_centered: bool = absf(contract_card.position.y + contract_card.size.y * 0.5 - center_size.y * 0.5) <= 2.0
		var scaled_button_height: float = contract_button_row.size.y * float(viewport_size.y) / 1920.0
		_check(width_matches and card_in_bounds and horizontally_centered and vertically_centered and scaled_button_height >= 44.0, "%dx%d 下承包账单宽度、居中、边界和按钮高度稳定" % [viewport_size.x, viewport_size.y])
	pond_detail.size = Vector2(1080, 1920)
	pond_detail.call("_on_viewport_size_changed")
	await _settle_frames()

	var cancel_button := _find_button_by_text(contract_modal, "再掂量掂量")
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
	extra_cost_row = contract_modal.get_node_or_null("%s/DialogBody/BillRows/ExtraCostRow" % popup_content_path) as PanelContainer
	pond_price_value = contract_modal.get_node("%s/DialogBody/BillRows/PondPriceRow/RowContent/Value" % popup_content_path) as Label
	total_contract_cost_value = contract_modal.get_node("%s/DialogBody/BillRows/TotalContractCostRow/RowContent/Value" % popup_content_path) as Label
	remaining_value = contract_modal.get_node("%s/DialogBody/BillRows/RemainingAfterContractRow/RowContent/Value" % popup_content_path) as Label
	_check(extra_cost_row != null and extra_cost_row.visible, "承包账单有杂费时显示包塘杂费行")
	_check(pond_price_value.text == "-%d 元" % pond_price, "承包账单有杂费时塘主要价仍与顶部鱼塘价格一致")
	_check(total_contract_cost_value.text == "-%d 元" % contract_total_cost and remaining_value.text == "%d 元" % remaining_after_contract, "承包账单有杂费时合计扣款和剩余金额一致")
	cancel_button = _find_button_by_text(contract_modal, "再掂量掂量")
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
	var shortage_status_title := contract_modal.get_node("%s/DialogBody/StatusBox/StatusContent/StatusTitleLabel" % popup_content_path) as Label
	var shortage_confirm := _find_button_by_text(contract_modal, "包不了")
	_check(shortage_status_title.text == "钱不够开工", "承包账单在最低开工资金不足时显示资金不足")
	_check(shortage_confirm != null and shortage_confirm.disabled, "承包账单在资金不足时禁用确认按钮")
	cancel_button = _find_button_by_text(contract_modal, "再掂量掂量")
	if cancel_button != null:
		cancel_button.pressed.emit()
		await process_frame
	contract_state.cash = cash_before_shortage_check
	pond_detail.call("_render_page")
	await _settle_frames()

	contract_button.pressed.emit()
	await _settle_frames()
	var confirm_button := _find_button_by_text(contract_modal, "干！包了")
	if confirm_button == null:
		confirm_button = _find_button_by_text(contract_modal, "干！包了（-%d）" % contract_total_cost)
	_check(confirm_button != null and not confirm_button.disabled, "承包弹窗确认按钮可用")
	_check(confirm_button != null and confirm_button.text == "干！包了（-%d）" % contract_total_cost, "承包弹窗确认按钮显示实际扣款金额")
	if confirm_button == null or confirm_button.disabled:
		_finish()
		return
	var cash_before_contract := contract_state.cash
	confirm_button.pressed.emit()
	await _settle_frames()
	_check_screen(screen_container, "AfterContractChoice", "确认承包进入承包后选择页")
	_check(contract_state.cash == cash_before_contract - contract_total_cost, "确认承包只扣除合计扣款一次")

	var choice_screen := _current_screen(screen_container)
	var choice_money_label := choice_screen.get_node("SafeArea/PageLayout/TopStatusBar/StatusRow/MoneyLabel") as Label
	var choice_contract_value := choice_screen.get_node("SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/ContractPriceRow/RowContent/Value") as Label
	var choice_inspection_value := choice_screen.get_node("SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/InspectionSpentRow/RowContent/Value") as Label
	var choice_total_value := choice_screen.get_node("SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/TotalInvestedRow/RowContent/Value") as Label
	var choice_revenue_value := choice_screen.get_node("SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/RevenueRow/RowContent/Value") as Label
	var choice_profit_value := choice_screen.get_node("SafeArea/PageLayout/ContentScroll/Content/OwnedPondCard/Margin/CardContent/LedgerSummary/ProfitLossRow/RowContent/Value") as Label
	var expected_invested := contract_total_cost + contract_state.inspection_cost_total
	_check(choice_money_label.text.contains(str(contract_state.cash)), "已承包页顶部本钱来自承包扣费后的真实现金")
	_check(choice_contract_value.text == "%d 元" % contract_total_cost, "已承包页账本显示真实承包投入")
	_check(choice_inspection_value.text == "%d 元" % contract_state.inspection_cost_total, "已承包页账本显示真实验塘费")
	_check(choice_total_value.text == "%d 元" % expected_invested, "已承包页当前总投入等于承包价加验塘费")
	_check(choice_revenue_value.text == "0 元", "刚承包后当前收入为 0")
	_check(choice_profit_value.text == "%+d 元" % -expected_invested, "刚承包后当前盈亏为负总投入")
	var owned_pond_visual := choice_screen.find_child("PondVisual", true, false) as TextureRect
	_check(owned_pond_visual != null and owned_pond_visual.texture != null, "已承包页显示鱼塘主视觉贴图")
	var transfer_button := choice_screen.find_child("TransferButton", true, false) as Button
	_check(not transfer_button.disabled, "转包脱手按钮可用")
	transfer_button.pressed.emit()
	await _settle_frames()
	var transfer_modal := choice_screen.get_node("TransferModal") as Control
	_check(transfer_modal.visible, "转包脱手按钮直接显示报价弹窗")
	var buyer_texture := transfer_modal.find_child("BuyerTexture", true, false) as TextureRect
	_check(buyer_texture != null and buyer_texture.texture != null, "转包弹窗显示买家头像贴图")
	_check(transfer_modal.find_child("BuyerSpeechBubble", true, false) != null, "转包弹窗显示买家台词气泡")
	var offer_highlight := transfer_modal.find_child("OfferHighlight", true, false) as Label
	var transfer_ledger := choice_screen.call("_get_transfer_decision_ledger") as Dictionary
	_check(offer_highlight != null and offer_highlight.text == "来人出价：%d 元" % int(transfer_ledger.get("offer_price", 0)), "转包弹窗突出显示对方报价")
	var modal_total_value := transfer_modal.find_child("TotalInvestedRow", true, false).get_node("RowContent/Value") as Label
	var modal_offer_value := transfer_modal.find_child("OfferPriceRow", true, false).get_node("RowContent/Value") as Label
	var modal_profit_value := transfer_modal.find_child("TransferProfitLossRow", true, false).get_node("RowContent/Value") as Label
	var modal_money_value := transfer_modal.find_child("MoneyAfterAcceptRow", true, false).get_node("RowContent/Value") as Label
	var transfer_profit_loss := int(transfer_ledger.get("transfer_profit_loss", 0))
	_check(modal_total_value.text == "%d 元" % int(transfer_ledger.get("total_invested", 0)), "转包弹窗显示当前总投入")
	_check(modal_offer_value.text == "%d 元" % int(transfer_ledger.get("offer_price", 0)), "转包弹窗账单显示对方接手价")
	_check(modal_profit_value.text == ("%+d 元" % transfer_profit_loss if transfer_profit_loss != 0 else "0 元"), "转包弹窗账单显示转包盈亏")
	_check(modal_money_value.text == "%d 元" % int(transfer_ledger.get("money_after_accept", 0)), "转包弹窗账单显示接受后本钱")
	var modal_accept_button := transfer_modal.find_child("AcceptTransferButton", true, false) as Button
	_check(modal_accept_button != null and modal_accept_button.text.begins_with("转！接了这个价（"), "转包弹窗接受按钮显示赚亏结果")
	var transfer_card_dialog := transfer_modal.get_node("DialogCard") as PanelContainer
	var transfer_button_row := transfer_modal.find_child("ButtonRow", true, false) as HBoxContainer
	var modal_continue_button := transfer_modal.find_child("ContinueButton", true, false) as Button
	for viewport_size in [Vector2i(540, 960), Vector2i(720, 1280), Vector2i(1080, 1920)]:
		choice_screen.call("_on_viewport_size_changed")
		await _settle_frames()
		var scale := minf(float(viewport_size.x) / 1080.0, float(viewport_size.y) / 1920.0)
		var scaled_card_width := transfer_card_dialog.size.x * scale
		var scaled_card_height := transfer_card_dialog.size.y * scale
		var width_ratio := scaled_card_width / float(viewport_size.x)
		var transfer_card_in_bounds := scaled_card_width <= float(viewport_size.x - 48) and scaled_card_height <= float(viewport_size.y - 48)
		var transfer_buttons_visible: bool = transfer_button_row.position.y + transfer_button_row.size.y <= transfer_card_dialog.size.y and modal_accept_button.size.y * scale >= 44.0 and modal_continue_button != null and modal_continue_button.size.y * scale >= 44.0
		_check(width_ratio >= 0.85 and width_ratio <= 0.92 and transfer_card_in_bounds and transfer_buttons_visible, "%dx%d 下转包报价弹窗宽高、边界和按钮高度稳定" % [viewport_size.x, viewport_size.y])
	choice_screen.size = Vector2(1080, 1920)
	choice_screen.call("_on_viewport_size_changed")
	await _settle_frames()
	var reject_transfer := _find_button_by_text(transfer_modal, "不转，自己干")
	_check(reject_transfer != null, "转包弹窗存在拒绝按钮")
	if reject_transfer != null:
		reject_transfer.pressed.emit()
		await process_frame
		_check(not transfer_modal.visible, "拒绝转包关闭弹窗并留在当前页")

	var sell_button := choice_screen.find_child("SellOneNetButton", true, false) as Button
	_check(sell_button != null and sell_button.disabled, "未打出鱼情时卖一网按钮正确禁用")
	var sell_action_card := choice_screen.find_child("ActionCard_SellOneNet", true, false) as PanelContainer
	var sell_status := sell_action_card.find_child("ActionStatusLabel", true, false) as Label if sell_action_card != null else null
	var sell_desc := sell_action_card.find_child("ActionDescLabel", true, false) as Label if sell_action_card != null else null
	_check(sell_status != null and sell_desc != null and sell_status.text == "还没下过网" and sell_desc.text.contains("先下一网"), "未打出鱼情时卖一网说明未解锁")

	var self_button := choice_screen.find_child("HarvestSelfButton", true, false) as Button
	self_button.pressed.emit()
	await _settle_frames()
	var work_scroll := choice_screen.find_child("WorkPlanScroll", true, false) as ScrollContainer
	var work_panel := choice_screen.find_child("WorkPlanPanel", true, false) as VBoxContainer
	_check(work_scroll.visible, "自己下网按钮直接打开作业方案列表")
	_check(work_scroll.custom_minimum_size.y >= 760.0, "自己下网方案列表有稳定高度，不会折叠为空白")
	var net_method_textures := work_panel.find_children("NetMethodTexture", "TextureRect", true, false)
	_check(net_method_textures.size() == 3 and net_method_textures.all(func(n: Node) -> bool: return (n as TextureRect).texture != null), "三个作业方案均显示下网方式贴图")
	_check(work_panel.find_children("NetOptionCard_*", "PanelContainer", true, false).size() == 3, "自己下网默认渲染三张下网方式卡片")
	_check(work_panel.find_child("FinalBadge", true, false) != null, "抽干收尾方案显示收尾标记")

	var work_back := choice_screen.find_child("WorkPlanBackButton", true, false) as Button
	_check(work_back.get_index() > work_scroll.get_index(), "返回处置选择固定在方案列表底端")
	work_back.pressed.emit()
	await process_frame
	_check(not work_scroll.visible, "作业方案返回按钮回到处置选择")

	self_button.pressed.emit()
	await _settle_frames()
	var low_button := choice_screen.find_child("LowWorkButton", true, false) as Button
	_check(low_button != null and not low_button.disabled, "小捞一网按钮可用")
	if low_button != null and not low_button.disabled:
		low_button.pressed.emit()
		await _settle_frames()
		var harvest_modal := choice_screen.get_node("HarvestResultModal") as Control
		_check(harvest_modal.visible, "非最终捕捞显示结果弹窗")
		var catch_visual := harvest_modal.find_child("CatchVisual", true, false) as TextureRect
		_check(catch_visual != null and catch_visual.texture != null, "捕捞结果显示鱼获贴图")
		_check(harvest_modal.find_child("NetSummaryCard", true, false) != null, "捕捞结果显示本次收入成本净收益")
		var continue_button := _find_button_by_text(harvest_modal, "收工")
		_check(continue_button != null, "捕捞结果弹窗存在继续按钮")
		if continue_button != null:
			continue_button.pressed.emit()
			await process_frame
			_check(not harvest_modal.visible, "捕捞结果继续按钮关闭弹窗")
		var latest_card := choice_screen.find_child("LatestNetResultCard", true, false) as PanelContainer
		var latest_method := choice_screen.find_child("LatestMethodLabel", true, false) as Label
		var latest_revenue := choice_screen.find_child("LatestRevenueLabel", true, false) as Label
		var latest_cost := choice_screen.find_child("LatestCostLabel", true, false) as Label
		var latest_profit := choice_screen.find_child("LatestProfitLabel", true, false) as Label
		var latest_result := choice_screen.get("latest_net_result") as Dictionary
		var latest_income := int(latest_result.get("fish_income", 0))
		var latest_work_cost := int(latest_result.get("work_cost", 0))
		var latest_net_profit := latest_income - latest_work_cost
		_check(latest_card != null and latest_card.visible, "完成一网后已承包页显示最新一网结果卡")
		_check(latest_method.text.contains("小捞一网") and latest_revenue.text == "鱼获：%d 元" % latest_income and latest_cost.text == "成本：%d 元" % latest_work_cost, "最新一网结果只显示本次方法、收入和成本摘要")
		var latest_profit_ok := (latest_net_profit > 0 and latest_profit.text == "这网净赚：+%d 元" % latest_net_profit) or (latest_net_profit < 0 and latest_profit.text == "这网净亏：%d 元" % abs(latest_net_profit)) or (latest_net_profit == 0 and latest_profit.text.contains("0 元"))
		_check(latest_profit_ok, "最新一网结果显示本次净赚亏")
		var action_section := choice_screen.find_child("ActionSection", true, false) as VBoxContainer
		var ledger_accordion := choice_screen.find_child("LedgerAccordion", true, false) as PanelContainer
		var ledger_detail := choice_screen.find_child("LedgerDetailLabel", true, false) as Label
		var ledger_detail_card := choice_screen.find_child("LedgerDetailCard", true, false) as PanelContainer
		var ledger_toggle := choice_screen.find_child("LedgerToggleButton", true, false) as Button
		var choice_content_scroll := choice_screen.find_child("ContentScroll", true, false) as ScrollContainer
		_check(action_section.get_index() < ledger_accordion.get_index(), "接下来操作区排在账本明细之前")
		_check(not ledger_detail.visible and not ledger_detail_card.visible and ledger_toggle.text.begins_with("账本明细：已实现 ") and ledger_toggle.text.contains("｜含估值 "), "账本明细默认收起且区分已实现和含估值")
		_check(action_section.position.y < choice_content_scroll.size.y, "完成一网后不滚动即可看到接下来怎么处理区域")
		ledger_toggle.pressed.emit()
		await process_frame
		var ledger_text := _collect_label_text(ledger_detail_card)
		_check(ledger_detail_card.visible and ledger_text.contains("收入") and ledger_text.contains("支出") and ledger_text.contains("塘口估值") and ledger_text.contains("账本结果"), "点击后展开分区账本明细")
		_check(ledger_text.contains("已实现盈亏") and ledger_text.contains("含估值盈亏") and ledger_text.contains("估值不是已入账现金"), "账本明细解释已实现与含估值口径")
		_check(not ledger_text.contains("其他收入\n0 元") and not ledger_text.contains("人工费\n0 元") and not ledger_text.contains("抽水费\n0 元"), "账本明细默认隐藏 0 元项目")
		choice_screen.call("_render")
		await process_frame
		_check(ledger_detail_card.visible, "手动展开账本后刷新页面不会强制收起")

	var choice_state := choice_screen.get("game_state") as GameState
	choice_screen.set("current_one_net_offer", ActionResolver.new(42).generate_one_net_offer(choice_state.current_pond))
	choice_screen.call("_render")
	await process_frame
	_check(not sell_button.disabled, "打出鱼情后卖一网按钮可用")
	sell_button.pressed.emit()
	await _settle_frames()
	var sell_modal := choice_screen.get_node("SellOneNetModal") as Control
	var sell_dialog := sell_modal.find_child("SellOneNetDialogCard", true, false) as PanelContainer
	var sell_highlight := sell_modal.find_child("SellOneNetOfferHighlight", true, false) as Label
	var current_money_row := sell_modal.find_child("CurrentMoneyRow", true, false) as Label
	var after_money_row := sell_modal.find_child("MoneyAfterSellOneNetRow", true, false) as Label
	var accept_sell_button := _find_button_with_prefix(sell_modal, "接！卖给他（+")
	var reject_sell_button := _find_button_by_text(sell_modal, "再等等看")
	var offered_income := int(Dictionary(choice_screen.get("current_one_net_offer")).get("income", 0))
	var money_before_sell := choice_state.cash
	_check(sell_modal.visible and sell_dialog != null, "卖一网按钮打开报价弹窗")
	if sell_dialog == null:
		_finish()
		return
	_check(sell_highlight != null and sell_highlight.text == "来人出到 %d 元" % offered_income, "卖一网弹窗突出显示买家出价")
	_check(current_money_row != null and after_money_row != null and current_money_row.text == "兜里有：%d 元" % money_before_sell and after_money_row.text == "接了兜里变：%d 元" % (money_before_sell + offered_income), "卖一网弹窗显示当前本钱和接受后本钱")
	_check(accept_sell_button != null and reject_sell_button != null and accept_sell_button.text == "接！卖给他（+%d）" % offered_income, "卖一网弹窗按钮主次和报价文案完整")
	for viewport_size in [Vector2i(540, 960), Vector2i(720, 1280), Vector2i(1080, 1920)]:
		choice_screen.call("_on_viewport_size_changed")
		await _settle_frames()
		var scale := minf(float(viewport_size.x) / 1080.0, float(viewport_size.y) / 1920.0)
		var scaled_dialog_width := sell_dialog.size.x * scale
		var scaled_dialog_height := sell_dialog.size.y * scale
		var sell_width_ratio := scaled_dialog_width / float(viewport_size.x)
		var sell_card_in_bounds := scaled_dialog_width <= float(viewport_size.x - 48) and scaled_dialog_height <= float(viewport_size.y * 0.80)
		var sell_buttons := sell_modal.find_child("ButtonRow", true, false) as HBoxContainer
		var bottom_gap := sell_dialog.size.y - (sell_buttons.position.y + sell_buttons.size.y) if sell_buttons != null else 9999.0
		var sell_buttons_visible := sell_buttons != null and sell_buttons.position.y + sell_buttons.size.y <= sell_dialog.size.y
		var sell_dialog_compact := scaled_dialog_height <= float(viewport_size.y * 0.55) and bottom_gap <= 90.0
		_check(sell_width_ratio >= 0.85 and sell_width_ratio <= 0.92 and sell_card_in_bounds and sell_buttons_visible and sell_dialog_compact, "%dx%d 下卖一网弹窗自适应高度且按钮下方无大空白" % [viewport_size.x, viewport_size.y])
	choice_screen.size = Vector2(1080, 1920)
	choice_screen.call("_on_viewport_size_changed")
	await _settle_frames()
	if accept_sell_button != null:
		accept_sell_button.pressed.emit()
		await _settle_frames()
	var success_banner := choice_screen.find_child("SellOneNetResultBanner", true, false) as PanelContainer
	var success_banner_title: Label = null
	if success_banner != null:
		success_banner_title = success_banner.find_child("BannerTitle", true, false) as Label
	var revenue_breakdown := choice_screen.find_child("RevenueBreakdownLabel", true, false) as Label
	var sell_action_card_after := choice_screen.find_child("ActionCard_SellOneNet", true, false) as PanelContainer
	_check(choice_state.sold_one_net, "卖一网接受按钮执行交易并更新状态")
	_check(success_banner != null and success_banner.visible and success_banner_title != null and success_banner_title.text.contains("+%d 元到兜里" % offered_income), "卖一网成功后显示明显入账反馈条")
	_check(revenue_breakdown != null and revenue_breakdown.visible and revenue_breakdown.text.contains("鱼获收入") and revenue_breakdown.text.contains("卖一网入账 +%d 元" % offered_income), "当前收入拆分鱼获收入和卖一网入账")
	_check(sell_action_card_after != null and not sell_action_card_after.visible, "已卖出后操作区不显示大号卖一网按钮")

	self_button.pressed.emit()
	await _settle_frames()
	var standard_button := choice_screen.find_child("StandardWorkButton", true, false) as Button
	_check(standard_button != null and not standard_button.disabled, "稳捞一网按钮可用")
	if standard_button != null and not standard_button.disabled:
		standard_button.pressed.emit()
		await _settle_frames()
		var standard_modal := choice_screen.get_node("HarvestResultModal") as Control
		_check(standard_modal.visible, "稳捞一网显示结果弹窗")
		var standard_continue := _find_button_by_text(standard_modal, "收工")
		if standard_continue != null:
			standard_continue.pressed.emit()
			await process_frame

	self_button.pressed.emit()
	await _settle_frames()
	var full_button := choice_screen.find_child("FullWorkButton", true, false) as Button
	_check(full_button != null and not full_button.disabled, "抽干收尾按钮可用")
	if full_button == null or full_button.disabled:
		_finish()
		return
	full_button.pressed.emit()
	await _settle_frames()
	var drain_confirm := root.get_node("PopupManager") as CanvasLayer
	_check(drain_confirm.visible and _find_button_by_text(drain_confirm, "抽干收尾") != null, "抽干收尾先显示最终结算确认")
	var confirm_drain := _find_button_by_text(drain_confirm, "抽干收尾")
	if confirm_drain != null:
		confirm_drain.pressed.emit()
		await _settle_frames()
	var final_modal := choice_screen.get_node("HarvestResultModal") as Control
	_check(final_modal.visible, "抽干收尾先显示这一网结果")
	var final_continue := _find_button_by_text(final_modal, "收工")
	if final_continue != null:
		final_continue.pressed.emit()
		await _settle_frames()
	_check_screen(screen_container, "Settlement", "收下抽干结果后进入结算页")

	var settlement := _current_screen(screen_container)
	var settlement_visual := settlement.find_child("SettlementVisual", true, false) as TextureRect
	_check(settlement_visual != null and settlement_visual.texture != null, "结算页显示结算主视觉贴图")
	_check(settlement.find_child("FinalLedgerSection", true, false) != null, "结算页显示最终公式分区")
	var next_button := settlement.find_child("NextButton", true, false) as Button
	_check(next_button != null, "结算页存在下一天按钮")
	if next_button == null:
		_finish()
		return
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
	_check(restart_contract != null, "重新开始流程存在承包按钮")
	if restart_contract == null:
		_finish()
		return
	restart_contract.pressed.emit()
	await _settle_frames()
	var restart_contract_modal := root.get_node("PopupManager") as CanvasLayer
	var restart_state := restart_detail.get("game_state") as GameState
	var restart_pond := restart_detail.get("pond") as Dictionary
	var restart_preview := restart_state.get_contract_preview(restart_pond)
	var restart_confirm := _find_button_by_text(restart_contract_modal, "干！包了（-%d）" % int(restart_preview.get("contract_total_cost", 0)))
	_check(restart_confirm != null, "重新开始流程存在承包确认按钮")
	if restart_confirm == null:
		_finish()
		return
	restart_confirm.pressed.emit()
	await _settle_frames()
	var restart_choice := _current_screen(restart_container)
	var restart_transfer := restart_choice.find_child("TransferButton", true, false) as Button
	_check(restart_transfer != null, "重新开始流程转包脱手按钮存在")
	if restart_transfer == null:
		_finish()
		return
	restart_transfer.pressed.emit()
	await _settle_frames()
	var restart_transfer_modal := restart_choice.get_node("TransferModal") as Control
	var restart_choice_state := restart_choice.get("game_state") as GameState
	var restart_transfer_ledger := restart_choice.call("_get_transfer_decision_ledger") as Dictionary
	var cash_before_transfer := restart_choice_state.cash
	var accept_transfer := restart_transfer_modal.find_child("AcceptTransferButton", true, false) as Button
	_check(accept_transfer != null, "转包弹窗存在接受按钮")
	if accept_transfer != null:
		accept_transfer.pressed.emit()
		await _settle_frames()
		if int(restart_transfer_ledger.get("transfer_profit_loss", 0)) < 0:
			var loss_confirm := _find_button_by_text(root.get_node("PopupManager"), "转出去，认亏")
			_check(loss_confirm != null, "亏损转包先显示二次确认")
			if loss_confirm != null:
				loss_confirm.pressed.emit()
				await _settle_frames()
		_check_screen(restart_container, "Settlement", "接受转包进入结算页")
		_check(restart_choice_state.cash == cash_before_transfer + int(restart_transfer_ledger.get("offer_price", 0)), "接受转包后本钱增加对方接手价")
		_check(str(restart_choice_state.current_pond.get("status", "")) == "transferred", "接受转包后鱼塘状态记录为 transferred")
		_check(int(restart_choice_state.current_pond.get("transfer_profit_loss", 0)) == int(restart_transfer_ledger.get("transfer_profit_loss", 0)), "接受转包后记录本次转包盈亏")

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


func _find_button_with_prefix(node: Node, prefix: String) -> Button:
	for child in node.find_children("*", "Button", true, false):
		var button := child as Button
		if button.text.begins_with(prefix):
			return button
	return null


func _collect_label_text(node: Node) -> String:
	var lines: Array[String] = []
	if node == null:
		return ""
	for child in node.find_children("*", "Label", true, false):
		var label := child as Label
		if label.visible:
			lines.append(label.text)
	return "\n".join(lines)


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
