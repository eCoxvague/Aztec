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
sleep 3

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
ufw --force enable

# Kullanıcı bilgilerini al
read -p "$(echo -e ${YELLOW}"🔐 EVM cüzdan adresinizi girin: "${NC})" COINBASE
read -p "$(echo -e ${YELLOW}"🌍 Ethereum Sepolia RPC URL'nizi girin: "${NC})" RPC_URL
read -p "$(echo -e ${YELLOW}"🛰️ Ethereum Beacon Consensus RPC URL'nizi girin: "${NC})" CONSENSUS_URL
read -p "$(echo -e ${YELLOW}"📡 Kaydettiğiniz genel IP adresinizi girin: "${NC})" LOCAL_IP
read -p "$(echo -e ${YELLOW}"🔑 Validator özel anahtarınızı girin: "${NC})" PRIVATE_KEY

# Doğrudan Docker imajını çek
echo -e "${CYAN}🚀 Aztec Docker imajı çekiliyor...${NC}"
docker pull aztecprotocol/aztec:alpha-testnet

# Eski container'ları temizle
docker stop aztec-node 2>/dev/null || true
docker rm aztec-node 2>/dev/null || true

# Environment dosyası oluştur
echo -e "${CYAN}📝 Environment dosyası oluşturuluyor...${NC}"
cat > aztec.env << EOL
DATA_DIRECTORY=/data
ETHEREUM_HOSTS=${RPC_URL}
L1_CONSENSUS_HOST_URLS=${CONSENSUS_URL}
COINBASE=${COINBASE}
LOG_LEVEL=debug
VALIDATOR_PRIVATE_KEY=${PRIVATE_KEY}
P2P_IP=${LOCAL_IP}
P2P_MAX_TX_POOL_SIZE=1000000000
EOL

# Kullanıcı adına manuel ortam değişkenleri ayarla
export P2P_BOOTSTRAP_NODES="/dns/bootnode-alpha-1.aztec.network/tcp/40400"
export BOOTSTRAP_NODES="/dns/bootnode-alpha-1.aztec.network/tcp/40400"

# Ağ adını düzelt (dev-alpha-testnet yerine sandpit kullanalım)
echo -e "${YELLOW}⚠️ network adı 'alpha-testnet' yerine 'sandpit' veya 'devnet' olabilir. İkisini de deneyeceğiz.${NC}"

# İlk deneme - alpha-testnet ile
echo -e "${GREEN}🚦 Aztec node başlatılıyor (alpha-testnet)...${NC}"
docker run -d \
  --name aztec-node \
  --network host \
  -v $DATA_DIR:/data \
  --env-file aztec.env \
  -e P2P_BOOTSTRAP_NODES="/dns/bootnode-alpha-1.aztec.network/tcp/40400" \
  -e BOOTSTRAP_NODES="/dns/bootnode-alpha-1.aztec.network/tcp/40400" \
  --restart unless-stopped \
  aztecprotocol/aztec:alpha-testnet \
  sh -c "node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --archiver --node --sequencer"

# Container durumunu kontrol et
sleep 5
if docker ps | grep -q aztec-node; then
  echo -e "${GREEN}✅ Aztec node başarıyla başlatıldı!${NC}"
