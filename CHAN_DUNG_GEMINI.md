# Tạo chân dung khách hàng bằng Gemini

Khung trò chuyện ở quầy sẽ tự dùng ảnh chân dung thật nếu có file `art/khach_that/<mã>.png`. Chưa có thì game vẫn dùng hình khối như cũ.

## Cách làm

1. Mở Gemini, **đính kèm ảnh mẫu** `art/khach_that_goc/khach_xanh.png` (anh áo xanh) để giữ cùng một phong cách vẽ.
2. Dán câu lệnh chung bên dưới, rồi thêm phần mô tả của từng nhân vật.
3. Tải ảnh về, đặt tên đúng **mã nhân vật** (ví dụ `khach_den.png`), bỏ vào `art/khach_that_goc/`.
4. Tách nền: mở cmd trong thư mục dự án và chạy
   ```
   pip install rembg onnxruntime
   python tools/cat_nen_chan_dung.py
   ```
   Ảnh đã tách nền sẽ nằm trong `art/khach_that/`. Nếu không muốn tự chạy, gửi ảnh cho Claude để tách giúp.
5. Mở Godot là game tự dùng ảnh mới. Xuất lại APK.

Không bắt buộc: muốn nét mặt đổi theo độ hài lòng của khách, tạo thêm `<mã>_vui.png` (cười tươi) và `<mã>_buon.png` (lưỡng lự, hơi thất vọng) cho cùng nhân vật.

## Câu lệnh chung (dán trước mô tả từng nhân vật)

```
Vẽ một nhân vật theo đúng phong cách ảnh mẫu đính kèm: minh họa bán tả thực, nét vẽ sạch, đổ bóng mềm, tỉ lệ cơ thể và gương mặt chân thật, thân thiện. Nhân vật đứng, lấy từ đầu xuống giữa đùi, người hơi xoay sang phải, mắt nhìn sang phải. Không cầm đồ vật gì. Nền màu kem trơn (#F3E6CC), không chữ, không khung, không người khác. Ảnh dọc tỉ lệ 2:3, độ phân giải cao.
Nhân vật:
```

## Mô tả từng nhân vật (khớp với nhân vật đi trong shop)

| Mã file | Mô tả |
| --- | --- |
| `khach_xanh` | Thanh niên Việt Nam khoảng 25 tuổi, da ngăm, tóc ngắn đen, áo thun xanh dương trơn, quần kaki màu be, giày nâu. (Ảnh mẫu hiện tại đang cầm hộp quà; tạo lại bản không cầm gì nếu muốn đồng bộ.) |
| `khach_den` | Nam khoảng 28 tuổi, da vừa, tóc đen vuốt dựng, áo thun đen trơn, quần trắng, giày đen. |
| `khach_raglan` | Nam sinh viên khoảng 20 tuổi, da sáng, tóc nâu đen vuốt dựng, áo thun raglan thân trắng tay đỏ, quần jean xanh đậm, giày thể thao đỏ. |
| `khach_vang` | Nam khoảng 30 tuổi, da sáng, tóc ngắn nhuộm vàng, áo thun xanh lá, quần jean xanh, giày nâu. |
| `khach_hong` | Nữ khoảng 27 tuổi, da sáng, tóc dài nâu, áo dài tay màu hồng cánh sen và quần cùng màu, thắt lưng vàng. |
| `khach_do` | Nữ khoảng 24 tuổi, da vừa, tóc đỏ buộc đuôi ngựa, áo thun đỏ, quần jean xanh, giày màu cam nâu. |
| `khach_tim` | Nữ khoảng 30 tuổi, da sáng, tóc đen cắt bob ngang cằm, áo thun tím, chân váy vàng mù tạt, giày nâu. |
| `be_trai` | Bé trai khoảng 8 tuổi, da vừa, tóc ngắn đen, áo thun xanh lá, quần xanh navy, giày thể thao xanh dương. |
| `be_gai` | Bé gái khoảng 8 tuổi, da sáng, tóc buộc đuôi ngựa nhuộm xanh lá, áo thun hồng, chân váy xanh dương, giày đỏ. |
| `cong_tu` | Công tử nhà giàu khoảng 30 tuổi, tóc vuốt ngược bóng mượt, kính râm, bộ vest trắng, sơ mi hồng mở cổ, dây chuyền vàng to, thắt lưng vàng, giày da nâu. Dáng tự tin, hơi khoe mẽ, vui vẻ. |
| `dan_anh` | Đàn anh giang hồ khoảng 40 tuổi, đầu trọc, râu lún phún, vết sẹo nhỏ trên lông mày, áo ba lỗ trắng, hình xăm trên cánh tay, dây chuyền vàng, quần túi hộp xanh rêu. Vẻ mặt dữ nhưng hài hước, không đáng sợ. |
| `dan_anh_thuong` | Cùng người đàn anh ở trên nhưng vừa thua: mắt trái thâm tím, băng trắng quấn quanh đầu, má dán băng cá nhân, tay phải bó bột treo bằng dây đeo xanh, vẻ mặt cay cú hài hước. (Đính kèm luôn ảnh `dan_anh` để giữ đúng gương mặt.) |

Mẹo: nếu Gemini vẽ khác ảnh mẫu, nhắn thêm "giữ đúng phong cách và độ chi tiết của ảnh mẫu, chỉ đổi người và trang phục". Muốn bỏ dấu ngôi sao Gemini thì bật tắt watermark trong cài đặt Gemini (nếu gói của bạn hỗ trợ).
