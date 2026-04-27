import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class CameraViewModel {
    enum State { case idle, starting, running, denied, error(String) }

    var state: State = .idle
    var remaining: Int = CaptureBatch.limit
    var nextBatchAt: Date?
    var lastError: String?
    var isCapturing: Bool = false

    let coordinator: CaptureCoordinator

    init(coordinator: CaptureCoordinator) {
        self.coordinator = coordinator
    }

    func onAppear(context: ModelContext) async {
        refreshRemaining(context: context)
        state = .starting
        do {
            try await coordinator.camera.start()
            state = .running
        } catch CaptureError.permissionDenied {
            state = .denied
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func onDisappear() {
        coordinator.camera.stop()
    }

    func flip() async {
        try? await coordinator.camera.flip()
    }

    func capture(context: ModelContext) async {
        guard remaining > 0, !isCapturing else { return }
        isCapturing = true
        defer { isCapturing = false }
        do {
            _ = try await coordinator.captureAndPersist(in: context)
        } catch CaptureLimitError.limitReached {
            // benign: another capture won the race; just resync the UI below
        } catch {
            lastError = error.localizedDescription
        }
        refreshRemaining(context: context)
    }

    func refreshRemaining(context: ModelContext) {
        remaining = (try? coordinator.limitService.remaining(in: context)) ?? 0
        if remaining == 0 {
            nextBatchAt = (try? coordinator.limitService.currentBatch(in: context))?.expiresAt()
        } else {
            nextBatchAt = nil
        }
    }
}
