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
# Cloudflare ve Google DNS'leri ekle
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
apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev dnsutils net-tools -y

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

# Local bootnodes.json dosyasını Aztec dizinine kopyala
mkdir -p $DATA_DIR/config/alpha-testnet
cp bootnode.json $DATA_DIR/config/alpha-testnet/bootnodes.json

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
ufw allow 40400/udp
ufw allow 40500
ufw allow 40500/udp
ufw allow 8080
ufw allow 80
ufw allow 443
ufw --force enable

# Kullanıcı bilgilerini al
read -p "$(echo -e ${YELLOW}"🔐 EVM cüzdan adresinizi girin: "${NC})" COINBASE
read -p "$(echo -e ${YELLOW}"🌍 Ethereum Sepolia RPC URL'nizi girin (https://dashboard.alchemy.com/apps/ adresinden alabilirsiniz): "${NC})" RPC_URL
read -p "$(echo -e ${YELLOW}"🛰️ Ethereum Beacon Consensus RPC URL'nizi girin (https://console.chainstack.com/user/login adresinden alabilirsiniz): "${NC})" CONSENSUS_URL
read -p "$(echo -e ${YELLOW}"📡 Kaydettiğiniz genel IP adresinizi girin: "${NC})" LOCAL_IP
read -p "$(echo -e ${YELLOW}"🔑 Validator özel anahtarınızı girin: "${NC})" PRIVATE_KEY

# Doğrudan Docker imajını çek
echo -e "${CYAN}🚀 Aztec Docker imajı çekiliyor...${NC}"
docker pull aztecprotocol/aztec:alpha-testnet

# Eski container'ları temizle
docker stop aztec-node 2>/dev/null || true
docker rm aztec-node 2>/dev/null || true

# Static URL yönlendirmesi için host dosyasını güncelle
echo "127.0.0.1 static.aztec.network" >> /etc/hosts

# Docker ile node'u başlat
echo -e "${GREEN}🚦 Aztec node başlatılıyor...${NC}"

# Docker container'ını oluştur
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
  -e P2P_IP="$LOCAL_IP" \
  -e P2P_MAX_TX_POOL_SIZE=1000000000 \
  -e NETWORK_NAME="alpha-testnet" \
  --restart unless-stopped \
  aztecprotocol/aztec:alpha-testnet \
  sh -c "cp /data/config/alpha-testnet/bootnodes.json /usr/src/yarn-project/aztec/dest/cli/chain_l2_config && node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --archiver --node --sequencer"

# Container durumunu kontrol et
sleep 5
if docker ps | grep -q aztec-node; then
  echo -e "${GREEN}✅ Aztec node başarıyla başlatıldı!${NC}"
  echo -e "${CYAN}📊 Node durumu:${NC}"
  docker ps | grep aztec-node
else
  echo -e "${RED}❌ Aztec node başlatılamadı. Logları kontrol ediniz:${NC}"
  docker logs aztec-node
  
  echo -e "${YELLOW}⚠️ Alternatif başlatma yöntemi deneniyor...${NC}"
  # Yerel IP'yi 127.0.0.1 olarak ayarla
  echo -e "${YELLOW}Yerel statik web sunucusu ayarlanıyor...${NC}"
  
  # Bootnode.json dosyasını doğrudan container içine kopyala
  docker run -d \
    --name aztec-node-alt \
    --network host \
    -v $DATA_DIR:/data \
    -e DATA_DIRECTORY=/data \
    -e ETHEREUM_HOSTS="$RPC_URL" \
    -e L1_CONSENSUS_HOST_URLS="$CONSENSUS_URL" \
    -e COINBASE="$COINBASE" \
    -e LOG_LEVEL=debug \
    -e VALIDATOR_PRIVATE_KEY="$PRIVATE_KEY" \
    -e P2P_IP="$LOCAL_IP" \
    -e P2P_MAX_TX_POOL_SIZE=1000000000 \
    -e NETWORK_NAME="alpha-testnet" \
    --restart unless-stopped \
    --add-host=static.aztec.network:127.0.0.1 \
    aztecprotocol/aztec:alpha-testnet \
    sh -c "mkdir -p /usr/src/yarn-project/aztec/dest/cli/config/alpha-testnet/ && cp /data/config/alpha-testnet/bootnodes.json /usr/src/yarn-project/aztec/dest/cli/config/alpha-testnet/ && node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --archiver --node --sequencer"
  
  sleep 5
  if docker ps | grep -q aztec-node-alt; then
    echo -e "${GREEN}✅ Alternatif yöntemle Aztec node başarıyla başlatıldı!${NC}"
    echo -e "${CYAN}📊 Node durumu:${NC}"
    docker ps | grep aztec-node-alt
  else
    echo -e "${RED}❌ Alternatif yöntem de başarısız oldu.${NC}"
    docker logs aztec-node-alt
  fi
