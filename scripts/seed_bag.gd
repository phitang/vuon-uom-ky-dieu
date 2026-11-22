extends Control
## Túi hạt: lưới 4 x 2 ô lõm mỗi trang, thanh chuyển túi ở dưới (nút mũi tên trái / phải).
## - Chạm nhẹ vào hạt: chọn hạt.
## - Bấm mũi tên: sang túi trước / túi sau (trang trượt nhẹ).
## - Chạm giữ hạt rồi kéo theo hướng bất kỳ: hạt đi theo ngón tay để gieo vào chậu hoặc thả vào Kho hạt.
##   (Không còn lướt ngang để đổi trang nên không lẫn với thao tác kéo hạt.)

const UiSkin := preload("res://scripts/ui_skin.gd")
const SeedArt := preload("res://scripts/seed_art.gd")

signal seed_tapped(index: int)

const COLS := 4
const ROWS := 2
const PER_PAGE := COLS * ROWS
const PAD := Vector2(8, 6)
const GAP := 6.0
const DOTS_H := 30.0     # thanh nút mũi tên dưới lưới
const ARROW_W := 46.0

var count := 0          # số hạt đang có
var kinds: Array = []   # mỗi hạt: {"hoa": loài hoa, "hiem": độ hiếm 0..3}
var _t := 0.0           # thời gian cho hiệu ứng phát sáng
var capacity := 8       # số ô (8 x số túi)
var selected := 0
var page := 0

var _offset := 0.0      # độ lệch khi đang lướt (điểm ảnh)
var _state := ""        # "", "pending", "swipe"
var _press_pos := Vector2.ZERO
var _press_idx := -1
var _tween: Tween
var _cell_style: StyleBox
var _cell_sel: StyleBox


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_cell_style = UiSkin.inset_box(Color("6b4426"))
	_cell_sel = UiSkin.inset_box(Color("a8742e"))


func pages() -> int:
	return maxi(1, ceili(float(capacity) / PER_PAGE))


func set_data(p_count: int, p_capacity: int, p_selected: int, p_kinds: Array = []) -> void:
	count = p_count
	kinds = p_kinds
	capacity = p_capacity
	selected = p_selected
	page = clampi(page, 0, pages() - 1)
	queue_redraw()


func go_page(p: int, animate := true) -> void:
	var target := clampi(p, 0, pages() - 1)
	var from_offset := _offset + (page - target) * size.x
	page = target
	_offset = from_offset
	if _tween:
		_tween.kill()
	if animate:
		_tween = create_tween()
		_tween.tween_method(func(v): _offset = v; queue_redraw(), _offset, 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_offset = 0.0
	queue_redraw()


func _cell_size() -> Vector2:
	var area := size - PAD * 2 - Vector2(0, DOTS_H)
	return Vector2((area.x - GAP * (COLS - 1)) / COLS, (area.y - GAP * (ROWS - 1)) / ROWS)


func _cell_rect(slot: int, page_x: float) -> Rect2:
	var cs := _cell_size()
	var c := slot % COLS
	var r := slot / COLS
	return Rect2(Vector2(page_x + PAD.x + c * (cs.x + GAP), PAD.y + r * (cs.y + GAP)), cs)


func _index_at(pos: Vector2) -> int:
	for slot in PER_PAGE:
		if _cell_rect(slot, 0.0).grow(GAP / 2.0).has_point(pos):
			var idx := page * PER_PAGE + slot
			return idx if idx < count else -1
	return -1


func _arrow_rect(dir: int) -> Rect2:
	var y := size.y - DOTS_H + 2
	var x := PAD.x if dir < 0 else size.x - PAD.x - ARROW_W
	return Rect2(Vector2(x, y), Vector2(ARROW_W, DOTS_H - 4))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# nút mũi tên chuyển túi
			for dir in [-1, 1]:
				if _arrow_rect(dir).grow(4).has_point(event.position):
					if page + dir >= 0 and page + dir < pages():
						go_page(page + dir)
					_state = ""
					accept_event()
					return
			_state = "pending"
			_press_pos = event.position
			_press_idx = _index_at(event.position)
		else:
			if _state == "pending" and _press_idx >= 0:
				seed_tapped.emit(_press_idx)
			_state = ""
		accept_event()
	elif event is InputEventMouseMotion and _state == "pending":
		var d: Vector2 = event.position - _press_pos
		if d.length() > 8.0:
			if _press_idx >= 0:
				_start_seed_drag()   # hạt bám theo ngón tay
				return
			_state = ""
		accept_event()


func _process(delta: float) -> void:
	# chỉ vẽ lại liên tục khi có hạt quý hiếm đang phát sáng
	for k in kinds:
		if int(k.get("hiem", 0)) >= 1:
			_t += delta
			queue_redraw()
			return


func _kind(idx: int) -> Dictionary:
	return kinds[idx] if idx >= 0 and idx < kinds.size() else {"hoa": "hong", "hiem": 0}


func _start_seed_drag() -> void:
	_state = ""
	selected = _press_idx
	seed_tapped.emit(_press_idx)
	var wrap := Control.new()
	var ic := SeedPreview.new()
	ic.kind = _kind(_press_idx)
	ic.size = Vector2(64, 64)
	ic.position = Vector2(-32, -32)
	wrap.add_child(ic)
	wrap.z_index = 4000   # luôn nổi trên chậu, khách và bảng bật lên
	force_drag({"hat": _press_idx}, wrap)
	queue_redraw()


func _draw() -> void:
	var cs := _cell_size()
	for p in pages():
		var px := (p - page) * size.x + _offset
		if px > size.x or px < -size.x:
			continue
		for slot in PER_PAGE:
			var idx := p * PER_PAGE + slot
			var r := _cell_rect(slot, px)
			if idx >= capacity:
				continue
			draw_style_box(_cell_sel if (idx == selected and idx < count) else _cell_style, r)
			if idx < count:
				var k := _kind(idx)
				SeedArt.draw_seed(self, r.get_center(), minf(cs.x, cs.y) / 64.0, k["hoa"], int(k["hiem"]), _t + idx * 0.7)
	# thanh chuyển túi: « mũi tên trái · Túi 1/2 · mũi tên phải »
	var n := pages()
	for dir in [-1, 1]:
		var r: Rect2 = _arrow_rect(dir)
		var on: bool = page + dir >= 0 and page + dir < n
		var base: Color = Color("a8742e") if on else Color("8a6a4a")
		draw_rect(r, Color(0.2, 0.1, 0.03, 0.55))
		draw_rect(Rect2(r.position + Vector2(1, 1), r.size - Vector2(2, 3)), base)
		draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 3)), base.lightened(0.25))
		var c: Vector2 = r.get_center()
		var tri: PackedVector2Array = PackedVector2Array([c + Vector2(-7 * dir, -7), c + Vector2(8 * dir, 0), c + Vector2(-7 * dir, 7)])
		draw_colored_polygon(tri, Color("fff1cf") if on else Color(1, 0.95, 0.85, 0.35))
	var font := get_theme_default_font()
	var text := "Túi %d/%d" % [page + 1, n]
	var fs := 16
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2(size.x / 2.0 - tw / 2.0, size.y - 9), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("6b4426"))


## Hình hạt đi theo ngón tay khi kéo đi gieo.
class SeedPreview extends Control:
	var kind := {}
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		SeedArt.draw_seed(self, size / 2.0, 1.4, kind.get("hoa", "hong"), int(kind.get("hiem", 0)), t)
