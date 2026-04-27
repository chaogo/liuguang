import Foundation

struct FilmProfile: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let grainIntensity: Double
    let contrast: Double
    let saturation: Double
    let warmth: Double
    let lightLeakStrength: Double

    static let all: [FilmProfile] = [
        .init(id: "portra400", name: "Portra 400", grainIntensity: 0.3, contrast: 1.05, saturation: 1.1, warmth: 0.15, lightLeakStrength: 0.2),
        .init(id: "trix400", name: "Tri-X 400", grainIntensity: 0.6, contrast: 1.25, saturation: 0.0, warmth: 0.0, lightLeakStrength: 0.1),
        .init(id: "ektar100", name: "Ektar 100", grainIntensity: 0.15, contrast: 1.15, saturation: 1.3, warmth: 0.05, lightLeakStrength: 0.15),
        .init(id: "cinestill800", name: "CineStill 800T", grainIntensity: 0.45, contrast: 0.95, saturation: 1.0, warmth: -0.1, lightLeakStrength: 0.35),
        .init(id: "fuji400h", name: "Fuji Pro 400H", grainIntensity: 0.35, contrast: 0.9, saturation: 1.05, warmth: -0.05, lightLeakStrength: 0.2),
        .init(id: "gold200", name: "Kodak Gold 200", grainIntensity: 0.4, contrast: 1.1, saturation: 1.15, warmth: 0.2, lightLeakStrength: 0.25)
    ]

    static func random(using rng: inout some RandomNumberGenerator) -> FilmProfile {
        all.randomElement(using: &rng)!
    }
}
