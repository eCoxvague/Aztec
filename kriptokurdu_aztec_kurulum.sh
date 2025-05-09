#!/bin/bash
clear
set -e
export PATH="/bin:/usr/bin:$HOME/.aztec/bin:$PATH"

# Renk Tanımları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Banner
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}           ${YELLOW}K R İ P T O   K U R D U   N O D E Kurulum${NC}"
echo -e "${BLUE}🐺 Twitter:  ${YELLOW}https://x.com/kriptokurduu${NC}"
echo -e "${BLUE}🌐 Telegram: ${YELLOW}https://t.me/kriptokurdugrup${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
sleep 3

# 1) Root Kontrolü
if [[ "$EUID" -ne 0 ]]; then
  echo -e "${RED}❌ Lütfen script'i root olarak çalıştırın (sudo)!${NC}"
  exit 1
fi

# 2) Ana Dizin
echo -e "${CYAN}📂 Ana dizine geçiliyor...${NC}"
cd ~

# 3) Geçici Dizin Oluşturuluyor
echo -e "${CYAN}📁 Geçici dizin hazırlanıyor...${NC}"
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

# 4) bootnode.json Oluşturuluyor
echo -e "${CYAN}📄 bootnode.json oluşturuluyor...${NC}"
cat > bootnode.json << 'EOF'
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
    "l1Provider": {"network":"sepolia","chainId":11155111},
    "chain": {"bootnodes":["/dns/bootnode-alpha-1.aztec.network/tcp/40400"]}
  }
}
EOF

# 5) Sistem Güncelleme ve Temel Paketler
echo -e "${CYAN}🔧 Sistem güncelleniyor ve temel paketler yükleniyor...${NC}"
apt-get update && apt-get upgrade -y
apt-get install -y curl jq lsb-release gnupg2 software-properties-common \
  nginx tmux htop ufw dnsutils net-tools apt-transport-https ca-certificates

# 6) Docker Paketlerini Kaldırma (varsa)
echo -e "${YELLOW}🧹 Mevcut Docker paketleri kaldırılıyor...${NC}"
apt-get purge -y "docker*" containerd runc || true
rm -rf /var/lib/docker /var/lib/containerd /etc/docker

echo -e "${GREEN}✅ Eski Docker paketleri kaldırıldı (varsa).${NC}"

# 7) Docker Kur & Başlat
echo -e "${CYAN}🐳 Docker kuruluyor...${NC}"
apt-get update
apt-get install -y docker.io
systemctl enable docker
systemctl start docker
# Docker servisi kontrolü
if ! systemctl is-active --quiet docker; then
  echo -e "${RED}❌ Docker servisi başlatılamadı. Lütfen journalctl -xeu docker.service ile kontrol edin.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Docker servisi çalışıyor.${NC}"

# 8) DNS ve Hosts Güncelleme
echo -e "${CYAN}🌐 DNS ve hosts dosyaları güncelleniyor...${NC}"
cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
cat >> /etc/hosts <<EOF
104.21.31.61 static.aztec.network
172.67.211.145 bootnode-alpha-1.aztec.network
EOF

# 9) Nginx Statik Sunucu
echo -e "${CYAN}🌍 Nginx ile statik bootnode sunucusu kuruluyor...${NC}"
mkdir -p /var/www/html/alpha-testnet/
cp bootnode.json /var/www/html/alpha-testnet/bootnodes.json
systemctl enable nginx && systemctl restart nginx

# 10) UFW Güvenlik Duvarı
echo -e "${CYAN}🧱 Güvenlik duvarı kuralları ekleniyor...${NC}"
ufw allow ssh
ufw allow 40400/tcp
ufw allow 40400/udp
ufw allow 8080
ufw --force enable

