extends Control
## Shop cây cảnh: sân lát đá, nhà kính ở giữa (chạm vào để về vườn), các gốc cây
## trưng bày quanh sân, quầy thu ngân có người bán và cổng vào. Khách vào xem cây;
## ai đứng ở quầy thì mở giao diện trò chuyện mua cây (do main.gd vẽ).

const Data := preload("res://scripts/data.gd")
const Gen := preload("res://scripts/genetics.gd")
const PlantView := preload("res://scripts/plant_view.gd")
const CustomerView := preload("res://scripts/customer_view.gd")
const Art := preload("res://scripts/shop_decor_art.gd")

signal back_pressed
signal chat_requested(customer: Dictionary)
signal stand_tapped(pot_index: int)
signal decor_pressed          # nút "Trang trí" góc trên bên phải
signal rename_pressed         # chạm vào bảng hiệu ở cổng
signal special_requested(customer: Dictionary)   # khách ẩn (công tử / bảo kê) tới quầy

const TOP_H := 56.0
const BOTTOM_H := 64.0
const CUST_SIZE := Vector2(64, 128)
const HOUSE_SIZE := Vector2(300, 196)

var gs: Node
var paused_check: Callable = Callable()   # trả về true khi đang có bảng bật lên

var stands: Array = []        # mỗi gốc: {pot, pos, sold (giá hoặc -1), pv, tag}
var customers: Array = []     # mỗi khách: {node, cust, state, path, goal, timer, visits, seen, choice, stand}
var counter_busy := false
var counter_claim = null      # khách đang đi tới quầy (giữ chỗ)
var spawn_timer := 2.0
var anim := 0.0

var title_l: Label
var cash_l: Label
var status_l: Label
var layer: Control            # chứa gốc cây và khách, sắp theo chiều sâu
var house: Control            # nhà kính giữa sân
var desk_front: Control       # mặt trước quầy (che nửa dưới người bán)
var keeper: Control           # người bán
var keeper_target := 0.0
var keeper_wait := 0.0
var sign_rect := Rect2()      # vùng bảng hiệu để bắt chạm

# Khách ẩn. event: "" | "vip" (công tử ăn chơi) | "bao_ke" (đàn anh đòi tiền bảo kê)
# Bước của công tử: "browse" khách thường xem 10 giây -> "clear" vệ sĩ đuổi khách
# -> "vip" công tử xem cây rồi ra quầy -> "leave" cả đoàn ra về.
var event := ""
var event_phase := ""
var event_kind := ""          # "quy" hoặc "huyen_thoai"
var event_timer := 0.0
var event_hint := false
var empty_time := 0.0         # số giây shop không còn cây nào để bán


func _ready() -> void:
	gs = get_node("/root/GameState")
	mouse_filter = Control.MOUSE_FILTER_STOP
	layer = Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	house = GreenhouseBuilding.new()
	house.size = HOUSE_SIZE
	house.tapped.connect(func(): back_pressed.emit())
	layer.add_child(house)
	keeper = Control.new()
	keeper.set_script(CustomerView)
	keeper.size = CUST_SIZE
	keeper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(keeper)
	keeper.setup("nguoi_ban", 1)
	desk_front = DeskFront.new()
	desk_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(desk_front)
	_build_bars()


func _build_bars() -> void:
	var top := PanelContainer.new()
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color(0.24, 0.16, 0.09, 0.92)
	tsb.border_color = Color("d9b26a")
	tsb.border_width_bottom = 3
	tsb.content_margin_left = 20
	tsb.content_margin_right = 20
	top.add_theme_stylebox_override("panel", tsb)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = TOP_H
	top.z_index = 2000
	add_child(top)
	var row := HBoxContainer.new()
	top.add_child(row)
	title_l = Label.new()
	title_l.text = "Shop cây cảnh"
	title_l.add_theme_font_size_override("font_size", 26)
	title_l.add_theme_color_override("font_color", Color("fff1cf"))
	title_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_l)
	cash_l = Label.new()
	cash_l.add_theme_font_size_override("font_size", 24)
	cash_l.add_theme_color_override("font_color", Color("ffe08a"))
	cash_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(cash_l)
	var deco := Button.new()
	deco.text = "Trang trí"
	deco.custom_minimum_size = Vector2(150, 44)
	deco.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	deco.pressed.connect(func(): decor_pressed.emit())
	row.add_child(deco)

	var bottom := PanelContainer.new()
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color("1f272e")
	bsb.content_margin_left = 14
	bsb.content_margin_right = 14
	bsb.content_margin_top = 8
	bsb.content_margin_bottom = 8
	bottom.add_theme_stylebox_override("panel", bsb)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -BOTTOM_H
	bottom.z_index = 2000
	add_child(bottom)
	var brow := HBoxContainer.new()
	bottom.add_child(brow)
	var back := Button.new()
	back.text = "Về vườn"
	back.custom_minimum_size = Vector2(200, 48)
	back.pressed.connect(func(): back_pressed.emit())
	brow.add_child(back)
	status_l = Label.new()
	status_l.add_theme_font_size_override("font_size", 20)
	status_l.add_theme_color_override("font_color", Color("f2ead8"))
	status_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	brow.add_child(status_l)


