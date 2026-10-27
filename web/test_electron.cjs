const { app, BrowserWindow } = require('electron');
const fs = require('fs');
const path = require('path');

app.whenReady().then(async () => {
  const win = new BrowserWindow({
    width: 1440,
    height: 900,
    show: false,
    webPreferences: {
      offscreen: true
    }
  });

  await win.loadURL('http://localhost:5174/');
  await new Promise(r => setTimeout(r, 2000));
  
  const image = await win.webContents.capturePage();
  fs.writeFileSync(path.join(__dirname, '..', 'screenshots', '01_login_test.png'), image.toPNG());
  console.log('Saved 01_login_test.png successfully!');
  app.quit();
});
