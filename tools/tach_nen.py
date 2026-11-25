from PIL import Image
import numpy as np
from scipy import ndimage
def cut(path):
    a=np.array(Image.open(path).convert('RGB')).astype(float)
    mn=a.min(2); mx=a.max(2)
    bgm=(mn>226)&(mx-mn<24)
    lab,n=ndimage.label(bgm)
    edge=set(lab[0,:])|set(lab[-1,:])|set(lab[:,0])|set(lab[:,-1]); edge.discard(0)
    fg=~np.isin(lab,list(edge))
    fg=ndimage.binary_opening(fg,iterations=1)
    return a,fg
def objects(a,fg,min_area=3000):
    lab,n=ndimage.label(ndimage.binary_dilation(fg,iterations=6))
    res=[]
    for sl,i in zip(ndimage.find_objects(lab),range(1,n+1)):
        m=(lab[sl]==i)&fg[sl]
        if m.sum()<min_area: continue
        al=ndimage.gaussian_filter(m.astype(float),0.7)*255
        al[~ndimage.binary_erosion(m)]*=0.6
        rgba=np.dstack([a[sl],al]).clip(0,255).astype(np.uint8)
        res.append((sl[1].start,Image.fromarray(rgba,'RGBA')))
    res.sort(key=lambda r:r[0])
    return [r[1] for r in res]
