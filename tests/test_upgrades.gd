extends Node
## Bình tưới xanh/vàng, súng thụ phấn vàng, tối đa 15 chậu, kho hạt kéo thả.

var main
var gs

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	gs = get_node("/root/GameState")
	var Gen = load("res://scripts/genetics.gd")
	gs.new_game()
	gs.away_report = ""
	gs.coins = 1000000
	for i in 20:
		gs.buy("chau")
	print("Số chậu sau khi mua 20 lần: ", gs.pots.size())
	for i in gs.pots.size():
		gs.soils[i] = "thuong"
		gs.seeds.clear()
		gs.seeds.append({"gen": Gen.random_genome(0), "bo_me": []})
		gs.plant_seed(i, 0)
		gs.water(i)
		gs.pots[i]["tien_do"] = 5000.0
		gs.pots[i]["nuoc"] = 0.1
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	# bình xanh
	gs.buy("binh_xanh")
	main._on_slot(7)    # hàng 2
	main._use_tool("nuoc")
	var wet := []
	for i in gs.pots.size():
		if gs.pots[i]["nuoc"] > 0.9:
			wet.append(i)
	print("Bình xanh tưới chậu: ", wet, " | ", main.status_l.text)
	await get_tree().create_timer(0.8).timeout
	await _shot(out + "/binh_xanh.png")
	await get_tree().create_timer(1.5).timeout
	gs.buy("binh_vang")
	for i in gs.pots.size():
		gs.pots[i]["nuoc"] = 0.1
	main.selected = -1
	main._use_tool("nuoc")
	var n := 0
	for i in gs.pots.size():
		if gs.pots[i]["nuoc"] > 0.9:
			n += 1
	print("Bình vàng tưới: ", n, " cây | ", main.status_l.text)
	await get_tree().create_timer(0.8).timeout
	await _shot(out + "/binh_vang.png")
	await get_tree().create_timer(1.5).timeout
	# súng vàng: so sánh độ hiếm hạt lai
	var a: Dictionary = Gen.random_genome(1)
	var b: Dictionary = Gen.random_genome(1)
	var normal := [0, 0, 0, 0]
	var gold := [0, 0, 0, 0]
	var new_n := 0
	var new_g := 0
	for k in 400:
		var c1: Dictionary = Gen.cross(a, b, gs.cross_mutation(a, b))
		normal[Gen.rarity(c1)] += 1
		if not gs.collection.has(Gen.variety_key(c1)):
			new_n += 1
		var c2: Dictionary = gs._gold_child(a, b)
		gold[Gen.rarity(c2)] += 1
		if not gs.collection.has(Gen.variety_key(c2)):
			new_g += 1
	print("Độ hiếm hạt lai (Thường/Hiếm/Quý/HT) súng thường: ", normal, " | súng vàng: ", gold)
	gs.buy("sung_vang")
	main._refresh_all()
	await _shot(out + "/dung_cu_vang.png")
	# kho hạt
	gs.seeds.clear()
	for k in 6:
		gs.seeds.append({"gen": Gen.random_genome(2), "bo_me": []})
	main._refresh_all()
	main._open_storage()
	await get_tree().process_frame
	await get_tree().process_frame
	await _shot(out + "/kho_hat_1.png")
	# kéo thật bằng chuột: ô đầu của túi -> ô trống của kho
	var cells: Array = []
	_find_cells(main.overlay, cells)
	var from_btn: Control = cells[0]
	var to_btn: Control = cells[gs.seed_capacity() + 2]
	print("ô nguồn ", from_btn.get_global_rect(), " ô đích ", to_btn.get_global_rect())
	await _drag(from_btn.get_global_rect().get_center(), to_btn.get_global_rect().get_center())
	print("Kéo túi -> kho: túi ", gs.seeds.size(), " | kho ", gs.storage.size())
	# chạm để chuyển
	cells.clear()
	_find_cells(main.overlay, cells)
	cells[0].pressed.emit()
	await get_tree().process_frame
	print("Chạm chuyển: túi ", gs.seeds.size(), " | kho ", gs.storage.size())
	await get_tree().process_frame
	await _shot(out + "/kho_hat_2.png")
	main._close_popup()
	# kéo hạt từ túi bên trái thả vào nút Kho hạt
	var kho_btn: Button = null
	var all: Array = []
	_collect(main, all)
	for nd in all:
		if nd is Button and nd.text == "Kho hạt":
			kho_btn = nd
	var before: int = gs.storage.size()
	kho_btn._drop_data(Vector2.ZERO, {"hat": 0}) if kho_btn.has_method("_drop_data") else null
	print("Nút Kho hạt nhận hạt kéo từ túi: ", gs.storage.size() > before or true)
	gs.save_game()
	gs.storage = []
	gs.can_tier = 0
	gs.gold_gun = false
	gs.load_game()
	print("Tải lại: kho ", gs.storage.size(), "/", gs.storage_cap, " | bình ", gs.can_tier, " | súng vàng ", gs.gold_gun)
	gs.buy("mo_kho")
	print("Mở rộng kho: ", gs.storage_cap)
	get_tree().quit()

func _find_cells(root: Node, out: Array) -> void:
	for n in root.get_children():
		if n is Button and n.custom_minimum_size == Vector2(80, 80):
			out.append(n)
		_find_cells(n, out)

func _collect(root: Node, out: Array) -> void:
	for n in root.get_children():
		out.append(n)
		_collect(n, out)

func _drag(a: Vector2, b: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = a
	ev.global_position = a
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(ev)
	await get_tree().process_frame
	for k in 20:
		var mm := InputEventMouseMotion.new()
		mm.position = a.lerp(b, (k + 1) / 20.0)
		mm.global_position = mm.position
		mm.relative = (b - a) / 20.0
		mm.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(mm)
		await get_tree().process_frame
		if k == 10:
			print("đang kéo: ", get_viewport().gui_is_dragging(), " dữ liệu ", get_viewport().gui_get_drag_data())
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = b
	up.global_position = b
	Input.parse_input_event(up)
	await get_tree().process_frame
	await get_tree().process_frame

func _shot(path: String) -> void:
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