else
  echo -e "${RED}❌ Aztec node başlatılamadı. alpha-testnet ağı ile başarısız oldu.${NC}"
  docker logs aztec-node
  docker stop aztec-node
  docker rm aztec-node
  
  # İkinci deneme - sandpit ile
  echo -e "${YELLOW}⚠️ 'sandpit' ağı ile deneniyor...${NC}"
  docker run -d \
    --name aztec-node \
    --network host \
    -v $DATA_DIR:/data \
    --env-file aztec.env \
    -e P2P_BOOTSTRAP_NODES="/dns/bootnode-alpha-1.aztec.network/tcp/40400" \
    -e BOOTSTRAP_NODES="/dns/bootnode-alpha-1.aztec.network/tcp/40400" \
    --restart unless-stopped \
    aztecprotocol/aztec:alpha-testnet \
    sh -c "node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network sandpit --archiver --node --sequencer"
  
  sleep 5
  if docker ps | grep -q aztec-node; then
    echo -e "${GREEN}✅ Aztec node 'sandpit' ağı ile başarıyla başlatıldı!${NC}"
  else
    echo -e "${RED}❌ Aztec node 'sandpit' ağı ile de başlatılamadı.${NC}"
    docker logs aztec-node
    docker stop aztec-node
    docker rm aztec-node
    
    # Üçüncü deneme - devnet ile
    echo -e "${YELLOW}⚠️ 'devnet' ağı ile deneniyor...${NC}"
    docker run -d \
      --name aztec-node \
      --network host \
      -v $DATA_DIR:/data \
      --env-file aztec.env \
      -e P2P_BOOTSTRAP_NODES="/dns/bootnode-alpha-1.aztec.network/tcp/40400" \
      -e BOOTSTRAP_NODES="/dns/bootnode-alpha-1.aztec.network/tcp/40400" \
      --restart unless-stopped \
      aztecprotocol/aztec:alpha-testnet \
      sh -c "node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network devnet --archiver --node --sequencer"
    
    sleep 5
    if docker ps | grep -q aztec-node; then
      echo -e "${GREEN}✅ Aztec node 'devnet' ağı ile başarıyla başlatıldı!${NC}"
    else
      echo -e "${RED}❌ Hiçbir ağ adı ile node başlatılamadı.${NC}"
      docker logs aztec-node
      
      # Son çare - ağ adı olmadan dene
      echo -e "${YELLOW}⚠️ Ağ adı olmadan deneniyor...${NC}"
      docker run -d \
        --name aztec-node-direct \
        --network host \
        -v $DATA_DIR:/data \
        --env-file aztec.env \
        -e P2P_BOOTSTRAP_NODES="/dns/bootnode-alpha-1.aztec.network/tcp/40400" \
        -e BOOTSTRAP_NODES="/dns/bootnode-alpha-1.aztec.network/tcp/40400" \
        --restart unless-stopped \
        aztecprotocol/aztec:alpha-testnet \
        sh -c "node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --archiver --node --sequencer"
      
      sleep 5
      if docker ps | grep -q aztec-node-direct; then
        echo -e "${GREEN}✅ Aztec node ağ adı olmadan başarıyla başlatıldı!${NC}"
      else
        echo -e "${RED}❌ Tüm denemeler başarısız oldu.${NC}"
        echo -e "${YELLOW}⚠️ Asıl Docker container loglarını kontrol ediyoruz...${NC}"
        docker logs aztec-node-direct
      fi
    fi
  fi
fi

# Docker container adını belirle
CONTAINER_NAME=$(docker ps | grep aztec | awk '{print $NF}' | head -n1)

# Container loglarını göster
echo -e "${CYAN}📋 Container logları (${CONTAINER_NAME}):${NC}"
docker logs --tail 20 $CONTAINER_NAME 2>/dev/null

echo -e "${GREEN}✅ Kurulum tamamlandı. Aşağıdaki bilgileri kaydedin:${NC}"
echo -e "${CYAN}Cüzdan: ${NC}$COINBASE"
echo -e "${CYAN}RPC URL: ${NC}$RPC_URL"
echo -e "${CYAN}Consensus URL: ${NC}$CONSENSUS_URL"
echo -e "${CYAN}IP Adresi: ${NC}$LOCAL_IP"
echo -e "${CYAN}Data Dizini: ${NC}$DATA_DIR"
echo -e "${CYAN}Container Adı: ${NC}$CONTAINER_NAME"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}   Node Yönetimi Komutları:${NC}"
echo -e "${GREEN}Logları görmek için:${NC} docker logs -f $CONTAINER_NAME"
echo -e "${GREEN}Node durumunu görmek için:${NC} docker ps | grep aztec"
echo -e "${GREEN}Node'u yeniden başlatmak için:${NC} docker restart $CONTAINER_NAME"
echo -e "${GREEN}Node'u durdurmak için:${NC} docker stop $CONTAINER_NAME"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}   Validator olarak kaydolmak için:${NC}"
echo -e "${GREEN}docker run --rm --network host -v $DATA_DIR:/data --env-file aztec.env aztecprotocol/aztec:alpha-testnet sh -c \"node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js add-l1-validator --l1-rpc-urls \\\"$RPC_URL\\\" --private-key \\\"$PRIVATE_KEY\\\" --attester \\\"$COINBASE\\\" --proposer-eoa \\\"$COINBASE\\\" --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 --l1-chain-id 11155111\"${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"

# Docker servisinin durumunu kontrol et
echo -e "${CYAN}🔍 Docker servisi durumu:${NC}"
systemctl status docker --no-pager | grep "Active:"

echo -e "${GREEN}✅ Kurulum işlemi tamamlandı!${NC}"
