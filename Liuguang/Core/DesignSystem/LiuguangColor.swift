import SwiftUI

enum LiuguangColor {
    static let paper = Color(hex: 0xF9F9F7)
    static let ink = Color(hex: 0x1A1C1B)
    static let shutter = Color(hex: 0xFF5722)
    static let primary = Color(hex: 0xB02F00)
    static let outline = Color(hex: 0x907067)
    static let outlineVariant = Color(hex: 0xE4BEB4)
    static let surfaceContainer = Color(hex: 0xEEEEEC)
    static let surfaceContainerLow = Color(hex: 0xF4F4F2)
    static let surfaceContainerLowest = Color(hex: 0xFFFFFF)
    static let onSurfaceVariant = Color(hex: 0x5B4039)
    static let tertiary = Color(hex: 0x655D56)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
