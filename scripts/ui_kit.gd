extends RefCounted
class_name FishPoolUIKit

const BG := Color(0.055, 0.11, 0.095, 1.0)
const SURFACE := Color(0.94, 0.86, 0.68, 1.0)
const SURFACE_DARK := Color(0.16, 0.25, 0.19, 1.0)
const CARD := Color(0.99, 0.94, 0.80, 1.0)
const CARD_ALT := Color(0.90, 0.80, 0.58, 1.0)
const INK := Color(0.12, 0.10, 0.06, 1.0)
const MUTED := Color(0.34, 0.31, 0.23, 1.0)
const CREAM := Color(1.0, 0.96, 0.83, 1.0)
const GREEN := Color(0.12, 0.36, 0.24, 1.0)
const GREEN_LIGHT := Color(0.22, 0.53, 0.34, 1.0)
const GOLD := Color(0.92, 0.62, 0.20, 1.0)
const RED := Color(0.66, 0.16, 0.11, 1.0)
const DISABLED := Color(0.42, 0.43, 0.38, 1.0)
const FONT_MIN := 24
const FONT_BODY := 27
const FONT_SECONDARY := 24
const FONT_SECTION := 31
const FONT_IMPORTANT := 32
const FONT_PAGE_TITLE := 44
const PAGE_ACTION_HEIGHT := 96
const MODAL_ACTION_HEIGHT := 84
const DESIGN_SIZE := Vector2(1080, 1920)

static var animations_enabled: bool = true


static func _static_init() -> void:
	# headless 模式下禁用所有动效，避免阻止测试 tween 卡住帧循环
	if OS.has_feature("headless"):
		animations_enabled = false
		return
	if not Engine.is_editor_hint() and DisplayServer.get_name() == "headless":
		animations_enabled = false
const PAGE_SAFE_X := 52.0
const PAGE_TOP := 32.0
const PAGE_BOTTOM := 48.0
const STATUS_HEIGHT := 64.0
const CONTENT_TOP := 110.0
const ACTION_TOP := 1660.0
const ACTION_BOTTOM := 1810.0

static func make_style(bg: Color, border: Color, radius: int = 18, border_width: int = 3, shadow := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	if shadow:
		style.shadow_color = Color(0, 0, 0, 0.24)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 5)
	return style


static func make_translucent_readability_panel(alpha := 0.78, radius := 16, border_alpha := 0.55) -> StyleBoxFlat:
	## Returns a cream/light panel that lets the global background show through slightly
	## while keeping text readable. Use behind text that sits on top of textured backgrounds.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.99, 0.95, 0.82, alpha)
	style.border_color = Color(0.61, 0.45, 0.25, border_alpha)
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style


static func make_translucent_dark_panel(alpha := 0.72, radius := 16) -> StyleBoxFlat:
	## A darker translucent panel for high-contrast text over busy textures.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.14, 0.10, alpha)
	style.border_color = Color(0.22, 0.36, 0.26, 0.65)
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style


static func apply_texture_button(button: Button, texture: Texture2D, patch := 20) -> void:
	## Applies a nine-patch texture to all button states.
	var normal := _make_nine_patch_style(texture, patch, Color(1.0, 1.0, 1.0, 1.0))
	var hover := _make_nine_patch_style(texture, patch, Color(1.12, 1.12, 1.12, 1.0))
	var pressed := _make_nine_patch_style(texture, patch, Color(0.88, 0.88, 0.88, 1.0))
	var disabled := _make_nine_patch_style(texture, patch, Color(0.65, 0.65, 0.65, 0.85))
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)


