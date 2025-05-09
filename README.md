<p align="center">
<strong># KriptoKurdu Aztec Sequencer Node Kurulum Rehberi</strong>
</p>

<p align="center">
  <a href="https://ibb.co/TqwZkSB8"><img src="https://i.ibb.co/x82yD0Sj/Ads-z-tasar-m-19.png" alt="Ads-z-tasar-m-19" border="0"></a>
</p>

---

## 📚 İçindekiler

- [Giriş](#-giriş)
- [Gereksinimler](#-gereksinimler)
- [Kurulum Adımları](#-kurulum-adımları)
- [Node Doğrulama](#-node-doğrulama)
- [Validator Olarak Kayıt](#-validator-olarak-kayıt)
- [Güncelleme Talimatları](#-güncelleme-talimatları)
- [Sık Sorulan Sorular](#-sık-sorulan-sorular)
- [İletişim](#-iletişim)

---

## 🔍 Giriş

Aztec, Ethereum üzerinde çalışan gizlilik odaklı bir L2 (Layer 2) çözümüdür. Bu rehber, Aztec ağının altyapısına katkıda bulunmak isteyen kullanıcılar için sequencer node kurulumunu adım adım anlatmaktadır.

KriptoKurdu ekibi olarak, topluluk üyelerimizin bu teknolojik gelişimlere kolay bir şekilde katılabilmesi için bu rehberi hazırladık. Bu rehberde sunduğumuz kurulum betikleri, süreci otomatikleştirerek herkesin kolayca node çalıştırabilmesini sağlar.

## 🛠 Gereksinimler

### Donanım Gereksinimleri
- **İşlemci:** 8 çekirdek (minimum)
- **RAM:** 8GB (minimum), 16GB (önerilen)
- **Depolama:** 100GB SSD (minimum)
- **İnternet:** Stabil bir internet bağlantısı

### Yazılım Gereksinimleri
- **İşletim Sistemi:** Ubuntu 20.04 LTS veya üzeri
- **Docker:** En son sürüm
- **Node.js:** 18.x sürümü
- **Git:** En son sürüm

### Diğer Gereksinimler
- **ETH Cüzdanı:** Metamask veya başka bir Ethereum cüzdanı
- **Sepolia Test ETH:** Node doğrulama için test ETH'ye ihtiyacınız olacak

## 🔧 Kurulum Adımları

### 1. VPS Kiralama (Opsiyonel)
Eğer kendi sunucunuz yoksa, aşağıdaki VPS sağlayıcılardan birini tercih edebilirsiniz:
- [Contabo](https://contabo.com/en/vps/) - 4.5€/ay'dan başlayan fiyatlarla
- [Hetzner](https://www.hetzner.com/cloud) - Avrupa ve ABD lokasyonları
- [Digital Ocean](https://www.digitalocean.com/) - 8GB RAM Droplet önerilir

### 2. Cüzdan Hazırlığı
- Ethereum ağında yeni bir cüzdan oluşturun veya mevcut bir cüzdanı kullanın
- Sepolia test ağı için ETH alın:
  - [Sepolia Faucet](https://sepoliafaucet.com/)
  - [Infura Faucet](https://www.infura.io/faucet/sepolia)
- Özel anahtarınızı ve adresinizi güvenli bir yerde saklayın

### 3. Sunucu Erişimi Sağlama
SSH ile sunucunuza bağlanın:
```
ssh kullanici@sunucu_ip
```

### 4. Screen Oluşturma
Kurulum işleminin arka planda devam etmesi için bir screen oturumu oluşturun:
```
screen -S aztec
```

### 5. Otomatik Kurulum Betiğini Çalıştırma
KriptoKurdu özel kurulum betiğini indirin ve çalıştırın:
```
curl -O https://raw.githubusercontent.com/KriptoKurdu/Aztec/main/kriptokurdu_aztec_kurulum.sh && chmod +x kriptokurdu_aztec_kurulum.sh && ./kriptokurdu_aztec_kurulum.sh
```

Kurulum betiği otomatik olarak:
- Sistem gereksinimlerini kontrol eder
- Gerekli yazılımları yükler
- Docker ve Node.js kurulumunu yapar
- Aztec CLI'yı yükler
- Aztec node'u yapılandırır ve başlatır

### 6. Kurulum Tamamlandığında
- Screen oturumundan çıkmak için `CTRL+A` ardından `D` tuşlarına basın
- Daha sonra screen oturumuna geri dönmek için:
```
screen -r aztec
```

## 🔄 Node Doğrulama

Node'unuzun düzgün çalıştığından emin olmak için şu adımları takip edin:

### 1. Logları Kontrol Etme
```
sudo docker logs -f $(sudo docker ps -q --filter ancestor=aztecprotocol/aztec:latest | head -n 1)
```

### 2. İspatlanmış Son Blok Numarasını Alma
```
curl -s -X POST -H 'Content-Type: application/json' \
-d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' \
http://localhost:8080 | jq -r ".result.proven.number"
```

Bu komut bir blok numarası döndürmelidir (örneğin: `20791`). Bu numarayı not edin, bir sonraki adımda kullanacaksınız.

### 3. Senkronizasyon Kanıtı Oluşturma
Aşağıdaki komutta `BLOK_NUMARASI` bölümünü bir önceki adımda aldığınız blok numarası ile değiştirin:

```
curl -s -X POST -H 'Content-Type: application/json' \
-d '{"jsonrpc":"2.0","method":"node_getArchiveSiblingPath","params":["BLOK_NUMARASI","BLOK_NUMARASI"],"id":67}' \
http://localhost:8080 | jq -r ".result"
```

Komut bir dizi veri döndürecektir, bu verileri Discord sunucusunda görevinizi almak için kullanabilirsiniz.

## 🔐 Validator Olarak Kayıt

Node'unuzu validator olarak kaydetmek için aşağıdaki adımları takip edin:

### 1. Cüzdan Bilgilerinizi Hazırlayın
- `SEPOLIA-RPC-URL`: Sepolia ağı için bir RPC URL (Infura, Alchemy gibi sağlayıcılardan alabilirsiniz)
- `CÜZDAN-ÖZEL-ANAHTARINIZ`: Cüzdanınızın özel anahtarı (0x ile başlar)
- `CÜZDAN-ADRESİNİZ`: Cüzdanınızın adresi (0x ile başlar)

### 2. Validator Kayıt Komutunu Çalıştırın
```
aztec add-l1-validator \
  --l1-rpc-urls SEPOLIA-RPC-URL \
  --private-key CÜZDAN-ÖZEL-ANAHTARINIZ \
  --attester CÜZDAN-ADRESİNİZ \
  --proposer-eoa CÜZDAN-ADRESİNİZ \
  --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
  --l1-chain-id 11155111
```

### 3. Doğrulama Durumunuzu Kontrol Edin
Discord sunucusuna bağlanın ve `/operator start` komutunu girin. Discord botu size validator rolü verecek ve yönergeler sunacaktır.

**Not:** Eğer "ValidatorQuotaFilledUntil" hatası alırsanız, bu günlük validator kotasının dolduğu anlamına gelir. UTC 01:00'den sonra tekrar deneyin.

## 🔄 Güncelleme Talimatları

Aztec protokolü güncellendiğinde node'unuzu güncellemek için aşağıdaki adımları takip edin:

### 1. Güncelleme Betiğini İndirin ve Çalıştırın
```
curl -O https://raw.githubusercontent.com/KriptoKurdu/Aztec/main/kriptokurdu_aztec_guncelleme.sh && chmod +x kriptokurdu_aztec_guncelleme.sh && ./kriptokurdu_aztec_guncelleme.sh
```

Güncelleme betiği:
- Mevcut node'u durduracak
- Yazılımı güncelleyecek
- Eski verileri temizleyecek
- Node'u yeniden başlatacak

### 2. Güncelleme Sonrası Doğrulama
Güncelleme tamamlandıktan sonra, node'un düzgün çalıştığından emin olmak için logları kontrol edin:
```
sudo docker logs -f $(sudo docker ps -q --filter ancestor=aztecprotocol/aztec:latest | head -n 1)
```

## ❓ Sık Sorulan Sorular

### Node için ne kadar ödül alacağım?
Aztec, validator node operatörlerine ağın mainnet lansmanı sonrasında teşvikler sunmayı planlıyor. Ayrıntılar için resmi duyuruları takip edin.

### Node'um çalışmayı durdurdu, ne yapmalıyım?
İlk olarak logları kontrol edin. Sorun devam ederse, node'u güncelleme betiğimizi kullanarak güncelleyin.

### Doğrulama için neden Sepolia ağını kullanıyoruz?
Sepolia, Aztec'in test ağı entegrasyonu için seçtiği Ethereum test ağıdır. Mainnet lansmanı öncesinde testler bu ağda yapılacaktır.

### Özel anahtar paylaşmak güvenli mi?
Özel anahtarınızı sadece kendi VPS'inizde kullanın ve asla başkalarıyla paylaşmayın. Güvenlik için test amaçlı yeni bir cüzdan oluşturmanızı öneririz.

### Node'um senkronize olmuyorsa ne yapmalıyım?
Senkronizasyon sorunları genellikle ağ bağlantısı veya donanım kısıtlamaları nedeniyle oluşur. Sunucunuzun gereksinimleri karşıladığından emin olun ve internet bağlantınızı kontrol edin.

## 📱 İletişim

KriptoKurdu ekibi olarak sorularınızı yanıtlamaktan ve size yardımcı olmaktan memnuniyet duyarız:

- **Telegram:** [KriptoKurdu Telegram](https://t.me/kriptokurdugrup)
- **Twitter:** [@KriptoKurdu](https://twitter.com/KriptoKurduu)

---

<p align="center">
  <strong>KriptoKurdu tarafından ❤️ ile hazırlanmıştır.</strong>
</p>
