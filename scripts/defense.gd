extends Control
## Mini game "Phòng thủ khu vườn" (mở bằng ô cửa sổ thứ nhất trong nhà kính).
## Côn trùng có hại bò theo đường đất; người chơi đặt chậu hoa phòng thủ trên cỏ.
## - Tiền trong game là đồng bạc (riêng, không phải xu ngoài vườn).
## - 99 vòng, cứ 2 vòng thường thì vòng thứ 3 có boss. Boss ốc sên đến ở vòng 44, 55, 66, 77, 88, 99.
## - Diệt boss nhận phân bón cho cây ngoài vườn (boss ốc sên: 3 túi).
## - Bắt đầu chỉ có Hoa sao; mở khóa: Xương rồng (6 boss), Hoa sen (10 boss), Hoa hồng (12 boss),
##   Tulip (diệt boss ốc sên). Côn trùng phòng thủ (bọ cánh cam, chuồn chuồn) mở khi diệt 3 boss.
## - Nâng cấp cây: Thường → Hiếm → Quý → Huyền thoại (Quý trở lên cần tinh dầu hoa hồng).
## Tiến trình lưu vào GameState.defense ở đầu và cuối mỗi vòng.

signal back_pressed
signal garden_changed

const Data := preload("res://scripts/data.gd")
const Gen := preload("res://scripts/genetics.gd")
const PlantView := preload("res://scripts/plant_view.gd")
const UiSkin := preload("res://scripts/ui_skin.gd")
const FONT_BOLD := preload("res://fonts/Lora-700.ttf")
const FONT_MEDIUM := preload("res://fonts/Lora-500.ttf")

const COLS := 14
const ROWS := 8
const TOP_H := 74.0
const SIDE_W := 250.0
const MAX_ROUND := 99
const START_SILVER := 120
const START_LIVES := 20
const GOLD := Color("d9b26a")

## Đường đi (toạ độ ô). Bắt đầu ngoài mép trái, kết thúc ngoài mép phải.
const PATH := [Vector2(-1, 1), Vector2(2, 1), Vector2(2, 6), Vector2(6, 6), Vector2(6, 1), Vector2(10, 1), Vector2(10, 6), Vector2(14, 6)]

## "can": sát thương mỗi giây khi cắn bọ cánh cam đang chặn đường.
## "bay": không bị bọ cánh cam chặn, nhưng bị chuồn chuồn chặn (đốt chuồn chuồn 3 lần thì nó biến mất).
const ENEMIES := {
	"sau": {"ten": "Sâu xanh", "mau": 28.0, "toc": 1.0, "bac": 3, "mang": 1, "co": 0.72, "can": 6.0},
	"bo_xit": {"ten": "Bọ xít", "mau": 55.0, "toc": 0.85, "bac": 5, "mang": 1, "co": 0.74, "can": 9.0},
	"ret": {"ten": "Rết", "mau": 95.0, "toc": 1.15, "bac": 7, "mang": 2, "co": 0.9, "can": 14.0},
	"chau_chau": {"ten": "Châu chấu", "mau": 80.0, "toc": 1.7, "bac": 8, "mang": 2, "co": 0.84, "can": 12.0},
	"boss_ret": {"ten": "Rết ba đầu", "mau": 340.0, "toc": 0.55, "bac": 50, "mang": 5, "co": 1.5, "boss": true, "can": 40.0},
	"boss_nhen": {"ten": "Nhện chúa", "mau": 290.0, "toc": 0.7, "bac": 50, "mang": 5, "co": 1.45, "boss": true, "can": 40.0},
	"boss_ong": {"ten": "Ong bắp cày chúa", "mau": 250.0, "toc": 0.95, "bac": 50, "mang": 5, "co": 1.4, "boss": true, "can": 40.0, "bay": true},
	"boss_oc": {"ten": "Ốc sên chúa", "mau": 1200.0, "toc": 0.35, "bac": 150, "mang": 10, "co": 1.7, "boss": true, "can": 60.0, "oc": true},
}
const SNAIL_ROUNDS := [44, 55, 66, 77, 88, 99]

## Côn trùng phòng thủ: thả từ cổng vườn, đi ngược đường về phía côn trùng có hại.
const ALLY_ORDER := ["bo_canh_cam", "chuon_chuon"]
const ALLIES := {
	"bo_canh_cam": {"ten": "Bọ cánh cam", "gia": 30, "mo": 3, "toc": 0.9, "mau": 60.0,
		"mo_ta": "Đi ngược đường chặn địch. Bị cắn hết máu thì biến mất.",
		"nang_cap": "+25% máu mỗi cấp, chỉ tốn bạc, không giới hạn."},
	"chuon_chuon": {"ten": "Chuồn chuồn", "gia": 45, "mo": 8, "toc": 2.4, "tam": 2.2, "nap": 0.7, "dam": 14.0,
		"mo_ta": "Bay nhanh về cổng địch, bắn 2 đạn gai, không bị cản. Chặn được ong bắp cày chúa (bị đốt 3 lần thì biến mất).",
		"nang_cap": "Bay chậm lại (bắn được lâu hơn), chỉ tốn tinh dầu.", "cap_toi_da": 8},
}
const ALLY_COOLDOWN := 1.5
const STING_TIME := 0.8      # ong bắp cày chúa đốt chuồn chuồn mỗi 0.8 giây
const STINGS_TO_KILL := 3
const BOSS_ORDER := ["boss_ret", "boss_nhen", "boss_ong"]

const TOWER_ORDER := ["sao", "xuong_rong", "sen", "hong", "tulip"]
const TOWERS := {
	"sao": {"ten": "Hoa sao", "gia": 50, "mo": 0, "hoa": "sao", "mau": "vang",
		"mo_ta": "Bắn đạn sao nhỏ vào một con.",
		"huyen_thoai": "Đạn sao lớn, sát thương cao, văng trúng con bên cạnh.",
		"tam": [2.4, 2.5, 2.6, 2.8], "nap": 0.8, "dam": [10.0, 18.0, 32.0, 55.0]},
	"hong": {"ten": "Hoa hồng", "gia": 85, "mo": 12, "hoa": "hong", "mau": "do",
		"mo_ta": "Tiết tinh dầu để nâng cấp cây.",
		"huyen_thoai": "Dây gai mọc từ đất lên trói một con, rút máu từ từ đến chết (boss chỉ bị làm chậm).",
		"tam": [2.4, 2.4, 2.4, 2.4], "tinh_dau": [10.0, 8.5, 7.0, 5.5], "dam": [0.0, 0.0, 0.0, 14.0]},
	"tulip": {"ten": "Hoa tulip", "gia": 100, "mo": -1, "hoa": "tulip", "mau": "tim",
		"mo_ta": "Tạo vùng làm chậm côn trùng đi qua.",
		"huyen_thoai": "Vùng làm chậm còn làm mất máu.",
		"tam": [1.5, 1.7, 1.9, 2.2], "cham": [0.30, 0.38, 0.46, 0.55], "dam": [0.0, 0.0, 0.0, 20.0]},
	"sen": {"ten": "Hoa sen", "gia": 75, "mo": 10, "hoa": "sen", "mau": "hongnhat",
		"mo_ta": "Bắn tia nước đóng băng một con (boss chỉ bị làm chậm).",
		"huyen_thoai": "Bắn cùng lúc 2 tia nước.",
		"tam": [3.0, 3.0, 3.1, 3.2], "nap": 2.6, "dam": [8.0, 14.0, 24.0, 40.0], "bang": [1.0, 1.3, 1.6, 2.0]},
	"xuong_rong": {"ten": "Xương rồng", "gia": 65, "mo": 6, "hoa": "xr_cao", "mau": "trang",
		"mo_ta": "Bắn gai mọi con ở gần (2 ô).",
		"huyen_thoai": "Bắn gai xa gấp đôi.",
		"tam": [1.6, 1.65, 1.7, 3.4], "nap": 1.2, "dam": [9.0, 16.0, 28.0, 48.0]},
}
const TIER_FLOWER := ["", "xanh", "tim", "cauvong"]   # màu hoa theo bậc ("" = màu riêng của cây)
## Giá nâng lên bậc 1, 2, 3: [hệ số giá bạc, tinh dầu]
const UPGRADE := [[0.0, 0], [0.8, 0], [1.6, 6], [3.2, 18]]

var gs: Node
var paused_check: Callable

# --- trạng thái ván chơi ---
var round_no := 1          # vòng sắp chơi / đang chơi
var silver := START_SILVER
var essence := 0
var lives := START_LIVES
var bosses := 0            # số boss đã diệt trong ván này
var snail_killed := false  # đã diệt boss ốc sên (mở khóa Tulip)
var ally_lv := {"bo_canh_cam": 0, "chuon_chuon": 0}
var ally_cd := 0.0
var allies: Array = []     # côn trùng phòng thủ đang trên đường
var ally_btns := {}        # loại -> {"tha": Button, "nang": Button, "mo_ta": Label}
var best := 0
var towers: Array = []     # {"c","r","kind","tier","spent","cd","node","vine"}
var enemies: Array = []
var shots: Array = []      # đạn bay
var fx: Array = []         # hiệu ứng ngắn
var spawn_queue: Array = []
var spawn_t := 0.0
var in_wave := false
var game_over := false
var speed := 1
var auto_next := false
var auto_t := 0.0
var selected_kind := ""    # loại cây đang chọn để đặt
var info_tower: Dictionary = {}
var hover_cell := Vector2i(-99, -99)
var time := 0.0
var _rng := RandomNumberGenerator.new()

# --- giao diện ---
var map: Control
var fxl: Control
var tower_layer: Control
var round_l: Label
var lives_l: Label
var silver_l: Label
var essence_l: Label
var start_b: Button
var speed_b: Button
var auto_b: Button
var shop_box: VBoxContainer
var shop_btns := {}
var info_panel: PanelContainer
var info_box: VBoxContainer
var toast_l: Label
var toast_t := 0.0
var end_panel: PanelContainer

static var _tex := {}


func _ready() -> void:
	gs = get_node("/root/GameState")
	_rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_load()


