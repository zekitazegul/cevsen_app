import pathlib,re,html,json
root=pathlib.Path(__file__).resolve().parents[1]
s=(root/'assets/raw/closing-prayer.html').read_text(encoding='utf-8-sig')
ps=[html.unescape(re.sub('<[^>]+>','',p)).strip() for p in re.findall('<p[^>]*>(.*?)</p>',s,re.S)]
ar=[p for p in ps if len(re.findall('[\u0600-\u06ff]',p))>30]
(root/'assets/raw/closing-ar.json').write_text(json.dumps(ar,ensure_ascii=False,indent=2),encoding='utf-8')
print([(len(x),x[:40].encode('unicode_escape').decode()) for x in ar])
s=(root/'assets/raw/audio-91.html').read_text(encoding='utf-8-sig')
print(sorted(set(x for x in re.findall('href="([^"]+)"',s) if '/cevsen/' in x)))
