#!/bin/bash

# Renkler
KIRMIZI='\033[0;31m'
YESIL='\033[0;32m'
SARI='\033[0;33m'
MAVI='\033[0;34m'
MOR='\033[0;35m'
TURKUAZ='\033[0;36m'
BEYAZ='\033[1;37m'
RESET='\033[0m'

clear

# KriptoKurdu Banner
echo -e "${SARI}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║          𝕂𝕣𝕚𝕡𝕥𝕠𝕂𝕦𝕣𝕕𝕦 - 𝔸𝕫𝕥𝕖𝕔 ℕ𝕠𝕕𝕖 𝕂𝕦𝕣𝕦𝕝𝕦𝕞𝕦             ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${KIRMIZI}❌ Lütfen bu betiği root olarak çalıştırın: sudo su${RESET}"
  exit 1
fi

# Başlatma Mesajı
echo -e "${BEYAZ}KriptoKurdu Aztec Node Kurulum Sihirbazına Hoş Geldiniz!${RESET}"
echo -e "${YESIL}Bu sihirbaz sisteminize Aztec sequencer node'u kuracak ve başlatacaktır.${RESET}"
echo -e "${SARI}Lütfen kurulum tamamlanana kadar bekleyin...${RESET}\n"

# Ana dizine git
cd

# Sistem kontrolü
echo -e "${TURKUAZ}══════════ Sistem Kontrolü ══════════${RESET}"

# İşlemci Kontrolü
CPU_CORES=$(nproc)
echo -ne "${BEYAZ}İşlemci Çekirdekleri: ${RESET}"
if [ "$CPU_CORES" -lt 8 ]; then
    echo -e "${KIRMIZI}$CPU_CORES çekirdek (Önerilen: 8+)${RESET}"
    echo -e "${SARI}⚠️  Uyarı: En iyi performans için 8+ çekirdek önerilir${RESET}"
else
    echo -e "${YESIL}$CPU_CORES çekirdek ✓${RESET}"
fi

# RAM Kontrolü
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
echo -ne "${BEYAZ}Toplam RAM: ${RESET}"
if [ "$TOTAL_MEM" -lt 16000 ]; then
    echo -e "${KIRMIZI}$TOTAL_MEM MB (Önerilen: 16+ GB)${RESET}"
    echo -e "${SARI}⚠️  Uyarı: Stabil çalışma için en az 16GB RAM önerilir${RESET}"
else
    echo -e "${YESIL}$TOTAL_MEM MB ✓${RESET}"
fi

# Disk Kontrolü
DISK_SPACE=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')
echo -ne "${BEYAZ}Kullanılabilir Disk Alanı: ${RESET}"
if (( $(echo "$DISK_SPACE < 100" | bc -l 2>/dev/null || echo 1) )); then
    echo -e "${KIRMIZI}${DISK_SPACE}GB (Önerilen: 100+ GB)${RESET}"
    echo -e "${SARI}⚠️  Uyarı: Sequencer verileri için en az 100GB boş alan önerilir${RESET}"
else
    echo -e "${YESIL}${DISK_SPACE}GB ✓${RESET}"
fi

# Onay İste
echo -e "\n${BEYAZ}Sistem gereksinimleri karşılanmıyor olsa bile kuruluma devam edilsin mi?${RESET}"
echo -e "${BEYAZ}Devam etmek için ENTER tuşuna basın, iptal etmek için CTRL+C tuşuna basın...${RESET}"
read -r

# Mevcut Aztec kurulumunu temizle (eğer varsa)
echo -e "\n${TURKUAZ}══════════ Mevcut Kurulumu Temizleme ══════════${RESET}"

# Aztec'i durdur (eğer çalışıyorsa)
if command -v aztec &> /dev/null; then
    echo -e "${BEYAZ}Çalışan Aztec servisi durdurulmaya çalışılıyor...${RESET}"
    aztec stop &>/dev/null || true
    echo -e "${YESIL}✅ Aztec servisi durduruldu (varsa)${RESET}"
fi

# Docker konteynerlerini temizle
if command -v docker &> /dev/null; then
    echo -e "${BEYAZ}Aztec Docker konteynerleri temizleniyor...${RESET}"
    docker rm -f aztec-node &>/dev/null || true
    docker rm -f $(docker ps -a -q --filter ancestor=aztecprotocol/aztec:latest) &>/dev/null || true
    echo -e "${YESIL}✅ Docker konteynerleri temizlendi${RESET}"
fi

# Veri dizinlerini temizle
echo -e "${BEYAZ}Eski Aztec verileri temizleniyor...${RESET}"
rm -rf ~/.aztec/alpha-testnet/data/ &>/dev/null || true
rm -rf /root/aztec-data/ &>/dev/null || true
echo -e "${YESIL}✅ Eski veri dizinleri temizlendi${RESET}"

