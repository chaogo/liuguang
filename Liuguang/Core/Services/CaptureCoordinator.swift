import Foundation
import SwiftData

@MainActor
final class CaptureCoordinator {
    let camera: PhotoCapturing
    let storage: PhotoStorage
    let limitService: CaptureLimitService
    let notifications: NotificationService
    let clock: Clock
    let developmentDelay: TimeInterval

    init(
        camera: PhotoCapturing,
        storage: PhotoStorage,
        limitService: CaptureLimitService,
        notifications: NotificationService,
        clock: Clock,
        developmentDelay: TimeInterval = 30
    ) {
        self.camera = camera
        self.storage = storage
        self.limitService = limitService
        self.notifications = notifications
        self.clock = clock
        self.developmentDelay = developmentDelay
    }

    @discardableResult
    func captureAndPersist(in context: ModelContext) async throws -> Photo {
        if let batch = try limitService.currentBatch(in: context),
           batch.count >= CaptureBatch.limit {
            throw CaptureLimitError.limitReached(nextAvailable: batch.expiresAt())
        }

        let captured = try await camera.capture()

        _ = try limitService.registerCapture(in: context)

        let id = UUID()
        _ = try storage.saveRaw(captured.jpegData, id: id)

        var rng = SystemRandomNumberGenerator()
        let profile = FilmProfile.random(using: &rng)
        let now = clock.now

        let photo = Photo(
            id: id,
            rawPath: storage.rawURL(for: id).path,
            capturedAt: now,
            developsAt: now.addingTimeInterval(developmentDelay),
            filmProfileID: profile.id,
            status: .queued,
            iso: captured.iso,
            shutterDenominator: captured.shutterDenominator,
            aperture: captured.aperture
        )
        context.insert(photo)
        try context.save()

        try? await notifications.schedule(.init(
            identifier: "develop-\(id.uuidString)",
            title: "A photo has developed",
            body: "Open Liuguang to see what you captured.",
            fireDate: photo.developsAt
        ))

        return photo
    }
}
