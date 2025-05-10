#!/bin/bash

# KriptoKurdu Aztec Sequencer Node Kurulum Script
# alpha-testnet

# Renk kodları
KIRMIZI='\033[0;31m'
YESIL='\033[0;32m'
SARI='\033[0;33m'
MAVI='\033[0;34m'
MOR='\033[0;35m'
TURKUAZ='\033[0;36m'
BEYAZ='\033[1;37m'
RESET='\033[0m'

# KriptoKurdu logosu göster
function logo() {
    clear
    echo -e "${MOR}"
    cat << "EOF"
  ██╗  ██╗██████╗ ██╗██████╗ ████████╗ ██████╗ ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗   ██╗
  ██║ ██╔╝██╔══██╗██║██╔══██╗╚══██╔══╝██╔═══██╗██║ ██╔╝██║   ██║██╔══██╗██╔══██╗██║   ██║
  █████╔╝ ██████╔╝██║██████╔╝   ██║   ██║   ██║█████╔╝ ██║   ██║██████╔╝██║  ██║██║   ██║
  ██╔═██╗ ██╔══██╗██║██╔═══╝    ██║   ██║   ██║██╔═██╗ ██║   ██║██╔══██╗██║  ██║██║   ██║
  ██║  ██╗██║  ██║██║██║        ██║   ╚██████╔╝██║  ██╗╚██████╔╝██║  ██║██████╔╝╚██████╔╝
  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝  ╚═════╝ 
EOF
    echo -e "${TURKUAZ}"
    echo "                     AZTEC SEQUENCER NODE KURULUM ARACI"
    echo -e "${BEYAZ}"
    echo "                              alpha-testnet"
    echo -e "${RESET}"
    echo ""
}

# Sistemi hazırla
function prepare_system() {
    echo -e "${TURKUAZ}Sistem hazırlanıyor...${RESET}"
    
    # Gerekli paketleri yükle
    apt-get update
    apt-get install -y curl git jq bc

    echo -e "${YESIL}✓ Gerekli paketler kuruldu${RESET}"
}

# Docker kurulumu
function install_docker() {
    echo -e "${TURKUAZ}Docker kontrol ediliyor...${RESET}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${TURKUAZ}Docker kuruluyor...${RESET}"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        
        # Docker kullanıcı grubuna kullanıcıyı ekle
        usermod -aG docker $USER
        
        echo -e "${YESIL}✓ Docker kuruldu${RESET}"
    else
        echo -e "${YESIL}✓ Docker zaten kurulu${RESET}"
    fi
}

# Node.js ve Yarn kurulumu 
function install_nodejs() {
    echo -e "${TURKUAZ}Node.js kontrol ediliyor...${RESET}"
    
    if ! command -v node &> /dev/null; then
        echo -e "${TURKUAZ}Node.js kuruluyor...${RESET}"
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
        
        echo -e "${YESIL}✓ Node.js kuruldu${RESET}"
    else
        echo -e "${YESIL}✓ Node.js zaten kurulu${RESET}"
    fi
    
    # Yarn kurulumu
    if ! command -v yarn &> /dev/null; then
        echo -e "${TURKUAZ}Yarn kuruluyor...${RESET}"
        npm install -g yarn
        echo -e "${YESIL}✓ Yarn kuruldu${RESET}"
    else
        echo -e "${YESIL}✓ Yarn zaten kurulu${RESET}"
    fi
}

