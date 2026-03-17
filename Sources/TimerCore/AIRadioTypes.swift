import Foundation

// MARK: - Anonymous Session Payload
// Kural: kullanıcı adı, cihaz adı, IP veya tam timestamp içermez.

public struct AISessionPayload: Codable, Equatable {
    public let durationMinutes: Int
    public let mode: String          // "Focus" / "Short Break" / "Long Break"
    public let completedSessions: Int
    public let hourOfDay: Int        // 0–23, tarih yok
    public let dayOfWeek: Int        // 1–7, yıl/ay yok
    public let streakDays: Int

    public init(
        durationMinutes: Int,
        mode: String,
        completedSessions: Int,
        hourOfDay: Int,
        dayOfWeek: Int,
        streakDays: Int
    ) {
        self.durationMinutes    = durationMinutes
        self.mode               = mode
        self.completedSessions  = completedSessions
        self.hourOfDay          = hourOfDay
        self.dayOfWeek          = dayOfWeek
        self.streakDays         = streakDays
    }
}

// MARK: - AI Response

public struct AIRadioResponse: Codable, Equatable {
    public let ambient: String   // "white" | "rain" | "lofi"
    public let volume: Float     // 0.0–1.0
    public let mood: String
    public let reason: String

    public init(ambient: String, volume: Float, mood: String, reason: String) {
        self.ambient = ambient
        self.volume  = volume
        self.mood    = mood
        self.reason  = reason
    }
}
