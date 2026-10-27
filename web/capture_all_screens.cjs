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
    width: 1600,
    height: 1000,
    show: false,
    webPreferences: {
      offscreen: true
    }
  });

  const screenshotsDir = path.join(__dirname, '..', 'screenshots');
  if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir, { recursive: true });
  }

  const wait = (ms) => new Promise(r => setTimeout(r, ms));

  // 1. Capture Login Screen
  console.log('Capturing 01_login.png...');
  await win.loadURL('http://localhost:5174/#/login');
  await wait(2000);
  let img = await win.webContents.capturePage();
  fs.writeFileSync(path.join(screenshotsDir, '01_login.png'), img.toPNG());

  // 2. Fetch live token and inject into localStorage
  console.log('Fetching auth token from Django API...');
  const authData = await apiLogin();
  const token = authData.token || authData.access;
  const user = authData.user;
  console.log('Got token for user:', user.name);

  await win.webContents.executeJavaScript(`
    localStorage.setItem('mtmms_token', ${JSON.stringify(token)});
    localStorage.setItem('mtmms_user', ${JSON.stringify(JSON.stringify(user))});
    window.location.hash = '#/dashboard';
  `);
  await wait(3500);

  // 3. Dashboard
  console.log('Capturing 02_dashboard.png...');
  img = await win.webContents.capturePage();
  fs.writeFileSync(path.join(screenshotsDir, '02_dashboard.png'), img.toPNG());

  // 4. Towers Registry
  console.log('Capturing 03_tower_registry.png...');
  await win.webContents.executeJavaScript(`window.location.hash = '#/towers';`);
  await wait(3000);
  img = await win.webContents.capturePage();
  fs.writeFileSync(path.join(screenshotsDir, '03_tower_registry.png'), img.toPNG());

  // 5. GIS Map View
  console.log('Capturing 04_gis_map_view.png...');
  await win.webContents.executeJavaScript(`window.location.hash = '#/map';`);
  await wait(4500);
  img = await win.webContents.capturePage();
  fs.writeFileSync(path.join(screenshotsDir, '04_gis_map_view.png'), img.toPNG());

  // 6. Rent Management
  console.log('Capturing 05_rent_management.png...');
  await win.webContents.executeJavaScript(`window.location.hash = '#/rent';`);
  await wait(3000);
  img = await win.webContents.capturePage();
  fs.writeFileSync(path.join(screenshotsDir, '05_rent_management.png'), img.toPNG());

  // 7. Form VII Statutory Rent Demand Notice Modal
  console.log('Opening Form VII Notice Modal and capturing 06_form_vii_notice.png...');
  await win.webContents.executeJavaScript(`
    (() => {
      const buttons = Array.from(document.querySelectorAll('button'));
      const noticeBtn = buttons.find(b => 
        b.innerText.toLowerCase().includes('demand notice') || 
        b.innerText.toLowerCase().includes('notice') ||
        b.getAttribute('title')?.toLowerCase().includes('demand notice')
      );
      if (noticeBtn) noticeBtn.click();
    })();
  `);
  await wait(2500);
  img = await win.webContents.capturePage();
  fs.writeFileSync(path.join(screenshotsDir, '06_form_vii_notice.png'), img.toPNG());

  // 8. Location Hierarchy Browser
  console.log('Capturing 07_location_hierarchy.png...');
  await win.webContents.executeJavaScript(`window.location.hash = '#/locations';`);
  await wait(3000);
  img = await win.webContents.capturePage();
  fs.writeFileSync(path.join(screenshotsDir, '07_location_hierarchy.png'), img.toPNG());

  // 9. Operators Management
  console.log('Capturing 08_operators.png...');
  await win.webContents.executeJavaScript(`window.location.hash = '#/operators';`);
  await wait(3000);
  img = await win.webContents.capturePage();
  fs.writeFileSync(path.join(screenshotsDir, '08_operators.png'), img.toPNG());

  // 10. Reports & Analytics
  console.log('Capturing 09_reports_analytics.png...');
  await win.webContents.executeJavaScript(`window.location.hash = '#/reports';`);
  await wait(3000);
  img = await win.webContents.capturePage();
  fs.writeFileSync(path.join(screenshotsDir, '09_reports_analytics.png'), img.toPNG());

  console.log('SUCCESS: All 9 screenshots captured perfectly via HashRouter!');
  app.quit();
});