# =====================================================================
# Giao diện
# =====================================================================

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("4f7a3a")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	map = MapView.new()
	map.game = self
	add_child(map)
	tower_layer = Control.new()
	tower_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tower_layer)
	fxl = FxView.new()
	fxl.game = self
	fxl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fxl)

	# Thanh trên
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", UiSkin.bevel_box(Color("5e3b22"), GOLD, 0, "normal", Vector4(10, 6, 10, 6)))
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = TOP_H
	add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	top.add_child(row)
	var back := _btn("Về vườn", func(): _go_back(), Color("4a5866"))
	back.custom_minimum_size = Vector2(150, 52)
	row.add_child(back)
	round_l = _hud_label(Color("fff1cf"))
	row.add_child(round_l)
	lives_l = _hud_label(Color("ffb3b3"))
	row.add_child(lives_l)
	silver_l = _hud_label(Color("e8eef2"))
	row.add_child(silver_l)
	essence_l = _hud_label(Color("ffc2dc"))
	row.add_child(essence_l)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	auto_b = _btn("Tự động: Tắt", func(): _toggle_auto(), Color("4a5866"))
	auto_b.custom_minimum_size = Vector2(180, 52)
	row.add_child(auto_b)
	speed_b = _btn("Tốc độ x1", func(): _toggle_speed(), Color("4a5866"))
	speed_b.custom_minimum_size = Vector2(150, 52)
	row.add_child(speed_b)
	start_b = _btn("Bắt đầu vòng", func(): start_wave(), Color("3e7d4a"))
	start_b.custom_minimum_size = Vector2(200, 52)
	row.add_child(start_b)

	# Cột cây bên phải
	var side := PanelContainer.new()
	side.add_theme_stylebox_override("panel", UiSkin.panel_box(Color("f3e3c0"), Color("7a4a24"), 10.0))
	side.anchor_left = 1.0
	side.anchor_right = 1.0
	side.anchor_bottom = 1.0
	side.offset_left = -SIDE_W
	side.offset_top = TOP_H
	add_child(side)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	shop_box = VBoxContainer.new()
	shop_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_box.add_theme_constant_override("separation", 6)
	scroll.add_child(shop_box)
	var head := _label("Cây phòng thủ", 20, Color("5e3b22"), HORIZONTAL_ALIGNMENT_CENTER)
	shop_box.add_child(head)
	for k in TOWER_ORDER:
		var b := TowerButton.new()
		b.game = self
		b.kind = k
		b.custom_minimum_size = Vector2(0, 104)
		b.pressed.connect(func(): _select_kind(k))
		shop_box.add_child(b)
		shop_btns[k] = b
	var hint := _label("Chọn cây rồi chạm vào ô cỏ để đặt. Chạm vào cây đã đặt để nâng cấp.", 15, Color("6b5a44"))
	shop_box.add_child(hint)
	shop_box.add_child(_label("Côn trùng phòng thủ", 20, Color("5e3b22"), HORIZONTAL_ALIGNMENT_CENTER))
	for k in ALLY_ORDER:
		shop_box.add_child(_ally_card(k))

	# Bảng thông tin cây
	info_panel = PanelContainer.new()
	info_panel.add_theme_stylebox_override("panel", UiSkin.panel_box(Color("fffaf0"), Color("7a4a24"), 16.0))
	info_panel.visible = false
	info_panel.z_index = 50
	add_child(info_panel)
	info_box = VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 6)
	info_panel.add_child(info_box)

	toast_l = Label.new()
	toast_l.add_theme_font_override("font", FONT_BOLD)
	toast_l.add_theme_font_size_override("font_size", 24)
	toast_l.add_theme_color_override("font_color", Color("fff6d8"))
	toast_l.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0, 0.9))
	toast_l.add_theme_constant_override("outline_size", 7)
	toast_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_l.z_index = 60
	add_child(toast_l)

	end_panel = PanelContainer.new()
	end_panel.add_theme_stylebox_override("panel", UiSkin.panel_box(Color("fffaf0"), Color("7a4a24"), 24.0))
	end_panel.visible = false
	end_panel.z_index = 80
	add_child(end_panel)


