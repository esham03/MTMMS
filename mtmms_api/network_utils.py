"""
MTMMS Network Utilities
Provides dynamic active LAN IPv4 address detection, multi-interface support,
global cloud tunnel integration, runtime configuration generation,
and health checking for deployments across ANY network.
"""

import sys
import os
import socket
import json
import subprocess
import urllib.request
from pathlib import Path


def is_valid_lan_ip(ip_str):
    """Returns True if the IP string is a valid non-loopback, non-APIPA IPv4 address."""
    if not ip_str or not isinstance(ip_str, str):
        return False
    ip_str = ip_str.strip()
    if ip_str.startswith('127.') or ip_str.startswith('169.254.') or ip_str == '0.0.0.0':
        return False
    parts = ip_str.split('.')
    if len(parts) != 4:
        return False
    for part in parts:
        if not part.isdigit() or not (0 <= int(part) <= 255):
            return False
    return True


def get_all_lan_ips():
    """
    Returns a deduplicated list of all active non-loopback, non-APIPA LAN IPv4 addresses on this machine.
    Prioritizes active Wi-Fi and physical Ethernet adapters.
    """
    ips = []

    # 1. On Windows, query PowerShell Get-NetIPAddress with interface alias inspection
    if sys.platform == 'win32':
        try:
            ps_cmd = (
                "Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | "
                "Where-Object { "
                "  $_.IPAddress -notlike '127.*' -and "
                "  $_.IPAddress -notlike '169.254.*' -and "
                "  $_.InterfaceAlias -notmatch 'Loopback|vEthernet|WSL|VMware|VirtualBox|Docker|VPN|Bluetooth' "
                "} | "
                "Sort-Object -Property @{Expression={if($_.InterfaceAlias -match 'Wi-Fi|Wireless|Ethernet|LAN') {0} else {1}}} | "
                "Select-Object -ExpandProperty IPAddress"
            )
            result = subprocess.run(
                ["powershell", "-NoProfile", "-NonInteractive", "-Command", ps_cmd],
                capture_output=True,
                text=True,
                timeout=5.0
            )
            for line in result.stdout.strip().splitlines():
                candidate = line.strip()
                if is_valid_lan_ip(candidate) and candidate not in ips:
                    ips.append(candidate)
        except Exception:
            pass

    # 2. Socket routing resolution targets
    test_targets = [
        ('192.168.255.255', 1),
        ('10.255.255.255', 1),
        ('172.31.255.255', 1),
        ('192.168.1.1', 80),
        ('192.168.0.1', 80),
        ('10.0.0.1', 80),
        ('8.8.8.8', 80),
        ('1.1.1.1', 80)
    ]
    for host, port in test_targets:
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.settimeout(0.4)
            s.connect((host, port))
            ip = s.getsockname()[0]
            s.close()
            if is_valid_lan_ip(ip) and ip not in ips:
                ips.append(ip)
        except Exception:
            continue

    # 3. gethostbyname_ex fallback
    try:
        hostname = socket.gethostname()
        for ip in socket.gethostbyname_ex(hostname)[2]:
            if is_valid_lan_ip(ip) and ip not in ips:
                ips.append(ip)
    except Exception:
        pass

    # If completely isolated, fallback to loopback
    if not ips:
        ips.append('127.0.0.1')

    return ips


def get_active_lan_ip():
    """
    Detects the primary active LAN IPv4 address of this machine.
    """
    env_ip = os.getenv('MTMMS_SERVER_IP', '').strip()
    if is_valid_lan_ip(env_ip):
        return env_ip

    all_ips = get_all_lan_ips()
    return all_ips[0] if all_ips else '127.0.0.1'


def get_subnet_broadcast(ip):
    """Computes a standard class C broadcast address for the given IPv4 address."""
    try:
        parts = ip.split('.')
        if len(parts) == 4:
            return f"{parts[0]}.{parts[1]}.{parts[2]}.255"
    except Exception:
        pass
    return '255.255.255.255'


def get_all_subnet_broadcasts():
    """Returns broadcast addresses for all active LAN adapters on this host."""
    broadcasts = {'255.255.255.255'}
    for ip in get_all_lan_ips():
        if ip != '127.0.0.1':
            bc = get_subnet_broadcast(ip)
            if bc:
                broadcasts.add(bc)
    return list(broadcasts)


