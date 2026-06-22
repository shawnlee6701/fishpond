extends Control
class_name PondThumbPlaceholder

# Native preview only. Replace this Control with pond_thumb_xxx.png in the art pass.


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var bounds := Rect2(Vector2(14, 14), size - Vector2(28, 28))
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return

	var pond_style := StyleBoxFlat.new()
	pond_style.bg_color = Color("79ad82")
	pond_style.border_color = Color("315d43")
	pond_style.set_border_width_all(4)
	pond_style.set_corner_radius_all(34)
	draw_style_box(pond_style, bounds)

	var water_rect := Rect2(
		bounds.position + Vector2(bounds.size.x * 0.08, bounds.size.y * 0.25),
		Vector2(bounds.size.x * 0.84, bounds.size.y * 0.48)
	)
	var water_style := StyleBoxFlat.new()
	water_style.bg_color = Color("4f8f77")
	water_style.border_color = Color("d6c984")
	water_style.set_border_width_all(3)
	water_style.set_corner_radius_all(int(water_rect.size.y * 0.5))
	draw_style_box(water_style, water_rect)

	var wave_color := Color(0.88, 0.91, 0.70, 0.72)
	for row in range(3):
		var y := water_rect.position.y + water_rect.size.y * (0.28 + row * 0.22)
		var wave := PackedVector2Array()
		for point in range(9):
			var t := float(point) / 8.0
			wave.append(Vector2(
				water_rect.position.x + water_rect.size.x * (0.13 + t * 0.74),
				y + sin(t * TAU * 2.0 + row) * 4.0
			))
		draw_polyline(wave, wave_color, 3.0, true)

	var fish_center := water_rect.position + water_rect.size * Vector2(0.56, 0.56)
	var fish_color := Color(0.10, 0.23, 0.18, 0.58)
	draw_circle(fish_center, maxf(8.0, water_rect.size.x * 0.055), fish_color)
	var tail_size := maxf(10.0, water_rect.size.x * 0.065)
	var tail := PackedVector2Array([
		fish_center - Vector2(tail_size * 0.72, 0),
		fish_center - Vector2(tail_size * 1.45, tail_size * 0.62),
		fish_center - Vector2(tail_size * 1.45, -tail_size * 0.62),
	])
	draw_colored_polygon(tail, fish_color)

	var bubble_color := Color(0.93, 0.96, 0.76, 0.78)
	draw_circle(water_rect.position + water_rect.size * Vector2(0.73, 0.30), 5.0, bubble_color)
	draw_circle(water_rect.position + water_rect.size * Vector2(0.79, 0.20), 3.5, bubble_color)
	draw_circle(water_rect.position + water_rect.size * Vector2(0.28, 0.68), 4.0, bubble_color)
