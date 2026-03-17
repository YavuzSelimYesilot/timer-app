import Foundation
import Combine
import TimerCore

// MARK: - Anonymous Session Payload
// Kural: kullanıcı adı, cihaz adı, IP veya tam timestamp içermez.

struct AISessionPayload: Codable {
    let durationMinutes: Int
    let mode: String          // "Focus" / "Short Break" / "Long Break"
    let completedSessions: Int
    let hourOfDay: Int        // 0–23, tarih yok
    let dayOfWeek: Int        // 1–7, yıl/ay yok
    let streakDays: Int
}

// MARK: - AI Response

struct AIRadioResponse: Codable, Equatable {
    let ambient: String   // "white" | "rain" | "lofi"
    let volume: Float     // 0.0–1.0
    let mood: String
    let reason: String

    var ambientSound: AmbientSound? { AmbientSound(rawValue: ambient) }
}

// MARK: - Service

@MainActor
final class AIRadioService: ObservableObject {
    @Published private(set) var recommendation: AIRadioResponse?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // apiKey: didSet Keychain'e kaydeder. Init'te _apiKey ile atandığından
    // didSet tetiklenmez — gereksiz Keychain yazımı önlenir.
    @Published var apiKey: String = "" {
        didSet {
            if apiKey.isEmpty {
                KeychainService.delete(key: Self.keychainKey)
            } else {
                KeychainService.save(key: Self.keychainKey, value: apiKey)
            }
        }
    }

    private static let keychainKey = "claude_api_key"
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    init() {
        // _apiKey ile atama: didSet tetiklenmez, sadece okuma yapılır
        _apiKey = Published(wrappedValue: KeychainService.load(key: Self.keychainKey) ?? "")
    }

    // MARK: - Fetch Recommendation

    func fetchRecommendation(
        durationMinutes: Int,
        mode: String,
        completedSessions: Int,
        hourOfDay: Int,
        dayOfWeek: Int,
        streakDays: Int
    ) async {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)
        guard !trimmedKey.isEmpty else {
            errorMessage = "API anahtarı girilmedi"
            return
        }

        isLoading = true
        errorMessage = nil

        let payload = AISessionPayload(
            durationMinutes: durationMinutes,
            mode: mode,
            completedSessions: completedSessions,
            hourOfDay: hourOfDay,
            dayOfWeek: dayOfWeek,
            streakDays: streakDays
        )

        do {
            recommendation = try await callClaudeAPI(payload: payload, key: trimmedKey)
        } catch {
            #if DEBUG
            print("[AIRadio] Hata: \(error.localizedDescription)")
            #endif
            errorMessage = "Öneri alınamadı, tekrar dene"
        }

        isLoading = false
    }

    // MARK: - Private

    private func callClaudeAPI(payload: AISessionPayload, key: String) async throws -> AIRadioResponse {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let payloadData = try encoder.encode(payload)
        let payloadString = String(data: payloadData, encoding: .utf8) ?? "{}"

        let systemPrompt = """
        You are an ambient sound advisor for a Pomodoro timer app.
        Based on anonymous session data, recommend one ambient sound.
        Available sounds:
        - "white": flat noise, best for blocking distractions and high-energy states
        - "rain": pink noise, best for calm or tired states
        - "lofi": brown noise, best for deep and sustained focus
        Respond with valid JSON only, no markdown, no explanation outside JSON:
        {"ambient":"lofi","volume":0.6,"mood":"derin odak","reason":"Kısa Türkçe açıklama, max 45 karakter"}
        """

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 150,
            "system": systemPrompt,
            "messages": [["role": "user", "content": "Session: \(payloadString)"]]
        ]

        var request = URLRequest(url: endpoint, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let envelope = try JSONDecoder().decode(ClaudeEnvelope.self, from: data)
        guard let text = envelope.content.first?.text,
              let jsonData = text.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }

        return try JSONDecoder().decode(AIRadioResponse.self, from: jsonData)
    }
}

// MARK: - Claude API envelope (iç kullanım)

private struct ClaudeEnvelope: Decodable {
    struct Block: Decodable { let text: String }
    let content: [Block]
}
