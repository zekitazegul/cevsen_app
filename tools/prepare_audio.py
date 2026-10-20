import json, pathlib, re
root=pathlib.Path(__file__).resolve().parents[1]
tracks=[]
for first in range(1,101,10):
    s=(root/'assets/raw'/f'audio-{first}.html').read_text(encoding='utf-8-sig')
    d=json.loads(re.search(r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>',s)[1])['props']['pageProps']
    tracks.append({'first':first,'last':first+9,'url':d['audioUrl'],'durationMs':d['durationMs']})
(root/'assets/audio/index.json').write_text(json.dumps(tracks,indent=2),encoding='utf-8')
scripts=re.findall(r'<script[^>]*src="([^"]+)"',s)
print('\n'.join(scripts))
