"""Tách nền trắng các ảnh Gemini của mini game (côn trùng, boss, hoa tròn)."""
import sys
sys.path.insert(0, 'tools')
from tach_nen import cut
from PIL import Image
import numpy as np
from scipy import ndimage

def objects(a, fg, min_area=3000):
    lab, n = ndimage.label(ndimage.binary_dilation(fg, iterations=6))
    res = []
    for sl, i in zip(ndimage.find_objects(lab), range(1, n + 1)):
        m = (lab[sl] == i) & fg[sl]
        if m.sum() < min_area:
            continue
        al = ndimage.gaussian_filter(m.astype(float), 0.7) * 255
        al[~ndimage.binary_erosion(m)] *= 0.6
        rgba = np.dstack([a[sl], al]).clip(0, 255).astype(np.uint8)
        cy = (sl[0].start + sl[0].stop) / 2
        res.append((round(cy / 200), sl[1].start, Image.fromarray(rgba, 'RGBA')))
    res.sort(key=lambda r: (r[0], r[1]))
    return [r[2] for r in res]

G = 'art/phong_thu_goc/'
jobs = [
    ('thuong.png', 'art/phong_thu/', ['sau', 'bo_xit', 'ret', 'chau_chau'], 220),
    ('boss.jpg', 'art/phong_thu/', ['boss_ret', 'boss_nhen', 'boss_ong'], 360),
    ('hoa_tron.jpg', 'art/minigame/', ['hong', 'huong_duong', 'violet', 'bim_bim', 'anh_dao', 'cuc', 'co_ba_la', 'bo_rua'], 160),
]
import os
for f, out, names, mx in jobs:
    os.makedirs(out, exist_ok=True)
    a, fg = cut(G + f)
    objs = objects(a, fg)
    print(f, len(objs), [o.size for o in objs])
    for n, o in zip(names, objs):
        o.thumbnail((mx, mx), Image.LANCZOS)
        o.save(out + n + '.png')
