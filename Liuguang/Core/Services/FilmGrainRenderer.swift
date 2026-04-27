import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

protocol FilmRenderer {
    func render(jpegData: Data, profile: FilmProfile, seed: UInt64) throws -> Data
}

enum FilmRenderError: Error {
    case invalidInput
    case renderFailed
}

final class FilmGrainRenderer: FilmRenderer {
    private let context: CIContext

    init() {
        self.context = CIContext(options: [.useSoftwareRenderer: false])
    }

    func render(jpegData: Data, profile: FilmProfile, seed: UInt64) throws -> Data {
        guard let input = CIImage(data: jpegData) else {
            throw FilmRenderError.invalidInput
        }
        let extent = input.extent

        var image = input
        image = applyColor(image, profile: profile)
        image = applyGrain(image, profile: profile, extent: extent, seed: seed)
        image = applyVignette(image, profile: profile)
        image = applyLightLeak(image, profile: profile, extent: extent, seed: seed)

        guard let cg = context.createCGImage(image, from: extent) else {
            throw FilmRenderError.renderFailed
        }
        let uiImage = UIImage(cgImage: cg)
        guard let data = uiImage.jpegData(compressionQuality: 0.92) else {
            throw FilmRenderError.renderFailed
        }
        return data
    }

    private func applyColor(_ image: CIImage, profile: FilmProfile) -> CIImage {
        let color = CIFilter.colorControls()
        color.inputImage = image
        color.contrast = Float(profile.contrast)
        color.saturation = Float(profile.saturation)
        color.brightness = 0
        var out = color.outputImage ?? image

        let temp = CIFilter.temperatureAndTint()
        temp.inputImage = out
        let warmthOffset = CGFloat(profile.warmth) * 1000
        temp.neutral = CIVector(x: 6500 + warmthOffset, y: 0)
        temp.targetNeutral = CIVector(x: 6500, y: 0)
        out = temp.outputImage ?? out
        return out
    }

    private func applyGrain(_ image: CIImage, profile: FilmProfile, extent: CGRect, seed: UInt64) -> CIImage {
        guard profile.grainIntensity > 0 else { return image }
        let noise = CIFilter.randomGenerator()
        guard var grain = noise.outputImage?.cropped(to: extent) else { return image }

        let mono = CIFilter.colorMatrix()
        mono.inputImage = grain
        mono.rVector = CIVector(x: 0.3, y: 0.3, z: 0.3, w: 0)
        mono.gVector = CIVector(x: 0.3, y: 0.3, z: 0.3, w: 0)
        mono.bVector = CIVector(x: 0.3, y: 0.3, z: 0.3, w: 0)
        mono.aVector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(profile.grainIntensity) * 0.4)
        mono.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        grain = mono.outputImage ?? grain

        let blend = CIFilter.sourceOverCompositing()
        blend.inputImage = grain
        blend.backgroundImage = image
        return blend.outputImage ?? image
    }

    private func applyVignette(_ image: CIImage, profile: FilmProfile) -> CIImage {
        let vignette = CIFilter.vignette()
        vignette.inputImage = image
        vignette.intensity = 0.6
        vignette.radius = 1.5
        return vignette.outputImage ?? image
    }

    private func applyLightLeak(_ image: CIImage, profile: FilmProfile, extent: CGRect, seed: UInt64) -> CIImage {
        guard profile.lightLeakStrength > 0 else { return image }
        var rng = SeededGenerator(seed: seed)
        let cornerX = Bool.random(using: &rng) ? extent.minX : extent.maxX
        let cornerY = Bool.random(using: &rng) ? extent.minY : extent.maxY

        let gradient = CIFilter.radialGradient()
        gradient.center = CGPoint(x: cornerX, y: cornerY)
        gradient.radius0 = 0
        gradient.radius1 = Float(max(extent.width, extent.height) * 0.8)
        gradient.color0 = CIColor(red: 1.0, green: 0.35, blue: 0.13,
                                   alpha: CGFloat(profile.lightLeakStrength))
        gradient.color1 = CIColor(red: 1.0, green: 0.35, blue: 0.13, alpha: 0)

        guard let leak = gradient.outputImage?.cropped(to: extent) else { return image }
        let blend = CIFilter.screenBlendMode()
        blend.inputImage = leak
        blend.backgroundImage = image
        return blend.outputImage ?? image
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0xdeadbeef : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

final class NoopRenderer: FilmRenderer {
    var output: Data = Data([0xFF, 0xD8, 0xFF, 0xD9])
    func render(jpegData: Data, profile: FilmProfile, seed: UInt64) throws -> Data {
        output
    }
}
