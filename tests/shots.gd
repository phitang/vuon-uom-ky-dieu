extends Node
## Chụp màn hình các phần giao diện. Chạy tests/shots.tscn (không dùng --headless).

var main: Control
var gs: Node
var out_dir := ""

func _ready() -> void:
	out_dir = OS.get_environment("SHOT_DIR")
	gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	gs.coins = 1240
	gs.revenue = 600
	gs.fertilizer = 3
	for i in 12:
		gs.pots.append({})
		gs.soils.append("thuong")
	var looks := [
		["cuc","vang"],["cuc","do"],["cuc","tim"],["hong","do"],["cuc","xanh"],
		["sao","tim"],["cuc","hongnhat"],["cuc","trang"],["cuc","cam"],["lan","xanh"],
		["cuc","cauvong"],["cuc","vang"],["cuc","do"],["tulip","cam"],["cuc","tim"]]
	var prog := [12000.0, 12000.0, 15000.0, 12000.0, 9500.0, 12000.0, 5000.0, 1000.0, 12000.0, 12000.0, 30000.0, 100.0, 12000.0, 12000.0, 3000.0]
	for i in looks.size():
		var g := {"hoa":[looks[i][0],looks[i][0]],"la":["tron","tron"],"than":["thang","thang"],"mau":[looks[i][1],looks[i][1]],"co":["vua","vua"]}
		gs.seeds.append({"gen": g, "bo_me": []})
		gs.plant_seed(i, gs.seeds.size() - 1)
		gs.water(i)
		gs.pots[i]["tien_do"] = prog[i]
	gs.pots[4]["nuoc"] = 0.0
	gs.seed_bags = 3
	for i in 11:
		gs.seeds.append({"gen": Gen.random_genome(1), "bo_me": []})
	gs._advance(1.0)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._on_slot(2)
	await _shot("1_nha_kinh")
	main._drop_seed(2, {"sung": true})
	await _shot("2_co_phan")
	main._unload_gun()
	main._open_price_editor(2)
	await _shot("3_dat_gia")
	main._close_popup()
	main._seed_page(1)
	await get_tree().create_timer(0.4).timeout
	await _shot("4_tui_hat_trang2")
	main._seed_page(-1)
	await get_tree().create_timer(0.4).timeout
	main._open_shop()
	await _shot("5_cua_hang")
	main._open_book()
	await _shot("6_so_tay")
	main._open_menu()
	await _shot("7_menu")
	get_tree().quit()

const Gen := preload("res://scripts/genetics.gd")

func _shot(name: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir + "/" + name + ".png")
