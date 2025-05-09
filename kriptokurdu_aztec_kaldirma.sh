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
echo "║        ${BEYAZ}𝕂𝕣𝕚𝕡𝕥𝕠𝕂𝕦𝕣𝕕𝕦 - 𝔸𝕫𝕥𝕖𝕔 ℕ𝕠𝕕𝕖 𝕂𝕒𝕝𝕕ı𝕣𝕞𝕒${TURKUAZ}               ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# Başlatma Mesajı
echo -e "${BEYAZ}KriptoKurdu Aztec Node Kaldırma Aracına Hoş Geldiniz!${RESET}"
echo -e "${KIRMIZI}⚠️  DİKKAT: Bu işlem, Aztec node'unuzu tamamen kaldıracak ve tüm verilerinizi silecektir!${RESET}"
echo -e "${SARI}Bu işlem geri alınamaz.${RESET}\n"

# Onay İste
echo -e "${KIRMIZI}Aztec node'unuzu ve ilgili tüm verileri kaldırmak istediğinizden emin misiniz?${RESET}"
echo -e "${BEYAZ}Onaylıyorsanız 'ONAYLIYORUM' yazın: ${RESET}"
read -r ONAY
if [ "$ONAY" != "ONAYLIYORUM" ]; then
    echo -e "${YESIL}İşlem iptal edildi. Hiçbir değişiklik yapılmadı.${RESET}"
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
        echo -e "${YESIL}✅ Konteynerler başarıyla durduruldu ve kaldırıldı.${RESET}"
    else
        echo -e "${SARI}⚠️  Çalışan Aztec konteyner bulunamadı.${RESET}"
    fi
    
    # Docker imajlarını temizle
    AZTEC_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep aztecprotocol)
    if [ -n "$AZTEC_IMAGES" ]; then
        echo -e "${BEYAZ}Aztec Docker imajları kaldırılıyor...${RESET}"
        docker rmi $(docker images -q aztecprotocol/aztec) 2>/dev/null || true
        echo -e "${YESIL}✅ Docker imajları başarıyla kaldırıldı.${RESET}"
    else
        echo -e "${SARI}⚠️  Kaldırılacak Aztec Docker imajı bulunamadı.${RESET}"
    fi
else
    echo -e "${SARI}⚠️  Docker yüklü değil, konteynerler kaldırılamadı.${RESET}"
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

echo -e "\n${TURKUAZ}══════════ Aztec CLI Kaldırılıyor ══════════${RESET}"
# NVM'i kontrol et ve etkinleştir
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Node.js ve npm kontrol et
if command -v npm &> /dev/null; then
    echo -e "${BEYAZ}Aztec CLI kaldırılıyor...${RESET}"
    npm uninstall -g @aztec/cli 2>/dev/null || true
    echo -e "${YESIL}✅ Aztec CLI başarıyla kaldırıldı.${RESET}"
else
    echo -e "${SARI}⚠️  npm yüklü değil, Aztec CLI kaldırılamadı.${RESET}"
fi

echo -e "\n${TURKUAZ}══════════ Aztec Verileri Siliniyor ══════════${RESET}"
echo -e "${BEYAZ}Aztec veri dizinleri siliniyor...${RESET}"
if [ -d ~/.aztec ]; then
    rm -rf ~/.aztec
    echo -e "${YESIL}✅ Aztec veri klasörü (~/.aztec) başarıyla silindi.${RESET}"
else
    echo -e "${SARI}⚠️  Aztec veri klasörü bulunamadı.${RESET}"
fi

# Kurulum scriptlerini temizle
echo -e "${BEYAZ}Kurulum betikleri temizleniyor...${RESET}"
if [ -f ./kriptokurdu_aztec_kurulum.sh ]; then
    rm -f ./kriptokurdu_aztec_kurulum.sh
    echo -e "${YESIL}✅ Kurulum betiği silindi.${RESET}"
fi

if [ -f ./kriptokurdu_aztec_guncelleme.sh ]; then
    rm -f ./kriptokurdu_aztec_guncelleme.sh
    echo -e "${YESIL}✅ Güncelleme betiği silindi.${RESET}"
fi

# Sistem temizliği
echo -e "${BEYAZ}Kullanılmayan paketler ve önbellek temizleniyor...${RESET}"
sudo apt autoremove -y &>/dev/null
sudo apt clean &>/dev/null
echo -e "${YESIL}✅ Sistem temizliği tamamlandı.${RESET}"

# Kaldırma işlemi tamamlandı
echo -e "\n${TURKUAZ}══════════ Kaldırma İşlemi Tamamlandı ══════════${RESET}"
echo -e "${YESIL}✅ Aztec node ve ilgili tüm bileşenler başarıyla kaldırıldı!${RESET}\n"

echo -e "${BEYAZ}Node'unuzu tekrar kurmak isterseniz, aşağıdaki komutu kullanabilirsiniz:${RESET}"
echo -e "${MAVI}curl -O https://raw.githubusercontent.com/KriptoKurdu/Aztec/main/kriptokurdu_aztec_kurulum.sh && chmod +x kriptokurdu_aztec_kurulum.sh && ./kriptokurdu_aztec_kurulum.sh${RESET}\n"

echo -e "${TURKUAZ}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${TURKUAZ}║       ${BEYAZ}KriptoKurdu Topluluğuna Katıldığınız İçin Teşekkürler!${TURKUAZ}    ║${RESET}"
echo -e "${TURKUAZ}╚═══════════════════════════════════════════════════════════╝${RESET}"

# Son olarak, bu kaldırma betiğini de sil
echo -e "${BEYAZ}Kaldırma betiği kendi kendini siliyor...${RESET}"
trap "rm -f $0" EXIT

exit 0
