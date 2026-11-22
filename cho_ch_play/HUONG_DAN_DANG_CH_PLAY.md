# Hướng dẫn đăng Vườn Ươm Kỳ Diệu lên CH Play

CH Play chỉ nhận tệp **.aab** (Android App Bundle) đã ký bằng khóa riêng. Tệp này phải xuất từ Godot trên máy tính của bạn vì cần Android SDK. Mọi thứ còn lại (khóa ký, ảnh, nội dung trang, chính sách quyền riêng tư) đã có sẵn trong gói này.

Cần chuẩn bị:
- Tài khoản nhà phát triển Google Play (phí 25 USD, trả 1 lần).
- Godot 4.7.2 (bạn đang dùng). Bản này mặc định nhắm Android 16 (API 36), đúng yêu cầu bắt buộc của CH Play hiện nay.
- JDK 17 và Android SDK. Nếu bạn đã từng xuất APK được thì máy đã có, chỉ cần cài thêm Android 16 ở bước 1.

---

## Phần A. Xuất tệp .aab trong Godot

### 1. Cài thêm Android 16 cho Android SDK
Mở **Android Studio → More Actions → SDK Manager**.
- Thẻ **SDK Platforms**: tích **Android 16 (API 36)**.
- Thẻ **SDK Tools**: tích **Android SDK Build-Tools** (bản mới nhất) và **Android SDK Command-line Tools**.

Bấm **Apply** để tải về. Nếu không có Android Studio, cài nó từ developer.android.com/studio.

### 2. Chép khóa ký vào máy
Chép thư mục `khoa_ky` (gồm `vuon_uom_upload.keystore` và `MAT_KHAU.txt`) vào một chỗ cố định trên máy, ví dụ `D:\khoa_ky\`. **Không** để trong thư mục dự án và không đưa lên GitHub.

Sao lưu thư mục này thêm 1–2 nơi (USB, Google Drive riêng). Mọi bản cập nhật game sau này đều phải ký bằng đúng khóa này.

### 3. Cài mẫu xây dựng Android
Trong Godot: **Project → Install Android Build Template… → Install**. Lệnh này tạo thư mục `android/` trong dự án.

### 4. Chỉnh bản xuất Android
**Project → Export…**, chọn mục **Android** rồi chỉnh:

| Mục | Giá trị |
| --- | --- |
| Gradle Build → Use Gradle Build | **Bật** |
| Gradle Build → Export Format | **Export AAB** |
| Gradle Build → Target SDK | để trống (mặc định 36) |
| Architectures → arm64-v8a | **Bật** (bắt buộc) |
| Architectures → armeabi-v7a | Bật |
| Keystore → Release | chọn `D:\khoa_ky\vuon_uom_upload.keystore` |
| Keystore → Release User | `vuonuom` |
| Keystore → Release Password | mật khẩu trong `MAT_KHAU.txt` |
| Version → Code | `1` (mỗi lần cập nhật sau tăng thêm 1: 2, 3, 4…) |
| Version → Name | `1.0` |
| Package → Unique Name | `com.vuonuom.kydieu` (**không đổi được** sau khi đã đăng) |
| Package → Name | `Vườn Ươm Kỳ Diệu` |
| Launcher Icons → Main 192×192 | `res://art/icon_192.png` |
| Launcher Icons → Adaptive Foreground 432×432 | `res://art/icon_fg_432.png` |
| Launcher Icons → Adaptive Background 432×432 | `res://art/icon_bg_432.png` |

### 5. Xuất tệp
Bấm **Export Project…**, **bỏ tích "Export With Debug"**, đặt tên `VuonUomKyDieu.aab` rồi bấm **Save**.

Lần đầu Godot sẽ tải các thư viện Gradle, mất khoảng 5–15 phút (cần có mạng). Xong sẽ có tệp `VuonUomKyDieu.aab`.

> Nếu báo lỗi về SDK hoặc Java: vào **Editor → Editor Settings → Export → Android** và kiểm tra **Android SDK Path** (thường là `C:\Users\<tên>\AppData\Local\Android\Sdk`) và **Java SDK Path** (thư mục JDK 17).

---

## Phần B. Đăng lên Google Play Console

### 1. Tạo ứng dụng
Vào play.google.com/console → **Tạo ứng dụng**:
- Tên: *Vườn Ươm Kỳ Diệu*
- Ngôn ngữ mặc định: *Tiếng Việt*
- Loại: *Trò chơi*
- Giá: *Miễn phí*

Tích đồng ý các cam kết rồi bấm Tạo.

### 2. Thiết lập "Nội dung ứng dụng"
Trong mục **Chính sách → Nội dung ứng dụng**, điền lần lượt như sau.

