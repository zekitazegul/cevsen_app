import pathlib,sys,subprocess,re,json
sys.path.insert(0,str(pathlib.Path(__file__).parent/'vendor'))
import imageio_ffmpeg
root=pathlib.Path(__file__).resolve().parents[1]
for first in range(1,101,10):
 p=root/'assets/audio'/f'{first}.mp3'
 r=subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-i',str(p),'-af','silencedetect=noise=-35dB:d=0.25','-f','null','-'],capture_output=True,text=True)
 ends=re.findall(r'silence_end: ([\d.]+) \| silence_duration: ([\d.]+)',r.stderr)
 (root/f'assets/raw/silences-{first}.json').write_text(json.dumps(ends),encoding='utf-8')
 if first==1:print([x for x in ends if 35<float(x[0])<52])
