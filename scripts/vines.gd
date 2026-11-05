extends Control
## Dây leo trang trí quấn quanh khung bảng bên trái (chỉ để trang trí, không bắt chạm).

var paths: Array = []   # mỗi dây: mảng điểm (tọa độ trong control)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_build()


func _build() -> void:
	paths.clear()
	var w := size.x
	var h := size.y
	# dây chạy dọc mép phải từ trên xuống
	var a := []
	for i in 61:
		var t := i / 60.0
		a.append(Vector2(w - 4 + sin(t * 22.0) * 7.0, t * h))
	paths.append(a)
	# dây ngắn vắt qua góc trên trái
	var b := []
	for i in 21:
		var t := i / 20.0
		b.append(Vector2(t * 120.0, 6 + sin(t * 9.0) * 6.0 + t * t * 30.0))
	paths.append(b)
	queue_redraw()


func _draw() -> void:
	for path in paths:
		var pts := PackedVector2Array(path)
		draw_polyline(pts, Color("1e3d14"), 6.0, true)
		draw_polyline(pts, Color("3f7a2a"), 3.6, true)
		draw_polyline(pts, Color("6fae4a"), 1.2, true)
		for i in range(2, pts.size() - 1, 3):
			var dir := (pts[i + 1] - pts[i - 1]).normalized()
			var side := 1.0 if i % 2 == 0 else -1.0
			var nrm := Vector2(-dir.y, dir.x) * side
			_leaf(pts[i] + nrm * 3.0, nrm.rotated(-0.5 * side), 11.0 + (i % 3) * 3.0)


func _leaf(base: Vector2, dir: Vector2, length: float) -> void:
	var tip := base + dir * length
	var nrm := Vector2(-dir.y, dir.x) * length * 0.38
	var mid := base + dir * length * 0.5
	var pts := PackedVector2Array()
	for i in 9:
		var t := i / 8.0
		pts.append(base.lerp(tip, t) + nrm * sin(t * PI))
	for i in range(7, 0, -1):
		var t := i / 8.0
		pts.append(base.lerp(tip, t) - nrm * sin(t * PI))
	var outline := PackedVector2Array()
	for p in pts:
		outline.append(mid + (p - mid) * 1.18)
	draw_colored_polygon(outline, Color("1e3d14"))
	draw_colored_polygon(pts, Color("4f9a3a"))
	draw_line(base, tip, Color("2f6a22"), 1.2)
