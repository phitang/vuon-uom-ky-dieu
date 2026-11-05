extends Node
func _ready() -> void:
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	gs.coins = 4200
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main._open_nursery()
	main.nursery.spawn_timer = 9999.0
	main._open_decor_shop()
	for i in 5:
		await get_tree().process_frame
	var sc: ScrollContainer = null
	var stack: Array = [main.overlay]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is ScrollContainer:
			sc = n
		stack.append_array(n.get_children())
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/decor_shop_top.png")
	sc.scroll_vertical = 100000
	for i in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/decor_shop_bottom.png")
	get_tree().quit()