## Thẻ côn trùng phòng thủ: tên, mô tả, nút Thả và nút Nâng cấp.
func _ally_card(kind: String) -> Control:
	var info: Dictionary = ALLIES[kind]
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiSkin.bevel_box(Color("fffaf0"), Color("a8875a"), 10, "normal", Vector4(8, 6, 8, 8)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	card.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var icon := TextureRect.new()
	icon.texture = tex(kind)
	icon.custom_minimum_size = Vector2(52, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(icon)
	var name_l := _label(info["ten"], 18, Color("3a2614"))
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(name_l)
	var desc := _label("", 13, Color("5a4a3a"))
	desc.custom_minimum_size.x = 200
	v.add_child(desc)
	var tha := _btn("", func(): release_ally(kind), Color("3e7d4a"))
	tha.add_theme_font_size_override("font_size", 15)
	tha.custom_minimum_size = Vector2(0, 40)
	v.add_child(tha)
	var nang := _btn("", func(): upgrade_ally(kind), Color("6a5a8a"))
	nang.add_theme_font_size_override("font_size", 14)
	nang.custom_minimum_size = Vector2(0, 40)
	v.add_child(nang)
	ally_btns[kind] = {"tha": tha, "nang": nang, "mo_ta": desc}
	return card


func _refresh_allies() -> void:
	for k in ally_btns:
		var b: Dictionary = ally_btns[k]
		var info: Dictionary = ALLIES[k]
		var open: bool = unlocked(k)
		var lv: int = ally_lv[k]
		if not open:
			b["mo_ta"].text = lock_text(k)
		elif k == "bo_canh_cam":
			b["mo_ta"].text = "%s\nCấp %d · máu %d" % [info["mo_ta"], lv, int(ally_hp(lv))]
		else:
			b["mo_ta"].text = "%s\nCấp %d · tốc độ bay %.1f ô/giây" % [info["mo_ta"], lv, ally_speed(k)]
		b["tha"].text = "Thả (%d bạc)" % info["gia"]
		b["tha"].disabled = not open or not in_wave or silver < int(info["gia"])
		var cost := ally_upgrade_cost(k)
		if cost.is_empty():
			b["nang"].text = "Đã tối đa"
			b["nang"].disabled = true
		else:
			b["nang"].text = "Nâng cấp: %s" % ("%d bạc" % cost[0] if cost[0] > 0 else "%d tinh dầu" % cost[1])
			b["nang"].disabled = not open or silver < cost[0] or essence < cost[1]


func _hud_label(col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", FONT_BOLD)
	l.add_theme_font_size_override("font_size", 23)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", 4)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


func _label(text: String, fs := 18, col := Color("2b3a2e"), align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT_BOLD if fs >= 18 else FONT_MEDIUM)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _btn(text: String, cb: Callable, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 19)
	UiSkin.style_button(b, col, UiSkin.SILVER if col.s < 0.35 else GOLD)
	b.pressed.connect(cb)
	return b


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout()


func _layout() -> void:
	var area := Rect2(Vector2(0, TOP_H), Vector2(size.x - SIDE_W, size.y - TOP_H))
	var cell: float = minf(area.size.x / COLS, area.size.y / ROWS)
	var grid := Vector2(cell * COLS, cell * ROWS)
	var origin := area.position + (area.size - grid) / 2.0
	for n in [map, fxl, tower_layer]:
		n.position = origin
		n.size = grid
	map.cell = cell
	fxl.cell = cell
	for t in towers:
		_place_node(t)
	toast_l.position = Vector2(origin.x, TOP_H + 14)
	toast_l.size = Vector2(grid.x, 40)
	_position_panels()
	map.queue_redraw()


func cell_size() -> float:
	return map.cell


# =====================================================================
# Lưu / nạp
# =====================================================================

func _load() -> void:
	var d: Dictionary = gs.defense if typeof(gs.defense) == TYPE_DICTIONARY else {}
	best = int(d.get("ky_luc", 0))
	if d.is_empty() or bool(d.get("thua", false)):
		_new_run(false)
		return
	round_no = clampi(int(d.get("vong", 1)), 1, MAX_ROUND + 1)
	silver = int(d.get("bac", START_SILVER))
	essence = int(d.get("tinh_dau", 0))
	lives = int(d.get("mang", START_LIVES))
	bosses = int(d.get("boss", 0))
	snail_killed = bool(d.get("oc", false))
	ally_lv = {"bo_canh_cam": int(d.get("bo_lv", 0)), "chuon_chuon": int(d.get("chuon_lv", 0))}
	for t in d.get("cay", []):
		if typeof(t) == TYPE_DICTIONARY and TOWERS.has(str(t.get("kind", ""))):
			_add_tower(int(t["c"]), int(t["r"]), str(t["kind"]), clampi(int(t.get("tier", 0)), 0, 3), int(t.get("spent", 0)))
	_refresh_hud()
	if round_no > MAX_ROUND:
		_show_victory()


func _save() -> void:
	var list: Array = []
	for t in towers:
		list.append({"c": t["c"], "r": t["r"], "kind": t["kind"], "tier": t["tier"], "spent": t["spent"]})
	gs.defense = {"vong": round_no, "bac": silver, "tinh_dau": essence, "mang": lives, "boss": bosses,
		"cay": list, "ky_luc": best, "thua": game_over, "oc": snail_killed,
		"bo_lv": ally_lv["bo_canh_cam"], "chuon_lv": ally_lv["chuon_chuon"]}
	gs.save_game()


func _new_run(save := true) -> void:
	for t in towers:
		t["node"].queue_free()
	towers.clear()
	enemies.clear()
	allies.clear()
	shots.clear()
	fx.clear()
	spawn_queue.clear()
	snail_killed = false
	ally_lv = {"bo_canh_cam": 0, "chuon_chuon": 0}
	round_no = 1
	silver = START_SILVER
	essence = 0
	lives = START_LIVES
	bosses = 0
	in_wave = false
	game_over = false
	selected_kind = ""
	_close_info()
	end_panel.visible = false
	if save:
		_save()
	_refresh_hud()


# =====================================================================
# Đường đi và ô
# =====================================================================

static var _path_cells := {}

static func path_cells() -> Dictionary:
	if _path_cells.is_empty():
		for i in PATH.size() - 1:
			var a: Vector2 = PATH[i]
			var b: Vector2 = PATH[i + 1]
			var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
			for s in steps + 1:
				var p := a + (b - a) * (float(s) / steps)
				_path_cells[Vector2i(int(p.x), int(p.y))] = true
	return _path_cells


static func path_length() -> float:
	var l := 0.0
	for i in PATH.size() - 1:
		l += (PATH[i + 1] - PATH[i]).length()
	return l


## Vị trí (toạ độ ô, tâm ô = +0.5) khi đã đi được quãng d.
static func path_pos(d: float) -> Vector2:
	for i in PATH.size() - 1:
		var seg: float = (PATH[i + 1] - PATH[i]).length()
		if d <= seg:
			return PATH[i] + (PATH[i + 1] - PATH[i]).normalized() * d + Vector2(0.5, 0.5)
		d -= seg
	return PATH.back() + Vector2(0.5, 0.5)


static func path_dir(d: float) -> Vector2:
	for i in PATH.size() - 1:
		var seg: float = (PATH[i + 1] - PATH[i]).length()
		if d <= seg:
			return (PATH[i + 1] - PATH[i]).normalized()
		d -= seg
	return Vector2.RIGHT


func cell_free(c: int, r: int) -> bool:
	if c < 0 or r < 0 or c >= COLS or r >= ROWS:
		return false
	if path_cells().has(Vector2i(c, r)):
		return false
	return tower_at(c, r).is_empty()


func tower_at(c: int, r: int) -> Dictionary:
	for t in towers:
		if t["c"] == c and t["r"] == r:
			return t
	return {}


# =====================================================================
# Cây phòng thủ
# =====================================================================

func unlocked(kind: String) -> bool:
	if ALLIES.has(kind):
		return bosses >= int(ALLIES[kind]["mo"])
	if int(TOWERS[kind]["mo"]) < 0:
		return snail_killed
	return bosses >= int(TOWERS[kind]["mo"])


func lock_text(kind: String) -> String:
	var m: int = int(ALLIES[kind]["mo"]) if ALLIES.has(kind) else int(TOWERS[kind]["mo"])
	if m < 0:
		return "Diệt boss ốc sên (vòng 44) để mở khóa"
	return "Diệt %d boss để mở khóa (đã diệt %d)" % [m, bosses]


func _select_kind(kind: String) -> void:
	if not unlocked(kind):
		toast("%s: %s." % [TOWERS[kind]["ten"], lock_text(kind)])
		return
	_close_info()
	selected_kind = "" if selected_kind == kind else kind
	if selected_kind != "":
		toast("Chạm vào ô cỏ để đặt %s (%d bạc)." % [TOWERS[kind]["ten"], TOWERS[kind]["gia"]])
	_refresh_shop()
	map.queue_redraw()


func on_cell_tapped(c: int, r: int) -> void:
	if game_over:
		return
	var t := tower_at(c, r)
	if not t.is_empty():
		selected_kind = ""
		_refresh_shop()
		_open_info(t)
		return
	_close_info()
	if path_cells().has(Vector2i(c, r)):
		return
	if selected_kind == "":
		toast("Chọn một cây ở cột bên phải trước.")
		return
	build(selected_kind, c, r)


func build(kind: String, c: int, r: int) -> bool:
	if not cell_free(c, r) or not unlocked(kind):
		return false
	var price: int = TOWERS[kind]["gia"]
	if silver < price:
		toast("Không đủ bạc (cần %d)." % price)
		return false
	silver -= price
	_add_tower(c, r, kind, 0, price)
	fx.append({"type": "puff", "p": Vector2(c + 0.5, r + 0.6), "t": 0.0, "d": 0.5})
	_refresh_hud()
	map.queue_redraw()
	return true


func _add_tower(c: int, r: int, kind: String, tier: int, spent: int) -> Dictionary:
	var pv := Control.new()
	pv.set_script(PlantView)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tower_layer.add_child(pv)
	var t := {"c": c, "r": r, "kind": kind, "tier": tier, "spent": spent, "cd": 0.0, "node": pv, "vine": null, "tinh_t": 0.0}
	towers.append(t)
	_style_tower(t)
	_place_node(t)
	# hàng dưới vẽ đè lên hàng trên
	var order := towers.duplicate()
	order.sort_custom(func(a, b): return a["r"] < b["r"])
	for i in order.size():
		tower_layer.move_child(order[i]["node"], i)
	return t


func _style_tower(t: Dictionary) -> void:
	var info: Dictionary = TOWERS[t["kind"]]
	var m: String = TIER_FLOWER[t["tier"]] if t["tier"] > 0 else str(info["mau"])
	t["node"].set_pheno({"hoa": info["hoa"], "mau": m, "la": "tron", "than": "thang", "co": "vua"}, 3)


func _place_node(t: Dictionary) -> void:
	var cs := cell_size()
	var pv: Control = t["node"]
	var w := cs * 1.0
	var h := w * 542.0 / 300.0
	pv.size = Vector2(w, h)
	pv.position = Vector2(t["c"] * cs + (cs - w) / 2.0, (t["r"] + 1) * cs - h + cs * 0.04)


func upgrade_cost(t: Dictionary) -> Array:
	var nt: int = t["tier"] + 1
	if nt > 3:
		return []
	var price: int = int(round(TOWERS[t["kind"]]["gia"] * UPGRADE[nt][0]))
	return [price, int(UPGRADE[nt][1])]


func upgrade(t: Dictionary) -> bool:
	var cost := upgrade_cost(t)
	if cost.is_empty():
		return false
	if silver < cost[0]:
		toast("Không đủ bạc (cần %d)." % cost[0])
		return false
	if essence < cost[1]:
		toast("Cần %d tinh dầu hoa hồng. Trồng Hoa hồng để có tinh dầu." % cost[1])
		return false
	silver -= cost[0]
	essence -= cost[1]
	t["spent"] += cost[0]
	t["tier"] += 1
	_style_tower(t)
	fx.append({"type": "spark", "p": Vector2(t["c"] + 0.5, t["r"] + 0.3), "t": 0.0, "d": 0.8, "col": Data.RARITY_COLORS[t["tier"]]})
	if t["tier"] == 3:
		toast("%s đạt bậc Huyền thoại: %s" % [TOWERS[t["kind"]]["ten"], TOWERS[t["kind"]]["huyen_thoai"]])
	_refresh_hud()
	_open_info(t)
	return true


func sell(t: Dictionary) -> void:
	var back := int(t["spent"] * 0.6)
	silver += back
	t["node"].queue_free()
	towers = towers.filter(func(x): return not is_same(x, t))
	_close_info()
	toast("Đã bán cây, nhận lại %d bạc." % back)
	_refresh_hud()
	map.queue_redraw()


func tower_range(t: Dictionary) -> float:
	return TOWERS[t["kind"]]["tam"][t["tier"]]


# =====================================================================
# Vòng chơi
# =====================================================================

func is_boss_round(r: int) -> bool:
	return r % 3 == 0


func is_snail_round(r: int) -> bool:
	return SNAIL_ROUNDS.has(r)


func hp_mult(r: int) -> float:
	var k := float(r - 1)
	return 1.0 + 0.12 * k + 0.0012 * k * k


func start_wave() -> void:
	if in_wave or game_over or round_no > MAX_ROUND:
		return
	_save()   # lưu trạng thái đầu vòng: thoát giữa chừng thì chơi lại vòng này
	in_wave = true
	auto_t = 0.0
	spawn_queue = _make_wave(round_no)
	spawn_t = 0.5
	if is_snail_round(round_no):
		toast("Vòng %d: Ốc sên chúa xuất hiện! Diệt nó để nhận 3 túi phân bón." % round_no, 3.5)
	elif is_boss_round(round_no):
		toast("Vòng %d: %s xuất hiện!" % [round_no, ENEMIES[_boss_of(round_no)]["ten"]])
	else:
		toast("Vòng %d bắt đầu!" % round_no)
	_refresh_hud()


func _boss_of(r: int) -> String:
	return BOSS_ORDER[(r / 3 - 1) % BOSS_ORDER.size()]


func _make_wave(r: int) -> Array:
	var kinds := ["sau"]
	if r >= 3:
		kinds.append("bo_xit")
	if r >= 7:
		kinds.append("ret")
	if r >= 12:
		kinds.append("chau_chau")
	var n := mini(6 + int(r * 0.7), 45)
	if is_boss_round(r):
		n = maxi(4, n / 2)
	var gap := maxf(0.35, 1.0 - r * 0.012)
	var q: Array = []
	for i in n:
		# loài mới hay xuất hiện hơn loài cũ một chút
		var w := []
		for j in kinds.size():
			for _k in j + 1:
				w.append(kinds[j])
		q.append({"kind": w[_rng.randi() % w.size()], "gap": gap})
		if is_boss_round(r) and i == n / 2:
			q.append({"kind": _boss_of(r), "gap": gap * 2.0})
		if is_snail_round(r) and i == n / 3:
			q.append({"kind": "boss_oc", "gap": gap * 2.0})
	return q


func _spawn(kind: String) -> void:
	var info: Dictionary = ENEMIES[kind]
	var hp: float = info["mau"] * hp_mult(round_no)
	enemies.append({"kind": kind, "hp": hp, "max": hp, "d": 0.0, "dead": false, "slow": 1.0, "freeze": 0.0,
		"bound": false, "boss": info.get("boss", false), "hit": 0.0, "wob": _rng.randf() * TAU})


func _process(delta: float) -> void:
	if not visible:
		return
	if paused_check.is_valid() and paused_check.call():
		return
	if toast_t > 0.0:
		toast_t -= delta
		toast_l.modulate.a = clampf(toast_t / 0.4, 0.0, 1.0)
	for _i in speed:
		step(delta)
	fxl.queue_redraw()


func step(dt: float) -> void:
	time += dt
	if game_over:
		return
	# hiệu ứng
	for e in fx:
		e["t"] += dt
	fx = fx.filter(func(e): return e["t"] < e["d"])
	if not in_wave:
		if auto_next and round_no <= MAX_ROUND:
			auto_t += dt
			if auto_t > 2.0:
				start_wave()
		return
	# thả côn trùng
	if not spawn_queue.is_empty():
		spawn_t -= dt
		if spawn_t <= 0.0:
			var s: Dictionary = spawn_queue.pop_front()
			_spawn(s["kind"])
			spawn_t = s["gap"]
	ally_cd = maxf(0.0, ally_cd - dt)
	_update_allies(dt)
	_update_towers(dt)
	_update_shots(dt)
	_update_enemies(dt)
	allies = allies.filter(func(x): return not x["dead"])
	enemies = enemies.filter(func(x): return not x["dead"])
	if spawn_queue.is_empty() and enemies.is_empty() and not game_over:
		for a in allies:
			fx.append({"type": "puff", "p": _ally_pos(a), "t": 0.0, "d": 0.5})
		allies.clear()
		_end_wave()


func _update_enemies(dt: float) -> void:
	var total := path_length()
	var gone: Array = []
	for e in enemies:
		if e["dead"]:
			continue
		e["hit"] = maxf(0.0, e["hit"] - dt)
		var info: Dictionary = ENEMIES[e["kind"]]
		var v: float = info["toc"] * e["slow"]
		if e["freeze"] > 0.0:
			e["freeze"] -= dt
			v = 0.0
		if e.get("chill", 0.0) > 0.0:
			e["chill"] -= dt
			v *= 0.5
		if e["bound"]:
			v *= 0.4 if e["boss"] else 0.0   # boss: dây gai chỉ làm chậm, không trói
		if e.get("chan", false):
			v = 0.0
			e["chan"] = false
		e["d"] += v * dt
		e["slow"] = 1.0   # tulip đặt lại mỗi khung hình
		if e["d"] >= total and not e["dead"]:
			gone.append(e)
	for e in gone:
		e["dead"] = true
		lives -= int(ENEMIES[e["kind"]]["mang"])
		fx.append({"type": "ouch", "p": Vector2(COLS - 0.6, PATH.back().y + 0.5), "t": 0.0, "d": 0.8})
		if lives <= 0:
			lives = 0
			_lose()
			return
	if not gone.is_empty():
		_refresh_hud()


func _pos(e: Dictionary) -> Vector2:
	return path_pos(e["d"])


# =====================================================================
# Côn trùng phòng thủ
# =====================================================================

func ally_upgrade_cost(kind: String) -> Array:
	## [bạc, tinh dầu] để lên cấp tiếp theo; [] nếu đã tối đa.
	var lv: int = ally_lv[kind]
	if kind == "bo_canh_cam":
		return [40 + 30 * lv + 4 * lv * lv, 0]
	if lv >= int(ALLIES[kind]["cap_toi_da"]):
		return []
	return [0, 3 + 2 * lv]


func ally_hp(lv: int) -> float:
	return ALLIES["bo_canh_cam"]["mau"] * hp_mult(round_no) * (1.0 + 0.25 * lv)


func ally_speed(kind: String) -> float:
	var v: float = ALLIES[kind]["toc"]
	if kind == "chuon_chuon":
		v *= pow(0.88, ally_lv[kind])
	return v


func release_ally(kind: String) -> bool:
	if not unlocked(kind):
		toast("%s: %s." % [ALLIES[kind]["ten"], lock_text(kind)])
		return false
	if not in_wave:
		toast("Bấm Bắt đầu vòng rồi mới thả %s." % ALLIES[kind]["ten"])
		return false
	if ally_cd > 0.0:
		return false
	var price: int = ALLIES[kind]["gia"]
	if silver < price:
		toast("Không đủ bạc (cần %d)." % price)
		return false
	silver -= price
	ally_cd = ALLY_COOLDOWN
	var a := {"kind": kind, "d": path_length(), "dead": false, "cd": 0.3, "wob": _rng.randf() * TAU, "chan": false}
	if kind == "bo_canh_cam":
		a["hp"] = ally_hp(ally_lv[kind])
		a["max"] = a["hp"]
	allies.append(a)
	fx.append({"type": "puff", "p": _ally_pos(a), "t": 0.0, "d": 0.4})
	_refresh_hud()
	return true


func upgrade_ally(kind: String) -> bool:
	if not unlocked(kind):
		toast("%s: %s." % [ALLIES[kind]["ten"], lock_text(kind)])
		return false
	var cost := ally_upgrade_cost(kind)
	if cost.is_empty():
		toast("%s đã đạt cấp tối đa." % ALLIES[kind]["ten"])
		return false
	if silver < cost[0]:
		toast("Không đủ bạc (cần %d)." % cost[0])
		return false
	if essence < cost[1]:
		toast("Cần %d tinh dầu hoa hồng." % cost[1])
		return false
	silver -= cost[0]
	essence -= cost[1]
	ally_lv[kind] += 1
	toast("%s lên cấp %d!" % [ALLIES[kind]["ten"], ally_lv[kind]])
	_refresh_hud()
	return true


func _ally_pos(a: Dictionary) -> Vector2:
	var p := path_pos(a["d"])
	if a["kind"] == "chuon_chuon":
		p += Vector2(0, -0.35 + sin(time * 3.0 + a["wob"]) * 0.12)
	return p


func _update_allies(dt: float) -> void:
	for a in allies:
		if a["dead"]:
			continue
		if a["kind"] == "bo_canh_cam":
			# địch đang chạm bọ cánh cam thì bị chặn lại và cắn nó
			var touching := false
			for e in enemies:
				if e["dead"] or ENEMIES[e["kind"]].get("bay", false):
					continue
				var gap: float = a["d"] - e["d"]
				if gap >= -0.2 and gap <= 0.55:
					touching = true
					e["chan"] = true
					a["hp"] -= ENEMIES[e["kind"]]["can"] * hp_mult(round_no) * dt
			a["chan"] = touching
			if a["hp"] <= 0.0:
				a["dead"] = true
				fx.append({"type": "puff", "p": _ally_pos(a), "t": 0.0, "d": 0.5})
				continue
			if not touching:
				a["d"] -= ally_speed("bo_canh_cam") * dt
		else:
			# chuồn chuồn chặn ong bắp cày chúa (côn trùng bay); bị đốt 3 lần thì biến mất
			var wasp_contact := false
			for e in enemies:
				if e["dead"] or not ENEMIES[e["kind"]].get("bay", false):
					continue
				var gap2: float = a["d"] - e["d"]
				if gap2 >= -0.2 and gap2 <= 0.55:
					wasp_contact = true
					e["chan"] = true
			a["chan"] = wasp_contact
			if wasp_contact:
				a["sting_t"] = a.get("sting_t", 0.0) + dt
				if a["sting_t"] >= STING_TIME:
					a["sting_t"] = 0.0
					a["stings"] = a.get("stings", 0) + 1
					fx.append({"type": "dot", "p": _ally_pos(a), "t": 0.0, "d": 0.4})
					if a["stings"] >= STINGS_TO_KILL:
						a["dead"] = true
						fx.append({"type": "puff", "p": _ally_pos(a), "t": 0.0, "d": 0.5})
						continue
			else:
				a["d"] -= ally_speed("chuon_chuon") * dt
			a["cd"] -= dt
			if a["cd"] <= 0.0:
				var info: Dictionary = ALLIES["chuon_chuon"]
				var me := _ally_pos(a)
				var tg := _targets_in(me, info["tam"])
				if not tg.is_empty():
					a["cd"] = info["nap"]
					var dam: float = info["dam"] * (1.0 + 0.08 * (round_no - 1))
					for k in 2:
						var target: Dictionary = tg[mini(k, tg.size() - 1)]
						shots.append({"p": me + Vector2(0, (k - 0.5) * 0.2), "e": target, "dam": dam,
							"big": false, "type": "gai", "v": 9.0, "rot": 0.0})
		if a["d"] <= 0.0:
			a["dead"] = true
			fx.append({"type": "puff", "p": _ally_pos(a), "t": 0.0, "d": 0.4})


func _targets_in(center: Vector2, rad: float) -> Array:
	var out: Array = []
	for e in enemies:
		if not e["dead"] and _pos(e).distance_to(center) <= rad:
			out.append(e)
	# con đi xa nhất trước
	out.sort_custom(func(a, b): return a["d"] > b["d"])
	return out


func _update_towers(dt: float) -> void:
	for t in towers:
		var c := Vector2(t["c"] + 0.5, t["r"] + 0.5)
		var info: Dictionary = TOWERS[t["kind"]]
		var tier: int = t["tier"]
		var rad := tower_range(t)
		t["cd"] = maxf(0.0, t["cd"] - dt)
		match t["kind"]:
			"sao":
				if t["cd"] <= 0.0:
					var tg := _targets_in(c, rad)
					if not tg.is_empty():
						t["cd"] = info["nap"]
						var big := tier == 3
						shots.append({"p": c + Vector2(0, -0.45), "e": tg[0], "dam": info["dam"][tier] * (1.6 if big else 1.0),
							"big": big, "type": "sao", "v": 7.0, "rot": 0.0})
			"sen":
				if t["cd"] <= 0.0:
					var tg := _targets_in(c, rad)
					if not tg.is_empty():
						t["cd"] = info["nap"]
						var n := 2 if tier == 3 else 1
						# ưu tiên con chưa bị đóng băng
						tg.sort_custom(func(a, b): return (a["freeze"] <= 0.0) and not (b["freeze"] <= 0.0))
						for k in mini(n, tg.size()):
							var e: Dictionary = tg[k]
							var dur: float = info["bang"][tier]
							if e["boss"]:
								e["chill"] = maxf(e.get("chill", 0.0), dur)   # boss: chỉ làm chậm, không đóng băng
							else:
								e["freeze"] = maxf(e["freeze"], dur)
							_hurt(e, info["dam"][tier])
							fx.append({"type": "beam", "a": c + Vector2(0, -0.4), "b": _pos(e), "t": 0.0, "d": 0.35})
			"xuong_rong":
				if t["cd"] <= 0.0:
					var tg := _targets_in(c, rad)
					if not tg.is_empty():
						t["cd"] = info["nap"]
						for e in tg:
							_hurt(e, info["dam"][tier])
						fx.append({"type": "spikes", "p": c, "r": rad, "t": 0.0, "d": 0.4})
			"tulip":
				for e in _targets_in(c, rad):
					e["slow"] = minf(e["slow"], 1.0 - info["cham"][tier])
					if tier == 3:
						_hurt(e, info["dam"][3] * dt, false)
			"hong":
				t["tinh_t"] += dt
				if t["tinh_t"] >= info["tinh_dau"][tier]:
					t["tinh_t"] = 0.0
					essence += 1
					fx.append({"type": "drop", "p": c + Vector2(0, -0.6), "t": 0.0, "d": 1.0})
					_refresh_hud()
				if tier == 3:
					var v = t["vine"]
					if v != null and (v["dead"] or _pos(v).distance_to(c) > rad + 0.6):
						v["bound"] = false
						t["vine"] = null
						v = null
					if v == null:
						for e in _targets_in(c, rad):
							if not e["bound"]:
								e["bound"] = true
								e["vine_t"] = 0.0
								t["vine"] = e
								v = e
								fx.append({"type": "dat", "p": _pos(e), "t": 0.0, "d": 0.6})
								break
					if v != null:
						v["vine_t"] = v.get("vine_t", 0.0) + dt
						_hurt(v, info["dam"][3] * dt, false)


func _update_shots(dt: float) -> void:
	var done: Array = []
	for s in shots:
		var e: Dictionary = s["e"]
		var alive: bool = not e["dead"]
		var target: Vector2 = _pos(e) if alive else s.get("last", s["p"])
		s["last"] = target
		var dvec: Vector2 = target - s["p"]
		var step_len: float = s["v"] * dt
		s["rot"] += dt * 9.0
		if dvec.length() <= step_len:
			done.append(s)
			if alive:
				_hurt(e, s["dam"])
				if s["big"]:
					for o in _targets_in(target, 0.7):
						if o != e:
							_hurt(o, s["dam"] * 0.4)
					fx.append({"type": "burst", "p": target, "t": 0.0, "d": 0.3})
		else:
			s["p"] += dvec.normalized() * step_len
	shots = shots.filter(func(x): return not done.any(func(y): return is_same(x, y)))


func _hurt(e: Dictionary, dam: float, flash := true) -> void:
	if e["dead"]:
		return
	e["hp"] -= dam
	if flash:
		e["hit"] = 0.12
	if e["hp"] <= 0.0:
		_kill(e)


func _kill(e: Dictionary) -> void:
	var info: Dictionary = ENEMIES[e["kind"]]
	var gain := int(round(info["bac"] * (1.0 + 0.03 * (round_no - 1))))
	silver += gain
	var p := _pos(e)
	fx.append({"type": "coin", "p": p, "t": 0.0, "d": 0.9, "n": gain})
	e["dead"] = true
	if e["boss"]:
		bosses += 1
		var bags := 3 if info.get("oc", false) else 1
		gs.fertilizer += bags
		gs._changed()
		var msg := "Diệt %s! Nhận %d túi phân bón cho vườn." % [info["ten"], bags]
		for k in TOWER_ORDER:
			if int(TOWERS[k]["mo"]) == bosses:
				msg += "  Mở khóa %s!" % TOWERS[k]["ten"]
		for k in ALLY_ORDER:
			if int(ALLIES[k]["mo"]) == bosses:
				msg += "  Mở khóa %s!" % ALLIES[k]["ten"]
		if info.get("oc", false) and not snail_killed:
			snail_killed = true
			msg += "  Mở khóa Hoa tulip!"
		toast(msg, 4.5)
		garden_changed.emit()
		_refresh_shop()
	_refresh_hud()


func _end_wave() -> void:
	in_wave = false
	for t in towers:
		t["vine"] = null
	shots.clear()
	var bonus := 8 + round_no
	silver += bonus
	best = maxi(best, round_no)
	round_no += 1
	_save()
	if round_no > MAX_ROUND:
		_show_victory()
	else:
		toast("Xong vòng %d! Thưởng %d bạc." % [round_no - 1, bonus])
	_refresh_hud()


func _lose() -> void:
	game_over = true
	in_wave = false
	spawn_queue.clear()
	best = maxi(best, round_no - 1)
	_save()
	_show_end("Khu vườn bị côn trùng tràn vào!", "Bạn trụ được đến vòng %d.\nKỷ lục: vòng %d." % [round_no, best])


func _show_victory() -> void:
	_show_end("Chiến thắng!", "Bạn đã bảo vệ khu vườn qua cả %d vòng!\nĐã diệt %d boss." % [MAX_ROUND, bosses])


func _show_end(title: String, body: String) -> void:
	_close_info()
	for c in end_panel.get_children():
		c.queue_free()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	end_panel.add_child(v)
	v.add_child(_label(title, 30, Color("7a3a14"), HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(_label(body, 22, Color("2b3a2e"), HORIZONTAL_ALIGNMENT_CENTER))
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)
	var again := _btn("Chơi lại từ đầu", func(): _new_run(), Color("3e7d4a"))
	again.custom_minimum_size = Vector2(230, 56)
	h.add_child(again)
	var back := _btn("Về vườn", func(): _go_back(), Color("4a5866"))
	back.custom_minimum_size = Vector2(160, 56)
	h.add_child(back)
	for l in v.get_children():
		if l is Label:
			l.custom_minimum_size.x = 520
	end_panel.visible = true
	end_panel.reset_size()
	_position_panels.call_deferred()


# =====================================================================
# Giao diện phụ
# =====================================================================

func toast(text: String, dur := 2.6) -> void:
	toast_l.text = text
	toast_t = dur
	toast_l.modulate.a = 1.0


func _toggle_speed() -> void:
	speed = 1 + speed % 3
	speed_b.text = "Tốc độ x%d" % speed


func _toggle_auto() -> void:
	auto_next = not auto_next
	auto_b.text = "Tự động: Bật" if auto_next else "Tự động: Tắt"


func _go_back() -> void:
	_close_info()
	selected_kind = ""
	_refresh_shop()
	back_pressed.emit()


func open() -> void:
	visible = true
	_layout()
	_refresh_hud()
	if in_wave:
		toast("Tiếp tục vòng %d." % round_no)
	elif not game_over and round_no <= MAX_ROUND:
		toast("Đặt cây phòng thủ rồi bấm Bắt đầu vòng.")


func _refresh_hud() -> void:
	if round_l == null:
		return
	var rn := mini(round_no, MAX_ROUND)
	round_l.text = "Vòng %d/%d%s" % [rn, MAX_ROUND, "  (Ốc sên chúa)" if is_snail_round(rn) else ("  (Boss)" if is_boss_round(rn) else "")]
	lives_l.text = "♥ %d" % lives
	silver_l.text = "Bạc %d" % silver
	essence_l.text = "Tinh dầu %d" % essence
	start_b.disabled = in_wave or game_over or round_no > MAX_ROUND
	start_b.text = "Đang đánh…" if in_wave else "Bắt đầu vòng"
	_refresh_shop()
	if not info_tower.is_empty() and info_panel.visible:
		_fill_info(info_tower)


func _refresh_shop() -> void:
	for k in shop_btns:
		shop_btns[k].queue_redraw()
	_refresh_allies()


func _open_info(t: Dictionary) -> void:
	info_tower = t
	_fill_info(t)
	info_panel.visible = true
	map.queue_redraw()


func _fill_info(t: Dictionary) -> void:
	for c in info_box.get_children():
		info_box.remove_child(c)
		c.queue_free()
	var info: Dictionary = TOWERS[t["kind"]]
	var tier: int = t["tier"]
	var lines := [
		_label("%s · %s" % [info["ten"], Data.RARITY_NAMES[tier]], 20, Data.RARITY_COLORS[tier].darkened(0.25)),
		_label(_stat_text(t), 15, Color("3a2614")),
		_label(("Kỹ năng: " if tier == 3 else "Khi Huyền thoại: ") + str(info["huyen_thoai"]), 15, Color("a0600a") if tier == 3 else Color("8a7a66")),
	]
	for l in lines:
		l.custom_minimum_size.x = 420
		info_box.add_child(l)
	var row := HBoxContainer.new()
	info_box.add_child(row)
	var cost := upgrade_cost(t)
	if not cost.is_empty():
		var txt := "Nâng lên %s\n%d bạc" % [Data.RARITY_NAMES[tier + 1], cost[0]]
		if cost[1] > 0:
			txt += " + %d tinh dầu" % cost[1]
		var up := _btn(txt, func(): upgrade(t), Color("3e7d4a"))
		up.add_theme_font_size_override("font_size", 16)
		up.custom_minimum_size = Vector2(210, 64)
		up.disabled = silver < cost[0] or essence < cost[1]
		row.add_child(up)
	var sl := _btn("Bán\n+%d bạc" % int(t["spent"] * 0.6), func(): sell(t), Color("b8473a"))
	sl.add_theme_font_size_override("font_size", 16)
	sl.custom_minimum_size = Vector2(110, 64)
	row.add_child(sl)
	var cl := _btn("Đóng", func(): _close_info(), Color("4a5866"))
	cl.add_theme_font_size_override("font_size", 16)
	cl.custom_minimum_size = Vector2(80, 64)
	row.add_child(cl)
	info_panel.reset_size()
	_position_panels.call_deferred()


func _stat_text(t: Dictionary) -> String:
	var info: Dictionary = TOWERS[t["kind"]]
	var tier: int = t["tier"]
	match t["kind"]:
		"sao":
			return "Sát thương %d mỗi phát · tầm %.1f ô" % [int(info["dam"][tier] * (1.6 if tier == 3 else 1.0)), info["tam"][tier]]
		"hong":
			var s := "1 giọt tinh dầu mỗi %.1f giây khi đang đánh" % info["tinh_dau"][tier]
			if tier == 3:
				s += "\nDây gai trói và rút %d máu/giây (boss: chỉ chậm 60%%)" % int(info["dam"][3])
			return s
		"tulip":
			var s2 := "Làm chậm %d%% · vùng %.1f ô" % [int(info["cham"][tier] * 100), info["tam"][tier]]
			if tier == 3:
				s2 += "\nGây %d máu/giây trong vùng" % int(info["dam"][3])
			return s2
		"sen":
			return "Đóng băng %.1f giây (boss: chậm 50%%) · sát thương %d · tầm %.1f ô" % [info["bang"][tier], int(info["dam"][tier]), info["tam"][tier]]
		"xuong_rong":
			return "Gai %d sát thương mỗi con · tầm %.1f ô" % [int(info["dam"][tier]), info["tam"][tier]]
	return ""


func _close_info() -> void:
	info_tower = {}
	if info_panel:
		info_panel.visible = false
	if map:
		map.queue_redraw()


func _position_panels() -> void:
	var area_w := size.x - SIDE_W
	if info_panel:
		info_panel.reset_size()
	if end_panel:
		end_panel.reset_size()
	if info_panel and info_panel.visible:
		info_panel.position = Vector2((area_w - info_panel.size.x) / 2.0, size.y - info_panel.size.y - 12)
	if end_panel and end_panel.visible:
		end_panel.position = (Vector2(area_w, size.y) - end_panel.size) / 2.0 + Vector2(0, TOP_H / 2.0)


static func tex(kind: String) -> Texture2D:
	if not _tex.has(kind):
		var p := "res://art/phong_thu/%s.png" % kind
		_tex[kind] = load(p) if ResourceLoader.exists(p) else null
	return _tex[kind]


# =====================================================================
# Bản đồ: cỏ, đường đất, chạm chọn ô
# =====================================================================

class MapView extends Control:
	var game
	var cell := 60.0
	var _press := Vector2.ZERO

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press = event.position
			elif event.position.distance_to(_press) < cell * 0.6:
				var c := int(floor(event.position.x / cell))
				var r := int(floor(event.position.y / cell))
				game.on_cell_tapped(c, r)
		elif event is InputEventMouseMotion:
			var hc := Vector2i(int(floor(event.position.x / cell)), int(floor(event.position.y / cell)))
			if hc != game.hover_cell:
				game.hover_cell = hc
				queue_redraw()

	func _draw() -> void:
		var pc: Dictionary = game.path_cells()
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		# cỏ hai màu xen kẽ
		for r in game.ROWS:
			for c in game.COLS:
				var col := Color("7fb85a") if (r + c) % 2 == 0 else Color("76ae52")
				draw_rect(Rect2(c * cell, r * cell, cell, cell), col)
		# hoa cỏ nhỏ trang trí
		for i in 70:
			var p := Vector2(rng.randf() * game.COLS, rng.randf() * game.ROWS)
			if pc.has(Vector2i(int(p.x), int(p.y))):
				continue
			var q := p * cell
			if i % 3 == 0:
				var fc: Color = [Color("fff6c8"), Color("ffd1e3"), Color("e8d8ff")][i % 3 if i % 2 == 0 else 1]
				for k in 5:
					draw_circle(q + Vector2.from_angle(TAU * k / 5.0) * cell * 0.05, cell * 0.035, fc)
				draw_circle(q, cell * 0.03, Color("f2b33d"))
			else:
				for k in 3:
					draw_line(q, q + Vector2(-0.06 + 0.06 * k, -0.12) * cell, Color("5f9a40"), 2.0)
		# đường đất: viền tối, mặt đất, vệt sáng giữa (vẽ từng đoạn thẳng nên góc vuông gọn)
		for layer in [[0.5, Color("7a5a36")], [0.43, Color("c9a26b")], [0.2, Color("d9b985")]]:
			var hw: float = layer[0]
			for i in game.PATH.size() - 1:
				var a: Vector2 = game.PATH[i] + Vector2(0.5, 0.5)
				var b: Vector2 = game.PATH[i + 1] + Vector2(0.5, 0.5)
				var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(hw, hw)
				var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(hw, hw)
				draw_rect(Rect2(lo * cell, (hi - lo) * cell), layer[1])
		# sỏi
		for i in 40:
			var d: float = rng.randf() * game.path_length()
			var p2: Vector2 = game.path_pos(d) + Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3))
			draw_circle(p2 * cell, cell * rng.randf_range(0.02, 0.04), Color("a8875a"))
		# cổng ra: hàng rào gỗ khu vườn
		var ex: Vector2 = (game.PATH.back() + Vector2(-0.15, 0.0)) * cell
		for k in 4:
			draw_rect(Rect2(ex + Vector2(-cell * 0.08, -cell * 0.1 + k * cell * 0.3), Vector2(cell * 0.16, cell * 0.26)), Color("a86b3a"))
		# đế màu theo bậc dưới mỗi cây
		for t in game.towers:
			if t["tier"] > 0:
				var bc := Vector2(t["c"] + 0.5, t["r"] + 0.88) * cell
				var rc: Color = Data.RARITY_COLORS[t["tier"]]
				var pts2 := PackedVector2Array()
				for k in 24:
					pts2.append(bc + Vector2(cos(TAU * k / 24.0) * cell * 0.42, sin(TAU * k / 24.0) * cell * 0.13))
				draw_colored_polygon(pts2, Color(rc, 0.55))
				draw_polyline(pts2 + PackedVector2Array([pts2[0]]), rc.lightened(0.3), 2.0, true)
		# ô đang chọn / tầm bắn
		if not game.info_tower.is_empty():
			var t: Dictionary = game.info_tower
			var ctr := Vector2(t["c"] + 0.5, t["r"] + 0.5) * cell
			draw_circle(ctr, game.tower_range(t) * cell, Color(1, 1, 1, 0.16))
			draw_arc(ctr, game.tower_range(t) * cell, 0, TAU, 64, Color(1, 1, 1, 0.7), 2.5, true)
		elif game.selected_kind != "":
			var h: Vector2i = game.hover_cell
			if h.x >= 0 and h.y >= 0 and h.x < game.COLS and h.y < game.ROWS:
				var ok: bool = game.cell_free(h.x, h.y)
				draw_rect(Rect2(Vector2(h) * cell, Vector2(cell, cell)), Color(1, 1, 1, 0.3) if ok else Color(1, 0.2, 0.2, 0.3))
				if ok:
					var rad: float = game.TOWERS[game.selected_kind]["tam"][0]
					draw_arc((Vector2(h) + Vector2(0.5, 0.5)) * cell, rad * cell, 0, TAU, 64, Color(1, 1, 1, 0.6), 2.0, true)
			# đánh dấu các ô trống đặt được
			for r in game.ROWS:
				for c in game.COLS:
					if game.cell_free(c, r):
						draw_rect(Rect2(c * cell + 3, r * cell + 3, cell - 6, cell - 6), Color(1, 1, 1, 0.22), false, 2.0)


# =====================================================================
# Lớp hiệu ứng: côn trùng, đạn, tia nước, đồng bạc
# =====================================================================

class FxView extends Control:
	var game
	var cell := 60.0

	func _draw() -> void:
		var cs := cell
		# vùng tulip
		for t in game.towers:
			if t["kind"] == "tulip":
				var c := Vector2(t["c"] + 0.5, t["r"] + 0.5) * cs
				var rad: float = game.tower_range(t) * cs
				var pulse := 0.5 + 0.5 * sin(game.time * 2.5 + t["c"])
				var col := Color(0.75, 0.5, 1.0, 0.10 + 0.05 * pulse) if t["tier"] < 3 else Color(0.9, 0.3, 0.8, 0.14 + 0.06 * pulse)
				draw_circle(c, rad, col)
				draw_arc(c, rad * (0.85 + 0.15 * pulse), 0, TAU, 48, Color(0.85, 0.65, 1.0, 0.35), 2.0, true)
		# côn trùng (con đi sau vẽ trước)
		var order: Array = game.enemies.duplicate()
		order.sort_custom(func(a, b): return game._pos(a).y < game._pos(b).y)
		# dây gai hoa hồng huyền thoại mọc từ đất: phần sau lưng vẽ trước, phần trước vẽ sau con côn trùng
		for e in order:
			var tied: bool = e["bound"] and not e["dead"]
			if tied:
				_draw_vines(e, cs, false)
			_draw_enemy(e, cs)
			if tied:
				_draw_vines(e, cs, true)
		# côn trùng phòng thủ
		for a in game.allies:
			_draw_ally(a, cs)
		# đạn
		for s in game.shots:
			var p: Vector2 = s["p"] * cs
			if s["type"] == "gai":
				var dirv: Vector2 = (s.get("last", s["p"]) - s["p"])
				if dirv.length() < 0.01:
					dirv = Vector2.LEFT
				dirv = dirv.normalized() * cs * 0.16
				draw_line(p - dirv, p + dirv, Color("2f5a2a"), 3.0, true)
				draw_circle(p + dirv, 2.0, Color("e8f0c8"))
				continue
			var r: float = cs * (0.2 if s["big"] else 0.11)
			if s["big"]:
				draw_circle(p, r * 1.5, Color(1, 0.9, 0.3, 0.3))
			_star(p, r, s["rot"], Color("ffe14d") if not s["big"] else Color("ffb81f"))
		# hiệu ứng
		for e in game.fx:
			var k: float = e["t"] / e["d"]
			match e["type"]:
				"beam":
					var a2: Vector2 = e["a"] * cs
					var b2: Vector2 = e["b"] * cs
					draw_line(a2, b2, Color(0.55, 0.85, 1.0, 0.85 * (1 - k)), cs * 0.12, true)
					draw_line(a2, b2, Color(1, 1, 1, 0.9 * (1 - k)), cs * 0.04, true)
					for i in 4:
						draw_circle(b2 + Vector2.from_angle(i * 1.6 + k * 3) * cs * 0.2 * k, cs * 0.05, Color(0.8, 0.95, 1, 1 - k))
				"spikes":
					var c2: Vector2 = e["p"] * cs
					for i in 12:
						var dir := Vector2.from_angle(TAU * i / 12.0)
						var p1: Vector2 = c2 + dir * float(e["r"]) * cs * k
						draw_line(p1 - dir * cs * 0.15, p1, Color(0.35, 0.55, 0.2, 1 - k), 3.0, true)
				"coin":
					var p3: Vector2 = e["p"] * cs + Vector2(0, -cs * 0.6 * k)
					draw_circle(p3, cs * 0.14, Color(0.75, 0.78, 0.82, 1 - k * 0.6))
					draw_circle(p3, cs * 0.1, Color(0.92, 0.94, 0.97, 1 - k * 0.6))
					draw_string(game.FONT_BOLD, p3 + Vector2(cs * 0.18, cs * 0.08), "+%d" % e["n"], HORIZONTAL_ALIGNMENT_LEFT, -1, int(cs * 0.3), Color(1, 1, 1, 1 - k))
				"drop":
					var p4: Vector2 = e["p"] * cs + Vector2(0, -cs * 0.5 * k)
					draw_circle(p4, cs * 0.09, Color(1, 0.45, 0.65, 1 - k))
					draw_colored_polygon(PackedVector2Array([p4 + Vector2(-cs * 0.08, -cs * 0.02), p4 + Vector2(0, -cs * 0.2), p4 + Vector2(cs * 0.08, -cs * 0.02)]), Color(1, 0.45, 0.65, 1 - k))
				"burst":
					draw_circle(e["p"] * cs, cs * 0.7 * k, Color(1, 0.85, 0.3, 0.5 * (1 - k)))
				"dot":
					var q2: Vector2 = e["p"] * cs
					for i in 6:
						var dir3 := Vector2.from_angle(TAU * i / 6.0)
						draw_line(q2 + dir3 * cs * 0.1, q2 + dir3 * cs * (0.18 + 0.2 * k), Color(1, 0.85, 0.2, 1 - k), 3.0, true)
				"dat":
					for i in 9:
						var ang := -PI * (0.15 + 0.7 * i / 8.0)
						var q: Vector2 = e["p"] * cs + Vector2(0, cs * 0.3) + Vector2.from_angle(ang) * cs * 0.6 * k + Vector2(0, cs * 0.8 * k * k)
						draw_circle(q, cs * 0.05 * (1 - k * 0.5), Color(0.42, 0.28, 0.15, 1 - k))
				"puff":
					for i in 6:
						draw_circle(e["p"] * cs + Vector2.from_angle(i) * cs * 0.4 * k, cs * 0.12 * (1 - k), Color(1, 1, 1, 0.7 * (1 - k)))
				"spark":
					for i in 10:
						var dir2 := Vector2.from_angle(TAU * i / 10.0 + k)
						_star(e["p"] * cs + dir2 * cs * 0.6 * k, cs * 0.08 * (1 - k * 0.5), k * 5, Color(e["col"], 1 - k))
				"ouch":
					draw_string(game.FONT_BOLD, e["p"] * cs + Vector2(-cs * 0.3, -cs * k), "-♥", HORIZONTAL_ALIGNMENT_LEFT, -1, int(cs * 0.4), Color(1, 0.3, 0.3, 1 - k))

	## Dây gai mọc lên từ mặt đất dưới chân con côn trùng rồi quấn quanh thân.
	func _draw_vines(e: Dictionary, cs: float, front: bool) -> void:
		var info: Dictionary = game.ENEMIES[e["kind"]]
		var sz: float = info["co"] * cs
		var p: Vector2 = game._pos(e) * cs
		var g: float = clampf(e.get("vine_t", 1.0) / 0.5, 0.0, 1.0)   # độ mọc 0..1
		g = 1.0 - pow(1.0 - g, 3.0)
		var base_y := p.y + sz * 0.26
		var tm: float = game.time
		var stem := Color("3d6b2c")
		var stem_hi := Color("5f8f3a")
		var thorn := Color("7a2232")
		if not front:
			# đất nứt, ụ đất quanh chân
			var mound := PackedVector2Array()
			for k in 20:
				var a := TAU * k / 20.0
				mound.append(Vector2(p.x, base_y) + Vector2(cos(a) * sz * 0.55, sin(a) * sz * 0.14) * (0.6 + 0.4 * g))
			draw_colored_polygon(mound, Color(0.45, 0.3, 0.17, 0.85 * g))
			for k in 5:
				var a2 := -2.6 + k * 1.3
				var c0 := Vector2(p.x, base_y)
				draw_line(c0 + Vector2(cos(a2), sin(a2) * 0.3) * sz * 0.12, c0 + Vector2(cos(a2), sin(a2) * 0.3) * sz * 0.5 * g, Color(0.25, 0.15, 0.08, 0.8), 2.0, true)
		# 3 sợi dây: hai bên ở sau lưng, sợi giữa ở trước
		var outline := Color("24401b")
		var offs := [-0.36, 0.06, 0.4]
		for i in offs.size():
			if (i == 1) != front:
				continue
			var bx: float = p.x + offs[i] * sz
			var h: float = sz * (0.7 if i == 1 else 0.85) * g * (0.45 if e["boss"] else 1.0)
			var pts := PackedVector2Array()
			var n := 8
			for j in n + 1:
				var k := float(j) / n
				var x: float = lerpf(bx, p.x + offs[i] * 0.3 * sz, k) + sin(k * 4.0 + i * 2.1 + tm * 1.6) * sz * 0.05 * k
				pts.append(Vector2(x, base_y - h * k))
			var w0 := maxf(cs * 0.1, sz * 0.12)
			for j in n:
				var w: float = lerpf(w0, w0 * 0.35, float(j) / n)
				draw_line(pts[j], pts[j + 1], outline, w + 3.0, true)
			for j in n:
				var w: float = lerpf(w0, w0 * 0.35, float(j) / n)
				draw_line(pts[j], pts[j + 1], stem, w, true)
				draw_line(pts[j] + Vector2(-w * 0.22, 0), pts[j + 1] + Vector2(-w * 0.22, 0), stem_hi, w * 0.28, true)
			# gai nhọn mọc chĩa ra ngoài
			var out_dir := -1.0 if offs[i] < 0.0 else 1.0
			for j in [2, 5]:
				var d: Vector2 = (pts[j + 1] - pts[j]).normalized()
				var w2: float = lerpf(w0, w0 * 0.35, float(j) / n) * 0.5
				var side := Vector2(out_dir, -0.35).normalized()
				var b0: Vector2 = pts[j] + side * w2
				draw_colored_polygon(PackedVector2Array([b0 + d * w2, b0 - d * w2, b0 + side * w2 * 2.2]), thorn)
			# lá
			if g > 0.5:
				var lp: Vector2 = pts[4]
				var ld := Vector2.from_angle(-PI / 2 - out_dir * 0.9)
				var ln := ld.orthogonal()
				var leaf := PackedVector2Array()
				for k in 9:
					var t := k / 8.0
					leaf.append(lp + ld * sz * 0.2 * t + ln * sin(t * PI) * sz * 0.06)
				for k in range(7, 0, -1):
					var t := k / 8.0
					leaf.append(lp + ld * sz * 0.2 * t - ln * sin(t * PI) * sz * 0.06)
				draw_colored_polygon(leaf, Color("72b244"))
				draw_line(lp, lp + ld * sz * 0.17, Color("4c8a2c"), 1.5, true)
			# ngọn xoắn
			var tip: Vector2 = pts[n]
			draw_arc(tip + Vector2(out_dir * sz * 0.045, 0), sz * 0.045, 0.0, PI * 1.5, 10, stem, maxf(2.0, w0 * 0.3), true)
		# dải dây quấn ngang thân (nửa sau vẽ sau, nửa trước vẽ trước)
		if g > 0.55 and not e["boss"]:
			var k2: float = (g - 0.55) / 0.45
			var rings := 1
			for ring in rings:
				var cy: float = p.y - sz * (0.02 + ring * 0.3)
				var rx := sz * (0.46 - ring * 0.06)
				var ry := sz * 0.11
				var a0: float = 0.0 if front else PI
				var pts2 := PackedVector2Array()
				for j in 17:
					var a := a0 + PI * j / 16.0 * k2
					pts2.append(Vector2(p.x + cos(a) * rx, cy + sin(a) * ry))
				var bw := maxf(cs * 0.06, sz * 0.07)
				draw_polyline(pts2, outline, bw + 3.0, true)
				draw_polyline(pts2, stem, bw, true)
				if front:
					for j in [5, 11]:
						if j < pts2.size():
							var q: Vector2 = pts2[j]
							draw_colored_polygon(PackedVector2Array([q + Vector2(-bw * 0.45, 0), q + Vector2(bw * 0.45, 0), q + Vector2(0, bw * 1.3)]), thorn)

	func _star(p: Vector2, r: float, rot: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 10:
			var rr := r if i % 2 == 0 else r * 0.45
			pts.append(p + Vector2.from_angle(rot + TAU * i / 10.0 - PI / 2) * rr)
		draw_colored_polygon(pts, col)
		draw_polyline(pts + PackedVector2Array([pts[0]]), col.darkened(0.3), 1.5, true)

	func _draw_enemy(e: Dictionary, cs: float) -> void:
		var info: Dictionary = game.ENEMIES[e["kind"]]
		var p: Vector2 = game._pos(e) * cs
		var dir: Vector2 = game.path_dir(e["d"])
		var sz: float = info["co"] * cs
		var moving: bool = e["freeze"] <= 0.0 and not (e["bound"] and not e["boss"])
		var bob := sin(game.time * 9.0 + e["wob"]) * cs * 0.03 if moving else 0.0
		# bóng
		_ellipse(p + Vector2(0, sz * 0.28), sz * 0.42, sz * 0.12, Color(0, 0, 0, 0.22))
		var flip := dir.x < -0.1
		var tx: Texture2D = game.tex(e["kind"])
		var tint := Color.WHITE
		if e["hit"] > 0.0:
			tint = Color(1.6, 1.6, 1.6)
		if e["freeze"] > 0.0:
			tint = Color(0.7, 0.9, 1.4)
		elif e.get("chill", 0.0) > 0.0:
			tint = Color(0.82, 0.95, 1.3)
		elif e["slow"] < 0.99:
			tint = tint * Color(1.0, 0.92, 1.1)
		if tx:
			var asp := float(tx.get_width()) / tx.get_height()
			var w := sz * (asp if asp > 1.0 else 1.0)
			var h := w / asp
			var rect := Rect2(p + Vector2(-w / 2.0, -h * 0.7 + bob), Vector2(w, h))
			if flip:
				rect = Rect2(rect.position.x + w, rect.position.y, -w, h)
			draw_texture_rect_region(tx, rect, Rect2(Vector2.ZERO, tx.get_size()), tint)
		else:
			_code_bug(e["kind"], p + Vector2(0, bob - sz * 0.15), sz, -1.0 if flip else 1.0, tint)
		if e["freeze"] > 0.0:
			# khối băng lục giác bọc quanh
			var ice := PackedVector2Array()
			for k in 6:
				ice.append(p + Vector2(0, -sz * 0.22) + Vector2.from_angle(TAU * k / 6.0 + 0.5) * Vector2(sz * 0.55, sz * 0.48))
			draw_colored_polygon(ice, Color(0.75, 0.92, 1.0, 0.4))
			draw_polyline(ice + PackedVector2Array([ice[0]]), Color(0.92, 0.98, 1.0, 0.9), 2.0, true)
			draw_line(ice[3].lerp(ice[4], 0.3), ice[3].lerp(ice[4], 0.3) + Vector2(sz * 0.12, -sz * 0.18), Color(1, 1, 1, 0.8), 2.0)
		# thanh máu
		var bw := sz * 0.9
		var by := p.y - sz * 0.78 + bob
		var frac: float = clampf(e["hp"] / e["max"], 0.0, 1.0)
		draw_rect(Rect2(p.x - bw / 2 - 1, by - 1, bw + 2, cs * 0.1 + 2), Color(0.1, 0.05, 0.02, 0.85))
		var hc := Color("5fd35f") if frac > 0.5 else (Color("f2c037") if frac > 0.25 else Color("e5483c"))
		draw_rect(Rect2(p.x - bw / 2, by, bw * frac, cs * 0.1), hc)
		if e["boss"]:
			draw_string(game.FONT_BOLD, Vector2(p.x - bw / 2, by - 4), info["ten"], HORIZONTAL_ALIGNMENT_LEFT, -1, int(cs * 0.22), Color("fff1cf"))

	func _draw_ally(a: Dictionary, cs: float) -> void:
		var p: Vector2 = game._ally_pos(a) * cs
		var fly: bool = a["kind"] == "chuon_chuon"
		var sz := cs * (0.85 if fly else 0.72)
		var dir: Vector2 = -game.path_dir(a["d"])
		var flip := dir.x < -0.1
		var moving: bool = fly or not a.get("chan", false)
		var bob := sin(game.time * (14.0 if fly else 9.0) + a["wob"]) * cs * 0.03 if moving else 0.0
		_ellipse(game.path_pos(a["d"]) * cs + Vector2(0, sz * 0.28), sz * (0.3 if fly else 0.4), sz * 0.1, Color(0, 0, 0, 0.15 if fly else 0.22))
		var tx: Texture2D = game.tex(a["kind"])
		if tx:
			var asp := float(tx.get_width()) / tx.get_height()
			var w := sz * (asp if asp > 1.0 else 1.0)
			var h := w / asp
			var rect := Rect2(Vector2(p.x - w / 2.0, p.y - h * 0.7 + bob), Vector2(w, h))
			if flip:
				rect = Rect2(rect.position.x + w, rect.position.y, -w, h)
			draw_texture_rect_region(tx, rect, Rect2(Vector2.ZERO, tx.get_size()))
		else:
			draw_circle(p, sz * 0.3, Color("3fae6a") if not fly else Color("4ab0d8"))
		if fly and a.get("stings", 0) > 0:
			for i in game.STINGS_TO_KILL:
				var hc := Color("ff6b7a") if i >= a.get("stings", 0) else Color(0.3, 0.3, 0.3, 0.6)
				draw_circle(Vector2(p.x - cs * 0.15 + i * cs * 0.15, p.y - sz * 0.75), cs * 0.05, hc)
		if not fly:
			var bw := sz * 0.8
			var by := p.y - sz * 0.78 + bob
			var frac: float = clampf(a["hp"] / a["max"], 0.0, 1.0)
			draw_rect(Rect2(p.x - bw / 2 - 1, by - 1, bw + 2, cs * 0.08 + 2), Color(0.1, 0.05, 0.02, 0.85))
			draw_rect(Rect2(p.x - bw / 2, by, bw * frac, cs * 0.08), Color("4fb4e8"))

	func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 20:
			var t := TAU * i / 20.0
			pts.append(c + Vector2(cos(t) * rx, sin(t) * ry))
		draw_colored_polygon(pts, col)

	## Côn trùng vẽ bằng code (dùng khi chưa có ảnh art/phong_thu/<loài>.png).
	func _code_bug(kind: String, p: Vector2, sz: float, fx_: float, tint: Color) -> void:
		var body: Color
		var segs := 1
		match kind:
			"sau":
				body = Color("8bd35a"); segs = 5
			"bo_xit":
				body = Color("9a6a3a"); segs = 1
			"ret", "boss_ret":
				body = Color("e0683a"); segs = 7
			"chau_chau":
				body = Color("6fc04a"); segs = 2
			"boss_nhen":
				body = Color("5a4a7a"); segs = 2
			"boss_ong":
				body = Color("f2c037"); segs = 3
			_:
				body = Color("888888")
		body = body * tint
		var head := p + Vector2(sz * 0.36 * fx_, -sz * 0.05)
		if segs >= 4:
			for i in segs:
				var q := p + Vector2((-0.36 + 0.6 * i / float(segs - 1)) * sz * fx_, sin(game.time * 8 + i) * sz * 0.03)
				draw_circle(q, sz * 0.14, body.darkened(0.15 if i % 2 else 0.0))
				if kind != "sau":
					draw_line(q, q + Vector2(0, sz * 0.18), body.darkened(0.4), 2.0)
		elif kind == "boss_nhen":
			for i in 4:
				for s in [-1.0, 1.0]:
					var a := Vector2(s * (0.2 + i * 0.1) * sz, sz * 0.12)
					draw_line(p, p + a + Vector2(0, -sz * 0.15), body.darkened(0.3), 3.0)
			draw_circle(p, sz * 0.3, body)
		elif kind == "boss_ong":
			draw_circle(p + Vector2(0, -sz * 0.25), sz * 0.2, Color(1, 1, 1, 0.6))
			_ellipse(p, sz * 0.36, sz * 0.22, body)
			for i in 2:
				draw_rect(Rect2(p + Vector2((-0.12 + 0.18 * i) * sz, -sz * 0.2), Vector2(sz * 0.07, sz * 0.4)), Color("3a2a1a"))
		else:
			_ellipse(p, sz * 0.36, sz * 0.24, body)
			if kind == "chau_chau":
				draw_line(p + Vector2(-0.1 * sz * fx_, 0), p + Vector2(-0.3 * sz * fx_, -sz * 0.3), body.darkened(0.3), 4.0)
		draw_circle(head, sz * 0.17, body.lightened(0.1))
		draw_circle(head + Vector2(sz * 0.06 * fx_, -sz * 0.03), sz * 0.06, Color.WHITE)
		draw_circle(head + Vector2(sz * 0.08 * fx_, -sz * 0.03), sz * 0.035, Color("222222"))
		if kind == "boss_ret":
			for k in [-1.0, 1.0]:
				var h2 := head + Vector2(-sz * 0.1 * fx_, k * sz * 0.22)
				draw_circle(h2, sz * 0.13, body.lightened(0.05))
				draw_circle(h2 + Vector2(sz * 0.05 * fx_, 0), sz * 0.04, Color("222222"))


# =====================================================================
# Nút chọn cây ở cột phải
# =====================================================================

class TowerButton extends Button:
	var game
	var kind := ""

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE

	func _draw() -> void:
		var info: Dictionary = game.TOWERS[kind]
		var open: bool = game.unlocked(kind)
		var sel: bool = game.selected_kind == kind
		var r := Rect2(Vector2(2, 2), size - Vector2(4, 4))
		var bg := Color("fffaf0") if not sel else Color("ffe7a8")
		if not open:
			bg = Color("d8ccb4")
		draw_style_box(UiSkin.bevel_box(bg, Color("d9b26a") if sel else Color("a8875a"), 10), r)
		# hình cây nhỏ
		var tx := PlantView._art("res://art/%s/3.png" % info["hoa"])
		var ih := size.y - 10
		var iw := ih * 300.0 / 542.0
		if tx:
			draw_texture_rect(tx, Rect2(Vector2(8, 5), Vector2(iw, ih)), false, Color.WHITE if open else Color(0.4, 0.4, 0.4, 0.8))
		var x := 14 + iw
		var f: Font = game.FONT_BOLD
		draw_string(f, Vector2(x, 28), info["ten"], HORIZONTAL_ALIGNMENT_LEFT, size.x - x - 6, 19, Color("3a2614") if open else Color("6a5a4a"))
		if open:
			var col := Color("2f6a3a") if game.silver >= info["gia"] else Color("b8473a")
			draw_string(f, Vector2(x, 52), "%d bạc" % info["gia"], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, col)
			_wrap(game.FONT_MEDIUM, info["mo_ta"], Vector2(x, 72), size.x - x - 6, 13, Color("5a4a3a"))
		else:
			draw_string(f, Vector2(x, 52), "Khóa · %d bạc" % info["gia"], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("6a4a2a"))
			_wrap(game.FONT_MEDIUM, game.lock_text(kind), Vector2(x, 72), size.x - x - 6, 13, Color("6a5a4a"))

	func _wrap(f: Font, text: String, pos: Vector2, width: float, fs: int, col: Color) -> void:
		var words := text.split(" ")
		var line := ""
		var y := pos.y
		for w in words:
			var test := (line + " " + w).strip_edges()
			if f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width and line != "":
				draw_string(f, Vector2(pos.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
				y += fs + 2
				line = w
			else:
				line = test
		if line != "":
			draw_string(f, Vector2(pos.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