# Aztec araçlarını kur
function install_aztec() {
    echo -e "${TURKUAZ}Aztec araçları kuruluyor...${RESET}"
    
    # Gerekli dizinleri oluştur
    mkdir -p $HOME/.aztec
    
    # Aztec'in kurulum sonrası PATH'e eklenmesi için .bashrc'ye ekleyelim
    echo 'export PATH=$PATH:$HOME/.yarn/bin' >> $HOME/.bashrc
    export PATH=$PATH:$HOME/.yarn/bin
    
    # Aztec installer'ı indir ve çalıştır
    echo -e "${TURKUAZ}Aztec installer indiriliyor...${RESET}"
    bash -i <(curl -s https://install.aztec.network)
    
    # Aztec komutunu bul (önceki kurulumdan)
    AZTEC_PATHS=(
        "$HOME/.yarn/bin/aztec"
        "/usr/local/bin/aztec"
        "$HOME/.local/bin/aztec"
        "$(which aztec 2>/dev/null || echo "")"
    )
    
    # Kullanılabilir aztec komutunu bul
    AZTEC_PATH=""
    for path in "${AZTEC_PATHS[@]}"; do
        if [[ -x "$path" ]]; then
            AZTEC_PATH="$path"
            break
        fi
    done
    
    # Eğer komut hala bulunamadıysa, tüm sistem genelinde ara
    if [[ -z "$AZTEC_PATH" ]]; then
        echo -e "${TURKUAZ}Aztec komutu aranıyor...${RESET}"
        AZTEC_PATH=$(find / -type f -name "aztec" -executable 2>/dev/null | head -n 1)
    fi
    
    # Komut bulunamadıysa
    if [[ -z "$AZTEC_PATH" ]]; then
        echo -e "${SARI}⚠️ Aztec komutu bulunamadı. Manual kurulum deneniyor...${RESET}"
        
        # Yarn global ile kurmayı dene
        yarn global add @aztec/cli
        
        # Tekrar kontrol et
        AZTEC_PATH=$(find / -type f -name "aztec" -executable 2>/dev/null | head -n 1)
        
        if [[ -z "$AZTEC_PATH" ]]; then
            echo -e "${KIRMIZI}✗ Aztec komutu kurulamadı ve bulunamadı.${RESET}"
            exit 1
        fi
    fi
    
    echo -e "${YESIL}✓ Aztec komutu bulundu: $AZTEC_PATH${RESET}"
    
    # Aztec'in konumunu yapılandırma dosyasına kaydet
    echo "AZTEC_PATH=\"$AZTEC_PATH\"" > $HOME/.aztec/aztec_path
    
    # Alpha-testnet sürümünü yükle
    echo -e "${TURKUAZ}Alpha-testnet sürümünü yükleniyor...${RESET}"
    "$AZTEC_PATH-up" alpha-testnet || "$HOME/.yarn/bin/aztec-up" alpha-testnet
    
    echo -e "${YESIL}✓ Aztec araçları kuruldu${RESET}"
}

# Yapılandırma değişkenlerini topla
function collect_config() {
    echo -e "${TURKUAZ}Node yapılandırma bilgileri toplanıyor...${RESET}"
    
    # Yapılandırma dizini
    mkdir -p $HOME/.aztec
    CONFIG_FILE="$HOME/.aztec/node_config.env"
    
    # Aztec komut dosyasının konumunu al
    AZTEC_PATH=$(cat $HOME/.aztec/aztec_path | grep AZTEC_PATH | cut -d'"' -f2)
    
    # Ethereum RPC URL
    echo -e "${BEYAZ}Ethereum RPC URL'lerini girin (virgülle ayrılmış):${RESET}"
    echo -e "${SARI}Örnek: https://eth-sepolia.g.alchemy.com/v2/your-api-key${RESET}"
    read -p "> " ETHEREUM_HOSTS
    
    # L1 Consensus URL
    echo -e "${BEYAZ}L1 Consensus Host URL'lerini girin (virgülle ayrılmış):${RESET}"
    echo -e "${SARI}Örnek: https://eth-sepolia-beacon.g.alchemy.com/v2/your-api-key${RESET}"
    read -p "> " L1_CONSENSUS_HOST_URLS
    
    # Validator Özel Anahtarı
    echo -e "${BEYAZ}Validator özel anahtarını girin (0x ile başlamalı):${RESET}"
    echo -e "${SARI}Bu, Sepolia ETH bulunan bir hesabın özel anahtarı olmalıdır${RESET}"
    read -p "> " VALIDATOR_PRIVATE_KEY
    
    # Coinbase Adresi
    echo -e "${BEYAZ}Blok ödülleri için Coinbase adresini girin (0x ile başlamalı):${RESET}"
    read -p "> " COINBASE
    
    # P2P IP'sini otomatik al
    P2P_IP=$(curl -s api.ipify.org)
    echo -e "${BEYAZ}Tespit edilen IP: ${P2P_IP}${RESET}"
    echo -e "${BEYAZ}Bu IP adresini kullanmak istiyor musunuz? (E/h)${RESET}"
    read -p "> " USE_DETECTED_IP
    if [[ "$USE_DETECTED_IP" =~ ^[Hh]$ ]]; then
        echo -e "${BEYAZ}P2P IP adresinizi girin:${RESET}"
        read -p "> " P2P_IP
    fi
    
    # Yapılandırma dosyasını oluştur
    cat > $CONFIG_FILE << EOL
# KriptoKurdu Aztec Node Yapılandırması
# Oluşturulma: $(date)

# Aztec komutunun tam yolu
AZTEC_PATH="$AZTEC_PATH"

# Ethereum RPC URL'leri
ETHEREUM_HOSTS="$ETHEREUM_HOSTS"

# L1 Consensus Host URL'leri
L1_CONSENSUS_HOST_URLS="$L1_CONSENSUS_HOST_URLS"

# Validator Özel Anahtarı
VALIDATOR_PRIVATE_KEY="$VALIDATOR_PRIVATE_KEY"

# Blok ödülleri için adres
COINBASE="$COINBASE"

# P2P IP adresi
P2P_IP="$P2P_IP"

# P2P port (varsayılan)
P2P_PORT="40400"
EOL

    echo -e "${YESIL}✓ Yapılandırma dosyası oluşturuldu: $CONFIG_FILE${RESET}"
}

# Çalıştırma betiği oluştur
function create_startup_scripts() {
    echo -e "${TURKUAZ}Başlatma betikleri oluşturuluyor...${RESET}"
    
    # Yapılandırma dosyasını yükle
    CONFIG_FILE="$HOME/.aztec/node_config.env"
    source $CONFIG_FILE
    
    # Node başlatma betiği
    START_SCRIPT="$HOME/.aztec/start-node.sh"
    cat > $START_SCRIPT << EOL
#!/bin/bash

# Yapılandırma dosyasını yükle
source $HOME/.aztec/node_config.env

echo "Aztec komutu kullanılıyor: \$AZTEC_PATH"

# Komutun mevcut olup olmadığını kontrol et
if [ ! -f "\$AZTEC_PATH" ] || [ ! -x "\$AZTEC_PATH" ]; then
    echo "Hata: Aztec komutu bulunamadı veya çalıştırılamıyor: \$AZTEC_PATH"
    echo "Alternatif komutlar aranıyor..."
    
    # Alternatif yolları kontrol et
    for alt_path in "$HOME/.yarn/bin/aztec" "/usr/local/bin/aztec" "$HOME/.local/bin/aztec" "\$(which aztec 2>/dev/null)"; do
        if [ -f "\$alt_path" ] && [ -x "\$alt_path" ]; then
            echo "Alternatif Aztec komutu bulundu: \$alt_path"
            AZTEC_PATH="\$alt_path"
            break
        fi
    done
    
    # Hala bulunamadıysa, hata ver ve çık
    if [ ! -f "\$AZTEC_PATH" ] || [ ! -x "\$AZTEC_PATH" ]; then
        echo "Kritik hata: Hiçbir çalıştırılabilir Aztec komutu bulunamadı."
        exit 1
    fi
fi

# Node'u başlat
"\$AZTEC_PATH" start --node --archiver --sequencer \\
  --network alpha-testnet \\
  --l1-rpc-urls \$ETHEREUM_HOSTS \\
  --l1-consensus-host-urls \$L1_CONSENSUS_HOST_URLS \\
  --sequencer.validatorPrivateKey \$VALIDATOR_PRIVATE_KEY \\
  --sequencer.coinbase \$COINBASE \\
  --p2p.p2pIp \$P2P_IP \\
  --p2p.p2pPort \$P2P_PORT \\
  --p2p.maxTxPoolSize 1000000000
EOL
    chmod +x $START_SCRIPT
    
    # Validator kayıt betiği
    VALIDATOR_SCRIPT="$HOME/.aztec/register-validator.sh"
    cat > $VALIDATOR_SCRIPT << EOL
#!/bin/bash

# Yapılandırma dosyasını yükle
source $HOME/.aztec/node_config.env

echo "Aztec komutu kullanılıyor: \$AZTEC_PATH"

# Komutun mevcut olup olmadığını kontrol et
if [ ! -f "\$AZTEC_PATH" ] || [ ! -x "\$AZTEC_PATH" ]; then
    echo "Hata: Aztec komutu bulunamadı veya çalıştırılamıyor: \$AZTEC_PATH"
    echo "Alternatif komutlar aranıyor..."
    
    # Alternatif yolları kontrol et
    for alt_path in "$HOME/.yarn/bin/aztec" "/usr/local/bin/aztec" "$HOME/.local/bin/aztec" "\$(which aztec 2>/dev/null)"; do
        if [ -f "\$alt_path" ] && [ -x "\$alt_path" ]; then
            echo "Alternatif Aztec komutu bulundu: \$alt_path"
            AZTEC_PATH="\$alt_path"
            break
        fi
    done
    
    # Hala bulunamadıysa, hata ver ve çık
    if [ ! -f "\$AZTEC_PATH" ] || [ ! -x "\$AZTEC_PATH" ]; then
        echo "Kritik hata: Hiçbir çalıştırılabilir Aztec komutu bulunamadı."
        exit 1
    fi
fi

# Validator özel anahtarından Ethereum adresini türet
NODE_ADDRESS=\$("\$AZTEC_PATH" address-from-private-key --private-key "\$VALIDATOR_PRIVATE_KEY")

echo "Validator olarak kaydediliyor..."
echo "Node adresi: \$NODE_ADDRESS"

# Validator olarak kaydet
"\$AZTEC_PATH" add-l1-validator \\
  --l1-rpc-urls "\$ETHEREUM_HOSTS" \\
  --private-key "\$VALIDATOR_PRIVATE_KEY" \\
  --attester "\$NODE_ADDRESS" \\
  --proposer-eoa "\$NODE_ADDRESS" \\
  --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \\
  --l1-chain-id 11155111

# Sonucu kontrol et
if [ \$? -eq 0 ]; then
    echo "✅ Validator kaydı başarılı!"
else
    echo "❌ Validator kaydı başarısız. Eğer 'ValidatorQuotaFilledUntil' hatası aldıysanız, bu kota dolduğu anlamına gelir."
    echo "   Belirtilen zaman damgasından sonra tekrar deneyebilirsiniz."
fi
EOL
    chmod +x $VALIDATOR_SCRIPT
    
    # Systemd servis dosyası oluştur
    SYSTEMD_SERVICE="/etc/systemd/system/aztec-node.service"
    cat > $SYSTEMD_SERVICE << EOL
[Unit]
Description=Aztec Sequencer Node
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/root
ExecStart=/bin/bash $START_SCRIPT
Environment="PATH=/usr/local/bin:/usr/bin:/bin:/sbin:/usr/sbin:/root/.yarn/bin:/root/.local/bin"
Restart=always
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOL

    # Systemd servisini etkinleştir
    systemctl daemon-reload
    systemctl enable aztec-node
    
    echo -e "${YESIL}✓ Başlatma betikleri oluşturuldu${RESET}"
    echo -e "${YESIL}✓ Aztec node servisi oluşturuldu ve etkinleştirildi${RESET}"
}

# Komutla node başlatma fonksiyonu
function start_aztec_node() {
    echo -e "${TURKUAZ}Aztec node başlatılıyor...${RESET}"
    
    # Servisi başlat
    systemctl start aztec-node
    sleep 2
    
    # Durumu kontrol et
    NODE_STATUS=$(systemctl is-active aztec-node)
    
    if [ "$NODE_STATUS" = "active" ]; then
        echo -e "${YESIL}✓ Aztec node başarıyla başlatıldı${RESET}"
    else
        echo -e "${SARI}⚠️ Aztec node başlatılamadı, servis durumu: $NODE_STATUS${RESET}"
        echo -e "${TURKUAZ}Loglara bakılıyor...${RESET}"
        
        # Logları göster
        journalctl -u aztec-node -n 20 --no-pager
        
        echo -e "${KIRMIZI}Node başlatılamadı. Lütfen manuel olarak kontrol edin: ${RESET}"
        echo -e "${SARI}   sudo journalctl -u aztec-node -f${RESET}"
    fi
}

# Manuel node başlatma komutu oluşturma
function create_manual_start() {
    echo -e "${TURKUAZ}Manuel başlatma komutu oluşturuluyor...${RESET}"
    
    # Yapılandırma dosyasını yükle
    CONFIG_FILE="$HOME/.aztec/node_config.env"
    source $CONFIG_FILE
    
    # Manuel başlatma betiği
    MANUAL_SCRIPT="$HOME/.aztec/manual-start.sh"
    cat > $MANUAL_SCRIPT << EOL
#!/bin/bash

# KriptoKurdu Aztec Node - Manuel Başlatma Betiği
# Bu betik, sistemd servisi başarısız olursa kullanılabilir

# PATH'i ayarla
export PATH=\$PATH:/usr/local/bin:/usr/bin:/bin:/sbin:/usr/sbin:/root/.yarn/bin:/root/.local/bin

# Yapılandırma dosyasını yükle
source $HOME/.aztec/node_config.env

echo "Aztec komutu için olası konumlar taranıyor..."

# Tüm olası Aztec konumlarını tara
POSSIBLE_PATHS=(
    "/root/.yarn/bin/aztec"
    "/usr/local/bin/aztec"
    "\$HOME/.local/bin/aztec"
    "\$(which aztec 2>/dev/null)"
    "\$(find / -type f -name aztec -executable 2>/dev/null | head -n 1)"
)

# Her bir olası konumu test et
for cmd in "\${POSSIBLE_PATHS[@]}"; do
    if [ -f "\$cmd" ] && [ -x "\$cmd" ]; then
        echo "Çalıştırılabilir Aztec komutu bulundu: \$cmd"
        
        echo "Node başlatılıyor: \$cmd start --node --archiver --sequencer ..."
        
        # Node'u başlat
        "\$cmd" start --node --archiver --sequencer \\
          --network alpha-testnet \\
          --l1-rpc-urls "\$ETHEREUM_HOSTS" \\
          --l1-consensus-host-urls "\$L1_CONSENSUS_HOST_URLS" \\
          --sequencer.validatorPrivateKey "\$VALIDATOR_PRIVATE_KEY" \\
          --sequencer.coinbase "\$COINBASE" \\
          --p2p.p2pIp "\$P2P_IP" \\
          --p2p.p2pPort "\$P2P_PORT" \\
          --p2p.maxTxPoolSize 1000000000
          
        # Başarılıysa döngüden çık
        if [ \$? -eq 0 ]; then
            exit 0
        fi
    fi
done

echo "Hiçbir Aztec komutu çalıştırılamadı."
EOL
    chmod +x $MANUAL_SCRIPT
    
    echo -e "${YESIL}✓ Manuel başlatma betiği oluşturuldu: $MANUAL_SCRIPT${RESET}"
}

# Port yönlendirme uyarısı
function port_forwarding_warning() {
    CONFIG_FILE="$HOME/.aztec/node_config.env"
    source $CONFIG_FILE
    
    echo -e "${KIRMIZI}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    ⚠️ ÖNEMLİ UYARI ⚠️                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${BEYAZ}"
    echo "Router'ınızda PORT YÖNLENDİRME yapmanız GEREKLİDİR:"
    echo ""
    echo "• TCP ve UDP trafiğini port 40400 üzerinden"
    echo "  $P2P_IP IP adresine yönlendirmelisiniz."
    echo ""
    echo "Bunu yapmazsanız, node'unuz P2P ağına katılamayabilir!"
    echo -e "${RESET}"
}

# Başarılı kurulum mesajı
function success_message() {
    echo -e "${YESIL}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    ✅ KURULUM TAMAMLANDI                       ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${BEYAZ}"
    echo "Betikler şu konumda oluşturuldu:"
    echo "• Node başlatma: $HOME/.aztec/start-node.sh"
    echo "• Validator kayıt: $HOME/.aztec/register-validator.sh"
    echo "• Manuel başlatma: $HOME/.aztec/manual-start.sh (sorun durumunda)"
    echo ""
    echo "Node şu anda çalışıyor olmalı. Kontrol etmek için:"
    echo "   sudo systemctl status aztec-node"
    echo ""
    echo "Eğer node çalışmıyorsa, manuel başlatmayı deneyebilirsiniz:"
    echo "   $HOME/.aztec/manual-start.sh"
    echo ""
    echo "Validator olarak kaydolmak için önce node'unuzun tam olarak"
    echo "senkronize olmasını bekleyin, ardından şu komutu çalıştırın:"
    echo "   $HOME/.aztec/register-validator.sh"
    echo ""
    echo "Logları görmek için:"
    echo "   sudo journalctl -u aztec-node -f"
    echo ""
    echo "KriptoKurdu Discord: https://discord.gg/kriptokurdu"
    echo -e "${RESET}"
}

# Ana fonksiyon
function main() {
    logo
    prepare_system
    install_docker
    install_nodejs
    install_aztec
    collect_config
    create_startup_scripts
    create_manual_start
    start_aztec_node
    port_forwarding_warning
    success_message
}

# Scripti çalıştır
main
