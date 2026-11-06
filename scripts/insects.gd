extends Control
## Côn trùng hỏi đáp trong nhà kính. Khoảng mỗi phút một con bay từ trên xuống, lượn quanh kệ cây;
## chạm vào thì phát tín hiệu insect_tapped(loại, cấp độ). Không ai chạm thì một lúc sau bay đi.
##   "buom": bướm (vàng / tím / đỏ)       -> từ vựng tiếng Anh
##   "chuon": chuồn chuồn (xanh lá / xanh dương / cam đỏ) -> toán
##   "ong": ong                          -> đời sống xã hội
## Cấp độ 0, 1, 2 chỉ thể hiện qua màu, không ghi cho người chơi.

signal insect_tapped(kind: String, level: int)

const SPAWN_MIN := 50.0
const SPAWN_MAX := 70.0
const LIFETIME := 35.0
const SIZE := Vector2(84, 84)        # vùng chạm (đủ lớn cho ngón tay)

var paused_check := Callable()       # trả về true khi đang có bảng bật lên / đang ở Shop cây
var spawn_timer := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	spawn_timer = randf_range(SPAWN_MIN, SPAWN_MAX)


func _paused() -> bool:
	return paused_check.is_valid() and paused_check.call()


func _process(delta: float) -> void:
	if _paused():
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = randf_range(SPAWN_MIN, SPAWN_MAX)
		if get_child_count() == 0:
			spawn()


## Thả một con côn trùng ngẫu nhiên (hoặc chỉ định loại / cấp độ).
func spawn(kind := "", level := -1) -> Control:
	if kind == "":
		var r := randf()
		kind = "buom" if r < 0.4 else ("chuon" if r < 0.75 else "ong")
	if level < 0:
		var r2 := randf()
		level = 0 if r2 < 0.45 else (1 if r2 < 0.8 else 2)
	if kind == "ong":
		level = 0
	var b := Bug.new()
	b.kind = kind
	b.level = level
	b.layer = self
	b.size = SIZE
	b.position = Vector2(randf_range(0.2, 0.8) * size.x, -SIZE.y) - SIZE / 2.0
	add_child(b)
	b.pick_target()
	return b


func clear() -> void:
	for c in get_children():
		c.queue_free()


