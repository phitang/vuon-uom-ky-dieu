extends Node
## Công tử ghé thêm: chê shop toàn cây Thường (3 phút), hỏi mua cây đắt nhất khi có cây Huyền thoại (5 phút).
## Đàn anh thỉnh thoảng vào như khách thường, khó mua hơn.

var main
var nur
var gs

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	gs.coins = 500
	_fill([0, 0])
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._open_nursery()
	nur = main.nursery
	await _run(170.0)
	print("Sau 170 giây toàn cây Thường: sự kiện='", nur.event, "'")
	await _run(15.0)
	print("Sau 185 giây: sự kiện='", nur.event, "' kiểu=", nur.event_kind)
	await _shot(out + "/vip2_vao.png")
	await _run_until(func(): return main.overlay.visible, 60.0)
	await _shot(out + "/vip2_khinh.png")
	_press("Tiếp tục")
	await _run_until(func(): return nur.event == "", 30.0)
	print("Công tử đã đi: ", nur.event == "", " | còn cây: ", nur._open_stands().size())
	await _run(200.0)
	print("Lần 2 trong cùng lần mở shop: sự kiện='", nur.event, "' (phải rỗng)")
	# cây huyền thoại
	main._close_nursery()
	_fill([3, 0, 2])
	main._open_nursery()
	await _run(290.0)
	print("Sau 290 giây có Huyền thoại: '", nur.event, "'")
	await _run(15.0)
	print("Sau 305 giây: '", nur.event, "' kiểu=", nur.event_kind)
	await _run_until(func(): return main.overlay.visible, 60.0)
	var k: int = nur.priciest_stand()
	var want: int = gs.asking_price(gs.pots[nur.stands[k]["pot"]])
	var prices := []
	for s in nur._open_stands():
		prices.append(gs.asking_price(gs.pots[nur.stands[s]["pot"]]))
	print("Giá các cây: ", prices, " -> công tử chọn ", want)
	await _shot(out + "/vip2_me.png")
	var c0: int = gs.coins
	_press("Có")
	await get_tree().process_frame
	print("Bán: xu ", c0, " -> ", gs.coins, " | còn ", nur._open_stands().size(), " cây")
	await _shot(out + "/vip2_me_ban.png")
	_press("Tiếp tục")
	await _run_until(func(): return nur.event == "", 30.0)
	print("Xong: '", nur.event, "'")
	# đàn anh như khách thường
	var n := 0
	for i in 400:
		nur.seen_events.erase("dan_anh")
		nur._spawn_customer()
		var c = nur.customers.back()
		if c["cust"].get("dan_anh", false):
			n += 1
		nur.customers.erase(c)
		c["node"].queue_free()
	print("Đàn anh xuất hiện: ", n, "/400 lần sinh khách (~12%)")
	nur._spawn_customer()
	nur._spawn_customer()
	var cnt := 0
	for c in nur.customers:
		if c["cust"].get("dan_anh", false):
			cnt += 1
	print("Trong một lần mở shop tối đa 1 đàn anh: ", cnt <= 1)
	var cust: Dictionary = gs.new_customer()
	var p: Dictionary = gs.pots[nur.stands[nur._open_stands()[0]]["pot"]] if not nur._open_stands().is_empty() else {}
	if not p.is_empty():
		var a: float = gs.buy_chance(p, gs.asking_price(p), cust, "")
		cust["dan_anh"] = true
		var b: float = gs.buy_chance(p, gs.asking_price(p), cust, "")
		print("Tỉ lệ mua: khách thường %.2f, đàn anh %.2f" % [a, b])
	# khung trò chuyện với đàn anh như khách
	nur.customers.clear()
	nur._spawn_customer()
	var d = nur.customers.back()
	d["cust"]["dan_anh"] = true
	d["node"].setup(d["cust"]["type"], 0, "dan_anh")
	d["choice"] = nur._open_stands()[0]
	main._open_chat(d)
	await _shot(out + "/dan_anh_khach.png")
	get_tree().quit()

func _fill(rar: Array) -> void:
	gs.pots.clear()
	gs.soils.clear()
	var Gen = load("res://scripts/genetics.gd")
	var Data = load("res://scripts/data.gd")
	for i in rar.size():
		gs.pots.append({})
		gs.soils.append("hiem")
	gs.seeds.clear()
	var made := 0
	var tries := 0
	while made < rar.size() and tries < 200000:
		tries += 1
		var g: Dictionary = Gen.random_genome(3)
		if rar[made] == 3:
			for part in Data.PARTS:
				for id in Data.TRAITS[part]:
					if Data.TRAITS[part][id]["hiem"] >= 3 and randf() < 0.5:
						g[part] = [id, id]
		if Gen.rarity(g) != rar[made]:
			continue
		gs.seeds.append({"gen": g, "bo_me": []})
		gs.plant_seed(made, gs.seeds.size() - 1)
		gs.water(made)
		gs.pots[made]["tien_do"] = 12000.0
		gs.set_display(made, true)
		made += 1

func _run(sec: float) -> void:
	var t := 0.0
	while t < sec:
		nur.spawn_timer = 1e9     # không cho khách thường vào để thử riêng công tử
		nur._process(0.05)
		t += 0.05
	await get_tree().process_frame

func _run_until(cond: Callable, max_sec: float) -> void:
	var t := 0.0
	while t < max_sec and not cond.call():
		nur.spawn_timer = 1e9
		nur._process(0.05)
		t += 0.05
	await get_tree().process_frame

func _press(text: String) -> void:
	var stack: Array = [main.overlay]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Button and n.text == text and not n.is_queued_for_deletion():
			n.pressed.emit()
			return
		stack.append_array(n.get_children())
	print("không thấy nút ", text)

func _shot(path: String) -> void:
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
