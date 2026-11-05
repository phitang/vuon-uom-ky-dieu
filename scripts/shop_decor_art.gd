extends RefCounted
## Vẽ đồ trang trí Shop cây: bảng hiệu, quầy, hàng rào (4 bậc mỗi loại) và các món trang trí.
## Dùng chung cho cảnh shop (nursery.gd) và hình xem trước trong cửa hàng trang trí.

const GOLD := Color("d9b26a")
const GOLD_DARK := Color("9a7430")
const INK := Color("2a1a0c")


static func _ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)


static func _round_rect(ci: CanvasItem, r: Rect2, rad: float, col: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(rad))
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)


static func _frame(ci: CanvasItem, r: Rect2, rad: float, fill: Color, border: Color, bw: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(int(bw))
	sb.set_corner_radius_all(int(rad))
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)


# =====================================================================
# Bảng hiệu (đặt trên cổng). Trả về khung chữ nhật để bắt chạm.
# =====================================================================
static func draw_sign(ci: CanvasItem, center: Vector2, text: String, tier: int, font: Font, t := 0.0) -> Rect2:
	var fs := 17 if tier == 0 else 19
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var w := maxf(130.0, tw + (36.0 if tier < 2 else 52.0))
	var h := 26.0 if tier == 0 else 32.0
	var r := Rect2(center - Vector2(w / 2.0, h / 2.0), Vector2(w, h))
	var text_col := Color("fff1cf")
	match tier:
		0:
			ci.draw_rect(r, Color("8a5a2b"))
			ci.draw_rect(r, GOLD, false, 2.0)
		1:
			_frame(ci, r.grow(3), 8, GOLD_DARK, GOLD_DARK, 0)
			_frame(ci, r, 7, Color("2f6a3c"), GOLD, 3)
			ci.draw_rect(Rect2(r.position + Vector2(6, 5), Vector2(r.size.x - 12, 3)), Color(1, 1, 1, 0.12))
			for sx in [r.position.x + 9, r.end.x - 9]:
				for k in 5:
					ci.draw_circle(Vector2(sx, r.position.y - 2) + Vector2.from_angle(TAU * k / 5.0) * 3.4, 2.6, Color("f2a7c3"))
				ci.draw_circle(Vector2(sx, r.position.y - 2), 2.0, Color("f6d55c"))
		2:
			# gỗ chạm, đỉnh vòm, hai đèn treo
			var arch := PackedVector2Array()
			for i in 17:
				var a := PI + PI * i / 16.0
				arch.append(Vector2(center.x + cos(a) * w / 2.0, r.position.y + 2 + sin(a) * 12.0))
			arch.append(Vector2(r.end.x, r.end.y))
			arch.append(Vector2(r.position.x, r.end.y))
			var outline := PackedVector2Array()
			for p in arch:
				outline.append(center + (p - center) * Vector2(1.03, 1.08))
			ci.draw_colored_polygon(outline, Color("3a2210"))
			ci.draw_colored_polygon(arch, Color("7a4520"))
			ci.draw_polyline(arch, GOLD, 2.0)
			ci.draw_line(Vector2(r.position.x + 10, r.end.y - 6), Vector2(r.end.x - 10, r.end.y - 6), Color("5a3214"), 2.0)
			for sx in [r.position.x - 10, r.end.x + 10]:
				var top := Vector2(sx, r.position.y + 4)
				ci.draw_line(top, top + Vector2(0, 12), Color("3a2a1a"), 1.5)
				var glow := 0.6 + 0.4 * sin(t * 4.0 + sx)
				ci.draw_circle(top + Vector2(0, 20), 13, Color(1, 0.85, 0.4, 0.18 * glow))
				_round_rect(ci, Rect2(top + Vector2(-6, 12), Vector2(12, 15)), 3, Color("e8a63a"))
				ci.draw_rect(Rect2(top + Vector2(-6, 12), Vector2(12, 3)), Color("3a2a1a"))
		_:
			# cẩm thạch trắng, chữ vàng, hoa văn vàng
			_frame(ci, r.grow(5), 10, GOLD, GOLD_DARK, 2)
			_frame(ci, r, 8, Color("f2efe8"), GOLD, 2)
			for i in 4:
				var y := r.position.y + 5 + i * 7
				ci.draw_line(Vector2(r.position.x + 8 + i * 9, y), Vector2(r.position.x + 30 + i * 13, y + 4), Color(0.75, 0.75, 0.8, 0.5), 1.0)
			ci.draw_colored_polygon(PackedVector2Array([center + Vector2(-10, -h / 2 - 5), center + Vector2(0, -h / 2 - 16), center + Vector2(10, -h / 2 - 5)]), GOLD)
			ci.draw_circle(center + Vector2(0, -h / 2 - 9), 3, Color("e2453c"))
			var sh := fmod(t * 0.5, 1.6) - 0.3
			if sh > 0.0 and sh < 1.0:
				var x := r.position.x + r.size.x * sh
				ci.draw_line(Vector2(x, r.position.y + 2), Vector2(x - 10, r.end.y - 2), Color(1, 1, 1, 0.6), 4.0)
			text_col = Color("a8741a")
	var tx := center.x - tw / 2.0
	var ty := center.y + fs * 0.36
	if tier >= 1:
		ci.draw_string(font, Vector2(tx + 1, ty + 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.35))
	ci.draw_string(font, Vector2(tx, ty), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)
	return r.grow(8)


