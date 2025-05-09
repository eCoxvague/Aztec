#!/bin/bash
clear

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

# Root olarak çalıştır
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Lütfen bu scripti root olarak çalıştırın!${NC}"
  echo -e "${YELLOW}Aşağıdaki komutu kullanabilirsiniz:${NC}"
  echo -e "${GREEN}curl -O https://raw.githubusercontent.com/eCoxvague/Aztec/main/kriptokurdu_aztec_kurulum.sh && chmod +x kriptokurdu_aztec_kurulum.sh && sudo ./kriptokurdu_aztec_kurulum.sh${NC}"
  exit 1
fi

# Ana dizine git
cd

# Sistem güncelleme
echo -e "${CYAN}📦 Sistem güncelleniyor...${NC}"
apt-get update && apt-get upgrade -y

# Bağımlılıkları yükle
echo -e "${CYAN}📚 Gerekli paketler yükleniyor...${NC}"
apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y

# Docker temizliği
echo -e "${YELLOW}🧹 Docker temizleniyor (eğer varsa)...${NC}"
if command -v docker &> /dev/null; then
  echo -e "${YELLOW}Mevcut Docker kurulumu bulundu. Temizleniyor...${NC}"
  docker system prune -af --volumes
  systemctl stop docker docker.socket containerd
  apt-get purge docker-ce docker-ce-cli containerd.io docker docker-engine docker.io containerd runc -y
  apt-get autoremove -y
  rm -rf /var/lib/docker /var/lib/containerd /etc/docker
  echo -e "${GREEN}Docker temizlendi.${NC}"
fi

# Docker yükle
echo -e "${CYAN}🐳 Docker yükleniyor...${NC}"
apt install docker.io -y
systemctl enable docker
systemctl start docker
docker --version
echo -e "${GREEN}Docker kurulumu tamamlandı.${NC}"

