extends Control
## Hoạt ảnh dụng cụ trên chậu:
##   mode "dat": bao đất đặt cạnh chậu, xẻng nhỏ xúc đất đổ vào chậu (2 lần).
##   mode "keo": cây kéo lượn quanh bông hoa và cắt "xoẹt xoẹt", vụn lá cánh hoa rơi.
## soil_pos: giữa miệng chậu; flower_pos: giữa tán hoa; k: tỉ lệ theo cỡ chậu.
## Khi xong gọi on_done (nếu có) rồi tự xóa.

var mode := "dat"
var soil_pos := Vector2.ZERO
var flower_pos := Vector2.ZERO
var k := 1.0
var soil_color := Color("6b4a2e")
var bag_color := Color("d8b878")
var petal_color := Color("e85a7a")
var on_done := Callable()

var _t := 0.0
var _bits: Array = []        # [vị trí, vận tốc, tuổi, màu, cỡ]
var _done := false
var _last_snip := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func duration() -> float:
	return 2.1 if mode == "dat" else 1.8


func _process(delta: float) -> void:
	_t += delta
	if mode == "dat":
		_update_soil()
	else:
		_update_scissors()
	for b in _bits:
		b[1].y += 700.0 * k * delta
		b[0] += b[1] * delta
		b[2] += delta
	_bits = _bits.filter(func(b): return b[2] < 1.2 and b[0].y < soil_pos.y + 4.0 * k)
	queue_redraw()
	if _t >= duration() and not _done:
		_done = true
		if on_done.is_valid():
			on_done.call()
	if _done and _bits.is_empty():
		queue_free()


func _alpha() -> float:
	return clampf(minf(_t / 0.2, (duration() - _t) / 0.25), 0.0, 1.0)


# ---------------- Xúc đất ----------------

## Một chu kỳ xúc đất dài 0.8 giây, bắt đầu từ 0.25 giây.
func _cycle() -> Array:
	var t := _t - 0.25
	if t < 0.0:
		return [0, 0.0]
	var n := int(t / 0.8)
	return [n, fmod(t, 0.8) / 0.8]


func _bag_pos() -> Vector2:
	return soil_pos + Vector2(-74, 22) * k


## Vị trí và góc xoay của xẻng theo pha 0..1 của chu kỳ.
func _shovel() -> Array:
	var c: Array = _cycle()
	var ph: float = c[1]
	var mouth := _bag_pos() + Vector2(4, -26) * k
	var above := soil_pos + Vector2(-6, -34) * k
	if c[0] >= 2:
		return [above + Vector2(-20, -10) * k, -0.3]
	if ph < 0.3:     # cắm xuống bao xúc đất
		var q := ph / 0.3
		return [mouth + Vector2(0, -14 + 18 * sin(q * PI)) * k, -0.6 + 0.4 * q]
	if ph < 0.65:    # đưa lên cao, vòng sang miệng chậu
		var q := (ph - 0.3) / 0.35
		var p := mouth.lerp(above, q) + Vector2(0, -26 * sin(q * PI)) * k
		return [p, -0.2]
	# nghiêng đổ đất
	var q := (ph - 0.65) / 0.35
	return [above, -0.2 + 1.2 * sin(q * PI * 0.5)]


func _update_soil() -> void:
	var c: Array = _cycle()
	var ph: float = c[1]
	if c[0] < 2 and ph > 0.7 and ph < 0.95:
		var s: Array = _shovel()
		var tip: Vector2 = s[0] + Vector2(34, 0).rotated(s[1]) * k
		for i in 2:
			var col := soil_color.lerp(Color.BLACK, randf() * 0.3)
			_bits.append([tip + Vector2(randf_range(-4, 4), randf_range(-2, 2)) * k,
				Vector2(randf_range(-30, 30), randf_range(-20, 20)) * k, 0.0, col, randf_range(1.8, 3.2) * k])


# ---------------- Cắt kéo ----------------

func _scissor_path() -> Array:
	# lượn một vòng quanh tán hoa (ngược chiều kim đồng hồ), từ bên phải
	var q := clampf((_t - 0.15) / 1.4, 0.0, 1.0)
	var ang := -0.3 + q * TAU * 0.95
	var rad := Vector2(52, 34) * k
	var pos := flower_pos + Vector2(cos(ang) * rad.x, sin(ang) * rad.y)
	var tangent := Vector2(-sin(ang) * rad.x, cos(ang) * rad.y).angle()
	return [pos, tangent + PI * 0.5, q]   # mũi kéo hướng vào thân hoa


func _update_scissors() -> void:
	var snip := int(_t * 4.0)
	if snip != _last_snip and _t > 0.2 and _t < 1.6:
		_last_snip = snip
		var s: Array = _scissor_path()
		var tip: Vector2 = s[0] + Vector2.from_angle(s[1]) * 26.0 * k
		for i in 4:
			var col := petal_color if i % 2 == 0 else Color("5f9a45")
			_bits.append([tip + Vector2(randf_range(-5, 5), randf_range(-5, 5)) * k,
				Vector2(randf_range(-60, 60), randf_range(-90, -20)) * k, 0.0, col, randf_range(2.0, 3.5) * k])


