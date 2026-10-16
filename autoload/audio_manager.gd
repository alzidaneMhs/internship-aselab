extends Node

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const EXTENSIONS := ["ogg", "wav", "mp3"]
const SFX_VOICES := 14
const MUSIC_DB := -3.0

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active: AudioStreamPlayer
var _current_track := ""
var _music_offset_db := 0.0
var _cache: Dictionary = {}
var _voices: Array = []
var _next_voice := 0
var _last_played: Dictionary = {}
var _fade_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_a = _make_player()
	_music_b = _make_player()
	_active = _music_a
	for i in SFX_VOICES:
		_voices.append(_make_player())


func _make_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Master"
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	return p


func _find(dir: String, sound: String) -> AudioStream:
	var key := dir + sound
	if _cache.has(key):
		return _cache[key]
	var stream: AudioStream = null
	for ext in EXTENSIONS:
		var path: String = dir + sound + "." + ext
		if ResourceLoader.exists(path):
			stream = load(path) as AudioStream
			break
	_cache[key] = stream
	return stream


func play_music(track_name: String, fade: float = 1.2) -> void:
	if track_name == _current_track and _active.playing:
		return
	var stream := _find(MUSIC_DIR, track_name)
	_current_track = track_name
	var old := _active
	var nxt := _music_b if _active == _music_a else _music_a
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	if old.playing:
		var out := create_tween()
		out.tween_property(old, "volume_db", -60.0, fade)
		out.tween_callback(old.stop)
	_active = nxt
	if stream == null:
		return
	nxt.stream = stream
	nxt.volume_db = -60.0
	nxt.play()
	_fade_tween = create_tween()
	_fade_tween.tween_property(nxt, "volume_db", MUSIC_DB + _music_offset_db, fade)


func stop_music(fade: float = 1.0) -> void:
	_current_track = ""
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	for p in [_music_a, _music_b]:
		var player: AudioStreamPlayer = p
		if player.playing:
			var tw := create_tween()
			tw.tween_property(player, "volume_db", -60.0, fade)
			tw.tween_callback(player.stop)


func play_sfx(sfx_name: String, volume_db: float = 0.0, pitch_variation: float = 0.05) -> void:
	var stream := _find(SFX_DIR, sfx_name)
	if stream == null:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sfx_name, -1000)) < 35:
		return
	_last_played[sfx_name] = now
	var player: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


func set_music_volume_db(db: float) -> void:
	_music_offset_db = db
	if _active != null and _active.playing:
		_active.volume_db = MUSIC_DB + db