# =====================================================================
# Bố cục sân
# =====================================================================

func _center() -> Vector2:
	return Vector2(size.x * 0.53, TOP_H + (size.y - TOP_H - BOTTOM_H) * 0.56)


func _radii() -> Vector2:
	return Vector2(size.x * 0.37, (size.y - TOP_H - BOTTOM_H) * 0.40)


func _gate() -> Vector2:
	return Vector2(_center().x, _center().y - _radii().y - 18)


func _counter_desk() -> Rect2:
	return Rect2(Vector2(size.x * 0.04, TOP_H + 104), Vector2(170, 56))


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and house != null:
		_layout_props()


## Đặt nhà kính, quầy và người bán theo kích thước màn hình.
func _layout_props() -> void:
	var c := _center()
	house.position = c + Vector2(-HOUSE_SIZE.x / 2.0, 44 - HOUSE_SIZE.y)
	house.z_index = int(c.y + 44)
	var d := _counter_desk()
	desk_front.position = d.position
	desk_front.size = d.size
	desk_front.tier = gs.upgrade_tier("quay")
	desk_front.queue_redraw()
	desk_front.z_index = int(d.end.y)
	var feet_y := d.position.y + 48   # đứng sau quầy, lộ nửa người trên
	if keeper_target == 0.0:
		keeper_target = d.position.x + d.size.x * 0.45
		keeper.set_meta("x", keeper_target)
	var kx: float = keeper.get_meta("x", keeper_target)
	keeper.position = Vector2(kx - CUST_SIZE.x / 2.0, feet_y - CUST_SIZE.y)
	keeper.z_index = int(feet_y) - 10


## Người bán đi qua đi lại sau quầy; quay về phía khách khi có người ở quầy.
func _update_keeper(delta: float) -> void:
	var d := _counter_desk()
	var kx: float = keeper.get_meta("x", d.position.x + d.size.x * 0.45)
	if counter_busy or counter_claim != null:
		keeper_target = d.end.x - 30
	else:
		keeper_wait -= delta
		if keeper_wait <= 0.0:
			keeper_wait = randf_range(2.0, 5.0)
			keeper_target = randf_range(d.position.x + 30, d.end.x - 30)
	var dx := keeper_target - kx
	var step := 45.0 * delta
	if absf(dx) > 1.0:
		kx += clampf(dx, -step, step)
		keeper.walking = true
		keeper.facing = signf(dx)
		keeper.bob += delta * 9.0
	else:
		keeper.walking = false
		keeper.facing = 1.0
	keeper.set_meta("x", kx)
	keeper.mood = 1
	keeper.bubble = "Mời quý khách!" if counter_busy else ""
	_layout_props()
	keeper.queue_redraw()


## Chỗ khách đứng trước quầy.
func _counter_spot() -> Vector2:
	var d := _counter_desk()
	return Vector2(d.end.x + 34, d.end.y + 26)


func _queue_spot(n: int) -> Vector2:
	return _counter_spot() + Vector2(52 + 50 * n, 26 + 12 * n)


## Vị trí 12 gốc trưng bày (tính theo bán kính sân), xếp từ hàng trước ra sau.
const STAND_SPOTS := [
	Vector2(-0.2, 0.95), Vector2(0.2, 0.95), Vector2(-0.58, 0.78), Vector2(0.58, 0.78),
	Vector2(-0.92, 0.42), Vector2(0.92, 0.42), Vector2(-0.98, -0.32), Vector2(0.98, -0.32),
	Vector2(-0.62, -0.76), Vector2(0.62, -0.76), Vector2(-0.28, -0.92), Vector2(0.28, -0.92),
]


func _stand_pos(k: int) -> Vector2:
	var f: Vector2 = STAND_SPOTS[k % STAND_SPOTS.size()]
	return _center() + f * _radii()


# =====================================================================
# Mở / đóng shop
# =====================================================================

func open_shop() -> void:
	visible = true
	_clear_customers()
	for s in stands:
		s["pv"].queue_free()
		s["tag"].queue_free()
		s["btn"].queue_free()
	stands.clear()
	var pots: Array = gs.displayed_pots()
	for k in mini(pots.size(), Data.MAX_STANDS):
		_add_stand(k, pots[k])
	counter_busy = false
	spawn_timer = 1.5
	_layout_props()
	if stands.is_empty():
		set_status("Chưa có cây trưng bày. Chạm vào nhà kính để về vườn và chọn cây Trưng bày.")
	else:
		set_status("Khách sắp tới! Chạm cây để chỉnh giá, chạm nhà kính để về vườn.")
	refresh()


func close_shop() -> void:
	_clear_customers()
	visible = false


func _clear_customers() -> void:
	for c in customers:
		c["node"].queue_free()
	customers.clear()
	counter_busy = false
	counter_claim = null
	event = ""
	event_phase = ""
	empty_time = 0.0


