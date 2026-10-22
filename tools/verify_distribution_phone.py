"""Read-only UI inspection and explicit taps on the authorized test phone."""
import subprocess, sys, time, re, os, json
import xml.etree.ElementTree as ET
from pathlib import Path

adb = 'C:/Users/Zek/AppData/Local/Android/sdk/platform-tools/adb.exe'
serial = os.environ.get('ADB_SERIAL')
state_path = Path(__file__).resolve().parents[1] / 'build/phone-connection.json'
if not serial and state_path.exists():
    state = json.loads(state_path.read_text(encoding='utf-8-sig'))
    if state.get('connected'):
        serial = state.get('serial')
if not serial:
    devices = [line.split()[0] for line in subprocess.check_output([adb, 'devices'], timeout=15).decode().splitlines()
               if len(line.split()) >= 2 and line.split()[1] == 'device']
    if len(devices) != 1:
        raise RuntimeError('Tek bir test telefonu bağla veya ADB_SERIAL değerini ayarla.')
    serial = devices[0]
out = Path('C:/cevsenApp/qa/distribution')
out.mkdir(parents=True, exist_ok=True)

def run(*args):
    return subprocess.check_output([adb, '-s', serial, *args], timeout=90)

def nodes():
    run('shell', 'uiautomator', 'dump', '/sdcard/distribution-qa.xml')
    data = run('shell', 'cat', '/sdcard/distribution-qa.xml')
    parsed = list(ET.fromstring(data).iter('node'))
    allowed = {'com.zek.cevsen_app', 'com.zek.cevsen_installer', 'com.zekitazegul.kuranapp',
               'com.android.settings', 'com.android.systemui', 'android',
               'com.google.android.packageinstaller', 'com.samsung.android.packageinstaller',
               'com.google.android.permissioncontroller', 'com.google.android.gms'}
    foreground = next((node.get('package') for node in parsed if node.get('package')), '')
    if foreground == 'com.android.vending':
        focus = run('shell', 'dumpsys', 'window').decode(errors='replace')
        if 'com.google.android.finsky.protectdialogs.activity.PlayProtectDialogsActivity' in focus:
            allowed.add('com.android.vending')
    if foreground and foreground not in allowed:
        raise RuntimeError('Test uygulaması ön planda değil; ekran okunmadı.')
    (out / 'screen.xml').write_bytes(data)
    return parsed

def dump():
    for node in nodes():
        text = node.get('text', '') or node.get('content-desc', '')
        if text: print(ascii(text), node.get('bounds'))

action = sys.argv[1]
run('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP')
run('shell', 'wm', 'dismiss-keyguard')
if action == 'launch':
    run('shell', 'am', 'start', '-n', sys.argv[2] + '/.MainActivity')
    time.sleep(2)
elif action == 'tap':
    match = [node for node in nodes() if sys.argv[2] in (node.get('text', '') + ' ' + node.get('content-desc', ''))]
    if not match: raise RuntimeError('Not visible: ' + ascii(sys.argv[2]))
    node = min(match, key=lambda node: len(node.get('text','') + node.get('content-desc','')))
    x1,y1,x2,y2 = map(int,re.findall(r'\d+',node.get('bounds')))
    run('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2))
    time.sleep(2)
elif action == 'back':
    run('shell','input','keyevent','4')
    time.sleep(1)
elif action == 'scroll':
    width, height = map(int, re.search(r'(\d+)x(\d+)', run('shell', 'wm', 'size').decode()).groups())
    run('shell', 'input', 'swipe', str(width // 2), str(height * 8 // 10), str(width // 2), str(height * 3 // 10), '450')
    time.sleep(1)
elif action == 'shot':
    (out / (sys.argv[2] + '.png')).write_bytes(run('exec-out','screencap','-p'))
dump()
