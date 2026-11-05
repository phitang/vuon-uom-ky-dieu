extends RefCounted
## Hệ di truyền: mỗi bộ phận có một cặp gen [gen1, gen2].
## Cây hiển thị kiểu có mức trội cao hơn; gen lặn vẫn truyền cho đời sau.

const Data := preload("res://scripts/data.gd")


## Kiểu hiển thị của một bộ phận.
static func expressed(gen: Dictionary, part: String) -> String:
	var pair: Array = gen[part]
	var a: String = pair[0]
	var b: String = pair[1]
	var ta: int = Data.TRAITS[part][a]["troi"]
	var tb: int = Data.TRAITS[part][b]["troi"]
	if ta > tb:
		return a
	if tb > ta:
		return b
	return a if a <= b else b  # bằng nhau: chọn cố định để kết quả luôn giống nhau


## Kiểu hiển thị của cả cây: {"hoa": "sao", "la": "kim", ...}
static func phenotype(gen: Dictionary) -> Dictionary:
	var p := {}
	for part in Data.PARTS:
		p[part] = expressed(gen, part)
	return p


## Mã giống, ví dụ "sao-kim-xoan-tim-vua". Dùng cho Sổ tay.
static func variety_key(gen: Dictionary) -> String:
	var p := phenotype(gen)
	var bits: PackedStringArray = []
	for part in Data.PARTS:
		bits.append(p[part])
	return "-".join(bits)


static func phenotype_from_key(key: String) -> Dictionary:
	var bits := key.split("-")
	var p := {}
	for i in Data.PARTS.size():
		p[Data.PARTS[i]] = bits[i]
	return p


## Độ hiếm 0..3 từ kiểu hiển thị.
static func rarity_of_pheno(p: Dictionary) -> int:
	var score := 0
	for part in Data.PARTS:
		var h: int = Data.TRAITS[part][p[part]]["hiem"]
		if h >= 3:
			return 3
		score += h
	if score >= 4:
		return 2
	if score >= 2:
		return 1
	return 0


static func rarity(gen: Dictionary) -> int:
	return rarity_of_pheno(phenotype(gen))


## Tên giống tự sinh, ví dụ "Sao Tím Xoắn".
static func variety_name_of_pheno(p: Dictionary) -> String:
	var name := "%s %s" % [Data.trait_name("hoa", p["hoa"]), Data.trait_name("mau", p["mau"])]
	if Data.TRAITS["than"][p["than"]]["hiem"] > 0:
		name += " " + Data.trait_name("than", p["than"])
	if Data.TRAITS["la"][p["la"]]["hiem"] > 0:
		name += " lá " + Data.trait_name("la", p["la"]).to_lower()
	if p["co"] == "lon":
		name += " Đại"
	elif p["co"] == "nho":
		name += " Tí hon"
	return name


static func variety_name(gen: Dictionary) -> String:
	return variety_name_of_pheno(phenotype(gen))


## Hạt ngẫu nhiên. max_hiem: kiểu hiếm nhất có thể có (0 = chỉ Thường).
static func random_genome(max_hiem: int) -> Dictionary:
	var gen := {}
	for part in Data.PARTS:
		var pool: Array = []
		for id in Data.TRAITS[part].keys():
			var h: int = Data.TRAITS[part][id]["hiem"]
			if h <= max_hiem and h < 3:
				# kiểu càng hiếm càng ít xuất hiện
				for i in (4 - h) * (4 - h):
					pool.append(id)
		gen[part] = [pool.pick_random(), pool.pick_random()]
	return gen


## Lai hai cây, trả về một hạt (bộ gen mới). Gen bố mẹ truyền lại theo Mendel nên bố mẹ
## mang kiểu hiếm thì con dễ ra hiếm; ngoài ra có mutation_chance khả năng đột biến.
static func cross(gen_a: Dictionary, gen_b: Dictionary, mutation_chance: float) -> Dictionary:
	var child := {}
	# mỗi hạt có mutation_chance khả năng đột biến ở đúng một bộ phận
	var mutate_part: String = Data.PARTS.pick_random() if randf() < mutation_chance else ""
	for part in Data.PARTS:
		var pa: Array = gen_a[part]
		var pb: Array = gen_b[part]
		var pair := [pa.pick_random(), pb.pick_random()]
		if part == mutate_part:
			var rare: Array = []
			for id in Data.TRAITS[part].keys():
				if Data.TRAITS[part][id]["hiem"] >= 2:
					rare.append(id)
			if rare.is_empty():  # bộ phận không có kiểu quý (ví dụ Kích thước)
				for id in Data.TRAITS[part].keys():
					if Data.TRAITS[part][id]["hiem"] >= 1:
						rare.append(id)
			var m: String = rare.pick_random()
			if Data.TRAITS[part][m]["hiem"] >= 3:
				pair = [m, m]  # đột biến huyền thoại hiện ra ngay
			else:
				pair[randi() % 2] = m
		child[part] = pair
	return child


## Số đặc điểm của cây khớp với yêu cầu của khách.
## wish là mảng [{"part": "mau", "id": "tim"}, ...]
static func count_matches(gen: Dictionary, wish: Array) -> int:
	var p := phenotype(gen)
	var n := 0
	for w in wish:
		if p[w["part"]] == w["id"]:
			n += 1
	return n
