extends RefCounted
## 600 từ vựng TOEIC theo thứ tự 50 bài (mỗi bài 12 từ) của sách "600 Essential Words for the TOEIC".
## Mỗi mục: [từ tiếng Anh, nghĩa tiếng Việt]. Nghĩa tiếng Việt do game tự soạn.

const LESSONS := [
	"Hợp đồng", "Tiếp thị", "Bảo hành", "Kế hoạch kinh doanh", "Hội nghị",
	"Máy tính", "Công nghệ văn phòng", "Thủ tục văn phòng", "Điện tử", "Thư từ",
	"Quảng cáo tuyển dụng", "Ứng tuyển và phỏng vấn", "Thuê và đào tạo", "Lương và phúc lợi", "Thăng chức, lương hưu, giải thưởng",
	"Mua sắm", "Đặt hàng vật tư", "Vận chuyển", "Hóa đơn", "Hàng tồn kho",
	"Ngân hàng", "Kế toán", "Đầu tư", "Thuế", "Báo cáo tài chính",
	"Bất động sản và phòng ban", "Họp hội đồng và ủy ban", "Kiểm tra chất lượng", "Phát triển sản phẩm", "Thuê nhà",
	"Chọn nhà hàng", "Ăn ngoài", "Gọi món trưa", "Nghề nấu ăn", "Sự kiện",
	"Du lịch chung", "Hàng không", "Tàu hỏa", "Khách sạn", "Thuê xe",
	"Phim ảnh", "Sân khấu", "Âm nhạc", "Bảo tàng", "Truyền thông",
	"Phòng khám bác sĩ", "Phòng khám nha khoa", "Bảo hiểm sức khỏe", "Bệnh viện", "Nhà thuốc",
]

