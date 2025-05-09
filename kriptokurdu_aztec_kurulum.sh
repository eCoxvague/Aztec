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
sleep 5

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Lütfen bu scripti root olarak çalıştırın!${NC}"
  echo -e "${YELLOW}# curl -O https://raw.githubusercontent.com/eCoxvague/Aztec/main/kriptokurdu_aztec_kurulum.sh && chmod +x kriptokurdu_aztec_kurulum.sh && sudo ./kriptokurdu_aztec_kurulum.sh${NC}"
  exit 1
fi

# Ana dizine git ve temp dizini oluştur
cd
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Sistem güncelleme ve temel paketler yükleniyor
echo -e "${CYAN}🔧 Sistem güncelleniyor ve gerekli paketler yükleniyor...${NC}"
apt-get update && apt-get upgrade -y
apt-get install -y curl jq nginx tmux htop ufw docker.io

# DNS yapılandırması
echo -e "${CYAN}🌐 DNS yapılandırılıyor ve hosts güncelleniyor...${NC}"
cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

cat >> /etc/hosts <<EOF
104.21.31.61 static.aztec.network
172.67.211.145 bootnode-alpha-1.aztec.network
EOF

# UFW yapılandırması
echo -e "${CYAN}🧱 UFW yapılandırılıyor...${NC}"
ufw allow ssh
ufw allow 40400/tcp
ufw allow 40400/udp
ufw --force enable

# Kullanıcı girdileri
read -p "$(echo -e ${YELLOW}🔐 EVM cüzdan adresinizi girin:${NC} )" COINBASE
read -p "$(echo -e ${YELLOW}🌐 Sepolia RPC URL (ETHEREUM_HOSTS):${NC} )" RPC_URL

# Beacon consensus URL otomatik test et
echo -e "${CYAN}🛰️ Beacon consensus RPC URL otomatik test ediliyor...${NC}"
CONSENSUS_URL=""
for url in "https://rpc.drpc.org/eth/sepolia/beacon" "https://lodestar-sepolia.chainsafe.io"; do
  echo -e "${CYAN}   Testing $url...${NC}"
  if curl -sf "$url" -o /dev/null; then
    CONSENSUS_URL=$url
    echo -e "${GREEN}✅ Consensus RPC seçildi: $url${NC}"
    break
  else
    echo -e "${YELLOW}⚠️ $url erişilemedi${NC}"
  fi
done
if [ -z "$CONSENSUS_URL" ]; then
  read -p "$(echo -e ${YELLOW}🛰️ Çalışan Beacon RPC URL'sini girin:${NC} )" CONSENSUS_URL
fi

# Genel IP al
public_ip=$(curl -s ipinfo.io/ip)
echo -e "${GREEN}📡 Algılanan IP adresiniz: ${YELLOW}$public_ip${NC}"
read -p "$(echo -e ${YELLOW}Bu IP'yi kullanmak istiyor musunuz? (e/h):${NC} )" use_ip
if [ "$use_ip" = "e" ]; then
  LOCAL_IP=$public_ip
else
  read -p "$(echo -e ${YELLOW}📡 Yerel IP adresinizi girin:${NC} )" LOCAL_IP
fi

# Docker servisi başlat
echo -e "${CYAN}🐳 Docker servisi başlatılıyor...${NC}"
systemctl enable docker
systemctl start docker

# Data dizini ve config hazırlığı
DATA_DIR="/root/aztec-data"
mkdir -p "$DATA_DIR/config"

echo -e "${CYAN}📥 Alpha-testnet resmi config indiriliyor ve bootstrap nodes ekleniyor...${NC}"
curl -s https://static.aztec.network/config/alpha-testnet.json | \
  jq '.p2pBootstrapNodes = ["/dns/bootnode-alpha-1.aztec.network/tcp/40400"]' \
  > "$DATA_DIR/config/alpha-testnet.json"

# Aztec node'u Docker ile başlat
echo -e "${GREEN}🚦 Aztec node başlatılıyor...${NC}"
docker stop aztec-node 2>/dev/null || true
docker rm aztec-node 2>/dev/null || true

docker run -d \
  --name aztec-node \
  --network host \
  -v "$DATA_DIR":/data \
  -v "$DATA_DIR/config":/usr/src/yarn-project/aztec/dest/cli/config \
  -e DATA_DIRECTORY=/data \
  -e ETHEREUM_HOSTS="$RPC_URL" \
  -e L1_CONSENSUS_HOST_URLS="$CONSENSUS_URL" \
  -e COINBASE="$COINBASE" \
  -e VALIDATOR_PRIVATE_KEY="$PRIVATE_KEY" \
  -e P2P_IP="$LOCAL_IP" \
  -e LOG_LEVEL=debug \
  -e NETWORK_NAME="alpha-testnet" \
  --restart unless-stopped \
  aztecprotocol/aztec:alpha-testnet \
  sh -c "node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --archiver --node --sequencer"

# Durum kontrolü
sleep 5
if docker ps | grep -q aztec-node; then
  echo -e "${GREEN}✅ Aztec node başarıyla başlatıldı!${NC}"
  docker ps | grep aztec-node
else
  echo -e "${RED}❌ Node başlatılamadı, logları kontrol ediniz:${NC}"
  docker logs aztec-node --tail 50
  exit 1
fi

# Tmux log takibi
echo -e "${CYAN}📊 Tmux oturumu oluşturuluyor (aztec-logs)...${NC}"
tmux kill-session -t aztec-logs 2>/dev/null || true
tmux new-session -d -s aztec-logs "docker logs -f aztec-node"

# Yönetim komutları ekrana yaz
cat <<EOF

${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}
${YELLOW}   Node Yönetimi Komutları:${NC}
  docker logs -f aztec-node    (logları izle)
  docker ps | grep aztec-node  (durum kontrolü)
  docker restart aztec-node    (yeniden başlat)
  docker stop aztec-node       (durdur)
${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}

${CYAN}🔗 Sepolia RPC URL:        ${RPC_URL}
${CYAN}🔗 Consensus RPC URL:      ${CONSENSUS_URL}
${CYAN}📡 P2P IP:                 ${LOCAL_IP}
${CYAN}💾 Data dizini:            ${DATA_DIR}

${GREEN}✅ Kurulum ve başlatma tamamlandı!${NC}
EOF

# Cleanup
cd ~
rm -rf "$TEMP_DIR"
