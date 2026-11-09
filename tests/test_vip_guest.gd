extends Node
## Công tử ghé như khách thường sau 7 phút shop còn cây: chỉ mua cây từ Hiếm, tỉ lệ gấp đôi, thẻ chân dung ở quầy.

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var gs = get_node("/root/GameState")
	var Gen = load("res://scripts/genetics.gd")
	gs.new_game()
	gs.away_report = ""
	gs.pots.clear()
	gs.soils.clear()
	gs.seeds.clear()
	var want := [0, 1]
	var made := 0
	for i in 2:
		gs.pots.append({})
		gs.soils.append("hiem")
	while made < 2:
		var g: Dictionary = Gen.random_genome(2)
		if Gen.rarity(g) != want[made]:
			continue
		gs.seeds.append({"gen": g, "bo_me": []})
		gs.plant_seed(made, gs.seeds.size() - 1)
		gs.water(made)
		gs.pots[made]["tien_do"] = 12000.0
		gs.set_display(made, true)
		made += 1
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._open_nursery()
	var nur = main.nursery
	var t := 0.0
	while t < 410.0:
		nur.spawn_timer = 1e9
		nur._update_events(0.05)
		t += 0.05
	print("Sau 410 giây: công tử khách = ", nur.seen_events.has("cong_tu_khach"))
	while t < 425.0:
		nur.spawn_timer = 1e9
		nur._update_events(0.05)
		t += 0.05
	var guest = null
	for c in nur.customers:
		if c["cust"].get("cong_tu", false):
			guest = c
	print("Sau 425 giây: công tử vào như khách = ", guest != null, " | mã nhân vật ", guest["node"].variant if guest else "")
	# tỉ lệ mua
	var cust: Dictionary = guest["cust"].duplicate()
	var normal := cust.duplicate()
	normal.erase("cong_tu")
	for k in nur._open_stands():
		var p: Dictionary = gs.pots[nur.stands[k]["pot"]]
		print("Cây độ hiếm %d: khách thường %.2f, công tử %.2f" % [Gen.rarity(p["gen"]), gs.buy_chance(p, gs.asking_price(p), normal, ""), gs.buy_chance(p, gs.asking_price(p), cust, "")])
	# khung ở quầy
	var rare_k := -1
	for k in nur._open_stands():
		if Gen.rarity(gs.pots[nur.stands[k]["pot"]]["gen"]) >= 1:
			rare_k = k
	guest["choice"] = rare_k
	main._open_chat(guest)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/cong_tu_khach.png")
	print("Lần 2 trong cùng lần mở shop: ", nur.seen_events.has("cong_tu_khach"), " (đã đánh dấu, không ghé lại)")
	get_tree().quit()
