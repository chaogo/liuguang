import XCTest
import SwiftData
@testable import Liuguang

final class CaptureLimitServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var clock: TestClock!
    var service: CaptureLimitService!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Photo.self, CaptureBatch.self,
            configurations: config
        )
        context = ModelContext(container)
        clock = TestClock(Date(timeIntervalSince1970: 1_700_000_000))
        service = CaptureLimitService(clock: clock)
    }

    func testStartsWithFullLimit() throws {
        XCTAssertEqual(try service.remaining(in: context), 12)
    }

    func testRegisteringCaptureDecrementsRemaining() throws {
        try service.registerCapture(in: context)
        XCTAssertEqual(try service.remaining(in: context), 11)
    }

    func testTwelfthCaptureAllowedThirteenthRejected() throws {
        for _ in 0..<12 {
            try service.registerCapture(in: context)
        }
        XCTAssertEqual(try service.remaining(in: context), 0)

        XCTAssertThrowsError(try service.registerCapture(in: context)) { error in
            guard case CaptureLimitError.limitReached = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
    }

    func testWindowExpiresAfter24HoursFromFirstShot() throws {
        try service.registerCapture(in: context)
        clock.advance(by: 23 * 3600)
        XCTAssertEqual(try service.remaining(in: context), 11, "still inside window")

        clock.advance(by: 2 * 3600) // now 25h past first shot
        XCTAssertEqual(try service.remaining(in: context), 12, "new batch after expiry")
    }

    func testWindowAnchoredToFirstShotNotMidnight() throws {
        try service.registerCapture(in: context)
        clock.advance(by: 12 * 3600)
        try service.registerCapture(in: context)
        XCTAssertEqual(try service.remaining(in: context), 10)

        clock.advance(by: 13 * 3600) // 25h from first shot
        XCTAssertEqual(try service.remaining(in: context), 12)
    }
}
