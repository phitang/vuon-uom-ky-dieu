extends RefCounted
## Câu hỏi cho côn trùng hỏi đáp. make(loại, cấp) trả về {"q": câu hỏi, "options": [4 đáp án], "answer": chỉ số đúng}.
##   buom  -> từ vựng tiếng Anh (cấp 0 dễ, 1 vừa, 2 khó)
##   chuon -> toán cộng trừ nhân chia (cấp 0, 1, 2)
##   ong   -> đời sống xã hội

const WORDS := [
	[   # dễ
		["cat", "con mèo"], ["dog", "con chó"], ["apple", "quả táo"], ["red", "màu đỏ"], ["blue", "màu xanh dương"],
		["book", "quyển sách"], ["sun", "mặt trời"], ["water", "nước"], ["house", "ngôi nhà"], ["mother", "mẹ"],
		["father", "bố"], ["school", "trường học"], ["fish", "con cá"], ["bird", "con chim"], ["flower", "bông hoa"],
		["tree", "cái cây"], ["milk", "sữa"], ["egg", "quả trứng"], ["chair", "cái ghế"], ["door", "cái cửa"],
		["banana", "quả chuối"], ["green", "màu xanh lá"], ["hand", "bàn tay"], ["eye", "con mắt"], ["car", "xe ô tô"],
		["moon", "mặt trăng"], ["rain", "mưa"], ["happy", "vui vẻ"], ["big", "to lớn"], ["small", "nhỏ bé"],
		["hot", "nóng"], ["cold", "lạnh"], ["pen", "cây bút"], ["bread", "bánh mì"], ["friend", "người bạn"],
	],
	[   # vừa
		["weather", "thời tiết"], ["kitchen", "nhà bếp"], ["teacher", "giáo viên"], ["doctor", "bác sĩ"],
		["hospital", "bệnh viện"], ["market", "cái chợ"], ["umbrella", "cái ô (dù)"], ["breakfast", "bữa sáng"],
		["holiday", "kỳ nghỉ"], ["birthday", "sinh nhật"], ["library", "thư viện"], ["tired", "mệt mỏi"],
		["hungry", "đói bụng"], ["beautiful", "xinh đẹp"], ["expensive", "đắt tiền"], ["cheap", "rẻ"],
		["borrow", "mượn"], ["remember", "ghi nhớ"], ["forget", "quên"], ["travel", "đi du lịch"],
		["neighbor", "hàng xóm"], ["garden", "khu vườn"], ["season", "mùa"], ["island", "hòn đảo"],
		["mountain", "ngọn núi"], ["river", "dòng sông"], ["friendly", "thân thiện"], ["dangerous", "nguy hiểm"],
		["quiet", "yên tĩnh"], ["healthy", "khỏe mạnh"], ["village", "ngôi làng"], ["crowded", "đông đúc"],
		["invite", "mời"], ["question", "câu hỏi"], ["answer", "câu trả lời"],
	],
	[   # khó
		["environment", "môi trường"], ["achievement", "thành tựu"], ["responsibility", "trách nhiệm"],
		["reluctant", "miễn cưỡng"], ["generous", "hào phóng"], ["curious", "tò mò"], ["opportunity", "cơ hội"],
		["experience", "kinh nghiệm"], ["pollution", "sự ô nhiễm"], ["agriculture", "nông nghiệp"],
		["harvest", "vụ thu hoạch"], ["fertilizer", "phân bón"], ["pollinate", "thụ phấn"],
		["determination", "sự quyết tâm"], ["consequence", "hậu quả"], ["negotiate", "đàm phán"],
		["ancestor", "tổ tiên"], ["abundant", "dồi dào"], ["fragile", "dễ vỡ"], ["ambitious", "tham vọng"],
		["sustainable", "bền vững"], ["encourage", "khuyến khích"], ["appreciate", "trân trọng"],
		["independent", "độc lập"], ["efficient", "hiệu quả"], ["ingredient", "nguyên liệu"],
		["volunteer", "tình nguyện viên"], ["endangered", "có nguy cơ tuyệt chủng"], ["evaporate", "bay hơi"],
		["persuade", "thuyết phục"], ["humble", "khiêm tốn"], ["punctual", "đúng giờ"], ["souvenir", "quà lưu niệm"],
	],
]

