extends Control

## Graybox-only pond visual. Replace this node with pond_main_visual.png later;
## keep it independent so layout, animation, and interaction can evolve separately.

const POND_FILL := Color("397A66")
const POND_INNER := Color("4E9279")
const POND_EDGE := Color("173D32")
const WATER_LINE := Color(0.78, 0.90, 0.72, 0.72)
const FISH_LINE := Color(0.96, 0.78, 0.35, 0.88)
const BUBBLE := Color(0.84, 0.95, 0.88, 0.72)


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radii := Vector2(size.x * 0.47, size.y * 0.36)
	var shadow_center := center + Vector2(0.0, size.y * 0.025)
	_draw_ellipse(shadow_center, radii, Color(0.03, 0.09, 0.07, 0.34))
	_draw_ellipse(center, radii, POND_FILL)
	_draw_ellipse(center, radii * 0.91, POND_INNER)
	_draw_ellipse_outline(center, radii, POND_EDGE, 8.0)

	_draw_wave(center, radii, -0.34, 0.56)
	_draw_wave(center, radii, 0.02, 0.68)
	_draw_wave(center, radii, 0.35, 0.48)
	_draw_fish(center + Vector2(-radii.x * 0.12, radii.y * 0.10), minf(size.x, size.y) * 0.11)
	_draw_bubbles(center + Vector2(radii.x * 0.42, -radii.y * 0.18), minf(size.x, size.y))


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(65):
		var angle := TAU * float(index) / 64.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _draw_ellipse_outline(center: Vector2, radii: Vector2, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for index in range(65):
		var angle := TAU * float(index) / 64.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_polyline(points, color, width, true)


func _draw_wave(center: Vector2, radii: Vector2, y_ratio: float, width_ratio: float) -> void:
	var half_width := radii.x * width_ratio
	var base_y := center.y + radii.y * y_ratio
	var points := PackedVector2Array()
	for index in range(25):
		var progress := float(index) / 24.0
		var x := lerpf(-half_width, half_width, progress)
		var y := sin(progress * TAU * 2.0) * radii.y * 0.035
		points.append(center + Vector2(x, base_y - center.y + y))
	draw_polyline(points, WATER_LINE, 5.0, true)


func _draw_fish(center: Vector2, length: float) -> void:
	var body_radii := Vector2(length * 0.55, length * 0.25)
	_draw_ellipse_outline(center, body_radii, FISH_LINE, 6.0)
	var tail_root := center + Vector2(-body_radii.x, 0)
	var tail := PackedVector2Array([
		tail_root,
		tail_root + Vector2(-length * 0.34, -length * 0.26),
		tail_root + Vector2(-length * 0.30, length * 0.29),
		tail_root,
	])
	draw_polyline(tail, FISH_LINE, 6.0, true)
	draw_circle(center + Vector2(body_radii.x * 0.58, -body_radii.y * 0.18), 5.0, FISH_LINE)


func _draw_bubbles(origin: Vector2, scale_base: float) -> void:
	draw_arc(origin, scale_base * 0.022, 0.0, TAU, 24, BUBBLE, 4.0, true)
	draw_arc(origin + Vector2(scale_base * 0.055, -scale_base * 0.075), scale_base * 0.014, 0.0, TAU, 20, BUBBLE, 4.0, true)
	draw_arc(origin + Vector2(-scale_base * 0.025, -scale_base * 0.12), scale_base * 0.010, 0.0, TAU, 18, BUBBLE, 3.0, true)
