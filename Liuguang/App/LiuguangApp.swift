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
                    BackgroundDevelopmentScheduler.submitNextRequest()
                }
        }
        .modelContainer(container)
    }
}
