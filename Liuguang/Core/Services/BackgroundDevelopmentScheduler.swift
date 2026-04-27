import Foundation
import BackgroundTasks
import SwiftData

enum BackgroundDevelopmentScheduler {
    static let taskIdentifier = "com.chao.liuguang.develop"

    @MainActor
    static func register(container: ModelContainer) {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            Task { @MainActor in
                await handle(task: task, container: container)
            }
        }
    }

    static func submitNextRequest(earliestBegin: Date = Date().addingTimeInterval(15 * 60)) {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = earliestBegin
        try? BGTaskScheduler.shared.submit(request)
    }

    @MainActor
    private static func handle(task: BGTask, container: ModelContainer) async {
        submitNextRequest()

        let context = ModelContext(container)
        let service = DevelopmentService(
            renderer: FilmGrainRenderer(),
            storage: FileSystemPhotoStorage(),
            clock: SystemClock()
        )

        let work = Task {
            try? await service.developReadyPhotos(in: context)
        }

        task.expirationHandler = {
            work.cancel()
        }

        _ = await work.value
        task.setTaskCompleted(success: true)
    }
}
