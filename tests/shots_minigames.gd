extends Node
## Mở 3 mini game bằng chạm thật vào ô cửa sổ, chơi thử và chụp màn hình.

var out := ""
var main

func _tap(p: Vector2) -> void:
	var sp: Vector2 = get_viewport().get_screen_transform() * p
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = sp
		ev.global_position = sp
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		Input.parse_input_event(ev)
		await get_tree().process_frame

func _drag(a: Vector2, b: Vector2) -> void:
	var st: Transform2D = get_viewport().get_screen_transform()
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = st * a
	ev.global_position = st * a
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(ev)
	await get_tree().process_frame
	for k in 6:
		var mm := InputEventMouseMotion.new()
		mm.position = st * a.lerp(b, (k + 1) / 6.0)
		mm.global_position = mm.position
		mm.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(mm)
		await get_tree().process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = st * b
	up.global_position = st * b
	Input.parse_input_event(up)
	await get_tree().process_frame

func _shot(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/" + name + ".png")

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func _open_window(i: int) -> void:
	var gh: Control = main.greenhouse
	await _tap(gh.get_global_transform_with_canvas() * gh.window_rects[i].get_center())
	await get_tree().process_frame

func _ready() -> void:
	out = OS.get_environment("SHOT_DIR")
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	# kiểm tra hạt theo độ hiếm
	var Gen = load("res://scripts/genetics.gd")
	for r in 4:
		var okc := 0
		for k in 30:
			if Gen.rarity(gs.make_seed(r)) == r:
				okc += 1
		print("make_seed rarity ", r, ": ", okc, "/30")
	var avoid := []
	for k in 3:
		var g: Dictionary = gs.make_seed(3, true, avoid)
		avoid.append(Gen.variety_key(g))
	print("3 legendary new keys: ", avoid)
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._hide_title()
	await _shot("mg_vuon")

	# ---- Ghép hoa
	await _open_window(1)
	var fm = main.mini_games[0]
	print("ghep visible: ", fm.visible)
	await _wait(1.2)
	await _shot("mg_ghep")
	var mv: Array = fm._find_move()
	var bv: Control = fm.board_view
	var cs: float = bv.cell
	var a: Vector2 = bv.get_global_transform_with_canvas() * ((Vector2(mv[0]) + Vector2(0.5, 0.5)) * cs)
	var b: Vector2 = bv.get_global_transform_with_canvas() * ((Vector2(mv[1]) + Vector2(0.5, 0.5)) * cs)
	var before: int = fm.moves
	await _drag(a, b)
	await _wait(0.15)
	await _shot("mg_ghep_no")
	await _wait(2.0)
	print("ghep moves ", before, " -> ", fm.moves, " score ", fm.score, " busy ", fm.busy)
	# đặt sẵn bông đặc biệt để xem hình
	fm.board[2][2]["sp"] = "hang_ngang"
	fm.board[4][5]["sp"] = "hang_doc"
	fm.board[6][1]["sp"] = "bom"
	fm.board[6][1]["t"] = -1
	await _shot("mg_ghep_db")
	# thắng 4 vòng liền -> nhận hạt
	var seeds_before: int = gs.seeds.size()
	for k in 4:
		fm.score = fm.target
		fm._after_turn()
		await get_tree().process_frame
		if k < 3:
			fm.close_modal()
			fm._start_level()
	await _shot("mg_ghep_thuong")
	print("ghep wins ", fm.wins, " level ", fm.level, " seeds ", seeds_before, " -> ", gs.seeds.size())
	fm.close_modal()
	fm._start_level()
	fm._go_back()
	await get_tree().process_frame

	# ---- Cờ caro
	await _open_window(2)
	var cr = main.mini_games[1]
	print("caro visible: ", cr.visible, " turn ", cr.turn)
	var cv: Control = cr.view
	var ccs: float = cv.cell
	for mvv in [Vector2i(7, 7), Vector2i(8, 8), Vector2i(6, 8)]:
		while cr.turn != cr.ME and not cr.over:
			await get_tree().process_frame
		await _tap(cv.get_global_transform_with_canvas() * ((Vector2(mvv) + Vector2(0.5, 0.5)) * ccs))
		await _wait(0.7)
	await _shot("mg_caro")
	var stones: int = cr._stones()
	print("caro stones after 3 taps: ", stones)
	# thắng: đặt sẵn 4 quân rồi chạm quân thứ 5
	cr.new_game()
	cr.turn = cr.ME
	for c in 4:
		cr.grid[2][c + 2] = cr.ME
	cr.grid[5][5] = cr.AI
	seeds_before = gs.seeds.size()
	await _tap(cv.get_global_transform_with_canvas() * ((Vector2(6, 2) + Vector2(0.5, 0.5)) * ccs))
	await _wait(0.2)
	await _shot("mg_caro_thang")
	print("caro wins ", cr.wins, " seeds ", seeds_before, " -> ", gs.seeds.size())
	# máy có chặn hàng 4 không?
	cr.close_modal()
	cr.new_game()
	for c in 3:
		cr.grid[9][c + 4] = cr.ME
	cr.grid[0][0] = cr.AI
	var bm: Vector2i = cr.best_move()
	print("AI blocks open three at: ", bm, " (expect (3,9) or (7,9))")
	cr._go_back()
	await get_tree().process_frame

	# ---- TOEIC
	await _open_window(3)
	var te = main.mini_games[2]
	print("toeic visible: ", te.visible, " word ", te.word_l.text)
	await _shot("mg_toeic")
	var btn: Button = te.opt_btns[te.answer]
	await _tap(btn.get_global_transform_with_canvas() * (btn.size / 2.0))
	await _wait(0.7)
	print("toeic after correct: idx ", te.idx, " word ", te.word_l.text)
	te.idx = 99
	te._show_word()
	seeds_before = gs.seeds.size()
	btn = te.opt_btns[te.answer]
	await _tap(btn.get_global_transform_with_canvas() * (btn.size / 2.0))
	await _wait(0.2)
	await _shot("mg_toeic_100")
	print("toeic milestone seeds ", seeds_before, " -> ", gs.seeds.size(), " idx ", te.idx)
	te.close_modal()
	te.idx = 599
	te._show_word()
	te._choose(te.answer)
	await _wait(0.2)
	await _shot("mg_toeic_600")
	print("toeic 600: seeds ", gs.seeds.size(), " storage ", gs.storage.size(), " idx ", te.idx, " xong ", te.rounds_done)
	te.close_modal()
	te._show_word()
	var wrong: int = (te.answer + 1) % 4
	btn = te.opt_btns[wrong]
	await _tap(btn.get_global_transform_with_canvas() * (btn.size / 2.0))
	await _wait(0.2)
	await _shot("mg_toeic_sai")
	print("toeic after wrong idx ", te.idx)
	get_tree().quit()
