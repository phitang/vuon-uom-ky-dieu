extends Node
const Data := preload("res://scripts/data.gd")
## Chụp Shop cây trước và sau khi mua đủ trang trí, cửa hàng trang trí, hộp đổi tên; thử chạm bảng hiệu.

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	gs.coins = 200000
	for i in 6:
		gs.pots.append({})
		gs.soils.append("thuong")
	var cols := ["tim", "vang", "do", "hongnhat", "xanh", "cam", "trang", "do", "tim"]
	var kinds := ["cuc", "hong", "tulip", "lan", "chuong", "cuc", "sen", "rong", "sao"]
	for i in 9:
		var g := {"hoa":[kinds[i],kinds[i]],"la":["tron","tron"],"than":["thang","thang"],"mau":[cols[i], cols[i]],"co":["vua","vua"]}
		gs.seeds.append({"gen": g, "bo_me": []})
		gs.plant_seed(i, gs.seeds.size() - 1)
		gs.water(i)
		gs.pots[i]["tien_do"] = 12000.0
		gs.set_display(i, true)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._open_nursery()
	var nur = main.nursery
	nur.spawn_timer = 9999.0
	await _shot(out + "/decor_0.png")
	# chạm vào bảng hiệu -> hộp đổi tên
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = nur.sign_rect.get_center()
	nur._gui_input(ev)
	await get_tree().process_frame
	print("Chạm bảng hiệu: mở hộp đổi tên = ", main.overlay.visible)
	await _shot(out + "/decor_rename.png")
	var edit: LineEdit = _find(main.overlay, LineEdit)
	edit.text = "Vườn Hoa Phi Tăng"
	edit.text_submitted.emit(edit.text)
	await get_tree().process_frame
	print("Tên mới: ", gs.shop_name)
	# mua hết
	for k in ["bang_hieu", "quay", "hang_rao"]:
		for t in 3:
			gs.buy_upgrade(k)
	for d in ["chuong_gio", "den_long", "bon_hoa", "ghe_da", "o_du", "xich_du", "tuong", "coi_xay_gio"]:
		gs.buy_decor(d)
	print("Sức hút: ", gs.appeal(), " | xu còn ", gs.coins)
	nur.refresh()
	for k in 3:
		nur._spawn_customer()
		for step in 40 + k * 30:
			nur._update_customer(nur.customers[k], 0.05)
	# một khách ra ghế đá ngồi nghỉ
	var sitter: Dictionary = nur.customers[0]
	var tries := 0
	while not nur._wants_bench(sitter) and tries < 200:
		tries += 1
	nur.bench_user = sitter
	sitter["rested"] = true
	nur._walk_to(sitter, nur._bench_pos() + Vector2(0, -12), "bench")
	for step in 400:
		nur._update_customer(sitter, 0.05)
		if sitter["state"] == "sit":
			break
	print("Khách ngồi ghế đá: ", sitter["state"], " | bench_user đúng: ", nur.bench_user == sitter)
	await _shot(out + "/decor_full.png")
	main._open_decor_shop()
	await _shot(out + "/decor_shop.png")
	main._close_popup()
	gs.shop_upgrades = {"bang_hieu": 1, "quay": 1, "hang_rao": 1}
	nur.refresh()
	await _shot(out + "/decor_t1.png")
	gs.shop_upgrades = {"bang_hieu": 2, "quay": 2, "hang_rao": 2}
	nur.refresh()
	await _shot(out + "/decor_t2.png")
	get_tree().quit()

func _find(root: Node, cls) -> Node:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if is_instance_of(n, cls):
			return n
		stack.append_array(n.get_children())
	return null

func _shot(path: String) -> void:
	for i in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
