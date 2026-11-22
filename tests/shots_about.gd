extends Node
func _ready():
	get_node("/root/GameState").away_report = ""
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 3: await get_tree().process_frame
	main._show_title()
	main._open_about()
	for i in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/home/claude/sh/about.png")
	get_tree().quit()
