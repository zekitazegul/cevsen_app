"""Generate the small download manifest from the source recordings (not bundled)."""
import json
from pathlib import Path

audio = Path(__file__).resolve().parents[1] / 'assets/audio'
clips = json.loads((audio / 'chapters.json').read_text(encoding='utf-8'))
sources = {clip['file']: clip['source'] for clip in clips}
tracks = [
    dict(file=name, url=url, sizeBytes=(audio / name).stat().st_size)
    for name, url in sources.items()
]
(audio / 'downloads.json').write_text(json.dumps(tracks, indent=2) + '\n', encoding='utf-8')
