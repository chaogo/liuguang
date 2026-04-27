import SwiftUI

struct PhotoDetailView: View {
    let photo: Photo

    var body: some View {
        ScrollView {
            VStack(spacing: 48) {
                DiskImage(path: photo.developedPath)
                    .aspectRatio(3.0/4.0, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .grainOverlay(opacity: 0.08)
                    .padding(12)
                    .background(LiuguangColor.surfaceContainerLowest)
                    .rotationEffect(.degrees(-1))
                    .shadow(color: .black.opacity(0.08), radius: 20, y: 10)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Captured").labelCaps().foregroundStyle(LiuguangColor.outline)
                        Text(photo.capturedAt.formatted(date: .long, time: .omitted))
                            .font(LiuguangFont.headline(22))
                    }
                    Spacer()
                    exifStrip
                }
                .padding(.horizontal, 8)
            }
            .padding(24)
        }
        .background(LiuguangColor.paper)
        .navigationTitle("流光")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let path = photo.developedPath,
                   let url = URL(string: "file://" + path) {
                    ShareLink(item: url) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(LiuguangColor.primary)
                    }
                }
            }
        }
    }

    private var exifStrip: some View {
        HStack(spacing: 20) {
            stat("ISO", "\(photo.iso)")
            Divider().frame(height: 16)
            stat("SS", "1/\(photo.shutterDenominator)")
            Divider().frame(height: 16)
            stat("F", String(format: "%.1f", photo.aperture))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .overlay(
            Rectangle().stroke(LiuguangColor.outline.opacity(0.15))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ISO \(photo.iso), shutter 1 over \(photo.shutterDenominator), aperture f \(String(format: "%.1f", photo.aperture))")
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(LiuguangFont.label(9)).foregroundStyle(LiuguangColor.outline)
            Text(value).font(LiuguangFont.label(12))
        }
    }
}
