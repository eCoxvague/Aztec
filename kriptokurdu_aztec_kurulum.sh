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

# PATH güncelle ve hemen uygula
echo -e "${YELLOW}PATH değişkenini güncelleniyor...${NC}"
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.profile

# PATH'i mevcut shell için güncelle
export PATH="$HOME/.aztec/bin:$PATH"

# Kurulumu kontrol et
echo -e "${YELLOW}Aztec CLI kurulumu kontrol ediliyor...${NC}"
if [ -f "$HOME/.aztec/bin/aztec" ]; then
  echo -e "${GREEN}Aztec CLI başarıyla kuruldu.${NC}"
else
  echo -e "${RED}Aztec CLI kurulumu başarısız oldu. Tam yolu kontrol ediniz.${NC}"
  # Alternatif konum aramayı dene
  AZTEC_PATH=$(find /root -name "aztec" -type f 2>/dev/null | head -n 1)
  if [ -n "$AZTEC_PATH" ]; then
    echo -e "${YELLOW}Aztec CLI burada bulundu: $AZTEC_PATH${NC}"
    AZTEC_BIN_DIR=$(dirname "$AZTEC_PATH")
    echo -e "${YELLOW}PATH değişkenini $AZTEC_BIN_DIR ile güncelleniyor...${NC}"
    export PATH="$AZTEC_BIN_DIR:$PATH"
    echo 'export PATH="'$AZTEC_BIN_DIR':$PATH"' >> ~/.bashrc
    echo 'export PATH="'$AZTEC_BIN_DIR':$PATH"' >> ~/.profile
  else
    echo -e "${RED}Aztec CLI bulunamadı. Kurulum başarısız olabilir.${NC}"
    echo -e "${YELLOW}Manuel olarak ilerlemeye devam ediliyor...${NC}"
  fi
fi

# Doğrudan tam yolları kullanarak komutları çalıştır
echo -e "${CYAN}Aztec CLI başlatılıyor...${NC}"
if [ -f "$HOME/.aztec/bin/aztec" ]; then
  $HOME/.aztec/bin/aztec
else
  echo -e "${RED}aztec komutu bulunamadı, atlanıyor...${NC}"
fi

echo -e "${CYAN}Aztec alpha-testnet yükleniyor...${NC}"
if [ -f "$HOME/.aztec/bin/aztec-up" ]; then
  $HOME/.aztec/bin/aztec-up alpha-testnet
else
  echo -e "${RED}aztec-up komutu bulunamadı, atlanıyor...${NC}"
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

# Aztec node başlat
echo -e "${GREEN}🚦 Aztec node başlatılıyor...${NC}"
if [ -f "$HOME/.aztec/bin/aztec" ]; then
  $HOME/.aztec/bin/aztec start \
    --network alpha-testnet \
    --l1-rpc-urls "$RPC_URL" \
    --l1-consensus-host-urls "$CONSENSUS_URL" \
    --sequencer.validatorPrivateKey "$PRIVATE_KEY" \
    --p2p.p2pIp "$LOCAL_IP" \
    --p2p.maxTxPoolSize 1000000000 \
    --archiver \
    --node \
    --sequencer
else
  echo -e "${RED}❌ Aztec CLI bulunamadı. Kurulumu kontrol edin.${NC}"
  echo -e "${YELLOW}Kurulum bilgileri:${NC}"
  echo -e "${CYAN}Cüzdan: ${NC}$COINBASE"
  echo -e "${CYAN}RPC URL: ${NC}$RPC_URL"
  echo -e "${CYAN}Consensus URL: ${NC}$CONSENSUS_URL"
  echo -e "${CYAN}IP Adresi: ${NC}$LOCAL_IP"
  echo -e "${YELLOW}Aşağıdaki komutu manuel olarak PATH değişkeni belirlendikten sonra çalıştırmanız gerekebilir:${NC}"
  echo -e "${GREEN}aztec start --network alpha-testnet --l1-rpc-urls \"$RPC_URL\" --l1-consensus-host-urls \"$CONSENSUS_URL\" --sequencer.validatorPrivateKey \"$PRIVATE_KEY\" --p2p.p2pIp \"$LOCAL_IP\" --p2p.maxTxPoolSize 1000000000 --archiver --node --sequencer${NC}"
fi
