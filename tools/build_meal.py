import json,pathlib
root=pathlib.Path(__file__).resolve().parents[1]
chapters=json.loads((root/'assets/cevsen.json').read_text(encoding='utf-8'))
intro='Allah’ım, isimlerinle sana yalvarıyor ve senden istiyorum.'
for line in (root/'tools/meal_meanings.txt').read_text(encoding='utf-8').splitlines():
    parts=line.split('|');n=int(parts.pop(0));b=chapters[n-1];rows=b['rows'][:-1]
    meanings=['Ey '+p.lower()+'!' if p!='Allah' else 'Ey Allah!' for p in parts]
    if len(rows)==len(meanings)+1:meanings.insert(0,intro)
    elif 'es’elüke' in rows[0]['tr']:meanings[0]=intro+' '+meanings[0]
    assert len(rows)==len(meanings),(n,len(rows),len(meanings))
    for r,m in zip(rows,meanings):r['meal']=m
    b['rows'][-1]['meal']='Seni bütün eksikliklerden uzak tutarım. Senden başka ilah yoktur. Güven ve kurtuluş diliyoruz; bizi ateşten kurtar.'
    b['mealSource']='Arapça dua metninden bu uygulama için hazırlanmış sade Türkçe anlam aktarımı.'
(root/'assets/cevsen.json').write_text(json.dumps(chapters,ensure_ascii=False,indent=2),encoding='utf-8')
print('100 bab için özgün sade anlam aktarımı eklendi.')
