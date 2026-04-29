import XCTest
import SwiftData
@testable import Liuguang

final class CaptureCoordinatorTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var clock: TestClock!
    var storage: InMemoryPhotoStorage!
    var camera: MockCamera!
    var notifications: MockNotificationService!
    var coordinator: CaptureCoordinator!

    @MainActor
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Photo.self, CaptureBatch.self,
            configurations: config
        )
        context = ModelContext(container)
        clock = TestClock(Date(timeIntervalSince1970: 1_700_000_000))
        storage = InMemoryPhotoStorage()
        camera = MockCamera()
        notifications = MockNotificationService()
        coordinator = CaptureCoordinator(
            camera: camera,
            storage: storage,
            limitService: CaptureLimitService(clock: clock),
            notifications: notifications,
            clock: clock
        )
    }

    @MainActor
    func testCaptureSchedulesNotificationAtDevelopsAt() async throws {
        let photo = try await coordinator.captureAndPersist(in: context)

        XCTAssertEqual(notifications.scheduled.count, 1)
        let n = try XCTUnwrap(notifications.scheduled.first)
        XCTAssertEqual(n.identifier, "develop-\(photo.id.uuidString)")
        XCTAssertEqual(n.fireDate, photo.developsAt)
        XCTAssertFalse(n.title.isEmpty)
        XCTAssertFalse(n.body.isEmpty)
    }

    @MainActor
    func testLimitReachedDoesNotScheduleNotification() async throws {
        for _ in 0..<12 {
            _ = try await coordinator.captureAndPersist(in: context)
        }
        let beforeCount = notifications.scheduled.count

        do {
            _ = try await coordinator.captureAndPersist(in: context)
        } catch CaptureLimitError.limitReached {
            // expected
        }
        XCTAssertEqual(notifications.scheduled.count, beforeCount)
    }

    @MainActor
    func testCaptureCreatesPhotoWithDevelopsAt24hLater() async throws {
        let photo = try await coordinator.captureAndPersist(in: context)

        XCTAssertEqual(photo.status, .queued)
        XCTAssertEqual(photo.developsAt.timeIntervalSince(photo.capturedAt), 24 * 3600, accuracy: 0.001)
        XCTAssertEqual(photo.capturedAt, clock.now)
    }

    @MainActor
    func testCaptureWritesRawJpeg() async throws {
        camera.nextCapture = CapturedPhoto(
            jpegData: Data([1, 2, 3, 4]),
            iso: 800,
            shutterDenominator: 250,
            aperture: 1.8,
            capturedAt: clock.now
        )

        let photo = try await coordinator.captureAndPersist(in: context)
        let saved = storage.writtenRaw[photo.id]
        XCTAssertEqual(saved, Data([1, 2, 3, 4]))
        XCTAssertEqual(photo.iso, 800)
        XCTAssertEqual(photo.shutterDenominator, 250)
        XCTAssertEqual(photo.aperture, 1.8)
    }

    @MainActor
    func testCaptureAssignsRandomFilmProfile() async throws {
        let photo = try await coordinator.captureAndPersist(in: context)
        XCTAssertTrue(FilmProfile.all.contains { $0.id == photo.filmProfileID })
    }

    @MainActor
    func testCaptureBlockedWhenLimitReached() async throws {
        for _ in 0..<12 {
            _ = try await coordinator.captureAndPersist(in: context)
        }
        do {
            _ = try await coordinator.captureAndPersist(in: context)
            XCTFail("should have thrown")
        } catch CaptureLimitError.limitReached {
            // expected
        }
    }

    @MainActor
    func testCameraFailurePropagates() async throws {
        camera.captureError = .captureFailed("boom")
        do {
            _ = try await coordinator.captureAndPersist(in: context)
            XCTFail("should have thrown")
        } catch CaptureError.captureFailed {
            // expected
        }
    }
}

final class InMemoryPhotoStorage: PhotoStorage {
    var writtenRaw: [UUID: Data] = [:]
    var writtenDeveloped: [UUID: Data] = [:]

    func saveRaw(_ data: Data, id: UUID) throws -> URL {
        writtenRaw[id] = data
        return rawURL(for: id)
    }

    func loadRaw(id: UUID) throws -> Data {
        guard let data = writtenRaw[id] else {
            throw NSError(domain: "InMemoryPhotoStorage", code: 404)
        }
        return data
    }

    func rawURL(for id: UUID) -> URL {
        URL(fileURLWithPath: "/mem/\(id.uuidString)_raw.jpg")
    }

    func developedURL(for id: UUID) -> URL {
        URL(fileURLWithPath: "/mem/\(id.uuidString)_dev.jpg")
    }

    func saveDeveloped(_ data: Data, id: UUID) throws -> URL {
        writtenDeveloped[id] = data
        return developedURL(for: id)
    }

    func developedExists(at path: String) -> Bool {
        writtenDeveloped.contains { developedURL(for: $0.key).path == path }
    }

    func delete(id: UUID) throws {
        writtenRaw.removeValue(forKey: id)
        writtenDeveloped.removeValue(forKey: id)
    }
}
