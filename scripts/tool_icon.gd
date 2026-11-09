extends Control
## Biểu tượng dụng cụ và hạt giống, vẽ bằng code.
## kind: "nuoc" bình tưới, "phan" bao phân, "keo" kéo thu hạt,
##       "sung" súng thụ phấn (loaded = đã nạp phấn), "co" cọ thụ phấn (cũ),
##       "tu_dong" bình tưới tự động (cũ), "hat" hạt giống,
##       "dat_thuong", "dat_tot", "dat_hiem" túi đất.

var kind := "nuoc"
var count := -1      # số lượng hiện ở góc (-1 = không hiện)
var dim := false
var highlight := false
var locked := false  # vẽ ổ khóa (chưa mua)
var loaded := false  # súng thụ phấn đã nạp phấn
var tier := 0        # bình tưới: 1 xanh, 2 vàng; súng thụ phấn: 2 vàng
var t := 0.0


func _process(delta: float) -> void:
	if loaded and kind == "sung" and visible:
		t += delta
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var s: float = min(size.x, size.y) / 64.0
	if highlight:
		draw_circle(c, 30 * s, Color(1, 0.9, 0.4, 0.45))
	var a := 0.35 if dim else 1.0
	match kind:
		"nuoc": _can(c, s, a)
		"phan": _bag(c, s, a)
		"keo": _shears(c, s, a)
		"co": _brush(c, s, a)
		"sung": _gun(c, s, a)
		"tu_dong": _bottle(c, s, a)
		"hat": _seed(c, s, a)
		"dat_thuong": _soil_bag(c, s, a, Color("c9a46a"), Color("6b4a2e"), "")
		"dat_tot": _soil_bag(c, s, a, Color("7fae5a"), Color("3a2a1c"), "tot")
		"dat_hiem": _soil_bag(c, s, a, Color("8a5ab8"), Color("4a3058"), "hiem")
	if locked:
		var lc := c + Vector2(14, 12) * s
		draw_rect(Rect2(lc + Vector2(-8, -2) * s, Vector2(16, 13) * s), Color("e0b040"))
		draw_arc(lc + Vector2(0, -2) * s, 5.5 * s, PI, TAU, 10, Color("e0b040"), 2.6 * s)
		draw_circle(lc + Vector2(0, 4) * s, 2 * s, Color("5a3a10"))
	if count >= 0:
		var font := get_theme_default_font()
		var t := str(count)
		var p := Vector2(size.x - 16 * s, size.y - 8 * s)
		draw_circle(p + Vector2(4 * s, -6 * s), 10 * s, Color(0.2, 0.12, 0.05, 0.85))
		draw_string(font, p + Vector2(4 * s - font.get_string_size(t, 0, -1, int(14 * s)).x / 2, -1 * s), t, HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * s), Color.WHITE)


func _al(col: Color, a: float) -> Color:
	return Color(col.r, col.g, col.b, col.a * a)


func _can(c: Vector2, s: float, a: float) -> void:
	var body: Color = [Color("3f9a5a"), Color("3a78d8"), Color("e0aa22")][clampi(tier, 0, 2)]
	if tier == 2:   # bình vàng lấp lánh
		draw_circle(c + Vector2(-4, 4) * s, 22 * s, _al(Color(1, 0.85, 0.3, 0.18), a))
	draw_rect(Rect2(c + Vector2(-14, -8) * s, Vector2(26, 24) * s), _al(body, a))
	draw_arc(c + Vector2(-1, -8) * s, 10 * s, PI, TAU, 12, _al(body.darkened(0.2), a), 4 * s)
	draw_line(c + Vector2(12, 4) * s, c + Vector2(26, -12) * s, _al(body, a), 5 * s)
	draw_rect(Rect2(c + Vector2(24, -16) * s, Vector2(6, 6) * s), _al(Color("2d6e40"), a))
	for i in 3:
		draw_circle(c + Vector2(30 + i * 3, -6 + i * 6) * s, 1.6 * s, _al(Color("8fd0ff"), a))
	draw_rect(Rect2(c + Vector2(-14, -8) * s, Vector2(26, 5) * s), _al(Color("f2f2e6"), a))


