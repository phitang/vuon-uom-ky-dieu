extends Node
## Bán cây chưa ra hoa: hỏi xác nhận, 50% giá.

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	gs.seeds.clear()
	for i in gs.pots.size():
		gs.soils[i] = "thuong"
	var g := {"hoa": ["hong", "hong"], "la": ["tron", "tron"], "than": ["thang", "thang"], "mau": ["do", "do"], "co": ["vua", "vua"]}
	for i in 2:
		gs.seeds.append({"gen": g.duplicate(true), "bo_me": []})
		gs.plant_seed(i, 0)
		gs.water(i)
	gs.pots[0]["tien_do"] = 4000.0    # cây non
	gs.pots[1]["tien_do"] = 12000.0   # đang ra hoa
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	print("Giai đoạn: ", gs.stage_of(gs.pots[0]), " / ", gs.stage_of(gs.pots[1]))
	print("Giá cây non = ", gs.market_price(gs.pots[0]), " | giá cây ra hoa = ", gs.market_price(gs.pots[1]))
	main._on_slot(0)
	print("Nút giá: ", main.price_btn.text)
	main._on_sell()
	print("Hỏi xác nhận: ", main.overlay.visible, " | trưng bày = ", gs.is_displayed(0))
	await _shot(out + "/cay_non_hoi.png")
	_press(main.overlay, "Từ chối")
	print("Từ chối: bảng đóng = ", not main.overlay.visible, " | trưng bày = ", gs.is_displayed(0))
	main._on_sell()
	_press(main.overlay, "Đồng ý")
	print("Đồng ý: trưng bày = ", gs.is_displayed(0))
	main._on_slot(1)
	main._on_sell()
	print("Cây ra hoa: hỏi = ", main.overlay.visible, " | trưng bày = ", gs.is_displayed(1))
	get_tree().quit()

func _press(root: Node, text: String) -> void:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Button and n.text == text:
			n.pressed.emit()
			return
		stack.append_array(n.get_children())
	print("không thấy nút ", text)

func _shot(path: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
