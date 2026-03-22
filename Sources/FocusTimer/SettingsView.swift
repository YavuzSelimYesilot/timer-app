import SwiftUI
import TimerCore

struct SettingsView: View {
    @EnvironmentObject var engine: TimerEngine
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var lang: LanguageManager
    @EnvironmentObject var alarm: AlarmSoundManager
    @EnvironmentObject var ambient: AmbientAudioEngine

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("settings.title", bundle: lang.bundle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            ScrollView {
                VStack(spacing: 0) {
                    PresetSelectorView()
                        .padding(.horizontal, 20)

                    ThemeSelectorView()
                        .padding(.top, 10)
                        .padding(.horizontal, 20)

                    AmbientSelectorView()
                        .padding(.top, 10)
                        .padding(.horizontal, 20)

                    AIRadioView()
                        .padding(.top, 10)
                        .padding(.horizontal, 20)

                    AlarmSelectorView()
                        .padding(.top, 10)
                        .padding(.horizontal, 20)

                    LanguageSelectorView()
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)
            }

            Divider()
                .background(Color.white.opacity(0.06))

            QuitButtonView()
                .padding(.vertical, 10)
        }
    }
}
