#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

clear
# KriptoKurdu Banner
echo -e "${CYAN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════╗                                                 
                    K R İ P T O K U R D U 
                     A Z T E C  N O D E
             Twitter:  https://x.com/kriptokurduu
             Telegram: https://t.me/kriptokurdugrup
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}KriptoKurdu Aztec Node Kurulum Aracına Hoş Geldiniz!${NC}"
sleep 2

# Root olarak çalıştır
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}❌ Lütfen bu scripti root olarak çalıştırın: sudo su${NC}"
  exit 1
fi

# Ana dizine git
cd

# Kurulum tipi seçimi
echo -e "${YELLOW}Kurulum tipini seçin:${NC}"
echo -e "1) ${GREEN}Docker Tabanlı Kurulum${NC} (Önerilen)"
echo -e "2) ${BLUE}CLI Tabanlı Kurulum${NC}"
read -p "Seçiminiz (1/2): " INSTALL_TYPE

# Sistem güncelleme
echo -e "${YELLOW}📦 Sistem güncelleniyor...${NC}"
apt-get update && apt-get upgrade -y

# Bağımlılıkları yükle
echo -e "${GREEN}📚 Gerekli bağımlılıklar yükleniyor...${NC}"
apt install curl wget jq screen build-essential git lz4 make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y

# Docker kurulumu
echo -e "${BLUE}🐳 Docker yükleniyor...${NC}"
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  rm get-docker.sh
  systemctl enable docker
  systemctl start docker
else 
  echo -e "${GREEN}✅ Docker zaten kurulu.${NC}"
fi

# Public IP al
public_ip=$(curl -s ipinfo.io/ip)
echo -e "${YELLOW}🌐 Tespit edilen public IP: ${GREEN}$public_ip${NC}"
echo -e "${RED}⚠️  Lütfen devam etmeden önce bu IP adresini kaydedin.${NC}"
read -p "Kaydettin mi? (e/h): " saved
if [ "$saved" != "e" ]; then
  echo -e "${RED}❗ IP adresini kaydedin ve scripti tekrar çalıştırın.${NC}"
  exit 1
fi

# Güvenlik duvarı ayarları
echo -e "${BLUE}🔒 Güvenlik duvarı yapılandırılıyor...${NC}"
apt install ufw -y
ufw allow ssh
ufw allow 40400
ufw allow 40500
ufw allow 8080
ufw --force enable

# Cüzdan bilgisi
read -p "🔐 EVM cüzdan adresinizi girin (0x ile başlayan): " COINBASE

# RPC ve doğrulayıcı bilgileri
echo -e "${GREEN}Şimdi gerekli RPC ve doğrulayıcı bilgilerini gireceğiz${NC}"
echo -e "${YELLOW}RPC URL'i https://dashboard.alchemy.com/apps/ adresinden alabilirsiniz${NC}"
read -p "🌍 Ethereum Sepolia RPC URL'nizi girin: " RPC_URL

echo -e "${YELLOW}Consensus URL'i https://console.chainstack.com/user/login adresinden alabilirsiniz${NC}"
read -p "🛰️ Ethereum Beacon Consensus RPC URL'nizi girin: " CONSENSUS_URL

read -p "📡 Kaydettiğiniz public IP adresinizi girin: " LOCAL_IP
read -p "🔑 Doğrulayıcı özel anahtarınızı girin (0x olmadan girebilirsiniz): " PRIVATE_KEY

# 0x ekle eğer yoksa
if [[ ! $PRIVATE_KEY =~ ^0x ]]; then
    PRIVATE_KEY="0x$PRIVATE_KEY"
fi

# Docker tabanlı kurulum
if [ "$INSTALL_TYPE" = "1" ]; then
  echo -e "${CYAN}🚀 Docker ile Aztec node başlatılıyor...${NC}"
  
  # Eski container silinsin
  docker rm -f kriptokurdu-aztec-node 2>/dev/null
  
  # Node başlat - DÜZELTİLMİŞ KOMUT
  docker run -d --name kriptokurdu-aztec-node \
    -e HOME=/root \
    -e FORCE_COLOR=1 \
    -p 8080:8080 -p 40400:40400 -p 40400:40400/udp \
    --add-host host.docker.internal:host-gateway \
    aztecprotocol/aztec:latest \
    start \
    --node --archiver --sequencer \
    --network alpha-testnet \
    --l1-rpc-urls "$RPC_URL" \
    --l1-consensus-host-urls "$CONSENSUS_URL" \
    --sequencer.validatorPrivateKey "$PRIVATE_KEY" \
    --sequencer.coinbase "$COINBASE" \
    --p2p.p2pIp "$LOCAL_IP" \
    --p2p.maxTxPoolSize 1000000000
  
  sleep 3
  
  # Kontrol et çalışıyor mu
  if [ "$(docker ps -q -f name=kriptokurdu-aztec-node)" ]; then
    echo -e "${GREEN}✅ KriptoKurdu Aztec Node başarıyla başlatıldı!${NC}"
    echo -e "${BLUE}📝 Node loglarını görmek için: ${YELLOW}docker logs -f kriptokurdu-aztec-node${NC}"
  else
    echo -e "${RED}❌ Node başlatılırken bir sorun oluştu. Lütfen logları kontrol edin.${NC}"
    echo -e "${YELLOW}docker logs kriptokurdu-aztec-node${NC}"
  fi

