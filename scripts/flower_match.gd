extends "res://scripts/minigame_screen.gd"
## Mini game "Ghép hoa" (ô cửa sổ thứ 2): giống Candy Crush nhưng là hoa.
## Đổi chỗ hai bông cạnh nhau để có hàng 3 bông cùng loại trở lên.
## - Ghép 4: tạo bông "gió" quét cả hàng (hoặc cả cột).
## - Ghép 5: tạo "bông cầu vồng", đổi với bông nào thì xóa hết loại đó.
## Đạt đủ điểm trước khi hết lượt là thắng vòng. Cứ thắng 4 vòng được 1 hạt giống;
## vòng càng cao, hạt càng dễ ra Hiếm, Quý, thậm chí Huyền thoại.

const COLS := 8
const ROWS := 8
const KINDS := ["hong", "huong_duong", "violet", "bim_bim", "anh_dao", "cuc"]
const SPEED := 14.0          # ô / giây khi rơi, đổi chỗ
const POP_TIME := 0.22
const WINS_PER_SEED := 4

var board: Array = []        # board[r][c] = mảnh hoa hoặc null
var level := 1
var wins := 0                # số vòng đã thắng (tính dồn để đổi hạt)
var best := 1
var score := 0
var moves := 0
var target := 0
var combo := 0
var busy := false            # đang có hoạt ảnh / dây chuyền
var check_pending := false
var swap_back: Array = []    # [a, b] nếu lần đổi vừa rồi không tạo được hàng thì đổi lại
var last_swap: Array = []
var popping := false
var pop_t := 0.0
var fx: Array = []
var sel := Vector2i(-1, -1)
var press_cell := Vector2i(-1, -1)
var press_pos := Vector2.ZERO
var ended := false
var hint_t := 0.0
var hint_pair: Array = []
var rng := RandomNumberGenerator.new()
var _next_id := 0

var board_view: Control
var side: VBoxContainer
var lv_l: Label
var score_l: Label
var moves_l: Label
var seed_l: Label
var bar: ProgressBar


func _init() -> void:
	title_text = "Ghép hoa"


func _build_game() -> void:
	rng.randomize()
	board_view = BoardView.new()
	board_view.game = self
	content.add_child(board_view)
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
	side = VBoxContainer.new()
	side.add_theme_constant_override("separation", 12)
	panel.add_child(side)
	lv_l = label("", 28, Color("7a3a14"), HORIZONTAL_ALIGNMENT_CENTER)
	side.add_child(lv_l)
	score_l = label("", 22)
	side.add_child(score_l)
	bar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 22
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("e0628a")
	fill.set_corner_radius_all(8)
	var bgs := StyleBoxFlat.new()
	bgs.bg_color = Color("6b4a2a")
	bgs.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bgs)
	side.add_child(bar)
	moves_l = label("", 22)
	side.add_child(moves_l)
	seed_l = label("", 18, Color("2f6a3a"))
	side.add_child(seed_l)
	side.add_child(label("Kéo một bông sang ô bên cạnh để đổi chỗ. Ghép 4 bông được bông gió quét cả hàng, ghép 5 bông được bông cầu vồng.", 15, Color("6b5a44")))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(sp)
	var again := button("Chơi lại vòng này", func(): _confirm_restart(), Color("4a5866"))
	again.custom_minimum_size.y = 54
	side.add_child(again)
	var d := load_state("ghep")
	level = maxi(1, int(d.get("lv", 1)))
	wins = int(d.get("thang", 0))
	best = maxi(level, int(d.get("cao_nhat", 1)))
	_start_level()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and board_view != null:
		_layout()


func _layout() -> void:
	var area := Vector2(size.x - 350, size.y - TOP_H)
	var cell: float = floor(minf((area.x - 40) / COLS, (area.y - 40) / ROWS))
	board_view.cell = cell
	board_view.size = Vector2(cell * COLS, cell * ROWS)
	board_view.position = (area - board_view.size) / 2.0


func _on_open() -> void:
	_layout()
	_refresh()


