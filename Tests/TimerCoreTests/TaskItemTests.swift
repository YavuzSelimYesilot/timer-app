import XCTest
@testable import TimerCore

final class TaskItemTests: XCTestCase {

    func testDefaultInit_isNotCompleted() {
        let item = TaskItem(title: "Test")
        XCTAssertFalse(item.isCompleted)
        XCTAssertNil(item.completedAt)
    }

    func testInit_withAllParameters() {
        let id = UUID()
        let now = Date()
        let item = TaskItem(id: id, title: "Write tests", isCompleted: true, createdAt: now, completedAt: now)
        XCTAssertEqual(item.id, id)
        XCTAssertEqual(item.title, "Write tests")
        XCTAssertTrue(item.isCompleted)
        XCTAssertEqual(item.createdAt, now)
        XCTAssertEqual(item.completedAt, now)
    }

    func testEquatable_sameId() {
        let id = UUID()
        let a = TaskItem(id: id, title: "A")
        let b = TaskItem(id: id, title: "A")
        XCTAssertEqual(a, b)
    }

    func testEquatable_differentId() {
        let a = TaskItem(title: "A")
        let b = TaskItem(title: "A")
        XCTAssertNotEqual(a, b)
    }

    func testHashable_canBeUsedInSet() {
        let a = TaskItem(title: "A")
        let b = TaskItem(title: "B")
        let set: Set<TaskItem> = [a, b, a]
        XCTAssertEqual(set.count, 2)
    }
}
