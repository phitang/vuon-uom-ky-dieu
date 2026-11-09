extends RefCounted
## Dữ liệu cố định của game: các bộ phận cây, kiểu của từng bộ phận,
## mức trội, độ hiếm, thời gian lớn, giá cả, loại khách.
## Muốn thêm kiểu hoa mới: thêm một dòng vào TRAITS bên dưới.

const PARTS := ["hoa", "la", "than", "mau", "co"]

const PART_NAMES := {
	"hoa": "Hoa",
	"la": "Lá",
	"than": "Thân",
	"mau": "Màu hoa",
	"co": "Kích thước",
}

## Mỗi kiểu: ten = tên hiển thị, troi = mức trội (cao hơn thì lấn át),
## hiem = điểm hiếm (0 thường, 1 hiếm, 2 quý, 3 huyền thoại - chỉ có qua đột biến).
const TRAITS := {
	"hoa": {
		"cuc":    {"ten": "Cúc",    "troi": 7, "hiem": 0},
		"hong":   {"ten": "Hồng",   "troi": 6, "hiem": 0},
		"tulip":  {"ten": "Tulip",  "troi": 5, "hiem": 1},
		"chuong": {"ten": "Chuông", "troi": 5, "hiem": 1},
		"sao":    {"ten": "Sao",    "troi": 4, "hiem": 1},
		"lan":    {"ten": "Lan",    "troi": 3, "hiem": 2},
		"sen":    {"ten": "Sen",    "troi": 3, "hiem": 2},
		"rong":   {"ten": "Rồng",   "troi": 2, "hiem": 3},
	},
	"la": {
		"tron":    {"ten": "Tròn",     "troi": 7, "hiem": 0},
		"nhon":    {"ten": "Nhọn",     "troi": 6, "hiem": 0},
		"rangcua": {"ten": "Răng cưa", "troi": 5, "hiem": 1},
		"kim":     {"ten": "Kim",      "troi": 4, "hiem": 1},
		"tim":     {"ten": "Trái tim", "troi": 3, "hiem": 2},
		"bac":     {"ten": "Bạc",      "troi": 2, "hiem": 3},
	},
	"than": {
		"thang": {"ten": "Thẳng", "troi": 7, "hiem": 0},
		"cong":  {"ten": "Cong",  "troi": 6, "hiem": 0},
		"xoan":  {"ten": "Xoắn",  "troi": 4, "hiem": 1},
		"gai":   {"ten": "Gai",   "troi": 3, "hiem": 2},
		"ngoc":  {"ten": "Ngọc",  "troi": 2, "hiem": 3},
	},
	"mau": {
		"trang":    {"ten": "Trắng",     "troi": 7, "hiem": 0},
		"vang":     {"ten": "Vàng",      "troi": 6, "hiem": 0},
		"do":       {"ten": "Đỏ",        "troi": 6, "hiem": 0},
		"hongnhat": {"ten": "Hồng phấn", "troi": 5, "hiem": 1},
		"cam":      {"ten": "Cam",       "troi": 5, "hiem": 1},
		"tim":      {"ten": "Tím",       "troi": 4, "hiem": 1},
		"xanh":     {"ten": "Xanh lam",  "troi": 3, "hiem": 2},
		"cauvong":  {"ten": "Cầu vồng",  "troi": 2, "hiem": 3},
	},
	"co": {
		"vua": {"ten": "Vừa", "troi": 6, "hiem": 0},
		"nho": {"ten": "Nhỏ", "troi": 5, "hiem": 0},
		"lon": {"ten": "Lớn", "troi": 4, "hiem": 1},
	},
}

const FLOWER_COLORS := {
	"trang": Color("f5f3ea"),
	"vang": Color("f6d55c"),
	"do": Color("e2453c"),
	"hongnhat": Color("f2a7c3"),
	"cam": Color("f39a3d"),
	"tim": Color("9b6bd6"),
	"xanh": Color("4a86e8"),
	"cauvong": Color("ff66cc"),
}

## Gợi ý cho các kiểu huyền thoại chưa tìm ra (hiện trong Sổ tay).
const LEGEND_HINTS := {
	"rong": "Chỉ xuất hiện qua đột biến khi lai hoa quý",
	"bac": "Đột biến hiếm của lá",
	"ngoc": "Đột biến hiếm của thân",
	"cauvong": "Đột biến hiếm của màu hoa",
}

# ---------------- Độ hiếm ----------------
const RARITY_NAMES := ["Thường", "Hiếm", "Quý", "Huyền thoại"]
const RARITY_PRICE_MULT := [1.0, 3.0, 10.0, 50.0]
const RARITY_GROW_MULT := [1.0, 1.5, 2.0, 3.0]  # giống hiếm lớn chậm hơn
const RARITY_COLORS := [Color("9aa39a"), Color("4a9be8"), Color("b36be0"), Color("f0a020")]

