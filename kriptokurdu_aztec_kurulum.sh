#!/bin/bash
clear
set -e

# Renk tanımları
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
sleep 5

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Lütfen bu scripti root olarak çalıştırın!${NC}"
  exit 1
fi

# Home dizinine geç
cd ~

# Sistem güncelleme ve bağımlılıklar
echo -e "${CYAN}🔧 Sistem güncelleniyor ve paketler yükleniyor...${NC}"
apt-get update && apt-get upgrade -y
apt-get install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip dnsutils net-tools docker.io ufw nginx

# DNS ve hosts ayarları
echo -e "${CYAN}🌐 DNS ve hosts yapılandırılıyor...${NC}"
cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
cat >> /etc/hosts <<EOF
104.21.31.61 static.aztec.network
172.67.211.145 bootnode-alpha-1.aztec.network bootnode-alpha-2.aztec.network bootnode-alpha-3.aztec.network
EOF

# NGINX statik bootnode sunucusu
echo -e "${CYAN}🌍 Statik bootnode sunucusu ayarlanıyor...${NC}"
mkdir -p /var/www/html/alpha-testnet/
cat > /var/www/html/alpha-testnet/bootnodes.json << 'EOL'
[
  "/dns/bootnode-alpha-1.aztec.network/tcp/40400"
]
EOL
systemctl enable nginx && systemctl restart nginx

# UFW yapılandırması
echo -e "${CYAN}🧱 Güvenlik duvarı ayarlanıyor...${NC}"
ufw allow ssh
ufw allow 40400/tcp
ufw allow 40400/udp
ufw allow 8080
ufw --force enable

# Aztec CLI kurulumu
echo -e "${CYAN}🚀 Aztec CLI kuruluyor...${NC}"
bash -i <(curl -s https://install.aztec.network)

echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Test ve upgrade to latest alpha-testnet aztec tools
echo -e "${CYAN}🔄 Aztec tools güncelleniyor (alpha-testnet)...${NC}"
aztec-up alpha-testnet

# Kullanıcı girdileri
read -p "🔐 EVM cüzdan adresinizi girin: " COINBASE
read -p "🌍 Sepolia RPC URL (ETHEREUM_HOSTS): " RPC_URL

# Genel IP
PUBLIC_IP=$(curl -s https://api.ipify.org)
echo "Detected public IP: $PUBLIC_IP"
read -p "Bu IP'yi kullanmak ister misiniz? (e/h): " USE_IP
if [[ "$USE_IP" == "e" ]]; then
  LOCAL_IP=$PUBLIC_IP
else
  read -p "📡 Lütfen IP adresinizi girin: " LOCAL_IP
fi

# Beacon consensus RPC otomatik test
echo -e "${CYAN}🛰️ Beacon consensus RPC test ediliyor...${NC}"
for url in "https://rpc.drpc.org/eth/sepolia/beacon" "https://lodestar-sepolia.chainsafe.io"; do
  echo -n "Testing $url..."
  if curl -sf "$url" -o /dev/null; then
    CONSENSUS_URL=$url
    echo -e "${GREEN} OK${NC}"
    break
  else
    echo -e "${RED} FAIL${NC}"
  fi
done
if [ -z "$CONSENSUS_URL" ]; then
  read -p "🛰️ Çalışan Beacon RPC URL'sini girin: " CONSENSUS_URL
fi

# Node başlatma
echo -e "${GREEN}🚦 Aztec node başlatılıyor...${NC}"
aztec start \
  --network alpha-testnet \
  --l1-rpc-urls "$RPC_URL" \
  --l1-consensus-host-urls "$CONSENSUS_URL" \
  --sequencer.validatorPrivateKey "$PRIVATE_KEY" \
  --p2p.p2pIp "$LOCAL_IP" \
  --p2p.maxTxPoolSize 1000000000 \
  --archiver \
  --node \
  --sequencer

# Log takibi
echo -e "${CYAN}📊 Logları izlemek için:${NC} aztec logs --follow"
echo -e "${CYAN}📋 Alternatif Docker log komutu:${NC} docker logs -f aztec-node"

echo -e "${GREEN}✅ Kurulum ve başlatma tamamlandı!${NC}"