func _bag(c: Vector2, s: float, a: float) -> void:
	var pts := PackedVector2Array([c + Vector2(-14, -16) * s, c + Vector2(14, -16) * s,
		c + Vector2(18, 20) * s, c + Vector2(-18, 20) * s])
	draw_colored_polygon(pts, _al(Color("c7a46a"), a))
	draw_rect(Rect2(c + Vector2(-15, -20) * s, Vector2(30, 6) * s), _al(Color("9c7a45"), a))
	draw_rect(Rect2(c + Vector2(-12, -2) * s, Vector2(24, 14) * s), _al(Color("f3e3c0"), a))
	draw_circle(c + Vector2(-3, 5) * s, 4 * s, _al(Color("5fae55"), a))
	draw_circle(c + Vector2(4, 4) * s, 4 * s, _al(Color("4b9a45"), a))


func _shears(c: Vector2, s: float, a: float) -> void:
	var metal := Color("cfd6dc")
	draw_line(c + Vector2(-4, 4) * s, c + Vector2(18, -20) * s, _al(metal, a), 4 * s)
	draw_line(c + Vector2(4, 4) * s, c + Vector2(-14, -20) * s, _al(metal.darkened(0.15), a), 4 * s)
	draw_arc(c + Vector2(-10, 14) * s, 8 * s, 0, TAU, 16, _al(Color("d24a3a"), a), 4 * s)
	draw_arc(c + Vector2(10, 14) * s, 8 * s, 0, TAU, 16, _al(Color("d24a3a"), a), 4 * s)
	draw_circle(c + Vector2(0, -2) * s, 2.5 * s, _al(Color("6b7680"), a))


func _brush(c: Vector2, s: float, a: float) -> void:
	draw_line(c + Vector2(-16, 18) * s, c + Vector2(6, -4) * s, _al(Color("8a5a2b"), a), 6 * s)
	draw_rect(Rect2(c + Vector2(3, -10) * s, Vector2(8, 8) * s), _al(Color("c0c4c8"), a))
	draw_circle(c + Vector2(13, -13) * s, 8 * s, _al(Color("f6d55c"), a))
	for i in 5:
		draw_circle(c + Vector2(13, -13) * s + Vector2.from_angle(TAU * i / 5.0) * 7 * s, 2 * s, _al(Color("fff3b0"), a))