func _save() -> void:
	save_state("ghep", {"lv": level, "thang": wins, "cao_nhat": best})


# ---------------------------------------------------------------- vòng chơi

func num_kinds() -> int:
	return 5 if level <= 5 else 6


func _start_level() -> void:
	target = 500 + 130 * (level - 1)
	moves = maxi(18, 24 - level / 6)
	score = 0
	combo = 0
	ended = false
	busy = false
	check_pending = false
	swap_back = []
	sel = Vector2i(-1, -1)
	fx.clear()
	_fill_board()
	_refresh()


func _new_piece(t: int, pos: Vector2) -> Dictionary:
	_next_id += 1
	return {"id": _next_id, "t": t, "sp": "", "pos": pos, "die": false, "scale": 1.0}


func _fill_board() -> void:
	board = []
	for r in ROWS:
		var row: Array = []
		for c in COLS:
			var t := rng.randi() % num_kinds()
			# tránh có sẵn hàng 3 khi mới bày
			while (c >= 2 and row[c - 1]["t"] == t and row[c - 2]["t"] == t) or (r >= 2 and board[r - 1][c]["t"] == t and board[r - 2][c]["t"] == t):
				t = rng.randi() % num_kinds()
			row.append(_new_piece(t, Vector2(c, r - ROWS - 1)))
		board.append(row)
	busy = true
	if not _has_moves():
		_fill_board()


func _refresh() -> void:
	if lv_l == null:
		return
	lv_l.text = "Vòng %d" % level
	score_l.text = "Điểm: %d / %d" % [score, target]
	bar.max_value = target
	bar.value = mini(score, target)
	moves_l.text = "Lượt còn lại: %d" % moves
	var left := WINS_PER_SEED - wins % WINS_PER_SEED
	seed_l.text = "Thắng thêm %d vòng nữa để nhận 1 hạt giống.\n(Vòng càng cao, hạt càng hiếm)" % left
	info_l.text = "Vòng cao nhất: %d" % best


func _confirm_restart() -> void:
	if busy:
		return
	show_modal("Chơi lại vòng %d?" % level, "Điểm và lượt của vòng này sẽ bắt đầu lại.", [["Chơi lại", func(): _start_level()], ["Thôi", func(): pass, Color("4a5866")]])


# ---------------------------------------------------------------- chạm và đổi chỗ

func cell_at(p: Vector2) -> Vector2i:
	var c := int(floor(p.x / board_view.cell))
	var r := int(floor(p.y / board_view.cell))
	if c < 0 or r < 0 or c >= COLS or r >= ROWS:
		return Vector2i(-1, -1)
	return Vector2i(c, r)


func on_press(p: Vector2) -> void:
	press_cell = cell_at(p)
	press_pos = p


func on_drag(p: Vector2) -> void:
	if press_cell.x < 0 or busy or ended:
		return
	var d := p - press_pos
	if d.length() > board_view.cell * 0.35:
		var dir := Vector2i(1, 0) if absf(d.x) > absf(d.y) and d.x > 0 else (Vector2i(-1, 0) if absf(d.x) > absf(d.y) else (Vector2i(0, 1) if d.y > 0 else Vector2i(0, -1)))
		try_swap(press_cell, press_cell + dir)
		press_cell = Vector2i(-1, -1)


func on_release(p: Vector2) -> void:
	if press_cell.x < 0 or busy or ended:
		press_cell = Vector2i(-1, -1)
		return
	var c := cell_at(p)
	if c == press_cell:
		# chạm-chạm: chọn rồi chạm ô kề bên
		if sel.x >= 0 and (absi(sel.x - c.x) + absi(sel.y - c.y)) == 1:
			try_swap(sel, c)
			sel = Vector2i(-1, -1)
		elif sel == c:
			sel = Vector2i(-1, -1)
		else:
			sel = c
	press_cell = Vector2i(-1, -1)
	board_view.queue_redraw()