func _add_stand(k: int, pot: int) -> void:
	var pos := _stand_pos(k)
	var pv := Control.new()
	pv.set_script(PlantView)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.size = Vector2(70, 126)
	pv.position = pos - Vector2(35, 126 + 10)
	pv.z_index = int(pos.y)
	layer.add_child(pv)
	var tag := Label.new()
	tag.add_theme_font_size_override("font_size", 15)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f7e7b8")
	sb.border_color = Color("8a5a2b")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	tag.add_theme_stylebox_override("normal", sb)
	tag.add_theme_color_override("font_color", Color("3a2614"))
	tag.z_index = int(pos.y) + 1
	layer.add_child(tag)
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	btn.position = pos - Vector2(40, 136)
	btn.size = Vector2(80, 150)
	btn.z_index = int(pos.y) + 2
	btn.pressed.connect(func(): _on_stand_pressed(k))
	layer.add_child(btn)
	stands.append({"pot": pot, "pos": pos, "sold": -1, "pv": pv, "tag": tag, "btn": btn})


func _on_stand_pressed(k: int) -> void:
	var s: Dictionary = stands[k]
	if s["sold"] >= 0:
		set_status("Cây này đã bán được %d xu." % s["sold"])
		return
	stand_tapped.emit(s["pot"])


## Vẽ lại cây và thẻ giá.
func refresh() -> void:
	cash_l.text = "%d xu" % gs.coins
	desk_front.tier = gs.upgrade_tier("quay")
	desk_front.queue_redraw()
	queue_redraw()
	for s in stands:
		var tag: Label = s["tag"]
		var pv: Control = s["pv"]
		if s["sold"] >= 0:
			pv.visible = false
			tag.text = "ĐÃ BÁN"
			tag.add_theme_color_override("font_color", Color("b8473a"))
		else:
			var p: Dictionary = gs.pots[s["pot"]]
			if p.is_empty():
				pv.visible = false
				tag.text = ""
				continue
			pv.visible = true
			pv.set_plant(p["gen"], gs.stage_of(p), p["chet"], p.get("heo", false))
			pv.set_soil(gs.soils[s["pot"]])
			tag.text = "%d xu" % gs.asking_price(p)
		tag.reset_size()
		tag.position = s["pos"] + Vector2(-tag.size.x / 2.0, 22)


func set_status(t: String) -> void:
	status_l.text = t


func _open_stands() -> Array:
	var out: Array = []
	for k in stands.size():
		if stands[k]["sold"] < 0 and not gs.pots[stands[k]["pot"]].is_empty():
			out.append(k)
	return out


# =====================================================================
# Khách
# =====================================================================

func _process(delta: float) -> void:
	if not visible:
		return
	anim += delta
	if _animated():
		queue_redraw()
	if paused_check.is_valid() and paused_check.call():
		return
	_update_keeper(delta)
	_update_events(delta)
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		# shop càng đẹp (sức hút cao) khách tới càng nhanh
		var speed := maxf(0.5, 1.0 - Data.APPEAL_SPAWN * gs.appeal())
		spawn_timer = randf_range(Data.SHOP_SPAWN_MIN, Data.SHOP_SPAWN_MAX) * speed
		var browsing := event == "vip" and event_phase == "browse"
		if browsing:
			spawn_timer = minf(spawn_timer, 1.6)   # công tử sắp tới: shop đông khách xem
		if (event == "" or browsing) and customers.size() < Data.MAX_SHOP_CUSTOMERS and not _open_stands().is_empty():
			_spawn_customer()
	for c in customers.duplicate():
		_update_customer(c, delta)


func _spawn_customer() -> void:
	var cust: Dictionary = gs.new_customer()
	var node := Control.new()
	node.set_script(CustomerView)
	node.size = CUST_SIZE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(node)
	node.setup(cust["type"], 0)
	var c := {"node": node, "cust": cust, "state": "walk", "path": [], "goal": "", "timer": 0.0,
		"visits": randi_range(2, 4), "seen": [], "choice": -1, "pos": _gate() + Vector2(0, -30), "role": ""}
	customers.append(c)
	_place(c)
	_go_next_stand(c)


func _place(c: Dictionary) -> void:
	var node: Control = c["node"]
	node.position = c["pos"] - Vector2(CUST_SIZE.x / 2.0, CUST_SIZE.y)
	node.z_index = int(c["pos"].y)