## Súng thụ phấn: thân xanh ngọc, bình phấn trong suốt trên lưng, đầu phun hình bông hoa.
func _gun(c: Vector2, s: float, a: float) -> void:
	var o := c + Vector2(-2, 2) * s
	var P := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * s
	var body := Color("2f9a8a") if tier < 2 else Color("d9a826")
	var dark := Color("1e6a60") if tier < 2 else Color("9a7414")
	# tay cầm
	draw_colored_polygon(PackedVector2Array([P.call(-15, 2), P.call(-4, 2), P.call(-8, 22), P.call(-20, 22)]), _al(Color("8a5a2b"), a))
	draw_colored_polygon(PackedVector2Array([P.call(-15, 2), P.call(-11, 2), P.call(-16, 22), P.call(-20, 22)]), _al(Color("a8743a"), a))
	for k in 3:
		draw_line(P.call(-17 + k * 0.8, 8 + k * 4), P.call(-9 + k * 0.8, 8 + k * 4), _al(Color("6b4220"), a), 1.4 * s)
	# cò súng
	draw_arc(P.call(-1, 6), 5 * s, 0.2, PI - 0.2, 8, _al(Color("c0c4c8"), a), 2 * s)
	draw_line(P.call(-1, 3), P.call(-2, 8), _al(Color("3a3a3a"), a), 2 * s)
	# thân súng
	draw_rect(Rect2(P.call(-22, -7), Vector2(36, 11) * s), _al(body, a))
	draw_rect(Rect2(P.call(-22, -7), Vector2(36, 3) * s), _al(body.lightened(0.35), a))
	draw_rect(Rect2(P.call(-22, 1), Vector2(36, 3) * s), _al(dark, a))
	draw_circle(P.call(-22, -1.5), 5.5 * s, _al(body, a))
	# nòng bạc
	draw_rect(Rect2(P.call(14, -5), Vector2(12, 7) * s), _al(Color("c9d2d8"), a))
	draw_rect(Rect2(P.call(14, -5), Vector2(12, 2) * s), _al(Color("eef3f6"), a))
	# đầu phun hình hoa
	var tip: Vector2 = P.call(29, -1.5)
	for i in 5:
		draw_circle(tip + Vector2.from_angle(TAU * i / 5.0 + 0.3) * 4.2 * s, 3 * s, _al(Color("f28ab2"), a))
	draw_circle(tip, 2.6 * s, _al(Color("f6d55c"), a))
	# bình phấn trong suốt
	var tank: Vector2 = P.call(-6, -14)
	draw_rect(Rect2(P.call(-10, -9), Vector2(8, 3) * s), _al(Color("9aa4aa"), a))
	draw_circle(tank, 9 * s, _al(Color(0.85, 0.95, 1.0, 0.55), a))
	if loaded:
		var glow := 0.5 + 0.5 * sin(t * 5.0)
		draw_circle(tank, 13 * s, _al(Color(1.0, 0.85, 0.2, 0.18 + 0.15 * glow), a))
		draw_circle(tank + Vector2(0, 2) * s, 7.2 * s, _al(Color("f6c933"), a))
		for i in 6:
			var q := tank + Vector2.from_angle(TAU * i / 6.0 + t) * 4.0 * s + Vector2(0, 2) * s
			draw_circle(q, 1.3 * s, _al(Color("fff3b0"), a))
		# bụi phấn lấp lánh ở đầu phun
		for i in 3:
			var ph := fmod(t * 0.8 + i / 3.0, 1.0)
			draw_circle(tip + Vector2(4 + ph * 10, -6 * ph + (i - 1) * 4 * ph) * s, (1.8 - ph) * s, _al(Color(1, 0.9, 0.3, 1.0 - ph), a))
	draw_arc(tank, 9 * s, PI * 1.1, PI * 1.6, 8, _al(Color(1, 1, 1, 0.9), a), 2 * s)
	draw_arc(tank, 9 * s, 0, TAU, 24, _al(Color("5a7a88"), a), 1.4 * s)


func _bottle(c: Vector2, s: float, a: float) -> void:
	draw_rect(Rect2(c + Vector2(-9, -18) * s, Vector2(18, 26) * s), _al(Color("7cc4e8"), a))
	draw_rect(Rect2(c + Vector2(-9, -6) * s, Vector2(18, 14) * s), _al(Color("3a8fd0"), a))
	draw_rect(Rect2(c + Vector2(-5, -24) * s, Vector2(10, 6) * s), _al(Color("e05a3a"), a))
	var spike := PackedVector2Array([c + Vector2(-6, 8) * s, c + Vector2(6, 8) * s, c + Vector2(0, 24) * s])
	draw_colored_polygon(spike, _al(Color("6f7a82"), a))


func _seed(c: Vector2, s: float, a: float) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		var r := 1.0 + 0.18 * cos(t * 2.0)
		pts.append(c + Vector2(cos(t) * 13 * r, sin(t) * 18) .rotated(0.5) * s)
	draw_colored_polygon(pts, _al(Color("8a4b2a"), a))
	draw_arc(c + Vector2(3, -2) * s, 9 * s, -0.6, 1.0, 8, _al(Color("b8754a"), a), 2.5 * s)