# =====================================================================
# Cổng (hai trụ) theo kiểu hàng rào
# =====================================================================
static func draw_gate_posts(ci: CanvasItem, gate_x: float, fy: float, tier: int) -> void:
	for side in [-1, 1]:
		var x: float = gate_x + side * 70
		match tier:
			3:
				ci.draw_rect(Rect2(x - 12, fy - 50, 24, 80), Color("a0523a"))
				for k in 5:
					ci.draw_line(Vector2(x - 12, fy - 50 + k * 16), Vector2(x + 12, fy - 50 + k * 16), Color("e8d8c0"), 1.5)
				ci.draw_rect(Rect2(x - 15, fy - 56, 30, 8), Color("cfc7b8"))
			2:
				ci.draw_rect(Rect2(x - 6, fy - 48, 12, 76), Color("2a2a2e"))
				ci.draw_circle(Vector2(x, fy - 52), 6, GOLD)
			1:
				ci.draw_rect(Rect2(x - 8, fy - 46, 16, 74), Color("f4f1ea"))
				ci.draw_rect(Rect2(x - 8, fy - 46, 16, 74), Color("b8b2a6"), false, 1.5)
			_:
				ci.draw_rect(Rect2(x - 8, fy - 46, 16, 74), Color("6a4426"))


# =====================================================================
# Hàng rào (trừ khoảng cổng)
# =====================================================================
static func draw_fence(ci: CanvasItem, w: float, fy: float, gate_x: float, tier: int) -> void:
	var open := func(x: float) -> bool: return absf(x - gate_x) <= 72
	match tier:
		0:
			for seg in [[0.0, gate_x - 70], [gate_x + 70, w]]:
				ci.draw_rect(Rect2(seg[0], fy - 4, seg[1] - seg[0], 8), Color("9a6a3a"))
				ci.draw_rect(Rect2(seg[0], fy + 14, seg[1] - seg[0], 8), Color("9a6a3a"))
			var x := 10.0
			while x < w:
				if not open.call(x):
					ci.draw_rect(Rect2(x, fy - 18, 10, 46), Color("7a5230"))
				x += 42.0
		1:
			for seg in [[0.0, gate_x - 70], [gate_x + 70, w]]:
				ci.draw_rect(Rect2(seg[0], fy - 2, seg[1] - seg[0], 6), Color("e6e2d8"))
				ci.draw_rect(Rect2(seg[0], fy + 14, seg[1] - seg[0], 6), Color("e6e2d8"))
			var x := 6.0
			while x < w:
				if not open.call(x + 6):
					var pts := PackedVector2Array([Vector2(x, fy + 28), Vector2(x, fy - 16), Vector2(x + 6, fy - 24), Vector2(x + 12, fy - 16), Vector2(x + 12, fy + 28)])
					ci.draw_colored_polygon(pts, Color("f8f6f0"))
					ci.draw_polyline(pts, Color("b8b2a6"), 1.2)
				x += 22.0
		2:
			for seg in [[0.0, gate_x - 70], [gate_x + 70, w]]:
				ci.draw_rect(Rect2(seg[0], fy - 14, seg[1] - seg[0], 4), Color("2a2a2e"))
				ci.draw_rect(Rect2(seg[0], fy + 20, seg[1] - seg[0], 4), Color("2a2a2e"))
			var x := 8.0
			var i := 0
			while x < w:
				if not open.call(x):
					ci.draw_rect(Rect2(x - 1.5, fy - 22, 3, 50), Color("2a2a2e"))
					ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 4, fy - 22), Vector2(x, fy - 30), Vector2(x + 4, fy - 22)]), GOLD)
					if i % 2 == 0 and not open.call(x + 9):
						ci.draw_arc(Vector2(x + 9, fy + 4), 6, 0, TAU, 14, Color("2a2a2e"), 2.0)
				x += 18.0
				i += 1
		_:
			for seg in [[0.0, gate_x - 82], [gate_x + 82, w]]:
				var r := Rect2(seg[0], fy - 4, seg[1] - seg[0], 32)
				ci.draw_rect(r, Color("a0523a"))
				var row := 0
				var y := fy - 4
				while y < fy + 28:
					ci.draw_line(Vector2(seg[0], y), Vector2(seg[1], y), Color("e8d8c0"), 1.2)
					var bx: float = seg[0] + (0.0 if row % 2 == 0 else 12.0)
					while bx < seg[1]:
						ci.draw_line(Vector2(bx, y), Vector2(bx, y + 8), Color("e8d8c0"), 1.2)
						bx += 24.0
					y += 8.0
					row += 1
				ci.draw_rect(Rect2(seg[0], fy - 10, seg[1] - seg[0], 7), Color("cfc7b8"))
				# bồn hoa trên tường
				var fx: float = seg[0] + 16
				var k := 0
				while fx < seg[1] - 10:
					ci.draw_circle(Vector2(fx, fy - 14), 7, Color("4f9a45"))
					ci.draw_circle(Vector2(fx + 2, fy - 17), 3, [Color("f2a7c3"), Color("f6d55c"), Color("e2453c"), Color("9b6bd6")][k % 4])
					fx += 20.0
					k += 1
				# cột đèn
				var lx := float(seg[0]) + 60.0
				while lx < seg[1] - 20:
					ci.draw_rect(Rect2(lx - 2, fy - 44, 4, 34), Color("2a2a2e"))
					ci.draw_circle(Vector2(lx, fy - 48), 6, Color("fff1b0"))
					ci.draw_circle(Vector2(lx, fy - 48), 11, Color(1, 0.95, 0.6, 0.2))
					lx += 240.0


