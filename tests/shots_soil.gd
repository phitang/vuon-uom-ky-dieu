extends Node
## Chụp giao diện đất + thử kéo thả hạt bằng sự kiện chuột thật.

const Gen := preload("res://scripts/genetics.gd")
var main: Control
var gs: Node

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	gs.coins = 263400
	gs.revenue = 30000
	gs.soils_owned["tot"] = true
	for i in 7:
		gs.pots.append({})
		gs.soils.append("")
	gs.soils[3] = "tot"
	gs.soils[4] = "hiem"
	gs.soils_owned["hiem"] = true
	var looks := [["cuc","vang"],["lan","xanh"],["cuc","do"]]
	for i in 3:
		var g := {"hoa":[looks[i][0],looks[i][0]],"la":["tron","tron"],"than":["thang","thang"],"mau":[looks[i][1],looks[i][1]],"co":["vua","vua"]}
		gs.seeds.append({"gen": g, "bo_me": []})
		gs.plant_seed(i, gs.seeds.size() - 1)
		gs.water(i)
		gs.pots[i]["tien_do"] = 12000.0
	gs.pots[1]["suc_khoe"] = 0.62
	gs.soils[5] = "thuong"
	for i in 4:
		gs.seeds.append({"gen": Gen.random_genome(1), "bo_me": []})
	gs._advance(1.0)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames()
	main._on_slot(1)
	await _shot(out + "/s1_dat.png")
	# kéo hạt đầu tiên vào chậu 5 (có đất thường)
	var from: Vector2 = main.seed_bag.get_global_rect().position + Vector2(48, 30)
	var to: Vector2 = main.slots[5].get_global_rect().get_center()
	_mouse_button(from, true)
	await _frames()
	for t in range(1, 11):
		_mouse_move(from.lerp(to, t / 10.0))
		await get_tree().process_frame
	await _shot(out + "/s2_dang_keo.png")
	_mouse_button(to, false)
	await _frames()
	print("Sau khi thả: chậu 6 có cây = ", not gs.pots[5].is_empty(), " | ", main.status_l.text)
	main._on_slot(6)
	await _shot(out + "/s3_chau_khong_dat.png")
	get_tree().quit()

func _mouse_button(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(e)

func _mouse_move(pos: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	e.relative = Vector2(8, 8)
	Input.parse_input_event(e)

func _frames() -> void:
	for i in 3:
		await get_tree().process_frame

func _shot(path: String) -> void:
	await _frames()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
