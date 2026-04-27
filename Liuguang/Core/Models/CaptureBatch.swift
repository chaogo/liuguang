import Foundation
import SwiftData

@Model
final class CaptureBatch {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var count: Int

    static let limit = 12
    static let windowHours: TimeInterval = 24 * 60 * 60

    init(id: UUID = UUID(), startedAt: Date, count: Int = 0) {
        self.id = id
        self.startedAt = startedAt
        self.count = count
    }

    func expiresAt() -> Date {
        startedAt.addingTimeInterval(Self.windowHours)
    }

    func isActive(at now: Date) -> Bool {
        now < expiresAt() && count < Self.limit
    }
}
