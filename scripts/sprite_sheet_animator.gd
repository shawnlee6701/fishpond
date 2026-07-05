class_name SpriteSheetAnimator
extends TextureRect

## Sprite-sheet-based frame animator for Control-based UI.
## Slices a grid sprite sheet and cycles through [total_frames] frames at [fps].
## Emits [signal animation_finished] when a non-looping animation reaches its last frame.

signal animation_finished

@export var spritesheet: Texture2D
@export var grid_size: int = 5
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


func _update_frame() -> void:
	if spritesheet == null:
		return

	var frame_w: float = spritesheet.get_width() / float(grid_size)
	var frame_h: float = spritesheet.get_height() / float(grid_size)
	var col: int = _frame_index % grid_size
	var row: int = _frame_index / grid_size
	_atlas.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