# =====================================================================
# Quầy: phần phía sau người bán (mái che) và mặt trước quầy
# =====================================================================
static func draw_counter_back(ci: CanvasItem, d: Rect2, tier: int, t := 0.0) -> void:
	if tier <= 0:
		return
	var top := d.position.y - 84
	for x in [d.position.x + 6, d.end.x - 12]:
		ci.draw_rect(Rect2(x, top + 18, 6, d.position.y - top - 18), Color("6e4527") if tier < 3 else Color("8a6a2a"))
	match tier:
		1:
			for i in 8:
				var col := Color("3e8a4a") if i % 2 == 0 else Color("f4f1ea")
				var x0 := d.position.x - 10 + i * (d.size.x + 20) / 8.0
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x0, top), Vector2(x0 + (d.size.x + 20) / 8.0, top), Vector2(x0 + (d.size.x + 20) / 8.0, top + 22), Vector2(x0, top + 22)]), col)
				ci.draw_circle(Vector2(x0 + (d.size.x + 20) / 16.0, top + 22), (d.size.x + 20) / 16.0, col)
		2:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(d.position.x - 16, top + 22), Vector2(d.end.x + 16, top + 22), Vector2(d.end.x - 10, top - 4), Vector2(d.position.x + 10, top - 4)]), Color("7a4520"))
			for i in 6:
				var x := d.position.x - 10 + i * (d.size.x + 20) / 5.0
				ci.draw_line(Vector2(x, top + 22), Vector2(lerpf(d.position.x + 10, d.end.x - 10, i / 5.0), top - 4), Color("5a3214"), 2.0)
		_:
			var c := Vector2(d.get_center().x, top + 20)
			var arc := PackedVector2Array()
			for i in 25:
				var a := PI + PI * i / 24.0
				arc.append(c + Vector2(cos(a) * (d.size.x / 2.0 + 14), sin(a) * 34))
			ci.draw_colored_polygon(arc, Color("2f6a3c"))
			ci.draw_polyline(arc, GOLD, 3.0)
			for i in 7:
				var a := PI + PI * (i + 0.5) / 7.0
				var p := c + Vector2(cos(a) * (d.size.x / 2.0 + 14), sin(a) * 34)
				var g := 0.6 + 0.4 * sin(t * 3.0 + i)
				ci.draw_circle(p, 6, Color(1, 0.9, 0.5, 0.25 * g))
				ci.draw_circle(p, 2.5, Color(1, 0.95, 0.7, g))


