extends RefCounted
class_name UIController

static func replace_screen(container: Control, next_screen: Control) -> void:
	for child in container.get_children():
		child.queue_free()

	container.add_child(next_screen)
	next_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