## Đời sống xã hội: [câu hỏi, đáp án đúng, sai 1, sai 2, sai 3]
const LIFE := [
	["Ở Việt Nam, gọi cứu hỏa thì bấm số nào?", "114", "113", "115", "111"],
	["Ở Việt Nam, gọi công an khi khẩn cấp thì bấm số nào?", "113", "114", "115", "116"],
	["Ở Việt Nam, gọi cấp cứu y tế thì bấm số nào?", "115", "113", "114", "119"],
	["Tổng đài quốc gia bảo vệ trẻ em là số nào?", "111", "113", "115", "118"],
	["Đèn giao thông chuyển sang màu vàng thì người lái xe nên làm gì?", "Giảm tốc độ và dừng trước vạch dừng", "Tăng tốc vượt qua thật nhanh", "Quay đầu xe ngay", "Bấm còi liên tục"],
	["Khi đi xe máy, người ngồi trên xe cần làm gì để an toàn?", "Đội mũ bảo hiểm và cài quai đúng cách", "Chỉ người lái mới cần đội mũ", "Đi gần thì không cần đội mũ", "Đội mũ nhưng không cần cài quai"],
	["Người đi bộ nên qua đường ở đâu?", "Ở vạch kẻ đường dành cho người đi bộ", "Bất kỳ chỗ nào vắng xe", "Len giữa hai xe đang chạy", "Ngay khúc cua khuất tầm nhìn"],
	["Rửa tay bằng xà phòng nên chà trong ít nhất bao lâu?", "20 giây", "3 giây", "5 phút", "Không cần chà"],
	["Khi bị bỏng nhẹ, việc nên làm đầu tiên là gì?", "Xả vết bỏng dưới vòi nước mát, sạch", "Bôi kem đánh răng lên vết bỏng", "Chọc vỡ bọng nước", "Băng thật chặt lại ngay"],
	["Ngày Quốc khánh nước Việt Nam là ngày nào?", "2 tháng 9", "30 tháng 4", "1 tháng 5", "19 tháng 8"],
	["Ngày Nhà giáo Việt Nam là ngày nào?", "20 tháng 11", "8 tháng 3", "1 tháng 6", "20 tháng 10"],
	["Ngày Quốc tế Thiếu nhi là ngày nào?", "1 tháng 6", "1 tháng 5", "2 tháng 9", "8 tháng 3"],
	["Ngày Phụ nữ Việt Nam là ngày nào?", "20 tháng 10", "8 tháng 3", "20 tháng 11", "1 tháng 6"],
	["Tết Trung thu rơi vào ngày nào âm lịch?", "Rằm tháng 8 (15/8)", "Mùng 1 tháng Giêng", "Mùng 5 tháng 5", "Mùng 10 tháng 3"],
	["Giỗ Tổ Hùng Vương là ngày nào âm lịch?", "Mùng 10 tháng 3", "Rằm tháng 8", "Mùng 5 tháng 5", "Rằm tháng Giêng"],
	["Tết Đoan Ngọ (Tết diệt sâu bọ) là ngày nào âm lịch?", "Mùng 5 tháng 5", "Rằm tháng 8", "Mùng 10 tháng 3", "Mùng 7 tháng 7"],
	["Thủ đô của Việt Nam là thành phố nào?", "Hà Nội", "TP. Hồ Chí Minh", "Huế", "Đà Nẵng"],
	["Đơn vị tiền tệ của Việt Nam là gì?", "Đồng", "Đô la", "Yên", "Nhân dân tệ"],
	["Đỉnh núi cao nhất Việt Nam là đỉnh nào?", "Fansipan", "Bà Đen", "Ngọc Linh", "Bạch Mã"],
	["Vịnh Hạ Long thuộc tỉnh nào?", "Quảng Ninh", "Khánh Hòa", "Thanh Hóa", "Đà Nẵng"],
	["Ở áp suất bình thường, nước sôi ở bao nhiêu độ C?", "100 độ C", "50 độ C", "80 độ C", "150 độ C"],
	["Một năm không nhuận có bao nhiêu ngày?", "365 ngày", "300 ngày", "352 ngày", "400 ngày"],
	["Vỏ chai nhựa đã dùng nên xử lý thế nào?", "Phân loại riêng để tái chế", "Đốt ngoài vườn", "Vứt xuống sông", "Chôn ngay cạnh nhà"],
	["Khi ra khỏi phòng, làm gì để tiết kiệm điện?", "Tắt đèn và quạt", "Bật thêm đèn cho sáng", "Mở cửa tủ lạnh", "Để tivi chạy tiếp"],
	["Người lạ rủ đi theo và hứa cho quà, trẻ em nên làm gì?", "Từ chối và báo ngay cho người lớn tin cậy", "Đi theo ngay", "Nhận quà rồi giữ bí mật", "Cho người lạ biết địa chỉ nhà"],
	["Khi quang hợp, cây xanh hấp thụ khí gì?", "Khí cacbonic (CO2)", "Khí oxy", "Khí nitơ", "Khí heli"],
	["Ong mật làm ra thứ gì mà con người hay dùng?", "Mật ong", "Sữa", "Tơ tằm", "Nhựa cây"],
	["Người trưởng thành nên ngủ khoảng bao nhiêu tiếng mỗi đêm?", "7 đến 9 tiếng", "3 đến 4 tiếng", "12 đến 14 tiếng", "1 đến 2 tiếng"],
	["Trong nhà có cháy và nhiều khói, nên thoát ra thế nào?", "Cúi thấp người, che mũi miệng, đi ra lối thoát", "Chạy vào phòng kín trốn", "Đi thang máy xuống", "Đứng yên chờ khói tan"],
	["Ngày Môi trường Thế giới là ngày nào?", "5 tháng 6", "1 tháng 1", "20 tháng 11", "2 tháng 9"],
	["Trái Đất quay quanh thiên thể nào?", "Mặt Trời", "Mặt Trăng", "Sao Hỏa", "Không quay quanh gì cả"],
	["Việt Nam có bao nhiêu dân tộc?", "54 dân tộc", "45 dân tộc", "64 dân tộc", "34 dân tộc"],
	["Dịp lễ nào cả nhà sum họp đón năm mới âm lịch?", "Tết Nguyên Đán", "Tết Trung thu", "Lễ Vu Lan", "Tết Đoan Ngọ"],
	["Khi gặp người lớn tuổi, cách chào lễ phép là gì?", "Khoanh tay, cúi đầu chào", "Lờ đi như không thấy", "Vẫy tay gọi trống không", "Chạy vụt qua"],
	["Vì sao nên uống nước đã đun sôi để nguội?", "Để diệt vi khuẩn gây bệnh", "Để nước ngọt hơn", "Để nước có màu đẹp", "Để nước nặng hơn"],
]


