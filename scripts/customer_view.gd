extends Control
## Nhân vật pixel art (khách hoặc người bán). Hình nằm trong art/nguoi/<id>.png,
## mỗi tệp gồm 7 khung 32 x 64: 0 bình thường, 1 vui, 2 buồn, 3-6 bước đi.
## Tạo lại hình bằng tools/tao_nhan_vat.py.
## - walking = true: chạy khung bước đi theo pha bob.
## - facing: 1 hoặc -1 (lật hình khi đi sang trái).
## - mood: -1 buồn, 0 phân vân, 1 vui.

const Data := preload("res://scripts/data.gd")

const FRAME := Vector2(32, 64)
const BUBBLE_TOP := 62.0   # bong bóng lời nói không vượt lên trên mức này (dưới thanh trên của shop)
const HD_SCALE := 8.0      # chân dung độ phân giải cao: art/nguoi_hd/<id>.png (3 khung nét mặt)
const PORTRAIT_SHADER := preload("res://scripts/portrait3d.gdshader")
## Nhân vật dành cho từng loại khách (trẻ em chỉ là người qua đường).
const VARIANTS := {
	"qua_duong": ["khach_xanh", "khach_den", "khach_raglan", "khach_vang", "be_trai", "be_gai"],
	"tang_qua": ["khach_hong", "khach_do", "khach_tim", "khach_xanh"],
	"tiet_kiem": ["khach_vang", "khach_den", "khach_do", "khach_raglan"],
	"suu_tam": ["khach_tim", "khach_xanh", "khach_hong", "khach_den"],
	"nguoi_ban": ["ban_hang"],
	"cong_tu": ["cong_tu"],     # khách ẩn
	"ve_si": ["ve_si"],
	"bao_ke": ["dan_anh"],
}
static var _tex := {}

var type := "qua_duong"
var mood := 0
var bubble := ""        # lời nói ngắn hiện trên đầu
var bob := 0.0          # pha bước chân
var walking := false
var facing := 1.0
var variant := "khach_xanh"
var hd := false         # true: vẽ chân dung mượt có ánh sáng khối (màn hình trò chuyện ở quầy)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## p_variant: dùng đúng nhân vật này (để khách ở quầy giống khách đang đi trong shop).
func setup(p_type: String, p_mood: int, p_variant := "") -> void:
	type = p_type
	mood = p_mood
	if p_variant != "":
		variant = p_variant
	else:
		var list: Array = VARIANTS.get(type, VARIANTS["qua_duong"])
		variant = list.pick_random()
	queue_redraw()


func set_hd(on: bool) -> void:
	hd = on
	if on and _real(variant, mood) != null:
		# có chân dung thật (ảnh vẽ chi tiết): vẽ mượt, không cần ánh sáng khối
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		material = null
	elif on:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var mat := ShaderMaterial.new()
		mat.shader = PORTRAIT_SHADER
		material = mat
	else:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		material = null
	queue_redraw()


func set_mood(p_mood: int) -> void:
	mood = p_mood
	queue_redraw()


static func _sheet(id: String) -> Texture2D:
	if not _tex.has(id):
		var path := "res://art/nguoi/%s.png" % id
		_tex[id] = load(path) if ResourceLoader.exists(path) else null
	return _tex[id]


## Chân dung thật: art/khach_that/<mã>.png, có thể thêm <mã>_vui.png / <mã>_buon.png theo nét mặt.
static func _real(id: String, p_mood: int) -> Texture2D:
	var names := [id]
	if p_mood > 0:
		names.push_front(id + "_vui")
	elif p_mood < 0:
		names.push_front(id + "_buon")
	for n in names:
		var key: String = "that:" + n
		if not _tex.has(key):
			var path := "res://art/khach_that/%s.png" % n
			_tex[key] = load(path) if ResourceLoader.exists(path) else null
		if _tex[key] != null:
			return _tex[key]
	return null


static func _hd_sheet(id: String) -> Texture2D:
	var key := "hd:" + id
	if not _tex.has(key):
		var path := "res://art/nguoi_hd/%s.png" % id
		_tex[key] = load(path) if ResourceLoader.exists(path) else null
	return _tex[key]


func _frame_index() -> int:
	if walking:
		return 3 + int(floor(bob / (PI / 2.0))) % 4
	if mood > 0:
		return 1
	if mood < 0:
		return 2
	return 0


