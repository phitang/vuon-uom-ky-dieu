"""Tạo hình nhân vật pixel art cho Shop cây cảnh.

Mỗi nhân vật là một dải 7 khung, mỗi khung 32 x 64 điểm ảnh:
  0 đứng yên (bình thường), 1 đứng yên (vui), 2 đứng yên (buồn),
  3-6 bốn khung bước đi.
Chạy:  python3 tools/tao_nhan_vat.py   (cần thư viện Pillow)
Kết quả nằm trong art/nguoi/. Muốn thêm nhân vật, thêm một mục vào CHARACTERS.
"""
import os
from PIL import Image

W, H = 32, 64
FRAMES = 7
OUT = os.path.join(os.path.dirname(__file__), "..", "art", "nguoi")
OUTLINE = (42, 30, 24, 255)


def hexc(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c[:3]) + (255,)


SKINS = {
    "sang": hexc("f6d3b3"),
    "vua": hexc("e8b88f"),
    "ngam": hexc("c98d62"),
}

CHARACTERS = {
    # id: tóc, màu tóc, da, áo, quần/váy, giày, kiểu áo, kiểu dưới, phụ kiện
    "ban_hang": dict(hair="ngan", hair_c="7a4a24", skin="sang", top="f4f1ea", bottom="2f4a7a",
                     shoes="5a3a22", top_style="thun", bottom_style="quan", apron="3e8a4a"),
    "khach_hong": dict(hair="dai", hair_c="6b3f22", skin="sang", top="d052a8", bottom="d052a8",
                       shoes="7a3a5a", top_style="dai_tay", bottom_style="quan", belt="f6c15c"),
    "khach_xanh": dict(hair="ngan", hair_c="2a1e18", skin="ngam", top="3a78d8", bottom="9a8a60",
                       shoes="4a3a2a", top_style="thun", bottom_style="quan"),
    "khach_do": dict(hair="duoi_ngua", hair_c="d0402a", skin="vua", top="d83a3a", bottom="4a6fb0",
                     shoes="c06a3a", top_style="thun", bottom_style="quan"),
    "khach_den": dict(hair="dung", hair_c="1e1a18", skin="vua", top="2a2a2e", bottom="e6e6e0",
                      shoes="2a2a2e", top_style="thun", bottom_style="quan"),
    "khach_raglan": dict(hair="dung", hair_c="2a1e18", skin="sang", top="f4f4f4", sleeve="d83a3a",
                         bottom="3a4f8a", shoes="d83a3a", top_style="raglan", bottom_style="quan"),
    "khach_tim": dict(hair="bob", hair_c="1e1a18", skin="sang", top="8a5ad0", bottom="f2c84a",
                      shoes="5a3a22", top_style="thun", bottom_style="vay"),
    "khach_vang": dict(hair="ngan", hair_c="e0b84a", skin="sang", top="4a9a4a", bottom="4a6fb0",
                       shoes="5a3a22", top_style="thun", bottom_style="quan"),
    "be_trai": dict(hair="ngan", hair_c="2a1e18", skin="vua", top="5aa83a", bottom="4a5a8a",
                    shoes="3a7ad0", top_style="thun", bottom_style="quan", kid=True),
    "be_gai": dict(hair="duoi_ngua", hair_c="3ab84a", skin="sang", top="e070a8", bottom="5a90d8",
                   shoes="d0402a", top_style="thun", bottom_style="vay", kid=True),
    # --- khách ẩn ---
    # công tử ăn chơi: vest trắng, sơ mi hồng, kính râm, dây chuyền vàng, tóc vuốt ngược
    "cong_tu": dict(hair="vuot", hair_c="2a1a12", skin="sang", top="f2eee4", shirt="f08ab0",
                    bottom="f2eee4", shoes="8a3a1a", top_style="vest", bottom_style="quan",
                    sunglasses=True, chain=True, belt="c89a3a"),
    # vệ sĩ: vest đen, cà vạt đen, kính râm, tai nghe, đầu húi cua
    "ve_si": dict(hair="troc", hair_c="1e1a18", skin="vua", top="24262c", shirt="f4f4f4", tie="111114",
                  bottom="24262c", shoes="111114", top_style="vest", bottom_style="quan",
                  sunglasses=True, earpiece=True),
    # đàn anh đòi tiền bảo kê: áo ba lỗ, hình xăm, đầu trọc, dây chuyền, râu lún phún
    "dan_anh": dict(hair="troc", hair_c="1e1a18", skin="ngam", top="f4f1ea", bottom="3a4a3a",
                    shoes="2a2a2a", top_style="ba_lo", bottom_style="quan", chain=True,
                    tattoo=True, beard=True, scar=True),
}