echo -e "\n${TURKUAZ}══════════ Sistem Güncelleniyor ══════════${RESET}"
echo -e "${BEYAZ}Sistem paketleri güncelleniyor...${RESET}"
apt-get update && apt-get upgrade -y

echo -e "${BEYAZ}Gerekli temel paketler yükleniyor...${RESET}"
apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip

# Docker Kontrolü ve Kurulumu
echo -e "\n${TURKUAZ}══════════ Docker Kuruluyor ══════════${RESET}"
if ! command -v docker &> /dev/null; then
    echo -e "${BEYAZ}Docker kuruluyor...${RESET}"
    apt install -y docker.io
    systemctl enable --now docker
    echo -e "${YESIL}✅ Docker başarıyla kuruldu!${RESET}"
else
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo -e "${YESIL}✅ Docker zaten kurulu. Sürüm: $DOCKER_VERSION${RESET}"
fi

# Docker soket izinlerini düzelt
echo -e "${BEYAZ}Docker soket izinleri düzeltiliyor...${RESET}"
chmod 666 /var/run/docker.sock
echo -e "${YESIL}✅ Docker soket izinleri düzeltildi${RESET}"

# UFW kurulumu ve yapılandırması
echo -e "\n${TURKUAZ}══════════ Güvenlik Duvarı Yapılandırılıyor ══════════${RESET}"
if ! command -v ufw &> /dev/null; then
    echo -e "${BEYAZ}UFW (Uncomplicated Firewall) kuruluyor...${RESET}"
    apt-get install -y ufw
    echo -e "${YESIL}✅ UFW başarıyla kuruldu!${RESET}"
else
    echo -e "${YESIL}✅ UFW zaten kurulu.${RESET}"
fi

echo -e "${BEYAZ}Gerekli portlar açılıyor...${RESET}"
ufw allow ssh
ufw allow 40400/tcp
ufw allow 40400/udp
ufw allow 40500/tcp
ufw allow 40500/udp
ufw allow 8080/tcp
ufw --force enable
echo -e "${YESIL}✅ Güvenlik duvarı yapılandırması tamamlandı${RESET}"

echo -e "\n${TURKUAZ}══════════ Aztec Kurulumu ══════════${RESET}"
echo -e "${BEYAZ}Aztec CLI kuruluyor (resmi Aztec kurulum betiği)...${RESET}"

