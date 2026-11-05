extends Node
## Nhạc nền (nạp tự động với tên Music).
## - "vuon": Garden of Whispers, phát khi ở nhà kính trồng hoa.
## - "shop": Cozy Afternoon, phát khi ở Shop cây cảnh.
## Đổi bài thì nhạc cũ nhỏ dần và nhạc mới to dần (chuyển mượt 1,2 giây).
## Bật/tắt và âm lượng được lưu trong user://settings.cfg.

const TRACKS := {
	"vuon": "res://music/vuon_garden_of_whispers.mp3",
	"shop": "res://music/shop_cozy_afternoon.mp3",
}
const FADE := 1.2
const SETTINGS := "user://settings.cfg"

var enabled := true
var volume := 0.7          # 0..1
var current := ""

var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _tween: Tween
var _positions := {}       # nhớ chỗ đang phát của từng bài để quay lại không phát từ đầu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	_load_settings()


func play_track(name: String) -> void:
	if name == current or not TRACKS.has(name):
		return
	var old := _players[_active]
	if current != "" and old.playing:
		_positions[current] = old.get_playback_position()
	current = name
	_active = 1 - _active
	var p := _players[_active]
	var stream = load(TRACKS[name])
	if stream is AudioStreamMP3:
		stream.loop = true
	p.stream = stream
	p.volume_db = -80.0
	if enabled:
		p.play(_positions.get(name, 0.0))
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(p, "volume_db", _target_db(), FADE)
	_tween.tween_property(old, "volume_db", -80.0, FADE)
	_tween.chain().tween_callback(func():
		if old != _players[_active]:
			old.stop())


func set_enabled(on: bool) -> void:
	enabled = on
	var p := _players[_active]
	if on:
		if p.stream and not p.playing:
			p.play(_positions.get(current, 0.0))
		p.volume_db = _target_db()
	else:
		if p.playing:
			_positions[current] = p.get_playback_position()
		for q in _players:
			q.stop()
	_save_settings()


func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	if enabled:
		_players[_active].volume_db = _target_db()
	_save_settings()


func _target_db() -> float:
	return linear_to_db(maxf(volume, 0.0001))


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		enabled = bool(cfg.get_value("nhac", "bat", true))
		volume = float(cfg.get_value("nhac", "am_luong", 0.7))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("nhac", "bat", enabled)
	cfg.set_value("nhac", "am_luong", volume)
	cfg.save(SETTINGS)
