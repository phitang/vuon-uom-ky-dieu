extends "res://scripts/minigame_screen.gd"
## Mini game "TOEIC 600" (ô cửa sổ thứ 4): lần lượt từng từ trong 600 từ TOEIC theo thứ tự sách,
## chọn nghĩa đúng trong 4 đáp án. Sai một từ là phải học lại từ từ đầu tiên.
## Mỗi mốc 100 từ liên tiếp được thưởng hạt giống:
##   100: 1 hạt Thường · 200: 1 hạt Hiếm · 300: 2 hạt Hiếm · 400: 1 hạt Quý
##   500: 1 hạt Huyền thoại · 600: 3 hạt Huyền thoại chưa có trong Sổ tay.

const Words := preload("res://scripts/toeic_words.gd")
const REWARDS := {
	100: [[0, 1]], 200: [[1, 1]], 300: [[1, 2]], 400: [[2, 1]], 500: [[3, 1]], 600: [[3, 3]],
}

var idx := 0                 # số từ đã trả lời đúng liên tiếp (= vị trí từ hiện tại)
var best := 0
var rounds_done := 0         # số lần hoàn thành cả 600 từ
var options: Array = []      # 4 nghĩa
var answer := 0
var locked := false
var wait_t := 0.0
var rng := RandomNumberGenerator.new()

var lesson_l: Label
var word_l: Label
var count_l: Label
var bar: ProgressBar
var next_l: Label
var opt_btns: Array = []


func _init() -> void:
	title_text = "TOEIC 600"


func _build_game() -> void:
	rng.randomize()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.panel_box(Color("fffaf0"), Color("7a4a24"), 28.0))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.custom_minimum_size = Vector2(820, 0)
	panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	lesson_l = label("", 19, Color("6b5a44"))
	lesson_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lesson_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(lesson_l)
	count_l = label("", 21, Color("7a3a14"), HORIZONTAL_ALIGNMENT_RIGHT)
	count_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(count_l)
	bar = ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 16
	bar.max_value = 600
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("4a9be8")
	fill.set_corner_radius_all(6)
	var bgs := StyleBoxFlat.new()
	bgs.bg_color = Color("d9ccb0")
	bgs.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bgs)
	v.add_child(bar)
	word_l = label("", 54, Color("2b3a2e"), HORIZONTAL_ALIGNMENT_CENTER)
	word_l.custom_minimum_size.y = 96
	word_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	v.add_child(word_l)
	v.add_child(label("Chọn nghĩa đúng:", 18, Color("6b5a44"), HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	v.add_child(grid)
	for i in 4:
		var b := button("", func(): _choose(i), Color("4a5866"))
		b.custom_minimum_size = Vector2(400, 76)
		b.add_theme_font_size_override("font_size", 21)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		grid.add_child(b)
		opt_btns.append(b)
	next_l = label("", 17, Color("2f6a3a"), HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(next_l)
	var d := load_state("toeic")
	idx = clampi(int(d.get("tu", 0)), 0, Words.WORDS.size() - 1)
	best = int(d.get("cao_nhat", 0))
	rounds_done = int(d.get("xong", 0))
	_show_word()


func _on_open() -> void:
	_refresh()


func _save() -> void:
	save_state("toeic", {"tu": idx, "cao_nhat": best, "xong": rounds_done})


func _refresh() -> void:
	if count_l == null:
		return
	count_l.text = "Từ %d / 600" % (idx + 1)
	bar.value = idx
	lesson_l.text = "Bài %d: %s" % [idx / 12 + 1, Words.LESSONS[idx / 12]]
	info_l.text = "Kỷ lục: %d từ liên tiếp" % best
	var nxt := (idx / 100 + 1) * 100
	next_l.text = "Mốc %d từ: %s" % [nxt, _reward_text(nxt)]


func _reward_text(m: int) -> String:
	match m:
		100: return "1 hạt Thường"
		200: return "1 hạt Hiếm"
		300: return "2 hạt Hiếm"
		400: return "1 hạt Quý"
		500: return "1 hạt Huyền thoại"
		600: return "3 hạt Huyền thoại chưa có trong Sổ tay"
	return ""


func _show_word() -> void:
	var w: Array = Words.WORDS[idx]
	word_l.text = w[0]
	# 3 nghĩa sai lấy ngẫu nhiên từ các từ khác (không trùng nghĩa đúng)
	var wrong: Array = []
	var used := {w[1]: true}
	while wrong.size() < 3:
		var o: Array = Words.WORDS[rng.randi() % Words.WORDS.size()]
		if used.has(o[1]):
			continue
		used[o[1]] = true
		wrong.append(o[1])
	options = wrong
	answer = rng.randi() % 4
	options.insert(answer, w[1])
	for i in 4:
		var b: Button = opt_btns[i]
		b.text = options[i]
		UiSkin.style_button(b, Color("4a5866"), UiSkin.SILVER)
		b.disabled = false
	locked = false
	_refresh()


func _choose(i: int) -> void:
	if locked or is_paused():
		return
	locked = true
	UiSkin.style_button(opt_btns[answer], Color("3e8d4a"), GOLD)
	if i == answer:
		idx += 1
		best = maxi(best, idx)
		var done := idx
		if idx >= Words.WORDS.size():
			rounds_done += 1
			idx = 0
		_save()
		if REWARDS.has(done):
			_give_milestone(done)
		else:
			wait_t = 0.45
	else:
		UiSkin.style_button(opt_btns[i], Color("b8473a"), GOLD)
		var w: Array = Words.WORDS[idx]
		var reached := idx
		idx = 0
		_save()
		show_modal("Sai rồi!", "\"%s\" nghĩa là: %s\n\nBạn đã đúng %d từ liên tiếp. Học lại từ từ đầu tiên nhé!" % [w[0], w[1], reached],
			[["Học lại từ đầu", func(): _show_word()], ["Về vườn", func(): _show_word(); _go_back(), Color("4a5866")]])


func _give_milestone(m: int) -> void:
	var lines: PackedStringArray = []
	var avoid: Array = []
	for spec in REWARDS[m]:
		for k in spec[1]:
			var gen: Dictionary = gs.make_seed(spec[0], m == 600, avoid)
			avoid.append(Gen.variety_key(gen))
			var where: String = gs.give_seed(gen)
			lines.append("• Hạt %s: %s (%s)" % [Data.RARITY_NAMES[Gen.rarity(gen)], Gen.variety_name(gen), where])
	garden_changed.emit()
	var title := "Đúng %d từ liên tiếp!" % m
	var body := "Phần thưởng:\n" + "\n".join(lines)
	if m == 600:
		body += "\n\nBạn đã học hết 600 từ TOEIC! Vòng mới sẽ bắt đầu lại từ từ đầu tiên."
	locked = true
	show_modal(title, body, [["Học tiếp", func(): _show_word()]])


func _process(delta: float) -> void:
	super(delta)
	if wait_t > 0.0 and not is_paused():
		wait_t -= delta
		if wait_t <= 0.0:
			_show_word()
