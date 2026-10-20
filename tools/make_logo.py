import pathlib,sys,math
sys.path.insert(0,str(pathlib.Path(__file__).parent/'vendor'))
from PIL import Image,ImageDraw
root=pathlib.Path(__file__).resolve().parents[1]
def render(size):
 im=Image.new('RGB',(1024,1024),'#123f35');d=ImageDraw.Draw(im)
 d.rounded_rectangle((35,35,989,989),radius=210,outline='#b8914b',width=12)
 for angle in (0,math.pi/4):
  pts=[(512+365*math.cos(angle+math.pi/4+i*math.pi/2),512+365*math.sin(angle+math.pi/4+i*math.pi/2)) for i in range(4)]
  d.line(pts+[pts[0]],fill='#b8914b',width=10)
 d.polygon([(512,405),(405,352),(300,365),(300,639),(410,626),(512,680),(614,626),(724,639),(724,365),(619,352)],fill='#faf5e9')
 d.line([(512,408),(512,667)],fill='#b8914b',width=9)
 for shift in (0,55,110):
  d.line([(337,414+shift),(409,412+shift),(473,441+shift)],fill='#b8914b',width=7)
  d.line([(551,441+shift),(615,412+shift),(687,414+shift)],fill='#b8914b',width=7)
 return im.resize((size,size),Image.Resampling.LANCZOS)
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
 render(size).save(root/f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
(root/'assets/branding').mkdir(exist_ok=True)
render(1024).save(root/'assets/branding/cevsen-logo.png')
for size in [192,512]:
 for prefix in ['Icon-','Icon-maskable-']:
  render(size).save(root/f'web/icons/{prefix}{size}.png')
render(32).save(root/'web/favicon.png')
print('Logo exported')
