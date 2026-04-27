import SwiftUI

enum LiuguangFont {
    static let headlineName = "NotoSerif-Italic"
    static let bodyName = "Inter-Regular"
    static let labelName = "Inter-Medium"

    static func headline(_ size: CGFloat) -> Font {
        .custom(headlineName, size: size, relativeTo: .title)
    }

    static func body(_ size: CGFloat) -> Font {
        .custom(bodyName, size: size, relativeTo: .body)
    }

    static func label(_ size: CGFloat) -> Font {
        .custom(labelName, size: size, relativeTo: .caption)
    }
}

struct LabelCaps: ViewModifier {
    var size: CGFloat = 10
    var tracking: CGFloat = 2.0
    func body(content: Content) -> some View {
        content
            .font(LiuguangFont.label(size))
            .tracking(tracking)
            .textCase(.uppercase)
    }
}

extension View {
    func labelCaps(size: CGFloat = 10, tracking: CGFloat = 2.0) -> some View {
        modifier(LabelCaps(size: size, tracking: tracking))
    }
}
