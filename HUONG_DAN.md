# Vườn Ươm Kỳ Diệu — hướng dẫn

Dự án Godot 4 cho game trồng và lai giống cây trên Android, làm theo tài liệu thiết kế "Thiết kế game: Vườn Ươm Kỳ Diệu".

## 1. Mở và chơi thử trên máy tính

1. Tải **Godot 4.3 trở lên**, bản *Standard* (không cần bản .NET), tại godotengine.org. Giải nén là chạy được, không cần cài.
2. Mở Godot → **Import** → chọn file `project.godot` trong thư mục này → **Import & Edit**.
3. Nhấn **F5** (hoặc nút ▶ góc trên bên phải) để chơi. Dùng chuột như ngón tay. Game chơi theo màn hình **ngang**.

**Cách chơi:**
- Chậu trống cần có đất: chạm chọn chậu, rồi bấm **túi đất** ở hàng dụng cụ. Túi luôn cho loại đất tốt nhất bạn đã mua và đổi hình theo loại đó (bao vàng nhãn xẻng: thường; bao xanh nhãn mầm cây: tốt; bao tím nhãn viên ngọc: hiếm). Bán cây, bỏ cây, thu hạt xong hoặc mua chậu mới thì chậu hết đất, phải cho đất lại.
- **Kéo** một hạt trong *Túi hạt* thả vào chậu có đất để gieo (chậu nhận được sẽ sáng xanh khi đang kéo). Sau đó **tưới nước** thì hạt mới bắt đầu lớn.
- Mỗi loài hoa có hình hạt riêng (hạt hồng nâu đỏ, cúc tròn sậm, sao 3 hạt đen dẹp, tulip là củ có rễ, chuông dẹp dài, lan tròn nhỏ, sen vàng nâu, rồng là củ tím có mầm đỏ). Hạt quý hiếm phát sáng nhẹ: xanh dương = Hiếm, tím = Quý, vàng = Huyền thoại.
- **Túi hạt** có 8 ô. Chạm để chọn hạt, **lướt ngang** trong khung để sang trang khác (chấm dưới khung cho biết đang ở trang nào). Túi đầy thì không mua, lai hay thu thêm hạt được; mua **Túi hạt thêm** ở mục Vật tư (1.000 xu, thêm 8 ô, tối đa 6 túi).
- Chạm vào cây để chọn, rồi bấm dụng cụ: bình tưới (bình nghiêng đổ nước vào chậu), bao phân (hồi 35% sức khỏe; cây chưa ra hoa còn lớn nhanh hơn), kéo (thu hạt khi cây già, có hoạt ảnh kéo cắt quanh bông hoa), túi đất (bao đất đặt cạnh chậu, xẻng xúc đất đổ vào).
- Đất kém hơn cây cần: thiếu 1 cấp mất hết sức khỏe trong 10 giờ, thiếu 2 cấp trong 4 giờ, và cây không tự hồi sức khỏe; phải bón phân (`HEALTH_SOIL_LOSS`, `FERTILIZER_HEAL` trong `data.gd`).
- **Súng thụ phấn:** kéo súng thả vào cây đang ra hoa để nạp phấn, súng tự quay về hàng dụng cụ (bình phấn sáng vàng). Kéo súng lần nữa tới cây ra hoa thứ hai để thụ phấn (20 xu). Thả súng lại vào chính cây vừa lấy phấn là **tự thụ phấn**: 3 hạt ra giống hệt cây đó. Cây đang kết hạt vẫn cho phấn được. Bấm vào súng đang có phấn để bỏ phấn.
- Cây được thụ phấn kết 3 hạt lai **giống hệt nhau**, cứ 5 phút một hạt. Tỉ lệ ra kiểu hiếm tăng theo độ hiếm của cây bố mẹ (đột biến: 2% + 3% cho mỗi bậc hiếm của bố và mẹ, `MUTATION_PER_RARITY` trong `data.gd`). Có hạt thì cạnh chậu hiện ký hiệu hạt màu cam kèm số hạt: chạm vào cây để thu. Cây đang kết hạt chưa trưng bày được. Thời gian 5 phút và số hạt nằm ở `SEED_POD_INTERVAL`, `SEEDS_PER_CROSS` trong `data.gd`.
- Thanh NƯỚC và SỨC KHỎE nằm hai bên thông tin cây. Sức khỏe giảm khi hết nước (cây càng hiếm giảm càng nhanh) và khi đất kém hơn cây cần: cây Hiếm cần Đất tốt, cây Quý và Huyền thoại cần Đất hiếm. Dưới một nửa là héo (giá giảm một nửa), hết là chết.
- Đất tốt (50.000 xu) và Đất hiếm (200.000 xu) mua một lần ở mục Vật tư là dùng mãi.
- Bấm vào **ô Giá** để chỉnh giá cây (50%–300% giá thị trường). Bấm **Trưng bày** để đưa cây ra Shop cây cảnh; chậu trong nhà kính hiện biểu tượng cửa hàng. Cây chưa ra hoa (từ giai đoạn Cây non) vẫn trưng bày được nhưng chỉ được 50% giá cây đang ra hoa; game hỏi "Đồng ý / Từ chối" trước (`YOUNG_SELL_RATIO` trong `data.gd`).
- **Shop cây**: sân có nhà kính ở giữa, người bán đứng sau quầy. Khách lần lượt vào xem các cây trên gốc trưng bày. Khách nào ra đứng ở quầy thì mở giao diện trò chuyện mua cây: chọn cách trả lời khéo để khách mua. Cây bán rồi hiện "ĐÃ BÁN". Chạm vào cây trên gốc để chỉnh giá. Chạm vào **nhà kính** giữa sân (hoặc nút **Về vườn**): cây chưa bán trở lại chậu cũ.
- **Bán hạt:** trong Vật tư bấm "Túi hạt" ở ô Bán hạt, chạm chọn một hạt rồi chọn Bán hoặc Không. Giá: Thường 5, Hiếm 15, Quý 30, Huyền thoại 50 xu (`SEED_SELL_PRICE`).
- **Trang trí Shop cây:** chạm vào **bảng hiệu ở cổng** để đổi tên shop. Nút **Trang trí** ở góc trên bên phải mở cửa hàng: nâng cấp bảng hiệu, quầy tính tiền, hàng rào (mỗi loại 3 bậc) và 8 món trang trí (chuông gió, đèn lồng, bồn hoa, ghế đá, bàn ô dù, xích đu, tượng thỏ đá, cối xay gió). Mỗi bậc/món cộng 1 điểm **sức hút**: khách tới nhanh hơn 5% (tối đa gấp đôi) và dễ mua hơn 1% (tối đa 12%).
- **Khách ẩn** (người chơi không được báo trước):
  - **Công tử ăn chơi** tới khi mọi cây đang bày bán đều Quý (hoặc hơn), và tới thêm một lần khi mọi cây đều Huyền thoại; mỗi mốc chỉ một lần. Khách thường vào xem 10 giây mà không mua, hai vệ sĩ vào đuổi hết khách, rồi công tử xem vài cây và ra quầy mua hết cây đang bày bán theo giá bạn đặt.
  - **Đàn anh đòi tiền bảo kê** tới khi shop không còn cây nào để bán quá 2 phút. Chọn "Đánh khứa này luôn" thì đấu **oẳn tù tì 3 ván** (hòa đánh lại): thắng cả 3 ván thì gã bị thâm mắt, bó bột tay, quấn băng bỏ chạy; thua 1/2/3 ván mất 10/20/50 xu (`BAO_KE_FIGHT_COST`); chọn "Đóng tiền bảo kê" thì mất 100 xu, gã khen "Ngoan lắm" rồi đi; chọn "Báo cảnh sát" thì gã bỏ đi.
  - Các con số (10 giây, 2 phút, 50 xu, 100 xu, số cây tối thiểu) nằm ở mục "Khách ẩn" trong `scripts/data.gd`. Hình nhân vật tạo bằng `tools/tao_nhan_vat.py cong_tu ve_si dan_anh dan_anh_thuong`.
