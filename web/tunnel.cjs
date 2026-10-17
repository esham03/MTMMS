/**
 * MTMMS Global Cloud Tunnel Service
 * Exposes the local Django REST API on port 8000 to a secure public HTTPS URL
 * so that field officers and mobile apps can connect from ANY network (4G/5G/Any Wi-Fi).
 */

const localtunnel = require('localtunnel');
const { execFile } = require('child_process');
const path = require('path');
const fs = require('fs');

const API_PORT = parseInt(process.env.MTMMS_API_PORT || '8000', 10);
const PROJECT_ROOT = path.resolve(__dirname, '..');
const NETWORK_UTILS = path.join(PROJECT_ROOT, 'mtmms_api', 'network_utils.py');

let currentTunnel = null;
let isReconnecting = false;

function updateRuntimeConfigs(tunnelUrl) {
  return new Promise((resolve) => {
    // 1. Direct synchronous update of .mtmms-runtime.env
    try {
      const runtimeEnvPath = path.join(PROJECT_ROOT, '.mtmms-runtime.env');
      if (fs.existsSync(runtimeEnvPath)) {
        let content = fs.readFileSync(runtimeEnvPath, 'utf8');
        const tunnelApiUrl = `${tunnelUrl.replace(/\/+$/, '')}/api`;
        if (content.includes('MTMMS_TUNNEL_URL=')) {
          content = content.replace(/MTMMS_TUNNEL_URL=.*/g, `MTMMS_TUNNEL_URL=${tunnelUrl}`);
        } else {
          content += `\nMTMMS_TUNNEL_URL=${tunnelUrl}\n`;
        }
        if (content.includes('MTMMS_TUNNEL_API_URL=')) {
          content = content.replace(/MTMMS_TUNNEL_API_URL=.*/g, `MTMMS_TUNNEL_API_URL=${tunnelApiUrl}`);
        } else {
          content += `\nMTMMS_TUNNEL_API_URL=${tunnelApiUrl}\n`;
        }
        fs.writeFileSync(runtimeEnvPath, content);
      }
    } catch (_) {}

    // 2. Call python network_utils.py set_tunnel to sync all configs
    execFile(
      'python',
      [NETWORK_UTILS, 'set_tunnel', tunnelUrl, PROJECT_ROOT],
      (err) => {
        resolve(!err);
      }
    );
  });
}

async function startTunnel() {
  if (isReconnecting) return;
  isReconnecting = true;

  if (currentTunnel) {
    try {
      currentTunnel.close();
    } catch (_) {}
    currentTunnel = null;
  }

  console.log(`[MTMMS Cloud Tunnel] Initializing secure tunnel for port ${API_PORT}...`);

  try {
    const tunnel = await localtunnel({
      port: API_PORT,
      local_host: '127.0.0.1',
    });

    currentTunnel = tunnel;
    isReconnecting = false;

    const publicUrl = tunnel.url;
    const apiUrl = `${publicUrl}/api`;

    console.log('\n================================================================');
    console.log('   MTMMS GLOBAL CLOUD TUNNEL ACTIVE');
    console.log('================================================================');
    console.log(`   Public Web/API Base:  ${publicUrl}`);
    console.log(`   Mobile API Endpoint:  ${apiUrl}`);
    console.log('   Works on ANY network: 4G / 5G / Remote Wi-Fi / Hotspot');
    console.log('================================================================\n');

    await updateRuntimeConfigs(publicUrl);

    tunnel.on('close', () => {
      console.log('[MTMMS Cloud Tunnel] Connection dropped. Re-establishing in 3 seconds...');
      currentTunnel = null;
      setTimeout(startTunnel, 3000);
    });

    tunnel.on('error', (err) => {
      console.error(`[MTMMS Cloud Tunnel] Error: ${err.message}`);
    });
  } catch (err) {
    isReconnecting = false;
    console.error(`[MTMMS Cloud Tunnel] Setup error: ${err.message}. Retrying in 5 seconds...`);
    setTimeout(startTunnel, 5000);
  }
}

// Clean shutdown handler
process.on('SIGINT', () => {
  if (currentTunnel) {
    try {
      currentTunnel.close();
    } catch (_) {}
  }
  process.exit(0);
});

process.on('SIGTERM', () => {
  if (currentTunnel) {
    try {
      currentTunnel.close();
    } catch (_) {}
  }
  process.exit(0);
});

startTunnel();
