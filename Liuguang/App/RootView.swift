import SwiftUI

struct RootView: View {
    @State private var selection: Tab = .capture

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
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Photo.self, CaptureBatch.self], inMemory: true)
}
