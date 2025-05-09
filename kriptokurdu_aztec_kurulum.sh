#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.aztec/bin"
set -e
clear

# Banner
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
           K R İ P T O   K U R D U   N O D E
                  Aztec Node Kurulum
🐺 Twitter:  https://x.com/kriptokurduu
🌐 Telegram: https://t.me/kriptokurdugrup
╚═══════════════════════════════════════════════════════════╝
EOF

sleep 2

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
  echo "❌ Lütfen script'i root olarak çalıştırın (sudo)."
  exit 1
fi

# Ana dizine geç
echo "📂 Ana dizine geçiliyor..."
cd ~

# Geçici dizin
echo "📁 Geçici dizin hazırlanıyor..."
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

# Sistem güncelleme & temel paketler
echo "🔧 Sistem güncelleniyor ve temel paketler yükleniyor..."
apt-get update -y
apt-get install -y curl jq sed gnupg2 lsb-release ca-certificates \
                   tmux htop ufw nginx dnsutils

# Docker CE kurulumu
echo "🐳 Eski Docker paketleri temizleniyor..."
apt-get remove -y docker docker-engine docker.io containerd runc || true
rm -rf /var/lib/docker /var/lib/containerd

echo "🐳 Docker CE reposu ekleniyor..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
   https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
echo "🐳 Docker CE kuruluyor..."
apt-get install -y docker-ce docker-ce-cli containerd.io

echo "✅ Docker servisi başlatılıyor..."
systemctl enable docker
systemctl start docker
sleep 2
if ! systemctl is-active --quiet docker; then
  echo "❌ Docker servisi başlatılamadı. 'systemctl status docker' ile kontrol edin."
  exit 1
fi
echo "✅ Docker servisi çalışıyor."

# DNS & hosts
echo "🌐 DNS ve hosts dosyaları güncelleniyor..."
cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
cat >> /etc/hosts <<EOF
104.21.31.61 static.aztec.network
172.67.211.145 bootnode-alpha-1.aztec.network
EOF

# Nginx ile statik bootnode
echo "🌍 Nginx ile statik bootnode sunucusu kuruluyor..."
mkdir -p /var/www/html/alpha-testnet
cat > /var/www/html/alpha-testnet/bootnodes.json <<EOF
[ "/dns/bootnode-alpha-1.aztec.network/tcp/40400" ]
EOF
systemctl enable nginx
systemctl restart nginx

# UFW
echo "🧱 Güvenlik duvarı kuralları ekleniyor..."
ufw allow ssh
ufw allow 40400/tcp
ufw allow 40400/udp
ufw --force enable

# Aztec CLI kurulumu
echo "🚀 Aztec CLI kuruluyor..."
bash <(curl -s https://install.aztec.network)
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Shebang düzeltmesi
for f in ~/.aztec/bin/aztec* ~/.aztec/bin/.aztec-run; do
  sed -i '1s|.*|#!/bin/bash|' "$f"
  chmod +x "$f"
done

# CLI güncelleme
aztec version >/dev/null 2>&1 || true
aztec-up alpha-testnet

# Kullanıcı girdileri
read -p "🔐 EVM cüzdan adresinizi girin: " COINBASE
read -p "🌍 Sepolia RPC URL (ETHEREUM_HOSTS): " RPC_URL

# IP tespiti
PUBLIC_IP=$(curl -s https://api.ipify.org)
echo "🌐 Algılanan IP: $PUBLIC_IP"
read -p "Bu IP'yi kullanmak ister misiniz? (e/h): " yn
if [ "$yn" != "e" ]; then
  read -p "📡 IP adresinizi girin: " PUBLIC_IP
fi

# Beacon RPC testi
echo "🛰️ Beacon consensus RPC test ediliyor..."
for url in "https://rpc.drpc.org/eth/sepolia/beacon" "https://lodestar-sepolia.chainsafe.io"; do
  echo -n "  Testing $url... "
  if curl -sf --connect-timeout 5 "$url" -o /dev/null; then
    CONSENSUS_URL="$url"
    echo "OK"
    break
  else
    echo "FAIL"
  fi
done
if [ -z "$CONSENSUS_URL" ]; then
  read -p "🛰️ Çalışan Beacon RPC URL'sini girin: " CONSENSUS_URL
fi

read -p "🔑 Validator private key: " PRIVATE_KEY

# bootnodes JSON ekleme
DATA_DIR="/root/aztec-data"
mkdir -p "$DATA_DIR/config"
curl -s https://static.aztec.network/config/alpha-testnet.json | \
  jq '.p2pBootstrapNodes = ["/dns/bootnode-alpha-1.aztec.network/tcp/40400"]' \
  > "$DATA_DIR/config/alpha-testnet.json"

# Node başlatma
echo "🚦 Aztec node başlatılıyor..."
aztec start \
  --network alpha-testnet \
  --l1-rpc-urls "$RPC_URL" \
  --l1-consensus-host-urls "$CONSENSUS_URL" \
  --sequencer.validatorPrivateKey "$PRIVATE_KEY" \
  --p2p.p2pIp "$PUBLIC_IP" \
  --p2p.maxTxPoolSize 1000000000 \
  --archiver \
  --node \
  --sequencer

# Log takibi için ipuçları
cat <<EOF
✅ Node start komutu gönderildi.
Logları izlemek için:
  aztec logs --follow
veya
  docker logs -f aztec-node
EOF

# Temizlik
cd ~
rm -rf "$TMPDIR"
