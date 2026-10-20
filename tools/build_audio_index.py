import pathlib,json
root=pathlib.Path(__file__).resolve().parents[1]
alignment=json.loads((root/'assets/raw/alignment.json').read_text())
tracks=json.loads((root/'assets/audio/index.json').read_text())
chapters=[]
for group,track in zip(alignment,tracks):
 first=group['first']
 silences=[(float(end)-float(length),float(end)) for end,length in json.loads((root/f'assets/raw/silences-{first}.json').read_text())]
 boundaries=[0]
 for end in group['ends'][:-1]:
  candidates=[(a,b) for a,b in silences if end-3<a<end+2 and b-a>.25]
  if not candidates:raise ValueError(f'No pause for {first}: {end}')
  # Refrain template ends just before the final breath pause.
  a,b=min(candidates,key=lambda p:abs((p[0]+p[1])/2-(end-.7)))
  boundaries.append(round((a+b)/2*1000))
 boundaries.append(track['durationMs'])
 for i in range(10):
  start,end=boundaries[i:i+2]
  assert 25000<end-start<100000,(first+i,start,end)
  chapters.append({'bab':first+i,'file':f'{first}.mp3','startMs':start,'endMs':end,'source':track['url']})
(root/'assets/audio/chapters.json').write_text(json.dumps(chapters,indent=2),encoding='utf-8')
print('Indexed 100 bab. Durations:',[round((c['endMs']-c['startMs'])/1000,1) for c in chapters])
