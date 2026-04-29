import XCTest
import SwiftData
@testable import Liuguang

/// Regressions for bugs found 2026-04-26.
final class BugRegressionTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var clock: TestClock!
    var storage: InMemoryPhotoStorage!

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
    }

    // Bug A: camera failure must not consume one of the 12 daily frames.
    @MainActor
    func testCameraFailureDoesNotConsumeFrame() async throws {
        let camera = MockCamera()
        camera.captureError = .captureFailed("boom")
        let limitService = CaptureLimitService(clock: clock)
        let coordinator = CaptureCoordinator(
            camera: camera,
            storage: storage,
            limitService: limitService,
            notifications: MockNotificationService(),
            clock: clock
        )

        do {
            _ = try await coordinator.captureAndPersist(in: context)
            XCTFail("should have thrown")
        } catch CaptureError.captureFailed {
            // expected
        }

        let remaining = try limitService.remaining(in: context)
        XCTAssertEqual(remaining, 12, "a failed shutter press should not burn a frame")
    }

    // Bug B: a single photo whose render throws must not block other ready
    // photos in the same pass.
    @MainActor
    func testRenderFailureDoesNotBlockSubsequentPhotos() async throws {
        let renderer = FailFirstRenderer()
        let service = DevelopmentService(renderer: renderer, storage: storage, clock: clock)

        let p1Raw = Data([1])
        let p1ID = UUID()
        _ = try storage.saveRaw(p1Raw, id: p1ID)
        let p1 = Photo(
            id: p1ID,
            rawPath: storage.rawURL(for: p1ID).path,
            capturedAt: clock.now,
            developsAt: clock.now.addingTimeInterval(-120),
            filmProfileID: "portra400"
        )

        let p2Raw = Data([2])
        let p2ID = UUID()
        _ = try storage.saveRaw(p2Raw, id: p2ID)
        let p2 = Photo(
            id: p2ID,
            rawPath: storage.rawURL(for: p2ID).path,
            capturedAt: clock.now,
            developsAt: clock.now.addingTimeInterval(-60),
            filmProfileID: "portra400"
        )
        context.insert(p1)
        context.insert(p2)
        try context.save()

        _ = try? await service.developReadyPhotos(in: context)

        XCTAssertEqual(renderer.callCount, 2, "every ready photo should be attempted, even if one fails")
        let developedCount = try context.fetch(FetchDescriptor<Photo>())
            .filter { $0.status == .developed }.count
        XCTAssertEqual(developedCount, 1, "the second photo should still develop after the first throws")
    }

    // Bug C: a photo persisted as .developed whose preview file is missing
    // must not stay in the Roll as a previewless ghost — it should be reset
    // so the next pass re-renders from the raw.
    @MainActor
    func testDevelopedPhotoMissingFileGetsReconciled() async throws {
        let renderer = NoopRenderer()
        renderer.output = Data([0xCA, 0xFE])
        let service = DevelopmentService(renderer: renderer, storage: storage, clock: clock)

        let id = UUID()
        _ = try storage.saveRaw(Data([1]), id: id)
        // Simulate a photo persisted as developed but whose file is missing
        // from storage (e.g. produced by an earlier crashy code path).
        let photo = Photo(
            id: id,
            rawPath: storage.rawURL(for: id).path,
            capturedAt: clock.now,
            developsAt: clock.now.addingTimeInterval(-3600),
            filmProfileID: "portra400",
            status: .developed
        )
        photo.developedPath = "/mem/\(id.uuidString)_dev.jpg"
        context.insert(photo)
        try context.save()

        _ = try await service.developReadyPhotos(in: context)

        XCTAssertEqual(photo.status, .developed,
                       "the orphan should be re-developed in the same pass")
        XCTAssertNotNil(photo.developedPath)
        XCTAssertEqual(storage.writtenDeveloped[id], Data([0xCA, 0xFE]),
                       "re-render should produce a real preview file")
    }
    
    // After Bug B is fixed, the failed photo must not be left stuck in
    // `.developing` — otherwise the Darkroom row sticks at 00:00:00 forever.
    @MainActor
    func testRenderFailureLeavesPhotoRetryable() async throws {
        let renderer = FailFirstRenderer()
        let service = DevelopmentService(renderer: renderer, storage: storage, clock: clock)

        let id = UUID()
        _ = try storage.saveRaw(Data([1]), id: id)
        let photo = Photo(
            id: id,
            rawPath: storage.rawURL(for: id).path,
            capturedAt: clock.now,
            developsAt: clock.now.addingTimeInterval(-60),
            filmProfileID: "portra400"
        )
        context.insert(photo)
        try context.save()

        _ = try? await service.developReadyPhotos(in: context)

        XCTAssertNotEqual(photo.status, .developing,
                          "a render failure must not strand the photo in .developing forever")
    }

}

final class FailFirstRenderer: FilmRenderer {
    var callCount = 0
    var output: Data = Data([0xCA, 0xFE])
    func render(jpegData: Data, profile: FilmProfile, seed: UInt64) throws -> Data {
        callCount += 1
        if callCount == 1 { throw FilmRenderError.renderFailed }
        return output
    }
}
