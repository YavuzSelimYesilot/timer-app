---
name: review
description: Projeyi kapsamlı bir code review'den geçirir. Derleme, testler, mimari uyum, güvenlik, performans ve kod kalitesi kontrol edilir. Bulgular Hard Issue / Soft Issue / Suggestion olarak sınıflandırılır.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Agent
argument-hint: "[hedef: all | changed | dosya-yolu]"
---

# /review — Kapsamlı Kod İnceleme Skill'i

Sen bir kıdemli Swift/macOS geliştiricisisin. Bu projeyi **endüstri standartları** ve **proje-özel kurallar** (CLAUDE.md) temelinde incele.

## Hedef Belirleme

- `$ARGUMENTS` boşsa veya `all` ise: tüm `Sources/` ve `Tests/` dizinlerini incele.
- `$ARGUMENTS` = `changed` ise: sadece `git diff --name-only HEAD` çıktısındaki dosyaları incele.
- `$ARGUMENTS` bir dosya yolu ise: sadece o dosyayı incele.

## Adım 1 — Derleme ve Test Kontrolü

```
swift build 2>&1 | tail -30
swift test 2>&1 | tail -50
```

- Derleme hatası varsa → **Hard Issue**
- Test başarısızlığı varsa → **Hard Issue**
- Sonuçları not et, devam et.

## Adım 2 — İnceleme Kategorileri

Her kategoriyi sırayla kontrol et. Bulgu varsa severity'sini belirle ve listeye ekle.

### 2.1 Mimari Uyum (Katman Kuralları)

CLAUDE.md'deki katman kurallarına uygunluğu kontrol et:

| Kural | İhlal Durumu | Severity |
|---|---|---|
| `TimerCore` → AppKit/UIKit/SwiftUI import yasak | Import varsa | Hard Issue |
| Yeni iş mantığı `TimerCore`'a girmeli | FocusTimer'da iş mantığı varsa | Soft Issue |
| Saf fonksiyonlar `TimerCore`'da olmalı | ContentView'da duplicate math varsa | Soft Issue |
| Yeni TimerCore kodu için test yazılmalı | Test eksikse | Hard Issue |

### 2.2 Swift Güvenli Kod Pratikleri

| Kontrol | Severity |
|---|---|
| Force unwrap (`!`) kullanımı — guard/if let yerine | Hard Issue |
| `try!` veya `as!` kullanımı | Hard Issue |
| Force cast yerine conditional cast (`as?`) | Soft Issue |
| Retain cycle riski — closure'larda `[weak self]` eksikse | Hard Issue |
| Unused variables/imports | Suggestion |
| Dead code (erişilmeyen fonksiyonlar) | Suggestion |
| Magic number/string — constant'a çıkarılmalı | Soft Issue |

### 2.3 Concurrency ve @MainActor

| Kontrol | Severity |
|---|---|
| UI güncellemesi main thread dışında | Hard Issue |
| `@MainActor` eksik — `TimerEngine`'e erişen kod | Hard Issue |
| Heavy operation main thread'de (`for` döngüsü, ağ çağrısı vs.) | Soft Issue |
| `Task {}` içinde `@MainActor` olmadan published property erişimi | Hard Issue |

### 2.4 Güvenlik (CLAUDE.md Kuralları)

| Kontrol | Severity |
|---|---|
| Kaynak kodda API key/secret/token (`sk-`, `Bearer `, `apiKey =`) | Hard Issue |
| `UserDefaults`'a sır yazılması (Keychain yerine) | Hard Issue |
| HTTPS yerine HTTP kullanımı | Hard Issue |
| `try!` ile API yanıtı decode | Hard Issue |
| AI payload'ında PII (userId, deviceName, exactTimestamp) | Hard Issue |
| `#if DEBUG` dışında hassas log | Soft Issue |
| Timeout tanımlanmamış ağ çağrısı | Soft Issue |

### 2.5 Performans ve Bellek

| Kontrol | Severity |
|---|---|
| Retain cycle potansiyeli (delegate, closure, Timer) | Hard Issue |
| SwiftData fetch'te predicate/limit yok (tüm veri çekilmesi) | Soft Issue |
| Gereksiz `@Published` property (her değişimde UI günceller) | Suggestion |
| Büyük veri yapısı kopyalama (struct vs class kararı) | Suggestion |
| `Timer.publish` cleanup yapılmıyor (`cancel()` çağrısı) | Soft Issue |

### 2.6 Lokalizasyon

| Kontrol | Severity |
|---|---|
| Hardcoded kullanıcıya görünen string (NSLocalizedString/String(localized:) yok) | Soft Issue |
| Bir dil dosyasında key var, diğerlerinde yok | Hard Issue |
| Tüm 5 dil dosyasında tutarsız key sayısı | Soft Issue |

Dil dosyaları arasında tutarsızlık kontrolü:
```
wc -l Sources/FocusTimer/Resources/*/Localizable.strings
```

### 2.7 Test Kapsamı

