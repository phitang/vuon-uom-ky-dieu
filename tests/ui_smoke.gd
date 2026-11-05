extends Node
## Kiểm tra nhanh: bấm thử qua mọi thao tác. Chạy cảnh tests/ui_smoke.tscn.

var main: Control
var gs: Node


func _ready() -> void:
	gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	# kéo thả 2 hạt vào chậu 0 và 1, rồi tưới
	print("Thả hạt được không: ", main._can_drop_seed(0, {"hat": 0}))
	main._drop_seed(0, {"hat": 0})
	main._drop_seed(1, {"hat": 0})
	print("Gieo: hạt còn ", gs.seeds.size(), " chậu0=", not gs.pots[0].is_empty(), " chậu1=", not gs.pots[1].is_empty(), " | ", main.state_l.text)
	gs._advance(600.0)
	print("Chưa tưới 10 phút: tien_do=", gs.pots[1]["tien_do"])
	main._on_slot(0); main._use_tool("nuoc")
	main._on_slot(1); main._use_tool("nuoc")
	for i in 2:
		gs.pots[i]["tien_do"] = 10000.0
	gs._advance(1.0)
	gs.changed.emit()
	await get_tree().process_frame
	print("Ra hoa: ", gs.stage_of(gs.pots[0]), " sotay=", gs.collection.size())

	# chọn cây 0, tưới, bón (không được vì đã ra hoa)
	main._on_slot(0)
	gs.pots[0]["nuoc"] = 0.2
	main._use_tool("nuoc")
	print("Tưới: nước=", gs.pots[0]["nuoc"], " | ", main.status_l.text)
	main._use_tool("phan")
	print("Bón: ", main.status_l.text)

	# súng thụ phấn: thả vào cây 0 để nạp phấn, thả vào cây 1 để thụ phấn
	var before: int = gs.seeds.size()
	main._drop_seed(0, {"sung": true})
	print("Nạp phấn: ", not main.pollen_gen.is_empty(), " | ", main.status_l.text)
	main._drop_seed(1, {"sung": true})
	print("Thụ phấn: kết hạt=", gs.has_pod(1), " | ", main.status_l.text)
	gs._advance(299.0)
	print("Sau 4p59: chờ thu=", gs.pod_ready(1))
	gs._advance(2.0)
	print("Sau 5p: chờ thu=", gs.pod_ready(1), " trưng bày được=", gs.set_display(1, true))
	main._on_slot(1)
	print("Chạm cây thu hạt: ", before, " -> ", gs.seeds.size(), " | ", main.status_l.text)
	gs._advance(900.0)
	print("Sau 15p nữa: chờ thu=", gs.pod_ready(1), " còn kết=", gs.pod_pending(1))
	main._on_slot(1)
	print("Thu tiếp: hạt=", gs.seeds.size(), " còn kết hạt=", gs.has_pod(1))

	# chỉnh giá cây 0 qua ô giá, rồi trưng bày cây 0 và 1
	main._on_slot(0)
	main._on_price_pressed()
	await get_tree().process_frame
	var sl: HSlider = _find_slider()
	sl.value = 80
	_press_text("Lưu giá")
	print("Giá đặt: ", gs.pots[0].get("gia_pct"), "% = ", gs.asking_price(gs.pots[0]), " xu | ô giá: ", main.price_btn.text)
	main._on_sell()
	main._on_slot(1)
	main._on_sell()
	print("Trưng bày: ", gs.displayed_pots(), " nút: ", main.sell_btn.text)
	main._use_tool("nuoc")
	print("Dùng dụng cụ khi trưng bày: ", main.status_l.text)

	# mở shop, cho khách đi tới quầy
	main._open_nursery()
	await get_tree().process_frame
	var nur = main.nursery
	print("Shop: ", nur.stands.size(), " gốc | ", nur.status_l.text)
	var chats := 0
	var sold_count := 0
	for round in 6:
		nur._spawn_customer()
		for step in 400:
			for c in nur.customers.duplicate():
				nur._update_customer(c, 0.05)
			if main.overlay.visible:
				chats += 1
				print("  Quầy: ", _find_label_starting("\""))
				_press_text("\"Cây này đúng")
				_press_text("Tiếp tục")
			if nur.customers.is_empty():
				break
		if gs.displayed_pots().is_empty():
			break
	for st in nur.stands:
		if st["sold"] >= 0:
			sold_count += 1
	print("Khách ra quầy: ", chats, " | cây đã bán: ", sold_count, " | xu=", gs.coins)
	nur.refresh()
	var left: Array = gs.displayed_pots()
	# bấm vào nhà kính giữa shop để về vườn
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = Vector2(150, 140)
	nur.house._gui_input(ev)
	print("Bấm nhà kính: shop còn mở=", nur.visible)
	print("Về vườn: còn trưng bày=", gs.displayed_pots().size(), " (trước đó ", left.size(), ") | ", main.status_l.text)
	# đảm bảo chậu 0 có cây để các bước sau
	# chậu trống không đất: cho đất
	if not gs.pots[0].is_empty():
		gs.remove_plant(0)
	main._on_slot(0)
	print("Sau bỏ cây: đất=", gs.soils[0], " | ", main.status_l.text)
	print("Thả hạt vào chậu không đất: ", main._can_drop_seed(0, {"hat": 0}))
	main._use_soil("tot")
	print("Đất tốt chưa mua: ", main.status_l.text)
	main._use_soil("thuong")
	print("Cho đất thường: ", gs.soils[0])
	gs.soils_owned["tot"] = true
	main._refresh_all()
	print("Túi đất đổi hình: ", main.tool_icons["dat"].kind)
	main._use_tool("dat")
	print("Bấm túi đất: ", gs.soils[0])
	gs.soils_owned.erase("tot")

	# cửa hàng
	gs.coins = 1000
	main._open_shop()
	await get_tree().process_frame
	_press_text("30 xu")
	await get_tree().process_frame
	_press_text("100 xu")
	await get_tree().process_frame
	gs.coins = 260000
	gs.changed.emit()
	await get_tree().process_frame
	_press_text("50000 xu")
	await get_tree().process_frame
	print("Mua đất tốt: ", gs.soils_owned.keys(), " nút còn mua được: ", _press_text("50000 xu"))
	print("Cửa hàng: chậu=", gs.pots.size(), " hạt=", gs.seeds.size(), " xu=", gs.coins)
	main._close_popup()

	# sổ tay, menu
	main._open_book()
	await get_tree().process_frame
	print("Sổ tay: ", gs.collection.size(), " giống")
	main._open_menu()
	_press_text("Chế độ thử nhanh")
	print("time_scale=", gs.time_scale)
	main._close_popup()

	# thu hạt từ cây già bằng kéo
	if gs.pots[1].is_empty():
		gs.soils[1] = "thuong"
		gs.seeds.append({"gen": load("res://scripts/genetics.gd").random_genome(0), "bo_me": []})
		gs.plant_seed(1, gs.seeds.size() - 1)
		gs.water(1)
	gs.pots[1]["tien_do"] = 30000.0
	main._on_slot(1)
	var s0: int = gs.seeds.size()
	main._use_tool("keo")
	print("Thu hạt: ", s0, " -> ", gs.seeds.size())

	# nhiều chậu -> sang kệ 2
	gs.coins = 100000
	for i in 14:
		gs.buy("chau")
	main._refresh_all()
	main._change_page(1)
	print("Kệ: ", main.page_l.text, " chậu=", gs.pots.size())

	# thùng rác
	main._change_page(-1)
	gs.seeds.append({"gen": load("res://scripts/genetics.gd").random_genome(0), "bo_me": []})
	main._drop_seed(2, {"hat": gs.seeds.size() - 1})
	main._on_slot(2)
	gs.pots[2]["chet"] = true
	main._on_trash()
	print("Thùng rác: chậu2 trống=", gs.pots[2].is_empty())
	await get_tree().create_timer(0.3).timeout
	print("XONG")
	get_tree().quit()


func _all_buttons(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Button and c.is_visible_in_tree():
			out.append(c)
		_all_buttons(c, out)


func _press_text(prefix: String) -> bool:
	var btns: Array = []
	_all_buttons(main.overlay if main.overlay.visible else main, btns)
	for b in btns:
		if b.text.begins_with(prefix) and not b.disabled:
			b.pressed.emit()
			return true
	print("  (không thấy nút: ", prefix, ")")
	return false


func _find_slider() -> HSlider:
	var stack: Array = [main.overlay]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is HSlider:
			return n
		stack.append_array(n.get_children())
	return null


func _find_label_starting(prefix: String) -> String:
	var stack: Array = [main.overlay]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Label and n.text.begins_with(prefix):
			return n.text
		stack.append_array(n.get_children())
	return ""
