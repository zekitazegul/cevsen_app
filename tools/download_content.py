import concurrent.futures
import html
import json
import pathlib
import re
import urllib.request
from transcription_corrections import correct_transcription

ROOT = pathlib.Path(__file__).resolve().parents[1]

def download(number):
    url = f'https://nurulkuran.com/cevsen/{number}'
    raw = (ROOT / 'assets' / 'raw' / f'{number}.html').read_text(encoding='utf-8-sig')
    rows = []
    for block in re.findall(r'<li id="satir-\d+".*?</li>', raw, re.S):
        texts = {}
        for lang in ('ar', 'tr'):
            match = re.search(r'<p[^>]*lang="' + lang + r'"[^>]*>(.*?)</p>', block, re.S)
            if not match:
                raise ValueError(f'Missing {lang} in bab {number}')
            texts[lang] = html.unescape(re.sub('<[^>]+>', '', match[1])).strip()
        rows.append(texts)
    correct_transcription(number, rows)
    if not 10 <= len(rows) <= 13:
        raise ValueError(f'Unexpected row count in bab {number}: {len(rows)}')
    return {'number': number, 'source': url, 'rows': rows}

if __name__ == '__main__':
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
        chapters = list(pool.map(download, range(1, 101)))
    target = ROOT / 'assets' / 'cevsen.json'
    target.parent.mkdir(exist_ok=True)
    target.write_text(json.dumps(chapters, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'Saved {len(chapters)} bab, {sum(len(c["rows"]) for c in chapters)} paired rows')
