extends Node
## Trạng thái game (tiền, chậu cây, túi đồ, sổ tay) và toàn bộ luật chơi.
## Được nạp tự động (autoload) với tên GameState, mọi màn hình đều gọi vào đây.

const Data := preload("res://scripts/data.gd")
const Gen := preload("res://scripts/genetics.gd")

signal changed            # có gì đó thay đổi, giao diện cần vẽ lại
signal message(text: String)

const SAVE_PATH := "user://save.json"

## Tăng số này để thử game nhanh (ví dụ 60 = 1 phút thật bằng 1 giờ trong game).
## Nhớ đặt lại 1.0 trước khi phát hành.
@export var time_scale := 1.0

var coins := 0
var revenue := 0          # tổng doanh thu, quyết định cấp vườn
var pots: Array = []      # mỗi chậu: {} nếu trống, hoặc một cây
var soils: Array = []     # đất của từng chậu: "thuong", "tot", "hiem" hoặc "" (chưa có đất)
var soils_owned := {"thuong": true}   # loại đất đã mở khóa (dùng mãi)
var seeds: Array = []     # túi hạt: mỗi hạt là {"gen": ..., "bo_me": [...]}
var seed_bags := 1        # số túi hạt (mỗi túi 8 ô)
var shop_name := ""       # tên trên bảng hiệu Shop cây
var shop_upgrades := {}   # "bang_hieu"/"quay"/"hang_rao" -> bậc đã mua
var decor_owned := {}     # mã đồ trang trí -> true
var hidden_met := {}      # khách ẩn đã gặp: "quy", "huyen_thoai" -> true
var fertilizer := 0
var auto_waterers := 0
var pots_bought := 0
var collection := {}      # mã giống -> {"ngay": ..., "bo_me": [...]}
var milestones_paid := 0
var sold_today := {}      # mã giống -> số cây đã bán hôm nay
var day_key := ""
var last_time := 0.0
var away_report := ""     # tóm tắt "trong lúc bạn vắng mặt"

var _save_timer := 0.0


func _ready() -> void:
	if not load_game():
		new_game()
	_catch_up_offline()


func _process(delta: float) -> void:
	var now := _now()
	var dt := now - last_time
	if dt >= 1.0:
		_advance(dt)
		last_time = now
		changed.emit()
	_save_timer += delta
	if _save_timer > 10.0:
		_save_timer = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_game()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		_catch_up_offline()
		changed.emit()


func _now() -> float:
	return Time.get_unix_time_from_system()


# ================== Khởi tạo và lưu game ==================

func new_game() -> void:
	coins = Data.START_COINS
	revenue = 0
	pots = []
	soils = []
	for i in Data.START_POTS:
		pots.append({})
		soils.append("thuong")
	soils_owned = {"thuong": true}
	seeds = []
	seed_bags = 1
	shop_name = Data.DEFAULT_SHOP_NAME
	shop_upgrades = {}
	decor_owned = {}
	hidden_met = {}
	for i in 2:
		seeds.append({"gen": Gen.random_genome(0), "bo_me": []})
	fertilizer = 1
	auto_waterers = 0
	pots_bought = 0
	collection = {}
	milestones_paid = 0
	sold_today = {}
	day_key = _today()
	last_time = _now()
	save_game()


