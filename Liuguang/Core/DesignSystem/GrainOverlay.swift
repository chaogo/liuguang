import SwiftUI

struct GrainOverlay: View {
    var opacity: Double = 0.04

    var body: some View {
        Canvas { context, size in
            let dotCount = Int(size.width * size.height / 60)
            var rng = SystemRandomNumberGenerator()
            for _ in 0..<dotCount {
                let x = Double.random(in: 0...size.width, using: &rng)
                let y = Double.random(in: 0...size.height, using: &rng)
                let rect = CGRect(x: x, y: y, width: 1, height: 1)
                context.fill(Path(rect), with: .color(.black.opacity(0.6)))
            }
        }
        .opacity(opacity)
        .allowsHitTesting(false)
        .drawingGroup()
    }
}

extension View {
    func grainOverlay(opacity: Double = 0.04) -> some View {
        overlay(GrainOverlay(opacity: opacity))
    }
}
