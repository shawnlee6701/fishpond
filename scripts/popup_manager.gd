extends CanvasLayer

const UI_THEME := preload("res://themes/UI_Theme.tres")

const CONTRACT_DIALOG_BG_TEXTURE: Texture2D = preload("res://assets/ui/contract_dialog_bg.png")
const TRANSFER_DIALOG_BG_TEXTURE: Texture2D = preload("res://assets/ui/transfer_dialog_bg.png")
const BALANCE_HIGHLIGHT_BG_TEXTURE: Texture2D = preload("res://assets/ui/balance_highlight_bg.png")
const STATUS_BOX_BG_TEXTURE: Texture2D = preload("res://assets/ui/status_box_bg.png")
const BUTTON_ACCEPT_TEXTURE: Texture2D = preload("res://assets/buttons/button_accept.png")
const BUTTON_DANGER_CONFIRM_TEXTURE: Texture2D = preload("res://assets/buttons/button_danger_confirm.png")
const BUTTON_SECONDARY_TEXTURE: Texture2D = preload("res://assets/buttons/button_secondary.png")
const UIKit := preload("res://scripts/ui_kit.gd")

var dim_overlay: Panel
var center_container: CenterContainer
var modal_panel: PanelContainer
var content_stack: VBoxContainer
var title_label: Label
var subtitle_label: Label
var balance_highlight: Label
var dialog_body: VBoxContainer
var bill_rows: VBoxContainer
var status_box: PanelContainer
var status_title_label: Label
var status_desc_label: Label
var warning_label: Label
var message_label: Label
var cancel_button: Button
var confirm_button: Button
var on_confirm_callback: Callable
var on_cancel_callback: Callable
var close_on_overlay := true
var is_submitting := false


func _ready() -> void:
	# Keep global confirmation popups above every routed gameplay page.
	layer = 100
	visible = false
	_build_popup_tree()
	get_viewport().size_changed.connect(_resize_modal)


func show_confirm(config: Dictionary) -> void:
	is_submitting = false
	close_on_overlay = bool(config.get("close_on_overlay", true))
	on_confirm_callback = config.get("on_confirm", Callable()) as Callable
	on_cancel_callback = config.get("on_cancel", Callable()) as Callable

	var is_transfer := bool(config.get("transfer_dialog", false))
	var is_danger := bool(config.get("danger_confirm", false))
	_apply_panel_texture(modal_panel, TRANSFER_DIALOG_BG_TEXTURE if is_transfer else CONTRACT_DIALOG_BG_TEXTURE, 40, 40)
	_apply_button_texture(confirm_button, BUTTON_DANGER_CONFIRM_TEXTURE if is_danger else BUTTON_ACCEPT_TEXTURE)

	title_label.text = str(config.get("title", "确认"))
	subtitle_label.text = str(config.get("subtitle", config.get("message", "")))
	subtitle_label.visible = not subtitle_label.text.is_empty()

	var balance_text := str(config.get("balance_text", ""))
	balance_highlight.text = balance_text
	balance_highlight.visible = not balance_text.is_empty()

	message_label.text = str(config.get("body", config.get("description", "")))
	message_label.visible = not message_label.text.is_empty()

	_render_bill_rows(config.get("bill_rows", []))
	_render_status(config)

	warning_label.text = str(config.get("warning_text", ""))
	warning_label.visible = not warning_label.text.is_empty()

	cancel_button.text = str(config.get("cancel_text", "取消"))
	confirm_button.text = str(config.get("confirm_text", "确认"))
	confirm_button.disabled = bool(config.get("confirm_disabled", false))

	visible = true
	dim_overlay.visible = true
	dim_overlay.modulate.a = 0.0
	_resize_modal()

	var tween := create_tween()
	tween.tween_property(dim_overlay, "modulate:a", 1.0, 0.12)


func hide_popup(call_cancel := false) -> void:
	visible = false
	dim_overlay.visible = false
	is_submitting = false
	if call_cancel and on_cancel_callback.is_valid():
		on_cancel_callback.call()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		hide_popup(true)
		get_viewport().set_input_as_handled()


