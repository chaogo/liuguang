import SwiftUI
import SwiftData

struct CameraView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel: CameraViewModel?

    var body: some View {
        ZStack {
            LiuguangColor.paper.ignoresSafeArea()
            if let vm = viewModel {
                switch vm.state {
                case .denied:
                    deniedState
                case .error(let message):
                    errorState(message)
                default:
                    content(vm: vm)
                }
            } else {
                ProgressView()
            }
        }
        .task {
            if viewModel == nil {
                let camera = AVFoundationCamera()
                let clock = SystemClock()
                let coordinator = CaptureCoordinator(
                    camera: camera,
                    storage: FileSystemPhotoStorage(),
                    limitService: CaptureLimitService(clock: clock),
                    notifications: SystemNotificationService(),
                    clock: clock
                )
                viewModel = CameraViewModel(coordinator: coordinator)
            }
            await viewModel?.onAppear(context: context)
        }
        .onDisappear { viewModel?.onDisappear() }
        .alert(
            "Capture failed",
            isPresented: Binding(
                get: { viewModel?.lastError != nil },
                set: { if !$0 { viewModel?.lastError = nil } }
            ),
            presenting: viewModel?.lastError
        ) { _ in
            Button("OK", role: .cancel) { viewModel?.lastError = nil }
        } message: { message in
            Text(message)
        }
    }

    private var deniedState: some View {
        VStack(spacing: 16) {
            Text("Camera access needed")
                .font(LiuguangFont.headline(24))
                .foregroundStyle(LiuguangColor.ink)
            Text("Enable camera access in Settings to capture photos.")
                .font(LiuguangFont.body(15))
                .foregroundStyle(LiuguangColor.outline)
                .multilineTextAlignment(.center)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Link("Open Settings", destination: url)
                    .font(LiuguangFont.label(12))
                    .foregroundStyle(LiuguangColor.shutter)
            }
        }
        .padding(32)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text("Camera unavailable")
                .font(LiuguangFont.headline(24))
                .foregroundStyle(LiuguangColor.ink)
            Text(message)
                .font(LiuguangFont.body(15))
                .foregroundStyle(LiuguangColor.outline)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    @ViewBuilder
    private func content(vm: CameraViewModel) -> some View {
        VStack(spacing: 0) {
            header
            Spacer()
            viewfinder(vm: vm)
            Spacer()
            VStack(spacing: 12) {
                shutter(vm: vm)
                if vm.remaining == 0, let next = vm.nextBatchAt {
                    HStack(spacing: 6) {
                        Text("Next roll in")
                            .labelCaps(size: 10, tracking: 1.5)
                        Text(next, style: .timer)
                            .font(LiuguangFont.label(10))
                            .monospacedDigit()
                    }
                    .foregroundStyle(LiuguangColor.outline)
                }
            }
            .padding(.bottom, 48)
        }
    }

    private var header: some View {
        HStack {
            Color.clear.frame(width: 24, height: 24)
            Spacer()
            Text("流光")
                .font(LiuguangFont.headline(24))
                .foregroundStyle(LiuguangColor.ink)
            Spacer()
            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private func viewfinder(vm: CameraViewModel) -> some View {
        ZStack {
            CameraPreview(previewLayer: vm.coordinator.camera.previewLayer)
                .aspectRatio(3.0/4.0, contentMode: .fit)
                .clipped()
                .overlay(alignment: .topLeading) {
                    Text("\(vm.remaining)/\(CaptureBatch.limit)")
                        .font(LiuguangFont.headline(18))
                        .tracking(4)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .padding(16)
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        Task { await vm.flip() }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Flip camera")
                    .padding(16)
                }
                .grainOverlay(opacity: 0.04)
        }
        .padding(.horizontal, 24)
    }

    private func shutter(vm: CameraViewModel) -> some View {
        Button {
            Task { await vm.capture(context: context) }
        } label: {
            Circle()
                .strokeBorder(LiuguangColor.shutter.opacity(0.3), lineWidth: 1)
                .frame(width: 72, height: 72)
                .overlay(
                    Circle()
                        .fill(vm.remaining > 0 ? LiuguangColor.shutter : LiuguangColor.outline.opacity(0.3))
                        .frame(width: 60, height: 60)
                )
        }
        .disabled(vm.remaining == 0 || vm.isCapturing)
        .accessibilityLabel("Shutter")
        .accessibilityHint("\(vm.remaining) of \(CaptureBatch.limit) frames remaining")
        .sensoryFeedback(.impact(weight: .medium), trigger: vm.remaining)
    }
}

#Preview {
    CameraView()
        .modelContainer(for: [Photo.self, CaptureBatch.self], inMemory: true)
}
