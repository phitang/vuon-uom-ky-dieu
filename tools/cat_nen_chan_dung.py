"""Tách nền chân dung khách hàng (ảnh tạo bằng Gemini) để dùng trong khung trò chuyện ở quầy.

Cách dùng:
  1. Bỏ ảnh gốc vào art/khach_that_goc/, đặt tên đúng mã nhân vật, ví dụ khach_xanh.png
     (thêm _vui / _buon nếu có ảnh vẻ mặt vui / không vui: khach_xanh_vui.png, khach_xanh_buon.png).
  2. Chạy:  pip install rembg onnxruntime   (một lần)
            python tools/cat_nen_chan_dung.py
  3. Ảnh đã tách nền nằm ở art/khach_that/. Mở Godot là game tự dùng.
"""
import os
import sys

from PIL import Image
from rembg import new_session, remove

GOC = "art/khach_that_goc"
RA = "art/khach_that"
CAO_TOI_DA = 900   # chiều cao tối đa (điểm ảnh) sau khi cắt


def main():
    os.makedirs(RA, exist_ok=True)
    chi = set(sys.argv[1:])
    session = new_session("u2net")
    for ten in sorted(os.listdir(GOC)):
        goc, duoi = os.path.splitext(ten)
        if duoi.lower() not in (".png", ".jpg", ".jpeg", ".webp") or (chi and goc not in chi):
            continue
        im = Image.open(os.path.join(GOC, ten)).convert("RGBA")
        cat = remove(im, session=session)
        # bỏ viền mờ còn sót, cắt sát người
        a = cat.getchannel("A").point(lambda v: 0 if v < 24 else v)
        cat.putalpha(a)
        box = a.getbbox()
        if box:
            cat = cat.crop(box)
        if cat.height > CAO_TOI_DA:
            w = round(cat.width * CAO_TOI_DA / cat.height)
            cat = cat.resize((w, CAO_TOI_DA), Image.LANCZOS)
        cat.save(os.path.join(RA, goc + ".png"))
        print("Đã tách nền:", goc, cat.size)


if __name__ == "__main__":
    main()
