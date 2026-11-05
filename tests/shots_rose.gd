extends Node
## Chụp vườn toàn hoa cúc nhiều màu và giai đoạn để kiểm tra ảnh vẽ tay.

func _ready() -> void:
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	for i in 12:
		gs.pots.append({})
		gs.soils.append("thuong")
	var mau := ["do", "vang", "tim", "hongnhat", "cauvong", "trang", "xanh", "cam", "do", "do", "tim", "vang", "do", "do", "cam"]
	var prog := [12000.0, 12000.0, 12000.0, 12000.0, 12000.0, 12000.0, 12000.0, 12000.0, 30000.0, 5000.0, 5000.0, 1000.0, 1000.0, 100.0, 12000.0]
	for i in 15:
		var g := {"hoa":["hong","hong"],"la":["tron","tron"],"than":["thang","thang"],"mau":[mau[i], mau[i]],"co":["vua","vua"]}
		gs.seeds.append({"gen": g, "bo_me": []})
		gs.plant_seed(i, gs.seeds.size() - 1)
		gs.water(i)
		gs.pots[i]["tien_do"] = prog[i]
	gs.pots[8]["heo"] = true
	for i in 15:
		gs.water(i)
	gs.pots[14]["suc_khoe"] = 0.3
	gs._advance(1.0)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main._close_popup()
	for k in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/9_hong.png")
	get_tree().quit()
