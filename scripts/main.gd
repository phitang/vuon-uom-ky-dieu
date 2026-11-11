extends Control
## Màn hình chính (màn hình ngang):
## - Bên trái: túi hạt, dụng cụ, thông tin cây đang chọn, ô tiền, thùng rác.
## - Bên phải: nhà kính với 3 kệ gỗ, mỗi kệ 5 chậu.
## - Dưới: dòng trạng thái và các nút Menu, Vật tư, Sổ tay, Shop cây, chuyển kệ.
## - Shop cây (nursery.gd): khách vào xem cây trưng bày và mua ở quầy.
## Cách chơi: chạm chọn cây trên kệ, rồi bấm dụng cụ để dùng cho cây đó.

const Data := preload("res://scripts/data.gd")
const Gen := preload("res://scripts/genetics.gd")
const PlantView := preload("res://scripts/plant_view.gd")
const CustomerView := preload("res://scripts/customer_view.gd")
const Greenhouse := preload("res://scripts/greenhouse.gd")
const Nursery := preload("res://scripts/nursery.gd")
const PotSlot := preload("res://scripts/pot_slot.gd")
const ToolIcon := preload("res://scripts/tool_icon.gd")
const UiSkin := preload("res://scripts/ui_skin.gd")
const SeedBag := preload("res://scripts/seed_bag.gd")
const Vines := preload("res://scripts/vines.gd")
const DragScroll := preload("res://scripts/drag_scroll.gd")
const DecorPreview := preload("res://scripts/decor_preview.gd")
const WaterAnim := preload("res://scripts/water_anim.gd")
const ToolAnim := preload("res://scripts/tool_anim.gd")
const Insects := preload("res://scripts/insects.gd")
const Quiz := preload("res://scripts/quiz.gd")
var insects: Control       # lớp côn trùng hỏi đáp bay trong nhà kính
var tool_busy := false      # đang chạy hoạt ảnh xúc đất / cắt kéo
const FONT_BOLD := preload("res://fonts/Lora-700.ttf")
const FONT_MEDIUM := preload("res://fonts/Lora-500.ttf")
const SLATE := Color("4a5866")

const LEFT_W := 400
const BOTTOM_H := 84
const STATUS_H := 40
const SLOTS_PER_PAGE := 15
const SEEDS_PER_PAGE := 8

# Bảng màu
const WOOD := Color("5e3b22")
const WOOD_LIGHT := Color("8a5a2b")
const GOLD := Color("d9b26a")
const PARCH := Color("f3e3c0")
const INK := Color("3a2614")
const PRIMARY := Color("3e7d4a")
const ACCENT := Color("d9822b")
const TEXT := Color("2b3a2e")
const MUTED := Color("6b7a6e")
const DANGER := Color("b8473a")
const PANEL := Color("fffaf0")

var gs: Node

# Trạng thái chọn
var selected := -1        # chậu đang chọn
var selected_seed := 0    # hạt đang chọn trong túi
var seed_page := 0
var shelf_page := 0
var pollen_from := -1     # súng thụ phấn đang nạp phấn của cây này
var pollen_gen := {}      # gen phấn đã nạp (rỗng = súng chưa nạp)
var dragging_gun := false

# Nút và nhãn
var greenhouse: Control
var slots: Array = []
var seed_bag: Control
var seed_banner: Label
var tool_buttons := {}
var tool_icons := {}
var dragging_seed := false
var plant_banner: Label
var water_bar: ProgressBar
var health_bar: ProgressBar
var stage_l: Label
var traits_l: Label
var price_btn: Button
var sell_btn: Button
var nursery: Control
var chat_ctx := {}
var special_ctx := {}      # bảng của khách ẩn đang mở: {"c": khách, "result": ...}
var state_l: Label
var age_l: Label
var cash_l: Label
var status_l: Label
var page_l: Label
var page_prev: Button
var page_next: Button
var status_tween: Tween

# Bảng bật lên
var overlay: Control
var title_screen: Control  # màn hình chính khi vào game
var popup_refresh: Callable = Callable()
var shop_box: VBoxContainer
var shop_sig := ""
var book_box: VBoxContainer
var book_sig := ""


func _ready() -> void:
	gs = get_node("/root/GameState")
	theme = _make_theme()
	_build_layout()
	gs.changed.connect(_on_state_changed)
	gs.message.connect(_status)
	_refresh_all()
	_music("vuon")
	_status("Chạm vào một chậu trên kệ để chọn cây.")
	_build_title()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN or what == NOTIFICATION_DRAG_END:
		var d = get_viewport().gui_get_drag_data() if what == NOTIFICATION_DRAG_BEGIN else null
		dragging_seed = typeof(d) == TYPE_DICTIONARY and d.has("hat")
		dragging_gun = typeof(d) == TYPE_DICTIONARY and d.has("sung")
		if what == NOTIFICATION_DRAG_END:
			dragging_seed = false
			if tool_icons.has("sung") and tool_icons["sung"].modulate.a < 1.0:
				_gun_return()
			dragging_gun = false
		if is_node_ready():
			_refresh_shelves()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if overlay.visible:
			_close_popup()
		elif title_screen != null and title_screen.visible:
			gs.save_game()
			get_tree().quit()
		elif nursery.visible:
			_close_nursery()
		elif not pollen_gen.is_empty():
			_unload_gun()
			_refresh_all()
		else:
			gs.save_game()
			get_tree().quit()


# =====================================================================
# Giao diện chung
# =====================================================================

func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = FONT_BOLD
	t.default_font_size = 21
	for st in ["normal", "hover", "pressed", "disabled"]:
		t.set_stylebox(st, "Button", UiSkin.bevel_box(SLATE, UiSkin.SILVER, 10, st))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", Color("fff6e0"))
	t.set_color("font_disabled_color", "Button", Color("eeeeee"))
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.55))
	t.set_constant("outline_size", "Button", 4)
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("panel", "PanelContainer", UiSkin.panel_box(PANEL, Color("7a4a24"), 22.0))
	t.set_constant("separation", "VBoxContainer", 10)
	t.set_constant("separation", "HBoxContainer", 10)
	t.set_constant("h_separation", "GridContainer", 10)
	t.set_constant("v_separation", "GridContainer", 10)
	t.set_stylebox("slider", "HSlider", UiSkin.inset_box(Color("8a6a44"), Vector4(0, 6, 0, 6)))
	var grab := UiSkin.bevel_box(ACCENT, GOLD, 8, "normal", Vector4(0, 6, 0, 6))
	t.set_stylebox("grabber_area", "HSlider", grab)
	t.set_stylebox("grabber_area_highlight", "HSlider", grab)
	return t


