extends Node
## Thử cử chỉ trên túi hạt bằng sự kiện chuột/chạm thật: lướt đổi trang, chạm chọn, kéo hạt vào chậu.

const Gen := preload("res://scripts/genetics.gd")
var main: Control
var gs: Node

func _ready() -> void:
	gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	gs.seed_bags = 2
	for i in 9:
		gs.seeds.append({"gen": Gen.random_genome(0), "bo_me": []})
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames()
	var bag: Control = main.seed_bag
	var r: Rect2 = bag.get_global_rect()
	print("Hạt: ", gs.seeds.size(), "/", gs.seed_capacity(), " trang: ", bag.pages())
	# lướt sang trái -> trang 2
	await _drag(r.get_center() + Vector2(80, 0), r.get_center() + Vector2(-90, 0))
	print("Sau khi lướt trái: trang ", bag.page + 1)
	# chạm hạt đầu trang 2 (hạt số 9)
	await _tap(r.position + Vector2(48, 30))
	print("Chạm chọn: hạt ", main.selected_seed + 1)
	# lướt phải -> trang 1
	await _drag(r.get_center() + Vector2(-80, 0), r.get_center() + Vector2(90, 0))
	print("Sau khi lướt phải: trang ", bag.page + 1)
	# kéo hạt 2 ra chậu 3 (chậu có đất)
	var to: Vector2 = main.slots[2].get_global_rect().get_center()
	var before: int = gs.seeds.size()
	await _drag(r.position + Vector2(140, 30), to)
	print("Kéo hạt vào chậu 3: có cây = ", not gs.pots[2].is_empty(), " | hạt ", before, " -> ", gs.seeds.size())
	# túi đầy: mua hạt bị chặn
	gs.coins = 5000
	while gs.seed_room() > 0:
		gs.seeds.append({"gen": Gen.random_genome(0), "bo_me": []})
	print("Mua hạt khi túi đầy: ", gs.buy("hat_thuong"))
	print("Mua túi hạt: ", gs.buy("tui_hat"), " sức chứa ", gs.seed_capacity(), " xu ", gs.coins)
	print("XONG")
	get_tree().quit()

func _frames() -> void:
	for i in 3:
		await get_tree().process_frame

func _btn(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(e)

func _move(pos: Vector2, rel: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.relative = rel
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(e)

func _drag(a: Vector2, b: Vector2) -> void:
	_btn(a, true)
	await get_tree().process_frame
	for t in range(1, 13):
		var p := a.lerp(b, t / 12.0)
		_move(p, (b - a) / 12.0)
		await get_tree().process_frame
	_btn(b, false)
	await get_tree().create_timer(0.35).timeout

func _tap(p: Vector2) -> void:
	_btn(p, true)
	await get_tree().process_frame
	_btn(p, false)
	await _frames()
