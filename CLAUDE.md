# CLAUDE.md — FocusTimer Project Guide

> Bu dosya her AI asistanın (Claude, GPT, Gemini, vb.) projeye başlamadan önce okuması gereken
> tek kaynak belgedir. Projenin mimarisi, geliştirme kuralları ve test beklentileri burada açıklanır.

---

## Proje Özeti

**FocusTimer** — macOS menu bar Pomodoro uygulaması. SwiftUI + SwiftData, Swift Package Manager ile
yönetilir. Xcode projesi yoktur; her şey `Package.swift` üzerinden derlenir.

- **Platform:** macOS 14+
- **Swift:** 5.9+
- **Build:** `swift build` / `swift test`
- **Çalıştırma:** `swift run FocusTimer`

---

## Mimari

```
timer-app/
├── Package.swift
├── Sources/
│   ├── TimerCore/            ← Platform-bağımsız iş mantığı (test edilebilir)
│   │   ├── Models.swift      ← TimerMode, TimerPreset
│   │   ├── TimerEngine.swift ← Tüm timer state'i (@MainActor ObservableObject)
│   │   └── CircularMath.swift← Saf fonksiyonlar: minutesFromAngle, Int.roundedToNearest
│   └── FocusTimer/           ← macOS UI katmanı (test edilmez)
│       ├── FocusTimerApp.swift ← NSApplicationDelegate, menu bar kurulumu
│       ├── ContentView.swift   ← Ana timer UI, dairesel slider
│       └── HistoryView.swift   ← SwiftData session geçmişi
└── Tests/
    └── TimerCoreTests/       ← Tüm unit testler buraya girer
        ├── TimerEngineTests.swift   (35 test)
        ├── ModelsTests.swift        (14 test)
        └── CircularMathTests.swift  (12 test)
```

### Katman Kuralı

- `TimerCore` → AppKit/UIKit/SwiftUI import **yasaktır**. Sadece `Foundation` + `Combine`.
- `FocusTimer` → `TimerCore`'a bağımlıdır; macOS API'leri buraya girer.
- Yeni iş mantığı ekleniyorsa **TimerCore'a** girer ve **testi yazılır**.

---

## TimerEngine — Özet

`@MainActor public final class TimerEngine: ObservableObject`

| Özellik / Metod | Açıklama |
|---|---|
| `mode: TimerMode` | `.focus / .shortBreak / .longBreak` |
| `timeRemaining: Int` | Saniye cinsinden kalan süre |
| `isRunning: Bool` | Timer çalışıyor mu |
| `completedSessions: Int` | Toplam tamamlanan focus oturumu |
| `preset: TimerPreset` | Aktif preset (.classic / .extended / .sprint) |
| `progress: Double` | 0.0–1.0 arası ilerleme |
| `timeString: String` | "MM:SS" formatında |
| `sessionsInCycle: Int` | completedSessions % 4 |
| `hasCustomDuration: Bool` | Slider ile override var mı |
| `toggle() / start() / pause() / reset()` | Timer kontrolü |
| `switchMode(_ :)` | Mod değiştirir, timer'ı sıfırlar |
| `applyPreset(_ :)` | Preset değiştirir, custom override'ları temizler |
| `setDuration(minutes:)` | Slider override — çalışırken çağrılamaz |
| `completionPublisher` | `PassthroughSubject<(mode, minutes), Never>` — oturum biter |

### Mod Geçiş Mantığı

```
focus → (completedSessions % 4 == 0) ? longBreak : shortBreak
shortBreak / longBreak → focus
```

4 focus tamamlanınca `sessionsInCycle` 0'a döner, uzun mola tetiklenir.

---

## Presetler

| Preset | Focus | Short Break | Long Break |
|---|---|---|---|
| Classic | 25 dk | 5 dk | 15 dk |
| Extended | 50 dk | 10 dk | 20 dk |
| Sprint | 15 dk | 3 dk | 10 dk |

---

## Testler — Kurallar ve Beklentiler

### Testleri Çalıştır

```bash
swift test
# Xcode'da: ⌘U
```

### Mevcut Kapsam

| Dosya | Test Sayısı | Kapsam |
|---|---|---|
| `TimerEngineTests` | 35 | State, tick, progress, slider, preset, mod geçişleri, publisher |
| `ModelsTests` | 14 | TimerMode rawValue/shortTitle, TimerPreset değerleri ve equality |
| `CircularMathTests` | 12 | Cardinal yönler, clamp, snap-to-5dk, roundedToNearest |

### AI için Test Kuralları

**Her değişiklik öncesinde `swift test` çalıştır.** Testler yeşil değilse commit atma.

**Yeni TimerCore kodu yazıyorsan:**
1. `Tests/TimerCoreTests/` altına test ekle
2. Happy path + edge case (min/max değerler, nil, sıfır) yaz
3. `@MainActor` gerektiren testlerde sınıfı `@MainActor` ile işaretle
4. Combine publisher'ları için `XCTestExpectation` kullan (bkz. `testCompletionPublisherEmitsOnComplete`)

**`tick()` / `complete()` / `advance()` metodları `internal`'dır** — `@testable import TimerCore` ile erişilebilir.