func try_swap(a: Vector2i, b: Vector2i) -> bool:
	if busy or ended or b.x < 0 or b.y < 0 or b.x >= COLS or b.y >= ROWS:
		return false
	sel = Vector2i(-1, -1)
	hint_t = 0.0
	hint_pair = []
	var pa: Dictionary = board[a.y][a.x]
	var pb: Dictionary = board[b.y][b.x]
	# bông cầu vồng: xóa hết loại hoa của bông kia
	if pa["sp"] == "bom" or pb["sp"] == "bom":
		_swap_cells(a, b)
		moves -= 1
		var other: Dictionary = pb if pa["sp"] == "bom" else pa
		var bomb: Dictionary = pa if pa["sp"] == "bom" else pb
		var clear := {}
		clear[bomb["id"]] = bomb
		for r in ROWS:
			for c in COLS:
				var q: Dictionary = board[r][c]
				if other["sp"] == "bom" or q["t"] == other["t"]:
					clear[q["id"]] = q
		combo = 1
		_pop(clear)
		busy = true
		_refresh()
		return true
	_swap_cells(a, b)
	if _find_matches().is_empty():
		swap_back = [a, b]
	else:
		moves -= 1
		last_swap = [a, b]
	busy = true
	check_pending = true
	_refresh()
	return true


func _swap_cells(a: Vector2i, b: Vector2i) -> void:
	var t = board[a.y][a.x]
	board[a.y][a.x] = board[b.y][b.x]
	board[b.y][b.x] = t


# ---------------------------------------------------------------- tìm hàng, nổ, rơi

## Trả về danh sách nhóm, mỗi nhóm {"cells": [Vector2i], "dir": "ngang"/"doc"}
func _find_matches() -> Array:
	var groups: Array = []
	for r in ROWS:
		var c := 0
		while c < COLS:
			var t: int = board[r][c]["t"]
			var e := c
			while e + 1 < COLS and t >= 0 and board[r][e + 1]["t"] == t:
				e += 1
			if e - c >= 2 and t >= 0:
				var cells: Array = []
				for k in range(c, e + 1):
					cells.append(Vector2i(k, r))
				groups.append({"cells": cells, "dir": "ngang"})
			c = e + 1
	for c in COLS:
		var r := 0
		while r < ROWS:
			var t: int = board[r][c]["t"]
			var e := r
			while e + 1 < ROWS and t >= 0 and board[e + 1][c]["t"] == t:
				e += 1
			if e - r >= 2 and t >= 0:
				var cells: Array = []
				for k in range(r, e + 1):
					cells.append(Vector2i(c, k))
				groups.append({"cells": cells, "dir": "doc"})
			r = e + 1
	return groups


func _resolve_matches(groups: Array) -> void:
	var clear := {}  # id -> mảnh
	var keep := {}   # id -> [mảnh, loại đặc biệt]: giữ lại để biến thành bông đặc biệt
	for g in groups:
		var cells: Array = g["cells"]
		for v in cells:
			clear[board[v.y][v.x]["id"]] = board[v.y][v.x]
		if cells.size() >= 4:
			# đặt bông đặc biệt ở ô vừa đổi (nếu nằm trong nhóm), không thì ở giữa nhóm
			var at: Vector2i = cells[cells.size() / 2]
			for v in last_swap:
				if cells.has(v):
					at = v
			var p: Dictionary = board[at.y][at.x]
			if keep.has(p["id"]) or p["sp"] != "":
				continue
			keep[p["id"]] = [p, "bom" if cells.size() >= 5 else ("hang_ngang" if g["dir"] == "ngang" else "hang_doc")]
	last_swap = []
	for id in keep:
		clear.erase(id)
	_pop(clear)
	for id in keep:
		var p: Dictionary = keep[id][0]
		p["sp"] = keep[id][1]
		if p["sp"] == "bom":
			p["t"] = -1
		fx.append({"type": "sparkle", "p": p["pos"] + Vector2(0.5, 0.5), "t": 0.0, "d": 0.6})