func _draw() -> void:
	if hd and not walking:
		var real := _real(variant, mood)
		if real != null:
			_draw_real(real)
			return
	var use_hd := hd and not walking and _hd_sheet(variant) != null
	var tex := _hd_sheet(variant) if use_hd else _sheet(variant)
	if tex == null:
		return
	# phóng to theo số nguyên để giữ nét pixel (chân dung mượt thì không cần)
	var sc: float = min(size.x / FRAME.x, size.y / FRAME.y)
	if sc >= 2.0 and not use_hd:
		sc = floor(sc)
	var dsz := FRAME * sc
	var origin := Vector2((size.x - dsz.x) / 2.0, size.y - dsz.y)
	# bóng dưới chân
	var sh := PackedVector2Array()
	for i in 16:
		var t := TAU * i / 16.0
		sh.append(Vector2(size.x / 2.0 + cos(t) * 11 * sc, size.y - 2 * sc + sin(t) * 2.5 * sc))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.22))
	if facing < 0:
		draw_set_transform(Vector2(size.x, 0), 0.0, Vector2(-1, 1))
	var src := Rect2(Vector2(_frame_index() * FRAME.x, 0), FRAME)
	if use_hd:
		src = Rect2(Vector2(_frame_index() * FRAME.x * HD_SCALE, 0), FRAME * HD_SCALE)
	draw_texture_rect_region(tex, Rect2(origin, dsz), src)
	# đồ cầm theo loại khách
	var px := func(x: float, y: float) -> Vector2: return origin + Vector2(x, y) * sc
	match type:
		"tang_qua":  # hộp quà trên tay
			var hand_y := 38.0 + (-2.0 if walking and _frame_index() == 3 else 0.0)
			draw_rect(Rect2(px.call(23, hand_y - 3), Vector2(7, 6) * sc), Color("e2453c"))
			draw_rect(Rect2(px.call(26, hand_y - 3), Vector2(1, 6) * sc), Color("f6d55c"))
			draw_rect(Rect2(px.call(23, hand_y - 1), Vector2(7, 1) * sc), Color("f6d55c"))
		"suu_tam":  # kính
			var ey := 13.0 - (1.0 if walking and _frame_index() in [4, 6] else 0.0)
			draw_rect(Rect2(px.call(11, ey - 1), Vector2(4, 4) * sc), Color("2a2a2a"), false, maxf(1.0, sc * 0.7))
			draw_rect(Rect2(px.call(17, ey - 1), Vector2(4, 4) * sc), Color("2a2a2a"), false, maxf(1.0, sc * 0.7))
			draw_rect(Rect2(px.call(15, ey), Vector2(2, 0.6) * sc), Color("2a2a2a"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if bubble != "":
		var font := get_theme_default_font()
		var fs := 15
		var tw := font.get_string_size(bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var cx := size.x / 2.0
		var r := Rect2(cx - tw / 2 - 8, origin.y - 34, tw + 16, 26)
		# đứng sát mép trên (gần cổng): hạ bong bóng xuống để thanh trên không che
		var top_limit := BUBBLE_TOP - global_position.y
		var lowered := r.position.y < top_limit
		if lowered:
			r.position.y = top_limit
		draw_rect(r, Color(1, 1, 1, 0.95))
		draw_rect(r, Color(0.3, 0.3, 0.3, 0.6), false, 1.5)
		if not lowered:
			var tip := PackedVector2Array([Vector2(cx - 5, r.end.y), Vector2(cx + 5, r.end.y), Vector2(cx, r.end.y + 7)])
			draw_colored_polygon(tip, Color(1, 1, 1, 0.95))
		draw_string(font, Vector2(r.position.x + 8, r.position.y + 19), bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("3a2614"))


## Vẽ chân dung thật vừa khung, đứng sát đáy, có bóng dưới chân.
func _draw_real(tex: Texture2D) -> void:
	var ts := tex.get_size()
	var sc: float = minf(size.x / ts.x, size.y / ts.y)
	if variant.begins_with("be_"):   # trẻ em đứng thấp hơn người lớn
		sc *= 0.8
	var dsz := ts * sc
	var origin := Vector2((size.x - dsz.x) / 2.0, size.y - dsz.y)
	var sh := PackedVector2Array()
	for i in 20:
		var t := TAU * i / 20.0
		sh.append(Vector2(size.x / 2.0 + cos(t) * dsz.x * 0.36, size.y - 4 + sin(t) * 7))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.18))
	if facing < 0:
		draw_set_transform(Vector2(size.x, 0), 0.0, Vector2(-1, 1))
	draw_texture_rect(tex, Rect2(origin, dsz), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
