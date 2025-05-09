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

# Geçici dizin oluştur
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR

# Bootnodes.json dosyasını manuel olarak oluştur
echo -e "${CYAN}📥 bootnode.json dosyası oluşturuluyor...${NC}"
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

# Sistem kontrolleri ve hazırlıklar
echo -e "${CYAN}🔧 Sistem kontrolü ve hazırlık yapılıyor...${NC}"

# DNS yapılandırması
echo -e "${CYAN}🌐 DNS yapılandırması iyileştiriliyor...${NC}"
cat > /etc/resolv.conf << EOL
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOL

# Hosts dosyasını güncelle
echo -e "${CYAN}📝 Hosts dosyası güncelleniyor...${NC}"
cat >> /etc/hosts << EOL
104.21.31.61 static.aztec.network
172.67.211.145 bootnode-alpha-1.aztec.network bootnode-alpha-2.aztec.network bootnode-alpha-3.aztec.network
EOL

# Static.aztec.network için yerel servis oluştur
echo -e "${CYAN}🌍 Yerel bootnode sunucusu oluşturuluyor...${NC}"
apt-get install -y nginx
mkdir -p /var/www/html/alpha-testnet/
cp bootnode.json /var/www/html/alpha-testnet/bootnodes.json
systemctl start nginx
systemctl enable nginx

# Sistem güncelleme
echo -e "${CYAN}📦 Sistem güncelleniyor...${NC}"
apt-get update && apt-get upgrade -y

# Bağımlılıkları yükle
echo -e "${CYAN}📚 Gerekli paketler yükleniyor...${NC}"
apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip dnsutils net-tools -y

# Docker temizliği ve kurulumu
echo -e "${YELLOW}🧹 Docker temizleniyor (eğer varsa)...${NC}"
if command -v docker &> /dev/null; then
  echo -e "${YELLOW}Mevcut Docker kurulumu bulundu. Temizleniyor...${NC}"
  docker stop $(docker ps -a -q) 2>/dev/null || true
  docker rm $(docker ps -a -q) 2>/dev/null || true
  docker system prune -af --volumes
  systemctl stop docker docker.socket containerd
  apt-get purge docker-ce docker-ce-cli containerd.io docker docker-engine docker.io containerd runc -y
  apt-get autoremove -y
  rm -rf /var/lib/docker /var/lib/containerd /etc/docker
  echo -e "${GREEN}Docker temizlendi.${NC}"
fi

echo -e "${CYAN}🐳 Docker yükleniyor...${NC}"
apt install docker.io -y
systemctl enable docker
systemctl start docker

# Docker'ı test et
if ! docker --version; then
  echo -e "${RED}❌ Docker kurulumu başarısız oldu.${NC}"
  exit 1
else
  echo -e "${GREEN}✅ Docker başarıyla kuruldu.${NC}"
fi

# Veri dizinini oluştur
DATA_DIR="/root/aztec-data"
mkdir -p $DATA_DIR

# Genel IP al
echo -e "${CYAN}🌐 Genel IP adresiniz alınıyor...${NC}"
public_ip=$(curl -s ipinfo.io/ip)
echo -e "${GREEN}Algılanan IP adresiniz: ${YELLOW}$public_ip${NC}"
read -p "$(echo -e ${YELLOW}Bu IP adresini kullanmak ister misiniz? (e/h):${NC}) " use_ip
if [ "$use_ip" = "e" ]; then
  LOCAL_IP=$public_ip
else
  read -p "$(echo -e ${YELLOW}📡 Kaydettiğiniz genel IP adresinizi girin: ${NC})" LOCAL_IP
fi

# Beacon consensus URL otomatik test et
echo -e "${CYAN}🛰️ Beacon consensus RPC URL otomatik test ediliyor...${NC}"
for url in "https://rpc.drpc.org/eth/sepolia/beacon" "https://lodestar-sepolia.chainsafe.io"; do
  echo -n "   Testing $url... "
  if curl -sf "$url" -o /dev/null; then
    CONSENSUS_URL=$url
    echo -e "${GREEN}OK${NC}"
    break
  else
    echo -e "${RED}FAIL${NC}"
  fi
done
if [ -z "$CONSENSUS_URL" ]; then
  read -p "$(echo -e ${YELLOW}🛰️ Çalışan Beacon RPC URL'sini girin:${NC}) " CONSENSUS_URL
fi

# Kullanıcı bilgilerini al
read -p "$(echo -e ${YELLOW}🔐 EVM cüzdan adresinizi girin: ${NC})" COINBASE
read -p "$(echo -e ${YELLOW}🌍 Ethereum Sepolia RPC URL'nizi girin: ${NC})" RPC_URL
read -p "$(echo -e ${YELLOW}🔑 Validator özel anahtarınızı girin: ${NC})" PRIVATE_KEY

# Local bootnodes.json dosyasını Aztec dizinine kopyala
mkdir -p $DATA_DIR/config/alpha-testnet
cp bootnode.json $DATA_DIR/config/alpha-testnet/bootnodes.json

# Docker ile node'u başlat
echo -e "${GREEN}🚦 Aztec node başlatılıyor...${NC}"
docker stop aztec-node 2>/dev/null || true
docker rm aztec-node 2>/dev/null || true

docker run -d \
  --name aztec-node \
  --network host \
  -v $DATA_DIR:/data \
  -e DATA_DIRECTORY=/data \
  -e ETHEREUM_HOSTS="$RPC_URL" \
  -e L1_CONSENSUS_HOST_URLS="$CONSENSUS_URL" \
  -e COINBASE="$COINBASE" \
  -e LOG_LEVEL=debug \
  -e VALIDATOR_PRIVATE_KEY="$PRIVATE_KEY" \
