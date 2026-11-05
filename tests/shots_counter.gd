extends Node
## Khách đi tới quầy rồi mở trò chuyện: chụp cả hai để so nhân vật có giống nhau không.

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	for i in 2:
		gs.pots.append({})
		gs.soils.append("thuong")
	for i in 3:
		var g := {"hoa":["cuc","cuc"],"la":["tron","tron"],"than":["thang","thang"],"mau":[["tim","vang","do"][i], ["tim","vang","do"][i]],"co":["vua","vua"]}
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
	var vars := []
	for k in ["khach_xanh", "khach_do", "khach_tim"]:
		nur._spawn_customer()
		var c = nur.customers.back()
		c["node"].setup(c["cust"]["type"], 0, k)
		vars.append(k)
	var c0 = nur.customers[0]
	c0["choice"] = 0
	nur._walk_to(c0, nur._counter_spot(), "counter")
	for step in 500:
		nur._update_customer(c0, 0.05)
		if c0["state"] == "chat":
			break
	main._close_popup.call()  # ẩn bảng để chụp cảnh khách đứng ở quầy
	nur.counter_busy = true
	await _shot(out + "/counter_scene.png")
	main._open_chat(c0)
	await _shot(out + "/counter_chat.png")
	var cv: Control = null
	var stack: Array = [main.overlay]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.get_script() == load("res://scripts/customer_view.gd"):
			cv = n
		stack.append_array(n.get_children())
	print("Khách đi tới quầy: ", c0["node"].variant, " | khách trong trò chuyện: ", cv.variant, " | giống nhau = ", cv.variant == c0["node"].variant)
	get_tree().quit()

func _shot(path: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