# ---------------- Thời gian lớn (giây, cho cây Thường) ----------------
## Mốc tích lũy: hết mốc thứ i thì sang giai đoạn i+1.
## Hạt 5 phút, Cây non 30 phút, Trưởng thành 2 giờ, Ra hoa 4 giờ, Già 24 giờ rồi chết.
const STAGE_NAMES := ["Hạt nảy mầm", "Cây non", "Trưởng thành", "Ra hoa", "Già, cho hạt"]
const STAGE_END := [300.0, 2100.0, 9300.0, 23700.0, 110100.0]
const STAGE_PRICE_MULT := [0.0, 0.0, 1.0, 1.5, 0.7]
## Cây non / trưởng thành chưa ra hoa vẫn bán được nhưng chỉ được phần này giá cây đang ra hoa.
const YOUNG_SELL_RATIO := 0.5
const YOUNG_SELL_MIN_STAGE := 1      # từ giai đoạn Cây non (hạt mới nảy mầm thì chưa bán được)

const WATER_DRAIN_PER_SEC := 1.0 / 28800.0   # bình nước đầy cạn sau 8 giờ
const MAX_OFFLINE := 7.0 * 24.0 * 3600.0       # tính tối đa 7 ngày vắng mặt
const AUTO_WATER_DURATION := 24.0 * 3600.0
const FERTILIZER_BOOST := 0.2                  # rút ngắn 20% giai đoạn hiện tại (cây chưa ra hoa)
const FERTILIZER_HEAL := 0.35                  # hồi 35% sức khỏe

# ---------------- Đất và sức khỏe ----------------
## cap = độ tốt của đất. Mua một lần ở cửa hàng là dùng được mãi.
const SOILS := {
	"thuong": {"ten": "Đất thường", "cap": 0, "gia": 0, "mau": Color("6b4a2e")},
	"tot":    {"ten": "Đất tốt", "cap": 1, "gia": 50000, "mau": Color("3a2a1c")},
	"hiem":   {"ten": "Đất hiếm", "cap": 2, "gia": 200000, "mau": Color("4a3058")},
}
const SOIL_ORDER := ["thuong", "tot", "hiem"]
## Cấp đất cây cần theo độ hiếm: Thường, Hiếm, Quý, Huyền thoại.
const SOIL_NEED := [0, 1, 2, 2]

## Sức khỏe từ 1.0 (khỏe) về 0.0 (chết). Dưới 0.5 là héo, giá bán giảm một nửa.
## Hết nước: cây Thường mất hết sức khỏe trong 8 giờ; cây càng hiếm mất càng nhanh.
const HEALTH_DRY_LOSS := 1.0 / (8.0 * 3600.0)
const HEALTH_DRY_RARITY_MULT := [1.0, 1.5, 2.0, 2.5]
## Đất kém hơn cây cần: thiếu 1 cấp mất hết sức khỏe trong 10 giờ, thiếu 2 cấp trong 4 giờ (kể cả khi đủ nước).
## (Trước đây là 36 giờ và 16 giờ.) Cây không tự hồi sức khỏe khi đất không hợp: phải bón phân.
const HEALTH_SOIL_LOSS := [0.0, 1.0 / (10.0 * 3600.0), 1.0 / (4.0 * 3600.0)]
## Đủ nước và đất hợp: hồi đầy sức khỏe trong 12 giờ.
const HEALTH_REGEN := 1.0 / (12.0 * 3600.0)
const WILT_HEALTH := 0.5

# ---------------- Kinh tế ----------------
const BASE_PRICE := 20.0
const START_COINS := 200
const START_POTS := 3
const MAX_POTS := 24
const POLLINATE_COST := 20
const SEEDS_PER_BAG := 8       # mỗi túi hạt chứa 8 hạt
const MAX_SEED_BAGS := 6
const SEEDS_PER_CROSS := 3          # số hạt một lần thụ phấn cho ra (cây mẹ kết dần từng hạt)
const SEED_POD_INTERVAL := 300.0     # cứ 5 phút (thời gian trong game) cây mẹ kết thêm 1 hạt
const BASE_MUTATION := 0.02
## Lai giống: mỗi độ hiếm của cây bố và cây mẹ cộng thêm tỉ lệ đột biến ra kiểu hiếm.
## Ví dụ Thường × Thường: 2%; Hiếm × Hiếm: 2% + 2 x 3% = 8%; Quý × Quý: 14%.
const MUTATION_PER_RARITY := 0.03
## Giá bán hạt ở mục Vật tư theo độ hiếm: Thường, Hiếm, Quý, Huyền thoại.
const SEED_SELL_PRICE := [5, 15, 30, 50]
const LEVEL_REVENUE := [0, 500, 2000, 8000, 25000]   # doanh thu để lên cấp vườn 1..5
const COLLECTION_MILESTONE := 25
const MILESTONE_COINS := 200

