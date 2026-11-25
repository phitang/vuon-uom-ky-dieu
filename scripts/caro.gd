extends "res://scripts/minigame_screen.gd"
## Mini game "Cờ caro" (ô cửa sổ thứ 3): bàn 15 x 15, ai có 5 quân liền hàng trước là thắng.
## Bạn cầm cỏ ba lá, máy cầm bọ rùa. Thắng máy được 1 hạt giống Thường.

const N := 15
const EMPTY := 0
const ME := 1
const AI := 2

var grid: Array = []
var turn := ME
var over := false
var last_move := Vector2i(-1, -1)
var win_line: Array = []
var think_t := 0.0
var wins := 0
var losses := 0
var draws := 0
var me_first := true
var view: Control
var stat_l: Label
var turn_l: Label


func _init() -> void:
	title_text = "Cờ caro"


func _build_game() -> void:
	view = CaroView.new()
	view.game = self
	content.add_child(view)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.panel_box(Color("f3e3c0"), Color("7a4a24"), 18.0))
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -330
	panel.offset_right = -16
	panel.offset_top = 16
	panel.offset_bottom = -16
	content.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	turn_l = label("", 24, Color("7a3a14"), HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(turn_l)
	var who := HBoxContainer.new()
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(who)
	for spec in [["co_ba_la", "Bạn"], ["bo_rua", "Máy"]]:
		var tr := TextureRect.new()
		tr.texture = tex("res://art/minigame/%s.png" % spec[0])
		tr.custom_minimum_size = Vector2(54, 54)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		who.add_child(tr)
		var nl := label(spec[1], 20)
		nl.autowrap_mode = TextServer.AUTOWRAP_OFF
		who.add_child(nl)
	stat_l = label("", 19)
	v.add_child(stat_l)
	v.add_child(label("Chạm vào giao điểm trống để đặt quân. Có 5 quân liền nhau theo hàng ngang, dọc hoặc chéo là thắng.\nThắng máy được 1 hạt giống Thường.", 15, Color("6b5a44")))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var nb := button("Ván mới", func(): _ask_new(), Color("4a5866"))
	nb.custom_minimum_size.y = 54
	v.add_child(nb)
	var d := load_state("caro")
	wins = int(d.get("thang", 0))
	losses = int(d.get("thua", 0))
	draws = int(d.get("hoa", 0))
	new_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and view != null:
		_layout()


func _layout() -> void:
	var area := Vector2(size.x - 350, size.y - TOP_H)
	var cell: float = floor(minf((area.x - 40) / N, (area.y - 40) / N))
	view.cell = cell
	view.size = Vector2(cell * N, cell * N)
	view.position = (area - view.size) / 2.0


func _on_open() -> void:
	_layout()
	_refresh()


func _save() -> void:
	save_state("caro", {"thang": wins, "thua": losses, "hoa": draws})


func _refresh() -> void:
	if stat_l == null:
		return
	stat_l.text = "Thắng: %d   Thua: %d   Hòa: %d" % [wins, losses, draws]
	if over:
		turn_l.text = "Ván đã kết thúc"
	else:
		turn_l.text = "Lượt của bạn" if turn == ME else "Máy đang nghĩ…"
	info_l.text = "Thắng máy: +1 hạt giống Thường"
	view.queue_redraw()


func _ask_new() -> void:
	if over or _stones() == 0:
		new_game()
		return
	show_modal("Bắt đầu ván mới?", "Ván đang chơi sẽ bị bỏ (không tính thua).", [["Ván mới", func(): new_game()], ["Chơi tiếp", func(): pass, Color("4a5866")]])


func new_game() -> void:
	grid = []
	for r in N:
		var row: Array = []
		row.resize(N)
		row.fill(EMPTY)
		grid.append(row)
	over = false
	win_line = []
	last_move = Vector2i(-1, -1)
	turn = ME if me_first else AI
	think_t = 0.0
	# đổi lượt đi trước mỗi ván cho công bằng
	me_first = not me_first
	_refresh()


func _stones() -> int:
	var n := 0
	for r in N:
		for c in N:
			if grid[r][c] != EMPTY:
				n += 1
	return n


func on_tap(c: int, r: int) -> void:
	if over or turn != ME or c < 0 or r < 0 or c >= N or r >= N or grid[r][c] != EMPTY or is_paused():
		return
	_place(c, r, ME)


func _place(c: int, r: int, who: int) -> void:
	grid[r][c] = who
	last_move = Vector2i(c, r)
	var line := _five(c, r, who)
	if not line.is_empty():
		win_line = line
		over = true
		_refresh()
		_finish(who)
		return
	if _stones() == N * N:
		over = true
		draws += 1
		_save()
		_refresh()
		show_modal("Hòa!", "Bàn cờ đã kín mà chưa ai thắng.", [["Ván mới", func(): new_game()], ["Về vườn", func(): _go_back(), Color("4a5866")]])
		return
	turn = AI if who == ME else ME
	think_t = 0.0
	_refresh()


func _finish(who: int) -> void:
	if who == ME:
		wins += 1
		_save()
		_refresh()
		var msg := "Bạn đã thắng máy!\nPhần thưởng: " + reward_seed(0)
		show_modal("Chiến thắng!", msg, [["Ván mới", func(): new_game()], ["Về vườn", func(): _go_back(), Color("4a5866")]])
	else:
		losses += 1
		_save()
		_refresh()
		show_modal("Máy thắng rồi!", "Bọ rùa đã xếp được 5 quân. Thử lại nhé!", [["Ván mới", func(): new_game()], ["Về vườn", func(): _go_back(), Color("4a5866")]])


func _process(delta: float) -> void:
	super(delta)
	if is_paused() or over or turn != AI:
		return
	think_t += delta
	if think_t > 0.45:
		var m := best_move()
		_place(m.x, m.y, AI)


## 5 quân liền nhau đi qua (c, r) — trả về các ô của hàng thắng.
func _five(c: int, r: int, who: int) -> Array:
	for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]:
		var cells: Array = [Vector2i(c, r)]
		for sgn in [1, -1]:
			var p: Vector2i = Vector2i(c, r) + d * sgn
			while p.x >= 0 and p.y >= 0 and p.x < N and p.y < N and grid[p.y][p.x] == who:
				cells.append(p)
				p += d * sgn
		if cells.size() >= 5:
			return cells
	return []


