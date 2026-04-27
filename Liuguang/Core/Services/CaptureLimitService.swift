import Foundation
import SwiftData

enum CaptureLimitError: Error, Equatable {
    case limitReached(nextAvailable: Date)
}

struct CaptureLimitService {
    let clock: Clock

    func currentBatch(in context: ModelContext) throws -> CaptureBatch? {
        let now = clock.now
        let descriptor = FetchDescriptor<CaptureBatch>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        let batches = try context.fetch(descriptor)
        return batches.first { $0.startedAt.addingTimeInterval(CaptureBatch.windowHours) > now }
    }

    func remaining(in context: ModelContext) throws -> Int {
        guard let batch = try currentBatch(in: context) else { return CaptureBatch.limit }
        return max(0, CaptureBatch.limit - batch.count)
    }

    @discardableResult
    func registerCapture(in context: ModelContext) throws -> CaptureBatch {
        let now = clock.now
        if let batch = try currentBatch(in: context) {
            guard batch.count < CaptureBatch.limit else {
                throw CaptureLimitError.limitReached(nextAvailable: batch.expiresAt())
            }
            batch.count += 1
            return batch
        } else {
            let batch = CaptureBatch(startedAt: now, count: 1)
            context.insert(batch)
            return batch
        }
    }
}