## Đánh dấu nổ các mảnh trong clear; bông đặc biệt bị nổ thì kích hoạt thêm.
func _pop(clear: Dictionary) -> void:
	var queue: Array = clear.values()
	var seen := {}   # id -> mảnh
	while not queue.is_empty():
		var p: Dictionary = queue.pop_back()
		if seen.has(p["id"]):
			continue
		seen[p["id"]] = p
		var at := _find(p)
		if at.x < 0:
			continue
		if p["sp"] == "hang_ngang" or p["sp"] == "hang_doc":
			fx.append({"type": p["sp"], "p": Vector2(at) + Vector2(0.5, 0.5), "t": 0.0, "d": 0.35})
			for k in (COLS if p["sp"] == "hang_ngang" else ROWS):
				var q: Dictionary = board[at.y][k] if p["sp"] == "hang_ngang" else board[k][at.x]
				if not seen.has(q["id"]):
					queue.append(q)
		elif p["sp"] == "bom" and not clear.has(p["id"]):
			# cầu vồng bị nổ lây: xóa loại hoa nhiều nhất
			var count := {}
			for r in ROWS:
				for c in COLS:
					count[board[r][c]["t"]] = count.get(board[r][c]["t"], 0) + 1
			var top := 0
			for k in count:
				if k >= 0 and count[k] > count.get(top, 0):
					top = k
			for r in ROWS:
				for c in COLS:
					if board[r][c]["t"] == top:
						queue.append(board[r][c])
	var n := 0
	for p in seen.values():
		p["die"] = true
		n += 1
	combo += 1
	var gain := n * 10 * combo
	score += gain
	if n > 0:
		var center := Vector2.ZERO
		for p in seen.values():
			center += p["pos"]
		center = center / n + Vector2(0.5, 0.5)
		fx.append({"type": "score", "p": center, "t": 0.0, "d": 0.9, "n": gain})
		if combo >= 3:
			toast(["Tuyệt vời!", "Rực rỡ!", "Hoa nở rộ!", "Quá đỉnh!"][mini(combo - 3, 3)], 1.0)
	popping = true
	pop_t = 0.0
	_refresh()


func _find(p: Dictionary) -> Vector2i:
	for r in ROWS:
		for c in COLS:
			if is_same(board[r][c], p):
				return Vector2i(c, r)
	return Vector2i(-1, -1)


func _gravity() -> void:
	for c in COLS:
		var stack: Array = []
		for r in range(ROWS - 1, -1, -1):
			if not board[r][c]["die"]:
				stack.append(board[r][c])
		var missing := ROWS - stack.size()
		for k in missing:
			var t := rng.randi() % num_kinds()
			stack.append(_new_piece(t, Vector2(c, -1 - k)))
		for i in ROWS:
			board[ROWS - 1 - i][c] = stack[i]


func _process(delta: float) -> void:
	super(delta)
	if is_paused():
		return
	for e in fx:
		e["t"] += delta
	fx = fx.filter(func(e): return e["t"] < e["d"])
	board_view.queue_redraw()
	if board.is_empty():
		return
	# di chuyển mảnh về đúng ô
	var moving := false
	for r in ROWS:
		for c in COLS:
			var p: Dictionary = board[r][c]
			var tgt := Vector2(c, r)
			if p["pos"] != tgt:
				var d: Vector2 = tgt - p["pos"]
				var stp := SPEED * delta
				p["pos"] = tgt if d.length() <= stp else p["pos"] + d.normalized() * stp
				moving = true
	if popping:
		pop_t += delta
		for r in ROWS:
			for c in COLS:
				if board[r][c]["die"]:
					board[r][c]["scale"] = maxf(0.0, 1.0 - pop_t / POP_TIME)
		if pop_t >= POP_TIME:
			popping = false
			_gravity()
			check_pending = true
		return
	if moving:
		return
	if check_pending:
		check_pending = false
		var g := _find_matches()
		if not g.is_empty():
			swap_back = []
			_resolve_matches(g)
			return
		if not swap_back.is_empty():
			_swap_cells(swap_back[0], swap_back[1])
			swap_back = []
			toast("Không ghép được, thử chỗ khác nhé!", 1.2)
			return
	if busy:
		busy = false
		combo = 0
		_after_turn()
	if not busy and not ended:
		hint_t += delta
		if hint_t > 6.0 and hint_pair.is_empty():
			hint_pair = _find_move()


