extends RefCounted
## Vẽ hạt giống theo loài hoa (kiểu hoa trội trong bộ gen) và độ hiếm.
## Đơn vị vẽ: một ô khoảng 64 x 64, tâm ở c, nhân với s.
##   hong  : hạt bóng nâu đỏ (giữ như cũ)
##   cuc   : hạt tròn màu nâu sậm
##   sao   : 3 hạt dẹp nhỏ màu đen
##   tulip : củ có ít rễ
##   chuong: hạt dẹp dài màu nâu
##   lan   : hạt tròn nhỏ màu kem
##   sen   : hạt bầu dục vàng nâu, đầu sẫm
##   rong  : củ tím sẫm có đốm và mầm đỏ
## Hạt Hiếm / Quý / Huyền thoại phát sáng nhẹ (xanh dương / tím / vàng).

const Data := preload("res://scripts/data.gd")

const OUTLINE := Color("2a1608")


static func draw_seed(ci: CanvasItem, c: Vector2, s: float, kind: String, rarity := 0, t := 0.0) -> void:
	if rarity >= 1:
		_glow(ci, c, s, rarity, t)
	match kind:
		"cuc": _cuc(ci, c, s)
		"sao": _sao(ci, c, s)
		"tulip": _tulip(ci, c, s)
		"chuong": _chuong(ci, c, s)
		"lan": _lan(ci, c, s)
		"sen": _sen(ci, c, s)
		"rong": _rong(ci, c, s)
		_: _hong(ci, c, s)


static func _glow(ci: CanvasItem, c: Vector2, s: float, rarity: int, t: float) -> void:
	var col: Color = [Color.WHITE, Color("8fd0ff"), Color("e3a8ff"), Color("ffe27a")][clampi(rarity, 0, 3)]
	var pulse := 0.7 + 0.3 * sin(t * 3.0)
	var r := 27.0 * s * (0.95 + 0.05 * sin(t * 3.0))
	for i in 7:
		var k := 1.0 - i / 7.0
		ci.draw_circle(c, r * k, Color(col.r, col.g, col.b, 0.10 * pulse * (1.0 + i * 0.35)))
	ci.draw_arc(c, r * 0.92, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.45 * pulse), 1.6 * s)
	# vài đốm lấp lánh
	for i in 3:
		var a := t * 1.4 + i * TAU / 3.0
		var p := c + Vector2(cos(a), sin(a)) * 19.0 * s
		var tw := 0.5 + 0.5 * sin(t * 5.0 + i * 2.0)
		ci.draw_circle(p, 1.8 * s * tw + 0.5, Color(1, 1, 0.9, 0.8 * tw))


static func _blob(ci: CanvasItem, c: Vector2, rx: float, ry: float, rot: float, col: Color, wobble := 0.0, outline := true) -> void:
	var pts := PackedVector2Array()
	var out := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		var k := 1.0 + wobble * cos(a * 2.0)
		var v := Vector2(cos(a) * rx * k, sin(a) * ry).rotated(rot)
		pts.append(c + v)
		out.append(c + v + v.normalized() * 1.6)
	if outline:
		ci.draw_colored_polygon(out, OUTLINE)
	ci.draw_colored_polygon(pts, col)


static func _shine(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r, Color(1, 0.95, 0.85, 0.75))


# ---------------- Hoa hồng (giữ như cũ) ----------------
static func _hong(ci: CanvasItem, c: Vector2, s: float) -> void:
	var pts := PackedVector2Array()
	var pts_out := PackedVector2Array()
	for i in 28:
		var t := TAU * i / 28.0
		var r := 1.0 + 0.16 * cos(t * 2.0)
		var v := Vector2(cos(t) * 15 * r, sin(t) * 20).rotated(0.55) * s
		pts.append(c + v)
		pts_out.append(c + v * 1.12)
	ci.draw_colored_polygon(pts_out, OUTLINE)
	ci.draw_colored_polygon(pts, Color("9a3a1e"))
	ci.draw_circle(c + Vector2(-4, -6) * s, 6.5 * s, Color("c8603a"))
	ci.draw_circle(c + Vector2(-5, -8) * s, 3.2 * s, Color(1, 0.9, 0.8, 0.85))
	ci.draw_arc(c + Vector2(3, 2) * s, 10 * s, -0.4, 1.2, 10, Color("6a2410"), 2.5 * s)


# ---------------- Hoa cúc: tròn, nâu sậm, có gân ----------------
static func _cuc(ci: CanvasItem, c: Vector2, s: float) -> void:
	_blob(ci, c, 14 * s, 14 * s, 0.0, Color("4a2c16"))
	ci.draw_circle(c + Vector2(-3, -3) * s, 8 * s, Color("5e3a1e"))
	for i in 3:
		ci.draw_arc(c, (5 + i * 3.5) * s, 0.6, 2.4, 8, Color("2e1a0c"), 1.2 * s)
	_shine(ci, c + Vector2(-5, -6) * s, 2.6 * s)


