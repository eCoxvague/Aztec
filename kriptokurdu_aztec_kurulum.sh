#!/bin/bash

# Ekranı temizle
clear

# Renk tanımları
KIRMIZI='\033[0;31m'
YESIL='\033[0;32m'
SARI='\033[1;33m'
MOR='\033[0;35m'
MAVI='\033[0;34m'
SIFIR='\033[0m'  # Renk sıfırlama

# Başlık
cat << "BANNER"

$(echo -e "${KIRMIZI}***********************************************${KIRMIZI}")
$(echo -e "${KIRMIZI}*         K R İ P T O K U R D U  N O D E       *${KIRMIZI}")
$(echo -e "${KIRMIZI}*        Hazırlayan: KriptoKurdu              *${KIRMIZI}")
$(echo -e "${KIRMIZI}*---------------------------------------------*${KIRMIZI}")
$(echo -e "${KIRMIZI}*   🦄 Twitter : https://twitter.com/kriptokurduu${KIRMIZI}")
$(echo -e "${KIRMIZI}*   🦉 Telegram: https://t.me/kriptokurdugrup${KIRMIZI}")
$(echo -e "${KIRMIZI}***********************************************${KIRMIZI}")

BANNER

sleep 2

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${KIRMIZI}Hata: Root olarak çalıştırın (sudo su)${SIFIR}"
  exit 1
fi

# Ana dizine geç
cd ~

# Sistem güncelleme
echo -e "${SARI}📦 Paketler güncelleniyor ve yükseltiliyor...${SIFIR}"
apt-get update && apt-get upgrade -y

# Gerekli paketlerin kurulumu
echo -e "${SARI}📚 Gerekli paketler yükleniyor...${SIFIR}"
apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip

# Docker kurulumundan önce çakışan paketleri temizleyelim
echo -e "${SARI}🧹 Mevcut containerd paketleri kaldırılıyor...${SIFOR}"
apt-get remove --purge -y containerd containerd.io
apt-get update
apt-get -f install

# Sonra Docker’ı yükleyin
echo -e "${SARI}🐳 Docker kuruluyor...${SIFOR}"
apt-get install -y docker.io

# Aztec CLI yükleme
echo -e "${SARI}🚀 Aztec CLI kuruluyor...${SIFIR}"
bash -i <(curl -s https://install.aztec.network)

# PATH güncellemesi
echo -e "${YESIL}✅ PATH dizini güncelleniyor...${SIFIR}"
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Aztec CLI başlatma
echo -e "${SARI}🔧 Aztec CLI başlatılıyor...${SIFIR}"
aztec
aztec-up alpha-testnet

# Genel IP adresi tespiti
IP=$(curl -s ipinfo.io/ip)
echo -e "${MOR}🌎 Bulunan IP: ${IP}${SIFIR}"
echo -e "${SARI}Bu IP’yi kaydetmeyi unutmayın!${SIFIR}"
read -p "Kaydettiniz mi? (e/h): " cevap
if [ "$cevap" != "e" ]; then
  echo -e "${KIRMIZI}Lütfen IP’yi kaydederek tekrar çalıştırın.${SIFIR}"
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
echo -en "${MOR}🔒 EVM cüzdan adresinizi girin: ${SIFIR}"
read CUZDAN

# Ortam değişkenleri export
echo -e "${YESIL}🌟 Ortam değişkenleri ayarlanıyor...${SIFIR}"
export DATA_DIRECTORY="/root/aztec-data/"
export COINBASE="$CUZDAN"
export LOG_LEVEL=debug
export P2P_MAX_TX_POOL_SIZE=1000000000

# RPC ve validator bilgileri
echo -en "${MOR}📡 Sepolia RPC URL (Alchemy vb.): ${SIFIR}"
read RPC

echo -en "${MOR}🚀 Beacon Konsensüs RPC URL: ${SIFIR}"
read CONS

echo -en "${MOR}🏠 Yerel IP adresi: ${SIFIR}"
read YEREL_IP

echo -en "${MOR}🔑 Validator özel anahtar: ${SIFIR}"
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