fi

# Container loglarını göster
echo -e "${CYAN}📋 Container logları:${NC}"
docker logs --tail 20 aztec-node 2>/dev/null || docker logs --tail 20 aztec-node-alt 2>/dev/null

echo -e "${GREEN}✅ Kurulum tamamlandı. Aşağıdaki bilgileri kaydedin:${NC}"
echo -e "${CYAN}Cüzdan: ${NC}$COINBASE"
echo -e "${CYAN}RPC URL: ${NC}$RPC_URL"
echo -e "${CYAN}Consensus URL: ${NC}$CONSENSUS_URL"
echo -e "${CYAN}IP Adresi: ${NC}$LOCAL_IP"
echo -e "${CYAN}Data Dizini: ${NC}$DATA_DIR"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}   Node Yönetimi Komutları:${NC}"
echo -e "${GREEN}Logları görmek için:${NC} docker logs -f $(docker ps | grep aztec | awk '{print $1}' | head -n1)"
echo -e "${GREEN}Node durumunu görmek için:${NC} docker ps | grep aztec"
echo -e "${GREEN}Node'u yeniden başlatmak için:${NC} docker restart $(docker ps | grep aztec | awk '{print $1}' | head -n1)"
echo -e "${GREEN}Node'u durdurmak için:${NC} docker stop $(docker ps | grep aztec | awk '{print $1}' | head -n1)"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}   Validator olarak kaydolmak için:${NC}"
echo -e "${GREEN}docker run --rm --network host -v $DATA_DIR:/data aztecprotocol/aztec:alpha-testnet sh -c \"node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js add-l1-validator --l1-rpc-urls \\\"$RPC_URL\\\" --private-key \\\"$PRIVATE_KEY\\\" --attester \\\"$COINBASE\\\" --proposer-eoa \\\"$COINBASE\\\" --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 --l1-chain-id 11155111\"${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"

# Docker servisinin durumunu kontrol et
echo -e "${CYAN}🔍 Docker servisi durumu:${NC}"
systemctl status docker --no-pager | grep "Active:"

# Tmux ile log takibi oluştur
if command -v tmux &> /dev/null; then
  echo -e "${CYAN}📊 Tmux oturumu oluşturuluyor...${NC}"
  CONTAINER_ID=$(docker ps | grep aztec | head -n 1 | awk '{print $1}')
  if [ -n "$CONTAINER_ID" ]; then
    tmux kill-session -t aztec-logs 2>/dev/null || true
    tmux new-session -d -s aztec-logs "docker logs -f $CONTAINER_ID"
    echo -e "${GREEN}✅ Tmux oturumu oluşturuldu. Logları görmek için:${NC} tmux attach -t aztec-logs"
  else
    echo -e "${RED}❌ Çalışan Aztec container'ı bulunamadığı için tmux oturumu oluşturulamadı.${NC}"
  fi
fi

# Temizlik
cd
rm -rf $TEMP_DIR

echo -e "${GREEN}✅ Kurulum işlemi tamamlandı!${NC}"
