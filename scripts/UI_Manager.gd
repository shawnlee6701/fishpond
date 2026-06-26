extends Control

const UIKit := preload("res://scripts/ui_kit.gd")

@onready var theme_resource = load("res://themes/UI_Theme.tres")


func _ready():
	get_tree().node_added.connect(_on_node_added)
	# 强制所有子节点使用主题，并清除所有覆盖
	apply_theme_recursive(self)

	# 给所有 Label 统一加描边（土味国风必备）
	apply_outline_recursive(self)


func _exit_tree():
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)


func _on_node_added(node: Node):
	if node == self or is_ancestor_of(node):
		_apply_to_added_subtree.call_deferred(node)


func _apply_to_added_subtree(node: Node):
	if not is_instance_valid(node) or (node != self and not is_ancestor_of(node)):
		return
	apply_theme_recursive(node)
	apply_outline_recursive(node)


func apply_theme_recursive(node: Node):
	if node is Control:
		node.theme = theme_resource
		# 清除字体颜色覆盖，保持主题语义色一致
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
			node.remove_theme_color_override(color_name)
		node.remove_theme_constant_override("corner_radius")
		node.remove_theme_constant_override("h_separation")
		node.remove_theme_constant_override("v_separation")

	if node is Button:
		UIKit.apply_button_click_feedback(node)

	for child in node.get_children():
		apply_theme_recursive(child)


func apply_outline_recursive(node: Node):
	if node is Label:
		node.add_theme_constant_override("outline_size", 2)
		# Keep each theme variation's semantic text color; only the outline is global.
		node.add_theme_color_override("font_outline_color", Color("#000000"))

	for child in node.get_children():
		apply_outline_recursive(child)
