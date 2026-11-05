extends Node
## Súng thụ phấn: tự thụ phấn ra hạt giống hệt cây; cây đang kết hạt vẫn cho phấn.

func _ready() -> void:
	var gs = get_node("/root/GameState")
	var Gen = load("res://scripts/genetics.gd")
	gs.new_game()
	gs.away_report = ""
	gs.coins = 500
	gs.seeds.clear()
	gs.soils = ["thuong", "thuong", "thuong"]
	for i in 3:
		gs.seeds.append({"gen": Gen.random_genome(1), "bo_me": []})
		gs.plant_seed(i, 0)
		gs.water(i)
		gs.pots[i]["tien_do"] = 12000.0
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	# tự thụ phấn cây 0
	main._drop_seed(0, {"sung": true})
	main._drop_seed(0, {"sung": true})
	print("Tự thụ phấn: ", gs.has_pod(0), " | ", main.status_l.text)
	# cây 0 đang kết hạt vẫn cho phấn -> thụ cho cây 1
	main._drop_seed(0, {"sung": true})
	print("Lấy phấn cây đang kết hạt: ", not main.pollen_gen.is_empty(), " | ", main.status_l.text)
	main._drop_seed(1, {"sung": true})
	print("Thụ cho cây 1: ", gs.has_pod(1))
	# thả vào cây đã thụ phấn
	main._drop_seed(2, {"sung": true})
	main._drop_seed(0, {"sung": true})
	print("Thả vào cây đã thụ: ", main.status_l.text)
	gs._advance(901.0)
	gs.harvest_pod(0)
	var same := true
	for s in gs.seeds:
		if JSON.stringify(s["gen"]) != JSON.stringify(gs.pots[0]["gen"]):
			same = false
	print("Hạt tự thụ: ", gs.seeds.size(), " hạt, giống hệt cây mẹ = ", same, " | tên ", Gen.variety_name(gs.seeds[0]["gen"]), " = ", Gen.variety_name(gs.pots[0]["gen"]))
	get_tree().quit()
