extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main_scene: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(main_scene)
	await _settle_frames()

	var game_root := main_scene.get_node("UIRoot/GameRoot") as Control
	var screen_container := game_root.get_node("ScreenContainer") as Control
	var start_button := game_root.get_node("HomeScreen/SafeArea/PageLayout/BottomActionCenter/BottomActionArea/ContinueButton") as Button
	start_button.pressed.emit()
	await _settle_frames()

	var screen := screen_container.get_child(0) as Control
	_check(screen.name == "PondList", "进入现有今日鱼塘页面")
	_check(screen.get_node_or_null("Background") != null, "页面保留原生绿色背景")
	_check(screen.get_node_or_null("SafeArea/PageLayout/TopStatusBar/StatusRow/DayLabel") != null, "状态栏拆分显示天数")
	_check(screen.get_node_or_null("SafeArea/PageLayout/TopStatusBar/StatusRow/MoneyLabel") != null, "状态栏拆分显示本钱")
	_check(screen.get_node_or_null("SafeArea/PageLayout/TopStatusBar/StatusRow/RecordButton") != null, "状态栏保留包塘记录")
	_check(screen.get_node_or_null("SafeArea/PageLayout/PageHeader/TitleLabel") != null, "页面标题独立成组")
	_check(screen.get_node_or_null("SafeArea/PageLayout/PageHeader/HintLabel") != null, "页面提示独立成组")

	var list := screen.get_node("SafeArea/PageLayout/PondListScroll/PondListContainer") as VBoxContainer
	var cards: Array[Node] = []
	for child in list.get_children():
		if child.get_meta("component", "") == "PondCard":
			cards.append(child)
	_check(cards.size() == 3, "当天生成三张统一鱼塘卡")
	if not cards.is_empty():
		var card := cards[0] as Control
		var card_bg := card.get_node("CardBg") as PanelContainer
		var info := card.get_node("CardBg/ContentRow/PondInfoArea") as VBoxContainer
		var price := info.get_node("HeaderRow/PriceBadge") as Label
		var action := info.get_node("ViewButton") as Button
		var thumb := card.get_node("CardBg/ContentRow/PondThumbPlaceholder") as PanelContainer
		_check(card_bg.theme_type_variation == &"PondCardPanel", "卡片底图使用可替换主题槽")
		_check(thumb.find_child("PlaceholderMarker", true, false) == null, "缩略图占位不再显示 X")
		_check(thumb.find_child("ImagePlaceholder", true, false) is PondThumbPlaceholder, "缩略图使用原生自绘水面")
		_check(price.theme_type_variation == &"PondPriceLabel" and price.get_theme_stylebox("normal") is StyleBoxFlat, "价格使用醒目 Badge")
		_check(info.get_node("TagRow").get_child_count() == 3, "卡片显示三个紧凑标签")
		_check((info.get_node("StatGrid") as GridContainer).columns == 3, "关键数据使用三列信息块")
		_check(action.custom_minimum_size.y >= 44.0 and action.theme_type_variation == &"PondActionButton", "主操作按钮满足移动点击尺寸")
		_check(card.size.x <= list.size.x + 1.0, "卡片宽度未溢出滚动容器")

	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			var output_path := argument.trim_prefix("--output=")
			var image := root.get_texture().get_image()
			_check(image != null and image.save_png(output_path) == OK, "页面截图已输出")

	var state := screen.get("game_state") as GameState
	state.cash = 0
	screen.call("_render_ponds")
	await _settle_frames()
	var disabled_action := screen.find_child("ViewButton", true, false) as Button
	var warning_price := screen.find_child("PriceBadge", true, false) as Label
	_check(disabled_action != null and disabled_action.disabled and disabled_action.text == "钱不够", "本钱不足时主操作禁用并显示钱不够")
	_check(warning_price != null and warning_price.theme_type_variation == &"PondPriceWarningLabel", "本钱不足时价格牌进入 warning 状态")

	if failures.is_empty():
		print("POND_LIST_UI_OK")
		quit(0)
	else:
		print("POND_LIST_UI_FAILED: %s" % ", ".join(failures))
		quit(1)


func _settle_frames() -> void:
	await process_frame
	await process_frame
	await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("POND_LIST_OK: %s" % message)
		return
	failures.append(message)
	push_error("POND_LIST_FAIL: %s" % message)