def get_saved_tunnel_url(project_root):
    """Reads any active tunnel URL from environment or .mtmms-runtime.env."""
    env_tunnel = os.getenv('MTMMS_TUNNEL_URL', '').strip()
    if env_tunnel and (env_tunnel.startswith('http://') or env_tunnel.startswith('https://')):
        return env_tunnel

    runtime_env_path = project_root / '.mtmms-runtime.env'
    if runtime_env_path.is_file():
        try:
            with open(runtime_env_path, 'r', encoding='utf-8') as f:
                for line in f:
                    if line.startswith('MTMMS_TUNNEL_URL='):
                        val = line.split('=', 1)[1].strip()
                        if val and (val.startswith('http://') or val.startswith('https://')):
                            return val
        except Exception:
            pass
    return ''


def generate_runtime_configs(project_root_str=None, api_port=8000, web_port=5174, override_ip=None, tunnel_url=None):
    """
    Generates single source of truth configurations across:
    1. <root>/.mtmms-runtime.env
    2. web/.env
    3. web/dist-desktop/.../.env (if packaged Electron exists)
    4. mobile_tower_app/lib/config/server_config.dart
    """
    if project_root_str:
        project_root = Path(project_root_str).resolve()
    else:
        project_root = Path(__file__).resolve().parent.parent

    # Allow environment override for ports
    api_port_env = os.getenv('MTMMS_API_PORT') or os.getenv('MTMMS_PORT')
    if api_port_env and api_port_env.isdigit():
        api_port = int(api_port_env)

    web_port_env = os.getenv('MTMMS_WEB_PORT')
    if web_port_env and web_port_env.isdigit():
        web_port = int(web_port_env)

    lan_ip = override_ip if override_ip and is_valid_lan_ip(override_ip) else get_active_lan_ip()
    all_lan_ips = get_all_lan_ips()
    if lan_ip not in all_lan_ips and lan_ip != '127.0.0.1':
        all_lan_ips.insert(0, lan_ip)

    api_url = f"http://{lan_ip}:{api_port}/api"
    web_url = f"http://{lan_ip}:{web_port}"
    health_url = f"http://{lan_ip}:{api_port}/api/health/"

    active_tunnel = tunnel_url or get_saved_tunnel_url(project_root)
    tunnel_api_url = f"{active_tunnel.rstrip('/')}/api" if active_tunnel else ''

    # 1. Root .mtmms-runtime.env (Single Source of Truth)
    runtime_env_path = project_root / '.mtmms-runtime.env'
    runtime_env_content = f"""# MTMMS Dynamic Runtime Configuration (Auto-generated by Start-Live-System.bat)
# DO NOT EDIT MANUALLY - This file is automatically regenerated on each system start.
MTMMS_SERVER_IP={lan_ip}
MTMMS_ALL_IPS={','.join(all_lan_ips)}
MTMMS_API_PORT={api_port}
MTMMS_API_URL={api_url}
MTMMS_WEB_PORT={web_port}
MTMMS_WEB_URL={web_url}
MTMMS_HEALTH_URL={health_url}
MTMMS_TUNNEL_URL={active_tunnel}
MTMMS_TUNNEL_API_URL={tunnel_api_url}
ALLOWED_HOSTS=*
CORS_ORIGINS=*
"""
    with open(runtime_env_path, 'w', encoding='utf-8') as f:
        f.write(runtime_env_content)

    # 2. web/.env
    web_dir = project_root / 'web'
    if web_dir.is_dir():
        web_env_path = web_dir / '.env'
        web_env_content = f"""# Auto-generated Vite environment (MTMMS Live System)
VITE_API_URL={api_url}
VITE_API_BASE_URL={api_url}
VITE_SERVER_IP={lan_ip}
VITE_API_PORT={api_port}
VITE_WEB_PORT={web_port}
VITE_TUNNEL_URL={active_tunnel}
"""
        with open(web_env_path, 'w', encoding='utf-8') as f:
            f.write(web_env_content)

    # 3. web/dist-desktop/.../.env (Electron packaged folder if present)
    electron_app_dir = project_root / 'web' / 'dist-desktop' / 'MTMMS Desktop-win32-x64' / 'resources' / 'app'
    if electron_app_dir.is_dir():
        try:
            electron_env_path = electron_app_dir / '.env'
            with open(electron_env_path, 'w', encoding='utf-8') as f:
                f.write(f"VITE_API_URL={api_url}\n")
        except Exception:
            pass

    # 4. mobile_tower_app/lib/config/server_config.dart
    flutter_config_dir = project_root / 'mobile_tower_app' / 'lib' / 'config'
    flutter_config_dir.mkdir(parents=True, exist_ok=True)
    flutter_config_file = flutter_config_dir / 'server_config.dart'
    all_ips_dart_str = ', '.join([f"'{ip}'" for ip in all_lan_ips])
    flutter_config_content = f"""// AUTO-GENERATED BY Start-Live-System.bat
// DO NOT EDIT MANUALLY - Automatically updated on every server launch

class GeneratedServerConfig {{
  static const String serverIp = '{lan_ip}';
  static const List<String> allServerIps = [{all_ips_dart_str}];
  static const int apiPort = {api_port};
  static const String apiUrl = '{api_url}';
  static const String healthUrl = '{health_url}';
  static const String tunnelUrl = '{tunnel_api_url}';
  static const int discoveryPort = 41588;
}}
"""
    with open(flutter_config_file, 'w', encoding='utf-8') as f:
        f.write(flutter_config_content)

    return {
        'ip': lan_ip,
        'all_ips': all_lan_ips,
        'api_port': api_port,
        'web_port': web_port,
        'api_url': api_url,
        'web_url': web_url,
        'health_url': health_url,
        'tunnel_url': active_tunnel,
        'tunnel_api_url': tunnel_api_url,
    }


