import SwiftUI
import SwiftData

struct RollView: View {
    @Query(
        filter: #Predicate<Photo> {
            $0.statusRaw == "developed" && $0.developedPath != nil
        },
        sort: \Photo.capturedAt, order: .reverse
    )
    private var photos: [Photo]

    private let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The Developed Roll")
                            .font(LiuguangFont.headline(36))
                            .foregroundStyle(LiuguangColor.ink)
                        Text("Sequence 01").labelCaps().foregroundStyle(LiuguangColor.outline)
                    }

                    if photos.isEmpty {
                        Text("Nothing developed yet.")
                            .font(LiuguangFont.body(15))
                            .foregroundStyle(LiuguangColor.outline)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    } else {
                        LazyVGrid(columns: columns, spacing: 32) {
                            ForEach(photos) { photo in
                                NavigationLink(value: photo) {
                                    PhotoCard(photo: photo)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Photo, \(photo.filmProfileID), \(photo.capturedAt.formatted(date: .abbreviated, time: .omitted))")
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(LiuguangColor.paper)
            .navigationDestination(for: Photo.self) { photo in
                PhotoDetailView(photo: photo)
            }
        }
    }
}

struct PhotoCard: View {
    let photo: Photo

    private var profileName: String {
        FilmProfile.all.first { $0.id == photo.filmProfileID }?.name ?? photo.filmProfileID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DiskImage(path: photo.developedPath)
                .aspectRatio(4.0/5.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipped()
                .grainOverlay(opacity: 0.06)
                .padding(8)
                .background(LiuguangColor.surfaceContainerLowest)

            Text(profileName)
                .font(LiuguangFont.headline(18))
                .italic()
                .foregroundStyle(LiuguangColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(photo.capturedAt.formatted(date: .abbreviated, time: .omitted))
                .labelCaps(size: 9)
                .foregroundStyle(LiuguangColor.outlineVariant)
        }
    }
}

#Preview {
    RollView()
        .modelContainer(for: [Photo.self, CaptureBatch.self], inMemory: true)
}
