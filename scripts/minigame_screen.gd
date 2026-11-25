extends Control
## Khung chung cho các mini game mở từ ô cửa sổ nhà kính (Ghép hoa, Cờ caro, TOEIC 600):
## nền, thanh trên có nút Về vườn và tiêu đề, dòng thông báo nổi, bảng thông báo ở giữa.
## Game con ghi đè _build_game() và _on_open().

signal back_pressed
signal garden_changed

const Data := preload("res://scripts/data.gd")
const Gen := preload("res://scripts/genetics.gd")
const UiSkin := preload("res://scripts/ui_skin.gd")
const FONT_BOLD := preload("res://fonts/Lora-700.ttf")
const FONT_MEDIUM := preload("res://fonts/Lora-500.ttf")
const TOP_H := 74.0
const GOLD := Color("d9b26a")
const INK := Color("3a2614")

var gs: Node
var paused_check: Callable
var title_text := ""
var title_l: Label
var info_l: Label
var top_row: HBoxContainer
var content: Control
var toast_l: Label
var toast_t := 0.0
var modal: Control

static var _tex := {}


func _ready() -> void:
	gs = get_node("/root/GameState")
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := TextureRect.new()
	bg.texture = _bg_texture()
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", UiSkin.bevel_box(Color("5e3b22"), GOLD, 0, "normal", Vector4(10, 6, 10, 6)))
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = TOP_H
	add_child(top)
	top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 16)
	top.add_child(top_row)
	var back := button("Về vườn", func(): _go_back(), Color("4a5866"))
	back.custom_minimum_size = Vector2(150, 52)
	top_row.add_child(back)
	title_l = Label.new()
	title_l.text = title_text
	title_l.add_theme_font_override("font", FONT_BOLD)
	title_l.add_theme_font_size_override("font_size", 26)
	title_l.add_theme_color_override("font_color", Color("fff1cf"))
	title_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(title_l)
	info_l = Label.new()
	info_l.add_theme_font_override("font", FONT_BOLD)
	info_l.add_theme_font_size_override("font_size", 21)
	info_l.add_theme_color_override("font_color", Color("ffe08a"))
	info_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(info_l)

	content = Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_top = TOP_H
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(content)

	toast_l = Label.new()
	toast_l.add_theme_font_override("font", FONT_BOLD)
	toast_l.add_theme_font_size_override("font_size", 24)
	toast_l.add_theme_color_override("font_color", Color("fff6d8"))
	toast_l.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0, 0.9))
	toast_l.add_theme_constant_override("outline_size", 7)
	toast_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_l.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	toast_l.offset_top = TOP_H + 8
	toast_l.offset_bottom = TOP_H + 48
	toast_l.z_index = 60
	add_child(toast_l)

	_build_game()


## Nền giấy kem có viền hoa lá nhạt (vẽ một lần).
static func _bg_texture() -> Texture2D:
	if _tex.has("_bg"):
		return _tex["_bg"]
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var k := float(y) / 63.0
			var c := Color("dff0c8").lerp(Color("b9dc9a"), k)
			if (x / 8 + y / 8) % 2 == 0:
				c = c.lightened(0.04)
			img.set_pixel(x, y, c)
	var t := ImageTexture.create_from_image(img)
	_tex["_bg"] = t
	return t


static func tex(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]


func _build_game() -> void:
	pass


func _on_open() -> void:
	pass


func open() -> void:
	visible = true
	_on_open()


func _go_back() -> void:
	close_modal()
	back_pressed.emit()


func _process(delta: float) -> void:
	if toast_t > 0.0:
		toast_t -= delta
		toast_l.modulate.a = clampf(toast_t / 0.4, 0.0, 1.0)


func is_paused() -> bool:
	return not visible or (paused_check.is_valid() and paused_check.call()) or (modal != null and modal.visible)


func toast(text: String, dur := 2.6) -> void:
	toast_l.text = text
	toast_t = dur
	toast_l.modulate.a = 1.0


func label(text: String, fs := 20, col := INK, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT_BOLD if fs >= 18 else FONT_MEDIUM)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func button(text: String, cb: Callable, col := Color("3e7d4a")) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 20)
	UiSkin.style_button(b, col, UiSkin.SILVER if col.s < 0.35 else GOLD)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


## Bảng thông báo giữa màn hình. buttons: [[chữ, Callable, màu], ...]
func show_modal(title: String, body: String, buttons: Array) -> void:
	close_modal()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.z_index = 90
	add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.panel_box(Color("fffaf0"), Color("7a4a24"), 26.0))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	var t := label(title, 30, Color("7a3a14"), HORIZONTAL_ALIGNMENT_CENTER)
	t.custom_minimum_size.x = 560
	v.add_child(t)
	var b := label(body, 21, Color("2b3a2e"), HORIZONTAL_ALIGNMENT_CENTER)
	b.custom_minimum_size.x = 560
	v.add_child(b)
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	for spec in buttons:
		var cb: Callable = spec[1]
		var btn := button(spec[0], func(): close_modal(); cb.call(), spec[2] if spec.size() > 2 else Color("3e7d4a"))
		btn.custom_minimum_size = Vector2(190, 56)
		h.add_child(btn)


func close_modal() -> void:
	if modal != null:
		modal.queue_free()
		modal = null


## Lưu một mục tiến trình mini game vào GameState.
func save_state(key: String, d: Dictionary) -> void:
	gs.minigames[key] = d
	gs.save_game()


func load_state(key: String) -> Dictionary:
	var d = gs.minigames.get(key, {})
	return d if typeof(d) == TYPE_DICTIONARY else {}


## Tặng hạt giống có độ hiếm cho trước; trả về câu mô tả.
func reward_seed(rarity: int, new_only := false, avoid: Array = []) -> String:
	var gen: Dictionary = gs.make_seed(rarity, new_only, avoid)
	var where: String = gs.give_seed(gen)
	garden_changed.emit()
	return "1 hạt %s (%s) – %s" % [Data.RARITY_NAMES[Gen.rarity(gen)], Gen.variety_name(gen), where]
