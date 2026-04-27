import SwiftUI
import UIKit

struct DiskImage: View {
    let path: String?
    var placeholder: Color = LiuguangColor.surfaceContainerLowest

    var body: some View {
        if let path, let image = UIImage(contentsOfFile: path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
    }
}
