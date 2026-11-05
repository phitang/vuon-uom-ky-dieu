extends Node
## Bán hạt ở Vật tư, và lai giống ra 3 hạt giống nhau.

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var gs = get_node("/root/GameState")
	var Gen = load("res://scripts/genetics.gd")
	gs.new_game()
	gs.away_report = ""
	gs.coins = 300
	gs.seeds.clear()
	var kinds := [["hong", "do"], ["cuc", "vang"], ["tulip", "tim"], ["lan", "xanh"], ["rong", "do"], ["sao", "trang"], ["sen", "hongnhat"]]
	for k in kinds:
		gs.seeds.append({"gen": {"hoa": [k[0], k[0]], "la": ["tron", "tron"], "than": ["thang", "thang"], "mau": [k[1], k[1]], "co": ["vua", "vua"]}, "bo_me": []})
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._open_shop()
	await _shot(out + "/ban_hat_1_vat_tu.png")
	main._open_sell_seeds()
	await get_tree().process_frame
	var prices := []
	for i in gs.seeds.size():
		prices.append(gs.seed_sell_price(i))
	print("Giá từng hạt: ", prices)
	main.sell_pick = 4
	main.popup_refresh.call()
	await _shot(out + "/ban_hat_2_chon.png")
	var c0: int = gs.coins
	var n0: int = gs.seeds.size()
	_press(main.overlay, "Bán %d xu" % gs.seed_sell_price(4))
	await get_tree().process_frame
	print("Bán: xu ", c0, " -> ", gs.coins, " | hạt ", n0, " -> ", gs.seeds.size(), " | chọn = ", main.sell_pick)
	main.sell_pick = 0
	main.popup_refresh.call()
	_press(main.overlay, "Không")
	print("Không bán: hạt = ", gs.seeds.size(), " chọn = ", main.sell_pick)
	await _shot(out + "/ban_hat_3_sau.png")
	main._close_popup()
	# lai giống: 3 hạt giống hệt nhau
	gs.seeds.clear()
	gs.soils = ["thuong", "thuong", "thuong"]
	for i in 2:
		gs.seeds.append({"gen": Gen.random_genome(1), "bo_me": []})
		gs.plant_seed(i, 0)
		gs.water(i)
		gs.pots[i]["tien_do"] = 12000.0
	gs.cross(0, 1)
	gs._advance(901.0)
	gs.harvest_pod(1)
	var keys := {}
	for s in gs.seeds:
		keys[JSON.stringify(s["gen"])] = true
	print("Lai ra ", gs.seeds.size(), " hạt, số bộ gen khác nhau = ", keys.size())
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
