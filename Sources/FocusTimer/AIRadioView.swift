import SwiftUI
import TimerCore

extension AIRadioResponse {
    var ambientSound: AmbientSound? { AmbientSound(rawValue: ambient) }
}

// MARK: - AI Radio Row

struct AIRadioView: View {
    @EnvironmentObject var aiRadio: AIRadioService
    @EnvironmentObject var ambient: AmbientAudioEngine
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var streak: StreakManager

    @State private var showKeyInput = false
    @State private var keyDraft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            controlRow
            if let rec = aiRadio.recommendation {
                recommendationRow(rec)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            if let err = aiRadio.errorMessage {
                Text(verbatim: err)
                    .font(.system(size: 9))
                    .foregroundColor(.red.opacity(0.55))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: aiRadio.recommendation)
        .animation(.easeInOut(duration: 0.18), value: aiRadio.errorMessage)
        .sheet(isPresented: $showKeyInput) {
            APIKeyInputView(draft: $keyDraft) { key in
                aiRadio.apiKey = key
            }
        }
    }

    // MARK: - Control Row

    private var controlRow: some View {
        HStack(spacing: 8) {
            Text("AI RADIO")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.2))
                .tracking(1.5)

            Spacer()

            // API key button
            Button {
                keyDraft = aiRadio.apiKey
                showKeyInput = true
            } label: {
                Image(systemName: aiRadio.apiKey.isEmpty ? "key.slash" : "key.fill")
                    .font(.system(size: 10))
                    .foregroundColor(
                        aiRadio.apiKey.isEmpty
                            ? .white.opacity(0.2)
                            : theme.accentColor.opacity(0.7)
                    )
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(aiRadio.apiKey.isEmpty ? 0 : 0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)

            // Recommend button
            Button {
                Task { await requestRecommendation() }
            } label: {
                if aiRadio.isLoading {
                    ProgressView()
                        .scaleEffect(0.55)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 10))
                        .foregroundColor(
                            aiRadio.apiKey.isEmpty
                                ? .white.opacity(0.15)
                                : .white.opacity(0.6)
                        )
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(aiRadio.apiKey.isEmpty ? 0 : 0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }
            .buttonStyle(.plain)
            .disabled(aiRadio.isLoading || aiRadio.apiKey.isEmpty)
        }
    }

    // MARK: - Recommendation Row

    @ViewBuilder
    private func recommendationRow(_ rec: AIRadioResponse) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                if let sound = rec.ambientSound {
                    Image(systemName: sound.icon)
                        .font(.system(size: 9))
                        .foregroundColor(theme.accentColor)
                }
                Text(verbatim: rec.mood)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))

                Spacer()

                Button {
                    applyRecommendation(rec)
                } label: {
                    Text("Uygula")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if !rec.reason.isEmpty {
                Text(verbatim: rec.reason)
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.3))
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Helpers

    private func requestRecommendation() async {
        let cal = Calendar.current
        await aiRadio.fetchRecommendation(
            durationMinutes: engine.currentDurationMinutes,
            mode: engine.mode.rawValue,
            completedSessions: engine.completedSessions,
            hourOfDay: cal.component(.hour, from: Date()),
            dayOfWeek: cal.component(.weekday, from: Date()),
            streakDays: streak.currentStreak
        )
    }

    private func applyRecommendation(_ rec: AIRadioResponse) {
        guard let sound = rec.ambientSound else { return }
        // Eğer zaten bu ses çalıyorsa sadece volume'ü güncelle,
        // aksi takdirde select() ile geç (toggle mantığı var).
        if ambient.current != sound {
            ambient.select(sound)
        }
        ambient.volume = rec.volume
    }
}

// MARK: - API Key Input Sheet

struct APIKeyInputView: View {
    @Binding var draft: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Claude API Anahtarı")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            Text("Anthropic Console'dan (console.anthropic.com)\naldığın anahtarı gir. Keychain'de güvenli saklanır.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)

            SecureField("sk-ant-...", text: $draft)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11, design: .monospaced))

            HStack(spacing: 12) {
                Button("İptal") {
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.4))

                Button("Kaydet") {
                    onSave(draft.trimmingCharacters(in: .whitespaces))
                    dismiss()
                }
                .foregroundColor(.white)
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .font(.system(size: 12))

            if !draft.isEmpty {
                Button("Anahtarı Sil") {
                    onSave("")
                    dismiss()
                }
                .font(.system(size: 10))
                .foregroundColor(.red.opacity(0.5))
            }
        }
        .padding(24)
        .frame(width: 300)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
    }
}