static func _make_nine_patch_style(texture: Texture2D, patch: int, modulate: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = modulate
	style.texture_margin_left = patch
	style.texture_margin_top = patch
	style.texture_margin_right = patch
	style.texture_margin_bottom = patch
	return style


static func set_scrollbar_auto_hide(scroll: ScrollContainer) -> void:
	## Hides scrollbars when content fits; shows them only while scrolling / when needed.
	if scroll == null:
		return
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

static func apply_root(root: Control) -> void:
	root.custom_minimum_size = DESIGN_SIZE
	root.add_theme_color_override("font_color", CREAM)
	root.add_theme_font_size_override("font_size", 28)

static func style_top_status(label: Label) -> void:
	style_label(label, "top_status")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var style := make_style(Color(0.93, 0.85, 0.67, 0.94), Color(0.43, 0.31, 0.16, 0.70), 18, 2, true)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	label.add_theme_stylebox_override("normal", style)

static func style_page_title(label: Label) -> void:
	label.add_theme_color_override("font_color", RED)
	label.add_theme_color_override("font_outline_color", Color(1.0, 0.90, 0.68, 0.92))
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_font_size_override("font_size", FONT_PAGE_TITLE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

static func style_modal_title(label: Label) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", Color("6d241f"))

static func style_highlight_label(label: Label, tone := "gold") -> void:
	var border := GOLD
	var font := INK
	if tone == "positive":
		border = GREEN_LIGHT
		font = GREEN
	elif tone == "negative":
		border = RED
		font = RED
	elif tone == "price":
		border = GOLD
		font = RED
	var style := make_style(Color(1.0, 0.92, 0.70, 0.92), border, 14, 3, true)
	style.content_margin_left = 18.0
	style.content_margin_top = 8.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 8.0
	label.add_theme_stylebox_override("normal", style)
	label.add_theme_color_override("font_color", font)
	label.add_theme_font_size_override("font_size", FONT_IMPORTANT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

static func style_main_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", make_style(SURFACE, Color(0.61, 0.45, 0.25), 20, 3, true))
	var margin := panel.get_node_or_null("Margin") as MarginContainer
	if margin != null:
		margin.add_theme_constant_override("margin_left", 22)
		margin.add_theme_constant_override("margin_top", 22)
		margin.add_theme_constant_override("margin_right", 22)
		margin.add_theme_constant_override("margin_bottom", 22)

static func style_card(card: PanelContainer, accent := GREEN) -> void:
	card.add_theme_stylebox_override("panel", make_style(CARD, accent, 14, 3, true))

static func style_page_frame(panel: PanelContainer, accent := GREEN) -> void:
	var style := make_style(Color(0.97, 0.90, 0.72, 0.98), accent, 8, 5, true)
	style.border_width_top = 10
	style.shadow_color = Color(0.10, 0.08, 0.04, 0.30)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 8)
	panel.add_theme_stylebox_override("panel", style)

static func style_message_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", make_style(Color(0.18, 0.30, 0.22, 1.0), Color(0.43, 0.62, 0.39, 1.0), 12, 2, false))

static func style_button(button: Button, role := "secondary") -> void:
	var normal := GREEN
	var hover := GREEN_LIGHT
	var pressed := Color(0.08, 0.26, 0.18, 1.0)
	var border := Color(0.58, 0.76, 0.47, 1.0)
	var font := CREAM
	if role == "primary":
		normal = RED
		hover = Color(0.78, 0.24, 0.15, 1.0)
		pressed = Color(0.48, 0.09, 0.07, 1.0)
		border = GOLD
	elif role == "gold":
		normal = GOLD
		hover = Color(1.0, 0.72, 0.28, 1.0)
		pressed = Color(0.72, 0.42, 0.12, 1.0)
		border = Color(1.0, 0.92, 0.45, 1.0)
		font = Color(0.18, 0.10, 0.04, 1.0)
	elif role == "ghost":
		normal = Color(0.78, 0.72, 0.57, 1.0)
		hover = Color(0.88, 0.80, 0.62, 1.0)
		pressed = Color(0.60, 0.55, 0.44, 1.0)
		border = Color(0.44, 0.36, 0.23, 1.0)
		font = INK

	button.add_theme_stylebox_override("normal", make_style(normal, border, 14, 3, true))
	button.add_theme_stylebox_override("hover", make_style(hover, border, 14, 3, true))
	button.add_theme_stylebox_override("pressed", make_style(pressed, border, 14, 3, false))
	button.add_theme_stylebox_override("disabled", make_style(DISABLED, Color(0.30, 0.32, 0.29, 1.0), 14, 2, false))
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_color_override("font_disabled_color", Color(0.74, 0.74, 0.66, 1.0))
	button.add_theme_font_size_override("font_size", 30)

static func style_label(label: Label, role := "body") -> void:
	if role == "title":
		label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32, 1.0))
		label.add_theme_font_size_override("font_size", 56)
	elif role == "panel_title":
		label.add_theme_color_override("font_color", RED)
		label.add_theme_font_size_override("font_size", FONT_PAGE_TITLE)
	elif role == "content_title":
		label.add_theme_color_override("font_color", INK)
		label.add_theme_font_size_override("font_size", 40)
	elif role == "panel_stat":
		label.add_theme_color_override("font_color", INK)
		label.add_theme_font_size_override("font_size", FONT_BODY)
	elif role == "top_status":
		label.add_theme_color_override("font_color", Color(0.08, 0.18, 0.12, 1.0))
		label.add_theme_font_size_override("font_size", FONT_BODY)
	elif role == "section":
		label.add_theme_color_override("font_color", GREEN)
		label.add_theme_font_size_override("font_size", FONT_SECTION)
	elif role == "body_dark":
		label.add_theme_color_override("font_color", INK)
		label.add_theme_font_size_override("font_size", FONT_BODY)
	elif role == "muted":
		label.add_theme_color_override("font_color", MUTED)
		label.add_theme_font_size_override("font_size", FONT_SECONDARY)
	elif role == "hud":
		label.add_theme_color_override("font_color", CREAM)
		label.add_theme_font_size_override("font_size", 28)
	else:
		label.add_theme_color_override("font_color", CREAM)
		label.add_theme_font_size_override("font_size", 30)

