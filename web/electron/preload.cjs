const { contextBridge, ipcRenderer } = require('electron');
const fs = require('fs');
const path = require('path');

// Dynamically resolve runtime API URL
let runtimeApiUrl = process.env.MTMMS_API_URL || null;
if (!runtimeApiUrl) {
  try {
    // Check possible locations for .mtmms-runtime.env
    const candidatePaths = [
      path.join(process.cwd(), '.mtmms-runtime.env'),
      path.join(__dirname, '../../.mtmms-runtime.env'),
      path.join(__dirname, '../../../.mtmms-runtime.env'),
      path.join(__dirname, '../../../../.mtmms-runtime.env'),
    ];
    for (const p of candidatePaths) {
      if (fs.existsSync(p)) {
        const content = fs.readFileSync(p, 'utf8');
        const match = content.match(/^MTMMS_API_URL=(.+)$/m);
        if (match && match[1]) {
          runtimeApiUrl = match[1].trim();
          break;
        }
      }
    }
  } catch (_) {}
}

contextBridge.exposeInMainWorld('electronAPI', {
  platform: process.platform,
  isElectron: true,
  apiUrl: runtimeApiUrl || 'http://127.0.0.1:8000/api',
  sendMessage: (channel, data) => ipcRenderer.send(channel, data),
  onMessage: (channel, func) => ipcRenderer.on(channel, (event, ...args) => func(...args)),
  printPage: () => ipcRenderer.send('PRINT_PAGE'),
});
