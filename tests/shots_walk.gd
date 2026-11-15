extends Node
## Chụp các khung bước đi của vài nhân vật anime, ghép thành một dải.

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var CV := preload("res://scripts/customer_view.gd")
	var bg := ColorRect.new()
	bg.color = Color("6fb35a")
	bg.size = Vector2(1280, 720)
	add_child(bg)
	var ids := ["khach_xanh", "khach_tim", "be_gai", "ban_hang", "dan_anh"]
	for r in ids.size():
		for f in 8:
			var n := Control.new()
			n.set_script(CV)
			n.size = Vector2(84, 168)
			n.position = Vector2(20 + f * 150, 0)
			add_child(n)
			n.setup("qua_duong", 0, ids[r])
			n.walking = true
			n.facing = 1.0
			n.bob = f * PI / 4.0
			n.position.y = 10 + r * 140 - 30
			n.scale = Vector2(0.8, 0.8)
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/walk.png")
	get_tree().quit()