## Bao đất: bao vải căng phồng, miệng mở lộ đất, nhãn in biểu tượng theo loại
## (thường: xẻng; tốt: mầm cây xanh; hiếm: viên ngọc tím lấp lánh).
func _soil_bag(c: Vector2, s: float, a: float, bag: Color, dirt: Color, kind: String) -> void:
	var o := c + Vector2(0, 2) * s
	var body := PackedVector2Array()
	# thân bao phình ra hai bên
	for i in 13:
		var t := float(i) / 12.0
		body.append(o + Vector2(-15 - 6 * sin(t * PI), -12 + t * 32) * s)
	for i in 13:
		var t := 1.0 - float(i) / 12.0
		body.append(o + Vector2(15 + 6 * sin(t * PI), -12 + t * 32) * s)
	draw_colored_polygon(body, _al(bag, a))
	# mảng tối bên phải và đáy bao
	var shade_pts := PackedVector2Array()
	for i in 13:
		var t := float(i) / 12.0
		shade_pts.append(o + Vector2(9 + 4 * sin(t * PI), -12 + t * 32) * s)
	for i in 13:
		var t := 1.0 - float(i) / 12.0
		shade_pts.append(o + Vector2(15 + 6 * sin(t * PI), -12 + t * 32) * s)
	draw_colored_polygon(shade_pts, _al(bag.darkened(0.25), a))
	draw_rect(Rect2(o + Vector2(-17, 17) * s, Vector2(34, 3) * s), _al(bag.darkened(0.3), a))
	# vệt sáng bên trái
	draw_line(o + Vector2(-15, -6) * s, o + Vector2(-17, 12) * s, _al(bag.lightened(0.35), a), 2.2 * s)
	# miệng bao gấp mép, lộ đất
	var top := PackedVector2Array()
	for i in 20:
		var t := TAU * i / 20.0
		top.append(o + Vector2(cos(t) * 16, -13 + sin(t) * 5) * s)
	draw_colored_polygon(top, _al(bag.darkened(0.15), a))
	var soil := PackedVector2Array()
	for i in 20:
		var t := TAU * i / 20.0
		soil.append(o + Vector2(cos(t) * 13, -13 + sin(t) * 3.6 - maxf(0.0, -sin(t)) * 3.0) * s)
	draw_colored_polygon(soil, _al(dirt, a))
	for i in 5:
		draw_circle(o + Vector2(-8 + i * 4, -15 + (i % 2) * 2) * s, 1.1 * s, _al(dirt.lightened(0.3), a))
	# đường may dưới miệng
	for i in 7:
		draw_line(o + Vector2(-13 + i * 4, -7) * s, o + Vector2(-11 + i * 4, -7) * s, _al(bag.darkened(0.4), a), 1.2 * s)
	# nhãn
	var lab := Rect2(o + Vector2(-10, -3) * s, Vector2(20, 15) * s)
	draw_rect(lab, _al(Color("fff6dc"), a))
	draw_rect(lab, _al(bag.darkened(0.35), a), false, 1.2 * s)
	var lc := lab.get_center()
	match kind:
		"tot":   # mầm cây
			draw_line(lc + Vector2(0, 5) * s, lc + Vector2(0, -1) * s, _al(Color("3f8a3a"), a), 1.6 * s)
			draw_circle(lc + Vector2(-3, -2) * s, 2.8 * s, _al(Color("5fae55"), a))
			draw_circle(lc + Vector2(3, -3) * s, 2.8 * s, _al(Color("4b9a45"), a))
			for i in 3:
				draw_circle(o + Vector2(-6 + i * 6, -17 - (i % 2) * 2) * s, 2.4 * s, _al(Color("6fbf5f"), a))
		"hiem":  # viên ngọc
			var gem := PackedVector2Array([lc + Vector2(0, -6) * s, lc + Vector2(5, -1) * s, lc + Vector2(0, 6) * s, lc + Vector2(-5, -1) * s])
			draw_colored_polygon(gem, _al(Color("9b59d0"), a))
			draw_colored_polygon(PackedVector2Array([lc + Vector2(0, -6) * s, lc + Vector2(5, -1) * s, lc + Vector2(0, -1) * s]), _al(Color("d6b0f5"), a))
			for i in 4:
				var q := o + Vector2(-9 + i * 6, -16 - (i % 2) * 3) * s
				draw_circle(q, 2.0 * s, _al(Color("ffd860"), a))
				draw_line(q + Vector2(-3, 0) * s, q + Vector2(3, 0) * s, _al(Color(1, 0.95, 0.6, 0.8), a), 0.8 * s)
				draw_line(q + Vector2(0, -3) * s, q + Vector2(0, 3) * s, _al(Color(1, 0.95, 0.6, 0.8), a), 0.8 * s)
		_:       # xẻng
			draw_line(lc + Vector2(-4, 5) * s, lc + Vector2(2, -1) * s, _al(Color("8a5a2b"), a), 1.8 * s)
			draw_colored_polygon(PackedVector2Array([lc + Vector2(1, -2) * s, lc + Vector2(5, -6) * s, lc + Vector2(6, -1) * s, lc + Vector2(3, 1) * s]), _al(Color("8a949c"), a))
