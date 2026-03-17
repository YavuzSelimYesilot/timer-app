import XCTest
@testable import TimerCore

final class AIRadioTypesTests: XCTestCase {

    // MARK: - AISessionPayload Encoding

    func testPayload_encodesWithSnakeCaseKeys() throws {
        let payload = AISessionPayload(
            durationMinutes: 25,
            mode: "Focus",
            completedSessions: 3,
            hourOfDay: 14,
            dayOfWeek: 2,
            streakDays: 7
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["duration_minutes"] as? Int, 25)
        XCTAssertEqual(json["mode"] as? String, "Focus")
        XCTAssertEqual(json["completed_sessions"] as? Int, 3)
        XCTAssertEqual(json["hour_of_day"] as? Int, 14)
        XCTAssertEqual(json["day_of_week"] as? Int, 2)
        XCTAssertEqual(json["streak_days"] as? Int, 7)
    }

    func testPayload_doesNotContainPII() throws {
        let payload = AISessionPayload(
            durationMinutes: 25,
            mode: "Focus",
            completedSessions: 1,
            hourOfDay: 9,
            dayOfWeek: 3,
            streakDays: 0
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let keys = Set(json.keys)

        // Kişisel veri içeren alanlar hiçbir zaman olmamalı
        XCTAssertFalse(keys.contains("user_id"))
        XCTAssertFalse(keys.contains("device_name"))
        XCTAssertFalse(keys.contains("exact_timestamp"))
        XCTAssertFalse(keys.contains("ip_address"))
    }

    func testPayload_roundtrip() throws {
        let original = AISessionPayload(
            durationMinutes: 50,
            mode: "Short Break",
            completedSessions: 4,
            hourOfDay: 22,
            dayOfWeek: 7,
            streakDays: 14
        )
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(AISessionPayload.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testPayload_hourOfDay_boundary_values() throws {
        let midnight = AISessionPayload(
            durationMinutes: 25, mode: "Focus",
            completedSessions: 0, hourOfDay: 0, dayOfWeek: 1, streakDays: 0
        )
        let endOfDay = AISessionPayload(
            durationMinutes: 25, mode: "Focus",
            completedSessions: 0, hourOfDay: 23, dayOfWeek: 1, streakDays: 0
        )
        XCTAssertEqual(midnight.hourOfDay, 0)
        XCTAssertEqual(endOfDay.hourOfDay, 23)
    }

    // MARK: - AIRadioResponse Decoding

    func testResponse_decodesValidJSON() throws {
        let json = """
        {"ambient":"lofi","volume":0.65,"mood":"derin odak","reason":"Uzun seri için uygun"}
        """
        let response = try JSONDecoder().decode(AIRadioResponse.self, from: Data(json.utf8))

        XCTAssertEqual(response.ambient, "lofi")
        XCTAssertEqual(response.volume, 0.65, accuracy: 0.001)
        XCTAssertEqual(response.mood, "derin odak")
        XCTAssertEqual(response.reason, "Uzun seri için uygun")
    }

    func testResponse_decodesAllAmbientTypes() throws {
        for ambient in ["white", "rain", "lofi"] {
            let json = """
            {"ambient":"\(ambient)","volume":0.5,"mood":"test","reason":"test"}
            """
            let response = try JSONDecoder().decode(AIRadioResponse.self, from: Data(json.utf8))
            XCTAssertEqual(response.ambient, ambient)
        }
    }

    func testResponse_volumeRange() throws {
        for volume in [0.4, 0.6, 0.8] {
            let json = """
            {"ambient":"rain","volume":\(volume),"mood":"sakin","reason":"test"}
            """
            let response = try JSONDecoder().decode(AIRadioResponse.self, from: Data(json.utf8))
            XCTAssertEqual(response.volume, Float(volume), accuracy: 0.001)
        }
    }

    func testResponse_missingFieldThrows() {
        let json = """
        {"ambient":"lofi","volume":0.5}
        """
        XCTAssertThrowsError(
            try JSONDecoder().decode(AIRadioResponse.self, from: Data(json.utf8))
        )
    }

    func testResponse_equality() throws {
        let a = AIRadioResponse(ambient: "rain", volume: 0.6, mood: "sakin", reason: "Yorgun görünüyorsun")
        let b = AIRadioResponse(ambient: "rain", volume: 0.6, mood: "sakin", reason: "Yorgun görünüyorsun")
        let c = AIRadioResponse(ambient: "white", volume: 0.6, mood: "sakin", reason: "Yorgun görünüyorsun")

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