## Đường đi tránh nhà kính ở giữa sân.
func _route(from: Vector2, to: Vector2) -> Array:
	var c := _center() + Vector2(0, 14)
	var avoid := Vector2(HOUSE_SIZE.x / 2.0 + 34, 58)
	# đo khoảng cách gần nhất từ tâm tới đoạn thẳng (trong hệ elip đã chuẩn hóa)
	var a := (from - c) / avoid
	var b := (to - c) / avoid
	var ab := b - a
	var t := clampf(-a.dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	if (a + ab * t).length() >= 1.0:
		return [to]
	var ang_a := a.angle()
	var ang_b := b.angle()
	var diff := wrapf(ang_b - ang_a, -PI, PI)
	var mid := ang_a + diff / 2.0
	var way := c + Vector2(cos(mid), sin(mid)) * avoid * 1.25
	return [way, to]


func _walk_to(c: Dictionary, target: Vector2, goal: String) -> void:
	c["path"] = _route(c["pos"], target)
	c["goal"] = goal
	c["state"] = "walk"


func _go_next_stand(c: Dictionary) -> void:
	var options: Array = _open_stands().filter(func(k): return not c["seen"].has(k))
	if options.is_empty() or c["visits"] <= 0:
		_decide(c)
		return
	var k: int = options.pick_random()
	c["stand"] = k
	c["seen"].append(k)
	c["visits"] -= 1
	var side := -1.0 if randf() < 0.5 else 1.0
	_walk_to(c, stands[k]["pos"] + Vector2(side * randf_range(48, 58), 40), "stand")


func _update_customer(c: Dictionary, delta: float) -> void:
	var node: Control = c["node"]
	node.walking = c["state"] == "walk"
	match c["state"]:
		"walk":
			var path: Array = c["path"]
			if path.is_empty():
				_arrive(c)
				return
			var target: Vector2 = path[0]
			var d: Vector2 = target - c["pos"]
			var step: float = Data.SHOP_WALK_SPEED * c.get("speed", 1.0) * delta
			if absf(d.x) > 2.0:
				node.facing = signf(d.x)
			if d.length() <= step:
				c["pos"] = target
				path.pop_front()
			else:
				c["pos"] += d.normalized() * step
			node.bob += delta * 9.0
			_place(c)
			node.queue_redraw()
		"look":
			c["timer"] -= delta
			if c["timer"] <= 0.0:
				node.bubble = ""
				node.queue_redraw()
				_go_next_stand(c)
		"queue":
			if event == "" and not counter_busy and counter_claim == null:
				counter_claim = c
				_walk_to(c, _counter_spot(), "counter")
		"leave_wait":
			c["timer"] -= delta
			if c["timer"] <= 0.0:
				node.bubble = ""
				_walk_to(c, _gate() + Vector2(0, -40), "exit")
		"follow":   # vệ sĩ đi theo sau công tử
			c["timer"] -= delta
			if c["timer"] <= 0.0:
				node.bubble = ""
				_walk_to(c, _gate() + Vector2(c.get("side", 1.0) * 24, -40), "exit")


func _arrive(c: Dictionary) -> void:
	var node: Control = c["node"]
	match c["goal"]:
		"stand":
			c["state"] = "look"
			c["timer"] = randf_range(1.6, 3.0)
			var k: int = c.get("stand", -1)
			if k >= 0:
				node.facing = signf(stands[k]["pos"].x - c["pos"].x)
			if c["role"] == "vip":
				node.bubble = ["Hàng xịn đấy!", "Đẹp, đẹp lắm!", "Xứng tầm anh!"].pick_random()
				node.set_mood(1)
				c["timer"] = 1.8
				node.queue_redraw()
				return
			var liked := false
			if k >= 0 and stands[k]["sold"] < 0 and not gs.pots[stands[k]["pot"]].is_empty():
				liked = Gen.count_matches(gs.pots[stands[k]["pot"]]["gen"], c["cust"]["wish"]) > 0
			node.bubble = ["Đẹp quá!", "Thích ghê!", "Ồ, hay đấy"].pick_random() if liked else ["Hmm…", "Để xem…", "Cũng được"].pick_random()
			node.set_mood(1 if liked else 0)
		"counter":
			if counter_claim == c:
				counter_claim = null
			if counter_busy:
				c["state"] = "queue"
				return
			if c["role"] in ["vip", "bao_ke"]:
				counter_busy = true
				node.facing = -1.0
				c["state"] = "chat"
				node.bubble = "Gói hết cho anh!" if c["role"] == "vip" else "Chủ quán đâu!"
				node.queue_redraw()
				special_requested.emit(c)
				return
			var k: int = c["choice"]
			if k < 0 or stands[k]["sold"] >= 0 or gs.pots[stands[k]["pot"]].is_empty():
				node.bubble = "Hết mất rồi…"
				node.set_mood(-1)
				c["state"] = "leave_wait"
				c["timer"] = 1.2
				return
			counter_busy = true
			node.facing = -1.0
			c["state"] = "chat"
			node.bubble = "Tôi muốn mua cây!"
			node.queue_redraw()
			chat_requested.emit(c)
		"queue":
			c["state"] = "queue"
		"post":     # vệ sĩ đứng gác ở cổng
			c["state"] = "idle"
			node.facing = -c.get("side", 1.0)
		"exit":
			customers.erase(c)
			node.queue_free()
	node.queue_redraw()


## Sau khi xem đủ: chọn cây thích nhất rồi ra quầy, hoặc bỏ về.
func _decide(c: Dictionary) -> void:
	if c["role"] == "vip":
		counter_claim = c
		node_say(c, "Ra quầy tính tiền!")
		_walk_to(c, _counter_spot(), "counter")
		return
	if event == "vip":
		# công tử sắp tới: khách chỉ xem chứ không mua, đi xem tiếp
		if _open_stands().is_empty():
			_leave(c, "Thôi, lần sau vậy")
			return
		c["visits"] = 2
		c["seen"] = []
		_go_next_stand(c)
		return
	var best := -1
	var best_score := -INF
	for k in _open_stands():
		var p: Dictionary = gs.pots[stands[k]["pot"]]
		var wish: Array = c["cust"]["wish"]
		var score := float(Gen.count_matches(p["gen"], wish)) / wish.size()
		score += 0.1 * Gen.rarity(p["gen"]) + randf() * 0.15
		if c["seen"].has(k):
			score += 0.2
		if score > best_score:
			best_score = score
			best = k
	if best < 0:
		_leave(c, "Thôi, lần sau vậy")
		return
	var p: Dictionary = gs.pots[stands[best]["pot"]]
	var chance: float = gs.buy_chance(p, gs.asking_price(p), c["cust"], "")
	if randf() < clampf(chance * 1.3, 0.15, 0.9):
		c["choice"] = best
		var queued := 0
		for o in customers:
			if o != c and (o["goal"] == "counter" or o["state"] in ["queue", "chat"]):
				queued += 1
		if queued == 0 and not counter_busy and counter_claim == null:
			counter_claim = c
			_walk_to(c, _counter_spot(), "counter")
		else:
			_walk_to(c, _queue_spot(queued), "queue")
	else:
		_leave(c, ["Đắt quá…", "Chưa ưng lắm", "Thôi, lần sau vậy"].pick_random())


func _leave(c: Dictionary, say: String) -> void:
	var node: Control = c["node"]
	node.bubble = say
	node.set_mood(-1 if say != "Cảm ơn nhé!" else 1)
	c["state"] = "leave_wait"
	c["timer"] = 1.3 if c["role"] == "" else 2.4


func node_say(c: Dictionary, say: String) -> void:
	c["node"].bubble = say
	c["node"].queue_redraw()


# =====================================================================
# Khách ẩn
# =====================================================================

func _role_count(role: String) -> int:
	var n := 0
	for c in customers:
		if c["role"] == role:
			n += 1
	return n


func _spawn_special(type: String, role: String, pos: Vector2) -> Dictionary:
	var node := Control.new()
	node.set_script(CustomerView)
	node.size = CUST_SIZE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(node)
	node.setup(type, 0)
	var c := {"node": node, "cust": {"type": type}, "state": "walk", "path": [], "goal": "", "timer": 0.0,
		"visits": 0, "seen": [], "choice": -1, "pos": pos, "role": role}
	customers.append(c)
	_place(c)
	return c


## Kiểm tra điều kiện khách ẩn và chạy từng bước của sự kiện.
func _update_events(delta: float) -> void:
	match event:
		"":
			var open := _open_stands()
			if open.is_empty():
				if customers.is_empty() and not counter_busy:
					empty_time += delta
					if empty_time >= Data.BAO_KE_WAIT:
						_start_bao_ke()
			else:
				empty_time = 0.0
				if not counter_busy and counter_claim == null:
					var kind: String = gs.vip_kind(open.map(func(k): return stands[k]["pot"]))
					if kind != "":
						_start_vip(kind)
		"vip":
			_update_vip(delta)
		"bao_ke":
			if _role_count("bao_ke") == 0:
				event = ""
				empty_time = 0.0


func _start_vip(kind: String) -> void:
	event = "vip"
	event_kind = kind
	event_phase = "browse"
	event_timer = Data.VIP_BROWSE_TIME
	event_hint = false
	spawn_timer = minf(spawn_timer, 0.6)
	# khách đang xếp hàng / ra quầy quay lại xem cây
	for c in customers:
		if c["role"] == "" and (c["goal"] in ["counter", "queue"] or c["state"] == "queue"):
			c["visits"] = 3
			c["seen"] = []
			_go_next_stand(c)


func _update_vip(delta: float) -> void:
	event_timer -= delta
	match event_phase:
		"browse":
			if event_timer <= 3.0 and not event_hint:
				event_hint = true
				set_status("Ngoài cổng có tiếng siêu xe vừa đỗ lại…")
			if event_timer <= 0.0:
				_guards_enter()
		"clear":
			var guards_ready := true
			for c in customers:
				if c["role"] == "guard" and c["state"] != "idle":
					guards_ready = false
			if (guards_ready and _role_count("") == 0) or event_timer <= 0.0:
				for c in customers.duplicate():
					if c["role"] == "":
						customers.erase(c)
						c["node"].queue_free()
				_vip_enter()
		"leave":
			if _role_count("vip") + _role_count("guard") == 0:
				event = ""
				event_phase = ""


func _guards_enter() -> void:
	event_phase = "clear"
	event_timer = 9.0
	for side in [-1.0, 1.0]:
		var g := _spawn_special("ve_si", "guard", _gate() + Vector2(side * 22, -30))
		g["side"] = side
		g["speed"] = 1.3
		node_say(g, "Giải tán! Giải tán!" if side < 0 else "Mời ra ngoài!")
		_walk_to(g, _gate() + Vector2(side * 84, 92), "post")
	for c in customers:
		if c["role"] != "":
			continue
		c["speed"] = 1.9
		c["node"].set_mood(-1)
		node_say(c, ["Ơ kìa!", "Chạy thôi!", "Gì vậy trời…", "Ối!"].pick_random())
		_walk_to(c, _gate() + Vector2(0, -40), "exit")
	set_status("Hai vệ sĩ áo đen bước vào mời hết khách ra ngoài!")


func _vip_enter() -> void:
	event_phase = "vip"
	for g in customers:
		if g["role"] == "guard":
			node_say(g, "Cậu chủ tới!")
	var v := _spawn_special("cong_tu", "vip", _gate() + Vector2(0, -30))
	v["visits"] = mini(3, _open_stands().size())
	v["speed"] = 0.85     # đi thong thả
	node_say(v, "Để anh xem nào…")
	set_status("Công tử ăn chơi ghé shop!")
	_go_next_stand(v)


func _start_bao_ke() -> void:
	event = "bao_ke"
	empty_time = 0.0
	var b := _spawn_special("bao_ke", "bao_ke", _gate() + Vector2(0, -30))
	b["speed"] = 1.1
	b["node"].set_mood(-1)
	node_say(b, "Chủ quán đâu ra đây!")
	counter_claim = b
	_walk_to(b, _counter_spot(), "counter")
	set_status("Một gã bặm trợn đi thẳng tới quầy…")


## Công tử mua hết cây đang bày bán theo giá đã đặt. Trả về [số cây, tổng xu].
func vip_sell_all(c: Dictionary) -> Array:
	if c.get("paid", false):
		return [0, 0]
	c["paid"] = true
	var n := 0
	var total := 0
	for k in _open_stands():
		var pot: int = stands[k]["pot"]
		var price: int = gs.asking_price(gs.pots[pot])
		gs.complete_sale(pot, price)
		stands[k]["sold"] = price
		n += 1
		total += price
	c["sold_n"] = n
	c["sold_total"] = total
	gs.mark_hidden(event_kind)
	refresh()
	return [n, total]


## main.gd gọi sau khi đóng bảng của khách ẩn. result (bảo kê): "danh" hoặc "canh_sat".
func special_finished(c: Dictionary, result: String) -> void:
	counter_busy = false
	var node: Control = c["node"]
	if c["role"] == "vip":
		vip_sell_all(c)
		_leave(c, "Hẹn gặp lại cưng!")
		node.set_mood(1)
		event_phase = "leave"
		for g in customers:
			if g["role"] == "guard":
				g["state"] = "follow"
				g["timer"] = 1.4
				node_say(g, "Rõ, thưa cậu chủ!")
		set_status("Công tử mua sạch %d cây, bạn nhận %d xu!" % [c.get("sold_n", 0), c.get("sold_total", 0)])
	else:
		match result:
			"danh":
				_leave(c, "Ui da! Nhớ mặt đó!")
				c["speed"] = 1.9
				set_status("Bạn đánh khứa đó chạy mất dép, nhưng tốn 50 xu bông băng thuốc đỏ.")
			"dong_tien":
				_leave(c, "Ngoan lắm!")
				node.set_mood(1)
				set_status("Bạn đã đóng %d xu tiền bảo kê." % c.get("paid_fee", Data.BAO_KE_FEE))
			"canh_sat":
				_leave(c, "Ngon lắm, hãy đợi đó!")
				set_status("Gã bảo kê bỏ đi, còn hăm dọa \"hãy đợi đó\".")
			_:
				_leave(c, "Hừ!")
	node.queue_redraw()
	refresh()


## main.gd gọi sau khi trò chuyện xong.
func chat_finished(c: Dictionary, bought: bool, price: int) -> void:
	counter_busy = false
	if bought:
		var k: int = c["choice"]
		stands[k]["sold"] = price
		_leave(c, "Cảm ơn nhé!")
		set_status("Đã bán cây được %d xu!" % price)
	else:
		_leave(c, "Thôi vậy…")
	refresh()


# =====================================================================
# Vẽ cảnh
# =====================================================================

func _draw() -> void:
	var w := size.x
	var h := size.y
	var c := _center()
	var r := _radii()
	# trời và đồi
	draw_rect(Rect2(0, 0, w, h), Color("6fb35a"))
	draw_rect(Rect2(0, TOP_H, w, 70), Color("a9dcf0"))
	for i in 5:
		var hx := w * (i / 4.0)
		_ellipse(Vector2(hx, TOP_H + 92), 260, 60, Color("7cc063").darkened(0.05 * (i % 2)))
	draw_circle(Vector2(w - 90, TOP_H + 28), 26, Color("ffe27a"))
	draw_rect(Rect2(0, TOP_H + 92, w, h), Color("6fb35a"))
	# cối xay gió trên đồi (sau hàng rào)
	var fy := _gate().y - 22
	if gs.decor_owned.get("coi_xay_gio", false):
		Art.draw_decor(self, "coi_xay_gio", Vector2(w * 0.36, fy + 4), 1.0, anim)
	# hàng rào, cổng, bảng hiệu (theo bậc nâng cấp)
	Art.draw_fence(self, w, fy, _gate().x, gs.upgrade_tier("hang_rao"))
	Art.draw_gate_posts(self, _gate().x, fy, gs.upgrade_tier("hang_rao"))
	var font := get_theme_default_font()
	sign_rect = Art.draw_sign(self, Vector2(_gate().x, fy - 30), gs.shop_name, gs.upgrade_tier("bang_hieu"), font, anim)
	if gs.decor_owned.get("chuong_gio", false):
		Art.draw_decor(self, "chuong_gio", Vector2(_gate().x + 70, fy - 14), 1.0, anim)
	if gs.decor_owned.get("den_long", false):
		for side in [-1, 1]:
			Art.draw_decor(self, "den_long", Vector2(_gate().x + side * 100 - 7, fy + 34), 1.0, anim)
	# lối đi từ cổng
	var path := PackedVector2Array([_gate() + Vector2(-46, -10), _gate() + Vector2(46, -10),
		Vector2(c.x + 60, c.y - r.y + 10), Vector2(c.x - 60, c.y - r.y + 10)])
	draw_colored_polygon(path, Color("b7b4aa"))
	# sân lát đá
	_ellipse(c, r.x + 16, r.y + 14, Color("8f8c84"))
	_ellipse(c, r.x, r.y, Color("b7b4aa"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 260:
		var p := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		if p.length() > 0.97:
			continue
		var q := c + Vector2(p.x * r.x, p.y * r.y)
		var col := Color("c9c6bc") if rng.randf() < 0.5 else Color("a8a59c")
		_stone(q, rng.randf_range(12, 22), rng.randf_range(7, 12), rng.randf() * PI, col)
	# đồ trang trí trên cỏ
	var spots := {
		"bon_hoa": [Vector2(w * 0.22, fy + 50), Vector2(w * 0.84, fy + 50)],
		"ghe_da": [Vector2(98, c.y - 40)],
		"xich_du": [Vector2(100, c.y + 80)],
		"tuong": [Vector2(w - 50, c.y - 60)],
		"o_du": [Vector2(w - 55, c.y + 66)],
	}
	for id in spots:
		if gs.decor_owned.get(id, false):
			for p in spots[id]:
				Art.draw_decor(self, id, p, 1.0, anim)
	# mái che quầy (phía sau người bán)
	Art.draw_counter_back(self, _counter_desk(), gs.upgrade_tier("quay"), anim)
	# gốc cây trưng bày
	for s in stands:
		var p: Vector2 = s["pos"]
		_ellipse(p + Vector2(0, 6), 46, 14, Color(0, 0, 0, 0.18))
		draw_rect(Rect2(p.x - 36, p.y - 12, 72, 18), Color("8a5a2b"))
		_ellipse(p + Vector2(0, 6), 36, 10, Color("6e4527"))
		_ellipse(p + Vector2(0, -12), 36, 11, Color("c9955a"))
		_ellipse(p + Vector2(0, -12), 24, 7, Color("b07a45"))
		_ellipse(p + Vector2(0, -12), 12, 3.5, Color("c9955a"))
	# cây bụi trang trí
	for b in [Vector2(40, h - 140), Vector2(w - 50, h - 160), Vector2(w - 70, TOP_H + 150), Vector2(90, h - BOTTOM_H - 20), Vector2(w * 0.5, h - BOTTOM_H - 6)]:
		_ellipse(b + Vector2(0, 10), 52, 16, Color(0, 0, 0, 0.15))
		draw_circle(b, 34, Color("3f8a3a"))
		draw_circle(b + Vector2(-20, 6), 26, Color("4f9a45"))
		draw_circle(b + Vector2(22, 4), 24, Color("468f3f"))
		for i in 4:
			draw_circle(b + Vector2(-18 + i * 12, -10 + (i % 2) * 14), 4, [Color("f2a7c3"), Color("f6d55c"), Color("ffffff"), Color("e2453c")][i])


## Có món nào cần vẽ lại liên tục (đèn nhấp nháy, cối xay quay...) không.
func _animated() -> bool:
	for id in ["den_long", "coi_xay_gio", "xich_du", "chuong_gio"]:
		if gs.decor_owned.get(id, false):
			return true
	return gs.upgrade_tier("bang_hieu") >= 2 or gs.upgrade_tier("quay") >= 3


## Chạm vào bảng hiệu để đổi tên.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if sign_rect.has_point(event.position):
			rename_pressed.emit()
			accept_event()


func _ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 40:
		var t := TAU * i / 40.0
		pts.append(center + Vector2(cos(t) * rx, sin(t) * ry))
	draw_colored_polygon(pts, col)


func _stone(center: Vector2, rx: float, ry: float, rot: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 7:
		var t := TAU * i / 7.0
		var k := 0.8 + 0.2 * sin(i * 2.3 + rot * 3.0)
		pts.append(center + Vector2(cos(t) * rx * k, sin(t) * ry * k).rotated(rot * 0.3))
	draw_colored_polygon(pts, col)


## Nhà kính giữa sân. Chạm vào để về vườn.
class GreenhouseBuilding extends Control:
	signal tapped
	var hover := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(func():
			hover = true
			queue_redraw())
		mouse_exited.connect(func():
			hover = false
			queue_redraw())

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			tapped.emit()
			accept_event()

	func _has_point(p: Vector2) -> bool:
		return Rect2(Vector2(14, 20), Vector2(272, 168)).has_point(p)

	func _poly(pts: Array, col: Color) -> void:
		draw_colored_polygon(PackedVector2Array(pts), col)

	func _draw() -> void:
		var glass := Color(0.78, 0.92, 0.95, 0.55)
		var frame := Color("f4f1e8")
		var frame_dark := Color("b9b4a6")
		# bóng
		var sh := PackedVector2Array()
		for i in 32:
			var t := TAU * i / 32.0
			sh.append(Vector2(150 + cos(t) * 150, 186 + sin(t) * 12))
		draw_colored_polygon(sh, Color(0, 0, 0, 0.18))
		# mặt bên (chiều sâu)
		_poly([Vector2(250, 92), Vector2(284, 74), Vector2(284, 160), Vector2(250, 178)], Color(0.62, 0.78, 0.82, 0.8))
		_poly([Vector2(236, 30), Vector2(270, 14), Vector2(284, 74), Vector2(250, 92)], Color(0.7, 0.86, 0.9, 0.8))
		# cây bên trong
		var leaves := [Color("3f8a3a"), Color("4f9a45"), Color("5fae55")]
		for i in 9:
			var x := 34.0 + i * 25.0
			draw_circle(Vector2(x, 150 - (i % 3) * 10), 17, leaves[i % 3])
		for i in 7:
			var x := 44.0 + i * 31.0
			draw_circle(Vector2(x, 128 + (i % 2) * 8), 13, leaves[(i + 1) % 3])
		var petals := [Color("f2a7c3"), Color("f6d55c"), Color("e2453c"), Color("9b6bd6"), Color("ffffff")]
		for i in 12:
			var x := 34.0 + i * 19.0
			draw_circle(Vector2(x, 118 + (i * 7) % 26), 4.5, petals[i % petals.size()])
		# chậu và bàn trồng bên trong
		draw_rect(Rect2(28, 160, 220, 10), Color("8a5a2b"))
		# tường kính phía trước
		draw_rect(Rect2(22, 92, 228, 86), glass)
		draw_rect(Rect2(22, 92, 228, 30), Color(1, 1, 1, 0.18))
		# mái kính
		_poly([Vector2(12, 94), Vector2(260, 94), Vector2(236, 30), Vector2(36, 30)], Color(0.82, 0.94, 0.97, 0.75))
		_poly([Vector2(36, 30), Vector2(236, 30), Vector2(150, 8)], Color(0.88, 0.96, 0.98, 0.85))
		# khung mái
		for i in 8:
			var t := i / 7.0
			draw_line(Vector2(lerpf(12, 260, t), 94), Vector2(lerpf(36, 236, t), 30), frame, 3.0)
		draw_line(Vector2(12, 94), Vector2(260, 94), frame, 5.0)
		draw_line(Vector2(36, 30), Vector2(236, 30), frame, 4.0)
		draw_line(Vector2(36, 30), Vector2(150, 8), frame, 4.0)
		draw_line(Vector2(236, 30), Vector2(150, 8), frame, 4.0)
		draw_line(Vector2(236, 30), Vector2(270, 14), frame, 3.0)
		draw_line(Vector2(260, 94), Vector2(284, 74), frame, 3.0)
		draw_line(Vector2(270, 14), Vector2(284, 74), frame, 3.0)
		# khung tường
		for i in 7:
			var x := lerpf(22, 250, i / 6.0)
			draw_line(Vector2(x, 92), Vector2(x, 178), frame, 4.0)
		draw_line(Vector2(22, 134), Vector2(250, 134), frame, 3.0)
		draw_line(Vector2(284, 74), Vector2(284, 160), frame, 3.0)
		draw_line(Vector2(250, 178), Vector2(284, 160), frame, 3.0)
		# chân tường đá
		draw_rect(Rect2(18, 170, 236, 14), Color("9c978b"))
		draw_rect(Rect2(18, 170, 236, 4), Color("b9b4a6"))
		_poly([Vector2(254, 170), Vector2(288, 152), Vector2(288, 166), Vector2(254, 184)], Color("847f74"))
		# cửa
		draw_rect(Rect2(116, 112, 48, 66), Color(0.55, 0.75, 0.8, 0.85))
		draw_rect(Rect2(116, 112, 48, 66), frame_dark, false, 4.0)
		draw_line(Vector2(140, 112), Vector2(140, 178), frame_dark, 3.0)
		draw_circle(Vector2(134, 148), 3, Color("d9b26a"))
		draw_circle(Vector2(146, 148), 3, Color("d9b26a"))
		# biển tên
		var sign_r := Rect2(92, 52, 116, 26)
		draw_rect(sign_r, Color("3e7d4a") if not hover else Color("4f9a5a"))
		draw_rect(sign_r, Color("d9b26a"), false, 2.5)
		var font := get_theme_default_font()
		var t1 := "NHÀ KÍNH"
		var tw := font.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(font, Vector2(150 - tw / 2, 71), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff1cf"))
		if hover:
			var t2 := "Chạm để về vườn"
			var tw2 := font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			draw_rect(Rect2(150 - tw2 / 2 - 8, -22, tw2 + 16, 22), Color(0, 0, 0, 0.6))
			draw_string(font, Vector2(150 - tw2 / 2, -6), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)


## Mặt trước quầy thu ngân, vẽ đè lên nửa dưới người bán.
class DeskFront extends Control:
	var tier := 0

	func _draw() -> void:
		Art.draw_counter_front(self, size, tier, get_theme_default_font())
