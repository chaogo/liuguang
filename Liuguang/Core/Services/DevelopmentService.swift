import Foundation
import SwiftData

@MainActor
final class DevelopmentService {
    let renderer: FilmRenderer
    let storage: PhotoStorage
    let clock: Clock

    init(renderer: FilmRenderer, storage: PhotoStorage, clock: Clock) {
        self.renderer = renderer
        self.storage = storage
        self.clock = clock
    }

    @discardableResult
    func developReadyPhotos(in context: ModelContext) async throws -> Int {
        var sawChanges = reconcileOrphanedDeveloped(in: context)

        let now = clock.now
        let descriptor = FetchDescriptor<Photo>(
            predicate: #Predicate { $0.statusRaw != "developed" }
        )
        let candidates = try context.fetch(descriptor)
        var processed = 0

        for photo in candidates where photo.developsAt <= now {
            do {
                try await develop(photo)
                processed += 1
                sawChanges = true
            } catch {
                photo.status = .queued
                sawChanges = true
            }
        }

        if sawChanges { try context.save() }
        return processed
    }

    /// Photos marked .developed whose preview file is missing (or whose
    /// developedPath was never persisted) cannot be displayed. Reset them
    /// so the next pass re-renders from the raw file.
    private func reconcileOrphanedDeveloped(in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<Photo>(
            predicate: #Predicate { $0.statusRaw == "developed" }
        )
        guard let developed = try? context.fetch(descriptor) else { return false }
        var changed = false
        for photo in developed {
            if let path = photo.developedPath, storage.developedExists(at: path) {
                continue
            }
            photo.developedPath = nil
            photo.status = .queued
            changed = true
        }
        return changed
    }
    
    func develop(_ photo: Photo) async throws {
        photo.status = .developing

        let rawData = try storage.loadRaw(id: photo.id)
        let profile = FilmProfile.all.first { $0.id == photo.filmProfileID }
            ?? FilmProfile.all[0]

        let seed = withUnsafeBytes(of: photo.id.uuid) { $0.load(as: UInt64.self) }
        let developed = try renderer.render(jpegData: rawData, profile: profile, seed: seed)

        let url = try storage.saveDeveloped(developed, id: photo.id)
        photo.developedPath = url.path
        photo.status = .developed
    }
}
