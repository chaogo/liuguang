import Foundation

protocol PhotoStorage {
    func saveRaw(_ data: Data, id: UUID) throws -> URL
    func loadRaw(id: UUID) throws -> Data
    func rawURL(for id: UUID) -> URL
    func developedURL(for id: UUID) -> URL
    func saveDeveloped(_ data: Data, id: UUID) throws -> URL
    func delete(id: UUID) throws
}

struct FileSystemPhotoStorage: PhotoStorage {
    let root: URL

    init(root: URL? = nil) {
        if let root {
            self.root = root
        } else {
            let base = try! FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            self.root = base.appendingPathComponent("Photos", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: self.root, withIntermediateDirectories: true)
    }

    func rawURL(for id: UUID) -> URL {
        root.appendingPathComponent("\(id.uuidString)_raw.jpg")
    }

    func developedURL(for id: UUID) -> URL {
        root.appendingPathComponent("\(id.uuidString)_dev.jpg")
    }

    func saveRaw(_ data: Data, id: UUID) throws -> URL {
        let url = rawURL(for: id)
        try data.write(to: url, options: .atomic)
        return url
    }

    func loadRaw(id: UUID) throws -> Data {
        try Data(contentsOf: rawURL(for: id))
    }

    func saveDeveloped(_ data: Data, id: UUID) throws -> URL {
        let url = developedURL(for: id)
        try data.write(to: url, options: .atomic)
        return url
    }

    func delete(id: UUID) throws {
        try? FileManager.default.removeItem(at: rawURL(for: id))
        try? FileManager.default.removeItem(at: developedURL(for: id))
    }
}
