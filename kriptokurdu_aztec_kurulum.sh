#!/bin/bash
clear
set -e

# Renkleri tanımla
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Banner
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}           ${YELLOW}K R İ P T O   K U R D U   N O D E${NC}"
echo -e "${BLUE}                  ${GREEN}Aztec Node Kurulum${NC}"
echo -e "${BLUE}🐺 Twitter:  ${GREEN}https://x.com/kriptokurduu${NC}"
echo -e "${BLUE}🌐 Telegram: ${GREEN}https://t.me/kriptokurdugrup${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
sleep 7

# Root olarak çalıştır
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Lütfen bu scripti root olarak çalıştırın!${NC}"
  echo -e "${YELLOW}Aşağıdaki komutu kullanabilirsiniz:${NC}"
  echo -e "${GREEN}curl -O https://raw.githubusercontent.com/eCoxvague/Aztec/main/kriptokurdu_aztec_kurulum.sh && chmod +x kriptokurdu_aztec_kurulum.sh && sudo ./kriptokurdu_aztec_kurulum.sh${NC}"
  exit 1
fi

# Ana dizine git
cd ~

# Geçici dizin oluştur
tmpdir=$(mktemp -d)
cd "$tmpdir"

# Bootnodes.json dosyasını oluştur
cat > bootnode.json << 'EOL'
{
  "sequence": {
    "contractAddresses": { ... }
    ,"chain": { "bootnodes": ["/dns/bootnode-alpha-1.aztec.network/tcp/40400"] }
  }
}
EOL

# Sistem güncelleme ve bağımlılıklar
echo -e "${CYAN}🔧 Sistem güncelleniyor ve paketler yükleniyor...${NC}"
apt-get update && apt-get upgrade -y
apt-get install -y curl jq nginx tmux htop ufw docker.io

# DNS ve hosts ayarları
echo -e "${CYAN}🌐 DNS ve hosts yapılandırılıyor...${NC}"
cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

cat >> /etc/hosts <<EOF
104.21.31.61 static.aztec.network
172.67.211.145 bootnode-alpha-1.aztec.network
EOF

# NGINX statik sunucu ayarla
mkdir -p /var/www/html/alpha-testnet
echo "Serving bootnode.json"
cp bootnode.json /var/www/html/alpha-testnet/bootnodes.json
systemctl enable nginx && systemctl start nginx

# UFW yapılandırması
echo -e "${CYAN}🧱 UFW yapılandırılıyor...${NC}"
ufw allow ssh; ufw allow 40400/tcp; ufw allow 40400/udp; ufw --force enable

# Kullanıcıdan bilgiler
read -p "🔐 EVM cüzdan adresinizi girin: " COINBASE
read -p "🌍 Sepolia RPC URL (ETHEREUM_HOSTS): " RPC_URL
read -p "🔑 Validator özel anahtarınızı girin: " PRIVATE_KEY

# General IP
echo -e "${CYAN}🌐 Genel IP alınıyor...${NC}"
PUBLIC_IP=$(curl -s https://api.ipify.org)
echo "Algılanan IP: $PUBLIC_IP"
read -p "Bu IP'yi kullanmak istiyor musunuz? (e/h): " use_ip
if [[ "$use_ip" != "e" ]]; then
  read -p "📡 IP adresinizi girin: " LOCAL_IP
else
  LOCAL_IP=$PUBLIC_IP
fi

# Beacon consensus RPC otomatik test
echo -e "${CYAN}🛰️ Beacon consensus RPC test ediliyor...${NC}"
for u in https://rpc.drpc.org/eth/sepolia/beacon https://lodestar-sepolia.chainsafe.io; do
  if curl -sf "$u" -o /dev/null; then
    CONSENSUS_URL=$u
    echo -e "${GREEN}Seçilen consensus RPC: $u${NC}"
    break
  fi
done
if [ -z "$CONSENSUS_URL" ]; then
  read -p "🛰️ Çalışan Beacon RPC URL'sini girin: " CONSENSUS_URL
fi

# Data dizini ve config hazırlığı
DATA_DIR=~/aztec-data
mkdir -p "$DATA_DIR/config"
# Resmi config indir ve bootstrap ekle
curl -s https://static.aztec.network/config/alpha-testnet.json | \
  jq '.p2pBootstrapNodes=["/dns/bootnode-alpha-1.aztec.network/tcp/40400"]' \
  > "$DATA_DIR/config/alpha-testnet.json"

# Docker container başlat
echo -e "${GREEN}🚦 Aztec node başlatılıyor...${NC}"
docker stop aztec-node 2>/dev/null || true
docker rm aztec-node 2>/dev/null || true
docker run -d --name aztec-node --network host \
  -v "$DATA_DIR":/data \
  -v "$DATA_DIR/config":/usr/src/yarn-project/aztec/dest/cli/config \
  -e DATA_DIRECTORY=/data \
  -e ETHEREUM_HOSTS="$RPC_URL" \
  -e L1_CONSENSUS_HOST_URLS="$CONSENSUS_URL" \
  -e COINBASE="$COINBASE" \
  -e VALIDATOR_PRIVATE_KEY="$PRIVATE_KEY" \
  -e P2P_IP="$LOCAL_IP" \
  -e LOG_LEVEL=debug \
  -e NETWORK_NAME=alpha-testnet \
  --restart unless-stopped aztecprotocol/aztec:alpha-testnet \
  node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --archiver --node --sequencer

# Durum kontrolü
sleep 5
if docker ps | grep -q aztec-node; then
  echo -e "${GREEN}Node çalışıyor!${NC}"
else
  echo -e "${RED}Node başlatılamadı. Logları kontrol edin.${NC}"
fi

# Tmux log takibi
tmux kill-session -t aztec-logs 2>/dev/null || true
tmux new-session -d -s aztec-logs "docker logs -f aztec-node"

echo -e "${GREEN}Kurulum tamamlandı!${NC}"
cd ~ && rm -rf "$tmpdir"
