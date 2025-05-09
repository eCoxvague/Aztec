#!/bin/bash

clear

cat << "EOF"


╔════════════════════════════════════════════════════════════╗                                                 
                    K R İ P T O K U R D U 
                     A Z T E C  N O D E

             Twitter:  https://x.com/kriptokurduu
             Telegram: https://t.me/vampsairdrop
╚════════════════════════════════════════════════════════════╝

EOF

sleep 3

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo "❌ Lütfen bu betiği root olarak çalıştırın: sudo su"
  exit 1
fi

# Ana dizine geç
cd

# PATH güncellemesi (önceden eksikti!)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.aztec/bin"

# Sistem güncellemesi
echo "📦 Sistem paketleri güncelleniyor..."
apt-get update && apt-get upgrade -y

# Bağımlılıkların kurulumu
echo "📚 Gerekli bağımlılıklar yükleniyor..."
apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y

# Docker kurulumu
echo "🐳 Docker kuruluyor..."
apt install docker.io -y

# Aztec CLI kurulumu
echo "🚀 Aztec CLI kuruluyor..."
curl -s https://install.aztec.network | bash

# PATH'i kalıcı hale getir
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
export PATH="$HOME/.aztec/bin:$PATH"

# Aztec CLI başlat
aztec
aztec-up alpha-testnet

# IP tespiti
public_ip=$(curl -s ipinfo.io/ip)
echo "🌐 Tespit edilen IP adresiniz: $public_ip"
echo "⚠️  Devam etmeden önce bu IP adresini kaydettiğinizden emin olun."
read -p "Kaydettiniz mi? (y/n): " saved
if [ "$saved" != "y" ]; then
  echo "❗ Lütfen IP adresini kaydedin ve scripti tekrar çalıştırın."
  exit 1
fi

# Güvenlik duvarı ayarı
echo "🧱 Güvenlik duvarı ayarlanıyor..."
ufw allow ssh
ufw allow 40400
ufw allow 40500
ufw allow 8080
ufw --force enable

# Cüzdan adresi gir
read -p "🔐 EVM cüzdan adresinizi girin: " COINBASE

# Ortam değişkenleri
export DATA_DIRECTORY=/root/aztec-data/
export COINBASE=$COINBASE
export LOG_LEVEL=debug
export P2P_MAX_TX_POOL_SIZE=1000000000

# RPC ve validator bilgileri
read -p "🌍 Ethereum Sepolia RPC URL’nizi girin: " RPC_URL
read -p "🛰️  Ethereum Beacon Consensus RPC URL’nizi girin: " CONSENSUS_URL
read -p "📡 Kaydettiğiniz genel IP adresinizi tekrar girin: " LOCAL_IP
read -p "🔑 Validator private key’inizi girin: " PRIVATE_KEY

# Node başlatma
echo "🚦 Aztec node başlatılıyor..."
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