# ---------------- Hoa sao: 3 hạt dẹp nhỏ màu đen ----------------
static func _sao(ci: CanvasItem, c: Vector2, s: float) -> void:
	var spots := [[Vector2(-8, -6), -0.5], [Vector2(8, -4), 0.6], [Vector2(0, 8), 0.1]]
	for sp in spots:
		var p: Vector2 = c + sp[0] * s
		_blob(ci, p, 8 * s, 4 * s, sp[1], Color("1c1c1e"))
		ci.draw_line(p + Vector2(-4, 0).rotated(sp[1]) * s, p + Vector2(3, 0).rotated(sp[1]) * s, Color("55555a"), 1.2 * s)
		_shine(ci, p + Vector2(-3, -1.5).rotated(sp[1]) * s, 1.2 * s)


# ---------------- Tulip: củ có ít rễ ----------------
static func _tulip(ci: CanvasItem, c: Vector2, s: float) -> void:
	var base := c + Vector2(0, 6) * s
	# rễ
	for i in 5:
		var x := (-6 + i * 3) * s
		var end := base + Vector2(x * 1.6, 13 * s + (i % 2) * 3 * s)
		ci.draw_line(base + Vector2(x, 8 * s), end, Color("e6d6b0"), 1.4 * s)
	# thân củ hình giọt nước, đầu nhọn
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		var y := sin(a)
		var x := cos(a) * (13.0 - (6.0 if y < 0 else 0.0) * absf(y) * absf(y))
		var yy := y * (12.0 if y > 0 else 16.0)
		pts.append(base + Vector2(x, yy) * s)
	var outp := PackedVector2Array()
	for p in pts:
		outp.append(base + (p - base) * 1.1)
	ci.draw_colored_polygon(outp, OUTLINE)
	ci.draw_colored_polygon(pts, Color("c8955a"))
	# vỏ lụa và vân
	ci.draw_arc(base + Vector2(4, 0) * s, 10 * s, -1.2, 1.0, 10, Color("9a6a3a"), 1.4 * s)
	ci.draw_line(base + Vector2(0, -15) * s, base + Vector2(0, 8) * s, Color("a8743e"), 1.2 * s)
	ci.draw_circle(base + Vector2(-5, -2) * s, 4 * s, Color("e2b67a"))
	# chóp mầm
	ci.draw_line(base + Vector2(0, -16) * s, base + Vector2(1, -21) * s, Color("7aa04a"), 2.2 * s)


# ---------------- Hoa chuông: dẹp dài, nâu ----------------
static func _chuong(ci: CanvasItem, c: Vector2, s: float) -> void:
	_blob(ci, c, 21 * s, 6 * s, -0.45, Color("8a5a2b"), 0.08)
	var d := Vector2(1, 0).rotated(-0.45)
	ci.draw_line(c - d * 15 * s, c + d * 15 * s, Color("5e3a1a"), 1.4 * s)
	_shine(ci, c + Vector2(-6, -5) * s, 2.0 * s)


# ---------------- Hoa lan: tròn nhỏ, màu kem ----------------
static func _lan(ci: CanvasItem, c: Vector2, s: float) -> void:
	_blob(ci, c, 7.5 * s, 7.5 * s, 0.0, Color("e8d4a0"))
	ci.draw_circle(c + Vector2(1.5, 1.5) * s, 4 * s, Color("d2b97e"))
	_shine(ci, c + Vector2(-2.5, -2.5) * s, 1.8 * s)


# ---------------- Hoa sen: bầu dục vàng nâu, đầu sẫm ----------------
static func _sen(ci: CanvasItem, c: Vector2, s: float) -> void:
	_blob(ci, c, 12 * s, 15 * s, 0.0, Color("c9a24a"))
	ci.draw_circle(c + Vector2(-3, -2) * s, 7 * s, Color("dcb860"))
	ci.draw_circle(c + Vector2(0, -12) * s, 3.2 * s, Color("5a3a14"))
	ci.draw_arc(c, 9 * s, 0.3, 1.6, 8, Color("9a7a2e"), 1.4 * s)
	_shine(ci, c + Vector2(-5, -6) * s, 2.4 * s)


# ---------------- Hoa rồng: củ tím sẫm có đốm, mầm đỏ ----------------
static func _rong(ci: CanvasItem, c: Vector2, s: float) -> void:
	# mầm nhọn màu đỏ tía
	var tip := PackedVector2Array([c + Vector2(-3, -10) * s, c + Vector2(4, -10) * s, c + Vector2(2, -22) * s])
	ci.draw_colored_polygon(tip, Color("b0283a"))
	ci.draw_polyline(PackedVector2Array([tip[0], tip[2], tip[1]]), OUTLINE, 1.2 * s)
	# củ dẹt, mép gợn
	_blob(ci, c + Vector2(0, 3) * s, 16 * s, 11 * s, 0.0, Color("4a2440"), 0.12)
	for p in [Vector2(-8, 2), Vector2(5, 6), Vector2(-2, 8), Vector2(9, -1), Vector2(-11, 7)]:
		ci.draw_circle(c + p * s, 2.0 * s, Color("8a5a8a"))
	for p in [Vector2(2, 0), Vector2(-6, 9)]:
		ci.draw_circle(c + p * s, 1.6 * s, Color("7aa04a"))
	_shine(ci, c + Vector2(-7, -3) * s, 2.0 * s)