func _after_turn() -> void:
	if score >= target:
		_win()
		return
	if moves <= 0:
		ended = true
		show_modal("Hết lượt!", "Bạn được %d / %d điểm. Thử lại vòng %d nhé!" % [score, target, level],
			[["Chơi lại", func(): _start_level()], ["Về vườn", func(): _go_back(), Color("4a5866")]])
		return
	if not _has_moves():
		toast("Hết nước đi, xáo lại hoa!", 1.5)
		_shuffle()


func _win() -> void:
	ended = true
	wins += 1
	var msg := "Bạn đạt %d điểm (cần %d)." % [score, target]
	if wins % WINS_PER_SEED == 0:
		msg += "\n\nThắng đủ %d vòng! Phần thưởng: %s" % [WINS_PER_SEED, reward_seed(_roll_rarity(level))]
	else:
		msg += "\nThắng thêm %d vòng nữa để nhận hạt giống." % (WINS_PER_SEED - wins % WINS_PER_SEED)
	level += 1
	best = maxi(best, level)
	_save()
	_refresh()
	show_modal("Thắng vòng %d!" % (level - 1), msg, [["Vòng tiếp theo", func(): _start_level()], ["Về vườn", func(): _start_level(); _go_back(), Color("4a5866")]])


## Vòng càng cao càng dễ ra hạt hiếm.
func _roll_rarity(lv: int) -> int:
	var p3 := clampf((lv - 24) * 0.006, 0.0, 0.12)
	var p2 := clampf(0.02 + lv * 0.008, 0.0, 0.35)
	var p1 := clampf(0.25 + lv * 0.012, 0.0, 0.5)
	var x := rng.randf()
	if x < p3:
		return 3
	if x < p3 + p2:
		return 2
	if x < p3 + p2 + p1:
		return 1
	return 0


func _shuffle() -> void:
	var all: Array = []
	for r in ROWS:
		for c in COLS:
			all.append(board[r][c])
	for attempt in 50:
		all.shuffle()
		for i in all.size():
			board[i / COLS][i % COLS] = all[i]
		if _find_matches().is_empty() and _has_moves():
			return
	_fill_board()


func _has_moves() -> bool:
	return not _find_move().is_empty()


func _find_move() -> Array:
	for r in ROWS:
		for c in COLS:
			if board[r][c]["sp"] == "bom":
				return [Vector2i(c, r), Vector2i(c + 1 if c + 1 < COLS else c - 1, r)]
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				var b: Vector2i = Vector2i(c, r) + d
				if b.x >= COLS or b.y >= ROWS:
					continue
				_swap_cells(Vector2i(c, r), b)
				var ok := not _find_matches().is_empty()
				_swap_cells(Vector2i(c, r), b)
				if ok:
					return [Vector2i(c, r), b]
	return []


# ---------------------------------------------------------------- vẽ bàn

