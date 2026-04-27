import XCTest
import SwiftData
@testable import Liuguang

final class DevelopmentServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var clock: TestClock!
    var storage: InMemoryPhotoStorage!
    var renderer: NoopRenderer!
    var service: DevelopmentService!

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
        renderer = NoopRenderer()
        renderer.output = Data([0xDE, 0xAD, 0xBE, 0xEF])
        service = DevelopmentService(
            renderer: renderer,
            storage: storage,
            clock: clock
        )
    }

    @MainActor
    private func makePhoto(id: UUID = UUID(), developsIn: TimeInterval) throws -> Photo {
        let raw = Data([1, 2, 3])
        _ = try storage.saveRaw(raw, id: id)
        let photo = Photo(
            id: id,
            rawPath: storage.rawURL(for: id).path,
            capturedAt: clock.now,
            developsAt: clock.now.addingTimeInterval(developsIn),
            filmProfileID: "portra400"
        )
        context.insert(photo)
        try context.save()
        return photo
    }

    @MainActor
    func testDoesNotProcessUnreadyPhotos() async throws {
        _ = try makePhoto(developsIn: 3600)
        let count = try await service.developReadyPhotos(in: context)
        XCTAssertEqual(count, 0)

        let all = try context.fetch(FetchDescriptor<Photo>())
        XCTAssertEqual(all.first?.status, .queued)
    }

    @MainActor
    func testProcessesReadyPhoto() async throws {
        let photo = try makePhoto(developsIn: -60)
        let count = try await service.developReadyPhotos(in: context)
        XCTAssertEqual(count, 1)

        XCTAssertEqual(photo.status, .developed)
        XCTAssertNotNil(photo.developedPath)
        XCTAssertEqual(storage.writtenDeveloped[photo.id], Data([0xDE, 0xAD, 0xBE, 0xEF]))
    }

    @MainActor
    func testOnlyProcessesReadySubset() async throws {
        _ = try makePhoto(developsIn: -60)
        _ = try makePhoto(developsIn: -30)
        _ = try makePhoto(developsIn: 3600)

        let count = try await service.developReadyPhotos(in: context)
        XCTAssertEqual(count, 2)

        let all = try context.fetch(FetchDescriptor<Photo>())
        let developed = all.filter { $0.status == .developed }
        let queued = all.filter { $0.status == .queued }
        XCTAssertEqual(developed.count, 2)
        XCTAssertEqual(queued.count, 1)
    }

    @MainActor
    func testIdempotentOnAlreadyDeveloped() async throws {
        let photo = try makePhoto(developsIn: -60)
        _ = try await service.developReadyPhotos(in: context)
        let firstPath = photo.developedPath

        renderer.output = Data([0xCA, 0xFE])
        let count = try await service.developReadyPhotos(in: context)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(photo.developedPath, firstPath)
    }
}
