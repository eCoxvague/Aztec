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
echo -e "${TURKUAZ}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║           ${BEYAZ}𝕂𝕣𝕚𝕡𝕥𝕠𝕂𝕦𝕣𝕕𝕦 - 𝔸𝕫𝕥𝕖𝕔 ℕ𝕠𝕕𝕖 𝕂𝕦𝕣𝕦𝕝𝕦𝕞𝕦${TURKUAZ}            ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# Başlatma Mesajı
echo -e "${BEYAZ}KriptoKurdu Aztec Node Kurulum Sihirbazına Hoş Geldiniz!${RESET}"
echo -e "${YESIL}Bu sihirbaz sisteminize Aztec sequencer node'u kuracak ve başlatacaktır.${RESET}"
echo -e "${SARI}Lütfen kurulum tamamlanana kadar bekleyin...${RESET}\n"

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

echo -e "\n${TURKUAZ}══════════ Gerekli Paketler Yükleniyor ══════════${RESET}"
echo -e "${BEYAZ}Sistem paketleri güncelleniyor...${RESET}"
sudo apt update && sudo apt upgrade -y

echo -e "${BEYAZ}Gerekli temel paketler yükleniyor...${RESET}"
sudo apt install -y curl wget git build-essential jq pkg-config libssl-dev bc screen libleveldb-dev

# Docker Kontrolü ve Kurulumu
if ! command -v docker &> /dev/null; then
    echo -e "${BEYAZ}Docker kuruluyor...${RESET}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo -e "${YESIL}✅ Docker başarıyla kuruldu!${RESET}"
else
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo -e "${YESIL}✅ Docker zaten kurulu. Sürüm: $DOCKER_VERSION${RESET}"
fi

# UFW kurulumunu kontrol et ve yükle
echo -e "\n${TURKUAZ}══════════ Güvenlik Duvarı Yapılandırılıyor ══════════${RESET}"
if ! command -v ufw &> /dev/null; then
    echo -e "${BEYAZ}UFW (Uncomplicated Firewall) kuruluyor...${RESET}"
    sudo apt-get install -y ufw
    echo -e "${YESIL}✅ UFW başarıyla kuruldu!${RESET}"
else
    echo -e "${YESIL}✅ UFW zaten kurulu.${RESET}"
fi

# Güvenlik duvarı yapılandırması
echo -e "${BEYAZ}Gerekli portlar açılıyor...${RESET}"
if command -v ufw &> /dev/null; then
    sudo ufw allow ssh
    sudo ufw allow 40400
    sudo ufw allow 40500
    sudo ufw allow 8080
    sudo ufw --force enable
    echo -e "${YESIL}✅ Güvenlik duvarı yapılandırması tamamlandı${RESET}"
else
    echo -e "${SARI}⚠️ UFW yüklenemedi, güvenlik duvarı yapılandırılmadı.${RESET}"
    echo -e "${SARI}⚠️ Kurulum devam edecek, ancak portları manuel olarak açmanız gerekebilir.${RESET}"
fi

echo -e "\n${TURKUAZ}══════════ Aztec Kurulumu ══════════${RESET}"
echo -e "${BEYAZ}Aztec CLI kuruluyor (resmi Aztec kurulum betiği)...${RESET}"

# Aztec'in resmi kurulum betiğini kullan
bash -i <(curl -s https://install.aztec.network)

# PATH güncellemesini bash profiline ekle
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Kurulum başarılı mı kontrol et
if ! command -v aztec &> /dev/null; then
    echo -e "${KIRMIZI}❌ Aztec kurulumu başarısız oldu. Lütfen manuel olarak kontrol edin.${RESET}"
    # Kurulum başarısız olsa bile devam et, kullanıcıya bilgi ver
    echo -e "${SARI}Kurulum işlemi devam edecek, ancak Aztec CLI komutları çalışmayabilir.${RESET}"
else
    echo -e "${YESIL}✅ Aztec CLI başarıyla kuruldu!${RESET}"
fi

# Kullanıcıdan Ethereum RPC URL'ini al (opsiyonel)
echo -e "\n${BEYAZ}Ethereum Sepolia RPC URL'nizi girin (boş bırakabilirsiniz):${RESET}"
echo -e "${SARI}Örnek: https://sepolia.infura.io/v3/YOUR-KEY${RESET}"
read -r RPC_URL

echo -e "\n${TURKUAZ}══════════ Aztec Node Başlatılıyor ══════════${RESET}"
echo -e "${BEYAZ}Aztec node başlatılıyor. Bu işlem biraz zaman alabilir...${RESET}"
echo -e "${SARI}Not: İşlem sırasında komut çıktısı görüntülenmezse endişelenmeyin, bu normaldir.${RESET}"

# PATH'i güncelle (bazı sistemlerde gerekli olabilir)
export PATH="$HOME/.aztec/bin:$PATH"

# Aztec başlatma komutunu çalıştır
if command -v aztec &> /dev/null; then
    # Aztec'i başlat (RPC URL girildiyse kullan)
    if [ -z "$RPC_URL" ]; then
        aztec start --network alpha-testnet --node --archiver || {
            echo -e "${KIRMIZI}❌ Aztec node başlatılamadı. Lütfen manuel olarak kontrol edin.${RESET}"
        }
    else
        aztec start --network alpha-testnet --l1-rpc-urls "$RPC_URL" --node --archiver || {
            echo -e "${KIRMIZI}❌ Aztec node başlatılamadı. Lütfen manuel olarak kontrol edin.${RESET}"
        }
    fi
else
    echo -e "${KIRMIZI}❌ Aztec komutu bulunamadı. Kurulum tamamlanamadı.${RESET}"
    echo -e "${SARI}Lütfen manuel olarak 'bash -i <(curl -s https://install.aztec.network)' komutunu çalıştırın ve kurulumu tamamlayın.${RESET}"
fi

# Kurulumu tamamla
echo -e "\n${TURKUAZ}══════════ Kurulum Tamamlandı ══════════${RESET}"
echo -e "${YESIL}✅ KriptoKurdu Aztec Node kurulum işlemi tamamlandı!${RESET}\n"

# IP adresini al
PUBLIC_IP=$(curl -s ipinfo.io/ip)
echo -e "${BEYAZ}🌐 Sunucu IP Adresi: ${YESIL}$PUBLIC_IP${RESET}"
echo -e "${SARI}⚠️  Lütfen bu IP adresini not alın, validator kayıt işleminde gerekecektir.${RESET}\n"

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
echo -e "${BEYAZ}Node'u başlatmak için:${RESET} ${YESIL}aztec start --network alpha-testnet --node --archiver${RESET}\n"

echo -e "${TURKUAZ}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${TURKUAZ}║               ${BEYAZ}KriptoKurdu!${TURKUAZ}              ║${RESET}"
echo -e "${TURKUAZ}╚═══════════════════════════════════════════════════════════╝${RESET}"

exit 0
