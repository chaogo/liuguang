import SwiftUI
import SwiftData

struct DarkroomView: View {
    @Query(
        filter: #Predicate<Photo> { $0.statusRaw != "developed" },
        sort: \Photo.developsAt, order: .forward
    )
    private var developing: [Photo]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 48) {
                header

                if developing.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 40) {
                        ForEach(developing) { photo in
                            DevelopingRow(photo: photo)
                        }
                    }
                }

                Text("Good things take time.")
                    .font(LiuguangFont.headline(20))
                    .italic()
                    .foregroundStyle(LiuguangColor.onSurfaceVariant.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)
            }
            .padding(24)
        }
        .background(LiuguangColor.paper)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Developing")
                .font(LiuguangFont.headline(44))
                .foregroundStyle(LiuguangColor.onSurfaceVariant)
            Text("Current Batch / 35mm ISO 400")
                .labelCaps()
                .foregroundStyle(LiuguangColor.outline)
        }
    }

    private var emptyState: some View {
        Text("No photos developing.\nTake one to start the clock.")
            .font(LiuguangFont.body(15))
            .foregroundStyle(LiuguangColor.outline)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
    }
}

struct DevelopingRow: View {
    let photo: Photo

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, photo.developsAt.timeIntervalSince(context.date))
            let total = photo.developsAt.timeIntervalSince(photo.capturedAt)
            let elapsedFraction = total > 0 ? (1.0 - remaining / total) : 1.0

            VStack(alignment: .leading, spacing: 16) {
                Rectangle()
                    .fill(LiuguangColor.surfaceContainerLowest)
                    .aspectRatio(4.0/3.0, contentMode: .fit)
                    .grainOverlay(opacity: 0.08)
                    .overlay(
                        Rectangle()
                            .strokeBorder(LiuguangColor.outlineVariant.opacity(0.3), lineWidth: 12)
                    )

                HStack {
                    Text(shortID).labelCaps().foregroundStyle(LiuguangColor.outline)
                    Spacer()
                    Text(statusLabel(remaining: remaining))
                        .labelCaps()
                        .foregroundStyle(LiuguangColor.shutter)
                }

                HStack(alignment: .lastTextBaseline) {
                    Text(countdownString(remaining))
                        .font(LiuguangFont.headline(28))
                        .monospacedDigit()
                    Spacer()
                    Text("Remaining").labelCaps().foregroundStyle(LiuguangColor.outline)
                }

                progressBar(fraction: elapsedFraction)
            }
        }
    }

    private var shortID: String {
        "Expos. " + String(photo.id.uuidString.prefix(4))
    }

    private func statusLabel(remaining: TimeInterval) -> String {
        if remaining <= 0 { return "Developed" }
        if remaining < 6 * 3600 { return "Agitating" }
        if remaining < 23 * 3600 { return "In Progress" }
        return "Queued"
    }

    private func countdownString(_ remaining: TimeInterval) -> String {
        let total = Int(remaining)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func progressBar(fraction: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(LiuguangColor.surfaceContainer)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [LiuguangColor.primary, LiuguangColor.shutter],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * max(0, min(1, fraction)))
            }
            .frame(height: 2)
        }
        .frame(height: 2)
    }
}

#Preview {
    DarkroomView()
        .modelContainer(for: [Photo.self, CaptureBatch.self], inMemory: true)
}
