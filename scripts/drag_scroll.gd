extends ScrollContainer
## Khung cuộn kéo được bằng ngón tay (cả khi ngón tay đặt lên nút bấm).
## - Vuốt lên/xuống quá DRAG_START điểm ảnh: cuộn nội dung, có trôi theo đà.
## - Khi đã vuốt, nút dưới ngón tay bị hủy bấm nên không mua/bấm nhầm.
## - Chạm nhẹ (không vuốt): nút vẫn bấm bình thường.

const DRAG_START := 12.0
const FRICTION := 4.0      # càng lớn càng dừng nhanh

var _pressing := false
var _dragging := false
var _start := Vector2.ZERO
var _start_scroll := 0.0
var _velocity := 0.0
var _last_y := 0.0
var _last_t := 0.0


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if get_global_rect().has_point(event.global_position):
				_pressing = true
				_dragging = false
				_start = event.global_position
				_start_scroll = scroll_vertical
				_velocity = 0.0
				_last_y = event.global_position.y
				_last_t = Time.get_ticks_msec() / 1000.0
		else:
			if _dragging:
				get_viewport().set_input_as_handled()
			_pressing = false
			_dragging = false
	elif event is InputEventMouseMotion and _pressing:
		var dy: float = event.global_position.y - _start.y
		if not _dragging and absf(dy) > DRAG_START:
			_dragging = true
			_cancel_button_at(_start)
		if _dragging:
			scroll_vertical = int(_start_scroll - dy)
			var now := Time.get_ticks_msec() / 1000.0
			var dt := maxf(now - _last_t, 0.001)
			_velocity = lerpf(_velocity, -(event.global_position.y - _last_y) / dt, 0.5)
			_last_y = event.global_position.y
			_last_t = now
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _pressing or absf(_velocity) < 5.0:
		return
	scroll_vertical = int(scroll_vertical + _velocity * delta)
	_velocity = lerpf(_velocity, 0.0, clampf(FRICTION * delta, 0.0, 1.0))


## Hủy trạng thái "đang bấm" của nút nằm dưới ngón tay khi bắt đầu vuốt.
func _cancel_button_at(p: Vector2) -> void:
	var stack: Array = [self]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is BaseButton and n.is_visible_in_tree() and n.get_global_rect().has_point(p):
			var was: bool = n.disabled
			n.disabled = true
			n.disabled = was
		stack.append_array(n.get_children())
