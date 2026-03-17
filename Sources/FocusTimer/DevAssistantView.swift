import SwiftUI

// MARK: - Dev Assistant View

struct DevAssistantView: View {
    @AppStorage("devAssistant_completedItems") private var rawCompleted: String = ""
    @State private var showScenarios = false
    @State private var showRisks = false

    private static let checklistItems: [ChecklistItem] = [
        .init(id: "launch",
              title: "Menu bar'da icon görünüyor",
              detail: "Üst menü çubuğunda FocusTimer simgesi ve süre gösterimi mevcut."),
        .init(id: "popover",
              title: "Popover açılıp kapanıyor",
              detail: "Menu bar ikonuna tıklayınca pencere açılıyor, tekrar tıklayınca kapanıyor."),
        .init(id: "start",
              title: "Start / Pause çalışıyor",
              detail: "▶ butonuna bas, timer geriye sayıyor. ⏸ ile duraklıyor."),
        .init(id: "tick",
              title: "Timer saniye saniye sayıyor",
              detail: "Süre gerçek zamanlı azalıyor, menu bar etiketi de güncelleniyor."),
        .init(id: "completion",
              title: "Tamamlanma: ses + bildirim",
              detail: "Timer 00:00'a düşünce alarm sesi çalıyor ve macOS bildirimi geliyor."),
        .init(id: "modeswitch",
              title: "Otomatik mod geçişi",
              detail: "Focus bitince Kısa Mola, 4 focus sonra Uzun Mola otomatik geçiyor."),
        .init(id: "history",
              title: "Geçmiş paneli açılıyor",
              detail: "Sağ üstteki grafik ikonu → HistoryView açılıyor. Crash yoksa SwiftData sağlıklı."),
        .init(id: "streak",
              title: "Streak satırı görünüyor",
              detail: "Session dot'larının altında alev ikonu + sayı. 0 olması normal (henüz oturum yok)."),
        .init(id: "floating",
              title: "Floating window açılıp kapanıyor",
              detail: "PiP butonu → sağ üstte mini panel belirir. Tekrar basınca kaybolur."),
        .init(id: "slider",
              title: "Dairesel slider çalışıyor",
              detail: "Timer dairesini sürükle → süre değişiyor. Timer çalışırken sürükleme kilitli."),
        .init(id: "preset",
              title: "Preset değiştirme",
              detail: "Classic / Extended / Sprint arasında geç. Her birinde süre değişmeli."),
        .init(id: "theme",
              title: "Tema rengi değiştirme",
              detail: "5 renk dairesi: beyaz / mavi / turuncu / yeşil / pembe. Aksan rengi değişmeli."),
        .init(id: "ambient",
              title: "Ambient ses çalışıyor",
              detail: "Ses ikonlarından birine bas → arka plan sesi başlar. Slider volume ayarlıyor."),
        .init(id: "alarm",
              title: "Alarm sesi önizleme",
              detail: "Glass / Ping / Tink / Hero / Funk butonlarına basınca ses önizlemesi çalıyor."),
        .init(id: "language",
              title: "Dil değiştirme",
              detail: "EN / TR / DE / JA / ES arasında geç. Arayüz metinleri değişmeli."),
        .init(id: "quit",
              title: "Quit düzgün çalışıyor",
              detail: "En alttaki Quit butonu uygulamayı kapatıyor, process arka planda kalmıyor."),
    ]

