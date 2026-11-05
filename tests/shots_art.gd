extends Node
## Chụp vườn toàn hoa cúc nhiều màu và giai đoạn để kiểm tra ảnh vẽ tay.

func _ready() -> void:
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	for i in 6:
		gs.pots.append({})
		gs.soils.append("thuong")
	var mau := ["vang", "do", "tim", "xanh", "cauvong", "hongnhat", "trang", "cam", "do"]
	var prog := [12000.0, 12000.0, 12000.0, 12000.0, 12000.0, 12000.0, 5000.0, 1000.0, 30000.0]
	for i in 9:
		var g := {"hoa":["cuc","cuc"],"la":["tron","tron"],"than":["thang","thang"],"mau":[mau[i], mau[i]],"co":["vua","vua"]}
		gs.seeds.append({"gen": g, "bo_me": []})
		gs.plant_seed(i, gs.seeds.size() - 1)
		gs.pots[i]["tien_do"] = prog[i]
	gs.pots[8]["heo"] = true
	gs._advance(1.0)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main._close_popup()
	for k in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/8_cuc.png")
	get_tree().quit()