def check_api_health(url, timeout=3):
    """Checks whether the Django API health endpoint responds with 200 OK and valid JSON."""
    try:
        proxy_handler = urllib.request.ProxyHandler({})
        opener = urllib.request.build_opener(proxy_handler)
        req = urllib.request.Request(
            url,
            headers={
                'User-Agent': 'MTMMS-Startup-Verifier/1.0',
                'Accept': 'application/json',
                'bypass-tunnel-reminder': 'true'
            }
        )
        with opener.open(req, timeout=timeout) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                if data.get('status') == 'ok':
                    return True, data
        return False, "Invalid response status or body"
    except Exception as e:
        return False, str(e)


if __name__ == '__main__':
    mode = sys.argv[1] if len(sys.argv) > 1 else 'detect'
    root_arg = sys.argv[2] if len(sys.argv) > 2 else None

    if mode == 'detect':
        print(get_active_lan_ip())
    elif mode == 'all_ips':
        print(','.join(get_all_lan_ips()))
    elif mode == 'generate':
        info = generate_runtime_configs(root_arg)
        print(json.dumps(info, indent=2))
    elif mode == 'set_tunnel':
        t_url = sys.argv[2] if len(sys.argv) > 2 else ''
        root_dir = sys.argv[3] if len(sys.argv) > 3 else None
        info = generate_runtime_configs(root_dir, tunnel_url=t_url)
        print(json.dumps(info, indent=2))
    elif mode == 'simulate':
        sim_ip = sys.argv[2] if len(sys.argv) > 2 else '192.168.0.25'
        root = sys.argv[3] if len(sys.argv) > 3 else None
        info = generate_runtime_configs(root, override_ip=sim_ip)
        print(json.dumps(info, indent=2))
    elif mode == 'health':
        target_url = sys.argv[2] if len(sys.argv) > 2 else 'http://127.0.0.1:8000/api/health/'
        ok, res = check_api_health(target_url)
        if not ok and '127.0.0.1' not in target_url and 'localhost' not in target_url:
            # Fallback check on loopback
            api_port = os.getenv('MTMMS_API_PORT', '8000')
            ok, res = check_api_health(f'http://127.0.0.1:{api_port}/api/health/')
        if ok:
            print("OK")
            sys.exit(0)
        else:
            print(f"FAILED: {res}")
            sys.exit(1)
