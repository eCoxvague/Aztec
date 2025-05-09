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
NC='\033[0m' # Renk yok

# Banner
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}           ${YELLOW}K R İ P T O   K U R D U   N O D E${NC}"
echo -e "${BLUE}                  ${GREEN}Aztec Node Kurulum${NC}"
echo -e "${BLUE}🐺 Twitter:  ${GREEN}https://x.com/kriptokurduu${NC}"
echo -e "${BLUE}🌐 Telegram: ${GREEN}https://t.me/kriptokurdugrup${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
sleep 7

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Lütfen bu scripti root olarak çalıştırın!${NC}"
  echo -e "${YELLOW}Aşağıdaki komutu kullanabilirsiniz:${NC}"
  echo -e "${GREEN}curl -O https://raw.githubusercontent.com/eCoxvague/Aztec/main/kriptokurdu_aztec_kurulum.sh && chmod +x kriptokurdu_aztec_kurulum.sh && sudo ./kriptokurdu_aztec_kurulum.sh${NC}"
  exit 1
fi

# Ana dizine dön
cd ~

# Geçici dizin oluştur
tmpdir=$(mktemp -d)
cd "$tmpdir"

# Bootnodes.json dosyasını oluştur
cat > bootnode.json << 'EOL'
{
  "sequence": {
    "contractAddresses": {
      "TmpBridge": "0xCB15f7B73BfCf91e0e385E3f5d0Ed98A5F95dD67",
      "TokenTable": "0xE688e58e511c7D970D29ab6b6c2f89cba3f67861",
      "TokenTableFactory": "0x8bbF5B91bAf849fF8dBFA5A7F27e29EeEC9bAfA4",
      "SequencerNexus": "0x3f770d6fA2C2363E5a69E7C92c13daF39E17c2f3",
      "BlobCache": "0x8c62B8D58c6E07f2D6b2beCdEf71456C168B7d60",
      "Inbox": "0x4cB81cd9f6C77e7FB8d4BD6dA6e0e95Cd3e05e6b",
      "RegistryL1": "0x2234A5F39A17aA4c0bfBFcBd61D246500540b3Ac",
      "RegistryL2": "0x2234A5F39A17aA4c0bfBFcBd61D246500540b3Ac"
    },
    "l1Provider": {
      "network": "sepolia",
      "chainId": 11155111
    },
    "chain": {
      "bootnodes": [
        "/dns/bootnode-alpha-1.aztec.network/tcp/40400"
      ]
    }
  }
}
EOL

# Sistem güncelleme ve temel paketler
echo -e "${CYAN}🔧 Sistem güncelleniyor ve gerekli paketler yükleniyor...${NC}"
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
172.67.211.145 bootnode-alpha-1.aztec.network bootnode-alpha-2.aztec.network bootnode-alpha-3.aztec.network
EOF

# NGINX ile statik sunucu oluştur
echo -e "${CYAN}🌍 Statik bootnode sunucusu ayarlanıyor...${NC}"
mkdir -p /var/www/html/alpha-testnet/
cp bootnode.json /var/www/html/alpha-testnet/bootnodes.json
systemctl enable nginx && systemctl start nginx

# UFW yapılandırması
echo -e "${CYAN}🧱 UFW yapılandırılıyor...${NC}"
ufw allow ssh
ufw allow 40400/tcp
ufw allow 40400/udp
ufw --force enable

# Kullanıcı girdileri
read -p "${YELLOW}🔐 EVM cüzdan adresinizi girin: ${NC}" COINBASE
read -p "${YELLOW}🌍 Sepolia RPC URL (ETHEREUM_HOSTS): ${NC}" RPC_URL
read -p "${YELLOW}🔑 Validator özel anahtarınızı girin: ${NC}" PRIVATE_KEY

# Genel IP algılama
echo -e "${CYAN}🌐 Genel IP alınıyor...${NC}"
PUBLIC_IP=$(curl -s https://api.ipify.org)
echo -e "${GREEN}Algılanan IP: $PUBLIC_IP${NC}"
read -p "${YELLOW}Bu IP'yi kullanmak ister misiniz? (e/h): ${NC}" use_ip
if [ "$use_ip" = "e" ]; then
  LOCAL_IP=$PUBLIC_IP
else
  read -p "${YELLOW}📡 IP adresinizi girin: ${NC}" LOCAL_IP
fi

# Beacon consensus RPC otomatik test
echo -e "${CYAN}🛰️ Beacon consensus RPC test ediliyor...${NC}"
for url in "https://rpc.drpc.org/eth/sepolia/beacon" "https://lodestar-sepolia.chainsafe.io"; do
  echo -n "   Testing $url... "
  if curl -sf "$url" -o /dev/null; then
    CONSENSUS_URL=$url
    echo -e "${GREEN}OK${NC}"
    break
  else
    echo -e "${RED}FAIL${NC}"
  fi
done
if [ -z "$CONSENSUS_URL" ]; then
  read -p "${YELLOW}🛰️ Çalışan Beacon RPC URL'sini girin: ${NC}" CONSENSUS_URL
fi

# Data dizini ve config ayarları
DATA_DIR="/root/aztec-data"
mkdir -p "$DATA_DIR/config"

# Resmi config indir ve p2pBootstrapNodes ekle
echo -e "${CYAN}📥 Resmi alpha-testnet config indiriliyor ve bootstrap nodes ekleniyor...${NC}"
curl -s https://static.aztec.network/config/alpha-testnet.json | \
  jq '.p2pBootstrapNodes = ["/dns/bootnode-alpha-1.aztec.network/tcp/40400"]' \
  > "$DATA_DIR/config/alpha-testnet.json"

# Docker ile node başlatma
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
  node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --archiver --node --sequencer

# Durum kontrolü
sleep 5
if docker ps | grep -q aztec-node; then
  echo -e "${GREEN}✅ Aztec node başarıyla başlatıldı!${NC}"
else
  echo -e "${RED}❌ Node başlatılamadı. Logları kontrol ediniz.${NC}"
  docker logs aztec-node --tail 20
  exit 1
fi

# Tmux ile log takibi oluştur
echo -e "${CYAN}📊 Tmux oturumu oluşturuluyor (aztec-logs)...${NC}"
tmux kill-session -t aztec-logs 2>/dev/null || true
tmux new-session -d -s aztec-logs "docker logs -f aztec-node"

# Yönetim komutları
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}   Node Yönetimi Komutları:${NC}"
echo "   docker logs -f aztec-node    (logları izle)"
echo "   docker ps | grep aztec-node  (durum kontrolü)"
echo "   docker restart aztec-node    (yeniden başlat)"
echo "   docker stop aztec-node       (durdur)"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"

echo -e "${GREEN}✅ Kurulum ve başlatma tamamlandı!${NC}"

# Cleanup
cd ~
rm -rf "$tmpdir"