static func style_chip(label: Label, accent := GOLD) -> void:
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_font_size_override("font_size", 28)
	var style := make_style(Color(accent.r * 0.45, accent.g * 0.45, accent.b * 0.45, 1.0), accent, 999, 2, false)
	label.add_theme_stylebox_override("normal", style)

static func make_label(text: String, font_size := 28, color := INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", maxi(FONT_MIN, font_size))
	label.add_theme_color_override("font_color", color)
	return label

static func make_chip(text: String, accent := GREEN) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", make_style(Color(accent.r * 0.55, accent.g * 0.55, accent.b * 0.55, 1.0), accent, 999, 2, false))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)
	var label := make_label(text, FONT_MIN, CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	margin.add_child(label)
	return panel

static func set_safe_panel(panel: Control, left := 22, top := 26, right := -22, bottom := -22) -> void:
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = left
	panel.offset_top = top
	panel.offset_right = right
	panel.offset_bottom = bottom

static func create_modal_layer(root: Control, modal_name: String, paper_texture: Texture2D = null) -> Dictionary:
	var overlay := Control.new()
	overlay.name = modal_name
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 100
	overlay.visible = false
	root.add_child(overlay)

	var mask := ColorRect.new()
	mask.name = "Mask"
	mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mask.color = Color(0.015, 0.02, 0.018, 0.72)
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(mask)

	var card := PanelContainer.new()
	card.name = "Card"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.clip_contents = true
	if paper_texture != null:
		var paper_style := StyleBoxTexture.new()
		paper_style.texture = paper_texture
		paper_style.texture_margin_left = 84.0
		paper_style.texture_margin_top = 84.0
		paper_style.texture_margin_right = 84.0
		paper_style.texture_margin_bottom = 84.0
		paper_style.content_margin_left = 72.0
		paper_style.content_margin_top = 64.0
		paper_style.content_margin_right = 72.0
		paper_style.content_margin_bottom = 64.0
		card.add_theme_stylebox_override("panel", paper_style)
	overlay.add_child(card)

	return {"overlay": overlay, "mask": mask, "card": card}

static func layout_modal(root: Control, card: PanelContainer, width_ratio: float, preferred_height: int, min_size: Vector2i, max_size: Vector2i) -> void:
	var viewport_size := Vector2i(root.size)
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		viewport_size = Vector2i(root.get_viewport_rect().size)
	var safe_width := maxi(1, viewport_size.x - 48)
	var safe_height := maxi(1, viewport_size.y - 48)
	var target_width := clampi(int(viewport_size.x * width_ratio), mini(min_size.x, safe_width), mini(max_size.x, safe_width))
	var target_height := clampi(preferred_height, mini(min_size.y, safe_height), mini(max_size.y, safe_height))
	card.size = Vector2(target_width, target_height)
	card.position = Vector2((viewport_size.x - target_width) * 0.5, (viewport_size.y - target_height) * 0.5)

static func show_modal(root: Control, overlay: Control, card: PanelContainer, width_ratio: float, preferred_height: int, min_size: Vector2i, max_size: Vector2i) -> void:
	layout_modal(root, card, width_ratio, preferred_height, min_size, max_size)
	overlay.visible = true
	root.move_child(overlay, root.get_child_count() - 1)

static func hide_modal(overlay: Control) -> void:
	if overlay != null:
		overlay.visible = false

static func make_image_placeholder(minimum_size: Vector2) -> PanelContainer:
	var placeholder := PanelContainer.new()
	placeholder.name = "ImagePlaceholder"
	placeholder.custom_minimum_size = minimum_size
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var marker := Label.new()
	marker.name = "PlaceholderMarker"
	marker.text = "×"
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	marker.add_theme_font_size_override("font_size", 64)
	placeholder.add_child(marker)
	return placeholder

static func format_run_status(day: int, cash: int, suffix := "") -> String:
	var text := "第 %d 天  |  本钱 %d 元" % [day, cash]
	if not suffix.is_empty():
		text = "%s  |  %s" % [text, suffix]
	return text

static func wrap_nodes_in_scroll(parent: VBoxContainer, nodes: Array[Control], scroll_name := "MobileScroll") -> ScrollContainer:
	var existing := parent.get_node_or_null(scroll_name) as ScrollContainer
	if existing != null:
		return existing

	var insert_index := parent.get_child_count()
	if not nodes.is_empty() and nodes[0].get_parent() == parent:
		insert_index = nodes[0].get_index()

	var scroll := ScrollContainer.new()
	scroll.name = scroll_name
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true

	var inner := VBoxContainer.new()
	inner.name = "Content"
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 12)
	scroll.add_child(inner)

	parent.add_child(scroll)
	parent.move_child(scroll, insert_index)
	for node in nodes:
		if node != null and node.get_parent() == parent:
			parent.remove_child(node)
			inner.add_child(node)

	return scroll


# ---------------------------------------------------------------------------
# 轻量动效 helpers（不影响核心玩法，headless 下自动禁用）
# ---------------------------------------------------------------------------

static func animate_page_entry(screen: Control, direction := 1.0) -> Tween:
	if not animations_enabled or screen == null:
		return null
	screen.modulate.a = 0.0
	var offset := Vector2(48.0 * direction, 0.0)
	screen.position += offset
	var tween := screen.create_tween()
	tween.set_parallel(false)
	tween.tween_property(screen, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(screen, "position", screen.position - offset, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween


static func apply_button_click_feedback(button: Button) -> void:
	if button == null or button.has_meta("_fp_click_feedback"):
		return
	button.set_meta("_fp_click_feedback", true)
	button.pressed.connect(_on_button_clicked_for_animation.bind(button))


static func _on_button_clicked_for_animation(button: Button) -> void:
	if not animations_enabled or not is_instance_valid(button):
		return
	var tween := button.create_tween()
	button.pivot_offset = button.size * 0.5
	tween.tween_property(button, "scale", Vector2(0.94, 0.94), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func animate_emphasis(control: Control, tone := "gold") -> Tween:
	if not animations_enabled or control == null:
		return null
	control.pivot_offset = control.size * 0.5
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2(1.08, 1.08), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


static func animate_pop_in(control: Control) -> Tween:
	if not animations_enabled or control == null:
		return null
	control.pivot_offset = control.size * 0.5
	control.modulate.a = 0.0
	control.scale = Vector2(0.92, 0.92)
	var tween := control.create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


static func animate_shine(control: Control) -> Tween:
	if not animations_enabled or control == null:
		return null
	var tween := control.create_tween()
	var original := control.modulate
	tween.tween_property(control, "modulate", Color(1.5, 1.45, 1.1, 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate", original, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	return tween


static func spawn_sparkles(parent: Control, local_rect: Rect2, tone := "gold") -> void:
	if not animations_enabled or parent == null:
		return
	var particles := CPUParticles2D.new()
	particles.name = "SparkleParticles"
	particles.position = local_rect.position + local_rect.size * 0.5
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.85
	particles.lifetime = 0.7
	particles.amount = 28
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(local_rect.size.x * 0.5, local_rect.size.y * 0.5)
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 90.0
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 180.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.gravity = Vector2(0.0, 280.0)
	particles.color = _sparkle_color(tone)
	particles.z_index = 20
	parent.add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


static func _sparkle_color(tone: String) -> Color:
	if tone == "positive":
		return Color(0.25, 0.85, 0.35)
	if tone == "negative":
		return Color(0.90, 0.25, 0.18)
	return Color(1.0, 0.85, 0.25)