static func make(kind: String, level: int) -> Dictionary:
	match kind:
		"buom": return _english(clampi(level, 0, 2))
		"chuon": return _math(clampi(level, 0, 2))
		_: return _life()


static func _pack(q: String, right: String, wrongs: Array) -> Dictionary:
	var opts: Array = [right]
	for w in wrongs:
		if opts.size() >= 4:
			break
		if not (w in opts):
			opts.append(w)
	opts.shuffle()
	return {"q": q, "options": opts, "answer": opts.find(right)}


static func _english(level: int) -> Dictionary:
	var words: Array = WORDS[level]
	var pick: Array = words.pick_random()
	var others: Array = words.duplicate()
	others.erase(pick)
	others.shuffle()
	if randf() < 0.5:   # tiếng Anh -> tiếng Việt
		return _pack("Từ \"%s\" nghĩa là gì?" % pick[0], pick[1], others.slice(0, 5).map(func(w): return w[1]))
	return _pack("\"%s\" trong tiếng Anh là từ nào?" % pick[1], pick[0], others.slice(0, 5).map(func(w): return w[0]))


static func _life() -> Dictionary:
	var row: Array = LIFE.pick_random()
	return _pack(row[0], row[1], row.slice(2))


static func _math(level: int) -> Dictionary:
	var q := ""
	var ans := 0
	match level:
		0:
			if randf() < 0.5:
				var a := randi_range(1, 12)
				var b := randi_range(1, 9)
				q = "%d + %d = ?" % [a, b]
				ans = a + b
			else:
				var a := randi_range(5, 20)
				var b := randi_range(1, a)
				q = "%d − %d = ?" % [a, b]
				ans = a - b
		1:
			match randi() % 4:
				0:
					var a := randi_range(2, 9)
					var b := randi_range(2, 10)
					q = "%d × %d = ?" % [a, b]
					ans = a * b
				1:
					var b := randi_range(2, 9)
					ans = randi_range(2, 10)
					q = "%d ÷ %d = ?" % [b * ans, b]
				2:
					var a := randi_range(15, 60)
					var b := randi_range(11, 39)
					q = "%d + %d = ?" % [a, b]
					ans = a + b
				_:
					var a := randi_range(40, 99)
					var b := randi_range(11, a - 5)
					q = "%d − %d = ?" % [a, b]
					ans = a - b
		_:
			match randi() % 4:
				0:
					var a := randi_range(12, 99)
					var b := randi_range(3, 9)
					q = "%d × %d = ?" % [a, b]
					ans = a * b
				1:
					var b := randi_range(3, 9)
					ans = randi_range(11, 40)
					q = "%d ÷ %d = ?" % [b * ans, b]
				2:   # nhân chia trước, cộng trừ sau
					var a := randi_range(5, 30)
					var b := randi_range(2, 9)
					var c := randi_range(2, 9)
					q = "%d + %d × %d = ?" % [a, b, c]
					ans = a + b * c
				_:
					var a := randi_range(2, 15)
					var b := randi_range(2, 15)
					var c := randi_range(2, 6)
					q = "(%d + %d) × %d = ?" % [a, b, c]
					ans = (a + b) * c
	var wrongs: Array = []
	var deltas := [1, -1, 2, -2, 10, -10, 3, 5]
	deltas.shuffle()
	for d in deltas:
		if ans + d >= 0:
			wrongs.append(str(ans + d))
	return _pack(q, str(ans), wrongs)
