extends Control
## Nhà kính: tường gỗ có cửa sổ, sàn đá, 3 kệ gỗ. Các ô chậu (pot_slot) là con
## của node này và được xếp lên kệ mỗi khi kích thước thay đổi.

const ROWS := 3
const COLS := 5
const WALL := 0.16        # phần tường phía trên (tỉ lệ chiều cao)
const PLANK_H := 18.0

var slots: Array = []


func add_slot(slot: Control) -> void:
	slots.append(slot)
	add_child(slot)
	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func _shelf_area() -> Rect2:
	var top := size.y * WALL
	return Rect2(Vector2(28, top), Vector2(size.x - 56, size.y - top - 10))


func _row_height() -> float:
	return _shelf_area().size.y / ROWS


func _plank_y(r: int) -> float:
	var a := _shelf_area()
	return a.position.y + _row_height() * (r + 1) - PLANK_H - 6


func _layout() -> void:
	var a := _shelf_area()
	var cw := a.size.x / COLS
	var rh := _row_height()
	for i in slots.size():
		var r := i / COLS
		var c := i % COLS
		var s: Control = slots[i]
		s.position = Vector2(a.position.x + c * cw + 6, _plank_y(r) - rh + 22)
		s.size = Vector2(cw - 12, rh - 18)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var wall_h := h * WALL + 24
	# Sàn đá xếp chéo
	draw_rect(Rect2(0, 0, w, h), Color("8f9ea6"))
	var tile := 64.0
	var line := Color("7d8b93")
	var x := -h
	while x < w + h:
		draw_line(Vector2(x, wall_h), Vector2(x + (h - wall_h), h), line, 2.0)
		draw_line(Vector2(x, h), Vector2(x + (h - wall_h), wall_h), line, 2.0)
		x += tile
	# Tường gỗ
	draw_rect(Rect2(0, 0, w, wall_h), Color("7b5536"))
	var px := 0.0
	while px < w:
		draw_line(Vector2(px, 0), Vector2(px, wall_h), Color("6a472c"), 2.0)
		px += 46.0
	# Cửa sổ nhà kính
	var win_w := 150.0
	var gap := (w - 4 * win_w) / 5.0
	for i in 4:
		var wx := gap + i * (win_w + gap)
		var r := Rect2(wx, 10, win_w, wall_h - 26)
		draw_rect(r, Color("cfeaf0"))
		draw_rect(Rect2(wx, 10, win_w, (wall_h - 26) * 0.45), Color("e6f6f8"))
		draw_rect(r, Color("4f3420"), false, 5.0)
		draw_line(Vector2(wx + win_w / 2, 10), Vector2(wx + win_w / 2, 10 + r.size.y), Color("4f3420"), 4.0)
		draw_line(Vector2(wx, 10 + r.size.y / 2), Vector2(wx + win_w, 10 + r.size.y / 2), Color("4f3420"), 4.0)
	draw_rect(Rect2(0, wall_h - 10, w, 10), Color("5a3b23"))
	# Kệ gỗ
	var a := _shelf_area()
	for rr in ROWS:
		var y := _plank_y(rr)
		# chân kệ
		for lx in [a.position.x + 10, a.position.x + a.size.x / 2 - 6, a.position.x + a.size.x - 22]:
			draw_rect(Rect2(lx, y + PLANK_H, 12, _row_height() * 0.28), Color("6e4527"))
		# bóng đổ
		draw_rect(Rect2(a.position.x + 6, y + PLANK_H, a.size.x - 12, 10), Color(0, 0, 0, 0.18))
		# mặt kệ
		draw_rect(Rect2(a.position.x, y, a.size.x, PLANK_H), Color("b47d47"))
		draw_rect(Rect2(a.position.x, y, a.size.x, 5), Color("d29e66"))
		draw_rect(Rect2(a.position.x, y + PLANK_H - 4, a.size.x, 4), Color("8a5a30"))
		# đế lót dưới mỗi chậu
		var cw := a.size.x / COLS
		for c in COLS:
			var cx := a.position.x + cw * (c + 0.5)
			_ellipse(Vector2(cx, y + 4), cw * 0.36, 7.0, Color("9fb4c2"))
			_ellipse(Vector2(cx, y + 3), cw * 0.33, 5.0, Color("c3d4de"))


func _ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		pts.append(center + Vector2(cos(t) * rx, sin(t) * ry))
	draw_colored_polygon(pts, col)
