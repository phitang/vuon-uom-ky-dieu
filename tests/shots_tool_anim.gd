extends Node
## Hoạt ảnh xúc đất và cắt kéo; sức khỏe khi đất không hợp; phân bón hồi sức khỏe.

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var gs = get_node("/root/GameState")
	var Gen = load("res://scripts/genetics.gd")
	gs.new_game()
	gs.away_report = ""
	gs.seeds.clear()
	gs.fertilizer = 5
	for i in gs.pots.size():
		gs.soils[i] = "thuong"
	var g := {"hoa": ["hong", "hong"], "la": ["tron", "tron"], "than": ["thang", "thang"], "mau": ["do", "do"], "co": ["vua", "vua"]}
	gs.seeds.append({"gen": g, "bo_me": []})
	gs.plant_seed(0, 0)
	gs.water(0)
	gs.pots[0]["tien_do"] = 30000.0     # cây già
	gs.soils[1] = ""
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	# xúc đất vào chậu 2
	main._on_slot(1)
	gs.soils_owned["tot"] = true
	main._use_tool("dat")
	print("Ngay sau bấm: đất chậu 2 = '", gs.soils[1], "' | bận = ", main.tool_busy)
	await get_tree().create_timer(0.75).timeout
	await _shot(out + "/anim_dat_1.png")
	await get_tree().create_timer(0.35).timeout
	await _shot(out + "/anim_dat_2.png")
	await get_tree().create_timer(1.3).timeout
	print("Sau hoạt ảnh: đất chậu 2 = '", gs.soils[1], "' | bận = ", main.tool_busy)
	# kéo cắt cây già
	main._on_slot(0)
	var n0: int = gs.seeds.size()
	main._use_tool("keo")
	await get_tree().create_timer(0.6).timeout
	await _shot(out + "/anim_keo_1.png")
	print("Đang cắt: cây còn = ", not gs.pots[0].is_empty())
	await get_tree().create_timer(0.5).timeout
	await _shot(out + "/anim_keo_2.png")
	await get_tree().create_timer(1.2).timeout
	print("Sau cắt: hạt ", n0, " -> ", gs.seeds.size(), " | chậu trống = ", gs.pots[0].is_empty())
	# sức khỏe khi đất không hợp
	var rare := {"hoa": ["lan", "lan"], "la": ["tron", "tron"], "than": ["thang", "thang"], "mau": ["do", "do"], "co": ["vua", "vua"]}
	gs.seeds.append({"gen": rare, "bo_me": []})
	gs.soils[2] = "thuong"
	gs.plant_seed(2, gs.seeds.size() - 1)
	gs.water(2)
	gs.pots[2]["tien_do"] = 4000.0
	print("Lan cần đất: ", gs.soil_needed(gs.pots[2]), " | độ hiếm ", Gen.rarity(rare), " | thiếu ", gs.soil_mismatch(2), " cấp")
	for h in 5:
		gs.pots[2]["nuoc"] = 1.0
		gs._advance(3600.0)
	print("Sau 5 giờ đất không hợp: sức khỏe = %d%%" % int(gs.pots[2]["suc_khoe"] * 100))
	main._on_slot(2)
	main._use_tool("phan")
	print("Bón phân: sức khỏe = %d%% | %s" % [int(gs.pots[2]["suc_khoe"] * 100), main.status_l.text])
	gs.pots[2]["tien_do"] = 12000.0
	gs.pots[2]["suc_khoe"] = 0.6
	main._use_tool("phan")
	print("Cây ra hoa yếu, bón phân: %d%% | %s" % [int(gs.pots[2]["suc_khoe"] * 100), main.status_l.text])
	get_tree().quit()

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
