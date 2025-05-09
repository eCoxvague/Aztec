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
if [ "$TOTAL_MEM" -lt 8000 ]; then
    echo -e "${KIRMIZI}$TOTAL_MEM MB (Önerilen: 8+ GB)${RESET}"
    echo -e "${SARI}⚠️  Uyarı: Stabil çalışma için en az 8GB RAM önerilir${RESET}"
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
ufw allow 40400
ufw allow 40500
ufw allow 8080
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

# IP adresini al
PUBLIC_IP=$(curl -s ipinfo.io/ip)
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

# Çevre değişkenleri için cüzdan adresi al
echo -e "\n${TURKUAZ}══════════ Cüzdan Bilgileri ══════════${RESET}"
echo -e "${BEYAZ}🔐 Ethereum cüzdan adresinizi girin: ${RESET}"
read -r COINBASE

# Çevre değişkenlerini ayarla
export DATA_DIRECTORY=/root/aztec-data/
export COINBASE=$COINBASE
export LOG_LEVEL=debug
export P2P_MAX_TX_POOL_SIZE=1000000000

# RPC ve diğer bilgileri al
echo -e "\n${TURKUAZ}══════════ RPC Bilgileri ══════════${RESET}"
echo -e "${BEYAZ}🌍 Ethereum Sepolia RPC URL'nizi girin:${RESET}"
echo -e "${SARI}(Buradan alabilirsiniz: https://dashboard.alchemy.com/apps/)${RESET}"
read -r RPC_URL

echo -e "${BEYAZ}🛰️ Ethereum Beacon Consensus RPC URL'nizi girin:${RESET}"
echo -e "${SARI}(Buradan alabilirsiniz: https://console.chainstack.com/user/login)${RESET}"
read -r CONSENSUS_URL

echo -e "${BEYAZ}📡 Az önce kaydettiğiniz IP adresinizi girin:${RESET}"
read -r LOCAL_IP

echo -e "${BEYAZ}🔑 Validator özel anahtarınızı girin:${RESET}"
read -r PRIVATE_KEY

echo -e "\n${TURKUAZ}══════════ Aztec Node Başlatılıyor ══════════${RESET}"
echo -e "${BEYAZ}Aztec node başlatılıyor. Bu işlem biraz zaman alabilir...${RESET}"
echo -e "${SARI}Not: İşlem sırasında komut çıktısı görüntülenmezse endişelenmeyin, bu normaldir.${RESET}"

# Aztec node'u tam parametrelerle başlat
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

# Kurulumu tamamla
echo -e "\n${TURKUAZ}══════════ Kurulum Tamamlandı ══════════${RESET}"
echo -e "${YESIL}✅ KriptoKurdu Aztec Node kurulum işlemi tamamlandı!${RESET}\n"

# Yardımcı Bilgiler
echo -e "${MOR}══════════ Önemli Komutlar ══════════${RESET}"
echo -e "${BEYAZ}📊 Log Kontrolü:${RESET}"
echo -e "${YESIL}sudo docker logs -f \$(sudo docker ps -q --filter ancestor=aztecprotocol/aztec:latest | head -n 1)${RESET}\n"

echo -e "${BEYAZ}🔍 İspatlanmış Son Blok Numarası:${RESET}"
echo -e "${YESIL}curl -s -X POST -H 'Content-Type: application/json' \\
-d '{\"jsonrpc\":\"2.0\",\"method\":\"node_getL2Tips\",\"params\":[],\"id\":67}' \\
http://localhost:8080 | jq -r \".result.proven.number\"${RESET}\n"

echo -e "${BEYAZ}🔄 Senkronizasyon Kanıtı (BLOCK_NUMBER yerine blok numarası yazın):${RESET}"
echo -e "${YESIL}curl -s -X POST -H 'Content-Type: application/json' \\
-d '{\"jsonrpc\":\"2.0\",\"method\":\"node_getArchiveSiblingPath\",\"params\":[\"BLOCK_NUMBER\",\"BLOCK_NUMBER\"],\"id\":67}' \\
http://localhost:8080 | jq -r \".result\"${RESET}\n"

echo -e "${BEYAZ}📝 Doğrulayıcı Kayıt Komutu:${RESET}"
echo -e "${YESIL}aztec add-l1-validator \\
  --l1-rpc-urls SEPOLIA-RPC-URL \\
  --private-key CÜZDAN-ÖZEL-ANAHTARINIZ \\
  --attester CÜZDAN-ADRESİNİZ \\
  --proposer-eoa CÜZDAN-ADRESİNİZ \\
  --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \\
  --l1-chain-id 11155111${RESET}\n"

echo -e "${BEYAZ}🌐 Topluluk:${RESET}"
echo -e "${YESIL}Discord: https://discord.gg/aztec${RESET}"
echo -e "${YESIL}Twitter: https://twitter.com/KriptoKurduu${RESET}\n"

echo -e "${SARI}Not: Node'un tamamen senkronize olması yaklaşık 10-20 dakika sürebilir.${RESET}"
echo -e "${SARI}Doğrulayıcı kaydı sırasında 'ValidatorQuotaFilledUntil' hatası alırsanız,${RESET}"
echo -e "${SARI}bu günlük kota dolduğu anlamına gelir. 01:00 UTC'den sonra tekrar deneyin.${RESET}\n"

echo -e "${BEYAZ}Node'u durdurmak için:${RESET} ${YESIL}aztec stop${RESET}"
echo -e "${BEYAZ}Node'u başlatmak için:${RESET} ${YESIL}aztec start --network alpha-testnet --node --archiver --sequencer${RESET}\n"

echo -e "${TURKUAZ}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${TURKUAZ}║               ${BEYAZ}KriptoKurdu!${TURKUAZ}              ║${RESET}"
echo -e "${TURKUAZ}╚═══════════════════════════════════════════════════════════╝${RESET}"

exit 0