| Mục | Trả lời |
| --- | --- |
| Chính sách quyền riêng tư | `https://phitang.github.io/vuon-uom-ky-dieu/chinh-sach-rieng-tu.html` |
| Quảng cáo | Không, ứng dụng không chứa quảng cáo |
| Quyền truy cập ứng dụng | Mọi chức năng đều dùng được, không cần đăng nhập |
| Phân loại nội dung | Xem bảng bên dưới |
| Đối tượng mục tiêu | Chọn **13 tuổi trở lên** (13–15, 16–17, 18+) |
| An toàn dữ liệu | Không thu thập dữ liệu người dùng, không chia sẻ dữ liệu |
| Ứng dụng chính phủ / tài chính / sức khỏe / tin tức | Không |

**Vì sao chọn 13+:** nếu chọn cả trẻ dưới 13 tuổi, game phải theo thêm chính sách Gia đình, xét duyệt khắt khe hơn. Trẻ nhỏ vẫn tải và chơi được bình thường.

**Phân loại nội dung (bảng hỏi IARC):** chọn thể loại *Trò chơi*, rồi trả lời:

| Câu hỏi về | Trả lời |
| --- | --- |
| Bạo lực, máu, nội dung tình dục, ngôn từ thô tục, ma túy | **Không** |
| Cờ bạc, mua bán thật | **Không** |
| Người dùng tương tác / chia sẻ nội dung, vị trí | **Không** |
| Mua hàng kỹ thuật số | **Không** |

Cảnh "đánh nhau" với đàn anh chỉ là oẳn tù tì kèm lời thoại hài, không có hình ảnh bạo lực. Kết quả thường là mọi lứa tuổi hoặc 3+/7+.

### 3. Trang thông tin cửa hàng
Vào **Phát triển → Trang thông tin chính trong cửa hàng**:
- Dán tên, mô tả ngắn và mô tả đầy đủ từ `NOI_DUNG_TRANG_CH_PLAY.md`.
- Tải lên biểu tượng `icon_512.png`.
- Tải lên hình nổi bật `anh_noi_bat_1024x500.png`.
- Tải lên 6 ảnh trong `anh_chup/` vào phần *Ảnh chụp màn hình điện thoại*.
- Ở phần *Cài đặt cửa hàng*: thể loại *Mô phỏng*, điền email liên hệ của bạn.

### 4. Thử nghiệm kín (bắt buộc với tài khoản cá nhân mới)
Tài khoản cá nhân tạo sau 13/11/2023 phải chạy thử nghiệm kín với **ít nhất 12 người thử, liên tục 14 ngày** mới được xin phát hành chính thức.

1. Vào **Thử nghiệm → Thử nghiệm kín → Tạo bản phát hành**.
2. Nếu được hỏi, chọn **dùng Play App Signing** (để Google giữ khóa ký chính).
3. Tải lên `VuonUomKyDieu.aab`, ghi chú phiên bản (ví dụ "Bản thử nghiệm đầu tiên") rồi bấm **Lưu → Xem xét → Bắt đầu triển khai**.
4. Ở thẻ **Người thử nghiệm**, thêm email Gmail của ít nhất 12 người, nên mời 15–20 người cho chắc.
5. Gửi họ đường link tham gia. Họ bấm chấp nhận, tải game qua CH Play và giữ trong 14 ngày.

Trong thời gian này, nếu có cập nhật thì tăng **Version Code** lên 2, 3… rồi tải bản mới lên cùng track.

### 5. Xin phát hành chính thức
Sau đủ 14 ngày, vào **Bảng điều khiển → Đăng ký quyền truy cập phiên bản chính thức** và trả lời vài câu về quá trình thử nghiệm. Google xét duyệt khoảng vài ngày.

Khi được duyệt, vào **Phát hành → Phiên bản chính thức → Tạo bản phát hành**, chọn bản `.aab` đã thử rồi gửi xét duyệt (thường 1–7 ngày).

---

## Lưu ý pháp lý trước khi phát hành
- **Nhạc nền tạo bằng Suno:** chỉ được dùng thương mại nếu bài được tạo khi bạn đang dùng gói trả phí (Pro/Premier).
- **Ảnh tạo bằng Gemini:** dùng được, nhưng không ghi là vẽ tay.
- **Ghi công phần mềm:** đã có nút **Giới thiệu** ở màn hình chính, ghi Godot Engine (MIT), phông Lora (SIL OFL), hình AI và nhạc Suno.
- **Tên gọi:** không dùng tên "Plant Tycoon" hay tên game khác trên trang CH Play.
- **Phát hành tại Việt Nam:** nếu sau này có thu tiền (quảng cáo hoặc mua trong game), cần tìm hiểu quy định cấp phép trò chơi G4 theo Nghị định 147/2024, hỏi luật sư cho chắc.
