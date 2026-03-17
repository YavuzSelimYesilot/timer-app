import Foundation

/// Converts a drag position on a circular control to a minute value.
/// - Parameters:
///   - dx: Horizontal distance from center
///   - dy: Vertical distance from center
///   - maxMinutes: Upper bound for the result
/// - Returns: Minutes clamped to [1, maxMinutes], rounded to nearest 5
public func minutesFromAngle(dx: Double, dy: Double, maxMinutes: Int) -> Int {
    // atan2(dx, -dy) gives angle from top (12 o'clock), clockwise
    var angle = atan2(dx, -dy)
    if angle < 0 { angle += 2 * .pi }
    let fraction = angle / (2 * .pi)
    let raw = Int(fraction * Double(maxMinutes))
    return max(1, min(maxMinutes, raw.roundedToNearest(5)))
}

public extension Int {
    func roundedToNearest(_ step: Int) -> Int {
        guard step > 0 else { return self }
        let r = self % step
        return r * 2 < step ? self - r : self - r + step
    }
}
