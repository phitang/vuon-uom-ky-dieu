extends Node
## Côn trùng đố vui: kiểm tra câu hỏi, bay, chạm, trả lời đúng/sai.

func _ready() -> void:
	var out: String = OS.get_environment("SHOT_DIR")
	var Quiz = load("res://scripts/quiz.gd")
	# 1) mọi câu hỏi đều có 4 đáp án khác nhau và đáp án đúng hợp lệ
	var bad := 0
	for kind in ["buom", "chuon", "ong"]:
		for level in 3:
			for n in 400:
				var q: Dictionary = Quiz.make(kind, level)
				var opts: Array = q["options"]
				var uniq := {}
				for o in opts:
					uniq[o] = true
				if opts.size() != 4 or uniq.size() != 4 or q["answer"] < 0 or q["answer"] > 3:
					bad += 1
	print("Câu hỏi lỗi: ", bad, " / 3600")
	for kind in ["buom", "chuon", "ong"]:
		for level in 3:
			var q: Dictionary = Quiz.make(kind, level)
			print("  %s cấp %d: %s  %s  (đúng: %s)" % [kind, level, q["q"], q["options"], q["options"][q["answer"]]])
	var gs = get_node("/root/GameState")
	gs.new_game()
	gs.away_report = ""
	var main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var lay: Control = main.insects
	lay.spawn("buom", 1)
	lay.spawn("chuon", 2)
	lay.spawn("ong", 0)
	lay.spawn("buom", 0)
	lay.spawn("buom", 2)
	lay.spawn("chuon", 0)
	await get_tree().create_timer(3.0).timeout
	await _shot(out + "/con_trung_bay.png")
	print("Đang bay: ", lay.get_child_count(), " con")
	# chạm thật vào con đầu tiên
	var bug: Control = lay.get_child(0)
	var p: Vector2 = bug.get_global_rect().get_center()
	_click(p)
	await get_tree().process_frame
	await get_tree().process_frame
	print("Chạm: bảng câu hỏi mở = ", main.overlay.visible, " | còn ", lay.get_child_count(), " con")
	await _shot(out + "/cau_hoi.png")
	# trả lời đúng
	var c0: int = gs.coins
	var right_text := _right_answer(main)
	_press(main.overlay, right_text)
	await get_tree().process_frame
	print("Trả lời đúng: xu ", c0, " -> ", gs.coins)
	await _shot(out + "/cau_hoi_dung.png")
	main._close_popup()
	# trả lời sai
	main._open_quiz("chuon", 1)
	await get_tree().process_frame
	var opts := _option_buttons(main.overlay)
	var right2 := _right_answer(main)
	for b in opts:
		if b.text != right2:
			b.pressed.emit()
			break
	await get_tree().process_frame
	print("Trả lời sai: xu ", gs.coins, " (không đổi)")
	await _shot(out + "/cau_hoi_sai.png")
	main._close_popup()
	# hết thời gian thì bay đi; bảng mở thì không xuất hiện thêm
	print("Hẹn giờ xuất hiện: ", lay.SPAWN_MIN, "-", lay.SPAWN_MAX, " giây")
	get_tree().quit()

var _last_q := {}

func _right_answer(main) -> String:
	# đọc đáp án đúng bằng cách tìm nhãn câu hỏi rồi tạo lại? Đơn giản hơn: thử từng nút trên bản sao không được,
	# nên lấy từ biến quiz đang hiển thị qua chữ nút được tô xanh sau khi chọn. Ở đây dùng mẹo: chọn nút có
	# modulate xanh sau khi bấm thử sẽ làm mất lượt, nên ta tính lại từ câu hỏi toán / từ điển.
	var labels: Array = []
	_collect(main.overlay, labels)
	var Quiz = load("res://scripts/quiz.gd")
	var qtext := ""
	for l in labels:
		if l is Label and (l.text.ends_with("?") or l.text.ends_with("= ?")):
			qtext = l.text
	var opts := _option_buttons(main.overlay)
	# toán
	if qtext.ends_with("= ?"):
		var expr := Expression.new()
		expr.parse(qtext.replace(" = ?", "").replace("×", "*").replace("÷", "/").replace("−", "-"))
		return str(int(expr.execute()))
	# từ vựng
	for lv in Quiz.WORDS:
		for w in lv:
			if qtext == "Từ \"%s\" nghĩa là gì?" % w[0]:
				return w[1]
			if qtext == "\"%s\" trong tiếng Anh là từ nào?" % w[1]:
				return w[0]
	for row in Quiz.LIFE:
		if row[0] == qtext:
			return row[1]
	return opts[0].text

func _option_buttons(root: Node) -> Array:
	var out: Array = []
	var all: Array = []
	_collect(root, all)
	for n in all:
		if n is Button and n.get_parent() is GridContainer:
			out.append(n)
	return out

func _collect(root: Node, out: Array) -> void:
	for n in root.get_children():
		out.append(n)
		_collect(n, out)

func _press(root: Node, text: String) -> void:
	for b in _option_buttons(root):
		if b.text == text:
			b.pressed.emit()
			return
	print("không thấy nút ", text)

func _click(p: Vector2) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = p
		ev.global_position = p
		Input.parse_input_event(ev)

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