func _build_popup_tree() -> void:
	dim_overlay = Panel.new()
	dim_overlay.name = "DimOverlay"
	dim_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	dim_overlay.theme = UI_THEME
	var overlay_style := StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.0, 0.0, 0.0, 0.6)
	dim_overlay.add_theme_stylebox_override("panel", overlay_style)
	dim_overlay.gui_input.connect(_on_dim_overlay_input)
	add_child(dim_overlay)

	center_container = CenterContainer.new()
	center_container.name = "ModalCenter"
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim_overlay.add_child(center_container)

	modal_panel = PanelContainer.new()
	modal_panel.name = "ConfirmContractDialog"
	modal_panel.theme = UI_THEME
	modal_panel.theme_type_variation = &"ContractDialogCard"
	modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_panel_texture(modal_panel, CONTRACT_DIALOG_BG_TEXTURE, 40)
	center_container.add_child(modal_panel)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	modal_panel.add_child(margin)

	content_stack = VBoxContainer.new()
	content_stack.name = "ContentStack"
	content_stack.add_theme_constant_override("separation", 8)
	margin.add_child(content_stack)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.theme_type_variation = &"InspectDialogTitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_stack.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.theme_type_variation = &"ContractDialogSubtitleLabel"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_stylebox_override("normal", UIKit.make_translucent_readability_panel(0.78))
	content_stack.add_child(subtitle_label)

	balance_highlight = Label.new()
	balance_highlight.name = "BalanceHighlight"
	balance_highlight.theme_type_variation = &"InspectDialogSummaryLabel"
	balance_highlight.custom_minimum_size = Vector2(0, 56)
	balance_highlight.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance_highlight.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	balance_highlight.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_label_texture(balance_highlight, BALANCE_HIGHLIGHT_BG_TEXTURE, 20, 8, 20)
	content_stack.add_child(balance_highlight)

	dialog_body = VBoxContainer.new()
	dialog_body.name = "DialogBody"
	dialog_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_body.add_theme_constant_override("separation", 8)
	content_stack.add_child(dialog_body)

	bill_rows = VBoxContainer.new()
	bill_rows.name = "BillRows"
	bill_rows.add_theme_constant_override("separation", 2)
	dialog_body.add_child(bill_rows)

	status_box = PanelContainer.new()
	status_box.name = "StatusBox"
	status_box.theme_type_variation = &"ContractStatusOkPanel"
	_apply_panel_texture(status_box, STATUS_BOX_BG_TEXTURE, 16, 20)
	dialog_body.add_child(status_box)

	var status_content := VBoxContainer.new()
	status_content.name = "StatusContent"
	status_content.add_theme_constant_override("separation", 4)
	status_box.add_child(status_content)

	status_title_label = Label.new()
	status_title_label.name = "StatusTitleLabel"
	status_title_label.theme_type_variation = &"ContractStatusTitleLabel"
	status_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_content.add_child(status_title_label)

	status_desc_label = Label.new()
	status_desc_label.name = "StatusDescLabel"
	status_desc_label.theme_type_variation = &"ContractStatusDescLabel"
	status_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_content.add_child(status_desc_label)

	warning_label = Label.new()
	warning_label.name = "WarningLabel"
	warning_label.theme_type_variation = &"InspectWarningLabel"
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_body.add_child(warning_label)

	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.theme_type_variation = &"InspectDialogBodyLabel"
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_stylebox_override("normal", UIKit.make_translucent_readability_panel(0.82))
	dialog_body.add_child(message_label)

	var action_row := HBoxContainer.new()
	action_row.name = "ButtonRow"
	action_row.add_theme_constant_override("separation", 18)
	content_stack.add_child(action_row)

	cancel_button = Button.new()
	cancel_button.name = "CancelButton"
	cancel_button.custom_minimum_size = Vector2(0, 96)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_texture(cancel_button, BUTTON_SECONDARY_TEXTURE)
	cancel_button.pressed.connect(_on_cancel_pressed)
	action_row.add_child(cancel_button)

	confirm_button = Button.new()
	confirm_button.name = "ConfirmButton"
	confirm_button.custom_minimum_size = Vector2(0, 96)
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_button.theme_type_variation = &"PondActionButton"
	_apply_button_texture(confirm_button, BUTTON_ACCEPT_TEXTURE)
	confirm_button.pressed.connect(_on_confirm_pressed)
	action_row.add_child(confirm_button)


