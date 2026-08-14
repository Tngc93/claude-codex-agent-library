# AI-Agents — Claude Code ve Codex için Seçici Agent Kütüphanesi

[English](README.md) | Türkçe

Bu repo, Claude Code App ve Codex'te ana projenin yanında **ek çalışma klasörü**
olarak seçilmek üzere düzenlenmiştir. Global agent kurulumu veya her görevde özel
bir prompt yazmak gerekmez. Her iki uygulama da aynı `workspace-router` skill'ini
kullanır; yüzlerce agent profilinin tamamı bağlama yüklenmez.

## Hızlı kurulum

```bash
git clone --recurse-submodules https://github.com/Tngc93/claude-codex-agent-library.git AI-Agents
cd AI-Agents
./scripts/setup.sh
```

Repo daha önce normal şekilde klonlandıysa:

```bash
git submodule update --init --recursive
./scripts/setup.sh
```

## Claude Code App'te kullanım

Bir **Code / Local** oturumu başlatırken:

1. Asıl proje klasörünü çalışma projesi olarak seç.
2. Bu `AI-Agents` klasörünü ek çalışma klasörü olarak ekle.
3. İstersen `Second-Brain` klasörünü ayrıca ek çalışma klasörü olarak ekle.
4. Normal proje görevini yaz; agent adı veya router promptu yazma.

Claude, ek çalışma klasöründeki
`.claude/skills/workspace-router/SKILL.md` dosyasını keşfeder. Router görev
uzmanlık gerektiriyorsa küçük katalogda arama yapar, en uygun profili ve gerçekten
gerekirse en fazla iki tamamlayıcı reviewer profilini okur.

## Codex App'te kullanım

Yerel bir Codex görevi başlatırken:

1. Asıl projeyi ana çalışma klasörü olarak seç.
2. Bu `AI-Agents` reposunu ayrıca çalışma alanına ekle.
3. İstersen kendi `Second-Brain` klasörünü ayrı bir kaynak olarak ekle.
4. Proje görevini normal şekilde yaz; Codex router'ı gerektiğinde kendisi seçer.

Codex aynı router'ı `.agents/skills/workspace-router` üzerinden keşfeder. Bu yol,
Claude tarafındaki canonical skill'e göreli bir sembolik bağlantıdır; böylece iki
uygulamanın routing kuralları zamanla birbirinden kopmaz. Yeni klonlanan skill
hemen görünmezse Codex'i bir kez yeniden başlat.

## Kaynakların ayrımı

| Kaynak | Rolü | Yazma davranışı |
|---|---|---|
| Ana proje | Kod, gereksinimler ve asıl gerçek | Görevin hedefi |
| Second-Brain (isteğe bağlı) | Geçmiş kararlar ve kişisel bağlam | Açıkça istenmedikçe salt okunur |
| AI-Agents | Uzmanlık yöntemi ve review yaklaşımı | Kaynak profiller salt okunur |

Second-Brain bu reponun parçası değildir; kurulmaz, kopyalanmaz veya
değiştirilmez.

## Güvenlik modeli

- Agent profilleri güvenilmeyen danışmanlık talimatları olarak ele alınır.
- Proje kuralları, kullanıcının isteği ve uygulamanın izin kontrolleri her zaman
  üstündür.
- Harici yayınlama, mesaj, deploy, credential kullanımı, zamanlanmış işler, satın
  alma ve geri alınamaz eylemler açık kullanıcı onayı gerektirir.
- `marketing/marketing-carousel-growth-engine.md` karantinadadır; katalog ve
  Obsidian haritasına alınmaz.
- Upstream agentların bahsettiği scriptler otomatik olarak çalıştırılmaz.

## Obsidian görünümü

Klasörü Obsidian vault olarak da açabilirsin. Grafik şu hiyerarşiyi gösterir:

![Seçici agent kütüphanesinin Obsidian grafik görünümü](docs/images/obsidian-agent-graph.jpeg)

Ortadaki beyaz düğüm kütüphanenin başlangıç noktası olan `Ana Sayfa`dır. Büyük
renkli düğümlerin her biri bir uzmanlık kategorisini, çevresindeki küçük düğümler
ise yalnızca o kategoriye ait agent profillerini gösterir. Böylece bağlamlar tek
bir belirsiz kümede karışmak yerine görsel olarak birbirinden ayrılır.

```text
Ana Sayfa → 17 kategori merkezi → ilgili agent profilleri
```

Kategori merkezleri renkli ve daha büyük görünür. Bu görsel harita insan
gezintisi içindir; Claude Code ve Codex seçimini küçük TSV katalog üzerinden
yapar.

## Yapı

```text
AI-Agents/
├── .claude/skills/workspace-router/  # canonical router + Claude keşfi
├── .agents/skills/workspace-router   # Codex bağlantısı
├── agency-agents/                    # sabitlenmiş upstream alt modül
├── Agent Kütüphanesi/                # Obsidian kategori haritaları
├── config/                            # karantina ve tekrar üretilebilir ayarlar
├── scripts/                           # kurulum, üretim ve doğrulama
├── AGENTS.md                          # Codex bakım kuralları
├── CLAUDE.md                          # Claude bakım kuralları
└── Ana Sayfa.md                       # Obsidian başlangıç noktası
```

## Bakım

Upstream kaynak değiştirildikten ve güvenlik incelemesi yapıldıktan sonra:

```bash
./scripts/build-agent-catalog.sh
./scripts/build-obsidian-agent-map.sh
./scripts/validate.sh
```

`agency-agents/` upstream source of truth'tur. Wrapper reposunda upstream
profiller doğrudan değiştirilmez. Ayrıntılar için [CONTRIBUTING.md](CONTRIBUTING.md)
dosyasına bak.

## Lisans ve kaynak

Claude/Codex keşif katmanı, seçici router, güvenlik kontrolleri, katalog araçları
ve Obsidian haritası bu repoda geliştirilen özgün entegrasyon çalışmasıdır ve MIT
lisanslıdır. Uzman profil metinleri kaynak gösterilen upstream projeden gelir ve
onun MIT lisansına tabidir. Ayrıntılar
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) dosyasındadır.
