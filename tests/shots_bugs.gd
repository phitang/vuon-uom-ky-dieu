extends Node
## Vẽ các côn trùng (ảnh Gemini) ở chế độ xem trước và lúc bay.

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var Ins = load("res://scripts/insects.gd")
	var bg := ColorRect.new()
	bg.color = Color("8f9ea6")
	bg.size = Vector2(1280, 720)
	add_child(bg)
	var lay: Control = Control.new()
	lay.set_script(Ins)
	lay.size = Vector2(1280, 720)
	add_child(lay)
	var kinds := [["buom", 0], ["buom", 1], ["buom", 2], ["chuon", 0], ["chuon", 1], ["chuon", 2], ["ong", 0]]
	for i in kinds.size():
		var b = lay.spawn(kinds[i][0], kinds[i][1])
		b.preview = true
		b.position = Vector2(40 + i * 170, 200)
		b.size = Vector2(150, 150)
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/bugs.png")
	get_tree().quit()
