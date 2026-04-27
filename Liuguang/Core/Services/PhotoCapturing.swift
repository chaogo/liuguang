import Foundation
import AVFoundation
import UIKit

struct CapturedPhoto {
    let jpegData: Data
    let iso: Int
    let shutterDenominator: Int
    let aperture: Double
    let capturedAt: Date
}

enum CaptureError: LocalizedError, Equatable {
    case permissionDenied
    case deviceUnavailable
    case captureFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera access was denied."
        case .deviceUnavailable:
            #if targetEnvironment(simulator)
            return "The iOS Simulator has no camera. Run on a physical device to capture photos."
            #else
            return "No camera is available on this device."
            #endif
        case .captureFailed(let reason):
            return "Capture failed: \(reason)"
        }
    }
}

protocol PhotoCapturing: AnyObject {
    var previewLayer: CALayer? { get }
    func requestPermission() async -> Bool
    func start() async throws
    func stop()
    func flip() async throws
    func capture() async throws -> CapturedPhoto
}

final class MockCamera: PhotoCapturing {
    var previewLayer: CALayer? = nil
    var permissionGranted = true
    var nextCapture: CapturedPhoto?
    var captureError: CaptureError?

    func requestPermission() async -> Bool { permissionGranted }
    func start() async throws {}
    func stop() {}
    func flip() async throws {}

    func capture() async throws -> CapturedPhoto {
        if let error = captureError { throw error }
        if let photo = nextCapture { return photo }
        return CapturedPhoto(
            jpegData: Data([0xFF, 0xD8, 0xFF, 0xD9]),
            iso: 400,
            shutterDenominator: 125,
            aperture: 2.8,
            capturedAt: Date()
        )
    }
}
