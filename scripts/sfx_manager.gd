extends Node

## Global sound-effect service.
## Effects are addressed by semantic ids so screens can reuse the same small set.

@export_range(0.0, 1.0, 0.01) var volume_linear: float = 0.9
@export var max_players: int = 8

const EFFECT_PATHS: Dictionary[String, String] = {
	"card_flip": "res://music/effect/card_flip.wav",
	"card_select": "res://music/effect/card_select.wav",
	"cash_gain": "res://music/effect/cash_gain.wav",
	"cash_loss": "res://music/effect/cash_loss.wav",
	"coin_heavy": "res://music/effect/coin_heavy.wav",
	"coin_small": "res://music/effect/coin_small.wav",
	"fish_king": "res://music/effect/fish_king.wav",
	"harvest_reveal": "res://music/effect/harvest_reveal.wav",
	"net_cast": "res://music/effect/net_cast.wav",
	"settlement_stamp": "res://music/effect/settlement_stamp.wav",
	"ui_tap_soft": "res://music/effect/ui_tap_soft.mp3",
}

var _streams: Dictionary[String, AudioStream] = {}
var _players: Array[AudioStreamPlayer] = []
var _headless := false


func _ready() -> void:
	_headless = DisplayServer.get_name() == "headless"
	for effect_id in EFFECT_PATHS:
		var path := EFFECT_PATHS[effect_id]
		if not ResourceLoader.exists(path):
			continue
		var stream := load(path) as AudioStream
		if stream != null:
			_streams[effect_id] = stream


func play(effect_id: String) -> void:
	if _headless or not _streams.has(effect_id):
		return
	var player := _get_available_player()
	if player == null:
		return
	player.stream = _streams[effect_id]
	player.volume_db = linear_to_db(volume_linear)
	player.play()


func has_effect(effect_id: String) -> bool:
	return _streams.has(effect_id)


func set_volume(new_volume: float) -> void:
	volume_linear = clampf(new_volume, 0.0, 1.0)


func _get_available_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	if _players.size() >= max_players:
		return _players[0]

	var player := AudioStreamPlayer.new()
	player.name = "SfxPlayer_%02d" % (_players.size() + 1)
	player.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	add_child(player)
	_players.append(player)
	return player
