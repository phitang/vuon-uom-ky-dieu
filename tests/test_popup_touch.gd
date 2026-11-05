extends Node
## Thử bảng Vật tư bằng sự kiện chạm thật: vuốt để cuộn (không mua nhầm), chạm nút để mua, chạm ra ngoài để đóng.

var main: Control
var gs: Node

func _ready() -> void:
	gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	gs.coins = 100000
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _frames()
	main._open_shop()
	await _frames()
	var scroll: ScrollContainer = _find_scroll()
	var max_scroll := scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page
	print("Vật tư mở: cuộn tối đa = ", int(max_scroll), " px")
	# vuốt lên, bắt đầu ngay trên nút "30 xu"
	var b := _find_button("30 xu")
	var start := b.get_global_rect().get_center()
	var coins0: int = gs.coins
	var seeds0: int = gs.seeds.size()
	await _drag(start, start + Vector2(0, -260))
	print("Vuốt lên từ nút mua: cuộn = ", scroll.scroll_vertical, " | xu không đổi = ", gs.coins == coins0, " | hạt không đổi = ", gs.seeds.size() == seeds0)
	await get_tree().create_timer(0.6).timeout
	print("Sau khi thả tay (trôi theo đà): cuộn = ", scroll.scroll_vertical)
	# vuốt xuống lại
	await _drag(scroll.get_global_rect().get_center(), scroll.get_global_rect().get_center() + Vector2(0, 300))
	await get_tree().create_timer(0.6).timeout
	print("Vuốt xuống: cuộn = ", scroll.scroll_vertical)
	# chạm nhẹ vào nút mua: vẫn mua được
	b = _find_button("30 xu")
	await _tap(b.get_global_rect().get_center())
	print("Chạm nút 30 xu: mua được = ", gs.seeds.size() == seeds0 + 1)
	# chạm vào vùng tối bên ngoài: đóng
	await _tap(Vector2(40, 360))
	print("Chạm ra ngoài: bảng đã đóng = ", not main.overlay.visible)
	# Sổ tay, Menu cũng đóng được
	main._open_book()
	await _frames()
	await _tap(Vector2(20, 700))
	print("Sổ tay chạm ra ngoài: đóng = ", not main.overlay.visible)
	print("XONG")
	get_tree().quit()

func _find_scroll() -> ScrollContainer:
	var stack: Array = [main.overlay]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is ScrollContainer:
			return n
		stack.append_array(n.get_children())
	return null

func _find_button(prefix: String) -> Button:
	var stack: Array = [main.overlay]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Button and n.text.begins_with(prefix) and n.is_visible_in_tree():
			return n
		stack.append_array(n.get_children())
	return null

func _frames() -> void:
	for i in 3:
		await get_tree().process_frame

func _btn(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(e)

func _move(pos: Vector2, rel: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = pos
	e.global_position = pos
	e.relative = rel
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(e)

func _drag(a: Vector2, b: Vector2) -> void:
	_btn(a, true)
	await get_tree().process_frame
	for t in range(1, 13):
		_move(a.lerp(b, t / 12.0), (b - a) / 12.0)
		await get_tree().process_frame
	_btn(b, false)
	await _frames()

func _tap(p: Vector2) -> void:
	_btn(p, true)
	await get_tree().process_frame
	_btn(p, false)
	await _frames()
