extends Node
## Chụp khung trò chuyện ở quầy với từng chân dung khách.

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	var g := {"hoa":["hong","hong"],"la":["tron","tron"],"than":["thang","thang"],"mau":["do","do"],"co":["vua","vua"]}
	gs.seeds.append({"gen": g, "bo_me": []})
	gs.plant_seed(0, 0)
	gs.water(0)
	gs.pots[0]["tien_do"] = 12000.0
	gs.set_display(0, true)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._open_nursery()
	var nur = main.nursery
	nur.spawn_timer = 9999.0
	for v in ["khach_den", "khach_hong", "be_gai", "khach_tim"]:
		nur._spawn_customer()
		var c = nur.customers.back()
		c["node"].setup(c["cust"]["type"], 0, v)
		c["choice"] = 0
		main._open_chat(c)
		await _shot(out + "/chan_dung_%s.png" % v)
		main._close_popup()
		await get_tree().process_frame
	get_tree().quit()

func _shot(path: String) -> void:
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
