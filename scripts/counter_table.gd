extends Control
## Bàn gỗ nhỏ đặt chậu cây trong khung trò chuyện ở quầy.

func _draw() -> void:
	var w := size.x
	var h := size.y
	var top := Color("a8703f")
	var front := Color("8a5a30")
	var dark := Color("5e3a1c")
	# chân bàn
	for x in [14.0, w - 30.0]:
		draw_rect(Rect2(x, 26, 16, h - 26), front)
		draw_rect(Rect2(x + 11, 26, 5, h - 26), dark)
	# mặt bàn (nhìn hơi từ trên xuống)
	draw_colored_polygon(PackedVector2Array([Vector2(8, 10), Vector2(w - 8, 10), Vector2(w, 22), Vector2(0, 22)]), top.lightened(0.12))
	draw_rect(Rect2(0, 22, w, 12), front)
	draw_rect(Rect2(0, 33, w, 3), dark)
	# vân gỗ
	for i in 4:
		var y := 13.0 + i * 2.5
		draw_line(Vector2(20 + i * 30, y), Vector2(70 + i * 40, y), top.darkened(0.12), 1.0)
	draw_line(Vector2(0, 22), Vector2(w, 22), top.lightened(0.3), 1.5)
