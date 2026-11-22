extends Node
## Vệ sĩ ghé shop như khách: đi xem vài kệ, nói tìm cậu chủ rồi về, không mua.

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	for i in 6:
		gs.pots.append({})
		gs.soils.append("thuong")
	for i in 6:
		var g := {"hoa":["cuc","cuc"],"la":["tron","tron"],"than":["thang","thang"],"mau":["vang","vang"],"co":["vua","vua"]}
		gs.seeds.append({"gen": g, "bo_me": []})
		gs.plant_seed(i, gs.seeds.size() - 1)
		gs.water(i)
		gs.pots[i]["tien_do"] = 12000.0
	gs._advance(1.0)
	for i in 6:
		gs.set_display(i, true)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._open_nursery()
	var nur = main.nursery
	nur.spawn_timer = 9999.0
	var Data = load("res://scripts/data.gd")
	var found := false
	for t in 200:
		nur.seen_events.erase("ve_si")
		nur._spawn_customer()
		var c: Dictionary = nur.customers.back()
		if c["cust"].get("ve_si", false):
			found = true
			break
		nur.customers.pop_back()["node"].queue_free()
	print("Vệ sĩ xuất hiện: ", found)
	var c: Dictionary = nur.customers.back()
	var coins: int = gs.coins
	var said := []
	var shot := false
	for step in 3000:
		nur._update_customer(c, 0.05)
		if c["node"].bubble != "" and not said.has(c["node"].bubble):
			said.append(c["node"].bubble)
		if c["state"] == "look" and not shot:
			shot = true
			for k in 3:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out + "/ve_si.png")
		if not nur.customers.has(c):
			break
	print("Lời vệ sĩ: ", said)
	print("Đã rời shop: ", not nur.customers.has(c), " | xu không đổi: ", gs.coins == coins, " | không ra quầy: ", c["goal"] != "counter")
	get_tree().quit()
