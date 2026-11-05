extends Control
## Vẽ một cây trong chậu.
## - Nếu có ảnh vẽ tay trong thư mục art/ thì dùng ảnh, tô lại màu cánh hoa theo gen.
##   art/chau_trong.png        chậu trống
##   art/chung/0.png, 1.png    hạt nảy mầm, cây non (dùng chung cho mọi loài)
##   art/<hoa>/2.png, 3.png    nụ, ra hoa (ví dụ art/cuc/3.png). Tùy chọn: 0.png, 1.png, 4.png (già)
##   Ảnh 300 x 542, nền trong suốt, chậu đặt đúng vị trí như ảnh mẫu.
##   Vẽ cánh hoa màu TRẮNG để game tô được mọi màu.
## - Loài chưa có ảnh thì vẽ bằng code, đặt trong chậu vẽ tay.

const Data := preload("res://scripts/data.gd")
const Gen := preload("res://scripts/genetics.gd")
const TINT_SHADER := preload("res://scripts/plant_tint.gdshader")

const ART_SIZE := Vector2(300, 542)
const ART_SOIL := Vector2(150, 336)   # gốc cây trong ảnh chậu
static var _tex_cache := {}

var pheno: Dictionary = {}   # kiểu hiển thị; rỗng = chậu trống
var stage := 3
var dead := false
var wilted := false
var silhouette := false      # vẽ bóng đen (giống chưa tìm ra)
var show_pot := true
var soil := "thuong"         # "thuong", "tot", "hiem" hoặc "" (chậu chưa có đất)


func set_plant(gen: Dictionary, p_stage: int, p_dead := false, p_wilted := false) -> void:
	pheno = Gen.phenotype(gen) if not gen.is_empty() else {}
	stage = p_stage
	dead = p_dead
	wilted = p_wilted
	queue_redraw()


func set_pheno(p: Dictionary, p_stage := 3) -> void:
	pheno = p
	stage = p_stage
	dead = false
	wilted = false
	queue_redraw()


func clear() -> void:
	pheno = {}
	queue_redraw()


func set_soil(t: String) -> void:
	if soil != t:
		soil = t
		queue_redraw()


## Phủ màu đất tốt / đất hiếm lên lớp đất trong ảnh chậu.
func _draw_soil_overlay(rect: Rect2) -> void:
	if soil != "tot" and soil != "hiem":
		return
	var k := rect.size.x / ART_SIZE.x
	var c := rect.position + Vector2(155, 347) * k
	var pts := PackedVector2Array()
	for i in 32:
		var t := TAU * i / 32.0
		pts.append(c + Vector2(cos(t) * 98.0, sin(t) * 9.0) * k)
	if soil == "tot":
		draw_colored_polygon(pts, Color(0.12, 0.07, 0.03, 0.5))
		for i in 5:
			draw_circle(c + Vector2(-70 + i * 34, -2 + (i % 2) * 4) * k, 2.2 * k, Color(0.35, 0.6, 0.25, 0.8))
	else:
		draw_colored_polygon(pts, Color(0.35, 0.15, 0.5, 0.45))
		for i in 7:
			var q := c + Vector2(-80 + i * 27, -3 + (i % 3) * 3) * k
			draw_circle(q, 2.4 * k, Color(1.0, 0.85, 0.35, 0.95))
			draw_circle(q, 1.0 * k, Color(1, 1, 1, 0.95))


func _ready() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = TINT_SHADER
	material = mat


