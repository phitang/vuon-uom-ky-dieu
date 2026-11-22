extends Node
## Bảng mẫu các loại hạt (4 mức độ hiếm) và túi hạt trong game.

const SeedArt := preload("res://scripts/seed_art.gd")
const KINDS := ["hong", "cuc", "sao", "tulip", "chuong", "lan", "sen", "rong", "xr_tron", "xr_cao", "mai", "bonsai"]
const NAMES := ["Hồng", "Cúc", "Sao", "Tulip", "Chuông", "Lan", "Sen", "Rồng", "XR tròn", "XR cao", "Mai", "Bonsai"]

class Sheet extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("f3e3c0"))
		var font := get_theme_default_font()
		var rar := ["Thường", "Hiếm", "Quý", "Huyền thoại"]
		for r in 4:
			draw_string(font, Vector2(14, 120 + r * 130), rar[r], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("3a2614"))
			for k in 12:
				var c := Vector2(170 + k * 92, 110 + r * 130)
				draw_rect(Rect2(c - Vector2(42, 42), Vector2(84, 84)), Color("6b4426"))
				SeedArt.draw_seed(self, c, 1.3, KINDS[k], r, 0.6 + k * 0.7)
		for k in 12:
			var w := font.get_string_size(NAMES[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			draw_string(font, Vector2(170 + k * 92 - w / 2, 36), NAMES[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("3a2614"))

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var sheet := Sheet.new()
	sheet.size = Vector2(1280, 620)
	sheet.theme = Theme.new()
	sheet.theme.default_font = load("res://fonts/Lora-700.ttf")
	add_child(sheet)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().get_region(Rect2i(0, 0, 1280, 620)).save_png(out + "/seeds_sheet.png")
	sheet.queue_free()
	# túi hạt trong game: mỗi loài một hạt
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	gs.seeds.clear()
	for k in KINDS:
		gs.seeds.append({"gen": {"hoa": [k, k], "la": ["tron", "tron"], "than": ["thang", "thang"], "mau": ["vang", "vang"], "co": ["vua", "vua"]}, "bo_me": []})
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	for i in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().get_region(Rect2i(0, 0, 410, 180)).save_png(out + "/seeds_bag.png")
	get_tree().quit()
