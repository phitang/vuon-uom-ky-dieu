extends Node
## Thử khách ẩn: công tử ăn chơi (cây Quý, rồi Huyền thoại) và đàn anh đòi tiền bảo kê (đánh, báo cảnh sát, đóng tiền). Chụp ảnh từng bước.

var out := ""
var main
var nur
var gs


func _ready() -> void:
	out = OS.get_environment("SHOT_DIR")
	gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	gs.coins = 1000
	_fill(2, 4)   # 4 cây Quý
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._open_nursery()
	nur = main.nursery
	print("Kích hoạt (Quý): ", nur.event, " / ", nur.event_kind)
	await _run(4.0)
	print("Đang xem: khách thường = ", nur._role_count(""), ", bước = ", nur.event_phase)
	await _shot("an_1_xem.png")
	await _run(7.5)
	print("Bước = ", nur.event_phase, ", vệ sĩ = ", nur._role_count("guard"))
	await _shot("an_2_ve_si.png")
	await _run_until(func(): return main.overlay.visible, 40.0)
	print("Công tử tới quầy: bảng mở = ", main.overlay.visible, ", khách thường còn = ", nur._role_count(""))
	await _shot("an_3_cong_tu.png")
	var coins0: int = gs.coins
	var b: Button = _find_button(main.overlay, "Bán hết cho công tử")
	b.pressed.emit()
	await get_tree().process_frame
	print("Xu: ", coins0, " -> ", gs.coins, " | còn cây bán: ", nur._open_stands().size(), " | đã gặp: ", gs.hidden_met)
	await _shot("an_4_mua_het.png")
	_find_button(main.overlay, "Tiếp tục").pressed.emit()
	await _run(1.0)
	await _shot("an_5_ra_ve.png")
	await _run_until(func(): return nur.event == "", 20.0)
	print("Sự kiện kết thúc: ", nur.event == "", " | khách = ", nur.customers.size())

	# Lần 2 với cây Quý: không tới nữa
	main._close_nursery()
	_fill(2, 3)
	main._open_nursery()
	await _run(0.5)
	print("Quý lần 2 -> sự kiện: '", nur.event, "' (phải rỗng)")

	# Huyền thoại: tới lần nữa
	main._close_nursery()
	_fill(3, 3)
	main._open_nursery()
	await _run(0.5)
	print("Huyền thoại -> ", nur.event, " / ", nur.event_kind)
	await _run_until(func(): return main.overlay.visible, 60.0)
	await _shot("an_6_huyen_thoai.png")
	_find_button(main.overlay, "Bán hết cho công tử").pressed.emit()
	_find_button(main.overlay, "Tiếp tục").pressed.emit()
	await _run_until(func(): return nur.event == "", 20.0)
	print("Đã gặp: ", gs.hidden_met)

	# Bảo kê: shop trống hơn 2 phút
	main._close_nursery()
	main._open_nursery()
	await _run(60.0)
	print("Sau 60 giây trống: ", nur.event, " (phải rỗng)")
	await _run(61.0)
	print("Sau 121 giây trống: ", nur.event)
	await _shot("an_7_bao_ke_di.png")
	await _run_until(func(): return main.overlay.visible, 20.0)
	await _shot("an_8_bao_ke.png")
	var c0: int = gs.coins
	_find_button(main.overlay, "Đánh khứa này luôn").pressed.emit()
	await get_tree().process_frame
	print("Đánh: xu ", c0, " -> ", gs.coins)
	await _shot("an_9_danh.png")
	_find_button(main.overlay, "Tiếp tục").pressed.emit()
	await _run_until(func(): return nur.event == "", 20.0)
	await _run(121.0)
	await _run_until(func(): return main.overlay.visible, 20.0)
	_find_button(main.overlay, "Báo cảnh sát").pressed.emit()
	await get_tree().process_frame
	await _shot("an_10_canh_sat.png")
	_find_button(main.overlay, "Tiếp tục").pressed.emit()
	await _run(1.0)
	await _shot("an_11_doi_do.png")
	await _run_until(func(): return nur.event == "", 20.0)
	print("Xu sau báo cảnh sát: ", gs.coins, " | sự kiện: '", nur.event, "'")
	await _run(121.0)
	await _run_until(func(): return main.overlay.visible, 20.0)
	var c1: int = gs.coins
	_find_button(main.overlay, "Đóng tiền bảo kê").pressed.emit()
	await get_tree().process_frame
	print("Đóng tiền: xu ", c1, " -> ", gs.coins)
	await _shot("an_12_dong_tien.png")
	_find_button(main.overlay, "Tiếp tục").pressed.emit()
	await _run(1.0)
	await _shot("an_13_ngoan.png")
	await _run_until(func(): return nur.event == "", 20.0)
	print("Sự kiện xong: '", nur.event, "'")
	# lưu và tải lại
	gs.save_game()
	gs.hidden_met = {}
	gs.load_game()
	print("Tải lại khách ẩn đã gặp: ", gs.hidden_met.keys())
	get_tree().quit()


## Xóa chậu cũ và trồng n cây có độ hiếm r, đưa ra trưng bày.
func _fill(r: int, n: int) -> void:
	gs.pots.clear()
	gs.soils.clear()
	for i in n:
		gs.pots.append({})
		gs.soils.append("hiem")
	var Gen = load("res://scripts/genetics.gd")
	var made := 0
	var tries := 0
	while made < n and tries < 200000:
		tries += 1
		var g: Dictionary = Gen.random_genome(3)
		if r == 3:   # gắn một kiểu hiếm bậc 3 thuần chủng
			var Data = load("res://scripts/data.gd")
			for part in Data.PARTS:
				for id in Data.TRAITS[part]:
					if Data.TRAITS[part][id]["hiem"] >= 3 and randf() < 0.5:
						g[part] = [id, id]
		if Gen.rarity(g) != r:
			continue
		gs.seeds.append({"gen": g, "bo_me": []})
		gs.plant_seed(made, gs.seeds.size() - 1)
		gs.water(made)
		gs.pots[made]["tien_do"] = 99999.0
		gs.set_display(made, true)
		made += 1
	print("Trồng ", made, " cây độ hiếm ", r)


func _run(sec: float) -> void:
	var t := 0.0
	while t < sec:
		nur._process(0.05)
		t += 0.05
	await get_tree().process_frame


func _run_until(cond: Callable, max_sec: float) -> void:
	var t := 0.0
	while t < max_sec and not cond.call():
		nur._process(0.05)
		t += 0.05
	await get_tree().process_frame


func _find_button(root: Node, text: String) -> Button:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Button and n.text == text and not n.is_queued_for_deletion():
			return n
		stack.append_array(n.get_children())
	push_error("Không thấy nút " + text)
	return Button.new()


func _shot(name: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/" + name)
