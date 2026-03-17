# Code Review Listesi

## 1. TimerCore — İş Mantığı Katmanı
- `TimerEngine` (state yönetimi, tick, mod geçişleri, preset, publisher)
- `CircularMath` (minutesFromAngle, roundedToNearest)
- `Models` (TimerMode, TimerPreset)

## 2. Circular Slider & Timer Ring (ContentView)
- Dairesel drag gesture, açı → dakika hesabı
- `setDuration` ile TimerEngine entegrasyonu

## 3. Session History — SwiftData (HistoryView)
- `FocusSession` modeli
- Günlük/haftalık listeleme

## 4. Tema Sistemi (ThemeManager)
- Accent renk seçimi, UserDefaults kalıcılığı

## 5. Menu Bar Progress Ring & Floating Window
- `MenuBarLabel` — animasyonlu progress ring
- `FloatingTimerWindow` — NSPanel tabanlı overlay

## 6. Ambient Ses (AmbientAudioEngine)
- White / rain / lofi — programatik AVAudioEngine üretimi
- Volume slider, seçim kalıcılığı

## 7. Alarm Sesleri (AlarmSoundManager)
- NSSound sistem sesleri
- Tıklayınca önizleme

## 8. Çoklu Dil Desteği (LanguageManager)
- TR / EN / DE / JA / ES
- Runtime switching, Localizable.strings

## 9. Streak Sistemi (StreakManager)
- Günlük seri takibi, en uzun streak
- Milestone animasyonu

## 10. Akıllı Mola Önerileri (BreakSuggestionView)
- Oturum verisinden öneri üretme
- Gösterim koşulları ve UI

## 11. AI Radio (AIRadioService + AIRadioView + KeychainService)
- Keychain API key yönetimi
- Claude API entegrasyonu (anonim payload, HTTPS, timeout)
- Öneri UI'ı ve ambient motora uygulama

## 12. Unit Testler (TimerCoreTests)
- TimerEngineTests (35 test)
- ModelsTests (14 test)
- CircularMathTests (12 test)
- StreakManagerTests
- BreakAdvisorTests
