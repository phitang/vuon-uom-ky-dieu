## Ghép cây (ảnh Gemini có ụ đất) vào chậu mới:
## - ụ đất của ảnh được tô lại đúng màu đất trong chậu và chỉ nằm trong miệng chậu
## - phần cây vẽ đè lên chậu, không bị chậu che (không đứt lá, đứt thân)
## - tâm ụ đất đặt đúng tâm miệng chậu
from PIL import Image
import numpy as np, os
from scipy import ndimage
CUT='/home/claude/gem/cay/cut/'
OUT='/home/claude/gem/cay/out/'
W,H=600,1084
pot_s=Image.open(CUT+'chau_dat.png'); pot_e=Image.open(CUT+'chau_rong.png')
k=470/pot_s.width
def place_pot(p):
    p=p.resize((int(p.width*k),int(p.height*k)),Image.LANCZOS)
    x0=(W-p.width)//2; y0=1068-p.height
    c=Image.new('RGBA',(W,H)); c.alpha_composite(p,(x0,y0)); return c,x0,y0
POT,x0,y0=place_pot(pot_s)
EMPTY,_,_=place_pot(pot_e)
cx=x0+246*k; cy=y0+100*k; rx=206*k; ry=52*k
Y,X=np.mgrid[0:H,0:W]
PA=np.array(POT).astype(float)
inner=((X-cx)/(rx*0.8))**2+((Y-cy)/(ry*0.6))**2<1
SOIL=PA[inner][:,:3]
soil_mean=SOIL.mean(0)
soil_lum=SOIL.mean(1).mean()

def split_mound(p):
    """Tách ụ đất (đất sẫm, ít xanh) ở đáy ảnh cây. Trả về (mask ụ đất, tâm x, hàng đáy, hàng đỉnh ụ)."""
    A=np.array(p).astype(float); rgb=A[:,:,:3]; al=A[:,:,3]
    r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    mx=rgb.max(2); mn=rgb.min(2); sat=(mx-mn)/(mx+1e-6)
    green=(g>r*1.04)&(g>60)
    soilish=(~green)&(al>20)&((mx<125)|((sat<0.25)&(mx<150)))
    h=p.height
    seed0=(r>b+30)&(r>95)
    dark=(~green)&(~seed0)&(al>150)&(sat<0.35)&(mx<200)
    rows=dark.sum(1).astype(float)
    rows[:int(h*0.62)]=0
    widest=rows.max()
    band=np.where(rows>widest*0.3)[0]
    top=band.min() if len(band) else h-1
    # ụ đất: các điểm đất từ hàng top trở xuống (thêm chút viền mờ)
    m=soilish&(np.arange(h)[:,None]>=top-4)
    # viền sáng mờ quanh ụ cũng là ụ
    # mọi điểm không phải lá xanh / thân nâu sáng / hạt trong vùng ụ đất đều là đất (kể cả viền sáng)
    seedc=(r>b+30)&(r>95)
    m|=(np.arange(h)[:,None]>=top+2)&(~green)&(~seedc)&(al>0)
    ys,xs=np.where(m&(al>150))
    mcx=xs.mean() if len(xs) else p.width/2
    bottom=ys.max() if len(ys) else h-1
    return m,mcx,bottom,top

def compose(plant, s, seed_up=0.0):
    p=plant.resize((max(1,int(plant.width*s)),max(1,int(plant.height*s))),Image.LANCZOS)
    m,mcx,bottom,top=split_mound(p)
    A=np.array(p).astype(float)
    # đáy ụ đất nằm ở phần dưới miệng chậu, tâm ụ trùng tâm miệng chậu
    ox=int(round(cx-mcx)); oy=int(round(cy+ry*0.62-bottom-seed_up))
    L=np.zeros((H,W,4)); M=np.zeros((H,W),bool)
    ys,xs=np.mgrid[0:p.height,0:p.width]
    ty=ys+oy; tx=xs+ox
    ok=(ty>=0)&(ty<H)&(tx>=0)&(tx<W)
    L[ty[ok],tx[ok]]=A[ok]; M[ty[ok],tx[ok]]=m[ok]
    # tô lại màu ụ đất theo đất trong chậu (giữ sáng tối của nét vẽ)
    lum=L[:,:,:3].mean(2)
    mlum=lum[M&(L[:,:,3]>200)].mean() if (M&(L[:,:,3]>200)).any() else soil_lum
    f=np.clip((lum/mlum),0.55,1.12)**0.85
    re=soil_mean[None,None,:]*f[:,:,None]
    L[:,:,:3]=np.where(M[:,:,None],re,L[:,:,:3])
    # ụ đất chỉ trong miệng chậu (phía trên tâm thì chỉ giới hạn bề ngang)
    dy=np.maximum(Y-cy,0)
    e=((X-cx)/(rx*0.97))**2+(dy/(ry*0.95))**2
    clip=np.clip((1.0-e)/0.12,0,1)
    # mép dưới ụ đất tan dần vào đất trong chậu (không thấy đường viền)
    clip*=np.clip((cy+ry*0.62-Y)/(ry*0.45),0,1)
    L[:,:,3]=np.where(M,L[:,:,3]*clip,L[:,:,3])
    out=POT.copy()
    mound=L.copy(); mound[:,:,3]*=M
    plant_only=L.copy(); plant_only[:,:,3]*=~M
    out.alpha_composite(Image.fromarray(mound.clip(0,255).astype(np.uint8)))
    out.alpha_composite(Image.fromarray(plant_only.clip(0,255).astype(np.uint8)))
    return out

os.makedirs(OUT,exist_ok=True)
POT.save(OUT+'chau_trong.png'); EMPTY.save(OUT+'chau_khong_dat.png')
def ld(n): return Image.open(CUT+n+'.png')
for sp in ['hong','cuc','tulip','chuong','sao','lan','sen','rong']:
    os.makedirs(OUT+sp,exist_ok=True)
    p2=ld(sp+'_2'); p3=ld(sp+'_3')
    sc=min(660/p3.height, 430/p3.width)
    compose(p2,sc).save(OUT+sp+'/2.png'); compose(p3,sc).save(OUT+sp+'/3.png')
for d in ['xr_tron','xr_cao','bonsai','mai','chung']: os.makedirs(OUT+d,exist_ok=True)
p=ld('xrtron_3'); s=420/p.width
compose(ld('xrtron_2'),s*0.85).save(OUT+'xr_tron/2.png'); compose(p,s).save(OUT+'xr_tron/3.png')
p=ld('xrcao_3'); s=min(700/p.height,430/p.width)
compose(ld('xrcao_2'),s*0.85).save(OUT+'xr_cao/2.png'); compose(p,s).save(OUT+'xr_cao/3.png')
for col in ['xanh','do','vang']:
    p=ld('bonsai_'+col); s=min(560/p.height,440/p.width)
    compose(p,s*0.8).save(OUT+f'bonsai/2_{col}.png'); compose(p,s).save(OUT+f'bonsai/3_{col}.png')
p=ld('mai_3'); s=min(640/p.height,560/p.width)
compose(ld('mai_2'),s*0.85).save(OUT+'mai/2.png'); compose(p,s).save(OUT+'mai/3.png')
m0=ld('mam_0'); compose(m0,400/m0.width).save(OUT+'chung/0.png')
m1=ld('mam_1'); compose(m1,400/m1.width).save(OUT+'chung/1.png')