const WORDS := [
	# 1 Hợp đồng
	["abide by", "tuân theo, chấp hành"], ["agreement", "sự thỏa thuận, hợp đồng"], ["assurance", "sự bảo đảm, cam đoan"],
	["cancellation", "sự hủy bỏ"], ["determine", "xác định, quyết định"], ["engage", "thuê, tham gia, cam kết"],
	["establish", "thành lập, thiết lập"], ["obligate", "bắt buộc, ràng buộc"], ["party", "bên (trong hợp đồng)"],
	["provision", "điều khoản, sự cung cấp"], ["resolve", "giải quyết"], ["specific", "cụ thể, riêng biệt"],
	# 2 Tiếp thị
	["attract", "thu hút, hấp dẫn"], ["compare", "so sánh"], ["competition", "sự cạnh tranh"],
	["consume", "tiêu thụ, tiêu dùng"], ["convince", "thuyết phục"], ["currently", "hiện nay, hiện tại"],
	["fad", "mốt nhất thời"], ["inspiration", "nguồn cảm hứng"], ["market", "thị trường; tiếp thị"],
	["persuasion", "sự thuyết phục"], ["productive", "năng suất, hiệu quả"], ["satisfaction", "sự hài lòng"],
	# 3 Bảo hành
	["characteristic", "đặc điểm, đặc trưng"], ["consequence", "hậu quả, kết quả"], ["consider", "cân nhắc, xem xét"],
	["cover", "bao gồm, chi trả (bảo hiểm)"], ["expire", "hết hạn"], ["frequently", "thường xuyên"],
	["imply", "ngụ ý, hàm ý"], ["promise", "lời hứa; hứa"], ["protect", "bảo vệ"],
	["reputation", "danh tiếng, uy tín"], ["require", "yêu cầu, đòi hỏi"], ["variety", "sự đa dạng, nhiều loại"],
	# 4 Kế hoạch kinh doanh
	["address", "giải quyết (vấn đề); địa chỉ"], ["avoid", "tránh"], ["demonstrate", "chứng minh, trình bày"],
	["develop", "phát triển"], ["evaluate", "đánh giá"], ["gather", "thu thập, tập hợp"],
	["offer", "đề nghị, cung cấp"], ["primarily", "chủ yếu, trước hết"], ["risk", "rủi ro"],
	["strategy", "chiến lược"], ["strong", "mạnh, vững"], ["substitution", "sự thay thế"],
	# 5 Hội nghị
	["accommodate", "chứa được, cung cấp chỗ ở"], ["arrangement", "sự sắp xếp"], ["association", "hiệp hội"],
	["attend", "tham dự"], ["get in touch", "liên lạc"], ["hold", "tổ chức, giữ"],
	["location", "địa điểm, vị trí"], ["overcrowded", "quá đông đúc"], ["register", "đăng ký"],
	["select", "chọn lựa"], ["session", "phiên, buổi họp"], ["take part in", "tham gia vào"],
	# 6 Máy tính
	["access", "truy cập; quyền truy cập"], ["allocate", "phân bổ"], ["compatible", "tương thích"],
	["delete", "xóa"], ["display", "hiển thị, trưng bày"], ["duplicate", "sao chép; bản sao"],
	["failure", "sự hỏng hóc, thất bại"], ["figure out", "tìm ra, hiểu ra"], ["ignore", "phớt lờ, bỏ qua"],
	["search", "tìm kiếm"], ["shut down", "tắt (máy), đóng cửa"], ["warning", "lời cảnh báo"],
	# 7 Công nghệ văn phòng
	["affordable", "giá phải chăng"], ["as needed", "khi cần thiết"], ["be in charge of", "phụ trách"],
	["capacity", "sức chứa, công suất"], ["durable", "bền"], ["initiative", "sáng kiến"],
	["physically", "về mặt thể chất"], ["provider", "nhà cung cấp"], ["recur", "tái diễn, lặp lại"],
	["reduction", "sự giảm bớt"], ["stay on top of", "nắm bắt kịp thời"], ["stock", "hàng trong kho; cổ phiếu"],
	# 8 Thủ tục văn phòng
	["appreciation", "sự đánh giá cao, cảm kích"], ["be made of", "được làm bằng"], ["bring in", "thuê, mang vào"],
	["casually", "một cách thoải mái, tùy ý"], ["code", "quy tắc, bộ luật"], ["expose", "phơi bày, tiếp xúc"],
	["glimpse", "cái nhìn thoáng qua"], ["out of", "hết, không còn"], ["outdated", "lỗi thời"],
	["practice", "thói quen, sự thực hành"], ["reinforce", "củng cố, tăng cường"], ["verbally", "bằng lời nói"],
	# 9 Điện tử
	["disk", "đĩa (lưu dữ liệu)"], ["facilitate", "tạo điều kiện thuận lợi"], ["network", "mạng lưới"],
	["popularity", "sự phổ biến"], ["process", "quy trình; xử lý"], ["replace", "thay thế"],
	["revolution", "cuộc cách mạng"], ["sharp", "sắc bén, nhanh nhạy"], ["skill", "kỹ năng"],
	["software", "phần mềm"], ["store", "lưu trữ; cửa hàng"], ["technically", "về mặt kỹ thuật"],
	# 10 Thư từ
	["assemble", "tập hợp, lắp ráp"], ["beforehand", "trước, sẵn từ trước"], ["complication", "sự phức tạp, rắc rối"],
	["courier", "người đưa thư, dịch vụ chuyển phát"], ["express", "nhanh, hỏa tốc; bày tỏ"], ["fold", "gấp lại"],
	["layout", "cách bố trí, bố cục"], ["mention", "đề cập"], ["petition", "đơn kiến nghị"],
	["proof", "bằng chứng; bản in thử"], ["register", "gửi bảo đảm, đăng ký"], ["revise", "sửa đổi, xem lại"],
	# 11 Quảng cáo tuyển dụng
	["abundant", "dồi dào, phong phú"], ["accomplishment", "thành tựu"], ["bring together", "tập hợp lại"],
	["candidate", "ứng viên"], ["come up with", "nghĩ ra"], ["commensurate", "tương xứng"],
	["match", "phù hợp, sánh được"], ["profile", "hồ sơ, sơ lược"], ["qualification", "bằng cấp, năng lực"],
	["recruit", "tuyển dụng"], ["submit", "nộp, đệ trình"], ["time-consuming", "tốn thời gian"],
	# 12 Ứng tuyển và phỏng vấn
	["ability", "khả năng"], ["apply", "nộp đơn, áp dụng"], ["background", "lý lịch, nền tảng"],
	["be ready for", "sẵn sàng cho"], ["call in", "mời đến, gọi đến"], ["confidence", "sự tự tin"],
	["constantly", "liên tục"], ["expert", "chuyên gia"], ["follow up", "theo dõi tiếp, liên lạc lại"],
	["hesitant", "do dự"], ["present", "trình bày, giới thiệu"], ["weakness", "điểm yếu"],
	# 13 Thuê và đào tạo
	["conduct", "tiến hành, thực hiện"], ["generate", "tạo ra"], ["hire", "thuê, tuyển"],
	["keep up with", "theo kịp"], ["look up to", "kính trọng, ngưỡng mộ"], ["mentor", "người cố vấn"],
	["on track", "đúng hướng, đúng tiến độ"], ["reject", "từ chối, loại bỏ"], ["set up", "thiết lập, sắp đặt"],
	["success", "sự thành công"], ["training", "sự đào tạo"], ["update", "cập nhật"],
	# 14 Lương và phúc lợi
	["basis", "nền tảng, cơ sở"], ["be aware of", "nhận thức được"], ["benefit", "lợi ích, phúc lợi"],
	["compensate", "bồi thường, trả công"], ["delicately", "một cách tế nhị"], ["eligible", "đủ điều kiện"],
	["flexibly", "một cách linh hoạt"], ["negotiate", "đàm phán, thương lượng"], ["raise", "sự tăng lương; nâng lên"],
	["retire", "nghỉ hưu"], ["vested", "được bảo đảm (quyền lợi)"], ["wage", "tiền công"],
	# 15 Thăng chức, lương hưu, giải thưởng
	["achievement", "thành tích"], ["contribute", "đóng góp"], ["dedication", "sự cống hiến, tận tụy"],
	["look forward to", "mong đợi"], ["look to", "trông cậy vào"], ["loyal", "trung thành"],
	["merit", "giá trị, công lao"], ["obviously", "rõ ràng"], ["productive", "có năng suất"],
	["promote", "thăng chức, quảng bá"], ["recognition", "sự công nhận"], ["value", "giá trị; coi trọng"],
	# 16 Mua sắm
	["bargain", "món hời; mặc cả"], ["bear", "chịu đựng, mang"], ["behavior", "hành vi, cách cư xử"],
	["checkout", "quầy thanh toán"], ["comfort", "sự thoải mái"], ["expand", "mở rộng"],
	["explore", "khám phá"], ["item", "món hàng, mục"], ["mandatory", "bắt buộc"],
	["merchandise", "hàng hóa"], ["strictly", "một cách nghiêm ngặt"], ["trend", "xu hướng"],
	# 17 Đặt hàng vật tư
	["diversify", "đa dạng hóa"], ["enterprise", "doanh nghiệp"], ["essentially", "về cơ bản"],
	["everyday", "hằng ngày, thông thường"], ["function", "chức năng"], ["maintain", "duy trì, bảo trì"],
	["obtain", "đạt được, có được"], ["prerequisite", "điều kiện tiên quyết"], ["quality", "chất lượng"],
	["smooth", "trôi chảy, êm"], ["source", "nguồn"], ["stationery", "văn phòng phẩm"],
	# 18 Vận chuyển
	["accurately", "một cách chính xác"], ["carrier", "hãng vận chuyển"], ["catalog", "danh mục, catalô"],
	["fulfill", "hoàn thành, đáp ứng"], ["integral", "không thể thiếu"], ["inventory", "hàng tồn kho"],
	["minimize", "giảm thiểu"], ["on hand", "có sẵn"], ["remember", "nhớ"],
	["ship", "gửi hàng, vận chuyển"], ["sufficiently", "một cách đầy đủ"], ["supply", "nguồn cung; cung cấp"],
	# 19 Hóa đơn
	["charge", "phí; tính phí"], ["compile", "biên soạn, tổng hợp"], ["customer", "khách hàng"],
	["discount", "giảm giá"], ["efficient", "hiệu quả"], ["estimate", "ước tính"],
	["impose", "áp đặt"], ["mistake", "lỗi, sai lầm"], ["order", "đơn hàng; đặt hàng"],
	["promptly", "ngay lập tức, đúng giờ"], ["rectify", "sửa chữa (lỗi)"], ["terms", "điều khoản"],
	# 20 Hàng tồn kho
	["adjustment", "sự điều chỉnh"], ["automatically", "một cách tự động"], ["crucial", "cực kỳ quan trọng"],
	["discrepancy", "sự chênh lệch, không khớp"], ["disturb", "làm phiền"], ["liability", "trách nhiệm pháp lý, khoản nợ"],
	["reflection", "sự phản ánh"], ["run", "điều hành, vận hành"], ["scan", "quét, xem lướt"],
	["subtract", "trừ đi"], ["tedious", "tẻ nhạt, chán ngắt"], ["verify", "xác minh"],
	# 21 Ngân hàng
	["accept", "chấp nhận"], ["balance", "số dư; sự cân bằng"], ["borrow", "vay, mượn"],
	["cautiously", "một cách thận trọng"], ["deduct", "khấu trừ"], ["dividend", "cổ tức"],
	["down payment", "tiền trả trước, đặt cọc"], ["mortgage", "khoản thế chấp"], ["restricted", "bị hạn chế"],
	["signature", "chữ ký"], ["take out", "rút (tiền), vay"], ["transaction", "giao dịch"],
	# 22 Kế toán
	["accounting", "kế toán"], ["accumulate", "tích lũy"], ["asset", "tài sản"],
	["audit", "kiểm toán"], ["budget", "ngân sách"], ["build up", "tăng dần, xây dựng"],
	["client", "khách hàng (dịch vụ)"], ["debt", "khoản nợ"], ["outstanding", "chưa thanh toán; nổi bật"],
	["profitably", "có lợi nhuận"], ["reconcile", "đối chiếu, điều hòa"], ["turnover", "doanh thu; tỷ lệ nghỉ việc"],
	# 23 Đầu tư
	["aggressively", "một cách mạnh bạo"], ["attitude", "thái độ"], ["commit", "cam kết"],
	["conservative", "bảo thủ, thận trọng"], ["fund", "quỹ"], ["invest", "đầu tư"],
	["long-term", "dài hạn"], ["portfolio", "danh mục đầu tư"], ["pull out", "rút ra, rút lui"],
	["resource", "nguồn lực, tài nguyên"], ["return", "lợi nhuận; trở lại"], ["wisely", "một cách khôn ngoan"],
	# 24 Thuế
	["calculate", "tính toán"], ["deadline", "hạn chót"], ["file", "nộp (hồ sơ); tập tin"],
	["fill out", "điền vào (mẫu đơn)"], ["give up", "từ bỏ"], ["joint", "chung, liên kết"],
	["owe", "nợ"], ["penalty", "tiền phạt, hình phạt"], ["preparation", "sự chuẩn bị"],
	["refund", "tiền hoàn lại"], ["spouse", "vợ hoặc chồng"], ["withhold", "giữ lại, khấu lưu"],
	# 25 Báo cáo tài chính
	["desired", "mong muốn"], ["detail", "chi tiết"], ["forecast", "dự báo"],
	["level", "mức, cấp độ"], ["overall", "tổng thể"], ["perspective", "góc nhìn, quan điểm"],
	["project", "dự kiến; dự án"], ["realistic", "thực tế"], ["target", "mục tiêu"],
	["translation", "sự chuyển đổi, bản dịch"], ["typically", "thường thì, điển hình"], ["yield", "lợi suất; mang lại"],
	# 26 Bất động sản và phòng ban
	["adjacent", "liền kề"], ["collaboration", "sự hợp tác"], ["concentrate", "tập trung"],
	["conducive", "có lợi, thuận lợi cho"], ["disrupt", "làm gián đoạn"], ["hamper", "cản trở"],
	["inconsiderately", "thiếu chu đáo, vô ý"], ["lobby", "sảnh"], ["move up", "thăng tiến, dời lên"],
	["open to", "sẵn sàng tiếp nhận"], ["opt", "chọn lựa"], ["scrutiny", "sự xem xét kỹ"],
	# 27 Họp hội đồng và ủy ban
	["adhere to", "tuân thủ, bám sát"], ["agenda", "chương trình nghị sự"], ["bring up", "nêu ra"],
	["conclude", "kết thúc, kết luận"], ["go ahead", "tiến hành"], ["goal", "mục tiêu"],
	["lengthy", "dài dòng"], ["matter", "vấn đề"], ["periodically", "định kỳ"],
	["priority", "sự ưu tiên"], ["progress", "sự tiến triển"], ["waste", "lãng phí"],
	# 28 Kiểm tra chất lượng
	["brand", "thương hiệu"], ["conform", "tuân theo, phù hợp"], ["defect", "khuyết điểm, lỗi"],
	["enhance", "nâng cao"], ["garment", "quần áo"], ["inspect", "kiểm tra, thanh tra"],
	["perceive", "nhận thấy"], ["repel", "đẩy lùi, chống thấm"], ["take back", "lấy lại, trả lại"],
	["throw out", "vứt bỏ"], ["uniformly", "đồng đều"], ["wrinkle", "nếp nhăn"],
	# 29 Phát triển sản phẩm
	["anxious", "lo lắng, nóng lòng"], ["ascertain", "xác định chắc chắn"], ["assume", "cho rằng, đảm nhận"],
	["decade", "thập kỷ"], ["examine", "kiểm tra, xem xét"], ["experiment", "thí nghiệm"],
	["logical", "hợp lý, logic"], ["research", "nghiên cứu"], ["responsibility", "trách nhiệm"],
	["solve", "giải quyết"], ["supervisor", "người giám sát"], ["systematically", "có hệ thống"],
	# 30 Thuê nhà
	["apprehensive", "e ngại, lo sợ"], ["circumstance", "hoàn cảnh"], ["condition", "điều kiện, tình trạng"],
	["due to", "do, bởi vì"], ["fluctuate", "dao động, biến động"], ["get out of", "thoát khỏi, rút khỏi"],
	["indicator", "chỉ số, dấu hiệu"], ["lease", "hợp đồng thuê; cho thuê"], ["lock into", "ràng buộc vào"],
	["occupy", "chiếm giữ, cư ngụ"], ["option", "sự lựa chọn"], ["subject to", "phụ thuộc vào, chịu"],
	# 31 Chọn nhà hàng
	["appeal", "sự hấp dẫn; lôi cuốn"], ["arrive", "đến nơi"], ["compromise", "sự thỏa hiệp"],
	["daringly", "một cách táo bạo"], ["familiar", "quen thuộc"], ["guide", "sách hướng dẫn; hướng dẫn"],
	["majority", "phần lớn, đa số"], ["mix", "trộn, pha trộn"], ["rely", "dựa vào, tin cậy"],
	["secure", "đạt được, bảo đảm"], ["subjective", "chủ quan"], ["suggestion", "lời gợi ý"],
	# 32 Ăn ngoài
	["basic", "cơ bản"], ["complete", "hoàn thành; đầy đủ"], ["excite", "kích thích, làm phấn khích"],
	["flavor", "hương vị"], ["forget", "quên"], ["ingredient", "nguyên liệu"],
	["judge", "đánh giá; giám khảo"], ["mix-up", "sự nhầm lẫn"], ["patron", "khách quen"],
	["predict", "dự đoán"], ["randomly", "ngẫu nhiên"], ["remind", "nhắc nhở"],
	# 33 Gọi món trưa
	["burden", "gánh nặng"], ["common", "phổ biến, chung"], ["delivery", "sự giao hàng"],
	["elegance", "sự thanh lịch"], ["fall to", "đến lượt, thuộc trách nhiệm"], ["impress", "gây ấn tượng"],
	["individual", "cá nhân, riêng lẻ"], ["list", "danh sách"], ["multiple", "nhiều"],
	["narrow", "thu hẹp; hẹp"], ["pick up", "nhận, đón, lấy"], ["settle", "giải quyết, thanh toán"],
	# 34 Nghề nấu ăn
	["accustom to", "làm quen với"], ["apprentice", "người học việc"], ["culinary", "thuộc về nấu nướng"],
	["demand", "nhu cầu; yêu cầu"], ["draw", "thu hút, lôi kéo"], ["incorporate", "kết hợp, sáp nhập"],
	["influx", "dòng chảy vào ồ ạt"], ["method", "phương pháp"], ["outlet", "cửa hàng bán lẻ, lối thoát"],
	["profession", "nghề nghiệp"], ["relinquish", "từ bỏ"], ["theme", "chủ đề"],
	# 35 Sự kiện
	["assist", "hỗ trợ"], ["coordinate", "phối hợp"], ["dimension", "kích thước, khía cạnh"],
	["exact", "chính xác"], ["general", "chung, tổng quát"], ["ideally", "lý tưởng nhất là"],
	["lead time", "thời gian chuẩn bị"], ["plan", "kế hoạch; lên kế hoạch"], ["proximity", "sự gần gũi (vị trí)"],
	["regulate", "điều chỉnh, quy định"], ["site", "địa điểm"], ["stage", "giai đoạn; sân khấu; dàn dựng"],
	# 36 Du lịch chung
	["agent", "đại lý, người đại diện"], ["announcement", "thông báo"], ["beverage", "đồ uống"],
	["blanket", "chăn; bao trùm"], ["board", "lên (tàu, xe, máy bay)"], ["claim", "nhận (hành lý); yêu cầu"],
	["delay", "sự trì hoãn"], ["embarkation", "sự lên tàu"], ["itinerary", "lịch trình chuyến đi"],
	["prohibit", "cấm"], ["valid", "có hiệu lực"], ["valuable", "có giá trị"],
	# 37 Hàng không
	["deal with", "giải quyết, xử lý"], ["destination", "điểm đến"], ["distinguish", "phân biệt"],
	["equivalent", "tương đương"], ["excursion", "chuyến tham quan ngắn"], ["expense", "chi phí"],
	["extend", "gia hạn, mở rộng"], ["prospective", "tiềm năng, sắp tới"], ["situation", "tình huống"],
	["substantially", "đáng kể"], ["system", "hệ thống"], ["travel", "đi lại, du lịch"],
	# 38 Tàu hỏa
	["comprehensive", "toàn diện"], ["deluxe", "sang trọng, cao cấp"], ["directory", "danh bạ, sổ chỉ dẫn"],
	["duration", "khoảng thời gian"], ["entitle", "cho quyền"], ["fare", "giá vé"],
	["offset", "bù đắp"], ["operate", "vận hành, hoạt động"], ["punctually", "đúng giờ"],
	["relatively", "tương đối"], ["remainder", "phần còn lại"], ["remote", "xa xôi, hẻo lánh"],
	# 39 Khách sạn
	["advance", "trước (đặt trước); sự tiến bộ"], ["chain", "chuỗi (khách sạn, cửa hàng)"], ["check in", "nhận phòng, làm thủ tục"],
	["confirm", "xác nhận"], ["expect", "mong đợi"], ["housekeeper", "nhân viên dọn phòng"],
	["notify", "thông báo"], ["preclude", "ngăn ngừa, loại trừ"], ["quote", "báo giá; trích dẫn"],
	["rate", "giá, mức phí"], ["reservation", "sự đặt chỗ"], ["service", "dịch vụ"],
	# 40 Thuê xe
	["busy", "bận rộn"], ["coincide", "trùng khớp"], ["confusion", "sự bối rối"],
	["contact", "liên hệ"], ["disappoint", "làm thất vọng"], ["intend", "dự định"],
	["license", "giấy phép"], ["nervous", "lo lắng, hồi hộp"], ["optional", "tùy chọn"],
	["tempt", "cám dỗ, lôi kéo"], ["thrill", "sự hồi hộp, phấn khích"], ["tier", "tầng, bậc"],
	# 41 Phim ảnh
	["attainment", "sự đạt được, thành tựu"], ["combine", "kết hợp"], ["continue", "tiếp tục"],
	["description", "sự mô tả"], ["disperse", "phân tán, giải tán"], ["entertainment", "sự giải trí"],
	["influence", "sự ảnh hưởng"], ["range", "phạm vi, loạt"], ["release", "phát hành"],
	["represent", "đại diện, thể hiện"], ["separately", "riêng biệt"], ["successive", "liên tiếp"],
	# 42 Sân khấu
	["action", "hành động"], ["approach", "tiếp cận; cách tiếp cận"], ["audience", "khán giả"],
	["create", "tạo ra"], ["dialogue", "lời thoại, đối thoại"], ["element", "yếu tố"],
	["experience", "kinh nghiệm, trải nghiệm"], ["occur", "xảy ra"], ["perform", "biểu diễn, thực hiện"],
	["rehearse", "diễn tập"], ["review", "bài phê bình; xem lại"], ["sell out", "bán hết"],
	# 43 Âm nhạc
	["available", "có sẵn"], ["broaden", "mở rộng"], ["category", "hạng mục, thể loại"],
	["disparate", "khác biệt hẳn"], ["divide", "phân chia"], ["favor", "ưu tiên, ủng hộ"],
	["instinct", "bản năng"], ["prefer", "thích hơn"], ["reason", "lý do"],
	["relaxation", "sự thư giãn"], ["taste", "khẩu vị, sở thích"], ["urge", "thôi thúc; sự thôi thúc"],
	# 44 Bảo tàng
	["acquire", "đạt được, mua lại"], ["admire", "ngưỡng mộ"], ["collection", "bộ sưu tập"],
	["criticism", "sự phê bình"], ["express", "bày tỏ, diễn đạt"], ["fashion", "thời trang; cách thức"],
	["leisure", "thời gian rảnh"], ["schedule", "lịch trình"], ["significant", "quan trọng, đáng kể"],
	["specialize", "chuyên về"], ["spectrum", "quang phổ, dải rộng"], ["unique", "độc nhất"],
	# 45 Truyền thông
	["assignment", "nhiệm vụ được giao"], ["choose", "chọn"], ["constant", "liên tục, không đổi"],
	["constitute", "cấu thành"], ["decisive", "quyết đoán, quyết định"], ["disseminate", "phổ biến, lan truyền"],
	["impact", "tác động"], ["in-depth", "chuyên sâu"], ["investigate", "điều tra"],
	["link", "liên kết"], ["subscribe", "đăng ký (dài hạn)"], ["thorough", "kỹ lưỡng"],
	# 46 Phòng khám bác sĩ
	["annually", "hằng năm"], ["appointment", "cuộc hẹn"], ["assess", "đánh giá"],
	["diagnose", "chẩn đoán"], ["effective", "có hiệu quả"], ["instrument", "dụng cụ"],
	["manage", "quản lý, xoay xở"], ["prevent", "ngăn chặn"], ["recommendation", "lời khuyên, sự giới thiệu"],
	["record", "hồ sơ; ghi lại"], ["refer", "giới thiệu đến, tham khảo"], ["serious", "nghiêm trọng"],
	# 47 Phòng khám nha khoa
	["aware", "nhận thức được"], ["catch up", "bắt kịp"], ["distraction", "sự xao nhãng"],
	["encouragement", "sự khích lệ"], ["evident", "hiển nhiên"], ["habit", "thói quen"],
	["illuminate", "chiếu sáng, làm sáng tỏ"], ["irritate", "làm khó chịu"], ["overview", "cái nhìn tổng quan"],
	["position", "vị trí, tư thế"], ["regularly", "đều đặn"], ["restore", "khôi phục"],
	# 48 Bảo hiểm sức khỏe
	["allow", "cho phép"], ["alternative", "sự thay thế, phương án khác"], ["aspect", "khía cạnh"],
	["concern", "mối quan tâm, lo ngại"], ["emphasize", "nhấn mạnh"], ["incur", "gánh chịu (chi phí)"],
	["personnel", "nhân sự"], ["policy", "chính sách, hợp đồng bảo hiểm"], ["portion", "phần"],
	["regardless", "bất kể"], ["salary", "lương"], ["suit", "phù hợp"],
	# 49 Bệnh viện
	["admit", "cho nhập viện, thừa nhận"], ["authorize", "ủy quyền, cho phép"], ["designate", "chỉ định"],
	["escort", "hộ tống"], ["identify", "nhận dạng"], ["mission", "sứ mệnh"],
	["permit", "cho phép; giấy phép"], ["pertinent", "thích hợp, liên quan"], ["procedure", "thủ tục"],
	["result", "kết quả"], ["statement", "bản kê khai, lời phát biểu"], ["usual", "thông thường"],
	# 50 Nhà thuốc
	["consult", "tham khảo ý kiến"], ["control", "kiểm soát"], ["convenient", "thuận tiện"],
	["detect", "phát hiện"], ["factor", "yếu tố"], ["interaction", "sự tương tác"],
	["limit", "giới hạn"], ["monitor", "theo dõi, giám sát"], ["potential", "tiềm năng, có thể"],
	["sample", "mẫu thử"], ["sense", "giác quan, cảm giác"], ["volunteer", "tình nguyện viên"],
]
