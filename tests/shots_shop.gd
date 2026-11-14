extends Node
## Chụp Shop cây cảnh: 10 cây trưng bày, khách đi lại, khách ở quầy.

const Gen := preload("res://scripts/genetics.gd")

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	gs.coins = 4820
	for i in 12:
		gs.pots.append({})
		gs.soils.append("thuong")
	var looks := [["cuc","vang"],["cuc","do"],["cuc","tim"],["hong","do"],["cuc","xanh"],["sao","tim"],["cuc","hongnhat"],["lan","xanh"],["cuc","cauvong"],["tulip","cam"],["cuc","cam"],["cuc","trang"],["hong","vang"],["sao","hongnhat"],["lan","tim"]]
	for i in looks.size():
		var g := {"hoa":[looks[i][0],looks[i][0]],"la":["tron","tron"],"than":["thang","thang"],"mau":[looks[i][1],looks[i][1]],"co":["vua","vua"]}
		gs.seeds.append({"gen": g, "bo_me": []})
		gs.plant_seed(i, gs.seeds.size() - 1)
		gs.water(i)
		gs.pots[i]["tien_do"] = 12000.0
	gs._advance(1.0)
	for i in 15:
		gs.set_display(i, true)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames()
	main._on_slot(0)
	await _shot(out + "/shop0_nha_kinh.png")
	main._open_nursery()
	var nur = main.nursery
	nur.spawn_timer = 9999.0
	for k in 4:
		nur._spawn_customer()
		for step in 30 + k * 22:
			nur._update_customer(nur.customers[k], 0.05)
	nur.stands[3]["sold"] = 120
	nur.refresh()
	await _shot(out + "/shop1_khach.png")
	# một khách ra quầy
	var c = nur.customers[0]
	c["choice"] = 2
	nur._walk_to(c, nur._counter_spot(), "counter")
	for step in 400:
		nur._update_customer(c, 0.05)
		if main.overlay.visible:
			break
	await _shot(out + "/shop2_quay.png")
	get_tree().quit()

func _frames() -> void:
	for i in 3:
		await get_tree().process_frame

func _shot(path: String) -> void:
	await _frames()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
