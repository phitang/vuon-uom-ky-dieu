extends Node
## Chụp màn hình mini game Phòng thủ và kiểm tra luật cơ bản.

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._hide_title()
	for k in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/def_vuon.png")
	# chạm cửa sổ đầu tiên bằng sự kiện thật
	var gh: Control = main.greenhouse
	var wr: Rect2 = gh.window_rects[0]
	var p: Vector2 = get_viewport().get_screen_transform() * (gh.get_global_transform_with_canvas() * wr.get_center())
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = p
		ev.global_position = p
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		Input.parse_input_event(ev)
		await get_tree().process_frame
	await get_tree().process_frame
	var d = main.defense
	print("defense visible: ", d.visible)
	d.bosses = 12
	d.silver = 5000
	d.essence = 1000
	var spots := [[1, 3, "sao"], [4, 3, "sen"], [3, 7, "tulip"], [5, 3, "xuong_rong"], [8, 3, "hong"], [9, 4, "sao"], [11, 0, "sao"], [7, 7, "xuong_rong"], [4, 0, "tulip"]]
	for s in spots:
		print("build ", s, " -> ", d.build(s[2], s[0], s[1]))
	var tiers := [3, 3, 3, 3, 3, 2, 1, 0, 3]
	for i in d.towers.size():
		for _u in tiers[i]:
			d.upgrade(d.towers[i])
	# mọi loài côn trùng đứng rải trên đường
	d.in_wave = true
	var kinds := ["sau", "bo_xit", "ret", "chau_chau", "boss_ret", "boss_nhen", "boss_ong"]
	for i in kinds.size():
		d._spawn(kinds[i])
		d.enemies.back()["d"] = 1.0 + i * 4.2
		d.enemies.back()["hp"] *= 0.4 + 0.1 * i
	d.enemies[2]["freeze"] = 2.0
	for k in 20:
		d.step(1.0 / 60.0)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/def_bugs.png")
	d.enemies.clear()
	d.in_wave = false
	d.round_no = 6
	d.start_wave()
	for k in 600:
		d.step(1.0 / 60.0)
	await get_tree().process_frame
	d._close_info()
	d.fxl.queue_redraw()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/def_play.png")
	d._open_info(d.towers[0])
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/def_info.png")
	get_tree().quit()
