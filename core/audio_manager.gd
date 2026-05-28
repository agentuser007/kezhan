extends Node

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
const SFX_POOL_SIZE: int = 8

var _bgm_streams: Dictionary = {}
var _sfx_streams: Dictionary = {}

var _current_bgm: StringName = &""
var _bgm_volume: float = 0.5
var _sfx_volume: float = 0.7


func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = &"Master"
	add_child(_bgm_player)

	for i in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_sfx_players.append(player)

	_load_all_audio()


func _load_all_audio() -> void:
	var bgm_paths: Dictionary = {
		&"farm": "res://sound/music/farm.wav",
		&"house": "res://sound/music/house.wav",
		&"town": "res://sound/music/town.wav",
		&"rain": "res://sound/music/rain.wav",
		&"force_sleep": "res://sound/music/forceSleep.wav",
		&"title": "res://sound/music/titleScreen.wav",
	}
	for key: StringName in bgm_paths:
		var stream: AudioStream = load(bgm_paths[key])
		if stream:
			_bgm_streams[key] = stream

	var sfx_paths: Dictionary = {
		&"right_foot": "res://sound/effects/rightFoot.wav",
		&"left_foot": "res://sound/effects/leftFoot.wav",
		&"drop": "res://sound/effects/drop.wav",
		&"sell": "res://sound/effects/sell.wav",
		&"store": "res://sound/effects/store.wav",
		&"harvest": "res://sound/effects/harvest.wav",
		&"purchase": "res://sound/effects/purchase.wav",
		&"bell": "res://sound/effects/bell.wav",
		&"sickle": "res://sound/tools/sickle.wav",
		&"watering": "res://sound/tools/watering.wav",
		&"axe": "res://sound/tools/axe.wav",
		&"seeds": "res://sound/tools/seeds.wav",
		&"hoe": "res://sound/tools/hoe.wav",
		&"hammer": "res://sound/tools/hammer.wav",
	}
	for key: StringName in sfx_paths:
		var stream: AudioStream = load(sfx_paths[key])
		if stream:
			_sfx_streams[key] = stream


func play_bgm(name: StringName, fade_time: float = 1.0) -> void:
	if name == _current_bgm and _bgm_player.playing:
		return
	if not _bgm_streams.has(name):
		return
	if _bgm_player.playing and fade_time > 0.0:
		var tween: Tween = create_tween()
		tween.tween_property(_bgm_player, "volume_db", -80.0, fade_time)
		tween.tween_callback(func() -> void: _start_bgm(name))
	else:
		_start_bgm(name)


func _start_bgm(name: StringName) -> void:
	_bgm_player.stream = _bgm_streams[name]
	_bgm_player.volume_db = _db_from_linear(_bgm_volume)
	_bgm_player.play()
	_current_bgm = name


func stop_bgm(fade_time: float = 1.0) -> void:
	if fade_time > 0.0:
		var tween: Tween = create_tween()
		tween.tween_property(_bgm_player, "volume_db", -80.0, fade_time)
		tween.tween_callback(
			func() -> void:
				_bgm_player.stop()
				_current_bgm = &""
		)
	else:
		_bgm_player.stop()
		_current_bgm = &""


func play_sfx(name: StringName, volume_scale: float = 1.0) -> void:
	if not _sfx_streams.has(name):
		return
	var player: AudioStreamPlayer = _sfx_players[_sfx_index]
	player.stream = _sfx_streams[name]
	player.volume_db = _db_from_linear(_sfx_volume * volume_scale)
	player.play()
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE


func set_bgm_volume(linear: float) -> void:
	_bgm_volume = clampf(linear, 0.0, 1.0)
	if _bgm_player.playing:
		_bgm_player.volume_db = _db_from_linear(_bgm_volume)


func set_sfx_volume(linear: float) -> void:
	_sfx_volume = clampf(linear, 0.0, 1.0)


func _db_from_linear(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return linear_to_db(linear)
