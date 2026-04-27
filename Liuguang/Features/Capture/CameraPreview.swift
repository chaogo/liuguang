import SwiftUI
import UIKit
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let previewLayer: CALayer?

    func makeUIView(context: Context) -> PreviewHostView {
        let view = PreviewHostView()
        view.backgroundColor = .black
        view.attach(previewLayer)
        return view
    }

    func updateUIView(_ uiView: PreviewHostView, context: Context) {
        uiView.attach(previewLayer)
    }
}

final class PreviewHostView: UIView {
    private weak var attached: CALayer?

    func attach(_ layer: CALayer?) {
        guard attached !== layer else { return }
        attached?.removeFromSuperlayer()
        if let layer {
            layer.frame = bounds
            self.layer.addSublayer(layer)
            attached = layer
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        attached?.frame = bounds
    }
}
