extends Control
## Hình xem trước một món trang trí / bậc nâng cấp trong cửa hàng trang trí.

const Art := preload("res://scripts/shop_decor_art.gd")

var kind := "bang_hieu"
var tier := 0
var _t := 0.0


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	Art.draw_preview(self, kind, tier, size, get_theme_default_font(), _t)
	draw_rect(Rect2(Vector2.ZERO, size), Color("7a4a24"), false, 2.0)