**UI kodu (FocusTimer target) test edilmez** — SwiftData ve NSApplication gerektiren kodlar için
entegrasyon testi yerine `TimerCore`'u soyutlayarak unit test yaz.

### Test Yazım Stili

```swift
@MainActor
final class OrnekTests: XCTestCase {
    var engine: TimerEngine!

    override func setUp() { engine = TimerEngine() }
    override func tearDown() { engine.pause(); engine = nil }

    func testX_yadaY_bekleneniZ() {
        // Arrange
        engine.setDuration(minutes: 30)
        // Act
        engine.tick()
        // Assert
        XCTAssertEqual(engine.timeRemaining, 30 * 60 - 1)
    }
}
```

---

## Geliştirme Süreci

### Dallanma Stratejisi

- Ana geliştirme: `claude/new-project-branch-kvwtR` (mevcut aktif branch)
- Git push: `git push -u origin <branch-adı>`

### Commit Öncesi Kontrol Listesi

- [ ] `swift test` — tüm testler geçiyor
- [ ] `swift build` — derleme temiz
- [ ] Yeni TimerCore kodu → yeni testler eklendi mi?
- [ ] CircularMath gibi saf fonksiyonlar `TimerCore`'a gitti mi (ContentView'da değil)?

### Ekleme Yaparken

- Yeni model → `Sources/TimerCore/Models.swift` veya ayrı bir `*.swift` dosyası
- Yeni iş mantığı → `TimerEngine` veya ayrı bir Core servisi
- Yeni UI bileşeni → `Sources/FocusTimer/`
- Her şeyin testi → `Tests/TimerCoreTests/`

---

## Dikkat Edilecek Noktalar

1. **`@MainActor`** — `TimerEngine` MainActor'da çalışır. `Timer.publish` ana thread'de ateşlenir.
   Başka thread'den çağırırsan `await MainActor.run {}` kullan.

2. **Custom Duration vs Preset** — `setDuration` sadece aktif modun override'ını değiştirir.
   `applyPreset` tüm override'ları temizler (`customDurations.removeAll()`).

3. **`sessionsInCycle`** — `completedSessions % 4`. `longBreak` tetiklendikten sonra 0'a döner.
   Mod geçiş mantığını değiştirirken bunu göz önünde bulundur.

4. **`Int.roundedToNearest`** — `public extension Int` olarak `CircularMath.swift`'te tanımlı.
   Hem uygulama hem testler bu implementasyonu paylaşır. ContentView'da duplicate kopyası yok.

5. **SwiftData (HistoryView)** — `FocusSession` modeli `HistoryView.swift` içinde tanımlı.
   SwiftData schema değişikliklerinde migration gerekebilir.

6. **macOS menu bar uygulaması** — `NSApplicationActivationPolicy.accessory` ile çalışır,
   Dock'ta görünmez. `FocusTimerApp.swift`'te `NSApplicationDelegate` ile yönetilir.

---

## Yol Haritası

### Phase 1 — MVP
- [x] macOS menu bar app (SwiftUI + AppKit)
- [x] Pomodoro döngüsü: 25dk çalışma / 5dk kısa mola / 15dk uzun mola
- [x] Start / Pause / Reset
- [x] Preset seçimi (Classic 25/5, Extended 50/10, Sprint 15/3)
- [x] Popover arayüz — siyah-beyaz, ultra minimal
- [x] Menu bar'da kalan süre gösterimi
- [x] Bildirim desteği (UNUserNotificationCenter)
- [ ] Tamamlanma alarmı (sistem sesi)

### Phase 2 — Tarihçe & Temalar
- [x] Günlük/haftalık oturum geçmişi (local SwiftData)
- [x] Tema sistemi (accent renkler — white/blue/orange/green/pink, UserDefaults kalıcı)
- [x] Menu bar icon animasyonu (progress ring, accent renkli)
- [x] Floating window (NSPanel tabanlı floating timer overlay, pip butonu)

### Phase 3 — Ses & Çoklu Dil
- [ ] Çalışma sırasında ambient müzik (lofi, rain, white noise seçenekleri)
- [ ] Özel alarm sesleri
- [ ] TR / EN / DE / JA / ES dil desteği
- [ ] iCloud sync (cihazlar arası geçmiş)

### Phase 4 — AI & Radio
- [ ] AI Radio — çalışma süresine göre generative ambient akış (Claude API ile mood detection + müzik öneri)
- [ ] AI Analiz — oturum verilerinden productivity pattern çıkarma, öneriler
- [ ] Akıllı mola önerileri (ne zaman durman gerektiğini öğrenen sistem)
- [ ] Streak sistemi + motivasyon

### Phase 5 — Ekosistem
- [ ] iOS companion app (telefonda timer sync)
- [ ] Widgets (macOS + iOS)
- [ ] Shortcuts app entegrasyonu
- [ ] Obsidian / Notion entegrasyonu (oturum log'u aktarma)

---

*Bu dosyayı güncel tut: yeni özellik eklenince, mimari değişince veya yeni test kuralları
belirlenince buraya yaz.*
