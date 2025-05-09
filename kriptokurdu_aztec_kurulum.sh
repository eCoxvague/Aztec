#!/bin/bash

# Renk tanımları
KIRMIZI='\033[0;31m'
YESIL='\033[0;32m'
SARI='\033[1;33m'
MOR='\033[0;35m'
MAVI='\033[0;34m'
SIFIR='\033[0m'  # Renk sıfırlama

# —— Otomatik root yükseltme ——
if [[ $EUID -ne 0 ]]; then
  echo -e "${KIRMIZI}Root yetkisi gerekiyor, sudo ile yeniden başlatılıyor...${SIFIR}"
  exec sudo bash "$0" "$@"
fi
# ————————————————————————

# Ekranı temizle
clear

# Başlık
cat << "BANNER"

$(echo -e "${MAVI}***********************************************${SIFIR}")
$(echo -e "${MAVI}*         K R İ P T O K U R D U  N O D E       *${SIFIR}")
$(echo -e "${MAVI}*        Hazırlayan: KriptoKurdu               *${SIFIR}")
$(echo -e "${MAVI}*---------------------------------------------*${SIFIR}")
$(echo -e "${MAVI}*   🦄 Twitter : https://twitter.com/kriptokurduu${SIFIR}")
$(echo -e "${MAVI}*   🦉 Telegram: https://t.me/kriptokurdugrup${SIFIR}")
$(echo -e "${MAVI}***********************************************${SIFIR}")

BANNER

sleep 2

# Ana dizine geç
cd ~

# Sistem güncelleme
echo -e "${SARI}📦 Paketler güncelleniyor ve yükseltiliyor...${SIFIR}"
apt-get update && apt-get upgrade -y

# Gerekli paketlerin kurulumu
echo -e "${SARI}📚 Gerekli paketler yükleniyor...${SIFIR}"
apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip

# Mevcut çakışan paketleri temizle
echo -e "${SARI}🧹 Çakışan containerd paketleri kaldırılıyor...${SIFIR}"
apt-get remove --purge -y containerd containerd.io
apt-get update
apt-get -f install

# Docker kurulumu
echo -e "${SARI}🐳 Docker kuruluyor...${SIFIR}"
apt install -y docker.io
systemctl enable --now docker

# Aztec CLI yükleme
echo -e "${SARI}🚀 Aztec CLI kuruluyor...${SIFIR}"
bash -i <(curl -s https://install.aztec.network)

# Yüklenen CLI ikililerini PATH'e al
AZTEC_BIN="$HOME/.aztec/bin"
export PATH="$AZTEC_BIN:$PATH"

# PATH ayarını kalıcı kıl
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc

# Yeni PATH ile shell'i yeniden yükle
source ~/.bashrc

# Aztec CLI kontrol
echo -e "${YESIL}✅ aztec versiyon: $(aztec --version)${SIFIR}"

# Aztec ağını başlat
echo -e "${SARI}🔧 Aztec ağı başlatılıyor...${SIFOR}"
aztec up alpha-testnet

# Genel IP adresi tespiti
IP=$(curl -s ipinfo.io/ip)
echo -e "${MOR}🌎 Bulunan IP: ${IP}${SIFIR}"
echo -e "${SARI}Bu IP’yi kaydetmeyi unutmayın!${SIFOR}"
read -p "Kaydettiniz mi? (e/h): " cevap
if [ "$cevap" != "e" ]; then
  echo -e "${KIRMIZI}Lütfen IP’yi kaydederek tekrar çalıştırın.${SIFOR}"
  exit 1
fi

# Güvenlik duvarı yapılandırması
echo -e "${SARI}🛡️ UFW ayarları yapılıyor...${SIFIR}"
ufw allow ssh
ufw allow 40400
ufw allow 40500
ufw allow 8080
ufw --force enable

# Cüzdan adresi girme
echo -en "${MOR}🔒 EVM cüzdan adresinizi girin: ${SIFOR}"
read CUZDAN

# Ortam değişkenleri export
echo -e "${YESIL}🌟 Ortam değişkenleri ayarlanıyor...${SIFIR}"
export DATA_DIRECTORY="/root/aztec-data/"
export COINBASE="$CUZDAN"
export LOG_LEVEL=debug
export P2P_MAX_TX_POOL_SIZE=1000000000

# RPC ve validator bilgileri
echo -en "${MOR}📡 Sepolia RPC URL (Alchemy vb.): ${SIFOR}"
read RPC

echo -en "${MOR}🚀 Beacon Konsensüs RPC URL: ${SIFOR}"
read CONS

echo -en "${MOR}🏠 Yerel IP adresi: ${SIFOR}"
read YEREL_IP

echo -en "${MOR}🔑 Validator özel anahtar: ${SIFOR}"
read VK

# Aztec düğümünü başlatma
echo -e "${YESIL}🚦 Aztec düğümü başlatılıyor...${SIFIR}"
aztec start \
  --network alpha-testnet \
  --l1-rpc-urls "$RPC" \
  --l1-consensus-host-urls "$CONS" \
  --sequencer.validatorPrivateKey "$VK" \
  --p2p.p2pIp "$YEREL_IP" \
  --p2p.maxTxPoolSize 1000000000 \
  --archiver \
  --node \
  --sequencer