- *Thùng rác* để bỏ cây. Menu dưới: Menu (cách chơi, chế độ thử nhanh, chơi lại), Vật tư, Sổ tay, Shop cây, nút ◀ ▶ để chuyển kệ.

**Chơi thử nhanh:** bấm **Menu** → bật **Chế độ thử nhanh** (1 phút thật = 1 giờ trong game). Nhớ tắt khi chơi thật.

## 2. Đưa game lên điện thoại Android (file APK)

Chỉ cần làm phần chuẩn bị một lần:

1. Cài **OpenJDK 17** (gợi ý bản Temurin).
2. Cài **Android Studio**, mở **SDK Manager** và cài: Platform-Tools, Build-Tools 34.0.0, Android 14 (API 34), Command-line Tools, CMake 3.10.2, NDK 23.2.8568313.
3. Trong Godot: **Editor → Editor Settings → Export → Android**, điền:
   - *Java SDK Path*: thư mục cài JDK 17
   - *Android Sdk Path*: thường là `%LOCALAPPDATA%\Android\Sdk` trên Windows
4. **Editor → Manage Export Templates → Download and Install** (tải bộ xuất bản đúng phiên bản Godot).

Xuất game:

1. **Project → Export**. Bản cài đặt sẵn tên *Android* đã có trong dự án.
2. Nếu Godot báo thiếu khóa ký (keystore) cho bản debug, làm theo nút gợi ý của Godot để tạo tự động.
3. Nhấn **Export Project** → bỏ chọn *Export With Debug* nếu muốn bản chính thức → lưu file `.apk`.
4. Chép file APK sang điện thoại và mở để cài (cho phép "cài ứng dụng không rõ nguồn gốc").

