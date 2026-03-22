import Foundation

// MARK: - TaskItem

public struct TaskItem: Identifiable, Equatable, Hashable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool
    public var createdAt: Date
    public var completedAt: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

// MARK: - TaskMetrics (anonymous, AI-safe)

public struct TaskMetrics: Codable, Equatable {
    public let taskCount: Int
    public let completedCount: Int
    public let completionRate: Double
    public let dayOfWeek: Int   // 1-7
    public let hourOfDay: Int   // 0-23

    public init(taskCount: Int, completedCount: Int, completionRate: Double, dayOfWeek: Int, hourOfDay: Int) {
        self.taskCount = taskCount
        self.completedCount = completedCount
        self.completionRate = completionRate
        self.dayOfWeek = dayOfWeek
        self.hourOfDay = hourOfDay
    }
}
