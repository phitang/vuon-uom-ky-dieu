extends Node
## Chụp màn hình chính (bản điện thoại 16:9 và màn hình rộng), bảng âm thanh, hỏi chơi lại.

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	get_node("/root/GameState").away_report = ""
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames()
	main._show_title()
	await _shot(out + "/title0.png")
	main._open_sound()
	await _shot(out + "/title1_amthanh.png")
	main._close_popup()
	main._ask_restart()
	await _shot(out + "/title2_choilai.png")
	main._close_popup()
	get_window().size = Vector2i(1600, 720)
	await _shot(out + "/title3_rong.png")
	main._hide_title()
	await _shot(out + "/title4_vao.png")
	main._open_menu()
	await _shot(out + "/title5_menu.png")
	get_tree().quit()

func _frames() -> void:
	for i in 3:
		await get_tree().process_frame

func _shot(path: String) -> void:
	await _frames()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
