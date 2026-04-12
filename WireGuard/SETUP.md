# WireGuard VPN Setup

Private VPN tunnel between local dev machine and VPS. All infrastructure services (ES, RabbitMQ, Redis, ScyllaDB) are accessible only via this VPN — not exposed to the public internet.

## SSH Key Setup (Prerequisite)

Key-based SSH access to the VPS is needed for automated tools and scripting.

### 1. Generate a dedicated key

```bash
ssh-keygen -t ed25519 -f ~/.ssh/vps_elk -N ""
```

### 2. Copy public key to VPS

```bash
ssh-copy-id -i ~/.ssh/vps_elk.pub root@93.127.194.47
```

This will prompt for the VPS password one last time.

### 3. Test passwordless login

```bash
ssh -i ~/.ssh/vps_elk root@93.127.194.47 echo "connected"
```

### 4. Usage

```bash
# Interactive SSH
ssh -i ~/.ssh/vps_elk root@93.127.194.47

# Run remote commands from local
ssh -i ~/.ssh/vps_elk root@93.127.194.47 "docker ps"
```

Key location: `~/.ssh/vps_elk` (private), `~/.ssh/vps_elk.pub` (public)

## Network Layout

| Node | WireGuard IP | Role |
|---|---|---|
| VPS (93.127.194.47) | 10.0.0.1 | Server — runs all services |
| Dev Mac | 10.0.0.2 | Client — local development |

- WireGuard port: **51820/UDP** (must be open in VPS firewall)
- Subnet: `10.0.0.0/24`

## VPS Setup (Server)

### 1. Install WireGuard

```bash
apt update && apt install -y wireguard
```

### 2. Generate server keys

```bash
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
chmod 600 /etc/wireguard/server_private.key
```

### 3. Create server config

```bash
cat > /etc/wireguard/wg0.conf << 'EOF'
[Interface]
PrivateKey = <SERVER_PRIVATE_KEY>
Address = 10.0.0.1/24
ListenPort = 51820

[Peer]
# Dev Mac
PublicKey = <MAC_PUBLIC_KEY>
AllowedIPs = 10.0.0.2/32
EOF

chmod 600 /etc/wireguard/wg0.conf
```

Replace `<SERVER_PRIVATE_KEY>` with contents of `/etc/wireguard/server_private.key`.
Replace `<MAC_PUBLIC_KEY>` with the Mac's public key (generated below).

### 4. Enable and start

```bash
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0
```

### 5. Open firewall port

```bash
ufw allow 51820/udp
```

### 6. Verify

```bash
wg show
```

## Mac Setup (Client)

### 1. Install WireGuard

```bash
brew install wireguard-tools
```

Or install the **WireGuard app** from the Mac App Store for a GUI.

### 2. Generate client keys

```bash
mkdir -p /usr/local/etc/wireguard
wg genkey | tee /usr/local/etc/wireguard/client_private.key | wg pubkey > /usr/local/etc/wireguard/client_public.key
chmod 600 /usr/local/etc/wireguard/client_private.key
```

### 3. Create client config

```bash
cat > /usr/local/etc/wireguard/wg0.conf << 'EOF'
[Interface]
PrivateKey = <MAC_PRIVATE_KEY>
Address = 10.0.0.2/24

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = 93.127.194.47:51820
AllowedIPs = 10.0.0.1/32
PersistentKeepalive = 25
EOF
```

Replace `<MAC_PRIVATE_KEY>` with contents of `/usr/local/etc/wireguard/client_private.key`.
Replace `<SERVER_PUBLIC_KEY>` with the VPS server public key.

### 4. Connect

```bash
# Start
sudo wg-quick up wg0

# Stop
sudo wg-quick down wg0

# Check status
sudo wg show
```

### 5. Verify

```bash
ping 10.0.0.1
```

## Firewall (UFW) — Block Public, Allow VPN

Services bind to `0.0.0.0` in Docker (required for both Traefik and WireGuard access). UFW blocks public access to sensitive ports — only the WireGuard subnet `10.0.0.0/24` can reach them.

```bash
ufw default allow outgoing
ufw default deny incoming

# Always allow
ufw allow 22/tcp          # SSH
ufw allow 51820/udp       # WireGuard
ufw allow 80/tcp           # Traefik HTTP
ufw allow 443/tcp          # Traefik HTTPS
ufw allow 8000/tcp         # Coolify UI

# Allow all traffic from VPN
ufw allow from 10.0.0.0/24

# ScyllaDB & Redis (public for now — migrate to VPN-only later)
ufw allow 9042/tcp
ufw allow 9044/tcp
ufw allow 9045/tcp
ufw allow 6380/tcp

echo "y" | ufw enable
```

ES (9200) and RabbitMQ (5672, 15672) are NOT in the allow list — only reachable via WireGuard.

### Local `.env` — Point to VPS WireGuard IP

```
ELASTICSEARCH_NODE=http://10.0.0.1:9200
ELASTICSEARCH_USERNAME=elastic
ELASTICSEARCH_PASSWORD=<your-password>
RABBITMQ_URL=amqp://admin:password@10.0.0.1:5672
REDIS_URL=redis://10.0.0.1:6380
SCYLLA_CONTACT_POINTS=10.0.0.1:9042,10.0.0.1:9045,10.0.0.1:9044
```

## Adding More Clients

To add another dev machine:

1. Generate keys on the new machine
2. Assign next IP (e.g., `10.0.0.3/32`)
3. Add a `[Peer]` block to the VPS `/etc/wireguard/wg0.conf`
4. Reload: `systemctl restart wg-quick@wg0`

## Troubleshooting

| Symptom | Fix |
|---|---|
| Can't connect | Check `ufw allow 51820/udp` on VPS |
| Handshake but no traffic | Check `AllowedIPs` on both sides |
| Connection drops after sleep | `PersistentKeepalive = 25` handles this |
| Port unreachable after Docker restart | Ensure ports bind to `10.0.0.1` not `127.0.0.1` |

## Cleanup — Remove SSH Tunnel (after WireGuard works)

```bash
# Mac — remove LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.elk.tunnel.plist
rm ~/Library/LaunchAgents/com.elk.tunnel.plist

# Optional — remove SSH config entry
# Edit ~/.ssh/config and remove the "Host elk-tunnel" block
```
