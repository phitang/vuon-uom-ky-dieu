extends Node
## Dụng cụ mới: kéo súng thụ phấn bằng chuột thật (nạp phấn, thụ phấn), hạt lai hiện ký hiệu, chạm thu hạt,
## hoạt ảnh bình tưới, túi đất đổi hình. Chụp ảnh từng bước.

var out := ""
var main
var gs


func _ready() -> void:
	out = OS.get_environment("SHOT_DIR")
	gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	gs.coins = 500
	for i in 3:
		gs.pots.append({})
		gs.soils.append("thuong")
	var looks := [["cuc", "vang"], ["hong", "do"], ["tulip", "tim"], ["cuc", "xanh"], ["sao", "trang"]]
	for i in looks.size():
		var g := {"hoa": [looks[i][0], looks[i][0]], "la": ["tron", "tron"], "than": ["thang", "thang"], "mau": [looks[i][1], looks[i][1]], "co": ["vua", "vua"]}
		gs.seeds.append({"gen": g, "bo_me": []})
		gs.plant_seed(i, gs.seeds.size() - 1)
		gs.water(i)
		gs.pots[i]["tien_do"] = 12000.0
	gs.pots[5] = {}
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame

	# 1) kéo súng tới cây 0 (nạp phấn)
	var gun: Control = main.tool_buttons["sung"]
	await _drag(gun.get_global_rect().get_center(), _slot_center(0), "dung_cu_1_keo_sung.png")
	print("Nạp phấn: ", not main.pollen_gen.is_empty(), " | súng hiện lại: ", main.tool_icons["sung"].modulate.a, " | ", main.status_l.text)
	await _wait(0.5)
	await _shot("dung_cu_2_sung_da_nap.png")
	# 2) kéo tới cây 1 (thụ phấn)
	await _drag(gun.get_global_rect().get_center(), _slot_center(1), "")
	print("Thụ phấn: ", gs.has_pod(1), " | xu=", gs.coins, " | ", main.status_l.text)
	gs._advance(601.0)
	main._refresh_all()
	await _shot("dung_cu_3_co_hat.png")
	var before: int = gs.seeds.size()
	main._on_slot(1)
	print("Chạm thu hạt: ", before, " -> ", gs.seeds.size(), " | ", main.status_l.text)
	# 3) tưới nước có hoạt ảnh
	main._on_slot(2)
	main._use_tool("nuoc")
	await _wait(0.85)
	await _shot("dung_cu_4_tuoi.png")
	# 4) túi đất theo loại tốt nhất
	main._on_slot(5)
	await _shot("dung_cu_5_tui_dat_thuong.png")
	gs.soils_owned["tot"] = true
	main._refresh_all()
	await _shot("dung_cu_6_tui_dat_tot.png")
	gs.soils_owned["hiem"] = true
	main._refresh_all()
	main._use_tool("dat")
	print("Túi đất hiếm: ", main.tool_icons["dat"].kind, " | chậu 6 đất = ", gs.soils[5])
	await _shot("dung_cu_7_tui_dat_hiem.png")
	get_tree().quit()


func _slot_center(i: int) -> Vector2:
	var r: Rect2 = main.slots[i].get_global_rect()
	return Vector2(r.get_center().x, r.end.y - r.size.y * 0.3)


## Kéo chuột thật từ a tới b (nhấn, di chuyển từng bước, thả). Chụp ảnh giữa chừng nếu có tên.
func _drag(a: Vector2, b: Vector2, shot_name: String) -> void:
	_mouse_button(a, true)
	await get_tree().process_frame
	for k in 25:
		var p := a.lerp(b, (k + 1) / 25.0)
		var mm := InputEventMouseMotion.new()
		mm.position = p
		mm.global_position = p
		mm.relative = (b - a) / 25.0
		mm.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(mm)
		await get_tree().process_frame
		if k == 20 and shot_name != "":
			await _shot(shot_name)
	_mouse_button(b, false)
	await get_tree().process_frame
	await get_tree().process_frame


func _mouse_button(p: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = p
	ev.global_position = p
	if pressed:
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(ev)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _shot(name: String) -> void:
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/" + name)