Cách nhanh hơn khi đang thử: bật *Gỡ lỗi USB* trên điện thoại, cắm cáp, rồi bấm biểu tượng Android ở góc trên bên phải Godot để cài thẳng lên máy.

Muốn phát hành lên Google Play cần tạo khóa ký bản phát hành (release keystore) và xuất file `.aab`. Xem tài liệu chính thức: "Exporting for Android" trên docs.godotengine.org.

## 3. Hình vẽ tay

Thư mục `art/` chứa hình màu nước cắt từ ảnh mẫu hoa cúc:

| File | Dùng cho |
| --- | --- |
| `art/chau_trong.png` | Chậu có đất, chưa có cây |
| `art/chau_khong_dat.png` | Chậu chưa có đất |
| `art/chung/0.png` | Hạt nảy mầm (mọi loài) |
| `art/chung/1.png` | Cây non (mọi loài) |
| `art/cuc/2.png` | Hoa cúc ra nụ |
| `art/cuc/3.png` | Hoa cúc nở (cây già dùng lại hình này, ngả màu nâu) |
| `art/hong/0.png` … `3.png` | Hoa hồng đủ 4 giai đoạn (hạt, cây non, ra nụ, nở). Cánh hồng đã chuyển sang trắng để game tô màu |
| `art/tulip/`, `art/chuong/`, `art/sao/`, `art/lan/`, `art/sen/`, `art/rong/` | Tulip, hoa chuông, hoa sao, lan hồ điệp, hoa sen, hoa rồng: `2.png` nụ xanh, `3.png` hoa nở (cánh trắng để tô màu). Hạt và cây non dùng hình chung |

Cánh hoa được vẽ màu trắng; game tự tô theo gen màu (vàng, đỏ, tím, xanh, cầu vồng...). Cả 8 loài hoa đều đã có hình vẽ tay. Nếu thêm loài mới mà chưa có hình, game tạm vẽ bằng code trong chậu vẽ tay.

**Thêm hình cho loài khác:** tạo ảnh cùng phong cách (cùng chậu đất nung, nền trắng, 4 chậu xếp hàng như ảnh mẫu), **cánh hoa màu trắng**, rồi gửi cho Claude để cắt. Hoặc tự cắt: mỗi giai đoạn một file PNG nền trong suốt, kích thước 300 × 542, chậu đặt đúng vị trí như `art/chau_trong.png`, lưu thành `art/<loài>/2.png` (nụ) và `art/<loài>/3.png` (nở). Có thể thêm `4.png` cho cây già.

Gợi ý câu lệnh tạo ảnh: *"Watercolor and ink botanical illustration, four identical terracotta pots in a row on a plain white background, showing the growth stages of a [white rose] plant: seed sprouting, young seedling, leafy plant with buds, full bloom with WHITE petals. Same pot size and position in every stage, soft shading, no text."*

## 4. Nhạc nền

| Nơi | Bài | File |
| --- | --- | --- |
| Nhà kính (trồng hoa) | Garden of Whispers | `music/vuon_garden_of_whispers.mp3` |
| Shop cây cảnh | Cozy Afternoon | `music/shop_cozy_afternoon.mp3` |

- Nhạc lặp liên tục. Khi vào hoặc rời Shop cây, bài cũ nhỏ dần và bài mới to dần; quay lại thì bài trước phát tiếp từ chỗ đang nghe dở.
- Menu có nút **Nhạc nền: BẬT/TẮT** và thanh **Âm lượng**; lựa chọn được nhớ cho lần chơi sau.
- Muốn đổi bài: chép file MP3 mới đè lên đúng tên file trên (hoặc sửa đường dẫn trong `scripts/music.gd`).

## 5. Cấu trúc dự án

