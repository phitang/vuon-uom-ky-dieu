extends Node
## Chụp vườn có đủ các loài hoa vẽ tay, nhiều màu và giai đoạn.

func _ready() -> void:
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	for i in 12:
		gs.pots.append({})
		gs.soils.append("thuong")
	var plants := [
		["tulip", "do", 12000.0], ["chuong", "tim", 12000.0], ["sao", "trang", 12000.0], ["lan", "hongnhat", 12000.0], ["hong", "do", 12000.0],
		["tulip", "vang", 12000.0], ["chuong", "xanh", 12000.0], ["sao", "vang", 12000.0], ["rong", "cauvong", 12000.0], ["rong", "trang", 5000.0],
		["sen", "trang", 12000.0], ["rong", "do", 12000.0], ["sen", "hongnhat", 12000.0], ["rong", "tim", 12000.0], ["sen", "trang", 5000.0]]
	for i in plants.size():
		var sp: String = plants[i][0]
		var col: String = plants[i][1]
		var g := {"hoa":[sp, sp],"la":["tron","tron"],"than":["thang","thang"],"mau":[col, col],"co":["vua","vua"]}
		gs.seeds.append({"gen": g, "bo_me": []})
		gs.plant_seed(i, gs.seeds.size() - 1)
		gs.water(i)
		gs.pots[i]["tien_do"] = plants[i][2]
	gs._advance(1.0)
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main._close_popup()
	for k in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/10_cac_loai.png")
	get_tree().quit()
