import XCTest
@testable import TimerCore

final class TaskEngineTests: XCTestCase {

    private let calendar = Calendar.current

    // MARK: - todayTasks

    func testTodayTasks_filtersCorrectly() {
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tasks = [
            TaskItem(title: "Today", createdAt: today),
            TaskItem(title: "Yesterday", createdAt: yesterday)
        ]
        let result = TaskEngine.todayTasks(tasks, date: today)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Today")
    }

    func testTodayTasks_emptyInput() {
        XCTAssertTrue(TaskEngine.todayTasks([]).isEmpty)
    }

    func testTodayTasks_allFromDifferentDay() {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let tasks = [TaskItem(title: "Old", createdAt: yesterday)]
        XCTAssertTrue(TaskEngine.todayTasks(tasks).isEmpty)
    }

    // MARK: - autocompleteSuggestions

    func testAutocomplete_prefixMatch() {
        let titles = ["Write report", "Write tests", "Read book"]
        let result = TaskEngine.autocompleteSuggestions(input: "Wr", from: titles)
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.hasPrefix("Write") })
    }

    func testAutocomplete_caseInsensitive() {
        let titles = ["Deploy app"]
        let result = TaskEngine.autocompleteSuggestions(input: "deploy", from: titles)
        XCTAssertEqual(result, ["Deploy app"])
    }

    func testAutocomplete_emptyInput() {
        let result = TaskEngine.autocompleteSuggestions(input: "", from: ["A", "B"])
        XCTAssertTrue(result.isEmpty)
    }

    func testAutocomplete_noMatch() {
        let result = TaskEngine.autocompleteSuggestions(input: "xyz", from: ["Alpha", "Beta"])
        XCTAssertTrue(result.isEmpty)
    }

    func testAutocomplete_limit() {
        let titles = (1...10).map { "Task \($0)" }
        let result = TaskEngine.autocompleteSuggestions(input: "Task", from: titles, limit: 3)
        XCTAssertEqual(result.count, 3)
    }

    func testAutocomplete_dedup() {
        let titles = ["Write code", "Write code", "Write code"]
        let result = TaskEngine.autocompleteSuggestions(input: "Write", from: titles)
        XCTAssertEqual(result.count, 1)
    }

    func testAutocomplete_containsMatchAfterPrefix() {
        let titles = ["Review PR", "Code review session"]
        let result = TaskEngine.autocompleteSuggestions(input: "review", from: titles)
        // "Review PR" is prefix match → first
        XCTAssertEqual(result.first, "Review PR")
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - completionRate

    func testCompletionRate_allCompleted() {
        let tasks = [
            TaskItem(title: "A", isCompleted: true),
            TaskItem(title: "B", isCompleted: true)
        ]
        XCTAssertEqual(TaskEngine.completionRate(tasks), 1.0)
    }

    func testCompletionRate_noneCompleted() {
        let tasks = [TaskItem(title: "A"), TaskItem(title: "B")]
        XCTAssertEqual(TaskEngine.completionRate(tasks), 0.0)
    }

    func testCompletionRate_half() {
        let tasks = [
            TaskItem(title: "A", isCompleted: true),
            TaskItem(title: "B")
        ]
        XCTAssertEqual(TaskEngine.completionRate(tasks), 0.5)
    }

    func testCompletionRate_empty() {
        XCTAssertEqual(TaskEngine.completionRate([]), 0.0)
    }

    // MARK: - sorted

    func testSorted_incompleteFirst() {
        let now = Date()
        let tasks = [
            TaskItem(title: "Done", isCompleted: true, createdAt: now),
            TaskItem(title: "Todo", createdAt: now)
        ]
        let result = TaskEngine.sorted(tasks)
        XCTAssertEqual(result.first?.title, "Todo")
        XCTAssertEqual(result.last?.title, "Done")
    }

    func testSorted_incompleteByCreationOrder() {
        let early = Date(timeIntervalSince1970: 100)
        let late = Date(timeIntervalSince1970: 200)
        let tasks = [
            TaskItem(title: "Late", createdAt: late),
            TaskItem(title: "Early", createdAt: early)
        ]
        let result = TaskEngine.sorted(tasks)
        XCTAssertEqual(result.first?.title, "Early")
    }

    func testSorted_completedByMostRecent() {
        let early = Date(timeIntervalSince1970: 100)
        let late = Date(timeIntervalSince1970: 200)
        let tasks = [
            TaskItem(title: "A", isCompleted: true, completedAt: early),
            TaskItem(title: "B", isCompleted: true, completedAt: late)
        ]
        let result = TaskEngine.sorted(tasks)
        XCTAssertEqual(result.first?.title, "B")
    }

    // MARK: - metrics

    func testMetrics_correctCounts() {
        let tasks = [
            TaskItem(title: "A", isCompleted: true),
            TaskItem(title: "B"),
            TaskItem(title: "C", isCompleted: true)
        ]
        let m = TaskEngine.metrics(from: tasks)
        XCTAssertEqual(m.taskCount, 3)
        XCTAssertEqual(m.completedCount, 2)
        XCTAssertEqual(m.completionRate, 2.0 / 3.0, accuracy: 0.001)
    }

    func testMetrics_empty() {
        let m = TaskEngine.metrics(from: [])
        XCTAssertEqual(m.taskCount, 0)
        XCTAssertEqual(m.completedCount, 0)
        XCTAssertEqual(m.completionRate, 0.0)
    }

    func testMetrics_dayOfWeekAndHour() {
        let date = Date()
        let cal = Calendar.current
        let m = TaskEngine.metrics(from: [], date: date, calendar: cal)
        XCTAssertEqual(m.dayOfWeek, cal.component(.weekday, from: date))
        XCTAssertEqual(m.hourOfDay, cal.component(.hour, from: date))
    }
}
