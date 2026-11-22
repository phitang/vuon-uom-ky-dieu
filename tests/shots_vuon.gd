extends Node
## Chụp nhà kính với cây ở nhiều giai đoạn (kiểm tra chậu đặt giữa đế lót, cây không bị chậu che).

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	for i in 12:
		gs.pots.append({})
		gs.soils.append("thuong")
	var looks := [["hong","do"],["cuc","vang"],["xr_tron","hongnhat"],["mai","do"],["bonsai","do"],["xr_cao","trang"],["tulip","tim"],["lan","xanh"],["sen","hongnhat"],["bonsai","vang"],["sao","cam"],["chuong","xanh"],["cuc","tim"],["hong","trang"],["rong","do"]]
	var prog := [0.0, 2000.0, 12000.0, 12000.0, 12000.0, 12000.0, 5000.0, 12000.0, 12000.0, 7000.0, 12000.0, 12000.0, 400.0, 1500.0, 12000.0]
	for i in looks.size():
		var g := {"hoa":[looks[i][0],looks[i][0]],"la":["tron","tron"],"than":["thang","thang"],"mau":[looks[i][1],looks[i][1]],"co":["vua","vua"]}
		gs.seeds.append({"gen": g, "bo_me": []})
		gs.plant_seed(i, gs.seeds.size() - 1)
		gs.water(i)
		gs.pots[i]["tien_do"] = prog[i]
	gs._advance(1.0)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for k in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/vuon.png")
	get_tree().quit()