static func draw_counter_front(ci: CanvasItem, size: Vector2, tier: int, font: Font) -> void:
	var w := size.x
	var h := size.y
	match tier:
		0:
			ci.draw_rect(Rect2(0, 0, w, h), Color("8a5a2b"))
			ci.draw_rect(Rect2(0, 0, w, 10), Color("c9955a"))
			ci.draw_rect(Rect2(0, h - 6, w, 6), Color("6e4527"))
			for i in 3:
				ci.draw_line(Vector2(w * (i + 1) / 4.0, 14), Vector2(w * (i + 1) / 4.0, h - 8), Color("7a4e26"), 2.0)
		1:
			ci.draw_rect(Rect2(0, 0, w, h), Color("6e3a1a"))
			for i in 3:
				_frame(ci, Rect2(8 + i * (w - 16) / 3.0, 16, (w - 16) / 3.0 - 6, h - 26), 3, Color("8a4a22"), Color("c08a3a"), 2)
			ci.draw_rect(Rect2(-4, 0, w + 8, 10), Color("b06a32"))
			ci.draw_rect(Rect2(-4, 0, w + 8, 3), Color("e0a060"))
		2:
			ci.draw_rect(Rect2(0, h * 0.55, w, h * 0.45), Color("7a4520"))
			_frame(ci, Rect2(4, 10, w - 8, h * 0.5), 3, Color(0.75, 0.9, 0.95, 0.55), Color("c0d8e0"), 2)
			for i in 6:
				var x := 16 + i * (w - 30) / 5.0
				ci.draw_circle(Vector2(x, h * 0.45), 6, Color("4f9a45"))
				ci.draw_circle(Vector2(x, h * 0.4), 3.5, [Color("f2a7c3"), Color("f6d55c"), Color("e2453c")][i % 3])
			ci.draw_line(Vector2(10, 14), Vector2(26, 30), Color(1, 1, 1, 0.6), 2.0)
			ci.draw_rect(Rect2(-4, 0, w + 8, 10), Color("e8e4dc"))
		_:
			ci.draw_rect(Rect2(0, 0, w, h), Color("3a2414"))
			_frame(ci, Rect2(6, 14, w - 12, h - 22), 4, Color("4a2e18"), GOLD, 2)
			ci.draw_rect(Rect2(-6, 0, w + 12, 11), Color("ece8e0"))
			ci.draw_line(Vector2(-6, 11), Vector2(w + 6, 11), GOLD, 2.0)
			# lọ hoa trên quầy
			ci.draw_rect(Rect2(14, -16, 10, 16), Color("4a86c8"))
			for k in 4:
				ci.draw_circle(Vector2(19, -18) + Vector2.from_angle(-PI / 2 + (k - 1.5) * 0.5) * 9, 4, [Color("f2a7c3"), Color("f6d55c"), Color("e2453c"), Color("ffffff")][k])
	# máy tính tiền
	var reg := Color("6f7a82") if tier < 3 else Color("b08a3a")
	ci.draw_rect(Rect2(w - 52, -22, 40, 24), reg)
	ci.draw_rect(Rect2(w - 48, -20, 32, 9), Color("b9e3c6"))
	var lab_col := Color("fff1cf") if tier != 2 else Color("f4f1ea")
	ci.draw_string(font, Vector2(14, h - 14 if tier == 2 else 40), "QUẦY", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, lab_col if tier != 3 else GOLD)