func _blade_open() -> float:
	return 0.08 + 0.32 * absf(sin(_t * 4.0 * PI))   # mở khép 4 lần mỗi giây


# ---------------- Vẽ ----------------

func _draw() -> void:
	var a := _alpha()
	for b in _bits:
		var fade := clampf(1.0 - b[2] / 1.2, 0.0, 1.0)
		var col: Color = b[3]
		col.a = fade
		draw_circle(b[0], b[4], col)
	if mode == "dat":
		_draw_bag(a)
		_draw_shovel(a)
	else:
		_draw_scissors(a)


func _draw_bag(a: float) -> void:
	var o := _bag_pos()
	draw_set_transform(o, -0.12, Vector2(k, k))
	var bag := bag_color
	bag.a = a
	var body := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		body.append(Vector2(-22 - 7 * sin(t * PI), -24 + t * 44))
	for i in 13:
		var t := 1.0 - float(i) / 12.0
		body.append(Vector2(22 + 7 * sin(t * PI), -24 + t * 44))
	draw_colored_polygon(body, bag)
	var dark := bag.darkened(0.25)
	draw_rect(Rect2(-24, 16, 48, 4), dark)
	draw_line(Vector2(-22, -14), Vector2(-25, 12), Color(1, 1, 1, 0.35 * a), 3)
	var rim := PackedVector2Array()
	var soil := PackedVector2Array()
	for i in 20:
		var t := TAU * i / 20.0
		rim.append(Vector2(cos(t) * 23, -25 + sin(t) * 7))
		soil.append(Vector2(cos(t) * 19, -25 + sin(t) * 5 - maxf(0.0, -sin(t)) * 4))
	draw_colored_polygon(rim, bag.darkened(0.15))
	var sc := soil_color
	sc.a = a
	draw_colored_polygon(soil, sc)
	var lab := Rect2(-13, -8, 26, 18)
	draw_rect(lab, Color(1, 0.97, 0.86, a))
	draw_rect(lab, Color(dark.r, dark.g, dark.b, a), false, 1.5)
	draw_circle(lab.get_center(), 4, Color(0.4, 0.65, 0.3, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_shovel(a: float) -> void:
	var s: Array = _shovel()
	draw_set_transform(s[0], s[1], Vector2(k, k))
	# cán gỗ
	draw_rect(Rect2(-30, -3.5, 26, 7), Color(0.55, 0.35, 0.18, a))
	draw_rect(Rect2(-30, -3.5, 26, 2.5), Color(0.72, 0.5, 0.28, a))
	draw_circle(Vector2(-30, 0), 3.5, Color(0.55, 0.35, 0.18, a))
	draw_rect(Rect2(-5, -2.5, 6, 5), Color(0.6, 0.62, 0.66, a))
	# lưỡi xẻng
	var blade := PackedVector2Array([Vector2(0, -7), Vector2(26, -6), Vector2(36, 0), Vector2(26, 6), Vector2(0, 7)])
	draw_colored_polygon(blade, Color(0.72, 0.75, 0.8, a))
	draw_line(Vector2(2, -5), Vector2(28, -4), Color(0.92, 0.94, 0.97, a), 2)
	# đất trên xẻng (khi đang mang)
	var c: Array = _cycle()
	if c[0] < 2 and c[1] > 0.22 and c[1] < 0.8:
		var sc := soil_color
		sc.a = a
		for i in 5:
			draw_circle(Vector2(8 + i * 5, -6 + (i % 2) * 2), 4.2, sc)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_scissors(a: float) -> void:
	var s: Array = _scissor_path()
	var open := _blade_open()
	draw_set_transform(s[0], s[1], Vector2(k, k) * 1.45)
	var steel := Color(0.78, 0.8, 0.84, a)
	var edge := Color(0.45, 0.47, 0.52, a)
	for side in [-1.0, 1.0]:
		var rot: float = open * side
		var blade := PackedVector2Array([Vector2(0, -2.5), Vector2(26, -1), Vector2(30, 0), Vector2(26, 1.5), Vector2(0, 2.5)])
		var handle_c := Vector2(-16, 0).rotated(rot)
		var pts := PackedVector2Array()
		for p in blade:
			pts.append(p.rotated(rot))
		draw_colored_polygon(pts, steel)
		draw_line(Vector2(0, 0), Vector2(28, 0).rotated(rot), edge, 1.0)
		# tay cầm vòng tròn màu đỏ cam
		draw_line(Vector2.ZERO, handle_c, Color(0.85, 0.3, 0.25, a), 4)
		draw_arc(handle_c + Vector2(-6, 0).rotated(rot), 6.5, 0, TAU, 18, Color(0.85, 0.3, 0.25, a), 3.5)
	draw_circle(Vector2.ZERO, 2.6, edge)
	draw_circle(Vector2.ZERO, 1.2, Color(0.95, 0.95, 0.95, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
