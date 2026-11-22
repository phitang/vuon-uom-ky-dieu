extends Node
## Bảng Kho hạt: chạm một hạt để chuyển, kéo hạt (hạt bám theo ngón tay) để chuyển.

const Gen := preload("res://scripts/genetics.gd")

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	for k in 6:
		gs.seeds.append({"gen": Gen.random_genome(2), "bo_me": []})
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._refresh_all()
	main._open_storage()
	for i in 3:
		await get_tree().process_frame
	var cells := _cells(main.overlay)
	await _tap(cells[0].get_global_rect().get_center())
	print("Chạm chuyển: túi ", gs.seeds.size(), " | kho ", gs.storage.size())
	for i in 3:
		await get_tree().process_frame
	cells = _cells(main.overlay)
	await _drag(cells[0].get_global_rect().get_center(), cells[gs.seed_capacity() + 3].get_global_rect().get_center(), out)
	print("Kéo chuyển: túi ", gs.seeds.size(), " | kho ", gs.storage.size())
	for i in 3:
		await get_tree().process_frame
	cells = _cells(main.overlay)
	await _tap(cells[gs.seed_capacity()].get_global_rect().get_center())
	print("Chạm lấy về: túi ", gs.seeds.size(), " | kho ", gs.storage.size())
	main._close_popup()
	# túi hạt ngoài: nút mũi tên đổi túi
	gs.seed_bags = 2
	main._refresh_all()
	await get_tree().process_frame
	var bag: Control = main.seed_bag
	var r: Rect2 = bag._arrow_rect(1)
	await _tap(bag.get_global_transform() * r.get_center())
	print("Bấm mũi tên phải: túi trang ", bag.page + 1, "/", bag.pages())
	for i in 15:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/tui_hat_mui_ten.png")
	await _tap(bag.get_global_transform() * bag._arrow_rect(-1).get_center())
	print("Bấm mũi tên trái: túi trang ", bag.page + 1, "/", bag.pages())
	get_tree().quit()

func _cells(root: Node) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for ch in n.get_children():
			stack.push_front(ch)
			if ch.has_method("_drop_data") and ch is Control and ch.custom_minimum_size == Vector2(80, 80):
				out.append(ch)
	out.sort_custom(func(a, b): return a.global_position.x < b.global_position.x - 200 or (absf(a.global_position.x - b.global_position.x) <= 200 and (a.global_position.y < b.global_position.y or (a.global_position.y == b.global_position.y and a.global_position.x < b.global_position.x))))
	return out

func _btn(p: Vector2, down: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = down
	ev.position = p
	ev.global_position = p
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	Input.parse_input_event(ev)

func _tap(p: Vector2) -> void:
	_btn(p, true)
	await get_tree().process_frame
	_btn(p, false)
	await get_tree().process_frame
	await get_tree().process_frame

func _drag(a: Vector2, b: Vector2, out: String) -> void:
	_btn(a, true)
	await get_tree().process_frame
	for k in 20:
		var mm := InputEventMouseMotion.new()
		mm.position = a.lerp(b, (k + 1) / 20.0)
		mm.global_position = mm.position
		mm.relative = (b - a) / 20.0
		mm.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(mm)
		await get_tree().process_frame
		if k == 12:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out + "/kho_dang_keo.png")
	_btn(b, false)
	await get_tree().process_frame
	await get_tree().process_frame