func _apply_panel_texture(panel: PanelContainer, texture: Texture2D, margin: int, texture_margin: int = 0) -> void:
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


func _apply_label_texture(label: Label, texture: Texture2D, margin_h: int, margin_v: int, texture_margin: int = 0) -> void:
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
	var normal := _make_nine_patch_style(texture, Color(1.0, 1.0, 1.0, 1.0))
	var hover := _make_nine_patch_style(texture, Color(1.12, 1.12, 1.12, 1.0))
	var pressed := _make_nine_patch_style(texture, Color(0.88, 0.88, 0.88, 1.0))
	var disabled := _make_nine_patch_style(texture, Color(0.65, 0.65, 0.65, 0.85))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)


func _make_nine_patch_style(texture: Texture2D, modulate: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = modulate
	var patch := 20
	style.texture_margin_left = patch
	style.texture_margin_top = patch
	style.texture_margin_right = patch
	style.texture_margin_bottom = patch
	return style


func _render_bill_rows(rows_value: Variant) -> void:
	_clear_children(bill_rows)
	if not rows_value is Array:
		bill_rows.visible = false
		return

	var rows := rows_value as Array
	bill_rows.visible = not rows.is_empty()
	for row_variant in rows:
		var row_data := row_variant as Dictionary
		if not bool(row_data.get("visible", true)):
			continue
		bill_rows.add_child(_build_bill_row(row_data))


func _build_bill_row(row_data: Dictionary) -> PanelContainer:
	var row := PanelContainer.new()
	row.name = str(row_data.get("name", "BillRow"))
	row.custom_minimum_size = Vector2(0, 38)
	row.add_theme_stylebox_override("panel", UIKit.make_translucent_readability_panel(0.68, 10, 0.45))

	var row_content := HBoxContainer.new()
	row_content.name = "RowContent"
	row_content.add_theme_constant_override("separation", 12)
	row.add_child(row_content)

	var name_label := Label.new()
	name_label.name = "Label"
	name_label.theme_type_variation = &"ContractBillNameLabel"
	name_label.text = str(row_data.get("label", ""))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row_content.add_child(name_label)

	var value_label := Label.new()
	value_label.name = "Value"
	value_label.theme_type_variation = &"ContractBillNegativeValueLabel" if bool(row_data.get("negative", false)) else &"ContractBillValueLabel"
	value_label.custom_minimum_size = Vector2(260, 0)
	value_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	value_label.text = str(row_data.get("value", ""))
	row_content.add_child(value_label)
	return row


func _render_status(config: Dictionary) -> void:
	var status_title := str(config.get("status_title", ""))
	var status_desc := str(config.get("status_desc", ""))
	status_box.visible = not status_title.is_empty() or not status_desc.is_empty()
	if not status_box.visible:
		return

	var status_type := str(config.get("status_type", "ok"))
	if status_type == "bad":
		status_box.theme_type_variation = &"ContractStatusBadPanel"
	elif status_type == "tight":
		status_box.theme_type_variation = &"ContractStatusTightPanel"
	else:
		status_box.theme_type_variation = &"ContractStatusOkPanel"

	status_title_label.text = status_title
	status_desc_label.text = status_desc


func _resize_modal() -> void:
	if modal_panel == null or center_container == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var safe_width := maxf(1.0, viewport_size.x - 48.0)
	var dialog_width := clampf(viewport_size.x * 0.9, minf(360.0, safe_width), minf(980.0, safe_width))
	modal_panel.custom_minimum_size = Vector2(dialog_width, 0)


func _on_dim_overlay_input(event: InputEvent) -> void:
	if not close_on_overlay:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_popup(true)
	elif event is InputEventScreenTouch and event.pressed:
		hide_popup(true)


func _play_sfx(effect_id: String) -> void:
	var sfx := get_tree().root.get_node_or_null("SfxManager")
	if sfx != null and sfx.has_method("play"):
		sfx.call("play", effect_id)


func _on_cancel_pressed() -> void:
	_play_sfx("ui_tap_soft")
	hide_popup(true)


func _on_confirm_pressed() -> void:
	if is_submitting or confirm_button.disabled:
		return
	_play_sfx("ui_tap_soft")
	is_submitting = true
	confirm_button.disabled = true
	hide_popup(false)
	if on_confirm_callback.is_valid():
		on_confirm_callback.call()


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