class Bug extends Control:
	var kind := "buom"
	var level := 0
	var layer: Control
	var age := 0.0
	var leaving := false
	var target := Vector2.ZERO
	var vel := Vector2.ZERO
	var flap := 0.0
	var facing := 1.0
	var preview := false     # chỉ để vẽ trong bảng câu hỏi, không bay

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE if preview else Control.MOUSE_FILTER_STOP
		flap = randf() * TAU

	func center() -> Vector2:
		return position + size / 2.0

	func pick_target() -> void:
		var r: Vector2 = layer.size
		target = Vector2(randf_range(0.1, 0.9) * r.x, randf_range(0.12, 0.85) * r.y)

	func _process(delta: float) -> void:
		flap += delta * (26.0 if kind != "buom" else 14.0)
		queue_redraw()
		if preview:
			return
		var paused: bool = layer._paused()
		if paused:
			return
		age += delta
		if age > layer.LIFETIME and not leaving:
			leaving = true
			target = Vector2(center().x + randf_range(-100, 100), -120)
		var c := center()
		var to := target - c
		if to.length() < 24.0 and not leaving:
			pick_target()
		var speed := 140.0 if kind == "chuon" else (90.0 if kind == "buom" else 110.0)
		if leaving:
			speed *= 1.6
		var want := to.normalized() * speed
		# đường bay lượn lờ: bướm chao lên xuống, chuồn chuồn lao nhanh rồi dừng
		if kind == "buom":
			want += Vector2(0, sin(age * 3.0) * 40.0)
		elif kind == "chuon":
			want *= 0.4 + 0.9 * absf(sin(age * 1.7))
		else:
			want += Vector2(cos(age * 9.0), sin(age * 11.0)) * 30.0
		vel = vel.lerp(want, clampf(delta * 2.5, 0.0, 1.0))
		position += vel * delta
		if absf(vel.x) > 8.0:
			facing = signf(vel.x)
		if leaving and center().y < -80.0:
			queue_free()

	func _gui_input(event: InputEvent) -> void:
		var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
			or (event is InputEventScreenTouch and event.pressed)
		if pressed and not leaving:
			accept_event()
			layer.insect_tapped.emit(kind, level)
			queue_free()

	func _draw() -> void:
		var c := size / 2.0
		var sc := minf(size.x, size.y) / 84.0 * (1.0 if preview else 1.35)
		draw_set_transform(c, 0.0, Vector2(facing, 1.0) * sc)
		match kind:
			"buom": _butterfly()
			"chuon": _dragonfly()
			_: _bee()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _butterfly() -> void:
		var cols := [[Color("ffd23f"), Color("e8a317")], [Color("b07ce8"), Color("7a4fc0")], [Color("ee4b4b"), Color("b3242c")]]
		var main: Color = cols[level][0]
		var edge: Color = cols[level][1]
		var w := 0.5 + 0.5 * absf(sin(flap))      # cánh khép mở
		for side in [-1.0, 1.0]:
			var up := PackedVector2Array()
			var lo := PackedVector2Array()
			for i in 14:
				var t := TAU * i / 14.0
				up.append(Vector2(side * (12 + cos(t) * 12) * w, -8 + sin(t) * 11))
				lo.append(Vector2(side * (8 + cos(t) * 8) * w, 9 + sin(t) * 8))
			draw_colored_polygon(up, edge)
			draw_colored_polygon(lo, edge)
			var up2 := PackedVector2Array()
			for p in up:
				up2.append(p * 0.78 + Vector2(side * 2 * w, -1))
			draw_colored_polygon(up2, main)
			var lo2 := PackedVector2Array()
			for p in lo:
				lo2.append(p * 0.72 + Vector2(side * 1.5 * w, 2))
			draw_colored_polygon(lo2, main)
			draw_circle(Vector2(side * 14 * w, -10), 3.0, Color(1, 1, 1, 0.85))
			draw_circle(Vector2(side * 14 * w, -10), 1.5, Color(0.15, 0.1, 0.1))
		draw_line(Vector2(0, -12), Vector2(0, 14), Color("3a2a22"), 4.0)
		draw_circle(Vector2(0, -13), 3.2, Color("3a2a22"))
		draw_line(Vector2(0, -15), Vector2(-5, -24), Color("3a2a22"), 1.3)
		draw_line(Vector2(0, -15), Vector2(5, -24), Color("3a2a22"), 1.3)
		draw_circle(Vector2(-5, -24), 1.6, Color("3a2a22"))
		draw_circle(Vector2(5, -24), 1.6, Color("3a2a22"))

	func _dragonfly() -> void:
		var cols := [Color("4caf50"), Color("2f7fd8"), Color("e8572a")]
		var body: Color = cols[level]
		var wing := Color(0.85, 0.95, 1.0, 0.55)
		var wing_edge := Color(0.5, 0.65, 0.8, 0.8)
		var tilt := sin(flap) * 0.35
		for side in [-1.0, 1.0]:
			for k in 2:
				var base := Vector2(-4 + k * 7, -2)
				var ang: float = side * (PI / 2.0 + (0.25 if k == 0 else -0.25)) + tilt * side
				var dir := Vector2.from_angle(ang)
				var pts := PackedVector2Array()
				for i in 12:
					var t := TAU * i / 12.0
					var along := (cos(t) + 1.0) * 13.0
					pts.append(base + dir * along + dir.orthogonal() * sin(t) * 3.6)
				draw_colored_polygon(pts, wing)
				pts.append(pts[0])
				draw_polyline(pts, wing_edge, 1.0)
		# thân dài
		draw_line(Vector2(-6, 0), Vector2(-30, 0), body.darkened(0.2), 4.0)
		for i in 5:
			draw_line(Vector2(-10 - i * 4.5, -2), Vector2(-10 - i * 4.5, 2), body.darkened(0.45), 1.0)
		draw_circle(Vector2(0, 0), 5.0, body)
		draw_circle(Vector2(8, 0), 5.2, body.lightened(0.15))
		draw_circle(Vector2(10, -3), 2.6, Color("1e2a30"))
		draw_circle(Vector2(10, 3), 2.6, Color("1e2a30"))
		draw_circle(Vector2(10.6, -3.6), 0.9, Color(1, 1, 1, 0.9))

	func _bee() -> void:
		var wing := Color(0.9, 0.97, 1.0, 0.7)
		var up := absf(sin(flap))
		for side in [-1.0, 1.0]:
			var pts := PackedVector2Array()
			for i in 12:
				var t := TAU * i / 12.0
				pts.append(Vector2(-2 + cos(t) * 7, -10 - up * 6 + sin(t) * 10).rotated(side * 0.35) + Vector2(side * 4, 0))
			draw_colored_polygon(pts, wing)
		var pts2 := PackedVector2Array()
		for i in 18:
			var t := TAU * i / 18.0
			pts2.append(Vector2(cos(t) * 15, sin(t) * 10))
		draw_colored_polygon(pts2, Color("f6c22a"))
		for x in [-6.0, 1.0, 8.0]:
			var stripe := PackedVector2Array()
			for i in 8:
				var t := -PI / 2.0 + PI * i / 7.0
				stripe.append(Vector2(x + 2.2, sin(t) * 9.5 * sqrt(maxf(0.0, 1.0 - pow((x + 2.0) / 15.0, 2)))))
			for i in 8:
				var t := PI / 2.0 - PI * i / 7.0
				stripe.append(Vector2(x - 1.0, sin(t) * 9.5 * sqrt(maxf(0.0, 1.0 - pow((x - 1.0) / 15.0, 2)))))
			draw_colored_polygon(stripe, Color("2a2018"))
		draw_line(Vector2(-15, 0), Vector2(-20, 0), Color("2a2018"), 2.0)
		draw_circle(Vector2(14, -1), 6.0, Color("2a2018"))
		draw_circle(Vector2(16, -3), 1.6, Color(1, 1, 1, 0.9))
		draw_line(Vector2(16, -6), Vector2(20, -13), Color("2a2018"), 1.2)
