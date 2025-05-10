#!/bin/bash
clear
# Banner renkli
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# KriptoKurdu Banner
echo -e "${CYAN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════╗                                                 
                    K R İ P T O K U R D U 
                     A Z T E C  N O D E
             Twitter:  https://x.com/kriptokurduu
             Telegram: https://t.me/kriptokurdugrup
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
sleep 5
echo -e "${CYAN}KriptoKurdu Aztec Node Kurulum Aracına Hoş Geldiniz!${NC}"
sleep 2

# Root olarak çalıştır
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Lütfen bu scripti root olarak çalıştırın: sudo su${NC}"
  exit 1
fi

# Ana dizine git
cd

# Sistem güncelleme
echo -e "${YELLOW}📦 Sistem güncelleniyor...${NC}"
apt-get update && apt-get upgrade -y

# Bağımlılıkları yükle
echo -e "${GREEN}📚 Gerekli bağımlılıklar yükleniyor...${NC}"
apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y

# Docker kurulumu
echo -e "${BLUE}🐳 Docker yükleniyor...${NC}"
apt install docker.io -y

# Aztec CLI kurulumu
echo -e "${CYAN}🚀 Aztec CLI yükleniyor...${NC}"
bash -i <(curl -s https://install.aztec.network)

# PATH güncelleme
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Aztec CLI başlatma
aztec
aztec-up alpha-testnet

# Public IP al
public_ip=$(curl -s ipinfo.io/ip)
echo -e "${YELLOW}🌐 Tespit edilen public IP: ${GREEN}$public_ip${NC}"
echo -e "${RED}⚠️  Lütfen devam etmeden önce bu IP adresini kaydedin.${NC}"
read -p "Kaydettin mi? (e/h): " saved
if [ "$saved" != "e" ]; then
  echo -e "${RED}❗ IP adresini kaydedin ve scripti tekrar çalıştırın.${NC}"
  exit 1
fi

# Güvenlik duvarı ayarları
echo -e "${BLUE}🔒 Güvenlik duvarı yapılandırılıyor...${NC}"
ufw allow ssh
ufw allow 40400
ufw allow 40500
ufw allow 8080
ufw --force enable

# Cüzdan bilgisi
read -p "🔐 EVM cüzdan adresinizi girin: " COINBASE

# Ortam değişkenlerini ayarla
export DATA_DIRECTORY=/root/aztec-kurdu-data/
export COINBASE=$COINBASE
export LOG_LEVEL=debug
export P2P_MAX_TX_POOL_SIZE=1000000000

# RPC ve doğrulayıcı bilgileri
echo -e "${GREEN}Şimdi gerekli RPC ve doğrulayıcı bilgilerini gireceğiz${NC}"
echo -e "${YELLOW}RPC URL'i https://dashboard.alchemy.com/apps/ adresinden alabilirsiniz${NC}"
read -p "🌍 Ethereum Sepolia RPC URL'nizi girin: " RPC_URL

echo -e "${YELLOW}Consensus URL'i https://console.chainstack.com/user/login adresinden alabilirsiniz${NC}"
read -p "🛰️ Ethereum Beacon Consensus RPC URL'nizi girin: " CONSENSUS_URL

read -p "📡 Kaydettiğiniz public IP adresinizi girin: " LOCAL_IP
read -p "🔑 Doğrulayıcı özel anahtarınızı girin: " PRIVATE_KEY

# Aztec node'unu başlat
echo -e "${CYAN}🚦 KriptoKurdu Aztec node başlatılıyor...${NC}"
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

echo -e "${GREEN}✅ KriptoKurdu Aztec Node başarıyla kuruldu ve çalışıyor!${NC}"
echo -e "${YELLOW}Bu node hakkında sorularınız için Telegram grubuna katılın: https://t.me/kriptokurdugrup${NC}"