const SHOP_ITEMS := [
	{"id": "hat_thuong", "ten": "Gói hạt thường", "gia": 30, "mo_ta": "1 hạt giống ngẫu nhiên loại Thường", "cap": 1},
	{"id": "phan_bon", "ten": "Phân bón", "gia": 25, "mo_ta": "Hồi 35% sức khỏe, cây chưa ra hoa lớn nhanh hơn", "cap": 1},
	{"id": "chau", "ten": "Chậu mới", "gia": 100, "mo_ta": "Thêm một chỗ trồng (giá tăng 50% mỗi lần)", "cap": 1},
	{"id": "hat_bi_an", "ten": "Gói hạt bí ẩn", "gia": 150, "mo_ta": "Có cơ hội ra kiểu Hiếm và Quý", "cap": 2},
	{"id": "tui_hat", "ten": "Túi hạt thêm", "gia": 1000, "mo_ta": "Thêm 8 ô chứa hạt (tối đa 6 túi)", "cap": 1},
	{"id": "dat_tot", "ten": "Đất tốt", "gia": 50000, "mo_ta": "Mua một lần, dùng mãi. Hợp cây Hiếm", "cap": 1},
	{"id": "dat_hiem", "ten": "Đất hiếm", "gia": 200000, "mo_ta": "Mua một lần, dùng mãi. Hợp cây Quý và Huyền thoại", "cap": 1},
]

# ---------------- Bán hàng ----------------
const PRICE_MIN_PCT := 50
const PRICE_MAX_PCT := 300
const CUSTOMERS_PER_SALE := 5
const MAX_STANDS := 12               # số gốc cây trưng bày trong Shop cây cảnh
const SHOP_SPAWN_MIN := 4.0          # giây giữa hai lượt khách vào shop
const SHOP_SPAWN_MAX := 8.0
const MAX_SHOP_CUSTOMERS := 5

# ---------------- Trang trí Shop cây ----------------
const DEFAULT_SHOP_NAME := "VƯỜN ƯƠM"
const SHOP_NAME_MAX := 18
## Nâng cấp theo bậc (bậc 0 có sẵn). Mỗi bậc cộng 1 điểm sức hút.
const SHOP_UPGRADES := {
	"bang_hieu": {"ten": "Bảng hiệu", "bac": [
		{"ten": "Bảng gỗ mộc", "gia": 0},
		{"ten": "Bảng sơn xanh viền vàng", "gia": 2000},
		{"ten": "Bảng gỗ chạm, đèn treo", "gia": 8000},
		{"ten": "Bảng cẩm thạch chữ vàng", "gia": 25000}]},
	"quay": {"ten": "Quầy tính tiền", "bac": [
		{"ten": "Quầy gỗ đơn giản", "gia": 0},
		{"ten": "Quầy gỗ bóng, mái che sọc", "gia": 3000},
		{"ten": "Quầy kính trưng bày hoa", "gia": 10000},
		{"ten": "Quầy cao cấp viền vàng, mái đèn", "gia": 30000}]},
	"hang_rao": {"ten": "Hàng rào", "bac": [
		{"ten": "Rào gỗ", "gia": 0},
		{"ten": "Rào trắng mũi nhọn", "gia": 1500},
		{"ten": "Rào sắt uốn hoa văn", "gia": 6000},
		{"ten": "Tường gạch có bồn hoa", "gia": 20000}]},
}
const UPGRADE_ORDER := ["bang_hieu", "quay", "hang_rao"]
## Đồ trang trí mua một lần, đặt cố định trong shop. Mỗi món cộng 1 điểm sức hút.
const SHOP_DECOR := [
	{"id": "chuong_gio", "ten": "Chuông gió", "gia": 600, "mo_ta": "Treo ở cổng, đung đưa theo gió"},
	{"id": "den_long", "ten": "Đèn lồng", "gia": 800, "mo_ta": "Hai cột đèn lồng đỏ hai bên cổng"},
	{"id": "bon_hoa", "ten": "Bồn hoa", "gia": 1000, "mo_ta": "Hai bồn hoa rực rỡ cạnh hàng rào"},
	{"id": "ghe_da", "ten": "Ghế đá", "gia": 1200, "mo_ta": "Chỗ nghỉ chân cho khách"},
	{"id": "o_du", "ten": "Bàn ô dù", "gia": 1500, "mo_ta": "Bàn nhỏ có ô che nắng"},
	{"id": "xich_du", "ten": "Xích đu", "gia": 3500, "mo_ta": "Xích đu gỗ đung đưa"},
	{"id": "tuong", "ten": "Tượng thỏ đá", "gia": 4000, "mo_ta": "Tượng thỏ may mắn trên bệ đá"},
	{"id": "coi_xay_gio", "ten": "Cối xay gió", "gia": 5000, "mo_ta": "Cối xay gió nhỏ quay trên đồi"},
]
## Mỗi điểm sức hút: khách tới nhanh hơn 5% (tối đa nhanh gấp đôi), dễ mua hơn 1% (tối đa 12%).
const APPEAL_SPAWN := 0.05
const APPEAL_BUY := 0.01
const APPEAL_BUY_MAX := 0.12        # số khách cùng lúc trong shop
const SHOP_WALK_SPEED := 130.0       # tốc độ đi của khách (điểm ảnh / giây)

