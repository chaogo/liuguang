import Foundation
import SwiftData

enum PhotoStatus: String, Codable {
    case queued
    case developing
    case developed
}

@Model
final class Photo {
    @Attribute(.unique) var id: UUID
    var rawPath: String
    var developedPath: String?
    var capturedAt: Date
    var developsAt: Date
    var filmProfileID: String
    var statusRaw: String
    var iso: Int
    var shutterDenominator: Int
    var aperture: Double

    var status: PhotoStatus {
        get { PhotoStatus(rawValue: statusRaw) ?? .queued }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        rawPath: String,
        capturedAt: Date,
        developsAt: Date,
        filmProfileID: String,
        status: PhotoStatus = .queued,
        iso: Int = 400,
        shutterDenominator: Int = 125,
        aperture: Double = 2.8
    ) {
        self.id = id
        self.rawPath = rawPath
        self.capturedAt = capturedAt
        self.developsAt = developsAt
        self.filmProfileID = filmProfileID
        self.statusRaw = status.rawValue
        self.iso = iso
        self.shutterDenominator = shutterDenominator
        self.aperture = aperture
    }
}
