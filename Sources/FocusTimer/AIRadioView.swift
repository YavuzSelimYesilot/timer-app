import SwiftUI
import TimerCore

// MARK: - AI Radio Row

struct AIRadioView: View {
    @EnvironmentObject var aiRadio: AIRadioService
    @EnvironmentObject var ambient: AmbientAudioEngine
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var streak: StreakManager
    @EnvironmentObject var lang: LanguageManager

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
                    .foregroundStyle(.red.opacity(0.7))
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: aiRadio.recommendation)
        .animation(.easeInOut(duration: 0.18), value: aiRadio.errorMessage)
        .sheet(isPresented: $showKeyInput) {
            APIKeyInputView(draft: $keyDraft, lang: lang) { key in
                aiRadio.apiKey = key
            }
        }
    }

    // MARK: - Control Row

    private var controlRow: some View {
        HStack(spacing: 8) {
            Text("ai.radio.label", bundle: lang.bundle)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.quaternary)
                .tracking(1.5)

            Spacer()

            Button {
                keyDraft = aiRadio.apiKey
                showKeyInput = true
            } label: {
                Image(systemName: aiRadio.apiKey.isEmpty ? "key.slash" : "key.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(
                        aiRadio.apiKey.isEmpty ? AnyShapeStyle(.quaternary) : AnyShapeStyle(theme.accentColor.opacity(0.7))
                    )
                    .frame(width: 24, height: 24)
                    .glassRoundedRect(cornerRadius: 5, fallback: Color.primary.opacity(aiRadio.apiKey.isEmpty ? 0 : 0.07))
            }
            .buttonStyle(.plain)

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
                        .foregroundStyle(
                            aiRadio.apiKey.isEmpty ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.secondary)
                        )
                        .frame(width: 24, height: 24)
                        .glassRoundedRect(cornerRadius: 5, fallback: Color.primary.opacity(aiRadio.apiKey.isEmpty ? 0 : 0.07))
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
                        .foregroundStyle(theme.accentColor)
                }
                Text(verbatim: rec.mood)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    applyRecommendation(rec)
                } label: {
                    Text("ai.radio.apply", bundle: lang.bundle)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .glassCapsule(fallback: Color.primary.opacity(0.1))
                }
                .buttonStyle(.plain)
            }

            if !rec.reason.isEmpty {
                Text(verbatim: rec.reason)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
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
        if ambient.current != sound {
            ambient.select(sound)
        }
        ambient.volume = rec.volume
    }
}

// MARK: - API Key Input Sheet

struct APIKeyInputView: View {
    @Binding var draft: String
    let lang: LanguageManager
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("ai.radio.apikey.title", bundle: lang.bundle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            Text("ai.radio.apikey.description", bundle: lang.bundle)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            SecureField("sk-ant-...", text: $draft)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11, design: .monospaced))

            HStack(spacing: 12) {
                Button(lang.loc("ai.radio.apikey.cancel")) {
                    dismiss()
                }
                .foregroundStyle(.tertiary)

                Button(lang.loc("ai.radio.apikey.save")) {
                    onSave(draft.trimmingCharacters(in: .whitespaces))
                    dismiss()
                }
                .foregroundStyle(.primary)
                .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .font(.system(size: 12))

            if !draft.isEmpty {
                Button(lang.loc("ai.radio.apikey.delete")) {
                    onSave("")
                    dismiss()
                }
                .font(.system(size: 10))
                .foregroundStyle(.red.opacity(0.5))
            }
        }
        .padding(24)
        .frame(width: 300)
        .glassRoundedRect(cornerRadius: 12, fallback: Color(red: 0.1, green: 0.1, blue: 0.1))
    }
}
