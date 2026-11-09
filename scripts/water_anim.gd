extends Control
## Hoạt ảnh bình tưới: bình hiện ra phía trên chậu, nghiêng đổ nước xuống đất rồi biến mất.
## target: điểm giữa mặt đất trong chậu (tọa độ màn hình). Tự xóa khi xong.

const DURATION := 1.7

var target := Vector2.ZERO
var scale_k := 1.0
var tint := Color(0.25, 0.62, 0.36)   # màu bình: xanh lá (thường), xanh dương, vàng
var delay := 0.0                       # chờ trước khi hiện (tưới nhiều chậu thì hiện so le)
var _t := 0.0
var _drops: Array = []     # mỗi giọt: [vị trí, vận tốc, tuổi]
var _splash: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	if delay > 0.0:
		delay -= delta
		return
	_t += delta
	var tilt := _tilt()
	# vòi đổ nước khi bình nghiêng đủ
	if tilt > 0.55 and _t < DURATION - 0.35:
		for i in 3:
			var sp := _spout()
			var v := Vector2(randf_range(25, 55), randf_range(-20, 10)) * scale_k
			_drops.append([sp + Vector2(randf_range(-3, 3), randf_range(-2, 2)) * scale_k, v, 0.0])
	for d in _drops:
		d[1].y += 900.0 * scale_k * delta
		d[0] += d[1] * delta
		d[2] += delta
	for d in _drops.duplicate():
		if d[0].y >= target.y:
			_drops.erase(d)
			if randf() < 0.5:
				_splash.append([Vector2(d[0].x, target.y), Vector2(randf_range(-50, 50), randf_range(-90, -40)) * scale_k, 0.0])
	for sp in _splash:
		sp[1].y += 500.0 * scale_k * delta
		sp[0] += sp[1] * delta
		sp[2] += delta
	_splash = _splash.filter(func(sp): return sp[2] < 0.35)
	queue_redraw()
	if _t >= DURATION and _drops.is_empty():
		queue_free()


## Độ nghiêng 0..1 theo thời gian: hiện ra, nghiêng, giữ, dựng lại.
func _tilt() -> float:
	if _t < 0.3:
		return 0.0
	if _t < 0.55:
		return (_t - 0.3) / 0.25
	if _t < DURATION - 0.35:
		return 1.0
	return clampf((DURATION - _t) / 0.3, 0.0, 1.0)


func _alpha() -> float:
	if _t < 0.25:
		return _t / 0.25
	if _t > DURATION - 0.2:
		return clampf((DURATION - _t) / 0.2, 0.0, 1.0)
	return 1.0


## Vị trí bình: phía trên bên trái chậu.
func _can_pos() -> Vector2:
	var drop := 18.0 * (1.0 - minf(_t / 0.3, 1.0))
	return target + Vector2(-82, -108 - drop) * scale_k


func _can_rot() -> float:
	return _tilt() * 0.62


## Miệng vòi (sau khi xoay).
func _spout() -> Vector2:
	return _can_pos() + Vector2(46, -22).rotated(_can_rot()) * scale_k


func _draw() -> void:
	var a := _alpha()
	# nước đang rơi
	for d in _drops:
		draw_circle(d[0], 2.6 * scale_k, Color(0.55, 0.8, 1.0, 0.85))
		draw_line(d[0], d[0] - d[1] * 0.025, Color(0.7, 0.9, 1.0, 0.6), 2.0 * scale_k)
	for sp in _splash:
		draw_circle(sp[0], 1.8 * scale_k, Color(0.7, 0.9, 1.0, 1.0 - sp[2] / 0.35))
	# vết đất ướt
	if _t > 0.6:
		var wet := minf((_t - 0.6) / 0.5, 1.0) * a
		var pts := PackedVector2Array()
		for i in 20:
			var t := TAU * i / 20.0
			pts.append(target + Vector2(cos(t) * 22, sin(t) * 5) * scale_k)
		draw_colored_polygon(pts, Color(0.15, 0.25, 0.4, 0.25 * wet))
	# bình tưới
	draw_set_transform(_can_pos(), _can_rot(), Vector2(scale_k, scale_k))
	if delay > 0.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var body := Color(tint.r, tint.g, tint.b, a)
	var dark := Color(tint.darkened(0.3).r, tint.darkened(0.3).g, tint.darkened(0.3).b, a)
	var light := Color(tint.lightened(0.35).r, tint.lightened(0.35).g, tint.lightened(0.35).b, a)
	# bóng thân
	draw_rect(Rect2(-24, -18, 40, 36), body)
	draw_rect(Rect2(-24, -18, 8, 36), light)
	draw_rect(Rect2(10, -18, 6, 36), dark)
	draw_rect(Rect2(-26, -22, 44, 6), Color(0.93, 0.93, 0.88, a))
	draw_rect(Rect2(-26, 16, 44, 4), dark)
	# quai
	draw_arc(Vector2(-6, -22), 15, PI, TAU, 16, dark, 5)
	# vòi
	draw_line(Vector2(14, 6), Vector2(40, -16), body, 7)
	draw_line(Vector2(14, 3), Vector2(40, -19), light, 2)
	# hoa sen
	var head := PackedVector2Array([Vector2(36, -22), Vector2(48, -28), Vector2(52, -16), Vector2(42, -12)])
	draw_colored_polygon(head, Color(0.18, 0.43, 0.25, a))
	for i in 3:
		draw_circle(Vector2(49 + i * 0.8, -25 + i * 4), 1.2, Color(0.75, 0.9, 1.0, a))
	# chữ nổi trang trí
	draw_circle(Vector2(-4, 0), 7, Color(0.95, 0.85, 0.4, a * 0.9))
	draw_circle(Vector2(-4, 0), 3, Color(0.98, 0.6, 0.6, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