func _box(col: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	return sb


## Khung nổi khối: giấy da viền gỗ cho nền sáng, ô lõm cho nền tối, nút vát cạnh cho màu khác.
func _framed(col: Color, border: Color, radius := 10, _width := 3) -> StyleBox:
	if col.get_luminance() > 0.72:
		return UiSkin.panel_box(col, Color("7a4a24"), 14.0)
	if col.get_luminance() < 0.16:
		return UiSkin.inset_box(col)
	return UiSkin.bevel_box(col, border, radius)


func _label(text: String, font_size := 22, col := TEXT, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = align
	if font_size <= 17:
		l.add_theme_font_override("font", FONT_MEDIUM)
	return l


func _button(text: String, cb: Callable, col := SLATE) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 56
	# nút xanh xám dùng viền bạc, các màu khác dùng viền vàng
	var rim := UiSkin.SILVER if col.s < 0.35 else GOLD
	UiSkin.style_button(b, col, rim)
	b.pressed.connect(cb)
	return b


func _banner(text: String) -> Label:
	var l := _label(text, 22, Color("fff1cf"), HORIZONTAL_ALIGNMENT_CENTER)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# băng tên màu cam viền vàng
	l.add_theme_stylebox_override("normal", UiSkin.bevel_box(Color("c8641e"), GOLD, 16, "normal", Vector4(16, 3, 16, 5)))
	l.add_theme_color_override("font_outline_color", Color(0.25, 0.1, 0, 0.8))
	l.add_theme_constant_override("outline_size", 5)
	return l


func _plant_view(min_size: Vector2) -> Control:
	var pv := Control.new()
	pv.set_script(PlantView)
	pv.custom_minimum_size = min_size
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pv


func _icon(kind: String, min_size: Vector2) -> Control:
	var ic := Control.new()
	ic.set_script(ToolIcon)
	ic.kind = kind
	ic.custom_minimum_size = min_size
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return ic


func _clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


func _vbar(title: String, col: Color) -> Array:
	# Thanh dọc có chữ dọc, giống ống đo nước / sức khỏe
	var holder := PanelContainer.new()
	holder.add_theme_stylebox_override("panel", UiSkin.bevel_box(Color("6b4426"), GOLD, 10, "normal", Vector4(6, 6, 6, 6)))
	holder.custom_minimum_size = Vector2(34, 0)
	var stack := Control.new()
	holder.add_child(stack)
	var bar := ProgressBar.new()
	bar.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.add_theme_stylebox_override("background", UiSkin.inset_box(Color("2a1a0e"), Vector4(0, 0, 0, 0)))
	# ống kính: tối ở hai mép, sáng ở giữa
	var grad := Gradient.new()
	grad.set_color(0, col.darkened(0.35))
	grad.set_color(1, col.darkened(0.35))
	grad.add_point(0.4, col.lightened(0.45))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 32
	gt.height = 4
	var fill := StyleBoxTexture.new()
	fill.texture = gt
	bar.add_theme_stylebox_override("fill", fill)
	stack.add_child(bar)
	var letters: PackedStringArray = []
	for ch in title:
		letters.append(ch)
	var l := _label("\n".join(letters), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.add_theme_constant_override("line_spacing", -4)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.add_child(l)
	return [holder, bar]


# =====================================================================
# Bố cục
# =====================================================================

func _build_layout() -> void:
	# Nhà kính bên phải
	greenhouse = Control.new()
	greenhouse.set_script(Greenhouse)
	greenhouse.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	greenhouse.offset_left = LEFT_W
	greenhouse.offset_bottom = -(BOTTOM_H + STATUS_H)
	add_child(greenhouse)
	for i in SLOTS_PER_PAGE:
		var s := Control.new()
		s.set_script(PotSlot)
		s.slot_index = i
		greenhouse.add_slot(s)
		s.tapped.connect(_on_slot)
		s.set_drag_forwarding(Callable(), func(_pos, data): return _can_drop_seed(i, data), func(_pos, data): _drop_seed(i, data))
		slots.append(s)

	# côn trùng hỏi đáp bay trong nhà kính (khoảng mỗi phút một con)
	insects = Control.new()
	insects.set_script(Insects)
	insects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	insects.offset_left = LEFT_W
	insects.offset_bottom = -(BOTTOM_H + STATUS_H)
	add_child(insects)
	insects.paused_check = func(): return overlay.visible or nursery.visible or (title_screen != null and title_screen.visible)
	insects.insect_tapped.connect(_open_quiz)

	_build_bottom()
	_build_left()

	nursery = Control.new()
	nursery.set_script(Nursery)
	nursery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	nursery.visible = false
	add_child(nursery)
	nursery.paused_check = func(): return overlay.visible
	nursery.back_pressed.connect(_close_nursery)
	nursery.chat_requested.connect(_open_chat)
	nursery.stand_tapped.connect(_open_price_editor)
	nursery.decor_pressed.connect(_open_decor_shop)
	nursery.rename_pressed.connect(_open_rename)
	nursery.special_requested.connect(_open_special)

	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 3000   # luôn nằm trên cây và khách trong shop (chúng dùng z theo chiều sâu)
	overlay.visible = false
	add_child(overlay)


func _build_bottom() -> void:
	# Dòng trạng thái
	var status_panel := PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", UiSkin.inset_box(Color("26313a"), Vector4(16, 2, 16, 2)))
	status_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status_panel.offset_left = LEFT_W
	status_panel.offset_top = -(BOTTOM_H + STATUS_H)
	status_panel.offset_bottom = -BOTTOM_H
	add_child(status_panel)
	status_l = _label("", 20, Color("f2ead8"), HORIZONTAL_ALIGNMENT_CENTER)
	status_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	status_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_panel.add_child(status_l)

	# Thanh menu
	var bar := PanelContainer.new()
	var bsb := StyleBoxTexture.new()
	var bgrad := Gradient.new()
	bgrad.set_color(0, Color("4a5560"))
	bgrad.set_color(1, Color("1c232a"))
	var bgt := GradientTexture2D.new()
	bgt.gradient = bgrad
	bgt.fill_from = Vector2(0, 0)
	bgt.fill_to = Vector2(0, 1)
	bgt.width = 4
	bgt.height = 64
	bsb.texture = bgt
	bsb.content_margin_left = 12
	bsb.content_margin_right = 12
	bsb.content_margin_top = 10
	bsb.content_margin_bottom = 10
	bar.add_theme_stylebox_override("panel", bsb)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = LEFT_W
	bar.offset_top = -BOTTOM_H
	add_child(bar)
	var row := HBoxContainer.new()
	bar.add_child(row)
	for spec in [["Menu", _open_menu], ["Vật tư", _open_shop], ["Sổ tay", _open_book], ["Shop cây", _open_nursery], ["Kho hạt", _open_storage]]:
		var b := _button(spec[0], spec[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
		if spec[0] == "Kho hạt":
			# kéo hạt từ túi thả vào nút này để cất vào kho
			b.set_drag_forwarding(Callable(),
				func(_pos, data): return typeof(data) == TYPE_DICTIONARY and data.has("hat"),
				func(_pos, data):
					if gs.store_seed(int(data["hat"])):
						_status("Đã cất hạt vào kho (%d/%d)." % [gs.storage.size(), gs.storage_cap]))
	page_prev = _button("«", func(): _change_page(-1))
	page_prev.custom_minimum_size.x = 64
	row.add_child(page_prev)
	page_l = _label("Kệ 1/1", 20, Color("f2ead8"), HORIZONTAL_ALIGNMENT_CENTER)
	page_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_l.custom_minimum_size.x = 80
	row.add_child(page_l)
	page_next = _button("»", func(): _change_page(1))
	page_next.custom_minimum_size.x = 64
	row.add_child(page_next)


func _build_left() -> void:
	var panel := PanelContainer.new()
	var sb := StyleBoxTexture.new()
	sb.texture = UiSkin.wood_texture(WOOD)
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.content_margin_left = 12
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_right = LEFT_W
	add_child(panel)
	# viền vàng nổi ở mép phải
	var edge := ColorRect.new()
	edge.color = GOLD
	edge.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	edge.offset_left = LEFT_W - 7
	edge.offset_right = LEFT_W
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(edge)
	var edge_dark := ColorRect.new()
	edge_dark.color = Color("6b4a1e")
	edge_dark.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	edge_dark.offset_left = LEFT_W - 2
	edge_dark.offset_right = LEFT_W
	edge_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(edge_dark)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	panel.add_child(v)

	# Túi hạt: chạm để chọn, lướt ngang để sang trang, kéo ra để gieo
	seed_banner = _banner("Túi hạt")
	v.add_child(seed_banner)
	var seed_box := PanelContainer.new()
	seed_box.add_theme_stylebox_override("panel", UiSkin.panel_box(PARCH, Color("7a4a24"), 8.0))
	v.add_child(seed_box)
	seed_bag = Control.new()
	seed_bag.set_script(SeedBag)
	seed_bag.custom_minimum_size = Vector2(0, 112)
	seed_bag.seed_tapped.connect(_select_seed)
	seed_box.add_child(seed_bag)

	# Dụng cụ và túi đất
	var tools_box := PanelContainer.new()
	tools_box.add_theme_stylebox_override("panel", _framed(PARCH, GOLD, 10, 2))
	v.add_child(tools_box)
	var tools_v := VBoxContainer.new()
	tools_v.add_theme_constant_override("separation", 2)
	tools_box.add_child(tools_v)
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 6)
	tools_v.add_child(tools)
	for kind in ["nuoc", "phan", "keo", "sung", "dat"]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(66, 50)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var flat := StyleBoxEmpty.new()
		b.add_theme_stylebox_override("normal", flat)
		b.add_theme_stylebox_override("hover", _box(Color(1, 1, 1, 0.35), 10))
		b.add_theme_stylebox_override("pressed", _box(Color(0, 0, 0, 0.12), 10))
		b.pressed.connect(func(): _use_tool(kind))
		var ic := _icon(kind, Vector2(60, 60))
		b.add_child(ic)
		tools.add_child(b)
		tool_buttons[kind] = b
		tool_icons[kind] = ic
		if kind == "sung":
			# kéo súng thụ phấn ra chậu: lần đầu lấy phấn, lần sau thụ phấn cho cây thứ hai
			b.set_drag_forwarding(func(_pos): return _gun_drag_data(b), Callable(), Callable())
	# (túi đất nằm trong hàng dụng cụ, hình túi đổi theo loại đất tốt nhất đã mua)

	# Cây đang chọn
	plant_banner = _banner("Chưa chọn cây")
	v.add_child(plant_banner)
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 6)
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(info)
	var wb := _vbar("NƯỚC", Color("4a9be8"))
	info.add_child(wb[0])
	water_bar = wb[1]
	var mid := PanelContainer.new()
	mid.add_theme_stylebox_override("panel", _framed(PARCH, GOLD, 10, 2))
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(mid)
	var mv := VBoxContainer.new()
	mv.add_theme_constant_override("separation", 4)
	mid.add_child(mv)
	stage_l = _label("", 18, INK)
	mv.add_child(stage_l)
	traits_l = _label("", 14, Color("6a4f33"))
	traits_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mv.add_child(traits_l)
	price_btn = _button("Giá: —", _on_price_pressed, Color("3b4a5a"))
	price_btn.custom_minimum_size.y = 36
	price_btn.add_theme_font_size_override("font_size", 19)
	mv.add_child(price_btn)
	sell_btn = _button("Trưng bày", _on_sell, Color("8a5a2b"))
	sell_btn.custom_minimum_size.y = 40
	mv.add_child(sell_btn)
	var hb := _vbar("SỨC KHỎE", Color("d24a5a"))
	info.add_child(hb[0])
	health_bar = hb[1]

	# Tình trạng
	var st := HBoxContainer.new()
	v.add_child(st)
	state_l = _label("", 19, Color("9fe08a"))
	state_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	state_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var ssb := _framed(Color("2f1f12"), GOLD, 8, 2)
	ssb.content_margin_top = 3
	ssb.content_margin_bottom = 3
	state_l.add_theme_stylebox_override("normal", ssb)
	st.add_child(state_l)
	age_l = _label("", 19, Color("fff1cf"), HORIZONTAL_ALIGNMENT_CENTER)
	age_l.custom_minimum_size.x = 120
	age_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	age_l.add_theme_stylebox_override("normal", ssb)
	st.add_child(age_l)

	# Tiền và thùng rác
	var cash_row := HBoxContainer.new()
	v.add_child(cash_row)
	var cash := PanelContainer.new()
	cash.add_theme_stylebox_override("panel", UiSkin.bevel_box(Color("9a2f22"), GOLD, 10, "normal", Vector4(12, 7, 10, 7)))
	cash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cash_row.add_child(cash)
	var ch := HBoxContainer.new()
	cash.add_child(ch)
	var xu_l := _label("XU", 22, Color("ffe08a"))
	xu_l.add_theme_color_override("font_outline_color", Color(0.3, 0.05, 0, 0.9))
	xu_l.add_theme_constant_override("outline_size", 5)
	xu_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	xu_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ch.add_child(xu_l)
	cash_l = _label("", 24, INK, HORIZONTAL_ALIGNMENT_RIGHT)
	cash_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	cash_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cash_l.add_theme_stylebox_override("normal", UiSkin.inset_box(Color("f1c9c0"), Vector4(10, 2, 10, 2)))
	ch.add_child(cash_l)
	var trash := _button("Thùng rác", _on_trash, Color("b0602a"))
	trash.custom_minimum_size = Vector2(130, 50)
	cash_row.add_child(trash)
	# dây leo trang trí
	var vines := Control.new()
	vines.set_script(Vines)
	vines.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	vines.offset_right = LEFT_W + 4
	vines.z_index = 0   # thêm trước Shop cây và bảng bật lên nên bị chúng che đúng thứ tự
	add_child(vines)


func _small_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(36, 32)
	b.add_theme_font_size_override("font_size", 16)
	var s := _framed(WOOD_LIGHT, GOLD, 8, 2)
	s.content_margin_left = 4
	s.content_margin_right = 4
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	b.add_theme_stylebox_override("normal", s)
	b.add_theme_stylebox_override("hover", s)
	b.add_theme_stylebox_override("pressed", s)
	b.pressed.connect(cb)
	return b


# =====================================================================
# Cập nhật hiển thị
# =====================================================================

func _on_state_changed() -> void:
	_refresh_all()
	if nursery.visible:
		nursery.refresh()
	if popup_refresh.is_valid():
		popup_refresh.call()


func _refresh_all() -> void:
	if selected >= gs.pots.size():
		selected = -1
	_refresh_shelves()
	_refresh_seeds()
	_refresh_tools()
	_refresh_info()
	cash_l.text = "%d" % gs.coins


func _pages() -> int:
	# đủ trang cho mọi chậu, cộng chỗ để mua thêm nếu chưa tối đa
	var n: int = gs.pots.size() + (1 if gs.pots.size() < Data.MAX_POTS else 0)
	return maxi(1, ceili(float(n) / SLOTS_PER_PAGE))


func _refresh_shelves() -> void:
	shelf_page = clampi(shelf_page, 0, _pages() - 1)
	page_l.text = "Kệ %d/%d" % [shelf_page + 1, _pages()]
	# vườn tối đa 15 chậu = 1 kệ; nút chuyển kệ chỉ hiện với file lưu cũ còn hơn 15 chậu
	for nd in [page_prev, page_l, page_next]:
		nd.visible = _pages() > 1
	page_prev.disabled = shelf_page == 0
	page_next.disabled = shelf_page >= _pages() - 1
	for k in SLOTS_PER_PAGE:
		var i := shelf_page * SLOTS_PER_PAGE + k
		var s: Control = slots[k]
		s.locked = i >= gs.pots.size()
		s.show_buy_hint = i == gs.pots.size() and gs.pots.size() < Data.MAX_POTS
		s.selected = i == selected
		s.pollen_target = dragging_gun and i < gs.pots.size() and (
			gs.can_cross(i) if not pollen_gen.is_empty() else _can_give_pollen(i))
		s.badge_count = 0
		s.drop_target = dragging_seed and not s.locked and gs.pots[i].is_empty() and gs.soils[i] != ""
		s.badge = ""
		if not s.locked:
			var p: Dictionary = gs.pots[i]
			s.pv.set_soil(gs.soils[i])
			if p.is_empty():
				s.pv.clear()
				if gs.soils[i] == "":
					s.badge = "dat"
			elif p.get("trung_bay", false):
				s.pv.clear()
				s.badge = "shop"
			else:
				var st: int = gs.stage_of(p)
				s.pv.set_plant(p["gen"], st, p["chet"], p.get("heo", false))
				if gs.pod_ready(i) > 0:
					s.badge = "qua"
					s.badge_count = gs.pod_ready(i)
				elif p["chet"]:
					s.badge = "chet"
				elif p["nuoc"] <= 0.0:
					s.badge = "nuoc"
				elif st >= 4:
					s.badge = "hat"
				elif st == 3 and not p.get("da_lai", false):
					s.badge = "hoa"
		s.refresh()


func _refresh_seeds() -> void:
	if selected_seed >= gs.seeds.size():
		selected_seed = maxi(0, gs.seeds.size() - 1)
	var kinds: Array = []
	for sd in gs.seeds:
		kinds.append({"hoa": Gen.expressed(sd["gen"], "hoa"), "hiem": Gen.rarity(sd["gen"])})
	seed_bag.set_data(gs.seeds.size(), gs.seed_capacity(), selected_seed, kinds)
	seed_banner.text = "Túi hạt  %d/%d" % [gs.seeds.size(), gs.seed_capacity()]


func _refresh_tools() -> void:
	var p := _sel_plant()
	var alive: bool = not p.is_empty() and not p["chet"]
	var st: int = gs.stage_of(p) if not p.is_empty() else -1
	tool_icons["nuoc"].dim = not alive
	tool_icons["phan"].count = gs.fertilizer
	tool_icons["phan"].dim = not alive or gs.fertilizer <= 0 or (st >= 3 and float(p.get("suc_khoe", 1.0)) >= 0.995)
	tool_icons["keo"].dim = not alive or st < 4
	tool_icons["sung"].loaded = not pollen_gen.is_empty()
	tool_icons["sung"].tier = 2 if gs.gold_gun else 0
	tool_icons["nuoc"].tier = gs.can_tier
	tool_icons["sung"].highlight = not pollen_gen.is_empty()
	var best: String = gs.best_soil()
	tool_icons["dat"].kind = "dat_" + best      # hình túi đổi theo loại đất tốt nhất đã mua
	tool_icons["dat"].dim = not (selected >= 0 and p.is_empty() and gs.soils[selected] != best)
	for k in tool_icons:
		tool_icons[k].queue_redraw()


func _sel_plant() -> Dictionary:
	if selected < 0 or selected >= gs.pots.size():
		return {}
	return gs.pots[selected]


func _refresh_info() -> void:
	var p := _sel_plant()
	if p.is_empty():
		plant_banner.text = "Chậu trống" if selected >= 0 else "Chưa chọn cây"
		traits_l.text = ""
		if selected < 0:
			stage_l.text = "Chạm vào một chậu trên kệ."
		elif gs.soils[selected] == "":
			stage_l.text = "Chậu chưa có đất.\nBấm một túi đất bên trên để cho đất vào."
		else:
			stage_l.text = "Có %s.\nKéo hạt từ Túi hạt thả vào chậu để gieo." % Data.SOILS[gs.soils[selected]]["ten"].to_lower()
		price_btn.text = "Giá: —"
		price_btn.disabled = true
		sell_btn.text = "Trưng bày"
		sell_btn.disabled = true
		water_bar.value = 0
		health_bar.value = 0
		state_l.text = ""
		age_l.text = ""
		return
	var st: int = gs.stage_of(p)
	var r := Gen.rarity(p["gen"])
	plant_banner.text = "Hạt bí ẩn" if st == 0 else "%s · %s" % [Gen.variety_name(p["gen"]), Data.RARITY_NAMES[r]]
	water_bar.value = p["nuoc"]
	health_bar.value = 0.0 if p["chet"] else float(p.get("suc_khoe", 1.0))
	if p["chet"]:
		stage_l.text = "Cây đã chết (%s). Bỏ vào thùng rác để dọn chậu." % p.get("ly_do", "")
	elif not p.get("da_tuoi", true):
		stage_l.text = "Hạt vừa gieo\nTưới nước để hạt bắt đầu nảy mầm"
	elif gs.has_pod(selected):
		var ready: int = gs.pod_ready(selected)
		var pend: int = gs.pod_pending(selected)
		stage_l.text = "Đang kết hạt lai"
		if ready > 0:
			stage_l.text += "\n%d hạt chờ thu: chạm vào cây để thu" % ready
		if pend > 0:
			stage_l.text += "\nHạt sau: %s (còn %d hạt)" % [_short_time(gs.pod_next_seconds(selected)), pend]
	elif st < 4:
		stage_l.text = "%s\nGiai đoạn sau: %s" % [Data.STAGE_NAMES[st], _short_time(gs.seconds_to_next_stage(p))]
	else:
		stage_l.text = "Già, đã có hạt\nDùng kéo để thu hạt"
	if st >= 1:
		var ph := Gen.phenotype(p["gen"])
		traits_l.text = "Hoa %s · Lá %s · Thân %s · Màu %s · Cỡ %s" % [
			Data.trait_name("hoa", ph["hoa"]).to_lower(), Data.trait_name("la", ph["la"]).to_lower(),
			Data.trait_name("than", ph["than"]).to_lower(), Data.trait_name("mau", ph["mau"]).to_lower(),
			Data.trait_name("co", ph["co"]).to_lower()]
	else:
		traits_l.text = "Hạt chỉ lộ hình dạng khi nảy mầm."
	var soil_name: String = Data.SOILS[gs.soils[selected]]["ten"] if gs.soils[selected] != "" else "chưa có đất"
	traits_l.text += "\n%s" % soil_name
	if st >= 1 and not p["chet"] and gs.soil_mismatch(selected) > 0:
		traits_l.text += " · cây cần %s, sức khỏe đang giảm!" % Data.SOILS[gs.soil_needed(p)]["ten"].to_lower()
	var shown: bool = p.get("trung_bay", false)
	if gs.can_sell(selected):
		price_btn.text = "Giá: %d xu%s  · sửa" % [gs.asking_price(p), " · HOT" if gs.is_hot(p["gen"]) else (" · 50%" if gs.is_young(selected) else "")]
		price_btn.disabled = false
		sell_btn.disabled = false
	else:
		price_btn.text = "Giá: —"
		price_btn.disabled = true
		sell_btn.disabled = true
	sell_btn.text = "Thu về vườn" if shown else "Trưng bày"
	if shown:
		stage_l.text = "Đang ở Shop cây cảnh"
	if p["chet"]:
		state_l.text = "Đã chết"
	elif shown:
		state_l.text = "Đang trưng bày"
	elif not p.get("da_tuoi", true):
		state_l.text = "Chờ tưới nước"
	elif p["nuoc"] <= 0.0:
		state_l.text = "Khát nước!"
	elif p.get("heo", false):
		state_l.text = "Đang héo"
	elif st >= 1 and gs.soil_mismatch(selected) > 0:
		state_l.text = "Đất không hợp"
	elif gs.pod_ready(selected) > 0:
		state_l.text = "Có hạt lai!"
	elif gs.has_pod(selected):
		state_l.text = "Đang kết hạt"
	elif p.get("da_lai", false) and st == 3:
		state_l.text = "Đã thụ phấn"
	elif st == 3:
		state_l.text = "Đang ra hoa"
	elif st == 4:
		state_l.text = "Đang cho hạt"
	else:
		state_l.text = "Đang lớn"
	var grown: float = p["tien_do"] * gs.grow_mult(p) / gs.time_scale
	age_l.text = "Tuổi: %s" % _short_time(grown)


func _short_time(sec: float) -> String:
	var s := int(ceil(sec))
	if s < 60:
		return "%ds" % s
	if s < 3600:
		return "%dp" % (s / 60)
	if s < 86400:
		return "%dg%02dp" % [s / 3600, (s % 3600) / 60]
	return "%dn%dg" % [s / 86400, (s % 86400) / 3600]


func _status(text: String) -> void:
	status_l.text = text
	status_l.modulate.a = 1.0
	if status_tween:
		status_tween.kill()
	status_tween = create_tween()
	status_tween.tween_interval(5.0)
	status_tween.tween_property(status_l, "modulate:a", 0.45, 0.8)


# =====================================================================
# Thao tác
# =====================================================================

func _change_page(d: int) -> void:
	shelf_page = clampi(shelf_page + d, 0, _pages() - 1)
	_refresh_all()


func _seed_page(d: int) -> void:
	seed_bag.go_page(seed_bag.page + d)


## Chọn hạt theo ô thứ k của trang đang xem.
func _pick_seed(k: int) -> void:
	_select_seed(seed_bag.page * SEEDS_PER_PAGE + k)


func _select_seed(idx: int) -> void:
	if idx < 0 or idx >= gs.seeds.size():
		return
	selected_seed = idx
	var s: Dictionary = gs.seeds[idx]
	var parents: Array = s.get("bo_me", [])
	var from := "mua ở cửa hàng"
	if parents.size() == 2:
		var a := Gen.variety_name_of_pheno(Gen.phenotype_from_key(parents[0]))
		var b := Gen.variety_name_of_pheno(Gen.phenotype_from_key(parents[1]))
		from = "thu từ %s" % a if parents[0] == parents[1] else "lai %s × %s" % [a, b]
	_status("Hạt %d (%s). Kéo hạt thả vào chậu có đất để gieo." % [idx + 1, from])
	_refresh_all()


func _on_slot(k: int) -> void:
	var i := shelf_page * SLOTS_PER_PAGE + k
	if i >= gs.pots.size():
		if i == gs.pots.size() and gs.pots.size() < Data.MAX_POTS:
			_open_shop()
		return
	selected = i
	if gs.pots[i].is_empty():
		if gs.soils[i] == "":
			_status("Chậu %d chưa có đất. Bấm túi đất bên trái để cho đất vào." % (i + 1))
		elif gs.seeds.is_empty():
			_status("Túi hạt trống. Mua hạt ở mục Vật tư hoặc lai giống để có hạt.")
		else:
			_status("Kéo một hạt từ Túi hạt thả vào chậu %d để gieo." % (i + 1))
	elif gs.pod_ready(i) > 0:
		gs.harvest_pod(i)    # chạm vào cây có hạt lai để thu
	else:
		_status("Đã chọn cây ở chậu %d." % (i + 1))
	_refresh_all()


func _use_soil(t: String) -> void:
	if selected < 0:
		_status("Chọn một chậu trống trước, rồi chọn túi đất.")
		return
	if not gs.soils_owned.get(t, false):
		_status("Chưa có %s. Mua ở mục Vật tư (%d xu), mua một lần dùng mãi." % [Data.SOILS[t]["ten"].to_lower(), Data.SOILS[t]["gia"]])
		return
	if not gs.pots[selected].is_empty():
		_status("Chậu đang có cây. Chỉ cho đất vào chậu trống.")
		return
	gs.fill_soil(selected, t)
	_refresh_all()


func _can_drop_seed(k: int, data) -> bool:
	var i := shelf_page * SLOTS_PER_PAGE + k
	if typeof(data) == TYPE_DICTIONARY and data.has("sung"):
		return i < gs.pots.size()
	return typeof(data) == TYPE_DICTIONARY and data.has("hat") and i < gs.pots.size() \
		and gs.pots[i].is_empty() and gs.soils[i] != ""


func _drop_seed(k: int, data) -> void:
	var i := shelf_page * SLOTS_PER_PAGE + k
	if not _can_drop_seed(k, data):
		return
	if data.has("sung"):
		_drop_gun(i)
		return
	if gs.plant_seed(i, int(data["hat"])):
		selected = i
	_refresh_all()


func _use_tool(kind: String) -> void:
	if kind == "dat":
		_use_soil_bag()
		return
	if kind == "sung":
		if pollen_gen.is_empty():
			_status("Kéo súng thụ phấn thả vào cây đang ra hoa để lấy phấn.")
		else:
			_unload_gun()
			_status("Đã bỏ phấn trong súng.")
		_refresh_all()
		return
	if kind == "nuoc" and gs.can_tier > 0:
		_water_upgraded()
		return
	var p := _sel_plant()
	if p.is_empty() or p["chet"]:
		_status("Hãy chọn một cây còn sống trước khi dùng dụng cụ.")
		return
	if p.get("trung_bay", false):
		_status("Cây đang trưng bày ở shop. Vào Shop cây rồi chạm nhà kính (hoặc nút Về vườn) để mang về.")
		return
	var st: int = gs.stage_of(p)
	match kind:
		"nuoc":
			gs.water(selected)
			_play_water(selected)
			_status("Đã tưới nước.")
		"phan":
			if gs.fertilizer <= 0:
				_status("Hết phân bón. Mua ở mục Vật tư.")
			else:
				gs.fertilize(selected)
		"keo":
			if st < 4:
				_status("Kéo dùng để thu hạt khi cây đã già.")
			elif gs.has_pod(selected):
				_status("Cây đang kết hạt lai. Chạm vào cây để thu hạt lai trước đã.")
			elif not tool_busy:
				# kéo lượn quanh bông hoa cắt xong mới thu hạt
				var pot := selected
				var ok := _play_tool("keo", pot, func():
					if pot < gs.pots.size() and not gs.pots[pot].is_empty():
						gs.harvest_seeds(pot)
						if selected == pot:
							selected = -1
					_refresh_all())
				if not ok:
					gs.harvest_seeds(pot)
					selected = -1
	_refresh_all()


## Bình xanh tưới cả hàng của chậu đang chọn, bình vàng tưới cả vườn.
func _water_upgraded() -> void:
	if gs.can_tier == 1 and selected < 0:
		_status("Chọn một chậu trong hàng muốn tưới, rồi bấm bình tưới.")
		return
	var targets: Array = gs.water_targets(maxi(selected, 0))
	var n: int = gs.water_many(targets)
	var order := 0
	for i in targets:
		var p: Dictionary = gs.pots[i]
		if not p.is_empty() and not p["chet"] and not p.get("trung_bay", false):
			_play_water(i, order * 0.12)
			order += 1
	if n == 0:
		_status("Không có cây nào để tưới.")
	else:
		_status("Đã tưới %d cây%s." % [n, " trong hàng" if gs.can_tier == 1 else " trong vườn"])
	_refresh_all()


## Túi đất: cho loại đất tốt nhất đã mua vào chậu trống đang chọn.
func _use_soil_bag() -> void:
	var t: String = gs.best_soil()
	if selected < 0:
		_status("Chọn một chậu trống trước, rồi bấm túi đất.")
		return
	if not gs.pots[selected].is_empty():
		_status("Chậu đang có cây. Chỉ cho đất vào chậu trống.")
		return
	if gs.soils[selected] == t:
		gs.fill_soil(selected, t)    # báo "chậu đã có đất này rồi"
		return
	if tool_busy:
		return
	# bao đất đặt cạnh chậu, xẻng xúc đất đổ vào xong mới có đất
	var pot := selected
	if not _play_tool("dat", pot, func():
			gs.fill_soil(pot, t)
			_refresh_all()):
		gs.fill_soil(pot, t)
	_refresh_all()


## Chạy hoạt ảnh dụng cụ trên chậu i; on_done chạy khi hoạt ảnh xong. Trả về false nếu chậu không hiện trên kệ.
func _play_tool(mode: String, i: int, on_done: Callable) -> bool:
	var kk := i - shelf_page * SLOTS_PER_PAGE
	if kk < 0 or kk >= SLOTS_PER_PAGE:
		return false
	var r: Rect2 = slots[kk].get_global_rect()
	var anim := Control.new()
	anim.set_script(ToolAnim)
	anim.mode = mode
	anim.k = clampf(r.size.y / 125.0, 0.8, 1.6)
	anim.soil_pos = Vector2(r.get_center().x, r.end.y - (r.size.y - 2.0) * 0.40)
	anim.flower_pos = Vector2(r.get_center().x, r.position.y + r.size.y * 0.22)
	if mode == "dat":
		var t: String = gs.best_soil()
		anim.bag_color = {"thuong": Color("d8b878"), "tot": Color("7fb66a"), "hiem": Color("9b6fc8")}.get(t, Color("d8b878"))
		anim.soil_color = {"thuong": Color("6b4a2e"), "tot": Color("4a3420"), "hiem": Color("3a2a3a")}.get(t, Color("6b4a2e"))
	elif not gs.pots[i].is_empty():
		anim.petal_color = Data.FLOWER_COLORS.get(Gen.expressed(gs.pots[i]["gen"], "mau"), Color("e85a7a"))
	tool_busy = true
	anim.on_done = func():
		tool_busy = false
		on_done.call()
	anim.z_index = 50
	add_child(anim)
	move_child(anim, nursery.get_index())
	return true


## Hoạt ảnh bình tưới trên chậu i (nếu chậu đang hiện trên kệ).
func _play_water(i: int, delay := 0.0) -> void:
	var k := i - shelf_page * SLOTS_PER_PAGE
	if k < 0 or k >= SLOTS_PER_PAGE:
		return
	var r: Rect2 = slots[k].get_global_rect()
	var anim := Control.new()
	anim.set_script(WaterAnim)
	anim.target = Vector2(r.get_center().x, r.end.y - (r.size.y - 2.0) * 0.40)
	anim.scale_k = clampf(r.size.y / 115.0, 0.8, 1.6)
	anim.tint = [Color(0.25, 0.62, 0.36), Color(0.23, 0.47, 0.85), Color(0.88, 0.67, 0.13)][clampi(gs.can_tier, 0, 2)]
	anim.delay = delay
	anim.z_index = 50
	add_child(anim)
	move_child(anim, nursery.get_index())   # nằm dưới Shop cây và bảng bật lên


# ---------- Súng thụ phấn ----------

func _can_give_pollen(i: int) -> bool:
	if i < 0 or i >= gs.pots.size():
		return false
	var p: Dictionary = gs.pots[i]
	# cây đang ra hoa, kể cả cây đã được thụ phấn và đang kết hạt, vẫn cho phấn được
	if p.is_empty() or p["chet"] or p.get("trung_bay", false):
		return false
	return gs.stage_of(p) == 3 or (gs.stage_of(p) == 4 and gs.has_pod(i))


func _gun_drag_data(b: Control):
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := _icon("sung", Vector2(84, 84))
	ic.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ic.size = Vector2(84, 84)
	ic.position = Vector2(-42, -56)
	ic.loaded = not pollen_gen.is_empty()
	ic.tier = 2 if gs.gold_gun else 0
	holder.add_child(ic)
	b.set_drag_preview(holder)
	tool_icons["sung"].modulate.a = 0.0    # súng đang trên tay
	_status("Thả súng vào cây đang ra hoa." if pollen_gen.is_empty() else "Thả súng vào cây ra hoa để thụ phấn (%d xu), thả lại cây cũ là tự thụ phấn." % Data.POLLINATE_COST)
	return {"sung": true}


## Thả súng xong: súng bay về chỗ cũ trong hàng dụng cụ.
func _gun_return() -> void:
	var ic: Control = tool_icons["sung"]
	ic.pivot_offset = ic.size / 2.0
	ic.scale = Vector2(0.4, 0.4)
	ic.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(ic, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh_all()


func _unload_gun() -> void:
	pollen_gen = {}
	pollen_from = -1


func _drop_gun(i: int) -> void:
	var p: Dictionary = gs.pots[i]
	if pollen_gen.is_empty():
		if p.is_empty():
			_status("Chậu này chưa có cây. Kéo súng vào cây đang ra hoa để lấy phấn.")
		elif not _can_give_pollen(i):
			_status("Chỉ lấy được phấn từ cây đang ra hoa.")
		else:
			pollen_gen = p["gen"].duplicate(true)
			pollen_from = i
			_status("Đã nạp phấn %s! Kéo súng tới cây ra hoa khác để lai, hoặc thả lại chính cây này để tự thụ phấn." % Gen.variety_name(p["gen"]))
	else:
		if not gs.can_cross(i):
			if p.is_empty():
				_status("Chậu này chưa có cây. Kéo súng tới cây đang ra hoa để thụ phấn.")
			elif p.get("da_lai", false):
				_status("Cây này đã được thụ phấn rồi. Hãy chọn cây ra hoa khác.")
			else:
				_status("Chỉ thụ phấn được cho cây đang ra hoa.")
		elif gs.pollinate(i, pollen_gen, i == pollen_from):   # thả lại vào chính cây đó = tự thụ phấn
			_unload_gun()
			selected = i
	_refresh_all()


func _on_trash() -> void:
	var p := _sel_plant()
	if p.is_empty():
		_status("Chọn cây muốn bỏ trước.")
		return
	if p.get("trung_bay", false):
		_status("Cây đang trưng bày ở shop, không bỏ được.")
		return
	if p["chet"]:
		gs.remove_plant(selected)
		_status("Đã dọn chậu.")
		return
	var idx := selected
	_confirm("Bỏ cây?", "Cây %s sẽ bị bỏ đi và không lấy lại được." % Gen.variety_name(p["gen"]), "Bỏ cây", func():
		gs.remove_plant(idx)
		_status("Đã bỏ cây."))


func _on_sell() -> void:
	if selected < 0 or not gs.can_sell(selected):
		return
	if gs.is_displayed(selected):
		gs.set_display(selected, false)
		_status("Đã thu cây về vườn.")
	elif gs.is_young(selected):
		# cây chưa ra hoa: hỏi trước vì chỉ bán được nửa giá
		var pot := selected
		_confirm("Cây chưa ra hoa",
			"Cây giống đang phát triển, chưa có hoa. Nếu bán sẽ chỉ thu về 50%% xu (khoảng %d xu).\nBạn có đồng ý bán?" % gs.asking_price(gs.pots[pot]),
			"Đồng ý", func():
				if pot < gs.pots.size() and gs.can_sell(pot) and not gs.is_displayed(pot):
					gs.set_display(pot, true)
				_refresh_all(), "Từ chối", PRIMARY)
		return
	else:
		gs.set_display(selected, true)
	_refresh_all()


func _on_price_pressed() -> void:
	if selected >= 0 and gs.can_sell(selected):
		_open_price_editor(selected)


func _music(track: String) -> void:
	var m := get_node_or_null("/root/Music")
	if m:
		m.play_track(track)


func _open_nursery() -> void:
	_close_popup()
	pollen_from = -1
	nursery.open_shop()
	_music("shop")


func _close_nursery() -> void:
	var sold := 0
	for st in nursery.stands:
		if st["sold"] >= 0:
			sold += 1
	nursery.close_shop()
	_music("vuon")
	var back: int = gs.undisplay_all()
	if back > 0:
		_status("Đã bán %d cây. %d cây chưa bán đã về lại chậu." % [sold, back])
	else:
		_status("Đã bán %d cây ở shop." % sold)
	_refresh_all()


# =====================================================================
# Bảng bật lên
# =====================================================================

## Mở một bảng bật lên. tap_outside_closes: chạm vào vùng tối bên ngoài để đóng.
func _open_popup(title: String, width := 760, height := 560, tap_outside_closes := true, scrollable := true) -> VBoxContainer:
	_close_popup()
	overlay.visible = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	if tap_outside_closes:
		dim.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_close_popup.call_deferred())
	overlay.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -width / 2.0
	panel.offset_right = width / 2.0
	panel.offset_top = -height / 2.0
	panel.offset_bottom = height / 2.0
	overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if scrollable:
		var scroll := ScrollContainer.new()
		scroll.set_script(DragScroll)   # vuốt bằng ngón tay để cuộn
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		panel.add_child(scroll)
		scroll.add_child(box)
	else:
		panel.add_child(box)   # bảng kéo thả (kho hạt): không cuộn để kéo hạt không bị nhầm thành cuộn
	box.add_child(_label(title, 28, Color("7a4a1a")))
	return box


func _close_popup() -> void:
	popup_refresh = Callable()
	_clear(overlay)
	overlay.visible = false
	if not chat_ctx.is_empty():
		var ctx := chat_ctx
		chat_ctx = {}
		nursery.chat_finished(ctx["c"], ctx.get("bought", false), ctx.get("price", 0))
	if not special_ctx.is_empty():
		var sctx := special_ctx
		special_ctx = {}
		nursery.special_finished(sctx["c"], sctx.get("result", ""))
		if selected >= 0 and selected < gs.pots.size() and gs.pots[selected].is_empty():
			selected = -1
	_refresh_all()


func _show_info(title: String, text: String) -> void:
	var box := _open_popup(title, 620, 340)
	box.add_child(_label(text))
	box.add_child(_button("Đóng", _close_popup, PRIMARY))


func _confirm(title: String, text: String, yes_text: String, on_yes: Callable, no_text := "Thôi", yes_color := DANGER) -> void:
	var box := _open_popup(title, 620, 300)
	box.add_child(_label(text))
	var row := HBoxContainer.new()
	box.add_child(row)
	var no := _button(no_text, _close_popup)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(no)
	var yes := _button(yes_text, func():
		_close_popup()
		on_yes.call(), yes_color)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(yes)


func _open_menu() -> void:
	var box := _open_popup("Menu", 560, 520)
	var fast: bool = gs.time_scale > 1.0
	box.add_child(_button("Tiếp tục chơi", _close_popup, PRIMARY))
	box.add_child(_button("Cách chơi", _open_help))
	_sound_controls(box, _open_menu)
	box.add_child(_button("Chế độ thử nhanh: %s" % ("BẬT (1 phút = 1 giờ)" if fast else "TẮT"), func():
		gs.time_scale = 1.0 if fast else 60.0
		_open_menu()))
	box.add_child(_button("Màn hình chính", func():
		_close_popup()
		gs.save_game()
		_show_title()))
	box.add_child(_button("Chơi lại từ đầu", _ask_restart, DANGER))


## Nút bật/tắt nhạc và thanh âm lượng; reopen: mở lại bảng hiện tại để cập nhật chữ trên nút.
func _sound_controls(box: VBoxContainer, reopen: Callable) -> void:
	var m := get_node_or_null("/root/Music")
	if m:
		box.add_child(_button("Nhạc nền: %s" % ("BẬT" if m.enabled else "TẮT"), func():
			m.set_enabled(not m.enabled)
			reopen.call()))
		var vrow := HBoxContainer.new()
		box.add_child(vrow)
		var vl := _label("Âm lượng", 19, INK)
		vl.autowrap_mode = TextServer.AUTOWRAP_OFF
		vl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		vrow.add_child(vl)
		var vs := HSlider.new()
		vs.min_value = 0
		vs.max_value = 100
		vs.step = 5
		vs.value = round(m.volume * 100)
		vs.custom_minimum_size.y = 40
		vs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vs.value_changed.connect(func(v): m.set_volume(v / 100.0))
		vrow.add_child(vs)


func _open_sound() -> void:
	var box := _open_popup("Tùy chỉnh âm thanh", 560, 280, true, false)
	_sound_controls(box, _open_sound)
	box.add_child(_button("Xong", _close_popup, PRIMARY))


func _ask_restart() -> void:
	_confirm("Chơi lại từ đầu?", "Bạn có đồng ý chơi lại từ đầu không?\nToàn bộ cây, hạt, xu và sổ tay sẽ bị xóa.", "Đồng ý", func():
		gs.reset_game()
		selected = -1
		pollen_from = -1
		shelf_page = 0
		_hide_title()
		_status("Bắt đầu vườn mới!"), "Từ chối")


# =====================================================================
# Màn hình chính
# =====================================================================

func _build_title() -> void:
	title_screen = Control.new()
	title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.z_index = 2500          # trên shop và nhà kính, dưới bảng bật lên
	title_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(title_screen)
	move_child(title_screen, overlay.get_index())
	var bg := TextureRect.new()
	bg.texture = load("res://art/man_hinh_chinh.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_screen.add_child(bg)

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_top = 22
	col.offset_bottom = -22
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_screen.add_child(col)
	var name_l := _label("Vườn Ươm Kỳ Diệu", 64, Color("fff4d2"), HORIZONTAL_ALIGNMENT_CENTER)
	name_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_l.add_theme_color_override("font_outline_color", Color("6a3412"))
	name_l.add_theme_constant_override("outline_size", 16)
	name_l.add_theme_color_override("font_shadow_color", Color(0.2, 0.08, 0, 0.55))
	name_l.add_theme_constant_override("shadow_offset_y", 5)
	name_l.add_theme_constant_override("shadow_outline_size", 16)
	col.add_child(name_l)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 6
	col.add_child(spacer)

	# bảng gỗ chứa các nút, đặt giữa màn hình
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.bevel_box(Color(0.42, 0.26, 0.13, 0.86), GOLD, 22, "normal", Vector4(22, 20, 22, 20)))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 380
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	box.add_child(_button("Tiếp tục chơi", _hide_title, PRIMARY))
	box.add_child(_button("Cách chơi", _open_help))
	box.add_child(_button("Tùy chỉnh âm thanh", _open_sound))
	box.add_child(_button("Chơi lại từ đầu", _ask_restart, Color("c8641e")))
	# trình duyệt (web / iPhone) không cho game tự đóng tab nên không có nút Thoát
	if not OS.has_feature("web"):
		box.add_child(_button("Thoát game", func():
			gs.save_game()
			get_tree().quit(), DANGER))
	# chỉ hiện khi đây là cảnh chính của game (các bài thử tự nạp màn chơi thì bỏ qua)
	title_screen.visible = get_tree().current_scene == self
	if not title_screen.visible:
		_hide_title()


func _show_title() -> void:
	if nursery.visible:
		_close_nursery()
	title_screen.visible = true


func _hide_title() -> void:
	title_screen.visible = false
	if gs.away_report != "":
		_show_info("Trong lúc bạn vắng mặt", gs.away_report)
		gs.away_report = ""


func _open_help() -> void:
	var box := _open_popup("Cách chơi", 860, 600)
	box.add_child(_label(
		"• Chậu trống cần có đất: chạm chọn chậu, rồi bấm Túi đất ở hàng dụng cụ (luôn dùng loại đất tốt nhất bạn đã mua).\n" +
		"  Bán, bỏ cây, thu hạt xong hoặc mua chậu mới thì phải cho đất lại.\n" +
		"• Kéo một hạt trong Túi hạt thả vào chậu có đất để gieo, rồi tưới nước thì hạt mới bắt đầu lớn.\n" +
		"• Cây Hiếm cần Đất tốt, cây Quý và Huyền thoại cần Đất hiếm; đất kém hơn thì sức khỏe giảm dần.\n" +
		"  Đất tốt và Đất hiếm mua một lần ở mục Vật tư là dùng mãi.\n" +
		"• Chạm vào cây để chọn, rồi bấm dụng cụ bên trái:\n" +
		"    Bình tưới: tưới nước. Bao phân: hồi 35% sức khỏe, cây chưa ra hoa lớn nhanh hơn. Kéo: thu hạt khi cây già.\n" +
		"    Đất kém hơn cây cần làm cây mất sức khỏe nhanh và không tự hồi: phải bón phân để cứu cây.\n" +
		("    Súng thụ phấn: kéo súng thả vào cây đang ra hoa để nạp phấn (cây đang kết hạt vẫn cho phấn), rồi kéo tới cây ra hoa khác để lai (%d xu).\n    Thả lại vào chính cây vừa lấy phấn là tự thụ phấn: hạt ra giống hệt cây đó.\n" % Data.POLLINATE_COST) +
		("    Cây được thụ phấn kết %d hạt lai, cứ %d phút một hạt. Có hạt thì cạnh chậu hiện ký hiệu hạt: chạm vào cây để thu.\n" % [Data.SEEDS_PER_CROSS, int(Data.SEED_POD_INTERVAL / 60.0)]) +
		"    Túi đất: chọn chậu trống rồi bấm túi đất để cho loại đất tốt nhất bạn có.\n" +
		"    Bình tưới xanh tưới cả hàng cây, bình tưới vàng tưới cả vườn. Súng thụ phấn vàng giúp hạt lai hiếm hơn và dễ ra giống mới.\n" +
		"• Vườn có tối đa 15 chậu. Bấm Kho hạt để cất bớt hạt: kéo hạt giữa túi và kho (hoặc kéo hạt từ túi thả vào nút Kho hạt).\n" +
		"• Thanh NƯỚC cạn thì cây ngừng lớn và mất SỨC KHỎE (cây càng hiếm mất càng nhanh); sức khỏe dưới một nửa là héo, hết là chết.\n" +
		"• Thỉnh thoảng có bướm, chuồn chuồn hoặc ong bay vào nhà kính. Chạm vào để nhận câu đố, trả lời đúng được 1 xu.\n" +
		"• Bấm vào ô Giá để chỉnh giá cây. Bấm Trưng bày để đưa cây ra Shop cây cảnh.\n" +
		"  Cây chưa ra hoa vẫn bán được nhưng chỉ thu về 50% xu (game sẽ hỏi lại trước khi đưa ra shop).\n" +
		"• Trong Shop cây: khách vào xem các cây, ai ra đứng ở quầy thì trò chuyện mua cây; chọn cách trả lời khéo để khách mua.\n" +
		"  Chạm vào cây trên gốc để chỉnh giá. Chạm nhà kính giữa sân (hoặc nút Về vườn): cây chưa bán trở lại chậu cũ.\n" +
		"• Cây ra hoa lần đầu được ghi vào Sổ tay. Tìm đủ các giống hiếm và huyền thoại!", 21))
	box.add_child(_button("Đóng", _close_popup, PRIMARY))


# =====================================================================
# Đặt giá và quầy bán hàng
# =====================================================================

func _open_price_editor(i: int) -> void:
	if i < 0 or i >= gs.pots.size() or gs.pots[i].is_empty():
		return
	var p: Dictionary = gs.pots[i]
	var market: int = gs.market_price(p)
	var box := _open_popup("Chỉnh giá bán", 820, 500)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)
	var pv := _plant_view(Vector2(190, 320))
	pv.set_plant(p["gen"], gs.stage_of(p), false, p.get("heo", false))
	pv.set_soil(gs.soils[i])
	row.add_child(pv)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	right.add_child(_label("%s\nGiá thị trường hôm nay: %d xu" % [Gen.variety_name(p["gen"]), market], 22))
	var price_lbl := _label("", 38, ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	right.add_child(price_lbl)
	var slider := HSlider.new()
	slider.min_value = Data.PRICE_MIN_PCT
	slider.max_value = Data.PRICE_MAX_PCT
	slider.step = 5
	slider.value = gs.price_pct(p)
	slider.custom_minimum_size.y = 50
	right.add_child(slider)
	var chance_l := _label("", 22, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	right.add_child(chance_l)
	right.add_child(_label("Giá càng cao hơn giá thị trường thì khách càng khó mua. Giá được giữ cho cây này cả khi trưng bày.", 18, MUTED))
	var update := func(_v = 0.0):
		var pr: int = maxi(1, int(round(market * slider.value / 100.0)))
		price_lbl.text = "%d xu  (%d%%)" % [pr, int(slider.value)]
		chance_l.text = "Khả năng bán theo giá: %s" % gs.chance_level(gs.price_chance(market, pr, 2.0))
	slider.value_changed.connect(update)
	update.call()
	var btns := HBoxContainer.new()
	right.add_child(btns)
	var cancel := _button("Hủy", _close_popup)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(cancel)
	var save := _button("Lưu giá", func():
		gs.set_price_pct(i, int(slider.value))
		_close_popup()
		_status("Đã đặt giá %d xu." % gs.asking_price(gs.pots[i])), ACCENT)
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btns.add_child(save)


## Khách đứng ở quầy: giao diện trò chuyện mua cây.
func _open_chat(c: Dictionary) -> void:
	var pot: int = nursery.stands[c["choice"]]["pot"]
	if pot >= gs.pots.size() or gs.pots[pot].is_empty():
		nursery.chat_finished(c, false, 0)
		return
	var p: Dictionary = gs.pots[pot]
	var cust: Dictionary = c["cust"]
	var price: int = gs.asking_price(p)
	var box := _open_popup("Khách ở quầy", 1120, 600, false)   # không đóng khi chạm ra ngoài, tránh lỡ tay mất khách
	chat_ctx = {"c": c, "pot": pot, "price": price, "bought": false}
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)

	var scene := PanelContainer.new()
	var ssb := _box(Color("f6ead2"), 16)
	ssb.border_color = Color("c9a46a")
	ssb.set_border_width_all(3)
	ssb.content_margin_left = 10
	ssb.content_margin_right = 10
	ssb.content_margin_top = 10
	scene.add_theme_stylebox_override("panel", ssb)
	row.add_child(scene)
	# sân khấu: khách đứng bên trái, chậu cây trên bàn gỗ bên phải, bảng giá góc trên
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(540, 450)
	scene.add_child(stage)
	var table := Control.new()
	table.set_script(load("res://scripts/counter_table.gd"))
	table.position = Vector2(296, 352)
	table.size = Vector2(236, 98)
	stage.add_child(table)
	var pv := _plant_view(Vector2(226, 290))
	pv.position = Vector2(301, 80)
	pv.set_plant(p["gen"], gs.stage_of(p), false, p.get("heo", false))
	pv.set_soil(gs.soils[pot])
	stage.add_child(pv)
	var cv := Control.new()
	cv.set_script(CustomerView)
	cv.position = Vector2(0, 8)
	cv.size = Vector2(300, 442)
	stage.add_child(cv)
	var tag := PanelContainer.new()
	var tsb := _box(Color("fbf3e2"), 12)
	tsb.border_color = Color("b98a4a")
	tsb.set_border_width_all(2)
	tsb.content_margin_left = 14
	tsb.content_margin_right = 14
	tsb.content_margin_top = 6
	tsb.content_margin_bottom = 6
	tsb.shadow_color = Color(0, 0, 0, 0.18)
	tsb.shadow_size = 4
	tsb.shadow_offset = Vector2(0, 2)
	tag.add_theme_stylebox_override("panel", tsb)
	var tag_l := _label("%s - Giá: %d xu" % [Gen.variety_name(p["gen"]), price], 18, INK, HORIZONTAL_ALIGNMENT_CENTER)
	tag_l.autowrap_mode = TextServer.AUTOWRAP_OFF
	tag.add_child(tag_l)
	stage.add_child(tag)
	# bảng giá bám mép phải, tên cây dài thì giãn sang trái
	tag.anchor_left = 1.0
	tag.anchor_right = 1.0
	tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tag.offset_right = -12
	tag.offset_left = -12
	tag.offset_top = 14

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var price_info := _label("%s · Giá: %d xu" % [Gen.variety_name(p["gen"]), price], 19, MUTED)
	right.add_child(price_info)
	var bubble := PanelContainer.new()
	var bsb := _box(Color("fffdf6"), 16)
	bsb.border_color = Color("e2d3b4")
	bsb.set_border_width_all(2)
	bsb.content_margin_left = 18
	bsb.content_margin_right = 18
	bsb.content_margin_top = 12
	bsb.content_margin_bottom = 12
	bubble.add_theme_stylebox_override("panel", bsb)
	right.add_child(bubble)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 4)
	bubble.add_child(bv)
	bv.add_child(_label("Công tử ăn chơi (ghé mua cây)" if cust.get("cong_tu", false) else ("Đàn anh khu phố (ghé mua cây)" if cust.get("dan_anh", false) else Data.CUSTOMER_TYPES[cust["type"]]["ten"]), 18, MUTED))
	if cust.get("cong_tu", false):
		var loi_cong_tu: String = gs.wish_text(cust).replace("Tôi ", "Ta ").replace("tôi ", "ta ").replace("Chào chủ vườn!", "Này chủ vườn!")
		bv.add_child(_label("\"%s Ta để ý cây %s này, hàng hiếm đấy!\"" % [loi_cong_tu, Gen.variety_name(p["gen"])], 23))
	else:
		bv.add_child(_label("\"%s Tôi để ý cây %s này.\"" % [gs.wish_text(cust), Gen.variety_name(p["gen"])], 23))

	var lv: String = gs.chance_level(gs.buy_chance(p, price, cust, ""))
	var mood := {"Thấp": -1, "Vừa": 0, "Cao": 1}[lv] as int
	# dùng đúng nhân vật đang đứng ở quầy, vẽ dạng chân dung có ánh sáng khối
	var walker = c.get("node")
	cv.setup(cust["type"], mood, walker.variant if is_instance_valid(walker) else "")
	cv.set_hd(true)
	var chat_card := _card_tex(cv.variant)
	if chat_card != null:
		# thẻ chân dung giữ nguyên khung và nền, không tách nền (ví dụ công tử ăn chơi)
		cv.visible = false
		var card := TextureRect.new()
		card.texture = chat_card
		card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card.position = Vector2(4, 4)
		card.size = Vector2(288, 442)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(card)
		stage.move_child(card, cv.get_index())   # bảng giá vẫn nằm trên thẻ
	var mood_text := {"Thấp": "Khách nhìn cây có vẻ lưỡng lự…", "Vừa": "Khách đang phân vân…", "Cao": "Khách nhìn cây đầy thích thú!"}
	var mood_l := _label(mood_text[lv], 22, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	right.add_child(mood_l)

	var answers := VBoxContainer.new()
	answers.add_theme_constant_override("separation", 8)
	right.add_child(answers)
	var options := [
		["nhiet_tinh", "\"Cây này đúng thứ anh/chị cần!\""],
		["thanh_that", "\"Cây hơi khác, nhưng có %s rất đẹp.\"" % gs.best_match_phrase(p["gen"], cust)],
		["giam_gia", "\"Tôi bớt cho anh/chị 10%%, còn %d xu.\"" % maxi(1, int(round(price * (1.0 - Data.DISCOUNT))))],
	]
	for opt in options:
		var b := _button(opt[1], func(): _chat_answer(opt[0], cv, mood_l, answers), Color("4f6f7f"))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		answers.add_child(b)
	right.add_child(_button("Không bán cây này", _close_popup))


func _chat_answer(kind: String, cv: Control, mood_l: Label, answers: VBoxContainer) -> void:
	var pot: int = chat_ctx.get("pot", -1)
	if pot < 0 or not gs.can_sell(pot):
		_close_popup()
		return
	var p: Dictionary = gs.pots[pot]
	var cust: Dictionary = chat_ctx["c"]["cust"]
	var price: int = chat_ctx["price"]
	if kind == "giam_gia":
		price = maxi(1, int(round(price * (1.0 - Data.DISCOUNT))))
		chat_ctx["price"] = price
	var bought: bool = randf() < gs.buy_chance(p, price, cust, kind)
	_clear(answers)
	if bought:
		cv.set_mood(1)
		mood_l.text = "Khách mua cây với giá %d xu!" % price
		mood_l.add_theme_color_override("font_color", PRIMARY)
		gs.complete_sale(pot, price)
		chat_ctx["bought"] = true
		if selected == pot:
			selected = -1
	else:
		cv.set_mood(-1)
		var why := "Khách lắc đầu, cảm ơn rồi đi ra."
		if Gen.count_matches(p["gen"], cust["wish"]) == 0:
			why = "Khách bảo cây không giống thứ họ tìm, rồi đi ra."
		elif kind == "nhiet_tinh":
			why = "Khách thấy bạn nói hơi quá, rồi đi ra."
		mood_l.text = why
		mood_l.add_theme_color_override("font_color", DANGER)
	answers.add_child(_button("Tiếp tục", _close_popup, PRIMARY))


# =====================================================================
# Khách ẩn ở quầy
# =====================================================================

func _open_special(c: Dictionary) -> void:
	if c["role"] == "vip":
		_open_vip_chat(c)
	elif c["role"] == "vip2":
		_open_vip2_chat(c)
	else:
		_open_bao_ke(c)


## Công tử ghé một mình: chê hoa tầm thường, hoặc hỏi mua cây đắt nhất vì nhớ mẹ.
func _open_vip2_chat(c: Dictionary) -> void:
	var khinh: bool = nursery.event_kind == "khinh"
	var k: int = -1 if khinh else nursery.priciest_stand()
	var parts := _special_layout("Khách đặc biệt ở quầy", c, -1 if khinh else 0)
	var right: VBoxContainer = parts[2]
	var btns := VBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	if khinh or k < 0:
		special_ctx["result"] = "khinh"
		_speech(right, "Công tử ăn chơi", "\"Các loài hoa ở đây thật tầm thường, thật không xứng để bản công tử chạm vào!\"")
		right.add_child(_label("Công tử phẩy tay, chẳng thèm nhìn cây nào thêm.", 22, TEXT, HORIZONTAL_ALIGNMENT_CENTER))
		right.add_child(btns)
		btns.add_child(_button("Tiếp tục", _close_popup, PRIMARY))
		return
	var pot: int = nursery.stands[k]["pot"]
	var p: Dictionary = gs.pots[pot]
	var price: int = gs.asking_price(p)
	_speech(right, "Công tử ăn chơi", "\"Trước kia mẹ ta cũng trồng loài hoa này, ngươi có thể bán cho ta không!\"")
	var info_row := HBoxContainer.new()
	info_row.alignment = BoxContainer.ALIGNMENT_CENTER
	info_row.add_theme_constant_override("separation", 12)
	right.add_child(info_row)
	var pv := _plant_view(Vector2(120, 150))
	pv.set_plant(p["gen"], gs.stage_of(p), false, p.get("heo", false))
	pv.set_soil(gs.soils[pot])
	info_row.add_child(pv)
	var info := _label("Công tử muốn mua cây %s · giá %d xu" % [Gen.variety_name(p["gen"]), price], 22, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_row.add_child(info)
	right.add_child(btns)
	var yes := _button("Có", func():
		var got: int = nursery.vip2_buy(c, k)
		special_ctx["result"] = "mua" if got > 0 else "khong"
		info.text = ("Công tử trân trọng nhận cây và trả bạn %d xu." % got) if got > 0 else "Cây này vừa bán mất rồi…"
		info.add_theme_color_override("font_color", PRIMARY)
		_clear(btns)
		btns.add_child(_button("Tiếp tục", _close_popup, PRIMARY)), PRIMARY)
	btns.add_child(yes)
	btns.add_child(_button("Không", func():
		special_ctx["result"] = "khong"
		_close_popup()))


## Khung bên trái: chân dung khách đứng trước quầy. Trả về [hàng ngang, nhân vật, cột phải].
func _special_layout(title: String, c: Dictionary, mood: int) -> Array:
	var box := _open_popup(title, 1080, 580, false)
	special_ctx = {"c": c, "result": ""}
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)
	var cv := Control.new()
	cv.set_script(CustomerView)
	var walker = c.get("node")
	cv.setup(c["cust"]["type"], mood, walker.variant if is_instance_valid(walker) else "")
	# thẻ chân dung vẽ sẵn cả khung và nền (art/khach_that/<mã>_the.png), ví dụ công tử ăn chơi
	var card_tex := _card_tex(cv.variant)
	var card: TextureRect = null
	if card_tex != null:
		card = TextureRect.new()
		card.texture = card_tex
		card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card.custom_minimum_size = Vector2(300, 466)
		row.add_child(card)
	else:
		var scene := PanelContainer.new()
		var ssb := _box(Color("f6ead2"), 16)
		ssb.border_color = Color("c9a46a")
		ssb.set_border_width_all(3)
		ssb.content_margin_left = 24
		ssb.content_margin_right = 24
		ssb.content_margin_top = 10
		scene.add_theme_stylebox_override("panel", ssb)
		row.add_child(scene)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		scene.add_child(col)
		cv.custom_minimum_size = Vector2(220, 400)
		col.add_child(cv)
		var desk := ColorRect.new()
		desk.color = Color("8a5a34")
		desk.custom_minimum_size = Vector2(240, 40)
		col.add_child(desk)
	cv.set_hd(true)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	row.add_child(right)
	return [row, cv, right, card]


func _card_tex(variant: String) -> Texture2D:
	var path := "res://art/khach_that/%s_the.png" % variant
	return load(path) if ResourceLoader.exists(path) else null


func _speech(parent: Control, who: String, text: String) -> Label:
	var bubble := PanelContainer.new()
	var bsb := _box(Color("fffdf6"), 16)
	bsb.border_color = Color("e2d3b4")
	bsb.set_border_width_all(2)
	bsb.content_margin_left = 18
	bsb.content_margin_right = 18
	bsb.content_margin_top = 12
	bsb.content_margin_bottom = 12
	bubble.add_theme_stylebox_override("panel", bsb)
	parent.add_child(bubble)
	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 4)
	bubble.add_child(bv)
	bv.add_child(_label(who, 18, MUTED))
	var l := _label(text, 24)
	bv.add_child(l)
	return l


## Công tử ăn chơi: mua hết cây đang bày bán.
func _open_vip_chat(c: Dictionary) -> void:
	var parts := _special_layout("Khách đặc biệt ở quầy", c, 1)
	var cv: Control = parts[1]
	var right: VBoxContainer = parts[2]
	var n := 0
	var total := 0
	for k in nursery._open_stands():
		n += 1
		total += gs.asking_price(gs.pots[nursery.stands[k]["pot"]])
	var line := "\"Shop toàn cây Quý thế này mới xứng tầm anh chứ! Gói hết cho anh, bao nhiêu cũng được, khỏi thối!\""
	if nursery.event_kind == "huyen_thoai":
		line = "\"Trời đất, toàn cây Huyền thoại! Anh mua sạch, không mặc cả một đồng nào!\""
	_speech(right, "Công tử ăn chơi", line)
	var info := _label("Công tử muốn mua cả %d cây đang bày bán · tổng %d xu" % [n, total], 22, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	right.add_child(info)
	var btns := VBoxContainer.new()
	right.add_child(btns)
	btns.add_child(_button("Bán hết cho công tử", func():
		var r: Array = nursery.vip_sell_all(c)
		cv.set_mood(1)
		info.text = "Công tử rút cọc tiền, mua cả %d cây. Bạn nhận %d xu!" % [r[0], r[1]]
		info.add_theme_color_override("font_color", PRIMARY)
		_clear(btns)
		btns.add_child(_button("Tiếp tục", _close_popup, PRIMARY)), PRIMARY))


## Đàn anh đòi tiền bảo kê.
func _open_bao_ke(c: Dictionary) -> void:
	var parts := _special_layout("Có biến ở quầy!", c, -1)
	var cv: Control = parts[1]
	rps_card = parts[3]
	var right: VBoxContainer = parts[2]
	var say := _speech(right, "Đàn anh khu phố",
		"\"Có biết khu này của anh Phi ca không hả? Khôn hồn đóng tiền bảo kê, thuận anh Phi thì sống, nghịch anh Phi thì... cũng sống nhưng không thọ đâu!\"")
	var info := _label("Bạn sẽ làm gì?", 22, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	right.add_child(info)
	var btns := VBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	right.add_child(btns)
	btns.add_child(_button("Đánh khứa này luôn", func(): _rps_start(c, cv, say, info, btns), DANGER))
	btns.add_child(_button("Đóng tiền bảo kê", func():
		special_ctx["result"] = "dong_tien"
		var paid: int = gs.pay_protection()
		c["paid_fee"] = paid
		cv.set_mood(1)
		say.text = "\"Ngoan lắm, giờ chú chỉ việc bán còn khu này anh lo!\""
		info.text = "Bạn đóng %d xu tiền bảo kê. Gã đàn anh hài lòng bỏ đi." % paid
		_clear(btns)
		btns.add_child(_button("Tiếp tục", _close_popup, PRIMARY)), ACCENT))
	btns.add_child(_button("Báo cảnh sát", func():
		special_ctx["result"] = "canh_sat"
		say.text = "\"Ngon lắm, hãy đợi đó!\""
		info.text = "Gã bảo kê hằm hằm bỏ đi."
		_clear(btns)
		btns.add_child(_button("Tiếp tục", _close_popup, PRIMARY)), Color("3a6fb0")))


# ---------- Oẳn tù tì với đàn anh bảo kê ----------

const RPS_NAMES := {"bua": "Búa", "keo": "Kéo", "bao": "Bao"}
const RPS_BEATS := {"bua": "keo", "keo": "bao", "bao": "bua"}   # cái bên trái thắng cái bên phải
var rps := {}


var rps_card: TextureRect = null   # thẻ chân dung của đàn anh (nếu có)


func _rps_start(c: Dictionary, cv: Control, say: Label, info: Label, btns: VBoxContainer) -> void:
	special_ctx["result"] = "danh"
	_clear(btns)
	say.text = "\"Dám đánh anh à? Chơi oẳn tù tì 3 ván, thua thì đừng có khóc!\""
	var arena := HBoxContainer.new()
	arena.alignment = BoxContainer.ALIGNMENT_CENTER
	arena.add_theme_constant_override("separation", 26)
	btns.add_child(arena)
	var mine := _hand_box(arena, "Bạn")
	var vs := _label("VS", 30, DANGER, HORIZONTAL_ALIGNMENT_CENTER)
	vs.autowrap_mode = TextServer.AUTOWRAP_OFF
	vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arena.add_child(vs)
	var theirs := _hand_box(arena, "Đàn anh")
	var score := _label("", 20, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	btns.add_child(score)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	btns.add_child(row)
	rps = {"card": rps_card, "c": c, "cv": cv, "say": say, "info": info, "btns": btns, "row": row, "mine": mine, "theirs": theirs,
		"score": score, "round": 1, "win": 0, "lose": 0, "busy": false}
	for k in ["bua", "keo", "bao"]:
		var b := _button(RPS_NAMES[k], func(): _rps_pick(k), Color("6a4a8a"))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 64
		b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var ic := HandIcon.new()
		ic.kind = k
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.position = Vector2(6, 4)
		ic.size = Vector2(56, 56)
		b.add_child(ic)
		row.add_child(b)
	info.text = "Oẳn tù tì %d ván, hòa thì đánh lại. Chọn Búa, Kéo hoặc Bao!" % Data.RPS_ROUNDS
	_rps_score()


func _hand_box(parent: Control, who: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	parent.add_child(v)
	var ic := HandIcon.new()
	ic.custom_minimum_size = Vector2(150, 130)
	v.add_child(ic)
	v.add_child(_label(who, 18, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	return ic


func _rps_score() -> void:
	rps["score"].text = "Ván %d/%d  ·  Bạn thắng %d  ·  Thua %d" % [mini(rps["round"], Data.RPS_ROUNDS), Data.RPS_ROUNDS, rps["win"], rps["lose"]]


func _rps_pick(k: String) -> void:
	if rps.is_empty() or rps["busy"]:
		return
	rps["busy"] = true
	for b in rps["row"].get_children():
		b.disabled = true
	var mine: Control = rps["mine"]
	var theirs: Control = rps["theirs"]
	mine.kind = "bua"
	theirs.kind = "bua"
	mine.shake = true
	theirs.shake = true
	var info: Label = rps["info"]
	info.remove_theme_color_override("font_color")
	var tw := create_tween()
	for word in ["Oẳn…", "tù…", "tì!"]:
		tw.tween_callback(func():
			if is_instance_valid(info):
				info.text = word)
		tw.tween_interval(0.32)
	tw.tween_callback(func(): _rps_reveal(k))


func _rps_reveal(k: String, their := "") -> void:
	if rps.is_empty() or not is_instance_valid(rps["info"]):
		return
	if their == "":
		their = ["bua", "keo", "bao"].pick_random()
	var mine: Control = rps["mine"]
	var theirs: Control = rps["theirs"]
	mine.shake = false
	theirs.shake = false
	mine.kind = k
	theirs.kind = their
	var info: Label = rps["info"]
	var cv: Control = rps["cv"]
	var n: int = rps["round"]
	if k == their:
		info.text = "Hòa! Cả hai cùng ra %s. Đánh lại ván %d." % [RPS_NAMES[k], n]
	elif RPS_BEATS[k] == their:
		rps["win"] += 1
		rps["round"] += 1
		cv.set_mood(-1)
		rps["say"].text = ["\"Á! Ăn may thôi!\"", "\"Ui da! Chơi lại!\"", "\"Không thể nào!\""].pick_random()
		info.text = "%s thắng %s: bạn thắng ván %d!" % [RPS_NAMES[k], RPS_NAMES[their], n]
		info.add_theme_color_override("font_color", PRIMARY)
	else:
		rps["lose"] += 1
		rps["round"] += 1
		cv.set_mood(1)
		rps["say"].text = ["\"Hà hà, non lắm!\"", "\"Biết sợ chưa?\"", "\"Đỡ nè!\""].pick_random()
		info.text = "%s thua %s: bạn thua ván %d!" % [RPS_NAMES[k], RPS_NAMES[their], n]
		info.add_theme_color_override("font_color", DANGER)
	_rps_score()
	if rps["round"] > Data.RPS_ROUNDS:
		_rps_end()
		return
	rps["busy"] = false
	for b in rps["row"].get_children():
		b.disabled = false


func _rps_end() -> void:
	var c: Dictionary = rps["c"]
	var cv: Control = rps["cv"]
	var info: Label = rps["info"]
	var say: Label = rps["say"]
	var losses: int = rps["lose"]
	var paid: int = gs.pay_fight(losses)
	c["fight_paid"] = paid
	var cost: int = Data.BAO_KE_FIGHT_COST[losses]
	var note := "" if paid == cost else " (bạn chỉ còn %d xu)" % paid
	match losses:
		0:
			special_ctx["result"] = "danh_thang"
			cv.setup("bao_ke", -1, "dan_anh_thuong")   # thâm mắt, bó bột tay, băng đầu
			cv.set_hd(true)
			var card = rps.get("card")
			if card != null and is_instance_valid(card) and _card_tex("dan_anh_thuong") != null:
				card.texture = _card_tex("dan_anh_thuong")
			say.text = "\"Chờ đó, ta sẽ quay lại lợi hại hơn, đợi đi!\""
			info.text = "Bạn thắng cả 3 ván! Đàn anh bầm dập, bó bột tay ôm đầu bỏ chạy."
			info.add_theme_color_override("font_color", PRIMARY)
		1:
			info.text = "Bạn đã mất %d xu để mua bông băng thuốc đỏ.%s" % [paid, note]
		2:
			info.text = "Bác sĩ bó tay bạn. Mất %d xu.%s" % [paid, note]
		_:
			info.text = "Bạn nhập viện và xém lên bàn thờ ngắm chuối rồi! Mất %d xu.%s" % [paid, note]
	if losses > 0:
		special_ctx["result"] = "danh_thua"
		cv.set_mood(1)
		say.text = "\"Biết điều chưa? Lần sau nhớ đóng tiền đàng hoàng!\""
		info.add_theme_color_override("font_color", DANGER)
	var row: Control = rps["row"]
	var btns: VBoxContainer = rps["btns"]
	row.queue_free()
	btns.add_child(_button("Tiếp tục", _close_popup, PRIMARY))
	rps = {}


## Bàn tay oẳn tù tì vẽ bằng code: "bua" nắm đấm, "keo" hai ngón chữ V, "bao" bàn tay xòe.
class HandIcon extends Control:
	var kind := "":
		set(v):
			kind = v
			queue_redraw()
	var shake := false
	var _t := 0.0

	func _process(delta: float) -> void:
		if shake:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		if kind == "":
			return
		var s: float = minf(size.x, size.y) / 64.0
		var c := size / 2.0 + Vector2(0, 4) * s
		if shake:
			c.y += sin(_t * 22.0) * 6.0 * s
		var skin := Color("f2c9a0")
		var dark := Color("b9845a")
		var line := Color("6b4428")
		# lòng bàn tay
		var palm := Rect2(c + Vector2(-14, -6) * s, Vector2(28, 26) * s)
		var fingers_up: Array = []
		match kind:
			"keo": fingers_up = [0, 1]
			"bao": fingers_up = [0, 1, 2, 3]
		for i in 4:
			var fx := -14.0 + i * 7.0
			if i in fingers_up:
				var top := -30.0 + absf(i - 1.5) * 3.0
				var r := Rect2(c + Vector2(fx, top) * s, Vector2(7, -6.0 - top + 6) * s)
				if kind == "keo":    # hai ngón xòe chữ V
					var ang := -0.28 if i == 0 else 0.28
					var base := c + Vector2(fx + 3.5, -4) * s
					var tip := base + Vector2(sin(ang), -cos(ang)) * 26.0 * s
					draw_line(base, tip, line, 9.0 * s)
					draw_line(base, tip, skin, 6.6 * s)
					draw_circle(tip, 3.3 * s, skin)
					continue
				draw_rect(r.grow(1.2 * s), line)
				draw_rect(r, skin)
				draw_circle(Vector2(r.get_center().x, r.position.y), 3.5 * s, skin)
			else:   # ngón gập: đốt tay tròn
				draw_circle(c + Vector2(fx + 3.5, -6) * s, 4.8 * s, line)
				draw_circle(c + Vector2(fx + 3.5, -6) * s, 3.8 * s, skin)
		draw_rect(palm.grow(1.2 * s), line)
		draw_rect(palm, skin)
		for i in 4:
			if not (i in fingers_up):
				var fx := -14.0 + i * 7.0
				draw_circle(c + Vector2(fx + 3.5, -6) * s, 3.8 * s, skin)
				draw_line(c + Vector2(fx + 1, -2) * s, c + Vector2(fx + 6, -2) * s, dark, 1.2 * s)
		# ngón cái
		var thumb_a := c + Vector2(-14, 6) * s if kind == "bao" else c + Vector2(-12, 7) * s
		var thumb_b := c + Vector2(-24, -6) * s if kind == "bao" else c + Vector2(2, 5) * s
		draw_line(thumb_a, thumb_b, line, 9.0 * s)
		draw_line(thumb_a, thumb_b, skin, 6.6 * s)
		draw_circle(thumb_b, 3.3 * s, skin)
		# cổ tay áo
		draw_rect(Rect2(c + Vector2(-13, 20) * s, Vector2(26, 8) * s), Color("4a78c0"))


# =====================================================================
# Cửa hàng
# =====================================================================

func _open_shop() -> void:
	shop_box = _open_popup("Cửa hàng vật tư", 900, 640)
	var holder := VBoxContainer.new()
	shop_box.add_child(holder)
	var close := _button("Đóng", _close_popup, PRIMARY)
	shop_box.add_child(close)
	shop_box = holder
	shop_sig = ""
	_refresh_shop()
	popup_refresh = _refresh_shop


func _refresh_shop() -> void:
	if shop_box == null or not is_instance_valid(shop_box):
		return
	var sig := "%d|%d|%d|%d|%d|%d|%s|%d|%d|%s|%d" % [gs.coins, gs.garden_level(), gs.pots.size(), gs.seeds.size(), gs.fertilizer, 0, gs.soils_owned.keys(), gs.seed_bags, gs.can_tier, gs.gold_gun, gs.storage_cap]
	if sig == shop_sig:
		return
	shop_sig = sig
	_clear(shop_box)
	var hot: PackedStringArray = []
	for t in gs.hot_traits():
		hot.append(Data.trait_phrase(t["part"], t["id"]))
	var hot_l := _label("Hôm nay khách săn đón: %s. Cây có một trong các đặc điểm này bán được giá gấp đôi." % ", ".join(hot), 19, Color("7a4a12"))
	hot_l.add_theme_stylebox_override("normal", _framed(Color("fff1dc"), Color("e2c48c"), 10, 2))
	shop_box.add_child(hot_l)
	shop_box.add_child(_label("Bạn có %d xu · Trong túi: %d hạt · %d phân bón · %d / %d chậu" % [gs.coins, gs.seeds.size(), gs.fertilizer, gs.pots.size(), Data.MAX_POTS], 19, MUTED))
	var grid := GridContainer.new()
	grid.columns = 2
	shop_box.add_child(grid)
	var icons := {"hat_thuong": "hat", "hat_bi_an": "hat", "phan_bon": "phan", "binh_tuoi": "tu_dong", "chau": "", "dat_tot": "dat_tot", "dat_hiem": "dat_hiem", "tui_hat": "hat",
		"binh_xanh": "nuoc", "binh_vang": "nuoc", "sung_vang": "sung", "mo_kho": "hat"}
	var tiers := {"binh_xanh": 1, "binh_vang": 2, "sung_vang": 2}
	for it in Data.SHOP_ITEMS:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", _framed(PARCH, GOLD, 10, 2))
		grid.add_child(panel)
		var row := HBoxContainer.new()
		panel.add_child(row)
		var ic_box := Control.new()
		ic_box.custom_minimum_size = Vector2(56, 56)
		row.add_child(ic_box)
		if icons.get(it["id"], "") != "":
			var ic := _icon(icons[it["id"]], Vector2(56, 56))
			ic.tier = tiers.get(it["id"], 0)
			ic_box.add_child(ic)
		else:
			var pv := _plant_view(Vector2(56, 56))
			pv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			ic_box.add_child(pv)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(v)
		v.add_child(_label(it["ten"], 21, INK))
		v.add_child(_label(it["mo_ta"], 16, MUTED))
		var price: int = gs.item_price(it["id"])
		var id: String = it["id"]
		var b := _button("%d xu" % price, func():
			if gs.buy(id):
				_status("Đã mua %s." % it["ten"].to_lower()), ACCENT)
		b.custom_minimum_size.x = 120
		if gs.garden_level() < it["cap"]:
			b.disabled = true
			b.text = "Cấp %d" % it["cap"]
		elif id == "tui_hat" and gs.seed_bags >= Data.MAX_SEED_BAGS:
			b.disabled = true
			b.text = "Đủ túi"
		elif (id == "binh_xanh" and gs.can_tier >= 1) or (id == "binh_vang" and gs.can_tier >= 2) or (id == "sung_vang" and gs.gold_gun):
			b.disabled = true
			b.text = "Đã có"
		elif id == "mo_kho" and gs.storage_cap >= Data.STORAGE_MAX:
			b.disabled = true
			b.text = "Tối đa"
		elif id == "chau" and gs.pots.size() >= Data.MAX_POTS:
			b.disabled = true
			b.text = "Đủ chậu"
		elif (id == "dat_tot" and gs.soils_owned.get("tot", false)) or (id == "dat_hiem" and gs.soils_owned.get("hiem", false)):
			b.disabled = true
			b.text = "Đã có"
		elif gs.coins < price or (id == "chau" and gs.pots.size() >= Data.MAX_POTS):
			b.disabled = true
		row.add_child(b)
	# Bán hạt: mở túi hạt để chọn hạt bán
	var sp := PanelContainer.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.add_theme_stylebox_override("panel", _framed(Color("e8f3dc"), GOLD, 10, 2))
	grid.add_child(sp)
	var srow := HBoxContainer.new()
	sp.add_child(srow)
	var sic := Control.new()
	sic.custom_minimum_size = Vector2(56, 56)
	sic.add_child(_icon("hat", Vector2(56, 56)))
	srow.add_child(sic)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 0)
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	srow.add_child(sv)
	sv.add_child(_label("Bán hạt", 21, INK))
	sv.add_child(_label("Thường %d · Hiếm %d · Quý %d · Huyền thoại %d xu" % Data.SEED_SELL_PRICE, 16, MUTED))
	var sb := _button("Túi hạt", _open_sell_seeds, PRIMARY)
	sb.custom_minimum_size.x = 120
	sb.disabled = gs.seeds.is_empty()
	srow.add_child(sb)
	var lv: int = gs.garden_level()
	if lv < Data.LEVEL_REVENUE.size():
		shop_box.add_child(_label("Cấp vườn %d · Doanh thu %d xu. Đạt %d xu để lên cấp %d." % [lv, gs.revenue, Data.LEVEL_REVENUE[lv], lv + 1], 19, MUTED))
	else:
		shop_box.add_child(_label("Cấp vườn %d (cao nhất) · Doanh thu %d xu." % [lv, gs.revenue], 19, MUTED))


# =====================================================================
# Côn trùng đố vui
# =====================================================================

const QUIZ_TITLES := {"buom": "Bướm đố vui", "chuon": "Chuồn chuồn đố vui", "ong": "Ong đố vui"}


func _open_quiz(kind: String, level: int) -> void:
	var qz: Dictionary = Quiz.make(kind, level)
	var box := _open_popup(QUIZ_TITLES.get(kind, "Đố vui"), 820, 500)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	var pic := Insects.Bug.new()
	pic.kind = kind
	pic.level = level
	pic.preview = true
	pic.custom_minimum_size = Vector2(96, 96)
	head.add_child(pic)
	var ql := _label(qz["q"], 28, INK)
	ql.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ql.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(ql)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	var result := _label("Trả lời đúng được 1 xu.", 22, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var buttons: Array = []
	var state := {"done": false}
	for i in qz["options"].size():
		var idx: int = i
		var b := _button(str(qz["options"][i]), func():
			if state["done"]:
				return
			state["done"] = true
			var right: int = qz["answer"]
			buttons[right].modulate = Color(0.65, 1.0, 0.6)
			if idx == right:
				gs.reward_coins(1)
				result.text = "Chính xác! Bạn nhận được 1 xu."
				result.add_theme_color_override("font_color", PRIMARY)
				pic.level = level
			else:
				buttons[idx].modulate = Color(1.0, 0.55, 0.55)
				result.text = "Chưa đúng rồi. Đáp án đúng: %s" % qz["options"][right]
				result.add_theme_color_override("font_color", DANGER)
			var go := _button("Tiếp tục", _close_popup, PRIMARY)
			box.add_child(go))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(360, 60)
		buttons.append(b)
		grid.add_child(b)
	box.add_child(result)


# =====================================================================
# Kho hạt
# =====================================================================

const BAG_PAGE := 16
const STORE_PAGE := 20
var kho_page := {"tui": 0, "kho": 0}


func _open_storage() -> void:
	var box := _open_popup("Kho hạt", 1100, 620, true, false)
	box.add_child(_label("Kéo hạt từ túi sang kho để cất, kéo từ kho về túi để lấy ra. Chạm một hạt cũng chuyển được.", 18, MUTED))
	var holder := HBoxContainer.new()
	holder.add_theme_constant_override("separation", 18)
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(holder)
	box.add_child(_button("Đóng", _close_popup, PRIMARY))
	var refresh := func(): _refresh_storage(holder)
	popup_refresh = refresh
	refresh.call()


func _kind_of(gen: Dictionary) -> Dictionary:
	return {"hoa": Gen.expressed(gen, "hoa"), "hiem": Gen.rarity(gen)}


func _refresh_storage(holder: HBoxContainer) -> void:
	if not is_instance_valid(holder):
		return
	_clear(holder)
	holder.add_child(_storage_side("tui", "Túi hạt", gs.seeds, gs.seed_capacity(), BAG_PAGE, 4, holder))
	holder.add_child(_storage_side("kho", "Kho hạt", gs.storage, gs.storage_cap, STORE_PAGE, 5, holder))


## Một bên của bảng kho: lưới ô hạt có chia trang; ô nhận hạt kéo từ bên kia.
func _storage_side(side: String, title: String, list: Array, cap: int, per_page: int, cols: int, holder: HBoxContainer) -> Control:
	var other := "kho" if side == "tui" else "tui"
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _framed(Color("f6ead2"), Color("c9a46a"), 12, 2))
	var accept := func(data) -> bool:
		return typeof(data) == TYPE_DICTIONARY and data.get("kho_tu", "") == other
	var do_drop := func(data) -> void:
		var ok: bool = gs.store_seed(int(data["idx"])) if side == "kho" else gs.take_seed(int(data["idx"]))
		if ok:
			selected_seed = mini(selected_seed, maxi(0, gs.seeds.size() - 1))
	panel.set_drag_forwarding(Callable(), func(_p, d): return accept.call(d), func(_p, d): do_drop.call(d))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var pages := maxi(1, ceili(float(cap) / per_page))
	kho_page[side] = clampi(kho_page[side], 0, pages - 1)
	var head := HBoxContainer.new()
	v.add_child(head)
	var tl := _label("%s  %d/%d" % [title, list.size(), cap], 22, INK)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	if pages > 1:
		var prev := _button("«", func():
			kho_page[side] = maxi(0, kho_page[side] - 1)
			_refresh_storage.call_deferred(holder))
		prev.custom_minimum_size = Vector2(52, 44)
		prev.disabled = kho_page[side] == 0
		head.add_child(prev)
		var pl := _label("%d/%d" % [kho_page[side] + 1, pages], 18, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		pl.custom_minimum_size.x = 50
		pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		head.add_child(pl)
		var nxt := _button("»", func():
			kho_page[side] = mini(pages - 1, kho_page[side] + 1)
			_refresh_storage.call_deferred(holder))
		nxt.custom_minimum_size = Vector2(52, 44)
		nxt.disabled = kho_page[side] >= pages - 1
		head.add_child(nxt)
	var grid := GridContainer.new()
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)
	var start: int = kho_page[side] * per_page
	for n in per_page:
		var i: int = start + n
		if i >= cap:
			break
		var b := Button.new()
		b.custom_minimum_size = Vector2(80, 80)
		b.focus_mode = Control.FOCUS_NONE
		var st := UiSkin.inset_box(Color("5a3a22"), Vector4(4, 4, 4, 4))
		for k in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(k, st)
		grid.add_child(b)
		if i < list.size():
			var ic := SeedBag.SeedPreview.new()
			ic.kind = _kind_of(list[i]["gen"])
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			b.add_child(ic)
			var idx := i
			b.pressed.connect(func():   # chạm: chuyển sang bên kia
				if side == "tui":
					gs.store_seed(idx)
				else:
					gs.take_seed(idx)
				selected_seed = mini(selected_seed, maxi(0, gs.seeds.size() - 1)))
			b.set_drag_forwarding(func(_pos):
					var pv := SeedBag.SeedPreview.new()
					pv.kind = _kind_of(list[idx]["gen"])
					pv.size = Vector2(72, 72)
					pv.position = Vector2(-36, -36)
					var hold := Control.new()
					hold.add_child(pv)
					b.set_drag_preview(hold)
					return {"kho_tu": side, "idx": idx},
				func(_p, d): return accept.call(d),
				func(_p, d): do_drop.call(d))
		else:
			b.set_drag_forwarding(Callable(), func(_p, d): return accept.call(d), func(_p, d): do_drop.call(d))
	return panel


# =====================================================================
# Bán hạt
# =====================================================================

var sell_pick := -1


func _open_sell_seeds() -> void:
	sell_pick = -1
	var box := _open_popup("Bán hạt", 900, 640)
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", 10)
	box.add_child(holder)
	var back := _button("Quay lại Vật tư", _open_shop)
	box.add_child(back)
	var refresh := func(): _refresh_sell_seeds(holder)
	popup_refresh = refresh
	refresh.call()


func _seed_kind(idx: int) -> Dictionary:
	var g: Dictionary = gs.seeds[idx]["gen"]
	return {"hoa": Gen.expressed(g, "hoa"), "hiem": Gen.rarity(g)}


func _refresh_sell_seeds(holder: VBoxContainer) -> void:
	if not is_instance_valid(holder):
		return
	_clear(holder)
	if sell_pick >= gs.seeds.size():
		sell_pick = -1
	holder.add_child(_label("Bạn có %d xu · Túi hạt %d/%d. Chạm vào một hạt để chọn." % [gs.coins, gs.seeds.size(), gs.seed_capacity()], 19, MUTED))
	if gs.seeds.is_empty():
		holder.add_child(_label("Túi hạt đang trống.", 22, INK))
		return
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	holder.add_child(grid)
	for i in gs.seeds.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(88, 88)
		b.focus_mode = Control.FOCUS_NONE
		var picked: bool = i == sell_pick
		var st := UiSkin.inset_box(Color("f6d98a") if picked else Color("5a3a22"), Vector4(4, 4, 4, 4))
		for k in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(k, st)
		var idx: int = i
		b.pressed.connect(func():
			sell_pick = idx
			_refresh_sell_seeds(holder))
		var ic := SeedBag.SeedPreview.new()
		ic.kind = _seed_kind(i)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		b.add_child(ic)
		var pl := Label.new()
		pl.text = "%d" % gs.seed_sell_price(i)
		pl.add_theme_font_size_override("font_size", 15)
		pl.add_theme_color_override("font_color", Color("ffe08a"))
		pl.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0, 1))
		pl.add_theme_constant_override("outline_size", 4)
		pl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		pl.offset_left = -40
		pl.offset_top = -24
		pl.offset_right = -6
		pl.offset_bottom = -2
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(pl)
		grid.add_child(b)
	# hạt đang chọn: hỏi bán hay không
	if sell_pick >= 0:
		var k := _seed_kind(sell_pick)
		var parents: Array = gs.seeds[sell_pick].get("bo_me", [])
		var from := "mua ở cửa hàng"
		if parents.size() == 2:
			var a := Gen.variety_name_of_pheno(Gen.phenotype_from_key(parents[0]))
			var c := Gen.variety_name_of_pheno(Gen.phenotype_from_key(parents[1]))
			from = "thu từ %s" % a if parents[0] == parents[1] else "lai %s × %s" % [a, c]
		var price: int = gs.seed_sell_price(sell_pick)
		var pane := PanelContainer.new()
		pane.add_theme_stylebox_override("panel", _framed(Color("fff1dc"), Color("e2c48c"), 10, 2))
		holder.add_child(pane)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		pane.add_child(row)
		var info := _label("Hạt %s · %s (%s)\nBán hạt này được %d xu?" % [
			Data.trait_name("hoa", k["hoa"]).to_lower(), Data.RARITY_NAMES[k["hiem"]], from, price], 21, INK)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var no := _button("Không", func():
			sell_pick = -1
			_refresh_sell_seeds(holder))
		no.custom_minimum_size.x = 130
		row.add_child(no)
		var yes := _button("Bán %d xu" % price, func():
			var idx2 := sell_pick
			sell_pick = -1
			if idx2 == selected_seed:
				selected_seed = 0
			gs.sell_seed(idx2), ACCENT)
		yes.custom_minimum_size.x = 150
		row.add_child(yes)


# =====================================================================
# Shop cây: đổi tên bảng hiệu và cửa hàng trang trí
# =====================================================================

func _open_rename() -> void:
	var box := _open_popup("Đổi tên bảng hiệu", 640, 330)
	box.add_child(_label("Tên mới cho bảng hiệu ở cổng Shop cây (tối đa %d ký tự):" % Data.SHOP_NAME_MAX, 19, MUTED))
	var edit := LineEdit.new()
	edit.text = gs.shop_name
	edit.max_length = Data.SHOP_NAME_MAX
	edit.custom_minimum_size.y = 54
	edit.add_theme_font_size_override("font_size", 24)
	edit.add_theme_stylebox_override("normal", UiSkin.inset_box(Color("fffaf0"), Vector4(14, 6, 14, 6)))
	edit.add_theme_stylebox_override("focus", UiSkin.inset_box(Color("fffaf0"), Vector4(14, 6, 14, 6)))
	edit.add_theme_color_override("font_color", INK)
	edit.select_all_on_focus = true
	box.add_child(edit)
	var row := HBoxContainer.new()
	box.add_child(row)
	var cancel := _button("Hủy", _close_popup)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cancel)
	var save := func():
		gs.set_shop_name(edit.text)
		_close_popup()
		nursery.refresh()
		nursery.set_status("Bảng hiệu mới: %s" % gs.shop_name)
	var ok := _button("Lưu tên", save, PRIMARY)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ok)
	edit.text_submitted.connect(func(_t): save.call())
	edit.grab_focus.call_deferred()


func _decor_preview(kind: String, tier: int, sz: Vector2) -> Control:
	var pv := Control.new()
	pv.set_script(DecorPreview)
	pv.kind = kind
	pv.tier = tier
	pv.custom_minimum_size = sz
	return pv


var decor_box: VBoxContainer
var decor_sig := ""


func _open_decor_shop() -> void:
	decor_box = _open_popup("Trang trí shop", 1000, 650)
	var holder := VBoxContainer.new()
	decor_box.add_child(holder)
	decor_box.add_child(_button("Đóng", _close_popup, PRIMARY))
	decor_box = holder
	decor_sig = ""
	_refresh_decor_shop()
	popup_refresh = _refresh_decor_shop


func _refresh_decor_shop() -> void:
	if decor_box == null or not is_instance_valid(decor_box):
		return
	var sig := "%d|%s|%s" % [gs.coins, gs.shop_upgrades, gs.decor_owned.keys()]
	if sig == decor_sig:
		return
	decor_sig = sig
	_clear(decor_box)
	var ap: int = gs.appeal()
	var faster := int(round((1.0 - maxf(0.5, 1.0 - Data.APPEAL_SPAWN * ap)) * 100))
	var easier := int(round(minf(Data.APPEAL_BUY_MAX, Data.APPEAL_BUY * ap) * 100))
	var info := _label("Bạn có %d xu · Sức hút shop: %d điểm (khách tới nhanh hơn %d%%, dễ mua hơn %d%%)" % [gs.coins, ap, faster, easier], 19, Color("7a4a12"))
	info.add_theme_stylebox_override("normal", _framed(Color("fff1dc"), Color("e2c48c"), 10, 2))
	decor_box.add_child(info)

	decor_box.add_child(_label("Nâng cấp", 24, Color("7a4a1a")))
	for kind in Data.UPGRADE_ORDER:
		var spec: Dictionary = Data.SHOP_UPGRADES[kind]
		var tiers: Array = spec["bac"]
		var cur: int = gs.upgrade_tier(kind)
		var nxt := mini(cur + 1, tiers.size() - 1)
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _framed(PARCH, GOLD, 10, 2))
		decor_box.add_child(panel)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		panel.add_child(row)
		row.add_child(_decor_preview(kind, nxt, Vector2(200, 100)))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(v)
		v.add_child(_label("%s (bậc %d/%d)" % [spec["ten"], cur, tiers.size() - 1], 22, INK))
		v.add_child(_label("Hiện tại: %s" % tiers[cur]["ten"], 17, MUTED))
		var price: int = gs.upgrade_next_price(kind)
		if price >= 0:
			v.add_child(_label("Nâng lên: %s" % tiers[cur + 1]["ten"], 17, Color("2f6a3c")))
		var b := _button("%d xu" % price if price >= 0 else "Tối đa", func():
			if gs.buy_upgrade(kind):
				nursery.refresh(), ACCENT)
		b.custom_minimum_size = Vector2(150, 56)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.disabled = price < 0 or gs.coins < price
		row.add_child(b)

	decor_box.add_child(_label("Đồ trang trí", 24, Color("7a4a1a")))
	var grid := GridContainer.new()
	grid.columns = 2
	decor_box.add_child(grid)
	for d in Data.SHOP_DECOR:
		var id: String = d["id"]
		var owned: bool = gs.decor_owned.get(id, false)
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel", _framed(PARCH, GOLD, 10, 2))
		grid.add_child(panel)
		var row := HBoxContainer.new()
		panel.add_child(row)
		row.add_child(_decor_preview(id, 0, Vector2(96, 96)))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(v)
		v.add_child(_label(d["ten"], 20, INK))
		v.add_child(_label(d["mo_ta"], 16, MUTED))
		var b := _button("Đã có" if owned else "%d xu" % d["gia"], func():
			if gs.buy_decor(id):
				nursery.refresh(), ACCENT)
		b.custom_minimum_size = Vector2(118, 52)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.disabled = owned or gs.coins < int(d["gia"])
		row.add_child(b)


# =====================================================================
# Sổ tay
# =====================================================================

func _open_book() -> void:
	book_box = _open_popup("Sổ tay giống cây", 1100, 640)
	var holder := VBoxContainer.new()
	book_box.add_child(holder)
	book_box.add_child(_button("Đóng", _close_popup, PRIMARY))
	book_box = holder
	book_sig = ""
	_refresh_book()
	popup_refresh = _refresh_book


func _refresh_book() -> void:
	if book_box == null or not is_instance_valid(book_box):
		return
	var sig := "%d" % gs.collection.size()
	if sig == book_sig:
		return
	book_sig = sig
	_clear(book_box)
	var total := 1
	for part in Data.PARTS:
		total *= Data.TRAITS[part].size()
	book_box.add_child(_label("Đã tìm ra %d / %d giống. Mỗi %d giống mới được thưởng %d xu và một gói hạt bí ẩn." % [gs.collection.size(), total, Data.COLLECTION_MILESTONE, Data.MILESTONE_COINS], 19, MUTED))

	var seen := {}
	for part in Data.PARTS:
		seen[part] = {}
	for key in gs.collection.keys():
		var ph := Gen.phenotype_from_key(key)
		for part in Data.PARTS:
			seen[part][ph[part]] = true
	var parts_panel := PanelContainer.new()
	parts_panel.add_theme_stylebox_override("panel", _framed(PARCH, GOLD, 10, 2))
	book_box.add_child(parts_panel)
	var pv_box := VBoxContainer.new()
	pv_box.add_theme_constant_override("separation", 4)
	parts_panel.add_child(pv_box)
	for part in Data.PARTS:
		var names: PackedStringArray = []
		for id in Data.TRAITS[part].keys():
			names.append(Data.trait_name(part, id) if seen[part].has(id) else "???")
		pv_box.add_child(_label("%s (%d/%d): %s" % [Data.PART_NAMES[part], seen[part].size(), Data.TRAITS[part].size(), ", ".join(names)], 18, INK))
	var hints: PackedStringArray = []
	for part in Data.PARTS:
		for id in Data.TRAITS[part].keys():
			if Data.TRAITS[part][id]["hiem"] >= 3 and not seen[part].has(id):
				hints.append(Data.LEGEND_HINTS.get(id, "Kiểu huyền thoại chưa tìm ra"))
	if not hints.is_empty():
		pv_box.add_child(_label("Gợi ý huyền thoại: " + " · ".join(hints), 17, Color("a06a10")))

	var keys: Array = gs.collection.keys()
	keys.sort_custom(func(a, b): return Gen.rarity_of_pheno(Gen.phenotype_from_key(a)) > Gen.rarity_of_pheno(Gen.phenotype_from_key(b)))
	if keys.is_empty():
		book_box.add_child(_label("Chưa có giống nào. Cây sẽ được ghi vào sổ khi ra hoa lần đầu.", 20, MUTED))
		return
	var grid := GridContainer.new()
	grid.columns = 6
	book_box.add_child(grid)
	for key in keys:
		var ph := Gen.phenotype_from_key(key)
		var r := Gen.rarity_of_pheno(ph)
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sb := _box(Color.WHITE, 12)
		sb.border_color = Data.RARITY_COLORS[r]
		sb.set_border_width_all(3)
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		panel.add_theme_stylebox_override("panel", sb)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		panel.add_child(v)
		var pv := _plant_view(Vector2(0, 170))
		pv.set_pheno(ph, 3)
		v.add_child(pv)
		v.add_child(_label(Gen.variety_name_of_pheno(ph), 15, INK, HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(_label(Data.RARITY_NAMES[r], 14, Data.RARITY_COLORS[r].darkened(0.2), HORIZONTAL_ALIGNMENT_CENTER))
		grid.add_child(panel)