# ---------------------------------------------------------------- máy chơi

## Điểm của một chuỗi theo độ dài và số đầu còn trống.
static func _shape(count: int, open_ends: int) -> int:
	if count >= 5:
		return 1000000
	if open_ends == 0:
		return 0
	match count:
		4:
			return 50000 if open_ends == 2 else 6000
		3:
			return 5000 if open_ends == 2 else 500
		2:
			return 300 if open_ends == 2 else 40
		1:
			return 10 if open_ends == 2 else 2
	return 0


func _score_at(c: int, r: int, who: int) -> int:
	var total := 0
	for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]:
		var count := 1
		var open_ends := 0
		for sgn in [1, -1]:
			var p: Vector2i = Vector2i(c, r) + d * sgn
			while p.x >= 0 and p.y >= 0 and p.x < N and p.y < N and grid[p.y][p.x] == who:
				count += 1
				p += d * sgn
			if p.x >= 0 and p.y >= 0 and p.x < N and p.y < N and grid[p.y][p.x] == EMPTY:
				open_ends += 1
		total += _shape(count, open_ends)
	return total


func best_move() -> Vector2i:
	if _stones() == 0:
		return Vector2i(N / 2, N / 2)
	var best := Vector2i(-1, -1)
	var best_v := -1.0
	for r in N:
		for c in N:
			if grid[r][c] != EMPTY or not _near(c, r):
				continue
			var attack := _score_at(c, r, AI)
			var defend := _score_at(c, r, ME)
			var v := attack * 1.1 + defend + randf() * 3.0
			if v > best_v:
				best_v = v
				best = Vector2i(c, r)
	return best


func _near(c: int, r: int) -> bool:
	for dr in range(-2, 3):
		for dc in range(-2, 3):
			var x := c + dc
			var y := r + dr
			if x >= 0 and y >= 0 and x < N and y < N and grid[y][x] != EMPTY:
				return true
	return false


# ---------------------------------------------------------------- bàn cờ

class CaroView extends Control:
	var game
	var cell := 40.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			game.on_tap(int(floor(event.position.x / cell)), int(floor(event.position.y / cell)))

	func _draw() -> void:
		var n: int = game.N
		draw_style_box(game.UiSkin.bevel_box(Color("8a5a2b"), game.GOLD, 16), Rect2(Vector2(-12, -12), size + Vector2(24, 24)))
		draw_rect(Rect2(Vector2.ZERO, size), Color("f6e7c1"))
		for i in n:
			var o := (i + 0.5) * cell
			draw_line(Vector2(cell * 0.5, o), Vector2(size.x - cell * 0.5, o), Color("b8925a"), 1.5)
			draw_line(Vector2(o, cell * 0.5), Vector2(o, size.y - cell * 0.5), Color("b8925a"), 1.5)
		for v in [Vector2i(3, 3), Vector2i(11, 3), Vector2i(7, 7), Vector2i(3, 11), Vector2i(11, 11)]:
			draw_circle((Vector2(v) + Vector2(0.5, 0.5)) * cell, cell * 0.08, Color("8a6a3a"))
		var lm: Vector2i = game.last_move
		if lm.x >= 0:
			draw_circle((Vector2(lm) + Vector2(0.5, 0.5)) * cell, cell * 0.5, Color(1, 0.85, 0.3, 0.45))
		for r in n:
			for c in n:
				var w: int = game.grid[r][c]
				if w == 0:
					continue
				var name := "co_ba_la" if w == game.ME else "bo_rua"
				var tx: Texture2D = game.tex("res://art/minigame/%s.png" % name)
				var s := cell * 0.92
				var rect := Rect2((Vector2(c, r) + Vector2(0.5, 0.5)) * cell - Vector2(s, s) / 2.0, Vector2(s, s))
				if tx:
					draw_texture_rect(tx, rect, false)
				else:
					draw_circle(rect.get_center(), s * 0.45, Color("5fb04a") if w == game.ME else Color("d8412f"))
		if game.win_line.size() >= 5:
			var pts: Array = game.win_line.duplicate()
			pts.sort_custom(func(a, b): return a.x < b.x or (a.x == b.x and a.y < b.y))
			draw_line((Vector2(pts[0]) + Vector2(0.5, 0.5)) * cell, (Vector2(pts.back()) + Vector2(0.5, 0.5)) * cell, Color(1, 0.2, 0.3, 0.75), cell * 0.16, true)