    private var completedSet: Set<String> {
        Set(rawCompleted.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    private var completedCount: Int { completedSet.count }
    private var totalCount: Int { Self.checklistItems.count }
    private var progress: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                progressHeader
                checklistSection
                scenariosSection
                risksSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("İlk Çalıştırma Kontrolleri")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.0)
                Spacer()
                Text("\(completedCount) / \(totalCount)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(
                        completedCount == totalCount
                            ? .green.opacity(0.7)
                            : .white.opacity(0.25)
                    )
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            completedCount == totalCount
                                ? Color.green.opacity(0.6)
                                : Color.white.opacity(0.4)
                        )
                        .frame(width: geo.size.width * progress, height: 3)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 3)

            if completedCount == totalCount {
                Text("Tum kontroller tamamlandi.")
                    .font(.system(size: 9))
                    .foregroundColor(.green.opacity(0.6))
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Checklist Section

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Kontrol Listesi")
                .padding(.bottom, 4)

            ForEach(Self.checklistItems) { item in
                ChecklistRow(
                    item: item,
                    isChecked: completedSet.contains(item.id)
                ) {
                    toggleItem(item.id)
                }
            }
        }
    }

    // MARK: - Scenarios Section

    private var scenariosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            CollapseButton(
                title: "Kullanim Senaryolari",
                isExpanded: showScenarios
            ) {
                withAnimation(.easeInOut(duration: 0.2)) { showScenarios.toggle() }
            }

            if showScenarios {
                VStack(alignment: .leading, spacing: 8) {
                    ScenarioCard(number: 1, title: "Tam Pomodoro Dongusu", steps: [
                        "Focus modunu sec (varsayilan zaten secili)",
                        "▶ bas — 25 dk geri sayim baslar",
                        "Timer bitince: ses calar + bildirim gelir",
                        "Otomatik Kisa Mola gecer (5 dk)",
                        "4 focus sonra Uzun Mola tetiklenir",
                        "HistoryView'dan oturumlari kontrol et",
                    ])

                    ScenarioCard(number: 2, title: "Ozel Sure Ayari", steps: [
                        "Timer durmaliyken daireyi surukle",
                        "Parmagi dondur → dakika degisiyor (5'er adim)",
                        "Birak → sure guncellenir, 'Custom' etiketi cikar",
                        "Bir preset sec → ozel sure sifirlanir",
                    ])

                    ScenarioCard(number: 3, title: "Streak Testi", steps: [
                        "1 focus oturumu tamamla",
                        "Streak satirinda alev + 1 gorunmeli",
                        "Ertesi gun 1 oturum daha → 2 olmali",
                        "Bir gun atla, uyg. ac → seri sifirlanir",
                        "En uzun seri (kupa) sifirlanmaz",
                    ])

                    ScenarioCard(number: 4, title: "Floating Window (PiP)", steps: [
                        "Sol ustteki PiP ikonuna bas",
                        "Sag ustte kucuk timer paneli belirir",
                        "Panel uzerindeki ▶/⏸ ile kontrol et",
                        "Popover'i kapat → panel kalmaya devam eder",
                        "PiP ikonuna tekrar bas → panel kapanir",
                    ])
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Risks Section

    private var risksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            CollapseButton(
                title: "Bilinen Riskler & Cozumler",
                isExpanded: showRisks
            ) {
                withAnimation(.easeInOut(duration: 0.2)) { showRisks.toggle() }
            }

            if showRisks {
                VStack(alignment: .leading, spacing: 8) {
                    RiskCard(
                        level: .high,
                        title: "SwiftData Crash (Ilk Acilis)",
                        description: "Eski store varsa schema uyumsuzlugundan uygulama capabilir.",
                        fix: "Terminal:\nrm -rf ~/Library/Application\\ Support/FocusTimer/"
                    )
                    RiskCard(
                        level: .medium,
                        title: "Ambient Ses Calısmiyor",
                        description: "AVAudioEngine sandbox kisitlamasi veya ses cihazi sorunu.",
                        fix: "Sistem Tercihleri → Ses → Cikis cihazini kontrol et."
                    )
                    RiskCard(
                        level: .medium,
                        title: "Bildirim Gelmiyor",
                        description: "Izin verilmemis veya Odak Modu aktif.",
                        fix: "Sistem Tercihleri → Bildirimler → FocusTimer → Izin Ver."
                    )
                    RiskCard(
                        level: .low,
                        title: "Streak Sifirlanmiyor",
                        description: "validateStreak() sadece popover acilinca calisir.",
                        fix: "Uygulamayi kapatip ac — onAppear tekrar tetiklenir."
                    )
                    RiskCard(
                        level: .low,
                        title: "Dil Degismiyor",
                        description: ".lproj bundle yukleme gecikmesi.",
                        fix: "Dil degistirince popover'i kapat/ac."
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Helper

    private func toggleItem(_ id: String) {
        var items = completedSet
        if items.contains(id) {
            items.remove(id)
        } else {
            items.insert(id)
        }
        rawCompleted = items.joined(separator: ",")
    }
}

// MARK: - Sub-components

private struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white.opacity(0.35))
            .tracking(1.0)
    }
}

private struct CollapseButton: View {
    let title: String
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(1.0)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ChecklistRow: View {
    let item: ChecklistItem
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 12))
                    .foregroundColor(isChecked ? .white.opacity(0.5) : .white.opacity(0.15))
                    .frame(width: 16)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 11, weight: isChecked ? .regular : .medium))
                        .foregroundColor(isChecked ? .white.opacity(0.25) : .white.opacity(0.7))
                        .strikethrough(isChecked, color: .white.opacity(0.25))

                    Text(item.detail)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.22))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ScenarioCard: View {
    let number: Int
    let title: String
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("\(number)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.black.opacity(0.7))
                    .frame(width: 16, height: 16)
                    .background(Color.white.opacity(0.4))
                    .clipShape(Circle())

                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 5) {
                        Text("\(index + 1).")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.white.opacity(0.18))
                            .frame(width: 14, alignment: .trailing)
                        Text(step)
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.38))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.leading, 2)
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
    }
}

private struct RiskCard: View {
    enum Level { case low, medium, high }

    let level: Level
    let title: String
    let description: String
    let fix: String

    private var levelColor: Color {
        switch level {
        case .low:    return .white.opacity(0.3)
        case .medium: return .orange.opacity(0.65)
        case .high:   return .red.opacity(0.65)
        }
    }

    private var levelLabel: String {
        switch level {
        case .low:    return "DUSUK"
        case .medium: return "ORTA"
        case .high:   return "YUKSEK"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(levelColor)
                    .frame(width: 5, height: 5)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.55))
                Spacer()
                Text(levelLabel)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(levelColor)
                    .tracking(0.5)
            }

            Text(description)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.3))
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 5) {
                Image(systemName: "wrench.fill")
                    .font(.system(size: 7))
                    .foregroundColor(.white.opacity(0.2))
                    .padding(.top, 1)
                Text(fix)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.28))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(6)
            .background(Color.white.opacity(0.04))
            .cornerRadius(5)
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
    }
}

// MARK: - Data Model

private struct ChecklistItem: Identifiable {
    let id: String
    let title: String
    let detail: String
}
