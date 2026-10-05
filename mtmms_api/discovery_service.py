"""
MTMMS LAN Discovery Service
Listens on UDP port 41588 for discovery probes from Flutter APK / mobile devices
and sends periodic discovery beacons across the local subnet.
"""

import sys
import time
import socket
import json
import threading
from network_utils import get_active_lan_ip, get_subnet_broadcast

DISCOVERY_PORT = 41588
BUFFER_SIZE = 1024

class DiscoveryServer:
    def __init__(self, api_port=8000, web_port=5174):
        self.api_port = api_port
        self.web_port = web_port
        self.running = False
        self.sock = None
        self.cached_lan_ip = None
        self.last_ip_check = 0

    def get_lan_ip(self, force_refresh=False):
        now = time.time()
        if force_refresh or not self.cached_lan_ip or (now - self.last_ip_check > 15):
            self.cached_lan_ip = get_active_lan_ip()
            self.last_ip_check = now
        return self.cached_lan_ip

    def get_payload(self):
        lan_ip = self.get_lan_ip()
        return {
            "service": "MTMMS",
            "version": "1.0",
            "device_name": "MTMMS Server",
            "server_ip": lan_ip,
            "api_port": self.api_port,
            "web_port": self.web_port,
            "api_url": f"http://{lan_ip}:{self.api_port}/api",
            "health_url": f"http://{lan_ip}:{self.api_port}/api/health/",
            "web_url": f"http://{lan_ip}:{self.web_port}",
            "timestamp": int(time.time()),
        }

    def start(self):
        self.running = True

        # 1. Initialize UDP socket immediately so it is instantly reachable
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        except Exception:
            pass
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        self.sock.bind(('0.0.0.0', DISCOVERY_PORT))

        # 2. Resolve initial IP
        lan_ip = self.get_lan_ip(force_refresh=True)
        print(f"[MTMMS Discovery] Active on UDP port {DISCOVERY_PORT}", flush=True)
        print(f"[MTMMS Discovery] Advertising MTMMS API at http://{lan_ip}:{self.api_port}/api", flush=True)

        # 3. Start background announcement broadcaster
        broadcast_thread = threading.Thread(target=self._broadcast_loop, daemon=True)
        broadcast_thread.start()

        # 4. Listen for discovery requests with instant responses
        try:
            while self.running:
                try:
                    data, addr = self.sock.recvfrom(BUFFER_SIZE)
                    message = data.decode('utf-8', errors='ignore').strip()
                    if "MTMMS_DISCOVER" in message or "MTMMS" in message:
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
        """Periodically broadcast server presence on LAN"""
        while self.running:
            try:
                lan_ip = self.get_lan_ip()
                payload = self.get_payload()
                payload["type"] = "beacon"
                data = json.dumps(payload).encode('utf-8')
                
                # Send to universal broadcast address
                self.sock.sendto(data, ('255.255.255.255', DISCOVERY_PORT))
                
                # Also send to directed subnet broadcast address
                subnet_bc = get_subnet_broadcast(lan_ip)
                if subnet_bc != '255.255.255.255':
                    self.sock.sendto(data, (subnet_bc, DISCOVERY_PORT))
            except Exception:
                pass
            time.sleep(2.0)

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
