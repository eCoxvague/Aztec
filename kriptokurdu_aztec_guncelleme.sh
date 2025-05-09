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

# KriptoKurdu Banner
echo -e "${TURKUAZ}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║        ${BEYAZ}𝕂𝕣𝕚𝕡𝕥𝕠𝕂𝕦𝕣𝕕𝕦 - 𝔸𝕫𝕥𝕖𝕔 ℕ𝕠𝕕𝕖 𝔾ü𝕟𝕔𝕖𝕝𝕝𝕖𝕞𝕖${TURKUAZ}             ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# Başlatma Mesajı
echo -e "${BEYAZ}KriptoKurdu Aztec Node Güncelleme Sihirbazına Hoş Geldiniz!${RESET}"
echo -e "${YESIL}Bu sihirbaz, Aztec sequencer node'unuzu en son sürüme güncelleyecektir.${RESET}"
echo -e "${SARI}⚠️  DİKKAT: Güncelleme sırasında mevcut veriler silinecektir!${RESET}\n"

# Onay İste
echo -e "${KIRMIZI}Bu işlem mevcut node'u durduracak ve verileri temizleyecektir.${RESET}"
echo -e "${BEYAZ}Devam etmek istiyor musunuz? (E/h): ${RESET}"
read -r RESP
if [[ "$RESP" =~ ^([hH][aA][yY][iI][rR]|[hH])$ ]]; then
    echo -e "${SARI}Güncelleme iptal edildi.${RESET}"
    exit 0
fi

echo -e "\n${TURKUAZ}══════════ Node Durduruluyor ══════════${RESET}"
echo -e "${BEYAZ}Çalışan Aztec konteynerler durduruluyor...${RESET}"

# Docker kontrol et ve çalışan konteynerları durdur
if command -v docker &> /dev/null; then
    RUNNING_CONTAINERS=$(docker ps -q --filter "ancestor=aztecprotocol/aztec")
    if [ -n "$RUNNING_CONTAINERS" ]; then
        docker stop $(docker ps -q --filter "ancestor=aztecprotocol/aztec") && \
        docker rm $(docker ps -a -q --filter "ancestor=aztecprotocol/aztec")
        echo -e "${YESIL}✅ Konteynerler başarıyla durduruldu.${RESET}"
    else
        echo -e "${SARI}⚠️  Çalışan Aztec konteyner bulunamadı.${RESET}"
    fi
else
    echo -e "${KIRMIZI}❌ Docker yüklü değil! Önce docker'ı kurmanız gerekiyor.${RESET}"
    exit 1
fi

echo -e "\n${TURKUAZ}══════════ Screen Oturumları Kapatılıyor ══════════${RESET}"
# Mevcut Screen oturumlarını kontrol et ve kapat
if command -v screen &> /dev/null; then
    AZTEC_SCREENS=$(screen -ls | grep -i aztec | awk '{print $1}')
    if [ -n "$AZTEC_SCREENS" ]; then
        screen -ls | grep -i aztec | awk '{print $1}' | xargs -I {} screen -X -S {} quit
        echo -e "${YESIL}✅ Aztec screen oturumları başarıyla kapatıldı.${RESET}"
    else
        echo -e "${SARI}⚠️  Çalışan Aztec screen oturumu bulunamadı.${RESET}"
    fi
else
    echo -e "${SARI}⚠️  Screen yüklü değil, oturumlar kapatılamadı.${RESET}"
fi

echo -e "\n${TURKUAZ}══════════ Aztec CLI Güncelleniyor ══════════${RESET}"
# NVM'i kontrol et ve etkinleştir
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Node.js ve npm kontrol et
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    echo -e "${BEYAZ}Aztec CLI güncelleniyor...${RESET}"
    npm update -g @aztec/cli@latest
    echo -e "${YESIL}✅ Aztec CLI başarıyla güncellendi.${RESET}"
else
    echo -e "${KIRMIZI}❌ Node.js veya npm yüklü değil! Öncelikle Node.js kurulumu yapmalısınız.${RESET}"
    exit 1
fi

echo -e "\n${TURKUAZ}══════════ Eski Veriler Temizleniyor ══════════${RESET}"
echo -e "${BEYAZ}Eski Aztec verileri temizleniyor...${RESET}"
if [ -d ~/.aztec/alpha-testnet/data/ ]; then
    rm -rf ~/.aztec/alpha-testnet/data/
    echo -e "${YESIL}✅ Eski veriler başarıyla temizlendi.${RESET}"
else
    echo -e "${SARI}⚠️  Silinecek veri bulunamadı.${RESET}"
fi

echo -e "\n${TURKUAZ}══════════ Aztec Node Yeniden Başlatılıyor ══════════${RESET}"
echo -e "${BEYAZ}Güncellenmiş Aztec node başlatılıyor. Bu işlem biraz zaman alabilir...${RESET}"
echo -e "${SARI}Not: İşlem sırasında komut çıktısı görüntülenmezse endişelenmeyin, bu normaldir.${RESET}"

# Node'u başlat
aztec-up alpha-testnet

# Kurulumu tamamla
echo -e "\n${TURKUAZ}══════════ Güncelleme Tamamlandı ══════════${RESET}"
echo -e "${YESIL}✅ KriptoKurdu Aztec Node güncelleme işlemi başarıyla tamamlandı!${RESET}\n"

# Yardımcı Bilgiler
echo -e "${MOR}══════════ Önemli Komutlar ══════════${RESET}"
echo -e "${BEYAZ}📊 Log Kontrolü:${RESET}"
echo -e "${YESIL}sudo docker logs -f \$(sudo docker ps -q --filter ancestor=aztecprotocol/aztec:latest | head -n 1)${RESET}\n"

echo -e "${BEYAZ}🔍 İspatlanmış Son Blok Numarası:${RESET}"
echo -e "${YESIL}curl -s -X POST -H 'Content-Type: application/json' \\
-d '{\"jsonrpc\":\"2.0\",\"method\":\"node_getL2Tips\",\"params\":[],\"id\":67}' \\
http://localhost:8080 | jq -r \".result.proven.number\"${RESET}\n"

echo -e "${BEYAZ}🕒 Node'un tekrar senkronize olması için biraz bekleyin.${RESET}"
echo -e "${BEYAZ}Sıkça sorulan sorular ve daha fazla yardım için discord kanalımızı ziyaret edin.${RESET}\n"

echo -e "${TURKUAZ}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${TURKUAZ}║       ${BEYAZ}KriptoKurdu Ekibine Teşekkürler!${TURKUAZ}                      ║${RESET}"
echo -e "${TURKUAZ}╚═══════════════════════════════════════════════════════════╝${RESET}"

exit 0
