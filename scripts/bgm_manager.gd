extends Node

## Global background-music service.
## Cycles through a list of tracks in order and loops back to the start.
## Call BgmManager.start_playback() from any scene to begin the playlist.

## Emitted when the active background track changes.
## [param track_index] is the zero-based index of the new track.
signal track_changed(track_index: int)
signal playback_paused
signal playback_resumed

## Linear volume multiplier for the music (0.0 = silent, 1.0 = full).
@export_range(0.0, 1.0, 0.01) var volume_linear: float = 0.35

const _TRACK_PATHS: Array[String] = [
	"res://music/bgm_01.mp3",
	"res://music/bgm_02.mp3",
]

var _tracks: Array[AudioStream] = []
var _player: AudioStreamPlayer
var _current_index: int = -1
var _started: bool = false

func _ready() -> void:
	for path: String in _TRACK_PATHS:
		var stream: AudioStream = load(path) as AudioStream
		if stream == null:
			push_error("BgmManager: failed to load track %s" % path)
			continue
		_tracks.append(stream)

	_player = AudioStreamPlayer.new()
	_player.name = "BgmPlayer"
	add_child(_player)
	_player.finished.connect(_on_track_finished)
	_set_player_bus()
	_apply_volume()


func _exit_tree() -> void:
	if _player != null:
		_player.stop()
		_player.stream = null
		_player.free()
	_tracks.clear()
	_player = null

func _set_player_bus() -> void:
	if AudioServer.get_bus_index("Music") != -1:
		_player.bus = "Music"
	else:
		_player.bus = "Master"


## Returns true if the playlist has been started at least once.
func is_started() -> bool:
	return _started


func _apply_volume() -> void:
	_player.volume_db = linear_to_db(volume_linear)

## Starts the playlist from the first track. Safe to call multiple times.
func start_playback() -> void:
	if _started:
		return
	if _tracks.is_empty():
		push_error("BgmManager: no background music tracks loaded")
		return
	# Avoid starting audio in headless runs, which can leak AudioStreamPlayback
	# objects because the audio server is not fully processed before exit.
	if DisplayServer.get_name() == "headless":
		return
	_started = true
	_play_track(0)

func _play_track(index: int) -> void:
	if index < 0 or index >= _tracks.size():
		push_error("BgmManager: invalid track index %d" % index)
		return

	_current_index = index
	_player.stream = _tracks[index]
	_player.play()
	track_changed.emit(index)

func _on_track_finished() -> void:
	if _tracks.size() == 0:
		return

	var next_index: int = (_current_index + 1) % _tracks.size()
	_play_track(next_index)

## Stops playback and resets the playlist to the beginning.
func stop() -> void:
	_player.stop()
	_started = false

## Pauses the current track without resetting playlist position.
func pause() -> void:
	if _player == null or not _started:
		return
	_player.stream_paused = true
	playback_paused.emit()

## Resumes a paused track.
func resume() -> void:
	if _player == null or not _started:
		return
	_player.stream_paused = false
	playback_resumed.emit()

## Sets the music volume in linear range [0.0, 1.0].
func set_volume(new_volume: float) -> void:
	volume_linear = clampf(new_volume, 0.0, 1.0)
	_apply_volume()
