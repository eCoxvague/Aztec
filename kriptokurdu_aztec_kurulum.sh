#!/bin/bash

# Renk tanımları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Renk sıfırlama

clear

cat << "EOF"
${CYAN}╔════════════════════════════════════════════════════════════╗
              ${BLUE}K R İ P T O K U R D U   N O D E
              ${MAGENTA}by KriptoKurdu${CYAN}
📡 Twitter:  https://x.com/kriptokurduu
💬 Telegram: https://t.me/kriptokurdugrup
╚════════════════════════════════════════════════════════════╝${NC}
EOF

sleep 2

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Lütfen betiği root olarak çalıştırın (sudo su)${NC}"
  exit 1
fi

cd ~

echo -e "${YELLOW}📦 Sistem paketleri güncelleniyor...${NC}"
apt-get update && apt-get upgrade -y

echo -e "${YELLOW}📚 Gerekli bağımlılıklar kuruluyor...${NC}"
apt install -y \
  curl iptables build-essential git wget lz4 jq make gcc nano \
  automake autoconf tmux htop nvme-cli libgbm1 pkg-config \
  libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip docker.io

echo -e "${GREEN}✅ Bağımlılıklar başarıyla kuruldu${NC}"

echo -e "${YELLOW}🚀 Aztec CLI yüklemesi başlatılıyor...${NC}"
bash -i <(curl -s https://install.aztec.network)

# PATH güncellemesi
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
echo -e "${GREEN}✅ Aztec CLI yüklendi ve PATH güncellendi${NC}"

echo -e "${YELLOW}⚙️  Aztec CLI alpha-testnet için başlatılıyor...${NC}"
aztec
aztec-up alpha-testnet

# Otomatik IP algılama
echo -e "${YELLOW}🌐 Genel IP adresiniz algılanıyor...${NC}"
PUBLIC_IP=$(curl -s https://ipinfo.io/ip)
echo -e "${GREEN}Algılanan IP:${NC} ${BLUE}$PUBLIC_IP${NC}"

# EVM cüzdan adresi
read -p "$(echo -e ${CYAN}🔐 EVM cüzdan adresinizi girin:${NC} )" COINBASE

# Sepolia RPC URL’si
read -p "$(echo -e ${CYAN}🌍 Ethereum Sepolia RPC URL’si girin (örnek: Alchemy):${NC} )" RPC_URL

# Beacon RPC otomatik seçimi
echo -e "${YELLOW}🔍 Beacon consensus RPC uç noktaları test ediliyor...${NC}"
for URL in \
  "https://rpc.drpc.org/eth/sepolia/beacon" \
  "https://lodestar-sepolia.chainsafe.io"
do
  if curl -s -X POST "$URL" \
       -H "Content-Type: application/json" \
       -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
       | grep -q '"result"'; then
    BEACON_URL="$URL"
    echo -e "${GREEN}✔️  Kullanılan Beacon RPC:${NC} ${BLUE}$BEACON_URL${NC}"
    break
  fi
done

if [ -z "$BEACON_URL" ]; then
  echo -e "${RED}❌ Çalışan Beacon RPC uç noktası bulunamadı. Betik sonlandırılıyor.${NC}"
  exit 1
fi

# Validator özel anahtar (gizli giriş)
read -s -p "$(echo -e ${CYAN}🔑 Validator özel anahtarınızı girin:${NC} )" PRIVATE_KEY
echo

# Ortam değişkenleri
export DATA_DIRECTORY=/root/aztec-data/
export COINBASE
export LOG_LEVEL=debug
export P2P_MAX_TX_POOL_SIZE=1000000000
export ETH_RPC_URL="$RPC_URL"
export ETH_BEACON_RPC_URL="$BEACON_URL"
export LOCAL_IP="$PUBLIC_IP"

# Aztec node’u başlat
echo -e "${YELLOW}🚦 Aztec node başlatılıyor...${NC}"
aztec start \
  --network alpha-testnet \
  --l1-rpc-urls "$ETH_RPC_URL" \
  --l1-consensus-host-urls "$ETH_BEACON_RPC_URL" \
  --sequencer.validatorPrivateKey "$PRIVATE_KEY" \
  --p2p.p2pIp "$LOCAL_IP" \
  --p2p.maxTxPoolSize "$P2P_MAX_TX_POOL_SIZE" \
  --archiver \
  --node \
  --sequencer
