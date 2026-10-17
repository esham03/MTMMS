# MTMMS Universal Multi-Network Setup & Deployment Guide

**Mobile Tower Monitoring & Management System (MTMMS)**  
*Department of Information Technology, Government of Goa*

---

## 1. Overview & Multi-Network Architecture

MTMMS is engineered for **100% universal network portability**. It works seamlessly on:
1. **Local Wi-Fi / Hotspot (Same Network)**: Direct, high-speed, 100% offline-capable peer-to-peer connection.
2. **Global Cloud Tunnel (Any Network)**: Secure public HTTPS connection accessible anywhere in the world on **4G / 5G mobile data**, public internet, or different Wi-Fi networks without requiring port forwarding.

```
                      +------------------------------------------+
                      |         HOST COMPUTER (WINDOWS)          |
                      |                                          |
                      |   Django REST API (0.0.0.0:8000)         |
                      |                 ^                        |
                      |                 | Localhost (127.0.0.1)  |
                      |                 v                        |
                      |         MySQL Database (Local)           |
                      |                                          |
                      |   React/Vite Web Portal (0.0.0.0:5174)   |
                      |   UDP Multi-Subnet Discovery (Port 41588)|
                      |   Global Cloud Tunnel (HTTPS Public URL) |
                      +--------------------+---------------------+
                                           |
                 +-------------------------+-------------------------+
                 |                                                   |
                 v                                                   v
   [PATH A: LOCAL WI-FI / HOTSPOT]                     [PATH B: ANY NETWORK / 4G / 5G]
                 |                                                   |
      Same Wi-Fi Router / Hotspot                           Mobile Data / Remote Wi-Fi
                 |                                                   |
  +--------------+--------------+                     +--------------+--------------+
  |                             |                     |                             |
  v                             v                     v                             v
+-----------------+   +------------------+  +-----------------+   +------------------+
|  ANDROID PHONE  |   | OTHER PCS / MACS |  |  ANDROID PHONE  |   | REMOTE LAPTOPS   |
| MTMMS Mobile APK|   | Any Web Browser  |  | In the Field    |   | Field Officers   |
| (Auto-discovery)|   | http://<IP>:5174 |  | On 4G / 5G      |   | (Web Browser)    |
|                 |   |                  |  | Cloud HTTPS URL |   | Cloud HTTPS URL  |
+-----------------+   +------------------+  +-----------------+   +------------------+
```

---

## 2. Quick Start: Launching MTMMS

1. Connect your computer to your network (Wi-Fi, Ethernet, or Phone Mobile Hotspot).
2. Ensure MySQL service is running.
3. In the project folder, double-click:
   ```cmd
   Start-Live-System.bat
   ```
4. The system automatically:
   - Detects all active local network interfaces (Wi-Fi, Ethernet, Hotspots).
   - Starts the Django REST API on `0.0.0.0:8000`.
   - Starts the Multi-Subnet UDP Discovery Service on port `41588`.
   - Starts the React/Vite Web Portal on `0.0.0.0:5174`.
   - Starts the Global Cloud Tunnel (`tunnel.cjs`), generating an instant secure HTTPS URL for 4G/5G mobile access.
   - Verifies API health and displays the interactive endpoints banner.

---

## 3. How to Connect the Android Mobile App

You only need **ONE portable APK** (`MTMMS.apk`).

### Scenario A: Phone is on the SAME Wi-Fi or Mobile Hotspot as the PC
1. Connect the phone to the same Wi-Fi router or laptop mobile hotspot.
2. Open the **MTMMS** app.
3. **Auto-Discovery**:
   - The app automatically discovers the host computer across UDP beacons and concurrent subnet sweeps.
   - It verifies the server signature and navigates straight to Login.

### Scenario B: Phone is on Mobile Data (4G / 5G) or a DIFFERENT Network
1. Ensure `Start-Live-System.bat` is running on your PC.
2. Look at the launcher window for the **Global Cloud Access URL**:
   ```
   Global Cloud Web: https://<subdomain>.loca.lt
   Global Cloud API: https://<subdomain>.loca.lt/api
   ```
3. Open the **MTMMS** app on your phone.
4. On the splash screen, tap **"Connect Server"** (or tap the top-right host icon on the login screen).
5. Paste or type the Cloud API URL (or tap **"Use Cloud URL"**).
6. Tap **"Test & Connect"** — the app immediately locks onto the server over 4G/5G and opens the login screen!

---

## 4. How to Connect Another Laptop or Tablet (Web Portal)

### On the Same Local Network:
Open any browser and type the Local Web URL shown in the launcher:
```
http://<SERVER_IP>:5174
```
*(Example: `http://172.20.10.3:5174` or `http://192.168.1.15:5174`)*

### From Any Network in the World:
Open any browser and type the Cloud Tunnel URL shown in the launcher:
```
https://<subdomain>.loca.lt
```

---

## 5. What Happens When Moving Between Networks?

When you disconnect from one Wi-Fi and connect to another (or switch to mobile hotspot):
1. Simply run `Start-Live-System.bat` on the new network.
2. The dynamic IP detector inspects all active adapters and rebinds all configuration files instantly in under 1 second.
3. Django accepts all hosts (`ALLOWED_HOSTS=*`), and CORS allows all origins.
4. The mobile app automatically probes for the new IP and falls back to the cloud tunnel if local discovery is blocked by the router.

---

## 6. Stopping the System

To stop all services cleanly:
- Press Option `[6]` from the `Start-Live-System.bat` menu, OR
- Double-click:
  ```cmd
  Stop-System.bat
  ```
This cleanly stops Django, the UDP Discovery Service, Vite Web Portal, and the Cloud Tunnel.
