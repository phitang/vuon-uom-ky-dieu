extends Node
## Mô phỏng cân bằng: bot đặt và nâng cấp cây giữa các vòng, in ra vòng thua.

func _ready() -> void:
	var gs = get_node("/root/GameState")
	gs.new_game()
	var D = load("res://scripts/defense.gd")
	var res := []
	for trial in 4:
		var use_allies: bool = trial >= 2
		var d = D.new()
		d.size = Vector2(1280, 720)
		add_child(d)
		d._new_run(false)
		var spots := _rank_cells(d)
		var log := ""
		while not d.game_over and d.round_no <= 99:
			_spend(d, spots)
			d.start_wave()
			var guard := 0
			while d.in_wave and guard < 200000:
				d.step(1.0 / 30.0)
				guard += 1
				# thả côn trùng phòng thủ khi dư bạc
				if guard % 60 == 0 and use_allies:
					if d.silver > 150 and d.unlocked("bo_canh_cam"):
						d.release_ally("bo_canh_cam")
					elif d.silver > 120 and d.unlocked("chuon_chuon"):
						d.release_ally("chuon_chuon")
			if d.round_no % 10 == 0 or d.round_no == 44:
				log += " r%d:%d tháp,%d♥,bac%d" % [d.round_no, d.towers.size(), d.lives, d.silver]
		res.append(d.round_no)
		print("trial ", trial, " allies ", use_allies, " reached round ", d.round_no, " bosses ", d.bosses, " oc ", d.snail_killed, " bo_lv ", d.ally_lv, log)
		d.queue_free()
	get_tree().quit()

func _rank_cells(d) -> Array:
	var pc: Dictionary = d.path_cells()
	var cells := []
	for r in d.ROWS:
		for c in d.COLS:
			if pc.has(Vector2i(c, r)):
				continue
			var n := 0
			for k in pc:
				if Vector2(k).distance_to(Vector2(c, r)) <= 2.4:
					n += 1
			cells.append([n, c, r])
	cells.sort_custom(func(a, b): return a[0] > b[0])
	return cells

func _spend(d, spots: Array) -> void:
	var guard := 0
	while guard < 50:
		guard += 1
		# ưu tiên nâng cấp rẻ nhất có thể
		var best = null
		var best_cost := 1 << 30
		for t in d.towers:
			var c: Array = d.upgrade_cost(t)
			if not c.is_empty() and d.silver >= c[0] and d.essence >= c[1] and c[0] < best_cost:
				best = t
				best_cost = c[0]
		var kinds := []
		for k in d.TOWER_ORDER:
			if d.unlocked(k):
				kinds.append(k)
		# mỗi loại có ít nhất 1-2 cây, còn lại là hoa sao / xương rồng
		var want := "sao"
		var counts := {}
		for t in d.towers:
			counts[t["kind"]] = counts.get(t["kind"], 0) + 1
		for k in ["xuong_rong", "sen", "hong", "tulip"]:
			if kinds.has(k) and counts.get(k, 0) < (2 if k != "hong" else 1):
				want = k
				break
		if want == "sao" and kinds.has("xuong_rong") and counts.get("xuong_rong", 0) < counts.get("sao", 0):
			want = "xuong_rong"
		var price: int = d.TOWERS[want]["gia"]
		if d.towers.size() < 6 + d.round_no / 5 and d.silver >= price:
			for s in spots:
				if d.cell_free(s[1], s[2]):
					d.build(want, s[1], s[2])
					break
			continue
		if best != null:
			d.upgrade(best)
			continue
		if d.unlocked("bo_canh_cam") and d.silver > 400:
			if d.upgrade_ally("bo_canh_cam"):
				continue
		if d.silver >= price:
			var placed := false
			for s in spots:
				if d.cell_free(s[1], s[2]):
					placed = d.build(want, s[1], s[2])
					break
			if placed:
				continue
		break
