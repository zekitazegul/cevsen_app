import pathlib,sys,subprocess,json
root=pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tools/vendor'))
import numpy as np
import imageio_ffmpeg
def features(first):
 cache=root/f'assets/raw/features-{first}.npy'
 if cache.exists():
  cached=np.load(cache)
  if np.isfinite(cached).all():return cached
 raw=subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-v','error','-i',str(root/f'assets/audio/{first}.mp3'),'-ar','8000','-ac','1','-f','f32le','-'],capture_output=True).stdout
 audio=np.frombuffer(raw,dtype=np.float32)
 windows=np.lib.stride_tricks.sliding_window_view(audio,512)[::800]
 spectrum=abs(np.fft.rfft(windows*np.hanning(512)))**2
 edges=np.geomspace(6,250,21).astype(int)
 bands=np.stack([np.log(spectrum[:,edges[i]:edges[i+1]].mean(axis=1)+1e-8) for i in range(20)],axis=1)
 bands-=bands.mean(axis=0);bands/=bands.std(axis=0)+1e-8
 bands/=np.linalg.norm(bands,axis=1,keepdims=True)+1e-8
 np.save(cache,bands)
 return bands
if __name__=='__main__':
 f=features(1)
 length=45
 template=np.lib.stride_tricks.sliding_window_view(f,length,axis=0).reshape(-1,length*20)[415]
 for first in range(1,101,10):
  g=features(first)
  windows=np.lib.stride_tricks.sliding_window_view(g,length,axis=0).reshape(-1,length*20)
  sim=windows@template/length
  picks=[]
  for idx in np.argsort(sim)[::-1]:
   if all(abs(idx-p)>240 for p in picks):picks.append(int(idx))
   if len(picks)==10:break
  print(first,[(p/10,round(float(sim[p]),3)) for p in sorted(picks)],flush=True)