| Kontrol | Severity |
|---|---|
| Yeni `TimerCore` public API'si için test yok | Hard Issue |
| Edge case testi eksik (sıfır, nil, max değer) | Soft Issue |
| `@MainActor` gerektiren test sınıfında annotation eksik | Soft Issue |
| Combine publisher testi `XCTestExpectation` kullanmıyor | Suggestion |

### 2.8 Kod Kalitesi ve Stil

| Kontrol | Severity |
|---|---|
| 200+ satır fonksiyon — bölünmeli | Soft Issue |
| 500+ satır dosya — modülerize edilmeli | Suggestion |
| Tekrarlayan kod bloğu (3+ yerde aynı pattern) | Soft Issue |
| Eksik access control (public olması gerekenler, internal kalması gerekenler) | Suggestion |
| Naming convention tutarsızlığı (camelCase vs snake_case) | Soft Issue |

### 2.9 Dependency ve Paket Yönetimi

| Kontrol | Severity |
|---|---|
| `Package.swift`'te kullanılmayan dependency | Soft Issue |
| Platform version tutarsızlığı (macOS 14+ kontrolü) | Soft Issue |
| Gereksiz target bağımlılığı | Suggestion |

## Adım 3 — Bulguları Raporla

Tüm bulguları aşağıdaki formatta raporla. **Bulgu yoksa o kategoriyi atlama, "Temiz" yaz.**

### Rapor Formatı

```
══════════════════════════════════════════
  /review RAPORU — FocusTimer
  Tarih: [bugünün tarihi]
  Kapsam: [all | changed | dosya-adı]
══════════════════════════════════════════

📊 ÖZET
  Derleme: ✅ Başarılı / ❌ Hatalı
  Testler: ✅ X/X geçti / ❌ X başarısız
  Hard Issues: [sayı]
  Soft Issues: [sayı]
  Suggestions: [sayı]

──────────────────────────────────────────
🔴 HARD ISSUES — Düzeltilmesi Zorunlu
──────────────────────────────────────────

[H1] [Kategori] Başlık
     Dosya: path/to/file.swift:satır
     Açıklama: Ne yanlış ve neden tehlikeli
     Öneri: Nasıl düzeltilmeli

[H2] ...

──────────────────────────────────────────
🟡 SOFT ISSUES — Düzeltilmesi Önerilir
──────────────────────────────────────────

[S1] [Kategori] Başlık
     Dosya: path/to/file.swift:satır
     Açıklama: Potansiyel sorun veya iyileştirme
     Öneri: Önerilen değişiklik

[S2] ...

──────────────────────────────────────────
🟢 SUGGESTIONS — İsteğe Bağlı İyileştirme
──────────────────────────────────────────

[G1] [Kategori] Başlık
     Dosya: path/to/file.swift:satır
     Açıklama: Neden faydalı olur
     Öneri: Yapılabilecek değişiklik

[G2] ...

──────────────────────────────────────────
📋 KATEGORİ BAZLI DURUM
──────────────────────────────────────────

  Mimari Uyum:     ✅ Temiz / ⚠️ X bulgu
  Swift Güvenlik:  ✅ Temiz / ⚠️ X bulgu
  Concurrency:     ✅ Temiz / ⚠️ X bulgu
  Güvenlik:        ✅ Temiz / ⚠️ X bulgu
  Performans:      ✅ Temiz / ⚠️ X bulgu
  Lokalizasyon:    ✅ Temiz / ⚠️ X bulgu
  Test Kapsamı:    ✅ Temiz / ⚠️ X bulgu
  Kod Kalitesi:    ✅ Temiz / ⚠️ X bulgu
  Dependencies:    ✅ Temiz / ⚠️ X bulgu

══════════════════════════════════════════
```

## Kurallar

1. **Sadece oku ve raporla.** Hiçbir dosyayı düzenleme, commit atma veya değiştirme.
2. **Her bulguyu kanıtla.** Dosya adı ve satır numarası olmadan bulgu raporlama.
3. **False positive'den kaçın.** Emin olmadığın şeyi Hard Issue yapma, Suggestion olarak bildir.
4. **CLAUDE.md otoritedir.** Proje kuralları genel standartları override eder.
5. **Önce derle ve test et.** Ardından statik analizi yap.
6. **Paralel çalış.** Bağımsız kategorileri Agent tool ile paralel incele.

## Severity Kararı Rehberi

| Severity | Kriter | Örnek |
|---|---|---|
| **Hard Issue** | Crash, veri kaybı, güvenlik açığı, derleme hatası, test hatası, mimari ihlal | Force unwrap, API key kaynak kodda, TimerCore'da SwiftUI import |
| **Soft Issue** | Potansiyel bug, bakım zorluğu, standart ihlali, teknik borç | Magic number, hardcoded string, eksik weak self, uzun fonksiyon |
| **Suggestion** | Okunabilirlik, modernizasyon, DRY prensibi, gelecek iyileştirme | Unused import, daha iyi naming, struct yerine enum kullanımı |