# =====================================================================
# Đồ trang trí (pos = chân đế, s = tỉ lệ)
# =====================================================================
static func draw_decor(ci: CanvasItem, id: String, pos: Vector2, s := 1.0, t := 0.0) -> void:
	match id:
		"den_long":
			_ellipse(ci, pos, 12 * s, 4 * s, Color(0, 0, 0, 0.18))
			ci.draw_rect(Rect2(pos + Vector2(-3, -70) * s, Vector2(6, 70) * s), Color("2a2a2e"))
			ci.draw_line(pos + Vector2(0, -70) * s, pos + Vector2(14, -70) * s, Color("2a2a2e"), 3 * s)
			var lp := pos + Vector2(14, -54) * s
			var g := 0.7 + 0.3 * sin(t * 5.0 + pos.x)
			ci.draw_circle(lp, 22 * s, Color(1, 0.6, 0.3, 0.14 * g))
			ci.draw_line(lp + Vector2(0, -16) * s, lp + Vector2(0, -12) * s, Color("2a2a2e"), 1.5 * s)
			_ellipse(ci, lp, 9 * s, 12 * s, Color("d8302a"))
			_ellipse(ci, lp + Vector2(-2, -3) * s, 4 * s, 6 * s, Color(1, 0.75, 0.4, 0.7 * g))
			ci.draw_rect(Rect2(lp + Vector2(-5, -13) * s, Vector2(10, 3) * s), GOLD)
			ci.draw_rect(Rect2(lp + Vector2(-5, 10) * s, Vector2(10, 3) * s), GOLD)
			ci.draw_line(lp + Vector2(0, 13) * s, lp + Vector2(0, 21) * s, GOLD, 1.5 * s)
		"ghe_da":
			_ellipse(ci, pos + Vector2(0, 2) * s, 40 * s, 7 * s, Color(0, 0, 0, 0.2))
			for x in [-26, 20]:
				ci.draw_rect(Rect2(pos + Vector2(x, -16) * s, Vector2(8, 16) * s), Color("8f8c84"))
			_round_rect(ci, Rect2(pos + Vector2(-36, -24) * s, Vector2(72, 10) * s), 3 * s, Color("b7b4aa"))
			ci.draw_rect(Rect2(pos + Vector2(-36, -24) * s, Vector2(72, 3) * s), Color("d8d6cf"))
		"o_du":
			_ellipse(ci, pos, 34 * s, 7 * s, Color(0, 0, 0, 0.18))
			ci.draw_rect(Rect2(pos + Vector2(-2, -74) * s, Vector2(4, 74) * s), Color("8a8a8a"))
			_ellipse(ci, pos + Vector2(0, -24) * s, 20 * s, 6 * s, Color("8a5a2b"))
			ci.draw_rect(Rect2(pos + Vector2(-2, -24) * s, Vector2(4, 24) * s), Color("6e4527"))
			for i in 6:
				var a0 := PI + PI * i / 6.0
				var a1 := PI + PI * (i + 1) / 6.0
				var tip := pos + Vector2(0, -88) * s
				var col := Color("e2453c") if i % 2 == 0 else Color("f4f1ea")
				ci.draw_colored_polygon(PackedVector2Array([tip, pos + Vector2(cos(a0) * 38, -66 + sin(a0) * -2) * s, pos + Vector2(cos(a1) * 38, -66 + sin(a1) * -2) * s]), col)
		"bon_hoa":
			_ellipse(ci, pos, 36 * s, 11 * s, Color("8f8c84"))
			_ellipse(ci, pos + Vector2(0, -3) * s, 32 * s, 9 * s, Color("5a3a22"))
			var cols := [Color("f2a7c3"), Color("f6d55c"), Color("e2453c"), Color("9b6bd6"), Color("ffffff"), Color("f39a3d")]
			for i in 11:
				var p := pos + Vector2(-26 + i * 5.2, -8 - (i % 3) * 4) * s
				ci.draw_circle(p + Vector2(0, 4) * s, 4.5 * s, Color("4f9a45"))
				ci.draw_circle(p, 3.2 * s, cols[i % cols.size()])
		"tuong":
			_ellipse(ci, pos, 22 * s, 6 * s, Color(0, 0, 0, 0.2))
			ci.draw_rect(Rect2(pos + Vector2(-16, -16) * s, Vector2(32, 16) * s), Color("9c978b"))
			ci.draw_rect(Rect2(pos + Vector2(-18, -20) * s, Vector2(36, 5) * s), Color("b9b4a6"))
			var st := Color("c9c6bc")
			_ellipse(ci, pos + Vector2(0, -34) * s, 12 * s, 14 * s, st)
			ci.draw_circle(pos + Vector2(0, -52) * s, 9 * s, st)
			_ellipse(ci, pos + Vector2(-4, -68) * s, 3 * s, 10 * s, st)
			_ellipse(ci, pos + Vector2(4, -68) * s, 3 * s, 10 * s, st)
			ci.draw_circle(pos + Vector2(-3, -53) * s, 1.3 * s, Color("5a5a5a"))
			ci.draw_circle(pos + Vector2(3, -53) * s, 1.3 * s, Color("5a5a5a"))
			ci.draw_circle(pos + Vector2(10, -24) * s, 4 * s, st)
		"coi_xay_gio":
			var body := PackedVector2Array([pos + Vector2(-14, 0) * s, pos + Vector2(14, 0) * s, pos + Vector2(8, -54) * s, pos + Vector2(-8, -54) * s])
			ci.draw_colored_polygon(body, Color("e8dcc8"))
			ci.draw_colored_polygon(PackedVector2Array([pos + Vector2(-11, -54) * s, pos + Vector2(11, -54) * s, pos + Vector2(0, -68) * s]), Color("a0523a"))
			ci.draw_rect(Rect2(pos + Vector2(-4, -14) * s, Vector2(8, 14) * s), Color("6e4527"))
			var hub := pos + Vector2(0, -50) * s
			for i in 4:
				var a := t * 1.5 + i * PI / 2.0
				var dir := Vector2.from_angle(a)
				var nrm := Vector2(-dir.y, dir.x)
				ci.draw_colored_polygon(PackedVector2Array([hub + nrm * 2 * s, hub + dir * 34 * s + nrm * 2 * s, hub + dir * 34 * s + nrm * 9 * s, hub + dir * 8 * s + nrm * 7 * s]), Color("f4f1ea"))
				ci.draw_line(hub, hub + dir * 34 * s, Color("6e4527"), 2 * s)
			ci.draw_circle(hub, 3 * s, Color("3a2a1a"))
		"xich_du":
			_ellipse(ci, pos, 40 * s, 7 * s, Color(0, 0, 0, 0.18))
			var wood := Color("7a5230")
			for x in [-34, 34]:
				ci.draw_line(pos + Vector2(x - 6, 0) * s, pos + Vector2(x * 0.8, -74) * s, wood, 4 * s)
				ci.draw_line(pos + Vector2(x + 6, 0) * s, pos + Vector2(x * 0.8, -74) * s, wood, 4 * s)
			ci.draw_line(pos + Vector2(-30, -74) * s, pos + Vector2(30, -74) * s, wood, 5 * s)
			var sw := sin(t * 1.6) * 8.0
			var seat := pos + Vector2(sw, -22) * s
			for x in [-14, 14]:
				ci.draw_line(pos + Vector2(x, -74) * s, seat + Vector2(x, 0) * s, Color("8a8a8a"), 1.5 * s)
			_round_rect(ci, Rect2(seat + Vector2(-18, -3) * s, Vector2(36, 6) * s), 2 * s, Color("c9955a"))
		"chuong_gio":
			var top := pos
			ci.draw_line(top + Vector2(-12, 0) * s, top + Vector2(12, 0) * s, Color("6e4527"), 3 * s)
			for i in 5:
				var x := (-10 + i * 5) * s
				var sway := sin(t * 3.0 + i) * 3.0 * s
				var l := (14 + (i % 3) * 5) * s
				ci.draw_line(top + Vector2(x, 0), top + Vector2(x + sway, l), Color("a8a8a8"), 1.0)
				ci.draw_rect(Rect2(top + Vector2(x + sway - 1.5 * s, l), Vector2(3 * s, 10 * s)), Color("cfd6dc"))
			ci.draw_circle(top + Vector2(sin(t * 3.0) * 2.0, 34) * s, 3 * s, Color("e2453c"))


