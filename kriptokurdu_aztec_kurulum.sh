#!/bin/bash

# —————————————————————————————————————————————
# KriptoKurdu Aztec Node Kurulum Betiği
# Türkçe; otomatik IP ve Beacon RPC seçimi
# —————————————————————————————————————————————

# 1) Mutlak yollarda ve sistem dizinlerinde her komutu bulunabilir kılmak için PATH’i başta ayarlıyoruz
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# 2) Renk tanımları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear

# 3) Banner
cat << EOF
${CYAN}╔════════════════════════════════════════════════════════════╗
              ${BLUE}K R İ P T O K U R D U   N O D E
              ${MAGENTA}by KriptoKurdu${CYAN}
📡 Twitter:  https://x.com/kriptokurduu
💬 Telegram: https://t.me/kriptokurdugrup
╚════════════════════════════════════════════════════════════╝${NC}
EOF
sleep 1

# 4) Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Lütfen betiği root (sudo su) olarak çalıştırın.${NC}"
  exit 1
fi

# 5) Paket depolarını güncelle ve yükselt
echo -e "${YELLOW}📦 Sistem paketleri güncelleniyor...${NC}"
apt-get update && apt-get upgrade -y

# 6) Önceki containerd kurulumlarını, tutulan (held) paketleri vb. tamamen temizle
echo -e "${YELLOW}🚮 Eski Docker/containerd paketleri temizleniyor...${NC}"
apt-mark unhold containerd containerd.io runc docker docker-engine docker.io || true
apt-get purge -y containerd containerd.io runc docker docker-engine docker.io
apt-get autoremove -y

# 7) Gerekli tüm bağımlılıkları ve docker.io’yu tek seferde kur
echo -e "${YELLOW}📚 Gerekli paketler kuruluyor (curl, jq, docker.io, vs.)...${NC}"
apt-get update
apt-get install -y \
  curl iptables build-essential git wget lz4 jq make gcc nano \
  automake autoconf tmux htop nvme-cli libgbm1 pkg-config \
  libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip \
  docker.io

echo -e "${GREEN}✅ Bağımlılıklar ve Docker başarıyla kuruldu.${NC}"

# 8) Aztec CLI kur (non-interactive, böylece bash -i <(...) içindekiler .bashrc’i geçersiz kılmaz)
echo -e "${YELLOW}🚀 Aztec CLI yüklemesi başlatılıyor...${NC}"
curl -s https://install.aztec.network | bash

# 9) CLI bin dizinini PATH’e ekle kalıcı ve geçici olarak
export PATH="$HOME/.aztec/bin:$PATH"
grep -qxF 'export PATH="$HOME/.aztec/bin:$PATH"' ~/.bashrc || \
  echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc

echo -e "${GREEN}✅ Aztec CLI yüklendi, PATH güncellendi.${NC}"

# 10) Aztec CLI’yi normal modda kullanarak alpha-testnet’i ayağa kaldır
echo -e "${YELLOW}⚙️  Aztec CLI alpha-testnet için başlatılıyor...${NC}"
"$HOME/.aztec/bin/aztec"
"$HOME/.aztec/bin/aztec-up" alpha-testnet

# 11) Genel IP’yi otomatik algıla
echo -e "${YELLOW}🌐 Genel IP adresiniz algılanıyor...${NC}"
PUBLIC_IP=$(curl -s https://ipinfo.io/ip)
echo -e "${GREEN}Algılanan IP:${NC} ${BLUE}$PUBLIC_IP${NC}"

# 12) Kullanıcı girdileri
read -p "$(echo -e ${CYAN}🔐 EVM cüzdan adresinizi girin:${NC} )" COINBASE
read -p "$(echo -e ${CYAN}🌍 Ethereum Sepolia RPC URL’si girin (ör. Alchemy):${NC} )" RPC_URL

# 13) Beacon RPC otomatik seçimi
echo -e "${YELLOW}🔍 Beacon RPC uç noktaları test ediliyor...${NC}"
for URL in \
  "https://rpc.drpc.org/eth/sepolia/beacon" \
  "https://lodestar-sepolia.chainsafe.io"
do
  if curl -s -X POST "$URL" \
       -H "Content-Type: application/json" \
       -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
       | grep -q '"result"'; then
    BEACON_URL="$URL"
    echo -e "${GREEN}✔️  Seçilen Beacon RPC:${NC} ${BLUE}$BEACON_URL${NC}"
    break
  fi
done
if [ -z "$BEACON_URL" ]; then
  echo -e "${RED}❌ Hiçbir Beacon RPC çalışmadı. Betik sonlanıyor.${NC}"
  exit 1
fi

# 14) Validator özel anahtar (gizli)
read -s -p "$(echo -e ${CYAN}🔑 Validator özel anahtarınızı girin:${NC} )" PRIVATE_KEY
echo

# 15) Ortam değişkenlerini ayarla
export DATA_DIRECTORY=/root/aztec-data/
export COINBASE
export LOG_LEVEL=debug
export P2P_MAX_TX_POOL_SIZE=1000000000
export ETH_RPC_URL="$RPC_URL"
export ETH_BEACON_RPC_URL="$BEACON_URL"
export LOCAL_IP="$PUBLIC_IP"

# 16) Aztec node’u başlat
echo -e "${YELLOW}🚦 Aztec node başlatılıyor...${NC}"
"$HOME/.aztec/bin/aztec" start \
  --network alpha-testnet \
  --l1-rpc-urls "$ETH_RPC_URL" \
  --l1-consensus-host-urls "$ETH_BEACON_RPC_URL" \
  --sequencer.validatorPrivateKey "$PRIVATE_KEY" \
  --p2p.p2pIp "$LOCAL_IP" \
  --p2p.maxTxPoolSize "$P2P_MAX_TX_POOL_SIZE" \
  --archiver \
  --node \
  --sequencer
