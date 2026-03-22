import Foundation

/// Stateless pure functions for task management logic.
public enum TaskEngine {

    // MARK: - Filtering

    /// Returns tasks whose `createdAt` falls on the same calendar day as `date`.
    public static func todayTasks(_ tasks: [TaskItem], date: Date = Date(), calendar: Calendar = .current) -> [TaskItem] {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        return tasks.filter { $0.createdAt >= start && $0.createdAt < end }
    }

    // MARK: - Autocomplete

    /// Returns up to `limit` distinct suggestions matching `input` (prefix-first, case-insensitive).
    public static func autocompleteSuggestions(
        input: String,
        from titles: [String],
        limit: Int = 5
    ) -> [String] {
        let query = input.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }

        let lowered = query.lowercased()
        let unique = Array(Set(titles))

        // Prefix matches first, then contains matches
        let prefixMatches = unique.filter { $0.lowercased().hasPrefix(lowered) }.sorted()
        let containsMatches = unique.filter {
            !$0.lowercased().hasPrefix(lowered) && $0.lowercased().contains(lowered)
        }.sorted()

        let combined = prefixMatches + containsMatches
        return Array(combined.prefix(limit))
    }

    // MARK: - Completion Rate

    /// Returns 0.0–1.0 completion rate. Returns 0.0 for empty arrays.
    public static func completionRate(_ tasks: [TaskItem]) -> Double {
        guard !tasks.isEmpty else { return 0.0 }
        let completed = tasks.filter(\.isCompleted).count
        return Double(completed) / Double(tasks.count)
    }

    // MARK: - Sorting

    /// Incomplete tasks first (by creation date), then completed tasks (most recently completed first).
    public static func sorted(_ tasks: [TaskItem]) -> [TaskItem] {
        let incomplete = tasks.filter { !$0.isCompleted }.sorted { $0.createdAt < $1.createdAt }
        let complete = tasks.filter(\.isCompleted).sorted {
            ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt)
        }
        return incomplete + complete
    }

    // MARK: - AI Metrics

    /// Produces anonymous metrics from tasks (no titles, no exact timestamps).
    public static func metrics(from tasks: [TaskItem], date: Date = Date(), calendar: Calendar = .current) -> TaskMetrics {
        let completedCount = tasks.filter(\.isCompleted).count
        let rate = tasks.isEmpty ? 0.0 : Double(completedCount) / Double(tasks.count)
        let dayOfWeek = calendar.component(.weekday, from: date)
        let hourOfDay = calendar.component(.hour, from: date)

        return TaskMetrics(
            taskCount: tasks.count,
            completedCount: completedCount,
            completionRate: rate,
            dayOfWeek: dayOfWeek,
            hourOfDay: hourOfDay
        )
    }
}