class BoardView extends Control:
	var game
	var cell := 70.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				game.on_press(event.position)
			else:
				game.on_release(event.position)
		elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			game.on_drag(event.position)

	func _draw() -> void:
		var R: int = game.ROWS
		var C: int = game.COLS
		var frame := Rect2(Vector2(-12, -12), size + Vector2(24, 24))
		draw_style_box(game.UiSkin.bevel_box(Color("8a5a2b"), game.GOLD, 16), frame)
		for r in R:
			for c in C:
				var col := Color("fbf3dc") if (r + c) % 2 == 0 else Color("f1e4c4")
				draw_rect(Rect2(c * cell, r * cell, cell, cell), col)
		if game.sel.x >= 0:
			draw_rect(Rect2(Vector2(game.sel) * cell, Vector2(cell, cell)), Color(1, 0.85, 0.3, 0.55))
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)
		for v in game.hint_pair:
			draw_rect(Rect2(Vector2(v) * cell + Vector2(3, 3), Vector2(cell - 6, cell - 6)), Color(1, 1, 1, 0.35 + 0.35 * pulse), false, 4.0)
		for r in R:
			for c in C:
				var p: Dictionary = game.board[r][c]
				if p["pos"].y < -0.99:
					continue
				var center: Vector2 = (p["pos"] + Vector2(0.5, 0.5)) * cell
				var s: float = cell * 0.88 * p["scale"]
				if center.y < -cell * 0.5:
					continue
				_piece(p, center, s)
		for e in game.fx:
			var k: float = e["t"] / e["d"]
			var pc: Vector2 = e["p"] * cell
			match e["type"]:
				"score":
					draw_string(game.FONT_BOLD, pc + Vector2(-cell * 0.4, -cell * 0.8 * k), "+%d" % e["n"], HORIZONTAL_ALIGNMENT_LEFT, -1, int(cell * 0.42), Color(1, 1, 1, 1 - k))
					draw_string(game.FONT_BOLD, pc + Vector2(-cell * 0.42, -cell * 0.8 * k - 2), "+%d" % e["n"], HORIZONTAL_ALIGNMENT_LEFT, -1, int(cell * 0.42), Color(0.85, 0.3, 0.45, 1 - k))
				"hang_ngang":
					draw_rect(Rect2(0, pc.y - cell * 0.3 * (1 - k), size.x, cell * 0.6 * (1 - k)), Color(1, 1, 0.8, 0.8 * (1 - k)))
				"hang_doc":
					draw_rect(Rect2(pc.x - cell * 0.3 * (1 - k), 0, cell * 0.6 * (1 - k), size.y), Color(1, 1, 0.8, 0.8 * (1 - k)))
				"sparkle":
					for i in 8:
						draw_circle(pc + Vector2.from_angle(TAU * i / 8.0 + k * 2) * cell * 0.6 * k, cell * 0.06 * (1 - k), Color(1, 0.95, 0.6, 1 - k))

	func _piece(p: Dictionary, center: Vector2, s: float) -> void:
		if p["sp"] == "bom":
			# bông cầu vồng
			var t := Time.get_ticks_msec() / 400.0
			for i in 8:
				var col := Color.from_hsv(fmod(i / 8.0 + t * 0.1, 1.0), 0.6, 1.0)
				var a := TAU * i / 8.0 + t
				draw_circle(center + Vector2.from_angle(a) * s * 0.24, s * 0.2, col)
			draw_circle(center, s * 0.18, Color("fff6c8"))
			draw_arc(center, s * 0.46, 0, TAU, 32, Color(1, 1, 1, 0.8), 2.0, true)
			return
		var tx: Texture2D = game.tex("res://art/minigame/%s.png" % game.KINDS[p["t"]])
		if tx:
			draw_texture_rect(tx, Rect2(center - Vector2(s, s) / 2.0, Vector2(s, s)), false)
		else:
			draw_circle(center, s * 0.45, Color.from_hsv(p["t"] / 6.0, 0.6, 0.95))
		if p["sp"] == "hang_ngang" or p["sp"] == "hang_doc":
			# sọc gió trắng chạy qua bông
			var horiz: bool = p["sp"] == "hang_ngang"
			for k in [-1, 1]:
				var o: Vector2 = Vector2(0, k * s * 0.14) if horiz else Vector2(k * s * 0.14, 0)
				var a: Vector2 = center + o + (Vector2(-s * 0.42, 0) if horiz else Vector2(0, -s * 0.42))
				var b: Vector2 = center + o + (Vector2(s * 0.42, 0) if horiz else Vector2(0, s * 0.42))
				draw_line(a, b, Color(1, 1, 1, 0.9), s * 0.07, true)
			var tip := Vector2(s * 0.5, 0) if horiz else Vector2(0, s * 0.5)
			for sgn in [-1.0, 1.0]:
				var tp: Vector2 = center + tip * sgn
				var side := Vector2(0, s * 0.12) if horiz else Vector2(s * 0.12, 0)
				draw_colored_polygon(PackedVector2Array([tp, tp - tip * sgn * 0.25 + side, tp - tip * sgn * 0.25 - side]), Color(1, 1, 1, 0.95))
