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
NC='\033[0m'

# Banner
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}           ${YELLOW}K R İ P T O   K U R D U   N O D E${NC}"
echo -e "${BLUE}                  ${GREEN}Aztec Node Kurulum${NC}"
echo -e "${BLUE}🐺 Twitter:  ${GREEN}https://x.com/kriptokurduu${NC}"
echo -e "${BLUE}🌐 Telegram: ${GREEN}https://t.me/kriptokurdugrup${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
sleep 5

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Lütfen bu scripti root olarak çalıştırın!${NC}"
  exit 1
fi

# Ana dizine geç
cd ~

# Geçici dizin oluştur
tmpdir=$(mktemp -d)
cd "$tmpdir"

# bootnode.json oluştur
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
apt-get update && apt-get upgrade -y
apt-get install -y curl jq docker.io nginx tmux htop ufw dnsutils net-tools jq

# DNS ve hosts yapılandırması
cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
cat >> /etc/hosts <<EOF
104.21.31.61 static.aztec.network
172.67.211.145 bootnode-alpha-1.aztec.network
EOF

# NGINX statik bootnode sunucusu
mkdir -p /var/www/html/alpha-testnet/
cp bootnode.json /var/www/html/alpha-testnet/bootnodes.json
systemctl enable nginx && systemctl restart nginx

# UFW yapılandırması
ufw allow ssh && ufw allow 40400/tcp && ufw allow 40400/udp && ufw --force enable

# Aztec CLI kurulumu ve PATH güncellemesi
echo -e "${CYAN}🚀 Aztec CLI kuruluyor...${NC}"
bash -i <(curl -s https://install.aztec.network)
export PATH="$HOME/.aztec/bin:$PATH"
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc

# Araçları güncelle
aztec-up alpha-testnet

# Kullanıcı girdileri
read -p "🔐 EVM cüzdan adresinizi girin: " COINBASE
read -p "🌍 Sepolia RPC URL (ETHEREUM_HOSTS): " RPC_URL
read -p "🔑 Validator özel anahtarınızı girin: " PRIVATE_KEY

# Genel IP algılama
PUBLIC_IP=$(curl -s https://api.ipify.org)
echo "Algılanan IP: $PUBLIC_IP"
read -p "Bu IP'yi kullanmak ister misiniz? (e/h): " use_ip
if [ "$use_ip" = "e" ]; then
  LOCAL_IP=$PUBLIC_IP
else
  read -p "📡 IP adresinizi girin: " LOCAL_IP
fi

# Beacon consensus RPC otomatik test
echo -e "${CYAN}🛰️ Beacon consensus RPC test ediliyor...${NC}"
for url in "https://rpc.drpc.org/eth/sepolia/beacon" "https://lodestar-sepolia.chainsafe.io"; do
  echo -n "Testing $url... "
  if curl -sf "$url" -o /dev/null; then
    CONSENSUS_URL=$url
    echo "OK"
    break
  else
    echo "FAIL"
  fi
done
if [ -z "$CONSENSUS_URL" ]; then
  read -p "🛰️ Çalışan Beacon RPC URL'sini girin: " CONSENSUS_URL
fi

# Data/config hazırlığı
DATA_DIR="$HOME/aztec-data"
mkdir -p "$DATA_DIR/config"

# Resmi config indir ve p2pBootstrapNodes ekle
curl -s https://static.aztec.network/config/alpha-testnet.json | jq '.p2pBootstrapNodes=["/dns/bootnode-alpha-1.aztec.network/tcp/40400"]' > "$DATA_DIR/config/alpha-testnet.json"

# Node'u başlat
echo -e "${GREEN}🚦 Aztec node başlatılıyor...${NC}"
aztec start --network alpha-testnet \
  --l1-rpc-urls "$RPC_URL" \
  --l1-consensus-host-urls "$CONSENSUS_URL" \
  --sequencer.validatorPrivateKey "$PRIVATE_KEY" \
  --p2p.p2pIp "$LOCAL_IP" \
  --p2p.maxTxPoolSize 1000000000 \
  --archiver --node --sequencer

# Log takibi
echo -e "${CYAN}📊 Logları izlemek için:${NC} aztec logs --follow"
echo -e "${CYAN}📋 Alternatif Docker log komutu:${NC} docker logs -f aztec-node"

# Temizlik
cd ~ && rm -rf "$tmpdir"

echo -e "${GREEN}✅ Kurulum tamamlandı!${NC}"