static func _art(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex_cache[path]


## Ảnh cho giai đoạn hiện tại (null nếu loài này chưa có ảnh).
func _stage_texture() -> Texture2D:
	var hoa: String = pheno.get("hoa", "")
	var own := _art("res://art/%s/%d.png" % [hoa, stage])
	if own:
		return own
	if stage <= 1:
		return _art("res://art/chung/%d.png" % stage)
	if stage == 4:
		return _art("res://art/%s/3.png" % hoa)
	return null


func _art_rect() -> Rect2:
	var s: float = min(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	var sz := ART_SIZE * s
	return Rect2(Vector2((size.x - sz.x) / 2.0, size.y - sz.y), sz)


func _set_shader(tinted: bool, fade: float, sil: bool) -> void:
	var mat := material as ShaderMaterial
	if mat == null:
		return
	var m: String = pheno.get("mau", "trang")
	mat.set_shader_parameter("use_tint", tinted and m != "trang")
	mat.set_shader_parameter("tint", Data.FLOWER_COLORS.get(m, Color.WHITE))
	mat.set_shader_parameter("rainbow", m == "cauvong")
	mat.set_shader_parameter("fade", fade)
	mat.set_shader_parameter("silhouette", sil)


func _draw() -> void:
	var rect := _art_rect()
	var pot_tex := _art("res://art/chau_trong.png")
	if pheno.is_empty():
		_set_shader(false, 0.0, false)
		var bare := _art("res://art/chau_khong_dat.png")
		if show_pot and soil == "" and bare:
			draw_texture_rect(bare, rect, false)
		elif show_pot and pot_tex:
			draw_texture_rect(pot_tex, rect, false)
			_draw_soil_overlay(rect)
		elif show_pot:
			var u0: float = min(size.x, size.y) / 100.0
			_draw_pot(Vector2(size.x / 2.0, size.y - 4.0 * u0), u0)
		return
	var tex := _stage_texture()
	if tex:
		var fade := 0.0
		if dead:
			fade = 0.85
		elif wilted:
			fade = 0.35
		elif stage == 4 and tex != _art("res://art/%s/4.png" % pheno.get("hoa", "")):
			fade = 0.4
		_set_shader(stage >= 2, fade, silhouette)
		draw_texture_rect(tex, rect, false)
		_draw_soil_overlay(rect)
		return
	# Loài chưa có ảnh: chậu vẽ tay + cây vẽ bằng code
	_set_shader(false, 0.0, false)
	if pot_tex:
		draw_texture_rect(pot_tex, rect, false)
		_draw_soil_overlay(rect)
		var k := rect.size.x / ART_SIZE.x
		_draw_code_plant(rect.position + ART_SOIL * k, rect.size.y / 100.0)
	else:
		var u: float = min(size.x, size.y) / 100.0
		var base := Vector2(size.x / 2.0, size.y - 4.0 * u)
		if show_pot:
			_draw_pot(base, u)
		_draw_code_plant(base + Vector2(0, -22 * u), u)


func _draw_code_plant(soil: Vector2, u: float) -> void:
	if stage == 0:
		draw_circle(soil + Vector2(0, -2 * u), 3 * u, _c(Color("8a6a3a")))
		_draw_leaf_shape("tron", soil + Vector2(0, -5 * u), -PI / 2 - 0.5, 5 * u, _leaf_color())
		_draw_leaf_shape("tron", soil + Vector2(0, -5 * u), -PI / 2 + 0.5, 5 * u, _leaf_color())
		return
	var size_mult := {"nho": 0.75, "vua": 0.9, "lon": 1.05}.get(pheno.get("co", "vua"), 0.9) as float
	var height: float = [0.0, 0.35, 0.75, 1.0, 1.0][stage] * 62.0 * u * size_mult
	var top := _draw_stem(soil, height, u)
	# lá dọc thân
	var leaf_count: int = 2 if stage == 1 else 4
	for i in leaf_count:
		var t := 0.25 + 0.5 * float(i) / maxi(1, leaf_count - 1)
		var pt := soil.lerp(top, t) + Vector2(_stem_offset(t, height, u), 0)
		var side := -1.0 if i % 2 == 0 else 1.0
		var ang := (PI if side < 0 else 0.0) + side * -0.45
		if wilted or dead:
			ang += side * 0.6
		_draw_leaf_shape(pheno["la"], pt, ang, (9.0 if stage > 1 else 6.0) * u * size_mult, _leaf_color())
	if stage == 2:
		draw_circle(top, 4 * u, _c(_leaf_color().darkened(0.15)))
		draw_circle(top + Vector2(0, -2 * u), 3 * u, _c(_flower_color(0).darkened(0.1)))
	elif stage >= 3:
		var r := 14.0 * u * size_mult
		if stage == 4 or wilted or dead:
			r *= 0.8
		_draw_flower(pheno["hoa"], top, r, u)


func _c(col: Color) -> Color:
	if silhouette:
		return Color(0.25, 0.27, 0.25, 0.9)
	if dead:
		return col.lerp(Color("7a6650"), 0.75)
	if wilted or stage == 4:
		return col.lerp(Color("a08a60"), 0.4)
	return col


func _leaf_color() -> Color:
	if pheno.get("la", "") == "bac":
		return Color("b9c7cf")
	return Color("5fae55")


func _flower_color(i: int) -> Color:
	var m: String = pheno.get("mau", "trang")
	if m == "cauvong":
		return Color.from_hsv(fmod(i * 0.14, 1.0), 0.65, 0.98)
	return Data.FLOWER_COLORS[m]


func _draw_pot(base: Vector2, u: float) -> void:
	var col := Color("b5653a")
	var pts := PackedVector2Array([
		base + Vector2(-18 * u, -22 * u), base + Vector2(18 * u, -22 * u),
		base + Vector2(14 * u, 0), base + Vector2(-14 * u, 0)])
	draw_colored_polygon(pts, col)
	draw_rect(Rect2(base + Vector2(-20 * u, -26 * u), Vector2(40 * u, 6 * u)), col.lightened(0.12))
	draw_rect(Rect2(base + Vector2(-17 * u, -21 * u), Vector2(34 * u, 2.5 * u)), Color("5a3d22"))


# ---------------- Thân ----------------

func _stem_offset(t: float, height: float, u: float) -> float:
	match pheno.get("than", "thang"):
		"cong":
			return sin(t * PI) * 8.0 * u
		"xoan":
			return sin(t * PI * 3.0) * 4.0 * u
	return 0.0


func _draw_stem(soil: Vector2, height: float, u: float) -> Vector2:
	var kind: String = pheno.get("than", "thang")
	var pts := PackedVector2Array()
	var steps := 16
	for i in steps + 1:
		var t := float(i) / steps
		var droop := 0.0
		if (wilted or dead) and t > 0.6:
			droop = (t - 0.6) * 18.0 * u
		pts.append(soil + Vector2(_stem_offset(t, height, u) + droop, -height * t + droop * 0.4))
	var col := Color("3f8a3a")
	if kind == "ngoc":
		col = Color("3fbf9f")
	var width := 2.2 * u
	draw_polyline(pts, _c(col), width, true)
	if kind == "gai":
		for i in range(3, steps, 3):
			var p := pts[i]
			var side := -1.0 if i % 2 == 0 else 1.0
			draw_line(p, p + Vector2(side * 3.5 * u, -2 * u), _c(col.darkened(0.2)), 1.4 * u)
	elif kind == "ngoc":
		for i in range(2, steps, 4):
			draw_circle(pts[i], 1.8 * u, _c(Color("9ff0d8")))
	return pts[pts.size() - 1]


# ---------------- Lá ----------------

func _draw_leaf_shape(kind: String, at: Vector2, ang: float, length: float, col: Color) -> void:
	var c := _c(col)
	match kind:
		"tron":
			_ellipse(at + Vector2.from_angle(ang) * length * 0.55, length * 0.55, length * 0.4, ang, c)
		"nhon", "bac":
			_lens(at, ang, length, length * 0.32, c)
		"rangcua":
			var pts := PackedVector2Array([at])
			var n := 6
			for i in range(1, n + 1):
				var t := float(i) / n
				var wid := sin(t * PI) * length * 0.32 * (1.25 if i % 2 == 0 else 0.8)
				pts.append(at + Vector2(t * length, -wid).rotated(ang))
			for i in range(n - 1, 0, -1):
				var t := float(i) / n
				var wid := sin(t * PI) * length * 0.32 * (1.25 if i % 2 == 0 else 0.8)
				pts.append(at + Vector2(t * length, wid).rotated(ang))
			draw_colored_polygon(pts, c)
		"kim":
			for k in [-0.35, 0.0, 0.35]:
				draw_line(at, at + Vector2.from_angle(ang + k) * length, c, max(1.0, length * 0.08))
		"tim":
			var pts := PackedVector2Array()
			for i in 24:
				var t := TAU * i / 24.0
				var x := 16.0 * pow(sin(t), 3)
				var y := 13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t)
				# hình trái tim, đỉnh nhọn hướng ra ngoài thân
				pts.append(at + (Vector2(-y + 13.0, x) * (length / 30.0)).rotated(ang))
			draw_colored_polygon(pts, c)
		_:
			_lens(at, ang, length, length * 0.3, c)


func _lens(at: Vector2, ang: float, length: float, width: float, c: Color) -> void:
	var pts := PackedVector2Array()
	var n := 10
	for i in n + 1:
		var t := float(i) / n
		pts.append(at + Vector2(t * length, -sin(t * PI) * width).rotated(ang))
	for i in range(n - 1, 0, -1):
		var t := float(i) / n
		pts.append(at + Vector2(t * length, sin(t * PI) * width).rotated(ang))
	draw_colored_polygon(pts, c)


func _ellipse(center: Vector2, rx: float, ry: float, ang: float, c: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var t := TAU * i / 20.0
		pts.append(center + Vector2(cos(t) * rx, sin(t) * ry).rotated(ang))
	draw_colored_polygon(pts, c)


# ---------------- Hoa ----------------

func _draw_flower(kind: String, c: Vector2, r: float, u: float) -> void:
	match kind:
		"cuc":
			for i in 12:
				var a := TAU * i / 12.0
				_ellipse(c + Vector2.from_angle(a) * r * 0.55, r * 0.5, r * 0.14, a, _c(_flower_color(i)))
			draw_circle(c, r * 0.28, _c(Color("f2c230")))
		"hong":
			for layer in 3:
				var rr := r * (1.0 - layer * 0.28)
				for i in 5:
					var a := TAU * i / 5.0 + layer * 0.6
					draw_circle(c + Vector2.from_angle(a) * rr * 0.35, rr * 0.5, _c(_flower_color(i + layer * 5).darkened(layer * 0.12)))
		"tulip":
			var col := _flower_color(0)
			_ellipse(c + Vector2(-r * 0.32, 0), r * 0.38, r * 0.7, -0.25, _c(col.darkened(0.12)))
			_ellipse(c + Vector2(r * 0.32, 0), r * 0.38, r * 0.7, 0.25, _c(col.darkened(0.12)))
			_ellipse(c + Vector2(0, -r * 0.05), r * 0.4, r * 0.75, 0.0, _c(_flower_color(2)))
		"chuong":
			for k in [-1.0, 1.0]:
				var hang := c + Vector2(k * r * 0.55, r * 0.15)
				draw_line(c, hang, _c(Color("3f8a3a")), 1.5 * u)
				var col := _flower_color(int(k + 2))
				var pts := PackedVector2Array([
					hang + Vector2(-r * 0.18, 0), hang + Vector2(r * 0.18, 0),
					hang + Vector2(r * 0.42, r * 0.7), hang + Vector2(r * 0.25, r * 0.62),
					hang + Vector2(0, r * 0.75), hang + Vector2(-r * 0.25, r * 0.62),
					hang + Vector2(-r * 0.42, r * 0.7)])
				draw_colored_polygon(pts, _c(col))
		"sao":
			var pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2 + TAU * i / 10.0
				pts.append(c + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.42))
			draw_colored_polygon(pts, _c(_flower_color(0)))
			draw_circle(c, r * 0.18, _c(Color("fff3b0")))
		"lan":
			_ellipse(c + Vector2(0, -r * 0.45), r * 0.3, r * 0.5, 0.0, _c(_flower_color(0)))
			_ellipse(c + Vector2(-r * 0.5, -r * 0.1), r * 0.5, r * 0.22, -0.3, _c(_flower_color(1)))
			_ellipse(c + Vector2(r * 0.5, -r * 0.1), r * 0.5, r * 0.22, 0.3, _c(_flower_color(2)))
			_ellipse(c + Vector2(0, r * 0.35), r * 0.38, r * 0.3, 0.0, _c(_flower_color(3).lightened(0.35)))
			draw_circle(c, r * 0.12, _c(Color("f2c230")))
		"sen":
			for layer in 2:
				for i in 7:
					var a := -PI + PI * (i + 0.5 * layer) / 6.0
					_lens(c, a, r * (1.0 - layer * 0.35), r * 0.2, _c(_flower_color(i).lightened(layer * 0.2)))
			draw_circle(c, r * 0.16, _c(Color("e8d27a")))
		"rong":
			for i in 9:
				var a := -PI / 2 + (i - 4) * 0.32
				var length := r * (1.1 - absi(i - 4) * 0.1)
				var pts := PackedVector2Array([
					c + Vector2.from_angle(a - 0.18) * r * 0.25, c + Vector2.from_angle(a) * length,
					c + Vector2.from_angle(a + 0.18) * r * 0.25])
				draw_colored_polygon(pts, _c(_flower_color(i)))
			draw_circle(c, r * 0.3, _c(_flower_color(4).darkened(0.25)))
			draw_circle(c + Vector2(-r * 0.1, -r * 0.05), r * 0.06, _c(Color("fff3b0")))
			draw_circle(c + Vector2(r * 0.1, -r * 0.05), r * 0.06, _c(Color("fff3b0")))
		_:
			draw_circle(c, r * 0.6, _c(_flower_color(0)))
	if stage == 4 and not dead:
		# hạt sẵn sàng thu
		for i in 3:
			draw_circle(c + Vector2((i - 1) * r * 0.35, r * 0.9), r * 0.09, Color("6b4a24"))