# Aztec'in resmi kurulum betiğini kullan
bash -i <(curl -s https://install.aztec.network)

# PATH güncellemesini bash profiline ekle
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
export PATH="$HOME/.aztec/bin:$PATH"

# Testnet sürümünü yükle
echo -e "${BEYAZ}Alpha testnet sürümünü yüklüyorum...${RESET}"
aztec-up alpha-testnet

# IP adresini al
PUBLIC_IP=$(curl -s api.ipify.org)
echo -e "\n${BEYAZ}🌐 Sunucu IP Adresi: ${YESIL}$PUBLIC_IP${RESET}"
echo -e "${SARI}⚠️  Lütfen bu IP adresini not alın, validator kayıt işleminde gerekecektir.${RESET}"
echo -e "${BEYAZ}IP adresinizi kaydettiniz mi? (e/h): ${RESET}"
read -r SAVED_IP
if [[ "$SAVED_IP" != "e" && "$SAVED_IP" != "E" ]]; then
    echo -e "${KIRMIZI}❗ Lütfen IP adresinizi kaydedin ve betiği tekrar çalıştırın.${RESET}"
    exit 1
fi

# Veri dizini oluştur
mkdir -p /root/aztec-data/

# Özel anahtar ve cüzdan bilgileri için güvenlik uyarısı
echo -e "\n${TURKUAZ}══════════ Güvenlik Uyarısı ══════════${RESET}"
echo -e "${KIRMIZI}⚠️ ÖNEMLİ GÜVENLİK UYARISI ⚠️${RESET}"
echo -e "${SARI}Validator işlemleri için YENİ ve SADECE bu amaçla kullanılacak bir Ethereum cüzdanı oluşturmanız önerilir.${RESET}"
echo -e "${SARI}Ana cüzdanınızın özel anahtarını ASLA kullanmayın!${RESET}"
echo -e "${BEYAZ}Yeni bir cüzdan oluşturmak için MetaMask veya başka bir Ethereum cüzdanı kullanabilirsiniz.${RESET}"
echo -e "${BEYAZ}MetaMask > Hesap Oluştur > Hesap Ayarları > Özel Anahtarı Dışa Aktar${RESET}\n"

# Çevre değişkenleri için cüzdan adresi al
echo -e "\n${TURKUAZ}══════════ Cüzdan Bilgileri ══════════${RESET}"
echo -e "${BEYAZ}🔐 Blok ödüllerini alacak Ethereum cüzdan adresinizi girin: ${RESET}"
read -r COINBASE

# Cüzdan adresi formatını kontrol et
if [[ ! "$COINBASE" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
    echo -e "${SARI}⚠️ Girdiğiniz adres '0x' ile başlayan 42 karakterlik bir Ethereum adresi değil.${RESET}"
    echo -e "${BEYAZ}Devam etmek için ENTER tuşuna basın, iptal etmek için CTRL+C tuşuna basın...${RESET}"
    read -r
fi

# Çevre değişkenlerini ayarla
export DATA_DIRECTORY=/root/aztec-data/
export COINBASE=$COINBASE
export LOG_LEVEL=debug
export P2P_MAX_TX_POOL_SIZE=1000000000

# RPC ve diğer bilgileri al
echo -e "\n${TURKUAZ}══════════ RPC Bilgileri ══════════${RESET}"
echo -e "${BEYAZ}🌍 Ethereum Sepolia RPC URL'nizi girin (veya varsayılan için boş bırakın):${RESET}"
echo -e "${SARI}(Buradan alabilirsiniz: https://dashboard.alchemy.com/apps/)${RESET}"
read -r RPC_URL
if [ -z "$RPC_URL" ]; then
    RPC_URL="https://eth-beacon-chain-sepolia.drpc.org/rest/"
    echo -e "${SARI}Varsayılan RPC URL kullanılıyor: $RPC_URL${RESET}"
fi

echo -e "${BEYAZ}🛰️ Ethereum Beacon Consensus RPC URL'nizi girin (veya varsayılan için boş bırakın):${RESET}"
echo -e "${SARI}(Buradan alabilirsiniz: https://console.chainstack.com/user/login)${RESET}"
read -r CONSENSUS_URL
if [ -z "$CONSENSUS_URL" ]; then
    CONSENSUS_URL="https://eth-beacon-chain.drpc.org/rest/"
    echo -e "${SARI}Varsayılan Consensus URL kullanılıyor: $CONSENSUS_URL${RESET}"
fi

echo -e "${BEYAZ}📡 Az önce kaydettiğiniz IP adresinizi girin (veya otomatik tespit için boş bırakın):${RESET}"
read -r LOCAL_IP
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP=$PUBLIC_IP
    echo -e "${SARI}Otomatik tespit edilen IP kullanılıyor: $LOCAL_IP${RESET}"
fi

echo -e "${BEYAZ}🔑 Özel anahtarınızı girin (Private Key):${RESET}"
read -r PRIVATE_KEY

# Özel anahtar formatını kontrol et
if [[ -z "$PRIVATE_KEY" ]]; then
    echo -e "${KIRMIZI}❌ Özel anahtar boş olamaz!${RESET}"
    exit 1
fi

# RPC URL'leri doğrulama
if [[ ! "$RPC_URL" =~ ^https?:// ]]; then
    echo -e "${KIRMIZI}❌ RPC URL'si geçerli bir format değil. 'http://' veya 'https://' ile başlamalı.${RESET}"
    exit 1
fi

if [[ ! "$CONSENSUS_URL" =~ ^https?:// ]]; then
    echo -e "${KIRMIZI}❌ Consensus URL'si geçerli bir format değil. 'http://' veya 'https://' ile başlamalı.${RESET}"
    exit 1
fi

echo -e "\n${TURKUAZ}══════════ Aztec Node Başlatılıyor ══════════${RESET}"
echo -e "${BEYAZ}Docker ile Aztec node başlatılıyor. Bu işlem biraz zaman alabilir...${RESET}"
echo -e "${SARI}Not: İşlem sırasında komut çıktısı görüntülenmezse endişelenmeyin, bu normaldir.${RESET}"

# Docker varsa eski konteyneri kaldır
docker rm -f aztec-node &>/dev/null || true

# Docker ile doğrudan başlat
echo -e "${BEYAZ}Docker ile node başlatılıyor...${RESET}"
docker run -d \
  --name aztec-node \
  -p 8080:8080 \
  -p 40400:40400/tcp \
  -p 40400:40400/udp \
  -p 40500:40500 \
  -e DATA_DIRECTORY=/data \
  -e LOG_LEVEL=debug \
  -v /root/aztec-data:/data \
  aztecprotocol/aztec:latest \
  node /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --node --archiver --sequencer \
  --l1-rpc-urls "$RPC_URL" \
  --l1-consensus-host-urls "$CONSENSUS_URL" \
  --sequencer.validatorPrivateKey "$PRIVATE_KEY" \
  --sequencer.coinbase "$COINBASE" \
  --p2p.p2pIp "$LOCAL_IP" \
  --p2p.maxTxPoolSize 1000000000

# Docker konteyner kontrolü
echo -e "${BEYAZ}Docker konteyneri kontrol ediliyor...${RESET}"
sleep 5  # Konteyner başlaması için bekle
CONTAINER_ID=$(docker ps -q -f name=aztec-node)
if [ -n "$CONTAINER_ID" ]; then
    echo -e "${YESIL}✅ Aztec Docker konteyneri başarıyla başlatıldı: ${CONTAINER_ID}${RESET}"
    
    # Konteyner durumunu göster
    docker ps | grep aztec-node
else
    echo -e "${KIRMIZI}❌ Docker konteyneri başlatılamadı.${RESET}"
    echo -e "${BEYAZ}Hata mesajı:${RESET}"
    docker logs aztec-node
    
    # Fallback: Daha basit bir yapılandırma ile tekrar dene
    echo -e "${SARI}⚠️ Daha basit bir yapılandırma ile tekrar deneniyor...${RESET}"
    docker run -d \
      --name aztec-node-simple \
      -p 8080:8080 \
      -p 40400:40400/tcp \
      -p 40400:40400/udp \
      -p 40500:40500 \
      -v /root/aztec-data:/data \
      aztecprotocol/aztec:latest \
      node /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --node
    
    sleep 5
    if [ -n "$(docker ps -q -f name=aztec-node-simple)" ]; then
        echo -e "${YESIL}✅ Basit yapılandırma ile Aztec node başlatıldı.${RESET}"
    else
        echo -e "${KIRMIZI}❌ Basit yapılandırma ile de başlatılamadı. Log'ları kontrol edin:${RESET}"
        docker logs aztec-node-simple
    fi
fi

# Kurulumu tamamla
echo -e "\n${TURKUAZ}══════════ Kurulum Tamamlandı ══════════${RESET}"
echo -e "${YESIL}✅ KriptoKurdu Aztec Node kurulum işlemi tamamlandı!${RESET}\n"

# Yardımcı Bilgiler
echo -e "${MOR}══════════ Önemli Komutlar ══════════${RESET}"
echo -e "${BEYAZ}📊 Log Kontrolü:${RESET}"
echo -e "${YESIL}docker logs -f aztec-node${RESET}\n"

echo -e "${BEYAZ}Docker Konteyner Yönetimi:${RESET}"
echo -e "${YESIL}docker stop aztec-node${RESET} (Node'u durdurmak için)"
echo -e "${YESIL}docker start aztec-node${RESET} (Node'u başlatmak için)"
echo -e "${YESIL}docker restart aztec-node${RESET} (Node'u yeniden başlatmak için)\n"

echo -e "${BEYAZ}🌐 Topluluk:${RESET}"
echo -e "${YESIL}Discord: https://discord.gg/aztec${RESET}"
echo -e "${YESIL}Twitter: https://twitter.com/KriptoKurduu${RESET}\n"

echo -e "${SARI}Not: Node'un tamamen senkronize olması yaklaşık 10-20 dakika sürebilir.${RESET}"
echo -e "${SARI}Doğrulayıcı kaydı sırasında 'ValidatorQuotaFilledUntil' hatası alırsanız,${RESET}"
echo -e "${SARI}bu günlük kota dolduğu anlamına gelir. 01:00 UTC'den sonra tekrar deneyin.${RESET}\n"

echo -e "${TURKUAZ}═══════════ Sorun Giderme ═══════════${RESET}"
echo -e "${BEYAZ}Eğer node başlatılmadıysa veya hata aldıysanız:${RESET}"
echo -e "${YESIL}1. Docker konteynerini durdurun:${RESET} docker stop aztec-node"
echo -e "${YESIL}2. Docker konteynerini kaldırın:${RESET} docker rm aztec-node"
echo -e "${YESIL}3. Mevcut verileri temizleyin:${RESET} rm -rf /root/aztec-data/*"
echo -e "${YESIL}4. Daha basit bir yapılandırma ile deneyin:${RESET}"
echo -e "${YESIL}   docker run -d --name aztec-node -p 8080:8080 -p 40400:40400 -p 40500:40500 aztecprotocol/aztec:latest node /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --node${RESET}\n"

echo -e "${TURKUAZ}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${TURKUAZ}║               ${BEYAZ}KriptoKurdu!${TURKUAZ}              ║${RESET}"
echo -e "${TURKUAZ}╚═══════════════════════════════════════════════════════════╝${RESET}"

exit 0
