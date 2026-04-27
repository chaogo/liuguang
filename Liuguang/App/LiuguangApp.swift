import SwiftUI
import SwiftData

@main
struct LiuguangApp: App {
    let container: ModelContainer

    init() {
        let container = try! ModelContainer(for: Photo.self, CaptureBatch.self)
        self.container = container
        BackgroundDevelopmentScheduler.register(container: container)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    _ = await SystemNotificationService().requestAuthorization()
                    await developReady()
                    BackgroundDevelopmentScheduler.submitNextRequest()
                }
        }
        .modelContainer(container)
    }

    @MainActor
    private func developReady() async {
        let context = ModelContext(container)
        let service = DevelopmentService(
            renderer: FilmGrainRenderer(),
            storage: FileSystemPhotoStorage(),
            clock: SystemClock()
        )
        _ = try? await service.developReadyPhotos(in: context)
    }
}
