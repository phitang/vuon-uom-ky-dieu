extends Control
## Một chỗ đặt chậu trên kệ. Chạm vào để chọn cây / gieo hạt.

const PlantView := preload("res://scripts/plant_view.gd")

signal tapped(slot_index: int)

var slot_index := 0
var selected := false
var pollen_target := false
var drop_target := false   # đang kéo hạt và chậu này nhận được
var badge := ""      # "nuoc", "hoa", "hat", "qua" (hạt lai chờ thu), "chet", "dat", "shop" hoặc ""
var badge_count := 0 # số hạt lai chờ thu (badge "qua")
var locked := false  # chỗ chưa có chậu
var show_buy_hint := false
var pv: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	pv = Control.new()
	pv.set_script(PlantView)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pv.offset_bottom = -2
	add_child(pv)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit(slot_index)
		accept_event()


func refresh() -> void:
	pv.visible = not locked
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if selected:
		_glow(Vector2(w / 2, h - 10), w * 0.46, 22.0, Color(1, 1, 0.85, 0.75))
	elif pollen_target:
		_glow(Vector2(w / 2, h - 10), w * 0.46, 22.0, Color(1.0, 0.85, 0.2, 0.6))
	elif drop_target:
		_glow(Vector2(w / 2, h - 10), w * 0.46, 22.0, Color(0.55, 1.0, 0.45, 0.65))
	if locked and show_buy_hint:
		var font := get_theme_default_font()
		var text := "+ Mua chậu"
		var fs := 18
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_rect(Rect2(w / 2 - tw / 2 - 10, h - 46, tw + 20, 32), Color(0, 0, 0, 0.25))
		draw_string(font, Vector2(w / 2 - tw / 2, h - 24), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	if badge != "":
		# đặt huy hiệu cạnh miệng chậu
		var art_w := (h - 2.0) * 300.0 / 542.0
		_draw_badge(Vector2(w / 2.0 + art_w * 0.45, h - (h - 2.0) * 0.42))


func _glow(c: Vector2, rx: float, ry: float, col: Color) -> void:
	for k in 4:
		var f := 1.0 - k * 0.2
		var pts := PackedVector2Array()
		for i in 28:
			var t := TAU * i / 28.0
			pts.append(c + Vector2(cos(t) * rx * f, sin(t) * ry * f))
		draw_colored_polygon(pts, Color(col.r, col.g, col.b, col.a * 0.3))


func _draw_badge(c: Vector2) -> void:
	var bg := {"qua": Color("e09a20"), "nuoc": Color("2f7fd0"), "hoa": Color("d0509a"), "hat": Color("8a5a2b"), "chet": Color("7a7a7a"), "dat": Color("b0602a"), "shop": Color("d9822b")}.get(badge, Color.GRAY) as Color
	draw_circle(c, 15, Color(1, 1, 1, 0.9))
	draw_circle(c, 13, bg)
	match badge:
		"nuoc":  # giọt nước
			var pts := PackedVector2Array([c + Vector2(0, -8)])
			for i in 9:
				var t := PI * i / 8.0
				pts.append(c + Vector2(cos(t) * 5.5, 2 + sin(t) * 5.5))
			draw_colored_polygon(pts, Color.WHITE)
		"hoa":
			for i in 5:
				draw_circle(c + Vector2.from_angle(TAU * i / 5.0 - PI / 2) * 5, 3.6, Color.WHITE)
			draw_circle(c, 3, Color("f6d55c"))
		"qua":  # hạt lai đã kết: hạt + số lượng
			var sp := PackedVector2Array()
			for i in 16:
				var t := TAU * i / 16.0
				sp.append(c + Vector2(cos(t) * 4.5, sin(t) * 6.5).rotated(0.5) + Vector2(-2, 0))
			draw_colored_polygon(sp, Color("7a3f1e"))
			draw_arc(c + Vector2(-1, -1), 3, -0.6, 1.0, 6, Color("d9965a"), 1.5)
			var bc := c + Vector2(10, -10)
			draw_circle(bc, 8, Color.WHITE)
			draw_circle(bc, 6.5, Color("c0392b"))
			var font := get_theme_default_font()
			var tx := str(badge_count)
			draw_string(font, bc + Vector2(-font.get_string_size(tx, 0, -1, 12).x / 2.0, 4.5), tx, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		"hat":
			for i in 3:
				draw_circle(c + Vector2((i - 1) * 6, 0), 3.2, Color("f3e3c0"))
		"shop":  # đang trưng bày: mái hiên cửa hàng
			for k in 4:
				var col := Color.WHITE if k % 2 == 0 else Color("ffe08a")
				draw_rect(Rect2(c + Vector2(-8 + k * 4, -7), Vector2(4, 6)), col)
			draw_rect(Rect2(c + Vector2(-7, -1), Vector2(14, 8)), Color.WHITE)
			draw_rect(Rect2(c + Vector2(-2, 2), Vector2(4, 5)), Color("d9822b"))
		"dat":  # cần cho đất
			var mound := PackedVector2Array()
			for i in 9:
				var t := PI + PI * i / 8.0
				mound.append(c + Vector2(cos(t) * 8, 4 + sin(t) * 7))
			draw_colored_polygon(mound, Color("f3e3c0"))
		"chet":
			draw_line(c + Vector2(-5, -5), c + Vector2(5, 5), Color.WHITE, 3)
			draw_line(c + Vector2(5, -5), c + Vector2(-5, 5), Color.WHITE, 3)