# CLI tabanlı kurulum
else
  echo -e "${CYAN}🚀 Aztec CLI yükleniyor...${NC}"
  
  # Aztec CLI kur (non-interactive)
  curl -s https://install.aztec.network | bash -s -- -y
  
  # PATH'e ekle
  echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
  echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bash_profile
  export PATH="$HOME/.aztec/bin:$PATH"
  
  echo -e "${GREEN}✅ Aztec CLI başarıyla kuruldu!${NC}"
  sleep 2
  
  # Testnet'e geçiş
  echo -e "${CYAN}🌐 Alpha-testnet'e geçiliyor...${NC}"
  aztec-up alpha-testnet &>/dev/null || true
  
  # Start script oluştur
  echo -e "${CYAN}🚀 Node başlatma scripti oluşturuluyor...${NC}"
  
  cat > $HOME/start_kriptokurdu_aztec.sh <<EOFSCRIPT
#!/bin/bash
export PATH=\$PATH:\$HOME/.aztec/bin
aztec start --node --archiver --sequencer \\
  --network alpha-testnet \\
  --l1-rpc-urls "$RPC_URL" \\
  --l1-consensus-host-urls "$CONSENSUS_URL" \\
  --sequencer.validatorPrivateKey "$PRIVATE_KEY" \\
  --sequencer.coinbase "$COINBASE" \\
  --p2p.p2pIp "$LOCAL_IP" \\
  --p2p.maxTxPoolSize 1000000000
EOFSCRIPT

  chmod +x $HOME/start_kriptokurdu_aztec.sh
  
  echo -e "${CYAN}🚦 KriptoKurdu Aztec node başlatılıyor (screen oturumunda)...${NC}"
  screen -dmS aztec $HOME/start_kriptokurdu_aztec.sh
  
  echo -e "${GREEN}✅ KriptoKurdu Aztec Node başarıyla başlatıldı!${NC}"
  echo -e "${BLUE}📝 Node ekranını görmek için: ${YELLOW}screen -r aztec${NC}"
  echo -e "${BLUE}📝 Screen oturumundan çıkmak için: ${YELLOW}CTRL + A ardından D${NC}"
fi

# Discord rolü rehberi
echo -e "${PURPLE}======== DISCORD ROLÜ ALMA REHBERİ ========${NC}"
echo -e "${CYAN}Discord 'Apprentice' rolü almak için node 5 dakika çalıştıktan sonra:${NC}"
echo -e "${YELLOW}1. Block numarası almak için:${NC}"
echo -e "${GREEN}curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"node_getL2Tips\",\"params\":[],\"id\":67}' http://localhost:8080 | jq -r \".result.proven.number\"${NC}"
echo
echo -e "${YELLOW}2. Proof almak için (BLOCK yerine az önce aldığınız numarayı yazın):${NC}"
echo -e "${GREEN}curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"node_getArchiveSiblingPath\",\"params\":[\"BLOCK\",\"BLOCK\"],\"id\":67}' http://localhost:8080 | jq -r \".result\"${NC}"
echo
echo -e "${YELLOW}3. Discord'da rol almak için:${NC}"
echo -e "${GREEN}- https://discord.gg/aztec adresine katılın${NC}"
echo -e "${GREEN}- #operators > start-here kanalına girin${NC}"
echo -e "${GREEN}- /operator start komutunu yazın${NC}"
echo -e "${GREEN}- Wallet adresinizi, block numaranızı ve proof'u girin${NC}"

# Validator kaydı rehberi
echo -e "${PURPLE}======== VALIDATOR KAYDI REHBERİ ========${NC}"
echo -e "${CYAN}Node senkronize olduktan sonra validator olarak kaydolmak için:${NC}"
echo -e "${GREEN}bash -c \"$(curl -fsSL https://raw.githubusercontent.com/UfukNode/aztec-sequencer-node/main/validator_kayıt.sh)\"${NC}"

echo -e "${YELLOW}Bu node hakkında sorularınız için Telegram grubuna katılın: https://t.me/kriptokurdugrup${NC}"