# 11) Aztec CLI Kurulumu
echo -e "${CYAN}🚀 Aztec CLI kuruluyor...${NC}"
bash -i <(curl -s https://install.aztec.network)
# PATH Güncelleme
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/.aztec/bin:$PATH"

# 12) CLI Wrapper Shebang Düzeltme
echo -e "${CYAN}🔧 CLI script shebang'ları güncelleniyor...${NC}"
for f in "$HOME/.aztec/bin/"*; do
  [[ -f "$f" ]] && sed -i '1s|.*|#!/bin/bash|' "$f" && chmod +x "$f"
done

# 13) Aztec Araçları Güncelleme
echo -e "${CYAN}🔄 Aztec araçları güncelleniyor (alpha-testnet)...${NC}"
aztec-up alpha-testnet

# 14) Kullanıcı Girdileri
echo -e "${CYAN}🔐 Kullanıcı bilgileriniz alınıyor...${NC}"
read -p "🔐 EVM cüzdan adresinizi girin: " COINBASE
read -p "🌍 Sepolia RPC URL (ETHEREUM_HOSTS): " RPC_URL
read -p "🔑 Validator private key: " PRIVATE_KEY

# 15) Genel IP
echo -e "${CYAN}🌐 Genel IP algılanıyor...${NC}"
PUBLIC_IP=$(curl -s https://api.ipify.org)
echo -e "${GREEN}Algılanan IP: $PUBLIC_IP${NC}"
read -p "Bu IP'yi kullanmak ister misiniz? (y/n): " USE_IP
if [[ "$USE_IP" == "y" ]]; then
  LOCAL_IP=$PUBLIC_IP
else
  read -p "📡 IP adresinizi girin: " LOCAL_IP
fi

# 16) Beacon Consensus RPC Test
echo -e "${CYAN}🛰️ Beacon consensus RPC testi yapılıyor...${NC}"
for url in "https://rpc.drpc.org/eth/sepolia/beacon" "https://lodestar-sepolia.chainsafe.io"; do
  echo -n "Testing $url... "
  if curl -sf "$url" -o /dev/null; then
    CONSENSUS_URL=$url
    echo -e "${GREEN}OK${NC}"
    break
  else
    echo -e "${RED}FAIL${NC}"
  fi
done
if [[ -z "$CONSENSUS_URL" ]]; then
  read -p "🛰️ Çalışan Beacon RPC URL girin: " CONSENSUS_URL
fi

# 17) Data/Config Hazırlığı
echo -e "${CYAN}📂 Data/config dizini oluşturuluyor...${NC}"
DATA_DIR="$HOME/aztec-data"
mkdir -p "$DATA_DIR/config"
curl -s https://static.aztec.network/config/alpha-testnet.json | jq '.p2pBootstrapNodes=["/dns/bootnode-alpha-1.aztec.network/tcp/40400"]' > "$DATA_DIR/config/alpha-testnet.json"

# 18) Home'a Dön
echo -e "${CYAN}📂 Çalışma dizini home'a getiriliyor...${NC}"
cd ~

# 19) Node Başlatma
echo -e "${GREEN}🚦 Aztec node başlatılıyor...${NC}"
aztec start --network alpha-testnet \
  --l1-rpc-urls "$RPC_URL" \
  --l1-consensus-host-urls "$CONSENSUS_URL" \
  --sequencer.validatorPrivateKey "$PRIVATE_KEY" \
  --sequencer.coinbase "$COINBASE" \
  --p2p.p2pIp "$LOCAL_IP" \
  --p2p.maxTxPoolSize 1000000000 \
  --archiver --node --sequencer

# 20) Log Takibi
echo -e "${CYAN}📊 Logları izlemek için: aztec logs --follow${NC}"
echo -e "${CYAN}📋 Alternatif: docker logs -f aztec-node${NC}"

# 21) Temizlik
echo -e "${CYAN}🧹 Geçici dosyalar temizleniyor...${NC}"
rm -rf "$TMPDIR"

echo -e "${GREEN}✅ Kurulum tamamlandı!${NC}"