# ---------- Khách ẩn ----------
# Công tử ăn chơi: tới khi mọi cây đang bày bán đều Quý (hoặc hơn), và một lần nữa khi đều Huyền thoại.
# Mỗi mốc chỉ một lần. Khách thường vào xem VIP_BROWSE_TIME giây (không mua), rồi 2 vệ sĩ đuổi hết khách,
# công tử xem vài cây và mua hết cây đang bày bán theo giá bạn đặt.
const VIP_MIN_PLANTS := 1            # số cây tối thiểu đang bày bán
const VIP_BROWSE_TIME := 10.0        # giây
# Đàn anh đòi tiền bảo kê: tới khi shop không còn cây nào để bán quá BAO_KE_WAIT giây.
const BAO_KE_WAIT := 120.0           # giây (2 phút)
# "Đánh khứa này luôn" = oẳn tù tì 3 ván (hòa thì đánh lại). Tiền mất theo số ván thua: 0, 1, 2, 3 ván.
const BAO_KE_FIGHT_COST := [0, 10, 20, 50]
const RPS_ROUNDS := 3
const BAO_KE_FEE := 100              # tiền bảo kê khi chọn "Đóng tiền bảo kê"
# Công tử ghé thêm (mỗi lần mở Shop cây tối đa một lần mỗi kiểu):
const VIP_COMMON_WAIT := 180.0       # shop toàn cây Thường quá 3 phút chưa bán hết: công tử vào chê rồi đi
const VIP_LEGEND_WAIT := 300.0       # shop còn cây Huyền thoại quá 5 phút: công tử hỏi mua cây đắt nhất
# Đàn anh thỉnh thoảng vào như khách thường (tối đa một lần mỗi lần mở Shop cây), khó mua hơn.
const DAN_ANH_SPAWN_CHANCE := 0.12   # khả năng mỗi khách mới là đàn anh
const DAN_ANH_BUY_FACTOR := 0.55     # tỉ lệ mua chỉ bằng phần này so với khách thường
# Công tử ghé như khách thường khi shop còn cây sau 7 phút (một lần mỗi lần mở Shop cây):
# chỉ mua cây từ Hiếm trở lên, tỉ lệ mua gấp đôi khách thường.
const VIP_GUEST_WAIT := 420.0
const VIP_GUEST_BUY_FACTOR := 2.0
const VIP_GUEST_MIN_RARITY := 1
const DISCOUNT := 0.10

## Các loại khách. so_dac_diem = [ít nhất, nhiều nhất], mu_gia = độ nhạy giá.
const CUSTOMER_TYPES := {
	"qua_duong": {"ten": "Người qua đường", "ty_le": 40, "so_dac_diem": [1, 1], "mu_gia": 2.0, "mau_ao": Color("6aa5d8")},
	"tang_qua":  {"ten": "Người mua tặng quà", "ty_le": 25, "so_dac_diem": [1, 1], "mu_gia": 2.0, "mau_ao": Color("e57aa0")},
	"tiet_kiem": {"ten": "Người tiết kiệm", "ty_le": 20, "so_dac_diem": [1, 2], "mu_gia": 3.0, "mau_ao": Color("8fbf6a")},
	"suu_tam":   {"ten": "Nhà sưu tầm", "ty_le": 15, "so_dac_diem": [2, 3], "mu_gia": 1.0, "mau_ao": Color("9b6bd6")},
}


static func trait_name(part: String, id: String) -> String:
	return TRAITS[part][id]["ten"]


static func trait_info(part: String, id: String) -> Dictionary:
	return TRAITS[part][id]


## Cụm từ dùng trong lời khách và tên cây, ví dụ "hoa Sao", "lá Kim", "màu Tím".
static func trait_phrase(part: String, id: String) -> String:
	var ten: String = trait_name(part, id)
	match part:
		"hoa": return "hoa " + ten.to_lower()
		"la": return "lá " + ten.to_lower()
		"than": return "thân " + ten.to_lower()
		"mau": return "màu " + ten.to_lower()
		"co": return "cỡ " + ten.to_lower()
	return ten
