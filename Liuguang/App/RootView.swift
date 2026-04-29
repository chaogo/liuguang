import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: Tab = .capture
    @State private var isDevelopmentRunning = false

    enum Tab: Hashable { case capture, darkroom, roll }

    var body: some View {
        TabView(selection: $selection) {
            CameraView()
                .tabItem { Label("Camera", systemImage: "camera") }
                .tag(Tab.capture)

            DarkroomView()
                .tabItem { Label("Darkroom", systemImage: "hourglass") }
                .tag(Tab.darkroom)

            RollView()
                .tabItem { Label("Roll", systemImage: "photo.on.rectangle") }
                .tag(Tab.roll)
        }
        .tint(LiuguangColor.shutter)
        .task {
            await runDevelopmentLoop()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { @MainActor in
                    await developReadyOnce()
                }
            }
        }
    }

    @MainActor
    private func runDevelopmentLoop() async {
        while !Task.isCancelled {
            await developReadyOnce()
            try? await Task.sleep(for: .seconds(nextWakeDelay()))
        }
    }

    @MainActor
    private func developReadyOnce() async {
        guard !isDevelopmentRunning else { return }
        isDevelopmentRunning = true
        defer { isDevelopmentRunning = false }

        let service = DevelopmentService(
            renderer: FilmGrainRenderer(),
            storage: FileSystemPhotoStorage(),
            clock: SystemClock()
        )
        _ = try? await service.developReadyPhotos(in: modelContext)
    }

    @MainActor
    private func nextWakeDelay() -> TimeInterval {
        var descriptor = FetchDescriptor<Photo>(
            predicate: #Predicate { $0.statusRaw != "developed" },
            sortBy: [SortDescriptor(\.developsAt)]
        )
        descriptor.fetchLimit = 1
        guard let next = (try? modelContext.fetch(descriptor))?.first?.developsAt else {
            return 3600
        }
        return max(1, min(next.timeIntervalSinceNow, 3600))
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Photo.self, CaptureBatch.self], inMemory: true)
}
