class_name SpriteSheetAnimator
extends TextureRect

## Sprite-sheet-based frame animator for Control-based UI.
## Slices a grid sprite sheet and cycles through [total_frames] frames at [fps].
## Supports square grids via [member grid_size] or non-square grids via [member columns] / [member rows].
## Emits [signal animation_finished] when a non-looping animation reaches its last frame.

signal animation_finished

@export_group("Grid Layout")
@export var spritesheet: Texture2D
## Number of columns when using a non-square grid. Leave 0 to use [member grid_size] for both axes.
@export var columns: int = 0
## Number of rows when using a non-square grid. Leave 0 to use [member grid_size] for both axes.
@export var rows: int = 0
## Legacy square-grid size. Ignored when [member columns] and [member rows] are both set.
@export var grid_size: int = 5

@export_group("Playback")
@export var total_frames: int = 24
@export var fps: float = 12.0
@export var autoplay: bool = true
@export var loop: bool = true

var _frame_index: int = 0
var _frame_timer: float = 0.0
var _atlas: AtlasTexture
var _playing: bool = false


func _ready() -> void:
	if spritesheet == null:
		push_error("SpriteSheetAnimator: spritesheet is not assigned on %s" % get_path())
		return

	_atlas = AtlasTexture.new()
	_atlas.atlas = spritesheet
	texture = _atlas
	_update_frame()

	if autoplay:
		play()


func _process(delta: float) -> void:
	if not _playing:
		return

	_frame_timer += delta
	if _frame_timer < 1.0 / fps:
		return

	_frame_timer -= 1.0 / fps

	if _frame_index < total_frames - 1:
		_frame_index += 1
		_update_frame()
	elif not loop:
		_playing = false
		animation_finished.emit()
	else:
		_frame_index = 0
		_update_frame()


func play() -> void:
	_playing = true


func stop() -> void:
	_playing = false


func reset() -> void:
	_frame_index = 0
	_frame_timer = 0.0
	_update_frame()


func _get_columns() -> int:
	return columns if columns > 0 else grid_size


func _get_rows() -> int:
	return rows if rows > 0 else grid_size


func _update_frame() -> void:
	if spritesheet == null:
		return

	var cols: int = _get_columns()
	var rows_count: int = _get_rows()
	if cols <= 0 or rows_count <= 0:
		push_error("SpriteSheetAnimator: invalid grid dimensions on %s" % get_path())
		return

	var frame_w: float = spritesheet.get_width() / float(cols)
	var frame_h: float = spritesheet.get_height() / float(rows_count)
	var col: int = _frame_index % cols
	var row: int = _frame_index / cols
	_atlas.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
