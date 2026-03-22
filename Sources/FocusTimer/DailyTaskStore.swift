import Foundation
import SwiftData
import TimerCore

@Model
final class DailyTask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdAt = Date()
        self.completedAt = nil
    }

    /// Bridge to TimerCore's platform-independent TaskItem
    var asTaskItem: TaskItem {
        TaskItem(
            id: id,
            title: title,
            isCompleted: isCompleted,
            createdAt: createdAt,
            completedAt: completedAt
        )
    }

    func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}