# Aztec CLI yükle
echo -e "${CYAN}🚀 Aztec CLI yükleniyor...${NC}"
bash -i <(curl -s https://install.aztec.network)
echo -e "${GREEN}Aztec CLI kurulumu tamamlandı.${NC}"

# Tam yol tanımlamaları
AZTEC_BIN_DIR="/root/.aztec/bin"
AZTEC_CMD="$AZTEC_BIN_DIR/aztec"
AZTEC_UP_CMD="$AZTEC_BIN_DIR/aztec-up"

# PATH'i güncelle
echo -e "${YELLOW}PATH değişkeni güncelleniyor...${NC}"
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Geçici olarak PATH'i ayarla
export PATH="$HOME/.aztec/bin:$PATH"

# Aztec komutlarını çalıştır
echo -e "${CYAN}Aztec alpha-testnet yükleniyor...${NC}"
if [ -f "$AZTEC_UP_CMD" ]; then
  $AZTEC_UP_CMD alpha-testnet
else
  echo -e "${RED}Aztec-up bulunamadı. Tam yolunu kontrol edin: $AZTEC_UP_CMD${NC}"
  find / -name "aztec-up" -type f 2>/dev/null | head -n 1
fi

# Genel IP al
public_ip=$(curl -s ipinfo.io/ip)
echo -e "${GREEN}🌐 Algılanan IP adresiniz: ${YELLOW}$public_ip${NC}"
echo -e "${RED}⚠️  Lütfen devam etmeden önce bu IP adresini kaydedin.${NC}"
read -p "$(echo -e ${YELLOW}"IP adresinizi kaydettiniz mi? (e/h): "${NC})" saved
if [ "$saved" != "e" ]; then
  echo -e "${RED}❗ IP adresinizi kaydedin ve scripti tekrar çalıştırın.${NC}"
  exit 1
fi

# Güvenlik duvarı ayarları
echo -e "${CYAN}🧱 Güvenlik duvarı yapılandırılıyor...${NC}"
ufw allow ssh
ufw allow 40400
ufw allow 40500
ufw allow 8080
ufw --force enable

# Cüzdan bilgisi al
read -p "$(echo -e ${YELLOW}"🔐 EVM cüzdan adresinizi girin: "${NC})" COINBASE

# Çevre değişkenlerini ayarla
export DATA_DIRECTORY=/root/aztec-data/
export COINBASE=$COINBASE
export LOG_LEVEL=debug
export P2P_MAX_TX_POOL_SIZE=1000000000

# RPC ve validator bilgilerini al
read -p "$(echo -e ${YELLOW}"🌍 Ethereum Sepolia RPC URL'nizi girin (https://dashboard.alchemy.com/apps/ adresinden alabilirsiniz): "${NC})" RPC_URL
read -p "$(echo -e ${YELLOW}"🛰️ Ethereum Beacon Consensus RPC URL'nizi girin (https://console.chainstack.com/user/login adresinden alabilirsiniz): "${NC})" CONSENSUS_URL
read -p "$(echo -e ${YELLOW}"📡 Kaydettiğiniz genel IP adresinizi girin: "${NC})" LOCAL_IP
read -p "$(echo -e ${YELLOW}"🔑 Validator özel anahtarınızı girin: "${NC})" PRIVATE_KEY

# Variableleri hazırla
export ETHEREUM_HOSTS=$RPC_URL
export L1_CONSENSUS_HOST_URLS=$CONSENSUS_URL
export VALIDATOR_PRIVATE_KEY=$PRIVATE_KEY
export P2P_IP=$LOCAL_IP

# Aztec node başlat (tam yolları kullanarak)
echo -e "${GREEN}🚦 Aztec node başlatılıyor...${NC}"
if [ -f "$AZTEC_CMD" ]; then
  # Tam yolla başlat
  $AZTEC_CMD start --network alpha-testnet \
    --l1-rpc-urls "$RPC_URL" \
    --l1-consensus-host-urls "$CONSENSUS_URL" \
    --sequencer.validatorPrivateKey "$PRIVATE_KEY" \
    --sequencer.coinbase "$COINBASE" \
    --p2p.p2pIp "$LOCAL_IP" \
    --p2p.maxTxPoolSize 1000000000 \
    --archiver \
    --node \
    --sequencer
else
  echo -e "${RED}❌ Aztec CLI bulunamadı. Sistem PATH değişkenlerini yenilemeye çalışıyoruz...${NC}"
  
  # PATH sorunlarına karşı alternatif yöntemler
  echo -e "${YELLOW}Alternatif komutları deniyoruz...${NC}"
  
  # Docker ile doğrudan başlatma
  echo -e "${YELLOW}Docker ile doğrudan başlatmayı deniyoruz...${NC}"
  docker run --network host -v /root/aztec-data:/data aztecprotocol/aztec:latest start \
    --network alpha-testnet \
    --l1-rpc-urls "$RPC_URL" \
    --l1-consensus-host-urls "$CONSENSUS_URL" \
    --sequencer.validatorPrivateKey "$PRIVATE_KEY" \
    --sequencer.coinbase "$COINBASE" \
    --p2p.p2pIp "$LOCAL_IP" \
    --p2p.maxTxPoolSize 1000000000 \
    --archiver \
    --node \
    --sequencer
fi

echo -e "${GREEN}✅ Kurulum tamamlandı. Aşağıdaki bilgileri kaydedin:${NC}"
echo -e "${CYAN}Cüzdan: ${NC}$COINBASE"
echo -e "${CYAN}RPC URL: ${NC}$RPC_URL"
echo -e "${CYAN}Consensus URL: ${NC}$CONSENSUS_URL"
echo -e "${CYAN}IP Adresi: ${NC}$LOCAL_IP"

echo -e "${YELLOW}Manuel komut (gerekirse):${NC}"
echo -e "${GREEN}$AZTEC_CMD start --network alpha-testnet --l1-rpc-urls \"$RPC_URL\" --l1-consensus-host-urls \"$CONSENSUS_URL\" --sequencer.validatorPrivateKey \"$PRIVATE_KEY\" --sequencer.coinbase \"$COINBASE\" --p2p.p2pIp \"$LOCAL_IP\" --p2p.maxTxPoolSize 1000000000 --archiver --node --sequencer${NC}"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}   Validator olarak kaydolmak için aşağıdaki komutu kullanın:${NC}"
echo -e "${GREEN}$AZTEC_CMD add-l1-validator --l1-rpc-urls \"$RPC_URL\" --private-key \"$PRIVATE_KEY\" --attester \"$(echo $COINBASE)\" --proposer-eoa \"$(echo $COINBASE)\" --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 --l1-chain-id 11155111${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
