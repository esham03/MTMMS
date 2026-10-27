const { app, BrowserWindow } = require('electron');
const fs = require('fs');
const path = require('path');
const http = require('http');

function apiLogin() {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      email: 'admin@goa.gov.in',
      password: 'Admin@1234'
    });

    const req = http.request({
      hostname: '127.0.0.1',
      port: 8000,
      path: '/api/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(body));
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

app.whenReady().then(async () => {
  const win = new BrowserWindow({
    width: 1400,
    height: 800,
    show: false,
    webPreferences: {
      offscreen: true
    }
  });

  const wait = (ms) => new Promise(r => setTimeout(r, ms));

  console.log('Logging in and navigating to /owners...');
  await win.loadURL('http://localhost:5174/#/login');
  await wait(1500);

  const authData = await apiLogin();
  const token = authData.token || authData.access;
  const user = authData.user;

  await win.webContents.executeJavaScript(`
    localStorage.setItem('mtmms_token', ${JSON.stringify(token)});
    localStorage.setItem('mtmms_user', ${JSON.stringify(JSON.stringify(user))});
    window.location.hash = '#/owners';
  `);
  await wait(3000);

  const img = await win.webContents.capturePage();
  const outPath = path.join(__dirname, 'owners_updated.png');
  fs.writeFileSync(outPath, img.toPNG());
  console.log('Saved screenshot to:', outPath);
  app.quit();
});