## Kích thước chuẩn của hình xem trước (dùng trong cửa hàng).
static func draw_preview(ci: CanvasItem, kind: String, tier: int, size: Vector2, font: Font, t := 0.0) -> void:
	var c := size / 2.0
	match kind:
		"bang_hieu":
			ci.draw_rect(Rect2(Vector2.ZERO, size), Color("a9dcf0"))
			ci.draw_rect(Rect2(0, size.y * 0.6, size.x, size.y * 0.4), Color("6fb35a"))
			draw_gate_posts(ci, c.x, size.y * 0.75, 0)
			draw_sign(ci, Vector2(c.x, size.y * 0.75 - 43), "SHOP", tier, font, t)
		"quay":
			ci.draw_rect(Rect2(Vector2.ZERO, size), Color("6fb35a"))
			var d := Rect2(Vector2(c.x - 50, size.y - 40), Vector2(100, 34))
			draw_counter_back(ci, Rect2(d.position + Vector2(0, 30), d.size), tier, t)
			ci.draw_set_transform(d.position, 0.0, Vector2(100.0 / 170.0, 34.0 / 56.0))
			draw_counter_front(ci, Vector2(170, 56), tier, font)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"hang_rao":
			ci.draw_rect(Rect2(Vector2.ZERO, size), Color("a9dcf0"))
			ci.draw_rect(Rect2(0, size.y * 0.55, size.x, size.y * 0.45), Color("6fb35a"))
			draw_fence(ci, size.x, size.y * 0.55, -1000.0, tier)
		_:
			ci.draw_rect(Rect2(Vector2.ZERO, size), Color("6fb35a"))
			var s := 0.62 if kind in ["o_du", "xich_du", "den_long", "coi_xay_gio", "tuong"] else 0.85
			var base := Vector2(c.x - (8.0 * s if kind == "den_long" else 0.0), size.y - 8)
			if kind == "chuong_gio":
				base = Vector2(c.x, 10)
				s = 1.1
			draw_decor(ci, kind, base, s, t)