| File | Nội dung |
| --- | --- |
| `scripts/data.gd` | Mọi con số của game: kiểu hoa, mức trội, độ hiếm, thời gian lớn, giá, cửa hàng, loại khách. **Chỉnh cân bằng game ở đây.** |
| `scripts/genetics.gd` | Hệ di truyền: gen trội/lặn, lai giống, đột biến, đặt tên giống |
| `scripts/game_state.gd` | Luật chơi: thời gian thực, tưới, bón, lai, giá thị trường, tỷ lệ khách mua, lưu game |
| `scripts/main.gd` | Giao diện chính: bảng điều khiển bên trái, dụng cụ, đặt giá, quầy bán hàng, Cửa hàng, Sổ tay, Menu |
| `scripts/nursery.gd` | Shop cây cảnh: sân đá, nhà kính giữa sân (chạm để về vườn), gốc trưng bày, quầy và người bán, khách đi xem và ra quầy mua |
| `scripts/greenhouse.gd` | Vẽ nhà kính: tường gỗ, cửa sổ, sàn đá, 3 kệ gỗ; xếp chậu lên kệ |
| `scripts/pot_slot.gd` | Một chỗ chậu trên kệ: chạm để chọn, vầng sáng khi chọn, biểu tượng khát nước / ra hoa / có hạt |
| `scripts/shop_decor_art.gd` | Vẽ bảng hiệu, quầy, hàng rào (4 bậc) và đồ trang trí Shop cây |
| `scripts/decor_preview.gd` | Hình xem trước trong cửa hàng trang trí |
| `scripts/music.gd` | Nhạc nền: chuyển bài mượt giữa vườn và shop, bật/tắt, âm lượng |
| `scripts/ui_skin.gd` | "Da" giao diện nổi khối: nút vát cạnh viền kim loại, băng tên, ô lõm, khung giấy da viền gỗ, nền gỗ (sinh bằng code) |
| `scripts/seed_art.gd` | Hình hạt theo loài hoa (hồng, cúc, sao, tulip, chuông, lan, sen, rồng); hạt Hiếm/Quý/Huyền thoại phát sáng xanh/tím/vàng |
| `scripts/seed_bag.gd` | Túi hạt: lưới 4 × 2 mỗi trang, chạm chọn, lướt đổi trang, kéo hạt ra để gieo |
| `scripts/vines.gd` | Dây leo trang trí quanh bảng trái |
| `fonts/Lora-700.ttf`, `fonts/Lora-500.ttf` | Phông chữ Lora (có tiếng Việt), giấy phép SIL OFL trong `fonts/OFL-Lora.txt` |
| `scripts/tool_icon.gd` | Biểu tượng dụng cụ vẽ bằng code: bình tưới, bao phân, kéo, súng thụ phấn, túi đất 3 loại |
| `scripts/water_anim.gd` | Hoạt ảnh bình tưới đổ nước vào chậu |
| `scripts/plant_view.gd` | Vẽ cây: dùng hình trong `art/` nếu có, nếu không thì vẽ bằng code |
| `scripts/plant_tint.gdshader` | Tô màu cánh hoa theo gen, làm cây ngả nâu khi héo/già/chết |
| `scripts/customer_view.gd` | Hiển thị nhân vật pixel (khách, người bán) từ `art/nguoi/`: 3 nét mặt, 4 khung bước đi, lật hình theo hướng đi |
| `tools/tao_nhan_vat.py` | Tạo lại hình nhân vật trong `art/nguoi/` (cần Python + Pillow). Thêm nhân vật mới bằng cách thêm một dòng vào `CHARACTERS` |
| `tests/` | Các cảnh kiểm tra tự động, không đưa vào bản APK |

Dữ liệu lưu ở `user://save.json` (trên điện thoại nằm trong bộ nhớ riêng của game).

## 6. Những gì đã có

- Cây lớn theo đồng hồ thật, cả khi tắt game (tối đa tính 7 ngày), bảng "Trong lúc bạn vắng mặt".
- 3 loại đất theo từng chậu, sức khỏe theo nước và độ hợp đất, hạt chỉ lớn sau lần tưới đầu; kéo thả hạt để gieo; phân bón; súng thụ phấn kéo thả, cây kết hạt lai dần theo thời gian.
- 5 bộ phận × gen trội/lặn, lai 2 cây ra hoa cho 3 hạt, 2% đột biến (tăng theo cấp vườn), 4 kiểu huyền thoại chỉ có qua đột biến; thu hạt từ cây già.
- Giá thị trường theo độ hiếm, giai đoạn, sức khỏe, nhu cầu trong ngày, số cây cùng giống đã bán.
- Tự đặt giá 50%–300%, quầy bán hàng: tối đa 5 khách, 4 loại khách, 3 cách trả lời, chỉ hiện mức Thấp / Vừa / Cao (không hiện %).
- Cửa hàng, cấp vườn theo doanh thu, Sổ tay có phần thưởng mốc và gợi ý huyền thoại.

## 7. Khác với tài liệu thiết kế / chưa làm

- "Giống được săn đón" làm theo **đặc điểm** (ví dụ hoa sao, màu tím) thay vì cả giống, vì với 5.760 giống thì hiếm khi trùng.
- Chưa có: **kệ trưng bày**, **thông báo đẩy Android** (cần thêm plugin), hiệu ứng âm thanh (tiếng tưới, tiếng xu...).