func save_game() -> void:
	var data := {
		"phien_ban": 2,
		"dat_chau": soils,
		"dat_da_mua": soils_owned.keys(),
		"xu": coins,
		"doanh_thu": revenue,
		"chau": pots,
		"hat": seeds,
		"tui_hat": seed_bags,
		"ten_shop": shop_name,
		"nang_cap_shop": shop_upgrades,
		"trang_tri": decor_owned.keys(),
		"khach_an": hidden_met.keys(),
		"phan_bon": fertilizer,
		"binh_tuoi": auto_waterers,
		"chau_da_mua": pots_bought,
		"so_tay": collection,
		"moc_da_thuong": milestones_paid,
		"ban_hom_nay": sold_today,
		"ngay": day_key,
		"lan_cuoi": last_time,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	coins = int(data.get("xu", Data.START_COINS))
	revenue = int(data.get("doanh_thu", 0))
	pots = data.get("chau", [])
	seeds = data.get("hat", [])
	fertilizer = int(data.get("phan_bon", 0))
	auto_waterers = int(data.get("binh_tuoi", 0))
	pots_bought = int(data.get("chau_da_mua", 0))
	collection = data.get("so_tay", {})
	milestones_paid = int(data.get("moc_da_thuong", 0))
	sold_today = data.get("ban_hom_nay", {})
	day_key = str(data.get("ngay", _today()))
	last_time = float(data.get("lan_cuoi", _now()))
	if pots.is_empty():
		for i in Data.START_POTS:
			pots.append({})
	# đất: file lưu cũ chưa có đất thì cho mọi chậu đất thường
	var saved_soils = data.get("dat_chau", null)
	soils = []
	for i in pots.size():
		var t := "thuong"
		if typeof(saved_soils) == TYPE_ARRAY:
			t = str(saved_soils[i]) if i < saved_soils.size() else ""
		soils.append(t if (t == "" or Data.SOILS.has(t)) else "thuong")
	soils_owned = {"thuong": true}
	for t in data.get("dat_da_mua", []):
		if Data.SOILS.has(str(t)):
			soils_owned[str(t)] = true
	# bỏ các chậu hoặc hạt bị hỏng dữ liệu
	for i in pots.size():
		if typeof(pots[i]) != TYPE_DICTIONARY or (not pots[i].is_empty() and not _valid_plant(pots[i])):
			pots[i] = {}
		elif pots[i].has("qua"):   # hạt lai đang kết: bỏ nếu dữ liệu hỏng
			var q = pots[i]["qua"]
			if typeof(q) != TYPE_DICTIONARY or not _valid_gen(q.get("bo")) or not q.has("con") or not q.has("san"):
				pots[i].erase("qua")
	seeds = seeds.filter(func(s): return typeof(s) == TYPE_DICTIONARY and _valid_gen(s.get("gen")))
	seed_bags = clampi(int(data.get("tui_hat", 1)), 1, Data.MAX_SEED_BAGS)
	shop_name = str(data.get("ten_shop", Data.DEFAULT_SHOP_NAME))
	if shop_name.strip_edges() == "":
		shop_name = Data.DEFAULT_SHOP_NAME
	shop_upgrades = {}
	var up = data.get("nang_cap_shop", {})
	if typeof(up) == TYPE_DICTIONARY:
		for k in Data.UPGRADE_ORDER:
			shop_upgrades[k] = clampi(int(up.get(k, 0)), 0, Data.SHOP_UPGRADES[k]["bac"].size() - 1)
	decor_owned = {}
	for id in data.get("trang_tri", []):
		decor_owned[str(id)] = true
	hidden_met = {}
	for id in data.get("khach_an", []):
		hidden_met[str(id)] = true
	# file lưu cũ có nhiều hạt hơn sức chứa: cho đủ túi
	seed_bags = maxi(seed_bags, ceili(float(seeds.size()) / Data.SEEDS_PER_BAG))
	return true


func _valid_gen(gen) -> bool:
	if typeof(gen) != TYPE_DICTIONARY:
		return false
	for part in Data.PARTS:
		if not gen.has(part) or gen[part].size() != 2:
			return false
		for id in gen[part]:
			if not Data.TRAITS[part].has(id):
				return false
	return true


func _valid_plant(p: Dictionary) -> bool:
	for k in ["gen", "tien_do", "nuoc"]:
		if not p.has(k):
			return false
	if not _valid_gen(p["gen"]):
		return false
	if not p.has("suc_khoe"):
		p["suc_khoe"] = 1.0
	if not p.has("da_tuoi"):
		p["da_tuoi"] = true
	for k in ["heo", "chet", "da_lai"]:
		if not p.has(k):
			p[k] = false
	return true


func reset_game() -> void:
	new_game()
	changed.emit()


# ================== Thời gian thực ==================

func _catch_up_offline() -> void:
	var now := _now()
	var dt := now - last_time
	last_time = now
	if dt <= 0.0:
		return  # đồng hồ máy bị chỉnh lùi: bỏ qua
	dt = min(dt, Data.MAX_OFFLINE)
	if dt < 60.0:
		_advance(dt)
		return
	var before := []
	for p in pots:
		before.append(stage_of(p) if not p.is_empty() else -1)
	_advance(dt)
	var grew := 0
	var thirsty := 0
	var died := 0
	for i in pots.size():
		var p: Dictionary = pots[i]
		if p.is_empty():
			continue
		if p.get("chet", false):
			if before[i] != -1:
				died += 1
			continue
		if stage_of(p) > before[i]:
			grew += 1
		if p["nuoc"] <= 0.0 and p.get("da_tuoi", true):
			thirsty += 1
	var lines := ["Bạn đã vắng mặt %s." % format_duration(dt)]
	if grew > 0:
		lines.append("%d cây đã lớn thêm." % grew)
	if thirsty > 0:
		lines.append("%d cây đang khát nước." % thirsty)
	if died > 0:
		lines.append("%d cây đã chết." % died)
	away_report = "\n".join(lines)


## Cho thời gian trôi dt giây (thật) với mọi chậu.
func _advance(real_dt: float) -> void:
	_check_new_day()
	var dt := real_dt * time_scale
	var now := _now()
	for i in pots.size():
		var p: Dictionary = pots[i]
		dt = real_dt * time_scale
		if p.is_empty() or p.get("chet", false):
			continue
		_advance_pod(p, dt)
		if not p.get("da_tuoi", true):
			continue  # hạt chưa được tưới lần đầu: chưa tính thời gian
		if p.get("trung_bay", false):
			continue  # cây đang trưng bày ở shop: shop chăm, không lớn thêm
		var wet := 0.0
		var auto_until: float = p.get("tu_tuoi_den", 0.0)
		if auto_until > now - real_dt:
			# phần thời gian có bình tưới tự động: luôn đủ nước
			var covered: float = min(real_dt, auto_until - (now - real_dt)) * time_scale
			wet += covered
			p["nuoc"] = 1.0
			dt -= covered
		var water_time: float = min(dt, p["nuoc"] / Data.WATER_DRAIN_PER_SEC)
		wet += water_time
		p["nuoc"] = max(0.0, p["nuoc"] - dt * Data.WATER_DRAIN_PER_SEC)
		var dry := dt - water_time
		var total := wet + dry
		# sức khỏe: mất khi khô (cây càng hiếm mất càng nhanh), mất khi đất kém hơn cây cần
		var r := Gen.rarity(p["gen"])
		var mism := soil_mismatch(i) if stage_of(p) >= 1 else 0
		var loss: float = dry * Data.HEALTH_DRY_LOSS * Data.HEALTH_DRY_RARITY_MULT[r] + total * Data.HEALTH_SOIL_LOSS[mism]
		var gain: float = wet * Data.HEALTH_REGEN if mism == 0 else 0.0
		p["suc_khoe"] = clampf(p.get("suc_khoe", 1.0) - loss + gain, 0.0, 1.0)
		p["heo"] = p["suc_khoe"] < Data.WILT_HEALTH
		p["tien_do"] += wet / grow_mult(p)
		if p["suc_khoe"] <= 0.0:
			_kill(p, "đất không hợp" if dry <= 0.0 and mism > 0 else "thiếu nước")
		if p["tien_do"] >= Data.STAGE_END[4]:
			_kill(p, "già")
		_check_discovery(p)


## Cây mẹ đã thụ phấn: cứ SEED_POD_INTERVAL giây kết thêm 1 hạt, đủ SEEDS_PER_CROSS hạt thì thôi.
## p["qua"] = {"bo": gen cây bố, "bo_me": [mã mẹ, mã bố], "t": giây đã đếm, "con": hạt chưa kết, "san": hạt chờ thu}
func _advance_pod(p: Dictionary, dt: float) -> void:
	if not p.has("qua") or p.get("trung_bay", false):
		return
	var q: Dictionary = p["qua"]
	if int(q["con"]) <= 0:
		return
	q["t"] = float(q["t"]) + dt
	while float(q["t"]) >= Data.SEED_POD_INTERVAL and int(q["con"]) > 0:
		q["t"] = float(q["t"]) - Data.SEED_POD_INTERVAL
		q["con"] = int(q["con"]) - 1
		q["san"] = int(q["san"]) + 1
	if int(q["con"]) <= 0:
		q["t"] = 0.0


func pod_ready(i: int) -> int:
	if i < 0 or i >= pots.size() or pots[i].is_empty() or not pots[i].has("qua"):
		return 0
	return int(pots[i]["qua"]["san"])


func pod_pending(i: int) -> int:
	if i < 0 or i >= pots.size() or pots[i].is_empty() or not pots[i].has("qua"):
		return 0
	return int(pots[i]["qua"]["con"])


## Số giây thật tới hạt kế tiếp.
func pod_next_seconds(i: int) -> float:
	if pod_pending(i) <= 0:
		return 0.0
	return (Data.SEED_POD_INTERVAL - float(pots[i]["qua"]["t"])) / time_scale


## Thu các hạt lai đã kết. Trả về số hạt đã thu.
func harvest_pod(i: int) -> int:
	var n := pod_ready(i)
	if n <= 0:
		return 0
	var room := seed_room()
	if room <= 0:
		message.emit("Túi hạt đã đầy. Mua thêm túi hạt ở mục Vật tư.")
		return 0
	var p: Dictionary = pots[i]
	var q: Dictionary = p["qua"]
	var take := mini(n, room)
	if not _valid_gen(q.get("gen_con")):   # file lưu cũ: tạo bộ gen con một lần rồi giữ lại
		q["gen_con"] = Gen.cross(p["gen"], q["bo"], cross_mutation(p["gen"], q["bo"]))
	for k in take:
		seeds.append({"gen": q["gen_con"].duplicate(true), "bo_me": q["bo_me"]})
	q["san"] = n - take
	if int(q["san"]) <= 0 and int(q["con"]) <= 0:
		p.erase("qua")
	var left := "" if take == n else " Túi đầy, còn %d hạt chờ thu." % (n - take)
	message.emit("Thu được %d hạt lai!%s" % [take, left])
	_changed()
	return take


func has_pod(i: int) -> bool:
	return pod_ready(i) > 0 or pod_pending(i) > 0


func _kill(p: Dictionary, why: String) -> void:
	p["chet"] = true
	p["ly_do"] = why


func grow_mult(p: Dictionary) -> float:
	return Data.RARITY_GROW_MULT[Gen.rarity(p["gen"])]


func stage_of(p: Dictionary) -> int:
	var t: float = p["tien_do"]
	for i in Data.STAGE_END.size():
		if t < Data.STAGE_END[i]:
			return i
	return 4


## Số giây thật còn lại tới giai đoạn sau (nếu đủ nước).
func seconds_to_next_stage(p: Dictionary) -> float:
	var s := stage_of(p)
	var remain: float = Data.STAGE_END[s] - p["tien_do"]
	return remain * grow_mult(p) / time_scale


func _check_discovery(p: Dictionary) -> void:
	if p.get("chet", false) or stage_of(p) < 3:
		return
	var key := Gen.variety_key(p["gen"])
	if collection.has(key):
		return
	collection[key] = {"ngay": Time.get_date_string_from_system(), "bo_me": p.get("bo_me", [])}
	message.emit("Giống mới vào Sổ tay: %s!" % Gen.variety_name(p["gen"]))
	var due := collection.size() / Data.COLLECTION_MILESTONE
	while milestones_paid < due:
		milestones_paid += 1
		coins += Data.MILESTONE_COINS
		if seed_room() > 0:
			seeds.append({"gen": Gen.random_genome(2), "bo_me": []})
		else:
			coins += 150  # túi đầy: đổi gói hạt thành xu
		message.emit("Mốc %d giống: thưởng %d xu và 1 gói hạt bí ẩn!" % [milestones_paid * Data.COLLECTION_MILESTONE, Data.MILESTONE_COINS])


# ================== Chăm sóc ==================

# ================== Túi hạt ==================

func seed_capacity() -> int:
	return seed_bags * Data.SEEDS_PER_BAG


func seed_room() -> int:
	return maxi(0, seed_capacity() - seeds.size())


func _need_room(n: int) -> bool:
	if seed_room() >= n:
		return true
	message.emit("Túi hạt không đủ chỗ (cần %d ô trống). Gieo bớt hạt hoặc mua thêm túi hạt ở mục Vật tư." % n)
	return false


# ================== Trang trí Shop cây ==================

func upgrade_tier(kind: String) -> int:
	return int(shop_upgrades.get(kind, 0))


## Giá bậc tiếp theo, -1 nếu đã tối đa.
func upgrade_next_price(kind: String) -> int:
	var tiers: Array = Data.SHOP_UPGRADES[kind]["bac"]
	var t := upgrade_tier(kind)
	return -1 if t >= tiers.size() - 1 else int(tiers[t + 1]["gia"])


func buy_upgrade(kind: String) -> bool:
	var price := upgrade_next_price(kind)
	if price < 0:
		message.emit("Đã nâng cấp tối đa.")
		return false
	if coins < price:
		message.emit("Không đủ xu.")
		return false
	coins -= price
	shop_upgrades[kind] = upgrade_tier(kind) + 1
	var tier_name: String = Data.SHOP_UPGRADES[kind]["bac"][upgrade_tier(kind)]["ten"]
	message.emit("Đã nâng cấp: %s." % tier_name)
	_changed()
	return true


func decor_price(id: String) -> int:
	for d in Data.SHOP_DECOR:
		if d["id"] == id:
			return int(d["gia"])
	return 0


func buy_decor(id: String) -> bool:
	if decor_owned.get(id, false):
		message.emit("Bạn đã có món này rồi.")
		return false
	var price := decor_price(id)
	if coins < price:
		message.emit("Không đủ xu.")
		return false
	coins -= price
	decor_owned[id] = true
	message.emit("Đã đặt đồ trang trí mới trong shop.")
	_changed()
	return true


## Sức hút shop: mỗi bậc nâng cấp và mỗi món trang trí được 1 điểm.
func appeal() -> int:
	var n := decor_owned.size()
	for k in Data.UPGRADE_ORDER:
		n += upgrade_tier(k)
	return n


func set_shop_name(n: String) -> void:
	n = n.strip_edges().left(Data.SHOP_NAME_MAX)
	shop_name = n if n != "" else Data.DEFAULT_SHOP_NAME
	_changed()


# ================== Đất ==================

func soil_level(i: int) -> int:
	var t: String = soils[i]
	return -1 if t == "" else int(Data.SOILS[t]["cap"])


## Đất kém hơn cây cần bao nhiêu cấp (0 = hợp).
func soil_mismatch(i: int) -> int:
	var p: Dictionary = pots[i]
	if p.is_empty():
		return 0
	var need: int = Data.SOIL_NEED[Gen.rarity(p["gen"])]
	return clampi(need - maxi(0, soil_level(i)), 0, 2)


## Cấp đất cây cần (dùng để hiện gợi ý).
func soil_needed(p: Dictionary) -> String:
	var need: int = Data.SOIL_NEED[Gen.rarity(p["gen"])]
	return Data.SOIL_ORDER[need]


func fill_soil(i: int, type: String) -> bool:
	if not soils_owned.get(type, false):
		message.emit("Chưa có %s. Mua ở mục Vật tư (%d xu)." % [Data.SOILS[type]["ten"], Data.SOILS[type]["gia"]])
		return false
	if not pots[i].is_empty():
		message.emit("Chậu đang có cây, không thay đất được.")
		return false
	if soils[i] == type:
		message.emit("Chậu đã có %s rồi." % Data.SOILS[type]["ten"].to_lower())
		return false
	soils[i] = type
	message.emit("Đã cho %s vào chậu %d." % [Data.SOILS[type]["ten"].to_lower(), i + 1])
	_changed()
	return true


# ================== Chăm sóc ==================

func plant_seed(pot_index: int, seed_index: int) -> bool:
	if not pots[pot_index].is_empty() or seed_index < 0 or seed_index >= seeds.size():
		return false
	if soils[pot_index] == "":
		message.emit("Chậu chưa có đất. Chọn chậu rồi chọn túi đất trước.")
		return false
	var s: Dictionary = seeds[seed_index]
	seeds.remove_at(seed_index)
	pots[pot_index] = {
		"gen": s["gen"],
		"bo_me": s.get("bo_me", []),
		"tien_do": 0.0,
		"nuoc": 0.0,
		"da_tuoi": false,
		"suc_khoe": 1.0,
		"heo": false,
		"chet": false,
		"da_lai": false,
		"tu_tuoi_den": 0.0,
	}
	message.emit("Đã gieo hạt. Tưới nước để hạt bắt đầu nảy mầm.")
	_changed()
	return true


func water(pot_index: int) -> void:
	var p: Dictionary = pots[pot_index]
	if p.is_empty() or p["chet"]:
		return
	p["nuoc"] = 1.0
	p["da_tuoi"] = true
	_changed()


func fertilize(pot_index: int) -> bool:
	var p: Dictionary = pots[pot_index]
	if p.is_empty() or p["chet"] or fertilizer <= 0:
		return false
	var s := stage_of(p)
	if s >= 3:
		message.emit("Cây đã ra hoa, không cần bón phân nữa.")
		return false
	if not p.get("da_tuoi", true):
		message.emit("Hãy tưới nước trước để hạt bắt đầu nảy mầm.")
		return false
	var start: float = 0.0 if s == 0 else Data.STAGE_END[s - 1]
	p["tien_do"] += (Data.STAGE_END[s] - start) * Data.FERTILIZER_BOOST
	fertilizer -= 1
	_check_discovery(p)
	_changed()
	return true


func attach_auto_waterer(pot_index: int) -> bool:
	var p: Dictionary = pots[pot_index]
	if p.is_empty() or p["chet"] or auto_waterers <= 0:
		return false
	auto_waterers -= 1
	p["tu_tuoi_den"] = _now() + Data.AUTO_WATER_DURATION / time_scale
	p["nuoc"] = 1.0
	p["da_tuoi"] = true
	_changed()
	return true


## Thu hạt từ cây già: nhận 2 hạt tự thụ phấn, chậu trống lại.
func harvest_seeds(pot_index: int) -> void:
	var p: Dictionary = pots[pot_index]
	if p.is_empty() or p["chet"] or stage_of(p) < 4:
		return
	if has_pod(pot_index):
		message.emit("Cây đang kết hạt lai. Chạm vào cây để thu hạt lai trước đã.")
		return
	if not _need_room(2):
		return
	var key := Gen.variety_key(p["gen"])
	for i in 2:
		seeds.append({"gen": Gen.cross(p["gen"], p["gen"], mutation_chance()), "bo_me": [key, key]})
	pots[pot_index] = {}
	soils[pot_index] = ""
	message.emit("Thu được 2 hạt. Chậu đã trống, cần cho đất mới.")
	_changed()


func remove_plant(pot_index: int) -> void:
	pots[pot_index] = {}
	soils[pot_index] = ""
	_changed()


# ================== Lai giống ==================

func mutation_chance() -> float:
	return Data.BASE_MUTATION + 0.01 * (garden_level() - 1)


## Tỉ lệ đột biến khi lai hai cây: càng hiếm càng cao.
func cross_mutation(gen_a: Dictionary, gen_b: Dictionary) -> float:
	return mutation_chance() + Data.MUTATION_PER_RARITY * (Gen.rarity(gen_a) + Gen.rarity(gen_b))


## Giá bán một hạt trong túi.
func seed_sell_price(idx: int) -> int:
	if idx < 0 or idx >= seeds.size():
		return 0
	return Data.SEED_SELL_PRICE[Gen.rarity(seeds[idx]["gen"])]


func sell_seed(idx: int) -> int:
	var price := seed_sell_price(idx)
	if price <= 0:
		return 0
	seeds.remove_at(idx)
	coins += price
	message.emit("Đã bán hạt được %d xu." % price)
	_changed()
	return price


func can_cross(i: int) -> bool:
	if i < 0 or i >= pots.size():
		return false
	var p: Dictionary = pots[i]
	return not p.is_empty() and not p["chet"] and stage_of(p) == 3 and not p.get("da_lai", false) \
		and not p.get("trung_bay", false)


## Thụ phấn cây i (cây bố, đã lấy phấn) cho cây j (cây mẹ).
func cross(i: int, j: int) -> bool:
	if i == j or i < 0 or i >= pots.size() or pots[i].is_empty():
		return false
	return pollinate(j, pots[i]["gen"])


## Bắn phấn (gen cây bố) vào cây mẹ j. Cây mẹ sẽ kết dần SEEDS_PER_CROSS hạt, mỗi hạt sau 5 phút.
func pollinate(j: int, father_gen: Dictionary) -> bool:
	if not can_cross(j):
		message.emit("Chỉ thụ phấn được cho cây đang ra hoa và chưa thụ phấn.")
		return false
	if coins < Data.POLLINATE_COST:
		message.emit("Không đủ xu để thụ phấn (%d xu)." % Data.POLLINATE_COST)
		return false
	coins -= Data.POLLINATE_COST
	var b: Dictionary = pots[j]
	b["da_lai"] = true
	# một lần lai chỉ tạo một bộ gen: mọi hạt của lần lai này giống hệt nhau
	var child := Gen.cross(b["gen"], father_gen, cross_mutation(b["gen"], father_gen))
	b["qua"] = {"bo": father_gen.duplicate(true), "bo_me": [Gen.variety_key(b["gen"]), Gen.variety_key(father_gen)],
		"t": 0.0, "con": Data.SEEDS_PER_CROSS, "san": 0, "gen_con": child}
	message.emit("Thụ phấn thành công! Cây sẽ kết %d hạt, cứ %d phút một hạt." % [Data.SEEDS_PER_CROSS, int(Data.SEED_POD_INTERVAL / 60.0)])
	_changed()
	return true


## Loại đất tốt nhất đã mua (túi đất luôn dùng loại này).
func best_soil() -> String:
	var best := "thuong"
	for t in Data.SOIL_ORDER:
		if soils_owned.get(t, false):
			best = t
	return best


# ================== Kinh tế ==================

func garden_level() -> int:
	var lv := 1
	for i in Data.LEVEL_REVENUE.size():
		if revenue >= Data.LEVEL_REVENUE[i]:
			lv = i + 1
	return lv


func _today() -> String:
	return Time.get_date_string_from_system()


func _check_new_day() -> void:
	var t := _today()
	if t != day_key:
		day_key = t
		sold_today = {}


## 3 kiểu đang được săn đón hôm nay (giống nhau cho cả ngày).
func hot_traits() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(day_key)
	var out: Array = []
	var parts := ["hoa", "mau", "la", "than"]
	while out.size() < 3:
		var part: String = parts[rng.randi() % parts.size()]
		var ids: Array = []
		for id in Data.TRAITS[part].keys():
			if Data.TRAITS[part][id]["hiem"] < 3:
				ids.append(id)
		var pick := {"part": part, "id": ids[rng.randi() % ids.size()]}
		if not out.has(pick):
			out.append(pick)
	return out


func is_hot(gen: Dictionary) -> bool:
	return Gen.count_matches(gen, hot_traits()) > 0


func market_price(p: Dictionary) -> int:
	var s := stage_of(p)
	var price := Data.BASE_PRICE
	price *= Data.RARITY_PRICE_MULT[Gen.rarity(p["gen"])]
	price *= Data.STAGE_PRICE_MULT[s]
	price *= 0.5 if p.get("heo", false) else 1.0
	price *= 2.0 if is_hot(p["gen"]) else 1.0
	var n := int(sold_today.get(Gen.variety_key(p["gen"]), 0))
	price *= max(0.5, 1.0 - 0.1 * n)
	return max(1, int(round(price)))


func can_sell(pot_index: int) -> bool:
	var p: Dictionary = pots[pot_index]
	return not p.is_empty() and not p["chet"] and stage_of(p) >= 2


## Giá người chơi đặt cho cây (phần trăm so với giá thị trường, mặc định 100%).
func price_pct(p: Dictionary) -> int:
	return int(p.get("gia_pct", 100))


func asking_price(p: Dictionary) -> int:
	return maxi(1, int(round(market_price(p) * price_pct(p) / 100.0)))


func set_price_pct(pot_index: int, pct: int) -> void:
	var p: Dictionary = pots[pot_index]
	if p.is_empty():
		return
	p["gia_pct"] = clampi(pct, Data.PRICE_MIN_PCT, Data.PRICE_MAX_PCT)
	_changed()


func is_displayed(pot_index: int) -> bool:
	return pot_index >= 0 and pot_index < pots.size() and pots[pot_index].get("trung_bay", false)


func displayed_pots() -> Array:
	var out: Array = []
	for i in pots.size():
		if is_displayed(i):
			out.append(i)
	return out


## Đưa cây ra Shop cây cảnh (hoặc thu về nếu on = false).
func set_display(pot_index: int, on: bool) -> bool:
	var p: Dictionary = pots[pot_index]
	if p.is_empty():
		return false
	if on:
		if not can_sell(pot_index):
			message.emit("Chỉ trưng bày được cây từ giai đoạn Trưởng thành trở đi.")
			return false
		if has_pod(pot_index):
			message.emit("Cây đang kết hạt lai. Thu đủ hạt rồi hãy trưng bày.")
			return false
		if displayed_pots().size() >= Data.MAX_STANDS:
			message.emit("Shop đã kín %d gốc trưng bày." % Data.MAX_STANDS)
			return false
		p["trung_bay"] = true
		message.emit("Đã đưa %s ra Shop cây cảnh." % Gen.variety_name(p["gen"]))
	else:
		p["trung_bay"] = false
	_changed()
	return true


## Nút "Về vườn": mọi cây chưa bán trở lại chậu.
func undisplay_all() -> int:
	var n := 0
	for p in pots:
		if not p.is_empty() and p.get("trung_bay", false):
			p["trung_bay"] = false
			n += 1
	_changed()
	return n


func pot_price() -> int:
	return int(round(100.0 * pow(1.5, pots_bought)))


func item_price(id: String) -> int:
	if id == "chau":
		return pot_price()
	for it in Data.SHOP_ITEMS:
		if it["id"] == id:
			return it["gia"]
	return 0


func buy(id: String) -> bool:
	var price := item_price(id)
	if coins < price:
		message.emit("Không đủ xu.")
		return false
	match id:
		"hat_thuong":
			if not _need_room(1):
				return false
			seeds.append({"gen": Gen.random_genome(0), "bo_me": []})
		"hat_bi_an":
			if not _need_room(1):
				return false
			seeds.append({"gen": Gen.random_genome(2), "bo_me": []})
		"tui_hat":
			if seed_bags >= Data.MAX_SEED_BAGS:
				message.emit("Đã có đủ %d túi hạt." % Data.MAX_SEED_BAGS)
				return false
			seed_bags += 1
			message.emit("Đã mua túi hạt mới: thêm %d ô (tổng %d ô)." % [Data.SEEDS_PER_BAG, seed_capacity()])
		"phan_bon":
			fertilizer += 1
		"binh_tuoi":
			auto_waterers += 1
		"chau":
			if pots.size() >= Data.MAX_POTS:
				message.emit("Vườn đã đủ %d chậu." % Data.MAX_POTS)
				return false
			pots.append({})
			soils.append("")
			pots_bought += 1
		"dat_tot", "dat_hiem":
			var t := "tot" if id == "dat_tot" else "hiem"
			if soils_owned.get(t, false):
				message.emit("Bạn đã có %s rồi." % Data.SOILS[t]["ten"].to_lower())
				return false
			soils_owned[t] = true
			message.emit("Đã mở khóa %s, dùng được mãi." % Data.SOILS[t]["ten"].to_lower())
	coins -= price
	_changed()
	return true


# ================== Bán hàng ==================

## Tỷ lệ bán chỉ theo giá: 50% khi đúng giá thị trường.
func price_chance(market: int, price: int, exponent: float) -> float:
	return 0.5 * pow(float(market) / float(max(1, price)), exponent)


## Mức Thấp / Vừa / Cao cho người chơi xem (không bao giờ hiện số %).
func chance_level(p: float) -> String:
	if p < 0.35:
		return "Thấp"
	if p < 0.65:
		return "Vừa"
	return "Cao"


func new_customer() -> Dictionary:
	var total := 0
	for k in Data.CUSTOMER_TYPES:
		total += Data.CUSTOMER_TYPES[k]["ty_le"]
	var r := randi() % total
	var type := "qua_duong"
	for k in Data.CUSTOMER_TYPES:
		r -= Data.CUSTOMER_TYPES[k]["ty_le"]
		if r < 0:
			type = k
			break
	var info: Dictionary = Data.CUSTOMER_TYPES[type]
	var n: int = randi_range(info["so_dac_diem"][0], info["so_dac_diem"][1])
	var wish: Array = []
	var used_parts: Array = []
	if type == "tang_qua":
		wish.append(_random_trait("mau", 2))
		used_parts.append("mau")
	elif randf() < 0.4:
		# hay hỏi đúng kiểu đang được săn đón
		var hot: Dictionary = hot_traits().pick_random()
		wish.append(hot)
		used_parts.append(hot["part"])
	var choices := ["hoa", "mau", "la", "than", "co"]
	while wish.size() < n:
		var part: String = choices.pick_random()
		if used_parts.has(part):
			continue
		used_parts.append(part)
		wish.append(_random_trait(part, 2 if type == "suu_tam" else 1))
	return {"type": type, "wish": wish}


func _random_trait(part: String, max_hiem: int) -> Dictionary:
	var ids: Array = []
	for id in Data.TRAITS[part].keys():
		if Data.TRAITS[part][id]["hiem"] <= max_hiem:
			ids.append(id)
	return {"part": part, "id": ids.pick_random()}


func wish_text(c: Dictionary) -> String:
	var bits: PackedStringArray = []
	for w in c["wish"]:
		bits.append(Data.trait_phrase(w["part"], w["id"]))
	var openers := {
		"qua_duong": "Chào chủ vườn! Tôi muốn tìm cây có %s.",
		"tang_qua": "Tôi cần một cây làm quà, phải có %s nhé.",
		"tiet_kiem": "Có cây nào %s mà giá mềm không?",
		"suu_tam": "Tôi đang săn cây có %s cho bộ sưu tập.",
	}
	return openers[c["type"]] % ", ".join(bits)


## Điểm khớp nhất để nói khi trả lời thành thật.
func best_match_phrase(gen: Dictionary, c: Dictionary) -> String:
	var p := Gen.phenotype(gen)
	for w in c["wish"]:
		if p[w["part"]] == w["id"]:
			return Data.trait_phrase(w["part"], w["id"])
	return Data.trait_phrase("hoa", p["hoa"])


## Tính tỷ lệ mua. answer: "" (chưa trả lời), "nhiet_tinh", "thanh_that", "giam_gia".
func buy_chance(p: Dictionary, price: int, c: Dictionary, answer: String) -> float:
	var info: Dictionary = Data.CUSTOMER_TYPES[c["type"]]
	var market := market_price(p)
	var chance := price_chance(market, price, info["mu_gia"])
	var wish: Array = c["wish"]
	var m := Gen.count_matches(p["gen"], wish)
	if m == wish.size():
		chance += 0.30
	elif m > 0:
		chance += 0.10 * m
	else:
		chance -= 0.25
	if stage_of(p) == 3:
		chance += 0.05
	match answer:
		"nhiet_tinh":
			if m == wish.size():
				chance += 0.10
			elif m == 0:
				chance -= 0.20
		"thanh_that":
			chance += 0.05
	match c["type"]:
		"tang_qua":
			chance += 0.10 if m > 0 else -0.10
		"suu_tam":
			if Gen.rarity(p["gen"]) >= 2:
				chance += 0.15
	# shop càng đẹp khách càng dễ mua
	chance += minf(Data.APPEAL_BUY_MAX, Data.APPEAL_BUY * appeal())
	return clamp(chance, 0.05, 0.95)


## Khách mua cây ở chậu pot_index với giá price.
func complete_sale(pot_index: int, price: int) -> void:
	var p: Dictionary = pots[pot_index]
	var key := Gen.variety_key(p["gen"])
	sold_today[key] = int(sold_today.get(key, 0)) + 1
	var old_level := garden_level()
	coins += price
	revenue += price
	pots[pot_index] = {}
	soils[pot_index] = ""
	if garden_level() > old_level:
		message.emit("Vườn lên cấp %d! Mục Vật tư có món mới, tỷ lệ đột biến tăng." % garden_level())
	_changed()


# ================== Khách ẩn ==================

## Công tử ăn chơi có tới không: "huyen_thoai" khi mọi cây đang bán đều Huyền thoại,
## "quy" khi mọi cây đều từ Quý trở lên; mỗi mốc chỉ một lần. Trả về "" nếu không.
func vip_kind(pot_ids: Array) -> String:
	if pot_ids.size() < Data.VIP_MIN_PLANTS:
		return ""
	var lowest := 3
	for i in pot_ids:
		if pots[i].is_empty():
			return ""
		lowest = mini(lowest, Gen.rarity(pots[i]["gen"]))
	if lowest >= 3 and not hidden_met.get("huyen_thoai", false):
		return "huyen_thoai"
	if lowest >= 2 and not hidden_met.get("quy", false):
		return "quy"
	return ""


func mark_hidden(kind: String) -> void:
	hidden_met[kind] = true
	_changed()


## Đóng tiền bảo kê cho đàn anh. Trả về số xu đã trả (không để xu bị âm).
func pay_protection() -> int:
	var paid := mini(coins, Data.BAO_KE_FEE)
	coins -= paid
	_changed()
	return paid


## Đánh nhau với đàn anh bảo kê: mua bông băng thuốc đỏ. Trả về số xu đã trả.
func pay_bandage() -> int:
	var paid := mini(coins, Data.BAO_KE_BANDAGE)
	coins -= paid
	_changed()
	return paid


# ================== Tiện ích ==================

func _changed() -> void:
	save_game()
	changed.emit()


static func format_duration(sec: float) -> String:
	var s := int(sec)
	if s < 60:
		return "%d giây" % s
	if s < 3600:
		return "%d phút" % (s / 60)
	if s < 86400:
		return "%d giờ %d phút" % [s / 3600, (s % 3600) / 60]
	return "%d ngày %d giờ" % [s / 86400, (s % 86400) / 3600]
