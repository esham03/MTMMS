"""
MTMMS Multi-Network LAN & Cloud Discovery Service
Listens on UDP port 41588 for discovery probes from Flutter APK / mobile devices
and sends periodic discovery beacons across ALL local network subnets,
advertising both local LAN IP endpoints and global cloud tunnel endpoints.
"""

import sys
import time
import socket
import json
import threading
from pathlib import Path
from network_utils import get_active_lan_ip, get_all_lan_ips, get_all_subnet_broadcasts, get_saved_tunnel_url

DISCOVERY_PORT = 41588
BUFFER_SIZE = 1024

class DiscoveryServer:
    def __init__(self, api_port=8000, web_port=5174):
        self.api_port = api_port
        self.web_port = web_port
        self.running = False
        self.sock = None
        self.cached_lan_ip = None
        self.cached_all_ips = []
        self.cached_tunnel_url = ""
        self.last_ip_check = 0
        self.project_root = Path(__file__).resolve().parent.parent

    def refresh_network_info(self, force=False):
        now = time.time()
        if force or (now - self.last_ip_check > 8):
            self.cached_lan_ip = get_active_lan_ip()
            self.cached_all_ips = get_all_lan_ips()
            self.cached_tunnel_url = get_saved_tunnel_url(self.project_root)
            self.last_ip_check = now

    def get_payload(self):
        self.refresh_network_info()
        lan_ip = self.cached_lan_ip or "127.0.0.1"
        tunnel_url = self.cached_tunnel_url or ""
        tunnel_api = f"{tunnel_url.rstrip('/')}/api" if tunnel_url else ""
        
        return {
            "service": "MTMMS",
            "version": "2.0",
            "device_name": "MTMMS Server",
            "server_ip": lan_ip,
            "all_ips": self.cached_all_ips or [lan_ip],
            "api_port": self.api_port,
            "web_port": self.web_port,
            "api_url": f"http://{lan_ip}:{self.api_port}/api",
            "health_url": f"http://{lan_ip}:{self.api_port}/api/health/",
            "web_url": f"http://{lan_ip}:{self.web_port}",
            "tunnel_url": tunnel_api,
            "timestamp": int(time.time()),
        }

    def start(self):
        self.running = True

        # 1. Initialize UDP socket immediately
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        except Exception:
            pass
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        self.sock.bind(('0.0.0.0', DISCOVERY_PORT))

        # 2. Resolve initial IP
        self.refresh_network_info(force=True)
        print(f"[MTMMS Discovery] Active on UDP port {DISCOVERY_PORT}", flush=True)
        print(f"[MTMMS Discovery] Primary LAN IP: {self.cached_lan_ip}", flush=True)
        print(f"[MTMMS Discovery] All Active Network Interfaces: {', '.join(self.cached_all_ips)}", flush=True)
        if self.cached_tunnel_url:
            print(f"[MTMMS Discovery] Global Cloud Tunnel: {self.cached_tunnel_url}", flush=True)

        # 3. Start background announcement broadcaster
        broadcast_thread = threading.Thread(target=self._broadcast_loop, daemon=True)
        broadcast_thread.start()

        # 4. Listen for discovery requests with instant responses
        try:
            while self.running:
                try:
                    data, addr = self.sock.recvfrom(BUFFER_SIZE)
                    message = data.decode('utf-8', errors='ignore').strip()
                    if "MTMMS" in message or "DISCOVER" in message or "PING" in message:
                        payload = self.get_payload()
                        response_bytes = json.dumps(payload).encode('utf-8')
                        self.sock.sendto(response_bytes, addr)
                except socket.timeout:
                    continue
                except Exception:
                    if self.running:
                        time.sleep(0.1)
        except KeyboardInterrupt:
            pass
        finally:
            self.stop()

    def _broadcast_loop(self):
        """Periodically broadcast server presence across all connected network subnets"""
        while self.running:
            try:
                self.refresh_network_info()
                payload = self.get_payload()
                payload["type"] = "beacon"
                data = json.dumps(payload).encode('utf-8')
                
                # Broadcast to all subnet broadcasts (e.g. 255.255.255.255, 172.20.10.255, etc.)
                broadcast_targets = get_all_subnet_broadcasts()
                for target_bc in broadcast_targets:
                    try:
                        self.sock.sendto(data, (target_bc, DISCOVERY_PORT))
                    except Exception:
                        pass
            except Exception:
                pass
            time.sleep(1.8)

    def stop(self):
        self.running = False
        if self.sock:
            try:
                self.sock.close()
            except Exception:
                pass
        print("[MTMMS Discovery] Stopped.", flush=True)


if __name__ == '__main__':
    api_p = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 8000
    web_p = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2].isdigit() else 5174
    server = DiscoveryServer(api_port=api_p, web_port=web_p)
    server.start()
