extends CanvasLayer

## Floating music toggle button.
## Appears on the top-right of the title/home page and toggles background music on/off.
## When music is playing, the note icon rotates clockwise; when paused, it stops.

const ICON_PLAY_PATH := "res://music/icon/music_play.png"
const ICON_MUTE_PATH := "res://music/icon/music_mute.png"

@export var button_size: Vector2 = Vector2(96, 96)
@export var seconds_per_rotation: float = 3.0
@export var right_margin: float = 24.0
@export var top_margin: float = 110.0
@export var shadow_offset: float = 4.0
@export var shadow_alpha: float = 0.4

var _button: TextureButton
var _icon: TextureRect
var _shadow: TextureRect
var _icon_play: Texture2D
var _icon_mute: Texture2D
var _is_music_on: bool = false

func _ready() -> void:
	layer = 10

	_icon_play = load(ICON_PLAY_PATH) as Texture2D
	_icon_mute = load(ICON_MUTE_PATH) as Texture2D
	if _icon_play == null:
		push_error("MusicToggleButton: failed to load icon %s" % ICON_PLAY_PATH)
	if _icon_mute == null:
		push_error("MusicToggleButton: failed to load icon %s" % ICON_MUTE_PATH)
	if _icon_play == null or _icon_mute == null:
		return

	_button = TextureButton.new()
	_button.name = "MusicButton"
	_button.custom_minimum_size = button_size
	_button.anchor_left = 1.0
	_button.anchor_top = 0.0
	_button.anchor_right = 1.0
	_button.anchor_bottom = 0.0
	_button.offset_left = -button_size.x - right_margin
	_button.offset_top = top_margin
	_button.offset_right = -right_margin
	_button.offset_bottom = top_margin + button_size.y
	_button.pressed.connect(_on_pressed)
	add_child(_button)

	_shadow = _create_icon_child("Shadow")
	_shadow.modulate = Color(0.0, 0.0, 0.0, shadow_alpha)
	_shadow.offset_left = shadow_offset
	_shadow.offset_top = shadow_offset
	_shadow.offset_right = shadow_offset
	_shadow.offset_bottom = shadow_offset
	_button.add_child(_shadow)

	_icon = _create_icon_child("Icon")
	_icon.pivot_offset = button_size / 2.0
	_button.add_child(_icon)

	_update_icon()

	BgmManager.track_changed.connect(_on_music_started)
	BgmManager.playback_paused.connect(_on_music_paused)
	BgmManager.playback_resumed.connect(_on_music_resumed)

func _create_icon_child(name: String) -> TextureRect:
	var child := TextureRect.new()
	child.name = name
	child.anchor_left = 0.0
	child.anchor_top = 0.0
	child.anchor_right = 1.0
	child.anchor_bottom = 1.0
	child.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	child.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return child

func _process(delta: float) -> void:
	if _is_music_on and _icon != null and seconds_per_rotation > 0.0:
		# Control.rotation is in radians, so use TAU (2*PI) for a full circle.
		_icon.rotation += (TAU / seconds_per_rotation) * delta

func _on_pressed() -> void:
	if _is_music_on:
		BgmManager.pause()
		_is_music_on = false
	else:
		if BgmManager.is_started():
			BgmManager.resume()
		else:
			BgmManager.start_playback()
		_is_music_on = true
	_update_icon()

func _on_music_started(_track_index: int) -> void:
	_is_music_on = true
	_update_icon()


func _on_music_paused() -> void:
	_is_music_on = false
	_update_icon()


func _on_music_resumed() -> void:
	_is_music_on = true
	_update_icon()


func _update_icon() -> void:
	if _icon == null or _shadow == null:
		return
	var texture: Texture2D = _icon_play if _is_music_on else _icon_mute
	_icon.texture = texture
	_shadow.texture = texture