class Sprite:
    def __init__(self):
        self.img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        self.px = self.img.load()

    def put(self, x, y, c):
        if 0 <= x < W and 0 <= y < H:
            self.px[x, y] = c

    def rect(self, x0, y0, x1, y1, c, shaded=True):
        """Tô hình chữ nhật [x0..x1] x [y0..y1], tối ở mép phải, sáng ở mép trái."""
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                col = c
                if shaded and x1 - x0 >= 2:
                    if x >= x1 - 1:
                        col = shade(c, 0.78)
                    elif x == x0:
                        col = shade(c, 1.1)
                self.put(x, y, col)

    def outline(self):
        src = self.img.copy().load()
        for y in range(H):
            for x in range(W):
                if src[x, y][3] == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < W and 0 <= ny < H and src[nx, ny][3] > 0:
                            self.px[x, y] = OUTLINE
                            break


def draw_character(cfg, frame):
    s = Sprite()
    skin = SKINS[cfg["skin"]]
    hair = hexc(cfg["hair_c"])
    top = hexc(cfg["top"])
    bottom = hexc(cfg["bottom"])
    shoes = hexc(cfg["shoes"])
    sleeve = hexc(cfg.get("sleeve", cfg["top"]))
    kid = cfg.get("kid", False)

    walk = frame - 3 if frame >= 3 else -1
    lift_l = walk == 0          # chân trái nhấc
    lift_r = walk == 2          # chân phải nhấc
    bob = 1 if walk in (1, 3) else 0   # khung giữa bước: người nhô lên 1 điểm

    # trẻ em: thân ngắn hơn, đầu giữ nguyên
    leg_top = 41 if not kid else 45
    torso_top = 23 if not kid else 29
    head_top = 5 if not kid else 11
    oy = -bob

    # --- tóc dài phía sau ---
    if cfg["hair"] == "dai":
        s.rect(8, head_top + 6 + oy, 23, torso_top + 12 + oy, hair)
    # --- chân ---
    foot_y = 62
    for side, lifted in (("l", lift_l), ("r", lift_r)):
        x0, x1 = (10, 14) if side == "l" else (17, 21)
        end = foot_y - 4 - (3 if lifted else 0)
        if cfg["bottom_style"] == "vay":
            s.rect(x0 + 1, leg_top + 6 + oy, x1 - 1, end, skin)
        else:
            s.rect(x0, leg_top + oy, x1, end, bottom)
        sx0 = x0 - 1 if side == "l" else x0
        sx1 = x1 if side == "l" else x1 + 1
        s.rect(sx0, end + 1, sx1, end + 4, shoes)
    if cfg["bottom_style"] == "vay":
        s.rect(8, leg_top - 1 + oy, 23, leg_top + 7 + oy, bottom)
    else:
        s.rect(10, leg_top + oy, 21, leg_top + 4 + oy, bottom)

    # --- thân ---
    s.rect(9, torso_top + oy, 22, leg_top + oy, top)
    s.rect(10, torso_top - 1 + oy, 21, torso_top - 1 + oy, top, shaded=False)
    if cfg.get("belt"):
        s.rect(9, leg_top - 1 + oy, 22, leg_top + oy, hexc(cfg["belt"]), shaded=False)
    elif cfg["bottom_style"] == "quan":
        s.rect(10, leg_top + oy, 21, leg_top + oy, shade(bottom, 0.7), shaded=False)
    if cfg.get("apron"):
        ap = hexc(cfg["apron"])
        s.rect(11, torso_top + 4 + oy, 20, leg_top + 6 + oy, ap)
        s.rect(13, torso_top + 9 + oy, 18, torso_top + 12 + oy, shade(ap, 0.8), shaded=False)
    # cổ áo
    s.rect(14, torso_top + oy, 17, torso_top + 1 + oy, skin, shaded=False)
    t0 = torso_top + oy
    if cfg["top_style"] == "ba_lo":       # áo ba lỗ: lộ vai, cổ khoét sâu
        s.rect(9, t0 - 1, 11, t0 + 2, skin, shaded=False)
        s.rect(20, t0 - 1, 22, t0 + 2, skin, shaded=False)
        s.rect(13, t0, 18, t0 + 2, skin, shaded=False)
        s.rect(14, t0 + 3, 17, t0 + 3, skin, shaded=False)
    if cfg["top_style"] == "vest":        # vest: chữ V sơ mi, ve áo, cà vạt, khuy
        shirt = hexc(cfg.get("shirt", "ffffff"))
        for i in range(8):
            w = max(0, 3 - i // 2)
            s.rect(15 - w, t0 + i, 16 + w, t0 + i, shirt, shaded=False)
            s.put(14 - w, t0 + i, shade(top, 0.7))
            s.put(17 + w, t0 + i, shade(top, 0.7))
        if cfg.get("tie"):
            tie = hexc(cfg["tie"])
            s.rect(15, t0 + 1, 16, t0 + 9, tie, shaded=False)
            s.put(15, t0 + 10, tie)
        else:
            s.rect(14, t0, 17, t0 + 1, skin, shaded=False)   # sơ mi mở cổ
        for by in (t0 + 11, t0 + 14):
            s.put(15, by, shade(top, 0.6))
    if cfg.get("chain"):                  # dây chuyền vàng
        gold = hexc("f2c230")
        for x, y in ((13, 1), (14, 2), (15, 3), (16, 3), (17, 2), (18, 1)):
            s.put(x, t0 + y, gold)
        s.rect(15, t0 + 4, 16, t0 + 5, hexc("ffe27a"), shaded=False)

    # --- tay (vung nhẹ khi đi) ---
    arm_len = 14 if not kid else 12
    for side in ("l", "r"):
        x0, x1 = (6, 8) if side == "l" else (23, 25)
        swing = 0
        if walk == 0:
            swing = -2 if side == "r" else 1
        elif walk == 2:
            swing = -2 if side == "l" else 1
        y0 = torso_top + oy
        y1 = y0 + arm_len + swing
        sleeve_end = y0 + (5 if cfg["top_style"] not in ("dai_tay", "vest") else arm_len - 2) + 0
        if cfg["top_style"] == "ba_lo":
            sleeve_end = y0
        s.rect(x0, y0 + 1, x1, min(sleeve_end, y1), sleeve)
        if sleeve_end < y1:
            s.rect(x0, sleeve_end + 1, x1, y1, skin)
        s.rect(x0, y1 + 1, x1, y1 + 2, skin, shaded=False)
        if cfg["top_style"] in ("dai_tay", "vest"):
            s.rect(x0, y1 - 1, x1, y1 - 1, shade(sleeve, 0.8), shaded=False)
        if cfg["top_style"] == "vest" and cfg.get("shirt"):
            s.rect(x0, y1, x1, y1, hexc(cfg["shirt"]), shaded=False)   # cổ tay sơ mi
        if cfg.get("tattoo"):              # hình xăm trên bắp tay
            ink = hexc("2f4a6a")
            s.put(x0, y0 + 3, ink); s.put(x0 + 1, y0 + 4, ink); s.put(x0 + 2, y0 + 3, ink)
            s.put(x0 + 1, y0 + 6, ink); s.put(x0, y0 + 7, ink); s.put(x0 + 2, y0 + 7, ink)
            s.put(x0 + 1, y0 + 8, hexc("b83a3a"))

    # --- đầu ---
    hy = head_top + oy
    s.rect(14, hy + 15, 17, hy + 17, shade(skin, 0.9), shaded=False)   # cổ
    s.rect(10, hy + 2, 21, hy + 14, skin)
    s.rect(11, hy + 1, 20, hy + 1, skin, shaded=False)
    s.rect(11, hy + 15, 20, hy + 15, skin, shaded=False)

    # --- tóc ---
    style = cfg["hair"]
    if style == "troc":                   # đầu húi cua / trọc: chỉ một lớp tóc lún phún
        s.rect(11, hy, 20, hy + 1, skin, shaded=False)
        stub = shade(skin, 0.72) if cfg["hair_c"] == "1e1a18" else hair
        s.rect(11, hy - 1, 20, hy, stub, shaded=False)
        s.rect(10, hy + 1, 10, hy + 4, stub, shaded=False)
        s.rect(21, hy + 1, 21, hy + 4, stub, shaded=False)
        s.put(13, hy, shade(skin, 1.15))
    else:
        s.rect(10, hy - 1, 21, hy + 3, hair)
        s.rect(11, hy - 2, 20, hy - 2, hair, shaded=False)
    if style == "vuot":                   # tóc vuốt ngược bóng mượt
        s.rect(10, hy + 4, 10, hy + 6, hair, shaded=False)
        s.rect(21, hy + 4, 21, hy + 6, hair, shaded=False)
        s.rect(11, hy - 3, 19, hy - 3, hair, shaded=False)
        s.rect(13, hy - 2, 17, hy - 2, shade(hair, 1.9), shaded=False)
    if style in ("ngan", "dung", "duoi_ngua"):
        s.rect(10, hy + 4, 10, hy + 7, hair, shaded=False)
        s.rect(21, hy + 4, 21, hy + 7, hair, shaded=False)
        s.rect(12, hy + 4, 15, hy + 4, hair, shaded=False)   # mái
    if style == "dung":
        for i, x in enumerate(range(10, 22, 3)):
            s.put(x, hy - 3 - (i % 2), hair)
            s.put(x + 1, hy - 3, hair)
    if style in ("dai", "bob"):
        s.rect(9, hy + 1, 10, hy + 13, hair)
        s.rect(21, hy + 1, 22, hy + 13, hair)
        s.rect(11, hy + 4, 20, hy + 4, hair, shaded=False)
    if style == "bob":
        s.rect(8, hy + 9, 9, hy + 13, hair)
        s.rect(22, hy + 9, 23, hy + 13, hair)
    if style == "duoi_ngua":
        s.rect(22, hy + 2, 24, hy + 5, hair)
        s.rect(23, hy + 6, 25, hy + 15, hair)
        s.put(22, hy + 1, shade(hexc("ffffff"), 0.95))

    # --- mặt ---
    ey = hy + 8
    eye = (40, 30, 26, 255)
    s.rect(12, ey, 13, ey + 1, eye, shaded=False)
    s.rect(18, ey, 19, ey + 1, eye, shaded=False)
    s.put(12, ey, (255, 255, 255, 255))
    s.put(18, ey, (255, 255, 255, 255))
    brow = shade(hair, 0.85)
    s.rect(12, ey - 2, 13, ey - 2, brow, shaded=False)
    s.rect(18, ey - 2, 19, ey - 2, brow, shaded=False)
    s.put(15, ey + 2, shade(skin, 0.85))
    s.put(16, ey + 2, shade(skin, 0.85))
    my = ey + 4
    mouth = (150, 60, 50, 255)
    mood = 1 if frame == 1 else (-1 if frame == 2 else 0)
    if mood > 0:
        s.rect(14, my, 17, my, mouth, shaded=False)
        s.put(13, my - 1, mouth)
        s.put(18, my - 1, mouth)
    elif mood < 0:
        s.rect(14, my - 1, 17, my - 1, mouth, shaded=False)
        s.put(13, my, mouth)
        s.put(18, my, mouth)
    else:
        s.rect(14, my, 17, my, mouth, shaded=False)
    # má hồng
    s.put(11, ey + 3, shade(hexc("f08080"), 1.0))
    s.put(20, ey + 3, shade(hexc("f08080"), 1.0))
    if cfg.get("beard"):                  # râu lún phún
        bc = shade(skin, 0.7)
        for x in (12, 14, 16, 18, 19):
            s.put(x, my + 2, bc)
        for x in (13, 15, 17):
            s.put(x, my + 1 if x != 15 else my + 2, bc)
        s.put(11, my, bc); s.put(20, my, bc)
    if cfg.get("scar"):                   # vết sẹo trên mày
        sc = shade(skin, 0.75)
        s.put(19, ey - 3, sc); s.put(20, ey - 2, sc); s.put(19, ey - 1, sc)
    if cfg.get("sunglasses"):             # kính râm
        glass = (24, 24, 30, 255)
        s.rect(11, ey - 1, 14, ey + 1, glass, shaded=False)
        s.rect(17, ey - 1, 20, ey + 1, glass, shaded=False)
        s.rect(15, ey - 1, 16, ey - 1, glass, shaded=False)
        s.rect(10, ey - 1, 10, ey - 1, glass, shaded=False)
        s.rect(21, ey - 1, 21, ey - 1, glass, shaded=False)
        s.put(12, ey - 1, (130, 150, 190, 255))
        s.put(18, ey - 1, (130, 150, 190, 255))
    if cfg.get("earpiece"):               # tai nghe vệ sĩ, dây xoắn xuống cổ áo
        s.put(20, ey + 2, (30, 30, 34, 255))
        for k in range(3, 8):
            s.put(20, ey + k, (190, 196, 210, 255))

    s.outline()
    return s.img


import sys
ONLY = [a for a in sys.argv[1:] if a in CHARACTERS]   # chỉ tạo các nhân vật được ghi tên (bỏ trống: tạo hết)


def _ids():
    return ONLY if ONLY else list(CHARACTERS)


def main():
    os.makedirs(OUT, exist_ok=True)
    for cid in _ids():
        cfg = CHARACTERS[cid]
        sheet = Image.new("RGBA", (W * FRAMES, H), (0, 0, 0, 0))
        for f in range(FRAMES):
            sheet.paste(draw_character(cfg, f), (f * W, 0))
        sheet.save(os.path.join(OUT, cid + ".png"))
    print("Đã tạo", len(_ids()), "nhân vật trong", os.path.abspath(OUT))


if __name__ == "__main__":
    main()


# ---------------------------------------------------------------------------
# Chân dung độ phân giải cao cho màn hình trò chuyện ở quầy (art/nguoi_hd/).
# Lấy 3 khung nét mặt (0, 1, 2), phóng to 8 lần bằng Scale2x (giữ đường chéo mượt),
# làm mảnh viền đen và làm mềm mép. Ánh sáng khối được thêm bằng shader trong game.
# ---------------------------------------------------------------------------
def scale2x(img):
    import numpy as np
    a = np.array(img)
    h, w = a.shape[:2]
    p = np.pad(a, ((1, 1), (1, 1), (0, 0)), mode="edge")
    B = p[0:h, 1:w + 1]
    D = p[1:h + 1, 0:w]
    E = p[1:h + 1, 1:w + 1]
    F = p[1:h + 1, 2:w + 2]
    H = p[2:h + 2, 1:w + 1]
    eq = lambda x, y: np.all(x == y, axis=2)
    cond = ~eq(B, H) & ~eq(D, F)
    E0 = np.where((cond & eq(D, B))[..., None], D, E)
    E1 = np.where((cond & eq(B, F))[..., None], F, E)
    E2 = np.where((cond & eq(D, H))[..., None], D, E)
    E3 = np.where((cond & eq(H, F))[..., None], F, E)
    out = np.zeros((h * 2, w * 2, 4), dtype=a.dtype)
    out[0::2, 0::2] = E0
    out[0::2, 1::2] = E1
    out[1::2, 0::2] = E2
    out[1::2, 1::2] = E3
    return Image.fromarray(out, "RGBA")


def make_portrait(frame_img):
    import numpy as np
    from scipy import ndimage as nd
    im = frame_img
    for _ in range(3):
        im = scale2x(im)                     # 32x64 -> 256x512
    a = np.array(im).astype(float)
    alpha = a[..., 3] > 0
    is_outline = np.all(a[..., :3] == np.array(OUTLINE[:3]), axis=2) & alpha
    # viền ngoài: chỉ giữ 3 điểm ảnh sát vào trong, phần còn lại bỏ đi cho viền mảnh
    dist_out = nd.distance_transform_edt(alpha)
    a[..., 3][is_outline & (dist_out <= 5)] = 0
    # viền trong (giữa các mảng màu): làm dịu màu đen thành nâu sẫm trong suốt một phần
    inner = is_outline & (dist_out > 5)
    a[..., :3][inner] = a[..., :3][inner] * 0.6 + np.array([60, 40, 30]) * 0.4
    # mép mềm
    al = a[..., 3] / 255.0
    al = nd.gaussian_filter(al, 0.9)
    a[..., 3] = np.clip(al * 255 * 1.15, 0, 255)
    for ch in range(3):
        a[..., ch] = nd.gaussian_filter(a[..., ch], 0.6)
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def make_portraits():
    out_dir = os.path.join(OUT, "..", "nguoi_hd")
    os.makedirs(out_dir, exist_ok=True)
    for cid in _ids():
        cfg = CHARACTERS[cid]
        sheet = Image.new("RGBA", (W * 8 * 3, H * 8), (0, 0, 0, 0))
        for f in range(3):
            sheet.paste(make_portrait(draw_character(cfg, f)), (f * W * 8, 0))
        sheet.save(os.path.join(out_dir, cid + ".png"), optimize=True)
    print("Đã tạo chân dung trong", os.path.abspath(out_dir))


if __name__ == "__main__":
    make_portraits()
