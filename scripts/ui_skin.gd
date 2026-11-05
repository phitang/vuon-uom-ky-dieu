extends RefCounted
## "Da" giao diện nổi khối: nút vát cạnh có viền kim loại, ô lõm, khung giấy da
## viền gỗ, nền gỗ có vân. Hình được sinh bằng code lúc chạy và lưu đệm lại.

static var _cache := {}

const GOLD := Color("d9b26a")
const SILVER := Color("b9c3cc")


## Khoảng cách có dấu tới hình chữ nhật bo góc (âm = bên trong).
static func _sd_round_rect(p: Vector2, size: Vector2, r: float) -> float:
	var c := size / 2.0
	var q := (p - c).abs() - (c - Vector2(r, r))
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r


static func _tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


## Nút nổi: viền ngoài tối, vành kim loại sáng dần lên trên, rãnh, mặt bóng chuyển màu.
static func bevel_texture(base: Color, rim: Color, radius := 10, state := "normal") -> ImageTexture:
	var key := "bevel|%s|%s|%d|%s" % [base.to_html(), rim.to_html(), radius, state]
	if _cache.has(key):
		return _cache[key]
	var w := maxi(48, radius * 2 + 16)
	var h := w
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var face := base
	if state == "hover":
		face = base.lightened(0.12)
	elif state == "pressed":
		face = base.darkened(0.18)
	elif state == "disabled":
		face = base.lerp(Color(0.55, 0.55, 0.55), 0.7)
		rim = rim.lerp(Color(0.7, 0.7, 0.7), 0.6)
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := -_sd_round_rect(p, Vector2(w, h), radius)
			if d <= -0.5:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var t := float(y) / h
			var col: Color
			if d < 1.3:
				col = rim.darkened(0.62)
			elif d < 4.3:
				# vành kim loại: sáng ở trên, tối ở dưới, có một vệt sáng
				col = rim.lightened(0.35 * (1.0 - t)).darkened(0.35 * t)
				if absf(d - 2.3) < 0.6:
					col = col.lightened(0.25 * (1.0 - t))
			elif d < 5.4:
				col = face.darkened(0.5)
			else:
				var tt := 1.0 - t if state == "pressed" else t
				col = face.lightened(0.30 * (1.0 - tt)).darkened(0.24 * tt)
				# vệt bóng phía trên
				if state != "pressed" and t < 0.46:
					col = col.lerp(Color.WHITE, 0.16 * (1.0 - t / 0.46))
				# bóng trong ở mép dưới
				if d < 8.0 and t > 0.6:
					col = col.darkened(0.12 * (8.0 - d) / 3.0)
			col.a = clampf(d + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, col)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func bevel_box(base: Color, rim := GOLD, radius := 10, state := "normal", pad := Vector4(14, 8, 14, 8)) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = bevel_texture(base, rim, radius, state)
	var m := float(radius + 6)
	sb.texture_margin_left = m
	sb.texture_margin_right = m
	sb.texture_margin_top = m
	sb.texture_margin_bottom = m
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	return sb


## Bộ 4 trạng thái cho một nút.
static func style_button(b: Button, base: Color, rim := GOLD, radius := 10) -> void:
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, bevel_box(base, rim, radius, st))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	b.add_theme_constant_override("outline_size", 4)


## Ô lõm: bóng tối ở trên-trái, viền sáng ở dưới-phải.
static func inset_texture(base: Color, radius := 7) -> ImageTexture:
	var key := "inset|%s|%d" % [base.to_html(), radius]
	if _cache.has(key):
		return _cache[key]
	var w := 32
	var img := Image.create(w, w, false, Image.FORMAT_RGBA8)
	for y in w:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := -_sd_round_rect(p, Vector2(w, w), radius)
			if d <= -0.5:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var t := float(y) / w
			var col := base.darkened(0.18 * (1.0 - t))
			if d < 1.2:
				# viền ngoài: tối ở trên-trái, sáng ở dưới-phải
				col = Color(1, 1, 1, 0.35) if (x + y) > w else Color(0, 0, 0, 0.6)
				col = base.lerp(col, col.a)
				col.a = 1.0
			elif d < 5.0:
				var shadow := clampf((5.0 - d) / 4.0, 0, 1) * (0.55 if y < w / 2 or x < w / 2 else 0.2)
				col = col.darkened(shadow)
			col.a = clampf(d + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, col)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func inset_box(base: Color, pad := Vector4(10, 6, 10, 6)) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = inset_texture(base)
	for side in ["left", "right", "top", "bottom"]:
		sb.set("texture_margin_" + side, 10.0)
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	return sb


## Khung giấy da viền gỗ chạm, có chỉ vàng bên trong.
static func panel_texture(face := Color("f3e3c0"), frame := Color("7a4a24")) -> ImageTexture:
	var key := "panel|%s|%s" % [face.to_html(), frame.to_html()]
	if _cache.has(key):
		return _cache[key]
	var w := 64
	var noise := FastNoiseLite.new()
	noise.seed = 11
	noise.frequency = 0.12
	var img := Image.create(w, w, false, Image.FORMAT_RGBA8)
	for y in w:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := -_sd_round_rect(p, Vector2(w, w), 12)
			if d <= -0.5:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var col: Color
			if d < 1.2:
				col = frame.darkened(0.6)
			elif d < 7.0:
				# gỗ vát: sáng trên-trái, tối dưới-phải
				# cạnh trên và trái sáng, cạnh dưới và phải tối
				var top_left := (x + y) < w
				col = frame.lightened(0.24) if top_left else frame.darkened(0.25)
				if absf(d - 3.0) < 0.7:
					col = col.lightened(0.12)
			elif d < 8.2:
				col = GOLD
			elif d < 9.2:
				col = face.darkened(0.25)
			else:
				var n := noise.get_noise_2d(x, y) * 0.04
				col = face.darkened(maxf(0.0, (11.0 - d)) * 0.03).lightened(n)
			col.a = clampf(d + 0.5, 0.0, 1.0)
			img.set_pixel(x, y, col)
	var tex := _tex(img)
	_cache[key] = tex
	return tex


static func panel_box(face := Color("f3e3c0"), frame := Color("7a4a24"), pad := 18.0) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = panel_texture(face, frame)
	for side in ["left", "right", "top", "bottom"]:
		sb.set("texture_margin_" + side, 16.0)
		sb.set("content_margin_" + side, pad)
	return sb


## Nền gỗ có vân (lặp được).
static func wood_texture(base := Color("5e3b22")) -> ImageTexture:
	var key := "wood|%s" % base.to_html()
	if _cache.has(key):
		return _cache[key]
	var noise := FastNoiseLite.new()
	noise.seed = 3
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.03
	var w := 128
	var h := 256
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			# vân gỗ chạy dọc: méo theo nhiễu
			var n := noise.get_noise_2d(x * 3.0, y * 0.25)
			var ring := sin((x + n * 30.0) * 0.35) * 0.5 + 0.5
			var col := base.lightened(0.10 * ring).darkened(0.10 * (1.0 - ring))
			col = col.darkened(absf(noise.get_noise_2d(x * 9.0, y * 2.0)) * 0.12)
			if x % 64 == 0:
				col = base.darkened(0.45)   # khe giữa hai tấm ván
			img.set_pixel(x, y, col)
	var tex := _tex(img)
	_cache[key] = tex
	return tex
